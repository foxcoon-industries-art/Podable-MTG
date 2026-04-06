import Foundation
import Podwork


///
///let entropy = damageEntropyAtTurn(forPlayer: playerIndex, atTurn: turnIndex, turns: turns)
///let borderWidth = CGFloat(1 + (1.0 - entropy) * 3) // 1–4 pts
///
func damageConcentrationEntropy(forPlayer playerIndex: Int, from turns: [Turn]) -> Double {
    var damageDealtToPlayers = [Int](repeating: 0, count: 4)
    var totalDamageDealt = 0

    for turn in turns {
        guard turn.activePlayer == playerIndex else { continue }

        // Regular damage (life)
        for (target, dmg) in turn.deltaLife.enumerated() {
            if target != playerIndex {
                let dmgDealt = max(0, -dmg)
                damageDealtToPlayers[target] += dmgDealt
                totalDamageDealt += dmgDealt
            }
        }

        // Commander damage (optional but included for completeness)
        for (target, dmgArray) in turn.deltaCmdrDamage.enumerated() {
            let dmgFromPlayer = max(0, dmgArray[playerIndex])
            if target != playerIndex {
                damageDealtToPlayers[target] += dmgFromPlayer
                totalDamageDealt += dmgFromPlayer
            }
        }

        // Partner damage (optional too)
        for (target, dmgArray) in turn.deltaPrtnrDamage.enumerated() {
            let dmgFromPlayer = max(0, dmgArray[playerIndex])
            if target != playerIndex {
                damageDealtToPlayers[target] += dmgFromPlayer
                totalDamageDealt += dmgFromPlayer
            }
        }
    }

    guard totalDamageDealt > 0 else { return 0 }

    // Compute entropy
    var entropy: Double = 0.0
    for dmg in damageDealtToPlayers where dmg > 0 {
        let p = Double(dmg) / Double(totalDamageDealt)
        entropy -= p * log2(p)
    }

    // Normalize (max entropy = log2(3) for 3 opponents)
    let maxEntropy = log2(3.0)
    return entropy / maxEntropy
}

struct TurnEntropy {
    let turnID: Int
    let playerIndex: Int
    let entropy: Double // 0 to 1 normalized
}

/**
 
 func computeTurnEntropies(from turns: [Turn]) -> [TurnEntropy] {
 var entropies: [TurnEntropy] = []
 
 for turn in turns {
 let active = turn.activePlayer
 var damageDealt = [Int](repeating: 0, count: 4)
 var totalDamage = 0
 
 // Life damage
 for (target, delta) in turn.deltaLife.enumerated() where target != active && delta < 0 {
 let dmg = -delta
 damageDealt[target] += dmg
 totalDamage += dmg
 }
 
 // Commander damage
 for (target, dmgArray) in turn.deltaCmdrDamage.enumerated() where target != active {
 let dmg = max(0, dmgArray[active])
 damageDealt[target] += dmg
 totalDamage += dmg
 }
 
 // Partner damage
 for (target, dmgArray) in turn.deltaPrtnrDamage.enumerated() where target != active {
 let dmg = max(0, dmgArray[active])
 damageDealt[target] += dmg
 totalDamage += dmg
 }
 
 guard totalDamage > 0 else {
 entropies.append(TurnEntropy(turnID: turn.id, playerIndex: active, entropy: 0))
 continue
 }
 
 // Entropy calculation
 var entropy = 0.0
 for dmg in damageDealt where dmg > 0 {
 let p = Double(dmg) / Double(totalDamage)
 entropy -= p * log2(p)
 }
 
 // Normalize (max entropy = log₂(3) = 1.5849...)
 let normalizedEntropy = entropy / log2(3.0)
 entropies.append(TurnEntropy(turnID: turn.id, playerIndex: active, entropy: normalizedEntropy))
 }
 
 return entropies
 }

 */

