import SwiftUI
import CoreHaptics
import Podwork
import Foundation



@Observable
public class QuadrantInputStates {
    public var isPresented: [Bool] = CommonConstants.resetAllPlayers
    public var showingRating: [Bool] = CommonConstants.resetAllPlayers
    public var ratingIndex: [Int] = [0,0,0,0]
    public var deckRatings: [[Int]] = [[0,0,0,0], [0,0,0,0], [0,0,0,0], [0,0,0,0]]
}



@Observable
public class QuadrantDamageStates {
    var showDamageButtonInQuadrant: [Bool] = CommonConstants.resetAllPlayers
    var damageFromQuadrantColors: [Color] = [.green, .orange, .blue, .purple, .black]
    var commanderDamage: [Bool] = CommonConstants.resetAllPlayers
}


@Observable
public class PodDragState {
    // MARK: - Per-player state (use array index = player index)
    public var draggedOffsets: [CGSize]  // Player Pods
    public var highlightedPodIndex: [Int]
    public var bombPodActive: [Bool]
    public var podCenters: [CGPoint?]
    public var damageLabelFrames: [CGRect?]
    public var commanderBarFrames: [CGRect?]
    public var centerPodFrames: [CGRect?]
    public var commanderDamage: [Bool]
    public var showDamageButtonInQuadrant: [Bool]
    public var damageFromQuadrantColors: [Color]
    public var draggedPhiOffsets: [CGSize]  // Phi Pods
    public var phiPodCenters: [CGPoint?]
    public var showPoisonDots: [Bool]
    public var solrings: [SolRingGesture]
    public var animateSolRing: [Bool]
    public var isPodDragging: [Bool]
    public var taxUp: [Bool]
    
    // MARK: - Global drag state
    public var highlightedDamageLabelIndex: Int? = nil
    public var highlightedCommanderBarIndex: Int? = nil
    public var highlightedCenterPodIndex: Int? = nil
    public var highlightedPhiQuadrantIndex: Int? = nil
    public var bombModeActive = false
    public var playerDraggedPodOntoCenterPod: Int = 0
    public var isBombPodDragging: Bool = false
    public var isBombShakingQuadrants: Bool = false
    public var centerRotation: Bool = false
    public var containerSize: CGSize = .zero
    
    public var dragTrails: [SimpleTrailManager] = []
    
    // MARK: - Update throttling
    private var lastUpdateTime = Date()
    private let updateInterval: TimeInterval = 1.0/60.0 //10.0 / 60.0 // ~60fps
    
    // MARK: - Init
    @MainActor public init(playerCount: Int = 4) {
        draggedOffsets = Array(repeating: .zero, count: playerCount)
        highlightedPodIndex = Array((0..<playerCount))
        bombPodActive = Array(repeating: false, count: playerCount)
        podCenters = Array(repeating: nil, count: playerCount)
        damageLabelFrames = Array(repeating: nil, count: playerCount)
        commanderBarFrames = Array(repeating: nil, count: playerCount)
        centerPodFrames = Array(repeating: nil, count: playerCount)
        commanderDamage = CommonConstants.resetAllPlayers
        showDamageButtonInQuadrant = CommonConstants.resetAllPlayers
        damageFromQuadrantColors = Array(repeating: Color.black, count: playerCount)
        draggedPhiOffsets = Array(repeating: .zero, count: 2) // One for each side
        phiPodCenters = Array(repeating: nil, count: 2)
        showPoisonDots = CommonConstants.resetAllPlayers
        solrings = (0..<playerCount).map { _ in SolRingGesture() }
        animateSolRing = CommonConstants.resetAllPlayers
        isPodDragging = Array(repeating: false, count: playerCount)
        taxUp = Array(repeating: false, count: playerCount)
        
//        dragTrails = Array( repeating: SimpleTrailManager(
//            config: SimpleTrailConfig(
//                duration: 1.0,
//                thickness: 50,
//                color: Color.red,
//                fadeOut: true
//            )),count:playerCount)
        
        dragTrails = (0..<playerCount).map { idx in SimpleTrailManager(
            config: SimpleTrailConfig(
                duration: 1.0,
                thickness: 50,
                color: getColor(for:idx).mix(with: Color.white, by: 0.61),
                fadeOut: true
            ))}
    }
    
