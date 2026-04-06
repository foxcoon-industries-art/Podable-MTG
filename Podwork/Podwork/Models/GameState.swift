import Foundation
import SwiftUI


public enum ActiveCommander: Codable, CaseIterable {
    case commander
    case partner
}


@MainActor
@Observable
public class GameState {
    /// Core game state management - handles active game logic
    public var podID: String = ""
    
    @ObservationIgnored public var gameDate: Date = Date()
    @ObservationIgnored public var tutorialMode: Bool = false

    private var podPlayers : [Bool] = []
    public var players: [Player] = []

    public var currentRound: Int = 0
    public var currentTurn: Turn
    public var podHistory: [Turn] = []
    public var currentActivePlayerTurnNumber : Int = 1
    public var finished: Bool = false
    public var inTheEndGame: Bool = false
    public var skipEndRatings: Bool = false
    public var showEndGameRatings: Bool = true
    public var gameOver: FinalPod?
    public var winnerID: Int = -1
    public var firstOutID: Int = -1
    public var turnResetCount: Int = 0
    public var finalTime: Date? = nil
    
    public var podCasts : PodCastHistory = PodCastHistory(podID: "")
    var playerEliminationRound : [Int:Int] = [:]
    var activeCommanderPartner : [Int:ActiveCommander] = [:]

    
    // MARK: - Pod Initializer

    //@MainActor
    public init() {
        self.tutorialMode = UserDefaults.standard.bool(forKey: "showTutorial") ?? false
        self.podPlayers = UserDefaults.standard.array(forKey: "podPlayers") as? [Bool] ?? [true, true,true, true]
        let firstPlayerID = UserDefaults.standard.integer(forKey: "firstPlayer") ?? 0
        let selfRatedBrackets = UserDefaults.standard.array(forKey: "selfRatedBrackets") as? [Int] ?? [0,0,0,0]
        self.currentTurn = Turn.initialTurn(firstPlayer: firstPlayerID, gameStartTime: Date.now)

        for (index,quad) in GameConstants.playerOrder.enumerated() {
            self.addPlayer(  firstPlayerID: firstPlayerID )
            self.players[index].deckBracket[index] = selfRatedBrackets[index]
            if !self.podPlayers[index] { self.playerMissing(who: index) }
        }
        setAllCommanderPartners()

        print("Turn Zero:", self.currentTurn)
        print("First PlayerID:", firstPlayerID)
        updatePlayerRoundDisplayNumber()
    }
    


    // MARK: - Pod Configuration
    public func addPlayer( firstPlayerID: Int) {
        let playerNameID = ((self.players.count + (4-firstPlayerID)) % 4) + 1
        let defaultName =  "Player \(playerNameID)"
        let newPlayer = Player(commanderName: defaultName, id: self.players.count)
        self.players.append(newPlayer)
    }

    public func assignWhoGoesFirst(as playerID: Int) {
        guard playerID >= 0 && playerID < players.count else { return }
        self.currentTurn.activePlayer = playerID
    }
    
    public var playerCount: Int {
        return self.players.count
    }
    
    public var nPlayers: Int {
        self.podPlayers.filter { $0 }.count
    }
    
    public var playerIndices: [Int] {
        return self.podPlayers.enumerated().compactMap{ (idx,playing) in
            if playing {return idx}
            return nil }
    }
    
    // MARK: - Active Commander/Partner Swapping Functions
    
    public func setAllCommanderPartners() {
        for i in 0..<players.count{
            self.activeCommanderPartner[i] = ActiveCommander.commander
        }
    }
    public func swapActiveCommander(for playerID: Int){
        if self.players[playerID].hasPartner {
            var choices = [ActiveCommander.commander, ActiveCommander.partner]
            if let currentlyActive = self.activeCommanderPartner[playerID]{
                if let index = choices.firstIndex(of: currentlyActive) {
                    choices.remove(at: index)
                    self.activeCommanderPartner[playerID] = choices[0]
                }
            }
        }
    }
    
