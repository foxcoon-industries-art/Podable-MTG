
import Foundation
import Podwork


public struct PodTurnMetrics {
    var turnImpact: [Int: Double] = [:]        // Normalized turn impact scores
    var turnEntropy: [Int: Double] = [:]       // Normalized damage entropy
    var averageTurnDuration: TimeInterval = 0
    var turnsWithKills: Set<Int> = []          // Turns where a player was eliminated
    var noDamageTurns: Set<Int> = []           // Defensive/passive turns
    var roundDurationPartition: [Int: Double] = [:]
    var turnPlayersRemoved: [Int: [Int]] = [:]
    
    /// Total commander damage dealt (per player)
    var damageTotals: [Int: Int] = [:]
    
    /// Total life loss damage dealt (per player, includes commander + normal + partner)
    var lifeLossTotals: [Int: Int] = [:]
    
    /// Total poison (infect) damage dealt (per player, tracked separately)
    var poisonTotals: [Int: Int] = [:]
}



public struct PodMetrics {
    
    
    public static func build(from turns: [Turn], playerCount: Int = 4) -> PodTurnMetrics {
        var turnImpact: [Int: Double] = [:]
        var turnEntropy: [Int: Double] = [:]
        var noDamageTurns: Set<Int> = []
        var turnsWithKills: Set<Int> = []
        var roundDurationPartition: [Int:Double] = [:]
        
        var totalImpactDamage: Double = 0
        var totalTurnDurations: TimeInterval = 0
        
        // New: per-player totals
        var commanderDamageTotals: [Int: Int] = [:]
        var lifeLossTotals: [Int: Int] = [:]
        var poisonTotals: [Int: Int] = [:]
        
        // -----------------------------
        // 1. First pass: compute impact and per-player damage
        // -----------------------------
        for turn in turns {
            let id = turn.id
            let active = turn.activePlayer
            
            var damageDealt = 0
            
            // ---- Normal life loss ----
            for (i, delta) in turn.deltaLife.enumerated() where i != active {
                if delta < 0 {
                    let dmg = -delta
                    damageDealt += dmg
                    lifeLossTotals[active, default: 0] += dmg
                }
            }
            
            // ---- Commander damage ----
            for (i, dmg) in turn.deltaCmdrDamage.enumerated() where i != active {
                let dmgValue = max(0, dmg[active])
                if dmgValue > 0 {
                    commanderDamageTotals[active, default: 0] += dmgValue
                    // Commander counts as life loss too
                    lifeLossTotals[active, default: 0] += dmgValue
                    damageDealt += dmgValue
                }
            }
            
            // ---- Partner damage ----
            for (i, dmg) in turn.deltaPrtnrDamage.enumerated() where i != active {
                let dmgValue = max(0, dmg[active])
                if dmgValue > 0 {
                    lifeLossTotals[active, default: 0] += dmgValue
                    damageDealt += dmgValue
                }
            }
            
            // ---- Poison (Infect) ----
            for (i, dmg) in turn.deltaInfect.enumerated() where i != active {
                let dmgValue = max(0, dmg)
                if dmgValue > 0 {
                    // Track separately as poison
                    poisonTotals[active, default: 0] += dmgValue
                    
                    // For impact only, count poison with weight
                    let infectImpact = 2 * dmgValue
                    damageDealt += infectImpact
                }
            }
            
            totalImpactDamage += Double(damageDealt)
            turnImpact[id] = Double(damageDealt)
            
            if damageDealt == 0 {
                noDamageTurns.insert(id)
            }
            
            roundDurationPartition[id] = turn.turnDuration
            totalTurnDurations += turn.turnDuration
        }
        
        // Normalize turn impact values
        var tempImpact = turnImpact
        let totalNonzeroImpacts = Double(turnImpact.map { $0.value }.filter { $0 != 0.0 }.count)
        turnImpact = [:]
        let total = totalImpactDamage > 0 ? totalImpactDamage : 1
        for (id, rawImpact) in tempImpact {
            if rawImpact != 0.0  {
                turnImpact[id] = totalNonzeroImpacts * rawImpact / total
            }
        }
        
        // -----------------------------
        // 2. Detect player deaths
        // -----------------------------
        var previousLifeTotals = Array(repeating: 40, count: playerCount)
        var previousInfectTotals = Array(repeating: 0, count: playerCount)
        var turnPlayersRemoved: [Int:[Int]] = [:]
        
        for turn in turns {
            let id = turn.id
            for i in 0..<playerCount {
                if previousLifeTotals[i] > 0 && turn.lifeTotal[i] <= 0 {
                    turnsWithKills.insert(id-1)
                    turnPlayersRemoved[id, default: []].append(i)
                }
                if previousInfectTotals[i] < 10 && turn.infectTotal[i] >= 10 {
                    turnsWithKills.insert(id-1)
                    turnPlayersRemoved[id, default: []].append(i)
                }
            }
            previousLifeTotals = turn.lifeTotal
            previousInfectTotals = turn.infectTotal
        }
        
        // -----------------------------
        // 3. Entropy calculation
        // -----------------------------
        for turn in turns {
            let id = turn.id
            let active = turn.activePlayer
            
            var perTargetDamage = Array(repeating: 0, count: playerCount)
            var totalDamage = 0
            
            // Life loss sources
            for (i, delta) in turn.deltaLife.enumerated() where i != active {
                if delta < 0 {
                    let dmg = -delta
                    perTargetDamage[i] += dmg
                    totalDamage += dmg
                }
            }
            for (i, dmg) in turn.deltaCmdrDamage.enumerated() where i != active {
                let dmgValue = max(0, dmg[active])
                perTargetDamage[i] += dmgValue
                totalDamage += dmgValue
            }
            for (i, dmg) in turn.deltaPrtnrDamage.enumerated() where i != active {
                let dmgValue = max(0, dmg[active])
                perTargetDamage[i] += dmgValue
                totalDamage += dmgValue
            }
            
            // Poison (separate but contributes to entropy)
            for (i, dmg) in turn.deltaInfect.enumerated() where i != active {
                let dmgValue = max(0, dmg)
                perTargetDamage[i] += 2 * dmgValue  // still weighted for entropy
                totalDamage += 2 * dmgValue
            }
            
            var entropy: Double = 0
            for dmg in perTargetDamage where dmg > 0 {
                let p = Double(dmg) / Double(totalDamage)
                entropy -= p * log2(p)
            }
            
            let playersRemoved = turnPlayersRemoved.map { $0.key <= turn.id ? $0.value.count : 0 }.reduce(0,+)
            let maxEntropy = log2(Double(playerCount - playersRemoved - 1 ))
            
            if entropy != 0 && maxEntropy != 0 {
                turnEntropy[id] = entropy / maxEntropy
            }
        }
        
        // -----------------------------
        // 4. Average & round partition normalization
        // -----------------------------
        var roundSpan = 0.0
        var nPlayers = 0
        var idSeen : [Int] = []
        
        for (idx,turn) in turns.enumerated() {
            nPlayers += 1
            if idSeen.contains(turn.activePlayer) && idx != 0  {
                for i in 1..<(nPlayers){
                    let roundEquipartionDivisor = (roundSpan == 0 || nPlayers == 0) ? 1 : (roundSpan / Double(nPlayers))
                    roundDurationPartition[idx-i] = (roundDurationPartition[idx-i] ?? 0) / roundEquipartionDivisor
                }
                if (idx < turns.count-1) {
                    roundSpan = 0.0
                    nPlayers = 1
                    idSeen = []
                }
            }
            roundSpan += turn.turnDuration
            idSeen.append(turn.activePlayer)
        }
        
        let averageTurnDuration = turns.isEmpty ? 0 : totalTurnDurations / Double(turns.count)
        
        return PodTurnMetrics(
            turnImpact: turnImpact,
            turnEntropy: turnEntropy,
            averageTurnDuration: averageTurnDuration,
            turnsWithKills: turnsWithKills,
            noDamageTurns: noDamageTurns,
            roundDurationPartition: roundDurationPartition,
            turnPlayersRemoved: turnPlayersRemoved,
            damageTotals: commanderDamageTotals,
            lifeLossTotals: lifeLossTotals,
            poisonTotals: poisonTotals
        )
    }
}



import SwiftUI

struct MetricDemo_Previews: PreviewProvider {
    
    static var previews: some View {
        var demoData : [(FinalPod, [Turn], [Int:EliminationMethod])] = DemoDataGenerator.generateDemoGames(count: 1)
        var finalStates : [FinalPod] = demoData.map { $0.0 }
        var turnHistory : [[Turn]] = demoData.map { $0.1 }
 
        let turns = turnHistory.first
        let metrics = PodMetrics.build(from: turns!)
        @State var flippedPodID: String? = nil
        @State var trashable: Bool = false
        //let _ = print(metrics)
        ZStack{
            VStack{
                
                ForEach(finalStates, id: \.gameID) { data in
                   // RecentGameCard(pod: data,
                   //                flippedPodID: $flippedPodID, showingExtended: trashable, onReturn: {})
                    let _ = print(data, "\n")
                }
                
                
//                OptimizedGameFlowCard(
//                    game: finalStates[0],
//                    turnHistory:  turnHistory[0],
//                    on_Appear: { }
//                )
//                
                
                
            }
        }
    }
}
