import Foundation
import SwiftUI


public enum BracketSystem: Int, CaseIterable, Codable {
    case bracket_1 = 1  // One for all
    case bracket_2 = 2
    case bracket_3 = 3  // 2v2
    case bracket_4 = 4
    case bracket_5 = 5  // All for one
    
    public var displayName: String {
        switch self {
        case .bracket_1: return "Story Time"
        case .bracket_2: return "Doing the Thing"
        case .bracket_3: return "Standard Game"
        case .bracket_4: return "Friendly Fight"
        case .bracket_5: return "Race to Win"
        }
    }
    
    public var description: String {
        switch self {
        case .bracket_1: return "Contains a theme or bracket_1 to be told."
        case .bracket_2: return "New builds and testing out ideas."
        case .bracket_3: return "Quote: 'My deck is a 7'."
        case .bracket_4: return "Play solitaire until you can take out the table."
        case .bracket_5: return "Size measuring contest of decks."
        }
    }
    
    public var color: Color {
        switch self {
        case .bracket_1: return Color(red: 0.0, green: 0.6, blue: 1.0)     // Blue
        case .bracket_2: return Color(red: 0.1, green: 0.8, blue: 0.1)      // Light Green
        case .bracket_3: return Color(red: 0.8, green: 0.4, blue: 0.0)   // Orange
        case .bracket_4: return Color(red: 0.7, green: 0.0, blue: 0.7)   // Purple
        case .bracket_5: return Color(red: 1.0, green: 0.0, blue: 0.0)        // Red
        }
    }
    
    
    
    public var secondColor: Color {
        switch self {
        //case .bracket_0: return Color.clear
        case .bracket_1: return Color.indigo
        case .bracket_2: return Color.cyan
        case .bracket_3: return Color.brown
        case .bracket_4: return Color.yellow
        case .bracket_5: return Color.pink
        }
    }
    
    
    public var emoji: String {
        switch self {
        case .bracket_1: return "🗣️📖  👥"
        case .bracket_2: return " 💃🎶🕺 "
        case .bracket_3: return "  🧑‍🤝‍🧑🧑‍🤝‍🧑    "
        case .bracket_4: return "  🤾‍♂️  🤺   "
        case .bracket_5: return " 🏃‍➡️   🏆 🏃"
        }
    }
}


public func bracketColor(_ bracket: Int) -> Color {
    if let bracketLevel = BracketSystem(rawValue: bracket) {
        return ColorPalettes.sunsetOceanMeadow( bracketLevel.rawValue)
    }
    return .gray
}





public class ColorPalettes {
    
    public func bracketColor(_ bracket: BracketSystem) -> Color {
        switch bracket {
        case .bracket_1: return Color(red: 0.1, green: 0.8, blue: 0.1)     // Light Green
        case .bracket_2: return Color(red: 0.0, green: 0.6, blue: 1.0)     // Blue
        case .bracket_3: return Color(red: 0.8, green: 0.4, blue: 0.0)  // Orange
        case .bracket_4: return Color(red: 0.7, green: 0.0, blue: 0.7)  // Purple
        case .bracket_5: return Color(red: 1.0, green: 0.0, blue: 0.0)  // Red
        }
    }
    
    public static func pbCup(_ bracket: Int) -> Color {
        switch bracket {
        case 1: return Color.hex("#ff5d00")     // Orange
        case 2: return Color.hex("#ffc000")     // Yellow
        case 3: return Color.hex("#5b391b")  // Brown
        case 4: return Color.hex("#976639")  // Peanut
        case 5: return Color.hex("#2f1c0b")  // Chocolate
        default:
            return Color.clear
        }
    }
    
    public static func sweetSpringDelight(_ bracket: Int) -> Color {
        switch bracket {
        case 1: return Color.hex("#FF99C8")     // pwink
        case 2: return Color.hex("#FCF6BD")     // Lellow
        case 3: return Color.hex("#D0F4DE")  // gween
        case 4: return Color.hex("#A9DEF9")  // bwoo
        case 5: return Color.hex("#D0F4DE")  // gween
            
        default:
            return Color.clear
        }
    }
    
    public static func sunsetOceanMeadow(_ bracket: Int) -> Color {
        switch bracket {
        case 1: return Color.hex("#c77dff")  // Purple // "#9B5DE5"
        case 2: return Color.hex("#00A6ED")  // bloo
            //case 3: return Color.hex("#7FB800")  // peagween
        case 3: return Color.hex("#70e000")  // peagween
        case 4: return Color.hex("#FFB400")     // mangwo
        case 5: return Color.hex("#F6511D")     // rowrange
            
        default:
            return Color.clear
        }
    }
    
    public static func neutralHarmonyBliss(_ bracket: Int) -> Color {
        switch bracket {
        case 1: return Color.hex("#E07A5F")     // fwuit
        case 2: return Color.hex("#3D405B")     // bewwry
        case 3: return Color.hex("#81B29A")  // gwava
        case 4: return Color.hex("#F2CC8F")  // sand
        case 5: return Color.hex("#F2CC8F")  // sand
            
        default:
            return Color.clear
        }
    }
    
    public static func watermelonSorbet(_ bracket: Int) -> Color {
        switch bracket {
        case 1: return Color.hex("#ef476f")     // fwuit
        case 2: return Color.hex("#ffd166")     // bewwry
        case 3: return Color.hex("#06d6a0")  // gwava
        case 4: return Color.hex("#118ab2")  // sand
        case 5: return Color.hex("#073b4c")  // sand
            
        default:
            return Color.clear
        }
    }
    
}