    public func indexOfActiveCommander(for playerID: Int) -> Int {
        guard playerID < players.count else { return 0 }
        return self.activeCommanderPartner[playerID] == ActiveCommander.commander ? 0 : 1
    }
    
    public func indexOfPlayersActiveCommanders() -> [Int]{
        return self.players.indices.map {indexOfActiveCommander(for: $0)}
    }
    
    public func whichCommanderIsActive(for playerID: Int) -> ActiveCommander {
        guard playerID < players.count else { return  ActiveCommander.commander }
        let cmdrType = self.activeCommanderPartner[playerID] ??  ActiveCommander.commander
        return cmdrType
    }
    
    public func commanderTaxes(for playerID: Int) -> [Int] {
        guard playerID < players.count else { return [0] }
        if self.players[playerID].hasPartner {
            return [self.players[playerID].commanderTax, self.players[playerID].partnerTax ]
        }
        return [self.players[playerID].commanderTax]
    }
    
    public func playerHasPartner(for playerID: Int) -> Bool {
        guard playerID < players.count else { return false }
        return self.players[playerID].hasPartner
    }

    public func whichPlayersHavePartner() -> [Bool] {
        return self.players.map { $0.hasPartner}
    }
    
    public func commanderLog(for playerID: Int) -> Bool {
        guard playerID < players.count else { return false }
        return self.players[playerID].isCommanderEntered()
    }
    
    public func getCommanderPartnerNames(for playerID : Int) -> [String] {
        guard playerID < players.count else { return ["Invalid PlayerID"] }
        return self.players[playerID].fullCommanderPartnerName
    }
    
    public func getCommanderPartnerNamesForAllPlayers() -> [String] {
        return self.players.map {$0.formattedCommanderPartnerName}
    }
    
    public func currentCommanderDamages(for playerID: Int) -> [[Int]] {
        return self.currentTurn.getCommanderDamageWithDeltas(for: playerID)
    }
    
    // MARK: - Pod State Queries
    
    public func activePlayer() -> Int { return self.currentTurn.activePlayer }
    
    
    public func checkIfFirstTurn() -> Bool {  return self.currentTurn.id == 0 }
    
    public func showLife(playerID: Int) -> Int {
        guard playerID < players.count else { return 0 }
        return self.players[playerID].life
    }
    
    public func showLifeRatio(playerID: Int) -> Double {
        return max(0, min(1, CGFloat(self.showLife(playerID: playerID)) / CGFloat(GameConstants.defaultStartingLife)))
    }
    
    public func showDeltaLife(playerID: Int) -> Int {
        guard playerID < currentTurn.deltaLife.count else { return 0 }
        return self.currentTurn.deltaLife[playerID]
    }
    
    public func showDeltaCmdrDamage(opponentID: Int, playerID: Int) -> Int {
        guard playerID < currentTurn.deltaCmdrDamage.count,
              opponentID < currentTurn.deltaCmdrDamage[playerID].count else { return 0 }
        return self.currentTurn.deltaCmdrDamage[playerID][opponentID]
    }
    
    public func showCmdrDamageTotal(opponentID: Int, playerID: Int) -> Int {
        guard playerID < currentTurn.cmdrDmgTotal.count,
              opponentID < currentTurn.cmdrDmgTotal[playerID].count else { return 0 }
        return self.currentTurn.cmdrDmgTotal[playerID][opponentID]
    }
    
    public func getCmdrDamagesFromAllPlayers(for playerID: Int) -> [Int] {
        return self.currentTurn.cmdrDmgTotal[playerID]
    }
    
    public func getDeltaCmdrDamagesFromAllPlayers(for playerID: Int) -> [Int] {
        return self.currentTurn.deltaCmdrDamage[playerID]
    }

    public func showDeltaPoison(playerIndex: Int) -> Int {
        guard playerIndex < currentTurn.deltaInfect.count else { return 0 }
        return self.currentTurn.deltaInfect[playerIndex]
    }
    
    public func showTotalInfect(playerID: Int) -> Int {
        guard playerID < players.count else { return 0 }
        return self.players[playerID].infect + showDeltaPoison(playerIndex: playerID)
    }
    
