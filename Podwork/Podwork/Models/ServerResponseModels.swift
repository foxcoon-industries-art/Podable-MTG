import Foundation
import SwiftUI
import SwiftData


@MainActor
public class LeaderboardManager: ObservableObject {
    @Published public var leaderboardItems: [LeaderboardItem] = []
    @Published public var leaderboardRecords: [LeaderboardRecord] = []
    @Published public var leaderboardTotals: [String: Double] = [:]
    @Published public var isLoading = false
    @Published public var lastUpdated: Date?
    @Published public var error: String?
    
    private let userDefaults = UserDefaults.standard
    private let leaderboardKey = "saved_leaderboard_items"
    private let lastUpdatedKey = "leaderboard_last_updated"
    private let leaderboardTotalsKey = "leaderboard_totals"
    
    private var modelContext: ModelContext
    
//    public init() {
//        setupSwiftData()
//        loadLeaderboard()
//    }
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadLeaderboard()
        //fetchLeaderboard()
    }
    
    private func setupSwiftData() {
        do {
         
        } catch {
            print("Failed to setup SwiftData: \(error)")
        }
    }
    
    // MARK: - Simple Load Function
    private func loadLeaderboard() {
        let modelContext = modelContext
        
        do {
            // Simple fetch - get all leaderboard records
            let descriptor = FetchDescriptor<LeaderboardRecord>()
            self.leaderboardRecords = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to load leaderboard: \(error)")
        }
    }
    // MARK: - Fetch from Server
    public func fetchLeaderboard() async {
        isLoading = true
        error = nil
        
        do {
            let url = URL(string: "https://foxcoon-industries.ca/pods/leaderboard")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(LeaderboardResponse.self, from: data)
            
            // Clear old data
            await clearOldRecords()
            
            
            self.leaderboardTotals = response.totals
            
            // Parse and save Glorious Ascension
            for (metricType, entry) in response.gloriousAscension {
                if let category = SummaryRankingTitles(rawValue: metricType) {
                    await saveRecord(
                        category: category,
                        commander: entry.commander,
                        partner: entry.partner ?? "",
                        record: entry.value,
                        isGlorious: true
                    )
                }
            }
            
            // Parse and save Wall of Shame
            for (metricType, entry) in response.wallOfShame {
                if let category = SummaryRankingTitles(rawValue: metricType) {
                    await saveRecord(
                        category: category,
                        commander: entry.commander,
                        partner: entry.partner ?? "",
                        record: entry.value,
                        isGlorious: false
                    )
                }
            }
            loadLeaderboard()
            
        } catch {
            self.error = "Failed to fetch: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Simple Save Function
    private func saveRecord(category: SummaryRankingTitles,
                            commander: String,
                            partner: String,
                            record: Double,
                            isGlorious: Bool) async {
        let modelContext = modelContext
        
        let newRecord = LeaderboardRecord(
            category: category,
            commander: commander,
            partner: partner,
            record: record,
            isGlorious: isGlorious
        )
        
        modelContext.insert(newRecord)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save record: \(error)")
        }
    }
    
    // MARK: - Clear Old Data
    private func clearOldRecords() async {
        let modelContext = modelContext
        
        do {
            try modelContext.delete(model: LeaderboardRecord.self)
            try modelContext.save()
        } catch {
            print("Failed to clear records: \(error)")
        }
    }
    
    // MARK: - Convenient Accessors
    public func gloriousRecords() -> [LeaderboardRecord] {
        leaderboardRecords
            .filter { $0.isGlorious }
            .sorted { ($0.rankingCategory?.displayName ?? "") < ($1.rankingCategory?.displayName ?? "") }
    }
    
    public func shameRecords() -> [LeaderboardRecord] {
        leaderboardRecords
            .filter { !$0.isGlorious }
            .sorted { ($0.rankingCategory?.displayName ?? "") < ($1.rankingCategory?.displayName ?? "") }
    }
    
    public func shouldRefresh() -> Bool {
        // Refresh if we have no data or if the oldest record is > 1 hour old
        guard let oldestRecord = leaderboardRecords.min(by: { $0.updated < $1.updated }) else {
            return true
        }
        return Date().timeIntervalSince(oldestRecord.updated) > 3600
    }
    
}

