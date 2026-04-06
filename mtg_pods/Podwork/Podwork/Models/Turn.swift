import Foundation
import SwiftUI
import SwiftData


@Model
final public class Turn: Identifiable, Equatable, Hashable {
    /// Represents a single turn in the game with delta changes and totals
    ///
    public var id: Int
    public var activePlayer: Int
    public var round: Int

    /// Current totals at end of turn
    public var lifeTotal: [Int]
    public var infectTotal: [Int]
    public var cmdrDmgTotal: [[Int]]
    public var prtnrDmgTotal: [[Int]]
    
    /// Changes made during this turn
    public var deltaLife: [Int]
    public var deltaInfect: [Int]
    public var deltaCmdrDamage: [[Int]]
    public var deltaPrtnrDamage: [[Int]]
    
    /// Turn timing
    public var whenTurnEnded: Date
    public var turnDuration: TimeInterval
    
    
    
    // MARK: - Initialization
    
    public init(activePlayer: Int, id: Int, round: Int, deltaLife: [Int], deltaInfect: [Int], whenTurnEnded: Date, deltaCmdrDamage: [[Int]], deltaPrtnrDamage: [[Int]], lifeTotal: [Int], infectTotal: [Int], cmdrDmgTotal: [[Int]], prtnrDmgTotal: [[Int]]) {
        
        self.activePlayer = activePlayer
        self.id = id
        self.round = round
        self.deltaLife = deltaLife
        self.deltaInfect = deltaInfect
        self.whenTurnEnded = whenTurnEnded
        self.turnDuration = 0.0 // Will be calculated when turn ends
        self.deltaCmdrDamage = deltaCmdrDamage
        self.deltaPrtnrDamage = deltaPrtnrDamage
        self.lifeTotal = lifeTotal
        self.infectTotal = infectTotal
        self.cmdrDmgTotal = cmdrDmgTotal
        self.prtnrDmgTotal = prtnrDmgTotal
    }

    /// Create a new turn based on the previous turn
    public init(from previousTurn: Turn, with newActivePlayer: Int, after newWhenTurnEnded: Date) {
        /// Reset delta arrays for new turn
        var resetDelta: [Int] = Array(repeating: 0, count: 4)
        var updatedCmdrDamage: [[Int]] = Array(repeating: Array(repeating: 0, count: 4), count: 4)
        var updatedPrtnrDamage: [[Int]] = Array(repeating: Array(repeating: 0, count: 4), count: 4)
        
        self.activePlayer = newActivePlayer
        self.id = previousTurn.id + 1  
        self.round = previousTurn.round 

        /// Calculate new totals based on previous turn's deltas
        
        var calculatedLifeTotal = zip(previousTurn.lifeTotal, previousTurn.deltaLife).map(+)
        self.infectTotal = zip(previousTurn.infectTotal, previousTurn.deltaInfect).map(+)
        
        /// Calculate commander damage totals and apply to life

        for playerIndex in 0..<4 {
            /// Apply commander damage to life total
            for cmdrDmg in previousTurn.deltaCmdrDamage[playerIndex] {
                calculatedLifeTotal[playerIndex] -= cmdrDmg
            }
            for prtnrDmg in previousTurn.deltaPrtnrDamage[playerIndex] {
                calculatedLifeTotal[playerIndex] -= prtnrDmg
            }
            
            
            /// Update commander damage totals
            updatedCmdrDamage[playerIndex] = zip(previousTurn.cmdrDmgTotal[playerIndex], previousTurn.deltaCmdrDamage[playerIndex]).map(+)
            updatedPrtnrDamage[playerIndex] = zip(previousTurn.prtnrDmgTotal[playerIndex], previousTurn.deltaPrtnrDamage[playerIndex]).map(+)
        }
        
        self.cmdrDmgTotal = updatedCmdrDamage
        self.prtnrDmgTotal = updatedPrtnrDamage
        
        self.lifeTotal = calculatedLifeTotal

        // Reset deltas for new turn
        self.deltaLife = resetDelta
        self.deltaInfect = resetDelta
        self.deltaCmdrDamage = Array(repeating: Array(repeating: 0, count: 4), count: 4)
        self.deltaPrtnrDamage = Array(repeating: Array(repeating: 0, count: 4), count: 4)

        self.whenTurnEnded = previousTurn.whenTurnEnded
        self.turnDuration = 0.0
    }
    