/*
 struct TurnSquare: View {
 let impactRatio: Double
 let isActivePlayer: Bool
 let entropy: Double
 let commanderCast: Bool
 
 var body: some View {
 let color = Color.red.opacity(min(1.0, impactRatio * 4))
 let borderWidth = isActivePlayer ? CGFloat(1 + (1 - entropy) * 3) : 0
 let shape: some Shape = commanderCast ? DiamondShape() : Rectangle()
 
 shape
 .fill(color)
 .frame(width: 20, height: 20)
 .overlay(
 shape.stroke(Color.black, lineWidth: borderWidth)
 )
 .overlay(
 entropyDot
 .offset(x: 6, y: -6),
 alignment: .topTrailing
 )
 }
 
 var entropyDot: some View {
 Circle()
 .fill(entropy > 0.7 ? .green : (entropy < 0.3 ? .red : .yellow))
 .frame(width: 5, height: 5)
 }
 }

 */


/*
 
 📊 1. Damage Concentration (Entropy)
 ➤ Purpose:
 
 Measure how focused a player’s aggression is across multiple opponents.
 
 Low entropy = focused (e.g., all-in on one player)
 
 High entropy = spread out (e.g., pinging everyone equally)
 
 ➤ Formula:
 
 Let DijDij​ = total damage dealt by player ii to player jj across the game.
 Let Di=∑j≠iDijDi​=∑j=i​Dij​ = total outgoing damage by player ii.
 
 Then:
 pij=DijDi(proportion of damage to each opponent)
 pij​=Di​Dij​​(proportion of damage to each opponent)
 Hi=−∑j≠ipij⋅log⁡2(pij)(entropy of player i)
 Hi​=−j=i∑​pij​⋅log2​(pij​)(entropy of player i)
 ➤ Notes:
 
 Entropy will be 0 if all damage goes to one player
 
 Max entropy (for 3 opponents) ≈ log₂(3) ≈ 1.58
 
 Can normalize:
 
 Hinorm=Hilog⁡2(N−1)(to scale 0–1)
 Hinorm​=log2​(N−1)Hi​​(to scale 0–1)
 ➤ Example:
 
 Player A deals:
 
 30 to B
 
 30 to C
 
 30 to D
 
 p=[0.33,0.33,0.33],H=−3(0.33⋅log⁡2(0.33))≈1.58
 p=[0.33,0.33,0.33],H=−3(0.33⋅log2​(0.33))≈1.58
 
 Player A deals:
 
 80 to B
 
 10 to C
 
 0 to D
 
 p=[0.89,0.11,0],H≈0.50
 p=[0.89,0.11,0],H≈0.50
 */


/*
 
 🎯 Goal
 
 Visualize entropy over time for each player (or just active turns) as a line or bar plot.
 Use this data to power:
 
 A line graph above or below your existing turn grid
 
 Or small bar charts per player row
 
 Or a tooltip on tap/hover per turn square
 
 🧱 2. How to Display It
 📈 Option A: Mini Line Graph for Each Player
 
 X-axis: Turn number
 
 Y-axis: Entropy (0–1)
 
 One line per player (color-coded)
 
 Place this graph either:
 
 Above your turn grid (global overview)
 
 Or per player in their row, under their squares
 
 📊 Option B: Small Bar Under Each Square
 
 For each turn where player was active, draw a small bar or dot just below their square
 
 Height or color = entropy (low = red, high = green)
 
 🟡 Option C: Turn-by-Turn Tooltips or Details
 
 On tap/hover of a turn square, show:
 
 Turn damage
 
 Entropy (as % or description: “Focused”, “Mixed”, “Spread”)
 
 🔄 3. Combining With TIP
 
 You can also cross-plot entropy with Turn Impact:
 
 Big Turn + Low Entropy → Sniper moment (likely a kill)
 
 Big Turn + High Entropy → Board sweep or chaos
 
 Low Impact + High Entropy → Poking everyone (early game)
 
 To visualize this:
 
 Draw circles or bars where:
 
 X = turn index
 
 Y = entropy
 
 Radius or color intensity = impact score
 
 */
