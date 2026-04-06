import SwiftUI
import Podwork


// MARK: - Duel Pre-Game View
/// Pre-match setup: enter player names, deck tags, notes, and select first player.
struct DuelPreGameView: View {
    @Bindable var match: DuelMatch
    let onStart: (Int) -> Void

    @State private var firstPlayer: Int? = nil
    @State private var isRandomizing = false
    @State private var randomHighlight: Int = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Title
                    VStack(spacing: 12) {
                        Text("60-Card Duel")
                            .font(.largeTitle)
                            .bold()
                            .foregroundStyle(Color.white)
                            .padding(.top, 20)
                        
                        Text("Best of 3")
                            .font(.title3)
                            .foregroundStyle(Color.gray)
                    }
                    // Player 1 Card
                    playerInfoCard(
                        playerIndex: 0,
                        name: $match.player1Name,
                        deckTag: $match.player1DeckTag,
                        notes: $match.player1Notes,
                        color: DuelPlayerColors.color(for: 0)
                    )

                    Text("VS")
                        .font(.title2)
                        .bold()
                        .foregroundStyle(Color.gray)

                    // Player 2 Card
                    playerInfoCard(
                        playerIndex: 1,
                        name: $match.player2Name,
                        deckTag: $match.player2DeckTag,
                        notes: $match.player2Notes,
                        color: DuelPlayerColors.color(for: 1)
                    )

                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.horizontal)

                    // First Player Selection
                    VStack(spacing: 16) {
                        Text("Who Goes First?")
                            .font(.headline)
                            .foregroundStyle(Color.white)

                        HStack(spacing: 16) {
                            // Player 1 button
                            firstPlayerButton(playerIndex: 0)
                            // Player 2 button
                            firstPlayerButton(playerIndex: 1)
                        }
                        .padding(.horizontal)

                        // Random button
                        Button(action: randomizeFirstPlayer) {
                            HStack(spacing: 8) {
                                Image(systemName: "dice.fill")
                                Text("Randomize")
                            }
                            .font(.headline)
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(Color.purple.gradient))
                        }
                        .disabled(isRandomizing)
                    }

                    // Start button
                    if let fp = firstPlayer {
                        Button(action: { onStart(fp) }) {
                            Text("Start Match")
                                .font(.title2)
                                .bold()
                                .foregroundStyle(Color.black)
                                .padding(.horizontal, 40)
                                .padding(.vertical, 14)
                                .background(Capsule().fill(Color.white.gradient))
                        }
                        .transition(.scale.combined(with: .opacity))
                        .padding(.bottom, 30)
                    }
                }
                .padding()
            }
        }
    }

    @ViewBuilder
    private func playerInfoCard(playerIndex: Int, name: Binding<String>, deckTag: Binding<String>, notes: Binding<String>, color: Color) -> some View {
        VStack(spacing: 12) {
            HStack {
                Circle()
                    .fill(color.gradient)
                    .frame(width: 20, height: 20)
                Text("Player \(playerIndex + 1)")
                    .font(.headline)
                    .foregroundStyle(color)
                Spacer()
            }

            TextField("Player Name", text: name)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()

            TextField("Deck Name / Tag", text: deckTag)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()

            TextField("Notes (optional)", text: notes)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }

    @ViewBuilder
    private func firstPlayerButton(playerIndex: Int) -> some View {
        let isSelected = firstPlayer == playerIndex
        let isHighlighted = isRandomizing && randomHighlight == playerIndex
        let color = DuelPlayerColors.color(for: playerIndex)
        let displayName = playerIndex == 0 ?
            (match.player1Name.isEmpty ? "Player 1" : match.player1Name) :
            (match.player2Name.isEmpty ? "Player 2" : match.player2Name)

        Button(action: {
            withAnimation(.spring(duration: 0.3)) {
                firstPlayer = playerIndex
            }
        }) {
            Text(displayName)
                .font(.headline)
                .foregroundStyle(isSelected ? Color.black : Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? color : color.opacity(0.2))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isHighlighted ? Color.yellow : color, lineWidth: isHighlighted ? 3 : 1)
                )
        }
        .disabled(isRandomizing)
    }

    private func randomizeFirstPlayer() {
        isRandomizing = true
        var count = 0
        let totalFlips = 12
        let baseInterval: TimeInterval = 0.08

        Timer.scheduledTimer(withTimeInterval: baseInterval, repeats: true) { timer in
            withAnimation(.easeInOut(duration: 0.08)) {
               // randomHighlight = count % 2
            }
            count += 1
            randomHighlight = count % 2

            if count >= totalFlips {
                timer.invalidate()
                let chosen = Int.random(in: 0...1)
                withAnimation(.spring(duration: 0.5)) {
                    firstPlayer = chosen
                    randomHighlight = chosen
                    isRandomizing = false
                }
            }
        }
    }
}
