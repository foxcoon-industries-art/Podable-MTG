import SwiftUI
import Charts
import Podwork


enum MetricFocus {
    case all, lifeOnly, commanderOnly, entropyOnly
}


///*--------------------------------------------------------------------------------------------------------------------------*/
// MARK: - Game Flow Card
/**-----------------------------------------------------------------------------------------------------------**/
@MainActor
public struct OptimizedGameFlowCard: View, Identifiable {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) private var dismiss

    public var id = UUID()
    
    @State var game: FinalPod
    @State var turnHistory: [Turn]
    let metrics : PodTurnMetrics
    let on_Appear: () -> Void
    public var podCastHistory: PodCastHistory? = nil
    
    @State var showLifeLossTurns: Bool = true
    @State var showCommanderDamageTurns: Bool = true
    @State var showEntropyTurns:Bool = true

    @State var focus: MetricFocus = MetricFocus.all
    @State var showingGameDetails: Bool = false
    @State var selectedTurn: Int? = nil

    ///Binding for chart selection
    @State private var selectedChartSector: String? = nil
    @State private var selectedChartRow: String? = nil
    
    @State var dmgHighlighted : Bool = false
    @State var isRotated: Bool?
    
    @State var exportPod: Bool?
    
    private let cellSize: CGSize = CGSize(width: 28, height: 28)
    let nameSpacing: CGFloat = 150
    let hSpacing: CGFloat = 2.0
    let vSpacing: CGFloat = 2.0
    let sidePad = 6.0
    
 
    @State private var containerSize : CGSize = .zero //UIScreen.main.bounds.size
    
    
    // MARK: - INITIALIZE
    @MainActor
    public init(game: FinalPod, turnHistory: [Turn], on_Appear: @escaping () -> Void, podCastHistory: PodCastHistory? = nil, isRotated : Bool? = nil, exportPod : Bool? = nil )  {
        self.game = game
        self.turnHistory = turnHistory
        self.on_Appear = on_Appear
        self.metrics = PodMetrics.build(from: turnHistory)
         if podCastHistory != nil {
             self.podCastHistory = podCastHistory!
        }
        //self.isRotated = isRotated!
        if isRotated == nil { self.isRotated = false}
        else if isRotated != nil {
            let _ = print(self.isRotated, isRotated)
            self.isRotated = isRotated!
            self._isRotated = State(wrappedValue: isRotated!)
            let _ = print(self.isRotated, isRotated)
        }
        let _ = print(self.isRotated, isRotated)
        if exportPod == nil {
            self.exportPod = false
        } else {
            self.exportPod = exportPod
        }
    }
    
    
    

    // MARK: - Computed Variables
    private var commandersInTurnOrder: [Commander] {
        return game.commanders.rePartner.sorted { $0.turnOrder < $1.turnOrder }
    }
    
    private var gameEndTurn: Int? {
        turnHistory.last?.id ?? turnHistory.count - 1
    }
    
    private var displayTurnCount: Int { turnHistory.count }

    private var commanderNamesByTurnOrder: [String] {
        return commandersInTurnOrder.map {String($0.displayNames.prefix(8))}
    }
    
    ///*--------------------------------------------------------------------------------------------------------------------------*/
    // MARK: - MAIN BODY VIEW
    ////======================================================================
    public var body: some View {
        
        if self.exportPod == true {
            fullBody
        }
        else {
            fullBody
                .sheet(isPresented: $showingGameDetails, onDismiss: {} ) {
                    EditPodDetailsView(
                        game: game,
                        turnHistory: turnHistory,
                        selectedTurn: selectedTurn ?? turnHistory.count-1)
                }
            
        }
        
        
    }
    public var fullBody: some View {
        //guard !turnHistory.isEmpty else { return loadingView }
        ScrollView( [.horizontal, .vertical], showsIndicators: true) {
            VStack(alignment: .leading, spacing: 6) {
                
                HStack(alignment: .top, spacing: 12){
                    fullTurnChart
                    damageChart
                    cmdrCompanionCube
                    infectChart
                }
                
                optimizedHeatMapGrid
                
                enhancedLegendView
                
                podableLogo
            }
            .padding(.leading, 8)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            
            .background(
                GeometryReader { geometry in
                    Color(.secondarySystemFill)
                        .onAppear {
                            let _ = print("OG Container Size:", containerSize)
                            self.containerSize = geometry.size
                            let _ = print("SET Container Size:", containerSize)
                            
                        }
                        
                }
            )

        }
       
        
        .rotationEffect(self.isRotated ?? false ? .degrees(-90) : .degrees(0))
        .padding()
        .frame(width: self.isRotated ?? false ? max(containerSize.height, containerSize.width ) : min(containerSize.height, containerSize.width),
               height: self.isRotated ?? false ? min(containerSize.height, containerSize.width) : max(containerSize.height, containerSize.width))

        
        .background(
            GeometryReader { geometry in
                Color.clear
                    
                    .onChange(of: geometry.size) { _, newSize in
                        containerSize = newSize
                        let _ = print("2New Container Size:", newSize)
                    }
            }
        )
        
        .onAppear(perform: on_Appear)
        
        
    
    }
    
    
    // MARK: - WATERMARK
    @ViewBuilder
    var podableLogo: some View {
        HStack(alignment: .lastTextBaseline, spacing: 0){
            Spacer(minLength: .zero)
            Text("Bring your Pod's Casts to life with... ")
                .font(.caption)
                .italic()
                .foregroundStyle(Color.blue.gradient.opacity(0.8))
            
            Text("Podable")
                .modifier(PodableLogoStyle())
                .font(.footnote)
                .padding(.trailing, 2*sidePad)
        }
        .padding(.top, -sidePad)
    }
    
    private var pod: FinalPod {  return game }
    
    
    
    
    
    // MARK: - PLAYER TIME PERCENTAGE CHART + CARD
    ///*-------------------------------------------------------------------------------------------------------------*/
    @ViewBuilder
    var fullTurnChart: some View {
        VStack(alignment: .center, spacing: 0.5*sidePad){
            turnPercentageHeader
                .padding(2)
                .frame(alignment:.center)
            turnChartView
                .background(Color(.secondarySystemFill))
            HStack{
                turnChartFooter
                Spacer()}
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12.0))
        .frame(maxWidth: 240, alignment:.center)
    }
    
    @ViewBuilder
    var turnChartView : some View {
        TurnTimePieChart(
            data: game.commanders.map{
                PlayerTurnTimeChartData(id: $0.turnOrder,
                                        name: $0.displayNames,
                                        duration: $0.totalTurnTime)},
            selectedSector: $selectedChartSector
        )
        .background(Color.clear)
        .frame(height:80)
        .frame(maxWidth: 260, maxHeight:80)
        .padding(.vertical, 2*sidePad)
        .padding(.trailing, sidePad)
        .background(Color(.secondarySystemFill))
    }
    
    @ViewBuilder
    private var turnPercentageHeader: some View {
        Text("Turn Percentage")
            .foregroundStyle(Color.white.gradient)
            .bold()
            .padding(.top, sidePad)
    }
    
    @ViewBuilder
    private var turnChartFooter: some View {
        HStack(alignment: .firstTextBaseline){
            Spacer(minLength: 0)
            Text(pod.duration.formattedDuration())
                .font(.caption)
                .fontWeight(.medium)
            Spacer(minLength: 0)

            Text("\(pod.date.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundColor(Color.secondary)
        }
        .padding(.vertical, 0.5*sidePad)
        .padding(.leading, 2*sidePad)
        .padding(.bottom, 0.5*sidePad)
    }

    
    @ViewBuilder
    private var turnChartFooter_: some View {
        HStack{
            VStack(alignment: .leading){
                Text("\(pod.date.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(Color.secondary)
                    
                
                HStack(alignment: .firstTextBaseline){
                    Text(pod.duration.formattedDuration())
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Text("\(pod.playedTurns) Rounds")
                        .font(.caption)
                        .foregroundColor(Color.secondary)
                }
            }
            .padding(.vertical, 0.5*sidePad)
            .padding(.leading, 2*sidePad)
            .padding(.bottom, 0.25*sidePad)
        }
    }

    
    
    // MARK: - WATERFALL OF DEATH CHART + CARD
    ///*--------------------------------------------------------------------------------------------------------------------------*/
    ///*-------------------------------------------------------------------------------------------------------------*/
    @ViewBuilder
    var damageChart: some View {
        VStack(alignment: .center, spacing: 0.5*sidePad){
            damageChartHeader
                .padding(2.0)
            damageChartView
                .background(Color(.secondarySystemFill))
            damageChartFooter
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12.0))
    }
    
    
    @ViewBuilder
    var damageChartView : some View {
        LifeRangeChart(turnHistory: turnHistory, selectedTurn: $selectedTurn, playerNames: commanderNamesByTurnOrder)
        .background(Color.clear)
        .frame(height:80, alignment: .center)
        .frame(maxWidth: 240, maxHeight:80, alignment: .center)
        .padding(2*sidePad)
        .background(Color(.secondarySystemFill))
    }
    
    @ViewBuilder
    private var damageChartHeader: some View {
        Text("Loss of Life")
            .foregroundStyle(Color.white.gradient)
            .bold()
            .padding(.top, sidePad)
    }
    
    @ViewBuilder
    private var damageChartFooter: some View {
        Text("Turn: \(selectedTurn ?? turnHistory.count)")
            .font(.footnote)
            .fontWeight(.medium)
            .padding(.vertical, 4)
            .cornerRadius(12)
    }
    
    // MARK: - COMMANDER DAMAGE COMPANION CUBE CHART + CARD
    ///*--------------------------------------------------------------------------------------------------------------------------*/
    ///*-------------------------------------------------------------------------------------------------------------*/
    @ViewBuilder
    private var aggCommanderDamageHeader: some View {
        HStack{Spacer(minLength: 0)
            Text("Commander Damage")
                .foregroundStyle(Color.white.gradient)
                .bold()
                .padding(.top, sidePad)
            Spacer(minLength: 0)
        }
    }
    
    @ViewBuilder
    var cmdrCompanionCube: some View {
        VStack(alignment: .center, spacing: 0.0*sidePad){
            aggCommanderDamageHeader
                .padding(2.0)
                .frame(alignment:.center)
            HStack(alignment: .center, spacing:0){
                CmdrChartNumbersView
                Spacer(minLength: 0)
                aggCmdrChartView
            }
            .padding(.leading, 8)
            .padding(.trailing, 8)
            .background(Color(.secondarySystemFill))
            .background(Color(.secondarySystemFill))
           
            
            cmdrChartFooter
                .frame(alignment: .center)
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12.0))
        .frame(maxWidth: 250, alignment:.center)
    }
    
 
    var cmdrDmgMaxPlayerID:  Int {
        let dmgs = companionCubeData.damageMatrix.map { $0.reduce(0, +) }
        return dmgs.firstIndex(of: dmgs.max() ?? 0.0) ?? 0
    }
    
    var cmdrTotals: [Double] {
        Array(companionCubeData.damageMatrix.enumerated()).map  { idx,dmgRow in
            dmgRow.reduce(0, +)
        }
    }
    
    @ViewBuilder
    var CmdrChartNumbersView : some View {
    
        VStack(alignment: .trailing, spacing: 0.5*sidePad){
            HStack(alignment: .top, spacing:25){
                Text("Total")
                Text("%")
            }
            .font(.subheadline)
            .minimumScaleFactor(0.85)
            .fontWeight(.heavy)
            .lineLimit(1)
            .foregroundStyle(Color.white.gradient)
            .customStroke(color: Color.black, width: 0.5)
        
            HStack(spacing: 10){
                VStack(alignment: .trailing) {
                    ForEach(Array(cmdrTotals.enumerated()), id: \.offset) { idx,dmgRow in
                        
                        let starIndex = ( idx == cmdrDmgMaxPlayerID) ?  String("⭐️  ") : "   "
                                            
                        //Text(starIndex + String(format: "%.0f%", dmgRow))
                        Text(starIndex + String(Int( dmgRow)))
                            .minimumScaleFactor(0.65)
                            .lineLimit(1)
                            .foregroundStyle( getColor(for: idx).gradient)
                            .bold()
                        
                            //.customStroke(color: Color.black, width: 0.125)
                    }
                }
                
                VStack(alignment: .trailing){
                    ForEach(Array(cmdrTotals.enumerated()), id: \.offset) { idx,dmgRow in
                        Text(String(format: "%.1f%%", 100 * dmgRow / totalCmdrDmgInPod))
                            .minimumScaleFactor(0.65)
                            .lineLimit(1)
                            .foregroundStyle( getColor(for: idx).gradient)
                            .bold()
                    }
                }
            }
            .minimumScaleFactor(0.5)
            .bold()
            .font(.title3)
           
        }
        .padding(.horizontal, 0)
        .padding(.trailing, 12)
        .frame(maxHeight: 80)
    }
    
    var companionCubeData : PlayerChartData {
        PlayerChartData( damageMatrix: turnHistory.aggregatedCmdrDamageAsDoubles() )
    }
    var totalCmdrDmgInPod : Double {
        let totaldmg = companionCubeData.damageMatrix.map { $0.reduce(0,+)} .reduce(0,+)
        if totaldmg == 0.0 { return 1.0 }
        return totaldmg
    }

    @ViewBuilder
    var aggCmdrChartView : some View {
        VStack(alignment: .center, spacing: sidePad){
            CommanderCompanionCube( data: companionCubeData )
                .background(Color.clear)
                .frame(height: 80)
        }
        .padding(3*sidePad)
      
    }
    
    @ViewBuilder
    private var cmdrChartFooter: some View {
        VStack(alignment: .center){
            Text("Companion Cube Chart")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.vertical, 4)
                .padding(.trailing, 4)
                .cornerRadius(12)
        }
    }
 
    
    // MARK: - POISON COUNTER CHART + CARD
    ///*--------------------------------------------------------------------------------------------------------------------------*/
    ///*-------------------------------------------------------------------------------------------------------------*/
    @ViewBuilder
    var infectChart: some View {
        VStack(alignment: .center, spacing: 0.0*sidePad){
            poisonHeader
                .padding(4.0)
            HStack(alignment:.center){
                InfectQuadQuickView(infect: turnHistory.playerPoisonCounters())
                    .frame(width: 120, alignment:.bottom)
                    .padding(.vertical, -12.0)
                    .padding(.horizontal, -12.0)
                    .background(Color(.secondarySystemFill))
            }
            
            .background(Color(.secondarySystemFill))
            poisonFooter
                .padding(1.5)
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12.0))
 
    }
    
    
    @ViewBuilder
    private var poisonHeader: some View {
        Text("Infect")
            .foregroundStyle(Color.white.gradient)
            .bold()
            .padding(.top, sidePad)
    }
    
    @ViewBuilder
    private var poisonFooter: some View {
        Text("")
            .foregroundStyle(Color.white.gradient)
            .padding(.top, sidePad)
    }
    
    
    // MARK: - TURN-BY-TURN POD REPLAY CHART
    ///*--------------------------------------------------------------------------------------------------------------------------*/
    ///*--------------------------------------------------------------------------------------------------------------------------*/
    @ViewBuilder
    private var optimizedHeatMapGrid: some View {
        VStack(alignment: .leading, spacing: 6) {
            turnLabelsRowOptimized
            
            ForEach(commandersInTurnOrder, id: \.turnOrder) { commander in
                commanderRowOptimized(commander: commander)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Row for Turn Identification
    @ViewBuilder
    private var turnLabelsRowOptimized: some View {
        HStack(spacing: hSpacing) {
            /// Commander name column spacer
            Text("✨ Commanders ✨")
                .font(Font.system(.body).smallCaps())
                .bold()
                .customStroke(color: Color.black, width: 0.25)

                //.underline(true)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundStyle(Color.yellow.gradient)
                .frame(width: nameSpacing + hSpacing)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.brown.secondary)
                        .stroke( Color.white.gradient.opacity(0.5), lineWidth: 2.1)
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 26))
            
            /// Draws out the turn bars   [   T1  ][   T2   ]...
            ForEach(1..<roundTurnNumber(from: turnHistory.count-1)+1, id: \.self) { turnIndex in
                let turnsInRound = countTurnsInCurrentRound( at: turnIndex)
                    Text("T\(turnIndex)")
                        .font(.caption2)
                        .fontWeight(.black)
                        .customStroke(color: Color.black, width: 0.5)
                        .frame(width: CGFloat(turnsInRound) * (cellSize.width + hSpacing) - hSpacing, height: 18)
                        .background(Color.brown.gradient.opacity(0.49))
                        .background(Color(.tertiaryLabel).opacity(0.53))
                        //.background(Color(.tertiaryLabel))
                       
                        .cornerRadius(4)
                        .foregroundStyle(Color.white.gradient)
                       
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.clear)
                                .stroke( Color.brown.gradient, lineWidth: 5)
                        )
                        .clipShape(
                            RoundedRectangle(cornerRadius: 26))
            }
        }
    }
    
    
    private func roundTurnNumber(from startIndex: Int) -> Int {
        let activePlayerID = turnHistory[startIndex].activePlayer
        return turnHistory[...startIndex].filter {$0.activePlayer == activePlayerID } .count
    }
    
    private func maxPlayerTurns() -> [Int] {
        var turnsEachPlayerHad = [0,0,0,0]
        
        for turn in turnHistory {
            let turnPlayerID = turn.activePlayer
            turnsEachPlayerHad[turnPlayerID] += 1
        }
        return turnsEachPlayerHad
    }
    
    private func countTurnsInCurrentRound( at  startIndex: Int ) -> Int {
        guard startIndex < turnHistory.count else { return 1 }
        guard startIndex > -1 else { return 1 }
        return maxPlayerTurns().count(where: {$0 >= startIndex})
    }
    
    // MARK: - ROW - Commander Name and Actions/Effects for Commander
    @ViewBuilder
    private func commanderRowOptimized(commander: Commander) -> some View {
        HStack(spacing: hSpacing) {
            
            
            /// Commander info - column (Row 0)
            /// --------------------------------------------------
            VStack(alignment: .leading, spacing: vSpacing) {
                HStack {
                    Text(commander.displayNames)//.prefix(15))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(getColor(for: commander.turnOrder))
                    
                        .lineLimit(commander.displayNames.contains("\n") ? 2 : 1)
                        .minimumScaleFactor(0.01)
                    
                    
                    if commander.winner {
                        Image(systemName: "crown.fill")
                            .font(.caption2)
                            .foregroundColor(Color.yellow)
                    }
                }
                .frame(maxHeight: 0.666*cellSize.height)
                
                
                if commander.eliminated { let method = commander.eliminationMethod
                    HStack(spacing: 4) {
                        Text(method.displayName)
                            .font(.caption2)
                            .foregroundColor(Color.red)
                            .minimumScaleFactor(0.01)
                            .lineLimit(1)
                    }
                    .frame(maxHeight: 0.333*cellSize.height)
                    
                }
            }
            .frame(width: nameSpacing, alignment: .leading)
            .padding(.vertical, 2)
            .padding(.horizontal, 2)
            .background(commander.winner ? Color.yellow.opacity(0.2) : Color.clear)
            .cornerRadius(6)
            .onTapGesture(count:1) {
                if selectedChartSector == nil {
                    selectedChartRow = commander.name
                }
            }
            
            
            /// Turn cells - Rows
            /// --------------------------------------------------
            ForEach(0..<displayTurnCount, id: \.self) { turnIndex in
                optimizedTurnCell(
                    commander: commander,
                    turnIndex: turnIndex
                )
            }
            
        }
        .onChange(of: selectedChartSector) { if selectedChartSector != nil { selectedChartRow = nil } }
        .background(commander.name == selectedChartSector || commander.name == selectedChartRow ? getColor(for: commander.turnOrder).opacity(0.25) : Color.clear )
   
    }
    
    // MARK: - Individual Turn vs. Commander Cell
    @ViewBuilder
    private func optimizedTurnCell(commander: Commander, turnIndex: Int) -> some View {
        let turn = turnHistory[turnIndex]
        let isActiveTurn = turn.activePlayer == commander.turnOrder
        
        let lifeDelta = turn.deltaLife[commander.turnOrder]
        let cmdrDamage = turn.deltaCmdrDamage[commander.turnOrder][turn.activePlayer]
        
        // Determine if this player is removed and when

        let cmdrElimTurn = commander.eliminationTurnID
        let winTurn = turnHistory.count - 1
        let commanderWinner = commander.winner
      
        
        // Build life + commander colors depending on focus
        let lifeColor: Color? =
        (focus == .all || focus == .lifeOnly) && lifeDelta != 0
        ? bucketedDamageColor(delta: lifeDelta, type: "life")
        : nil
        
        let cmdrColor: Color? =
        (focus == .all || focus == .commanderOnly) && cmdrDamage != 0
        ? bucketedDamageColor(
            delta: cmdrDamage,
            baseColor: getColor(for: turn.activePlayer),
            type: "commander"
        )
        : nil
        
        // Decide how to render the base cell
        let cellBase: AnyView = {
            if cmdrElimTurn != nil && turn.id > cmdrElimTurn! {
                // Player already removed → no cell
                return AnyView(Rectangle().fill(Color.clear))
            }
            else if let life = lifeColor, let cmdr = cmdrColor {
                // Both → split cell
                return AnyView(
                    SplitCell(lifeColor: life, cmdrColor: cmdr, cellSize: cellSize)
                )
            }
            else if let life = lifeColor {
                // Only life
                return AnyView(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(life)
                )
            }
            else if let cmdr = cmdrColor {
                // Only commander
                return AnyView(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(cmdr)
                )
            }
            else if winTurn == turnIndex && commanderWinner {
                return AnyView(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.yellow.tertiary)
                )
            }
            
            else {
                // Still alive, no damage this turn → neutral filler
                return AnyView(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.quaternaryLabel))
                )
            }
        }()
        
        // Emoji overlays
        let overlay = ZStack {
         
            
          
            
            
            // High damage marker
            let totalDmg = calculateDamageDealt(by: commander.turnOrder, in: turn)
            if totalDmg > 10 {
                Text("🔥").font(.caption2)
                    .offset(x: -8, y: -8)
            }
            
           
            if let playedSolRing = podCastHistory?.wasSolRingPlayed(on: turnIndex, by: commander.turnOrder, in: game.gameID), playedSolRing {
                Text("💍")
                    .font(.caption2)
                    .offset(x: 8, y: -8)
            }
            
            if let activatedBombPod = podCastHistory?.wasBombPodPlayed(on: turnIndex, by: commander.turnOrder, in: game.gameID), activatedBombPod {
                Text("💣")
                    .font(.caption2)
                    .offset(x: -8, y: 8)
                    .shadow(color: Color.brown, radius: 1.5)
            }
            
            
            if let castCommander = podCastHistory?.wasTaxPaid(on: turnIndex, by: commander.turnOrder, in: game.gameID), castCommander {
                Text("👤")
                    .font(.caption2)
                    .customStroke(color: Color.black, width: 0.33)
                    .customStroke(color: getColor(for: commander.turnOrder), width: 0.66)
                    .offset(x: 0, y: 8)
            }
            
            /*
            if let commanderTaxForTurn = commander.taxTurns {
                if commanderTaxForTurn != nil {
                    if  commanderTaxForTurn.contains(turn.id) {
                        Text("👤")
                            .font(.caption2)
                            .customStroke(color: Color.mint, width: 0.5)
                            .offset(x: 0, y: 8)
                    }
                }
            }
            */
            
            if turn.id == (turnHistory.count-1) && winTurn == turnIndex && commanderWinner {
                if game.commanders.filter({ $0.eliminationMethod == EliminationMethod.altWin }).isEmpty == false {
                    Text("\(EliminationMethod.altWin.emojiOverlay)")
                        .font(.caption)
                        .customStroke(color: Color.black, width: 0.35)
                        .offset(x: 0, y: 0)
                }
                else {
                    Text("👑").font(.caption)
                        .customStroke(color: Color.black, width: 0.35)
                }
            }
            
            if let elimRound = commander.eliminationTurnID {
                if elimRound == turn.id {
                    Text(commander.eliminationMethod.emojiOverlay)
                        .font(.caption)
                        .customStroke(color: Color.black, width: 0.35)
                }
            }
            
        }
        
        return cellBase
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isActiveTurn ? Color.primary : Color.clear, lineWidth: 2)
                    .stroke(winTurn == turnIndex && commanderWinner ? Color.yellow : Color.clear, lineWidth: 2)
            )
            .overlay(overlay)
            .frame(width: cellSize.width, height: cellSize.height)
            .onTapGesture {
                print("Sheet triggered - Turn ID:\(turnIndex)")
                self.selectedTurn = turnIndex
                HapticFeedback.selection()
                showTurnDetails(turnNumber: turnIndex, commander: commander)
                showingGameDetails = true
            }
           
    }


    
    /// This function needs to be used to show the details in the view, not the terminal
    private func showTurnDetails(turnNumber: Int, commander: Commander) {
        // This could be expanded to show a detailed popup
        if turnNumber < turnHistory.count {
            let turn = turnHistory[turnNumber]
            print("Turn: \(turnNumber + 1)  Round: \(turn.id) Details:")
            print("Active Player: \(turn.activePlayer)")
            print("Commander: \(commander.name)")
            print("Eliminated This Round? \(commander.eliminationTurnID ?? 0) == \(turn.id) = \(commander.eliminationRound == turn.id) | \(commander.eliminationMethod.displayName )")
            print("Duration: \(turn.turnDuration)s")
            print("Life Changes: \(turn.deltaLife)")
            print("Commander Damage: \(turn.deltaCmdrDamage)")
            print("Infect: \(turn.deltaInfect)")
        }
    }
    
    // MARK: - Player State Analysis
    private func calculateDamageDealt(by playerIndex: Int, in turn: Turn) -> Int {
        var totalDamage = 0
        
        // Only count damage if this player is active
        guard turn.activePlayer == playerIndex else { return 0 }
        
        for targetIndex in 0..<4 where targetIndex != playerIndex {
            // Life damage dealt to others
            totalDamage += turn.deltaLife[targetIndex] < 0 ? abs(turn.deltaLife[targetIndex]) : -abs(turn.deltaLife[targetIndex])
            
            // Commander damage dealt to others
            totalDamage += turn.deltaCmdrDamage[targetIndex][playerIndex]
            totalDamage += turn.deltaPrtnrDamage[targetIndex][playerIndex]
        }
        return totalDamage
    }

    // MARK: - Helper Functions
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .orange))
            Text("Loading turn history...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
    }
    
    
    private func intensityToColor(_ intensity: Double) -> AnyShapeStyle {
        switch intensity {
        case 0.0..<0.2: return AnyShapeStyle(Color(.systemGray4))
        case 0.2..<0.4: return AnyShapeStyle(Color.blue.secondary)
        case 0.4..<0.6: return AnyShapeStyle(Color.orange.secondary)
        case 0.6..<0.8: return AnyShapeStyle(Color.red.secondary)
        default: return AnyShapeStyle(Color.red.secondary)
        }
    }
    
    
    // MARK: - TURN CHART LEGEND

    @ViewBuilder
    private var enhancedLegendView: some View {
        HStack(alignment: .bottom, spacing: 24) {

            // Intensity scale
            HStack(alignment: .firstTextBaseline){
                
                
                LegendSymbolOutline(color: Color.primary, caption: "Active")
                
                
                DamageLegend(type: "life", baseColor: .red)
                
                LegendSymbolOutline(color: Color.yellow, caption: "Winner")

        
               
            }
            .padding(sidePad)
            .background(Color(.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 12.0))
            
            
            HStack(alignment: .firstTextBaseline){
                LegendSymbol(symbol: "🔥", description: "High Dmg.")
                LegendSymbol(symbol: "💍", description: "Sol Ring")
                LegendSymbol(symbol: "💣", description: "Bomb Pod")
                LegendSymbol(symbol: "👤", description: "Cmdr. Cast")
            }
            .padding(sidePad)
            .background(Color(.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 12.0))
            
            
            
            
            
            // Symbols legend
                HStack(spacing: 12) {
                    ForEach(EliminationMethod.allCases, id:\.rawValue){ elim in
                        if elim != EliminationMethod.notEliminated &&
                            elim != EliminationMethod.notEliminated &&
                            elim != EliminationMethod.emptySeat{
                            
                            
                            LegendSymbol(symbol: elim.emojiOverlay, description: elim.displayName)
                        }
                    }
                }
                .padding(sidePad)
                .background(Color(.tertiarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 12.0))
            
        }
        .padding(.vertical, 0)
        .padding(.horizontal, 0)
        .cornerRadius(12)
    }
}


