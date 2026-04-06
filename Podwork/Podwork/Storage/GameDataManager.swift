import Foundation
import SwiftUI


@MainActor
public class GameDataManager: ObservableObject {
    public static let shared = GameDataManager()

    @Published public var finalStates: [FinalPod] = []
    @Published public var commanderStats : [String: CommanderSummary] = [:]
    @Published public var podSummaryStats: PodSummaryStats = PodSummaryStats(totalGames: 0)
    @Published public var bracketStats: [Int: BracketStatistics] = [:]
    @Published public var seatOrderStats:  SeatOrder = SeatOrder()
    
    @Published public var demoPods = DemoDataGenerator.demoData(count:20)
    @Published public var demoFinalPods : [FinalPod] = []
    @Published public var demoTurns : [String:[Turn]] = [:]

    // MARK: - Duel Match Data
    @Published public var duelMatches: [FinalDuelMatch] = []
    @Published public var tournaments: [TournamentRecord] = []

    @Published public var isLoading = false
    @Published public var error: DataManagerError?
    @Published public var lastRefresh: Date = Date()
    @Published public var includeDemoData: Bool = false

    
    // MARK: - Storage Managers
    public let podStorage = PodStorageManager.shared
    
    // MARK: - Configuration
    private var refreshTimer: Timer?
    private let autoRefreshInterval: TimeInterval = 30.0
    
    // MARK: - Initialization
    private init() {
        Task { await reloadStats() }
    }
    
    
    // MARK: - Data Loading
    /// Manually refresh all data
    public func refreshAllData() {
        refreshStats()
    }
    

    // MARK: - Loading Past Games Management
    public func refreshStats() {
        Task { await reloadStats() }
    }

    private func reloadStats() async {
        isLoading = true
        clearCache()

        await loadCommanderGameSummary()
        loadDuelMatches()
        loadTournaments()

        self.isLoading = false
        self.lastRefresh = Date()
    }
    
    private func loadCommanderGameSummary() async {
        do {
            var finalStates: [FinalPod] = []
            
            if includeDemoData {
                /// Use ONLY demo data
                self.demoFinalPods = demoPods.map { $0.0 }
                self.demoTurns = demoPods.reduce(into: [:]) { $0[$1.0.gameID] = $1.1 }
                
                finalStates = self.demoFinalPods
            } else {
                /// Use ONLY database data
                finalStates = podStorage.loadAllFinalPods()
            }
            
            let commanderSummaries = finalStates.getCommanderSummaries()

            self.finalStates = finalStates
            self.commanderStats = commanderSummaries
            self.seatOrderStats = commanderSummaries.turnOrderWinRates()
            self.bracketStats = BracketStatistics.buildAnalysis(from: finalStates)
            self.podSummaryStats = PodSummaryStats.getPodStats(from: finalStates,
                                                               and: commanderSummaries)
        } catch {
            print("❌ Error loading commander game stats: \(error)")
        }
    }

    
    @MainActor
    public func loadTurnHistory(for gameID: String) async -> [Turn] {
        /// If demo mode is on, check demo turns first
        if includeDemoData, let demo = demoTurns[gameID] as? [Turn] { return demo }
        
        /// Otherwise try database
        do {
            return try podStorage.loadGameTurnHistory(gameID: gameID)
        } catch {
            print("❌ Failed to load turn history for \(gameID): \(error)")
            return []
        }
    }

    public func loadPodsWithTurnHistory() -> [(FinalPod,[Turn])] {
        if includeDemoData {
           return self.demoFinalPods.map{ ($0,  self.demoTurns[ $0.gameID ]! ) } + podStorage.loadPodsForYeeting()
        }
        return podStorage.loadPodsForYeeting()
    }
    
    // MARK: - Game Management
    /// Save a completed game
    public func saveGame(_ finalState: FinalPod) {
        podStorage.saveFinalPod(finalState)
        Task { await reloadStats() }
    }

    /// Update a previously-saved game after user edits.
    public func updateGame(_ finalState: FinalPod) async throws {
        try podStorage.updateFinalPod(finalState)
        await reloadStats()
    }
    
