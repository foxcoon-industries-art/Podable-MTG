import Foundation


// MARK: - Tournament Record (Persisted)
/// Represents a completed tournament stored locally.
public struct TournamentRecord: Codable, Identifiable, Sendable {
    public let tournamentID: String
    public let name: String
    public let code: String
    public let dateCreated: Date
    public let dateEnded: Date?
    public let playerCount: Int
    public let roundCount: Int
    public let status: String
    public let finalStandings: [TournamentStandingRecord]
    public let entries: [TournamentEntry]

    public var id: String { tournamentID }

    public init(
        tournamentID: String,
        name: String,
        code: String,
        dateCreated: Date,
        dateEnded: Date?,
        playerCount: Int,
        roundCount: Int,
        status: String,
        finalStandings: [TournamentStandingRecord],
        entries: [TournamentEntry]
    ) {
        self.tournamentID = tournamentID
        self.name = name
        self.code = code
        self.dateCreated = dateCreated
        self.dateEnded = dateEnded
        self.playerCount = playerCount
        self.roundCount = roundCount
        self.status = status
        self.finalStandings = finalStandings
        self.entries = entries
    }

    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: dateCreated)
    }

    public var duration: TimeInterval? {
        guard let ended = dateEnded else { return nil }
        return ended.timeIntervalSince(dateCreated)
    }
}


// MARK: - Tournament Entry
/// A single match entry within a tournament round.
public struct TournamentEntry: Codable, Sendable {
    public let matchID: String?
    public let roundNumber: Int
    public let player1Name: String
    public let player2Name: String
    public let result: String

    public init(
        matchID: String?,
        roundNumber: Int,
        player1Name: String,
        player2Name: String,
        result: String
    ) {
        self.matchID = matchID
        self.roundNumber = roundNumber
        self.player1Name = player1Name
        self.player2Name = player2Name
        self.result = result
    }
}


// MARK: - Tournament Standing Record
/// Final standing for a player in a completed tournament.
public struct TournamentStandingRecord: Codable, Sendable, Identifiable {
    public let rank: Int
    public let playerName: String
    public let points: Int
    public let wins: Int
    public let losses: Int
    public let draws: Int
    public let opponentMatchWinPct: Double
    public let gameWinPct: Double

    public var id: Int { rank }

    public init(
        rank: Int,
        playerName: String,
        points: Int,
        wins: Int,
        losses: Int,
        draws: Int,
        opponentMatchWinPct: Double,
        gameWinPct: Double
    ) {
        self.rank = rank
        self.playerName = playerName
        self.points = points
        self.wins = wins
        self.losses = losses
        self.draws = draws
        self.opponentMatchWinPct = opponentMatchWinPct
        self.gameWinPct = gameWinPct
    }

    public var record: String {
        return "\(wins)-\(losses)-\(draws)"
    }
}


// MARK: - Tournament Server API Models

/// Info returned from the tournament server.
public struct TournamentInfo: Codable, Sendable {
    public let tournamentID: Int
    public let name: String
    public let code: String
    public let status: String
    public let currentRound: Int
    public let players: [TournamentPlayerInfo]
    public let pairings: [TournamentPairingInfo]?
    public let standings: [TournamentStandingInfo]?

    enum CodingKeys: String, CodingKey {
        case tournamentID = "tournament_id"
        case name, code, status
        case currentRound = "current_round"
        case players, pairings, standings
    }
}

/// Player info from the tournament server.
public struct TournamentPlayerInfo: Codable, Sendable, Identifiable {
    public let playerID: Int
    public let playerName: String
    public let deviceID: String
    public let isDeviceOwner: Bool
    public let points: Int
    public let wins: Int
    public let losses: Int
    public let draws: Int

    public var id: Int { playerID }

    enum CodingKeys: String, CodingKey {
        case playerID = "player_id"
        case playerName = "player_name"
        case deviceID = "device_id"
        case isDeviceOwner = "is_device_owner"
        case points, wins, losses, draws
    }
}

