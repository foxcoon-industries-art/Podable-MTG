import SwiftUI
import Podwork


// MARK: - Tournament Lobby View
/// Waiting room showing tournament code, player list, and round management.
struct TournamentLobbyView: View {
    @State private var manager = TournamentManager.shared
    @State private var showRoundView = false
    @State private var showStandings = false
    @State private var isStartingRound = false
    @State private var errorMessage: String?

    let onBack: () -> Void

    private var tournament: TournamentInfo? { manager.currentTournament }
    private var isOrganizer: Bool {
        // The organizer is the device that created the tournament
        tournament != nil
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if showStandings {
                TournamentStandingsView(onBack: { showStandings = false })
            } else if showRoundView {
                TournamentRoundView(onBack: {
                    showRoundView = false
                    Task { await manager.refreshStatus() }
                })
            } else {
                lobbyContent
            }
        }
        .onAppear {
            manager.startPolling(interval: 5.0)
        }
        .onDisappear {
            manager.stopPolling()
        }
    }

    @ViewBuilder
    private var lobbyContent: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Leave")
                    }
                    .foregroundStyle(Color.red)
                }
                Spacer()

                Button(action: { showStandings = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "list.number")
                        Text("Standings")
                    }
                    .foregroundStyle(Color.white)
                }
            }
            .padding(.horizontal)

            // Tournament info
            if let tournament = tournament {
                VStack(spacing: 8) {
                    Text(tournament.name)
                        .font(.title)
                        .bold()
                        .foregroundStyle(Color.white)

                    // Join code
                    VStack(spacing: 4) {
                        Text("Join Code")
                            .font(.caption)
                            .foregroundStyle(Color.gray)
                        Text(tournament.code)
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.yellow)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.yellow.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }

                    Text("Round \(tournament.currentRound)")
                        .font(.subheadline)
                        .foregroundStyle(Color.gray)

                    statusBadge(tournament.status)
                }

                Divider()
                    .background(Color.gray.opacity(0.3))

                // Players list
                VStack(alignment: .leading, spacing: 8) {
                    Text("Players (\(tournament.players.count))")
                        .font(.headline)
                        .foregroundStyle(Color.white)

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(tournament.players) { player in
                                HStack {
                                    Circle()
                                        .fill(player.isDeviceOwner ? Color.green : Color.orange)
                                        .frame(width: 10, height: 10)
                                    Text(player.playerName)
                                        .foregroundStyle(Color.white)
                                    Spacer()
                                    Text("\(player.points) pts")
                                        .font(.caption)
                                        .foregroundStyle(Color.gray)
                                    if !player.isDeviceOwner {
                                        Image(systemName: "iphone.slash")
                                            .font(.caption)
                                            .foregroundStyle(Color.orange)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.1))
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal)

                // Error
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Color.red)
                }

                Spacer()

                // Actions
                VStack(spacing: 12) {
                    if tournament.status == "lobby" || tournament.status == "active" {
                        Button(action: startNextRound) {
                            if isStartingRound {
                                ProgressView().tint(Color.black)
                            } else {
                                Text(tournament.currentRound == 0 ? "Start Round 1" : "Start Next Round")
                                    .bold()
                            }
                        }
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(Color.green.gradient))
                        .padding(.horizontal, 32)
                        .disabled(tournament.players.count < 2 || isStartingRound)

                        if tournament.currentRound > 0 {
                            Button(action: { showRoundView = true }) {
                                Text("View Current Round")
                                    .bold()
                            }
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Capsule().fill(Color.blue.gradient))
                            .padding(.horizontal, 32)
                        }
                    }

                    if tournament.status == "active" {
                        Button(action: closeTournament) {
                            Text("End Tournament")
                                .bold()
                                .foregroundStyle(Color.red)
                        }
                        .padding(.horizontal, 32)
                    }
                }
                .padding(.bottom, 20)
            } else {
                Spacer()
                ProgressView("Loading...")
                    .foregroundStyle(Color.white)
                Spacer()
            }
        }
    }

    @ViewBuilder
    private func statusBadge(_ status: String) -> some View {
        let color: Color = {
            switch status {
            case "lobby": return Color.orange
            case "active": return Color.green
            case "completed": return Color.gray
            default: return Color.gray
            }
        }()

        Text(status.capitalized)
            .font(.caption)
            .bold()
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Capsule().fill(color.opacity(0.2)))
    }

    private func startNextRound() {
        isStartingRound = true
        errorMessage = nil
        Task {
            do {
                let _ = try await manager.startRound()
                showRoundView = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isStartingRound = false
        }
    }

    private func closeTournament() {
        Task {
            do {
                try await manager.closeTournament()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
