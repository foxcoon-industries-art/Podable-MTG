import SwiftUI
import Charts
import Podwork

// MARK: - Chart Data Format
struct TurnDurationPoint: Identifiable {
    var id: Int { turn }
    let turn: Int
    let avgDuration: Double
    let startPercent: Double
    let percentOfTotal: Double
}

func secondsToHoursMinutesSeconds(_ seconds: Int) -> (Int, Int, Int) {
    return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
}





// MARK: - Average Durations of Turns Chart
struct TurnAnalysisRow: View {
    @State private var selectedCount: Double?
    @State private var selectedSector: Int?
    @State private var selectedTurnID: Int?
    
    let commander: String
    let cmdrSummary: CommanderSummary
    //let avgDurations_: [Double] = []

    var numTurns : Int { avgDurations.count == 0 ? 1 : avgDurations.count }
    var totalTime : Double { avgDurations.reduce(0, +) }
    //var maxHeight : Double { avgDurations.max() ?? 1.0 }
    var maxHeight : Double {
        let meanPlusStd = Array(cmdrSummary.avgDurationPerTurn.enumerated()).map { $0.1 + cmdrSummary.stdDevTimePerTurn[$0.0] }
        let meanStdMax = meanPlusStd.max()
        return meanStdMax ?? 0 }
    var avgDurationPerTurn: Double { totalTime/Double(numTurns) }

    var avgDurations: [Double] { cmdrSummary.avgDurationPerTurn}
    var stdDurations: [Double] { cmdrSummary.stdDevTimePerTurn}
    
    private func findSelectedTurn(value: Double, data: [TurnDurationPoint]) -> Int? {
        let turn = data.filter( {
            return ($0.startPercent) <= value  && value <= ( ($0.startPercent + $0.percentOfTotal))
        })
        if let selectedTurn = turn.first{
            return selectedTurn.turn
        }
        return nil
    }

