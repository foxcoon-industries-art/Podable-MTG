import SwiftUI
import Charts
import Podwork


// ═══════════════════════════════════════════════════════════════════
// MARK: - Commander Stats List View
// ═══════════════════════════════════════════════════════════════════

struct CommanderStatsListView: View {
    @StateObject private var dataManager = GameDataManager.shared
    @EnvironmentObject var appInfo: App_Info
    
    @State private var searchText: String = ""
    @State private var selectedCommander: String? = nil
    @State private var showDetailSheet: Bool = false
    @State private var showHidden: Bool = false
    
    private let sidePad: CGFloat = 8
    
    var body: some View {
        VStack(spacing: 0) {
            if filteredCommanders.isEmpty {
                emptyStateView
            } else {
                commanderList
            }
        }
        .sheet(item: $selectedCommander) { cmdrName in
            if let stats = dataManager.commanderStats[cmdrName] {
                CommanderDetailSheet(commander: cmdrName, stats: stats)
            }
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search...", text: $searchText)
                    .textFieldStyle(.plain)
                    .disableAutocorrection(true)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .font(.callout)
            .padding(8)
            .background(Color(.quaternarySystemFill))
            .cornerRadius(10)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Commander List
    private var commanderList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                let pinned = filteredCommanders.filter { isPinned($0.0) }
                let unpinned = filteredCommanders.filter { !isPinned($0.0) }
                
                if !pinned.isEmpty {
                    Section {
                        ForEach(pinned, id: \.0) { commander, stats in
                            CommanderStatRow(
                                commander: commander,
                                stats: stats,
                                totalGames: dataManager.podSummaryStats.totalGames,
                                isPinned: isPinned(commander),
                                isHidden: isHidden(commander),
                                canPin: canPin,
                                onTap: { selectedCommander = commander; showDetailSheet = true },
                                onPin: { togglePin(commander) },
                                onHide: { toggleHide(commander) }
                            )
                            .frame(maxWidth: .infinity)
                        }
                    } header: {
                        HStack {
                            Image(systemName: "pin.fill")
                                .foregroundStyle(Color.orange)
                            Text("")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.secondary)
                            
                            searchBar
                            
                            Image(systemName: showHidden ? "eye.fill" : "eye.slash")
                                .font(.callout)
                                .foregroundStyle(showHidden ? Color.orange : Color.secondary)
                                .onTapGesture {
                                    withAnimation { showHidden.toggle() }
                                }
                        }
                        .padding(.horizontal, sidePad * 2)
                        .padding(.top, 8)
                    }
                }
                
                Section {
                    ForEach(unpinned, id: \.0) { commander, stats in
                        CommanderStatRow(
                            commander: commander,
                            stats: stats,
                            totalGames: dataManager.podSummaryStats.totalGames,
                            isPinned: isPinned(commander),
                            isHidden: isHidden(commander),
                            canPin: canPin,
                            onTap: { selectedCommander = commander; showDetailSheet = true },
                            onPin: { togglePin(commander) },
                            onHide: { toggleHide(commander) }
                        )
                        .frame(maxWidth: .infinity)
                    }
                } header: {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundStyle(Color.orange)
                        Text("")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, sidePad * 2)
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal, 0)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(Color.orange.gradient.opacity(0.5))
            
            Text("No Commanders Found")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(searchText.isEmpty
                 ? "Play some games to see commander statistics!"
                 : "Try a different search term")
            .font(.body)
            .foregroundStyle(Color.secondary)
            .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Filtered & Sorted Commanders
    private var filteredCommanders: [(String, CommanderSummary)] {
        dataManager.commanderStats
            .sorted { $0.value.games > $1.value.games }
            .sorted { $0.value.wins > $1.value.wins }
            .filter { commander, _ in
                let matchesSearch = searchText.isEmpty ||
                commander.localizedCaseInsensitiveContains(searchText)
                let shouldShow = showHidden || !isHidden(commander)
                return matchesSearch && shouldShow
            }
    }
    