// MARK: - LEADERBOARD TOTALS FROM API
public struct LeaderboardTotals: Codable {
    public let commandersSeen: Double
    public let commanderDamage: Double
    public let commanderTax: Double
    public let games: Double
    public let playtime: Double
    
    public init(jsonDict : [String:Double]) {
        self.commandersSeen = jsonDict["total_cmdrs_seen_played"] ?? 0
        self.commanderDamage = jsonDict["total_commander_damage"] ?? 0
        self.commanderTax = jsonDict["total_commander_tax"] ?? 0
        self.games = jsonDict["total_games"] ?? 0
        self.playtime = jsonDict["total_playtime"] ?? 0
    }
    
    public enum CodingKeys: String, CodingKey  {
        // Glorious Ascension metrics
        case commandersSeen = "total_cmdrs_seen_played"
        case commanderDamage = "total_commander_damage"
        case commanderTax = "total_commander_tax"
        case games = "total_games"
        case playtime = "total_playtime"
    }
}


// MARK: - LEADERBOARD RECORD - SWIFTDATA
@Model
public final class LeaderboardRecord {
    @Attribute(.unique) public var id: String
    public var category: String  // Store as string for SwiftData compatibility
    public var commander: String
    public var partner: String
    public var record: Double
    public var updated: Date
    public var isGlorious: Bool
    
    
    public init(category: SummaryRankingTitles,
         commander: String,
         partner: String = "",
         record: Double,
         isGlorious: Bool = true) {
        self.id = "\(category.rawValue)_\(isGlorious)"  // Unique ID per category/type
        self.category = category.rawValue
        self.commander = commander
        self.partner = partner
        self.record = record
        self.isGlorious = isGlorious
        self.updated = Date()
    }
    
    // Computed property to get the enum back
    public var rankingCategory: SummaryRankingTitles? {
        SummaryRankingTitles(rawValue: category)
    }
}

public struct LeaderboardItem: Codable, Identifiable, Equatable {
    public let id: String
    public let category: SummaryRankingTitles
    public let commander: String
    public let partner: String
    public let record: Double
    public let info: String
    public let updated: Date?
    public let isGlorious: Bool  // true for glorious, false for shame
    
    public init(category: SummaryRankingTitles,
         commander: String,
         partner: String = "",
         record: Double,
         info: String = "",
         updated: Date = Date(),
         isGlorious: Bool = true) {
        self.id = UUID().uuidString
        self.category = category
        self.commander = commander
        self.partner = partner
        self.record = record
        self.info = info
        self.updated = updated
        self.isGlorious = isGlorious
    }
    
    public  init(from record: LeaderboardRecord) {
        self.id = record.id
        self.category = SummaryRankingTitles(rawValue: record.category) ?? .mostWins
        self.commander = record.commander
        self.partner = record.partner
        self.record = record.record
        self.info = ""
        self.updated = record.updated
        self.isGlorious = record.isGlorious
    }
}


public enum SummaryRankingTitles: String, CaseIterable, Codable {
    // Glorious Ascension metrics
    case mostWins = "most_wins"
    case mostPlayed = "most_played"
    case mostDamage = "most_damage"
    case mostTax = "most_tax"
    case mostAltWins = "most_alt_wins"
    case fastestWins = "fastest_win"
    case mostSolRings = "most_sol_rings"  
    
    // Wall of Shame metrics
    case longestTurns = "longest_turns"
    case leastImpactful = "least_impact"
    case mostBracketDisparity = "most_bracket_disparity"
    case mostConcessions = "most_concessions"
    case mostBombsUsed = "most_bombs"
    case mostTurnOneSolRings = "most_turn_one_sol_rings"
    
