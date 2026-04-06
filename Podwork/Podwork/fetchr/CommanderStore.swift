import Foundation
import SwiftUI
import SwiftData


/// A unified store for managing commanders with SwiftData
@MainActor
@Observable
public class CommanderStore {
    public static let shared = CommanderStore()
    public var commanders: [ScryfallCommander] = []
    public var isLoaded = false
    public var loadingError: String?
    public var searchResults: [ScryfallCommander] = []
    
    
    
    private var modelContext: ModelContext?
    //public var scryfallService = ScryfallService()
    public let scryfallService: ScryfallService
    
    // Cache for performance
    private var commandersByLetter: [String: [ScryfallCommander]] = [:]
    private var searchCache: [String: [ScryfallCommander]] = [:]
    private let maxCacheSize = 100
    
    
    private let metadataKey = "CommanderStoreMetadata"
    public var lastUpdateDate: Date? {
        didSet { saveMetadata() }
    }
    public var lastDownloadSize: Int? {
        didSet { saveMetadata() }
    }
    
    public var progress: Double {
        get { scryfallService.progress }
        set { scryfallService.progress = newValue }
    }
    
    public init() {
        scryfallService = ScryfallService()
        loadMetadata()
    }
    
    private func saveMetadata() {
        //let encoder = JSONEncoder()
        let metadata = [
            "lastUpdateDate": lastUpdateDate?.timeIntervalSince1970 ?? 0,
            "lastDownloadSize": lastDownloadSize ?? 15_000_000 // Default to approx 15mb
        ] as [String: Any]
        
        UserDefaults.standard.set(metadata, forKey: metadataKey)
    }
    private func loadMetadata() {
        guard let metadata = UserDefaults.standard.dictionary(forKey: metadataKey) else { return }
        
        if let timestamp = metadata["lastUpdateDate"] as? Double, timestamp > 0 {
            lastUpdateDate = Date(timeIntervalSince1970: timestamp)
        }
        if let bytes = metadata["lastDownloadSize"] as? Int, bytes > 0 {
            lastDownloadSize = bytes
        }
    }
    
    public var isEmpty: Bool {
        commanders.isEmpty
    }
    
    /// Set the model context and load initial data
    @MainActor
    public func setup(with context: ModelContext) {
        self.modelContext = context
        self.scryfallService.setModelContext(context)
        Task {
            await loadCommanders()
        }
    }
    
    // MARK: - Public Methods
    
    /// Load commanders from database (modelContext)
    public func loadCommanders() async {
        do {
            print("Loading Commanders... ")
            commanders = try scryfallService.loadCommanders()
            updateCommandersByLetter()
            isLoaded = true
            loadingError = nil
            print("... ✅ Loaded: \(commanders.count) Commanders from [modelContext] database!")
        } catch {
            print("... ❌ Failed to load commanders: \(error)")
            loadingError = error.localizedDescription
            
            /// Try to load from bundled JSON as fallback
            await loadFromBundle()
        }
    }
    
    /// Fetch fresh data from Scryfall
    public func refreshFromScryfall() async {
        do {
            
            Task {
                for await progress in scryfallService.$progress.values {
                    await MainActor.run {
                        // Re-expose the progress for SwiftUI to update
                        self.scryfallService.progress = progress
                    }
                }
            }
            
            try await scryfallService.fetchAndSaveCommanders()
            await loadCommanders()
            
            // Save metadata after successful fetch
            lastUpdateDate = Date()
            lastDownloadSize = scryfallService.totalBytesDownloaded

        } catch {
            loadingError = "Failed to fetch from Scryfall: \(error.localizedDescription)"
            //errorMessage = "Failed to fetch from Scryfall:\n\(error.localizedDescription)"
            //showingErrorAlert = true
        }
    }
    
