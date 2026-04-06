import Foundation
import SwiftUI
import Podwork
import SwiftData


public struct LeaderboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State public var manager : LeaderboardManager
    @State private var selectedTab = 0
    
    var bracket_view: some View {
        BracketStatistics_View()
    }

    
    @MainActor
    public var body: some View {
       // NavigationStack {
        VStack(spacing: 4) {
          
                
                
            SummaryStatsView(totals: manager.leaderboardTotals)
                .padding(.horizontal, 6 )
                //Text("\(manager.leaderboardTotals)")
   
            
            // Tab Selector
            Picker("Category", selection: $selectedTab) {
                Text("Glorious Ascension")
                    .bold(selectedTab == 0)
                    .tag(0)
                Text("Wall of Shame")
                    .bold(selectedTab == 1)
                    .tag(1)
                Text("Brackets")
                    .bold(selectedTab == 2)
                    .tag(2)
            }
            .background(Color.blue)
            .pickerStyle(SegmentedPickerStyle())
            .cornerRadius(12)
        

            
            if manager.isLoading {
                ProgressView("Loading leaderboard...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = manager.error {
                ErrorView(message: error) {
                    Task { await manager.fetchLeaderboard() }
                }
            } else {
                
                if selectedTab != 2 {
              
                    List {
                       // Group{
                        ForEach(selectedTab == 0 ? manager.gloriousRecords() : manager.shameRecords() ) { record in
                            LeaderboardRowView(item: LeaderboardItem(from: record))
                        }
                        .cornerRadius(12)

                        
                        
                   // }
                }
                .listStyle(GroupedListStyle())
                .padding(.horizontal, 6 )
                .cornerRadius(12)

                }
                else if selectedTab == 2{
                    bracket_view
                }
            }
        }

        .navigationTitle("Leaderboard")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    Task { await manager.fetchLeaderboard() }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(manager.isLoading)
            }
        }
        .task {
            // Fetch new data if we don't have any or if it's older than 1 hour
            if manager.lastUpdated == nil ||
                Date().timeIntervalSince(manager.lastUpdated!) > 3600 {
                await manager.fetchLeaderboard()
            }
            
        }
        
        .task {
            if manager.shouldRefresh() {
                await manager.fetchLeaderboard()
            }
        }
    }
}



public struct SummaryStatsIcon: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    public init(title: String, value: String, icon: String, color: Color) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
    }
    
    public var body: some View {
        VStack(alignment: .center, spacing: 8) {
//            Image(systemName: icon)
//                .font(.footnote)
//                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
                .foregroundStyle(Color.white.gradient)
                //.padding(4)
                .background(Color(.secondarySystemFill))
            
            Text(title)
                .font(.caption)
                .bold()
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 4)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
      
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}




struct SummaryStatsView: View {
    let statistics : LeaderboardTotals
    
    init(totals: [String: Double]){
        self.statistics = LeaderboardTotals( jsonDict: totals)
    }
    
    var body: some View {
     

        
        // Row 1: Basic Stats
        VStack{
            
            Rectangle()
                .fill(Color.clear)
                .frame(height: 40)
            
            Text("🌐 Global Summary")
                .font(.title2.bold())
                //Color.teal
           
            .foregroundStyle( LinearGradient(colors: [.green, .blue],   startPoint: .top, endPoint: .bottom))
            .customStroke(color: Color.black, width: 0.5)
            
            HStack(alignment: .bottom , spacing: 8) {
                SummaryStatsIcon(
                    title: "Pods",
                    value: "\(Int(statistics.games))",
                    icon: "gamecontroller.fill",
                    color: .blue
                )
                
                SummaryStatsIcon(
                    title: "Time",
                    value: "\(statistics.playtime.formattedDuration())",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                )
            }
              
                
                // Row 2: Opponent Rating Stats
                HStack(spacing: 8) {
                    SummaryStatsIcon(
                        title: "Cmdr",
                        value: "\(Int(statistics.commandersSeen))",
                        icon: "chart.line.downtrend.xyaxis",
                        color: .red
                    )
                    
                SummaryStatsIcon(
                    title: "Cmdr Dmg",
                    value: "\(Int(statistics.commanderDamage))",
                    icon: "exclamationmark.triangle.fill",
                    color: .orange
                )
                    
                    SummaryStatsIcon(
                        title: "Cmdr Tax",
                        value: "\(Int(statistics.commanderTax))",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
              
            }
        }
    }
}

import Podwork
struct LeaderboardRowView: View {
    let item: LeaderboardItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.category.displayName)
                        .font(.headline)
                        .foregroundColor(item.isGlorious ? .green : .red)
                    
                    HStack {
                        Text(item.commander)
                            .font(.subheadline)
                        if !item.partner.isEmpty {
                            Text("&")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(item.partner)
                                .font(.subheadline)
                        }
                    }
                }
                
                Spacer()
                
                Text(formatRecord(item.record, for: item.category))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(item.isGlorious ? .green : .red)
            }
            
            if let lastUpdated = item.updated {
               // Text("Updated \(lastUpdated.formatted(.relative(presentation: .numeric)))")
                Text("Updated \(lastUpdated.formattedString())")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatRecord(_ value: Double, for category: SummaryRankingTitles) -> String {
        switch category {
        case .fastestWins:
            return value.formattedDuration()
        case .mostDamage, .mostTax:
            return String(format: "%.0f", value)
        case .longestTurns:
            return String(format: "%.1f min", value)
        default:
            return String(format: "%.0f", value)
        }
    }
}

struct ErrorView: View {
    let message: String
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Retry", action: retry)
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}








struct LeaderboardView_Previews: PreviewProvider {
    //@Environment(\.modelContext) var modelContext
    

    
    //context.insert(model)
    

    static var previews: some View {
        
  
        let container =  try! ModelContainer(for: LeaderboardRecord.self, CachedBracketStatistics.self )
            let context = ModelContext(container)
            
            
            
           let lb = LeaderboardManager(modelContext: context)
            
            //.modelContainer(container)
       
    LeaderboardView(manager : lb )

    }
    
    
}


