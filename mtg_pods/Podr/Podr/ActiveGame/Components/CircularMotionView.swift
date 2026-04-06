import SwiftUI

struct CircularMotionView: View {
    @State var color: Color
    @State private var angle: Double
    @State private var isForward: Bool = true
    @State private var animationTask: Task<Void, Never>? = nil
    @State var duration: Double
    
    let radius: CGFloat
    let startAngle: Double
    let endAngle: Double

    let updateRate: Double = 1.0 / 30.0
    

    
    init(color: Color, radius: CGFloat, startAngle: Double, endAngle: Double) {
        self.color = color
        self.radius = radius
        self.startAngle = startAngle
        self.endAngle = endAngle
        _angle = State(initialValue: startAngle)
        self.duration = 1.0
    }

    init(color: Color, radius: CGFloat, startAngle: Double, endAngle: Double, duration: Double) {
        self.color = color
        self.radius = radius
        self.startAngle = startAngle
        self.endAngle = endAngle
        _angle = State(initialValue: startAngle)
        self.duration = duration
    }
    
    private var oneSecondAnimation: Animation {
        .linear(duration: 1.0)
    }
    
    func forwardDurationPercent() -> Double {
        if self.isForward { return  ( (endAngle - startAngle ) / (2 * .pi))  }
        return 1 - ( abs(endAngle - startAngle) / ( 2 * .pi))
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill( !isForward ? color.gradient : Color.red.gradient)
                .frame(width: 20, height: 20)
                .offset(x: cos(angle) * radius, y: sin(angle) * radius)
                //.animation(.linear(duration: duration), value: angle)
                //.animation(oneSecondAnimation.speed(forwardDurationPercent() / updateRate), value: angle)
        }
        .onAppear {
            startConcurrentAnimation()
        }
        .onDisappear {
            animationTask?.cancel()
        }
    }
    
    func startConcurrentAnimation() {
        let fps = updateRate * 1_000_000_000 // forwardDurationPercent()
        animationTask?.cancel()  // cancel previous if any
        
        animationTask = Task {
            let totalAngle = abs(endAngle - startAngle)
            let delta = totalAngle / (duration / updateRate)
            //let _ = print("totalAngle", totalAngle, "delta", delta,"startAngle", startAngle, "endAngle", endAngle)
            
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(fps))
                
                await MainActor.run {
                    if isForward {
                        angle = min(angle + delta, endAngle)
                        //let _ = print("angle", angle)
                        // totalAngle is using radians currently -> convert to deg

                        if angle == endAngle {
                            isForward = false
                            print("b",forwardDurationPercent())
                        }
                    } else {
                        angle = max(angle - delta, startAngle)
                        if angle == startAngle {
                            isForward = true
                            print("f",forwardDurationPercent())
                        }
                    }
                }

            }
        }
    }
}

func toDeg( _ angle: Double) -> Double{
    return (angle * 180.0 / .pi)
}

func toRad( _ angle: Double) -> Double{
    return (angle * .pi / 180.0)
}

struct CircularMotionView_Previews: PreviewProvider {
    static var previews: some View {
        CircularMotionView(color: Color.blue, radius: 100.0, startAngle: 0.0, endAngle: 2 * .pi)
    }
}




