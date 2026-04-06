import Foundation
import SwiftUI


@Observable
public class FinalPod: Codable {
    /// Represents the final state of a completed game
    public var gameID: String
    public var date: Date
    public var duration: TimeInterval
    public var commanders: [Commander]
    public var totalRounds: Int
    public var winMethod: String
    
    enum CodingKeys: String, CodingKey {
        case _gameID = "gameID"
        case _date = "date"
        case _duration = "duration"
        case _commanders = "commanders"
        case _totalRounds = "totalRounds"
        case _winMethod = "winMethod"
    }

    
    // MARK: - Computed Properties
    public var commandersSortedByTurnOrder: [Commander] {
        return commanders.sorted(by: { $0.turnOrder < $1.turnOrder })
    }
    
    public var sortedCommanderNames: [String] {
        return self.commandersSortedByTurnOrder.map { $0.name }
    }
    
    public var winningCommander: Commander? {
        return commanders.first { $0.winner }
    }
    
    public var winningCommanderName: String? {
        return winningCommander?.name
    }

    public var winningPartner: Commander? {
        return  commanders.first { $0.winner && $0.isPartner }
    }
    
    public var winningPartnerName: String? {
        return winningPartner?.name
    }
    
    public var winningDisplayName: String? {
        return winningCommander?.displayNames
    }
    
    public var winningPlayerIndex: Int? {
        return commanders.firstIndex { $0.winner }
    }
    
    public var winnersColor: Color {
        guard let win = winningCommander else {
            return Color.black
        }
        return getColor(for: win.turnOrder)
    }
    
    public var playedTurns: Int {
        winningCommander?.turnCount ?? 0
    }
    
    public var eliminatedCommanders: [Commander] {
        return commanders.filter { $0.eliminated }
    }
    
    public var formattedDuration: String {
        return duration.formattedDuration(style: .full)
    }
    
    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    
    // MARK: - Initialization
    
    public init(gameID: String, date: Date, duration: TimeInterval, commanders: [Commander], totalRounds: Int, winMethod: String) {
        self.gameID = gameID
        self.date = date
        self.duration = duration
        self.commanders = commanders
        self.totalRounds = totalRounds
        self.winMethod = winMethod
    }
    

    // MARK: - Game Analysis
    
    public var averageTurnDuration: TimeInterval {
        let totalTurns = commanders.map { $0.turnDurations.count }.reduce(0, +)
        guard totalTurns > 0 else { return 0 }
        return duration / TimeInterval(totalTurns)
    }
    
    public var fastestCommander: Commander? {
        return commanders.min { $0.averageTurnDuration < $1.averageTurnDuration }
    }
    
    public var slowestCommander: Commander? {
        return commanders.max { $0.averageTurnDuration < $1.averageTurnDuration }
    }
    
    public var mostAggressiveCommander: Commander? {
        return commanders.max { $0.totalCommanderDamage < $1.totalCommanderDamage }
    }
    
    public var playRatio: [Double] {
        return commanders.map { $0.totalTurnTime / duration }
    }
    
    public var rounds: Int? {
        if let w_id = winningPlayerIndex {
            return commanders[w_id].turnDurations.count
        }
        return 0
    }

}


public struct FinalPodWithTurns {
    public var finalPod: FinalPod
    public var turns: [Turn]
}



// MARK: - Array Extension for Final State
public extension Array where Element == FinalPod {
    
    public var commanderPlayCounts : [String:Int] {
        return self.flatMap { $0.commanders.flatMap {$0.name} }.reduce(into: [:]) { counts, letter in
            counts[letter, default: 0] += 1}
    }

    public var totalUniqueCommanders: Int {
        return commanderPlayCounts.keys.count
    }
    
    public var mostPlayedCommander : String {
        commanderPlayCounts.max(by: {$0.value < $1.value})?.key ?? ""
    }
    
    
    public func getOverviewStatistics() -> OverviewStatistics {

        return OverviewStatistics(
            totalGames: self.count,
            totalCommanders: self.totalUniqueCommanders,
            averageGameDuration: self.isEmpty ? 0 : self.map { $0.duration }.reduce(0, +) / Double(self.count),
            totalPlaytime: self.map { $0.duration }.reduce(0, +),
            mostPlayedCommander: self.mostPlayedCommander,
            lastGameDate: self.first?.date
        )
    }
    
    
    public func getCommanderSummaries() -> [String:CommanderSummary] {
        var commanderData: [String: CommanderSummary] = [:]

        for game in self {
            for commander in game.commanders {
                let key = commander.fullCommanderName
                var data = commanderData[key, default: CommanderSummary(fullName: key)]
                
                data.games += 1
                
                if commander.winner { data.wins += 1 }
                if commander.eliminated { data.timesEliminated += 1 }
                
                let method = commander.eliminationMethod ?? EliminationMethod.notEliminated
                data.eliminationMethods[method, default: 0] += 1
                if let eliminationRound = commander.eliminationRound {
                    data.eliminationRounds.append(eliminationRound)
                }
                
                data.totalRounds += game.totalRounds
            
                data.turnDurations.append(contentsOf: commander.turnDurations)
                data.turnDurationsPerTurn.append(commander.turnDurations)
                data.podPlaytimeRatio.append(commander.totalTurnTime / game.duration)
                if commander.winner { data.timeToWin.append(commander.totalTurnTime) }
                
                data.damagePerGameHistory.append(commander.totalCommanderDamage)
                data.totalCommanderDamage += commander.totalCommanderDamage
                data.totalPartnerDamage += commander.totalPartnerDamage ?? 0
                data.totalTax += commander.tax
                data.taxPerGame.append(Double(commander.tax))
                
                data.seatOrder.add(turnOrder: commander.turnOrder, win: commander.winner)
                data.brackets.append(commander.bracketRating)

                data.podDurations.append(game.duration)
                
                /// Calculate turn time percentage for this game
                if game.duration > 0 {
                    let turnPercentage = (commander.totalTurnTime / game.duration)
                    data.podPlaytimeRatio.append(turnPercentage)
                }
                /// Track partner games
                if !commander.partner.isEmpty {
                    data.partnerGames += 1
                    if commander.winner { data.partnerWins += 1 }
                }
                
                commanderData[key] = data
            }
        }
        return  commanderData
    }
}

