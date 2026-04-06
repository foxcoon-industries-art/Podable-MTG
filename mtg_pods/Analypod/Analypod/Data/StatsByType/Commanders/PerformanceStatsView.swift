import SwiftUI
import Podwork


// ═══════════════════════════════════════════════════════════════
// MARK: - Commander Performance Card
// ═══════════════════════════════════════════════════════════════
/// Metric row shown inside a commander card.  Displays play rate, win rate,
/// average commander damage (with std-dev), and average game duration (with
/// std-dev).  Used by FetchrScryfallView when previewing a single commander's
/// stats.

struct CommanderPerformanceCard: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appInfo: App_Info

    let commander: String
    let stats: CommanderSummary
    let playRate: Double

    var body: some View {
        let playRatePercentage   = 100.0 * playRate
        let winPercent           = stats.winPercentage
        let averageDuration      = timeFormatDuration(stats.avgPodDuration)
        let stdDuration          = timeFormatDuration(stats.timePerGameStdDev)
        let averageDamage        = stats.avgCommanderDamagePerGame
        let damageStdDev         = stats.damagePerGameStdDev

        VStack(alignment: .leading, spacing: 6) {

            HStack(spacing: 0) {
                MetricPill(title: "Play Rate",
                           value: String(format: "%.1f", playRatePercentage) + "%",
                           color: winRateColor(playRatePercentage))

                MetricPill(title: "Win Rate",
                           value: String(format: "%.1f", winPercent) + "%",
                           color: winRateColor(winPercent))

                StatWithDeviation(title: "Avg Damage",
                                  avg:   averageDamage,
                                  stdDev: damageStdDev,
                                  color: Color.teal)
                    .frame(maxWidth: .infinity)

                TimeStatWithDeviation(title: "Avg Game",
                                      avg:   averageDuration,
                                      stdDev: stdDuration,
                                      color: Color.teal)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, PodableTheme.spacingS)
            .padding(.top,        PodableTheme.spacingS)

            // Win-rate progress bar
            ProgressView(value: 0.01 * winPercent)
                .tint(winRateColor(winPercent))
                .padding(.bottom,    PodableTheme.spacingS)
                .padding(.horizontal, PodableTheme.spacingS)
        }
        .background(Color(.secondarySystemFill))
    }

    // ── colour helpers ──
    private func winRateColor(_ rate: Double) -> Color {
        switch rate {
        case 25...:        return .green
        case 6.25..<25:    return .orange
        default:           return .red
        }
    }
}


// ═══════════════════════════════════════════════════════════════
// MARK: - Stat With Deviation  (numeric value)
// ═══════════════════════════════════════════════════════════════
/// Compact pill that shows a numeric average with an optional ± std-dev badge.

struct StatWithDeviation: View {
    let title:  String
    let avg:    Double
    let stdDev: Double
    let color:  Color

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(String(format: "%.1f", avg))
                    .font(.headline)
                    .bold()

                if stdDev > 0 {
                    Text("± \(String(format: "%.1f", stdDev))")
                        .font(.caption)
                        .foregroundColor(Color.orange)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.55)
            .customStroke(color: Color.black, width: 0.75)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.875)
        }
        .padding(.vertical,   4)
        .padding(.horizontal, PodableTheme.spacingS)
        .background(color.tertiary)
        .cornerRadius(PodableTheme.radiusM)
    }
}


// ═══════════════════════════════════════════════════════════════
// MARK: - Stat With Deviation  (pre-formatted time string)
// ═══════════════════════════════════════════════════════════════
/// Same pill layout as StatWithDeviation, but accepts pre-formatted `String`
/// values (used for durations that have already been run through
/// `timeFormatDuration`).

struct TimeStatWithDeviation: View {
    let title:  String
    let avg:    String
    let stdDev: String
    let color:  Color

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(avg)
                    .font(.headline)
                    .bold()

                Text("± \(stdDev)")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.55)
            .customStroke(color: Color.black, width: 0.75)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical,   4)
        .padding(.horizontal, PodableTheme.spacingS)
        .background(color.tertiary)
        .cornerRadius(PodableTheme.radiusM)
    }
}
