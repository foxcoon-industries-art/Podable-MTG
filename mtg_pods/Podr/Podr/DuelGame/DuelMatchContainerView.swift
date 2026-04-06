import SwiftUI
import Podwork


// MARK: - Duel Match Container View
/// Top-level coordinator for the best-of-3 duel match flow.
/// Manages transitions between: preGame -> mulligan -> activeGame -> gameEnd -> betweenGames -> matchComplete
public struct DuelMatchContainerView: View {
    @State var match: DuelMatch
    @State private var phase: DuelMatchPhase = .preGame
    @State private var currentGameTurnHistories: [[DuelTurn]] = []
    @State private var exitToMenu = false

    @EnvironmentObject var dataManager: GameDataManager
    @Environment(\.dismiss) var dismiss

    public init(match: DuelMatch) {
        self._match = State(initialValue: match)
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch phase {
            case .preGame:
                DuelPreGameView(match: match) { firstPlayer in
                    withAnimation(.easeInOut(duration: 0.4)) {
                        let game = match.startGame(firstPlayer: firstPlayer)
                        phase = .mulliganCheck
                    }
                }
                .transition(.asymmetric(insertion: .opacity, removal: .scale(scale: 0.9).combined(with: .opacity)))

            case .mulliganCheck:
                if let game = match.currentGame {
                    DuelMulliganView(
                        game: game,
                        gameNumber: match.currentGameNumber
                    ) {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            phase = .activeGame
                        }
                    }
                    .transition(.opacity)
                }

            case .activeGame:
                if let game = match.currentGame {
                    DuelActiveGameView(
                        game: game,
                        matchScore: match.matchScore,
                        gameNumber: match.currentGameNumber
                    ) {
                        // Game ended
                        let result = game.toDuelGameResult()
                        // Save turn history for this game
                        currentGameTurnHistories.append(game.turnHistory)
                        match.recordGameResult(result)

                        withAnimation(.easeInOut(duration: 0.5)) {
                            phase = .gameEnd
                        }
                    }
                    .transition(.opacity)
                }

            case .gameEnd:
                if let lastGame = match.completedGames.last {
                    DuelEndGameView(
                        gameResult: lastGame,
                        player1Name: match.player1Name,
                        player2Name: match.player2Name,
                        matchScore: match.matchScore,
                        isMatchOver: match.isMatchOver(),
                        onNextGame: {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                phase = .betweenGames
                            }
                        },
                        onMatchComplete: {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                phase = .matchComplete
                            }
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                }

            case .betweenGames:
                DuelBetweenGamesView(match: match) { firstPlayer in
                    if match.startNextGame(firstPlayer: firstPlayer) != nil {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            phase = .mulliganCheck
                        }
                    }
                }
                .transition(.slide)

            case .matchComplete:
                DuelMatchSummaryView(match: match) {
                    exitToMenu = true
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .statusBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .onChange(of: exitToMenu) { _, exit in
            if exit { dismiss() }
        }
    }
}


// MARK: - Match Phase Enum
enum DuelMatchPhase {
    case preGame
    case mulliganCheck
    case activeGame
    case gameEnd
    case betweenGames
    case matchComplete
}