    /// Create initial turn for game start
    public static func initialTurn(firstPlayer: Int, gameStartTime: Date) -> Turn {
        return Turn(
            activePlayer: firstPlayer,
            id: 0,
            round: 0,
            deltaLife: Array(repeating: 0, count: 4),
            deltaInfect: Array(repeating: 0, count: 4),
            whenTurnEnded: gameStartTime,
            deltaCmdrDamage: Array(repeating: Array(repeating: 0, count: 4), count: 4),
            deltaPrtnrDamage: Array(repeating: Array(repeating: 0, count: 4), count: 4),
            lifeTotal: Array(repeating: GameConstants.defaultStartingLife, count: 4),
            infectTotal: Array(repeating: 0, count: 4),
            cmdrDmgTotal: Array(repeating: Array(repeating: 0, count: 4), count: 4),
            prtnrDmgTotal: Array(repeating: Array(repeating: 0, count: 4), count: 4)
        )
    }
    
    // MARK: - Turn Analytics
    
    public var hasChanges: Bool {
        return !deltaLife.allSatisfy({ $0 == 0 }) ||
               !deltaInfect.allSatisfy({ $0 == 0 }) ||
               !deltaCmdrDamage.allSatisfy({ row in row.allSatisfy({ $0 == 0 }) }) ||
               !deltaPrtnrDamage.allSatisfy({ row in row.allSatisfy({ $0 == 0 }) })
    }
    
    public var netLifeChange: Int {
        return deltaLife.reduce(0, +)
    }
    
    public var netInfectChange: Int {
        return deltaInfect.reduce(0, +)
    }
    
    public var totalCommanderDamageDealt: Int {
        return deltaCmdrDamage.flatMap({ $0 }).reduce(0, +)
    }

    public var totalPartnerDamageDealt: Int {
        return deltaPrtnrDamage.flatMap({ $0 }).reduce(0, +)
    }

    public func getCommanderDamageWithDeltas(for playerID: Int) -> [[Int]] {
        guard playerID < cmdrDmgTotal.count else { return [[0]] }
        guard playerID < deltaCmdrDamage.count else { return [[0]] }
        guard playerID < prtnrDmgTotal.count else { return [[0]] }
        guard playerID < deltaPrtnrDamage.count else { return [[0]] }
        
        
        var damagesFromOpponents : [[Int]] = []
        for i in 0..<cmdrDmgTotal.count {

            damagesFromOpponents.append([self.cmdrDmgTotal[playerID][i],
                                             self.deltaCmdrDamage[playerID][i],
                                             self.prtnrDmgTotal[playerID][i],
                                             self.deltaPrtnrDamage[playerID][i]])
   
        }
        
        return damagesFromOpponents
    }

    public func colorCmdrDamage(for playerID: Int) ->  [[Color: Int]] {
        var playerClrDmgs : [[Color:Int]] = []
        for playID in 0..<4 {
            var colorDmgDic:[Color:Int] = [:]
            for oppID in 0..<4 {
                colorDmgDic[getColor(for: oppID)] = self.cmdrDmgTotal[playID][oppID]
            }
            playerClrDmgs.append(colorDmgDic)
        }
        return playerClrDmgs
    }
    
    /* ------------------------Everything below is probably not used ------------------------------*/
//    public func damageReceivedByPlayer(_ playerIndex: Int) -> Int {
//        guard playerIndex < deltaCmdrDamage.count else { return 0 }
//        return deltaCmdrDamage[playerIndex].reduce(0, +)
//    }
    
//    public func damageDealtByPlayer(_ playerIndex: Int) -> Int {
//        guard playerIndex < 4 else { return 0 }
//        return deltaCmdrDamage.compactMap { $0.count > playerIndex ? $0[playerIndex] : nil }.reduce(0, +)
//    }
    
    public func cmdrDamageDealtByPlayer(_ playerIndex: Int) -> Int {
        guard playerIndex < 4 else { return 0 }
        return self.deltaCmdrDamage.compactMap {$0[playerIndex] }.reduce(0, +)
    }
    
