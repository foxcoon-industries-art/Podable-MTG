import SwiftUI
import Charts
import Podwork


// ═══════════════════════════════════════════════════════════════════
// MARK: - Turn Order Stats Panel
// ═══════════════════════════════════════════════════════════════════

struct TurnOrderStatsPanel: View {
    @StateObject private var dataManager = GameDataManager.shared
    @State private var selectedSeat: Int? = nil
    
    // ── Derived ─────────────────────────────────────────
    private var seats: [SeatOrder.Seat] {
        dataManager.seatOrderStats.turnOrderWinRates
            .sorted { $0.seatID < $1.seatID }
    }
    
    private var totalGames: Int {
        // Each game contributes 4 seat entries (one per player).
        // Unique games = total seat-games / 4, but for display
        // purposes the sum of games across seats (all equal) works.
        // Using dataManager's count is safest:
        dataManager.podSummaryStats.totalGames
    }
    
    private var maxDeviation: Double {
        let devs: [Double] = seats.compactMap { seat in
            guard seat.games > 0 else { return nil }
            return abs(Double(seat.wins) / Double(seat.games) - 0.25)
        }
        return max(devs.max() ?? 0.25, 0.10)
    }
    
    private let turnNames = [
        "First Player", "Second Player", "Third Player", "Final Player"
    ]
    private let shortNames = ["1st", "2nd", "3rd", "4th"]
    
    // ── Body ────────────────────────────────────────────
    var body: some View {
        VStack(spacing: 16) {
            if totalGames == 0 {
                turnOrderEmptyState
            } else {
                deviationSection
            }
        }
        .sheet(item: $selectedSeat) { seatID in
            let seat = dataManager.seatOrderStats.seats[seatID]
            ?? SeatOrder.Seat(seatID: seatID)
            TurnOrderDetailSheet(
                position: seatID,
                seat: seat,
                allSeats: seats,
                totalGames: totalGames
            )
        }
    }
    