    public func showSumDeltaLife(playerID: Int) -> Int {
        guard playerID < currentTurn.deltaLife.count,
              playerID < currentTurn.deltaCmdrDamage.count else { return 0 }
        
        var deltaLife = self.currentTurn.deltaLife[playerID]
        for opponentID in 0..<4 {
            if opponentID < currentTurn.deltaCmdrDamage[playerID].count {
                deltaLife -= self.currentTurn.deltaCmdrDamage[playerID][opponentID]
            }
        }
        return deltaLife
    }
    
    public func fullHistoryOfDeltaCmdrDamage(opponentID: Int, playerID: Int) -> [Int] {
        var cmdrDmgChunks: [Int] = []
        
        for previousTurn in self.podHistory {
            guard playerID < previousTurn.deltaCmdrDamage.count,
                  opponentID < previousTurn.deltaCmdrDamage[playerID].count else { continue }
            
            let cmdrDmg = previousTurn.deltaCmdrDamage[playerID][opponentID]
            if cmdrDmg != 0 {
                cmdrDmgChunks.append(cmdrDmg)
            }
        }
        return cmdrDmgChunks
    }
    
    // MARK: - Pod Actions
    
    public func addPoison(to playerIndex: Int) {
        guard playerIndex < currentTurn.deltaInfect.count else { return }
        guard currentTurn.deltaInfect[playerIndex] < 10 else { return }
        self.currentTurn.deltaInfect[playerIndex] += 1
    }
    
    public func subtractPoison(from playerIndex: Int) {
        guard playerIndex < currentTurn.deltaInfect.count else { return }
        self.currentTurn.deltaInfect[playerIndex] = max(0, self.currentTurn.deltaInfect[playerIndex] - 1)
    }
    
    public func increaseCommanderTax(for playerIndex: Int) {
        guard playerIndex < players.count else { return }
        if self.whichCommanderIsActive(for: playerIndex) == ActiveCommander.commander {
            self.players[playerIndex].commanderTax += 1}
        else { self.players[playerIndex].partnerTax += 1 }
        changeCommanderTax(for: playerIndex, by: 1)
    }
    
    public func decreaseCommanderTax(for playerIndex: Int) {
        guard playerIndex < players.count else { return }
        if self.whichCommanderIsActive(for: playerIndex) == ActiveCommander.commander {
            self.players[playerIndex].commanderTax = max(0, players[playerIndex].commanderTax - 1)
        } else { self.players[playerIndex].partnerTax = max(0, players[playerIndex].partnerTax - 1) }
        changeCommanderTax(for: playerIndex, by: -1)
    }
    
    public func changeCommanderTax(for playerIndex: Int, by amount: Int) {
        guard playerIndex < players.count else { return }
        var castingName: String = ""
        var isPartner: Bool = false
        if self.whichCommanderIsActive(for: playerIndex) == ActiveCommander.commander {
            castingName = self.players[playerIndex].commanderName }
        else {
            castingName = self.players[playerIndex].partnerName
            isPartner = true }
        if amount > 0 {
            try? podCasts.addCastTaxReceipt(turnID: self.currentTurn.id,
                                            playerID: playerIndex,
                                            casting: castingName,
                                            isPartner: isPartner,
                                            increment: 1)
        } else {
            try? podCasts.removeCastTaxFromReceipt(turnID: self.currentTurn.id,
                                            playerID: playerIndex,
                                            casting: castingName,
                                            isPartner: isPartner,
                                            increment: 1)
        }
    }

    
    
    // MARK: - Damage Application
    
