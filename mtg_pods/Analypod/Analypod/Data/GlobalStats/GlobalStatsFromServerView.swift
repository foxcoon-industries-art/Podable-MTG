import SwiftUI
import Charts
import Podwork
import SwiftData
import Foundation
import Combine


@Observable
class BracketStatisticsManager {
    var statistics: BracketStatistics_?
    var isLoading = false
    var error: BracketStatistics_Error?
    var lastUpdated: Date?
    
    private let modelContext: ModelContext
    private let api: BracketStatistics_API
    private let cacheValidityDuration: TimeInterval = 300 // 5 minutes
    
    init(modelContext: ModelContext, baseURL: String = "https://foxcoon-industries.ca/pods") {
        self.modelContext = modelContext
        self.api = BracketStatistics_API(baseURL: baseURL)
        loadFromCache()
    }
    
    func loadFromCache() {
        let descriptor = FetchDescriptor<CachedBracketStatistics>()
        if let cached = try? modelContext.fetch(descriptor).first,
           let stats = cached.toBracketStatistics() {
            self.statistics = stats
            self.lastUpdated = cached.lastUpdated
        }
    }
    
    @MainActor
    func fetchStatistics(forceRefresh: Bool = false) {
        // Check if cache is still valid
        if !forceRefresh,
           let lastUpdated = lastUpdated,
           Date().timeIntervalSince(lastUpdated) < cacheValidityDuration,
           statistics != nil {
            return
        }
        
        isLoading = true
        error = nil
        
        api.fetchStatistics(useTestData: false)
        
        // Observe API changes
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            
            if let stats = self.api.statistics {
                self.statistics = stats
                self.lastUpdated = Date()
                self.saveToCache(stats)
                self.isLoading = false
            } else if let error = self.api.error {
                self.error = error
                self.isLoading = false
            }
        }
    }
    
    private func saveToCache(_ statistics: BracketStatistics_) {
        let descriptor = FetchDescriptor<CachedBracketStatistics>()
        let existing = try? modelContext.fetch(descriptor)
        existing?.forEach { modelContext.delete($0) }
        
        let cached = CachedBracketStatistics(statistics: statistics, lastUpdated: Date())
        modelContext.insert(cached)
        try? modelContext.save()
    }
}


@Model
public final class CachedBracketStatistics {
    @Attribute(.unique) public var id: String = "singleton"
    var totalGames: Int
    var bracketsData: Data
    var lastUpdated: Date
    
    public init(statistics: BracketStatistics_, lastUpdated: Date) {
        self.totalGames = statistics.totalGames
        self.lastUpdated = lastUpdated
        self.bracketsData = (try? JSONEncoder().encode(statistics.brackets)) ?? Data()
    }
    
    func toBracketStatistics() -> BracketStatistics_? {
        guard let brackets = try? JSONDecoder().decode([Int: BracketData].self, from: bracketsData) else {
            return nil
        }
        return BracketStatistics_(totalGames: totalGames, brackets: brackets)
    }
}

// MARK: - VIBE CHECK DATA
/// Represents a single vibe check data point
public struct VibeCheckEntry: Codable, Identifiable {
    public let id = UUID()
    let opponentBracket: Int
    let count: Int
    
    enum CodingKeys: String, CodingKey {
        case opponentBracket = "opponent_bracket"
        case count
    }
}

public extension Array where Element == VibeCheckEntry {
    func maxCount() -> Int {
        guard !isEmpty else { return 0 }
        return self.map{ $0.count}.max() ?? 0
    }
}

// MARK: - TURN ORDER DATA
/// Represents turn order statistics for winners
public struct TurnOrderEntry: Codable, Identifiable {
    public let id = UUID()
    let turnOrder: Int
    let wins: Int
    
    enum CodingKeys: String, CodingKey {
        case turnOrder = "turn_order"
        case wins
    }
}

// MARK: - BRACKET DATA
/// Statistics for a single bracket
public struct BracketData: Codable {
    let gamesPlayed: Int
    let vibeCheckDistribution: [VibeCheckEntry]
    let winnerTurnOrderDistribution: [TurnOrderEntry]
    let mostLikelyWinnerTurnOrder: Int?
    let percentageOfTotalGames: Double
    
    enum CodingKeys: String, CodingKey {
        case gamesPlayed = "games_played"
        case vibeCheckDistribution = "vibe_check_distribution"
        case winnerTurnOrderDistribution = "winner_turn_order_distribution"
        case mostLikelyWinnerTurnOrder = "most_likely_winner_turn_order"
        case percentageOfTotalGames = "percentage_of_total_games"
    }
    
