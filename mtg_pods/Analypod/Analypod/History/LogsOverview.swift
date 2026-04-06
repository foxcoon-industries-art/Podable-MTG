import SwiftUI
import Charts
import Podwork
import Foundation

struct LogsOverview: View {
    @StateObject private var dataManager = GameDataManager.shared
    @State private var containerSize: CGSize = UIScreen.main.bounds.size
    @State private var showDatabaseResetConfirmation = false
    @State var demoModeOn = false
    
    private let containerScale : CGFloat = 0.95
    private let sectionScale : CGFloat = 0.90
    private let sidePad : CGFloat = 6
    let turnNames: [String] =  ["First Player", "Second Player", "Third Player", "Final Player"]
    
    var body: some View {
        //ZStack{
        VStack(alignment: .center, spacing: 24) {
            VStack(alignment: .center, spacing:sidePad*0.5) {
                    //summaryCardsSection
                cardsForPodSummarization
                TurnOrderWinChart
                cardsForPodAverages
                cardsForPodRemovalAverages
                    //gloriousAscensionSection
                    //wallOfShameSection
         
                }
            Spacer()
            demoMode
            }
       // }
    }
    
        
    private var demoMode : some View {
        VStack{
            Toggle(isOn: $dataManager.includeDemoData ) {
                Text("Demo Mode")
                    .foregroundStyle(Color.orange.gradient)
                    .customStroke(color: Color.black, width: 0.50)
            }
            Text("Generate Randomized Pods")
                .font(.caption)
                .foregroundStyle(Color.brown)
        }
        .frame(width:200)
    }
    
    
    private func warning(_ content: AnyView) -> AnyView {
        AnyView( content
        .onLongPressGesture(minimumDuration: 3) {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            showDatabaseResetConfirmation=true
        }
        .alert(isPresented: $showDatabaseResetConfirmation) {
            Alert(
                title: Text("🗑️ Reset Pod Logs? 🪵"),
                message: Text("Are you sure you want to \nDELETE ALL GAME DATA?\n\n⚠️ THIS CANNOT BE UNDONE! ⚠️"),
                primaryButton: .destructive(Text("RESET")) {
                    SQLiteManager.shared.setupDatabase(reset:true)
                },
                secondaryButton: .cancel()
             )
        })
    }
        
    
    @ViewBuilder
    private var cardsForPodSummarization : some View {
        HStack(spacing: sidePad*0.5){
            StatisticsCardView(title: "Pods", value: "\(dataManager.podSummaryStats.totalGames)", color: Color.orange, subtitle: "Played")
                .frame(minWidth: 0.25*UIScreen.main.bounds.size.width )
            
            StatisticsCardView(title: "Time", value: timeFormatDuration(dataManager.podSummaryStats.totalPlaytime), color: Color.orange, subtitle: "Total")
                .layoutPriority(1)
            
            StatisticsCardView(title: "Commanders", value: "\(dataManager.podSummaryStats.totalCmdrsSeenPlayed)", color: Color.orange, subtitle: "Seen")
                .frame(minWidth: 0.25*UIScreen.main.bounds.size.width )
            
        } //.frame(maxWidth: 0.9*containerSize.width)
        .padding(.horizontal, sidePad)
    }
    
    
    @ViewBuilder
    private var cardsForPodAverages : some View {
        HStack(spacing: sidePad*0.5){
            StatisticsCardView(title: "Game Duration",
                               value: "\(dataManager.podSummaryStats.formattedAvgGameDuration)",
                               std: "\(TimeInterval(dataManager.podSummaryStats.stdGameDuration).formattedDuration(style: .compact))",
                               color: Color.orange,
                               subtitle: "Average Time ±std")
            .layoutPriority(1)
            
           
        } //.frame(maxWidth: 0.9*containerSize.width)
        .padding(.horizontal, sidePad)
    }
    
    
    
