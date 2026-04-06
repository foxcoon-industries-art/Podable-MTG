import Foundation
import SwiftData


public struct Commander: Codable, Identifiable, Equatable, Hashable {
    public let id = UUID()
    
    public var turnOrder: Int
    
    public var name: String
    public var partner: String
    public let isPartner: Bool

    
    
    public var tax: Int
    public var taxTurns: [Int?]? = []
    
    public var totalCommanderDamage: Int
    

    public var partnerTax: Int? = 0
    public var totalPartnerDamage: Int? = 0
    
    public var turnDurations: [TimeInterval]
    
    public var winner: Bool
    public var eliminated: Bool
    public var eliminationRound: Int?
    public var eliminationTurnID: Int?
    public var eliminationMethod: EliminationMethod
    
    
    public var bracket: [Int]
    
    // MARK: - Computed Properties
    
    public var averageTurnDuration: TimeInterval {
        guard !turnDurations.isEmpty else { return 0.0 }
        return turnDurations.reduce(0, +) / TimeInterval(turnDurations.count)
    }
    
    public var totalTurnTime: TimeInterval {
        return turnDurations.reduce(0, +)
    }
    
    public var turnCount: Int {
        return turnDurations.count
    }
    
    public var bracketRating: Int {
        guard turnOrder < bracket.count else { return 0 }
        return bracket[turnOrder]
    }
    
    public var totalTurns: Double {
        return Double(turnDurations.count)
    }
    
    
    public var fullCommanderName: String {
        if partner.isEmpty {
            return name
        } else {
            return "\(name) // \(partner)"
        }
    }
    
    public var displayNames: String {
        return fullCommanderName.replacingOccurrences(of: "//", with: "\n")
    }
    
    public var isPartnerCommander: Bool {
        return !partner.isEmpty
    }
    
    // MARK: - Initialization
    public init( name: String, partner: String = "", isPartner : Bool = false, bracket: [Int] = Array(repeating: 0, count: 4), tax: Int = 0, totalCommanderDamage: Int = 0, turnOrder: Int = 0, turnDurations: [TimeInterval] = [], winner: Bool = false, eliminated: Bool = false, eliminationRound: Int? = nil, eliminationTurnID: Int? = nil, eliminationMethod: EliminationMethod = EliminationMethod.notEliminated) {
 
        self.name = name
        self.partner = partner
        self.isPartner = isPartner
        self.bracket = bracket
        self.tax = tax
        self.totalCommanderDamage = totalCommanderDamage
        self.turnOrder = turnOrder
        self.turnDurations = turnDurations
        self.winner = winner
        self.eliminated = eliminated
        self.eliminationRound = eliminationRound
        self.eliminationTurnID = eliminationTurnID
        self.eliminationMethod = eliminationMethod
    }
    
    // MARK: - Initialization
    public init( name: String, turnOrder: Int){
        self.name = name
        self.partner = ""
        self.isPartner = false
        self.bracket = []
        self.tax = 0
        self.totalCommanderDamage = 0
        self.turnOrder = turnOrder
        self.turnDurations = []
        self.winner = false
        self.eliminated = false
        self.eliminationRound = -1
        self.eliminationTurnID = -1
        self.eliminationMethod = EliminationMethod.notEliminated
    }
    
    // MARK: - Performance Metrics
    
    public var efficiency: Double {
        guard averageTurnDuration > 0 else { return 0 }
        return Double(totalCommanderDamage) / averageTurnDuration
    }
    
    public var consistency: Double {
        guard turnDurations.count > 1 else { return 100.0 }
        let standardDeviation = turnDurations.standardDeviation
        return max(0, 100 - (standardDeviation / averageTurnDuration * 100))
    }
    
    public var placement: Int {
        if winner { return 1 }
        if let round = eliminationRound {
            // Higher elimination round = better placement
            return 5 - round
        }
        return 4 // Still in game but not winner
    }
}


// MARK: - Commander Extensions

public extension Commander {
    /// Performance rating based on win rate and turn efficiency
    public var performanceRating: Double {
        let winBonus = winner ? 100.0 : 0.0
        let turnEfficiency = averageTurnDuration > 0 ? min(100, 3000 / averageTurnDuration) : 0
        let damageEfficiency = Double(totalCommanderDamage) / max(1.0, Double(totalTurns))
        
        return (winBonus + turnEfficiency + damageEfficiency) / 3.0
    }
    
    /// Check if commander was eliminated by a specific method
    public func wasEliminatedBy(_ method: EliminationMethod) -> Bool {
        // This would need game context to determine exact elimination method
        return eliminated
    }
}

// MARK: - Array Extensions

public extension Array where Element == Commander {
    /// Get the winning commander from an array
    public var winner: Commander? {
        return first { $0.winner }
    }
    
    /// Get commanders sorted by turn order
    public var sortedByTurnOrder: [Commander] {
        return sorted { $0.turnOrder < $1.turnOrder }
    }
    
    /// Get commanders sorted by performance
    public var sortedByPerformance: [Commander] {
        return sorted { $0.performanceRating > $1.performanceRating }
    }
    
    public var rePartner: [Commander] {
        var commanders = self.filter { $0.isPartner == false || $0.partner.isEmpty }
        let partners = self.filter { $0.isPartner }
        
        for partner in partners {
            if var matchingCommanderIndex = commanders.firstIndex(where:
              {$0.partner == partner.name && $0.name == partner.partner && $0.turnOrder == partner.turnOrder}) {
                commanders[matchingCommanderIndex].partnerTax = partner.tax
                commanders[matchingCommanderIndex].totalPartnerDamage = partner.totalCommanderDamage
            }
        }
        return commanders
    }
    
    /// Average bracket rating for all commanders
    public var averageBracket: Double {
        let brackets = compactMap { $0.bracketRating }
        guard !brackets.isEmpty else { return 0 }
        return Double(brackets.reduce(0, +)) / Double(brackets.count)
    }
    
    public var firstRemovalTurn: Int {
        let elimTurns = self.compactMap { $0.eliminated && $0.eliminationMethod != EliminationMethod.emptySeat ? $0.turnCount : nil}
        return elimTurns.min() ?? 1
    }
}
