import SwiftUI
import Podwork


public struct InfectQuadQuickView: View {
    let infect: [Int]
    
    public init(infect: [Int]) {
        self.infect = infect
    }
    
    public var body: some View{
        let _ = print("infect: \(infect)")
        ZStack{
            quads(bkg:true)
            RoundedRectangle(cornerRadius: 12)
                .background(.ultraThinMaterial)
                .frame(width: 2.250*PodworkUIConstants.podSize / 1.750, height: 2.75*PodworkUIConstants.podSize / 1.750)
//            Circle()
            //.background(.ultraThinMaterial)
//            .cornerRadius(12)
            PhiView()
                //.aspectRatio(1, contentMode: .fit)
                //.frame(width: 60)
            quads(bkg:false)
        }
        //.border(.blue,width:6)
        .mask {
            RoundedRectangle(cornerRadius: 12)
                .frame(width: 2.250*PodworkUIConstants.podSize / 1.750, height: 2.75*PodworkUIConstants.podSize / 1.750)
        }
        //.border(.red,width:4)
        //.aspectRatio(1, contentMode: .fill)
        //.frame(maxHeight: 60)
        //.border(Color.yellow)
    }

    @ViewBuilder
    func quads(bkg: Bool) -> some View {
        HStack(alignment: .center, spacing:-15){
            VStack(alignment: .leading, spacing:5){
                infectLabel( infect[Quadrant.topLeft.rawValue], quad: Quadrant.topLeft, bkg: bkg  )
                infectLabel( infect[Quadrant.bottomLeft.rawValue], quad: Quadrant.bottomLeft, bkg: bkg )
            }
            VStack(alignment: .trailing, spacing:5){
                infectLabel( infect[Quadrant.topRight.rawValue], quad: Quadrant.topRight, bkg: bkg  )
                infectLabel( infect[Quadrant.bottomRight.rawValue], quad: Quadrant.bottomRight, bkg: bkg )
            }
        }
    }
    
    @ViewBuilder
    func infectLabel(_ infect : Int, quad: Quadrant, bkg: Bool = true ) -> some View {
        Text(String(infect))
            .font(.title3)
            .bold()
            .foregroundStyle(getColor(for: quad.rawValue))
            .customStroke(color: Color.black, width: 0.5)
            //.foregroundStyle(bkg ? Color.white.gradient : Color.black.gradient)
            .frame(width: 30, height: 30)
            .padding()
            .background(bkg ?  getColor(for: quad.rawValue) : Color.clear)
            .clipShape(Circle())
           
    }
}


/// /*=========================================================================*/
struct PhiView: View {
    let oneArcSection : Double = 360.0 / Double(8)
    let deltaArc : Double = 360.0 / Double(15*15)
    let radius : CGFloat = 0.325 * GameUIConstants.podSize
    let ringThickness: CGFloat = 7.50
    let poisonCounters: Int = 10
    
    var body: some View{

            ZStack{
                // [existing arc rendering code]
                ///Coloured  in  arc segments from pervious turn commander damage
                ForEach(0..<8, id: \.self) { dmgIndex in
                    ArcSegment(
                        startAngle: .degrees(Double(dmgIndex) * oneArcSection),
                        endAngle: .degrees( (Double(dmgIndex + 1) * oneArcSection) - deltaArc )
                    )
                    .stroke( Color.black.gradient.opacity(0.8),  lineWidth:  ringThickness)
                    .aspectRatio(CGSize(width: 1, height: 1), contentMode: .fill)
                    .frame(width: 2 * radius, height: 2 * radius)
                }
                CenterLineSegment(radius: 6 * ringThickness, sign: -1)
                    .stroke( Color.black.gradient.opacity(0.8), lineWidth:  ringThickness)
                    .frame(width:0.75*PodworkUIConstants.podSize, height: 0.75*PodworkUIConstants.podSize )
                    .zIndex(-1)
                CenterLineSegment(radius: -6 * ringThickness, sign: 1.0)
                    .stroke( Color.black.gradient.opacity(0.8), lineWidth:  ringThickness)
                    .frame(width:0.75*PodworkUIConstants.podSize ,height: 0.75*PodworkUIConstants.podSize )
                    .zIndex(-1)
                    
        }


    }
}

/// /*=========================================================================*/
struct CenterLineSegment: Shape {
    let radius: CGFloat
    let sign: CGFloat
    let deltaArc : Double = 0.05*360.0 / Double(8*8)
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        //let radius = 0.5 * min(rect.width, rect.height)
        
        path.addLines( [center - radius, center + sign * deltaArc])
        //path.addLine(to: endPoint)
        return path
    }
}

/// /*=========================================================================*/
struct ArcSegment: Shape {
    let startAngle: Angle
    let endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = 0.5 * min(rect.width, rect.height)
        
        path.addArc(center: center, radius: radius,
                    startAngle: startAngle + .degrees(135),
                    endAngle: endAngle + .degrees(135),
                    clockwise: false)
        return path
    }
}

#Preview{
    InfectQuadQuickView(infect: [0,2,5,10])
}
