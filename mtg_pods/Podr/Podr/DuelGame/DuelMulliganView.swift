import SwiftUI
import Podwork


// MARK: - Duel Mulligan View
/// Displayed before each game starts. Both players choose to keep or mulligan.
struct DuelMulliganView: View {
    @Bindable var game: DuelGameState
    let gameNumber: Int
    let onAllConfirmed: () -> Void

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // Player 2 mulligan area (rotated)
                mulliganPanel(playerIndex: 1, isRotated: true)
                    .frame(height: geo.size.height / 2)

                // Player 1 mulligan area
                mulliganPanel(playerIndex: 0, isRotated: false)
                    .frame(height: geo.size.height / 2)
            }
        }
        .background(Color.black)
        .onChange(of: game.allMulligansConfirmed) { _, confirmed in
            if confirmed {
                onAllConfirmed()
            }
        }
    }

    @ViewBuilder
    private func mulliganPanel(playerIndex: Int, isRotated: Bool) -> some View {
        let isConfirmed = game.mulligansConfirmed[playerIndex]
        let mulliganCount = game.mulliganCounts[playerIndex]
        let color = DuelPlayerColors.color(for: playerIndex)
        let playerName = game.players[playerIndex].playerName.isEmpty ?
            "Player \(playerIndex + 1)" : game.players[playerIndex].playerName

        ZStack {
            RoundedRectangle(cornerRadius: 0)
                .fill(color.gradient.opacity(0.15))

            VStack(spacing: 16) {
                Text("Game \(gameNumber)")
                    .font(.caption)
                    .foregroundStyle(Color.gray)

                Text(playerName)
                    .font(.title2)
                    .bold()
                    .foregroundStyle(color)

                if mulliganCount > 0 {
                    Text("Mulligans: \(mulliganCount)")
                        .font(.headline)
                        .foregroundStyle(Color.yellow)
                }

                if isConfirmed {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.green)

                        Text("Keeping \(7 - mulliganCount) cards")
                            .font(.headline)
                            .foregroundStyle(Color.green)

                        Text("Waiting for opponent...")
                            .font(.caption)
                            .foregroundStyle(Color.gray)
                    }
                    .transition(.scale.combined(with: .opacity))
                } else {
                    HStack(spacing: 24) {
                        // Mulligan button
                        Button(action: {
                            withAnimation(.spring(duration: 0.3)) {
                                game.recordMulligan(for: playerIndex)
                            }
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: "arrow.counterclockwise.circle.fill")
                                    .font(.system(size: 48))
                                Text("Mulligan")
                                    .font(.headline)
                                Text("Draw \(6 - mulliganCount)")
                                    .font(.caption)
                            }
                            .foregroundStyle(Color.orange)
                            .frame(width: 120, height: 100)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.orange.opacity(0.15))
                            )
                        }
                        .disabled(mulliganCount >= 6)

                        // Keep button
                        Button(action: {
                            withAnimation(.spring(duration: 0.3)) {
                                game.confirmKeep(for: playerIndex)
                            }
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: "hand.thumbsup.circle.fill")
                                    .font(.system(size: 48))
                                Text("Keep")
                                    .font(.headline)
                                Text("\(7 - mulliganCount) cards")
                                    .font(.caption)
                            }
                            .foregroundStyle(Color.green)
                            .frame(width: 120, height: 100)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.green.opacity(0.15))
                            )
                        }
                    }
                }
            }
            .rotationEffect(isRotated ? .degrees(180) : .zero)
        }
    }
}
