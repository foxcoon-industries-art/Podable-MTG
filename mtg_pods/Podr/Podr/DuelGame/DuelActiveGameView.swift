import SwiftUI
import Podwork


// MARK: - Duel Active Game View
/// Core gameplay screen for a single 60-card game within a match.
/// Two player panels (top rotated 180, bottom normal) with center controls.
struct DuelActiveGameView: View {
    @Bindable var game: DuelGameState
    let matchScore: [Int]
    let gameNumber: Int
    let onGameEnd: () -> Void

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // Player 2 (top, rotated)
                DuelPlayerPanel(
                    game: game,
                    playerIndex: 1,
                    isRotated: true
                )
                .frame(height: (geo.size.height - 100) / 2)

                // Center control bar
                DuelCenterBar(
                    game: game,
                    matchScore: matchScore,
                    gameNumber: gameNumber,
                    onNextTurn: passTurn,
                    onUndo: undoTurn,
                    onConcede: concede
                )
                .frame(height: 100)
                .padding(.horizontal, 8)

                // Player 1 (bottom, normal)
                DuelPlayerPanel(
                    game: game,
                    playerIndex: 0,
                    isRotated: false
                )
                .frame(height: (geo.size.height - 100) / 2)
            }
        }
        .background(Color.black)
        .onChange(of: game.finished) { _, finished in
            if finished {
                onGameEnd()
            }
        }
    }

    private func passTurn() {
        withAnimation(.easeInOut(duration: 0.3)) {
            game.nextTurn()
        }
    }

    private func undoTurn() {
        withAnimation(.easeInOut(duration: 0.3)) {
            game.resetTurn()
        }
    }

    private func concede(playerIndex: Int) {
        game.playerConceded(who: playerIndex)
    }
}
