import SwiftUI
import Podwork


// MARK: - Tournament Standings View
/// Displays live tournament standings with rank, record, and tiebreakers.
struct TournamentStandingsView: View {
    @State private var manager = TournamentManager.shared
    @State private var standings: [TournamentStandingInfo] = []
    @State private var isLoading = false

    let onBack: () -> Void

    private var tournament: TournamentInfo? { manager.currentTournament }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 16) {
                // Header
                HStack {
                    Button(action: onBack) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundStyle(Color.white)
                    }
                    Spacer()

                    Button(action: loadStandings) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(Color.white)
                    }
                }
                .padding(.horizontal)

                Text("Standings")
                    .font(.title)
                    .bold()
                    .foregroundStyle(Color.white)

                if let tournament = tournament {
                    Text("\(tournament.name) - Round \(tournament.currentRound)")
                        .font(.subheadline)
                        .foregroundStyle(Color.gray)
                }

                // Column headers
                HStack {
                    Text("#")
                        .frame(width: 30, alignment: .center)
                    Text("Player")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Pts")
                        .frame(width: 35, alignment: .center)
                    Text("Record")
                        .frame(width: 60, alignment: .center)
                    Text("OMW%")
                        .frame(width: 50, alignment: .trailing)
                }
                .font(.caption)
                .bold()
                .foregroundStyle(Color.gray)
                .padding(.horizontal)

                Divider()
                    .background(Color.gray.opacity(0.3))

                if isLoading {
                    ProgressView()
                        .tint(Color.white)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 4) {
                            ForEach(standings) { standing in
                                standingRow(standing)
                            }
                        }
                    }
                }

                Spacer()
            }
        }
        .onAppear {
            loadStandings()
        }
    }

    @ViewBuilder
    private func standingRow(_ standing: TournamentStandingInfo) -> some View {
        let isMe = standing.playerID == manager.playerID

        HStack {
            Text("\(standing.rank)")
                .frame(width: 30, alignment: .center)
                .foregroundStyle(standing.rank <= 3 ? Color.yellow : Color.white)

            Text(standing.playerName)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(isMe ? Color.cyan : Color.white)
                .bold(isMe)

            Text("\(standing.points)")
                .frame(width: 35, alignment: .center)
                .foregroundStyle(Color.white)

            Text(standing.record)
                .frame(width: 60, alignment: .center)
                .foregroundStyle(Color.gray)

            Text(String(format: "%.1f%%", standing.opponentMatchWinPct * 100))
                .frame(width: 50, alignment: .trailing)
                .foregroundStyle(Color.gray)
        }
        .font(.subheadline)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isMe ? Color.cyan.opacity(0.1) : Color.clear)
        )
    }

    private func loadStandings() {
        isLoading = true
        Task {
            do {
                standings = try await manager.getStandings()
            } catch {
                // Fall back to tournament info standings
                standings = tournament?.standings?.map { info in
                    TournamentStandingInfo(
                        rank: info.rank,
                        playerID: info.playerID,
                        playerName: info.playerName,
                        points: info.points,
                        wins: info.wins,
                        losses: info.losses,
                        draws: info.draws,
                        opponentMatchWinPct: info.opponentMatchWinPct,
                        gameWinPct: info.gameWinPct
                    )
                } ?? []
            }
            isLoading = false
        }
    }
}
