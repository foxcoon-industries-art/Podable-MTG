import Foundation

/// High-level storage manager that provides a clean API for game data persistence
@MainActor
public class PodStorageManager: ObservableObject {
    public static let shared = PodStorageManager()
    
    private let sqliteManager = SQLiteManager.shared
    private let fileManager = FileManager.default
    
    @Published public var isLoading = false
    @Published public var error: DataManagerError?
    
    private init() { initializeStorage() }
    
    // MARK: - Initialization
    
    private func initializeStorage() {
        do {
            sqliteManager.setupDatabase()
        } catch {
            self.error = DataManagerError.databaseSetupError(error.localizedDescription)
        }
    }
    
    // MARK: - Game Storage Methods - Retrieval
    
    /// Load all completed games from SQL storage
    @MainActor
    public func loadAllFinalPods() -> [FinalPod] {
        isLoading = true
        error = nil
        
        let finalStates = sqliteManager.loadAllFinalPods()
        if finalStates.isEmpty {  error = DataManagerError.noDataFound }
        isLoading = false
        
        return finalStates
    }
    
    /// Load games played within a specific date range
    public func loadPodsForYeeting() -> [(FinalPod,[Turn])] {
        let allGames = loadAllFinalPods()
        let gameIDs = allGames.compactMap(\.gameID)
        let pods = allGames.map { game in
            let turns = try! loadGameTurnHistory(gameID:game.gameID)
            return (game, turns )
        }
        return pods
    }
    
    @MainActor
    public func loadGameTurnHistory(gameID gameID : String) throws -> [Turn] {
        return try sqliteManager.loadGameTurnHistory(gameID: gameID)
    }
    

    
    // MARK: - Game Storage Methods - Saving
    
    /// Save a completed game to SQL storage
    public func saveFinalPod(_ finalState: FinalPod) {
        isLoading = true
        error = nil
        do {
            sqliteManager.saveFinalPod(finalState)
            print("✅ Game saved: \(finalState.gameID)")
        } catch {
            self.error = DataManagerError.saveError(error.localizedDescription)
            print("❌ [PodStorage] Failed to save game: \(error)")
        }
        isLoading = false
    }

    /// Update a completed game already stored in SQL.
    public func updateFinalPod(_ finalState: FinalPod) throws {
        isLoading = true
        error = nil

        do {
            try sqliteManager.updateFinalPod(finalState)
            print("✅ Game updated: \(finalState.gameID)")
        } catch {
            self.error = DataManagerError.saveError(error.localizedDescription)
            print("❌ [PodStorage] Failed to update game: \(error)")
            isLoading = false
            throw error
        }

        isLoading = false
    }
    
    
    // MARK: - Game Storage Methods - Retrieval of Stats from SQL

    /// Get comprehensive commander statistics
    public func getCommanderStatistics() -> [String: CommanderStatistics] {
        isLoading = true
        error = nil
        let stats = sqliteManager.getCommanderStatistics()
        if stats.isEmpty { error = DataManagerError.noStatisticsData }
        isLoading = false
        return stats
    }
    

    
    
    // MARK: - Game Storage Methods - Removal
    
    /// Delete a specific game
    //@MainActor
    public func deleteGame(gameID: String) {
        isLoading = true
        error = nil
        sqliteManager.deleteGame(gameID: gameID)
        isLoading = false
    }
    
    /// Clear all game data (use with caution)
    public func clearAllData() {
        isLoading = true
        error = nil
        sqliteManager.clearAllData()
        isLoading = false
    }
    
    /// Reset the entire database (development/testing use)
    public func resetDatabase() {
        isLoading = true
        error = nil
        sqliteManager.setupDatabase(reset: true)
        isLoading = false
    }
    
    // MARK: - Duel Match Storage

    public func loadAllDuelMatches() -> [FinalDuelMatch] {
        isLoading = true
        error = nil
        let matches = sqliteManager.loadAllDuelMatches()
        isLoading = false
        return matches
    }

    public func saveDuelMatch(_ match: FinalDuelMatch, turnHistories: [[DuelTurn]]) {
        isLoading = true
        error = nil
        do {
            try sqliteManager.saveDuelMatch(match, turnHistories: turnHistories)
            print("Duel match saved: \(match.matchID)")
        } catch {
            self.error = DataManagerError.saveError(error.localizedDescription)
            print("[PodStorage] Failed to save duel match: \(error)")
        }
        isLoading = false
    }

    public func deleteDuelMatch(matchID: String) {
        isLoading = true
        error = nil
        sqliteManager.deleteDuelMatch(matchID: matchID)
        isLoading = false
    }

    @MainActor
    public func loadDuelGameTurnHistory(matchID: String, gameNumber: Int) -> [DuelTurn] {
        return sqliteManager.loadDuelGameTurnHistory(matchID: matchID, gameNumber: gameNumber)
    }

    // MARK: - Tournament Storage

