import SwiftUI
import Podwork


public struct CommanderDamagePlotData: Identifiable,  Hashable {
    public let id = UUID()
    public var playerIndex: Int = 0
    public var totalCmdrDamage: Int = 0
    public var deltaCmdrDamage: Int = 0
    public var totalPrtnrDamage: Int = 0
    public var deltaPrtnrDamage: Int = 0
    public var hasPartner: Bool = false
    public var activeCmdrIndex: Int = 0
    
    public func makePlotData(from cmdrDmg : [Int], with deltaCmdrDmg : [Int] ) -> [CommanderDamagePlotData] {
        let cmdrDmgPlayerData = zip(cmdrDmg, deltaCmdrDmg).enumerated().map(
            { idx, dmgTup in
                CommanderDamagePlotData(playerIndex: idx, totalCmdrDamage: dmgTup.0, deltaCmdrDamage: dmgTup.1)
            })
        return cmdrDmgPlayerData
    }
    
    public static func plotData(for playerID:Int, currentDamages:[[Int]], partners:[Bool], activeCommanders:[Int]) -> [CommanderDamagePlotData] {
        var data : [CommanderDamagePlotData] = []
        currentDamages.enumerated().forEach { (i,z) in
            data.append(CommanderDamagePlotData(
                playerIndex: i,
                totalCmdrDamage: z[0],
                deltaCmdrDamage: z[1],
                totalPrtnrDamage: z[2],
                deltaPrtnrDamage: z[3],
                hasPartner: partners[i],
                activeCmdrIndex: activeCommanders[i]
            ))
        }
        return data
    }
}


// -------------------------------------------------------------------
/**/
/**/
@MainActor
public struct ConcentricCommanderDamageView: View {
    var damageData: [CommanderDamagePlotData]
    var currentPlayer: Int
    var attackingPlayer: Int
    private let baseRadius: CGFloat = GameUIConstants.podSize
    private let ringSpacing: CGFloat = 10
    private let ringThickness: CGFloat = 12
    private let deltaAngle: Double = 360.0 / 21.0
    
    @State private var containerSize: CGSize = UIScreen.main.bounds.size
    @State private var selectedCommander: CommanderDamagePlotData?
    @State private var selectedIndex: Int = -1
    @State private var isIndexSelected: Bool = false
    
    //// Animation states
    @State private var animatingRingIndex: Int = 0
    @State private var animationDirection: Int = 1 /// 1 for outward, -1 for inward
    @State private var animationTimer: Timer?
    @State private var pulseOpacity: Double = 0.0
    
    private let timeToNextRing = 1.25/8.0
    private let fullTimeForBounce = 1.25
    private let synodic: Double = 29.5
    private let synodicMonths: Double = 223.0 // time for color cycle (new-full)
    private let draconic: Double =  27.2
    private let draconicMonths: Double =  242.0 // ring dwell time
    private let anomalistic: Double = 27.5
    private let anomalisticMonths: Double = 239.0 // time for shell cycles
    private let saros: Double = 6585 + (8.0/24.0)
    private let fps: Double = 1.0/30.0
    
    var showAnimation : Bool?
    private let oneArcSection: CGFloat = (360.0 / 21)
    
    private var unwrapShowAnimation : Bool {
        if let showAnimation_ = showAnimation {
            return showAnimation_
        }
        return false
    }
    
    /// Check if any delta damage exists
    private var shouldAnimate: Bool {
        reSortDamageData.contains { data in
            ( data.deltaCmdrDamage > 0 || data.deltaPrtnrDamage > 0 )
        } && unwrapShowAnimation 
    }
    
    @MainActor
    private var reSortDamageData: [CommanderDamagePlotData] {
        let reSortedIndices = PlayerLayoutConfig.config(for: currentPlayer).concentricOrder
        return  reSortedIndices.map { damageData[$0] }
        
    }
    
    private var whichPlayerDamaging: Int {
        guard attackingPlayer < GameConstants.maxPlayers else {return -1}
        return attackingPlayer
    }
    

    
    private var plotRadius : CGFloat {
        0.5 * containerSize.width
    }
    
    private var baseRadiusGeom : CGFloat {
        0.6 * baseRadius
    }
    
    private var widthRatio : CGFloat {
        0.1 * containerSize.width
    }
    