    // MARK: - Helpers
    func shouldUpdate() -> Bool {
        let now = Date()
        guard now.timeIntervalSince(lastUpdateTime) > updateInterval else { return false }
        lastUpdateTime = now
        return true
    }
    
    func findOverlappingFrame(point: CGPoint, in frames: [CGRect?]) -> Int? {
        for (i, frame) in frames.enumerated() {
            if let frame, frame.contains(point) {
                return i
            }
        }
        return nil
    }
    
    public func resetUIElements() {
        self.resetCommanderDamageButtons()
        self.resetHighlights()
        self.resetShowPoison()
    }
    private func resetCommanderDamageButtons() {
        self.commanderDamage = CommonConstants.resetAllPlayers
        self.showDamageButtonInQuadrant = CommonConstants.resetAllPlayers
    }
    private func resetHighlights() {
        self.highlightedPodIndex = [0,1,2,3]
    }
    private func resetShowPoison() {
        self.showPoisonDots = CommonConstants.resetAllPlayers
    }
    
}



@MainActor
public struct PodView: View {
    let quadrant: Quadrant
    @Bindable var game: GameState
    @Bindable var dragState: PodDragState

    @GestureState private var dragOffset: CGSize = .zero

    var index : Int { quadrant.rawValue}
    var playerConfig: PlayerLayoutConfig {  PlayerLayoutConfig.config(for: index) }
    private var isActivePlayer: Bool { game.activePlayer() == index }
    private var isEliminated: Bool { game.players[index].isPlayerEliminated() || game.players[index].winner == true }
    private let halfPodSize = GameUIConstants.podSize * 0.5
    
    private var lifeRatio: CGFloat {
        let currentLife = game.showLife(playerID: index)
        return max(0, min(1, CGFloat(currentLife) / CGFloat(GameConstants.defaultStartingLife)))
    }
    
    //@StateObject private var trail = dragState.dragTrails[self.index]

    private func activePodLabel() -> String {
        var podText = ""
        if isActivePlayer { podText = game.checkIfFirstTurn() ?  "🎬" : "💫" }
        return podText
    }
    
    
    @MainActor
    @ViewBuilder
    public var body: some View {
        ZStack{
           
            PodContent(
                index: index,
                isActivePlayer: isActivePlayer,
                lifeRatio: lifeRatio,
                playerConfig: playerConfig,
                dragState: dragState,
                podLabel: activePodLabel()
            )
            .onTapGesture(count: 1) {
                withAnimation{ handleSingleTap() }
            }
            .offset(dragState.draggedOffsets[index])
            .gesture(optimizedDragGesture)
            .background(frameReader)
            .compositingGroup()
            .opacity(isEliminated ? 0.0 : 1.0)
            .opacity(dragState.showPoisonDots[index] ? 0 : 1 )
        }
    }
    
