
import SwiftUI
import Charts
import Foundation
import Podwork


public struct PlayerTurnTimeChartData: Identifiable {
    public let id: Int      // player index
    public let name: String
    public let duration: TimeInterval
    public var winner: Bool? = false
    
    public init(id: Int, name: String, duration: TimeInterval, winner: Bool? = nil) {
        self.id = id
        self.name = name
        self.duration = duration
        self.winner = winner
    }
    
    public static func chartDataFromCommanders(_ commanders: [Commander] ) -> [PlayerTurnTimeChartData]{
        return commanders.map {
            PlayerTurnTimeChartData(
                id:$0.turnOrder,
                name: $0.fullCommanderName,
                duration: $0.totalTurnTime,
                winner: $0.winner)
        }
    }
    
    
}


/*
func calculateTurnDurations(from commanders: [Commander]) -> [PlayerTurnTime] {
    var timePerPlayer = [Int: TimeInterval](uniqueKeysWithValues: (0..<4).map { ($0, 0) })
    
    for cmdr in commanders {
        timePerPlayer[cmdr.turnOrder, default: 0] += turn.turnDuration
    }
    
    return timePerPlayer.map { (index, duration) in
        PlayerTurnTime(id: index, name: playerNames[index], duration: duration)
    }.sorted { $0.duration > $1.duration }
}

*/

extension TimeInterval {
    func formattedString() -> String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%dm %02ds", minutes, seconds)
    }
}

extension TimeInterval {
    func fractionFormattedString() -> String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%d", minutes)
    }
}

/**/

public struct TurnTimePieChart: View {
    let data: [PlayerTurnTimeChartData]
    @State private var selectedCount: Double?
    @Binding public var selectedSector: String?
    @State private var selectedItem: PlayerTurnTimeChartData?
    @State private var scaleSize: CGFloat = 0.5
    @State private var SelectedName: String? = nil
    let winnerID : Int = 0
    
    var totalDuration: TimeInterval {
        data.reduce(0) { $0 + $1.duration }
    }
    
    public init(data: [PlayerTurnTimeChartData], selectedSector: Binding<String?> ) {
        self.data = data
        self._selectedSector = selectedSector
    }
    
    func findSelectedSector(value: Double, data: [PlayerTurnTimeChartData]) -> PlayerTurnTimeChartData? {
        var accumulatedCount = 0.0
        
        let item = data.first { (obj) in
            accumulatedCount += obj.duration
            return value <= accumulatedCount
        }
        return item!
    }
    
    func changeOpacity(entryID : Int) -> Bool {
        if let unwrappedSelectedItem = selectedItem, (selectedItem != nil), (unwrappedSelectedItem != nil), (unwrappedSelectedItem.id != entryID) { return  true }
        return false
    }
    
    func selectedColor() -> Color { return selectedItem != nil ? getColor(for: selectedItem!.id) : Color.indigo }
    
    public var body: some View {
        HStack(spacing:10){
            
            Chart(data) { entry in
                SectorMark(
                    angle: .value("Time", entry.duration),
                    innerRadius: .ratio(0.5),
                    angularInset: 2.61
                )
                .foregroundStyle(getColor(for: entry.id))
                .opacity(changeOpacity(entryID: entry.id) ? 0.25 : 1 )
            }
            .chartLegend(.hidden)
            .chartAngleSelection(value: $selectedCount)
            .onChange(of: selectedCount) { oldValue, newValue in
                if let newValue {
                    selectedItem = findSelectedSector(value: newValue, data:data)
                    selectedSector = selectedItem?.name
                } else {
                    selectedItem = nil
                    selectedSector = nil
                }
            }
            .padding(6)
            
                
            if  selectedItem == nil {

                HStack(alignment: .firstTextBaseline, spacing:10){
                    VStack(alignment: .leading){
                        Text("Total")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .foregroundStyle(Color.white.gradient)
                            .frame(maxWidth: .infinity)
                                
                        ForEach(data, id: \.id) { selectedItem in
                            
                            Text("\(selectedItem.duration.formattedString())")
                                .font(.caption)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                                .foregroundStyle( getColor(for: selectedItem.id).gradient)
                        }
                    }
                    
                    VStack(alignment: .trailing){
                        Text("%")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .foregroundStyle(Color.white.gradient)
                           // .frame(maxWidth: .infinity)
                        
                        ForEach(data, id: \.id) { selectedItem in
                            Text(String(format: "%.1f%%", 100 * selectedItem.duration / totalDuration))
                                .font(.caption)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                                .foregroundStyle( getColor(for: selectedItem.id).gradient)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .bold()
            }
            
            
            
            if selectedItem != nil {
                VStack{
                    Text(String(format: "%.1f% %", 100 * selectedItem!.duration / totalDuration))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                    
                    Text("≈ \(selectedItem!.duration.fractionFormattedString()) / \(totalDuration.fractionFormattedString()) mins")
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                    
                }
                .foregroundStyle(selectedColor())
                .bold()
            }
        }
        .frame(alignment: .leading)
    }
}



struct TurnTimePieChartView_Previews: PreviewProvider {
    static let mockDurations: [TimeInterval] = [120, 45, 90, 30] // Player 0-3
    static let mockDurations_: [TimeInterval] = [420, 145, 50, 40] // Player 0-3
    //static let mockDurations_: [TimeInterval] = [420, 345, 950, 340] // Player 0-3
    static var total: TimeInterval {
        mockDurations.reduce(0, +)
    }
    
    static func total(_ durations: [TimeInterval]) -> TimeInterval {
        durations.reduce(0, +)
    }
    
    static let mockData : [PlayerTurnTimeChartData] = [
        PlayerTurnTimeChartData(id: 0, name: "Name 0", duration: mockDurations[0]),
        PlayerTurnTimeChartData(id: 1, name: "Name 1", duration: mockDurations[1]),
        PlayerTurnTimeChartData(id: 2, name: "Name 2", duration: mockDurations[2]),
        PlayerTurnTimeChartData(id: 3, name: "Name 3", duration: mockDurations[3])
    ]
    
    static let mockData_ : [PlayerTurnTimeChartData] = [0,1,2,3].map { PlayerTurnTimeChartData(id: $0, name: "Name \($0)", duration: mockDurations_[$0]) }
    
    @State static var selectedSector: String? = nil
    static var previews: some View {
        ZStack {
            Rectangle()
                .fill()
            
            
            TurnTimePieChart(data: mockData_ , selectedSector: $selectedSector)
                .previewDisplayName("Turn Time Pie Chart")
                //.frame(width:300, height:75)
                .frame(width:300, height:75)
                //.frame(maxWidth:300, maxHeight:75)
        
           // TurnTimePieChart(data: mockData_ )
           //     .frame(width:150, height:150)
        }
    }
}