    // MARK: - Pin / Hide Helpers
    private func isPinned(_ commander: String) -> Bool {
        appInfo.userInfo.pinnedCommanderNames.map(\.name).contains(commander)
    }
    private func canPin() -> Bool { !appInfo.hasMaxCommanderPins() }
    private func isHidden(_ commander: String) -> Bool {
        appInfo.userInfo.hiddenCommanderNames.map(\.name).contains(commander)
    }
    private func togglePin(_ commander: String) {
        HapticFeedback.impact()
        isPinned(commander) ? appInfo.unpinCommander(commander) : appInfo.pinCommander(commander)
    }
    private func toggleHide(_ commander: String) {
        HapticFeedback.impact()
        isHidden(commander) ? appInfo.unhideCommander(commander) : appInfo.hideCommander(commander)
    }
}


// ═══════════════════════════════════════════════════════════════════
// MARK: - Commander Stat Row
// ═══════════════════════════════════════════════════════════════════

@MainActor
struct CommanderStatRow: View {
    let commander: String
    let stats: CommanderSummary
    let totalGames: Int
    @State var isPinned: Bool
    var isHidden: Bool
    let canPin: () -> Bool
    let onTap: () -> Void
    let onPin: () -> Void
    let onHide: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    private var playRate: Double {
        totalGames > 0 ? 100.0 * Double(stats.games) / Double(totalGames) : 0
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .bottom, spacing: 8) {
                HStack(alignment: .lastTextBaseline, spacing: 0) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(commander)
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(isHidden
                                             ? Color.orange.gradient.opacity(0.5)
                                             : Color.orange.gradient.opacity(1))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        
                        Text("\(stats.games) games")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    }
                    Spacer(minLength: .zero)
                }
                .frame(maxWidth: .infinity)
                
                HStack(spacing: 8) {
                    StatPill(value: String(format: "%.0f%%", stats.winPercentage),
                             label: "Win",
                             color: winRateColor(stats.winPercentage))
                    
                    StatPill(value: String(format: "%.0f%%", playRate),
                             label: "Play",
                             color: Color.teal)
                }
                
                HStack(spacing: 4) {
                    Button(action: {
                        withAnimation {
                            let wasPinned = isPinned
                            if canPin() || wasPinned {
                                isPinned.toggle()
                                onPin()
                            }
                        }
                    }) {
                        Image(systemName: isPinned ? "pin.fill" : "pin")
                            .font(.caption)
                            .foregroundStyle(isPinned ? Color.orange : Color.secondary)
                            .rotationEffect(isPinned ? .degrees(45) : .degrees(0))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { withAnimation { onHide() } }) {
                        Image(systemName: isHidden ? "eye.slash.fill" : "eye.slash")
                            .font(.caption)
                            .foregroundStyle(isHidden ? Color.red : Color.secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
            .padding(PodableTheme.spacingS)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
            .opacity(isHidden ? 0.6 : 1.0)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}


// ═══════════════════════════════════════════════════════════════════
// MARK: - Shared Helpers
// ═══════════════════════════════════════════════════════════════════

func winRateColor(_ rate: Double) -> Color {
    switch rate {
    case 30...: return .green
    case 20..<30: return .orange
    default: return .red
    }
}

struct StatPill: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.secondary)
        }
        .frame(minWidth: 45)
    }
}

struct MetricRow: View {
    let label: String
    let value: String
    let detail: String?
    
    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.primary)
                
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(Color.orange)
                }
            }
        }
    }
}


// ═══════════════════════════════════════════════════════════════════
// MARK: - Commander Detail Sheet  (Redesigned)
// ═══════════════════════════════════════════════════════════════════