    var maxTotalRatings: Int {
        vibeCheckDistribution.maxCount()
    }
    /// Calculate the average opponent rating for vibe check
    var averageOpponentRating: Double {
        guard !vibeCheckDistribution.isEmpty else { return 0 }
        
        let totalCount = vibeCheckDistribution.reduce(0) { $0 + $1.count }
        let weightedSum = vibeCheckDistribution.reduce(0) {
            $0 + ($1.opponentBracket * $1.count)
        }
        return totalCount > 0 ? Double(weightedSum) / Double(totalCount) : 0
    }
    
    /// Get the most common opponent bracket rating
    var mostCommonOpponentBracket: Int? {
        vibeCheckDistribution.max(by: { $0.count < $1.count })?.opponentBracket
    }
    
    /// Calculate win rate by turn order (percentage)
    func winRateForTurnOrder(_ turnOrder: Int) -> Double {
        guard let entry = winnerTurnOrderDistribution.first(where: { $0.turnOrder == turnOrder }) else {
            return 0
        }
        
        let totalWins = winnerTurnOrderDistribution.reduce(0) { $0 + $1.wins }
        return totalWins > 0 ? (Double(entry.wins) / Double(totalWins)) * 100 : 0
    }
}

public extension Array where Element == BracketData {
    func maxYAxisValue() -> Int {
        self.map{ $0.maxTotalRatings }.max() ?? 0
    }
}

// MARK: - BracketStatistics_

/// Complete bracket statistics response
public struct BracketStatistics_: Codable {
    let totalGames: Int
    let brackets: [Int: BracketData]
    
    enum CodingKeys: String, CodingKey {
        case totalGames = "total_games"
        case brackets
    }
    
    func allBracketData() -> [BracketData] { self.brackets.map{ $0.value } }
    func maxYAxisValue() -> Int { allBracketData().maxYAxisValue() }
    func statistics(for bracket: Int) -> BracketData? { return brackets[bracket]}
    var sortedBracketNumbers: [Int] { return brackets.keys.sorted() }
    var gameDistribution: [(bracket: Int, percentage: Double)] {
        return sortedBracketNumbers.map { bracket in
            let percentage = brackets[bracket]?.percentageOfTotalGames ?? 0
            return (bracket: bracket, percentage: percentage)
        }
    }

    var mostPlayedBracket: Int {
        brackets.max(by: { $0.value.gamesPlayed < $1.value.gamesPlayed })?.key ?? 1
    }
    
    var leastPlayedBracket: Int {
        brackets.min(by: { $0.value.gamesPlayed < $1.value.gamesPlayed })?.key ?? 1
    }
    
    var bracketWithMostAgreement: Int {
        // Agreement = when opponents rate you in your own bracket most often
        var maxAgreement = 0.0
        var bestBracket = 1
        
        for (bracket, data) in brackets {
            let ownBracketCount = data.vibeCheckDistribution.first(where: { $0.opponentBracket == bracket })?.count ?? 0
            let totalCount = data.vibeCheckDistribution.reduce(0) { $0 + $1.count }
            let agreement = totalCount > 0 ? Double(ownBracketCount) / Double(totalCount) : 0
            
            if agreement > maxAgreement {
                maxAgreement = agreement
                bestBracket = bracket
            }
        }
        
        return bestBracket
    }
    
    var bracketWithMostDisparity: Int {
        // Disparity = standard deviation of opponent ratings
        var maxDisparity = 0.0
        var worstBracket = 1
        
        for (bracket, data) in brackets {
            let disparity = calculateDisparity(for: data)
            
            if disparity > maxDisparity {
                maxDisparity = disparity
                worstBracket = bracket
            }
        }
        
        return worstBracket
    }
    
    func bracketWithMostWinsByPosition(_ position : Int) -> Int {
        guard position >= 0 && position < 4 else { return 1 }
        var maxWinRate = 0.0
        var bestBracket = 1
        
        for (bracket, data) in brackets {
            let positionWins = data.winnerTurnOrderDistribution.first(where: { $0.turnOrder == position })?.wins ?? 0
            let totalWins = data.winnerTurnOrderDistribution.reduce(0) { $0 + $1.wins }
            let winRate = totalWins > 0 ? Double(positionWins) / Double(totalWins) : 0
            
            if winRate > maxWinRate {
                maxWinRate = winRate
                bestBracket = bracket
            }
        }
        
        
        return bestBracket
    }
    
    var maxVibeCheckCount: Int {
        brackets.values.flatMap { $0.vibeCheckDistribution }.map { $0.count }.max() ?? 0
    }
    