    @ViewBuilder
    private var cardsForPodRemovalAverages : some View {
        HStack(spacing: sidePad*0.5){
            StatisticsCardView(title: "First Elimination",
                               value: "\(dataManager.podSummaryStats.avgFirstRemovalRound.formatted())",
                               std: "\(dataManager.podSummaryStats.stdFirstRemovalRound.formatted())",
                               color: Color.orange,
                               subtitle: "Avg. Turns Played ±std")
            //.layoutPriority(1)
            
            
            StatisticsCardView(title: "Winner Declared",
                               value: "\(dataManager.podSummaryStats.avgTurnsPerGame.formatted())",
                               std: "\(dataManager.podSummaryStats.stdTurnsPerGame.formatted())",
                               color: Color.orange,
                               subtitle: "Avg. Round ±std")
            .frame(minWidth: 0.333*UIScreen.main.bounds.size.width )
            
        } //.frame(maxWidth: 0.9*containerSize.width)
        .padding(.horizontal, sidePad)
    }
    
    
        
    @ViewBuilder
    private var summaryCardsSection: some View {
        VStack{
            VStack(spacing: 0){
                HStack(alignment: .bottom , spacing: 16) {

                    //StatCard(title: "Pods", value: "\(dataManager.podSummaryStats.totalGames)", color: Color.orange)

                    //StatCard(title: "Commanders", value: "\(dataManager.podSummaryStats.totalCmdrsSeenPlayed)", color: Color.orange)
                 
                    //StatCard(title: "Playtime", value: timeFormatDuration(dataManager.podSummaryStats.totalPlaytime), color: Color.orange)
                }
                .padding([.top], sidePad)
                .background(Color(.secondarySystemFill))
                .padding([.horizontal],0)
                   
                Text("Logged Pods")
                    .bold()
                    .padding([.top], sidePad)
            }
            .padding([.bottom], 8)
            .padding([.horizontal], 0)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding( 0.5*sidePad )
    }
    
    
    
    private var TurnOrderWinChart: some View {
        VStack (spacing:sidePad){
            
            Text("Win Rate")
                //.font(.footnote)
                .fontWeight(.bold)
                .foregroundStyle(Color.white.gradient)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 3)
                //.padding(.top, 6)
            
            
            HStack(alignment: .center, spacing: sidePad){
                
                // Labels on Left Side
                    VStack(spacing: 8) {
                        ForEach(0..<2) { position in
                            let turnOrder = dataManager.seatOrderStats.turnOrderWinRates[3-position]
                            let winRate =  Double(turnOrder.games) == 0 ? 0 : 100 * Double(turnOrder.wins) / Double(turnOrder.games)
                            let winRateLabel = String(format: "%d",  Int(winRate))
                            VStack(spacing: 4){
                                
                                Text("\( winRateLabel  )%")
                                    .foregroundStyle(ColorPalettes.watermelonSorbet(3-position+1).gradient)
                                    .font(.title2)
                                
                                HStack(spacing: 4) {
                                  
                                    Text("\(turnNames[3-position])")
                                        .font(.footnote)
                                        .foregroundStyle(Color.white.gradient)
                                    
                                    Circle()
                                        .fill(ColorPalettes.watermelonSorbet(3-position+1).gradient)
                                        .frame(width: 8, height: 8)
                                }
                            }.bold()
                        }
                    }.frame(maxWidth: .infinity)
                    
                Chart(dataManager.seatOrderStats.turnOrderWinRates.sorted(by: { $0.seatID < $1.seatID })) { entry in
                    SectorMark(
                        angle: .value("Wins", ( Double(entry.games) == 0 ? 0 : Double(entry.wins)  ) ),
                        innerRadius: .ratio(0.618),
                        angularInset: 1.5
                    )
                    .foregroundStyle(ColorPalettes.watermelonSorbet( min( entry.seatID, 3 )+1).gradient)
                    //.annotation(position: .overlay) { Text("\(entry.seatID)") }
                }
                .padding()
                    
                // Labels on Right Side
                    VStack(spacing: 8) {
                        ForEach(0..<2) { position in
                            let turnOrder = dataManager.seatOrderStats.turnOrderWinRates[position]
                            let seat_id = turnOrder.seatID
                            let winRate =  Double(turnOrder.games) == 0 ? 0 : 100 * Double(turnOrder.wins) / Double(turnOrder.games)
                            let winRateLabel = String(format: "%d",  Int(winRate))
                            VStack(spacing: 4){
                                                                
                                Text("\( winRateLabel  )%")
                                    .foregroundStyle(ColorPalettes.watermelonSorbet(position+1).gradient)
                                    .font(.title2)
                                
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(ColorPalettes.watermelonSorbet(position+1).gradient)
                                        .frame(width: 8, height: 8)
                                    
                                    Text("\(turnNames[position])")
                                        .font(.footnote)
                                        .foregroundStyle(Color.white.gradient)
                          
                                }
                                
                            }.bold()
                        }
                    }
                    .frame(maxWidth: .infinity)
            }
            //.padding([.top], sidePad)
            .background(Color(.secondarySystemFill))
            .padding([.horizontal],0)
            
            Text("Turn Order")
                //.font(.callout)
                //.font(.footnote)
                .foregroundStyle(Color.white.secondary)
                .multilineTextAlignment(.center)
                //.padding(.horizontal, 3)
                //.padding(.bottom, 6)
        }
        .padding([.bottom], sidePad)
        .padding([.top], sidePad)
        .padding([.horizontal], 0)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        //.frame(maxWidth: 0.95*containerSize.width)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, sidePad)
    }


    
    
    @ViewBuilder
    private var gloriousAscensionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            Text("Glorious Ascension")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.blue.gradient)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding([.top], sidePad)

            
            VStack(alignment: .leading, spacing: 16) {
                LeaderboardEntry(
                    icon: "rosette",
                    title: summaryRankingTitles.mostWins,
                    commander: dataManager.podSummaryStats.highestWinRate,
                    color: Color.yellow
                )
                LeaderboardEntry(
                    icon: "gamecontroller.fill",
                    title: summaryRankingTitles.mostPlayed,
                    commander: dataManager.podSummaryStats.mostPlayedCommander,
                    color: Color.blue
                )
                LeaderboardEntry(
                    icon: "flame.fill",
                    title: summaryRankingTitles.mostDamage,
                    commander: dataManager.podSummaryStats.mostCommanderDamage,
                    color: Color.red
                )
                LeaderboardEntry(
                    icon: "dollarsign.bank.building",
                    title: summaryRankingTitles.mostTax,
                    commander: dataManager.podSummaryStats.mostTaxPaid,
                    color: Color.green
                )
                LeaderboardEntry(
                    icon: "hare",
                    title: summaryRankingTitles.fastestWins,
                    commander: dataManager.podSummaryStats.fastestWins,
                    color: Color.secondary
                )
//                LeaderboardEntry(
//                    icon: "circle.badge.exclamationmark",
//                    title: summaryRankingTitles.mostSolRings,
//                    commander: dataManager.podSummaryStats.mostSolRings,
//                    color: Color.yellow
//                )
                /// Ideas for more categories:
                ///  - Game win from Bomb Pod damage
                ///  - 
                ///
                ///
                
                
//                .visualEffect { content, proxy in
//                    content.blur(radius: 1.5)
//                }
            }
            .padding(sidePad)
            .background(Color(.secondarySystemFill))
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(sidePad)
    }
    
    
    @ViewBuilder
    private var wallOfShameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            Text("Wall of Shame")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.pink.gradient.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding([.top], sidePad)

            
            VStack(alignment: .leading, spacing: 16) {
                LeaderboardEntry(
                    icon: "hourglass.bottomhalf.fill",
                    title: summaryRankingTitles.longestTurns,
                    commander: dataManager.podSummaryStats.longestTurns,
                    color: Color.gray
                )
                LeaderboardEntry(
                    icon: "flag.fill",
                    title: summaryRankingTitles.mostConcessions,
                    commander: dataManager.podSummaryStats.mostConcesions,
                    color: Color.white
                )
                LeaderboardEntry(
                    icon: "circle.dashed",
                    title: summaryRankingTitles.leastImpactful,
                    commander: dataManager.podSummaryStats.leastImpact,
                    color: Color.secondary
                )
//                LeaderboardEntry(
//                    icon: "dot.scope",
//                    title: summaryRankingTitles.mostTurnOneSolRings,
//                    commander: dataManager.podSummaryStats.mostTurnOneSolRings,
//                    color: Color.yellow
//                )
//                .visualEffect { content, proxy in
//                    content.blur(radius: 1.5)
//                }
//                LeaderboardEntry(
//                    icon: "burst.fill",
//                    title: summaryRankingTitles.mostBombsUsed,
//                    commander: dataManager.podSummaryStats.mostBombsUsed,
//                    color: Color.pink
//                )
//                .visualEffect { content, proxy in
//                    content.blur(radius: 1.5)
//                }
//                LeaderboardEntry(
//                    icon: "divide.circle.fill",
//                    title: summaryRankingTitles.mostBracketDisparity,
//                    commander: dataManager.podSummaryStats.mostBracketDisparity,
//                    color: Color.orange
//                ).visualEffect { content, proxy in
//                    content.blur(radius: 1.5) // Apply a Gaussian blur
//                }
            }
            .padding(sidePad)
            .background(Color(.secondarySystemFill))
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(sidePad)
    }
}


