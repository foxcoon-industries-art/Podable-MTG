import Foundation


public struct BracketStatistics: Hashable, Identifiable {
    public let id = UUID()
    public let bracket: Int

    public var games: Int = 0
    public var wins: Int = 0
    public var decks: Int = 0
    private var samerating: Int = 0
    public var totalrated: Int = 0
    public var vibeCheck:  [Int:Int] = [:]
    
    public init(bracket : Int){
        self.bracket = bracket
    }
    
    public var winRate: Double {
        return Double(wins) / (Double(games) != 0 ? Double(games) : 1.0)
    }
    public var sameBracketRate: Double {
        return Double(samerating) / (Double(totalrated) != 0 ? Double(totalrated) : 1.0)
    }
    
    public static func buildAnalysis(from finalStates: [FinalPod]) -> [Int: BracketStatistics] {
        var bracketData: [Int: BracketStatistics] = [:]
        
        for finalState in finalStates {
            for commander in finalState.commanders {
                
                let bracket = commander.bracketRating
                if bracket < 1 { continue }
                bracketData[bracket, default: BracketStatistics(bracket:bracket)].decks += 1
                
                bracketData[bracket, default: BracketStatistics(bracket:bracket)].wins += (commander.winner ? 1 : 0)
                bracketData[bracket]?.games += (commander.winner ? 1 : 0)
                
                let playerID = commander.turnOrder
                for cmdr in finalState.commanders {
                    let opponentID = cmdr.turnOrder
                    if opponentID != playerID {
                        let opponentRatedBracket = cmdr.bracket[playerID]
                        if opponentRatedBracket < 1 { continue }
                        bracketData[bracket]?.samerating += (opponentRatedBracket == bracket ? 1 : 0)
                        bracketData[bracket]?.vibeCheck[opponentRatedBracket, default:0] += (cmdr != commander) ? 1 : 0
                        bracketData[bracket]?.totalrated += 1
                    }
                }
            }
        }
        return bracketData
    }
}