/// Pairing info from the tournament server.
public struct TournamentPairingInfo: Codable, Sendable, Identifiable {
    public let pairingID: Int
    public let roundNumber: Int
    public let player1ID: Int
    public let player2ID: Int?
    public let player1Name: String
    public let player2Name: String?
    public let player1Submitted: Bool
    public let player2Submitted: Bool
    public let confirmed: Bool
    public let status: String

    public var id: Int { pairingID }
    public var isBye: Bool { player2ID == nil }

    enum CodingKeys: String, CodingKey {
        case pairingID = "pairing_id"
        case roundNumber = "round_number"
        case player1ID = "player1_id"
        case player2ID = "player2_id"
        case player1Name = "player1_name"
        case player2Name = "player2_name"
        case player1Submitted = "player1_submitted"
        case player2Submitted = "player2_submitted"
        case confirmed, status
    }
}

/// Standing info from the tournament server.
public struct TournamentStandingInfo: Codable, Sendable, Identifiable {
    public let rank: Int
    public let playerID: Int
    public let playerName: String
    public let points: Int
    public let wins: Int
    public let losses: Int
    public let draws: Int
    public let opponentMatchWinPct: Double
    public let gameWinPct: Double

    public var id: Int { rank }

    public init(rank: Int, playerID: Int, playerName: String, points: Int, wins: Int, losses: Int, draws: Int, opponentMatchWinPct: Double, gameWinPct: Double) {
        self.rank = rank
        self.playerID = playerID
        self.playerName = playerName
        self.points = points
        self.wins = wins
        self.losses = losses
        self.draws = draws
        self.opponentMatchWinPct = opponentMatchWinPct
        self.gameWinPct = gameWinPct
    }
    
    
    enum CodingKeys: String, CodingKey {
        case rank
        case playerID = "player_id"
        case playerName = "player_name"
        case points, wins, losses, draws
        case opponentMatchWinPct = "opponent_match_win_pct"
        case gameWinPct = "game_win_pct"
    }

    public var record: String {
        return "\(wins)-\(losses)-\(draws)"
    }
}


// MARK: - Game Submission to Server
public struct GameSubmission: Codable, Sendable {
    public let roundNumber: Int
    public let playerID: Int
    public let opponentID: Int
    public let matchWins: Int
    public let matchLosses: Int
    public let gameDetails: [GameSubmissionDetail]

    enum CodingKeys: String, CodingKey {
        case roundNumber = "round_number"
        case playerID = "player_id"
        case opponentID = "opponent_id"
        case matchWins = "match_wins"
        case matchLosses = "match_losses"
        case gameDetails = "game_details"
    }

    public init(
        roundNumber: Int,
        playerID: Int,
        opponentID: Int,
        matchWins: Int,
        matchLosses: Int,
        gameDetails: [GameSubmissionDetail]
    ) {
        self.roundNumber = roundNumber
        self.playerID = playerID
        self.opponentID = opponentID
        self.matchWins = matchWins
        self.matchLosses = matchLosses
        self.gameDetails = gameDetails
    }
}

public struct GameSubmissionDetail: Codable, Sendable {
    public let gameNumber: Int
    public let winnerPlayerIndex: Int?
    public let finalLifeP1: Int
    public let finalLifeP2: Int
    public let turnCount: Int

    enum CodingKeys: String, CodingKey {
        case gameNumber = "game_number"
        case winnerPlayerIndex = "winner_player_index"
        case finalLifeP1 = "final_life_p1"
        case finalLifeP2 = "final_life_p2"
        case turnCount = "turn_count"
    }

    public init(
        gameNumber: Int,
        winnerPlayerIndex: Int?,
        finalLifeP1: Int,
        finalLifeP2: Int,
        turnCount: Int
    ) {
        self.gameNumber = gameNumber
        self.winnerPlayerIndex = winnerPlayerIndex
        self.finalLifeP1 = finalLifeP1
        self.finalLifeP2 = finalLifeP2
        self.turnCount = turnCount
    }
}
