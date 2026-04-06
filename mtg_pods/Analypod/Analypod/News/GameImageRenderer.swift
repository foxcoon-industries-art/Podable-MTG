import SwiftUI
import Podwork


// MARK: - Visualization Types Available for Article Images

public enum GameVisualizationType: String, CaseIterable, Identifiable {
    case podFlowMap = "Pod Flow Map"
    case turnTimePie = "Turn Time Chart"
    case companionCube = "Companion Cube"
    case gameOverview = "Game Overview"

    public var id: String { rawValue }

    public var systemImage: String {
        switch self {
        case .podFlowMap: return "square.grid.3x3.fill"
        case .turnTimePie: return "chart.pie.fill"
        case .companionCube: return "cube.fill"
        case .gameOverview: return "list.bullet.rectangle.portrait"
        }
    }

    public var description: String {
        switch self {
        case .podFlowMap: return "Turn-by-turn game flow heatmap"
        case .turnTimePie: return "Time spent per player pie chart"
        case .companionCube: return "Commander damage distribution"
        case .gameOverview: return "Game summary with commanders and result"
        }
    }
}


// MARK: - Renderer

@MainActor
public struct GameImageRenderer {

    /// Render a visualization type for the given game data as a UIImage
    public static func render(
        type: GameVisualizationType,
        game: FinalPod,
        turns: [Turn],
        size: CGSize = CGSize(width: 400, height: 400)
    ) -> UIImage {
        let view: AnyView

        switch type {
        case .podFlowMap:
            let card = OptimizedGameFlowCard(
                game: game,
                turnHistory: turns,
                on_Appear: {},
                isRotated: false,
                exportPod: true
            )
            view = AnyView(
                card
                    .frame(width: size.width, height: size.height)
                    .background(Color(.systemBackground))
            )

        case .turnTimePie:
            let chartData = PlayerTurnTimeChartData.chartDataFromCommanders(
                game.commanders.rePartner.sorted { $0.turnOrder < $1.turnOrder }
            )
            let pieChart = TurnTimePieChart(
                data: chartData,
                selectedSector: .constant(nil)
            )
            view = AnyView(
                pieChart
                    .frame(width: size.width, height: size.height)
                    .background(Color(.systemBackground))
            )

        case .companionCube:
            let damageMatrix = turns.aggregatedCmdrDamageAsDoubles()
            let chartData = PlayerChartData(damageMatrix: damageMatrix)
            let cube = CommanderCompanionCube(data: chartData)
            view = AnyView(
                cube
                    .frame(width: size.width, height: size.height)
                    .background(Color(.systemBackground))
            )

        case .gameOverview:
            let overview = GameOverviewCard(game: game)
            view = AnyView(
                overview
                    .frame(width: size.width, height: size.height)
                    .background(Color(.systemBackground))
            )
        }

        return view.snapshot()
    }

    /// Render all available visualization types as thumbnails
    public static func renderThumbnails(
        game: FinalPod,
        turns: [Turn],
        thumbSize: CGSize = CGSize(width: 200, height: 200)
    ) -> [(type: GameVisualizationType, image: UIImage)] {
        GameVisualizationType.allCases.map { type in
            (type: type, image: render(type: type, game: game, turns: turns, size: thumbSize))
        }
    }
}


// MARK: - Game Overview Card (simple text-based summary)

struct GameOverviewCard: View {
    let game: FinalPod

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Game Summary")
                .font(.title2)
                .fontWeight(.bold)

            Divider()

            // Commanders
            ForEach(game.commanders.rePartner.sorted(by: { $0.turnOrder < $1.turnOrder }),
                    id: \.turnOrder) { cmdr in
                HStack(spacing: 8) {
                    Circle()
                        .fill(getColor(for: cmdr.turnOrder))
                        .frame(width: 12, height: 12)

                    Text(cmdr.displayNames)
                        .font(.subheadline)
                        .fontWeight(cmdr.winner ? .bold : .regular)

                    Spacer()

                    if cmdr.winner {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    } else if cmdr.eliminated {
                        Text(cmdr.eliminationMethod.emojiOverlay)
                            .font(.caption)
                    }
                }
            }

            Divider()

            HStack {
                Label("\(game.totalRounds) rounds", systemImage: "arrow.triangle.2.circlepath")
                    .font(.caption)
                Spacer()
                Label(game.formattedDuration, systemImage: "clock")
                    .font(.caption)
            }

            if let winner = game.winningCommander {
                Text("Won by: \(game.winMethod)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}
