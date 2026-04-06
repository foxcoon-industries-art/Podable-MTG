/*
import SwiftUI
import Charts
/**/

// MARK: - Data Models
fileprivate class Turn {
    let turnNumber: Int
    let deltaLife: [String: Int] // Player name to life change
    
    init(turnNumber: Int, deltaLife: [String: Int]) {
        self.turnNumber = turnNumber
        self.deltaLife = deltaLife
    }
}

struct PlayerLifeRange: Identifiable {
    let id = UUID()
    let playerName: String
    let minLife: Int
    let maxLife: Int
    let currentLife: Int
}

// MARK: - Life Chart View
struct LifeRangeChart: View {
    fileprivate let turns: [Turn]
    let selectedTurn: Int?
    
    private let startingLife = 40
    private let chartAspectRatio: CGFloat = 1.2
    
    var playerLifeRanges: [PlayerLifeRange] {
        calculateLifeRanges()
    }
    
    var body: some View {
        Chart {
            
            RuleMark(y: .value("Starting Life", startingLife))
                .foregroundStyle(.yellow.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 5, dash: [0, 0]))
            
            ForEach(playerLifeRanges) { playerData in
                // Bar from minimum to maximum life
                BarMark(
                    x: .value("Player", playerData.playerName),
                    yStart: .value("Min Life", playerData.minLife),
                    yEnd: .value("Max Life", playerData.maxLife),
                    width: 30
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            playerData.minLife < startingLife ? Color.red : Color.cyan,
                            playerData.maxLife > startingLife ? Color.cyan : Color.red
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(8)
                .opacity(0.8)
                
                // Current life indicator
                PointMark(
                    x: .value("Player", playerData.playerName),
                    y: .value("Current Life", playerData.currentLife)
                )
                .foregroundStyle(Color.white.opacity(0.5))
                
                .symbolSize(250)
                .annotation(position: .overlay) {
                    Text("\(playerData.currentLife)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel()
                if value.as(Int.self) == 0 || value.as(Int.self) == startingLife {
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 2))
                        .foregroundStyle(Color.primary.opacity(0.5))
                }
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel()
            }
        }
        .frame(maxHeight: 300)
        .aspectRatio(chartAspectRatio, contentMode: .fit)
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            VStack {
                HStack {
                    Spacer()
                    Text("Turn: \(selectedTurn ?? turns.count)")
                        .font(.caption)
                        .padding(6)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(6)
                }
                Spacer()
            }
                .padding()
        )
    }
    
    private func calculateLifeRanges() -> [PlayerLifeRange] {
        var playerLifeTotals: [String: [Int]] = [:]
        var allPlayers: Set<String> = []
        
        // Collect all player names
        for turn in turns {
            for playerName in turn.deltaLife.keys {
                allPlayers.insert(playerName)
            }
        }
        
        // Initialize each player with starting life
        for player in allPlayers {
            playerLifeTotals[player] = [startingLife]
        }
        
        // Calculate life totals up to selected turn (or all turns)
        let turnsToProcess = selectedTurn ?? turns.count
        
        for turn in turns where turn.turnNumber <= turnsToProcess {
            for player in allPlayers {
                let currentLife = playerLifeTotals[player]?.last ?? startingLife
                let deltaLife = turn.deltaLife[player] ?? 0
                let newLife = currentLife + deltaLife
                playerLifeTotals[player]?.append(newLife)
            }
        }
        
        // Calculate min, max, and current for each player
        return allPlayers.compactMap { player in
            guard let lifeTotals = playerLifeTotals[player], !lifeTotals.isEmpty else {
                return nil
            }
            
            let minLife = lifeTotals.min() ?? startingLife
            let maxLife = lifeTotals.max() ?? startingLife
            let currentLife = lifeTotals.last ?? startingLife
            
            return PlayerLifeRange(
                playerName: player,
                minLife: minLife,
                maxLife: maxLife,
                currentLife: currentLife
            )
        }.sorted { $0.playerName < $1.playerName }
    }
}

// MARK: - Preview with Sample Data
struct LifeChartPreview: View {
    @State private var selectedTurn: Int? = nil
    
