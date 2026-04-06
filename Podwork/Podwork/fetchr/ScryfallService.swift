import Foundation
import SwiftData


// MARK: - Scryfall Commander
@Model
final public class ScryfallCommander: Identifiable, @unchecked  Sendable {
    @Attribute(.unique) public var name: String
    public var colorIdentity: String
    public var cmc: Int
    public var hasPartner: Bool
    public var partnersWith: String?
    
    /// Computed properties for convenience
    public var colorIdentityArray: [String] {
        return colorIdentity.compactMap { String($0) }
    }
    
    public var colorDescription: String {
        let colors: [String: String] = [
            "W": "White",
            "U": "Blue",
            "B": "Black",
            "R": "Red",
            "G": "Green"
        ]
        
        let colorNames = colorIdentityArray.compactMap { colors[$0] }
        
        if colorNames.isEmpty {
            return "Colorless"
        } else if colorNames.count == 1 {
            return colorNames.first!
        } else {
            return colorNames.joined(separator: ", ")
        }
    }
    
    public init(name: String, colorIdentity: String, cmc: Int, hasPartner: Bool = false, partnersWith: String? = nil) {
        self.name = name
        self.colorIdentity = colorIdentity
        self.cmc = cmc
        self.hasPartner = hasPartner
        self.partnersWith = partnersWith
    }
    
    /// For JSON export compatibility
    public func toJSON() -> [String: Any] {
        return [
            "name": name,
            "colorIdentity": colorIdentity,
            "cmc": cmc,
            "hasPartner": hasPartner,
            "partnersWith": partnersWith ?? ""
        ]
    }
}

/// Extension for color identity helpers
public extension ScryfallCommander {
    static var commonColorCombinations: [String: String] {
        return [
            "C": "Colorless",
            "W": "White",
            "U": "Blue",
            "B": "Black",
            "R": "Red",
            "G": "Green",
            "WU": "Azorius",
            "WB": "Orzhov",
            "WR": "Boros",
            "WG": "Selesnya",
            "UB": "Dimir",
            "UR": "Izzet",
            "UG": "Simic",
            "BR": "Rakdos",
            "BG": "Golgari",
            "RG": "Gruul",
            "WUB": "Esper",
            "WUR": "Jeskai",
            "WUG": "Bant",
            "WBR": "Mardu",
            "WBG": "Abzan",
            "WRG": "Naya",
            "UBR": "Grixis",
            "UBG": "Sultai",
            "URG": "Temur",
            "BRG": "Jund",
            "WUBR": "Four-Color (No Green)",
            "WUBG": "Four-Color (No Red)",
            "WURG": "Four-Color (No Black)",
            "WBRG": "Four-Color (No Blue)",
            "UBRG": "Four-Color (No White)",
            "WUBRG": "Five-Color (WUBRG)"
        ]
    }
}




// MARK: - Scryfall Service
@MainActor
public class ScryfallService: ObservableObject {
    @Published public var isLoading = false
    @Published public var loadingError: String?
    @Published public var progress: Double = 0.0
    @Published public var totalBytesDownloaded: Int = 0
    private let baseURL = "https://api.scryfall.com/cards/search?order=edhrec&q=(game%3Apaper)+legal%3Acommander+is%3Acommander"
    private var modelContext: ModelContext?
    
    public init() {}
    
    
    /// Set the model context for SwiftData operations
    public func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Public Methods
    
    /// Fetches all commanders from Scryfall and saves them to SwiftData

    public func fetchAndSaveCommanders() async throws {
        isLoading = true
        loadingError = nil
        //progress = 0.0
        await MainActor.run { self.progress = 0.0 }
        
        do {
            let commanders = try await fetchAllCommanders()
            try await saveCommanders(commanders)
            
            // Also export to JSON for backup
            try await exportToJSON(commanders)
            
            isLoading = false
            //progress = 1.0
            await MainActor.run { self.progress = 1.0 }
            print("✅ Successfully fetched and saved \(commanders.count) commanders")
        } catch {
            await MainActor.run { self.progress = 0.0 } 
            isLoading = false
            loadingError = error.localizedDescription
            print("❌ Error fetching commanders: \(error)")
            throw error
        }
    }
    