enum summaryRankingTitles: String, CaseIterable, Codable {
    case mostWins = "Most Wins"
    case mostPlayed = "Most Played"
    case mostDamage = "Most Damage"
    case mostTax = "Most Tax"
    case mostAltWins = "Most Alternative Wins"
    case fastestWins = "Fastest Win"
    case mostSolRings = "Most Sol Rings Played"
    
    case longestTurns = "Longest Turns"
    case leastImpactful = "Least Impactful"
    case mostBracketDisparity = "Most Bracket Disparity"
    case mostConcessions = "Most Concessions"
    case mostBombsUsed = "Most Bombs Used"
    case mostTurnOneSolRings = "Most Turn 1 Sol Rings"
}


struct LeaderboardEntry: View {
    let sidePad: CGFloat = 6
    let icon: String
    let title: summaryRankingTitles
    let commander: CommanderNameStats
    let color: Color
    
    public var additionalInfo: String {
        let commanderInfo = commander.values.first
        switch title {
        case summaryRankingTitles.mostWins: return "Total Wins: \(commanderInfo?.wins ?? 0)"
            
        case summaryRankingTitles.mostPlayed: return "Total Games: \(commanderInfo?.games ?? 0)"
            
        case summaryRankingTitles.mostDamage: return "Total Damage: \(commanderInfo?.totalCommanderDamageDealt ?? 0)"
            
        case summaryRankingTitles.mostTax: return "Total Tax: \(commanderInfo?.totalTaxPaid ?? 0)"

        case summaryRankingTitles.fastestWins: return "Avg. Time: \((commanderInfo?.avgTimeToWin ?? 0).formattedDuration(style: DurationStyle.compact))"
            
        case summaryRankingTitles.longestTurns: return "Avg. Duration of Turns:  \((commanderInfo?.avgTurnDuration ?? 0).formattedDuration(style: DurationStyle.compact))"
            
        case summaryRankingTitles.mostConcessions: return "Consession Rate: " + String(format: "%.0f", 100 * (commanderInfo?.concessionRate ?? 0) ) + "%"

        case summaryRankingTitles.leastImpactful:
            return "Damage Rate: " +
            String(format: "%.0f", 100 * ( commanderInfo?.avgCommanderDamagePerGame ?? 0) )
            + "%"

        case summaryRankingTitles.mostTurnOneSolRings:
            return "Damage Rate: " +
            String(format: "%.0f", 100 * ( commanderInfo?.totalTurnOneSolRings ?? 0) )
            + "%"

        default: return "No Info Available"
        }
    }