    private func calculateDisparity(for data: BracketData) -> Double {
        let counts = data.vibeCheckDistribution
        guard !counts.isEmpty else { return 0 }
        
        let totalCount = counts.reduce(0) { $0 + $1.count }
        guard totalCount > 0 else { return 0 }
        
        // Calculate mean
        let mean = counts.reduce(0.0) { $0 + (Double($1.opponentBracket * $1.count)) } / Double(totalCount)
        
        // Calculate variance
        let variance = counts.reduce(0.0) { sum, entry in
            let diff = Double(entry.opponentBracket) - mean
            return sum + (diff * diff * Double(entry.count))
        } / Double(totalCount)
        
        // Return standard deviation
        return sqrt(variance)
    }
}


// MARK: - API CLIENT
/// API client for fetching bracket statistics
class BracketStatistics_API: ObservableObject {
    @Published var statistics: BracketStatistics_?
    @Published var isLoading = false
    @Published var error: BracketStatistics_Error?
    @Published var lastUpdated: Date?
    
    private var cancellables = Set<AnyCancellable>()
    private let baseURL: String
    private let session: URLSession
    private let endpoint = "/brackets"
    /// Initialize with base URL
    /// - Parameter baseURL: Base URL for the API (e.g., "http://localhost:5000")
    init(baseURL: String = "https://foxcoon-industries.ca/pods", session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }
    
    /// Fetch bracket statistics from the API
    /// - Parameter useTestData: If true, uses the test endpoint
    func fetchStatistics(useTestData: Bool = false) {
        isLoading = true
        error = nil
        
        print("Now fetching ...")
        
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            self.error = .invalidURL
            self.isLoading = false
            return
        }
        
        session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: BracketStatistics_Response.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        if let decodingError = error as? DecodingError {
                            self?.error = .decodingError(decodingError.localizedDescription)
                        } else {
                            self?.error = .networkError(error.localizedDescription)
                        }
                    }
                },
                receiveValue: { [weak self] response in
                    if response.success {
                        self?.statistics = response.data
                        self?.lastUpdated = Date()
                    } else {
                        self?.error = .serverError(response.error ?? "Unknown error")
                    }
                }
            )
            .store(in: &cancellables)
    }
}



// MARK: - RESPONSE FROM SERVER
/// API response wrapper
struct BracketStatistics_Response: Codable {
    let success: Bool
    let data: BracketStatistics_?
    let error: String?
    let timestamp: String
    let testMode: Bool?
    
    enum CodingKeys: String, CodingKey {
        case success
        case data
        case error
        case timestamp
        case testMode = "test_mode"
    }
}


/// Errors that can occur when fetching bracket statistics
enum BracketStatistics_Error: LocalizedError {
    case invalidURL
    case noData
    case decodingError(String)
    case serverError(String)
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .noData:
            return "No data received from server"
        case .decodingError(let details):
            return "Failed to decode response: \(details)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

























struct EnhancedSummaryCard: View {
    let statistics: BracketStatistics_
    let lastUpdated: Date?
    
