import Foundation


// MARK: - Duel Game Result
/// Represents the completed result of a single game within a best-of-3 match.
public struct DuelGameResult: Codable, Sendable, Identifiable {
    public var id: Int { gameNumber }

    public let gameNumber: Int
    public let winnerPlayerIndex: Int?
    public let finalLifeTotals: [Int]
    public let finalInfectTotals: [Int]
    public let turnCount: Int
    public let mulliganCounts: [Int]
    public let firstPlayer: Int
    public let duration: TimeInterval
    public let winMethod: String
    public let date: Date

    public init(
        gameNumber: Int,
        winnerPlayerIndex: Int?,
        finalLifeTotals: [Int],
        finalInfectTotals: [Int],
        turnCount: Int,
        mulliganCounts: [Int],
        firstPlayer: Int,
        duration: TimeInterval,
        winMethod: String,
        date: Date
    ) {
        self.gameNumber = gameNumber
        self.winnerPlayerIndex = winnerPlayerIndex
        self.finalLifeTotals = finalLifeTotals
        self.finalInfectTotals = finalInfectTotals
        self.turnCount = turnCount
        self.mulliganCounts = mulliganCounts
        self.firstPlayer = firstPlayer
        self.duration = duration
        self.winMethod = winMethod
        self.date = date
    }


    // MARK: - Computed Properties
    public var isDraw: Bool {
        return winnerPlayerIndex == nil
    }

    public var loserPlayerIndex: Int? {
        guard let winner = winnerPlayerIndex else { return nil }
        return 1 - winner
    }

    public var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    public var totalMulligans: Int {
        return mulliganCounts.reduce(0, +)
    }
}
