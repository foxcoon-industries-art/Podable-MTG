import Foundation
import Podwork


@MainActor
public class DemoDataGenerator {
    
    // Popular commander names for demo data
    static private let commanderNames = [
        "Atraxa, Praetors' Voice",
        "Korvold, Fae-Cursed King",
        "Edgar Markov",
        "The Ur-Dragon",
        "Muldrotha, the Gravetide",
        "Yuriko, the Tiger's Shadow",
        "Teysa Karlov",
        "Krenko, Mob Boss",
        "Ms. Bumbleflower",
        "Rin and Seri, Inseparable",
        "Voja, Jaws of the Conclave",
        "Vivi Ornitier",
        "Kenrith, the Returned King",
        "The Wise Mothman",
        "Jodah, the Unifier",
        "Kaalia of the Vast",
        "Sisay, Weatherlight Captain",
        "Queen Marchesa",
        "Urza, Lord High Artificer",
        "Giada, Font of Hope",
        "Baylen, the Haymaker",
        "Chatterfang, Squirrel General",
        "Sauron, the Dark Lord",
        "Pantlaza, Sun-Favored",
        "Lathril, Blade of the Elves",
        "Bello, Bard of the Brambles"
    ]
    
    // Partner commanders for demo data
    static private let partnerCommanders = [
        "Thrasios, Triton Hero",
        "Tymna the Weaver",
        "Vial Smasher the Fierce",
        "Kraum, Ludevic's Opus",
        "Bruse Tarl, Boorish Herder",
        "Ravos, Soultender",
        "Kydele, Chosen of Kruphix",
        "Silas Renn, Seeker Adept"
    ]
    
    // Win methods
    static private let winMethods = [EliminationMethod.lifeDamage,
     EliminationMethod.commanderDamage,
     EliminationMethod.infect,
     EliminationMethod.concede,
     EliminationMethod.altWin,
     EliminationMethod.milled,
     EliminationMethod.endingInDraw,
     EliminationMethod.notEliminated]
    
    
    // Generate a configurable number of demo games
    public static func generateDemoGames(count: Int = 20) -> [(FinalPod, [Turn], [Int:EliminationMethod])] {
        var games: [(FinalPod, [Turn], [Int:EliminationMethod])] = []
        
        var game = GameState()
        let cmdrPrtnrNames = selectRandomCommanders(count:4)
        for playerID in game.players.indices {
            game.players[playerID].commanderName = cmdrPrtnrNames[playerID].name
        }
        
        for i in 0..<count {
            // Generate game date (spread over last 3 months)
            let daysAgo = Double.random(in: 0...90)
            let gameDate = Date().addingTimeInterval(-daysAgo * 24 * 60 * 60)
            
            // Generate game parameters with some variety
            let gameLength = Int.random(in: 13...21) // Wider range for more variety
            var gameDuration = 0.0
            let numPlayers = 4
            

            // Create commanders with realistic data
            var commanders: [Commander] = []
            // Select random commanders
            let selectedCommanders = DemoDataGenerator.selectRandomCommanders(count: numPlayers)
            
            
            for playerIndex in 0..<numPlayers {
                // Generate brackets (power levels)
             
                var commander = Commander(
                    name: selectedCommanders[playerIndex].name,
                    turnOrder:playerIndex,
                )
                commanders.append(commander)
            }

            
            // Generate realistic turn history (don't predetermine winner)
            let (turnHistory, commanderStats, actualGameLength, winMethod, rmMethod) = DemoDataGenerator.generateRealisticTurnHistory(
                numPlayers: numPlayers,
                maxRounds: gameLength,
                gameDate: gameDate,
                gameDuration: &gameDuration,
                commanders: &commanders
            )
            
            // Find the winner (whomever survived)
            let winnerIndex = commanderStats.firstIndex { !$0.eliminated } ?? 0
            commanders[winnerIndex].winner = true
            commanders[winnerIndex].eliminated = false
            commanders[winnerIndex].eliminationRound = nil
            commanders[winnerIndex].eliminationTurnID = nil

            for playerIndex in 0..<numPlayers {
                let brackets = generateBrackets(for: numPlayers)
                commanders[playerIndex].bracket = brackets
                commanders[playerIndex].winner = playerIndex == winnerIndex
            }
            
            let totalGameDuration = commanders.compactMap { $0.totalTurnTime }.reduce(0, +)

            for i in 0..<commanders.count {
                commanders[i].totalCommanderDamage = turnHistory.totalCommanderDamageFrom(playerID: i)
            }
            
            // Create FinalPod
            let finalState = FinalPod(
                gameID: generateGameID(index: i),
                date: gameDate,
                duration: totalGameDuration,
                commanders: commanders,
                totalRounds: actualGameLength,
                winMethod: winMethod
            )
            //let _ = print("=> finalState: ", finalState, "\n")
            games.append((finalState, turnHistory, rmMethod))
        }
        
        return games
    }
    