    // ── Empty ───────────────────────────────────────────
    private var turnOrderEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "metronome")
                .font(.system(size: 36))
                .foregroundStyle(Color.blue.opacity(0.4))
            Text("No Turn Order Data Yet")
                .font(.subheadline).foregroundStyle(.secondary)
            Text("Play some games to see turn order analysis here.")
                .font(.caption)
                .foregroundStyle(Color.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
    
    // ── Deviation bars ──────────────────────────────────
    private var deviationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            TurnSectionHeader(title: "Turn Order Performance",
                              icon: "arrow.triangle.turn.up.right.diamond")
            
            VStack(spacing: 10) {
                // Summary
                HStack {
                    Text("\(totalGames) games recorded")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                
                // Legend
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(Color.primary.opacity(0.35))
                            .frame(width: 12, height: 1.5)
                        Text("0% (25% expected)")
                            .font(.caption2).foregroundStyle(.secondary)
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
                
                ForEach(0..<4, id: \.self) { pos in
                    let seat = seats.first { $0.seatID == pos }
                    let g    = seat?.games ?? 0
                    let w    = seat?.wins  ?? 0
                    let rate = g > 0 ? Double(w) / Double(g) : 0
                    let dev  = g > 0 ? rate - 0.25 : 0
                    
                    Button {
                        selectedSeat = pos
                    } label: {
                        SeatDeviationRow(
                            label: shortNames[pos],
                            fullName: turnNames[pos],
                            games: g, wins: w,
                            deviation: dev,
                            maxDeviation: maxDeviation,
                            color: ColorPalettes.watermelonSorbet(pos + 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: PodableTheme.radiusM))
    }
}


// ═══════════════════════════════════════════════════════════════════
// MARK: - Turn Order Detail Sheet
// ═══════════════════════════════════════════════════════════════════

struct TurnOrderDetailSheet: View {
    @Environment(\.dismiss) var dismiss
    
    let position: Int
    let seat: SeatOrder.Seat
    let allSeats: [SeatOrder.Seat]
    let totalGames: Int
    
    private let turnNames = [
        "First Player", "Second Player", "Third Player", "Final Player"
    ]
    
    private var winRate: Double {
        seat.games > 0 ? 100.0 * Double(seat.wins) / Double(seat.games) : 0
    }
    private var deviation: Double { winRate - 25.0 }
    private var losses: Int { seat.games - seat.wins }
    private var color: Color { ColorPalettes.watermelonSorbet(position + 1) }
    private var playRate: Double {
        totalGames > 0 ? 100.0 * Double(seat.games) / Double(totalGames) : 0
    }
    
    private let sidePad: CGFloat = 16
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    metricsSection
                    comparisonSection
                }
                .padding(.horizontal, sidePad)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(turnNames[position])
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(color)
                }
            }
        }
    }
    
    
    // ─────────────────────────────────────────────
    // MARK: Header
    // ─────────────────────────────────────────────
    
    private var headerSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                TurnOverviewCell(value: "\(seat.games)",
                                 label: "Games", color: color)
                tSmallDivider
                TurnOverviewCell(value: "\(seat.wins)",
                                 label: "Wins", color: .green)
                tSmallDivider
                TurnOverviewCell(value: "\(losses)",
                                 label: "Losses", color: .red)
                tSmallDivider
                TurnOverviewCell(
                    value: String(format: "%.1f%%", winRate),
                    label: "Win Rate", color: color)
            }
            .padding(.vertical, 14)
            
            Divider()
            
            HStack {
                Text(turnNames[position])
                    .font(.subheadline).fontWeight(.medium)
                    .foregroundStyle(color)
                Spacer()
                Text(String(format: "%+.1f%% vs expected",  deviation))
                    .font(.caption).fontWeight(.semibold)
                    .foregroundStyle(deviation >= 0 ? .green : .red)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var tSmallDivider: some View { Divider().frame(height: 32) }
    
    
    // ─────────────────────────────────────────────
    // MARK: Metrics
    // ─────────────────────────────────────────────
    
    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            TurnSectionHeader(title: "Performance",
                              icon: "chart.line.uptrend.xyaxis")
            
            VStack(spacing: 8) {
                MetricRow(label: "Games Played",
                          value: "\(seat.games)",
                          detail: nil)
                
                MetricRow(label: "Wins",
                          value: "\(seat.wins)",
                          detail: nil)
                
                MetricRow(label: "Losses",
                          value: "\(losses)",
                          detail: nil)
                
                MetricRow(label: "Win Rate",
                          value: String(format: "%.1f%%", winRate),
                          detail: nil)
                
                MetricRow(label: "vs Expected (25%)",
                          value: String(format: "%+.1f%%", deviation),
                          detail: deviation >= 0 ? "above" : "below")
                
                MetricRow(label: "Play Rate",
                          value: String(format: "%.1f%%", playRate),
                          detail: "of all games")
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    
    // ─────────────────────────────────────────────
    // MARK: Comparison Chart
    // ─────────────────────────────────────────────
    
    private var comparisonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            TurnSectionHeader(title: "Position Comparison",
                              icon: "chart.bar")
            
            VStack(spacing: 8) {
                Chart {
                    ForEach(allSeats, id: \.seatID) { s in
                        let rate = s.games > 0
                        ? 100.0 * Double(s.wins) / Double(s.games) : 0
                        
                        BarMark(
                            x: .value("Position", shortLabel(s.seatID)),
                            y: .value("Win %", rate)
                        )
                        .foregroundStyle(
                            ColorPalettes.watermelonSorbet(s.seatID + 1)
                                .gradient
                        )
                        .opacity(s.seatID == position ? 1.0 : 0.25)
                        .cornerRadius(4)
                    }
                    
                    // 25 % baseline
                    RuleMark(y: .value("Expected", 25.0))
                        .foregroundStyle(Color.primary.opacity(0.30))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                        .annotation(position: .trailing, spacing: 4) {
                            Text("25%")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                }
                .chartYAxisLabel {
                    Text("Win Rate (%)").font(.caption2).fontWeight(.bold)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine(stroke: StrokeStyle(
                            lineWidth: 0.3, dash: [4, 4]))
                        AxisValueLabel()
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                    }
                }
                .chartLegend(.hidden)
                .frame(height: 200)
                
                // Legend hint
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: 10, height: 10)
                    Text("Current position")
                        .font(.caption2).foregroundStyle(.secondary)
                    Spacer()
                    Rectangle()
                        .fill(Color.primary.opacity(0.3))
                        .frame(width: 14, height: 1.5)
                    Text("25% expected")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    private func shortLabel(_ seatID: Int) -> String {
        let names = ["1st", "2nd", "3rd", "4th"]
        return seatID < names.count ? names[seatID] : "\(seatID + 1)"
    }
}


// ═══════════════════════════════════════════════════════════════════
// MARK: - Sub-Components (private)
// ═══════════════════════════════════════════════════════════════════

// MARK: Section Header

private struct TurnSectionHeader: View {
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

// MARK: Overview Cell (header row in detail sheet)

private struct TurnOverviewCell: View {
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
                .font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: Seat Deviation Row (main panel)

private struct SeatDeviationRow: View {
    let label: String
    let fullName: String
    let games: Int
    let wins: Int
    let deviation: Double
    let maxDeviation: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: 10) {
            // Position label
            Text(label)
                .font(.subheadline).fontWeight(.bold)
                .foregroundStyle(color)
                .frame(width: 28, alignment: .leading)
            
            // Seat name
            Text(fullName)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)
                .lineLimit(1)
            
            // Deviation bar (centred)
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
            
            // Numbers
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
            
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(Color.secondary.opacity(0.5))
        }
        .padding(.vertical, 4)
    }
}


// ═══════════════════════════════════════════════════════════════════
// MARK: - Preview
// ═══════════════════════════════════════════════════════════════════

#Preview { TurnOrderStatsPanel() }
