import SwiftUI
import Podwork

// MARK: - Tutorial Container

struct TutorialOverlayView: View {
    @State private var currentStep = 0
    @State private var isActive = true
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            
            if isActive && currentStep < tutorialSteps(screenWidth: screenWidth, screenHeight: screenHeight).count {
                let steps = tutorialSteps(screenWidth: screenWidth, screenHeight: screenHeight)
                let step = steps[currentStep]
                
                ZStack {
                   
                    HStack{
                        Spacer(minLength: 0.0)
                        TutorialMask(highlightArea: step.highlightArea)
                            .fill(Color.black.opacity(0.75))
                            .frame(maxWidth: 1.0*screenWidth)
                    }
                    
                    VStack{
                        Spacer()
                        HStack{
                            Spacer()
                            Text("Podable Tutorial  ")
                                .font(Font.system(.title2).smallCaps())
                                .foregroundStyle(Color.cyan.gradient)
                                .customStroke(color: Color.blue, width: 0.75)
                                //.bold()
                        }
                    }
                    
                    
                    BigArrowView(rotation: .degrees(arrowPlacement.theta))
                        .offset(x: screenWidth*arrowPlacement.x,
                                y: screenHeight*arrowPlacement.y)
                    
                    VStack(spacing:0){
                        Text(tutorialTitle)
                            .font(.title2)
                            .foregroundStyle(Color.yellow.gradient)
                            .bold()
                        InfoBoxTextView(text: step.instructionText )
                        
                    }
                    .frame(width: 0.45*screenWidth)
                    .offset(x:screenWidth*0.25 , y: -0.07910*screenHeight)
                    
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button("<<") {
                                previousStep()
                            }
                            .modifier(tutorialButtonStyle())
                            
                            SlideProgressIndicator(
                                current: currentStep,
                                total: steps.count
                            )
                            
                            Button(currentStep == steps.count - 1 ? "OK" : ">>") {
                                nextStep()
                            }
                            .modifier(tutorialButtonStyle())
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 45)
                    }
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.4), value: currentStep)
            }
        }
        .allowsHitTesting(isActive)
    }
    
    private struct tutorialButtonStyle: ViewModifier {
        func body(content : Content) -> some View {
            content
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white)
                .cornerRadius(20)
        }
    }
    
    
    private var tutorialTitle: String {
        switch currentStep {
        case 0: return "Star✨Pod"
        case 1: return "Dragon Pods"
        case 2: return "Life Total"
        case 3: return "Damage Rings"
        case 4: return "Commander"
        case 5: return "Infect"
        case 6: return "Star Modes"
        case 7: return "Bomb💣Pod"
        default: return ""
        }
    }
    
    private var tutorialDescription: String {
        switch currentStep {
        case 0: return "Double Tap the Star✨Pod to Pass the Turn!\n\nHold for 3 sec to Return to Main Menu"
        case 1: return "Pods Drag-On to things to interact!\n\nSlide into an opponents DMs to change their buttons to Commander damage."
        case 2: return "Tap above or below Life total to apply damage.\n\nTap Pod to reset the damage mode."
        case 3: return "Commander damage is shown as Rings around the Pod.\n\nApply Commander damage in the same way as Life damage."
        case 4: return "Add a name to the Commander Log.\n\nDrag your Pod onto the TAX side when you cast them! \n\n(Remove tax on the opposite side)"
        case 5: return "Tap the Φ Pod to open the Poison counter."
        //case 6: return "Change the ✨Pod into the 💣Pod by dragging your Pod onto it.\n\nDrag the Bomb Pod into your DMs to choose Alt Loss Method\n(Concede, Mill)"
        case 6: return "Drag the Star✨Pod into your DMs to:\n\n-Undo the Turn\n-Take Extra Turns\n- Declare Alt Wincon"
        case 7: return "Drag Your Pod onto the Star✨Pod to change it into the Bomb💣Pod!\n\nDouble tap Bomb💣Pod for 1 damage to ALL opponents.\n\nDrag it into DMs to:\n- Concede\n-Declare Loss by Mill"
        default: return ""
        }
    }
   
    
    private var arrowPlacement: xyTheta {
        switch currentStep {
        case 0: return xyTheta(x:0.0, y: -0.3, theta: 0.0)
        case 1: return xyTheta(x:-0.105, y: -0.225, theta: -95.0)
        case 2: return xyTheta(x:-0.10, y: 0.15, theta: -104.0)
        case 3: return xyTheta(x:-0.10, y: -0.30, theta: -81.0)
        case 4: return xyTheta(x:-0.3, y: 0.3, theta: -135.0)
        case 5: return xyTheta(x:-0.25, y: -0.4, theta: -75.0)
        case 6: return xyTheta(x: -0.050, y: -0.30, theta: 15.0)
        case 7: return xyTheta(x: -0.050, y: -0.30, theta: 15.0)

        default: return xyTheta(x: -0.050, y: -0.30, theta: 15.0)
        }
    }
    
    struct xyTheta {
        let x: Double
        let y: Double
        let theta: Double
    }
    
    
    private func tutorialSteps(screenWidth: CGFloat, screenHeight: CGFloat) -> [TutorialStep] {
        return [
            /// Step 1: Highlight center "Star Pod" area
            TutorialStep(
                highlightArea: CGRect(
                    x: screenWidth * 0.35,
                    y: screenHeight * -0.10,
                    width: screenWidth * 0.3,
                    height: screenHeight * 0.25
                ),
                instructionText: tutorialDescription,
                instructionPosition: CGPoint(x: screenWidth * 0.45, y: screenHeight * 0.32)
            ),
            
            /// Step 2: Highlight player Pod
            ///  hand.draw
            TutorialStep(
                highlightArea: CGRect(
                    x: screenWidth * 0.125,
                    y: screenHeight * 0.17,
                    width: screenWidth * 0.25,
                    height: screenHeight * 0.25
                ),
                instructionText: tutorialDescription,
                instructionPosition: CGPoint(x: screenWidth * 0.365, y: screenHeight * 0.62)
            ),

            /// Step 3: Highlight life total
            TutorialStep(
                highlightArea: CGRect(
                    x: screenWidth * 0.02,
                    y: screenHeight * 0.437,
                    width: screenWidth * 0.46,
                    height: screenHeight * 0.45
                ),
                instructionText: tutorialDescription,
                instructionPosition: CGPoint(x: screenWidth * 0.85, y: screenHeight * 0.78)
            ),
            
            /// Step 4: Commander Damage
            TutorialStep(
                highlightArea: CGRect(
                    x: screenWidth * 0.0125,
                    y: screenHeight * 0.0817,
                    width: screenWidth * 0.45,
                    height: screenHeight * 0.45
                ),
                instructionText: tutorialDescription,
                instructionPosition: CGPoint(x: screenWidth * 0.365, y: screenHeight * 0.62)
            ),
            
            /// Step 5: Highlight name entry area at bottom
            TutorialStep(
                highlightArea: CGRect(
                    x: screenWidth * 0.005,
                    y: screenHeight * 0.9,
                    width: screenWidth * 0.5,
                    height: screenHeight * 0.08
                ),
                instructionText: tutorialDescription,
                instructionPosition: CGPoint(x: screenWidth * 0.85, y: screenHeight * 0.78)
            ),
            /// Step 6: Poison counters
            TutorialStep(
                highlightArea: CGRect(
                    x: screenWidth * 0.005,
                    y: screenHeight * 0.0,
                    width: screenWidth * 0.15,
                    height: screenHeight * 0.15
                ),
                instructionText: tutorialDescription,
                instructionPosition: CGPoint(x: screenWidth * 0.85, y: screenHeight * 0.18)
            )
            ,
            /// Step 7: Alt Wins
            TutorialStep(
                highlightArea: CGRect(
                    x: screenWidth * 0.35,
                    y: screenHeight * -0.10,
                    width: screenWidth * 0.3,
                    height: screenHeight * 0.25
                ),
                instructionText: tutorialDescription,
                instructionPosition: CGPoint(x: screenWidth * 0.5, y: screenHeight * 0.52)
            ),
            /// Step 8: Bombpod
            TutorialStep(
                highlightArea: CGRect(
                    x: screenWidth * 0.35,
                    y: screenHeight * -0.10,
                    width: screenWidth * 0.3,
                    height: screenHeight * 0.25
                ),
                instructionText: tutorialDescription,
                instructionPosition: CGPoint(x: screenWidth * 0.5, y: screenHeight * 0.52)
            )
        ]
    }
    
    private func nextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            let steps = tutorialSteps(screenWidth: 400, screenHeight: 800)
            if currentStep < steps.count - 1 {
                currentStep += 1
            } else {
                closeTutorial()
            }
        }
    }
  
    
    private func previousStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if currentStep > 0 {
                currentStep -= 1
            }
        }
    }
    
    private func closeTutorial() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isActive = false
        }
    }
    
    private func angleFromPoints(_ start: CGPoint, _ end: CGPoint) -> Double {
        let dx = end.x - start.x
        let dy = end.y - start.y
        return atan2(dy, dx)
    }
}



