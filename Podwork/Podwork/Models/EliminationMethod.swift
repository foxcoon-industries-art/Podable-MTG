import SwiftUI


public enum EliminationMethod: Int, CaseIterable, Codable, Sendable {
    case lifeDamage = 0
    case commanderDamage = 1
    case infect = 2
    case concede = 3
    case altWin = 4
    case milled = 5
    case endingInDraw = 6
    case notEliminated = 7
    case emptySeat = 8
    
    
    public var displayName: String {
        switch self {
        case EliminationMethod.lifeDamage: return "Loss of Life"
        case EliminationMethod.commanderDamage: return "Cmdr. Dmg."
        case EliminationMethod.infect: return "Poison"
        case EliminationMethod.concede: return "Concede"
        case EliminationMethod.altWin: return "Alt. Win"
        case EliminationMethod.milled: return "Milled"
        case EliminationMethod.endingInDraw: return "Draw"
        case EliminationMethod.notEliminated: return "Not Eliminated"
        case EliminationMethod.emptySeat: return "No Player"

        }
    }
    
    public var description: String {
        switch self {
        case EliminationMethod.lifeDamage: return "Player eliminated by reducing life to 0 or below"
        case EliminationMethod.commanderDamage: return "Player eliminated by commander damage (21+ from single commander)"
        case EliminationMethod.infect: return "Player eliminated by infect/poison (10+ counters)"
        case EliminationMethod.concede: return "Player chose to concede the game"
        case EliminationMethod.altWin: return "Game won through alternative win condition"
        case EliminationMethod.milled: return "Player eliminated by milling/library depletion"
        case EliminationMethod.endingInDraw: return "Game ended in a draw"
        case EliminationMethod.notEliminated: return "Player is still active in the game"
        case EliminationMethod.emptySeat: return "A vacant seat remaining at the table without a Player"
        }
    }
    
    public var displayEmoji: Image {
        switch self {
        case EliminationMethod.lifeDamage: return Image(systemName: "person.crop.circle.badge.xmark")
        case EliminationMethod.commanderDamage: return Image(systemName: "bolt.circle")
        case EliminationMethod.infect: return Image(systemName: "eyedropper.halffull")
        case EliminationMethod.concede: return  Image(systemName: "door.left.hand.open")
        case EliminationMethod.altWin: return  Image(systemName: "wand.and.stars")
        case EliminationMethod.milled: return  Image(systemName: "tray.and.arrow.down")
        case EliminationMethod.endingInDraw: return  Image(systemName: "hand.raised")
        case EliminationMethod.notEliminated: return  Image(systemName: "person.crop")
        case EliminationMethod.emptySeat: return Image(systemName: "person.slash")

        }
    }
    
    
    public var emojiOverlay: String {
        switch self {
        case EliminationMethod.lifeDamage: return String("💀")
        case EliminationMethod.commanderDamage: return  String("⚡️")
        case EliminationMethod.infect: return  String("💉")
        case EliminationMethod.concede: return   String("🏃")
        case EliminationMethod.altWin: return   String("🏅")
        case EliminationMethod.milled: return   String("🪦")
        case EliminationMethod.endingInDraw: return String("🤝")
        case EliminationMethod.notEliminated: return String("🆗")
        case EliminationMethod.emptySeat: return String("🪑")
        }
    }
}
