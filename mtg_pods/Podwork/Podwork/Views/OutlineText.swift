import SwiftUI

public struct StrokeModifier: ViewModifier {
    var strokeSize: CGFloat = 1
    var strokeColor: Color = Color.blue
    let uuid = UUID()
    
    public func body(content: Content) -> some View {
        content
            .padding(strokeSize)
            .background(
                Rectangle()
                    .foregroundStyle(strokeColor.gradient)
                    .mask(outline(context: content))
            )
    }
    
    private func outline(context: Content) -> some View {
        Canvas { context, size in
            context.addFilter(.alphaThreshold(min: 0.01))
            context.drawLayer { layer in
                if let text = context.resolveSymbol(id: uuid) {
                    layer.draw(text, at: CGPoint(x: 0.5*size.width, y: 0.5*size.height))
                }
            }
        } symbols: {
            context.tag(uuid).blur(radius: strokeSize)
        }
    }
}


extension View {
    public func customStroke(color: Color, width: CGFloat) -> some View {
        self.modifier(StrokeModifier(strokeSize: width, strokeColor: color))
    }
}


#Preview {
    ZStack{
        Color.clear
            .background(.gray)
        
        Text("Outlined Text")
            .font(.largeTitle)
            .foregroundStyle(.white)
            .customStroke(color: .blue, width: 1.750)
            .customStroke(color: .black, width: 0.50)
    }
}
