import SwiftUI
import Combine
import Podwork


@MainActor
struct StarPodView: View {
    @Bindable var viewModel: TurnCycleViewModel
    let bombPod: Bool
    let initialPosition: CGPoint
    
    @ViewBuilder
    func podSetup() -> AnyView {
        AnyView(
            VStack{
                Image(systemName:"2.brakesignal")
                Image(systemName:"hand.tap.fill")
            }
            .font(.system( size: 30))
            .foregroundStyle(Color.black.gradient)
            .opacity(viewModel.opacity)
        )
    }
    
    @ViewBuilder
    var starAnimation: AnyView{
        viewModel.podSetupPhase ? podSetup() :
        AnyView(
            AnimatedIconView()
                .opacity(viewModel.opacity)
        )
    }
    
    @ViewBuilder
    var centerPodText: AnyView{
        AnyView(
            Text(viewModel.displayText)
                .font(.title)
                .foregroundStyle(Color.black.gradient)
                .customStroke(color: Color.black, width: 0.25)
                .opacity(viewModel.opacity)
                .multilineTextAlignment(.center))
    }
    
    @ViewBuilder
    var bombPodText: AnyView{
        AnyView(
            Text("💣")
                .font(.system(size: 50))
                .opacity(viewModel.opacity))
    }
    
    @ViewBuilder
    var bombPodExplanation: AnyView{
        AnyView(
            VStack{
                Image(systemName:"2.brakesignal")
                Image(systemName:"hand.tap.fill")
            }
            .font(.system( size: 30))
            .opacity(viewModel.opacity)
        )
    }
    
    @ViewBuilder
    var body: some View {
        ZStack {
            ZStack{
                Circle()
                    .fill( bombPod ?  AnyShapeStyle(Color.red.gradient) : AnyShapeStyle(Color.white.gradient))
                    .stroke(Color.black, lineWidth:1)
                    .shadow(radius: 5)
                    .frame(width: PodworkUIConstants.bombPodSize, height: PodworkUIConstants.bombPodSize)
                    .overlay(
                        bombPod ?
                        (viewModel.isSymbolShowing ? bombPodExplanation : bombPodText ) :
                            (viewModel.isSymbolShowing ? starAnimation : centerPodText )
                    )
            }
            .rotationEffect(viewModel.isRotated ? Angle(degrees: viewModel.rotatedAngle) : Angle(degrees: viewModel.nonRotatedAngle) )
        }
    
    }
}



func directionFromVector(_ vector: CGPoint) -> String {
    let absX = abs(vector.x)
    let absY = abs(vector.y)
    
    if absX > absY {
        return vector.x > 0 ? "right" : "left"
    } else {
        return vector.y > 0 ? "down" : "up"
    }
}


@Observable
class TurnCycleViewModel{
    var displayText: String = ""
    var opacity: Double = 1.0
    var displayTurn: String = ""
    var symbol = " "
    var isRotated: Bool = false
    var previousRotation: Bool = false
    var rotatedAngle: Double = 0
    var nonRotatedAngle: Double = 0
    
    var currentTurn: Int = 1
    var podSetupPhase: Bool = true
    var task: Task<Void, Never>?
    
    var showDuration: TimeInterval = 3.5
    var symbolDuration: TimeInterval = 5.0
    
    var isSymbolShowing: Bool = false

    
    func applyRotation() {
        if isRotated != previousRotation {
            rotatedAngle = isRotated ? nonRotatedAngle + 180 : rotatedAngle
            nonRotatedAngle = !isRotated ? rotatedAngle + 180 : nonRotatedAngle
        }
    }
    
    func displayTurnNumber() -> String {
        podSetupPhase ? "Start\nGame" : "Turn\n\(currentTurn)" 
    }
    
    func endSetupPhase() { podSetupPhase = false }
    
    @MainActor
    func startCycle(for msg: String) {
        task?.cancel()
        
        task = Task  {
            
            displayTurn = displayTurnNumber()
            displayText = msg
            opacity = 1.0
            
            try? await Task.sleep(nanoseconds: UInt64(showDuration * 1_000_000_000))
            while !Task.isCancelled {

                ///Fade out Text
            
                withAnimation (.smooth(duration: 1.0)) {
                    opacity = 0.0
                }
                
                /// Time taken to fade out
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                isSymbolShowing = true
                /// Show turn text
                
                
                withAnimation (.smooth(duration: 1.0)) {
                    opacity = 1.0
                }
                /// Main Showing of the Center Menu Text
                
                let delay = showDuration 
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
                /// Fade out turn Text
                withAnimation (.smooth(duration: 1.0)) {
                    opacity = 0.0
                }
                
                /// Time taken to fade out with no thing in circle
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                isSymbolShowing = false

                displayText = displayTurnNumber()

                
                /// Show Symbol fade in
                withAnimation (.smooth(duration: 1.0)) {
                    opacity = 1.0
                }
                
                let secondDelay = symbolDuration
                try? await Task.sleep(nanoseconds: UInt64(secondDelay * 1_000_000_000))
            }
        }
    }
    
    @MainActor
    func stopCycle() {
        task?.cancel()
    }

    deinit {
        task?.cancel()
    }
}





struct TurnCircleView: View {
    @Bindable var viewModel: TurnCycleViewModel
    
    @ViewBuilder
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue)
                .frame(width: 150, height: 150)
                .shadow(radius: 10)
            
            Text(viewModel.displayText)
                .font(.title)
                .foregroundColor(Color.white)
                .opacity(viewModel.opacity)
                .multilineTextAlignment(.center)
                .scaledToFit()
        }
    }
}



struct TurnCircleView_Previews: PreviewProvider {
    static var previews: some View {
        TurnCirclePreviewWrapper()
            .previewLayout(.sizeThatFits)
            .padding()
    }
    
    struct TurnCirclePreviewWrapper: View {
        @State private var viewModel = TurnCycleViewModel()
        
        var body: some View {
            TurnCircleView(viewModel: viewModel)
                .onAppear {
                    viewModel.startCycle(for: "Turn\n\(1)")
                }
        }
    }
}

struct TurnCircleView_Previews2: PreviewProvider {
    static var previews: some View {
        TurnCirclePreviewWrapper()
            .previewLayout(.sizeThatFits)
            .padding()
    }
    
    struct TurnCirclePreviewWrapper: View {
        @State private var viewModel = TurnCycleViewModel()
        @State private var isStarted = false
        @State private var turnNumber = 1
        
        var body: some View {
            VStack(spacing: 20) {
                TurnCircleView(viewModel: viewModel)
                
                if !isStarted {
                    Button("Start Turn Cycle") {
                        isStarted = true
                        viewModel.startCycle(for: "Turn\n\(turnNumber)")
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Next Turn") {
                        turnNumber += 1
                        viewModel.startCycle(for: "Turn\n\(turnNumber)")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
}
