import SwiftUI
import Podwork


// MARK: - Duel Match History View
/// List of past duel matches with expandable details.
public struct DuelMatchHistoryView: View {
    @EnvironmentObject var dataManager: GameDataManager
    @State private var expandedMatchID: String?

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Duel History")
                .font(.title2)
                .bold()
                .foregroundStyle(Color.white)
                .padding(.horizontal)

            if dataManager.duelMatches.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "rectangle.on.rectangle.slash")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.gray)
                    Text("No duel matches yet")
                        .font(.subheadline)
                        .foregroundStyle(Color.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(dataManager.duelMatches) { match in
                            matchRow(match)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    @ViewBuilder
    private func matchRow(_ match: FinalDuelMatch) -> some View {
        let isExpanded = expandedMatchID == match.matchID

        VStack(alignment: .leading, spacing: 8) {
            // Main row
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    expandedMatchID = isExpanded ? nil : match.matchID
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(match.player1Name)
                                .foregroundStyle(DuelPlayerColors.color(for: 0))
                            Text("vs")
                                .foregroundStyle(Color.gray)
                                .font(.caption)
                            Text(match.player2Name)
                                .foregroundStyle(DuelPlayerColors.color(for: 1))
                        }
                        .font(.headline)

                        HStack(spacing: 8) {
                            if !match.player1DeckTag.isEmpty || !match.player2DeckTag.isEmpty {
                                Text("\(match.player1DeckTag) vs \(match.player2DeckTag)")
                                    .font(.caption)
                                    .foregroundStyle(Color.gray)
                            }
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(match.scoreString)
                            .font(.title3)
                            .bold()
                            .foregroundStyle(Color.white)
                        Text(match.formattedDate)
                            .font(.caption2)
                            .foregroundStyle(Color.gray)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(Color.gray)
                }
            }

            // Expanded details
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                        .background(Color.gray.opacity(0.3))

                    if let winnerName = match.winnerName {
                        Text("Winner: \(winnerName)")
                            .font(.subheadline)
                            .foregroundStyle(Color.green)
                    }

                    ForEach(match.games) { game in
                        HStack {
                            Text("Game \(game.gameNumber)")
                                .font(.caption)
                                .bold()
                                .foregroundStyle(Color.white)

                            Spacer()

                            if let winner = game.winnerPlayerIndex {
                                Text(match.playerName(for: winner))
                                    .font(.caption)
                                    .foregroundStyle(DuelPlayerColors.color(for: winner))
                            } else {
                                Text("Draw")
                                    .font(.caption)
                                    .foregroundStyle(Color.gray)
                            }

                            Text("Life: \(game.finalLifeTotals[0])/\(game.finalLifeTotals[1])")
                                .font(.caption2)
                                .foregroundStyle(Color.gray)

                            Text("\(game.turnCount)T")
                                .font(.caption2)
                                .foregroundStyle(Color.gray)

                            if game.totalMulligans > 0 {
                                Text("M:\(game.mulliganCounts[0])/\(game.mulliganCounts[1])")
                                    .font(.caption2)
                                    .foregroundStyle(Color.yellow)
                            }
                        }
                    }

                    HStack {
                        Text("Duration: \(match.formattedDuration)")
                            .font(.caption2)
                            .foregroundStyle(Color.gray)
                        Spacer()
                        Text("Turns: \(match.totalTurnsPlayed)")
                            .font(.caption2)
                            .foregroundStyle(Color.gray)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }
}