/**-----------------------------------------------------------------------------------------------------------**/
struct LegendSymbolOutline: View {
    let color: Color
    let caption: String
    
    @ViewBuilder
    var body: some View {
        VStack(spacing: 4) {
            Rectangle()
                .fill(Color.clear)
                .frame(width: 16, height: 16)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(color, lineWidth: 1.5)
                )
            Text(caption)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}


// MARK: - Draw Methods
/**-----------------------------------------------------------------------------------------------------------**/
struct LegendSymbol: View {
    let symbol: String
    let description: String
    
    @ViewBuilder
    var body: some View {
        VStack(spacing: 4) {
            Text(symbol)
                .font(.caption)
            Text(description)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

/**-----------------------------------------------------------------------------------------------------------**/
struct LegendImageSymbol: View {
    let symbol: EliminationMethod
    let description: String
    
    @ViewBuilder
    var body: some View {
        VStack(spacing: 4) {
            symbol.displayEmoji
                .font(.caption)
            Text(description)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

/**-----------------------------------------------------------------------------------------------------------**/
/// Returns a bucketed color for life or commander damage,
/// using percentages of the max possible value.
/// - For life: red = loss, cyan = gain.
/// - For commander: uses provided player color.
func bucketedDamageColor(
    delta: Int,
    baseColor: Color? = nil,
    type: String = "life"
) -> Color {
    guard delta != 0 else { return Color.clear }
    
    let dmg = abs(delta)
    let maxDmg = (type == "commander") ? 21.0 : 40.0
    let dmgPercent = Double(dmg) / maxDmg
    
    // 5 bucket thresholds
    let thresholds: [Double] = [0.05, 0.20, 0.40, 0.70, 1.0]
    let opacities: [Double]  = [0.25, 0.45, 0.65, 0.8, 1.0]
    
    // Find bucket index
    var bucketIndex = 0
    for (i, threshold) in thresholds.enumerated() where dmgPercent > threshold {
        bucketIndex = i
    }
    
    if type == "life" {
        // Negative delta = life loss (red), positive delta = life gain (cyan)
        let color = delta < 0 ? Color.red : Color.cyan
        return color.opacity(opacities[bucketIndex])
    } else {
        // Commander dmg always uses provided base color
        return (baseColor ?? .gray).opacity(opacities[bucketIndex])
    }
}

/**-----------------------------------------------------------------------------------------------------------**/
struct LifeLegend: View {
    private let thresholds: [Double] = [0.05, 0.20, 0.40, 0.70, 1.0]
    private let opacities: [Double]  = [0.25, 0.45, 0.65, 0.8, 1.0]
    
    @ViewBuilder
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Life Change").font(.caption).bold()
            
            HStack(spacing: 12) {
                // Life Loss (red)
                HStack(spacing: 6) {
                    ForEach(0..<thresholds.count, id: \.self) { idx in
                        Rectangle()
                            .fill(Color.red.opacity(opacities[idx]))
                            .frame(width: 16, height: 16)
                            .cornerRadius(3)
                    }
                }
                Text("Loss").font(.caption2)
                
                // Life Gain (cyan)
                HStack(spacing: 6) {
                    ForEach(0..<thresholds.count, id: \.self) { idx in
                        Rectangle()
                            .fill(Color.cyan.opacity(opacities[idx]))
                            .frame(width: 16, height: 16)
                            .cornerRadius(3)
                    }
                }
                Text("Gain").font(.caption2)
            }
        }
    }
}

/**-----------------------------------------------------------------------------------------------------------**/
struct SplitCell: View {
    let lifeColor: Color?
    let cmdrColor: Color?
    let cellSize: CGSize
    
    @ViewBuilder
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.1))
            
            
            if let life = lifeColor {
                Rectangle()
                    .fill(life)
                    .frame(width: cellSize.width, height: cellSize.height)
                    .clipShape(DiagonalHalf(topLeft: true))
            }
            
            if let cmdr = cmdrColor {
                Rectangle()
                    .fill(cmdr)
                    .frame(width: cellSize.width, height: cellSize.height)
                    .clipShape(DiagonalHalf(topLeft: false))
            }
        }
        .cornerRadius(6)
    }
}


/**-----------------------------------------------------------------------------------------------------------**/
/// Custom diagonal clipping shape
struct DiagonalHalf: Shape {
    let topLeft: Bool
    func path(in rect: CGRect) -> Path {
        var path = Path()
        if topLeft {
            path.move(to: rect.origin)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        } else {
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
        return path
    }
}


/**-----------------------------------------------------------------------------------------------------------**/
struct DamageLegend: View {
    let type: String
    let baseColor: Color
    