    public func refresh() -> Bool {
        clearCache()
        Task {
            await loadCommanders()
        }
        return self.commanders.count != 0 ? false : true
    }
    
    
    public func clearCache() {
        commanders.removeAll()
        searchResults.removeAll()
        commandersByLetter.removeAll()
        searchCache.removeAll()
    }
    
    public func allCommanderNames() -> [String] {
        return self.commanders.map{$0.name}
    }
    
    /// Search commanders by name
    public func searchCommanders(query: String) -> [ScryfallCommander] {
        guard !query.isEmpty else {
            searchResults = []
            return [] 
        }
        
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Check cache first
        if let cached = searchCache[cleanQuery] {
            searchResults = cached
            return cached
        }
        
        // Perform search
        let results = commanders.filter { commander in
            commander.name.lowercased().contains(cleanQuery)
        }.sorted { $0.name < $1.name }
        
        // Cache results
        cacheSearchResults(query: cleanQuery, results: results)
        searchResults = results
        return results
    }
    
    /// Get commanders starting with a specific letter
    @MainActor
    public func commanders(startingWith letter: String) -> [ScryfallCommander] {
        return commandersByLetter[letter.uppercased()] ?? []
    }
    
    /// Get commanders by color identity
    public func commanders(withColorIdentity colorIdentity: String) -> [ScryfallCommander] {
        return commanders.filter { $0.colorIdentity == colorIdentity }
            .sorted { $0.name < $1.name }
    }
    
    /// Get commanders by CMC
    public func commanders(withCMC cmc: Int) -> [ScryfallCommander] {
        return commanders.filter { $0.cmc == cmc }
            .sorted { $0.name < $1.name }
    }
    
    /// Get partner-eligible commanders
    public func partnerEligibleCommanders() -> [ScryfallCommander] {
        return commanders.filter { $0.hasPartner }
            .sorted { $0.name < $1.name }
    }
    
    /// Get commanders that can partner with a specific commander
    public func partnersFor(commander: ScryfallCommander) -> [ScryfallCommander] {
        // --- DOCTOR WHO SPECIAL CASE ---
        // If this is a Doctor’s Companion → return all Doctors
        if commander.partnersWith == "The Doctor"  {
            return commanders.filter { $0.name.contains("The ") && $0.name.contains("Doctor") }
                .sorted { $0.name < $1.name }
        }
        
        // If this IS a Doctor → return all Doctor’s Companions
        if commander.name.contains("The ") && commander.name.contains("Doctor") {
            return commanders.filter { $0.partnersWith == "The Doctor" }
                .sorted { $0.name < $1.name }
        }
        // --- END SPECIAL CASE ---
        
        if let specificPartner = commander.partnersWith,
           specificPartner != "partner" {
            // Has specific partner
            return commanders.filter { $0.name == specificPartner }
        } else if commander.hasPartner {
            // Can partner with any partner commander
            return commanders.filter { 
                $0.hasPartner && 
                $0.name != commander.name &&
                ($0.partnersWith == "partner" || $0.partnersWith == nil)
            }.sorted { $0.name < $1.name }
        }
        return []
    }
    
    /// Check if a commander exists
    public func contains(_ name: String) -> Bool {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return commanders.contains { $0.name.localizedCaseInsensitiveCompare(cleanName) == .orderedSame }
    }
    
    
    /// Get random commanders
    public func randomCommanders(count: Int = 5) -> [ScryfallCommander] {
        return Array(commanders.shuffled().prefix(count))
    }
    
    
    public var statistics : CommanderIdentityStatistics {
        CommanderIdentityStatistics.fromCommanders(commanders)
    }
    
    // MARK: - Private Methods
    private func updateCommandersByLetter() {
        commandersByLetter = Dictionary(grouping: commanders) { commander in
            String(commander.name.prefix(1)).uppercased()
        }
        
        /// Sort each letter's commanders
        for (letter, commanders) in commandersByLetter {
            commandersByLetter[letter] = commanders.sorted { $0.name < $1.name }
        }
    }
    
