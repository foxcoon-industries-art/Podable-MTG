import Foundation
import Podwork
import SwiftUI

// MARK: - Produces a separate view naviation sheet that overlays the screen
public struct EditPodDetailsView: View {
    @State var game: FinalPod
    @State var turnHistory: [Turn]
    @State var selectedTurn: Int
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    
    public var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                Tab("Turn History", systemImage: "clock.arrow.circlepath", value: 1){
                    TurnHistoryView(turns: turnHistory, commanders: game.commanders, selectedTurn: selectedTurn)
                }
            }
            .navigationTitle("Game Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var gameOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            HStack {
                PodStatCard(
                    title: "Duration",
                    value: game.duration.formattedDuration(),
                    color: .blue
                )
                
                PodStatCard(
                    title: "Rounds",
                    value: "\(game.totalRounds)",
                    color: .green
                )
                
                PodStatCard(
                    title: "Win Method",
                    value: game.winMethod,
                    color: .orange
                )
            }
        }
    }
    
    private var commanderDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack{
                Text("Commanders")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            ForEach(game.commanders.sorted(by: { $0.turnOrder < $1.turnOrder }), id: \.turnOrder) { commander in
                CommanderDetailRow(commander: commander)
            }
        }
    }
    
    private var gameStatistics: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Game Summary")
                .font(.title2)
                .fontWeight(.semibold)
            
            let stats = calculateGameStats(from: turnHistory)
            
            VStack(spacing: 8) {
                StatRow(label: "Total Damage Dealt", value: "\(stats.totalDamage)")
                StatRow(label: "Commander Damage", value: "\(stats.commanderDamage)")
                StatRow(label: "Total Poison Counters", value: "\(stats.totalPoison)")
                StatRow(label: "Average Turn Duration", value: stats.avgTurnDuration.formattedDuration())
                StatRow(label: "Longest Turn", value: stats.longestTurn.formattedDuration())
                StatRow(label: "Game Date", value: game.date.formatted(date: .abbreviated, time: .shortened))
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private func calculateGameStats(from history: [Turn]) -> GameStatistics {
        var totalDamage = 0
        var commanderDamage = 0
        var totalPoison = 0
        var turnDurations: [Double] = []
        
        for turn in history {
            for i in 0..<4 {
                //totalDamage += abs(turn.deltaLife[i])
                totalDamage -= turn.deltaLife[i]
                totalPoison += turn.deltaInfect[i]
                
                for j in 0..<4 {
                    let cmdrDmg = turn.deltaCmdrDamage[i][j]
                    commanderDamage += cmdrDmg
                    totalDamage += cmdrDmg
                }
            }
            turnDurations.append(turn.turnDuration)
        }
        
        let avgDuration = turnDurations.isEmpty ? 0 : turnDurations.reduce(0, +) / Double(turnDurations.count)
        let longestTurn = turnDurations.max() ?? 0
        
        return GameStatistics(
            totalDamage: totalDamage,
            commanderDamage: commanderDamage,
            totalPoison: totalPoison,
            avgTurnDuration: avgDuration,
            longestTurn: longestTurn
        )
    }
}

// MARK: - Supporting Types and Views
struct GameStatistics {
    let totalDamage: Int
    let commanderDamage: Int
    let totalPoison: Int
    let avgTurnDuration: Double
    let longestTurn: Double
}

// MARK: -
struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: -
struct PodStatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let color: Color
    let action: (() -> Void)?
    
    init(title: String, value: String, subtitle: String? = nil, color: Color = .primary, action: (() -> Void)? = nil) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.color = color
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .padding([.top],10)
            
            Text(title)
                .font(.caption)
                .bold()
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(minWidth: 60)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2)
        .onTapGesture {
            action?()
        }
    }
}

// MARK: -
struct CommanderDetailRow: View {
    @State var commander: Commander
    @State var editable: Bool = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(commander.displayNames)
                        .font(.headline)
                        .lineLimit(commander.displayNames.contains("\n") ? 2 : 1)
                        .minimumScaleFactor(0.01)
                    