    static private func selectRandomCommanders(count: Int) -> [(name: String, partner: String?)] {
        var selected: [(name: String, partner: String?)] = []
        var availableCommanders = DemoDataGenerator.commanderNames.shuffled()
        
        for _ in 0..<count {
            // 15% chance of partner commander
            if Double.random(in: 0...1) < 0.15 && availableCommanders.count >= 2 {
                let commander1 = availableCommanders.removeFirst()
                let partner = partnerCommanders.randomElement()!
                selected.append((name: commander1, partner: partner))
            } else if !availableCommanders.isEmpty {
                let commander = availableCommanders.removeFirst()
                selected.append((name: commander, partner: nil))
            } else {
                // Fallback if we run out
                selected.append((name: commanderNames.randomElement()!, partner: nil))
            }
        }
        
        return selected
    }
    
    static private func generateBrackets(for numPlayers: Int) -> [Int] {
        // Generate power levels between 4-9 with some clustering
        var brackets: [Int] = []
        for _ in 0..<numPlayers {
            let bracket = Int.random(in: 1...5)
            brackets.append(bracket)}
        return brackets

        /*
        return [Int.random(in: 1...5), Int.random(in: 1...5), Int.random(in: 1...5), Int.random(in: 1...5)]
     
        let basePowerLevel = Int.random(in: 5...7)
        var brackets: [Int] = []
        
        for _ in 0..<numPlayers {
            // Vary by +/- 1 from base power level
            let variance = Int.random(in: -1...1)
            let bracket = max(4, min(9, basePowerLevel + variance))
            brackets.append(bracket)
        }
        
        return brackets
        */
    }
    