    private func cacheSearchResults(query: String, results: [ScryfallCommander]) {
        // Maintain cache size
        if searchCache.count >= maxCacheSize {
            // Remove oldest entries
            let keysToRemove = Array(searchCache.keys.shuffled().prefix(10))
            for key in keysToRemove {
                searchCache.removeValue(forKey: key)
            }
        }
        searchCache[query] = results
    }
    
    
    private func loadFromBundle() async {
        /// Try to load from bundled JSON file
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = documentsPath.appendingPathComponent("commanders.json")
        
        do {
            let data = try Data(contentsOf: url)
            
            // Try to decode as array of dictionaries
            if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                let bundledCommanders = jsonArray.compactMap { dict -> ScryfallCommander? in
                    guard let name = dict["card_name"] as? String ?? dict["name"] as? String else { return nil }

                    let colorIdentity = dict["color_identity"] as? String ?? ""
                    let cmc = Int(dict["cmc"] as? String ?? "0") ?? 0
                    let hasPartner = dict["has_partner"] as? Bool ?? false
                    let partnersWith = dict["partner_with"] as? String ?? dict["partnersWith"] as? String
                    
                    return ScryfallCommander(
                        name: name,
                        colorIdentity: colorIdentity,
                        cmc: cmc,
                        hasPartner: hasPartner,
                        partnersWith: partnersWith
                    )
                }
                /// Save to  modelContext database
                for commander in bundledCommanders { modelContext?.insert(commander) }
                try modelContext?.save()
                
                commanders = bundledCommanders
                updateCommandersByLetter()
                isLoaded = true
                print("... ✅ Loaded: \(commanders.count) Commanders from bundle JSON!")
            }
        } catch {
            print("... ❌ Failed to load from bundle: \(error)")
        }
    }
}

public struct CommanderIdentityStatistics {
    public let totalCommanders: Int
    public let partnersCount: Int
    public let uniqueColors: Int
    public let averageCMC: Double
    public let stdevCMC: Double
    public let colorBins: [String: ColorBin]
    public let specialNameCount: Int
    public let asciiSafeCount: Int
    
    public var formattedAverageCMC: String { String(format: "%.1f", averageCMC) }
    public var formattedCMCstdev: String { String(format: "%.1f", stdevCMC) }
    public var partnerPercentage: Double {
        totalCommanders > 0 ? Double(partnersCount) / Double(totalCommanders) * 100 : 0
    }
    
    public static func fromCommanders(_ commanders: [ScryfallCommander]) -> CommanderIdentityStatistics {
        let partnerCount = commanders.filter { $0.hasPartner }.count
        let uniqueColors = Set(commanders.map { $0.colorIdentity.normalizedColorIdentity }).count
        let averageCMC = commanders.isEmpty ? 0 :
        Double(commanders.reduce(0) { $0 + $1.cmc }) / Double(commanders.count)
        let stdCMC = commanders.isEmpty ? 0 :  commanders.map{Double($0.cmc)}.standardDeviation
        
        // Build bins with counts + average CMC + std deviation
        var binData: [String: [Int]] = [:]
        for cmd in commanders {
            let key = cmd.colorIdentity.normalizedColorIdentity
            binData[key, default: []].append(cmd.cmc)
        }
        
        var bins: [String: ColorBin] = [:]
        for (key, cmcs) in binData {
            bins[key] = ColorBin(rawCMC: cmcs)
        }
        
        let specialNameCount = commanders.filter { !$0.name.canBeSafelyTypedASCII }.count
        let asciiSafeCount = commanders.count - specialNameCount
        
        return CommanderIdentityStatistics(
            totalCommanders: commanders.count,
            partnersCount: partnerCount,
            uniqueColors: uniqueColors,
            averageCMC: averageCMC,
            stdevCMC: stdCMC,
            colorBins: bins,
            specialNameCount: specialNameCount,
            asciiSafeCount: asciiSafeCount
        )
    }
}