    /// Loads commanders from SwiftData
    func loadCommanders() throws -> [ScryfallCommander] {
        guard let modelContext = modelContext else { return [] }
        let descriptor = FetchDescriptor<ScryfallCommander>(
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// Searches for commanders by name
    func searchCommanders(query: String) throws -> [ScryfallCommander] {
        guard let modelContext = modelContext else { return [] }
        let descriptor = FetchDescriptor<ScryfallCommander>(
            predicate: #Predicate { commander in
                commander.name.localizedStandardContains(query)
            },
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// Gets commanders by color identity
    func commandersByColor(identity: String) throws -> [ScryfallCommander] {
        guard let modelContext = modelContext else { return [] }
        let descriptor = FetchDescriptor<ScryfallCommander>(
            predicate: #Predicate { commander in
                commander.colorIdentity == identity
            },
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// Gets partner-eligible commanders
    func partnerEligibleCommanders() throws -> [ScryfallCommander] {
        guard let modelContext = modelContext else { return [] }
        let descriptor = FetchDescriptor<ScryfallCommander>(
            predicate: #Predicate { commander in
                commander.hasPartner == true
            },
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - Private Methods
    
    public func fetchAllCommanders() async throws -> [ScryfallCommander] {
        var allCommanders: [ScryfallCommander] = []
        var currentURL = baseURL
        var hasMore = true
        var pageCount = 0
        totalBytesDownloaded = 0
        
        while hasMore {

            let (commanders, nextURL, morePages, dataSize) = try await fetchCommandersPage(url: currentURL)
            allCommanders.append(contentsOf: commanders)
            totalBytesDownloaded += dataSize
            pageCount += 1
            let estimatedProgress = min(Double(pageCount) / 15.0, 0.9) // estimate about 20 pages
            if estimatedProgress > progress {
                await MainActor.run { self.progress = estimatedProgress }
            }
            //self.progress = min(Double(totalBytesDownloaded) / 15_000_000, 1.0) // Estimate about 20 pages
            print("progress", progress)
            
            if let nextURL = nextURL, morePages {
                currentURL = nextURL
                
                // Add a small delay to avoid rate limiting
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            } else {
                hasMore = false
            }
        }
        
        return allCommanders
    }
    
    private func fetchCommandersPage(url: String) async throws -> (commanders: [ScryfallCommander], nextURL: String?, hasMore: Bool, dataSize: Int) {
        guard let url = URL(string: url) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let dataSize = data.count
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let json = json else {
            throw NSError(domain: "ScryfallService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"])
        }
        
        let hasMore = json["has_more"] as? Bool ?? false
        let nextPage = json["next_page"] as? String
        
        guard let cardsData = json["data"] as? [[String: Any]] else {
            throw NSError(domain: "ScryfallService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No card data found"])
        }
        
        let commanders = parseCommanders(cardsData)
        return (commanders, nextPage, hasMore, dataSize)
    }
    
    private func parseCommanders(_ cardsData: [[String: Any]]) -> [ScryfallCommander] {
        return cardsData.compactMap { cardData in
            parseCommanderData(cardData)
        }
    }
    
    private func parseCommanderData(_ cardData: [String: Any]) -> ScryfallCommander? {
        // Check if it's a double-faced card
        if let cardFaces = cardData["card_faces"] as? [[String: Any]], !cardFaces.isEmpty {
            // Use the front face for name and oracle text
            let frontFace = cardFaces[0]
            return extractCommanderInfo(frontFace, cardData: cardData)
        } else {
            // Single-faced card
            return extractCommanderInfo(cardData, cardData: cardData)
        }
    }
    
    private func extractCommanderInfo(_ faceData: [String: Any], cardData: [String: Any]) -> ScryfallCommander? {
        guard let name = faceData["name"] as? String else {
            print("Card name not found")
            return nil
        }
        
        let oracleText = faceData["oracle_text"] as? String ?? ""
        
        // Parse partner ability
        var hasPartner = oracleText.contains("Partner") || oracleText.contains("partner")
        var partnersWith: String? = nil
        
        if hasPartner && oracleText.contains("Partner with") {
            // Extract the specific partner name
            let pattern = "Partner with ([^\\n.,;()]+)"
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(oracleText.startIndex..<oracleText.endIndex, in: oracleText)
                if let match = regex.firstMatch(in: oracleText, options: [], range: range) {
                    if let partnerNameRange = Range(match.range(at: 1), in: oracleText) {
                        partnersWith = String(oracleText[partnerNameRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
            }
        }
        
        let oracleTextLower = oracleText.lowercased()
        let typeLineLower = (cardData["type_line"] as? String ?? "").lowercased()
        let isDoctor = typeLineLower.contains("doctor")
        if isDoctor {
            hasPartner = true
//            partnersWith = "doctor"
        }
        
        
        if oracleTextLower.contains("doctor's companion") {
            hasPartner = true
            partnersWith = "The Doctor"
        }
        
        // Get color identity and CMC from the main card data
        let colorIdentityArray = cardData["color_identity"] as? [String] ?? []
        var colorIdentity = colorIdentityArray.joined()
        
        // Explicitly mark colorless commanders
        if colorIdentity.isEmpty { colorIdentity = "C"}

        let cmc = Int(cardData["cmc"] as? Double ?? 0)
        
        return ScryfallCommander(
            name: name,
            colorIdentity: colorIdentity,
            cmc: cmc,
            hasPartner: hasPartner,
            partnersWith: partnersWith
        )
    }
    
    @MainActor
    private func saveCommanders(_ commanders: [ScryfallCommander]) async throws {
        // Use a background context for concurrent safety
        guard let modelContext = modelContext else { return  }
        let container = modelContext.container
        let backgroundContext = ModelContext(container)
        
        //try await backgroundContext.transaction { context in
        try backgroundContext.transaction { context in
        
            let existing = try context.fetch(FetchDescriptor<ScryfallCommander>())
            let existingMap = Dictionary(uniqueKeysWithValues: existing.map { ($0.name, $0) })
            
            for newCommander in commanders {
                if let old = existingMap[newCommander.name] {
                    old.colorIdentity = newCommander.colorIdentity
                    old.cmc = newCommander.cmc
                    old.hasPartner = newCommander.hasPartner
                    old.partnersWith = newCommander.partnersWith
                } else {
                    context.insert(newCommander)
                }
            }
            
            // First, remove duplicates (if any)
            //let existingNames = try context.fetch(FetchDescriptor<ScryfallCommander>()).map { $0.name }
            //let existingNamesSet = Set(existingNames)
            
            // Insert only new commanders
            //for commander in commanders {
            //    if !existingNamesSet.contains(commander.name) {
            //        context.insert(commander)
            //    }
            //}
            
            try context.save()
        }
    }
    
    
    
    private func exportToJSON(_ commanders: [ScryfallCommander]) async throws {
        let jsonArray = commanders.map { $0.toJSON() }
        let jsonData = try JSONSerialization.data(withJSONObject: jsonArray, options: .prettyPrinted)
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let filePath = documentsPath.appendingPathComponent("commanders.json")
        
        try jsonData.write(to: filePath)
        print("💾 Exported commanders to JSON at: \(filePath)")
    }
}

extension ModelContext {
    @MainActor
    func transaction<T>(_ body: (ModelContext) throws -> T) throws -> T {
        try body(self)
    }
}

// MARK: - ModelContext Extension for Concurrent Transactions
//extension ModelContext {
//    @MainActor
//    func transaction<T>(_ body: @escaping (ModelContext) throws -> T) async throws -> T {
//        return try await withCheckedThrowingContinuation { continuation in
//            Task {
//                do {
//                    let result = try body(self)
//                    continuation.resume(returning: result)
//                } catch {
//                    continuation.resume(throwing: error)
//                }
//            }
//        }
//    }
//}

/*
public extension ScryfallCommander {
    static var commonColorCombinations: [String: String] {
        return [
            "C": "Colorless",
            "W": "White",
            "U": "Blue",
            "B": "Black",
            "R": "Red",
            "G": "Green",
            "WU": "Azorius (W/U)",
            "WB": "Orzhov (W/B)",
            "WR": "Boros (W/R)",
            "WG": "Selesnya (W/G)",
            "UB": "Dimir (U/B)",
            "UR": "Izzet (U/R)",
            "UG": "Simic (U/G)",
            "BR": "Rakdos (B/R)",
            "BG": "Golgari (B/G)",
            "RG": "Gruul (R/G)",
            "WUB": "Esper (W/U/B)",
            "WUR": "Jeskai (W/U/R)",
            "WUG": "Bant (W/U/G)",
            "WBR": "Mardu (W/B/R)",
            "WBG": "Abzan (W/B/G)",
            "WRG": "Naya (W/R/G)",
            "UBR": "Grixis (U/B/R)",
            "UBG": "Sultai (U/B/G)",
            "URG": "Temur (U/R/G)",
            "BRG": "Jund (B/R/G)",
            "WUBR": "Four-Color (No Green)",
            "WUBG": "Four-Color (No Red)",
            "WURG": "Four-Color (No Black)",
            "WBRG": "Four-Color (No Blue)",
            "UBRG": "Four-Color (No White)",
            "WUBRG": "Five-Color (WUBRG)"
        ]
    }
}
*/
