import SwiftUI
import Charts
import Podwork



private struct SheetItem<T>: Identifiable {
    let id: UUID
    let value: T
    init(_ value: T) where T: Hashable {
        self.id = UUID()
        self.value = value
    }
}



extension String: @retroactive Identifiable{
    public var id: String {self}
}

extension Int: @retroactive Identifiable{
   public var id: Int {self}
}
extension Bool: @retroactive Identifiable{
   public var id: Bool {self}
}

/*
// MARK: - FetchrCommanderList
/// Lists all commanders seen in pods. Supports search, pinning, and hiding.
/// Tapping a commander opens a detail sheet with plots and averages.
struct FetchrCommanderList: View {
    @StateObject private var dataManager = GameDataManager.shared
    @EnvironmentObject var appInfo: App_Info

    @State private var searchText = ""
    @State private var hiddenCommanders: Set<String> = []
    @State private var selectedCommander: String? = nil

    private let sidePad: CGFloat = 6

    var body: some View {
        VStack(spacing: 0) {

            // Search bar
            searchBar
                .padding(.horizontal, sidePad)
                .padding(.top, 4)
                .padding(.bottom, 6)

            // Commander rows
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 6) {
                    ForEach(filteredCommanders, id: \.0) { name, stats in
                        FetchrCommanderRow(
                            name: name,
                            summary: stats,
                            playRate: computePlayRate(stats),
                            isPinned: isPinned(name),
                            isHidden: hiddenCommanders.contains(name),
                            onTap: { selectedCommander = name },
                            onPin: { togglePin(name) },
                            onHide: { hiddenCommanders.insert(name) },
                            onUnhide: { hiddenCommanders.remove(name) }
                        )
                    }
                }
                .padding(.horizontal, sidePad)
                .padding(.bottom, 8)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius:12))
        // Commander detail sheet
        .sheet(item: $selectedCommander, onDismiss: { selectedCommander = nil }) { item in
            FetchrCommanderDetailSheet(commander: item)
        }
    }


    // MARK: - Search Bar
    @ViewBuilder
    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                //.font(.caption)
                .foregroundStyle(.secondary)
            TextField("Search commanders…", text: $searchText)
               // .font(.caption)
                .foregroundStyle(Color.primary)
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color(.secondarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }


    // MARK: - Filtered & Sorted Commanders
    private var visibleCommanders: [(String, CommanderSummary)] {
        let pinnedNames = appInfo.userInfo.pinnedCommanderNames.map { $0.name }

        return dataManager.commanderStats
            .filter { !hiddenCommanders.contains($0.key) }
            .filter { searchText.isEmpty || $0.key.lowercased().contains(searchText.lowercased()) }
            .sorted {
                let aIsPinned = pinnedNames.contains($0.key)
                let bIsPinned = pinnedNames.contains($1.key)
                if aIsPinned != bIsPinned { return aIsPinned }
                if $0.value.games != $1.value.games { return $0.value.games > $1.value.games }
                return $0.value.wins > $1.value.wins
            }
    }

    private func computePlayRate(_ summary: CommanderSummary) -> Double {
        let total = dataManager.podSummaryStats.totalGames
        guard total > 0 else { return 0 }
        return Double(summary.games) / Double(total)
    }

    private func isPinned(_ name: String) -> Bool {
        appInfo.userInfo.pinnedCommanderNames.contains { $0.name == name }
    }

    private func togglePin(_ name: String) {
        HapticFeedback.impact()
        if isPinned(name) { appInfo.unpinCommander(name) }
        else { appInfo.pinCommander(name) }
    }
    
    // MARK: - Filtered Commanders
    private var filteredCommanders: [(String, CommanderSummary)] {
        let pinnedNames = Set(appInfo.userInfo.pinnedCommanderNames.map { $0.name })
        let hiddenNames = Set(appInfo.userInfo.hiddenCommanderNames.map { $0.name })
        
        let allCommanders = dataManager.commanderStats
            .filter { !hiddenNames.contains($0.key) }
            .filter { commander in
                searchText.isEmpty || commander.key.localizedCaseInsensitiveContains(searchText)
            }
            .sorted { $0.key < $1.key }
            .sorted { $0.value.wins > $1.value.wins }
            .sorted { $0.value.games > $1.value.games }
        
        // Split into pinned and unpinned
        let pinned = allCommanders.filter { pinnedNames.contains($0.key) }
        let unpinned = allCommanders.filter { !pinnedNames.contains($0.key) }
        
        return pinned + unpinned
    }
}


// MARK: - FetchrCommanderRow
/// Single row in the commander list with metrics pills and pin/hide controls.
private struct FetchrCommanderRow: View {
    let name: String
    let summary: CommanderSummary
    let playRate: Double
    let isPinned: Bool
    let isHidden: Bool
    let onTap: () -> Void
    let onPin: () -> Void
    let onHide: () -> Void
    let onUnhide: () -> Void

    @State private var showHideConfirm = false

    var body: some View {
        HStack(spacing: 8) {
            // Tap area → opens detail sheet
            Button { onTap() } label: {
                VStack(alignment: .leading, spacing: 6) {
                    // Name + chevron
                    HStack {
                        Text(name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.orange.gradient)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    // Metric pills
                    HStack(spacing: 4) {
                        MetricPill(
                            title: "Games",
                            value: "\(summary.games)",
                            color: Color.teal
                        )
                        MetricPill(
                            title: "Win Rate",
                            value: String(format: "%.1f%%", summary.winPercentage),
                            color: winRateColor(summary.winPercentage)
                        )
                        MetricPill(
                            title: "Play Rate",
                            value: String(format: "%.1f%%", playRate * 100),
                            color: winRateColor(playRate * 100)
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Pin button
            Button { onPin() } label: {
                Image(systemName: isPinned ? "pin.fill" : "pin")
                    .font(.caption)
                    .foregroundStyle(isPinned ? Color.cyan : Color.secondary)
            }

            // Hide / unhide button
            if isHidden {
                Button { onUnhide() } label: {
                    Image(systemName: "eye")
                        .font(.caption)
                        .foregroundStyle(Color.green)
                }
            } else {
                Button { onHide() } label: {
                    Image(systemName: "eye.slash")
                        .font(.caption)
                        .foregroundStyle(Color.secondary.opacity(0.5))
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func winRateColor(_ rate: Double) -> Color {
        switch rate {
        case 25...: return .green
        case 6.25..<25: return .orange
        default: return .red
        }
    }
}


// MARK: - FetchrCommanderDetailSheet
/// Sheet shown when a commander is tapped — charts and detailed averages.
struct FetchrCommanderDetailSheet: View {
    let commander: String
    @StateObject private var dataManager = GameDataManager.shared
    @Environment(\.dismiss) var dismiss

    private var stats: CommanderSummary? {
        dataManager.commanderStats[commander]
    }

    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    if let stats = stats {
                       
                        //return
                        
                        
                        // Header stats row
                        commanderHeaderRow(stats)
                        
                        Divider()
                        
                        // Win Rate Progress Bar
                        winRateSection(stats)
                        
                        // Average Game Duration card
                        averageDurationSection(stats)
                        
                        // Average Damage per Game chart
                        damageHistoryChart(stats)
                        
                        // Turn Duration per Turn chart (repurposed from TurnAnalysisView)
                        turnDurationChart(stats)
                        
                        // Seat order / turn order breakdown
                        seatOrderSection(stats)
                    } else {
                        Text("No data available.")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    Spacer(minLength: 16)
                }
                .padding(.horizontal, 16)
            }
            .navigationTitle(commander)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationCompactAdaptation(horizontal: .popover, vertical: .sheet)
    }


    // ── Header row: games · wins · eliminations
    private func commanderHeaderRow(_ s: CommanderSummary) -> some View {
        HStack(spacing: 12) {
            StatPill(label: "Games", value: "\(s.games)", color: .teal)
            StatPill(label: "Wins", value: "\(s.wins)", color: .green)
            StatPill(label: "Eliminated", value: "\(s.timesEliminated)", color: .red)
        }
    }


    // ── Win Rate with progress bar
    private func winRateSection(_ s: CommanderSummary) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Win Rate")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text(String(format: "%.1f%%", s.winPercentage))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.green.gradient)
            }
            ProgressView(value: s.winPercentage / 100.0)
                .tint(Color.green)
                .progressViewStyle(LinearProgressViewStyle())
        }
        .padding(.vertical, 4)
    }


    // ── Average game duration ± std
    private func averageDurationSection(_ s: CommanderSummary) -> some View {
        HStack(spacing: 12) {
            StatPill(
                label: "Avg Game",
                value: timeFormatDuration(s.avgPodDuration),
                color: .teal
            )
            StatPill(
                label: "± Std Dev",
                value: timeFormatDuration(s.timePerGameStdDev),
                color: .orange
            )
            StatPill(
                label: "Avg Damage",
                value: String(format: "%.1f", s.avgCommanderDamagePerGame),
                color: .red
            )
        }
    }


    // ── Damage per game bar chart
    private func damageHistoryChart(_ s: CommanderSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Commander Damage Per Game")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.white.gradient)

            let chartData = s.damagePerGameHistory.enumerated().map {
                DamagePoint(game: $0.offset + 1, damage: Double($0.element))
            }
            let avgDamage = s.avgCommanderDamagePerGame

            Chart(chartData) { point in
                BarMark(
                    x: .value("Game", point.game),
                    y: .value("Damage", point.damage)
                )
                .foregroundStyle(Color.red.opacity(0.6))
                .cornerRadius(2)

                // Average rule line
                RuleMark(y: .value("Average", avgDamage))
                    .foregroundStyle(Color.orange)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [4]))
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                    if let v = value.as(Double.self) {
                        AxisValueLabel(String(format: "%.0f", v))
                        AxisGridLine()
                    }
                }
            }
            .chartXAxis {
                AxisMarks(position: .bottom, values: .automatic(desiredCount: min(chartData.count, 6))) { value in
                    if let v = value.as(Int.self) {
                        AxisValueLabel("G\(v)")
                    }
                }
            }
            .padding()
            .frame(height: 100)
            .padding(.horizontal, 4)
            .background(Color(.secondarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // Chart data model
    private struct DamagePoint: Identifiable {
        let id: Int
        let game: Int
        let damage: Double
        init(game: Int, damage: Double) {
            self.id = game
            self.game = game
            self.damage = damage
        }
    }


    // ── Turn duration per turn (repurposed from TurnAnalysisView)
    private func turnDurationChart(_ s: CommanderSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Average Duration Per Turn")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.white.gradient)

            let avgs = s.avgDurationPerTurn
            let stds = s.stdDevTimePerTurn
            guard !avgs.isEmpty else { return AnyView(EmptyView()) }

            let chartData = avgs.enumerated().map {
                TurnPoint(turn: $0.offset + 1, avg: $0.element,
                          std: $0.offset < stds.count ? (stds[$0.offset] ?? 0) : 0)
            }
            let maxY = chartData.map { $0.avg + $0.std }.max() ?? 60

            return AnyView(
                Chart(chartData) { point in
                    // Std dev band
                    AreaMark(
                        x: .value("Turn", point.turn),
                        yStart: .value("Low", max(0, point.avg - point.std)),
                        yEnd: .value("High", point.avg + point.std)
                    )
                    .foregroundStyle(Color.blue.opacity(0.15))

                    // Mean line
                    LineMark(
                        x: .value("Turn", point.turn),
                        y: .value("Avg", point.avg)
                    )
                    .foregroundStyle(Color.cyan.gradient)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))

                    PointMark(
                        x: .value("Turn", point.turn),
                        y: .value("Avg", point.avg)
                    )
                    .foregroundStyle(Color.white)
                    .symbolSize(30)
                }
                .chartYScale(domain: 0...max(maxY * 1.1, 60))
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                        if let sec = value.as(Double.self) {
                            let mins = Int(sec) / 60
                            let secs = Int(sec) % 60
                            if mins > 0 {
                                AxisValueLabel(String(format: "%dm%ds", mins, secs))
                            } else {
                                AxisValueLabel(String(format: "%ds", secs))
                            }
                            AxisGridLine()
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: min(chartData.count, 8))) { value in
                        if let v = value.as(Int.self) {
                            AxisValueLabel("T\(v)")
                        }
                    }
                }
                .frame(height: 130)
                .padding(.horizontal, 4)
                .background(Color(.secondarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            )
        }
    }

    private struct TurnPoint: Identifiable {
        let id: Int
        let turn: Int
        let avg: Double
        let std: Double
        init(turn: Int, avg: Double, std: Double) {
            self.id = turn
            self.turn = turn
            self.avg = avg
            self.std = std
        }
    }


    // ── Seat / turn order breakdown (donut)
    private func seatOrderSection(_ s: CommanderSummary) -> some View {
        let seats = s.seatOrder.turnOrderWinRates
        let turnNames = ["First", "Second", "Third", "Fourth"]

        return VStack(alignment: .leading, spacing: 8) {
            Text("Turn Order Performance")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.white.gradient)

            HStack(spacing: 12) {
                Chart(seats) { seat in
                    SectorMark(
                        angle: .value("Wins", max(seat.wins, seat.games > 0 ? 1 : 0)),
                        innerRadius: .ratio(0.55),
                        angularInset: 1.5
                    )
                    .foregroundStyle(ColorPalettes.watermelonSorbet(min(seat.seatID, 3) + 1).gradient)
                }
                .chartLegend(.hidden)
                .frame(width: 80, height: 80)

                VStack(alignment: .leading, spacing: 4) {
                    ForEach(seats) { seat in
                        let label = seat.seatID < turnNames.count ? turnNames[seat.seatID] : "Seat \(seat.seatID)"
                        let winRate = seat.games > 0 ? 100.0 * Double(seat.wins) / Double(seat.games) : 0
                        HStack(spacing: 6) {
                            Circle()
                                .fill(ColorPalettes.watermelonSorbet(min(seat.seatID, 3) + 1))
                                .frame(width: 8, height: 8)
                            Text(label)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(String(format: "%.0f%%", winRate))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(ColorPalettes.watermelonSorbet(min(seat.seatID, 3) + 1))
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}


// MARK: - StatPill (small summary pill for detail headers)
private struct StatPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(color.gradient)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}


#Preview {
    FetchrCommanderList()
        .preferredColorScheme(.dark)
}
*/
