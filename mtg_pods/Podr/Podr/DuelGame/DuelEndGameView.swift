import SwiftUI
import Podwork


// MARK: - Duel End Game View
/// Shown when a single game within a match ends. Displays winner and game stats.
struct DuelEndGameView: View {
    let gameResult: DuelGameResult
    let player1Name: String
    let player2Name: String
    let matchScore: [Int]
    let isMatchOver: Bool
    let onNextGame: () -> Void
    let onMatchComplete: () -> Void

    @State private var showStats = false

    private var winnerName: String {
        guard let winner = gameResult.winnerPlayerIndex else { return "Draw" }
        return winner == 0 ? player1Name : player2Name
    }

    private var winnerColor: Color {
        guard let winner = gameResult.winnerPlayerIndex else { return Color.gray }
        return DuelPlayerColors.color(for: winner)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Winner announcement
                VStack(spacing: 12) {
                    if gameResult.isDraw {
                        Image(systemName: "equal.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(Color.gray)
                        Text("Draw!")
                            .font(.largeTitle)
                            .bold()
                            .foregroundStyle(Color.gray)
                    } else {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.yellow)

                        Text(winnerName)
                            .font(.largeTitle)
                            .bold()
                            .foregroundStyle(winnerColor)

                        Text("wins Game \(gameResult.gameNumber)!")
                            .font(.title2)
                            .foregroundStyle(Color.white)

                        Text("by \(gameResult.winMethod)")
                            .font(.subheadline)
                            .foregroundStyle(Color.gray)
                    }
                }

                // Match score
                VStack(spacing: 8) {
                    Text("Match Score")
                        .font(.caption)
                        .foregroundStyle(Color.gray)

                    HStack(spacing: 20) {
                        VStack {
                            Text(player1Name.isEmpty ? "P1" : player1Name)
                                .font(.caption)
                                .foregroundStyle(DuelPlayerColors.color(for: 0))
                            Text("\(matchScore[0])")
                                .font(.title)
                                .bold()
                                .foregroundStyle(Color.white)
                        }

                        Text("-")
                            .font(.title)
                            .foregroundStyle(Color.gray)

                        VStack {
                            Text(player2Name.isEmpty ? "P2" : player2Name)
                                .font(.caption)
                                .foregroundStyle(DuelPlayerColors.color(for: 1))
                            Text("\(matchScore[1])")
                                .font(.title)
                                .bold()
                                .foregroundStyle(Color.white)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.1))
                    )
                }

                // Game stats
                if showStats {
                    VStack(spacing: 8) {
                        statRow(label: "Turns Played", value: "\(gameResult.turnCount)")
                        statRow(label: "Duration", value: gameResult.formattedDuration)
                        statRow(label: "Final Life", value: "\(gameResult.finalLifeTotals[0]) / \(gameResult.finalLifeTotals[1])")
                        if gameResult.totalMulligans > 0 {
                            statRow(label: "Mulligans", value: "\(gameResult.mulliganCounts[0]) / \(gameResult.mulliganCounts[1])")
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.1))
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer()

                // Action button
                if isMatchOver {
                    Button(action: onMatchComplete) {
                        Text("Match Complete")
                            .font(.title3)
                            .bold()
                            .foregroundStyle(Color.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Capsule().fill(Color.yellow.gradient))
                    }
                    .padding(.horizontal, 32)
                } else {
                    Button(action: onNextGame) {
                        Text("Next Game")
                            .font(.title3)
                            .bold()
                            .foregroundStyle(Color.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Capsule().fill(Color.white.gradient))
                    }
                    .padding(.horizontal, 32)
                }

                Spacer()
                    .frame(height: 30)
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.5).delay(0.5)) {
                showStats = true
            }
        }
    }

    @ViewBuilder
    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.gray)
            Spacer()
            Text(value)
                .font(.subheadline)
                .bold()
                .foregroundStyle(Color.white)
        }
    }
}
