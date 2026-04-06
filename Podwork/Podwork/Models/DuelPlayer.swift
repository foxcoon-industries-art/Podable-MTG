import Foundation
import SwiftUI


// MARK: - Duel Player (60-Card Format)
@Observable
@MainActor
public final class DuelPlayer: Identifiable, Sendable {
    public let id: Int
    public var playerName: String
    public var deckTag: String
    public var notes: String
    public var life: Int
    public var infect: Int
    public var eliminated: Bool
    public var eliminationMethod: EliminationMethod
    public var timePerTurn: [TimeInterval]
    public var conceded: Bool

    public init(
        id: Int,
        playerName: String = "",
        deckTag: String = "",
        notes: String = "",
        life: Int = DuelConstants.startingLife
    ) {
        self.id = id
        self.playerName = playerName
        self.deckTag = deckTag
        self.notes = notes
        self.life = life
        self.infect = 0
        self.eliminated = false
        self.eliminationMethod = .notEliminated
        self.timePerTurn = []
        self.conceded = false
    }


    // MARK: - Update After Turn
    public func update(after currentTurn: DuelTurn) {
        self.life += currentTurn.deltaLife[id]
        self.infect += currentTurn.deltaInfect[id]
        self.timePerTurn.append(currentTurn.turnDuration)

        if isPlayerEliminated() && !eliminated {
            eliminated = true
            eliminationMethod = determineEliminationMethod()
        }
    }


    // MARK: - Elimination Check
    public func isPlayerEliminated() -> Bool {
        if conceded { return true }
        if life <= 0 { return true }
        if infect >= DuelConstants.infectLethal { return true }
        return false
    }


    // MARK: - Determine Elimination Method
    public func determineEliminationMethod() -> EliminationMethod {
        if conceded { return .concede }
        if life <= 0 { return .lifeDamage }
        if infect >= DuelConstants.infectLethal { return .infect }
        return .notEliminated
    }


    // MARK: - Reset For New Game
    public func resetForNewGame() {
        self.life = DuelConstants.startingLife
        self.infect = 0
        self.eliminated = false
        self.eliminationMethod = .notEliminated
        self.timePerTurn = []
        self.conceded = false
    }


    // MARK: - Computed Properties
    public var averageTurnDuration: TimeInterval {
        guard !timePerTurn.isEmpty else { return 0 }
        return timePerTurn.reduce(0, +) / Double(timePerTurn.count)
    }

    public var totalTurnTime: TimeInterval {
        return timePerTurn.reduce(0, +)
    }

    public var turnCount: Int {
        return timePerTurn.count
    }
}