public struct ColorBin {
    public let count: Int
    public let avgCMC: Double
    public let stdCMC: Double
    public let rawCMC: [Int]
    
    public init(rawCMC: [Int]){
        self.count = rawCMC.count
        self.avgCMC = rawCMC.map{ Double($0) }.mean
        self.stdCMC = rawCMC.map{ Double($0) }.standardDeviation
        self.rawCMC = rawCMC
    }
}




public  extension String {
    /// True if the name only contains characters that can be typed
    /// with the custom keyboard (letters, digits, spaces, punctuation).
    var canBeSafelyTypedASCII: Bool {
        let allowed: CharacterSet = {
            var set = CharacterSet.alphanumerics
            /// add space, apostrophe, comma, hyphen, slash, colon
            set.insert(charactersIn: " ',-/:")
            return set
        }()
        return unicodeScalars.allSatisfy { allowed.contains($0) }
    }
}

public extension String {
    /// Normalize color identity string into WUBRG order
    var normalizedColorIdentity: String {
        let wubrg = ["W","U","B","R","G"]
        let chars = self.map { String($0) }
        
        // Colorless
        if chars.isEmpty || self == "C" { return "C" }

        let sorted = wubrg.filter { chars.contains($0) }
        return sorted.joined()
    }
}

public extension String {
    /// Map color identity string into SwiftUI Colors
    var manaColors: [Color] {
        let map: [Character: Color] = [
            "C": Color(white: 0.55),     // Gray -> Dark Grayish
            "W": Color(white: 0.90),    // White → Light Grayish
            "U": Color.blue,            // Blue
            "B": Color.black,           // Black
            "R": Color.red,             // Red
            "G": Color.green            // Green
        ]
        return self.compactMap { map[$0] }
    }
}



/*
 // MARK: - Statistics Model
 struct CommanderStatistics {
 let totalCommanders: Int
 let partnersCount: Int
 let uniqueColors: Int
 let averageCMC: Double
 let colorBins: [String: (count: Int, avgCMC: Double)]
 let specialNameCount: Int
 let asciiSafeCount: Int
 
 var formattedAverageCMC: String { String(format: "%.1f", averageCMC) }
 var partnerPercentage: Double {
 totalCommanders > 0 ? Double(partnersCount) / Double(totalCommanders) * 100 : 0
 }
 
 
 static func fromCommanders(_ commanders: [ScryfallCommander]) -> CommanderStatistics {
 let partnerCount = commanders.filter { $0.hasPartner }.count
 let uniqueColors = Set(commanders.map { $0.colorIdentity.normalizedColorIdentity }).count
 let averageCMC = commanders.isEmpty ? 0 :
 Double(commanders.reduce(0) { $0 + $1.cmc }) / Double(commanders.count)
 
 /// Build bins with counts + average CMC
 var binData: [String: (sum: Int, count: Int)] = [:]
 for cmd in commanders {
 let key = cmd.colorIdentity.normalizedColorIdentity
 var entry = binData[key] ?? (0, 0)
 entry.sum += cmd.cmc
 entry.count += 1
 binData[key] = entry
 }
 
 var bins: [String: (count: Int, avgCMC: Double)] = [:]
 for (key, entry) in binData {
 let avg = entry.count > 0 ? Double(entry.sum) / Double(entry.count) : 0
 bins[key] = (entry.count, avg)
 }
 
 let specialNameCount = commanders.filter { !$0.name.canBeSafelyTypedASCII }.count
 let asciiSafeCount = commanders.count - specialNameCount
 
 return CommanderStatistics(
 totalCommanders: commanders.count,
 partnersCount: partnerCount,
 uniqueColors: uniqueColors,
 averageCMC: averageCMC,
 colorBins: bins,
 specialNameCount: specialNameCount,
 asciiSafeCount: asciiSafeCount
 )
 }
 }
 */