    public func removeDamage(from playerIndex: Int, to targetIndex: Int, as commanderDamage: Bool) {
        guard targetIndex < currentTurn.deltaLife.count else { return }
        
        if commanderDamage {
            guard targetIndex < currentTurn.deltaCmdrDamage.count,
                  playerIndex < currentTurn.deltaCmdrDamage[targetIndex].count else { return }
            if self.whichCommanderIsActive(for: playerIndex) == ActiveCommander.commander {
                self.currentTurn.deltaCmdrDamage[targetIndex][playerIndex] = max(0,self.currentTurn.deltaCmdrDamage[targetIndex][playerIndex] - 1)
            }else{
                self.currentTurn.deltaPrtnrDamage[targetIndex][playerIndex] = max(0,self.currentTurn.deltaPrtnrDamage[targetIndex][playerIndex] - 1)
            }
        } else {
            self.currentTurn.deltaLife[targetIndex] += 1
        }
    }

    public func applyDamage(from playerIndex: Int, to targetIndex: Int, as commanderDamage: Bool) {
        guard targetIndex < currentTurn.deltaLife.count else { return }
        
        if commanderDamage {
            guard targetIndex < currentTurn.deltaCmdrDamage.count,
                  playerIndex < currentTurn.deltaCmdrDamage[targetIndex].count else { return }
            
            if self.whichCommanderIsActive(for: playerIndex) == ActiveCommander.commander {
                self.currentTurn.deltaCmdrDamage[targetIndex][playerIndex] += 1
            } else {
                self.currentTurn.deltaPrtnrDamage[targetIndex][playerIndex] += 1
            }
        } else {
            self.currentTurn.deltaLife[targetIndex] -= 1
        }
    }
    
    public func applyLifeDamage(of amount: [Int], from playerIndex: Int) {
        for (i, hp) in amount.enumerated() {
            if i < currentTurn.deltaLife.count {
                self.currentTurn.deltaLife[i] += hp
            }
        }
    }
    
    public func applyBombPodDamage(from playerIndex: Int) {
        try? self.podCasts.addBombReceipt( turnID: self.currentTurn.id, playerID: playerIndex, increment: 1)
        for (i, player) in self.players.enumerated() {
            if !player.isPlayerEliminated() && i != playerIndex && i < currentTurn.deltaLife.count {
                self.currentTurn.deltaLife[i] -= 1
            }
        }
      
    }
    
    // MARK: - Modify States of Players

    func updateEliminations() {
        for i in 0..<4 {
            if !self.playerEliminationRound.contains(where: {$0.key == i} ){
                if self.players[i].isPlayerEliminated(){
                    self.playerEliminationRound[i] = self.currentRound
                }
            }
        }
    }
    
    /// Used to determine the next player when others are eliminated
    func nextZeroIndex(from idx: Int, in boolList: [Bool]) -> Int {
        return (boolList[idx...] + boolList[..<idx]).firstIndex(where: { !$0 }) ?? -1
    }

    public func onReturnFromStarPod(playerID: Int, method: EliminationMethod) {
        if method == EliminationMethod.concede {
            self.playerConceded(who: playerID)
            print("Player \(playerID) conceded")
        }
        if method == EliminationMethod.milled {
            self.playerMilled(who: playerID)
            print("Player \(playerID) was Milled")
        }
        if method == EliminationMethod.emptySeat {
            self.playerMissing(who: playerID)
            print("Player \(playerID) is missing from game")
        }
        if method == EliminationMethod.altWin {
            self.playerAltWins(who: playerID)
            print("Player \(playerID) wins with Alt Win Con.")
        }
    }
    
    public func playerConceded(who playerID: Int) {
        guard playerID < players.count else { return }
        self.players[playerID].eliminated = true
        self.players[playerID].eliminationMethod = EliminationMethod.concede
        //self.players[playerID].life = 0
        self.players[playerID].eliminationRound = self.currentRound
        self.players[playerID].eliminationTurnID = self.currentTurn.id
        self.playerEliminationRound[playerID] = self.currentRound
    }
    