    fileprivate let sampleTurns: [Turn] = [
        Turn(turnNumber: 1, deltaLife: [
            "Alice": -3,
            "Bob": 0,
            "Charlie": -2,
            "Diana": 0
        ]),
        Turn(turnNumber: 2, deltaLife: [
            "Alice": -5,
            "Bob": -4,
            "Charlie": 8,  // Gained life
            "Diana": -3
        ]),
        Turn(turnNumber: 3, deltaLife: [
            "Alice": 0,
            "Bob": -7,
            "Charlie": -4,
            "Diana": -6
        ]),
        Turn(turnNumber: 4, deltaLife: [
            "Alice": -8,
            "Bob": -5,
            "Charlie": 3,   // Gained more life
            "Diana": -4
        ]),
        Turn(turnNumber: 5, deltaLife: [
            "Alice": -4,
            "Bob": -12,
            "Charlie": -6,
            "Diana": -5
        ]),
        Turn(turnNumber: 6, deltaLife: [
            "Alice": -7,
            "Bob": -8,      // Bob eliminated
            "Charlie": -10,
            "Diana": -7
        ]),
        Turn(turnNumber: 7, deltaLife: [
            "Alice": -5,
            "Bob": 0,       // Already eliminated
            "Charlie": -8,
            "Diana": -6
        ]),
        Turn(turnNumber: 8, deltaLife: [
            "Alice": -8,    // Alice eliminated
            "Bob": 0,
            "Charlie": -15, // Charlie eliminated
            "Diana": -9     // Diana eliminated
        ])
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Life Range Chart")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            LifeRangeChart(turns: sampleTurns, selectedTurn: selectedTurn)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Turn Selection")
                    .font(.headline)
                
                HStack {
                    Button("Show All") {
                        selectedTurn = nil
                    }
                    .buttonStyle(.bordered)
                    
                    ForEach(1...sampleTurns.count, id: \.self) { turn in
                        Button("Turn \(turn)") {
                            selectedTurn = turn
                        }
                        .buttonStyle(.bordered)
                        .tint(selectedTurn == turn ? .blue : .gray)
                    }
                }
                
                Text("Instructions:")
                    .font(.caption)
                    .fontWeight(.semibold)
                Text("• Bars show life range from minimum to maximum")
                    .font(.caption2)
                Text("• Cyan = above 40 life, Red = below 40 life")
                    .font(.caption2)
                Text("• White dot shows current life at selected turn")
                    .font(.caption2)
                Text("• Horizontal lines mark 0 and 40 life")
                    .font(.caption2)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
        .padding()
    }
}

// MARK: - Preview Provider
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        LifeChartPreview()
            .previewLayout(.sizeThatFits)
    }
}
/**/

*/
import SwiftUI
import Charts
import Podwork

// MARK: - Segment Model
struct DamageSegment: Identifiable {
    let id = UUID()
    let playerIndex: Int
    let playerName: String
    let turnNumber: Int
    let yStart: Int
    let yEnd: Int
    let color: Color
}

// MARK: - Helper to flatten turns
fileprivate class TurnLife {
    let turnNumber: Int
    let deltaLife: [Int]
    let commanderDamageDelta: [[Color: Int]]  // <- per-turn delta, not cumulative
    
    init(turnNumber: Int, deltaLife: [Int], commanderDamageDelta: [[Color: Int]]) {
        self.turnNumber = turnNumber
        self.deltaLife = deltaLife
        self.commanderDamageDelta = commanderDamageDelta
    }
    
    static func buildTurnLifeData(from turnHistory: [Turn]) -> [TurnLife] {
        var runningCommanderTotals: [[Color: Int]] = []
        var result: [TurnLife] = []
        
        for (i, turn) in turnHistory.enumerated() {
            let fullTotals = turn.colorCmdrDamage(for: turn.activePlayer)
            
            // initialize running totals if first turn
            if runningCommanderTotals.isEmpty {
                runningCommanderTotals = Array(repeating: [:], count: fullTotals.count)
            }
            
            var deltas: [[Color: Int]] = []
            for (idx, totals) in fullTotals.enumerated() {
                var deltaDict: [Color: Int] = [:]
                for (color, total) in totals {
                    let prev = runningCommanderTotals[idx][color] ?? 0
                    let delta = total - prev
                    if delta != 0 {
                        deltaDict[color] = delta
                    }
                    runningCommanderTotals[idx][color] = total
                }
                deltas.append(deltaDict)
            }
            
            result.append(
                TurnLife(
                    turnNumber: turn.id,
                    deltaLife: turn.deltaLife,
                    commanderDamageDelta: deltas
                )
            )
        }
        return result
    }
    
    func buildSegments(
        playerNames: [String],
        playerColors: [Color],
        startingLife: Int,
        previousLife: inout [Int]
    ) -> [DamageSegment] {
        var segments: [DamageSegment] = []
        
        for (index, name) in playerNames.enumerated() {
            var currentLife = previousLife[index]
            
            // Regular life delta
            if index < deltaLife.count {
                let delta = deltaLife[index]
                let newLife = currentLife + delta
                if delta != 0 {
                    segments.append(
                        DamageSegment(
                            playerIndex: index,
                            playerName: name,
                            turnNumber: turnNumber,
                            yStart: currentLife,
                            yEnd: newLife,
                            color: delta > 0 ? Color.cyan : Color.red
                        )
                    )
                }
                currentLife = newLife
            }
            
            // Commander damage (delta only, not total)
            if index < commanderDamageDelta.count {
                for (color, dmg) in commanderDamageDelta[index] where dmg > 0 {
                    let newLife = currentLife - dmg
                    segments.append(
                        DamageSegment(
                            playerIndex: index,
                            playerName: name,
                            turnNumber: turnNumber,
                            yStart: currentLife,
                            yEnd: newLife,
                            color: color.opacity(0.8)
                        )
                    )
                    currentLife = newLife
                }
            }
            previousLife[index] = currentLife
        }
        return segments
    }
}

