import Foundation
import SwiftUI


// MARK: - Duel Match (Best-of-3)
/// Manages the overall best-of-3 match flow for 60-card format games.
@Observable
@MainActor
public final class DuelMatch: @MainActor Identifiable, Sendable {
    public let matchID: String
    public let startDate: Date

    // Player info
    public var player1Name: String
    public var player2Name: String
    public var player1DeckTag: String
    public var player2DeckTag: String
    public var player1Notes: String
    public var player2Notes: String

    // Match state
    public var matchScore: [Int]
    public var currentGameNumber: Int
    public var currentGame: DuelGameState?
    public var completedGames: [DuelGameResult]
    public var matchFinished: Bool
    public var matchWinner: Int?
    public var tournamentID: String?

    public var id: String { matchID }


    // MARK: - Init
    public init(
        matchID: String = UUID().uuidString,
        player1Name: String = "Player 1",
        player2Name: String = "Player 2",
        player1DeckTag: String = "",
        player2DeckTag: String = "",
        player1Notes: String = "",
        player2Notes: String = "",
        tournamentID: String? = nil
    ) {
        self.matchID = matchID
        self.startDate = Date()
        self.player1Name = player1Name
        self.player2Name = player2Name
        self.player1DeckTag = player1DeckTag
        self.player2DeckTag = player2DeckTag
        self.player1Notes = player1Notes
        self.player2Notes = player2Notes
        self.matchScore = [0, 0]
        self.currentGameNumber = 1
        self.currentGame = nil
        self.completedGames = []
        self.matchFinished = false
        self.matchWinner = nil
        self.tournamentID = tournamentID
    }


    // MARK: - Start a New Game
    @discardableResult
    public func startGame(firstPlayer: Int) -> DuelGameState {
        let game = DuelGameState(
            gameNumber: currentGameNumber,
            firstPlayer: firstPlayer,
            player1Name: player1Name,
            player2Name: player2Name,
            player1DeckTag: player1DeckTag,
            player2DeckTag: player2DeckTag,
            player1Notes: player1Notes,
            player2Notes: player2Notes
        )
        self.currentGame = game
        return game
    }


    // MARK: - Record Game Result
    public func recordGameResult(_ result: DuelGameResult) {
        completedGames.append(result)

        if let winner = result.winnerPlayerIndex {
            matchScore[winner] += 1
        }

        currentGame = nil

        if isMatchOver() {
            matchFinished = true
            if matchScore[0] >= DuelConstants.gamesNeededToWin {
                matchWinner = 0
            } else if matchScore[1] >= DuelConstants.gamesNeededToWin {
                matchWinner = 1
            }
        }
    }


    // MARK: - Match State
    public func isMatchOver() -> Bool {
        return matchScore[0] >= DuelConstants.gamesNeededToWin
            || matchScore[1] >= DuelConstants.gamesNeededToWin
            || completedGames.count >= DuelConstants.maxGamesInMatch
    }

    @discardableResult
    public func startNextGame(firstPlayer: Int) -> DuelGameState? {
        guard !isMatchOver() else { return nil }
        currentGameNumber += 1
        return startGame(firstPlayer: firstPlayer)
    }


    // MARK: - Convert to Storage Model
    public func toFinalDuelMatch() -> FinalDuelMatch {
        return FinalDuelMatch(
            matchID: matchID,
            date: startDate,
            totalDuration: totalDuration,
            player1Name: player1Name,
            player2Name: player2Name,
            player1DeckTag: player1DeckTag,
            player2DeckTag: player2DeckTag,
            player1Notes: player1Notes,
            player2Notes: player2Notes,
            games: completedGames,
            matchScore: matchScore,
            matchWinner: matchWinner,
            tournamentID: tournamentID
        )
    }


    // MARK: - Computed Properties
    public var totalDuration: TimeInterval {
        return completedGames.reduce(0) { $0 + $1.duration }
    }

    public var scoreString: String {
        return "\(matchScore[0]) - \(matchScore[1])"
    }

    public var winnerName: String? {
        guard let winner = matchWinner else { return nil }
        return winner == 0 ? player1Name : player2Name
    }

    public var lastGameWinner: Int? {
        return completedGames.last?.winnerPlayerIndex
    }

    public var lastGameLoser: Int? {
        guard let winner = lastGameWinner else { return nil }
        return 1 - winner
    }

    public func playerName(for index: Int) -> String {
        return index == 0 ? player1Name : player2Name
    }

    public func deckTag(for index: Int) -> String {
        return index == 0 ? player1DeckTag : player2DeckTag
    }
}