    public func playerMilled(who playerID: Int){
        self.players[playerID].eliminated = true
        self.players[playerID].eliminationMethod = EliminationMethod.milled
        //self.players[playerID].life = 0
        self.players[playerID].eliminationRound = self.currentRound
        self.players[playerID].eliminationTurnID = self.currentTurn.id
        self.playerEliminationRound[playerID] = self.currentRound
    }
    
    
    public func playerMissing(who playerID: Int){
        self.players[playerID].commanderName = "No Player"
        self.players[playerID].eliminated = true
        self.players[playerID].eliminationMethod = EliminationMethod.emptySeat
        //self.players[playerID].life = 0
        self.players[playerID].eliminationRound = 0
        self.players[playerID].eliminationTurnID = 0
        self.playerEliminationRound[playerID] = 0
    }
    
    
    public func playerAltWins(who altWinPlayerID: Int){
        let remainingPlayerIDs = self.remainingPlayerIDs()
        
        self.players.forEach { player in
            if remainingPlayerIDs.contains(player.id){
                if player.id != altWinPlayerID {
                    player.eliminated = true
                    player.eliminationMethod = EliminationMethod.altWin
                    player.eliminationRound = self.currentRound
                    player.eliminationTurnID = self.currentTurn.id
                    self.playerEliminationRound[player.id] = self.currentRound
                } else {
                    player.eliminated = false
                    player.winner = true
                }
            }
        }
        self.nextTurn()
    }
    
    
    public func removedPlayers() -> [Bool] {
        return self.players.map { $0.isPlayerEliminated() || $0.eliminationMethod == EliminationMethod.emptySeat }
    }
    
    public func remainingPlayerIDs() -> [Int] {
        return self.players.filter { !$0.isPlayerEliminated() && $0.eliminationMethod != EliminationMethod.emptySeat } .map{$0.id}
    }
    
    public func totalPlayers() -> Int {
        return self.players.filter { $0.eliminationMethod != EliminationMethod.emptySeat} .count
    }
    
    
    // MARK: - Turn Management
    /**/
    @MainActor
    public func resetTurn() {
        guard !self.podHistory.isEmpty else {
            print("No previous turn to reset to.")
            return
        }
        print("Reset Turn triggered")
        print("Before",self.currentTurn.lifeTotal, self.currentTurn.deltaLife)
        let previousTurn = self.podHistory.removeLast()
        
        for i in 0..<self.players.count {
            self.players[i].life -= previousTurn.deltaLife[i]
            self.players[i].infect -= previousTurn.deltaInfect[i]
            for j in 0..<self.players.count {
                self.players[i].commanderDamage[j] -= previousTurn.deltaCmdrDamage[i][j]
                self.players[i].partnerDamage[j] -= previousTurn.deltaPrtnrDamage[i][j]
            }
            
            if !self.players[i].timePerTurn.isEmpty {
                self.players[i].timePerTurn.removeLast()
            }
            
            if previousTurn.id == self.players[i].eliminationTurnID {
                self.players[i].eliminated = false
                self.players[i].eliminationRound = nil
                self.players[i].eliminationTurnID = nil
                self.players[i].eliminationMethod = EliminationMethod.notEliminated
            }
            
            if self.players[i].eliminated && !self.players[i].isPlayerEliminated() {
                self.players[i].eliminated = false
                self.players[i].eliminationRound = nil
                self.players[i].eliminationTurnID = nil
                self.players[i].eliminationMethod = EliminationMethod.notEliminated
            }
        }
        print("Current Turn Number:", self.currentActivePlayerTurnNumber, self.currentRound)
        self.currentActivePlayerTurnNumber -= 1
        self.currentRound -= 1
        print("Turn Number Reset to:", self.currentActivePlayerTurnNumber, self.currentRound)
        print("Life Totals Before Reset:", self.currentTurn.lifeTotal, self.currentTurn.deltaLife)
        self.currentTurn = previousTurn
        print("Life Totals After Reset:", self.currentTurn.lifeTotal, self.currentTurn.deltaLife)
        self.turnResetCount += 1
        print("Turns have been reset to a previous state", self.turnResetCount, "times.")
    }


