import Foundation
import SwiftUI


// MARK: - Duel Game State (60-Card Format)
/// Manages a single game within a best-of-3 duel match.
/// Follows the same delta-based turn tracking pattern as GameState for Commander.
@Observable
@MainActor
public final class DuelGameState: @MainActor Identifiable, Sendable {
    public let gameID: String
    public var players: [DuelPlayer]
    public var currentTurn: DuelTurn
    public var turnHistory: [DuelTurn]
    public var currentRound: Int
    public var currentActivePlayerTurnNumber: Int
    public var finished: Bool
    public var winnerID: Int?
    public let gameNumber: Int
    public let firstPlayer: Int
    public var mulliganCounts: [Int]
    public var mulligansConfirmed: [Bool]
    public var gameDate: Date
    public var turnResetCount: Int

    public var id: String { gameID }


    // MARK: - Init
    public init(
        gameNumber: Int,
        firstPlayer: Int,
        player1Name: String = "Player 1",
        player2Name: String = "Player 2",
        player1DeckTag: String = "",
        player2DeckTag: String = "",
        player1Notes: String = "",
        player2Notes: String = ""
    ) {
        self.gameID = UUID().uuidString
        self.gameNumber = gameNumber
        self.firstPlayer = firstPlayer
        let g = Date()
        self.gameDate = g
        
        self.finished = false
        self.winnerID = nil
        self.currentRound = 1
        self.currentActivePlayerTurnNumber = 1
        self.turnResetCount = 0
        self.mulliganCounts = [0, 0]
        self.mulligansConfirmed = [false, false]
        self.turnHistory = []

        self.players = [
            DuelPlayer(id: 0, playerName: player1Name, deckTag: player1DeckTag, notes: player1Notes),
            DuelPlayer(id: 1, playerName: player2Name, deckTag: player2DeckTag, notes: player2Notes)
        ]

        self.currentTurn = DuelTurn.initialTurn(firstPlayer: firstPlayer, gameStartTime: g)
    }


    // MARK: - Active Player
    public func activePlayer() -> Int {
        return currentTurn.activePlayer
    }

    public func activePlayerObject() -> DuelPlayer {
        return players[activePlayer()]
    }

    public func opponentPlayer() -> DuelPlayer {
        return players[1 - activePlayer()]
    }


    // MARK: - Life Changes
    public func applyLifeChange(to playerIndex: Int, amount: Int) {
        guard playerIndex >= 0 && playerIndex < DuelConstants.playerCount else { return }
        currentTurn.deltaLife[playerIndex] += amount
    }

    public func showDeltaLife(for playerIndex: Int) -> Int {
        guard playerIndex >= 0 && playerIndex < currentTurn.deltaLife.count else { return 0 }
        return currentTurn.deltaLife[playerIndex]
    }

    public func currentLife(for playerIndex: Int) -> Int {
        guard playerIndex >= 0 && playerIndex < currentTurn.lifeTotal.count else { return 0 }
        return currentTurn.lifeTotal[playerIndex] + currentTurn.deltaLife[playerIndex]
    }


    // MARK: - Infect Changes
    public func applyInfect(to playerIndex: Int, amount: Int) {
        guard playerIndex >= 0 && playerIndex < DuelConstants.playerCount else { return }
        currentTurn.deltaInfect[playerIndex] += amount
    }

    public func showDeltaInfect(for playerIndex: Int) -> Int {
        guard playerIndex >= 0 && playerIndex < currentTurn.deltaInfect.count else { return 0 }
        return currentTurn.deltaInfect[playerIndex]
    }

    public func currentInfect(for playerIndex: Int) -> Int {
        guard playerIndex >= 0 && playerIndex < currentTurn.infectTotal.count else { return 0 }
        return currentTurn.infectTotal[playerIndex] + currentTurn.deltaInfect[playerIndex]
    }