                    if commander.winner {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                    }
                }
                
                HStack(spacing: 12) {
                    Text("Order: \(commander.turnOrder + 1)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Turns: \(commander.turnDurations.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Tax: \(commander.tax)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            HStack{
                Button(action: {editable.toggle()}){
                Label("Edit", systemImage: "document.badge.ellipsis")
                }
                .font(.headline)
                .labelStyle(.iconOnly)
                //.buttonStyle(.bordered)
                
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Bracket \(commander.bracketRating)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.performanceColor(for: Double(commander.bracketRating), in: PerformanceRange.bracket))
                        .foregroundColor(Color.white)
                        .cornerRadius(12)
                    
                    if commander.eliminated {
                        VStack(alignment: .trailing, spacing: 2) {
                            if let round = commander.eliminationRound {
                                Text("Round \(round + 1)")
                                    .font(.caption)
                                    .foregroundColor(Color.red)
                            }
                            
                            if commander.eliminated { let method = commander.eliminationMethod
                                HStack(spacing: 2) {
                                    Text(method.emojiOverlay)
                                    Text(method.displayName)
                                }
                                .font(.caption)
                                .foregroundColor(Color.primary)
                                
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(commander.winner ? Color.yellow.opacity(0.1) : Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(commander.winner ? Color.yellow : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: -
struct TurnHistoryView: View {
    let turns: [Turn]
    let commanders: [Commander]
    let selectedTurn: Int
    
    var body: some View {
        List {
            ForEach(Array(turns.enumerated()), id: \.offset) { index, turn in
                TurnHistoryRow(turn: turn, turnNumber: index, commanders: commanders)
                    .background(index == selectedTurn ? Color.yellow.opacity(0.10) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.clear)
                            .stroke(index == selectedTurn ? Color.yellow.opacity(0.90) : Color.clear, lineWidth: 3)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

// MARK: -
struct TurnHistoryRow: View {
    let turn: Turn
    let turnNumber: Int
    let commanders: [Commander]
    
    init(turn : Turn, turnNumber: Int, commanders: [Commander]){
        self.turn = turn
        self.turnNumber = turnNumber
        self.commanders = commanders.count > 4 ? commanders.rePartner : commanders
    }
    
    var activeCommander: Commander? {
        commanders.rePartner.first { $0.turnOrder == turn.activePlayer }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Turn \(turn.id) ")
                    .font(.headline)
                
                Spacer()
                
                if let commander = activeCommander {
                    Text(commander.name)
                        .font(.caption)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .foregroundColor(Color.black)
                        .background(getColor(for:commander.turnOrder).opacity(0.3))
                        .cornerRadius(8)
                }
            }
            
            // Show significant events
            let events = getSignificantEvents()
            ForEach(events, id: \.player) { event in
                PlayerEventRow(event: event)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func getSignificantEvents() -> [(player: String, description: String, life: String)] {
        var events: [(player: String, description: String, life: String)] = []

        var startingLife: [Int] =  turn.lifeTotal
        
        for (index, commander) in commanders.enumerated() {
            var eventParts: [String] = []
            let idx = commander.turnOrder
            
            // Life changes
            if turn.deltaLife[index] != 0 {
                eventParts.append("\(turn.deltaLife[idx] > 0 ? "+" : "")\(turn.deltaLife[idx]) life")
                startingLife[idx] += turn.deltaLife[idx]
            }
            
            // Commander damage received
            let cmdrDmgReceived = turn.deltaCmdrDamage[idx].reduce(0, +)
            if cmdrDmgReceived > 0 {
                eventParts.append("\(cmdrDmgReceived) Cmdr.")
                startingLife[idx] -= cmdrDmgReceived
            }
            // Partner damage received
            let prtnrDmgReceived = turn.deltaPrtnrDamage[idx].reduce(0, +)
            if prtnrDmgReceived > 0 {
                eventParts.append("\(prtnrDmgReceived) Prtnr.")
                startingLife[idx] -= prtnrDmgReceived
            }
            
            
            // Poison
            if turn.deltaInfect[idx] > 0 {
                eventParts.append("+\(turn.deltaInfect[idx]) poison")
            }
            
            // Check for elimination
            if startingLife[idx] <= 0 || turn.infectTotal[idx]+turn.deltaInfect[idx] >= 10 ||
               ((turn.cmdrDmgTotal[idx]+turn.deltaCmdrDamage[idx]).max() ?? 0) >= 21 {
                eventParts.append("💀 Eliminated")
            }
        
            
            if !eventParts.isEmpty {
                events.append((player: commander.name, description: eventParts.joined(separator: ", "), life: String(startingLife[idx]) ))
            }
            
            
        }
        
        return events
    }
}

// MARK: -
struct PlayerEventRow: View {
    let event: (player: String, description: String, life: String)

    
    var body: some View {
        HStack {
            Text(event.player)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
                .lineLimit(1)
                .strikethrough(event.description.contains("💀"), color: Color.pink)

            Text(event.description)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Spacer()
            
        
            Text(event.life)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(1)
            
        }
    }
}