    /// Delete a specific game
    public func deleteGame(_ gameID: String) async {
        self.clearCache()
        self.podStorage.deleteGame(gameID: gameID)
        await self.reloadStats()
    }

    
    /// Get all games
    public func getAllGames() -> [FinalPod] {
        return podStorage.loadAllFinalPods()
    }
    
    
    public func recentGames() -> [FinalPod] {
        return Array(self.finalStates
            .sorted { $0.date > $1.date }
            .prefix(10))
    }
    
    // MARK: - Duel Match Management

    public func loadDuelMatches() {
        self.duelMatches = podStorage.loadAllDuelMatches()
    }

    public func saveDuelMatch(_ match: FinalDuelMatch, turnHistories: [[DuelTurn]]) {
        podStorage.saveDuelMatch(match, turnHistories: turnHistories)
        Task { await reloadStats() }
    }

    public func deleteDuelMatch(_ matchID: String) async {
        podStorage.deleteDuelMatch(matchID: matchID)
        await reloadStats()
    }

    public func recentDuelMatches() -> [FinalDuelMatch] {
        return Array(self.duelMatches
            .sorted { $0.date > $1.date }
            .prefix(10))
    }

    // MARK: - Tournament Management

    public func loadTournaments() {
        self.tournaments = podStorage.loadAllTournaments()
    }

    public func saveTournamentRecord(_ record: TournamentRecord) {
        podStorage.saveTournamentRecord(record)
        Task { await reloadStats() }
    }

    // MARK: - Statistics Access
    /// Get overview statistics
    public func getOverviewStatistics() -> OverviewStatistics {
        return podStorage.loadAllFinalPods().getOverviewStatistics()
    }
    
    /// Get commander statistics
    public func getCommanderStatistics() -> [String: CommanderStatistics] {
        return podStorage.getCommanderStatistics()
    }
    

    
    


    
    // MARK: - Data Export/Import
    
    /// Export all games to JSON
    public func exportAllGames() -> Data? {
        return podStorage.exportGamesToJSON()
    }
    
    /// Import games from JSON data
    public func importGames(from data: Data) -> ImportResult {
        let result = podStorage.importGamesFromJSON(data)
        // Refresh data after import
        if result.imported > 0 {
            Task {
                await reloadStats()
            }
        }
        return result
    }
    
    // MARK: - Database Management
    @MainActor
    public func clearCache() {
        commanderStats.removeAll()
        finalStates.removeAll()
        bracketStats.removeAll()
        seatOrderStats = SeatOrder()
        podSummaryStats = PodSummaryStats(totalGames: 0)
        duelMatches.removeAll()
        tournaments.removeAll()
    }
    
    /// Clear all game data (use with caution)
    public func clearAllGameData() {
        podStorage.clearAllData()
        clearCache()
        Task {
            await reloadStats()
        }
    }
    
    /// Reset database (development/testing use)
    public func resetDatabase() {
        podStorage.resetDatabase()
        clearCache()
        Task {
            await reloadStats()
        }
    }
    
    /// Get database information
    public var databaseInfo: DatabaseInfo {
        return DatabaseInfo(
            size: podStorage.databaseFileSize,
            formattedSize: podStorage.formattedDatabaseSize,
            totalGames: getAllGames().count,
            lastBackup: lastRefresh
        )
    }
    
    // MARK: - Error Handling
    public func clearError() {
        error = nil
        podStorage.clearError()
    }
}




// MARK: - Convenience Extensions

public extension GameDataManager {
    func playrate(for name: String) -> Double? {
        guard self.commanderStats[name] != nil else {return nil}
        guard podSummaryStats.totalGames > 0 else {return nil}
        
        let plays = Double(self.commanderStats[name]!.games)
        let games = Double(podSummaryStats.totalGames)
        return plays/games
    }
    
    /// Check if any data is available
    var hasData: Bool {
        return !finalStates.isEmpty
    }
    
    /// Get system information including framework details
    var systemInfo: SystemInfo {
        return Podwork.shared.systemInfo
    }

    /// Create a binding for error display in SwiftUI
    var errorBinding: Binding<Bool> {
        Binding(
            get: { self.error != nil },
            set: { _ in self.clearError() }
        )
    }
}