    // MARK: - Turn Management
    public func nextTurn() {
        // Finalize turn timing
        assignTurnDuration()

        // Apply deltas to player states
        for i in 0..<DuelConstants.playerCount {
            players[i].update(after: currentTurn)
        }

        // Save turn to history
        turnHistory.append(currentTurn)

        // Check for game end
        if hasWinningStateBeenFound() {
            finished = true
            return
        }

        // Advance round counter if both players have taken a turn
        let nextPlayerID = 1 - currentTurn.activePlayer
        if nextPlayerID <= currentTurn.activePlayer {
            currentRound += 1
        }

        // Create new turn
        let now = Date()
        currentTurn = DuelTurn(from: currentTurn, with: nextPlayerID, after: now)

        // Update player turn counter
        updatePlayerRoundDisplayNumber()
    }


    // MARK: - Reset Turn (Undo)
    public func resetTurn() {
        guard let previousTurn = turnHistory.popLast() else { return }

        // Reverse the deltas that were applied to players
        for i in 0..<DuelConstants.playerCount {
            players[i].life -= previousTurn.deltaLife[i]
            players[i].infect -= previousTurn.deltaInfect[i]

            if players[i].eliminated {
                players[i].eliminated = false
                players[i].eliminationMethod = .notEliminated
            }

            if !players[i].timePerTurn.isEmpty {
                players[i].timePerTurn.removeLast()
            }
        }

        // Restore turn
        currentTurn = previousTurn
        turnResetCount += 1

        // Recalculate round
        if currentRound > 1 && currentTurn.activePlayer == 0 {
            currentRound -= 1
        }

        updatePlayerRoundDisplayNumber()
    }


    // MARK: - Player Actions
    public func playerConceded(who playerID: Int) {
        guard playerID >= 0 && playerID < DuelConstants.playerCount else { return }
        players[playerID].conceded = true
        players[playerID].eliminated = true
        players[playerID].eliminationMethod = .concede
        winnerID = 1 - playerID
        finished = true
    }


    // MARK: - Win Detection
    public func hasWinningStateBeenFound() -> Bool {
        let p1Eliminated = players[0].isPlayerEliminated()
        let p2Eliminated = players[1].isPlayerEliminated()

        if p1Eliminated && p2Eliminated {
            // Both eliminated same turn - draw
            winnerID = nil
            return true
        } else if p1Eliminated {
            winnerID = 1
            return true
        } else if p2Eliminated {
            winnerID = 0
            return true
        }

        return false
    }


    // MARK: - Assign Win Method
    public func assignWinMethod() -> String {
        guard let winner = winnerID else { return "Draw" }
        let loser = 1 - winner
        let method = players[loser].determineEliminationMethod()
        return method.displayName
    }


    // MARK: - Convert to Result
    public func toDuelGameResult() -> DuelGameResult {
        return DuelGameResult(
            gameNumber: gameNumber,
            winnerPlayerIndex: winnerID,
            finalLifeTotals: [players[0].life, players[1].life],
            finalInfectTotals: [players[0].infect, players[1].infect],
            turnCount: turnHistory.count,
            mulliganCounts: mulliganCounts,
            firstPlayer: firstPlayer,
            duration: Date().timeIntervalSince(gameDate),
            winMethod: assignWinMethod(),
            date: gameDate
        )
    }


    // MARK: - Mulligan
    public func recordMulligan(for playerIndex: Int) {
        guard playerIndex >= 0 && playerIndex < DuelConstants.playerCount else { return }
        mulliganCounts[playerIndex] += 1
    }

    public func confirmKeep(for playerIndex: Int) {
        guard playerIndex >= 0 && playerIndex < DuelConstants.playerCount else { return }
        mulligansConfirmed[playerIndex] = true
    }

    public var allMulligansConfirmed: Bool {
        return mulligansConfirmed.allSatisfy { $0 }
    }


    // MARK: - Private Helpers
    private func assignTurnDuration() {
        let now = Date()
        currentTurn.whenTurnEnded = now
        currentTurn.turnDuration = now.timeIntervalSince(currentTurn.whenTurnStarted)
    }

    private func updatePlayerRoundDisplayNumber() {
        let ap = activePlayer()
        var count = 0
        for turn in turnHistory where turn.activePlayer == ap {
            count += 1
        }
        currentActivePlayerTurnNumber = count + 1
    }


    // MARK: - Game Duration
    public var gameDuration: TimeInterval {
        return Date().timeIntervalSince(gameDate)
    }

    public var totalTurnsPlayed: Int {
        return turnHistory.count
    }
}
