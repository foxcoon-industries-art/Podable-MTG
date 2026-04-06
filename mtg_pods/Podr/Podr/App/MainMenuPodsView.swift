import SwiftUI
import Podwork


// --------
// Controls for Main Menu Button select from Center Pod
// --------

@MainActor
public struct PodsOnMainView: View {
    let index: Int
    @Bindable var dragState: PodsOnMainDragState
    @Binding var animate: Bool

    @State var swipePod: Bool = false
    @GestureState private var dragOffset: CGSize = .zero
    private let halfPodSize = GameUIConstants.podSize
    
    
    @MainActor
    @ViewBuilder
    public var body: some View {
        podView
    }
    
    
    @MainActor
    @ViewBuilder
    private var podView : some View{
            Circle()
            .fill( Color.white.gradient)
            .stroke(Color.black.gradient, lineWidth: 1)
            .overlay(Image(systemName: "sparkles")
                .font(.title)
                .foregroundStyle(Color.yellow.gradient)
                .customStroke(color: Color.black, width: 0.250))
            .scaleEffect(swipePod ? 1.0 : 1.2)
            .frame(width: GameUIConstants.podSize, height: GameUIConstants.podSize)
            .offset(dragState.draggedOffsets[index])
            .gesture(optimizedDragGesture)
            .background(podFrameReader)
    }
    
    
    @MainActor
    @ViewBuilder
    private var podFrameReader: some View {
        GeometryReader { geoproxy in
            Color.clear
                .onChange(of: dragState.podCenters[0]){ prev, curVal in
                    if curVal == nil { dragState.podCenters[0] = geoproxy.frame(in: .global).origin}
                }
        }
    }
   
    
    @MainActor
    private var optimizedDragGesture: some Gesture {
        DragGesture(minimumDistance: 0.10)
        
            .updating($dragOffset) { value, state, transaction in

                if swipePod == false {
                    swipePod = true
                    dragState.podCenters[index] = value.startLocation
                }
                
                /// This updates the @GestureState automatically
                state = value.translation
                
                /// Disable animations for smooth dragging
                transaction.animation = nil
                
                /// Update collision detection logic
                handleDragChanged( value )
            }
            .onEnded { value in
                handleDragEnded(value)
                swipePod = false
            }
    }
    
    
    @MainActor
    private func handleDragChanged(_ value: DragGesture.Value) {

        dragState.draggedOffsets[index] = value.translation
        let centerPointOrigin = CGPoint(
            x: 0.5*UIScreen.main.bounds.width,
            y: 0.5*UIScreen.main.bounds.height
        )
        let origin = value.startLocation
        
        let draggedCenter = CGPoint(
            x: centerPointOrigin.x - origin.x + value.translation.width + halfPodSize,
            y: centerPointOrigin.y - origin.y + value.translation.height + halfPodSize
        )
        performOverlapChecks(at: draggedCenter)
    }
    
    
    @MainActor
    private func performOverlapChecks(at point: CGPoint) {
        dragState.highlightedMenuButtonIndex = dragState.findOverlappingFrame(
            point: point,
            in:  dragState.menuButtonFrames
        )
    }
    
    
    @MainActor
    private func handleDragEnded(_ value: DragGesture.Value) {
        guard let origin = dragState.podCenters[index] else { return }

        let centerPointOrigin = CGPoint(
            x: 0.5*UIScreen.main.bounds.width,
            y: 0.5*UIScreen.main.bounds.height
        )
 
        let finalPosition = CGPoint(
            x: centerPointOrigin.x - origin.x + value.translation.width + halfPodSize,
            y: centerPointOrigin.y - origin.y + value.translation.height + halfPodSize
        )
        
        let selectedButton = dragState.findOverlappingFrame(
            point: finalPosition,
            in:  dragState.menuButtonFrames
        )
        if selectedButton != nil {
            dragState.selectedMenuButtonIndex = selectedButton
            let _ = print("STOPPED: ⭐️ Button detected", dragState.onReturn)
        }
        resetDragState()
    }
    
    
    @MainActor
    private func resetDragState() {
        dragState.podCenters[index] = CGPoint(
            x: 0.5*UIScreen.main.bounds.width,
            y: 0.5*UIScreen.main.bounds.height
        )
        dragState.draggedOffsets[index] = CGSize.zero
        dragState.highlightedMenuButtonIndex = nil
        swipePod = false
    }
}



// Saves where the frames are on the Screen
@MainActor
struct MainMenusButtonsFramePreferenceKey: @MainActor PreferenceKey {
    nonisolated(unsafe) static var defaultValue: [CGRect?] = []
    
    @MainActor
    static func reduce(value: inout [CGRect?], nextValue: () -> [CGRect?]) {
        if nextValue().count > value.count {
            value.append(contentsOf: Array(repeating: nil, count: nextValue().count - value.count))
        }
        
        for (i, frame) in nextValue().enumerated() {
            if let frame = frame {
                value[i] = frame
            }
        }
    }
}


// Preference key to pass Main Menu Button frames
@MainActor
struct ButtonFrameKey: @MainActor PreferenceKey {
    nonisolated(unsafe) static var defaultValue: [Int: CGRect] = [:]
    
    @MainActor
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}


@MainActor
@Observable
public class PodsOnMainDragState {
    // MARK: - Per-player state (use array index = player index)
    public var draggedOffsets: [CGSize]  
    public var podCenters: [CGPoint?]
    public var menuButtonFrames: [CGRect?]
    
    // MARK: - Global drag state
    public var highlightedMenuButtonIndex: Int? = nil
    public var selectedMenuButtonIndex: Int? = nil
    public var onReturn : AppView = AppView.main
    
    // MARK: - Update throttling
    private var lastUpdateTime = Date()
    private let updateInterval: TimeInterval = 1.0/60.0 // 60fps
    
    
    // MARK: - Init
    @MainActor public init(buttonCount: Int = 8) {
        draggedOffsets = Array(repeating: .zero, count: buttonCount)
        podCenters = Array(repeating: nil, count: buttonCount)
        menuButtonFrames = Array(repeating: nil, count: buttonCount)
    }
    
    
    // MARK: - Helpers
    @MainActor
    func shouldUpdate() -> Bool {
        let now = Date()
        guard now.timeIntervalSince(lastUpdateTime) > updateInterval else { return false }
        lastUpdateTime = now
        return true
    }
    
    
    @MainActor
    func findOverlappingFrame(point: CGPoint, in frames: [CGRect?]) -> Int? {
        for (i, frame) in frames.enumerated() {
            if let frame, frame.contains(point) {
                return i
            }
        }
        return nil
    }
}
