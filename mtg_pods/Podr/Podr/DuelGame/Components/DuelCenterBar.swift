import SwiftUI
import Podwork


// MARK: - Duel Center Bar
/// Center control bar between the two player panels.
/// Handles turn advancement, undo, concession, and displays turn/match info.
struct DuelCenterBar: View {
    @Bindable var game: DuelGameState
    let matchScore: [Int]
    let gameNumber: Int
    let onNextTurn: () -> Void
    let onUndo: () -> Void
    let onConcede: (Int) -> Void

    @State private var showConcedeAlert = false
    @State private var concedePlayerIndex: Int = 0

    var body: some View {
        HStack(spacing: 0) {
            // Left: Match info
            VStack(alignment: .leading, spacing: 2) {
                Text("Game \(gameNumber)")
                    .font(.caption)
                    .foregroundStyle(Color.gray)
                Text("\(matchScore[0]) - \(matchScore[1])")
                    .font(.title3)
                    .bold()
                    .foregroundStyle(Color.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 16)

            // Center: Turn controls
            VStack(spacing: 4) {
                // Turn number
                Text("Turn \(game.currentActivePlayerTurnNumber)")
                    .font(.caption2)
                    .foregroundStyle(Color.gray)
                
                // Pass turn button
                Button(action: onNextTurn ) {
                    ZStack {
                        Circle()
                            .fill(DuelPlayerColors.color(for: game.activePlayer()).gradient)
                            .frame(width: 56, height: 56)
                            .shadow(color: DuelPlayerColors.color(for: game.activePlayer()).opacity(0.5), radius: 8)

                        Image(systemName: game.activePlayer() == 0 ? "arrow.down.circle.fill" :  "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.white)
                    }
                }

                Text("Pass Turn")
                    .font(.caption2)
                    .foregroundStyle(Color.gray)
            }

            // Right: Undo & Concede
            VStack(alignment: .trailing, spacing: 8) {
                Button(action: onUndo) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.uturn.backward")
                        Text("Undo")
                    }
                    .font(.caption)
                    .foregroundStyle(Color.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.orange.opacity(0.15)))
                }
                .disabled(game.turnHistory.isEmpty)
                .opacity(game.turnHistory.isEmpty ? 0.4 : 1.0)

                Button(action: {
                    concedePlayerIndex = game.activePlayer()
                    showConcedeAlert = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "flag.fill")
                        Text("Concede")
                    }
                    .font(.caption)
                    .foregroundStyle(Color.red)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.red.opacity(0.15)))
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 16)
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
        .alert("Concede Game?", isPresented: $showConcedeAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Concede", role: .destructive) {
                onConcede(concedePlayerIndex)
            }
        } message: {
            Text("\(game.players[concedePlayerIndex].playerName.isEmpty ? "Player \(concedePlayerIndex + 1)" : game.players[concedePlayerIndex].playerName) will concede this game.")
        }
    }
}
