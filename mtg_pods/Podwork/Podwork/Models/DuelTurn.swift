import Foundation
import SwiftUI


// MARK: - Duel Turn (60-Card Format)
/// Tracks a single turn's state in a 2-player game using the delta pattern.
/// Delta arrays store changes during this turn; total arrays store cumulative state.
@Observable
@MainActor
public final class DuelTurn: @MainActor Identifiable, Sendable {
    public var id: Int
    public var activePlayer: Int
    public var round: Int

    // MARK: - Delta Changes (This Turn)
    public var deltaLife: [Int]
    public var deltaInfect: [Int]

    // MARK: - Cumulative Totals (End of Turn)
    public var lifeTotal: [Int]
    public var infectTotal: [Int]

    // MARK: - Turn Timing
    public var whenTurnStarted: Date
    public var whenTurnEnded: Date
    public var turnDuration: TimeInterval


    // MARK: - Init from Previous Turn
    public init(from previousTurn: DuelTurn, with newActivePlayer: Int, after newWhenTurnEnded: Date) {
        // Calculate totals by applying previous turn's deltas
        let calculatedLifeTotal = zip(previousTurn.lifeTotal, previousTurn.deltaLife).map(+)
        let calculatedInfectTotal = zip(previousTurn.infectTotal, previousTurn.deltaInfect).map(+)

        self.id = previousTurn.id + 1
        self.activePlayer = newActivePlayer
        self.round = previousTurn.round

        // Reset deltas for the new turn
        self.deltaLife = Array(repeating: 0, count: DuelConstants.playerCount)
        self.deltaInfect = Array(repeating: 0, count: DuelConstants.playerCount)

        // Carry forward totals
        self.lifeTotal = calculatedLifeTotal
        self.infectTotal = calculatedInfectTotal

        // Timing
        self.whenTurnStarted = newWhenTurnEnded
        self.whenTurnEnded = newWhenTurnEnded
        self.turnDuration = 0
    }


    // MARK: - Initial Turn Factory
    public static func initialTurn(firstPlayer: Int, gameStartTime: Date) -> DuelTurn {
        let turn = DuelTurn(
            id: 0,
            activePlayer: firstPlayer,
            round: 1,
            deltaLife: DuelCommonConstants.blankLifeArray,
            deltaInfect: DuelCommonConstants.blankInfectArray,
            lifeTotal: DuelCommonConstants.startingLife,
            infectTotal: DuelCommonConstants.blankInfectArray,
            whenTurnStarted: gameStartTime,
            whenTurnEnded: gameStartTime,
            turnDuration: 0
        )
        return turn
    }


    // MARK: - Full Init
    public init(
        id: Int,
        activePlayer: Int,
        round: Int,
        deltaLife: [Int],
        deltaInfect: [Int],
        lifeTotal: [Int],
        infectTotal: [Int],
        whenTurnStarted: Date,
        whenTurnEnded: Date,
        turnDuration: TimeInterval
    ) {
        self.id = id
        self.activePlayer = activePlayer
        self.round = round
        self.deltaLife = deltaLife
        self.deltaInfect = deltaInfect
        self.lifeTotal = lifeTotal
        self.infectTotal = infectTotal
        self.whenTurnStarted = whenTurnStarted
        self.whenTurnEnded = whenTurnEnded
        self.turnDuration = turnDuration
    }


    // MARK: - Validation
    public var isValid: Bool {
        return deltaLife.count == DuelConstants.playerCount
            && deltaInfect.count == DuelConstants.playerCount
            && lifeTotal.count == DuelConstants.playerCount
            && infectTotal.count == DuelConstants.playerCount
            && activePlayer >= 0 && activePlayer < DuelConstants.playerCount
    }


    // MARK: - Computed Properties
    public var hasChanges: Bool {
        return deltaLife.contains(where: { $0 != 0 }) || deltaInfect.contains(where: { $0 != 0 })
    }

    public var netLifeChange: [Int] {
        return deltaLife
    }

    public var netInfectChange: [Int] {
        return deltaInfect
    }
}