    @State private var isExpanded = false
    var body: some View {
        
        let nameKey : String = commander.keys.first ?? "N/A"
        let isCommanderPartner = nameKey.contains("//") || nameKey.contains("\n")
        let name : String = nameKey.replacingOccurrences(of: "//", with:  "\n")
        
        VStack(alignment: .leading, spacing: 8) {
            HStack (alignment: .firstTextBaseline){
 
                    Image(systemName: icon)
                        .font(.body)
                        .foregroundColor(color)
                        .frame(width: 20)
                    
                Text(title.rawValue)
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(Color.primary)
                    
                    Spacer()
                    
                Text(name)
                        .font(.footnote)
                        .fontWeight(.medium)
                        .lineLimit( isCommanderPartner ? 2 : 1)
                        .minimumScaleFactor(isCommanderPartner ? 0.55 : 0.88)
            }
            .padding(.horizontal, sidePad)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }
            
            if isExpanded {
                VStack(alignment: .trailing){
                    Text(additionalInfo)
                        .font(.subheadline)
                        .foregroundStyle( Color(.secondaryLabel).gradient)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.scale.combined(with: .opacity))
                        .padding(.horizontal, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color(.tertiarySystemFill))
                .fixedSize(horizontal: false, vertical: true)
                .transition(.opacity)
            }
        }
    }
}


