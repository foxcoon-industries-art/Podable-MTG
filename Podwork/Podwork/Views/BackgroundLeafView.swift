import SwiftUI

public struct BackgroundLeafView: View {
    public let backdropColor: Color
    public let leafWidth: CGFloat
    public let foredropColor: Color = Color.clear
    public let steelGray = Color(white: 0.8845)
    //public let steelGray = Color(white: 0.4345)

    public init(backdropColor : Color) {
        self.backdropColor = backdropColor
        self.leafWidth = 0.666
    }
    
    public init(backdropColor : Color, leafWidth: CGFloat) {
        self.backdropColor = backdropColor
        self.leafWidth = leafWidth
    }

    public var body: some View {
        ZStack {
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                
                ZStack {
                    Rectangle()
                        .fill(backdropColor.gradient.opacity(0.55))
                        .frame(width: width, height: height*0.90)
                     
                    RoundedRectangle(cornerRadius: 30)
                        .fill(steelGray.gradient)
                        .stroke(Color.black, lineWidth: 3)
                        .frame(width: width*self.leafWidth, height: 1.0*height)
                        .cornerRadius(17)
                        .shadow(color: Color.black, radius: 10)
                        .multilineTextAlignment(.center)
                }
            }
            .background(Color.black.gradient)
        }
    }
}

#Preview {
    BackgroundLeafView(backdropColor: Color.orange)
}
