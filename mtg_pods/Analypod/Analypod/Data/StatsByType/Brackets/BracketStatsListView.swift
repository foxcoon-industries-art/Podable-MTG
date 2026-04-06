import SwiftUI
import Charts
import Podwork


// ═══════════════════════════════════════════════════════════════════
// MARK: - Bracket Stats List View
// ═══════════════════════════════════════════════════════════════════

@MainActor
struct BracketStatsListView: View {
    @StateObject private var dataManager = GameDataManager.shared
    @State private var selectedBracket: Int? = nil
    
    var body: some View {
        if dataManager.finalStates.isEmpty {
            bracketEmptyState
        } else {
            VStack(spacing: 16) {
                BracketVibeCheckView(
                    dataManager.bracketStats.values.map { $0 }
                )
                .padding(.horizontal, 8)
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(sortedBrackets, id: \.bracket) { stat in
                            BracketStatRowCompact(
                                bracket: stat,
                                totalPlayed: totalGamesPlayed,
                                onTap: { selectedBracket = stat.bracket }
                            )
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .sheet(item: $selectedBracket) { bracketNum in
                BracketDetailSheet(bracketNumber: bracketNum)
            }
        }
    }
    
    private var sortedBrackets: [BracketStatistics] {
        dataManager.bracketStats.values
            .filter { $0.bracket >= 1 && $0.bracket <= 5 }
            .sorted { $0.bracket < $1.bracket }
    }
    
    private var totalGamesPlayed: Int {
        dataManager.bracketStats.values.map(\.games).reduce(0, +)
    }
    
    private var bracketEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar")
                .font(.system(size: 36))
                .foregroundStyle(Color.blue.opacity(0.4))
            Text("No Bracket Data Yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Play some games and rate brackets to see analysis here.")
                .font(.caption)
                .foregroundStyle(Color.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}


// ═══════════════════════════════════════════════════════════════════
// MARK: - Vibe Check Overview (top of list)
// ═══════════════════════════════════════════════════════════════════
/*
struct BracketVibeCheckView: View {
    let stats: [BracketStatistics]
    
    init(_ stats: [BracketStatistics]) {
        self.stats = stats
    }
    
    private var sortedStats: [BracketStatistics] {
        stats
            .filter { $0.bracket >= 1 && $0.bracket <= 5 && $0.totalrated > 0 }
            .sorted { $0.bracket < $1.bracket }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            BracketSectionHeader(title: "Vibe Check", icon: "hand.thumbsup")
            
            if sortedStats.isEmpty {
                Text("No vibe check data yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(sortedStats, id: \.bracket) { stat in
                        HStack(spacing: 8) {
                            Text("B\(stat.bracket)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(bracketColor(stat.bracket))
                                .frame(width: 26, alignment: .leading)
                            
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(bracketColor(stat.bracket).opacity(0.12))
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(bracketColor(stat.bracket).gradient)
                                        .frame(width: max(
                                            geo.size.width * stat.sameBracketRate, 3
                                        ))
                                }
                            }
                            .frame(height: 14)
                            
                            Text(String(format: "%.1f%%", stat.sameBracketRate * 100))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                                .frame(minWidth: 44, alignment: .trailing)
                        }
                    }
                }
                
                Text("Opponent agreement with self-declared bracket")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
*/

// ═══════════════════════════════════════════════════════════════════
// MARK: - Bracket Stat Row (compact)
// ═══════════════════════════════════════════════════════════════════

@MainActor
struct BracketStatRowCompact: View {
    let bracket: BracketStatistics
    let totalPlayed: Int
    let onTap: () -> Void
    
    private var playRate: Double {
        totalPlayed > 0 ? 100.0 * Double(bracket.games) / Double(totalPlayed) : 0
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 12) {
                // Bracket badge
                ZStack {
                    Circle()
                        .fill(bracketColor(bracket.bracket).gradient.opacity(0.2))
                        .frame(width: 50, height: 50)
                    Text("\(bracket.bracket)")
                        .font(.title2).bold()
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(BracketSystem(rawValue: bracket.bracket)?.displayName ?? "Unknown")
                        .font(.body)
                        .foregroundStyle(bracketColor(bracket.bracket))
                    Text("\(bracket.decks) deck ratings  ·  \(bracket.games) games")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 14) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%.1f%%", playRate))
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundColor(.orange)
                        Text("Play")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%.1f%%", bracket.sameBracketRate * 100))
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundColor(.purple)
                        Text("Agree")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}


// ═══════════════════════════════════════════════════════════════════
// MARK: - Bracket Detail Sheet
// ═══════════════════════════════════════════════════════════════════

@MainActor
struct BracketDetailSheet: View {
    @StateObject private var dataManager = GameDataManager.shared
    @Environment(\.dismiss) var dismiss
    
    let bracketNumber: Int
    
    // MARK: Derived
    private var bracket: BracketStatistics? {
        dataManager.bracketStats[bracketNumber]
    }
    
    private var totalGames: Int {
        dataManager.bracketStats.values.map(\.games).reduce(0, +)
    }
    
    /// Enriched game-level metrics computed on demand.
    private var metrics: BracketGameMetrics {
        BracketGameMetrics.compute(
            for: bracketNumber,
            from: dataManager.finalStates
        )
    }
    
    private var maxSeatDeviation: Double {
        let devs: [Double] = (0..<4).compactMap { pos in
            guard let seat = metrics.seatOrder.seats[pos],
                  seat.games > 0 else { return nil }
            return abs(Double(seat.wins) / Double(seat.games) - 0.25)
        }
        return max(devs.max() ?? 0.25, 0.10)
    }
    
    private let sidePad: CGFloat = 16
    
    // MARK: Body
    var body: some View {
        NavigationView {
            ScrollView {
                if let bracket {
                    VStack(alignment: .leading, spacing: 20) {
                        headerSection(bracket)
                        overviewSection(bracket)
                        gameMetricsSection
                        vibeCheckSection(bracket)
                        seatOrderSection
                    }
                    .padding(.horizontal, sidePad)
                    .padding(.bottom, 40)
                } else {
                    Text("No data for Bracket \(bracketNumber)")
                        .foregroundStyle(.secondary)
                        .padding(40)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Bracket \(bracketNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(bracketColor(bracketNumber))
                }
            }
        }
    }
    
    
    // ─────────────────────────────────────────────
    // MARK: 1 · Header
    // ─────────────────────────────────────────────
    
    private func headerSection(_ b: BracketStatistics) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                BracketOverviewCell(
                    value: "\(b.games)", label: "Games",
                    color: bracketColor(bracketNumber))
                bSmallDivider
                BracketOverviewCell(
                    value: "\(b.decks)", label: "Decks Rated",
                    color: .primary)
                bSmallDivider
                let pr = totalGames > 0
                ? 100.0 * Double(b.games) / Double(totalGames) : 0
                BracketOverviewCell(
                    value: String(format: "%.1f%%", pr), label: "Play Rate",
                    color: .orange)
                bSmallDivider
                BracketOverviewCell(
                    value: String(format: "%.1f%%", b.sameBracketRate * 100),
                    label: "Agreement",
                    color: .purple)
            }
            .padding(.vertical, 14)
            
            Divider()
            
            HStack {
                Text(BracketSystem(rawValue: bracketNumber)?.displayName ?? "")
                    .font(.subheadline).fontWeight(.medium)
                    .foregroundStyle(bracketColor(bracketNumber))
                Spacer()
                Text("\(b.totalrated) opponent ratings")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var bSmallDivider: some View { Divider().frame(height: 32) }
    
    
    // ─────────────────────────────────────────────
    // MARK: 2 · Overview Metrics
    // ─────────────────────────────────────────────
    
    private func overviewSection(_ b: BracketStatistics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            BracketSectionHeader(title: "Overview",
                                 icon: "chart.bar.xaxis")
            
            VStack(spacing: 8) {
                let pr = totalGames > 0
                ? 100.0 * Double(b.games) / Double(totalGames) : 0
                MetricRow(label: "Games Played",
                          value: "\(b.games)",
                          detail: String(format: "%.1f%% of all games", pr))
                
                MetricRow(label: "Decks Rated",
                          value: "\(b.decks)",
                          detail: nil)
                
                MetricRow(label: "Bracket Agreement",
                          value: String(format: "%.1f%%", b.sameBracketRate * 100),
                          detail: "\(b.totalrated) ratings")
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    
    // ─────────────────────────────────────────────
    // MARK: 3 · Game Metrics (duration / rounds)
    // ─────────────────────────────────────────────
    
    private var gameMetricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            BracketSectionHeader(title: "Game Metrics",
                                 icon: "clock")
            
            VStack(spacing: 8) {
                MetricRow(label: "Avg Game Duration",
                          value: timeFormatDuration(metrics.avgDuration),
                          detail: "± \(timeFormatDuration(metrics.stdDuration))")
                
                MetricRow(label: "Avg Rounds per Game",
                          value: String(format: "%.1f", metrics.avgRounds),
                          detail: "± \(String(format: "%.1f", metrics.stdRounds))")
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    
    // ─────────────────────────────────────────────
    // MARK: 4 · Vibe Check Breakdown
    // ─────────────────────────────────────────────
    
    private func vibeCheckSection(_ b: BracketStatistics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            BracketSectionHeader(title: "Vibe Check Breakdown",
                                 icon: "hand.thumbsup")
            
            if b.vibeCheck.isEmpty {
                Text("No vibe check data available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
            } else {
                VStack(spacing: 8) {
                    // Bar chart
                    Chart {
                        ForEach(
                            b.vibeCheck.sorted(by: { $0.key < $1.key }),
                            id: \.key
                        ) { ratedBracket, count in
                            BarMark(
                                x: .value("Rating", "B\(ratedBracket)"),
                                y: .value("Count", count)
                            )
                            .foregroundStyle(
                                bracketColor(ratedBracket).gradient
                            )
                            .opacity(ratedBracket == b.bracket ? 1.0 : 0.30)
                            .cornerRadius(4)
                        }
                    }
                    .chartYAxisLabel {
                        Text("Ratings").font(.caption2).fontWeight(.bold)
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisGridLine(stroke: StrokeStyle(
                                lineWidth: 0.3, dash: [4, 4]))
                            AxisValueLabel()
                        }
                    }
                    .chartLegend(.hidden)
                    .frame(height: 180)
                    
                    // Legend hint
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(bracketColor(b.bracket))
                            .frame(width: 10, height: 10)
                        Text("Self-declared bracket (agreement)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    
                    // Numeric breakdown
                    let total = max(b.vibeCheck.values.reduce(0, +), 1)
                    ForEach(
                        b.vibeCheck.sorted(by: { $0.key < $1.key }),
                        id: \.key
                    ) { rated, count in
                        HStack {
                            Circle()
                                .fill(bracketColor(rated))
                                .frame(width: 8, height: 8)
                            Text("Rated B\(rated)")
                                .font(.caption)
                                .foregroundStyle(
                                    rated == b.bracket
                                    ? Color.primary : .secondary)
                            Spacer()
                            Text("\(count)")
                                .font(.caption).fontWeight(.semibold)
                            Text(String(format: "(%.1f%%)",
                                        100.0 * Double(count) / Double(total)))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(minWidth: 48, alignment: .trailing)
                        }
                    }
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
    }
    
    
    // ─────────────────────────────────────────────
    // MARK: 5 · Seat Order within Bracket
    // ─────────────────────────────────────────────
    
    private var seatOrderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            BracketSectionHeader(title: "Turn Order in Bracket",
                                 icon: "arrow.triangle.turn.up.right.diamond")
            
            let hasSeatData = (0..<4).contains {
                (metrics.seatOrder.seats[$0]?.games ?? 0) > 0
            }
            
            if hasSeatData {
                VStack(spacing: 10) {
                    // Legend
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Rectangle()
                                .fill(Color.primary.opacity(0.35))
                                .frame(width: 12, height: 1.5)
                            Text("0% (25% expected)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        HStack(spacing: 2) {
                            Text("W").font(.caption2).fontWeight(.semibold)
                            Text("Wins").font(.caption2).foregroundStyle(.secondary)
                            Text("·").font(.caption2).foregroundStyle(.secondary)
                            Text("G").font(.caption2).fontWeight(.semibold)
                            Text("Games").font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    
                    let labels = ["1st", "2nd", "3rd", "4th"]
                    ForEach(0..<4, id: \.self) { pos in
                        let seat  = metrics.seatOrder.seats[pos]
                        let g     = seat?.games ?? 0
                        let w     = seat?.wins  ?? 0
                        let rate  = g > 0 ? Double(w) / Double(g) : 0
                        let dev   = g > 0 ? rate - 0.25 : 0
                        
                        BracketDeviationRow(
                            label: labels[pos],
                            games: g, wins: w,
                            deviation: dev,
                            maxDeviation: maxSeatDeviation,
                            color: ColorPalettes.watermelonSorbet(pos + 1)
                        )
                    }
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            } else {
                Text("Not enough seat data for this bracket")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
            }
        }
    }
}


// ═══════════════════════════════════════════════════════════════════
// MARK: - Bracket Game Metrics (enriched stats from FinalPod)
// ═══════════════════════════════════════════════════════════════════

struct BracketGameMetrics {
    let gameDurations: [Double]
    let gameRounds: [Double]
    let seatOrder: SeatOrder
    
    var avgDuration: Double { gameDurations.isEmpty ? 0 : gameDurations.mean }
    var stdDuration: Double { gameDurations.isEmpty ? 0 : gameDurations.standardDeviation }
    var avgRounds: Double   { gameRounds.isEmpty ? 0 : gameRounds.mean }
    var stdRounds: Double   { gameRounds.isEmpty ? 0 : gameRounds.standardDeviation }
    
    /// Compute enriched metrics for a given bracket from raw game data.
    static func compute(for bracketNumber: Int,
                        from finalStates: [FinalPod]) -> BracketGameMetrics {
        let bracketGames = finalStates.filter { pod in
            pod.commanders.contains { $0.winner && $0.bracketRating == bracketNumber }
        }
        
        let durations = bracketGames.map { $0.duration }
        let rounds    = bracketGames.map { Double($0.totalRounds) }
        
        var seats = SeatOrder()
        for game in bracketGames {
            for commander in game.commanders {
                seats.add(turnOrder: commander.turnOrder, win: commander.winner)
            }
        }
        
        return BracketGameMetrics(
            gameDurations: durations,
            gameRounds: rounds,
            seatOrder: seats
        )
    }
}


// ═══════════════════════════════════════════════════════════════════
// MARK: - Bracket Sub-Components (private)
// ═══════════════════════════════════════════════════════════════════

// MARK: Section header

private struct BracketSectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        Label {
            Text(title).font(.headline).foregroundStyle(.primary)
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(Color.orange.gradient)
        }
    }
}

// MARK: Overview cell (header row)

private struct BracketOverviewCell: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.callout).fontWeight(.bold)
                .foregroundStyle(color)
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: Deviation row (reused for seat order within bracket)

private struct BracketDeviationRow: View {
    let label: String
    let games: Int
    let wins: Int
    let deviation: Double
    let maxDeviation: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.subheadline).fontWeight(.bold)
                .foregroundStyle(color)
                .frame(width: 28, alignment: .leading)
            
            GeometryReader { geo in
                let half  = geo.size.width / 2
                let scale = maxDeviation > 0 ? (half - 4) / maxDeviation : 0
                let barW  = abs(deviation) * scale
                
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.06))
                    
                    if games > 0 && deviation != 0 {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(deviation > 0
                                  ? color.gradient
                                  : color.opacity(0.40).gradient)
                            .frame(width: max(barW, 3), height: 18)
                            .offset(x: deviation > 0
                                    ?  barW / 2
                                    : -barW / 2)
                    }
                    
                    Rectangle()
                        .fill(Color.primary.opacity(0.35))
                        .frame(width: 1.5)
                }
            }
            .frame(height: 22)
            
            VStack(alignment: .trailing, spacing: 0) {
                Text(games > 0
                     ? String(format: "%+.1f%%", deviation * 100)
                     : "—")
                .font(.subheadline).fontWeight(.bold)
                .foregroundStyle(color)
                Text("\(wins)W · \(games)G")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            .frame(minWidth: 70, alignment: .trailing)
        }
    }
}


// ═══════════════════════════════════════════════════════════════════
// MARK: - Preview
// ═══════════════════════════════════════════════════════════════════

#Preview { BracketStatsListView() }