    static private func generateRealisticTurnHistory(
        numPlayers: Int,
        maxRounds: Int,
        gameDate: Date,
        gameDuration: inout Double,
        commanders: inout [Commander]
    ) -> ([Turn], [(totalCmdrDamage: Int, turnDurations: [Double], eliminated: Bool, eliminationRound: Int?)], Int, String, [Int:EliminationMethod]) {
        
        var turnHistory: [Turn] = []
 
        var playerStats: [(totalCmdrDamage: Int, turnDurations: [Double], eliminated: Bool, eliminationRound: Int?)] = []
        
        // Initialize player stats
        for _ in 0..<numPlayers {
            playerStats.append((totalCmdrDamage: 0, turnDurations: [], eliminated: false, eliminationRound: nil))
        }
        
        // Initialize game state
        var lifeTotal = [40, 40, 40, 40]
        var lifeTotalAtStartOfTurn = [40, 40, 40, 40]
        var infectTotal = [0, 0, 0, 0]
        var infectTotalAtStartOfTurn = [0, 0, 0, 0]
        var cmdrDmgTotal = [[0,0,0,0], [0,0,0,0], [0,0,0,0], [0,0,0,0]]
        var turnEndTime = gameDate
        var turnId = -1
        var eliminatedPlayers: Set<Int> = []
        var roundNumber = 0
        var totalTurnDuration = Double(0)
        var cmdrRemovalReason: [Int: EliminationMethod]  = [:]
        var checked = false /// gives an additional turn for deltas to be applied
        gameLoop: for round in 0..<(maxRounds+1) {
            roundNumber = round
            
            var remainingPlayers = (0..<numPlayers).filter { !eliminatedPlayers.contains($0) }
            
            if remainingPlayers.count <= 1 {
                /// If only one player left, end the game
                break gameLoop
            }
            

            let turnDuration =  Double.random(in: 15...300)
            turnEndTime = turnEndTime.addingTimeInterval(turnDuration)
            totalTurnDuration += turnDuration
            
            // Initialize deltas for this turn
            var deltaLife = [0, 0, 0, 0]
            var deltaInfect = [0, 0, 0, 0]
            var deltaCmdrDamage = [[0,0,0,0], [0,0,0,0], [0,0,0,0], [0,0,0,0]]
            var deltaPrtnrDamage = [[0,0,0,0], [0,0,0,0], [0,0,0,0], [0,0,0,0]]
            
            // Generate damage based on game progression
            //let gameProgression = Double(round) / Double(maxRounds)
            //let aggressionLevel =  0.5 + (round > 3 ? 0.2 : 0.0)// Start at 50%, increase by 20% after turn 3
            var aggressionLevel =  (0.05 * Double(turnId)) + (round > 3 ? 0.1 : 0.0)// Start at 50%, increase by 20% after turn 3
            
            
            for playerIndex in remainingPlayers {
                
                if eliminatedPlayers.contains( playerIndex ) {
                    continue
                }
                
                turnId += 1
                
                /// Set start of turn parameters
                lifeTotalAtStartOfTurn = lifeTotal
                infectTotalAtStartOfTurn = infectTotal
                
                for i in 0..<4 {
                    deltaLife[i] = 0
                    deltaInfect[i] = 0
                    deltaCmdrDamage[i] = [0,0,0,0]
                    deltaPrtnrDamage[i] = [0,0,0,0]
                }
                /// randomly cast commanders if player is still in game

                if !eliminatedPlayers.contains(playerIndex){
                    let randomlyApplyTax = Double.random(in: 0...1)
                    if randomlyApplyTax < 0.15 {
                        commanders[playerIndex].tax += 1
                        if (commanders[playerIndex].taxTurns != nil) != nil {
                            commanders[playerIndex].taxTurns!.append(turnId)
                        }
                    }
                }
                
                
                
                // Only generate damage if game has progressed enough
                if round >= 2 || aggressionLevel > 0.10 {
                    DemoDataGenerator.generateDamageForTurn(
                        activePlayer: playerIndex,
                        remainingPlayers: remainingPlayers,
                        deltaLife: &deltaLife,
                        deltaInfect: &deltaInfect,
                        deltaCmdrDamage: &deltaCmdrDamage,
                        aggressionLevel: aggressionLevel,
                        round: round,
                        commanders: &commanders
                    )
                }
                
                /// Reset damages to make sure removed players do no damage
              
                
                /// Apply deltas to totals (only for still-active players)
                for i in remainingPlayers { //0..<numPlayers {
                    
                    if eliminatedPlayers.contains(i) {
                        deltaLife[i] = 0
                        deltaInfect[i] = 0
                        deltaCmdrDamage[i] = [0,0,0,0]
                        deltaPrtnrDamage[i] = [0,0,0,0]
                    }
                    
                    if !eliminatedPlayers.contains(i) {
                        lifeTotal[i] += deltaLife[i]
                        infectTotal[i] += deltaInfect[i]
                        
                        /// Apply commander damage to life total
                        for j in remainingPlayers {
                            if i != j {
                                if deltaCmdrDamage[i][j] > 0 {
                                    lifeTotal[i] -= deltaCmdrDamage[i][j]
                                    cmdrDmgTotal[i][j] += deltaCmdrDamage[i][j]
                                    
                                    let storedDamage = deltaCmdrDamage[j][i]
                                    playerStats[i].totalCmdrDamage += storedDamage
                                    commanders[i].totalCommanderDamage += storedDamage

                                }
                            }
                        }
                        
                        /// Track commander damage dealt by active player
//                        for targetIndex in remainingPlayers {
//                            if deltaCmdrDamage[targetIndex][playerIndex] > 0 {
//                                playerStats[playerIndex].totalCmdrDamage += deltaCmdrDamage[targetIndex][playerIndex]
//                                commanders[playerIndex].totalCommanderDamage += deltaCmdrDamage[targetIndex][playerIndex]
//
//                            }
//                        }
                    }
                }
                
                
                // Check for new eliminations
                let newlyEliminated = DemoDataGenerator.checkForEliminations(
                    lifeTotal: lifeTotal,
                    infectTotal: infectTotal,
                    cmdrDmgTotal: cmdrDmgTotal,
                    currentlyEliminated: eliminatedPlayers,
                    round: round,
                    turnID: turnId,
                    commanders: &commanders
                )
                
                for removed in newlyEliminated {
                    let idxRemoved = removed.key
                    if !eliminatedPlayers.contains(idxRemoved) {
                        eliminatedPlayers.insert(idxRemoved)
                        playerStats[idxRemoved].eliminated = true
                        playerStats[idxRemoved]
                        cmdrRemovalReason[idxRemoved] = removed.value
                    }
                }
                
                
                
                /// Reset damages to make sure removed players do no damage
                /*
                commanders.forEach{ cmdr in
                    if cmdr.eliminated == true  ||  remainingPlayers.count == 1 {
                        let idx = cmdr.turnOrder
                        
                        deltaLife[idx] = 0
                        deltaInfect[idx] = 0
                        deltaCmdrDamage[idx] = [0,0,0,0]
                        deltaPrtnrDamage[idx] = [0,0,0,0]
                    }
                }
                 */
                
                
                //print("DemoData | Round: \(round) active: \(playerIndex) Players: \(remainingPlayers)  PlayerRemaining: \(remainingPlayers.count)")

                // Create turn
                var turn = Turn(
                    activePlayer: playerIndex,
                    id: turnId,
                    round: round,
                    deltaLife: deltaLife,
                    deltaInfect: deltaInfect,
                    whenTurnEnded: turnEndTime,
                    deltaCmdrDamage: deltaCmdrDamage,
                    deltaPrtnrDamage: deltaPrtnrDamage,
                    lifeTotal: Array(lifeTotalAtStartOfTurn),
                    infectTotal: Array(infectTotalAtStartOfTurn),
                    cmdrDmgTotal: cmdrDmgTotal.map { Array($0) },
                    prtnrDmgTotal: cmdrDmgTotal.map { Array($0) }
                )
                turn.turnDuration = turnDuration
                commanders[turn.activePlayer].turnDurations.append(turnDuration)
                //print(turn.activePlayer)
                turnHistory.append(turn)
                playerStats[playerIndex].turnDurations.append(turnDuration)
                
                // Check if game should end
                let remainingPlayers = remainingPlayers.filter { !eliminatedPlayers.contains($0) }
                if remainingPlayers.count <= 1 {
                    //print("commander dmg: \(commanders[0])")
                    //print("playerStats dmg: \(playerStats[0])")
                    //break gameLoop
                    if checked { break gameLoop }
                    checked = true
                }
            }
        }
        gameDuration = totalTurnDuration
        // Determine win method based on elimination patterns
        let winMethod = determineWinMethod(turnHistory: turnHistory, playerStats: playerStats, removalMethods: cmdrRemovalReason)
        

        return (turnHistory, playerStats, roundNumber + 1, winMethod, cmdrRemovalReason)
    }
    
