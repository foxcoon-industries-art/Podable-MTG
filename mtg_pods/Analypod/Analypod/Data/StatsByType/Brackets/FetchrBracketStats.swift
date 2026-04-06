import SwiftUI
import Charts
import Podwork


// MARK: - FetchrBracketList
/// Stats split by bracket. Shows the vibe check chart at top, then
/// tappable bracket rows. Tapping opens a detail sheet with deeper metrics.
struct FetchrBracketList: View {
    @StateObject private var dataManager = GameDataManager.shared
    @State private var selectedBracket: Int? = nil
    @State private var showBracketDetail: Bool = false

    
    private let sidePad: CGFloat = 6

    var body: some View {
        VStack(spacing: 0) {
            if dataManager.bracketStats.isEmpty {
                emptyState
                //return EmptyView()
            }

            let bracketValues = dataManager.bracketStats.values
                .sorted(by: { $0.bracket < $1.bracket })
                .filter { $0.bracket >= 1 && $0.bracket <= 5 }

            let totalPlayed = bracketValues.map { $0.games }.reduce(0, +)

            // Vibe Check Chart
            BracketVibeCheckView(bracketValues)
                .padding(.horizontal, sidePad)
                .padding(.top, 4)
                .padding(.bottom, 10)

            // Bracket rows
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 6) {
                    ForEach(bracketValues, id: \.bracket) { bracket in
                        FetchrBracketRow(
                            bracket: bracket,
                            totalPlayed: totalPlayed,
                            onTap: { selectedBracket = bracket.bracket
                            showBracketDetail = true}
                        )
                    }
                }
                .padding(.horizontal, sidePad)
                .padding(.bottom, 8)
            }
        }
        // Bracket detail sheet
        .sheet(item: $selectedBracket, onDismiss: { selectedBracket = nil }) { bracket in
            FetchrBracketDetailSheet(bracketNumber: bracket)
        }
    }


    @ViewBuilder
    private var emptyState: some View {
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


// MARK: - FetchrBracketRow
/// Single row for a bracket with play rate, win rate, and agreement.
public struct FetchrBracketRow: View {
    let bracket: BracketStatistics
    let totalPlayed: Int
    let onTap: () -> Void

    public var body: some View {
        Button { onTap() } label: {
            HStack(spacing: 10) {
                // Bracket badge
                ZStack {
                    Circle()
                        .fill(bracketColor(bracket.bracket).opacity(0.2))
                        .frame(width: 32, height: 32)
                    Text("\(bracket.bracket)")
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundStyle(bracketColor(bracket.bracket))
                }

                // Label
                VStack(alignment: .leading, spacing: 2) {
                    Text(bracketDisplayName(bracket.bracket))
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(bracketColor(bracket.bracket).gradient)
                    Text("\(bracket.decks) decks rated")
                        .font(.callout)
                        .fontWeight(.thin)
                        .foregroundStyle(bracketColor(bracket.bracket).gradient)
                        //.foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                // Metric pills
                HStack(spacing: 6) {
                    BracketMetricPill(
                        label: "Play Rate",
                        value: String(format: "%.1f%%", playRatePercent),
                        color: rateColor(playRatePercent)
                    )
                    BracketMetricPill(
                        label: "Agreement",
                        value: String(format: "%.1f%%", sameBracketPercent),
                        color: rateColor(sameBracketPercent)
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

    private var playRatePercent: Double {
        totalPlayed > 0 ? 100.0 * Double(bracket.games) / Double(totalPlayed) : 0
    }

    private var sameBracketPercent: Double {
        bracket.sameBracketRate * 100.0
    }

    private func rateColor(_ rate: Double) -> Color {
        switch rate {
        case 66...: return .green
        case 33..<66: return .orange
        default: return .red
        }
    }

    private func bracketDisplayName(_ b: Int) -> String {
        switch b {
        case 1: return "Story Time"
        case 2: return "Doing the Thing"
        case 3: return "Standard Game"
        case 4: return "Friendly Fight"
        case 5: return "Race to Win"
        default: return "Bracket \(b)"
        }
    }
}


// MARK: - BracketMetricPill
private struct BracketMetricPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.callout)
                .fontWeight(.bold)
                .foregroundStyle(color.gradient)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 6)
        .background(color.opacity(0.08))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}


// MARK: - FetchrBracketDetailSheet
/// Detailed bracket analysis shown when a bracket row is tapped.
/// Shows win rate, play rate, agreement rate, decks rated,
/// average game length for this bracket, and a mini vibe check.
struct FetchrBracketDetailSheet: View {
    let bracketNumber: Int
    @StateObject private var dataManager = GameDataManager.shared
    @Environment(\.dismiss) var dismiss

    private var bracket: BracketStatistics? {
        dataManager.bracketStats[bracketNumber]
    }

    private var totalGames: Int {
        dataManager.bracketStats.values.map { $0.games }.reduce(0, +)
    }

    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    if let b = bracket  {
                        Text("No data for this bracket.")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                        //                        return EmptyView()
                        
                        
                        // Header
                        bracketHeader(b)
                        
                        Divider()
                        
                        // Key metrics grid
                        metricsGrid(b)
                        
                        // Detailed explanation
                        explanationSection(b)
                        
                        // Mini vibe check for just this bracket
                        miniVibeCheck(b)
                        
                        // Win rate vs other brackets comparison
                        winRateComparison()
                    }
                    Spacer(minLength: 16)
                }
                .padding(.horizontal, 16)
            }
            .navigationTitle("Bracket \(bracketNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationCompactAdaptation(horizontal: .popover, vertical: .sheet)
    }


    // ── Header with badge and name
    private func bracketHeader(_ b: BracketStatistics) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(bracketColor(b.bracket).opacity(0.25))
                    .frame(width: 48, height: 48)
                Text("\(b.bracket)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(bracketColor(b.bracket))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(bracketName(b.bracket))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(bracketColor(b.bracket))
                Text("\(b.decks) decks rated • \(b.games) games won")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }


    // ── Key metrics grid: Play Rate, Win Rate, Agreement, Decks
    private func metricsGrid(_ b: BracketStatistics) -> some View {
        let playRate = totalGames > 0 ? 100.0 * Double(b.games) / Double(totalGames) : 0
        let winRate = b.winRate * 100
        let agreement = b.sameBracketRate * 100

        return LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ], spacing: 8) {
            DetailMetricCard(
                title: "Play Rate",
                value: String(format: "%.1f%%", playRate),
                subtitle: "of all games",
                color: .teal,
                icon: "chart.bar"
            )
            DetailMetricCard(
                title: "Win Rate",
                value: String(format: "%.1f%%", winRate),
                subtitle: "from this bracket",
                color: .green,
                icon: "checkmark.circle"
            )
            DetailMetricCard(
                title: "Agreement",
                value: String(format: "%.1f%%", agreement),
                subtitle: "opponents agree",
                color: agreement >= 50 ? .green : .orange,
                icon: "person.2"
            )
            DetailMetricCard(
                title: "Decks Rated",
                value: "\(b.decks)",
                subtitle: "unique commanders",
                color: .purple,
                icon: "rectangle.stack"
            )
        }
    }


    // ── Explanation text for this bracket
    private func explanationSection(_ b: BracketStatistics) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("About This Bracket")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.white.gradient)

            Text(bracketExplanation(b.bracket))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.secondarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }


    // ── Mini vibe check donut for this single bracket
    private func miniVibeCheck(_ b: BracketStatistics) -> some View {
        guard !b.vibeCheck.isEmpty else { return AnyView(EmptyView()) }

        let sorted = b.vibeCheck.sorted(by: { $0.key < $1.key })

        return AnyView(
            VStack(alignment: .leading, spacing: 8) {
                Text("How Others Rate Bracket \(b.bracket) Decks")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.white.gradient)

                Chart(sorted, id: \.key) { entry in
                    BarMark(
                        x: .value("Rating", "B\(entry.key)"),
                        y: .value("Count", entry.value)
                    )
                    .foregroundStyle(
                        entry.key == b.bracket
                            ? AnyShapeStyle(bracketColor(b.bracket).gradient)
                            : AnyShapeStyle(bracketColor(b.bracket).tertiary)
                    )
                    .cornerRadius(4)
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                        if let v = value.as(Int.self) {
                            AxisValueLabel("\(v)")
                            AxisGridLine()
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                    }
                }
                .frame(height: 100)
                .padding(.horizontal, 4)
                .background(Color(.secondarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        )
    }


    // ── Win rate comparison bar chart across all brackets
    private func winRateComparison() -> some View {
        let brackets = dataManager.bracketStats.values
            .filter { $0.bracket >= 1 && $0.bracket <= 5 }
            .sorted(by: { $0.bracket < $1.bracket })

        guard !brackets.isEmpty else { return AnyView(EmptyView()) }

        let chartData = brackets.map {
            BracketWinPoint(bracket: $0.bracket, winRate: $0.winRate * 100)
        }

        return AnyView(
            VStack(alignment: .leading, spacing: 8) {
                Text("Win Rate Across Brackets")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.white.gradient)

                Chart(chartData) { point in
                    BarMark(
                        x: .value("Bracket", "B\(point.bracket)"),
                        y: .value("Win Rate", point.winRate)
                    )
                    .foregroundStyle(
                        point.bracket == bracketNumber
                            ? AnyShapeStyle(bracketColor(point.bracket).gradient)
                            : AnyShapeStyle(bracketColor(point.bracket).opacity(0.4))
                    )
                    .cornerRadius(4)
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                        if let v = value.as(Double.self) {
                            AxisValueLabel(String(format: "%.0f%%", v))
                            AxisGridLine()
                        }
                    }
                }
                .frame(height: 100)
                .padding(.horizontal, 4)
                .background(Color(.secondarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        )
    }


    private struct BracketWinPoint: Identifiable {
        let id: Int
        let bracket: Int
        let winRate: Double
        init(bracket: Int, winRate: Double) {
            self.id = bracket
            self.bracket = bracket
            self.winRate = winRate
        }
    }


    private func bracketName(_ b: Int) -> String {
        switch b {
        case 1: return "Story Time"
        case 2: return "Doing the Thing"
        case 3: return "Standard Game"
        case 4: return "Friendly Fight"
        case 5: return "Race to Win"
        default: return "Bracket \(b)"
        }
    }

    private func bracketExplanation(_ b: Int) -> String {
        switch b {
        case 1: return "The most casual bracket — focused on story-telling and theme. Games here prioritize fun and flavor over competitive play. Win rates are less predictable since players may intentionally hold back."
        case 2: return "A testing ground for new ideas and experimental builds. Players at this level are learning decks and exploring synergies. Expect some inconsistency as builds are still being tuned."
        case 3: return "The sweet spot for most casual playgroups. Decks are built to function well but aren't optimized for maximum efficiency. This is where the majority of games tend to land."
        case 4: return "Decks here are well-tuned and expected to perform. Players understand their game plans and execute them reliably. Games tend to be more competitive and faster."
        case 5: return "The highest tier — optimized, combo-focused, or highly synergistic decks. Games here move quickly and require strategic decision-making from all players."
        default: return "No description available for this bracket."
        }
    }
}


// MARK: - DetailMetricCard  (reusable metric card for detail sheets)
private struct DetailMetricCard: View {
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
    FetchrBracketList()
        .preferredColorScheme(.dark)
}