struct SlideProgressIndicator: View {
    let current: Int
    let total: Int
    
    var body: some View {
        HStack(spacing: 4) {
           Text("\(current) / \(total)")
                .foregroundStyle(Color.white.gradient)
        }.bold()
    }
}

struct CircleProgressIndicator: View {
    let current: Int
    let total: Int
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index <= current ? Color.white : Color.white.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

struct TutorialStep {
    let highlightArea: CGRect
    let instructionText: String
    let instructionPosition: CGPoint
}

struct TutorialMask: Shape {
    let highlightArea: CGRect
    
    func path(in rect: CGRect) -> Path {
        var path = Path(rect)
        let cutout = Path(roundedRect: highlightArea, cornerRadius: 12)
        return path.subtracting(cutout)
    }
}

struct MirroredTutorialView: View {
    var body: some View {
        TutorialOverlayView()
            .rotationEffect(.degrees(180))
    }
}




struct BigArrowView: View {
    var rotation: Angle
    
    @State private var pulse = false
    
    var body: some View {
        VStack(spacing: 0) {
            Triangle()
                .fill(Color.red)
                .frame(width: 30, height: 30)
            
            Rectangle()
                .fill(Color.red)
                .frame(width: 12, height: 60)
        }
        .overlay(
            VStack(spacing: 0) {
                Triangle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: 30, height: 30)
                
                Rectangle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: 12, height: 60)
            }
        )
        .rotationEffect(rotation)
        .scaleEffect(pulse ? 1.2 : 1.0)
        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: pulse)
        .onAppear {
            pulse = true
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let top = CGPoint(x: rect.midX, y: rect.minY)
        let left = CGPoint(x: rect.minX, y: rect.maxY)
        let right = CGPoint(x: rect.maxX, y: rect.maxY)
        
        path.move(to: top)
        path.addLine(to: left)
        path.addLine(to: right)
        path.closeSubpath()
        
        return path
    }
}


#Preview {
    VStack(spacing:0){
        MirroredTutorialView()
        TutorialOverlayView()
    }
    .background(Color.white)
}
