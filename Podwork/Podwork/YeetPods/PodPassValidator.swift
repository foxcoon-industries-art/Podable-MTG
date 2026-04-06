import Foundation
import SwiftUI
import Podwork

// MARK: - Pod Pass Validation

public struct PodPassValidator {
    
    public enum ValidationFailure {
        case hasDefaultCommanderNames(playerIndices: [Int])
        case missingBracketRatings(playerIndices: [Int])
        case commanderDamageWithoutTax(playerIndex: Int, turnID: Int, partner: Bool)
        case turnTooShort(turnID: Int, duration: TimeInterval)
        case commanderDamageDecreased(playerIndex: Int, turnID: Int, previousDamage: Int, currentDamage: Int)
        case lifeTotalIncreaseExcessive(playerIndex: Int, turnID: Int, increase: Int)
        case suspiciousTurnDurationPattern(averageDuration: TimeInterval, suspiciousTurnCount: Int)
        
        var description: String {
            switch self {
            case .hasDefaultCommanderNames(let indices):
                return "Players at positions \(indices.map { $0 + 1 }) have default commander names"
            case .missingBracketRatings(let indices):
                return "Players at positions \(indices.map { $0 + 1 }) are missing bracket ratings"
            case .commanderDamageWithoutTax(let playerIndex, let turnID, let partner):
                return "Player \(playerIndex + 1) dealt \(partner ? "partner" : "commander") damage on turn \(turnID) without prior tax record"
            case .turnTooShort(let turnID, let duration):
                return "Turn \(turnID) lasted only \(String(format: "%.1f", duration)) seconds"
            case .commanderDamageDecreased(let playerIndex, let turnID, let previous, let current):
                return "Player \(playerIndex + 1) commander damage decreased from \(previous) to \(current) on turn \(turnID)"
            case .lifeTotalIncreaseExcessive(let playerIndex, let turnID, let increase):
                return "Player \(playerIndex + 1) gained \(increase) life on turn \(turnID) (potential data error)"
            case .suspiciousTurnDurationPattern(let avgDuration, let suspiciousTurnCount):
                return "\(suspiciousTurnCount) turns with suspicious durations detected (avg: \(String(format: "%.1f", avgDuration))s)"
            }
        }
    }
    
    public struct ValidationResult {
        public let isValid: Bool
        public let failures: [ValidationFailure]
        
        public var failureDescriptions: [String] {
            failures.map { $0.description }
        }
    }
    
    public static let defaultCommanderNames = [
        "Player 1",
        "Player 2",
        "Player 3",
        "Player 4"
    ]
    
    public static let minimumTurnDuration: TimeInterval = 2.0
    public static let suspiciousLifeGainThreshold = 100
    public static let maxReasonableTurnDuration: TimeInterval = 600.0 // 10 minutes
    
    @Environment(\.modelContext)  var modelContext
    
    
    public static func validatePodForPass(pod: FinalPod, turns: [Turn]) -> ValidationResult {
        var failures: [ValidationFailure] = []
        //var podCasts = PodCastHistory.load(from: modelContext, podID: pod.gameID)
        // Rule 1: Check for default commander names (except empty seats)
        let defaultNameFailures = checkDefaultCommanderNames(commanders: pod.commanders)
        failures.append(contentsOf: defaultNameFailures)
        
        // Rule 2: Check all brackets are rated (except empty seats)
        let bracketFailures = checkBracketRatings(commanders: pod.commanders)
        failures.append(contentsOf: bracketFailures)
        
        // Rule 3: Commander damage requires prior tax recording
        let taxFailures = checkCommanderTaxBeforeDamage(commanders: pod.commanders, turns: turns)
        failures.append(contentsOf: taxFailures)
        
        // Rule 4: No turns under minimum duration
        let durationFailures = checkMinimumTurnDurations(turns: turns)
        failures.append(contentsOf: durationFailures)
        
        // Rule 5: Commander damage should not decrease
        let damageDecreaseFailures = checkCommanderDamageNeverDecreases(turns: turns)
        failures.append(contentsOf: damageDecreaseFailures)
        
        // Additional validation: Check for suspicious life gain patterns
        let lifeGainFailures = checkSuspiciousLifeGains(turns: turns)
        failures.append(contentsOf: lifeGainFailures)
        
        // Additional validation: Check for suspicious turn duration patterns
        let patternFailures = checkSuspiciousTurnPatterns(turns: turns)
        failures.append(contentsOf: patternFailures)
        
        return ValidationResult(isValid: failures.isEmpty, failures: failures)
    }
    
