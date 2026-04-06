import Foundation
import SQLite3

// MARK: - SQLite Error Handling

public enum SQLiteError: LocalizedError {
    case openDatabase(message: String)
    case prepare(message: String)
    case step(message: String)
    case bind(message: String)
    case query(message: String)
    case noDatabase
    
    public var errorDescription: String? {
        switch self {
        case .openDatabase(let message):
            return "Database opening failed: \(message)"
        case .prepare(let message):
            return "Statement preparation failed: \(message)" 
        case .step(let message):
            return "Statement execution failed: \(message)"
        case .bind(let message):
            return "Parameter binding failed: \(message)"
        case .query(let message):
            return "Query execution failed: \(message)"
        case .noDatabase:
            return "Database not initialized"
        }
    }
}





// MARK: - SQLite Database Wrapper

public class SQLiteDatabase {
    public var dbPointer: OpaquePointer?
    private var path: String = ""
    
    public var errorMessage: String {
        if let errorPointer = sqlite3_errmsg(dbPointer) {
            return String(cString: errorPointer)
        } else {
            return "No error message provided from sqlite."
        }
    }
    
    public init(path: String) throws {
        self.path = path
        var db: OpaquePointer?
        // 1 - Open the database
        if sqlite3_open(path, &db) == SQLITE_OK {
            // 2 - Success, save the database pointer
            dbPointer = db
            print("(INIT) 🚪 Successfully opened connection to database at \(path)")
            
            // ✅ Add PRAGMA here
            if sqlite3_exec(dbPointer, "PRAGMA foreign_keys = ON;", nil, nil, nil) == SQLITE_OK {
                print("✅ Foreign key constraints enabled")
            } else {
                print("❌ Failed to enable foreign key constraints: \(errorMessage)")
            }
        } else {
            // 3 - Failure, close the database connection to avoid memory leaks
            if let db = db {
                sqlite3_close(db)
            }
            dbPointer = nil
            throw SQLiteError.openDatabase(message: errorMessage)
        }
    }
    
    deinit {
        sqlite3_close(dbPointer)
    }
    
    public func prepareStatement(sql: String) throws -> OpaquePointer? {
        var statement: OpaquePointer?
        
        // 1 - Prepare the statement
        if sqlite3_prepare_v2(dbPointer, sql, -1, &statement, nil) == SQLITE_OK {
            // 2 - Success, return the prepared statement
            return statement
        } else {
            // 3 - Failure, throw an error
            throw SQLiteError.prepare(message: errorMessage)
        }
    }
    
    // Helper function to execute non-query SQL statements
    func execute(sql: String) throws {
        let statement = try prepareStatement(sql: sql)
        defer {
            sqlite3_finalize(statement)
        }
        
        // Execute the statement
        if sqlite3_step(statement) != SQLITE_DONE {
            throw SQLiteError.step(message: errorMessage)
        }
    }
}

// MARK: - SQLite Manager

//@MainActor
public class SQLiteManager: ObservableObject {
    @MainActor public static let shared = SQLiteManager()
    
    private var db: SQLiteDatabase?
    public var isInitialized: Bool { db != nil }
    

    
    private init() {
        setupDatabase()
    }
    
    public func setupDatabase(reset: Optional<Bool> = false) {

        let fileManager = FileManager.default
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let databasePath = documentsPath +  "/podable.sqlite"

        
        /// Check if database exists, if not create it
        if !fileManager.fileExists(atPath: databasePath) {
            do {
                /// Create a new database
                db = try SQLiteDatabase(path: databasePath)
                try resetDatabase()
                
        
                
                print("✅ Database created at: \(databasePath)")
            } catch {
                print("❌ Database creation failed: \(error)")
            }
        } else {
            /// Open existing database
            do {
                db = try SQLiteDatabase(path: databasePath)
                print("✅ Database opened at: \(databasePath)")

                guard let reset else {
                    throw SQLiteError.openDatabase(message: "Database not reset")
                }
                if reset{
                    do{
                        try resetDatabase()
                        print("🗑️ Database reset! \(databasePath)")
                        
                    } catch {
                        throw error
                    }
                }
            } catch {
                print("❌ Database setup failed: \(error)")
            }
       }
    }
    
    private func getDatabasePath() -> String {
        let fileManager = FileManager.default
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let databasePath = documentsPath +  "/podable.sqlite"
        return databasePath
    }
    

    
    // MARK: - Table Creation
    
    private func createTables() throws {
        guard let db = db else { throw SQLiteError.noDatabase }
        
        // Create games table
        let createGamesTable = """
            CREATE TABLE IF NOT EXISTS games (
                game_id TEXT PRIMARY KEY,
                date_played REAL NOT NULL,
                duration REAL NOT NULL,
                total_rounds INTEGER NOT NULL,
                win_method TEXT NOT NULL,
                winning_commander TEXT,
                winning_partner TEXT,
                winning_player_index INTEGER,
                date_added REAL NOT NULL DEFAULT (datetime('now'))
            );
            """
        
        // Create commanders table
        let createCommandersTable = """
            CREATE TABLE IF NOT EXISTS commanders (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                game_id TEXT NOT NULL,
                name TEXT NOT NULL,
                partner TEXT DEFAULT '',
                isPartner BOOLEAN DEFAULT FALSE,
                bracket_0 INTEGER DEFAULT 0,
                bracket_1 INTEGER DEFAULT 0,
                bracket_2 INTEGER DEFAULT 0,
                bracket_3 INTEGER DEFAULT 0,
                tax INTEGER DEFAULT 0,
                total_commander_damage INTEGER DEFAULT 0,
                turn_order INTEGER NOT NULL,
                winner BOOLEAN DEFAULT FALSE,
                eliminated BOOLEAN DEFAULT FALSE,
                elimination_round INTEGER,
                elimination_turn_id INTEGER,
                elimination_method INTEGER DEFAULT 7,
                average_turn_duration REAL DEFAULT 0,
                total_turn_time REAL DEFAULT 0,
                FOREIGN KEY (game_id) REFERENCES games (game_id) ON DELETE CASCADE
            );
            """
        
        // Create turn durations table
        let createTurnDurationsTable = """
            CREATE TABLE IF NOT EXISTS turn_durations (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                commander_id INTEGER NOT NULL,
                game_id TEXT NOT NULL,
                turn_number INTEGER NOT NULL,
                duration REAL NOT NULL,
                FOREIGN KEY (commander_id) REFERENCES commanders (id) ON DELETE CASCADE,
                FOREIGN KEY (game_id) REFERENCES games (game_id) ON DELETE CASCADE
            );
            """
        
        // Game turns table with proper cascade
        let createGameTurnsTable = """
            CREATE TABLE IF NOT EXISTS game_turns (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                game_id TEXT NOT NULL,
                turn_id INTEGER NOT NULL,
                active_player INTEGER NOT NULL,
                round_number INTEGER NOT NULL,
                life_total_0 INTEGER NOT NULL,
                life_total_1 INTEGER NOT NULL, 
                life_total_2 INTEGER NOT NULL,
                life_total_3 INTEGER NOT NULL,
                infect_total_0 INTEGER NOT NULL,
                infect_total_1 INTEGER NOT NULL,
                infect_total_2 INTEGER NOT NULL,
                infect_total_3 INTEGER NOT NULL,
                delta_life_0 INTEGER NOT NULL,
                delta_life_1 INTEGER NOT NULL,
                delta_life_2 INTEGER NOT NULL,
                delta_life_3 INTEGER NOT NULL,
                delta_infect_0 INTEGER NOT NULL,
                delta_infect_1 INTEGER NOT NULL,
                delta_infect_2 INTEGER NOT NULL,
                delta_infect_3 INTEGER NOT NULL,
                commander_damage_json TEXT NOT NULL DEFAULT '[[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]',
                partner_damage_json TEXT NOT NULL DEFAULT '[[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]',
                delta_commander_damage_json TEXT NOT NULL DEFAULT '[[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]',
                delta_partner_damage_json TEXT NOT NULL DEFAULT '[[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]',
                turn_started REAL NOT NULL,
                turn_ended REAL NOT NULL,
                turn_duration REAL NOT NULL,
                FOREIGN KEY (game_id) REFERENCES games (game_id) ON DELETE CASCADE
            );
            """
        
        
        // Create turn durations table
        let createSentPodPassTable = """
            CREATE TABLE IF NOT EXISTS sent_pod_passes (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                game_id TEXT NOT NULL,
                pod_pass BOOLEAN DEFAULT FALSE,
                status_code INTEGER NOT NULL,
                date_sent REAL NOT NULL DEFAULT (datetime('now'))
                FOREIGN KEY (game_id) REFERENCES games (game_id) ON DELETE CASCADE
            );
            """
        
        // MARK: - Duel Match Tables (60-Card Format)

        let createDuelMatchesTable = """
            CREATE TABLE IF NOT EXISTS duel_matches (
                match_id TEXT PRIMARY KEY,
                date_played REAL NOT NULL,
                total_duration REAL NOT NULL,
                player1_name TEXT NOT NULL DEFAULT '',
                player2_name TEXT NOT NULL DEFAULT '',
                player1_deck_tag TEXT NOT NULL DEFAULT '',
                player2_deck_tag TEXT NOT NULL DEFAULT '',
                player1_notes TEXT NOT NULL DEFAULT '',
                player2_notes TEXT NOT NULL DEFAULT '',
                match_score_p1 INTEGER NOT NULL DEFAULT 0,
                match_score_p2 INTEGER NOT NULL DEFAULT 0,
                match_winner INTEGER,
                tournament_id TEXT,
                date_added REAL NOT NULL DEFAULT (datetime('now'))
            );
            """

        let createDuelGamesTable = """
            CREATE TABLE IF NOT EXISTS duel_games (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                match_id TEXT NOT NULL,
                game_number INTEGER NOT NULL,
                winner_player_index INTEGER,
                final_life_p1 INTEGER NOT NULL DEFAULT 20,
                final_life_p2 INTEGER NOT NULL DEFAULT 20,
                final_infect_p1 INTEGER NOT NULL DEFAULT 0,
                final_infect_p2 INTEGER NOT NULL DEFAULT 0,
                turn_count INTEGER NOT NULL DEFAULT 0,
                mulligan_count_p1 INTEGER NOT NULL DEFAULT 0,
                mulligan_count_p2 INTEGER NOT NULL DEFAULT 0,
                first_player INTEGER NOT NULL DEFAULT 0,
                duration REAL NOT NULL DEFAULT 0,
                win_method TEXT NOT NULL DEFAULT '',
                date_played REAL NOT NULL,
                FOREIGN KEY (match_id) REFERENCES duel_matches (match_id) ON DELETE CASCADE
            );
            """

        let createDuelGameTurnsTable = """
            CREATE TABLE IF NOT EXISTS duel_game_turns (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                match_id TEXT NOT NULL,
                game_number INTEGER NOT NULL,
                turn_id INTEGER NOT NULL,
                active_player INTEGER NOT NULL,
                round_number INTEGER NOT NULL,
                life_total_0 INTEGER NOT NULL,
                life_total_1 INTEGER NOT NULL,
                infect_total_0 INTEGER NOT NULL,
                infect_total_1 INTEGER NOT NULL,
                delta_life_0 INTEGER NOT NULL,
                delta_life_1 INTEGER NOT NULL,
                delta_infect_0 INTEGER NOT NULL,
                delta_infect_1 INTEGER NOT NULL,
                turn_started REAL NOT NULL,
                turn_ended REAL NOT NULL,
                turn_duration REAL NOT NULL,
                FOREIGN KEY (match_id) REFERENCES duel_matches (match_id) ON DELETE CASCADE
            );
            """

        // MARK: - Tournament Tables

        let createTournamentsTable = """
            CREATE TABLE IF NOT EXISTS tournaments (
                tournament_id TEXT PRIMARY KEY,
                name TEXT NOT NULL DEFAULT '',
                code TEXT NOT NULL DEFAULT '',
                date_created REAL NOT NULL,
                date_ended REAL,
                player_count INTEGER NOT NULL DEFAULT 0,
                round_count INTEGER NOT NULL DEFAULT 0,
                status TEXT NOT NULL DEFAULT 'completed',
                final_standings_json TEXT
            );
            """

        let createTournamentEntriesTable = """
            CREATE TABLE IF NOT EXISTS tournament_entries (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                tournament_id TEXT NOT NULL,
                match_id TEXT,
                round_number INTEGER NOT NULL,
                player1_name TEXT NOT NULL DEFAULT '',
                player2_name TEXT NOT NULL DEFAULT '',
                result TEXT NOT NULL DEFAULT '',
                FOREIGN KEY (tournament_id) REFERENCES tournaments (tournament_id) ON DELETE CASCADE
            );
            """

        // Execute table creation
        try db.execute(sql: createGamesTable)
        try db.execute(sql: createCommandersTable)
        try db.execute(sql: createTurnDurationsTable)
        try db.execute(sql: createGameTurnsTable)
        try db.execute(sql: createSentPodPassTable)
        try db.execute(sql: createDuelMatchesTable)
        try db.execute(sql: createDuelGamesTable)
        try db.execute(sql: createDuelGameTurnsTable)
        try db.execute(sql: createTournamentsTable)
        try db.execute(sql: createTournamentEntriesTable)

        // Create indexes for performance
        let createIndexes = [
            "CREATE INDEX IF NOT EXISTS idx_games_date ON games (date_played);",
            "CREATE INDEX IF NOT EXISTS idx_commanders_game ON commanders (game_id);",
            "CREATE INDEX IF NOT EXISTS idx_commanders_name ON commanders (name);",
            "CREATE INDEX IF NOT EXISTS idx_commanders_winner ON commanders (winner);",
            "CREATE INDEX IF NOT EXISTS idx_turn_durations_commander ON turn_durations (commander_id);",
            "CREATE INDEX IF NOT EXISTS idx_game_turns_game ON game_turns (game_id);",
            "CREATE INDEX IF NOT EXISTS idx_game_turns_turn_id ON game_turns (turn_id);",
            "CREATE INDEX IF NOT EXISTS idx_game_pod_pass ON sent_pod_passes (game_id, pod_pass);",
            "CREATE INDEX IF NOT EXISTS idx_sent_pod_status ON sent_pod_passes (game_id, status_code);",
            "CREATE INDEX IF NOT EXISTS idx_sent_pod_date ON sent_pod_passes (game_id, date_sent);",
            "CREATE INDEX IF NOT EXISTS idx_duel_matches_date ON duel_matches (date_played);",
            "CREATE INDEX IF NOT EXISTS idx_duel_matches_tournament ON duel_matches (tournament_id);",
            "CREATE INDEX IF NOT EXISTS idx_duel_games_match ON duel_games (match_id);",
            "CREATE INDEX IF NOT EXISTS idx_duel_game_turns_match ON duel_game_turns (match_id);",
            "CREATE INDEX IF NOT EXISTS idx_tournaments_code ON tournaments (code);",
            "CREATE INDEX IF NOT EXISTS idx_tournament_entries_tournament ON tournament_entries (tournament_id);",
        ]
        
        for indexSql in createIndexes {
            try db.execute(sql: indexSql)
        }
        
        print("✅ Database tables and indexes created with proper cascades")
    }