// MARK: - Stats Card
public struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let color: Color
    let action: (() -> Void)?
    
    public init(title: String, value: String, subtitle: String? = nil, color: Color = Color.primary, action: (() -> Void)? = nil) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.color = color
        self.action = action
    }
    
    public var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(Color(color).gradient)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.center)

            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.center)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(Color(color).secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.3)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(minWidth: 60, minHeight: 50)
        .padding(.top, 8)
        .padding(.horizontal, 12)
        .background(Color.clear)
        .onTapGesture { action?() }
    }
}



public struct StatisticsCardView: View {
    let title: String
    let value: String
    let std: String?
    let color: Color
    let subtitle: String?
    
    public init(title: String, value: String, std: String? = nil, color: Color, subtitle: String? = nil ) {
        self.title = title
        self.value = value
        self.std = std
        self.color = color
        self.subtitle = subtitle
    }
    
    
    @ViewBuilder
    var formattedValueWithStd : some View {
        HStack(alignment: .lastTextBaseline, spacing: 6) {
            Text(value)
                .font(.title)
                .bold()
                .lineLimit(1)
                .foregroundStyle(color.gradient)
                //.fixedSize(horizontal: false, vertical: true)

                
                if std != nil {
                    Text(" ±\(std!)")
                        .foregroundStyle(color.gradient)
                        .lineLimit(1)
                        .opacity(0.85)
                        //.fixedSize(horizontal: false, vertical: true)
                }
            }
    }
    
    public var body: some View {
        VStack(alignment: .center, spacing: 6) {

            Text(title)
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundStyle(Color.white.gradient)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 3)
                .padding(.top, 6)
            
                //.padding(.bottom, 3)
            
            //Text(value)
            formattedValueWithStd
                //.font(.title)
                //.lineLimit(1)
                //.bold()
                //.minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity)
                .padding(.top, 6)
                .padding(.bottom, 6)
                .foregroundStyle(color.gradient)
                .background(Color(.secondarySystemFill).opacity(0.3))
                .background(.ultraThinMaterial)
            
            if subtitle != nil {
                
                Text(subtitle!)
                    .font(.footnote)
                    .foregroundStyle(Color(color))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 3)
                    //.padding(.top, 3)
                    .padding(.bottom, 6)
                
            }
            
          
        }
        .fixedSize(horizontal: false, vertical: true)

        //.frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}



#Preview{
    LogsOverview()
        .background(Color.gray)
}
