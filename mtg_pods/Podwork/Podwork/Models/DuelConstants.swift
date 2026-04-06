import SwiftUI
import Foundation


// MARK: - Duel Game Constants (60-Card Format)
public struct DuelConstants {
    public static let startingLife = 20
    public static let playerCount = 2
    public static let maxGamesInMatch = 3
    public static let gamesNeededToWin = 2
    public static let infectLethal = 10
    public static let maxPoisonCounters = 10
}


// MARK: - Duel Player Slot
public enum DuelSlot: Int, CaseIterable, Codable, Sendable {
    case player1 = 0
    case player2 = 1

    public var color: Color {
        switch self {
        case .player1: return Color.blue
        case .player2: return Color.red
        }
    }

    public var description: String {
        switch self {
        case .player1: return "Player 1"
        case .player2: return "Player 2"
        }
    }

    public var opponent: DuelSlot {
        switch self {
        case .player1: return .player2
        case .player2: return .player1
        }
    }
}


// MARK: - Duel Player Colors
public struct DuelPlayerColors {
    public static func color(for index: Int) -> Color {
        switch index {
        case 0: return Color.orange
        case 1: return Color.teal
        default: return Color.gray
        }
    }

    public static let allPlayerColors: [Color] = [Color.orange, Color.teal]
}


// MARK: - Duel Common Constants
public struct DuelCommonConstants {
    public static let startingLife = [20, 20]
    public static let blankLifeArray = [0, 0]
    public static let blankInfectArray = [0, 0]
}
