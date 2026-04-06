import SwiftUI


@MainActor
public struct ShimmerModifier: ViewModifier {
    @State private var animate: Bool = false
    let speed: Double = 10.0
    let angle: Angle = .degrees(20)
    let highlightColor: Color = .white.opacity(0.8)
    let baseColor: Color = .black.opacity(0.125)
    
    public init() {  }
    
    public func body(content: Content) -> some View {
        content
            // The mask is crucial: it restricts the shimmer gradient to the shape of the content
            .mask(content)
        
            // Use an overlay to place the animated gradient on top
            .overlay(GeometryReader { geometry in
                let startPoint = UnitPoint(x: 0.33, y: 0.33)
                let endPoint = UnitPoint(x: 0.666, y: 0.666) // End far off-screen to ensure continuous movement
                VStack(spacing:0){
                    LinearGradient(
                        colors:  [baseColor, highlightColor, baseColor],
                        startPoint: animate ? endPoint : startPoint,
                        endPoint: animate ? startPoint : endPoint
                    ).frame(maxHeight:.infinity)
                    LinearGradient(
                        colors:  [baseColor, highlightColor, baseColor],
                        startPoint: animate ? endPoint : startPoint,
                        endPoint: animate ? startPoint : endPoint
                    ).frame(maxHeight:.infinity)
                    LinearGradient(
                        colors:  [baseColor, highlightColor, baseColor],
                        startPoint: animate ? endPoint : startPoint,
                        endPoint: animate ? startPoint : endPoint
                    ).frame(maxHeight:.infinity)
                    LinearGradient(
                        colors:  [baseColor, highlightColor, baseColor],
                        startPoint: animate ? endPoint : startPoint,
                        endPoint: animate ? startPoint : endPoint
                    ).frame(maxHeight:.infinity)
                }
                .frame(height: 4*UIScreen.main.bounds.height)
                .ignoresSafeArea()
                .frame(maxHeight:.infinity)
                .opacity(0.37)
                .onAppear {
                    withAnimation(.easeInOut(duration: speed).repeatForever(autoreverses: true)) {
                        animate = true
                    }
                    
                }
            })
    }
}


// Extension to make the modifier easy to use
@MainActor
public extension View {
    public func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}
