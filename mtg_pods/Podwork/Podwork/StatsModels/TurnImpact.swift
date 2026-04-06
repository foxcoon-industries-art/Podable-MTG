import Foundation
import Podwork

struct TurnImpact {
    let turnID: Int
    let impactRatio: Double
}


///
///let baseColor = Color.red
///let scaledImpact = min(1.0, impactRatio * 4) // exaggerate small values for visibility
///let finalColor = baseColor.opacity(scaledImpact)
///
func computeTurnImpactScores(from turns: [Turn]) -> [TurnImpact] {
    // Total game damage
    var totalDamage = 0
    var turnImpactScores: [TurnImpact] = []

    for turn in turns {
        var turnDamage = 0

        // Sum delta life
        for dmg in turn.deltaLife {
            if dmg < 0 {
                turnDamage += -dmg
            }
        }

        // Sum delta commander damage
        for dmgArray in turn.deltaCmdrDamage {
            for dmg in dmgArray where dmg > 0 {
                turnDamage += dmg
            }
        }

        // Sum delta partner damage
        for dmgArray in turn.deltaPrtnrDamage {
            for dmg in dmgArray where dmg > 0 {
                turnDamage += dmg
            }
        }

        totalDamage += turnDamage

        turnImpactScores.append(
            TurnImpact(turnID: turn.id, impactRatio: Double(turnDamage)) // divide later
        )
    }

    guard totalDamage > 0 else {
        return turnImpactScores.map { TurnImpact(turnID: $0.turnID, impactRatio: 0) }
    }

    // Finalize with actual ratios
    return turnImpactScores.map {
        TurnImpact(turnID: $0.turnID, impactRatio: $0.impactRatio / Double(totalDamage))
    }
}


func totalDamageDealtByPlayer(_ playerIndex: Int, in turns: [Turn]) -> Int {
    var total = 0
    
    for turn in turns where turn.activePlayer == playerIndex {
        for (target, dmg) in turn.deltaLife.enumerated() where target != playerIndex && dmg < 0 {
            total += -dmg
        }
        
        for (target, dmgArray) in turn.deltaCmdrDamage.enumerated() where target != playerIndex {
            total += max(0, dmgArray[playerIndex])
        }
        
        for (target, dmgArray) in turn.deltaPrtnrDamage.enumerated() where target != playerIndex {
            total += max(0, dmgArray[playerIndex])
        }
    }
    
    return total
}


