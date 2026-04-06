import Foundation


// MARK: - Final Duel Match (Persisted Record)
/// The saved record of a completed best-of-3 duel match. Analogous to FinalPod for commander.
public struct FinalDuelMatch: Codable, Identifiable, Sendable {
    public let matchID: String
    public let date: Date
    public let totalDuration: TimeInterval
    public let player1Name: String
    public let player2Name: String
    public let player1DeckTag: String
    public let player2DeckTag: String
    public let player1Notes: String
    public let player2Notes: String
    public let games: [DuelGameResult]
    public let matchScore: [Int]
    public let matchWinner: Int?
    public let tournamentID: String?

    public var id: String { matchID }

    public init(
        matchID: String,
        date: Date,
        totalDuration: TimeInterval,
        player1Name: String,
        player2Name: String,
        player1DeckTag: String,
        player2DeckTag: String,
        player1Notes: String,
        player2Notes: String,
        games: [DuelGameResult],
        matchScore: [Int],
        matchWinner: Int?,
        tournamentID: String? = nil
    ) {
        self.matchID = matchID
        self.date = date
        self.totalDuration = totalDuration
        self.player1Name = player1Name
        self.player2Name = player2Name
        self.player1DeckTag = player1DeckTag
        self.player2DeckTag = player2DeckTag
        self.player1Notes = player1Notes
        self.player2Notes = player2Notes
        self.games = games
        self.matchScore = matchScore
        self.matchWinner = matchWinner
        self.tournamentID = tournamentID
    }


    // MARK: - Computed Properties
    public var totalGamesPlayed: Int {
        return games.count
    }

    public var winnerName: String? {
        guard let winner = matchWinner else { return nil }
        return winner == 0 ? player1Name : player2Name
    }

    public var loserName: String? {
        guard let winner = matchWinner else { return nil }
        return winner == 0 ? player2Name : player1Name
    }

    public var scoreString: String {
        return "\(matchScore[0]) - \(matchScore[1])"
    }

    public var formattedDuration: String {
        let minutes = Int(totalDuration) / 60
        let seconds = Int(totalDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    public var totalTurnsPlayed: Int {
        return games.reduce(0) { $0 + $1.turnCount }
    }

    public var totalMulligans: Int {
        return games.reduce(0) { $0 + $1.totalMulligans }
    }

    public var averageGameDuration: TimeInterval {
        guard !games.isEmpty else { return 0 }
        return totalDuration / Double(games.count)
    }

    public func playerName(for index: Int) -> String {
        return index == 0 ? player1Name : player2Name
    }

    public func deckTag(for index: Int) -> String {
        return index == 0 ? player1DeckTag : player2DeckTag
    }
}
