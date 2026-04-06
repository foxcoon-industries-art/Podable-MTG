import SwiftUI
import Podwork


struct BracketAnalysisView: View {
    @StateObject private var dataManager = GameDataManager.shared
    @State private var showExpl: Bool = false
    
    let sidePad = 8.0
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            
            if dataManager.finalStates.isEmpty {
                //EmptyNoDataView(statsScreen: EnhancedStatsScreens.brackets)
                
            } else {
                
                let bracket_analysis = dataManager.bracketStats
                let totalPlayed = bracket_analysis.map { $0.value.games }.reduce(0, +)
                
                BracketVibeCheckView(bracket_analysis.map {$0.value})
                    .background(
                        Rectangle()
                            .fill(Color.black.secondary)
                            .cornerRadius(12)
                    ).padding(8)
                
                LazyVStack(spacing: 16) {
                    ForEach( bracket_analysis.keys.sorted() , id: \.self) { bra_key in
                        if bra_key >= 1 && bra_key <= 5
                        {                        if let data = bracket_analysis[bra_key] {
                            BracketFactsCard(bracket: data, totalPlayed: totalPlayed, answer: "")
                        }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
            

//    private var headerSection: some View {
//        VStack(alignment: .center, spacing: 8) {
//                let statsType = EnhancedStatsScreens.brackets.displayName
//                let statsDesc = EnhancedStatsScreens.brackets.description
//                let title = showExpl ? "((( \(statsType) )))" : "\(statsType)"
//                
//                Text(title)
//                    .font(.title2)
//                    .fontWeight(.bold)
//                    .foregroundStyle(Color.orange)
//                
//                Text(statsDesc)
//                    .font(.subheadline)
//                    .foregroundColor(Color.secondary)
//        }
//        .padding(.horizontal)
//        .frame(maxWidth: .infinity, alignment: .leading)
//    }
}

struct BracketCard: View {
    let bracket: BracketStatistics
    let totalPlayed: Int
    
    var body: some View {
        let winRatePercent = bracket.winRate * 100.0
        let sameBracketPercent = bracket.sameBracketRate * 100.0
        let playRatePercent = 100.0 * Double( bracket.games) / Double (totalPlayed)

        HStack(alignment: .lastTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Bracket \(bracket.bracket)")
                    .foregroundStyle(bracketColor(bracket.bracket))
                    .font(.title3)
                    .bold()
                    .lineLimit(1)
                    //.foregroundStyle(Color.primary)
               
                Text("\(bracket.decks) ratings")
                    .font(.caption)
                    .foregroundColor(Color.secondary)
            }
            
            Spacer(minLength: 0)
            
            HStack (alignment: .lastTextBaseline ,spacing: 32) {
                VStack(alignment: .center, spacing: 4) {
                        Text(String(format: "%.1f", playRatePercent) + "%  ")
                            .font(.title3)
                            .lineLimit(1)
                            .fontWeight(.semibold)
                            .foregroundStyle(agreeColor(playRatePercent))
                    
                        Text("Play Rate")
                            .font(.caption)
                            .foregroundColor(Color.secondary)
                            .lineLimit(1)
                }
                
                VStack(alignment: .center, spacing: 4) {
                        Text("" + (String(format: "%.1f", sameBracketPercent) + "%"))
                            .font(.title3)
                            .foregroundStyle(agreeColor(sameBracketPercent))
                            .lineLimit(1)
                            .fontWeight(.semibold)
                    
                        Text("Agreement")
                            .font(.caption)
                            .foregroundColor(Color.secondary)
                            .lineLimit(1)
                }
            }
        }
        .padding(.trailing, 8)
        .padding(.vertical)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func agreeColor(_ agreement: Double) -> AnyShapeStyle {
        switch agreement {
        case ..<25: return AnyShapeStyle(Color.red)
        case 25..<33: return AnyShapeStyle(Color.red.secondary)
        case 33..<50: return AnyShapeStyle(Color.orange.secondary)
        case 50..<66: return AnyShapeStyle(Color.orange)
        case 66..<75: return AnyShapeStyle(Color.green.secondary)
        default: return AnyShapeStyle(Color.green)
        }
    }
}



struct BracketFactsCard: View {
    let bracket: BracketStatistics
    let totalPlayed: Int
    let answer: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack (alignment: .firstTextBaseline, spacing: 0){
                
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(Color.secondary)
                    .rotationEffect(.degrees(isExpanded ? 0 : -90))
                    .padding(8)
         
                BracketCard(bracket: bracket, totalPlayed: totalPlayed)
  
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }
            
            if isExpanded {
                Text(answer)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.scale.combined(with: .opacity))
                    .blur(radius:5)
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}





import Charts
/**/
struct BracketVibeCheckView: View {
    // Sample data: bracket -> bar -> height
    static func exampleData() -> [Int: [Int: Int]] { [
        1: [1: 1, 2: 2, 3: 3, 4: 4, 5: 5],
        2: [1: 2, 2: 3, 3: 4, 4: 1, 5: 5],
        3: [1: 3, 2: 1, 3: 5, 4: 2, 5: 4],
        4: [1: 4, 2: 5, 3: 2, 4: 3, 5: 1],
        5: [1: 5, 2: 4, 3: 1, 4: 5, 5: 2]
    ]
    }
    
    static func testData() -> [BracketStatistics] {
        var bracket_test_data : [BracketStatistics] = []
        for idx in 1..<6 {
            var bracketExample = BracketStatistics(bracket: idx)
            bracketExample.vibeCheck = exampleData()[idx] ?? [:]
            bracket_test_data.append(bracketExample)
        }
        return bracket_test_data
    }
    
    @State var containerSize : CGSize = CGSize()
    var bracketStats : [BracketStatistics]
    
    public init(_ bracketStats: [BracketStatistics]){
        var tempBrackets = bracketStats.sorted(by: { $0.bracket < $1.bracket })
        var recordedBracketNumbers = tempBrackets.map {$0.bracket}
        for idx in 1..<6 {
            if !recordedBracketNumbers.contains(idx){
                var bracketExample : BracketStatistics = BracketStatistics(bracket: idx)
                bracketExample.vibeCheck = [:]
                tempBrackets.append(bracketExample)
            }
        }
        self.bracketStats = tempBrackets.sorted(by: { $0.bracket < $1.bracket })
        self.bracketStats = self.bracketStats.filter { $0.bracket != 0 && $0.bracket > 0}
    }
    
    var body: some View {
        VStack (spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                ForEach(bracketStats, id: \.bracket) { bracket in
                        VStack{
                            Chart {
                                ForEach(bracket.vibeCheck.sorted(by: { $0.key < $1.key }), id: \.key) { bar in
                                    RectangleMark(
                                        x: .value("Bar", Double(bar.key) - 1.0),
                                        yStart: .value("Start", 0),
                                        yEnd: .value("Height", bar.value)
                                    )
                                    .foregroundStyle( bar.key == bracket.bracket ?
                                                      AnyShapeStyle(bracketColor(bracket.bracket).gradient) :
                                                      AnyShapeStyle(bracketColor(bracket.bracket).tertiary)
                                    )
                                }
                            }
                            .chartXAxis(.hidden)
                            .chartYAxis(.hidden)
                            .padding(.horizontal, 4)
                            .frame( height: 50)
                            .padding(5)
                            
                            Text("\(bracket.bracket)")
                                .foregroundStyle(Color.secondary)
                        }
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 8)
            .background(Color(.secondarySystemFill))
 
            
        Text("Bracket Vibe Check")
                .bold()
                .foregroundStyle(Color.primary)
                .padding(.bottom, 8)
        }
            .background(GeometryReader { geometry in
                Color(.systemGray6)
                    .onAppear { containerSize = geometry.size }
                    })
            .cornerRadius(12)
    }
}


#Preview{
    BracketVibeCheckView( BracketVibeCheckView.testData())
    BracketCard(bracket: BracketStatistics(bracket: 1), totalPlayed:10)
    BracketFactsCard(bracket: BracketStatistics(bracket: 1), totalPlayed:10, answer: "FAQ.")
    
}
/**/