    private var ringSpacingGeom : CGFloat {
        0.15 * ringThicknessGeom
    }
    
    private var ringThicknessGeom : CGFloat {
        1.50 * 0.666 * plotRadius / ( 2 * Double(damageData.count) )
    }
    
    private var bkgRingThicknessGeom : CGFloat {
        0.55 * ringThicknessGeom
    }
    
    
    @MainActor
    private func damageDataDisplayOrder(side: Int) -> [CommanderDamagePlotData] {
        if side == 0 {
            return topBottomDisplayOrder(side: side, top: damageData.prefix(2).reversed(), bottom: damageData.suffix(2))}
        return topBottomDisplayOrder(side: side,top:damageData.prefix(2).reversed(), bottom:damageData.suffix(2))
    }
    
    
    /// Flip the labels for commander damage for top/bottom perspective.
    @MainActor
    private func topBottomDisplayOrder(side: Int, top topRowDamageData : [CommanderDamagePlotData],bottom bottomRowDamageData : [CommanderDamagePlotData]  ) ->  [CommanderDamagePlotData] {
        if PlayerLayoutConfig.config(for: currentPlayer).isRotated {
            return side == 0 ? [bottomRowDamageData[1], bottomRowDamageData[0]] :  [topRowDamageData[1], topRowDamageData[0]]
        }
        return side == 0 ? topRowDamageData : bottomRowDamageData
    }
    
    private func markerOffset(for index: Int) -> Int {
        let offset : [Int] = [0,0,0,0]
        return offset[index]
    }
    
    func maxRadius() -> CGFloat {
        baseRadiusGeom + CGFloat(damageData.count) * (ringThicknessGeom + ringSpacingGeom)
    }
    
