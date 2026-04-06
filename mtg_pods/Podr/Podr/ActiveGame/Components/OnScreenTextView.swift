import SwiftUI


struct OutlinedText: View {
    let text: String
    let font: Font
    let strokeWidth: CGFloat
    let strokeColor: Color
    let fillColor: Color
    
    var body: some View {
        ZStack {
            // Stroke (draw text multiple times offset)
            ForEach([-strokeWidth, 0, strokeWidth], id: \.self) { x in
                ForEach([-strokeWidth, 0, strokeWidth], id: \.self) { y in
                    Text(text)
                        .font(font)
                        .foregroundStyle(strokeColor.gradient)
                        .offset(x: x, y: y)
                }
            }
            .multilineTextAlignment(.center)

            // Fill
            Text(text)
                .font(font)
                .foregroundStyle(fillColor.gradient)
                .multilineTextAlignment(.center)

            
        }
    }
}



struct MultiOutlinedText: View {
    let text: String
    let font: Font
    let strokeWidth: CGFloat
    let strokeColor: [Color]
    let fillColor: Color
    
    var n : Int {strokeColor.count}
    func up(_ val : Int, _ scale : CGFloat ) -> CGFloat {
        CGFloat(scale) * CGFloat(n-val) * strokeWidth
    }
    func down(_ val : Int, _ scale : CGFloat) -> CGFloat {
        -1.0 * CGFloat(scale) * CGFloat(n-val) * strokeWidth
    }
    
    var body: some View {
        ZStack {
            ForEach(Array(strokeColor.enumerated()), id: \.offset) { idx, col in
                // Stroke (draw text multiple times offset)
                ForEach([down(idx, 1), down(idx, 0.5), 0, up(idx, 0.5), up(idx, 1)], id: \.self) { x in
                    ForEach([down(idx, 1), down(idx, 0.5), 0, up(idx, 0.5), up(idx, 1)], id: \.self) { y in
                        Text(text)
                            .font(font)
                            .foregroundStyle(col.gradient)
                            .offset(x: x, y: y)
                    }
                }
            }
            
            // Fill
            Text(text)
                .font(font)
                .foregroundStyle(fillColor.gradient)
        }
    }
}


enum AnimationPhase {
    case hidden
    case visible
}

struct InstructionTiming {
    let fadeDuration: TimeInterval
    let visibleDuration: TimeInterval
    
    init(
        fadeDuration: TimeInterval = 0.45,
        visibleDuration: TimeInterval = 3.5
    ) {
        self.fadeDuration = fadeDuration
        self.visibleDuration = visibleDuration
    }
    
    var fadeNanoseconds: UInt64 {
        UInt64(fadeDuration * 1_000_000_000)
    }
    
    var visibleNanoseconds: UInt64 {
        UInt64(visibleDuration * 1_000_000_000)
    }
}


struct InstructionOverlay: View {
    let messages: [String]
    let timing: InstructionTiming
    
    init(
        messages: [String],
        timing: InstructionTiming = InstructionTiming()
    ) {
        self.messages = messages
        self.timing = timing
    }

    
    @State private var phase: AnimationPhase = .hidden
    @State private var currentIndex = 0
    @State private var hasStarted = false
    
    var body: some View {
        OutlinedText(
            text: messages[currentIndex],
            font: .system(size: 24, weight: .heavy, design: .rounded),
            strokeWidth: 1.5,
            strokeColor: Color.black,
            fillColor: Color.white
        )
        .opacity(phase == .visible ? 1 : 0)
        .onAppear {
            guard !hasStarted else { return }
            hasStarted = true
            startSequence()
        }
    }
    
    private func startSequence() {
        Task {
            while true {
                // Fade in
                withAnimation(.easeInOut(duration: timing.fadeDuration)) {
                    phase = .visible
                }
                
                try await Task.sleep(nanoseconds: timing.visibleNanoseconds)
                
                // Fade out
                withAnimation(.easeInOut(duration: timing.fadeDuration)) {
                    phase = .hidden
                }
                
                try await Task.sleep(nanoseconds: timing.fadeNanoseconds)
                
                // Swap text while fully invisible
                currentIndex = (currentIndex + 1) % messages.count
                
                // One frame safety delay
                try await Task.sleep(nanoseconds: 50_000_000)
            }
        }
    }
}



struct ContentView: View {
    var body: some View {
        ZStack {
            // Your app UI
            Color.blue.ignoresSafeArea()
            
            InstructionOverlay(messages: [
                "TAP TO SELECT",
                "SWIPE TO MOVE",
                "PINCH TO ZOOM"
            ],
                               timing: InstructionTiming(
                                fadeDuration: 0.45,
                                visibleDuration: 1.5
                               ))
        }
    }
}



#Preview("Short Instructions") {
    InstructionOverlay(messages: [
        "TAP",
        "SWIPE",
        "GO!"
    ])
}

#Preview("Onboarding Style") {
    ZStack {
        Color.black.ignoresSafeArea()
        InstructionOverlay(messages: [
            "BE BRAVE",
            "PLAY TO THE END",
            "ASSIGN \nPOST-GAME BRACKETS",
            "LET'S BEGIN"
        ],
                           timing: InstructionTiming(
                            fadeDuration: 0.45,
                            visibleDuration: 1.5
                           ))
    }
}