    @MainActor
    static private func generateDamageForTurn(
        activePlayer: Int,
        remainingPlayers: [Int],
        deltaLife: inout [Int],
        deltaInfect: inout [Int],
        deltaCmdrDamage: inout [[Int]],
        aggressionLevel: Double,
        round: Int,
        commanders: inout [Commander]
    ) {
        
        
        let damageChance = aggressionLevel

        for targetIndex in remainingPlayers {
            
            if targetIndex == activePlayer { continue  }
            
            let infectTypeRand = Double.random(in: 0...1)
            if infectTypeRand < 0.05 && round > 1 {
               
                let randInfect = Int.random(in: 0...5)
                deltaInfect[targetIndex] = Int.random(in: 0...5)
            }else {
                deltaInfect[targetIndex] = 0
            }
            
            /// Decide if this player attacks this target   /// Determine damage type and amount
            if Double.random(in: 0...1) < damageChance {
                
                let damageAmount = Int.random(in: 0...5) + Int((1+aggressionLevel)*Double.random(in: 0...5))
       
                let damageTypeRand = Double.random(in: 0...1)
                if damageTypeRand < 0.25 && round > 3 {
                    
                    deltaCmdrDamage[targetIndex][activePlayer] = Int.random(in: 0...5) + Int((1+aggressionLevel)*Double.random(in: 0...5))
                } else {
                    
                    deltaLife[targetIndex] = -(Int.random(in: -0...5) + Int((1+aggressionLevel)*Double.random(in: -5...5)))
                }
            } else {
                deltaLife[targetIndex] = 0
            }
        }
        
        // Small chance for mass damage effects (board wipes, etc.)
//        if Double.random(in: 0...1) < 0.051 && round > 5 {
//            let massLife = Int.random(in: 2...4)
//            for targetIndex in remainingPlayers {
//                if targetIndex != activePlayer {
//                    deltaLife[targetIndex] -= massLife
//                }
//            }
//        }
    }
    
