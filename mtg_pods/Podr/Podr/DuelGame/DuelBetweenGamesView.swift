import SwiftUI
import Podwork


// MARK: - Duel Between Games View
/// Shown between games in a best-of-3 match. Allows selecting first player for the next game.
//@MainActor
struct DuelBetweenGamesView: View {
    @Bindable var match: DuelMatch
    let onStartNextGame: (Int) -> Void

    @State private var nextFirstPlayer: Int? = nil
    @State private var isRandomizing = false
    @State private var randomHighlight: Int = 0

    private var lastGameLoser: Int? { match.lastGameLoser }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Match score
                Text("Match Score")
                    .font(.headline)
                    .foregroundStyle(Color.gray)

                HStack(spacing: 30) {
                    VStack(spacing: 4) {
                        Text(match.player1Name.isEmpty ? "Player 1" : match.player1Name)
                            .font(.subheadline)
                            .foregroundStyle(DuelPlayerColors.color(for: 0))
                        Text("\(match.matchScore[0])")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.white)
                    }

                    Text("-")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.gray)

                    VStack(spacing: 4) {
                        Text(match.player2Name.isEmpty ? "Player 2" : match.player2Name)
                            .font(.subheadline)
                            .foregroundStyle(DuelPlayerColors.color(for: 1))
                        Text("\(match.matchScore[1])")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.white)
                    }
                }

                Divider()
                    .background(Color.gray.opacity(0.3))
                    .padding(.horizontal, 40)

                // Next game first player selection
                VStack(spacing: 16) {
                    Text("Game \(match.currentGameNumber + 1)")
                        .font(.title2)
                        .bold()
                        .foregroundStyle(Color.white)

                    Text("Who goes first?")
                        .font(.subheadline)
                        .foregroundStyle(Color.gray)

                    if let loser = lastGameLoser {
                        Text("(Loser of last game typically chooses)")
                            .font(.caption)
                            .foregroundStyle(Color.gray.opacity(0.7))
                    }

                    HStack(spacing: 16) {
                        firstPlayerButton(playerIndex: 0)
                        firstPlayerButton(playerIndex: 1)
                    }
                    .padding(.horizontal)

                    Button(action: randomize) {
                        HStack(spacing: 8) {
                            Image(systemName: "dice.fill")
                            Text("Random")
                        }
                        .font(.headline)
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Color.purple.gradient))
                    }
                    .disabled(isRandomizing)
                }

                Spacer()

                // Start button
                if let fp = nextFirstPlayer {
                    Button(action: { onStartNextGame(fp) }) {
                        Text("Start Game \(match.currentGameNumber + 1)")
                            .font(.title3)
                            .bold()
                            .foregroundStyle(Color.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Capsule().fill(Color.white.gradient))
                    }
                    .padding(.horizontal, 32)
                    .transition(.scale.combined(with: .opacity))
                }

                Spacer()
                    .frame(height: 30)
            }
        }
    }

    @ViewBuilder
    private func firstPlayerButton(playerIndex: Int) -> some View {
        let isSelected = nextFirstPlayer == playerIndex
        let isHighlighted = isRandomizing && randomHighlight == playerIndex
        let color = DuelPlayerColors.color(for: playerIndex)
        let displayName = match.playerName(for: playerIndex)

        Button(action: {
            withAnimation(.spring(duration: 0.3)) {
                nextFirstPlayer = playerIndex
            }
        }) {
            Text(displayName.isEmpty ? "Player \(playerIndex + 1)" : displayName)
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

    @State var count = 0
    //@MainActor
    private func randomize() {
        isRandomizing = true
        count = 0
        let totalFlips = 12
        
        for count in 0..<totalFlips {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(count) * 0.1) {
                withAnimation(.easeInOut(duration: 0.08)) {
                    self.count += 1
                    randomHighlight = count % 2
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(totalFlips+1) * 0.1) {
            withAnimation(.easeInOut(duration: 0.08)) {
                let chosen = Int.random(in: 0...1)
                nextFirstPlayer = chosen
                randomHighlight = chosen
                isRandomizing = false
            }
        }
        /*
        Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { timer in
            withAnimation(.easeInOut(duration: 0.08)) {
                //  randomHighlight = count % 2
                
                self.count += 1
                randomHighlight = count % 2
            }
          

            if count >= totalFlips {
                timer.invalidate()
                let chosen = Int.random(in: 0...1)
                withAnimation(.spring(duration: 0.5)) {
                    nextFirstPlayer = chosen
                    randomHighlight = chosen
                    isRandomizing = false
                }
            }
            
        }
        */
    }
}