struct CommanderDetailSheet: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var dataManager = GameDataManager.shared
    
    let commander: String
    let stats: CommanderSummary
    
    private let sidePad: CGFloat = 16
    
    // MARK: Derived values
    private var playRate: Double {
        let total = dataManager.podSummaryStats.totalGames
        return total > 0 ? 100.0 * Double(stats.games) / Double(total) : 0
    }
    
    /// Best-effort lookup of the most recent game featuring this commander.
    private var lastPlayedDate: Date? {
        dataManager.finalStates
            .filter { pod in
                pod.commanders.contains { commander.contains($0.name) }
            }
            .map(\.date)
            .max()
    }
    
    /// Largest |winRate − 0.25| across all four seats (floor 0.10 so bars are never invisible).
    private var turnOrderMaxDeviation: Double {
        let deviations: [Double] = (0..<4).compactMap { position in
            guard let seat = stats.seatOrder.seats[position],
                  seat.games > 0 else { return nil }
            let rate = Double(seat.wins) / Double(seat.games)
            return abs(rate - 0.25)
        }
        return max(deviations.max() ?? 0.25, 0.10)
    }
    
    // MARK: Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    overviewSection          // 1
                    performanceSection       // 2
                    survivalSection          // 3
                    bracketSection           // 4
                    turnDurationSection      // 5
                    castingSection           // 6
                    damageSection            // 7
                    turnOrderSection         // 8
                }
                .padding(.horizontal, sidePad)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(commander)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.orange)
                }
            }
        }
    }
    
    
    // ─────────────────────────────────────────────
    // MARK: 1 · Overview
    // ─────────────────────────────────────────────
    
    private var overviewSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                OverviewStatCell(value: "\(stats.games)",
                                 label: "Games",  color: .blue)
                smallDivider
                OverviewStatCell(value: "\(stats.wins)",
                                 label: "Wins",   color: .green)
                smallDivider
                OverviewStatCell(value: "\(stats.games - stats.wins)",
                                 label: "Losses", color: .red)
                smallDivider
                OverviewStatCell(value: String(format: "%.1f%%", stats.winPercentage),
                                 label: "Win Rate",
                                 color: winRateColor(stats.winPercentage))
                smallDivider
                OverviewStatCell(value: String(format: "%.1f%%", playRate),
                                 label: "Play Rate", color: .teal)
            }
            .padding(.vertical, 14)
            
            Divider()
            
            HStack {
                if let date = lastPlayedDate {
                    Label {
                        Text("Last played \(date, style: .relative) ago")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if stats.mostFrequentBracket > 0 {
                    Text("Bracket \(stats.mostFrequentBracket)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(bracketColor(stats.mostFrequentBracket))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(bracketColor(stats.mostFrequentBracket).opacity(0.15))
                        .cornerRadius(4)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var smallDivider: some View {
        Divider().frame(height: 32)
    }
    
    
    // ─────────────────────────────────────────────
    // MARK: 2 · Performance
    // ─────────────────────────────────────────────
    
    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            StatsSectionHeader(title: "Performance",
                               icon: "chart.line.uptrend.xyaxis")
            
            VStack(spacing: 8) {
                MetricRow(label: "Avg Game Duration",
                          value: timeFormatDuration(stats.avgPodDuration),
                          detail: "± \(timeFormatDuration(stats.timePerGameStdDev))")
                
                MetricRow(label: "Avg Turn Duration",
                          value: timeFormatDuration(stats.avgTurnDuration),
                          detail: "± \(timeFormatDuration(stats.stdTurnDuration))")
                
                MetricRow(label: "Avg Rounds per Game",
                          value: String(format: "%.1f", stats.avgGameLength),
                          detail: "rounds")
                
                MetricRow(label: "Avg Turns Taken",
                          value: String(format: "%.1f", stats.avgTurnsTaken),
                          detail: "± \(String(format: "%.1f", stats.stdTurnsTaken))")
                
                MetricRow(label: "Avg Playtime Share",
                          value: String(format: "%.1f%%", stats.avgPodPlaytimeRatio * 100),
                          detail: "± \(String(format: "%.1f%%", stats.stdPodPlaytimeRatio * 100))")
                
                if stats.wins > 0 {
                    MetricRow(label: "Avg Time to Win",
                              value: timeFormatDuration(stats.avgTimeToWin),
                              detail: "± \(timeFormatDuration(stats.stdTimeToWin))")
                }
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    
    // ─────────────────────────────────────────────
    // MARK: 3 · Survival & Elimination
    // ─────────────────────────────────────────────
    
    private var survivalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            StatsSectionHeader(title: "Survival & Elimination",
                               icon: "shield.lefthalf.filled")
            
            VStack(spacing: 12) {
                // Top-level survival summary
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(format: "%.1f%%", stats.survivalRate * 100))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(stats.survivalRate >= 0.5
                                             ? Color.green : Color.orange)
                        Text("Survival Rate")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(stats.games - stats.timesEliminated) / \(stats.games)")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("games survived")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if stats.avgEliminationRound > 0 {
                    MetricRow(label: "Avg Elimination Round",
                              value: String(format: "%.1f", stats.avgEliminationRound),
                              detail: "± \(String(format: "%.1f", stats.stdEliminationRound))")
                }
                
                MetricRow(label: "Concession Rate",
                          value: String(format: "%.1f%%", stats.concessionRate * 100),
                          detail: "\(stats.eliminationMethods[.concede] ?? 0) times")
                
                // Elimination method breakdown (already sorted descending in computed property)
                let elimEntries = stats.eliminationBreakdown
                if !elimEntries.isEmpty {
                    Divider()
                    
                    Text("Eliminated By")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    ForEach(elimEntries) { entry in
                        EliminationMethodRow(entry: entry)
                    }
                }
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    
    // ─────────────────────────────────────────────
    // MARK: 4 · Bracket Distribution
    // ─────────────────────────────────────────────
    
    @ViewBuilder
    private var bracketSection: some View {
        let entries = stats.bracketDistributionEntries
        if !entries.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                StatsSectionHeader(title: "Bracket Distribution",
                                   icon: "square.stack.3d.up")
                
                BracketDistributionBar(entries: entries)
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
            }
        }
    }
    
    
    // ─────────────────────────────────────────────
    // MARK: 5 · Turn Duration Analysis
    // ─────────────────────────────────────────────
    
    private var turnDurationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            StatsSectionHeader(title: "Turn Duration Analysis",
                               icon: "clock.arrow.circlepath")
            
            if stats.avgDurationPerTurn.isEmpty {
                Text("No turn data available")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
            } else {
                TurnDurationChartV2(
                    avgDurations: stats.avgDurationPerTurn,
                    stdDurations: stats.stdDevTimePerTurn
                )
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
    }
    
    
    // ─────────────────────────────────────────────
    // MARK: 6 · The Tax & The Ring
    // ─────────────────────────────────────────────
    
    private var castingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            StatsSectionHeader(title: "The Tax & The Ring",
                               icon: "scroll")
            
            VStack(spacing: 8) {
                // ── Commander Tax (the honest dues) ──
                HStack(spacing: 6) {
                    Image(systemName: "building.columns")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text("Commander Tax")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                
                MetricRow(label: "Total Tax Paid",
                          value: "\(stats.totalTax)",
                          detail: nil)
                
                // NOTE: std dev requires a taxPerGame: [Double] array
                // on CommanderSummary (not yet tracked). Shows mean only for now.
                MetricRow(label: "Avg Tax per Game",
                          value: String(format: "%.1f", stats.avgTax),
                          detail: "± \(String(format: "%.1f", stats.stdTaxPerGame))")
                
                Divider().padding(.vertical, 4)
                
                // ── Sol Rings (the stacked hand) ──
                HStack(spacing: 6) {
                    Image(systemName: "diamond")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                    Text("Sol Rings")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                
                MetricRow(label: "Sol Rings Played",
                          value: "\(stats.totalSolRings)",
                          detail: String(format: "%.1f%% of games", stats.solRingRate))
                
                MetricRow(label: "Turn 1 Sol Rings",
                          value: "\(stats.totalTurnOneSolRings)",
                          detail: String(format: "%.1f%% of games", stats.turnOneSolRingRate))
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    
    // ─────────────────────────────────────────────
    // MARK: 7 · Commander Damage
    // ─────────────────────────────────────────────
    
    private var damageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            StatsSectionHeader(title: "Commander Damage",
                               icon: "bolt.fill")
            
            VStack(spacing: 8) {
                MetricRow(label: "Total Commander Damage",
                          value: "\(stats.totalCommanderDamage)",
                          detail: nil)
                
                MetricRow(label: "Avg Damage per Game",
                          value: String(format: "%.1f", stats.avgCommanderDamagePerGame),
                          detail: "± \(String(format: "%.1f", stats.damagePerGameStdDev))")
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    
    // ─────────────────────────────────────────────
    // MARK: 8 · Turn Order Performance (deviation)
    // ─────────────────────────────────────────────
    
    private var turnOrderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            StatsSectionHeader(title: "Turn Order Performance",
                               icon: "arrow.triangle.turn.up.right.diamond")
            
            VStack(spacing: 10) {
                // Legend row
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
                       
                        
                        Text("Wins")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("·")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    
                        Text("Games")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                    }
                }
                
                let labels = ["1st", "2nd", "3rd", "4th"]
                
                ForEach(0..<4, id: \.self) { position in
                    let seat  = stats.seatOrder.seats[position]
                    let games = seat?.games ?? 0
                    let wins  = seat?.wins  ?? 0
                    let rate  = games > 0 ? Double(wins) / Double(games) : 0
                    let deviation = games > 0 ? rate - 0.25 : 0
                    
                    TurnOrderDeviationRow(
                        label: labels[position],
                        games: games,
                        wins: wins,
                        deviation: deviation,
                        maxDeviation: turnOrderMaxDeviation,
                        color: ColorPalettes.watermelonSorbet(position + 1)
                    )
                }
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
}


// ═══════════════════════════════════════════════════════════════════
// MARK: - Detail Sheet Sub-Components
// ═══════════════════════════════════════════════════════════════════

// MARK: Section Header

private struct StatsSectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        Label {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(Color.orange.gradient)
        }
    }
}

// MARK: Overview Stat Cell

private struct OverviewStatCell: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.callout)
                .fontWeight(.bold)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: Elimination Method Row

private struct EliminationMethodRow: View {
    let entry: EliminationEntry
    
    var body: some View {
        HStack(spacing: 8) {
            entry.method.displayEmoji
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            
            Text(entry.method.displayName)
                .font(.subheadline)
                .foregroundStyle(.primary)
            
            Spacer()
            
            Text("\(entry.count)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            Text(String(format: "(%.1f%%)", entry.percent))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(minWidth: 48, alignment: .trailing)
        }
    }
}

// MARK: Bracket Distribution Bar

private struct BracketDistributionBar: View {
    let entries: [BracketEntry]
    
    private var maxCount: Int { entries.map(\.count).max() ?? 1 }
    
    var body: some View {
        VStack(spacing: 10) {
            ForEach(entries) { entry in
                HStack(spacing: 10) {
                    Text("B\(entry.bracket)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(bracketColor(entry.bracket))
                        .frame(width: 30, alignment: .leading)
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(bracketColor(entry.bracket).opacity(0.12))
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(bracketColor(entry.bracket).gradient)
                                .frame(width: barWidth(for: entry.count,
                                                       in: geo.size.width))
                        }
                    }
                    .frame(height: 22)
                    
                    Text("\(entry.count)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(minWidth: 24, alignment: .trailing)
                    
                    Text(String(format: "(%.1f%%)", entry.percent))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 48, alignment: .trailing)
                }
            }
        }
    }
    
    private func barWidth(for count: Int, in totalWidth: CGFloat) -> CGFloat {
        guard maxCount > 0 else { return 0 }
        return max(totalWidth * CGFloat(count) / CGFloat(maxCount), 4)
    }
}


// MARK: Turn Duration Chart V2

struct TurnDurationChartV2: View {
    let avgDurations: [Double]   // seconds
    let stdDurations: [Double]   // seconds
    
    /// Map a duration (seconds) to a warm→cool colour.
    /// Fast (low) → orange/red,  Slow (high) → blue/purple.
    private func barColor(for seconds: Double) -> Color {
        guard let lo = avgDurations.min(),
              let hi = avgDurations.max(),
              hi > lo else { return .orange }
        let t = (seconds - lo) / (hi - lo)                    // 0 = fastest, 1 = slowest
        return Color(hue: 0.06 + t * 0.64,                    // orange → purple
                     saturation: 0.72,
                     brightness: 0.84)
    }
    
    private let errorBarColor = Color(.systemGray)
    
    var body: some View {
        VStack(spacing: 8) {
            // ── Chart ──
            Chart {
                ForEach(Array(avgDurations.enumerated()), id: \.offset) { index, duration in
                    let turn   = "\(index + 1)"
                    let avgMin = duration / 60.0
                    let stdMin = index < stdDurations.count
                    ? stdDurations[index] / 60.0 : 0
                    
                    // Bar
                    BarMark(
                        x: .value("Turn", turn),
                        y: .value("Duration", avgMin)
                    )
                    .foregroundStyle(barColor(for: duration))
                    .cornerRadius(4)
                    
                    // ± 1 σ error bar
                    if stdMin > 0 {
                        RuleMark(
                            x: .value("Turn", turn),
                            yStart: .value("Low",  max(avgMin - stdMin, 0)),
                            yEnd:   .value("High", avgMin + stdMin)
                        )
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                        .foregroundStyle(errorBarColor.opacity(0.65))
                        
                        // Top cap
                        RuleMark(
                            x: .value("Turn", turn),
                            yStart: .value("CapHi", avgMin + stdMin - 0.001),
                            yEnd:   .value("CapHi", avgMin + stdMin + 0.001)
                        )
                        .lineStyle(StrokeStyle(lineWidth: 8, lineCap: .round))
                        .foregroundStyle(errorBarColor.opacity(0.50))
                        
                        // Bottom cap
                        RuleMark(
                            x: .value("Turn", turn),
                            yStart: .value("CapLo", max(avgMin - stdMin, 0) - 0.001),
                            yEnd:   .value("CapLo", max(avgMin - stdMin, 0) + 0.001)
                        )
                        .lineStyle(StrokeStyle(lineWidth: 8, lineCap: .round))
                        .foregroundStyle(errorBarColor.opacity(0.50))
                    }
                }
            }
            .background(.ultraThinMaterial)
            .chartXAxisLabel(position: .bottom, alignment: .center) {
                Text("Turn").font(.caption).fontWeight(.bold)
            }
            .chartYAxisLabel(position: .leading) {
                Text("Duration (min)").font(.caption).fontWeight(.bold).rotationEffect(.degrees(180))
            }
            .chartXAxis {
                AxisMarks(preset: .aligned) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.4))
                    AxisValueLabel(centered: true)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3, dash: [4, 4]))
                    AxisValueLabel()
                }
            }
            .chartLegend(.hidden)
            .frame(height: 200)
            
            // ── Manual Legend ──
            HStack(spacing: 14) {
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.orange)
                        .frame(width: 10, height: 10)
                    Text("Fast")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 7))
                        .foregroundStyle(.tertiary)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.purple)
                        .frame(width: 10, height: 10)
                    Text("Slow")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(errorBarColor.opacity(0.65))
                        .frame(width: 10, height: 2)
                    Text("± 1σ")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
        }
    }
}


