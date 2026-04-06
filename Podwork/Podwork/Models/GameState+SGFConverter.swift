import Foundation

extension GameState {
    
    /// Converts the current GameState into the standardized GameRecord format (SGF v2.0).
    /// This function acts as the bridge between the live game tracking and the portable JSON export.
    @MainActor
    public func exportGameRecord() -> GameRecord {
        
        // 1. Header
        let finalDuration = self.gameOver?.duration ?? abs(self.gameDate.timeIntervalSinceNow)
        let header = GameHeader(
            datePlayed: self.gameDate,
            duration: finalDuration,
            gameType: "Commander" // Defaulting to Commander as this is a Commander app
        )
        
        let nPlayers = self.players.count
        
        // 2. Pod (Seats)
        let seats: [Seat] = self.players.enumerated().map { (index, player) in
            // Determine commanders: if partnerName is empty, just one commander
            var commanders = [player.commanderName]
            if !player.partnerName.isEmpty {
                commanders.append(player.partnerName)
            }
            
            // Get the self-rated bracket (Player 1 rates Seat 1, etc.)
            // Safe index access just in case
            let bracket = index < player.deckBracket.count ? player.deckBracket[index] : 0
            
            return Seat(
                index: index,
                commanders: commanders,
                selfRatedBracket: bracket
            )
        }
        
        // 3. Timeline
        // We need to replay the history to build accurate scoreboards and logs.
        var timeline: [Turn_] = []
        
        // We'll track the running totals locally to build snapshots
        var currentLifeTotals = Array(repeating: GameConstants.defaultStartingLife, count: nPlayers)
        var currentPoisonTotals = Array(repeating: 0, count: nPlayers)
        var currentCmdrDamage = Array(repeating: Array(repeating: 0, count: nPlayers), count: nPlayers) // [Player][Opponent]
        var currentTaxes = Array(repeating: 0, count: nPlayers)
        
        // We'll also track partner damage separately to combine it into the sparse record if needed,
        // or we just rely on the GameState's `cmdrDmgTotal` which combines them?
        // Checking Turn.swift: `cmdrDmgTotal` seems to track them separately in arrays but `Turn` has both.
        // SGF v2.0 `CommanderDamageRecord` is simplified. Let's aggregate for now.
        
        for turn in self.podHistory {
            var actions: [GameAction] = []
            
            // --- Life Changes ---
            for (playerIdx, delta) in turn.deltaLife.enumerated() {
                if delta != 0 {
                    actions.append(GameAction(
                        type: .lifeChange,
                        //actorSeatIndex: turn.activePlayer, // Or nil? Usually combat damage is attributed to active player, but life gain/loss can be anything.
                        // SGF defines actorSeatIndex. For life loss, usually the player losing it is the target?
                        // Let's assume generic life change: actor = player affected?
                        // Or better: actor = active player (source), target = playerIdx.
                        // Since `deltaLife` lumps everything (fetch lands, drain, etc.), it's hard to know the source.
                        // We will set actor = playerIdx (self-inflicted/generic) for now unless we know otherwise.
                        actorSeatIndex: playerIdx,
                        targetSeatIndex: nil,
                        value: delta,
                        note: "Life Change"
                    ))
                    currentLifeTotals[playerIdx] += delta
                }
            }
            
            // --- Poison Changes ---
            for (playerIdx, delta) in turn.deltaInfect.enumerated() {
                if delta != 0 {
                    actions.append(GameAction(
                        type: .poisonChange,
                        actorSeatIndex: turn.activePlayer,
                        targetSeatIndex: playerIdx,
                        value: delta,
                        note: "Poison"
                    ))
                    currentPoisonTotals[playerIdx] += delta
                }
            }
            
            // --- Commander Damage ---
            /*
            for playerIdx in 0..<4 { // The victim
                for opponentIdx in 0..<4 { // The dealer
                    // Commander Damage
                    let cDmg = turn.deltaCmdrDamage[playerIdx][opponentIdx]
                    if cDmg != 0 {
                        actions.append(GameAction(
                            type: .commanderDamage,
                            actorSeatIndex: opponentIdx,
                            targetSeatIndex: playerIdx,
                            value: cDmg,
                            note: "Commander Damage"
                        ))
                        // Note: Turn logic says deltaLife does NOT include cmdr damage deltas,
                        // so we must subtract from running life total here manually?
                        // "Turn.swift": `calculatedLifeTotal[playerIndex] -= cmdrDmg`
                        // Yes.
                        currentLifeTotals[playerIdx] -= cDmg
                        currentCmdrDamage[playerIdx][opponentIdx] += cDmg
                    }
                    
                    // Partner Damage
                    let pDmg = turn.deltaPrtnrDamage[playerIdx][opponentIdx]
                    if pDmg != 0 {
                        actions.append(GameAction(
                            type: .commanderDamage,
                            actorSeatIndex: opponentIdx,
                            targetSeatIndex: playerIdx,
                            value: pDmg,
                            note: "Partner Damage"
                        ))
                        currentLifeTotals[playerIdx] -= pDmg
                        // We treat partner damage as commander damage in the aggregate record for now
                        // or should we split? SGF v2 has sparse records.
                        // We will add it to the same slot for simplicity unless we want to distinguish.
                        currentCmdrDamage[playerIdx][opponentIdx] += pDmg
                    }
                }
            }
            */
            
            // --- Casts & Taxes (From PodCastHistory) ---
            // `podCasts` stores events by `turnID`.
            let casts = self.podCasts.getTurnsWithCastTax(turnID: turn.id)
            for cast in casts {
                actions.append(GameAction(
                    type: .castCommander,
                    actorSeatIndex: cast.playerID,
                    targetSeatIndex: nil,
                    value: cast.total, // Total increment (usually 1)
                    note: cast.casting
                ))
                // Update running tax total
                // Note: `cast.total` is the increment/decrement.
                // We should track the total tax *amount* (2, 4, 6...).
                // `GameState` maintains `commanderTax` on the player.
                // Here we just accumulate the counts.
                // Assuming standard +2 tax per cast (or +1 counter?).
                // The app seems to track "count of casts" or "tax amount"?
                // `changeCommanderTax(..., by: 1)` suggests it counts the *instances* of tax increase?
                // Let's assume it tracks the *count* of tax increments (so *2 for actual mana).
                currentTaxes[cast.playerID] += cast.total
            }
            
            // --- Eliminations ---
            // Check if any player's `eliminationTurnID` matches this turn
            for player in self.players {
                if player.eliminationTurnID == turn.id {
                    actions.append(GameAction(
                        type: .elimination,
                        actorSeatIndex: turn.activePlayer, // Who killed them? Often the active player.
                        targetSeatIndex: player.id,
                        value: nil,
                        note: player.eliminationMethod.displayName
                    ))
                }
            }
            
            // --- Build Scoreboard Snapshot ---
            var sparseCmdrDamage: [CommanderDamageRecord] = []
            for playerIdx in 0..<nPlayers {
                for opponentIdx in 0..<nPlayers {
                    let total = currentCmdrDamage[playerIdx][opponentIdx]
                    if total > 0 {
                        sparseCmdrDamage.append(CommanderDamageRecord(
                            fromSeatIndex: opponentIdx,
                            toSeatIndex: playerIdx,
                            amount: total
                        ))
                    }
                }
            }
            
            let scoreboard = Scoreboard(
                lifeTotals: currentLifeTotals,
                poisonTotals: currentPoisonTotals,
                commanderDamage: sparseCmdrDamage,
                commanderTax: currentTaxes
            )
            
            // Add Turn to Timeline
            timeline.append(Turn_(
                number: turn.id,
                round: turn.round,
                activeSeatIndex: turn.activePlayer,
                duration: turn.turnDuration,
                log: actions,
                scoreboard: scoreboard
            ))
        }
        
        // 4. Summary
        var vibeChecks: [VibeCheck] = []
        for (raterIdx, rater) in self.players.enumerated() {
            for (ratedIdx, rating) in rater.deckBracket.enumerated() {
                // If rating is 0, maybe they didn't vote? Assuming non-zero is valid.
                if rating > 0 {
                    vibeChecks.append(VibeCheck(checkerSeatIndex: ratedIdx,
                                                bracketVibe: rating,
                                                
                                               ))
                }
            }
        }
        
        let summary = GameSummary(
            winningSeatIndex: self.winnerID != -1 ? self.winnerID : nil,
            winCondition: self.gameOver?.winMethod ?? "Unknown",
            vibeChecks: vibeChecks
        )
        
        return GameRecord(
            header: header,
            pod: seats,
            timeline: timeline,
            summary: summary
        )
    }
}