    private var thresholds: [Double] {
        [0.05, 0.20, 0.40, 0.70, 1.0] // 5 buckets
    }
    
    private var opacities: [Double] {
        [0.25, 0.45, 0.65, 0.8, 1.0]
    }
    
    @ViewBuilder
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<thresholds.count, id: \.self) { idx in
                VStack(spacing: 4) {
                    Rectangle()
                        .fill(baseColor.opacity(opacities[idx]))
                        .frame(width: 16, height: 16)
                        .cornerRadius(3)
                    
                    // Convert threshold to %
                    let percent = Int(thresholds[idx] * 100)
                    if idx == 0 {
                        Text("≤\(percent)%")
                            .font(.caption2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.33)
                            .foregroundColor(.secondary)
                    } else {
                        Text(" <\(percent)%")
                            .font(.caption2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.33)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}


/// Determines if a bomb-like effect occurred:
/// All players except exactly one took life loss.
func isBombTurn(_ turn: Turn) -> Bool {
    let damaged = turn.deltaLife.enumerated().filter { $0.element < 0 }.map { $0.offset }
    let safe = turn.deltaLife.enumerated().filter { $0.element >= 0 }.map { $0.offset }
    
    // Valid bomb turn if: exactly 3 players damaged, 1 not damaged
    return damaged.count == 3 && safe.count == 1
}

func isBombPlayer(_ turn: Turn) -> Int {
    let damaged = turn.deltaLife.enumerated().filter { $0.element < 0 }.map { $0.offset }
    let safe = turn.deltaLife.enumerated().filter { $0.element >= 0 }.map { $0.offset }
    
    // Valid bomb turn if: exactly 3 players damaged, 1 not damaged
    if safe.count == 1 {return safe.first!}
    return -1
}








/**-----------------------------------------------------------------------------------------------------------**/
struct PodSummary:  View {
    
    var pod : FinalPod
    var turns: [Turn]
    var totalGameDamage: Int?
    @State  var dmgHighlighted : Bool = false
    @Binding var focus: MetricFocus
    @State var turnRound: Turn? = nil
    
    var sidePad = 6.0
    
    var body: some View {
        VStack(spacing: 12){
            podTitleView
            VStack(alignment:.center, spacing: 0){
                //podWinnerTitle
                damageMetricsView
            }
            .background(Color(.secondarySystemFill))
            .background(Color(.secondarySystemFill))
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12.0))
    }
    
    
    private var podTitleView__: some View {
        Text("✨ \(winCommander()) ✨")
            .font(Font.system(.body).smallCaps())
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .foregroundStyle( pod.winnersColor.gradient)
            .padding(.top, sidePad)
    }
    private var podTitleView_: some View {
        Text("Pod Overview")
            .foregroundStyle(Color.white.gradient)
            .padding(.top, sidePad)
    }
    
    func winCommander() -> String {
        let winCom = pod.winningCommander
        var winName = ""
        if winCom == nil {
            winName = "No Winner"
        }
        else {
            winName = winCom!.name
        }
        
        return String(winName)
    }
    private var podTitleView: some View {
        VStack(alignment: .center, spacing: 0){
            Text("✨ \(winCommander()) ✨")
                .font(Font.system(.body).smallCaps())
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundStyle( pod.winnersColor.gradient)
            
            Text("Pod Winner")
                .font(Font.system(.caption).smallCaps())
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundStyle( Color.secondary.gradient)
        }
        .padding(.top, sidePad)
    }
    

    private var damageMetricsView: some View {
        HStack{
            VStack(spacing: 12) {
              
                MetricPill(title: "Win Method", value: "\(pod.winMethod)", color: pod.winnersColor)
                    .background( RoundedRectangle(cornerRadius: 12))
                                 
                MetricPill(title: "Life Lost", value: "\(turns.totalDamage)", color: Color.pink)
                    .background( RoundedRectangle(cornerRadius: 12)
                        .fill( focus == MetricFocus.lifeOnly ? AnyShapeStyle(Color.white.opacity(0.1)) : AnyShapeStyle( Color.clear))
                        .shadow(color: focus == MetricFocus.lifeOnly ? Color.mint : Color.clear, radius: 10)
                                 
                    )
                    .onTapGesture {
                        if focus == MetricFocus.commanderOnly {
                            focus =  MetricFocus.all
                        } else if focus == MetricFocus.all {
                            focus =  MetricFocus.lifeOnly
                        }
                        else {
                            focus = MetricFocus.lifeOnly
                        }
                    }
                
                
                
                MetricPill(title: "Cmdr Dmg", value: "\(turns.totalCommanderDamage)", color: Color.brown)
                    .background( RoundedRectangle(cornerRadius: 12)
                        .fill( focus == .commanderOnly ? AnyShapeStyle(Color.white.opacity(0.1)) : AnyShapeStyle( Color.clear))
                        .shadow(color: focus == .commanderOnly ? Color.mint : Color.clear, radius: 10)
                                 
                    )
                    .onTapGesture {
                        if focus == MetricFocus.lifeOnly {
                            focus =  MetricFocus.all
                        } else if focus == MetricFocus.all {
                            focus =  MetricFocus.commanderOnly
                        }
                        else {
                            focus = MetricFocus.commanderOnly
                        }
                    }
                // .onTapGesture { focus = (focus == .commanderOnly ? .all : .commanderOnly) }
                
              
            }
                    }
        .background(Color.clear)
        .padding(sidePad)
        //.background(Color(.secondarySystemFill))
    }
    
    var selectedTurnID : Int {
        let selectedTurn = turnRound
        if selectedTurn == nil {
            return turns.count - 1}
        return selectedTurn!.id
    }
}



private var playerDamageTitle: some View {
    Text("Damage Dealt by Players")
        .foregroundStyle(Color.white.gradient)
        .padding(.top, 6.0)
}

/**-----------------------------------------------------------------------------------------------------------**/






/**-----------------------------------------------------------------------------------------------------------**/
public struct TurnDetailsFocusView: View {
    
    //var turnNumber : Int
    var turn: Turn
    
    public var body: some View {
        return VStack(alignment: .leading, spacing: 12) {
            Text("Game Summary")
                .font(.title2)
                .fontWeight(.semibold)
            
            let stats = calculateGameStats(from: turn)
            
            VStack(spacing: 8) {
                StatRow(label: "Total Damage Dealt", value: "\(stats.totalDamage)")
                StatRow(label: "Commander Damage", value: "\(stats.commanderDamage)")
                StatRow(label: "Total Poison Counters", value: "\(stats.totalPoison)")
                StatRow(label: "Average Turn Duration", value: stats.avgTurnDuration.formattedDuration())
                StatRow(label: "Longest Turn", value: stats.longestTurn.formattedDuration())
                Text("Turn: \(turn.round)")
            }
            //.font(.subheadline)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private func calculateGameStats(from history: Turn) -> GameStatistics {
        var totalDamage = 0
        var commanderDamage = 0
        var totalPoison = 0
        var turnDurations: [Double] = []
        
        for turn in [history] {
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
















/**-----------------------------------------------------------------------------------------------------------**/
struct PodMapDemo_Previews: PreviewProvider {

    @ViewBuilder
    static var previews: some View {
        let previewUser = User_Info(uniqueID: "preview-user", paidApp: true)
        let previewAppInfo = App_Info(userInfo: previewUser)
        
        
        let demoData : [(FinalPod, [Turn], [Int:EliminationMethod])] = DemoDataGenerator.generateDemoGames(count: 1)
        let finalStates : [FinalPod] = demoData.map { $0.0 }
        let turnHistory : [[Turn]] = demoData.map { $0.1 }
        
        
        //let turns = turnHistory.first
        //let metrics = PodMetrics.build(from: turns!)
        @State var flippedPodID : String? = nil
        @State var trashable: Bool = false

        //let _ = print(metrics)
        ZStack{
            VStack{
                
                ForEach(finalStates, id: \.gameID) { data in
                 //   RecentGameCard(pod: data,
                //                   flippedPodID:$flippedPodID,
                        //                   showingExtended: trashable,
                  //                 onReturn: {})
                    let _ = print(data, "\n")
                }
                
                OptimizedGameFlowCard(
                    game: finalStates[0],
                    turnHistory:  turnHistory[0],
                    on_Appear: { }
                )
                
            }
        }
        .environmentObject(previewAppInfo)
        .previewDevice("iPhone 12 mini")
    }
}
