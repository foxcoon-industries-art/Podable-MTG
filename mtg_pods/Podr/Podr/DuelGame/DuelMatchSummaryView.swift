import SwiftUI
import Podwork


// MARK: - Duel Match Summary View
/// Final summary shown when the best-of-3 match is complete.
struct DuelMatchSummaryView: View {
    let match: DuelMatch
    let onSaveAndReturn: () -> Void

    @EnvironmentObject var dataManager: GameDataManager

    private var winnerName: String {
        match.winnerName ?? "Draw"
    }

    private var winnerColor: Color {
        guard let winner = match.matchWinner else { return Color.gray }
        return DuelPlayerColors.color(for: winner)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 20)

                    // Match winner
                    VStack(spacing: 12) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(Color.yellow)

                        Text(winnerName)
                            .font(.largeTitle)
                            .bold()
                            .foregroundStyle(winnerColor)

                        Text("wins the match!")
                            .font(.title2)
                            .foregroundStyle(Color.white)

                        Text(match.scoreString)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.white)
                    }

                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.horizontal)

                    // Game summaries
                    VStack(spacing: 16) {
                        Text("Games")
                            .font(.headline)
                            .foregroundStyle(Color.gray)

                        ForEach(match.completedGames) { game in
                            gameCard(game)
                        }
                    }

                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.horizontal)

                    // Match stats
                    VStack(spacing: 12) {
                        Text("Match Stats")
                            .font(.headline)
                            .foregroundStyle(Color.gray)

                        statsGrid
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.1))
                    )
                    .padding(.horizontal)

                    // Save and return
                    Button(action: saveAndReturn) {
                        Text("Save & Return to Menu")
                            .font(.title3)
                            .bold()
                            .foregroundStyle(Color.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Capsule().fill(Color.green.gradient))
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 30)
                }
            }
        }
    }

    @ViewBuilder
    private func gameCard(_ game: DuelGameResult) -> some View {
        let winnerName: String = {
            guard let winner = game.winnerPlayerIndex else { return "Draw" }
            return match.playerName(for: winner)
        }()
        let winnerColor: Color = {
            guard let winner = game.winnerPlayerIndex else { return Color.gray }
            return DuelPlayerColors.color(for: winner)
        }()

        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Game \(game.gameNumber)")
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(Color.white)

                Text("Winner: \(winnerName)")
                    .font(.caption)
                    .foregroundStyle(winnerColor)

                Text("\(game.winMethod)")
                    .font(.caption2)
                    .foregroundStyle(Color.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Life: \(game.finalLifeTotals[0]) / \(game.finalLifeTotals[1])")
                    .font(.caption)
                    .foregroundStyle(Color.white)

                Text("\(game.turnCount) turns")
                    .font(.caption)
                    .foregroundStyle(Color.gray)

                Text(game.formattedDuration)
                    .font(.caption)
                    .foregroundStyle(Color.gray)

                if game.totalMulligans > 0 {
                    Text("Mull: \(game.mulliganCounts[0])/\(game.mulliganCounts[1])")
                        .font(.caption2)
                        .foregroundStyle(Color.yellow)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
        .padding(.horizontal)
    }

    @ViewBuilder
    private var statsGrid: some View {
        let totalGames = match.completedGames.count
        let totalTurns = match.completedGames.reduce(0) { $0 + $1.turnCount }
        let totalMulligans = match.completedGames.reduce(0) { $0 + $1.totalMulligans }
        let totalDuration = match.totalDuration

        VStack(spacing: 8) {
            statRow(label: "Games Played", value: "\(totalGames)")
            statRow(label: "Total Turns", value: "\(totalTurns)")
            statRow(label: "Total Duration", value: formatDuration(totalDuration))
            if totalMulligans > 0 {
                let p1Mulls = match.completedGames.reduce(0) { $0 + $1.mulliganCounts[0] }
                let p2Mulls = match.completedGames.reduce(0) { $0 + $1.mulliganCounts[1] }
                statRow(label: "Total Mulligans", value: "\(p1Mulls) / \(p2Mulls)")
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

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func saveAndReturn() {
        let finalMatch = match.toFinalDuelMatch()
        // Collect turn histories from completed games
        // (turn histories are lost after game completes, so we pass empty arrays for now
        // - in production this would be collected during gameplay)
        let turnHistories: [[DuelTurn]] = match.completedGames.map { _ in [] }
        dataManager.saveDuelMatch(finalMatch, turnHistories: turnHistories)
        onSaveAndReturn()
    }
}