    public func saveTournamentRecord(_ record: TournamentRecord) {
        isLoading = true
        error = nil
        do {
            try sqliteManager.saveTournamentRecord(record)
            print("Tournament saved: \(record.tournamentID)")
        } catch {
            self.error = DataManagerError.saveError(error.localizedDescription)
            print("[PodStorage] Failed to save tournament: \(error)")
        }
        isLoading = false
    }

    public func loadAllTournaments() -> [TournamentRecord] {
        isLoading = true
        error = nil
        let tournaments = sqliteManager.loadAllTournaments()
        isLoading = false
        return tournaments
    }

    // MARK: - Export/Import - JSON
    
    /// Export all games to JSON format
    public func exportGamesToJSON() -> Data? {
        let allGames = loadAllFinalPods()
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            return try encoder.encode(allGames)
        } catch {
            self.error = DataManagerError.exportError(error.localizedDescription)
            return nil
        }
    }
    
    
    /// Import games from JSON data
    public func importGamesFromJSON(_ data: Data) -> ImportResult {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let games = try decoder.decode([FinalPod].self, from: data)
            
            var importedCount = 0
            var skippedCount = 0
            
            for game in games {
                // Check if game already exists
                let existingGames = loadAllFinalPods()
                if !existingGames.contains(where: { $0.gameID == game.gameID }) {
                    saveFinalPod(game)
                    importedCount += 1
                } else {
                    skippedCount += 1
                }
            }
            
            return ImportResult(
                imported: importedCount,
                skipped: skippedCount,
                errors: []
            )
        } catch {
            self.error = DataManagerError.importError(error.localizedDescription)
            return ImportResult(
                imported: 0,
                skipped: 0,
                errors: [error.localizedDescription]
            )
        }
    }
    
    // MARK: - Error Handling
    
    public func clearError() {
        error = nil
    }
}

// MARK: - Supporting Data Structures

public enum StorageError: LocalizedError {
    case databaseSetupError(String)
    case saveError(String)
    case loadError(String)
    case deleteError(String)
    case exportError(String)
    case importError(String)
    case noDataFound
    case noStatisticsData
    case invalidGameData(String)
    
    public var errorDescription: String? {
        switch self {
        case .databaseSetupError(let message):
            return "Database setup failed: \(message)"
        case .saveError(let message):
            return "Save failed: \(message)"
        case .loadError(let message):
            return "Load failed: \(message)"
        case .deleteError(let message):
            return "Delete failed: \(message)"
        case .exportError(let message):
            return "Export failed: \(message)"
        case .importError(let message):
            return "Import failed: \(message)"
        case .noDataFound:
            return "No game data found"
        case .noStatisticsData:
            return "No statistics data available"
        case .invalidGameData(let message):
            return "Invalid game data: \(message)"
        }
    }
}

public struct ImportResult {
    public let imported: Int
    public let skipped: Int
    public let errors: [String]
    
    public init(imported: Int, skipped: Int, errors: [String]) {
        self.imported = imported
        self.skipped = skipped
        self.errors = errors
    }
    
    public var isSuccess: Bool {
        return imported > 0 && errors.isEmpty
    }
    
    public var summary: String {
        var parts: [String] = []
        
        if imported > 0 {
            parts.append("\(imported) games imported")
        }
        
        if skipped > 0 {
            parts.append("\(skipped) games skipped (already exist)")
        }
        
        if !errors.isEmpty {
            parts.append("\(errors.count) errors")
        }
        
        return parts.joined(separator: ", ")
    }
}

// MARK: - File Storage Utilities

public extension PodStorageManager {
    /// Save exported data to device storage
    func saveExportedData(_ data: Data, filename: String) -> URL? {
        let documentsPath = FileManagerUtils.documentsDirectory()
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            self.error = DataManagerError.exportError(error.localizedDescription)
            return nil
        }
    }
    
    /// Load data from device storage for import
    func loadImportData(from url: URL) -> Data? {
        do {
            return try Data(contentsOf: url)
        } catch {
            self.error = DataManagerError.importError(error.localizedDescription)
            return nil
        }
    }
    
    /// Get the size of the database file
    var databaseFileSize: Int64 {
        let documentsPath = FileManagerUtils.documentsDirectory()
        let dbPath = documentsPath.appendingPathComponent("podwork.sqlite")
        
        do {
            let attributes = try fileManager.attributesOfItem(atPath: dbPath.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
    
    /// Get formatted database file size
    var formattedDatabaseSize: String {
        let size = databaseFileSize
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}


// MARK: - Supporting Data Structures

public struct DatabaseInfo {
    public let size: Int64
    public let formattedSize: String
    public let totalGames: Int
    public let lastBackup: Date
    
    public init(size: Int64, formattedSize: String, totalGames: Int, lastBackup: Date) {
        self.size = size
        self.formattedSize = formattedSize
        self.totalGames = totalGames
        self.lastBackup = lastBackup
    }
    
    public var summary: String {
        return """
        Database Size: \(formattedSize)
        Total Games: \(totalGames)
        Last Update: \(lastBackup.formattedString())
        """
    }
}