    @ViewBuilder
    private var frameReader: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear {
                    if dragState.podCenters[index] == nil {
                        dragState.podCenters[index] = proxy.frame(in: .global).origin
                    }
                }
        }
    }
    
    @MainActor
    private var optimizedDragGesture: some Gesture {
        DragGesture(minimumDistance: 0.10)
        
            .updating($dragOffset) { value, state, transaction in
                /// This updates the @GestureState automatically
                state = value.translation
                
                /// Disable animations for smooth dragging
                transaction.animation = nil
                
                /// Update collision detection logic here if needed
                handleDragChanged( value)
            }
        
            .onEnded { value in
                handleDragEnded(value)
            }
    }
    
    @MainActor
    private func handleDragChanged(_ value: DragGesture.Value) {
        /// Always update visual position (smooth)
        /// Throttle expensive calculations
        guard dragState.shouldUpdate(), let origin = dragState.podCenters[index] else { return }
        
        dragState.draggedOffsets[index] = value.translation
        
       
        if dragState.dragTrails[self.index].positions.count == 0 { dragState.dragTrails[index].add(centerPoint(for: quadrant, in: dragState.containerSize))
        }
       
        
        let draggedCenter = CGPoint(
            x: origin.x + value.translation.width + halfPodSize,
            y: origin.y + value.translation.height + halfPodSize
        )

        let dragCenter = CGPoint(
            x: origin.x + value.translation.width + halfPodSize,
            y: origin.y + value.translation.height - (index == 0 || index == 3 ? 2*halfPodSize : 0)
        )
        
//        let origin = centerPoint(for: quadrant, in: dragState.containerSize)
//        
//        
//        let draggedCenter = CGPoint(
//            x: origin.x + value.translation.width ,
//            y: origin.y + value.translation.height  + halfPodSize
//        )
//        
//        let dragCenter = CGPoint(
//            x: origin.x + value.translation.width ,
//            y: origin.y + value.translation.height
//        )
        
       
        //let draggedCenter = value.location
        dragState.dragTrails[self.index].add(dragCenter)
        
        // Batch all the expensive checks
        performOverlapChecks(at: draggedCenter)
        
        
        
        let prevTotalRings = dragState.solrings[index].totalRings
        //dragState.solrings[index].setNewDragPoint(draggedCenter, around: centerPoint(for: quadrant, in: dragState.containerSize ))
        dragState.solrings[index].setNewDragPoint(draggedCenter, around: dragState.podCenters[index]!)
        let newTotalRings = dragState.solrings[index].totalRings
        if newTotalRings != prevTotalRings {
            do{
                try game.podCasts.addSolRingReceipt(turnID: game.currentTurn.id, playerID: index)
                print("Total Rings for Player \(index): ", game.podCasts.solRings.count)
            }
            catch {
                print("Error with adding SolRing Receipt")
            }
        }
    }
    
    
    private func performOverlapChecks(at point: CGPoint) {
        
        dragState.playerDraggedPodOntoCenterPod = index
 
        dragState.highlightedCenterPodIndex = dragState.findOverlappingFrame(
            point: point,
            in:  dragState.centerPodFrames
        )
                
        if dragState.highlightedCenterPodIndex != index {
            dragState.highlightedCenterPodIndex = nil
            dragState.bombPodActive[index] = false
            dragState.bombModeActive = false
        } else {
            dragState.bombModeActive = true
            dragState.bombPodActive[index] = true
            dragState.highlightedDamageLabelIndex = nil
        }
                
        if dragState.highlightedCenterPodIndex == nil {
            
            if let quadrant = determineQuadrant(from: point){
                if (quadrant.rawValue == index) { dragState.highlightedPodIndex[index] = index
                    for p in dragState.highlightedPodIndex.indices {
                        if  dragState.highlightedPodIndex[p] == index {
                            dragState.highlightedPodIndex[p] = p
                        }
                    }
                }
                else {
                    dragState.highlightedPodIndex[quadrant.rawValue] = index
                    for p in dragState.highlightedPodIndex.indices {
                        if dragState.highlightedPodIndex[p] == index && p != quadrant.rawValue {
                            dragState.highlightedPodIndex[p] = p
                        }
                    }
                }
            }
 
            dragState.highlightedDamageLabelIndex = dragState.findOverlappingFrame(
                point: point,
                in: dragState.damageLabelFrames
            )
            if dragState.highlightedDamageLabelIndex != index {
                dragState.highlightedDamageLabelIndex = nil
            }
        }
        
        dragState.highlightedCommanderBarIndex = dragState.findOverlappingFrame(
            point: point,
            in:  dragState.commanderBarFrames
        )
        if dragState.highlightedCommanderBarIndex != index {
            dragState.highlightedCommanderBarIndex = nil
        } else {
           
            ///Specific colouring for the removal of commander tax
            if let frame = dragState.commanderBarFrames[index]{
                dragState.taxUp[index] = willTaxGoUp(at: point, in: frame)
            }

        }

    }
    
    
    private func determineQuadrant(from globalLocation: CGPoint) -> Quadrant? {
        /// Center of the full container in global coordinates
        let center = CGPoint(x: 0.5*dragState.containerSize.width, y: 0.5*dragState.containerSize.height)
        
        /// Determine position relative to the center
        let relative = CGPoint(x: globalLocation.x - center.x,
                               y: globalLocation.y - center.y)
        
        if relative.x < 0, relative.y < 0 { return Quadrant.topLeft }
        if relative.x >= 0, relative.y < 0 { return Quadrant.topRight }
        if relative.x < 0, relative.y >= 0 { return Quadrant.bottomLeft }
        if relative.x >= 0, relative.y >= 0 { return Quadrant.bottomRight }
        
        return nil
    }
    
    
    private func handleDragEnded(_ value: DragGesture.Value) {
        guard let origin = dragState.podCenters[index] else { return }
        
        let finalPosition = CGPoint(
            x: origin.x + value.translation.width + GameUIConstants.podSize * 0.5,
            y: origin.y + value.translation.height + GameUIConstants.podSize * 0.5
        )
        
        let isBombActive = dragState.bombPodActive[index]
        
        if !isBombActive {
            let centerOverlap = dragState.findOverlappingFrame(point: finalPosition,
                                                               in: dragState.centerPodFrames)
            
            if centerOverlap == nil, let quadrant = determineQuadrant(from: finalPosition) {
                let quadrantID = quadrant.rawValue
                /// From player dragging pod onto quadrant
                if quadrantID != index {
                    applyDamage(from: index, to: quadrantID)
                }
                /// Self Commander Damage - only registers when dragged onto certain part of quadrant
                if dragState.highlightedDamageLabelIndex == index {
                    applyDamage(from: index, to: index)
                }
            }
        } else { dragState.highlightedDamageLabelIndex = nil }
        
        if let frame = dragState.commanderBarFrames[index],
           frame.contains(finalPosition) {
            handleCommanderTax(at: finalPosition, in: frame)
        }
        resetDragState()
        dragState.solrings[index].resetDrag()
        dragState.dragTrails[index].clear()
        
    
        
    }

    /// Apply damage color + flags
    private func applyDamage(from sourceIndex: Int, to targetIndex: Int) {
        dragState.showDamageButtonInQuadrant[targetIndex] = true
        dragState.commanderDamage[targetIndex] = true
        dragState.damageFromQuadrantColors[targetIndex] = PlayerColors.color(for: sourceIndex)
    }
    
    private func willTaxGoUp(at position: CGPoint, in frame: CGRect) -> Bool {
        let rightSideOfBarFace = position.x > frame.midX
        let increase: Bool
        
        switch (rightSideOfBarFace, playerConfig.isLeftSide, playerConfig.isRotated) {
        case (true, true, false),
            (true, false, true),
            (false, true, true),
            (false, false, false):
            increase = false
            
        default:
            increase = true
        }
        return increase
    }
    
    /// Handle commander tax increase/decrease depending on side + rotation
    private func handleCommanderTax(at position: CGPoint, in frame: CGRect) {
        let increase: Bool = willTaxGoUp(at: position, in: frame)
        
        if increase {
            game.increaseCommanderTax(for: index)
        } else {
            game.decreaseCommanderTax(for: index)
        }
    }

    
    
    /**/
    @MainActor
    private func handleSingleTap() {
        dragState.commanderDamage[index] = false
        dragState.showDamageButtonInQuadrant[index].toggle()
        dragState.highlightedPodIndex[index] = index
        dragState.bombModeActive = false
    }
    
    /**/
    private func resetDragState() {
        dragState.draggedOffsets[index] = .zero
        dragState.highlightedCommanderBarIndex = nil
        dragState.highlightedCenterPodIndex = nil
        dragState.highlightedDamageLabelIndex = nil
    }

    
}

