import SwiftUI
import Podwork


// MARK: - Tournament Round View
/// Shows current round pairings and allows starting games or submitting results.
struct TournamentRoundView: View {
    @State private var manager = TournamentManager.shared
    @State private var showDuelGame = false
    @State private var selectedPairing: TournamentPairingInfo?
    @State private var currentDuelMatch: DuelMatch?

    let onBack: () -> Void

    private var tournament: TournamentInfo? { manager.currentTournament }
    private var pairings: [TournamentPairingInfo] { tournament?.pairings ?? [] }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if showDuelGame, let match = currentDuelMatch {
                DuelMatchContainerView(match: match)
                    .onDisappear {
                        showDuelGame = false
                        // After game ends, submit result
                        if let pairing = selectedPairing, match.matchFinished {
                            submitResult(match: match, pairing: pairing)
                        }
                    }
            } else {
                roundContent
            }
        }
    }

    @ViewBuilder
    private var roundContent: some View {
        VStack(spacing: 20) {
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
            }
            .padding(.horizontal)

            Text("Round \(tournament?.currentRound ?? 0)")
                .font(.title)
                .bold()
                .foregroundStyle(Color.white)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(pairings) { pairing in
                        pairingCard(pairing)
                    }
                }
                .padding(.horizontal)
            }

            Spacer()
        }
    }

    @ViewBuilder
    private func pairingCard(_ pairing: TournamentPairingInfo) -> some View {
        let isMyPairing = pairing.player1ID == manager.playerID || pairing.player2ID == manager.playerID

        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(pairing.player1Name)
                        .font(.headline)
                        .foregroundStyle(Color.white)
                }

                Spacer()

                Text("vs")
                    .font(.caption)
                    .foregroundStyle(Color.gray)

                Spacer()

                VStack(alignment: .trailing) {
                    Text(pairing.player2Name ?? "BYE")
                        .font(.headline)
                        .foregroundStyle(pairing.isBye ? Color.gray : Color.white)
                }
            }

            // Status
            HStack {
                statusIndicator(pairing)
                Spacer()

                if isMyPairing && !pairing.confirmed && !pairing.isBye {
                    Button(action: {
                        startGame(pairing: pairing)
                    }) {
                        Text("Play Game")
                            .font(.caption)
                            .bold()
                            .foregroundStyle(Color.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.green.gradient))
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isMyPairing ? Color.blue.opacity(0.15) : Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isMyPairing ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private func statusIndicator(_ pairing: TournamentPairingInfo) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor(pairing.status))
                .frame(width: 8, height: 8)
            Text(pairing.status.capitalized)
                .font(.caption)
                .foregroundStyle(statusColor(pairing.status))
        }
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "pending": return Color.orange
        case "submitted": return Color.yellow
        case "confirmed": return Color.green
        case "conflict": return Color.red
        default: return Color.gray
        }
    }

    private func startGame(pairing: TournamentPairingInfo) {
        selectedPairing = pairing

        let isPlayer1 = pairing.player1ID == manager.playerID
        let myName = isPlayer1 ? pairing.player1Name : (pairing.player2Name ?? "")
        let oppName = isPlayer1 ? (pairing.player2Name ?? "") : pairing.player1Name

        let match = DuelMatch(
            player1Name: myName,
            player2Name: oppName,
            tournamentID: "\(tournament?.tournamentID ?? 0)"
        )
        currentDuelMatch = match
        showDuelGame = true
    }

    private func submitResult(match: DuelMatch, pairing: TournamentPairingInfo) {
        guard let playerID = manager.playerID,
              let opponentID = pairing.player1ID == playerID ? pairing.player2ID : Optional(pairing.player1ID)
        else { return }

        let isPlayer1 = pairing.player1ID == playerID
        let myWins = isPlayer1 ? match.matchScore[0] : match.matchScore[1]
        let myLosses = isPlayer1 ? match.matchScore[1] : match.matchScore[0]

        let gameDetails = match.completedGames.map { game in
            GameSubmissionDetail(
                gameNumber: game.gameNumber,
                winnerPlayerIndex: game.winnerPlayerIndex,
                finalLifeP1: game.finalLifeTotals[0],
                finalLifeP2: game.finalLifeTotals[1],
                turnCount: game.turnCount
            )
        }

        Task {
            do {
                try await manager.submitGameResult(
                    roundNumber: tournament?.currentRound ?? 0,
                    opponentID: opponentID,
                    matchWins: myWins,
                    matchLosses: myLosses,
                    gameDetails: gameDetails
                )
            } catch {
                print("Failed to submit result: \(error)")
            }
        }
    }
}