    public func resetFromTutorialMode() {
        let firstPlayerID = UserDefaults.standard.integer(forKey: "firstPlayer")
        self.podHistory.removeAll()
        self.currentTurn = Turn.initialTurn(firstPlayer: firstPlayerID, gameStartTime: Date.now)
        for playerID in 0..<self.nPlayers {
            self.players[playerID].resetPlayer()
        }
        Task {await self.podCasts.deleteHistory()
            self.podCasts = PodCastHistory(podID: "")
        }
        self.playerEliminationRound = [:]
        self.activeCommanderPartner = [:]
        self.finished = false
        self.winnerID = -1
        self.firstOutID = -1
        self.currentRound = 0
        self.turnResetCount = 0
        self.currentActivePlayerTurnNumber = 1
        setAllCommanderPartners()
        updatePlayerRoundDisplayNumber()
        print("Turn Zero:", self.currentTurn)
    }
    
    @MainActor
    public func nextTurn(extra playerID : Int? = nil) {
      
        if self.finished { return }
        
        /// Finalize Current Turn
        self.assignTurnDuration()
        
        /// Update All Players with Current Turn
        for i in 0..<players.count { players[i].update(after: currentTurn) }
        
        /// Add to History
        self.podHistory.append(self.currentTurn)

        self.attemptEndGame()
        if self.finished { return }
     
        print("End Turn:", self.currentTurn.id, "activePlayer:", self.currentTurn.activePlayer )
        self.updateRound()
        
        /// Find Next Active Player
        var nextPlayerID : Int = 0
        let nextAfterRemoved = nextZeroIndex(from: self.currentTurn.activePlayer+1, in: self.removedPlayers())
        nextPlayerID = (nextAfterRemoved%4)
        if let newID = playerID, newID != nil { nextPlayerID = newID  ; print("nextPlayerID",nextPlayerID) }
        
        ///  Begin New Turn
        self.currentTurn = Turn(from: self.currentTurn, with: nextPlayerID, after: Date() )
        print("New Turn:", self.currentTurn.id, "activePlayer:", self.currentTurn.activePlayer)
        self.updatePlayerRoundDisplayNumber()
    }
    
    
    
    private func assignTurnDuration() {
        self.currentTurn.whenTurnEnded = Date()
        if self.currentTurn.id == 0 {
            /// Set the very first turn to take 30 seconds - account for all the pre-pod non-game actions
            self.currentTurn.turnDuration = Double(30.0)
        } else {
            self.currentTurn.turnDuration = self.currentTurn.whenTurnEnded.timeIntervalSince( self.podHistory.last!.whenTurnEnded)
        }
    }
    
    @MainActor
    public func attemptEndGame(){
        let gameWasWon = self.hasWinningStateBeenFound()
        print("[End Game] - Has Winning State?", gameWasWon)
        if gameWasWon {
            do{
                try self.gameToPod()
                print("Attempted gameToPod save to sql.")
                self.finished = true
                print("self.finished ... \(self.finished)")
                return
            } catch { print("End Game - Error caught") }
        }
    }
    
    func updateRound() {
        self.currentRound += 1
        self.currentTurn.round = self.currentRound
    }
    
    public func updatePlayerRoundDisplayNumber() {
        var turnCount: Int = 1
        for turn in podHistory {
            if turn.activePlayer == activePlayer() {
                turnCount += 1
            }
        }
        self.currentActivePlayerTurnNumber = turnCount
    }
    
