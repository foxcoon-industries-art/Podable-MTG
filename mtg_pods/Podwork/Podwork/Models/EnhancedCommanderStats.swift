import SwiftUI
import Podwork


public struct OverviewStatistics: Codable {
    public let totalGames: Int
    public let totalCommanders: Int
    public let averageGameDuration: TimeInterval
    public let totalPlaytime: TimeInterval
    public let mostPlayedCommander: String?
    public let lastGameDate: Date?
    
    public init(totalGames: Int, totalCommanders: Int, averageGameDuration: TimeInterval, totalPlaytime: TimeInterval, mostPlayedCommander: String?, lastGameDate: Date?) {
        self.totalGames = totalGames
        self.totalCommanders = totalCommanders
        self.averageGameDuration = averageGameDuration
        self.totalPlaytime = totalPlaytime
        self.mostPlayedCommander = mostPlayedCommander
        self.lastGameDate = lastGameDate
    }
    
    public var formattedAverageGameDuration: String {
        return averageGameDuration.formattedDuration()
    }
    
    public var formattedTotalPlaytime: String {
        return totalPlaytime.formattedDuration(style: .full)
    }
    
    public var gamesPerDay: Double {
        guard let lastDate = lastGameDate else { return 0 }
        let daysSinceFirst = abs(lastDate.timeIntervalSinceNow) / (24 * 60 * 60)
        return daysSinceFirst > 0 ? Double(totalGames) / daysSinceFirst : 0
    }
}



// MARK: - Statistics Data Structure
public struct CommanderStatistics: Codable, Identifiable {
    public let id = UUID()
    public let name: String
    public let gamesPlayed: Int
    public let wins: Int
    public let avgGameLength: Double
    public let avgTurnDuration: TimeInterval
    public let totalCommanderDamageDealt: Int
    public let avgTaxPaid: Double
    public let timesEliminated: Int
    public let totalTax: Int
    
    
    public init(name: String, gamesPlayed: Int, wins: Int, avgGameLength: Double, avgTurnDuration: TimeInterval, totalCommanderDamageDealt: Int, avgTaxPaid: Double, timesEliminated: Int, totalTax: Int) {
        self.name = name
        self.gamesPlayed = gamesPlayed
        self.wins = wins
        self.avgGameLength = avgGameLength
        self.avgTurnDuration = avgTurnDuration
        self.totalCommanderDamageDealt = totalCommanderDamageDealt
        self.avgTaxPaid = avgTaxPaid
        self.timesEliminated = timesEliminated
        self.totalTax = totalTax
    }
    
    // MARK: - Computed Properties
    
    public var winPercentage: Double {
        return gamesPlayed > 0 ? 100.0 * (Double(wins) / Double(gamesPlayed)): 0
    }
    
    public var survivalRate: Double {
        let survivalCount = gamesPlayed - timesEliminated
        return gamesPlayed > 0 ? Double(survivalCount) / Double(gamesPlayed) * 100 : 0
    }
    
    public var damagePerGame: Double {
        return gamesPlayed > 0 ? Double(totalCommanderDamageDealt) / Double(gamesPlayed) : 0
    }
    
    public var efficiency: Double {
        return avgTurnDuration > 0 ? damagePerGame / avgTurnDuration : 0
    }
}



public struct SeatOrder {
    public var seats: [Int:Seat] = [:]
    
    public init() {self.seats = [0: Seat(seatID: 0), 1: Seat(seatID: 1), 2: Seat(seatID: 2), 3: Seat(seatID: 3)]}
    
    public var turnOrderWinRates: [Seat] { self.seats.map { $0.value } .sorted(by: { $0.seatID < $1.seatID }) }
    
    public struct Seat:  Identifiable {
        public var id = UUID()
        public let seatID: Int
        public var wins: Int = 0
        public var games: Int = 0
        
        public init(seatID: Int) { self.seatID = seatID }
    }
    
    public mutating func add(turnOrder: Int, win:Bool){
        guard turnOrder < 4, turnOrder >= 0 else { return }
        self.seats[turnOrder]?.games += 1
        self.seats[turnOrder]?.wins += win ? 1 : 0
    }
}