/*
 | Icon String                            | Meaning / Use Case                        |
 | -------------------------------------- | ----------------------------------------- |
 | `"flame"`                              | High damage turn (tip > threshold)        |
 | `"target"`                             | Focused (low entropy) turn                |
 | `"circle.grid.cross"`                  | Spread damage (high entropy)              |
 | `"timer"`                              | Long turn (above average duration)        |
 | `"hare"`                               | Fast turn (very short duration)           |
 | `"tortoise"`                           | Slower turn (dragged out)                 |
 | `"crown"`                              | Commander cast this turn                  |
 | `"person.crop.circle.badge.checkmark"` | Player eliminated another (kill turn)     |
 | `"exclamationmark.triangle"`           | Sudden swing turn / tipping point         |
 | `"sparkles"`                           | "Epic turn" (high impact + kill or swing) |
 | `"scissors"`                           | Board wipe or mass damage                 |
 | `"shield"`                             | Defensive play (no damage dealt)          |
 | `"arrow.3.trianglepath"`               | Chaos — damage spread across all players  |
 | `"bolt.circle"`                        | Combo turn (cluster of effects/damage)    |
 | `"wand.and.stars"`                     | Unexpected or flashy play                 |

 
 func iconForTurn(turn: Turn, metrics: GameMetrics) -> String? {
 let impact = metrics.turnImpact[turn.id] ?? 0
 let entropy = metrics.turnEntropy[turn.id] ?? 0
 let active = turn.activePlayer
 let commanderCast = metrics.commanderCast[turn.id] ?? false
 let duration = turn.turnDuration
 let gameAvgDuration = metrics.averageTurnDuration
 
 let killedSomeone = metrics.turnsWithKills.contains(turn.id)
 
 // 🔥 Big impactful turn
 if impact > 0.3 {
 if killedSomeone {
 return "person.crop.circle.badge.checkmark" // kill turn
 } else if impact > 0.5 {
 return "sparkles" // epic / explosive
 } else {
 return "flame"
 }
 }
 
 // 🎯 Focused (sniper) turn
 if impact > 0.1 && entropy < 0.25 {
 return "target"
 }
 
 // 🌪️ Spread / chaotic
 if impact > 0.1 && entropy > 0.85 {
 return "circle.grid.cross"
 }
 
 // 👑 Commander cast
 if commanderCast {
 return "crown"
 }
 
 // 🐢 Long or 🐇 Short turn
 if duration > gameAvgDuration * 1.5 {
 return "tortoise"
 } else if duration < gameAvgDuration * 0.5 {
 return "hare"
 }
 
 // 🛡️ Defensive: No damage dealt
 if metrics.noDamageTurns.contains(turn.id) {
 return "shield"
 }
 
 // ✨ Low-impact flashy move
 if entropy > 0.9 && impact < 0.05 {
 return "wand.and.stars"
 }
 
 // Default: no icon
 return nil
 }

 
 struct GameMetrics {
 var turnImpact: [Int: Double]         // turn.id → TIP
 var turnEntropy: [Int: Double]        // turn.id → normalized entropy
 var commanderCast: [Int: Bool]        // turn.id → true if cast
 var averageTurnDuration: TimeInterval
 var turnsWithKills: Set<Int>          // turn.id where someone was eliminated
 var noDamageTurns: Set<Int>           // turn.id with zero outgoing damage
 }

 if let icon = iconForTurn(turn: turn, metrics: gameMetrics) {
 Image(systemName: icon)
 .font(.caption2)
 .foregroundColor(.primary)
 }

 
 */


/*
 
 
 📈 2. Turn Impact Score (TIP)
 ➤ Purpose:
 
 Highlight which turns had the biggest effect on the game — useful for storytelling and performance analysis.
 ➤ Formula:
 
 Let Di,tDi,t​ = damage dealt by player ii on turn tt
 Let DtotalDtotal​ = total damage dealt by all players in the game
 TIPi,t=Di,tDtotal
 TIPi,t​=Dtotal​Di,t
 
 Or alternatively, per turn:
 TIPt=∑iDi,tDtotal(impact of the turn itself)
 TIPt​=Dtotal​∑i​Di,t​​(impact of the turn itself)
 ➤ Visualization:
 
 Show the top 1–3 "impact turns" per game
 
 Color-coded timeline: red = high impact, gray = low
 
 Tooltip: “Turn 7: 42% of game damage dealt”
 
 ➤ Optional Bonus:
 
 You could apply a "momentum curve" over turns:
 Mi(t)=∑k=1tDi,k
 Mi​(t)=k=1∑t​Di,k
 
 That gives you the player’s cumulative impact trajectory, useful for visual storytelling or momentum charts.
 
 */


/*
 ⏳ 3. Turn Duration Variance (First Order Model)
 
 Even though it's noisy, you can still:
 
 Report average turn length (with a disclaimer: "estimated")
 
 Flag outlier turns (e.g., 3× longer than average)
 
 Use it as a possible indicator of decision complexity if patterns are consistent
 
 ➤ Formula:
 
 Let Ti,tTi,t​ = duration of player ii’s turn tt
 σTi=1n∑t=1n(Ti,t−Tˉi)2
 σTi​=n1​t=1∑n​(Ti,t​−Tˉi​)2
 ​
 
 You could ignore any durations over, say, 300 seconds as likely user error or distractions.
 
 */