    var body: some View {
        VStack(spacing:6){
            
            
            Text("Time Taken Per Turn")
                .foregroundStyle(Color.white.gradient)
                .font(.headline)
                .bold()
                .frame(maxWidth: .infinity)
            
                .frame(alignment: .center)
        
            
            
            
            
            
            
            
            VStack(alignment: .leading, spacing: 12) {
                
                
                
                var runningTotal: Double = 0.0
                let data: [TurnDurationPoint] = avgDurations.enumerated().map { (index, duration) in
                    let percent = duration / totalTime
                    let point = TurnDurationPoint(
                        turn: index + 1,
                        avgDuration: duration,
                        startPercent: runningTotal,
                        percentOfTotal: percent
                    )
                    runningTotal += percent
                    return point
                }
                
                
                HStack(alignment: .firstTextBaseline){
                           
                    HStack(spacing:0){
                        Text("Mean: ")
                            .foregroundColor(Color.primary)
                            .font(.subheadline)
                        
                        Text("\(timeFormatDuration(avgDurationPerTurn))")
                            .foregroundColor(Color.primary)
                            .font(.subheadline)
                            .bold()
                        
                        Text(" ± \(timeFormatDuration(cmdrSummary.stdTurnDuration))")
                            .foregroundColor(Color.secondary)
                            .font(.subheadline)
                    }
                    
                  
                    
                    
                    if selectedSector  == nil {
                        Text("Tap bars to show avg. duration")
                            .foregroundStyle(Color(.tertiaryLabel))
                            .font(.subheadline)
                            .bold()
                            .frame(maxWidth:.infinity)
                    } else {
                        
                        if let sector = selectedSector {
                            if sector != nil {
                                let displayed_avg = timeFormatDuration(avgDurations[sector-1])
                                var selectedTurnID = sector == nil ? 0 : sector ?? 0
                                HStack{
                                    //Spacer(minLength: 20)
                                    HStack(spacing:0){
                                        Text("Turn: ")
                                            .font(.subheadline)
                                        Text("\(selectedSector == nil ? 0 : selectedSector ?? 0)")
                                            .font(.subheadline)
                                            .bold()
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(alignment: .trailing)
                                    //Spacer(minLength: 0)
                                    HStack(spacing:0){
                                        Text("Avg: ")
                                            .font(.subheadline)
                                        
                                        Text("\(displayed_avg)")
                                            .font(.subheadline)
                                            .bold()
                                        
                                        Text(" ± \(timeFormatDuration(stdDurations[sector-1]))")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(alignment: .trailing)
                                  //  Spacer(minLength: 20)
                                }
                                // .padding([.bottom], 20)
                            }
                        }
                            //                    }}else{
                            //                        HStack{Spacer()
                            //                            Text(" ")
                            //                                .font(.subheadline)
                            //                                .foregroundColor(.secondary)
                            //                        }
                            //                        .padding([.bottom], 20)
                        
                        
                    }
                    
                    
                }
                .padding(.bottom, 6)
                .padding(.horizontal, 12)
                .padding(.top, 6)
             
                let turnPositions = data.map {$0.startPercent}
                Chart(data) { point in
                    // Draw the average as a line
                    RuleMark(
                        xStart: .value("Start", point.startPercent),
                        xEnd: .value("End", point.startPercent + point.percentOfTotal),
                        y: .value("Avg Duration", point.avgDuration)
                    )
                    .foregroundStyle(speedColor(point.avgDuration))
                    .lineStyle(StrokeStyle(lineWidth: 6, lineCap: .round))
                    .opacity(selectedSector == nil ? 1.0 : (selectedSector == point.turn ? 1.0 : 0.25))
                    
                    // Simple error bar for ±1 SD
                    if stdDurations.count > point.turn - 1 {
                        let std = stdDurations[point.turn - 1]
                        let lower = max(0, point.avgDuration - std)
                        let upper = point.avgDuration + std
                        
                        // Vertical error line
                        RuleMark(
                            x: .value("Center", point.startPercent + point.percentOfTotal / 2),
                            yStart: .value("Lower", lower),
                            yEnd: .value("Upper", upper)
                        )
                        .foregroundStyle(speedColor(point.avgDuration).opacity(0.7))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [3]))
                        .zIndex(-1)
                        
                        // End caps for clarity (dotted lines might not have line at end points)
                        RuleMark(
                            xStart: .value("Left Cap", point.startPercent + point.percentOfTotal / 2 - 0.002),
                            xEnd: .value("Right Cap", point.startPercent + point.percentOfTotal / 2 + 0.002),
                            y: .value("Lower", lower)
                        )
                        .foregroundStyle(Color.white.opacity(1))
                        RuleMark(
                            xStart: .value("Left Cap", point.startPercent + point.percentOfTotal / 2 - 0.002),
                            xEnd: .value("Right Cap", point.startPercent + point.percentOfTotal / 2 + 0.002),
                            y: .value("Upper", upper)
                        )
                        .foregroundStyle(Color.white.opacity(1))
                    }
                    
                    // Draws bands of +/- std length
                    if stdDurations.count > point.turn - 1 {
                        let std = stdDurations[point.turn - 1]
                        let normSTD = (std / totalTime )
                        let lower = max(0, point.avgDuration - std )
                        let upper = point.avgDuration + std
                        let mid = point.startPercent + point.percentOfTotal / 2
                       
                        
                        // Faint glow band for deviation
                        RuleMark(
                            xStart: .value("Start", max(0, mid - normSTD) ),
                            xEnd: .value("End", min(1, mid + normSTD)  ),
                            y: .value("Upper Bound", upper)
                        )
                        .foregroundStyle(Color.blue.opacity(0.75))
                        RuleMark(
                            xStart: .value("Start", max(0, mid - normSTD) ),
                            xEnd: .value("End", min(1, mid + normSTD) ),
                            y: .value("Lower Bound", lower)
                        )
                        .foregroundStyle(Color.blue.opacity(0.75))
                    }
                    
                    // Draw the X-Axis Line
                    RuleMark(
                        xStart: .value("Start", 0),
                        xEnd: .value("End", 1),
                        y: .value("Avg Duration", 0)
                    )
                    .foregroundStyle(Color.white)
                    .lineStyle(StrokeStyle(lineWidth: 1, lineCap: .butt))
                    // Draw the Y-Axis
                    RuleMark(
                        x: .value("Center", 0),
                        yStart: .value("Lower", 0),
                        yEnd: .value("Upper", maxHeight)
                    )
                    .foregroundStyle(Color.white)
                    .lineStyle(StrokeStyle(lineWidth: 1, lineCap: .butt))
                    //.opacity(selectedSector == nil ? 1.0 : (selectedSector == point.turn ? 1.0 : 0.25))
                    
                }

                .chartXSelection(value: $selectedCount)
                .onChange(of: selectedCount) { oldValue, newValue in
                    if let newValue {
                        selectedSector = findSelectedTurn(value: newValue, data: data)
                    } else { selectedSector = nil }
                }
                .chartXScale(domain: 0...1.0)
                .chartYScale(domain: 0...1.01*maxHeight)
                .chartXAxis {  AxisMarks(position: .automatic, values: .automatic(desiredCount: numTurns)) { value in
                    if let turnCategory = value.as(Double.self) {
                    AxisValueLabel( String(1+Int(turnCategory*Double(numTurns))) )
                        AxisGridLine()
                    }
                    
                }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                        if let sec = value.as(Double.self) {
                            let hours = Double( Int(sec) / 3600 )
                            let minutes = Double( Int(sec) % 3600 / 60 )
                            let seconds = Double( Int(sec) % 60 )
                            let _ = print(hours, minutes, seconds)
                            let _ = print(String(format: "%0.0fh %0.0fm %0.0fs", hours,  minutes, seconds))
                            if hours > 0 {
                                AxisValueLabel(String(format: "%0.0fh %0.0fm %0.0fs", hours, minutes, seconds))
                            } else if minutes > 0 {
                                AxisValueLabel(String(format: "%0.0fm %0.0fs", minutes, seconds))
                            }
                            else {
                                AxisValueLabel(String(format: "%0.0fs", seconds))
                                
                            }
                            AxisGridLine()
                        }
                    }
                       
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(Color(.secondarySystemFill))
                .frame(height: CGFloat(8) * 17)
               
                
                
            }
            //.padding([.bottom], 26)
            //.padding([.bottom], 12 )
            //.padding([.horizontal], 12)
            .background(Color(.secondarySystemFill))
            
        
            Text("Turn Number")
                .bold()
                .padding(6)
                .foregroundStyle(Color.white.gradient)
        }
        //.padding([.top], 8)
    
    }
    
    private func speedColor(_ duration: Double) -> Color {
        switch duration {
        case ..<180: return Color.green
        case 180..<420: return Color.orange
        default: return Color.red
        }
    }
}


//#Preview{
//    TurnAnalysisView()
//}