    // MARK: - Rule 1: Default Commander Names
    
    public static func checkDefaultCommanderNames(commanders: [Commander]) -> [ValidationFailure] {
        var failures: [ValidationFailure] = []
        var playersWithDefaults: [Int] = []
        
        for commander in commanders {
            // Skip empty seat players
            if commander.eliminationMethod == .emptySeat {
                continue
            }
            
            // Check if name is default
            if defaultCommanderNames.contains(commander.name) {
                playersWithDefaults.append(commander.turnOrder)
            }
        }
        
        if !playersWithDefaults.isEmpty {
            failures.append(.hasDefaultCommanderNames(playerIndices: playersWithDefaults))
        }
        
        return failures
    }
    
    // MARK: - Rule 2: Bracket Ratings
    
    public static func checkBracketRatings(commanders: [Commander]) -> [ValidationFailure] {
        var failures: [ValidationFailure] = []
        var playersWithoutRatings: [Int] = []
        
        for commander in commanders {
            // Skip empty seat players
            if commander.eliminationMethod == .emptySeat {
                continue
            }
            
            // Check if all bracket ratings are present (non-zero)
            // Each player should have rated all other players
            let hasAllRatings = commander.bracket.allSatisfy { $0 > 0 }
            
            if !hasAllRatings {
                playersWithoutRatings.append(commander.turnOrder)
            }
        }
        
        if !playersWithoutRatings.isEmpty {
            failures.append(.missingBracketRatings(playerIndices: playersWithoutRatings))
        }
        
        return failures
    }
    
    // MARK: - Rule 3: Commander Tax Before Damage
    
    
    public static func checkCommanderTaxBeforeDamage(commanders: [Commander], turns: [Turn]) -> [ValidationFailure] {
        var failures: [ValidationFailure] = []
        
      
        // Check each turn for commander damage
        for turn in turns {
            // Check commander damage
            
            for commander in commanders {
                let playerIndex = commander.turnOrder
                if turn.cmdrDamageDealtByPlayer(playerIndex) > 0 {
                    if commander.tax < 1 {
                        failures.append(.commanderDamageWithoutTax(playerIndex: playerIndex, turnID: turn.id, partner: false))
                    }
                   
                }
                
                if turn.prtnrDamageDealtByPlayer(playerIndex) > 0 {
                    if let partnerTax = commander.partnerTax, (partnerTax < 1) {
                        // Partner was not cast but did damage
                        failures.append(.commanderDamageWithoutTax(playerIndex: playerIndex, turnID: turn.id, partner: true))
                    }
                }
            }
         
        }
        
        return failures
    }
    
    // MARK: - Rule 4: Minimum Turn Duration
    
    public static func checkMinimumTurnDurations(turns: [Turn]) -> [ValidationFailure] {
        var failures: [ValidationFailure] = []
        
        // Last Turn will always have Zero duration.
        for turn in turns.dropLast() {
            if turn.turnDuration < minimumTurnDuration && turn.turnDuration > 0 {
                failures.append(.turnTooShort(turnID: turn.id, duration: turn.turnDuration))
            }
        }
        
        return failures
    }
    
    // MARK: - Rule 5: Commander Damage Never Decreases
    
