import SwiftUI
import Podwork

struct AnimatedIconView: View {
    @State private var animate = false
    
    var body: some View {
        Image(systemName: "sparkles") 
            .resizable()
            .frame(width: PodworkUIConstants.podSize, height:  PodworkUIConstants.podSize)
            .foregroundStyle(Color.yellow.gradient)
            .onAppear {
                animate = true
            }
            .phaseAnimator([false, true], content: { content, animate in
                content
                    .symbolEffect(.wiggle.byLayer, options: .repeat(3), value: animate)
                    .symbolEffect(.bounce.byLayer, options: .repeat(3), value: animate)
                    .symbolEffect(.pulse.byLayer, options: .repeat(3), value: animate)
                    .symbolEffect(.breathe.byLayer, options: .repeat(3), value: animate)
            })
    }
}


#Preview {
    AnimatedIconView()
}
