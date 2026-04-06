import SwiftUI
import Podwork


// MARK: - Duel Stats View
/// Statistics overview for 60-card duel matches.
public struct DuelStatsView: View {
    @EnvironmentObject var dataManager: GameDataManager

    public init() {}

    private var matches: [FinalDuelMatch] { dataManager.duelMatches }
    private var totalMatches: Int { matches.count }
    private var totalGames: Int { matches.reduce(0) { $0 + $1.totalGamesPlayed } }
    private var totalDuration: TimeInterval { matches.reduce(0) { $0 + $1.totalDuration } }
    private var totalMulligans: Int { matches.reduce(0) { $0 + $1.totalMulligans } }
    private var totalTurns: Int { matches.reduce(0) { $0 + $1.totalTurnsPlayed } }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Duel Stats")
                .font(.title2)
                .bold()
                .foregroundStyle(Color.white)
                .padding(.horizontal)

            if matches.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.gray.opacity(0.5))
                    Text("Play some duel matches to see stats")
                        .font(.subheadline)
                        .foregroundStyle(Color.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Overview cards
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            statCard(title: "Matches", value: "\(totalMatches)", icon: "gamecontroller.fill")
                            statCard(title: "Games", value: "\(totalGames)", icon: "square.stack.fill")
                            statCard(title: "Total Time", value: formatDuration(totalDuration), icon: "clock.fill")
                            statCard(title: "Total Turns", value: "\(totalTurns)", icon: "arrow.right.circle.fill")
                            statCard(title: "Mulligans", value: "\(totalMulligans)", icon: "arrow.counterclockwise")
                            statCard(title: "Avg Game", value: formatDuration(totalGames > 0 ? totalDuration / Double(totalGames) : 0), icon: "timer")
                        }
                        .padding(.horizontal)

                        // Deck performance
                        if !deckPerformance.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Deck Performance")
                                    .font(.headline)
                                    .foregroundStyle(Color.white)
                                    .padding(.horizontal)

                                ForEach(deckPerformance, id: \.deckName) { deck in
                                    HStack {
                                        Text(deck.deckName)
                                            .font(.subheadline)
                                            .foregroundStyle(Color.white)
                                        Spacer()
                                        Text("\(deck.wins)W-\(deck.losses)L")
                                            .font(.caption)
                                            .foregroundStyle(Color.gray)
                                        Text(String(format: "%.0f%%", deck.winRate * 100))
                                            .font(.caption)
                                            .bold()
                                            .foregroundStyle(deck.winRate >= 0.5 ? Color.green : Color.red)
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.gray.opacity(0.1))
                                    )
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.cyan)
            Text(value)
                .font(.title3)
                .bold()
                .foregroundStyle(Color.white)
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        if minutes < 60 {
            let seconds = Int(duration) % 60
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return String(format: "%dh %dm", hours, remainingMinutes)
        }
    }

    // MARK: - Deck Performance Calculation

    private struct DeckPerf: Hashable {
        let deckName: String
        var wins: Int
        var losses: Int
        var winRate: Double { Double(wins) / Double(max(wins + losses, 1)) }
    }

    private var deckPerformance: [DeckPerf] {
        var decks: [String: (wins: Int, losses: Int)] = [:]

        for match in matches {
            // Player 1 deck
            let deck1 = match.player1DeckTag.isEmpty ? match.player1Name : match.player1DeckTag
            let deck2 = match.player2DeckTag.isEmpty ? match.player2Name : match.player2DeckTag

            if !deck1.isEmpty {
                var entry = decks[deck1] ?? (0, 0)
                if match.matchWinner == 0 { entry.wins += 1 }
                else if match.matchWinner == 1 { entry.losses += 1 }
                decks[deck1] = entry
            }

            if !deck2.isEmpty {
                var entry = decks[deck2] ?? (0, 0)
                if match.matchWinner == 1 { entry.wins += 1 }
                else if match.matchWinner == 0 { entry.losses += 1 }
                decks[deck2] = entry
            }
        }

        return decks.map { DeckPerf(deckName: $0.key, wins: $0.value.wins, losses: $0.value.losses) }
            .sorted { $0.winRate > $1.winRate }
    }
}