// MARK: Turn Order Deviation Row

private struct TurnOrderDeviationRow: View {
    let label: String
    let games: Int
    let wins: Int
    let deviation: Double      // winRate − 0.25
    let maxDeviation: Double   // for scaling the bar width
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: 28, alignment: .leading)
            
            // Centered deviation bar
            GeometryReader { geo in
                let half  = geo.size.width / 2
                let scale = maxDeviation > 0 ? (half - 4) / maxDeviation : 0
                let barW  = abs(deviation) * scale
                
                ZStack {
                    // Track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.06))
                    
                    // Bar growing from centre
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
                    
                    // Centre-line (0 % deviation = 25 % expected)
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
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(color)
                
                Text("\(wins) · \(games)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(minWidth: 70, alignment: .trailing)
        }
    }
}


// ═══════════════════════════════════════════════════════════════════
// MARK: - Identifiable Wrappers (ForEach)
// ═══════════════════════════════════════════════════════════════════

public struct EliminationEntry: Identifiable {
    public var id: Int { method.rawValue }
    let method: EliminationMethod
    let count: Int
    let percent: Double
}

public struct BracketEntry: Identifiable {
    public var id: Int { bracket }
    let bracket: Int
    let count: Int
    let percent: Double
}


// ═══════════════════════════════════════════════════════════════════
// MARK: - CommanderSummary · New Computed Properties
// ═══════════════════════════════════════════════════════════════════
//
//  Move to EnhancedCommanderStats.swift (Podwork) when ready.
//