    private func resetDatabase() throws {
        // Drop existing tables to ensure clean start
        try dropAllTables()
        // Create fresh tables
        try createTables()
    }
    
    func dropAllTables() throws {
        guard let db = db else { return }
        
        // Drop tables in correct order due to foreign key constraints
        let dropStatements = [
            "DROP TABLE IF EXISTS game_turns;",
            "DROP TABLE IF EXISTS turn_durations;",
            "DROP TABLE IF EXISTS commanders;",
            "DROP TABLE IF EXISTS games;",
            "DROP TABLE IF EXISTS sent_pod_passes;",
            "DROP TABLE IF EXISTS duel_game_turns;",
            "DROP TABLE IF EXISTS duel_games;",
            "DROP TABLE IF EXISTS duel_matches;",
            "DROP TABLE IF EXISTS tournament_entries;",
            "DROP TABLE IF EXISTS tournaments;"
        ]
        
        for statement in dropStatements {
            try db.execute(sql: statement)
        }
        
        print("🗑️ Dropped all existing tables")
    }

    // MARK: - Game Storage Methods
    
    
    
    
    
    /* ---------------------------------------------------------------------------------- */
    /* ---------------------------------------------------------------------------------- */
    // MARK: - Game Storage Methods (FinalPod)
    //@MainActor
    public func saveGame(_ finalState: FinalPod, podHistory: [Turn]) throws {
        guard let db = db else {
            throw SQLiteError.openDatabase(message: "Database not initialized")
        }
        
        guard gameExists(gameID: finalState.gameID) == false else {print("Game already exists in db. Skipping save."); return}
        
        print("Saving Final Pod to SQL:", finalState.gameID, "from", Thread.isMainThread ? "main" : "background")
        try self.saveFinalPod(finalState)
        
        print("Saving Pod Turns to SQL:", podHistory.count, "from", Thread.isMainThread ? "main" : "background")
        try self.saveGameTurnHistory(podHistory, gameID: finalState.gameID)
        
    }

    /* --------------------------- Check if Game is already saved --------------------------------- */

    public func gameExists(gameID: String) -> Bool {
        guard let db = db else { return false }
        
        let querySQL = "SELECT 1 FROM games WHERE game_id = ? LIMIT 1;"
        do {
            let stmt = try db.prepareStatement(sql: querySQL)
            defer { sqlite3_finalize(stmt) }
            sqlite3_bind_text(stmt, 1, (gameID as NSString).utf8String, -1, nil)
            
            if sqlite3_step(stmt) == SQLITE_ROW {
                return true // row exists
            } else {
                return false
            }
        } catch {
            print("❌ Error checking game exists: \(error)")
            return false
        }
    }
    
    
    /* -------------------------  Save FinalPod  -------------------------------------------- */
    /* -------------------------------------------------------------------------------------- */

    //@MainActor
    public func saveFinalPod(_ finalState: FinalPod) {
        do {
            guard let db = db else { throw SQLiteError.noDatabase }
            
            /// Begin transaction
            try db.execute(sql: "BEGIN TRANSACTION;")
            
            do {
                try insertFinalPod(finalState, db: db)
                print("final pod inserted: \(finalState.gameID)")

                for commander in finalState.commanders {
                    let commanderID = try insertCommander(commander, gameID: finalState.gameID, db: db)
                    try insertTurnDurations(commander.turnDurations, commanderID: commanderID, gameID: finalState.gameID, db: db)
                    print("CommanderID: \(commanderID) + Turn durations inserted. \(commander.turnDurations.count)")
                }
                
                /// Commit transaction
                try db.execute(sql: "COMMIT;")
                print("✅ Game saved to database: \(finalState.gameID)")
                
            } catch {
                /// Rollback on error
                try? db.execute(sql: "ROLLBACK;")
                print("❌ [SQL] Transaction failed: \(error)")
                throw error
            }
        } catch {
            print("❌ [SQL] Failed to save game: \(error)")
            print("finalState", finalState)
        }
    }

    public func updateFinalPod(_ finalState: FinalPod) throws {
        guard let db = db else {
            throw SQLiteError.openDatabase(message: "Database not initialized")
        }

        try db.execute(sql: "BEGIN TRANSACTION;")

        do {
            try updateGameRecord(finalState, db: db)

            for commander in storageCommanders(from: finalState.commanders) {
                try updateCommander(commander, gameID: finalState.gameID, db: db)
            }

            try db.execute(sql: "COMMIT;")
            print("✅ Game updated in database: \(finalState.gameID)")
        } catch {
            try? db.execute(sql: "ROLLBACK;")
            print("❌ [SQL] Failed to update game: \(error)")
            throw error
        }
    }
    
