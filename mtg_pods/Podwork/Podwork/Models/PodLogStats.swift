import SwiftUI
import Podwork


public struct PodSummaryStats {
    /// Overall game statistics summary

    // Totals
    public var totalGames: Int
    public var totalCmdrsSeenPlayed: Int = 0
    public var totalPlaytime: TimeInterval = 0
    public var totalCommanderDamage: Int = 0
    public var totalCommanderTax: Int = 0
    
    // Glorious Ascension
    public var highestWinRate: CommanderNameStats = [:]
    public var mostPlayedCommander: CommanderNameStats = [:]
    public var mostCommanderDamage: CommanderNameStats = [:]
    public var mostTaxPaid: CommanderNameStats = [:]
    public var mostAltWins: CommanderNameStats = [:]
    public var fastestWins: CommanderNameStats = [:]
    public var mostSolRings: CommanderNameStats = [:]

    // Wall of Shame
    public var longestTurns: CommanderNameStats = [:]
    public var leastImpact: CommanderNameStats = [:]
    public var mostBracketDisparity: CommanderNameStats = [:]
    public var mostConcesions: CommanderNameStats = [:]
    public var mostEndOfTurnActions: CommanderNameStats = [:]
    public var mostBombsUsed: CommanderNameStats = [:]
    public var mostTurnOneSolRings: CommanderNameStats = [:]

    // Averages
    public var avgGameDuration: TimeInterval = 0
    public var stdGameDuration: Double = 0
    
    public var avgTurnsPerGame: Double = 0
    public var stdTurnsPerGame: Double = 0
        
    
    public var avgFirstRemovalRound: Double = 0
    public var stdFirstRemovalRound: Double = 0
    
    
    // Recents
    public var gamesThisWeek: Int = 0
    public var gamesThisMonth: Int = 0
    
    
    public init(totalGames: Int) {
        self.totalGames = totalGames
    }
    
    public var formattedTotalPlaytime: String {
        return totalPlaytime.formattedDuration(style: .full)
    }
    
    public var formattedAvgGameDuration: String {
        return TimeInterval(avgGameDuration).formattedDuration(style: .compact)
    }
    
    
    
    public static func getPodStats(from logs: [FinalPod], and commanderStatsByName: CommanderNameStats) -> PodSummaryStats {

        guard !logs.isEmpty else { return PodSummaryStats(totalGames: 0) }
        
        var stats = PodSummaryStats(totalGames: logs.count)
        
        // Calculate totals
        let allCommanders = Set(logs.flatMap { $0.commanders.map { $0.name } })
        stats.totalCmdrsSeenPlayed = allCommanders.count
        
        let fullGameDurations = logs.map { $0.duration }
        stats.totalPlaytime = fullGameDurations.reduce(0, +)
        stats.avgGameDuration = stats.totalPlaytime / Double(logs.count)
        stats.stdGameDuration = fullGameDurations.standardDeviation()
        
        let fullTotalRounds = logs.map { $0.totalRounds }
        let totalRounds = fullTotalRounds.reduce(0, +)
        stats.avgTurnsPerGame = Double(totalRounds) / Double(logs.count)
        stats.stdTurnsPerGame = fullTotalRounds.map{Double($0)}.standardDeviation()
        
        let fullFirstElimRounds = logs.compactMap{ $0.commanders.firstRemovalTurn }
        let totalFirstElimRounds = fullFirstElimRounds.reduce(0, +)
        stats.avgFirstRemovalRound = Double(totalFirstElimRounds) / Double(logs.count)
        stats.stdFirstRemovalRound = fullFirstElimRounds.asDoubleArray().standardDeviation()
        
        // Find most played commander
        let commanderCounts = logs.flatMap { $0.commanders.map { $0.name } }
            .reduce(into: [String: Int]()) { counts, commander in
                counts[commander, default: 0] += 1
            }
        let mostPlayed = commanderCounts.max { $0.value < $1.value }?.key ?? ""
        stats.mostPlayedCommander = commanderStatsByName.filter { $0.key == mostPlayed } //?? mostPlayed
        //stats.mostPlayedCommander = commanderCounts.max { $0.value < $1.value }?.key ?? ""
        
        // Find highest win rate commander (with minimum games)
        if let bestCommander = commanderStatsByName
            .filter({ $0.value.games >= 1 })
            .max(by: { $0.value.winPercentage < $1.value.winPercentage  && $0.value.totalCommanderDamageDealt < $1.value.totalCommanderDamageDealt }) {
            
            let winRate = bestCommander.key
            stats.highestWinRate = commanderStatsByName.filter { $0.key == winRate }
            //stats.highestWinRate = bestCommander.key
        }
        
        let mostTaxedCommander = commanderStatsByName.max(by: {$0.value.totalTaxPaid < $1.value.totalTaxPaid })
        let mostTaxed = mostTaxedCommander?.key ?? ""
        stats.mostTaxPaid = commanderStatsByName.filter { $0.key == mostTaxed }
        //stats.mostTaxPaid = mostTaxedCommander?.key ?? ""
        
        
        let mostDamageCommander = commanderStatsByName.max(by: {$0.value.totalCommanderDamage < $1.value.totalCommanderDamage })
        let mostDamage = mostDamageCommander?.key ?? ""
        stats.mostCommanderDamage = commanderStatsByName.filter { $0.key == mostDamage }
        
        let fastestWinCommander = commanderStatsByName.min(by: {$0.value.avgTimeToWin > $1.value.avgTimeToWin })
        let fastWinCommander = fastestWinCommander?.key ?? ""
        stats.fastestWins = commanderStatsByName.filter { $0.key == fastWinCommander }
        
        
        let longestAvgTurnCommander = commanderStatsByName.max(by: {$0.value.avgTurnDuration > $1.value.avgTurnDuration })
        let longestTurns = longestAvgTurnCommander?.key ?? ""
        stats.longestTurns = commanderStatsByName.filter { $0.key == longestTurns }
        
        
        // Calculate recent games
        let now = Date()
        let weekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: now) ?? now
        
        
        let mostConcessionsCommander = commanderStatsByName.max(by: {$0.value.concessionRate < $1.value.concessionRate })
        let mostConcessions = mostDamageCommander?.key ?? ""
        stats.mostConcesions = commanderStatsByName.filter { $0.key == mostConcessions }
        
        
        let leastImpactCommander = commanderStatsByName.min(by: {$0.value.avgCommanderDamagePerGame < $1.value.avgCommanderDamagePerGame })
        let leastImpactful = leastImpactCommander?.key ?? ""
        stats.leastImpact = commanderStatsByName.filter { $0.key == leastImpactful }
        
        
        
        stats.gamesThisWeek = logs.filter { $0.date >= weekAgo }.count
        stats.gamesThisMonth = logs.filter { $0.date >= monthAgo }.count
        
        return stats
        }
        
    
}