    static private func checkForEliminations(
        lifeTotal: [Int],
        infectTotal: [Int],
        cmdrDmgTotal: [[Int]],
        currentlyEliminated: Set<Int>,
        round: Int,
        turnID: Int,
        commanders: inout [Commander]
    ) -> [Int:EliminationMethod] {
        
        var newlyEliminated: [Int:EliminationMethod] = [:]
        var method: [EliminationMethod] = []
        
        /*
        for removed in newlyEliminated {
            let idxRemoved = removed.key
            if !eliminatedPlayers.contains(idxRemoved) {
                commanders[idxRemoved].eliminated = true
                commanders[idxRemoved].eliminationRound = round
                commanders[idxRemoved].eliminationTurnID = turnId
                commanders[idxRemoved].eliminationMethod = removed.value
                
                
                eliminatedPlayers.insert(idxRemoved)
                playerStats[idxRemoved].eliminated = true
                playerStats[idxRemoved]
                cmdrRemovalReason[idxRemoved] = removed.value
            }
        }
        */
        ///
        ///
        var wasEliminated = false
        for i in 0..<commanders.count {
            //let idx = commanders[i].turnOrder
            
            if currentlyEliminated.contains(i) { continue }
            
            // Check elimination conditions
            if lifeTotal[i] <= 0 {
                newlyEliminated[i] = EliminationMethod.lifeDamage
                wasEliminated = true
            } else if infectTotal[i] >= 10 {
                newlyEliminated[i] = EliminationMethod.infect
                wasEliminated = true
            } else if let maxCmdrDamage = cmdrDmgTotal[i].max(), maxCmdrDamage >= 21 {
                newlyEliminated[i] = EliminationMethod.commanderDamage
                wasEliminated = true
            }

            // Small chance of concession in later rounds
            if round > 5 && Double.random(in: 0...1) < 0.015 {
                let activePlayers = (0..<lifeTotal.count).filter {
                    !currentlyEliminated.contains($0) && !newlyEliminated.keys.contains($0)
                }
                if activePlayers.count >= 2, let concedePlayer = activePlayers.randomElement() {
                    if !newlyEliminated.keys.contains(concedePlayer) {
                        newlyEliminated.updateValue(EliminationMethod.concede, forKey: concedePlayer)
                    }
                    else {
                        newlyEliminated[concedePlayer] = EliminationMethod.concede
                        wasEliminated = true
                    }
                }
            }
            
            if wasEliminated {
                commanders[i].eliminated = true
                commanders[i].eliminationTurnID = turnID
                commanders[i].eliminationRound = round
                commanders[i].eliminationMethod = newlyEliminated[i]!
            }

            wasEliminated = false
        }
        
        return newlyEliminated
    }
    
    static private func determineWinMethod(
        turnHistory: [Turn],
        playerStats: [(totalCmdrDamage: Int, turnDurations: [Double], eliminated: Bool, eliminationRound: Int?)],
        removalMethods: [Int: EliminationMethod]
    ) -> String {
        
        // Analyze how most players were eliminated
        var eliminationMethods: [String: Int] = [:]
        
        // Look at the last turn to see final states
        guard let lastTurn = turnHistory.last else { return "No Winner" }
        
        for i in 0..<4 {
            if playerStats[i].eliminated {
                
                if let methodType = removalMethods.first(where: { $0.key == i })?.value {
                    
                    if methodType == EliminationMethod.lifeDamage {
                        eliminationMethods[EliminationMethod.lifeDamage.displayName, default: 0] += 1
                    } else if methodType == EliminationMethod.commanderDamage {
                        eliminationMethods[EliminationMethod.commanderDamage.displayName, default: 0] += 1
                    } else if methodType == EliminationMethod.infect {
                        eliminationMethods[EliminationMethod.infect.displayName, default: 0] += 1
                    } else if methodType == EliminationMethod.concede {
                        eliminationMethods[EliminationMethod.concede.displayName, default: 0] += 1
                    } else if methodType == EliminationMethod.altWin {
                        eliminationMethods[EliminationMethod.altWin.displayName, default: 0] += 1
                    }

                }

            }
        }
       
        return eliminationMethods.max(by: { $0.value < $1.value })?.key ?? "Combat"
    }
    