    public static func checkCommanderDamageNeverDecreases(turns: [Turn]) -> [ValidationFailure] {
        var failures: [ValidationFailure] = []
        
        // Track commander damage totals per player over time
        // Structure: [playerReceiving][playerDealing] = total damage
        var previousCmdrDamage: [[Int]] = Array(repeating: Array(repeating: 0, count: 4), count: 4)
        var previousPrtnrDamage: [[Int]] = Array(repeating: Array(repeating: 0, count: 4), count: 4)
        
        for turn in turns {
            // Check commander damage totals
            for playerIndex in 0..<4 {
                for opponentIndex in 0..<4 {
                    let currentTotal = turn.cmdrDmgTotal[playerIndex][opponentIndex]
                    let previousTotal = previousCmdrDamage[playerIndex][opponentIndex]
                    
                    if currentTotal < previousTotal {
                        failures.append(.commanderDamageDecreased(
                            playerIndex: playerIndex,
                            turnID: turn.id,
                            previousDamage: previousTotal,
                            currentDamage: currentTotal
                        ))
                    }
                    
                    // Check partner damage
                    let currentPrtnrTotal = turn.prtnrDmgTotal[playerIndex][opponentIndex]
                    let previousPrtnrTotal = previousPrtnrDamage[playerIndex][opponentIndex]
                    
                    if currentPrtnrTotal < previousPrtnrTotal {
                        failures.append(.commanderDamageDecreased(
                            playerIndex: playerIndex,
                            turnID: turn.id,
                            previousDamage: previousPrtnrTotal,
                            currentDamage: currentPrtnrTotal
                        ))
                    }
                }
            }
            
            // Update tracking
            previousCmdrDamage = turn.cmdrDmgTotal
            previousPrtnrDamage = turn.prtnrDmgTotal
        }
        
        return failures
    }
    
    // MARK: - Additional Validation: Suspicious Life Gains
    
    public static func checkSuspiciousLifeGains(turns: [Turn]) -> [ValidationFailure] {
        var failures: [ValidationFailure] = []
        
        for turn in turns {
            for (playerIndex, lifeChange) in turn.deltaLife.enumerated() {
                // Flag excessive life gain as potentially suspicious
                if lifeChange > suspiciousLifeGainThreshold {
                    failures.append(.lifeTotalIncreaseExcessive(
                        playerIndex: playerIndex,
                        turnID: turn.id,
                        increase: lifeChange
                    ))
                }
            }
        }
        
        return failures
    }
    
    // MARK: - Additional Validation: Suspicious Turn Patterns
    
    public static func checkSuspiciousTurnPatterns(turns: [Turn]) -> [ValidationFailure] {
        var failures: [ValidationFailure] = []
        
        // Identify turns with unrealistically long durations
        var suspiciousTurns: [Turn] = []
        
        for turn in turns {
            if turn.turnDuration > maxReasonableTurnDuration {
                suspiciousTurns.append(turn)
            }
        }
        
        if !suspiciousTurns.isEmpty {
            let avgDuration = suspiciousTurns.map { $0.turnDuration }.reduce(0, +) / Double(suspiciousTurns.count)
            failures.append(.suspiciousTurnDurationPattern(
                averageDuration: avgDuration,
                suspiciousTurnCount: suspiciousTurns.count
            ))
        }
        
        return failures
    }
}

// MARK: - Extension for YeetPodView Integration

public extension Array where Element == (FinalPod, [Turn]) {
    public func filterEligibleForPodPass() -> [(FinalPod, [Turn])] {
        return self.filter { pod, turns in
            let validation = PodPassValidator.validatePodForPass(pod: pod, turns: turns)
            return validation.isValid
        }
    }
    
    public func podPassValidationResults() -> [String: PodPassValidator.ValidationResult] {
        var results: [String: PodPassValidator.ValidationResult] = [:]
        for (pod, turns) in self {
            let validation = PodPassValidator.validatePodForPass(pod: pod, turns: turns)
            results[pod.gameID] = validation
        }
        return results
    }
}