///===========================================

//@MainActor
public struct PodContent: View {
    let index: Int
    let isActivePlayer: Bool
    let lifeRatio: CGFloat
    let playerConfig: PlayerLayoutConfig
    @Bindable var dragState: PodDragState
    let podLabel: String
    
    // Precompute animation styles once
    @State private var animationStyle = PodAnimationStyle.allCases.randomElement() ?? .wobbler
    @State private var podAnimationStyle = PodAnimationStyle.allCases.randomElement() ?? .wobbler
    @State private var scale: CGFloat = 1.0
    
    // MARK: Computed properties
    private var isHighlighted: Bool {
        guard index < GameConstants.maxPlayers && index >= 0 else { return false }
        guard dragState.highlightedPodIndex[index] >= 0 else { return false }
        return dragState.highlightedPodIndex[index] != nil && dragState.highlightedPodIndex[index] != index
    }
    
    private var highlightColor: Color {
        guard isHighlighted else { return Color.clear }
        return getColor(for: dragState.highlightedPodIndex[index])
    }
    
    private var checkShake: Bool {
        dragState.isBombShakingQuadrants && (dragState.playerDraggedPodOntoCenterPod != index)
    }
    
    // MARK: Body
    public var body: some View {
        ZStack {
            /// Background pod circle
            Circle()
                .fill(highlightColor)
                .applyPodAnimationIfNeeded(isActive: isActivePlayer || isHighlighted,
                                           style: animationStyle,
                                           color: PlayerColors.color(for: index))
                .frame(width: 1.25*GameUIConstants.podSize,
                       height: 1.25*GameUIConstants.podSize)
            
            /// Pod backdrop
            Circle()
                .stroke(PlayerColors.color(for: index), lineWidth: 1)
                .fill(PlayerColors.color(for: index).tertiary)
                .frame(width: GameUIConstants.podSize,
                       height: GameUIConstants.podSize)
            
            /// Life indicator
            Circle()
                .stroke(Color.black, lineWidth: 3)
                .fill(PlayerColors.color(for: index).gradient)
                .applyPodAnimationIfNeeded(isActive: isActivePlayer,
                                           style: podAnimationStyle,
                                           color: PlayerColors.color(for: index))
                .frame(width: GameUIConstants.podSize * lifeRatio,
                       height: GameUIConstants.podSize * lifeRatio)
            
            /// Text overlay
            Text(podLabel)
                .foregroundColor( Color.white)
                .font(.title3.bold())
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .customStroke(color: Color.black, width: 0.5)
                .scaleEffect(isActivePlayer ? 1.25 : 1.0)
                .rotationEffect(Angle(degrees: playerConfig.rotationAngle))
        }
        .frame(width: GameUIConstants.podSize, height: GameUIConstants.podSize)
        .compositingGroup()
        .shadow(color: checkShake ? Color.red : Color.clear, radius: 5*scale)
        .onChange(of: checkShake) {
            /// Bomb Animation applied to Pod
            withAnimation(checkShake
                          ? .easeInOut(duration: 0.125).repeatForever(autoreverses: true)
                          : .default) {
                HapticFeedback.impact(.light)
                scale = checkShake ? 2.0 : 1.0
                HapticFeedback.impact(.medium)
            }
        }
    }
}


/// Custom modifier to handle conditional animations efficiently
@MainActor
struct ConditionalPodAnimation: ViewModifier {
    let shouldAnimate: Bool
    let style: PodAnimationStyle
    let color: Color
    
    @ViewBuilder
    func body(content: Content) -> some View {
        if shouldAnimate {
            content.applyPodAnimation(style: style, color: color)
        } else {
            content
        }
    }
}