public extension Array where Element == SeatOrder {
    
    func combineAll() -> SeatOrder {
        var globalSeatOrder = SeatOrder()
        for sitting in self {
            sitting.seats.forEach { key, value in
                globalSeatOrder.seats[key]?.games += value.games
                globalSeatOrder.seats[key]?.wins += value.wins
            }
        }
        return globalSeatOrder
    }
}


public extension Array where Element == CommanderSummary {
    public func combinedTurnOrderWinRates() -> SeatOrder {
        self.map {$0.seatOrder} .combineAll()
    }
}


public extension Dictionary where Key == String, Value == CommanderSummary {
    public func summariesOnly() -> [CommanderSummary] {
        self.map { $0.value }
    }
    public func turnOrderWinRates() -> SeatOrder {
        self.summariesOnly().combinedTurnOrderWinRates()
    }
}


public typealias CommanderNameStats = [String: CommanderSummary]

public struct CommanderSummary {
    
    public init(fullName: String){
        if fullName.contains("//"){
            let split = fullName.split(separator: "//")
            self.commander = String(split[0])
            self.partner = String(split[1])
        } else {
            self.commander = fullName
            self.partner = ""
        }
    }
    public let commander: String
    public let partner: String?
    
    public var games = 0
    public var wins = 0
    public var timesEliminated = 0
    public var eliminationMethods: [EliminationMethod: Int] = [:]
    public var eliminationRounds: [Int] = []
    public var totalRounds : Int  = 0
    public var seatOrder: SeatOrder = SeatOrder()
    
    public var podDurations: [TimeInterval] = []
    public var turnDurations: [TimeInterval] = []
    public var turnDurationsPerTurn: [[TimeInterval]] = [[]]
    public var timeToWin: [TimeInterval] = []
    public var podPlaytimeRatio: [Double] = []
    
    public var totalCommanderDamage = 0
    public var totalPartnerDamage = 0
    public var commanderDamagesDoneEachTurn: [Int:[Int]] = [:]
    public var damagePerGameHistory: [Int] = []
    public var totalTax = 0
    public var totalSolRings = 0
    public var totalTurnOneSolRings = 0
    public var taxPerGame: [Double] = []
    
    public var brackets: [Int] = []
    var bracketsByOpponents: [Int] = []
    
    var partnerGames = 0
    var partnerWins = 0
    
    public var displayNames : String { "\(commander)\n\(partner ?? "")" }
    
    public var totalCommanderDamageDealt : Int { totalCommanderDamage }
    public var totalTaxPaid : Int { totalTax }
    
    public var winRate : Double { games > 0 ? (Double(wins) / Double(games)) : 0 }
    
    public var winPercentage : Double { games > 0 ? 100.0 * winRate : 0 }
    
    public var survivalRate : Double {games > 0 ? Double(games - timesEliminated) / Double(games) : 0 }
    
    public var avgCommanderDamagePerGame : Double { games > 0 ? Double(totalCommanderDamage) / Double(games) : 0 }
    
    public var avgPodDuration: Double { podDurations.isEmpty ? 0 : podDurations.reduce(0, +) / Double(podDurations.count)}
    
    public var avgGameLength : Double {
        games > 0 ? Double(totalRounds) / Double(games) : 0 }
    
    public var avgTax : Double { games > 0 ? Double(totalTax) / Double(games) : 0 }

    public var avgTimeToWin : Double {timeToWin.isEmpty ? 0 : timeToWin.reduce(0, +) / Double(timeToWin.count)}
    
    public var avgTurnDuration : Double {turnDurations.isEmpty ? 0 : turnDurations.reduce(0, +) / Double(turnDurations.count)}
    public var stdTurnDuration : Double {turnDurations.isEmpty ? 0 : turnDurations.standardDeviation ?? 0}
    
    public var avgPodPlaytimeRatio : Double {podPlaytimeRatio.isEmpty ? 0 : podPlaytimeRatio.reduce(0, +) / Double(podPlaytimeRatio.count)}
    