    /* ------------------------- Insert FinalPod  -------------------------------------------- */

    //@MainActor
    private func insertFinalPod(_ finalState: FinalPod, db: SQLiteDatabase) throws {
        let insertGame = """
        INSERT INTO games (
            game_id, date_played, duration, total_rounds, win_method, 
            winning_commander, winning_partner, winning_player_index, date_added
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        
        let statement = try db.prepareStatement(sql: insertGame)
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, (finalState.gameID as NSString).utf8String, -1, nil)
        sqlite3_bind_double(statement, 2, finalState.date.timeIntervalSince1970)
        sqlite3_bind_double(statement, 3, finalState.duration)
        sqlite3_bind_int(statement, 4, Int32(finalState.totalRounds))
        sqlite3_bind_text(statement, 5, (finalState.winMethod as NSString).utf8String, -1, nil)
        
        if let winningCommander = finalState.winningCommanderName {
            sqlite3_bind_text(statement, 6, (winningCommander as NSString).utf8String, -1, nil)
        } else {
            sqlite3_bind_null(statement, 6)
        }
        
        if let winningPartner = finalState.winningPartnerName {
            sqlite3_bind_text(statement, 7, (winningPartner as NSString).utf8String, -1, nil)
        } else {
            sqlite3_bind_null(statement, 7)
        }
        
        if let winningPlayerIndex = finalState.winningPlayerIndex {
            sqlite3_bind_int(statement, 8, Int32(winningPlayerIndex))
        } else {
            sqlite3_bind_null(statement, 8)
        }
        
        sqlite3_bind_double(statement, 9, Date().timeIntervalSince1970)
        
        if sqlite3_step(statement) != SQLITE_DONE {
            throw SQLiteError.step(message: db.errorMessage)
        }
    }

    private func updateGameRecord(_ finalState: FinalPod, db: SQLiteDatabase) throws {
        let updateSQL = """
        UPDATE games
        SET date_played = ?,
            duration = ?,
            total_rounds = ?,
            win_method = ?,
            winning_commander = ?,
            winning_partner = ?,
            winning_player_index = ?
        WHERE game_id = ?;
        """

        let statement = try db.prepareStatement(sql: updateSQL)
        defer { sqlite3_finalize(statement) }

        let winningCommander = finalState.commanders.first { $0.winner }
        let winningPartner = winningCommander?.partner
            .trimmingCharacters(in: .whitespacesAndNewlines)

        sqlite3_bind_double(statement, 1, finalState.date.timeIntervalSince1970)
        sqlite3_bind_double(statement, 2, finalState.duration)
        sqlite3_bind_int(statement, 3, Int32(finalState.totalRounds))
        sqlite3_bind_text(statement, 4, (finalState.winMethod as NSString).utf8String, -1, nil)

        if let winningCommanderName = winningCommander?.name {
            sqlite3_bind_text(statement, 5, (winningCommanderName as NSString).utf8String, -1, nil)
        } else {
            sqlite3_bind_null(statement, 5)
        }

        if let winningPartner, winningPartner.isEmpty == false {
            sqlite3_bind_text(statement, 6, (winningPartner as NSString).utf8String, -1, nil)
        } else {
            sqlite3_bind_null(statement, 6)
        }

        if let winningPlayerIndex = finalState.winningPlayerIndex {
            sqlite3_bind_int(statement, 7, Int32(winningPlayerIndex))
        } else {
            sqlite3_bind_null(statement, 7)
        }

        sqlite3_bind_text(statement, 8, (finalState.gameID as NSString).utf8String, -1, nil)

        if sqlite3_step(statement) != SQLITE_DONE {
            throw SQLiteError.step(message: db.errorMessage)
        }

        if sqlite3_changes(db.dbPointer) == 0 {
            throw SQLiteError.query(message: "No game row found for update: \(finalState.gameID)")
        }
    }

    private func updateCommander(_ commander: Commander, gameID: String, db: SQLiteDatabase) throws {
        let updateSQL = """
        UPDATE commanders
        SET name = ?,
            partner = ?,
            bracket_0 = ?,
            bracket_1 = ?,
            bracket_2 = ?,
            bracket_3 = ?,
            tax = ?,
            total_commander_damage = ?,
            winner = ?,
            eliminated = ?,
            elimination_round = ?,
            elimination_turn_id = ?,
            elimination_method = ?,
            average_turn_duration = ?,
            total_turn_time = ?
        WHERE game_id = ? AND turn_order = ? AND isPartner = ?;
        """

        let statement = try db.prepareStatement(sql: updateSQL)
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_text(statement, 1, (commander.name as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 2, (commander.partner as NSString).utf8String, -1, nil)

        for index in 0..<4 {
            let bracketValue = index < commander.bracket.count ? commander.bracket[index] : 0
            sqlite3_bind_int(statement, Int32(3 + index), Int32(bracketValue))
        }

        sqlite3_bind_int(statement, 7, Int32(commander.tax))
        sqlite3_bind_int(statement, 8, Int32(commander.totalCommanderDamage))
        sqlite3_bind_int(statement, 9, commander.winner ? 1 : 0)
        sqlite3_bind_int(statement, 10, commander.eliminated ? 1 : 0)

        if let eliminationRound = commander.eliminationRound {
            sqlite3_bind_int(statement, 11, Int32(eliminationRound))
        } else {
            sqlite3_bind_null(statement, 11)
        }

        if let eliminationTurnID = commander.eliminationTurnID {
            sqlite3_bind_int(statement, 12, Int32(eliminationTurnID))
        } else {
            sqlite3_bind_null(statement, 12)
        }

        sqlite3_bind_int(statement, 13, Int32(commander.eliminationMethod.rawValue))
        sqlite3_bind_double(statement, 14, commander.averageTurnDuration)
        sqlite3_bind_double(statement, 15, commander.totalTurnTime)
        sqlite3_bind_text(statement, 16, (gameID as NSString).utf8String, -1, nil)
        sqlite3_bind_int(statement, 17, Int32(commander.turnOrder))
        sqlite3_bind_int(statement, 18, commander.isPartner ? 1 : 0)

        if sqlite3_step(statement) != SQLITE_DONE {
            throw SQLiteError.step(message: db.errorMessage)
        }

        if sqlite3_changes(db.dbPointer) == 0 {
            throw SQLiteError.query(
                message: "No commander row found for update in game \(gameID), turn order \(commander.turnOrder), partner \(commander.isPartner)"
            )
        }
    }

    private func storageCommanders(from commanders: [Commander]) -> [Commander] {
        commanders
            .rePartner
            .sorted { lhs, rhs in lhs.turnOrder < rhs.turnOrder }
            .flatMap { commander -> [Commander] in
                var normalized: [Commander] = [
                    Commander(
                        name: commander.name,
                        partner: commander.partner,
                        isPartner: false,
                        bracket: commander.bracket,
                        tax: commander.tax,
                        totalCommanderDamage: commander.totalCommanderDamage,
                        turnOrder: commander.turnOrder,
                        turnDurations: commander.turnDurations,
                        winner: commander.winner,
                        eliminated: commander.eliminated,
                        eliminationRound: commander.eliminationRound,
                        eliminationTurnID: commander.eliminationTurnID,
                        eliminationMethod: commander.eliminationMethod
                    )
                ]

                let partnerName = commander.partner.trimmingCharacters(in: .whitespacesAndNewlines)
                if partnerName.isEmpty == false {
                    normalized.append(
                        Commander(
                            name: partnerName,
                            partner: commander.name,
                            isPartner: true,
                            bracket: commander.bracket,
                            tax: commander.partnerTax ?? 0,
                            totalCommanderDamage: commander.totalPartnerDamage ?? 0,
                            turnOrder: commander.turnOrder,
                            turnDurations: commander.turnDurations,
                            winner: commander.winner,
                            eliminated: commander.eliminated,
                            eliminationRound: commander.eliminationRound,
                            eliminationTurnID: commander.eliminationTurnID,
                            eliminationMethod: commander.eliminationMethod
                        )
                    )
                }

                return normalized
            }
            .sorted { lhs, rhs in
                if lhs.turnOrder == rhs.turnOrder {
                    return lhs.isPartner == false && rhs.isPartner == true
                }
                return lhs.turnOrder < rhs.turnOrder
            }
    }
    
    
    

    /* ------------------------- Save Commander  -------------------------------------------- */
    //@MainActor
    private func insertCommander(_ commander: Commander, gameID: String, db: SQLiteDatabase) throws -> Int64 {
        let insertCommander = """
        INSERT INTO commanders (
            game_id, name, partner, isPartner, 
            bracket_0, bracket_1, bracket_2, bracket_3,
            tax, total_commander_damage, turn_order, winner, 
            eliminated, elimination_round, elimination_turn_id, elimination_method, 
            average_turn_duration, total_turn_time
        ) VALUES (?, ?, ?, ?,
        ?, ?, ?, ?,
        ?, ?, ?, ?,
        ?, ?, ?, ?,
        ?, ?);
        """
        
        dump(commander)
        let statement = try db.prepareStatement(sql: insertCommander)
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, (gameID as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 2, (commander.name as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 3, (commander.partner as NSString).utf8String, -1, nil)
        sqlite3_bind_int(statement, 4, commander.isPartner ? 1 : 0)

        // Bind bracket values
        for i in 0..<4 {
            let bracketValue = i < commander.bracket.count ? commander.bracket[i] : 0
            sqlite3_bind_int(statement, Int32(5 + i), Int32(bracketValue))
        }
        
        sqlite3_bind_int(statement, 9, Int32(commander.tax))
        sqlite3_bind_int(statement, 10, Int32(commander.totalCommanderDamage))
        sqlite3_bind_int(statement, 11, Int32(commander.turnOrder))
        sqlite3_bind_int(statement, 12, commander.winner ? 1 : 0)
        sqlite3_bind_int(statement, 13, commander.eliminated ? 1 : 0)
        
        if let eliminationRound = commander.eliminationRound {
            sqlite3_bind_int(statement, 14, Int32(eliminationRound))
        } else {
            sqlite3_bind_null(statement, 14)
        }

        if let eliminationTurnID = commander.eliminationTurnID {
            sqlite3_bind_int(statement, 15, Int32(eliminationTurnID))
        } else {
            sqlite3_bind_null(statement, 15)
        }
        
        sqlite3_bind_int(statement, 16, Int32(commander.eliminationMethod.rawValue))
        sqlite3_bind_double(statement, 17, commander.averageTurnDuration)
        sqlite3_bind_double(statement, 18, commander.totalTurnTime)
        sqlite3_bind_int(statement, 19, commander.isPartner ? 1 : 0)

        
        if sqlite3_step(statement) != SQLITE_DONE {
            throw SQLiteError.step(message: db.errorMessage)
        }
        
        return sqlite3_last_insert_rowid(db.dbPointer)
    }
    

        
    
    
    /* ------------------------- Insert TurnDuration  -------------------------------------------- */
    //@MainActor
    private func insertTurnDurations(_ turnDurations: [TimeInterval], commanderID: Int64, gameID: String, db: SQLiteDatabase) throws {
        let insertSQL = """
        INSERT INTO turn_durations (commander_id, game_id, turn_number, duration)
        VALUES (?, ?, ?, ?);
        """
        
        
        dump(turnDurations)
        for (turnNumber, duration) in turnDurations.enumerated() {
            let statement = try db.prepareStatement(sql: insertSQL)
            defer { sqlite3_finalize(statement) }
            
            sqlite3_bind_int64(statement, 1, commanderID)
            sqlite3_bind_text(statement, 2, (gameID as NSString).utf8String, -1, nil)
            sqlite3_bind_int(statement, 3, Int32(turnNumber))
            sqlite3_bind_double(statement, 4, duration)
            
            if sqlite3_step(statement) != SQLITE_DONE {
                throw SQLiteError.step(message: db.errorMessage)
            }
        }
    }
    
    
    /* ------------------------- Save Turns  -------------------------------------------- */
    /* ---------------------------------------------------------------------------------- */
    //@MainActor
    public func saveGameTurnHistory(_ podHistory: [Turn], gameID: String) throws {
        guard let db = db else {
            throw SQLiteError.openDatabase(message: "Database not initialized")
        }
        
        try db.execute(sql: "BEGIN TRANSACTION;")
        
        do {
            for turn in podHistory {
                try insertGameTurn(turn, gameID: gameID, db: db)
            }
            
            try db.execute(sql: "COMMIT;")
            print("✅ Game turn history saved for gameID: \(gameID)")
            
        } catch {
            print(" - Failed in - Save Game Turn History -to-> db")
            try? db.execute(sql: "ROLLBACK;")
            throw error
        }
    }
    
    /* ------------------------- Insert Turn  -------------------------------------------- */
    
    //@MainActor
    private func insertGameTurn(_ turn: Turn, gameID: String, db: SQLiteDatabase) throws {
        // Convert commander damage arrays to JSON with better error handling
        
        dump(turn)
        let cmdrDamageData: Data
        let deltaCmdrDamageData: Data
        
        let prtnrDamageData: Data
        let deltaPrtnrDamageData: Data
        
        do {
            cmdrDamageData = try JSONSerialization.data(withJSONObject: turn.cmdrDmgTotal, options: [])
            deltaCmdrDamageData = try JSONSerialization.data(withJSONObject: turn.deltaCmdrDamage, options: [])
            
            prtnrDamageData = try JSONSerialization.data(withJSONObject: turn.prtnrDmgTotal, options: [])
            deltaPrtnrDamageData = try JSONSerialization.data(withJSONObject: turn.deltaPrtnrDamage, options: [])
        } catch {
            print("❌ JSON serialization error: \(error)")
            throw SQLiteError.query(message: "Failed to serialize commander damage data")
        }
        
        let cmdrDamageJSON = String(data: cmdrDamageData, encoding: .utf8) ?? "[[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]"
        let prtnrDamageJSON = String(data: prtnrDamageData, encoding: .utf8) ?? "[[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]"
        let deltaCmdrDamageJSON = String(data: deltaCmdrDamageData, encoding: .utf8) ?? "[[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]"
        let deltaPrtnrDamageJSON = String(data: deltaPrtnrDamageData, encoding: .utf8) ?? "[[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]"
        
        let insertTurn = """
        INSERT INTO game_turns (
            game_id, turn_id, active_player, round_number,
            life_total_0, life_total_1, life_total_2, life_total_3,
            infect_total_0, infect_total_1, infect_total_2, infect_total_3,
            delta_life_0, delta_life_1, delta_life_2, delta_life_3,
            delta_infect_0, delta_infect_1, delta_infect_2, delta_infect_3,
            commander_damage_json, partner_damage_json, 
            delta_commander_damage_json, delta_partner_damage_json,
            turn_started, turn_ended, turn_duration
        ) VALUES (
        ?, ?, ?, ?,
        ?, ?, ?, ?,
        ?, ?, ?, ?,
        ?, ?, ?, ?,
        ?, ?, ?, ?,
        ?, ?,
        ?, ?,
        ?, ?, ?);
        """
        
        let statement = try db.prepareStatement(sql: insertTurn)
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, (gameID as NSString).utf8String, -1, nil)
        sqlite3_bind_int(statement, 2, Int32(turn.id))
        sqlite3_bind_int(statement, 3, Int32(turn.activePlayer))
        sqlite3_bind_int(statement, 4, Int32(turn.round))
        
        // Bind life totals (ensuring we have at least 4 values)
        for i in 0..<4 {
            let lifeValue = i < turn.lifeTotal.count ? turn.lifeTotal[i] : 0
            sqlite3_bind_int(statement, Int32(5 + i), Int32(lifeValue))
        }
        
        // Bind infect totals
        for i in 0..<4 {
            let infectValue = i < turn.infectTotal.count ? turn.infectTotal[i] : 0
            sqlite3_bind_int(statement, Int32(9 + i), Int32(infectValue))
        }
        
        // Bind delta life
        for i in 0..<4 {
            let deltaLifeValue = i < turn.deltaLife.count ? turn.deltaLife[i] : 0
            sqlite3_bind_int(statement, Int32(13 + i), Int32(deltaLifeValue))
        }
        
        // Bind delta infect
        for i in 0..<4 {
            let deltaInfectValue = i < turn.deltaInfect.count ? turn.deltaInfect[i] : 0
            sqlite3_bind_int(statement, Int32(17 + i), Int32(deltaInfectValue))
        }
        
        // Bind JSON strings
        sqlite3_bind_text(statement, 21, (cmdrDamageJSON as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 22, (prtnrDamageJSON as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 23, (deltaCmdrDamageJSON as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 24, (deltaPrtnrDamageJSON as NSString).utf8String, -1, nil)
        
        // Bind timestamps
        // 25 = turn start
        // 26 = turn end
        // 27 = turn duration
        sqlite3_bind_double(statement, 25, turn.whenTurnEnded.timeIntervalSince1970 - turn.turnDuration)
        sqlite3_bind_double(statement, 26, turn.whenTurnEnded.timeIntervalSince1970)
        sqlite3_bind_double(statement, 27, turn.turnDuration)
        
        if sqlite3_step(statement) != SQLITE_DONE {
            throw SQLiteError.step(message: "Failed to insert Turn into DB: \(db.errorMessage)")
        }
    }
    
    /* ------------------------- Insert SentPodPasses  -------------------------------------------- */
    //@MainActor
    private func insertSentPodPass(gameID: String, podPass: Bool, statusCode: Int, date: Date? = nil, db: SQLiteDatabase) throws {
        let insertSQL = """
        INSERT INTO turn_durations ( game_id, pod_pass, status_code, date_sent)
        VALUES (?, ?, ?, ?);
        """
        
        let statement = try db.prepareStatement(sql: insertSQL)
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, (gameID as NSString).utf8String, -1, nil)
        sqlite3_bind_int(statement, 2, podPass ? 1 : 0)
        sqlite3_bind_int(statement, 3, Int32(statusCode))
        if let date = date {
            sqlite3_bind_double(statement, 4, date.timeIntervalSince1970)
        } else {
            sqlite3_bind_double(statement, 4, Date.now.timeIntervalSince1970)
        }
        
        if sqlite3_step(statement) != SQLITE_DONE {
            throw SQLiteError.step(message: db.errorMessage)
        }
    
    }
    
    
    
    /* -------------------------  Load FinalPods  -------------------------------------------- */
    public func loadAllFinalPods() -> [FinalPod] {
        do {
            guard let db = db else { throw SQLiteError.noDatabase }
            
            var finalStates: [FinalPod] = []
            
            let querySQL = """
            SELECT game_id, date_played, duration, total_rounds, win_method,
                   winning_commander, winning_partner, winning_player_index
            FROM games
            ORDER BY date_played DESC;
            """
            
            let statement = try db.prepareStatement(sql: querySQL)
            defer { sqlite3_finalize(statement) }
            
            while sqlite3_step(statement) == SQLITE_ROW {
                let gameID = String(cString: sqlite3_column_text(statement, 0))
                let datePlayed = Date(timeIntervalSince1970: sqlite3_column_double(statement, 1))
                let duration = sqlite3_column_double(statement, 2)
                let totalRounds = Int(sqlite3_column_int(statement, 3))
                //let winMethod = String(cString: sqlite3_column_text(statement, 4))
                let winMethod = sqlite3_column_text(statement, 4).flatMap { String(cString: $0) } ?? "unknown"
                
                let commanders = try loadCommanders(for: gameID)
                
                let finalState = FinalPod(
                    gameID: gameID,
                    date: datePlayed,
                    duration: duration,
                    commanders: commanders,
                    totalRounds: totalRounds,
                    winMethod: winMethod,
                )
                
                finalStates.append(finalState)
            }
            
            
            let pod_ids = finalStates.map {$0.gameID}
            print(pod_ids)
            return finalStates
        } catch {
            print("❌ Failed to load games: \(error)")
            return []
        }
    }
    
    /* ------------------------- Load Commanders  -------------------------------------------- */
    
    private func loadCommanders(for gameID: String) throws -> [Commander] {
        guard let db = db else { throw SQLiteError.noDatabase }
        
        var commanders: [Commander] = []
        
        let queryCommanders = """
        SELECT id, name, partner, isPartner, bracket_0, bracket_1, bracket_2, bracket_3,
               tax, total_commander_damage, turn_order, winner, eliminated,
               elimination_round, elimination_turn_id,  elimination_method, average_turn_duration, total_turn_time
        FROM commanders
        WHERE game_id = ?
        ORDER BY turn_order;
        """
        
        let statement = try db.prepareStatement(sql: queryCommanders)
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, (gameID as NSString).utf8String, -1, nil)
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let commanderID = sqlite3_column_int64(statement, 0)
            let name = String(cString: sqlite3_column_text(statement, 1))
            let partner = String(cString: sqlite3_column_text(statement, 2))
            let isPartner = sqlite3_column_int(statement, 3) == 1
            
            
            let bracket = [
                Int(sqlite3_column_int(statement, 4)),
                Int(sqlite3_column_int(statement, 5)),
                Int(sqlite3_column_int(statement, 6)),
                Int(sqlite3_column_int(statement, 7))
            ]
            
            let tax = Int(sqlite3_column_int(statement, 8))
            let totalCommanderDamage = Int(sqlite3_column_int(statement, 9))
            let turnOrder = Int(sqlite3_column_int(statement, 10))
            let winner = sqlite3_column_int(statement, 11) == 1
            let eliminated = sqlite3_column_int(statement, 12) == 1
            
            let eliminationRound: Int? = sqlite3_column_type(statement, 13) == SQLITE_NULL ?
            nil : Int(sqlite3_column_int(statement, 13))
            
            let eliminationTurnID: Int? = sqlite3_column_type(statement, 14) == SQLITE_NULL ?
            nil : Int(sqlite3_column_int(statement, 14))
            
            let eliminationMethod = EliminationMethod(rawValue: Int(sqlite3_column_int(statement, 15))) ?? .notEliminated
            
            let turnDurations = try loadTurnDurations(for: commanderID)
            
            let commander = Commander(
                name: name,
                partner: partner,
                isPartner: isPartner,
                bracket: bracket,
                tax: tax,
                totalCommanderDamage: totalCommanderDamage,
                turnOrder: turnOrder,
                turnDurations: turnDurations,
                winner: winner,
                eliminated: eliminated,
                eliminationRound: eliminationRound,
                eliminationTurnID: eliminationTurnID,
                eliminationMethod: eliminationMethod
            )
            
            commanders.append(commander)
        }
        
        let repartneredCommanders = commanders.rePartner
        return repartneredCommanders
    }
    
    
    /* ------------------------- Load TurnDuration  -------------------------------------------- */
    private func loadTurnDurations(for commanderID: Int64) throws -> [TimeInterval] {
        guard let db = db else { throw SQLiteError.noDatabase }
        
        var turnDurations: [TimeInterval] = []
        
        let queryTurnDurations = """
        SELECT duration
        FROM turn_durations
        WHERE commander_id = ?
        ORDER BY turn_number;
        """
        
        let statement = try db.prepareStatement(sql: queryTurnDurations)
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_int64(statement, 1, commanderID)
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let duration = sqlite3_column_double(statement, 0)
            turnDurations.append(duration)
        }
        
        return turnDurations
    }
    
    // * ------------------------- Load SentPodPass  -------------------------------------------- */
    private func loadPassPods(gameID: String) throws -> Bool {
        guard let db = db else { throw SQLiteError.noDatabase }
        
        var turnDurations: [TimeInterval] = []
        
        let querySentPodPasses = """
        SELECT pod_pass
        FROM sent_pod_passes
        WHERE game_id = ?
        ORDER BY date_sent;
        """
        
        let statement = try db.prepareStatement(sql: querySentPodPasses)
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, (gameID as NSString).utf8String, -1, nil)

        let podPass = sqlite3_column_int(statement, 2) == 1

        return podPass
    }
    
    
    /* -------------------------  Load Turns  -------------------------------------------- */
    public func loadGameTurnHistory(gameID: String) throws -> [Turn] {
        guard let db = db else {
            throw SQLiteError.openDatabase(message: "Database not initialized")
        }
        
        var turns: [Turn] = []
        
        let queryTurns = """
        SELECT turn_id, active_player, round_number,
               life_total_0, life_total_1, life_total_2, life_total_3,
               infect_total_0, infect_total_1, infect_total_2, infect_total_3,
               delta_life_0, delta_life_1, delta_life_2, delta_life_3,
               delta_infect_0, delta_infect_1, delta_infect_2, delta_infect_3,
               commander_damage_json, partner_damage_json, 
               delta_commander_damage_json, delta_partner_damage_json,
               turn_started, turn_ended, turn_duration
        FROM game_turns
        WHERE game_id = ?
        ORDER BY turn_id;
        """
        
        let statement = try db.prepareStatement(sql: queryTurns)
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, (gameID as NSString).utf8String, -1, nil)
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let turnId = Int(sqlite3_column_int(statement, 0))
            let activePlayer = Int(sqlite3_column_int(statement, 1))
            let round = Int(sqlite3_column_int(statement, 2))
            
            // Life totals
            let lifeTotal = [
                Int(sqlite3_column_int(statement, 3)),
                Int(sqlite3_column_int(statement, 4)),
                Int(sqlite3_column_int(statement, 5)),
                Int(sqlite3_column_int(statement, 6))
            ]
            
            // Infect totals
            let infectTotal = [
                Int(sqlite3_column_int(statement, 7)),
                Int(sqlite3_column_int(statement, 8)),
                Int(sqlite3_column_int(statement, 9)),
                Int(sqlite3_column_int(statement, 10))
            ]
            
            // Delta life
            let deltaLife = [
                Int(sqlite3_column_int(statement, 11)),
                Int(sqlite3_column_int(statement, 12)),
                Int(sqlite3_column_int(statement, 13)),
                Int(sqlite3_column_int(statement, 14))
            ]
            
            // Delta infect
            let deltaInfect = [
                Int(sqlite3_column_int(statement, 15)),
                Int(sqlite3_column_int(statement, 16)),
                Int(sqlite3_column_int(statement, 17)),
                Int(sqlite3_column_int(statement, 18))
            ]
            
            // Fixed JSON handling with better error checking
            let cmdrDamageTotal: [[Int]]
            let prtnrDamageTotal: [[Int]]
            let deltaCmdrDamage: [[Int]]
            let deltaPrtnrDamage: [[Int]]
            
            // Get JSON strings safely
            if let cmdrDamagePtr = sqlite3_column_text(statement, 19) {
                let commanderDamageJSONString = String(cString: cmdrDamagePtr)
                if let data = commanderDamageJSONString.data(using: .utf8),
                   let parsed = try? JSONSerialization.jsonObject(with: data, options: []) as? [[Int]] {
                    cmdrDamageTotal = parsed
                } else {
                    print("⚠️ Failed to parse commander damage JSON, using default")
                    cmdrDamageTotal = [[0,0,0,0], [0,0,0,0], [0,0,0,0], [0,0,0,0]]
                }
            } else {
                cmdrDamageTotal = [[0,0,0,0], [0,0,0,0], [0,0,0,0], [0,0,0,0]]
            }
            
            if let prtnrDamagePtr = sqlite3_column_text(statement, 20) {
                let partnerDamageJSONString = String(cString: prtnrDamagePtr)
                if let data = partnerDamageJSONString.data(using: .utf8),
                   let parsed = try? JSONSerialization.jsonObject(with: data, options: []) as? [[Int]] {
                    prtnrDamageTotal = parsed
                } else {
                    print("⚠️ Failed to parse commander damage JSON, using default")
                    prtnrDamageTotal = [[0,0,0,0], [0,0,0,0], [0,0,0,0], [0,0,0,0]]
                }
            } else {
                prtnrDamageTotal = [[0,0,0,0], [0,0,0,0], [0,0,0,0], [0,0,0,0]]
            }
            
            if let deltaCmdrPtr = sqlite3_column_text(statement, 21) {
                let deltaCommanderDamageJSONString = String(cString: deltaCmdrPtr)
                if let data = deltaCommanderDamageJSONString.data(using: .utf8),
                   let parsed = try? JSONSerialization.jsonObject(with: data, options: []) as? [[Int]] {
                    deltaCmdrDamage = parsed
                } else {
                    print("⚠️ Failed to parse delta commander damage JSON, using default")
                    deltaCmdrDamage = [[0,0,0,0], [0,0,0,0], [0,0,0,0], [0,0,0,0]]
                }
            } else {
                deltaCmdrDamage = [[0,0,0,0], [0,0,0,0], [0,0,0,0], [0,0,0,0]]
            }
            
            if let deltaPrtnrPtr = sqlite3_column_text(statement, 22) {
                let deltaPartnerDamageJSONString = String(cString: deltaPrtnrPtr)
                if let data = deltaPartnerDamageJSONString.data(using: .utf8),
                   let parsed = try? JSONSerialization.jsonObject(with: data, options: []) as? [[Int]] {
                    deltaPrtnrDamage = parsed
                } else {
                    print("⚠️ Failed to parse delta commander damage JSON, using default")
                    deltaPrtnrDamage = [[0,0,0,0], [0,0,0,0], [0,0,0,0], [0,0,0,0]]
                }
            } else {
                deltaPrtnrDamage = [[0,0,0,0], [0,0,0,0], [0,0,0,0], [0,0,0,0]]
            }

            let turnStart = Date(timeIntervalSince1970: sqlite3_column_double(statement, 23))
            let turnEnded = Date(timeIntervalSince1970: sqlite3_column_double(statement, 24))
            let turnDuration = sqlite3_column_double(statement, 25)
            
            // Create turn with proper initialization
            var turn = Turn(
                activePlayer: activePlayer,
                id: turnId,
                round: round,
                deltaLife: deltaLife,
                deltaInfect: deltaInfect,
                whenTurnEnded: turnEnded,
                deltaCmdrDamage: deltaCmdrDamage,
                deltaPrtnrDamage: deltaPrtnrDamage,
                lifeTotal: lifeTotal,
                infectTotal: infectTotal,
                cmdrDmgTotal: cmdrDamageTotal,
                prtnrDmgTotal: prtnrDamageTotal
            )
            
            // Set turn duration manually if needed
            turn.turnDuration = turnDuration
            
            turns.append(turn)
        }
        //turns.map { print($0, "\n") }
        
        return turns
    }
    
    
    
    // MARK: - Statistics Queries
    
    
    /*  SELECT c1.name AS commander, c2.name AS partner,
     COUNT(*) AS games_played,
     SUM(c1.winner OR c2.winner) AS team_wins
     FROM commanders c1
     JOIN commander_partners cp ON c1.id = cp.commander_id
     JOIN commanders c2 ON cp.partner_id = c2.id
     GROUP BY c1.name, c2.name;
     */
    
    
    public func getCommanderStatistics() -> [String: CommanderStatistics] {
        do {
            guard let db = db else { throw SQLiteError.noDatabase }
            
            var stats: [String: CommanderStatistics] = [:]
            
            let querySQL = """
            SELECT 
                c.name,
                COUNT(*) as games_played,
                SUM(CASE WHEN c.winner = 1 THEN 1 ELSE 0 END) as wins,
                AVG(g.total_rounds) as avg_game_length,
                AVG(c.average_turn_duration) as avg_turn_duration,
                SUM(c.total_commander_damage) as total_damage_dealt,
                AVG(c.tax) as avg_tax_paid,
                SUM(CASE WHEN c.eliminated = 1 THEN 1 ELSE 0 END) as times_eliminated,
                AVG(CASE WHEN c.winner = 0 AND c.eliminated = 0 THEN 1 ELSE 0 END) as survive_rate,
                SUM(c.tax) as total_tax
            FROM commanders c
            JOIN games g ON c.game_id = g.game_id
            GROUP BY c.name
            HAVING games_played > 0
            ORDER BY wins DESC, games_played DESC;
            """
            
            let statement = try db.prepareStatement(sql: querySQL)
            defer { sqlite3_finalize(statement) }
            
            while sqlite3_step(statement) == SQLITE_ROW {
                let commanderName = String(cString: sqlite3_column_text(statement, 0))
                let gamesPlayed = Int(sqlite3_column_int(statement, 1))
                let wins = Int(sqlite3_column_int(statement, 2))
                let avgGameLength = sqlite3_column_double(statement, 3)
                let avgTurnDuration = sqlite3_column_double(statement, 4)
                let totalDamageDealt = Int(sqlite3_column_int(statement, 5))
                let avgTaxPaid = sqlite3_column_double(statement, 6)
                let timesEliminated = Int(sqlite3_column_int(statement, 7))
                let totalTax = Int(sqlite3_column_int(statement, 8))
                
                let commanderStats = CommanderStatistics(
                    name: commanderName,
                    gamesPlayed: gamesPlayed,
                    wins: wins,
                    avgGameLength: avgGameLength,
                    avgTurnDuration: avgTurnDuration,
                    totalCommanderDamageDealt: totalDamageDealt,
                    avgTaxPaid: avgTaxPaid,
                    timesEliminated: timesEliminated,
                    totalTax: totalTax
                )
                
                stats[commanderName] = commanderStats
            }
            
            return stats
        } catch {
            print("❌ Failed to load commander statistics: \(error)")
            return [:]
        }
    }
    
    // MARK: - Data Management
    //@MainActor
    public func deleteGame(gameID: String) {
        do {
            guard let db = db else { throw SQLiteError.noDatabase }
            
            
            ///Check gameID exists
            /*
            let checkSQL = "SELECT game_id FROM games WHERE game_id = ?;"
            let stmt = try db.prepareStatement(sql: checkSQL)
            sqlite3_bind_text(stmt, 1, gameID, -1, nil)
            if sqlite3_step(stmt) == SQLITE_ROW {
                print("🔎 Found row for \(gameID) before delete")
            } else {
                print("⚠️ No row found for \(gameID) before delete")
            }
            sqlite3_finalize(stmt)
             */
            
            
            let deleteSQL = "DELETE FROM games WHERE game_id = ?;"
            let statement = try db.prepareStatement(sql: deleteSQL)
            defer { sqlite3_finalize(statement) }
            
            sqlite3_bind_text(statement, 1, (gameID as NSString).utf8String, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                
                let changes = sqlite3_changes(db.dbPointer)
                print("✅ Game deleted: \(gameID), rows affected: \(changes)")

            } else {
                /// Try manual delete if DELETE CASCADE fails
                do{
                    self.chainDeleteGame(gameID: gameID)
                    print("✅ Game deleted: \(gameID)")
                } catch {
                    throw SQLiteError.step(message: db.errorMessage)
                }
            }
        } catch {
            print("❌ Failed to delete game: \(error)")
        }
    }
    
    public func chainDeleteGame(gameID: String) {
        guard let db = db else {
            print("❌ No database open")
            return
        }
        print("Attempting Chain Delete from DELETE CASCADE failure: \(gameID)")
        do {
         
            // 1️⃣ Delete child rows manually (if no ON DELETE CASCADE)
            let childTables = ["sent_pod_passes", "game_turns", "turn_durations", "commanders"]
            for table in childTables {
                let deleteChildSQL = "DELETE FROM \(table) WHERE game_id = ?;"
                let stmt = try db.prepareStatement(sql: deleteChildSQL)
                defer { sqlite3_finalize(stmt) }
                sqlite3_bind_text(stmt, 1, (gameID as NSString).utf8String, -1, nil)
                
                if sqlite3_step(stmt) == SQLITE_DONE {
                    let changes = sqlite3_changes(db.dbPointer)
                    print("✅ Deleted \(changes) rows from \(table) for game \(gameID)")
                } else {
                    print("⚠️ Failed to delete from \(table): \(db.errorMessage)")
                }
            }
            
            // 2️⃣ Delete the game itself
            let deleteGameSQL = "DELETE FROM games WHERE game_id = ?;"
            let stmt = try db.prepareStatement(sql: deleteGameSQL)
            defer { sqlite3_finalize(stmt) }
            sqlite3_bind_text(stmt, 1, (gameID as NSString).utf8String, -1, nil)
            
            if sqlite3_step(stmt) == SQLITE_DONE {
                let changes = sqlite3_changes(db.dbPointer)
                print("✅ Game deleted: \(gameID), rows affected: \(changes)")
            } else {
                print("❌ Failed to delete game: \(db.errorMessage ?? "Unknown error")")
            }
            
        } catch {
            print("❌ SQLite exception: \(error)")
        }
    }
    
    // MARK: - Duel Match Storage Methods

    @MainActor public func saveDuelMatch(_ match: FinalDuelMatch, turnHistories: [[DuelTurn]]) throws {
        guard let db = db else { throw SQLiteError.noDatabase }

        guard !duelMatchExists(matchID: match.matchID) else {
            print("Duel match already exists in db. Skipping save.")
            return
        }

        try db.execute(sql: "BEGIN TRANSACTION;")

        do {
            // Insert the match record
            let insertMatch = """
            INSERT INTO duel_matches (
                match_id, date_played, total_duration, player1_name, player2_name,
                player1_deck_tag, player2_deck_tag, player1_notes, player2_notes,
                match_score_p1, match_score_p2, match_winner, tournament_id, date_added
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
            """

            let stmt = try db.prepareStatement(sql: insertMatch)
            defer { sqlite3_finalize(stmt) }

            sqlite3_bind_text(stmt, 1, (match.matchID as NSString).utf8String, -1, nil)
            sqlite3_bind_double(stmt, 2, match.date.timeIntervalSince1970)
            sqlite3_bind_double(stmt, 3, match.totalDuration)
            sqlite3_bind_text(stmt, 4, (match.player1Name as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 5, (match.player2Name as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 6, (match.player1DeckTag as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 7, (match.player2DeckTag as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 8, (match.player1Notes as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 9, (match.player2Notes as NSString).utf8String, -1, nil)
            sqlite3_bind_int(stmt, 10, Int32(match.matchScore[0]))
            sqlite3_bind_int(stmt, 11, Int32(match.matchScore[1]))

            if let winner = match.matchWinner {
                sqlite3_bind_int(stmt, 12, Int32(winner))
            } else {
                sqlite3_bind_null(stmt, 12)
            }

            if let tournamentID = match.tournamentID {
                sqlite3_bind_text(stmt, 13, (tournamentID as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_null(stmt, 13)
            }

            sqlite3_bind_double(stmt, 14, Date().timeIntervalSince1970)

            if sqlite3_step(stmt) != SQLITE_DONE {
                throw SQLiteError.step(message: db.errorMessage)
            }

            // Insert individual game results
            for game in match.games {
                try insertDuelGame(game, matchID: match.matchID, db: db)
            }

            // Insert turn histories
            for (gameIndex, turns) in turnHistories.enumerated() {
                let gameNumber = gameIndex + 1
                for turn in turns {
                    try insertDuelGameTurn(turn, matchID: match.matchID, gameNumber: gameNumber, db: db)
                }
            }

            try db.execute(sql: "COMMIT;")
            print("Duel match saved: \(match.matchID)")

        } catch {
            try? db.execute(sql: "ROLLBACK;")
            print("Failed to save duel match: \(error)")
            throw error
        }
    }

    private func insertDuelGame(_ game: DuelGameResult, matchID: String, db: SQLiteDatabase) throws {
        let insertSQL = """
        INSERT INTO duel_games (
            match_id, game_number, winner_player_index,
            final_life_p1, final_life_p2, final_infect_p1, final_infect_p2,
            turn_count, mulligan_count_p1, mulligan_count_p2,
            first_player, duration, win_method, date_played
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """

        let stmt = try db.prepareStatement(sql: insertSQL)
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, (matchID as NSString).utf8String, -1, nil)
        sqlite3_bind_int(stmt, 2, Int32(game.gameNumber))

        if let winner = game.winnerPlayerIndex {
            sqlite3_bind_int(stmt, 3, Int32(winner))
        } else {
            sqlite3_bind_null(stmt, 3)
        }

        sqlite3_bind_int(stmt, 4, Int32(game.finalLifeTotals[0]))
        sqlite3_bind_int(stmt, 5, Int32(game.finalLifeTotals[1]))
        sqlite3_bind_int(stmt, 6, Int32(game.finalInfectTotals[0]))
        sqlite3_bind_int(stmt, 7, Int32(game.finalInfectTotals[1]))
        sqlite3_bind_int(stmt, 8, Int32(game.turnCount))
        sqlite3_bind_int(stmt, 9, Int32(game.mulliganCounts[0]))
        sqlite3_bind_int(stmt, 10, Int32(game.mulliganCounts[1]))
        sqlite3_bind_int(stmt, 11, Int32(game.firstPlayer))
        sqlite3_bind_double(stmt, 12, game.duration)
        sqlite3_bind_text(stmt, 13, (game.winMethod as NSString).utf8String, -1, nil)
        sqlite3_bind_double(stmt, 14, game.date.timeIntervalSince1970)

        if sqlite3_step(stmt) != SQLITE_DONE {
            throw SQLiteError.step(message: db.errorMessage)
        }
    }

    @MainActor
    private func insertDuelGameTurn(_ turn: DuelTurn, matchID: String, gameNumber: Int, db: SQLiteDatabase) throws {
        let insertSQL = """
        INSERT INTO duel_game_turns (
            match_id, game_number, turn_id, active_player, round_number,
            life_total_0, life_total_1, infect_total_0, infect_total_1,
            delta_life_0, delta_life_1, delta_infect_0, delta_infect_1,
            turn_started, turn_ended, turn_duration
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """

        let stmt = try db.prepareStatement(sql: insertSQL)
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, (matchID as NSString).utf8String, -1, nil)
        sqlite3_bind_int(stmt, 2, Int32(gameNumber))
        sqlite3_bind_int(stmt, 3, Int32(turn.id))
        sqlite3_bind_int(stmt, 4, Int32(turn.activePlayer))
        sqlite3_bind_int(stmt, 5, Int32(turn.round))
        sqlite3_bind_int(stmt, 6, Int32(turn.lifeTotal[0]))
        sqlite3_bind_int(stmt, 7, Int32(turn.lifeTotal[1]))
        sqlite3_bind_int(stmt, 8, Int32(turn.infectTotal[0]))
        sqlite3_bind_int(stmt, 9, Int32(turn.infectTotal[1]))
        sqlite3_bind_int(stmt, 10, Int32(turn.deltaLife[0]))
        sqlite3_bind_int(stmt, 11, Int32(turn.deltaLife[1]))
        sqlite3_bind_int(stmt, 12, Int32(turn.deltaInfect[0]))
        sqlite3_bind_int(stmt, 13, Int32(turn.deltaInfect[1]))
        sqlite3_bind_double(stmt, 14, turn.whenTurnStarted.timeIntervalSince1970)
        sqlite3_bind_double(stmt, 15, turn.whenTurnEnded.timeIntervalSince1970)
        sqlite3_bind_double(stmt, 16, turn.turnDuration)

        if sqlite3_step(stmt) != SQLITE_DONE {
            throw SQLiteError.step(message: db.errorMessage)
        }
    }

    public func duelMatchExists(matchID: String) -> Bool {
        guard let db = db else { return false }

        let querySQL = "SELECT 1 FROM duel_matches WHERE match_id = ? LIMIT 1;"
        do {
            let stmt = try db.prepareStatement(sql: querySQL)
            defer { sqlite3_finalize(stmt) }
            sqlite3_bind_text(stmt, 1, (matchID as NSString).utf8String, -1, nil)
            return sqlite3_step(stmt) == SQLITE_ROW
        } catch {
            print("Error checking duel match exists: \(error)")
            return false
        }
    }

    public func loadAllDuelMatches() -> [FinalDuelMatch] {
        guard let db = db else { return [] }

        var matches: [FinalDuelMatch] = []

        let querySQL = """
        SELECT match_id, date_played, total_duration, player1_name, player2_name,
               player1_deck_tag, player2_deck_tag, player1_notes, player2_notes,
               match_score_p1, match_score_p2, match_winner, tournament_id
        FROM duel_matches ORDER BY date_played DESC;
        """

        do {
            let stmt = try db.prepareStatement(sql: querySQL)
            defer { sqlite3_finalize(stmt) }

            while sqlite3_step(stmt) == SQLITE_ROW {
                let matchID = String(cString: sqlite3_column_text(stmt, 0))
                let datePlayed = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 1))
                let totalDuration = sqlite3_column_double(stmt, 2)
                let player1Name = String(cString: sqlite3_column_text(stmt, 3))
                let player2Name = String(cString: sqlite3_column_text(stmt, 4))
                let player1DeckTag = String(cString: sqlite3_column_text(stmt, 5))
                let player2DeckTag = String(cString: sqlite3_column_text(stmt, 6))
                let player1Notes = String(cString: sqlite3_column_text(stmt, 7))
                let player2Notes = String(cString: sqlite3_column_text(stmt, 8))
                let matchScoreP1 = Int(sqlite3_column_int(stmt, 9))
                let matchScoreP2 = Int(sqlite3_column_int(stmt, 10))
                let matchWinner: Int? = sqlite3_column_type(stmt, 11) == SQLITE_NULL ? nil : Int(sqlite3_column_int(stmt, 11))
                let tournamentID: String? = sqlite3_column_type(stmt, 12) == SQLITE_NULL ? nil : String(cString: sqlite3_column_text(stmt, 12))

                // Load games for this match
                let games = loadDuelGames(matchID: matchID)

                let match = FinalDuelMatch(
                    matchID: matchID,
                    date: datePlayed,
                    totalDuration: totalDuration,
                    player1Name: player1Name,
                    player2Name: player2Name,
                    player1DeckTag: player1DeckTag,
                    player2DeckTag: player2DeckTag,
                    player1Notes: player1Notes,
                    player2Notes: player2Notes,
                    games: games,
                    matchScore: [matchScoreP1, matchScoreP2],
                    matchWinner: matchWinner,
                    tournamentID: tournamentID
                )
                matches.append(match)
            }
        } catch {
            print("Failed to load duel matches: \(error)")
        }

        return matches
    }

    private func loadDuelGames(matchID: String) -> [DuelGameResult] {
        guard let db = db else { return [] }

        var games: [DuelGameResult] = []

        let querySQL = """
        SELECT game_number, winner_player_index, final_life_p1, final_life_p2,
               final_infect_p1, final_infect_p2, turn_count, mulligan_count_p1,
               mulligan_count_p2, first_player, duration, win_method, date_played
        FROM duel_games WHERE match_id = ? ORDER BY game_number ASC;
        """

        do {
            let stmt = try db.prepareStatement(sql: querySQL)
            defer { sqlite3_finalize(stmt) }
            sqlite3_bind_text(stmt, 1, (matchID as NSString).utf8String, -1, nil)

            while sqlite3_step(stmt) == SQLITE_ROW {
                let gameNumber = Int(sqlite3_column_int(stmt, 0))
                let winnerPlayerIndex: Int? = sqlite3_column_type(stmt, 1) == SQLITE_NULL ? nil : Int(sqlite3_column_int(stmt, 1))
                let finalLifeP1 = Int(sqlite3_column_int(stmt, 2))
                let finalLifeP2 = Int(sqlite3_column_int(stmt, 3))
                let finalInfectP1 = Int(sqlite3_column_int(stmt, 4))
                let finalInfectP2 = Int(sqlite3_column_int(stmt, 5))
                let turnCount = Int(sqlite3_column_int(stmt, 6))
                let mulliganP1 = Int(sqlite3_column_int(stmt, 7))
                let mulliganP2 = Int(sqlite3_column_int(stmt, 8))
                let firstPlayer = Int(sqlite3_column_int(stmt, 9))
                let duration = sqlite3_column_double(stmt, 10)
                let winMethod = String(cString: sqlite3_column_text(stmt, 11))
                let datePlayed = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 12))

                let game = DuelGameResult(
                    gameNumber: gameNumber,
                    winnerPlayerIndex: winnerPlayerIndex,
                    finalLifeTotals: [finalLifeP1, finalLifeP2],
                    finalInfectTotals: [finalInfectP1, finalInfectP2],
                    turnCount: turnCount,
                    mulliganCounts: [mulliganP1, mulliganP2],
                    firstPlayer: firstPlayer,
                    duration: duration,
                    winMethod: winMethod,
                    date: datePlayed
                )
                games.append(game)
            }
        } catch {
            print("Failed to load duel games: \(error)")
        }

        return games
    }

    @MainActor
    public func loadDuelGameTurnHistory(matchID: String, gameNumber: Int) -> [DuelTurn] {
        guard let db = db else { return [] }

        var turns: [DuelTurn] = []

        let querySQL = """
        SELECT turn_id, active_player, round_number,
               life_total_0, life_total_1, infect_total_0, infect_total_1,
               delta_life_0, delta_life_1, delta_infect_0, delta_infect_1,
               turn_started, turn_ended, turn_duration
        FROM duel_game_turns WHERE match_id = ? AND game_number = ? ORDER BY turn_id ASC;
        """

        do {
            let stmt = try db.prepareStatement(sql: querySQL)
            defer { sqlite3_finalize(stmt) }
            sqlite3_bind_text(stmt, 1, (matchID as NSString).utf8String, -1, nil)
            sqlite3_bind_int(stmt, 2, Int32(gameNumber))

            while sqlite3_step(stmt) == SQLITE_ROW {
                let turnID = Int(sqlite3_column_int(stmt, 0))
                let activePlayer = Int(sqlite3_column_int(stmt, 1))
                let round = Int(sqlite3_column_int(stmt, 2))
                let lifeTotal0 = Int(sqlite3_column_int(stmt, 3))
                let lifeTotal1 = Int(sqlite3_column_int(stmt, 4))
                let infectTotal0 = Int(sqlite3_column_int(stmt, 5))
                let infectTotal1 = Int(sqlite3_column_int(stmt, 6))
                let deltaLife0 = Int(sqlite3_column_int(stmt, 7))
                let deltaLife1 = Int(sqlite3_column_int(stmt, 8))
                let deltaInfect0 = Int(sqlite3_column_int(stmt, 9))
                let deltaInfect1 = Int(sqlite3_column_int(stmt, 10))
                let turnStarted = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 11))
                let turnEnded = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 12))
                let turnDuration = sqlite3_column_double(stmt, 13)

                let turn = DuelTurn(
                    id: turnID,
                    activePlayer: activePlayer,
                    round: round,
                    deltaLife: [deltaLife0, deltaLife1],
                    deltaInfect: [deltaInfect0, deltaInfect1],
                    lifeTotal: [lifeTotal0, lifeTotal1],
                    infectTotal: [infectTotal0, infectTotal1],
                    whenTurnStarted: turnStarted,
                    whenTurnEnded: turnEnded,
                    turnDuration: turnDuration
                )
                turns.append(turn)
            }
        } catch {
            print("Failed to load duel game turns: \(error)")
        }

        return turns
    }

    public func deleteDuelMatch(matchID: String) {
        guard let db = db else { return }

        do {
            let deleteSQL = "DELETE FROM duel_matches WHERE match_id = ?;"
            let stmt = try db.prepareStatement(sql: deleteSQL)
            defer { sqlite3_finalize(stmt) }
            sqlite3_bind_text(stmt, 1, (matchID as NSString).utf8String, -1, nil)

            if sqlite3_step(stmt) != SQLITE_DONE {
                throw SQLiteError.step(message: db.errorMessage)
            }
            print("Duel match deleted: \(matchID)")
        } catch {
            print("Failed to delete duel match: \(error)")
        }
    }

    // MARK: - Tournament Storage Methods

    public func saveTournamentRecord(_ record: TournamentRecord) throws {
        guard let db = db else { throw SQLiteError.noDatabase }

        try db.execute(sql: "BEGIN TRANSACTION;")

        do {
            let insertSQL = """
            INSERT INTO tournaments (
                tournament_id, name, code, date_created, date_ended,
                player_count, round_count, status, final_standings_json
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
            """

            let stmt = try db.prepareStatement(sql: insertSQL)
            defer { sqlite3_finalize(stmt) }

            sqlite3_bind_text(stmt, 1, (record.tournamentID as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, (record.name as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 3, (record.code as NSString).utf8String, -1, nil)
            sqlite3_bind_double(stmt, 4, record.dateCreated.timeIntervalSince1970)

            if let dateEnded = record.dateEnded {
                sqlite3_bind_double(stmt, 5, dateEnded.timeIntervalSince1970)
            } else {
                sqlite3_bind_null(stmt, 5)
            }

            sqlite3_bind_int(stmt, 6, Int32(record.playerCount))
            sqlite3_bind_int(stmt, 7, Int32(record.roundCount))
            sqlite3_bind_text(stmt, 8, (record.status as NSString).utf8String, -1, nil)

            if let standingsData = try? JSONEncoder().encode(record.finalStandings),
               let standingsJSON = String(data: standingsData, encoding: .utf8) {
                sqlite3_bind_text(stmt, 9, (standingsJSON as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_null(stmt, 9)
            }

            if sqlite3_step(stmt) != SQLITE_DONE {
                throw SQLiteError.step(message: db.errorMessage)
            }

            // Insert entries
            for entry in record.entries {
                try insertTournamentEntry(entry, tournamentID: record.tournamentID, db: db)
            }

            try db.execute(sql: "COMMIT;")
            print("Tournament saved: \(record.tournamentID)")

        } catch {
            try? db.execute(sql: "ROLLBACK;")
            throw error
        }
    }

    private func insertTournamentEntry(_ entry: TournamentEntry, tournamentID: String, db: SQLiteDatabase) throws {
        let insertSQL = """
        INSERT INTO tournament_entries (
            tournament_id, match_id, round_number, player1_name, player2_name, result
        ) VALUES (?, ?, ?, ?, ?, ?);
        """

        let stmt = try db.prepareStatement(sql: insertSQL)
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, (tournamentID as NSString).utf8String, -1, nil)

        if let matchID = entry.matchID {
            sqlite3_bind_text(stmt, 2, (matchID as NSString).utf8String, -1, nil)
        } else {
            sqlite3_bind_null(stmt, 2)
        }

        sqlite3_bind_int(stmt, 3, Int32(entry.roundNumber))
        sqlite3_bind_text(stmt, 4, (entry.player1Name as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 5, (entry.player2Name as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 6, (entry.result as NSString).utf8String, -1, nil)

        if sqlite3_step(stmt) != SQLITE_DONE {
            throw SQLiteError.step(message: db.errorMessage)
        }
    }

    public func loadAllTournaments() -> [TournamentRecord] {
        guard let db = db else { return [] }

        var tournaments: [TournamentRecord] = []

        let querySQL = """
        SELECT tournament_id, name, code, date_created, date_ended,
               player_count, round_count, status, final_standings_json
        FROM tournaments ORDER BY date_created DESC;
        """

        do {
            let stmt = try db.prepareStatement(sql: querySQL)
            defer { sqlite3_finalize(stmt) }

            while sqlite3_step(stmt) == SQLITE_ROW {
                let tournamentID = String(cString: sqlite3_column_text(stmt, 0))
                let name = String(cString: sqlite3_column_text(stmt, 1))
                let code = String(cString: sqlite3_column_text(stmt, 2))
                let dateCreated = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 3))
                let dateEnded: Date? = sqlite3_column_type(stmt, 4) == SQLITE_NULL ? nil : Date(timeIntervalSince1970: sqlite3_column_double(stmt, 4))
                let playerCount = Int(sqlite3_column_int(stmt, 5))
                let roundCount = Int(sqlite3_column_int(stmt, 6))
                let status = String(cString: sqlite3_column_text(stmt, 7))

                var finalStandings: [TournamentStandingRecord] = []
                if sqlite3_column_type(stmt, 8) != SQLITE_NULL {
                    let standingsJSON = String(cString: sqlite3_column_text(stmt, 8))
                    if let data = standingsJSON.data(using: .utf8) {
                        finalStandings = (try? JSONDecoder().decode([TournamentStandingRecord].self, from: data)) ?? []
                    }
                }

                let entries = loadTournamentEntries(tournamentID: tournamentID)

                let record = TournamentRecord(
                    tournamentID: tournamentID,
                    name: name,
                    code: code,
                    dateCreated: dateCreated,
                    dateEnded: dateEnded,
                    playerCount: playerCount,
                    roundCount: roundCount,
                    status: status,
                    finalStandings: finalStandings,
                    entries: entries
                )
                tournaments.append(record)
            }
        } catch {
            print("Failed to load tournaments: \(error)")
        }

        return tournaments
    }

    private func loadTournamentEntries(tournamentID: String) -> [TournamentEntry] {
        guard let db = db else { return [] }

        var entries: [TournamentEntry] = []

        let querySQL = """
        SELECT match_id, round_number, player1_name, player2_name, result
        FROM tournament_entries WHERE tournament_id = ? ORDER BY round_number ASC;
        """

        do {
            let stmt = try db.prepareStatement(sql: querySQL)
            defer { sqlite3_finalize(stmt) }
            sqlite3_bind_text(stmt, 1, (tournamentID as NSString).utf8String, -1, nil)

            while sqlite3_step(stmt) == SQLITE_ROW {
                let matchID: String? = sqlite3_column_type(stmt, 0) == SQLITE_NULL ? nil : String(cString: sqlite3_column_text(stmt, 0))
                let roundNumber = Int(sqlite3_column_int(stmt, 1))
                let player1Name = String(cString: sqlite3_column_text(stmt, 2))
                let player2Name = String(cString: sqlite3_column_text(stmt, 3))
                let result = String(cString: sqlite3_column_text(stmt, 4))

                let entry = TournamentEntry(
                    matchID: matchID,
                    roundNumber: roundNumber,
                    player1Name: player1Name,
                    player2Name: player2Name,
                    result: result
                )
                entries.append(entry)
            }
        } catch {
            print("Failed to load tournament entries: \(error)")
        }

        return entries
    }


    public func clearAllData() {
        do {
            guard let db = db else { throw SQLiteError.noDatabase }
            
            let clearStatements = [
                "DELETE FROM sent_pod_passes;",
                "DELETE FROM game_turns;",
                "DELETE FROM turn_durations;",
                "DELETE FROM commanders;",
                "DELETE FROM games;",
                "DELETE FROM duel_game_turns;",
                "DELETE FROM duel_games;",
                "DELETE FROM duel_matches;",
                "DELETE FROM tournament_entries;",
                "DELETE FROM tournaments;"
            ]
            
            try db.execute(sql: "BEGIN TRANSACTION;")
            
            for sql in clearStatements {
                try db.execute(sql: sql)
            }
            
            try db.execute(sql: "COMMIT;")
            print("✅ All game data cleared")
        } catch {
            print("❌ Failed to clear data: \(error)")
        }
    }
    
    
    
    
}
