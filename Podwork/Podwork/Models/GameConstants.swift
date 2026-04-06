import SwiftUI
import Foundation


// MARK: - Core Game Constants
public struct GameConstants {
    public static let defaultStartingLife = 40
    public static let commanderDamageLethal = 21
    public static let infectLethal = 10
    public static let maxPlayers = 4
    public static let maxPoisonCounters = 10
    public static let longTurnDuration: TimeInterval = 10.0
    public static let playerOrder: [Quadrant] = [Quadrant.bottomLeft, Quadrant.topLeft, Quadrant.topRight,  Quadrant.bottomRight]

}

// MARK: - UI Constants
public struct GameUIConstants {
    public static let podSize: CGFloat = 62
    public static let buttonSize: CGFloat = 90 //78
    public static let bombPodSize: CGFloat = 120 //96
    public static let damageButtonSpacing: CGFloat = 10
    public static let damageButtonWidth: CGFloat = 4.65

}

public struct ViewUIConstants {
    public static let sidePad : CGFloat = 6
    @MainActor public static let cmdrBarHeight : CGFloat = (0.05555556 * UIScreen.main.bounds.height)
    
}


// MARK: - Quadrant System
public enum Quadrant: Int, CaseIterable, Codable, Sendable {
    case bottomLeft = 0
    case topLeft = 1
    case topRight = 2
    case bottomRight = 3
    case center = 4
    
    public var playerIndex: Int {
        return self.rawValue
    }
    
    public var description: String{
        switch self {
        case .bottomLeft: return "Green"
        case .topLeft: return "Orange"
        case .topRight: return "Blue"
        case .bottomRight: return "Purple"
        case .center: return "White"
        }
    }
    
    
    public var color: Color {
        switch self {
        case Quadrant.bottomLeft: return Color.green
        case Quadrant.topLeft: return Color.orange
        case Quadrant.topRight: return Color.blue
        case Quadrant.bottomRight: return Color.purple
        case Quadrant.center: return Color.white
        default: return Color.red
        }
    }
    
    public static func getQuadrantCenter(for idx: Int, in size: CGSize? = nil) -> CGPoint {
        
        
        let playerQuad = PlayerLayoutConfig.configurations[idx].quadrantID
        let width = size != nil ? size!.width : UIScreen.main.bounds.size.width
        let height = size != nil ? size!.height : UIScreen.main.bounds.size.height
        switch playerQuad {
        case Quadrant.topLeft:
            return CGPoint(x: width * 0.25, y: height * 0.25)
        case Quadrant.topRight:
            return CGPoint(x: width * 0.75, y: height * 0.25)
        case Quadrant.bottomLeft:
            return CGPoint(x: width * 0.25, y: height * 0.70)
        case Quadrant.bottomRight:
            return CGPoint(x: width * 0.75, y: height * 0.70)
        case Quadrant.center:
            return CGPoint(x: width * 0.5, y: height * 0.5)
        }
    }
}


// MARK: - Player Layout Configuration
public struct PlayerLayoutConfig : Sendable {
    public let rotationAngle: Double
    public let isRotated: Bool
    public let isLeftSide: Bool
    public let shouldMirrorLeftCorner: Bool
    public let podLayoutOrder: [Int]
    public let concentricOrder: [Int]
    public let quadrantID: Quadrant
    
    public init(rotationAngle: Double, isRotated: Bool, isLeftSide: Bool, shouldMirrorLeftCorner: Bool, podLayoutOrder: [Int], concentricOrder: [Int], quadrantID: Quadrant) {
        self.rotationAngle = rotationAngle
        self.isRotated = isRotated
        self.isLeftSide = isLeftSide
        self.shouldMirrorLeftCorner = shouldMirrorLeftCorner
        self.podLayoutOrder = podLayoutOrder
        self.concentricOrder = concentricOrder
        self.quadrantID = quadrantID
    }
    
    public static let configurations: [PlayerLayoutConfig] = [
        // Player 0 (Bottom Left)
        PlayerLayoutConfig(
            rotationAngle: 0.0,
            isRotated: false,
            isLeftSide: true,
            shouldMirrorLeftCorner: true,
            podLayoutOrder: [1, 2, 0, 3],
            concentricOrder: [0,1,2,3],
            quadrantID: Quadrant.bottomLeft
        ),
        // Player 1 (Top Left)
        PlayerLayoutConfig(
            rotationAngle: 180.0,
            isRotated: true,
            isLeftSide: false,
            shouldMirrorLeftCorner: false,
            podLayoutOrder: [3, 0, 2, 1],
            concentricOrder: [1,2,3,0],
            quadrantID: Quadrant.topLeft
        ),
        // Player 2 (Top Right)
        PlayerLayoutConfig(
            rotationAngle: 180.0,
            isRotated: true,
            isLeftSide: true,
            shouldMirrorLeftCorner: true,
            podLayoutOrder: [3, 0, 2, 1],
            concentricOrder: [2,3,0,1],
            quadrantID: Quadrant.topRight
        ),
        // Player 3 (Bottom Right)
        PlayerLayoutConfig(
            rotationAngle: 0.0,
            isRotated: false,
            isLeftSide: false,
            shouldMirrorLeftCorner: false,
            podLayoutOrder: [1, 2, 0, 3],
            concentricOrder: [3,0,1,2],
            quadrantID: Quadrant.bottomRight
        )
    ]
    
    public static func config(for playerIndex: Int) -> PlayerLayoutConfig {
        guard playerIndex >= 0 && playerIndex < configurations.count else {
            return configurations[0] // Default to player 0 config as fallback
        }
        return configurations[playerIndex]
    }
}

// MARK: - Player Colors
public struct PlayerColors {
    // Function to get color based on the player index
    public static func color(for index: Int) -> Color {
        switch index {
        case 0: return Color.green   // Bottom Left
        case 1: return Color.orange  // Top Left
        case 2: return Color.blue    // Top Right
        case 3: return Color.purple  // Bottom Right
        case 4: return Color.white     // Center/Special
        default: return Color.red
        }
    }
    
    // Function to get player index based on color (reverse lookup)
    public static func playerIndex(for color: Color) -> Int {
        switch color {
        case Color.green: return 0   // Bottom Left
        case Color.orange: return 1  // Top Left
        case Color.blue: return 2    // Top Right
        case Color.purple: return 3  // Bottom Right
        case Color.white: return 4     // Center/Special
        default: return -1      // Invalid/Unknown
        }
    }
    
    public static let allPlayerColors: [Color] = [Color.green, Color.orange, Color.blue, Color.purple]
}

// MARK: - Convenience Functions
public func getColor(for index: Int) -> Color {
    return PlayerColors.color(for: index)
}

// MARK: - Common Constants
public struct CommonConstants {
    public static let resetAllPlayers = [false, false, false, false]
    public static let startingLife = [40, 40, 40, 40]
    public static let blankLifeArray = [0, 0, 0, 0]
    public static let blankCmdrDamageArray = [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]
}