    public var maxTurnsOfGames : Int { turnDurationsPerTurn.map { $0.count }.max() ?? 0 }
    
    
    public var efficiency: Double {
        // Metric combining win rate and turn speed
        let turnEfficiency = avgTurnDuration > 0 ? 60.0 / avgTurnDuration : 0
        return winPercentage * turnEfficiency / 100.0
    }
    
    public var avgBracket : Int {
        guard brackets.count > 0 else { print("No brackets rated")
            return 1 }
        print("avg Bracket",  Double(brackets.reduce(0, +)) / Double(brackets.count))
        return Int( Double(brackets.reduce(0, +)) / Double(brackets.count))
    }
    
    public var mostFrequentBracket : Int {
        var bracketCounts: [Int: Int] = [:]
        for number in self.brackets {
            bracketCounts[number, default: 0] += 1
        }
        // Find the element with the highest count
        guard let (bracketNumber, total) = bracketCounts.max(by: { $0.value < $1.value }) else {
            return 0
        }
        return Int(bracketNumber)
    }
    
    
    public var concessionRate : Double {
        let runs = eliminationMethods[EliminationMethod.concede]
        let total = self.games == 0 ? 1.0 : Double(  self.games )
        return Double(runs ?? 0) / total
    }
    
    public var avgDurationPerTurn : [Double] {
        var turnTimeAverages: [Double] = []
        for turnIndex in 0..<maxTurnsOfGames {
            let timeOfTurn = turnDurationsPerTurn.compactMap { turnDurs -> Double? in
                guard turnIndex < turnDurs.count else { return nil }
                return turnDurs[turnIndex]
            }
            if !timeOfTurn.isEmpty {
                let average = timeOfTurn.reduce(0, +) / Double(timeOfTurn.count)
                turnTimeAverages.append(average)
            } else { turnTimeAverages.append(0.0) }
        }
        return turnTimeAverages
    }
    
    public var stdDevTimePerTurn : [Double] {
        var timeOfTurns: [[Double]] = Array(repeating: [], count: maxTurnsOfGames)
        //for turnIdx in 0..<maxTurnsOfGames {
            
        Array(turnDurationsPerTurn.enumerated()).forEach { (podIdx, pod) in
            Array(pod.enumerated()).forEach  { turnIdx, turnDur in
                timeOfTurns[turnIdx].append(turnDur)
            }
        }
        let stds = timeOfTurns.map { $0.standardDeviation }
        
        return stds
    }
    
    public var avgEliminationRound : Double {
        eliminationRounds.isEmpty ? 0 : Double(eliminationRounds.reduce(0, +)) / Double(eliminationRounds.count) }
    
}



public extension CommanderSummary {
    
    // Add properties to track individual game data
    // (These should already exist or be added to the model)
    // var damagePerGameHistory: [Double] = []
    // var timePerGameHistory: [TimeInterval] = []
    
    public var damagePerGameStdDev: Double {
        guard games > 1 else { return 0 }
        
        let values = damagePerGameHistory
        let mean = damagePerGameHistory.mean ?? 0
        
        let sumOfSquaredDifferences = values.reduce(0.0) { sum, value in
            sum + pow(Double(value) - mean, 2)
        }
        
        let variance = sumOfSquaredDifferences / Double(games - 1)
        return sqrt(variance)
    }
    
    public var timePerGameStdDev: Double {
        guard games > 1 else { return 0 }
        
        let values = podDurations
        let mean = podDurations.mean
        
        let sumOfSquaredDifferences = values.reduce(0.0) { sum, value in
            sum + pow(value - mean, 2)
        }
        
        let variance = sumOfSquaredDifferences / Double(games - 1)
        return sqrt(variance)
    }
    
    public var damagePerGameWithStdDev: String {
        let avg = String(format: "%.1f", damagePerGameHistory.mean)
        let stdDev = String(format: "%.1f", damagePerGameStdDev)
        return "\(avg) ± \(stdDev)"
    }
    
    public var timePerGameWithStdDev: String {
        let avgMinutes = podDurations.mean / 60.0
        let stdDevMinutes = timePerGameStdDev / 60.0
        return String(format: "%.0f ± %.0f min", avgMinutes, stdDevMinutes)
    }
}
