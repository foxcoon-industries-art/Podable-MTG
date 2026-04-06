import SwiftUI
import Podwork


struct GameStoryPickerView: View {
    @StateObject private var dataManager = GameDataManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedGame: FinalPod?
    @State private var loadedTurns: [Turn]?
    @State private var showStoryBuilder = false
    @State private var isLoadingTurns = false

    var body: some View {
        NavigationView {
            Group {
                if dataManager.finalStates.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "gamecontroller")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.secondary.opacity(0.5))

                        Text("No Completed Games")
                            .font(.headline)

                        Text("Play a Commander game first, then come back to write a story about it.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(sortedGames, id: \.gameID) { game in
                                gameRow(game)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Select a Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay {
                if isLoadingTurns {
                    ProgressView("Loading game data...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                }
            }
            .sheet(isPresented: $showStoryBuilder) {
                if let game = selectedGame, let turns = loadedTurns {
                    GameStoryBuilderView(game: game, turns: turns)
                }
            }
            .onAppear {
                dataManager.refreshAllData()
            }
        }
    }

    private var sortedGames: [FinalPod] {
        dataManager.finalStates.sorted { $0.date > $1.date }
    }

    @ViewBuilder
    private func gameRow(_ game: FinalPod) -> some View {
        Button {
            loadGameAndPresent(game)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // Commander names row
                HStack(spacing: 6) {
                    ForEach(game.commanders.rePartner.sorted(by: { $0.turnOrder < $1.turnOrder }),
                            id: \.turnOrder) { cmdr in
                        HStack(spacing: 3) {
                            Circle()
                                .fill(getColor(for: cmdr.turnOrder))
                                .frame(width: 8, height: 8)
                            Text(String(cmdr.name.prefix(10)))
                                .font(.caption)
                                .lineLimit(1)
                                .foregroundColor(cmdr.winner ? .primary : .secondary)
                                .fontWeight(cmdr.winner ? .bold : .regular)
                        }
                    }
                }

                HStack {
                    // Winner
                    if let winner = game.winningCommander {
                        Label(String(winner.name.prefix(15)), systemImage: "crown.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }

                    Spacer()

                    // Date
                    Text(game.formattedDate)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Label("\(game.totalRounds) rds", systemImage: "arrow.triangle.2.circlepath")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Label(game.formattedDuration, systemImage: "clock")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(game.winMethod)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    private func loadGameAndPresent(_ game: FinalPod) {
        isLoadingTurns = true
        selectedGame = game

        Task {
            let turns = await dataManager.loadTurnHistory(for: game.gameID)
            await MainActor.run {
                loadedTurns = turns
                isLoadingTurns = false
                if !turns.isEmpty {
                    showStoryBuilder = true
                }
            }
        }
    }
}