    public func prtnrDamageDealtByPlayer(_ playerIndex: Int) -> Int {
        guard playerIndex < 4 else { return 0 }
        return self.deltaPrtnrDamage.compactMap {  $0[playerIndex] }.reduce(0, +)
    }
    
    // MARK: - Validation
    
    public var isValid: Bool {
        // Ensure all arrays have correct size
        guard deltaLife.count == 4,
              deltaInfect.count == 4,
              deltaCmdrDamage.count == 4,
              lifeTotal.count == 4,
              infectTotal.count == 4,
              cmdrDmgTotal.count == 4 else { return false }
        
        // Ensure inner commander damage arrays have correct size
        guard deltaCmdrDamage.allSatisfy({ $0.count == 4 }),
              cmdrDmgTotal.allSatisfy({ $0.count == 4 }) else { return false }
        
        // Ensure active player is valid
        guard activePlayer >= 0 && activePlayer < 4 else { return false }
        
        // Ensure no negative totals where they shouldn't be
        guard infectTotal.allSatisfy({ $0 >= 0 }),
              cmdrDmgTotal.allSatisfy({ row in row.allSatisfy({ $0 >= 0 }) }) else { return false }
        
        return true
    }
    
    // MARK: - Equatable
    
    public static func == (lhs: Turn, rhs: Turn) -> Bool {
        return lhs.id == rhs.id &&
               lhs.activePlayer == rhs.activePlayer &&
               lhs.round == rhs.round
    }
}




// MARK: - Turn Analysis Extensions

public extension Turn {
    var formattedDuration: String {
        return turnDuration.formattedDuration(style: .compact)
    }
    
    var isLongTurn: Bool {
        return turnDuration > GameConstants.longTurnDuration
    }
    
    var activePlayerName: String {
        return "Player \(activePlayer + 1)"
    }
    
    var summary: String {
        var summary = "Turn \(id + 1) - \(activePlayerName)"
        
        if hasChanges {
            let changes = [
                netLifeChange != 0 ? "Life: \(netLifeChange > 0 ? "+" : "")\(netLifeChange)" : nil,
                netInfectChange != 0 ? "Infect: +\(netInfectChange)" : nil,
                totalCommanderDamageDealt != 0 ? "Cmdr Dmg: \(totalCommanderDamageDealt)" : nil
            ].compactMap { $0 }
            
            if !changes.isEmpty {
                summary += " [\(changes.joined(separator: ", "))]"
            }
        }
        
        summary += " - \(formattedDuration)"
        return summary
    }
}



// MARK: - Array Extension for Final State
public extension Array where Element == Turn {
    
    public func totalCommanderDamageFrom(playerID: Int) -> Int {
        let cmdrDmg = self.map { $0.cmdrDamageDealtByPlayer(playerID) }.reduce(0,+)
        //let prtnrDmg = self.flatMap { $0.deltaPrtnrDamage}.flatMap { $0.reduce(0,+) }.reduce(0,+)
        return cmdrDmg //+ prtnrDmg
    }
    
    public var totalDamage : Int {
        return -totalCommanderDamage + self.flatMap { $0.deltaLife} .reduce(0,+)
    }
    
    public var totalCommanderDamage: Int {
        let cmdrDmg = self.flatMap { $0.deltaCmdrDamage}.flatMap { $0.reduce(0,+) }.reduce(0,+)
        //let prtnrDmg = self.flatMap { $0.deltaPrtnrDamage}.flatMap { $0.reduce(0,+) }.reduce(0,+)
        return cmdrDmg //+ prtnrDmg
    }
    
    public func playerPoisonTotal(playerID: Int) -> Int {
        return self.map { $0.deltaInfect[playerID]} .reduce(0,+)
    }
    public func playerPoisonCounters() -> [Int] {
        return [0,1,2,3].map{ playerPoisonTotal(playerID: $0) }
        ///return self.map { $0.deltaInfect}}.reduce([0,0,0,0], { x, y in
    }
    
    public func playerLifeTotal(playerID: Int) -> Int {
        return self.map { $0.deltaInfect[playerID]} .reduce(0,+)
    }
    public func playerMinMaxLife() -> LifeOfPlayers {
        var lifeOfPlayers: LifeOfPlayers = LifeOfPlayers()
        
        for turn in self {
            for (idx, delta) in turn.deltaLife.enumerated() {
                lifeOfPlayers.update(playerID: idx, deltaLife:delta )
            }
        }
        return lifeOfPlayers
        ///return self.map { $0.deltaInfect}}.reduce([0,0,0,0], { x, y in
    }
}