    public var displayName: String {
        switch self {
        case .mostWins: return "Most Wins"
        case .mostPlayed: return "Most Played"
        case .mostDamage: return "Most Damage"
        case .mostTax: return "Most Tax"
        case .mostAltWins: return "Most Alternative Wins"
        case .fastestWins: return "Fastest Win"
        case .mostSolRings: return "Most Sol Rings Played"
        case .longestTurns: return "Longest Turns"
        case .leastImpactful: return "Least Impactful"
        case .mostBracketDisparity: return "Most Bracket Disparity"
        case .mostConcessions: return "Most Concessions"
        case .mostBombsUsed: return "Most Bombs Used"
        case .mostTurnOneSolRings: return "Most Turn 1 Sol Rings"
        }
    }
    
    public var displayIcon: String {
        switch self {
        case .mostWins: return "rosette"
        case .mostPlayed: return "gamecontroller.fill"
        case .mostDamage: return "flame.fill"
        case .mostTax: return "dollarsign.bank.building"
        case .mostAltWins: return "flag.pattern.checkered"
        case .fastestWins: return "hare"
        case .mostSolRings: return "circle.badge.exclamationmark"
        case .longestTurns: return "hourglass.bottomhalf.fill"
        case .leastImpactful: return "circle.dashed"
        case .mostBracketDisparity: return "divide.circle.fill"
        case .mostConcessions: return "flag.fill"
        case .mostBombsUsed: return "burst.fill"
        case .mostTurnOneSolRings: return "dot.scope"
        }
    }
    
    public var displayColor: Color {
        switch self {
        case .mostWins: return Color.yellow
        case .mostPlayed: return Color.blue
        case .mostDamage: return Color.red
        case .mostTax: return  Color.green
        case .mostAltWins: return Color.mint
        case .fastestWins: return  Color.secondary
        case .mostSolRings: return Color.yellow
        case .longestTurns: return Color.gray
        case .leastImpactful: return  Color.secondary
        case .mostBracketDisparity: return Color.orange
        case .mostConcessions: return Color.white
        case .mostBombsUsed: return Color.pink
        case .mostTurnOneSolRings: return  Color.yellow
        }
    }
    
    
    
    public var isGloriousCategory: Bool {
        switch self {
        case .mostWins, .mostPlayed, .mostDamage, .mostTax, .mostAltWins, .fastestWins, .mostSolRings:
            return true
        default:
            return false
        }
    }
}


// MARK: - Response Models
public struct LeaderboardResponse: Codable {
    public let totals: [String: Double]
    public let gloriousAscension: [String: GlobalLeaderboardEntry]
    public let wallOfShame: [String: GlobalLeaderboardEntry]
    public let lastUpdated: String?
}

public struct GlobalLeaderboardEntry: Codable {
    public let commander: String
    public let partner: String?
    public let value: Double
    
    public enum CodingKeys: String, CodingKey {
        case commander
        case partner
        case value
    }
}




/**/
 
/*
// MARK: - Commander Stats Summary
struct CommanderSummaryStats: Codable {
    let commander: String
    let partner: String?
    let games: Int
    let wins: Int
    let winRate: Double
    let winPercentage: Double
    let survivalRate: Double
    let efficiency: Double
    let totalCommanderDamage: Int
    let avgCommanderDamagePerGame: Double
    let avgCommanderDamagePerTurn: [Double]
    let totalTax: Int
    let avgTax: Double
    let totalPlayTime: Double
    let avgGameDuration: Double
    let avgTimeToWin: Double
    let avgTurnDuration: Double
    let avgDurationPerTurn: [Double]
    let avgGamePlaytimeRatio: Double
    let maxTurnsOfGames: Int
    let timesEliminated: Int
    let avgEliminationRound: Double?
    let mostCommonEliminationMethod: String
}

 */

