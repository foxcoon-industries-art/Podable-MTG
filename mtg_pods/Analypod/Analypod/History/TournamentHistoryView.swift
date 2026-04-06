import SwiftUI
import Podwork


// MARK: - Tournament History View
/// List of past tournaments with expandable details.
public struct TournamentHistoryView: View {
    @EnvironmentObject var dataManager: GameDataManager
    @State private var expandedTournamentID: String?

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tournaments")
                .font(.title2)
                .bold()
                .foregroundStyle(Color.white)
                .padding(.horizontal)

            if dataManager.tournaments.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.gray.opacity(0.5))
                    Text("No tournaments played yet")
                        .font(.subheadline)
                        .foregroundStyle(Color.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(dataManager.tournaments) { tournament in
                            tournamentRow(tournament)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    @ViewBuilder
    private func tournamentRow(_ tournament: TournamentRecord) -> some View {
        let isExpanded = expandedTournamentID == tournament.tournamentID

        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    expandedTournamentID = isExpanded ? nil : tournament.tournamentID
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tournament.name)
                            .font(.headline)
                            .foregroundStyle(Color.yellow)

                        HStack(spacing: 8) {
                            Text("\(tournament.playerCount) players")
                                .font(.caption)
                                .foregroundStyle(Color.gray)
                            Text("\(tournament.roundCount) rounds")
                                .font(.caption)
                                .foregroundStyle(Color.gray)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(tournament.formattedDate)
                            .font(.caption)
                            .foregroundStyle(Color.gray)

                        Text(tournament.status.capitalized)
                            .font(.caption2)
                            .foregroundStyle(tournament.status == "completed" ? Color.green : Color.orange)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(Color.gray)
                }
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                        .background(Color.gray.opacity(0.3))

                    // Final standings
                    if !tournament.finalStandings.isEmpty {
                        Text("Final Standings")
                            .font(.caption)
                            .bold()
                            .foregroundStyle(Color.white)

                        ForEach(tournament.finalStandings) { standing in
                            HStack {
                                Text("#\(standing.rank)")
                                    .font(.caption)
                                    .foregroundStyle(standing.rank <= 3 ? Color.yellow : Color.gray)
                                    .frame(width: 30)
                                Text(standing.playerName)
                                    .font(.caption)
                                    .foregroundStyle(Color.white)
                                Spacer()
                                Text("\(standing.points) pts")
                                    .font(.caption)
                                    .foregroundStyle(Color.gray)
                                Text(standing.record)
                                    .font(.caption2)
                                    .foregroundStyle(Color.gray)
                            }
                        }
                    }

                    // Round entries
                    if !tournament.entries.isEmpty {
                        Text("Matches")
                            .font(.caption)
                            .bold()
                            .foregroundStyle(Color.white)
                            .padding(.top, 4)

                        let groupedByRound = Dictionary(grouping: tournament.entries) { $0.roundNumber }
                        let sortedRounds = groupedByRound.keys.sorted()

                        ForEach(sortedRounds, id: \.self) { round in
                            Text("Round \(round)")
                                .font(.caption2)
                                .foregroundStyle(Color.gray)

                            if let entries = groupedByRound[round] {
                                ForEach(entries.indices, id: \.self) { index in
                                    let entry = entries[index]
                                    HStack {
                                        Text(entry.player1Name)
                                            .font(.caption2)
                                            .foregroundStyle(Color.white)
                                        Text("vs")
                                            .font(.caption2)
                                            .foregroundStyle(Color.gray)
                                        Text(entry.player2Name)
                                            .font(.caption2)
                                            .foregroundStyle(Color.white)
                                        Spacer()
                                        Text(entry.result)
                                            .font(.caption2)
                                            .foregroundStyle(Color.gray)
                                    }
                                }
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }
}
