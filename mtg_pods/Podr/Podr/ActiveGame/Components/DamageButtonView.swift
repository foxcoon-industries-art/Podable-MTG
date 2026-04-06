import SwiftUI
import Podwork


@MainActor
struct DamageButtonView: View {
    let action: () -> Void
    let text: String
    let color: Color
    let width: CGFloat
    let showButton: Bool
    
    @State var placeTapped : CGPoint? = nil
    @State var buttonHighlight : Bool = false
    @State var holdTapStartTime : Date = Date.now
    let showTime = 0.1250
    
    
    var body: some View {
        ZStack{
            mainButton
            //tapLine
        }
    }
    
    
    @MainActor
    @ViewBuilder
    var mainButton: some View {
        Button(action: action) {
            Image(systemName: text == "↑" ? "chevron.up" : "chevron.down")
                .font(.largeTitle)
                .foregroundStyle(Color.white.gradient)
                .multilineTextAlignment(.center)
                .customStroke(color: Color.black, width: 1.633)
                //.offset(y: text == "↑" ? 4 : 4 )
                .frame(width: width, height:  0.5 * width , alignment: text == "↑" ?  .bottom  : .top )
                .frame(maxHeight: .infinity, alignment: text == "↑" ?  .center  :  .center)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
               .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.35))
                .stroke(color, style: StrokeStyle( lineWidth: 20) )
                .background(Color.gray.gradient.opacity(showButton ? 1 : 0))
                .colorMultiply(color == Color.gray ? Color.red : color)
                .opacity(self.buttonHighlight ? 0.950 : 0.4567)
        )
        .highPriorityGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in  self.buttonHighlight = true }
            
                .onEnded { value in
                    self.placeTapped = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.001) {
                        HapticFeedback.impact(.medium)
                        self.buttonHighlight = false
                    }
                    action()
                }
        )
        .padding(0)
        .padding(.horizontal, 3)
        .minimumScaleFactor(0.1)
        .buttonRepeatBehavior(.enabled)
    }
   
}






#Preview {
    VStack {
        DamageButtonView(action: {}, text: "+", color: .blue, width: 100,showButton: true)
        DamageButtonView(action: {}, text: "-", color: .red, width: 100, showButton: true)
    }
    .border(.black)
}
