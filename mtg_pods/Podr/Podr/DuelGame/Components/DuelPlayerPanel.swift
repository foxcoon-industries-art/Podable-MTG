import SwiftUI
import Podwork


// MARK: - Duel Player Panel
/// Displays one player's life total, infect counter, name, and deck tag.
/// Used as the top or bottom half of the DuelActiveGameView.
struct DuelPlayerPanel: View {
    @Bindable var game: DuelGameState
    let playerIndex: Int
    let isRotated: Bool

    private var player: DuelPlayer { game.players[playerIndex] }
    private var isActive: Bool { game.activePlayer() == playerIndex }
    private var displayLife: Int { game.currentLife(for: playerIndex) }
    private var displayInfect: Int { game.currentInfect(for: playerIndex) }
    private var deltaLife: Int { game.showDeltaLife(for: playerIndex) }
    private var deltaInfect: Int { game.showDeltaInfect(for: playerIndex) }
    private var slotColor: Color { DuelPlayerColors.color(for: playerIndex) }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 16)
                    .fill(slotColor.gradient.opacity(isActive ? 0.4 : 0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isActive ? slotColor : Color.gray.opacity(0.3), lineWidth: isActive ? 3 : 1)
                    )

                VStack(spacing: 8) {
                    // Player info
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(player.playerName.isEmpty ? DuelSlot(rawValue: playerIndex)!.description : player.playerName)
                                .font(.headline)
                                .foregroundStyle(Color.white)
                            if !player.deckTag.isEmpty {
                                Text(player.deckTag)
                                    .font(.caption)
                                    .foregroundStyle(Color.gray)
                            }
                        }

                        Spacer()

                        // Mulligan badge
                        if game.mulliganCounts[playerIndex] > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.caption2)
                                Text("\(game.mulliganCounts[playerIndex])")
                                    .font(.caption)
                                    .bold()
                            }
                            .foregroundStyle(Color.yellow)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.yellow.opacity(0.2)))
                        }

                        // Infect badge
                        if displayInfect > 0 {
                            HStack(spacing: 4) {
                                Text("φ: \(displayInfect)")
                                    .font(.headline)
                                    .bold()
                            }
                            .foregroundStyle(Color.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.green.opacity(0.2)))
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer()

                    // Life total
                    HStack(spacing: 30) {
                        // Minus button
                        Button(action: { game.applyLifeChange(to: playerIndex, amount: -1) }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(Color.red.gradient)
                        }

                        VStack(spacing: 0) {
                            Text("\(displayLife)")
                                .font(.system(size: 72, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.white)
                                .contentTransition(.numericText())
                                .animation(.snappy, value: displayLife)

                            // Delta indicator
                            if deltaLife != 0 {
                                Text(deltaLife > 0 ? "+\(deltaLife)" : "\(deltaLife)")
                                    .font(.title3)
                                    .foregroundStyle(deltaLife > 0 ? Color.green : Color.red)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }

                        // Plus button
                        Button(action: { game.applyLifeChange(to: playerIndex, amount: 1) }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(Color.green.gradient)
                        }
                    }

                    Spacer()

                    // Infect controls (smaller)
                    HStack(spacing: 20) {
                        Button(action: { game.applyInfect(to: playerIndex, amount: -1) }) {
                            HStack(spacing: 4) {
                                Image(systemName: "minus")
                                Image(systemName: "biohazard")
                            }
                            .font(.caption)
                            .foregroundStyle(Color.green.opacity(0.7))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.green.opacity(0.1)))
                        }

                        Button(action: { game.applyInfect(to: playerIndex, amount: 1) }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                Image(systemName: "biohazard")
                            }
                            .font(.caption)
                            .foregroundStyle(Color.green.opacity(0.7))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.green.opacity(0.1)))
                        }
                    }
                }
                .padding(.vertical, 12)

                // Eliminated overlay
                if player.eliminated {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.6))
                    Text("ELIMINATED")
                        .font(.title2)
                        .bold()
                        .foregroundStyle(Color.red)
                }
            }
            .rotationEffect(isRotated ? .degrees(180) : .zero)
        }
    }
}
