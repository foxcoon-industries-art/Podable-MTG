import SwiftUI


enum PodAnimationStyle: CaseIterable  {
    case bouncer
    case pumper
    case jitterbug
    case wobbler
    case spinner
    case throbber
    case drifter
}


@MainActor
struct PodAnimationModifier: ViewModifier {
    var style: PodAnimationStyle
    var color: Color

    @State private var scale: CGFloat = 1.0
    @State private var scaleX: CGFloat = 1.0
    @State private var scaleY: CGFloat = 1.0
    @State private var offsetX: CGFloat = 0.0
    @State private var offsetY: CGFloat = 0.0
    @State private var secondOffsetY: CGFloat = 0.0
    @State private var jitterOffset: CGSize = .zero
    @State private var isJitterbugging: Bool = false

    @State private var rotation: Double = 0
    @State private var secondRotation: Double = 0
    @State private var opacity: Double = 0
    @State private var wobbleX: CGFloat = 1.0
    @State private var wobbleY: CGFloat = 1.0

    func body(content: Content) -> some View {
        content
            .scaleEffect(x: wobbleX, y: wobbleY)
            .scaleEffect(scale)
            .offset(y: offsetY)
            .offset(y: secondOffsetY)
            .offset(x: offsetX)
            .offset(jitterOffset)
            .rotationEffect(.degrees(rotation))
            .rotationEffect(.degrees(secondRotation))
            .onAppear {
                switch style {
                case PodAnimationStyle.bouncer:
                    withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                        offsetY = -6
                    }
                    
                case PodAnimationStyle.pumper:
                    withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                        scale = 1.15
                    }
                    
                case PodAnimationStyle.jitterbug:
                    withAnimation(.easeInOut(duration: 0.2).repeatForever(autoreverses: true)) {
                        offsetX = -2
                        offsetY = 2
                        scale = 0.98
                    }

                case PodAnimationStyle.wobbler:
                    withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                        wobbleX = 1.1
                        wobbleY = 0.9
                    }
                    
                case PodAnimationStyle.spinner:
                    withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                        rotation = -11
                        scale = 0.98
                    }
                    withAnimation(.easeInOut(duration: 0.1 * .pi).repeatForever(autoreverses: true)) {
                        secondRotation = 11
                        scale = 1.02
                    }
                    
                case PodAnimationStyle.throbber:
                    withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                        wobbleX = 0.95
                        wobbleY = 1.05
                    }

                case PodAnimationStyle.drifter:
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        offsetX = 3
                        offsetY = -3
                        opacity = 0.85
                    }

                }
            }
    }
}


extension View {
    func applyPodAnimation(style: PodAnimationStyle, color: Color) -> some View {
        self.modifier(PodAnimationModifier(style: style, color: color))
    }
}


extension View {
    /// Conditionally applies a pod animation if `isActive` is true.
    /// - Parameters:
    ///   - isActive: Whether the animation should run
    ///   - style: The animation style to use
    ///   - color: The color associated with the pod
    /// - Returns: Modified view
    func applyPodAnimationIfNeeded(isActive: Bool, style: PodAnimationStyle, color: Color) -> some View {
        // Only apply the animation if active
        Group {
            if isActive {
                self.modifier(PodAnimationModifier(style: style, color: color))
            } else {
                self
            }
        }
    }
}
