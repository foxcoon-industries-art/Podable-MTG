import Foundation
import SwiftData


@Model
final public class Player: Identifiable, Equatable, Hashable {
    /// Core Player data structure - unified across all apps

    public var id: Int
    public var quadrant: Quadrant?
    public var commanderName: String
    public var partnerName: String
    
    public var life: Int
    public var infect: Int
    
    public var commanderTax: Int
    public var commanderDamage: [Int] // From Opponents
    public var totalCommanderDamageDealt: Int

    public var partnerTax: Int
    public var partnerDamage: [Int] // From Opponents
    public var totalPartnerDamageDealt: Int

    public var timePerTurn: [TimeInterval]
    
    public var winner: Bool
    public var eliminated: Bool
    public var eliminationRound: Int?
    public var eliminationTurnID: Int?
    public var eliminationMethod: EliminationMethod
    
    /// Self-rated bracket by each player for all players - deckBrackert[id] is self-bracket
    public var deckBracket: [Int]
    
    // MARK: - Initialization
    
    public init(commanderName: String = "", partnerName: String = "", id: Int, bracket: Int? = nil, missing: Bool? = false ) {
        self.id = id
        let playerNumber = id + 1
        let defaultName = "Player \(playerNumber)"
        self.commanderName = commanderName.isEmpty ? defaultName : commanderName
        self.partnerName = partnerName
        self.quadrant = Quadrant(rawValue: id)
        
        // Initialize with default values
        self.life = GameConstants.defaultStartingLife
        
        self.infect = 0

        self.commanderTax = 0
        self.commanderDamage = Array(repeating: 0, count: 4)


        self.partnerTax = 0
        self.partnerDamage = Array(repeating: 0, count: 4)

        
        self.totalCommanderDamageDealt = 0
        self.totalPartnerDamageDealt = 0
        

        self.timePerTurn = []
        self.winner = false
        self.eliminated = false
        self.eliminationRound = nil
        self.eliminationTurnID = nil
        self.eliminationMethod = EliminationMethod.notEliminated
        
        self.deckBracket = Array(repeating: 0, count: 4)
    }
    
    // MARK: - Game State Updates
    
    public func update(after currentTurn: Turn) {
        guard self.eliminated == false else { return }
        
        /// Track turn duration for active player
        if currentTurn.activePlayer == self.id {
            self.timePerTurn.append(currentTurn.turnDuration)
        }
        /// Apply life changes
        self.life += currentTurn.deltaLife[self.id]
        
        /// Apply commander damage to life
        for dmg in currentTurn.deltaCmdrDamage[self.id] {
            self.life -= dmg
        }
        
        /// Apply partner damage to life
        for dmg in currentTurn.deltaPrtnrDamage[self.id] {
            self.life -= dmg
        }
        
        /// Update infect
        self.infect += currentTurn.deltaInfect[self.id]
        
        /// Update commander damage received
        self.commanderDamage = zip(self.commanderDamage, currentTurn.deltaCmdrDamage[self.id]).map(+)
        self.partnerDamage = zip(self.partnerDamage, currentTurn.deltaPrtnrDamage[self.id]).map(+)
        
        /// Update commander damage dealt
        for i in 0..<4 {
            self.totalCommanderDamageDealt += currentTurn.deltaCmdrDamage[i][self.id]
            self.totalPartnerDamageDealt += currentTurn.deltaPrtnrDamage[i][self.id]
        }
  
        /// Track when player was eliminated
        if self.wasRemoved(on: currentTurn.round) && eliminationRound == nil {
        //if self.wasRemovedOn(currentTurn.id) && eliminationRound == nil {
            self.eliminationRound = self.timePerTurn.count
            self.eliminationTurnID = currentTurn.id
            self.eliminationMethod = determineEliminationMethod()
        }
    }
    
    public func resetPlayer() {
        self.life = GameConstants.defaultStartingLife
        self.infect = 0
        self.commanderTax = 0
        self.commanderDamage = Array(repeating: 0, count: 4)
        self.partnerTax = 0
        self.partnerDamage = Array(repeating: 0, count: 4)
        self.totalCommanderDamageDealt = 0
        self.totalPartnerDamageDealt = 0
        self.timePerTurn = []
        self.winner = false
        self.eliminated = false
        self.eliminationRound = nil
        self.eliminationTurnID = nil
        if self.eliminationMethod != EliminationMethod.emptySeat  {
            self.eliminationMethod = EliminationMethod.notEliminated
        }
    }
    
    
    // MARK: - Player Status Checks
    
    public var hasPartner: Bool {
        return !partnerName.isEmpty
    }
    
    public var deadOrDone: Bool {
        return self.eliminated || self.winner
    }
    
    public func wasRemoved(on round : Int) -> Bool {
        if self.eliminationRound == round {return true}
        let wasEliminated = self.eliminated
        self.eliminated = self.isPlayerEliminated()
        if wasEliminated != self.eliminated {
            return true
        }
        return false
    }
    