    var body: some View {
        VStack{
            
            VStack(spacing: 8) {
                
                // Row 1:
                HStack(spacing: 8) {
//                    SummaryStatItem(
//                        title: "Total Pods",
//                        value: "\(statistics.totalGames)",
//                        icon: "gamecontroller.fill",
//                        color: .blue
//                    )
                    
                    SummaryStatItem(
                        title: "Most Played",
                        value: "B\(statistics.mostPlayedBracket)",
                        icon: "chart.line.uptrend.xyaxis",
                        color: .green
                    )
                   
                    SummaryStatItem(
                        title: "Most Agreement",
                        value: "B\(statistics.bracketWithMostAgreement)",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
                  
                    SummaryStatItem(
                        title: "Most 1st Player Wins",
                        value: "B\(statistics.bracketWithMostWinsByPosition(0))",
                        icon: "trophy.fill",
                        color: .yellow
                    )
                } // Row 2:
                
                HStack(spacing: 8) {
                    
                SummaryStatItem(
                    title: "Least Played",
                    value: "B\(statistics.leastPlayedBracket)",
                    icon: "chart.line.downtrend.xyaxis",
                    color: .red
                )
                
               
              
                    SummaryStatItem(
                        title: "Most Disparity",
                        value: "B\(statistics.bracketWithMostDisparity)",
                        icon: "exclamationmark.triangle.fill",
                        color: .orange
                    )
                    
                  
                    SummaryStatItem(
                        title: "Most 4th Player Wins",
                        value: "B\(statistics.bracketWithMostWinsByPosition(3))",
                        icon: "trophy.fill",
                        color: .brown
                    )
                   
                }
                
                if let lastUpdated = lastUpdated {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                        Text("Updated \(timeAgoString(from: lastUpdated))")
                        Text("•")
                        Text(lastUpdated.formatted(date: .abbreviated, time: .shortened))
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func timeAgoString(from date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        if seconds < 60 { return "just now" }
        if seconds < 3600 { return "\(Int(seconds / 60))m ago" }
        if seconds < 86400 { return "\(Int(seconds / 3600))h ago" }
        return "\(Int(seconds / 86400))d ago"
    }
}

 //MARK: - Bracket Distribution Chart (Percentage Based)

struct BracketDistributionChart: View {
    let statistics: BracketStatistics_
    
    var percentageMax : Double {
        Array([1,2,3,4,5]).map{statistics.statistics(for: $0)!}.map{$0.percentageOfTotalGames} .max()!
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bracket Distribution")
                .font(.headline)
            
            Chart {
                ForEach(statistics.sortedBracketNumbers, id: \.self) { bracket in
                    if let data = statistics.statistics(for: bracket) {
                        BarMark(
                            x: .value("Bracket", "B\(bracket)"),
                            y: .value("Percentage", data.percentageOfTotalGames)
                        )
                        .foregroundStyle(bracketGradient(for: bracket))
                        .annotation(position: .top) {
                            Text(String(format: "%.1f%%", data.percentageOfTotalGames))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .frame(height: 120)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let percentage = value.as(Double.self) {
                            Text("\(Int(percentage))%")
                        }
                    }
                }
            }
            .chartYScale(domain: 0...(1.1 * percentageMax))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func bracketGradient(for bracket: Int) -> LinearGradient {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue]
        let color = colors[min(bracket - 1, colors.count - 1)]
        return LinearGradient(colors: [color.opacity(0.6), color], startPoint: .bottom, endPoint: .top)
    }
}

// MARK: - All Brackets Vibe Check Chart

struct AllBracketsVibeCheckChart: View {
    let statistics: BracketStatistics_
    @Binding var selectedBracket : Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Vibe Check by Bracket")
                .font(.headline)
            
            Text("Each chart shows the bracket rating that each opponent gave the winner (highlighted bar = own bracket)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .bottom , spacing: 8) {
                ForEach(statistics.sortedBracketNumbers, id: \.self) { bracket in
                    if let data = statistics.statistics(for: bracket) {
                        SingleBracketVibeChart(
                            bracketNumber: bracket,
                            data: data,
                            maxCount: statistics.maxVibeCheckCount,
                            isSelectedBracket:   selectedBracket == bracket

                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                selectedBracket = bracket
                            }
                        }
                    }
                }
            }
            .frame(height: 120)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct SingleBracketVibeChart: View {
    let bracketNumber: Int
    let data: BracketData
    let maxCount: Int
    let isSelectedBracket : Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text("B\(bracketNumber)")
                .font(.caption.bold())
            
            // Create chart with all 5 brackets represented
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(BracketSystem.allCases, id: \.self) { bkt in
                    let opponentBracket = bkt.rawValue
                    let count = data.vibeCheckDistribution.first(where: { $0.opponentBracket == opponentBracket })?.count ?? 0
                    let percentage = maxCount > 0 ? CGFloat(count) / CGFloat(maxCount) : 0
                    let isSameBracket = opponentBracket == bracketNumber
                    
                 
                        
                        VStack(spacing: 2) {
                            Rectangle()
                                .fill( bracketColor(for: opponentBracket))
                                .opacity(isSameBracket ? 1.0 : 0.3)
                                .frame(height: max(percentage * 80, 2))
                            
                            Text("\(opponentBracket)")
                                .font(.system(size: 8))
                                .foregroundColor(isSameBracket ? .primary : .secondary)
                        }
                    
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        //.background(Color(.secondarySystemBackground))
        .cornerRadius(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke( isSelectedBracket ? bracketColor(for: bracketNumber) : Color.clear, lineWidth: 2)
                )
        )

    }
    
    private func bracketColor(for bracket: Int) -> Color {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue]
        return colors[min(bracket - 1, colors.count - 1)]
    }
}


// MARK: - Updated Main View

struct BracketStatistics_View: View {
    @Environment(\.modelContext) private var modelContext
    @State private var manager: BracketStatisticsManager?
    @State private var selectedBracket = 3
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    if let manager = manager {
                        if manager.isLoading && manager.statistics == nil {
                            ProgressView("Loading bracket statistics...")
                                .padding()
                        } else if let error = manager.error, manager.statistics == nil {
                            ErrorView(message: error.errorDescription ?? "?") {
                                manager.fetchStatistics(forceRefresh: true)
                            }
                        } else if let statistics = manager.statistics {
                            contentView(statistics: statistics, manager: manager)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let manager = manager {
                    Button(action: {
                        manager.fetchStatistics(forceRefresh: true)
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(manager.isLoading ? 360 : 0))
                            .animation(manager.isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: manager.isLoading)
                    }
                    .disabled(manager.isLoading)
                }
            }
        }
        .onAppear {
            if manager == nil {
                manager = BracketStatisticsManager(modelContext: modelContext)
                manager?.fetchStatistics()
            }
        }
    }
    
    @ViewBuilder
    private func contentView(statistics: BracketStatistics_, manager: BracketStatisticsManager) -> some View {
        // Enhanced Summary Section
        EnhancedSummaryCard(statistics: statistics, lastUpdated: manager.lastUpdated)
        
        // Bracket Distribution Bar Chart (Percentage)
        BracketDistributionChart(statistics: statistics)
        
        // Bracket Selector
        BracketSelector(selectedBracket: $selectedBracket)
        
        
        // All Brackets Vibe Check Chart
        AllBracketsVibeCheckChart(statistics: statistics, selectedBracket: $selectedBracket)
        
        // Turn Order Mini Charts
        TurnOrderMiniCharts(
            statistics: statistics,
            selectedBracket: $selectedBracket
        )
        
        // Selected Bracket Details
        if let bracketData = statistics.statistics(for: selectedBracket) {
            SelectedBracketDetails(
                bracket: selectedBracket,
                data: bracketData,
                totalGames: statistics.totalGames
            )
            
            // Individual Vibe Check Chart for selected bracket
            VibeCheckSection(data: bracketData, bracket: selectedBracket)
        }
    }
}



struct SummaryStatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Bracket Distribution Chart
//
//struct BracketDistributionChart: View {
//    let statistics: BracketStatistics_
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            Text("Bracket Distribution")
//                .font(.headline)
//            
//            Chart {
//                ForEach(statistics.sortedBracketNumbers, id: \.self) { bracket in
//                    if let data = statistics.statistics(for: bracket) {
//                        BarMark(
//                            x: .value("Bracket", "B\(bracket)"),
//                            y: .value("Games", data.gamesPlayed)
//                        )
//                        .foregroundStyle(bracketGradient(for: bracket))
//                        .annotation(position: .top) {
//                            Text("\(data.gamesPlayed)")
//                                .font(.caption2)
//                                .foregroundColor(.secondary)
//                        }
//                    }
//                }
//            }
//            .frame(height: 120)
//            .chartYAxis {
//                AxisMarks(position: .leading)
//            }
//        }
//        .padding()
//        .background(Color(.systemGray6))
//        .cornerRadius(16)
//    }
//    
//    private func bracketGradient(for bracket: Int) -> LinearGradient {
//        let colors: [Color] = [.red, .orange, .yellow, .green, .blue]
//        let color = colors[min(bracket - 1, colors.count - 1)]
//        return LinearGradient(colors: [color.opacity(0.6), color], startPoint: .bottom, endPoint: .top)
//    }
//}

// MARK: - Turn Order Mini Charts

struct TurnOrderMiniCharts: View {
    let statistics: BracketStatistics_
    @Binding var selectedBracket: Int
    
    let turnOrderColors: [Color] = [
        Color(red: 0.2, green: 0.4, blue: 0.8),  // Position 0 - Blue
        Color(red: 0.3, green: 0.7, blue: 0.3),  // Position 1 - Green
        Color(red: 0.9, green: 0.6, blue: 0.2),  // Position 2 - Orange
        Color(red: 0.8, green: 0.3, blue: 0.3)   // Position 3 - Red
    ]
    let turnNames: [String] = ["1st", "2nd", "3rd", "4th"]

    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Turn Order Win Rates")
                    .font(.headline)
                
                Spacer()
                
                // Legend
                HStack(spacing: 8) {
                    ForEach(0..<4) { position in
                        HStack(spacing: 4) {
                            Circle()
                                //.fill(turnOrderColors[position])
                                .fill(ColorPalettes.pbCup(position+1))
                                .frame(width: 8, height: 8)
                            Text("\(turnNames[position])")
                                .font(.caption2)
                        }
                    }
                }
            }
            
            HStack(spacing: 8) {
                ForEach(statistics.sortedBracketNumbers, id: \.self) { bracketNumber in
                    if let bracketData = statistics.statistics(for: bracketNumber) {
                        VStack(spacing: 4) {
                            TurnOrderDonutChart(
                                data: bracketData,
                                colors: turnOrderColors
                            )
                            .frame(height: 80)
                            
                            Text("B\(bracketNumber)")
                                .font(.caption.bold())
                                .foregroundColor(selectedBracket == bracketNumber ? .yellow : .primary)
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                //.fill(Color(.secondarySystemBackground))
                                .fill( Color(.secondarySystemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke( selectedBracket == bracketNumber ?bracketColor(for: bracketNumber) : Color.clear, lineWidth: 2)
                                )
//                                .overlay(
//                                    RoundedRectangle(cornerRadius: 12)
//                                        .stroke(selectedBracket == bracketNumber ? Color.yellow : Color.clear, lineWidth: 3)
//                                )
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                selectedBracket = bracketNumber
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    private func bracketColor(for bracket: Int) -> Color {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue]
        return colors[min(bracket - 1, colors.count - 1)]
    }
}

struct TurnOrderDonutChart: View {
    let data: BracketData
    let colors: [Color]
    
    var body: some View {
        Chart(data.winnerTurnOrderDistribution.sorted(by: { $0.turnOrder < $1.turnOrder })) { entry in
            SectorMark(
                angle: .value("Wins", entry.wins),
                innerRadius: .ratio(0.618),
                angularInset: 1.5
            )
            //.foregroundStyle(colors[min(entry.turnOrder, colors.count - 1)])
            .foregroundStyle(ColorPalettes.pbCup(min(entry.turnOrder, colors.count - 1)+1))
        }
    }
}

// MARK: - Selected Bracket Details

struct SelectedBracketDetails: View {
    let bracket: Int
    let data: BracketData
    let totalGames: Int
    
    let turnNames: [String] = ["First Player", "Second Player", "Third Player", "Final Player"]
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Bracket \(bracket) Details")
                .font(.title3.bold())
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],  spacing: 6) {
                DetailStatCard(
                    title: "Games Played",
                    value: "\(data.gamesPlayed)",
                    icon: "gamecontroller",
                    color: .blue
                )
                
                DetailStatCard(
                    title: "Play Rate of Total",
                    value: String(format: "%.1f%%", data.percentageOfTotalGames),
                    icon: "chart.pie",
                    color: .green
                )
                
                if let mostLikely = data.mostLikelyWinnerTurnOrder {
                    DetailStatCard(
                        title: "Best Position",
                        value: "\(turnNames[mostLikely])",
                        icon: "trophy.fill",
                        color: .orange
                    )
                }
                
//                if let mostCommon = data.mostCommonOpponentBracket {
//                    DetailStatCard(
//                        title: "Common Opponent",
//                        value: "Bracket \(mostCommon)",
//                        icon: "person.2",
//                        color: .purple
//                    )
//                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct DetailStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack{
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(value)
                    .font(.title3.bold())
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
            
            }
        
        Text(title)
            .font(.caption)
            .foregroundColor(.secondary)
            .lineLimit(1)
            .multilineTextAlignment(.center)
        }
        //.padding()
        .frame(maxWidth: .infinity)
        //.padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Vibe Check Section

struct VibeCheckSection: View {
    let data: BracketData
    let bracket: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Opponent Bracket Distribution")
                .font(.headline)
            
            Chart(data.vibeCheckDistribution) { entry in
                BarMark(
                    x: .value("Opponent Bracket", "B\(entry.opponentBracket)"),
                    y: .value("Count", entry.count)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.6), Color.blue],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .annotation(position: .top) {
                    Text("\(entry.count)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct BracketSelector: View {
    @Binding var selectedBracket: Int
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
//            Text("Brackets")
//                .font(.title2)
//                .background(Color(.secondarySystemFill))

            Picker("Bracket", selection: $selectedBracket) {
                ForEach(1...5, id: \.self) { bracket in
                    Text("Bracket \(bracket)")
                        .tag(bracket)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .background(Color(.tertiarySystemBackground))
    }
}

struct BracketDetailCard: View {
    let bracket: Int
    let data: BracketData
    @Binding var showVibeCheck: Bool
    @Binding var showTurnOrder: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Bracket \(bracket) Details")
                .font(.headline)
            
            VStack(spacing: 12) {
                DetailRow(label: "Games Played", value: "\(data.gamesPlayed)")
                DetailRow(label: "% of Total", value: String(format: "%.1f%%", data.percentageOfTotalGames))
                DetailRow(label: "Avg Opponent Rating", value: String(format: "%.2f", data.averageOpponentRating))
                
                if let mostLikely = data.mostLikelyWinnerTurnOrder {
                    DetailRow(label: "Most Likely Winner Position", value: "Turn \(mostLikely)")
                }
            }
            
            HStack(spacing: 12) {
                Button(action: { showVibeCheck.toggle() }) {
                    Label(
                        showVibeCheck ? "Hide Vibe Check" : "Show Vibe Check",
                        systemImage: "chart.bar"
                    )
                    .font(.footnote)
                }
                .buttonStyle(BorderedButtonStyle())
                
                Button(action: { showTurnOrder.toggle() }) {
                    Label(
                        showTurnOrder ? "Hide Turn Order" : "Show Turn Order",
                        systemImage: "list.number"
                    )
                    .font(.footnote)
                }
                .buttonStyle(BorderedButtonStyle())
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

@available(iOS 16.0, *)
struct VibeCheckChart: View {
    let data: BracketData
    let maxYaxisValue: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Chart(data.vibeCheckDistribution) { entry in
                BarMark(
                    x: .value("Opponent Bracket", entry.opponentBracket),
                    y: .value("Count", entry.count)
                )
                .foregroundStyle(Color.blue.gradient)
                
                RuleMark(y: .value("max", maxYaxisValue))
            }
            .frame(height: 50)
            .chartXAxis {
                AxisMarks(values: [1, 2, 3, 4, 5])
            }
            .chartYScale(domain: 0...maxYaxisValue)
           // .chartXAxis(.hidden)
            .chartYAxis(.hidden)
        }
        .padding(2)
        .background(Color(.systemGray6))
    }
}

@available(iOS 16.0, *)
struct TurnOrderChart: View {
    let data: BracketData
    // Needs better colours for turn order chart segements
    let colorByTurnOrder: [Color] = [.white, Color(.systemGray), Color(.systemGray3), Color(.systemGray5)]
    
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            Chart(data.winnerTurnOrderDistribution) { entry in
                SectorMark(
                    angle: .value("Value", Double(data.winRateForTurnOrder( entry.turnOrder))),
                    innerRadius: .ratio(0.618),
                    outerRadius: .inset(10),
                    angularInset: 1
                )
                .foregroundStyle(colorByTurnOrder[entry.turnOrder])
            }
            .frame(height: 70)
            //.chartXAxis { AxisMarks(values: [0, 1, 2, 3]) }
            .chartYAxis(.hidden)
        }
        .padding(2)
        .background(Color(.tertiarySystemBackground))
    }
}

struct BracketComparisonView: View {
    let statistics: BracketStatistics_
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bracket Comparison")
                .font(.headline)
            
            ForEach(statistics.sortedBracketNumbers, id: \.self) { bracket in
                if let data = statistics.statistics(for: bracket) {
                    HStack {
                        Text("B\(bracket)")
                            .font(.caption)
                            .frame(width: 30)
                        
                        GeometryReader { geometry in
                            Rectangle()
                                .fill(bracketColor(for: bracket).gradient)
                                .frame(width: geometry.size.width * data.percentageOfTotalGames / 100)
                        }
                        .frame(height: 20)
                        
                        Text("\(data.gamesPlayed)")
                            .font(.caption)
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    func bracketColor(for bracket: Int) -> Color {
        switch bracket {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .green
        case 5: return .blue
        default: return .gray
        }
    }
}

// Helper Views

struct StatItem: View {
    let label: String
    let value: String
    let systemImage: String
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            HStack{
                Image(systemName: systemImage)
                Text(value)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.25)
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .stroke(Color.gray.opacity(0.52), lineWidth: 2)
            )
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}
//
//struct ErrorView: View {
//    let error: BracketStatistics_Error
//    let retry: () -> Void
//    
//    var body: some View {
//        VStack(spacing: 16) {
//            Image(systemName: "exclamationmark.triangle.fill")
//                .font(.largeTitle)
//                .foregroundColor(.red)
//            
//            Text("Error Loading Data")
//                .font(.headline)
//            
//            Text(error.localizedDescription)
//                .font(.caption)
//                .foregroundColor(.secondary)
//                .multilineTextAlignment(.center)
//            
//            Button("Retry", action: retry)
//                .buttonStyle(BorderedProminentButtonStyle())
//        }
//        .padding()
//    }
//}

// For iOS versions that don't have Charts framework
struct FallbackVibeCheckChart: View {
    let data: BracketData
    var maxCount: Int { data.vibeCheckDistribution.map(\.count).max() ?? 1 }

    var body: some View {
        VStack{
            Text("Vibe Check Distribution")
                .font(.headline)
            HStack(alignment: .center, spacing: 2) {
                
                ForEach(data.vibeCheckDistribution) { entry in
                    VStack {
                        GeometryReader { geometry in
                            Rectangle()
                                .fill(Color(.systemGray6))
                                .frame(height: geometry.size.height * (1 - (CGFloat(entry.count) / CGFloat(maxCount)) ))
                            
                        }
                        .frame(height: 60)
                        .background(Color.blue.gradient)
                        
                        Text("\(entry.count)")
                            .font(.caption)
                            .frame(width: 30, alignment: .trailing)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// Preview Provider
struct BracketStatistics_View_Previews: PreviewProvider {
    static var previews: some View {
        BracketStatistics_View()
        BracketStatistics_View_()
    }
}



// MARK: - Enhanced API with Persistence

// Data structures and API client for bracket statistics
//
// REVIEW NOTES:
// - Needs Data persistence of Bracket data & timestamp of last update
// - Prevent fetching so much by loading data from persistence
//

// MARK: - View Model Helper

/// View model for presenting bracket statistics
@available(iOS 13.0, macOS 10.15, *)
class BracketStatistics_ViewModel: ObservableObject {
    @Published var selectedBracket: Int = 3
    @Published var comparisonMode: Bool = false
    @Published var comparisonBracket: Int = 3
    
    private let api = BracketStatistics_API()
    var statistics: BracketStatistics_? { api.statistics }
    var isLoading: Bool { api.isLoading }
    var error: BracketStatistics_Error? { api.error }
    
    /// Get formatted statistics for display
    func formattedStatistics(for bracket: Int) -> String {
        guard let data = statistics?.statistics(for: bracket) else {
            return "No data available"
        }
        
        return """
        Games Played: \(data.gamesPlayed)
        Percentage of Total: \(String(format: "%.1f%%", data.percentageOfTotalGames))
        Average Opponent Rating: \(String(format: "%.2f", data.averageOpponentRating))
        Most Likely Winner Position: \(data.mostLikelyWinnerTurnOrder ?? 0)
        """
    }
    
    /// Compare two brackets
    func compareStatistics() -> String {
        guard let stats = statistics,
              let data1 = stats.statistics(for: selectedBracket),
              let data2 = stats.statistics(for: comparisonBracket) else {
            return "Insufficient data for comparison"
        }
        
        return """
        Bracket \(selectedBracket) vs Bracket \(comparisonBracket)
        
        Games: \(data1.gamesPlayed) vs \(data2.gamesPlayed)
        Avg Opponent Rating: \(String(format: "%.2f", data1.averageOpponentRating)) vs \(String(format: "%.2f", data2.averageOpponentRating))
        Most Likely Winner Position: \(data1.mostLikelyWinnerTurnOrder ?? 0) vs \(data2.mostLikelyWinnerTurnOrder ?? 0)
        """
    }
    
    /// Load statistics
    func loadStatistics(useTestData: Bool = false) {
        api.fetchStatistics(useTestData: useTestData)
    }
}

// MARK: - Sample Usage
// Example usage in a SwiftUI view:
// - Question: Why does this only show the button and nothing else?
import SwiftUI
struct BracketStatistics_View_: View {
    @StateObject private var viewModel = BracketStatistics_ViewModel()
    private let api = BracketStatistics_API( )
    var body: some View {
        VStack {
            if api.isLoading {
                ProgressView("Loading statistics...")
                    .foregroundColor(.red)
                let _ = print(api.isLoading)
            }
            else if let error = viewModel.error {
                Text("Error: \(error.localizedDescription)")
                    .foregroundColor(.red)
                let _ = print(error)

            }
            if let stats = api.statistics {
                let _ = print(stats)
                // Display statistics UI
                ForEach(stats.sortedBracketNumbers, id: \.self) { bracket in
                    let _ = print(bracket)
                    if let data = stats.statistics(for: bracket) {
                        VStack(alignment: .leading) {
                            Text("Bracket \(bracket)")
                                .font(.headline)
                            Text("Games: \(data.gamesPlayed)")
                            Text("Win Rate Position 1: \(String(format: "%.1f%%", data.winRateForTurnOrder(1)))")
                        }
                        .foregroundStyle(Color.white)
                        .padding()
                    }
                }
            }
            
            Button("Refresh") {api.fetchStatistics()}
        }
        
        .onAppear {
            let _ = print("\(api.statistics)")
            api.fetchStatistics() // Use test data for development
        }
    }
}