public extension CommanderSummary {
    
    // MARK: Turn counts
    
    /// Number of turns the commander took in each game.
    /// Derived from turnDurationsPerTurn (one inner array per game).
    var turnsPerGame: [Double] {
        turnDurationsPerTurn
            .filter { !$0.isEmpty }
            .map { Double($0.count) }
    }
    
    /// Average turns the commander took per game.
    var avgTurnsTaken: Double {
        turnsPerGame.isEmpty ? 0 : turnsPerGame.mean
    }
    
    /// Std dev of turns the commander took per game.
    var stdTurnsTaken: Double {
        turnsPerGame.isEmpty ? 0 : turnsPerGame.standardDeviation
    }
    
    // MARK: Playtime & win-time variability
    
    /// Standard deviation of the per-game playtime ratio.
    var stdPodPlaytimeRatio: Double {
        podPlaytimeRatio.standardDeviation
    }
    
    /// Standard deviation of time-to-win across won games.
    var stdTimeToWin: Double {
        timeToWin.isEmpty ? 0 : timeToWin.standardDeviation
    }
    
    // MARK: Elimination
    
    /// Std dev of the round at which this commander was eliminated.
    var stdEliminationRound: Double {
        eliminationRounds.isEmpty ? 0 : eliminationRounds.standardDeviation
    }
    