    static private func generateGameID(index: Int) -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        return "DEMO---\(timestamp)-\(String(format: "%03d", index))"
    }
    
    
    static public func demoData(count : Int) -> [(FinalPod, [Turn])]{
        let demoData : [(FinalPod, [Turn], [Int:EliminationMethod])] = DemoDataGenerator.generateDemoGames(count: count)
        let finalStates : [FinalPod] = demoData.map { $0.0 }
        let turnHistory : [[Turn]] = demoData.map { $0.1 }
        return Array(zip(finalStates, turnHistory))
    }
    
    public struct DemoGamePreview {
        public let gameID: String
        public let date: Date
        public let duration: Double
        public let rounds: Int
        public let winnerName: String
        public let winMethod: String
        public let playerCount: Int
        public let eliminationMethods: [String]
        
        public var description: String {
            return """
            Game: \(gameID)
            Date: \(date.formatted(date: .abbreviated, time: .omitted))
            Duration: \(Int(duration/60)) minutes
            Rounds: \(rounds)
            Winner: \(winnerName)
            Method: \(winMethod)
            Players: \(playerCount)
            Eliminations: \(eliminationMethods.joined(separator: ", "))
            """
        }
    }

    
}





// MARK: - Demo Data Preview and Customization

public extension DemoDataGenerator {
    
    
    public static func previewDemoGames(count: Int = 15) -> [DemoGamePreview] {
        let games = DemoDataGenerator.generateDemoGames(count: count)
        
        let (finalState, _, elimMethod) = games.last!
        var methodCounts: [String] = ["","","",""]
        for (idx, method) in elimMethod {
            methodCounts[idx] = method.displayName
        }
        /*
         return games.map { finalState, turnHistory, elimMethod in
         let eliminationMethods = finalState.commanders
         .filter { $0.eliminated }
         .map { _ in "Combat" } // Simplified for preview
         */
        return [DemoGamePreview(
            gameID: finalState.gameID,
            date: finalState.date,
            duration: finalState.duration,
            rounds: finalState.totalRounds,
            winnerName: finalState.winningCommanderName ?? "Unknown",
            winMethod: finalState.winMethod,
            playerCount: finalState.commanders.count,
            eliminationMethods: methodCounts
        )]
    }
    
    
    // MARK: - Customizable Demo Parameters
    
    struct DemoGameParameters {
        var gameCount: Int
        var minRounds: Int
        var maxRounds: Int
        var minDuration: Double  // In seconds
        var maxDuration: Double  // In seconds
        var aggressionMultiplier: Double // 0.5 = half damage, 2.0 = double damage
        var commanderDamageFrequency: Double // 0.0 to 1.0
        var infectFrequency: Double // 0.0 to 1.0
        
        static var balanced: DemoGameParameters {
            return DemoGameParameters(
                gameCount: 15,
                minRounds: 6,
                maxRounds: 18,
                minDuration: 1200,
                maxDuration: 8400,
                aggressionMultiplier: 1.0,
                commanderDamageFrequency: 0.25,
                infectFrequency: 0.05
            )
        }
        
        static var aggressive: DemoGameParameters {
            return DemoGameParameters(
                gameCount: 15,
                minRounds: 4,
                maxRounds: 12,
                minDuration: 900,
                maxDuration: 5400,
                aggressionMultiplier: 1.5,
                commanderDamageFrequency: 0.4,
                infectFrequency: 0.1
            )
        }
        
        static var casual: DemoGameParameters {
            return DemoGameParameters(
                gameCount: 15,
                minRounds: 8,
                maxRounds: 25,
                minDuration: 2400,
                maxDuration: 10800,
                aggressionMultiplier: 0.7,
                commanderDamageFrequency: 0.15,
                infectFrequency: 0.02
            )
        }
    }
}