    @MainActor
    public func gameToPod() throws {
        if let finalState = self.finalizeGameInformation(with: self.winnerID) {
            do {
                try SQLiteManager.shared.saveGame(finalState, podHistory: self.podHistory)
            } catch {
                print("❌ [GameState] Failed to save finalState or podHistory: \(error)\n")
            }
            self.finished = true
        }
    }
    
    
    // MARK: - Game End Logic
    @MainActor
    func hasWinningStateBeenFound() -> Bool {
        let removedPlayers = self.removedPlayers()
        let playersRemaining = removedPlayers.filter{$0==false}.count
        print("[Winning State] - Checking if Found...")
        print(" - Players Remaining: \(playersRemaining) ")
    
        if playersRemaining == (self.nPlayers - 1) && self.firstOutID == -1 {
            let firstOutID = removedPlayers.firstIndex(where: {$0 == true})
            self.firstOutID = firstOutID!
            print(" - First-out PlayerID: \(self.firstOutID)")
        }
        
        if playersRemaining == 0 {
            print(" ...TIED!")
            //self.gameOver = self.finalizeGameInformation(with: winnerID)
            self.players.map {$0.winner = false}
            self.players.map {$0.eliminationMethod = EliminationMethod.endingInDraw}
            self.finished = true
            if self.finalTime == nil {self.finalTime = Date.now}
            self.inTheEndGame = true
        }
        
        if playersRemaining == 1 {
            print(" ...Winner Found!")
            guard let winnerID = self.removedPlayers().firstIndex(where: {$0 == false}) else {return false}
            self.winnerID = winnerID
            self.players[winnerID].winner = true
            if self.finalTime == nil {self.finalTime = Date.now}
            withAnimation{ self.inTheEndGame = true }
            print("... in the End Game with WinnerID ", self.winnerID)

            //self.gameOver = self.finalizeGameInformation(with: winnerID)

        }
        
        print("... is gameOver Populated?", self.gameOver)
        if self.gameOver == nil {
            print(" SkipEndRatings? \(self.skipEndRatings)")
            if skipEndRatings { return skipEndRatings }
            
            let dataEntered = checkVibeCheckEntered()
            print(" Vibe Checked? \(dataEntered)")
            return dataEntered }

        print("returning with result: ", self.gameOver != nil)
        return self.gameOver != nil
    }
    
    // MARK: - Turn Reset
    
  

    
    // MARK: - Game Finalization
 

    public func checkCommanderNamesEntered() -> Bool {
        /// Make sure all commanders are entered
        let playingPlayers = self.players.filter { $0.eliminationMethod != EliminationMethod.emptySeat }
        let enteredCommanders = playingPlayers.map { $0.isCommanderEntered()}
        guard !enteredCommanders.contains(false) else {return false}
        return true
    }
    
    public func checkVibeCheckEntered() -> Bool {
        /// Make sure everyone has vibe checked the opponents brackets
        let playingPlayers = self.players.filter { $0.eliminationMethod != EliminationMethod.emptySeat }
        let ratedBrackets = playingPlayers.map( {$0.deckBracket} )
        let filteredBrackets = ratedBrackets.map { playerBracket in playerIndices.map{ playerBracket[$0] }}
        let totalCompletedRatings = filteredBrackets.map( {$0.allSatisfy({$0 != 0}) } ).count(where: {$0})
        guard totalCompletedRatings == totalPlayers() else {return false}
        return true
    }
    
    @MainActor
    public func finalizeGameInformation(with winnerID: Int) -> FinalPod? {
        print("[Finalize Game Info]")
        let commanders = self.players.flatMap { $0.toCommander() }
        let winMethod = self.assignWinMethod()
        //let gameDuration = abs(self.gameDate.timeIntervalSinceNow)
        if self.finalTime == nil {self.finalTime = Date.now}
        
        let gameDuration = abs(self.finalTime!.timeIntervalSince(self.gameDate))
        print("... Duration: ", gameDuration)
        
        let gameOver = FinalPod(
            gameID: self.podID,
            date: self.gameDate,
            duration: gameDuration,
            commanders: commanders,
            totalRounds: self.currentRound,
            winMethod: winMethod,
        )
        
        self.gameOver = gameOver
        print("... Game ID:", gameOver.gameID)
        return gameOver
    }
    

    
    public func assignWinMethod() -> String {
        let eliminatedPlayers = self.players.filter { $0.eliminated }
        let remainingPlayers = self.remainingPlayerIDs()
        guard remainingPlayers != [] else { return "Draw" }
        guard let lastEliminated = eliminatedPlayers.max(by: { ($0.eliminationTurnID ?? 0) < ($1.eliminationTurnID ?? 0) }) else {
            return "Unknown Win Condition"
        }
        if lastEliminated.eliminationMethod == EliminationMethod.altWin {
            return "Alternative Win Condition"
        }
        return lastEliminated.eliminationMethod.displayName
    }
    

  
}