    @ViewBuilder
    public var body: some View {
        ZStack(alignment: .center){
            ringsAndThings
                .opacity(0)
            PodArcs()
                .frame(maxWidth: 0.5*maxRadius(), maxHeight: 0.5*maxRadius() )
        }
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        containerSize = geometry.size
                        startAnimationIfNeeded()
                    }
                    .onChange(of: geometry.size) { _, newSize in
                        containerSize = newSize
                    }
            }
        )
        .onChange(of: damageData) { _, _ in
            startAnimationIfNeeded()
        }
        .onDisappear {
            animationTimer?.invalidate()
        }
    }
    
    
    
    @MainActor
    private func startAnimationIfNeeded() {
        animationTimer?.invalidate()
        
        guard shouldAnimate else {
            animatingRingIndex = -1
            pulseOpacity = 0.0
            return
        }
        
        animatingRingIndex = 0
        animationDirection = 1
        
        //let duration = 0.250
        pulseOpacity = 1.0
        
        animationTimer  = Timer.scheduledTimer(withTimeInterval: synodic*fps, repeats: true) { _ in
            
            
            // anomalistic (size of pod particle
            DispatchQueue.main.asyncAfter(deadline: .now() + draconic*fps) {
               // withAnimation(.easeInOut(duration: 3.5*timeToNextRing )) {
                    moveToNextRing()
            //    }
            }
            
           // DispatchQueue.main.asyncAfter(deadline: .now() + 2*timeToNextRing) {
           //     moveToNextRing()
           // }
        }
    }
    
    
    @MainActor
    func changeOpacity( _ val : Double) {
        pulseOpacity = val
    }
    
    private func moveToNextRing() {
        animatingRingIndex += animationDirection
        if animatingRingIndex >= damageData.count {
            animatingRingIndex = damageData.count - 1
            animationDirection = -1
        } else if animatingRingIndex < 0 {
            animatingRingIndex = 0
            animationDirection = 1
        }
    }
    
    private func detectRing(at radius: CGFloat) -> Int? {
        for (index, _) in reSortDamageData.enumerated().reversed() {
            let minR = baseRadiusGeom + CGFloat(index) * (ringThicknessGeom + ringSpacingGeom) - ringThicknessGeom / 2
            let maxR = minR + ringThicknessGeom
            if radius >= minR && radius <= maxR {
                return index
            }
        }
        return nil
    }
    
    
    @ViewBuilder
    private func cmdrPrtnrDmgDisplay(cmdr: CommanderDamagePlotData) -> some View {
        VStack(alignment: .leading, spacing: 2){
            HStack (alignment:.top, spacing: 6) {
                PodCommanderPartnerDamageView(cmdrDmg: cmdr.totalCmdrDamage, color: getColor(for: cmdr.playerIndex), active: cmdr.activeCmdrIndex == 0)
                if cmdr.deltaCmdrDamage != 0 {
                    DeltaCmdrDamageLabel(cmdr:cmdr)
                }
            }
            if cmdr.hasPartner {
                HStack(alignment:.top, spacing: 6){
                    PodCommanderPartnerDamageView(cmdrDmg: cmdr.totalPrtnrDamage, color: getColor(for: cmdr.playerIndex), active:cmdr.activeCmdrIndex == 1)
                    if cmdr.deltaPrtnrDamage != 0 {
                        DeltaCmdrDamageLabel(cmdr:cmdr, isPartner: true)
                    }
                }
            }
        }
        
    }
    
    
    
    var ringsAndThings : some View {
        HStack{
            LazyHGrid(rows: [GridItem.init( .flexible(), alignment: .topLeading),
                             GridItem.init( .flexible(), alignment: .bottomLeading)]) {
                ForEach( damageDataDisplayOrder(side:0) ) { cmdr in
                    cmdrPrtnrDmgDisplay(cmdr: cmdr)
                    //cmdrDmgDisplay(cmdr: cmdr)
                        .opacity( (cmdr.totalCmdrDamage == 0) && (cmdr.deltaCmdrDamage == 0) ? 0.0 : 1.0 )
                }
            }
            Spacer()
            LazyHGrid(rows: [GridItem.init( .flexible(), alignment: .topTrailing),
                             GridItem.init( .flexible(), alignment: .bottomTrailing)]) {
                ForEach( damageDataDisplayOrder(side:1) ) { cmdr in
                    cmdrPrtnrDmgDisplay(cmdr: cmdr)
                    //cmdrDmgDisplay(cmdr: cmdr)
                        .opacity( (cmdr.totalCmdrDamage == 0) && (cmdr.deltaCmdrDamage == 0) ? 0.0 : 1.0 )
                }
            }
        }
    }
    
    private var letalCmdrDmg : Bool {
        for data in reSortDamageData {
            if (data.totalCmdrDamage + data.deltaCmdrDamage) >= 21 || (data.totalPrtnrDamage + data.deltaPrtnrDamage) >= 21
            { return true}
        }
        return false
    }
    
    
    @ViewBuilder
    private func PodArcs() -> some View{
        ZStack (alignment: .center){
            ForEach(reSortDamageData, id: \.self) { data in
    
                let index = reSortDamageData.firstIndex(of: data)!
                let playerIndex = data.playerIndex
                
                /// lowest index should be the current_player so that its the inner most ring
                let radius = baseRadiusGeom + CGFloat(index) * (ringThicknessGeom + ringSpacingGeom)
                let delta = (data.hasPartner ? 0.5*bkgRingThicknessGeom : 0)
                let spliter = (data.hasPartner ?  0.45 : 1.0)
                let isPulsing = shouldAnimate && animatingRingIndex == index
                let playerDmgColor = whichPlayerDamaging == -1 ? Color.red : getColor(for: whichPlayerDamaging)
                let dmgColor = letalCmdrDmg ? Color.red : playerDmgColor
                
                ZStack{
                    /// Background Rings - will split if Partner
                    if data.hasPartner {
                        Circle()
                            .stroke( ( (data.totalCmdrDamage > 0) || (data.deltaCmdrDamage > 0)) ?
                                     (data.activeCmdrIndex == 1 ? Color.black.opacity(0.0715) : Color.black.opacity(0.125)) :
                                        Color.clear, lineWidth: 0.5*bkgRingThicknessGeom )
                            .frame(width: (2 * (radius - delta)), height: (2 * (radius - delta) ) )
                    }
                    
                    Circle()
                        .stroke( ( (data.totalCmdrDamage > 0) || (data.deltaCmdrDamage > 0)) ?
                                 (data.activeCmdrIndex == 0 ? Color.black.opacity(0.0715) : Color.black.opacity(0.125)) :
                                    Color.clear, lineWidth: spliter*bkgRingThicknessGeom )
                        .frame(width: (2 * (radius + delta)), height: (2 * (radius + delta) ) )
                    
                    /// Subtle pulsating highlight for active rings
                    if isPulsing {
                        Circle()
                            .stroke(dmgColor.opacity(pulseOpacity * 1.0), lineWidth: 0.25*bkgRingThicknessGeom)
                            .frame(width: (2 * (radius + delta + 1)), height: (2 * (radius + delta + 1)))
                            .blur(radius: 0.8)
                        
                        if data.hasPartner {
                            Circle()
                                .stroke(dmgColor.opacity(pulseOpacity * 1.00), lineWidth: 0.25*bkgRingThicknessGeom)
                                .frame(width: (2 * (radius - delta - 1)), height: (2 * (radius - delta - 1)))
                                .blur(radius: 0.8)
                        }
                    }
                    
                    
                    /// Colored Part of the Ring
                    ArcSection(of:radius, for:playerIndex, with:data.totalCmdrDamage, new:data.deltaCmdrDamage, deltaRadius: -delta, splitRing: spliter, isPulsing: isPulsing)
                    
                    if data.hasPartner {
                        ArcSection(of:radius, for:playerIndex, with:data.totalPrtnrDamage, new:data.deltaPrtnrDamage, deltaRadius: +delta, splitRing: spliter, isPulsing: isPulsing)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func ArcSection(of radius:Double, for playerID:Int, with prevDamage:Int, new damageSegments:Int , deltaRadius: Double = 0, splitRing: Double = 1.0, isPulsing: Bool = false) -> some View {
        
        let playerColor = getColor(for: playerID)
        let oddColor = playerColor.mix(with: Color.white, by: -0.125)
        let evenColor = playerColor.mix(with: Color.yellow, by: 0.125)

        /// Much more subtle color variations during pulsing
        let baseColor = isPulsing ?
        playerColor.opacity(1.0 + pulseOpacity * 0.15) :
        playerColor.opacity(1.0)
        let deltaColor = isPulsing ?
        Color.red.opacity(0.75 + pulseOpacity * 0.15) :
        playerColor.opacity(0.25)
        
        return  ZStack{

            ///Coloured Arc Segments from Previous Turns Commander Damage
            ForEach(0..<prevDamage, id: \.self) { dmgIndex in
                let idxPairity = (dmgIndex + playerID) % 2 == 0
                let baseColor = idxPairity ? evenColor : oddColor
                ArcSegment(
                    startAngle: .degrees(Double(dmgIndex + markerOffset(for: playerID)) * oneArcSection),
                    endAngle:.degrees(Double(dmgIndex + 1 + markerOffset(for: playerID)) * oneArcSection)
                )
                .stroke(baseColor, lineWidth:  splitRing * ringThicknessGeom )
                .shadow(color: Color.black, radius: 2)
                .aspectRatio(CGSize(width: 1, height: 1), contentMode: .fill)
                .frame(width: 2 * (radius + deltaRadius) , height: 2 * (radius + deltaRadius ))
            }
            /// Gray pending damage from this turn
            ForEach(0..<damageSegments, id: \.self) { dmgSegmentIndex in
                ArcSegment(
                    startAngle:
                            .degrees(Double(dmgSegmentIndex + markerOffset(for: playerID) + prevDamage) * oneArcSection),
                    endAngle:
                            .degrees(Double(dmgSegmentIndex + 1 + markerOffset(for: playerID) + prevDamage) * oneArcSection)
                )
                .stroke(deltaColor, lineWidth: splitRing * ringThicknessGeom )
                .shadow(color: Color.black, radius: 2)
                .aspectRatio(CGSize(width: 1, height: 1), contentMode: .fill)
                .frame(width: 2 * (radius + deltaRadius) , height: 2 * (radius + deltaRadius ))
            }
            
            if damageSegments != 0 && (damageSegments + prevDamage) <= 21 {
                let startingRadians = (-2 * .pi) + toRad(135) + toRad(Double(  prevDamage + damageSegments  )*oneArcSection)
                let endingRadians = toRad(135)
                
                //
               // CircularMotionView(color: baseColor, radius: (radius + deltaRadius) , startAngle: startingRadians, endAngle: endingRadians, duration: anomalistic*fps )
            }
        }
    }
}





// ---------------------------------------------------------------------------------


@MainActor
public struct CommanderDamageDeltasOnlyView: View {
    var damageData: [CommanderDamagePlotData]
    var currentPlayer: Int
    var attackingPlayer: Int
    private let baseRadius: CGFloat = GameUIConstants.podSize
    private let ringSpacing: CGFloat = 10
    private let ringThickness: CGFloat = 12
    private let deltaAngle: Double = 360.0 / 21.0
    
    @State private var containerSize: CGSize = UIScreen.main.bounds.size
    @State private var selectedCommander: CommanderDamagePlotData?
    @State private var selectedIndex: Int = -1
    @State private var isIndexSelected: Bool = false
    
    //// Animation states
    @State private var animatingRingIndex: Int = 0
    @State private var animationDirection: Int = 1 /// 1 for outward, -1 for inward
    @State private var animationTimer: Timer?
    @State private var pulseOpacity: Double = 0.0
    
    private let timeToNextRing = 1.25/8.0
    private let fullTimeForBounce = 1.25
    private let synodic: Double = 29.5
    private let synodicMonths: Double = 223.0 // time for color cycle (new-full)
    private let draconic: Double =  27.2
    private let draconicMonths: Double =  242.0 // ring dwell time
    private let anomalistic: Double = 27.5
    private let anomalisticMonths: Double = 239.0 // time for shell cycles
    private let saros: Double = 6585 + (8.0/24.0)
    private let fps: Double = 1.0/30.0
    
    var showAnimation : Bool?
    private let oneArcSection: CGFloat = (360.0 / 21)
    
    private var unwrapShowAnimation : Bool {
        if let showAnimation = showAnimation {
            return showAnimation
        }
        return false
    }
    
    /// Flip the labels for commander damage for top/bottom perspective.
    @MainActor
    private func topBottomDisplayOrder(side: Int, top topRowDamageData : [CommanderDamagePlotData],bottom bottomRowDamageData : [CommanderDamagePlotData]  ) ->  [CommanderDamagePlotData] {
        if PlayerLayoutConfig.config(for: currentPlayer).isRotated {
            return side == 0 ? [bottomRowDamageData[1], bottomRowDamageData[0]] :  [topRowDamageData[1], topRowDamageData[0]]
        }
        return side == 0 ? topRowDamageData : bottomRowDamageData
    }
    
    @MainActor
    private func damageDataDisplayOrder(side: Int) -> [CommanderDamagePlotData] {
        if side == 0 {
            return topBottomDisplayOrder(side: side, top: damageData.prefix(2).reversed(), bottom: damageData.suffix(2))}
        return topBottomDisplayOrder(side: side,top:damageData.prefix(2).reversed(), bottom:damageData.suffix(2))
    }
    
    @ViewBuilder
    private func cmdrPrtnrDmgDisplay(cmdr: CommanderDamagePlotData) -> some View {
        VStack(alignment: .leading, spacing: 2){
            HStack (alignment:.top, spacing: 6) {
                PodCommanderPartnerDamageView(cmdrDmg: cmdr.totalCmdrDamage, color: getColor(for: cmdr.playerIndex), active: cmdr.activeCmdrIndex == 0)
                    .opacity(cmdr.totalCmdrDamage == 0 ? 0 : 1 )

               // if cmdr.deltaCmdrDamage != 0 { DeltaCmdrDamageLabel(cmdr:cmdr) }
            }
            if cmdr.hasPartner {
                HStack(alignment:.top, spacing: 6){
                    PodCommanderPartnerDamageView(cmdrDmg: cmdr.totalPrtnrDamage, color: getColor(for: cmdr.playerIndex), active:cmdr.activeCmdrIndex == 1)
                        .opacity(cmdr.totalCmdrDamage == 0 ? 0 : 1 )
                 // if cmdr.deltaPrtnrDamage != 0 {DeltaCmdrDamageLabel(cmdr:cmdr, isPartner: true)}
                }
            }
        }
        
    }
    
    
    
    var ringsAndThings : some View {
        HStack{
            LazyHGrid(rows: [GridItem.init( .flexible(), alignment: .topLeading),
                             GridItem.init( .flexible(), alignment: .bottomLeading)]) {
                ForEach( damageDataDisplayOrder(side:0) ) { cmdr in
                    cmdrPrtnrDmgDisplay(cmdr: cmdr)
                    //cmdrDmgDisplay(cmdr: cmdr)
                        .opacity( (cmdr.totalCmdrDamage == 0) && (cmdr.deltaCmdrDamage == 0) ? 0.0 : 1.0 )
                }
            }
            Spacer()
            LazyHGrid(rows: [GridItem.init( .flexible(), alignment: .topTrailing),
                             GridItem.init( .flexible(), alignment: .bottomTrailing)]) {
                ForEach( damageDataDisplayOrder(side:1) ) { cmdr in
                    cmdrPrtnrDmgDisplay(cmdr: cmdr)
                    //cmdrDmgDisplay(cmdr: cmdr)
                        .opacity( (cmdr.totalCmdrDamage == 0) && (cmdr.deltaCmdrDamage == 0) ? 0.0 : 1.0 )
                }
            }
        }
    }
    
    
    public var body : some View {
        ringsAndThings
            
        }
        
        
    }



// ---------------------------------------------------------------------------------

public struct DeltaCmdrDamageLabel : View {
    public let cmdr: CommanderDamagePlotData
    public var isPartner: Bool? = nil
    
    var dmgNumber : String {
        guard isPartner == nil else { return String(cmdr.deltaPrtnrDamage) }
        return String(cmdr.deltaCmdrDamage) }
    
    var showOpacity : Double {
        if isPartner == nil { return  (cmdr.deltaCmdrDamage > 0 ? 1.0 : 0.0) }
        return  (cmdr.deltaPrtnrDamage > 0 ? 1.0 : 0.0)
    }
    
    var prtnrCmdrIndex : Int {
        if isPartner == nil { return 0 }
        return 1
    }
    
    public var body: some View {
        HStack(spacing:0){
            
            Text("+")
            Text(dmgNumber)
        }
            .font(.headline)
            .monospacedDigit()
            //.bold()
            .fontWeight(.heavy)
            .foregroundColor( cmdr.activeCmdrIndex == prtnrCmdrIndex ? Color.white : getColor(for: cmdr.playerIndex)
            )
            .customStroke(color: Color.black, width: 0.750)
            .customStroke(color: cmdr.activeCmdrIndex == prtnrCmdrIndex ? getColor(for: cmdr.playerIndex) :  Color.white, width: 0.750)
            .customStroke(color: Color.black, width: 0.750)
            .opacity( showOpacity )
    }
}

/**/
// ---------------------------------------------------------------------------------

@MainActor
struct ArcSegment: Shape {
    let startAngle: Angle
    let endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = 0.5 * min(rect.width, rect.height)
        
        path.addArc(center: center, radius: radius,
                    startAngle: startAngle + .degrees(135),
                    endAngle: endAngle + .degrees(135),
                    clockwise: false)
        return path
    }
}



// ---------------------------------------------------------------------------------

// ---------------------------------------------------------------------------------
#Preview {
    CommanderDamageDeltasOnlyView(
        damageData: CommanderDamagePlotData.plotData(for: 0, currentDamages: [[3,3,4,0],[0,0,1,2],[0,0,10,5],[4,8,0,0]], partners:[false,false,true,true], activeCommanders: [0,0,1,1]), currentPlayer : 0, attackingPlayer: 3 , showAnimation: true )
}

#Preview {
    ConcentricCommanderDamageView(
        damageData: CommanderDamagePlotData.plotData(for: 2, currentDamages: [[1,0,0,0],[1,0,0,0],[0,0,0,0],[1,0,0,1]], partners:[false,false,true,true], activeCommanders: [0,0,0,1]), currentPlayer : 1, attackingPlayer: 0 )
}
#Preview {
    ConcentricCommanderDamageView(
        damageData: CommanderDamagePlotData().makePlotData(from: [10,10,10,10], with: [4,2,3,4]) , currentPlayer : 2, attackingPlayer: 0 )
}


#Preview {
    Button( action:  {
        let _ = print(CommanderDamagePlotData().makePlotData(from: [1,2,3,1], with: [20,3,2,1]) )
    })  { Text("Test") }
}