public class LifeOfPlayers : Identifiable {

//    public var life: [Int: PlayerLifeStats] = [0: PlayerLifeStats(abv:0, sub:0),
//                    1: PlayerLifeStats(abv:0, sub:0),
//                    2: PlayerLifeStats(abv:0, sub:0),
//                    3: PlayerLifeStats(abv:0, sub:0)]
  
    public var life: [PlayerLifeStats] = Array([PlayerLifeStats(abv:0, sub:0),
                                          PlayerLifeStats(abv:0, sub:0),
                                          PlayerLifeStats(abv:0, sub:0),
                                          PlayerLifeStats(abv:0, sub:0)])
    public func update(playerID: Int, deltaLife: Int) {
        self.life[playerID].abv += deltaLife > 0 ? deltaLife : 0
        self.life[playerID].sub += deltaLife < 0 ? deltaLife : 0
    }
}

public struct PlayerLifeStats: Identifiable {
    public var id = UUID()
    public var abv: Int
    public var sub: Int
}

public extension Array where Element == Turn {
    public func aggregatedCmdrDamage() -> [[Int]] {
        /// Build a 4×4 matrix of zeros
        var totals = (0..<4).map { _ in
            (0..<4).map { _ in 0 }
        }
        
        // Aggregate damage
        for turn in self {
            for playerID in 0..<4 {
                for opponentID in 0..<4 {
                    let damageTaken = turn.deltaCmdrDamage[playerID][opponentID]
                    totals[opponentID][playerID] += damageTaken
                }
            }
        }
        
        /// Reorder rows [1, 2, 3, 0]
        let order = [0, 1, 2, 3]
        let reordered = order.map { totals[$0] }
        
        return reordered
    }
    public func aggregatedCmdrDamageAsDoubles() -> [[Double]] {
        let totals = self.aggregatedCmdrDamage()
        return totals.map { row in row.map { Double($0) } }
    }
    
 
    public func commanderDamagePerPlayerPerTurn(commanderNames: [String]) -> [String: [Int: Int]] {
            
        /// Builds a dictionary of commander damage dealt per commander per turn number.
        /// - Parameter commanderNames: Commander names sorted by turn order (e.g., from `FinalPod.sortedCommanderNames`)
        /// - Returns: [commanderName: [turnNumber: totalCmdrDamage]]
        ///
        guard !self.isEmpty else { return [:] }
        
        // Tracks how many turns each player has taken so far
        var playerTurnCounters : [Int] = [] // Array(repeating: 0, count: commanderNames.count)
        
        // Final dictionary to return
        var damageByCommander: [String: [Int: Int]] = [:]
        for name in commanderNames {
            damageByCommander[name] = [:]
            playerTurnCounters.append(0)
        }
        
        for turn in self {
            let playerIndex = turn.activePlayer
            guard playerIndex < commanderNames.count else { continue }
            
            // Increment that player's personal turn counter
            playerTurnCounters[playerIndex] += 1
            let currentTurnNumber = playerTurnCounters[playerIndex]
            
            // Calculate commander damage dealt *by* that player this turn
            let cmdrDamageDealt = turn.cmdrDamageDealtByPlayer(playerIndex)
            
            // Record in the dictionary
            let commanderName = commanderNames[playerIndex]
            damageByCommander[commanderName]?[currentTurnNumber] = cmdrDamageDealt
        }
        
        return damageByCommander
    }

}

public extension Array where Element == [String: [Int: Int]] {
    /// Combines multiple per-game commander damage dictionaries into
    /// per-commander damage distributions across all games.
    ///
    /// Returns a dictionary of the form:
    /// [commanderName: [turnNumber: [damageValuesAcrossGames]]]
    func combinedDamageDistributionsByCommander() -> [String: [Int: [Int]]] {
        var result: [String: [Int: [Int]]] = [:]
        
        for gameDict in self {
            for (commanderName, turnDict) in gameDict {
                for (turnNum, dmg) in turnDict {
                    result[commanderName, default: [:]][turnNum, default: []].append(dmg)
                }
            }
        }
        
        return result
    }
}