// MARK: - Life Chart View
public struct LifeRangeChart: View {
    public let turnHistory: [Turn]
    @Binding public var selectedTurn: Int?
    public let playerNames: [String]
    
    
    public let playerColors: [Color] = [.green, .orange, .blue, .purple]
    
    private let startingLife = 40
    private let chartAspectRatio: CGFloat = 1.4
    
    // Build all stacked segments
    private var allSegments: [DamageSegment] {
        let turns = TurnLife.buildTurnLifeData(from: turnHistory)
        let turnsToProcess = selectedTurn ?? turns.count
        
        var segments: [DamageSegment] = []
        var runningLife = Array(repeating: startingLife, count: playerNames.count)
        
        for turn in turns where turn.turnNumber <= turnsToProcess+1 {
            segments.append(
                contentsOf: turn.buildSegments(
                    playerNames: playerNames,
                    playerColors: playerColors,
                    startingLife: startingLife,
                    previousLife: &runningLife
                )
            )
        }
        return segments
    }
    
    private var yAxisRange: (min: Int, max: Int) {
        let minLife = allSegments.map { min($0.yStart, $0.yEnd) }.min() ?? 0
        let maxLife = allSegments.map { max($0.yStart, $0.yEnd) }.max() ?? startingLife
        return (min: min(minLife - 5, 0), max: max(maxLife + 5, startingLife))
    }
    
    public init(turnHistory: [Turn], selectedTurn: Binding<Int?> , playerNames: [String]) {
        self.turnHistory = turnHistory
        self._selectedTurn = selectedTurn
        self.playerNames = playerNames
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Turn label above chart
//            Text("Turn: \(selectedTurn ?? turnHistory.count)")
//                .font(.caption)
//                .fontWeight(.medium)
//                .padding(.horizontal, 12)
//                .padding(.vertical, 4)
//                .background(Color.gray.opacity(0.2))
//                .cornerRadius(6)
//                .padding(.bottom, 8)
            
            Chart {
                // Starting life rule
                RuleMark(y: .value("Starting Life", startingLife))
                    .foregroundStyle(.yellow.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 3))
                
                // Zero life rule
                RuleMark(y: .value("Zero", 0))
                    .foregroundStyle(.primary.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 2))
                
                // Waterfall bars
                ForEach(allSegments) { seg in
                    BarMark(
                        x: .value("Player", seg.playerName),
                        yStart: .value("Start", seg.yStart),
                        yEnd: .value("End", seg.yEnd),
                        width: 15
                    )
                    .foregroundStyle(seg.color)
                  
                    .cornerRadius(2)
                    .opacity(0.9)
                }
                
                // Current life indicator (moved inside chart but higher y)
                ForEach(playerNames.indices, id: \.self) { idx in
                    if let lastSeg = allSegments.last(where: { $0.playerIndex == idx }) {
                        PointMark(
                            x: .value("Player", playerNames[idx]),
                            y: .value("Life", lastSeg.yEnd)
                        )
                        .foregroundStyle(Color.black)
                        .annotation(position: .top, alignment: .center) {
                            Text("\(lastSeg.yEnd)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .offset(x:-15, y:15)
                        }
                    }
                }
            }
            .chartYScale(domain: yAxisRange.min...yAxisRange.max)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    if let v = value.as(Int.self), v == 0 || v == startingLife {
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 2))
                            .foregroundStyle(Color.primary.opacity(0.5))
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                       // .tint(value == 1 ? .blue : .gray)
                }
            }
            .frame(maxHeight: 200)
            .frame(width: 200)
            .frame(height: 120)
            .aspectRatio(chartAspectRatio, contentMode: .fit)
        }
    }
}