    public func wasRemovedOn(_ turnID : Int) -> Bool {
        if self.eliminationTurnID == turnID {return true}
        let wasEliminated = self.eliminated
        self.eliminated = self.isPlayerEliminated()
        if wasEliminated != self.eliminated {
            return true
        }
        return false
    }
    
    
    public func isCommanderEntered() -> Bool {
        if self.commanderName.hasPrefix("Player ") {
            return false
        }
        return true
    }
    
    
    
    public func isPlayerEliminated() -> Bool {
        if self.eliminationMethod != EliminationMethod.notEliminated { return true }
        if self.eliminationMethod == EliminationMethod.concede { return true }
        if self.eliminationMethod == EliminationMethod.milled { return true }
        if self.eliminationMethod == EliminationMethod.altWin { return true }
        
        let lifeLethal = life <= 0
        let commanderLethal = commanderDamage.contains { $0 >= GameConstants.commanderDamageLethal }
        let partnerLethal = partnerDamage.contains { $0 >= GameConstants.commanderDamageLethal }
        let infectLethal = infect >= GameConstants.infectLethal
        
        return lifeLethal || commanderLethal || partnerLethal || infectLethal
    }
    
    
    public func determineEliminationMethod() -> EliminationMethod {
        guard isPlayerEliminated() else { return EliminationMethod.notEliminated }
        
        let lifeLethal = life <= 0
        let commanderLethal = commanderDamage.contains { $0 >= GameConstants.commanderDamageLethal }
        let partnerLethal = partnerDamage.contains { $0 >= GameConstants.commanderDamageLethal }
        let infectLethal = infect >= GameConstants.infectLethal
        
        if infectLethal {
            return EliminationMethod.infect
        } else if commanderLethal {
            return EliminationMethod.commanderDamage
        } else if partnerLethal {
            return EliminationMethod.commanderDamage
        } else if lifeLethal {
            return EliminationMethod.lifeDamage
        }
        
        return EliminationMethod.notEliminated
    }
    
    public func setCommanderPartnerName(names: String) {
        if names.contains("//") {
            let splitNames = names.split(separator: "//", maxSplits:1)
            commanderName = String(splitNames[0])
            partnerName = String(splitNames[1])
        }
        else {
            commanderName = names
        }
    }
    
    public var commanderNameOrRemovePlayerNumberFromDefaultName : String {
        guard self.commanderName.hasPrefix("Player") else { return String(self.commanderName) }
        return String("Player")
    }
    
    
    // MARK: - Data Conversion
    
    public func toCommander() -> [Commander] {
        var cmdrs : [Commander] = []
        cmdrs.append( Commander(
            name: commanderNameOrRemovePlayerNumberFromDefaultName,
            partner: self.partnerName,
            isPartner: false,
            bracket: self.deckBracket,
            tax: self.commanderTax,
            totalCommanderDamage: self.totalCommanderDamageDealt,
            turnOrder: self.id,
            turnDurations: self.timePerTurn,
            winner: self.winner,
            eliminated: self.eliminated,
            eliminationRound: self.eliminationRound,
            eliminationTurnID: self.eliminationTurnID,
            eliminationMethod: self.eliminationMethod
        ))
        if hasPartner {
            cmdrs.append(
                Commander(
                    name: self.partnerName,
                    partner: self.commanderName,
                    isPartner: true,
                    bracket: self.deckBracket,
                    tax: self.partnerTax,
                    totalCommanderDamage: self.totalPartnerDamageDealt,
                    turnOrder: self.id,
                    turnDurations: self.timePerTurn,
                    winner: self.winner,
                    eliminated: self.eliminated,
                    eliminationRound: self.eliminationRound,
                    eliminationTurnID: self.eliminationTurnID,
                    eliminationMethod: self.eliminationMethod
                )
                
            )
        }
        return cmdrs
    }
    
    // MARK: - Static Methods
    
    public static func ==(lhs: Player, rhs: Player) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Player Performance Analysis Extensions

public extension Player {
    var averageTurnDuration: Double {
        guard !timePerTurn.isEmpty else { return 0.0 }
        return timePerTurn.reduce(0, +) / Double(timePerTurn.count)
    }
    
    var totalTurnTime: Double {
        return timePerTurn.reduce(0, +)
    }
    
    var turnCount: Int {
        return timePerTurn.count
    }
    
    var bracketRating: Int {
        guard id < deckBracket.count else { return 0 }
        return deckBracket[id]
    }
    
    var fullCommanderPartnerName: [String] {
        if partnerName.isEmpty {
            return [commanderName]
        } else {
            return [commanderName, partnerName]
        }
    }
    
    var formattedCommanderPartnerName: String {
        if partnerName.isEmpty {
            return commanderName
        } else {
            return "\(commanderName)\n\(partnerName)"
        }
    }
    //-------------------------------- things below are probably unused ------------------
    var winRate: Double {
        return winner ? 100.0 : 0.0
    }
    
    var damageToLifeRatio: Double {
        guard life > 0 else { return 0 }
        return Double(totalCommanderDamageDealt) / Double(life)
    }
}



// MARK: - Array Extensions

public extension Array where Element == Player {
    /// Get the winning commander from an array
    public var winner: Player? {
        return first { $0.winner }
    }
}
