import SwiftUI
import Charts
import Podwork


// MARK: - FetchrTurnOrderList
/// Stats split by turn order (seat position).
/// Repurposes the TurnOrderWinChart donut from LogsOverview.
/// Tapping a seat opens a detail sheet with additional analysis.
struct FetchrTurnOrderList: View {
    @StateObject private var dataManager = GameDataManager.shared
    @State private var selectedSeat: Int? = nil

    private let sidePad: CGFloat = 6
    private let turnNames = ["First Player", "Second Player", "Third Player", "Final Player"]

    var body: some View {
        VStack(spacing: 0) {
            let seats = dataManager.seatOrderStats.turnOrderWinRates
                .sorted(by: { $0.seatID < $1.seatID })
            let totalGames = seats.reduce(0) { $0 + $1.games }

            if (totalGames > 0) == false {
                emptyState
              //  return
            } else {
                
                // Donut chart (repurposed from LogsOverview TurnOrderWinChart)
                turnOrderDonut(seats: seats)
                    .padding(.horizontal, sidePad)
                    .padding(.top, 4)
                    .padding(.bottom, 10)
                
                // Seat rows
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 6) {
                        ForEach(seats) { seat in
                            let label = seat.seatID < turnNames.count
                            ? turnNames[seat.seatID]
                            : "Seat \(seat.seatID + 1)"
                            FetchrSeatRow(
                                seatID: seat.seatID,
                                label: label,
                                wins: seat.wins,
                                games: seat.games,
                                totalGames: totalGames,
                                onTap: { selectedSeat = seat.seatID }
                            )
                        }
                    }
                    .padding(.horizontal, sidePad)
                    .padding(.bottom, 8)
                }
            }
        }
        // Seat detail sheet
        .sheet(item: $selectedSeat, onDismiss: { selectedSeat = nil }) { seatID in
            FetchrTurnOrderDetailSheet(seatID: seatID)
        }
    }


    // ── Donut chart with labels on both sides (from LogsOverview style)
    private func turnOrderDonut(seats: [SeatOrder.Seat]) -> some View {
        VStack(spacing: sidePad) {
            Text("Win Rate by Seat")
                .fontWeight(.bold)
                .foregroundStyle(Color.white.gradient)
                .multilineTextAlignment(.center)

            HStack(alignment: .center, spacing: sidePad) {
                // Left labels (seats 2, 3 from top)
                VStack(spacing: 8) {
                    ForEach(0..<2) { position in
                        let seat = seats[3 - position]
                        let winRate = seat.games > 0
                            ? 100.0 * Double(seat.wins) / Double(seat.games) : 0
                        VStack(spacing: 4) {
                            Text(String(format: "%d%%", Int(winRate)))
                                .foregroundStyle(ColorPalettes.watermelonSorbet(3 - position + 1).gradient)
                                .font(.title2)
                            HStack(spacing: 4) {
                                Text(seat.seatID < turnNames.count ? turnNames[seat.seatID] : "Seat \(seat.seatID)")
                                    .font(.footnote)
                                    .foregroundStyle(Color.white.gradient)
                                Circle()
                                    .fill(ColorPalettes.watermelonSorbet(3 - position + 1).gradient)
                                    .frame(width: 8, height: 8)
                            }
                        }.bold()
                    }
                }.frame(maxWidth: .infinity)

                // Donut
                Chart(seats.sorted(by: { $0.seatID < $1.seatID })) { entry in
                    SectorMark(
                        angle: .value("Wins", entry.games > 0 ? Double(entry.wins) : 0),
                        innerRadius: .ratio(0.618),
                        angularInset: 1.5
                    )
                    .foregroundStyle(ColorPalettes.watermelonSorbet(min(entry.seatID, 3) + 1).gradient)
                }
                .padding()
                .frame(width: 120, height: 120)

                // Right labels (seats 0, 1 from top)
                VStack(spacing: 8) {
                    ForEach(0..<2) { position in
                        let seat = seats[position]
                        let winRate = seat.games > 0
                            ? 100.0 * Double(seat.wins) / Double(seat.games) : 0
                        VStack(spacing: 4) {
                            Text(String(format: "%d%%", Int(winRate)))
                                .foregroundStyle(ColorPalettes.watermelonSorbet(position + 1).gradient)
                                .font(.title2)
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(ColorPalettes.watermelonSorbet(position + 1).gradient)
                                    .frame(width: 8, height: 8)
                                Text(seat.seatID < turnNames.count ? turnNames[seat.seatID] : "Seat \(seat.seatID)")
                                    .font(.footnote)
                                    .foregroundStyle(Color.white.gradient)
                            }
                        }.bold()
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .background(Color(.secondarySystemFill))
            .padding(.horizontal, 0)

            Text("Turn Order")
                .foregroundStyle(Color.white.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, sidePad)
        .padding(.top, sidePad)
        .padding(.horizontal, 0)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }


    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "metronome")
                .font(.system(size: 36))
                .foregroundStyle(Color.blue.opacity(0.4))
            Text("No Turn Order Data Yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Play some games to see turn order analysis here.")
                .font(.caption)
                .foregroundStyle(Color.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}


// MARK: - FetchrSeatRow
/// Single row for a turn order seat.
private struct FetchrSeatRow: View {
    let seatID: Int
    let label: String
    let wins: Int
    let games: Int
    let totalGames: Int
    let onTap: () -> Void

    var body: some View {
        Button { onTap() } label: {
            HStack(spacing: 10) {
                // Seat badge
                ZStack {
                    Circle()
                        .fill(ColorPalettes.watermelonSorbet(min(seatID, 3) + 1).opacity(0.2))
                        .frame(width: 32, height: 32)
                    Text("\(seatID + 1)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(ColorPalettes.watermelonSorbet(min(seatID, 3) + 1))
                }

                // Label
                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(ColorPalettes.watermelonSorbet(min(seatID, 3) + 1))

                Spacer(minLength: 0)

                // Metrics
                HStack(spacing: 6) {
                    SeatMetricPill(
                        label: "Wins",
                        value: "\(wins)",
                        color: .green
                    )
                    SeatMetricPill(
                        label: "Games",
                        value: "\(games)",
                        color: .teal
                    )
                    SeatMetricPill(
                        label: "Win %",
                        value: String(format: "%.0f%%", games > 0 ? 100.0 * Double(wins) / Double(games) : 0),
                        color: ColorPalettes.watermelonSorbet(min(seatID, 3) + 1)
                    )
                }

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}


// ── Seat Metric Pill
private struct SeatMetricPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 6)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}


// MARK: - FetchrTurnOrderDetailSheet
/// Detail sheet for a specific seat position — additional analysis and comparisons.
struct FetchrTurnOrderDetailSheet: View {
    let seatID: Int
    @StateObject private var dataManager = GameDataManager.shared
    @Environment(\.dismiss) var dismiss

    private let turnNames = ["First Player", "Second Player", "Third Player", "Final Player"]

    private var seat: SeatOrder.Seat? {
        dataManager.seatOrderStats.seats[seatID]
    }

    private var allSeats: [SeatOrder.Seat] {
        dataManager.seatOrderStats.turnOrderWinRates.sorted(by: { $0.seatID < $1.seatID })
    }

    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    if let s = seat  {
                        Text("No data for this seat.")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                        //return
                        
                        
                        // Header
                        seatHeader(s)
                        
                        Divider()
                        
                        // Key metrics
                        seatMetricsGrid(s)
                        
                        // Explanation
                        explanationSection()
                        
                        // Win rate comparison bar chart across all seats
                        winRateComparisonChart()
                        
                        // Games distribution pie (how many games each seat played)
                        gamesDistributionChart()
                    }
                    Spacer(minLength: 16)
                }
                .padding(.horizontal, 16)
            }
            .navigationTitle(seatID < turnNames.count ? turnNames[seatID] : "Seat \(seatID + 1)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationCompactAdaptation(horizontal: .popover, vertical: .sheet)
    }


    // ── Header badge and label
    private func seatHeader(_ s: SeatOrder.Seat) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(ColorPalettes.watermelonSorbet(min(seatID, 3) + 1).opacity(0.25))
                    .frame(width: 48, height: 48)
                Text("\(seatID + 1)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(ColorPalettes.watermelonSorbet(min(seatID, 3) + 1))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(seatID < turnNames.count ? turnNames[seatID] : "Seat \(seatID + 1)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(ColorPalettes.watermelonSorbet(min(seatID, 3) + 1))
                Text("\(s.wins) wins out of \(s.games) games")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }


    // ── Key metrics grid
    private func seatMetricsGrid(_ s: SeatOrder.Seat) -> some View {
        let winRate = s.games > 0 ? 100.0 * Double(s.wins) / Double(s.games) : 0
        let totalAllGames = allSeats.reduce(0) { $0 + $1.games }
        let shareOfGames = totalAllGames > 0 ? 100.0 * Double(s.games) / Double(totalAllGames) : 0
        let losses = s.games - s.wins

        return LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ], spacing: 8) {
            SeatDetailCard(
                title: "Win Rate",
                value: String(format: "%.1f%%", winRate),
                subtitle: "\(s.wins) of \(s.games)",
                color: .green,
                icon: "checkmark.circle"
            )
            SeatDetailCard(
                title: "Games Played",
                value: "\(s.games)",
                subtitle: String(format: "%.1f%% of total", shareOfGames),
                color: .teal,
                icon: "gamecontroller"
            )
            SeatDetailCard(
                title: "Losses",
                value: "\(losses)",
                subtitle: String(format: "%.1f%% loss rate", s.games > 0 ? 100.0 * Double(losses) / Double(s.games) : 0),
                color: .red,
                icon: "xmark.circle"
            )
            SeatDetailCard(
                title: "Advantage",
                value: winRate >= 25 ? (winRate > 30 ? "Strong ↑" : "Fair →") : "Weak ↓",
                subtitle: "vs. 25% baseline",
                color: winRate >= 25 ? .green : .orange,
                icon: "arrow.up.right.circle"
            )
        }
    }


    // ── Explanation of this seat position
    private func explanationSection() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("About This Position")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.white.gradient)

            Text(seatExplanation())
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.secondarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }


    // ── Win rate bar chart comparing all seats (highlights current)
    private func winRateComparisonChart() -> some View {
        let chartData = allSeats.map {
            SeatWinPoint(seatID: $0.seatID,
                         label: $0.seatID < turnNames.count ? turnNames[$0.seatID] : "Seat \($0.seatID + 1)",
                         winRate: $0.games > 0 ? 100.0 * Double($0.wins) / Double($0.games) : 0)
        }

        return VStack(alignment: .leading, spacing: 8) {
            Text("Win Rate Comparison")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.white.gradient)

            Chart(chartData) { point in
                BarMark(
                    x: .value("Seat", point.label),
                    y: .value("Win %", point.winRate)
                )
                .foregroundStyle(
                    point.seatID == seatID
                        ? AnyShapeStyle(ColorPalettes.watermelonSorbet(min(seatID, 3) + 1).gradient)
                        : AnyShapeStyle(ColorPalettes.watermelonSorbet(min(point.seatID, 3) + 1).opacity(0.3))
                )
                .cornerRadius(4)

                // Baseline at 25%
                RuleMark(y: .value("Baseline", 25))
                    .foregroundStyle(Color.white.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4]))
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                    if let v = value.as(Double.self) {
                        AxisValueLabel(String(format: "%.0f%%", v))
                        AxisGridLine()
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    if let label = value.as(String.self) {
                        // Shorten labels for space
                        let short = label.components(separatedBy: " ").first ?? label
                        AxisValueLabel(short)
                    }
                }
            }
            .frame(height: 110)
            .padding(.horizontal, 4)
            .background(Color(.secondarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }


    // ── Games distribution donut (how games are split across seats)
    private func gamesDistributionChart() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Games Distribution")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.white.gradient)

            HStack(spacing: 12) {
                Chart(allSeats) { s in
                    SectorMark(
                        angle: .value("Games", Double(s.games)),
                        innerRadius: .ratio(0.55),
                        angularInset: 1.5
                    )
                    .foregroundStyle(ColorPalettes.watermelonSorbet(min(s.seatID, 3) + 1).gradient)
                    .opacity(s.seatID == seatID ? 1.0 : 0.5)
                }
                .chartLegend(.hidden)
                .frame(width: 80, height: 80)

                VStack(alignment: .leading, spacing: 4) {
                    ForEach(allSeats) { s in
                        let label = s.seatID < turnNames.count ? turnNames[s.seatID] : "Seat \(s.seatID + 1)"
                        HStack(spacing: 6) {
                            Circle()
                                .fill(ColorPalettes.watermelonSorbet(min(s.seatID, 3) + 1))
                                .frame(width: 8, height: 8)
                            Text(label)
                                .font(.caption)
                                .foregroundStyle(s.seatID == seatID ? Color.primary : Color.secondary)
                            Spacer()
                            Text("\(s.games)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(ColorPalettes.watermelonSorbet(min(s.seatID, 3) + 1))
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }


    private struct SeatWinPoint: Identifiable {
        let id: Int
        let seatID: Int
        let label: String
        let winRate: Double
        init(seatID: Int, label: String, winRate: Double) {
            self.id = seatID
            self.seatID = seatID
            self.label = label
            self.winRate = winRate
        }
    }


    // ── Seat explanation text
    private func seatExplanation() -> String {
        switch seatID {
        case 0: return "Going first means you get to set the pace and establish board presence early. In Commander, first player advantage can be significant — you get more turns and earlier access to resources. However, you also become a target as the first to show board state."
        case 1: return "Second seat lets you react to the first player's opening while still having early agency. You can respond to threats before they fully develop and often have slightly better information for your initial strategy."
        case 2: return "Third seat provides a reactive advantage — you've seen two players' openings before committing. This often leads to better political positioning and the ability to form early alliances based on observed board states."
        case 3: return "Going last (or fourth) gives maximum information before your first turn, but you have the fewest total turns in the game. This seat often requires aggressive early plays to keep up with the tempo established by earlier players."
        default: return "No specific analysis available for this seat position."
        }
    }
}


// ── Seat Detail Card
private struct SeatDetailCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(color.gradient)
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(Color.secondary.opacity(0.7))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}


#Preview {
    FetchrTurnOrderList()
        .preferredColorScheme(.dark)
}