    /// Elimination methods sorted descending by count,
    /// excluding `.notEliminated`, `.emptySeat`, and methods with 0 occurrences.
    var eliminationBreakdown: [EliminationEntry] {
        let total = max(timesEliminated, 1)
        return eliminationMethods
            .filter { $0.key != .notEliminated && $0.key != .emptySeat && $0.value > 0 }
            .sorted { $0.value > $1.value }
            .map { EliminationEntry(method: $0.key,
                                    count:  $0.value,
                                    percent: 100.0 * Double($0.value) / Double(total)) }
    }
    
    // MARK: Sol Ring rates
    
    /// Percentage of games in which at least one Sol Ring was played.
    var solRingRate: Double {
        games > 0 ? 100.0 * Double(totalSolRings) / Double(games) : 0
    }
    
    /// Percentage of games with a turn-1 Sol Ring.
    var turnOneSolRingRate: Double {
        games > 0 ? 100.0 * Double(totalTurnOneSolRings) / Double(games) : 0
    }
    
    // MARK: Tax variability
    // TODO: To compute real std dev, add `taxPerGame: [Double]` to CommanderSummary
    //       during aggregation. For now returns 0.
    var stdTaxPerGame: Double {
        taxPerGame.isEmpty ? 0 : taxPerGame.standardDeviation
    }
    
    // MARK: Bracket distribution
    
    /// Bracket distribution as identifiable entries, excluding bracket 0.
    var bracketDistributionEntries: [BracketEntry] {
        var counts: [Int: Int] = [:]
        for b in brackets where b > 0 {
            counts[b, default: 0] += 1
        }
        let total = max(counts.values.reduce(0, +), 1)
        return counts
            .sorted { $0.key < $1.key }
            .map { BracketEntry(bracket: $0.key,
                                count:   $0.value,
                                percent: 100.0 * Double($0.value) / Double(total)) }
    }
}


// ═══════════════════════════════════════════════════════════════════
// MARK: - Preview
// ═══════════════════════════════════════════════════════════════════

#Preview {
    CommanderStatsListView()
        .environmentObject(App_Info(userInfo: User_Info(uniqueID: "preview", paidApp: true)))
}
