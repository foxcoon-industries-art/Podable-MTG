import SwiftUI
import Podwork


struct PoisonCounterView: View {
    @Binding var count: Int
    @Binding var isVisible: Bool
    
    let diameter: CGFloat = 20
    let spacing: CGFloat = 20
    let radius: CGFloat = 40
    let n: Double = 7
    let m: Double = 3
    
    let theta: Double = -39.0
    
    var body: some View {
        ZStack  {
            Text("ɸ")
                .font(.system(size: 150))
                .fontWeight(.bold)
                .foregroundStyle(.gray)
                .customStroke(color: .black, width: 0.50)

            ForEach(0..<10, id: \.self) { i in
                Circle()
                    .fill(i < count ? Color.black : Color.gray.opacity(0.3))
                    .stroke( i+1 == 10 ? Color.green : Color.clear, lineWidth: 1.5)
                    .stroke( i == 0 ? Color.red : Color.clear, lineWidth: 1.5)
                    
                    .frame(width: diameter, height: diameter)
                    .overlay(
                        Text( i == 0 ? "-" : ( i == 9 ? "+" : " " ) )
                            .foregroundColor(Color.white)
                            .bold()
                            .customStroke(color: .black, width: 0.50)

                    )
                    .position(position(for: i))
                    .onTapGesture {
                        handleTap(index: i)
                    }
            }
        }
        .offset(y: -10)
        .frame(width: totalSize.width, height: totalSize.height)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .opacity(isVisible ? 1 : 0)
        .animation(.easeInOut, value: isVisible)
        .padding(8)
        .frame(maxHeight: 1.5 * PodworkUIConstants.podSize)
    }
    
    // MARK: - Position Calculation
    private func position(for index: Int) -> CGPoint {
        let center = CGPoint(x: totalSize.width / 2, y: totalSize.height / 2)
        
        let curveYOffset: CGFloat = 20
        let stemYOffset: CGFloat = 20
        
        if index < Int(n - 1) {
            /// Circle Ring
            let freq: Double = 360 / n
            let angle = Angle(degrees: theta + (Double(index) * freq))
            let x = center.x + radius * cos(CGFloat(angle.radians))
            let y = center.y + radius * sin(CGFloat(angle.radians)) + curveYOffset
            return CGPoint(x: x, y: y)
        } else {
            /// Center vertical line
            let verticalSpacing = diameter + spacing
            let offset = CGFloat(Double(index) - n - (m - 2) / 2) * verticalSpacing + stemYOffset
            return CGPoint(x: center.x, y: center.y + offset)
        }
    }
    
    
    // MARK: - Dynamic Size Calculation
    private var totalSize: CGSize {
        let verticalLineHeight = (CGFloat(4) * diameter) + (CGFloat(3) * spacing)
        let totalHeight = max(2 * (radius + diameter), verticalLineHeight + diameter)
        let totalWidth = 2 * (radius + diameter)
        return CGSize(width: totalWidth, height: totalHeight)
    }
    
    private func handleTap(index: Int) {
        if index < count {
            count -= 1
        } else if count < 10 {
            count += 1
        }
    }
}


struct PhiSegments: View {
    @Binding var poisonCounters: Int
    @Binding var isVisible: Bool
    
    let oneArcSection : Double = 360.0 / Double(8)
    let deltaArc : Double = 360.0 / Double(8*8)
    let radius : CGFloat = 0.5 * GameUIConstants.podSize
    let ringThickness: CGFloat = 10
    
    var body: some View{
        VStack(spacing: 0){
            ZStack{
                /// [from existing arc rendering code]
                /// Coloured  in  arc segments from pervious turn commander damage
                ForEach(0..<8, id: \.self) { dmgIndex in
                    ArcSegment(
                        startAngle: .degrees(Double(dmgIndex) * oneArcSection),
                        endAngle: .degrees( (Double(dmgIndex + 1) * oneArcSection) - deltaArc )
                    )
                    
                    .stroke( dmgIndex < poisonCounters ? Color.white.gradient.opacity(1.0) : Color.gray.gradient.opacity(0.5), lineWidth:  1.075*ringThickness)
                    
                    .stroke( dmgIndex < poisonCounters ? Color.black.gradient.opacity(1.0) : Color.gray.gradient.opacity(0.5), lineWidth:  0.96*ringThickness)

                    .aspectRatio(CGSize(width: 1, height: 1), contentMode: .fill)
                    .frame(width: 2.0 * radius, height: 2.0 * radius)

                }
                LineSegment(radius: 5 * ringThickness, sign: -1)
                    .stroke( poisonCounters >= 9 ? Color.white.gradient.opacity(1.0) : Color.gray.gradient.opacity(0.5), lineWidth:  1.075*ringThickness)
                    .stroke( poisonCounters >= 9 ? Color.black.gradient.opacity(1.0) : Color.gray.gradient.opacity(0.5), lineWidth:  0.96*ringThickness)
                    .zIndex(-1)
                LineSegment(radius: -5 * ringThickness, sign: 1.0)
                    .stroke( poisonCounters >= 10 ? Color.white.gradient.opacity(1.0) : Color.gray.gradient.opacity(0.5), lineWidth:  1.075*ringThickness)
                    .stroke( poisonCounters >= 10 ? Color.black.gradient.opacity(1.0) : Color.gray.gradient.opacity(0.5), lineWidth:  0.96*ringThickness)
                    .zIndex(-1)
                
                Text("\(poisonCounters)")
                    .font(.system(size:34))
                    //.font(.title)
                    .bold()
                    .customStroke(color: Color.black, width: 1.0)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                
                
            }
            /*
            HStack(){
                Text(" - ")
                    .foregroundStyle(Color.black)
                    .padding(6)
                    .bold()
                    .background(Color.pink.secondary)
                    .clipShape(Circle())
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        poisonCounters -= 1
                        if poisonCounters <= 0 { poisonCounters = 0}
                    }
                
                Text("\(poisonCounters)")
                    .font(.title2)
                    .bold()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                
                Text(" + ")
                    .foregroundStyle(Color.black)
                    .padding(4)
                    .bold()
                    .background(Color.teal.secondary)
                    .clipShape(Circle())
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        poisonCounters += 1
                        if poisonCounters >= 10 { poisonCounters = 10}
                    }
            }
            */
        }
        //.offset(y: -10)
        .frame(width: 1.75*PodworkUIConstants.podSize, height: 2.5*PodworkUIConstants.podSize)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .opacity(isVisible ? 1 : 0)
        .animation(.easeInOut, value: isVisible)
        .padding(8)
        .frame(maxHeight: 3.5 * PodworkUIConstants.podSize)
        .cornerRadius(12)
        .clipShape(
            Circle())
                //.frame(width: 1.25*PodworkUIConstants.podSize,  height: 1.25*PodworkUIConstants.podSize))
    }
}

struct LineSegment: Shape {

    let radius: CGFloat
    let sign: CGFloat
    let deltaArc : Double = 0.25*360.0 / Double(8*8)
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        path.addLines( [center - radius, center + sign * deltaArc])
        return path
    }
}



struct OilButton: View {
    var fillPercent: CGFloat 
    
    var body: some View {
        ZStack {
            Text("φ")
                .offset(y:-3)
                .font(.largeTitle)
                //.bold()
                //.foregroundStyle(Color.white.opacity(0.4 + fillPercent).gradient)
                .foregroundStyle(Color.white.opacity(1.1).gradient)
                .customStroke(color: Color.black, width: 0.50)
                .frame(width: PodworkUIConstants.podSize, height: PodworkUIConstants.podSize)
                .background(
                    Color.black.gradient
                )
//                .background(
//                    GeometryReader { geo in
//                        ZStack(alignment: .bottom) {
//                            Color.black
//                                .frame(height: geo.size.height * fillPercent)
//                        }
//                    }
//                )
                .overlay(
                    Circle()
                        .stroke(fillPercent != 0 ? .gray : .clear, lineWidth: 2)
                )
                .clipShape(Circle())
                .background(.clear)
                .padding([.horizontal],0)
                .clipShape(Circle())
        }
    }
    
}


@MainActor
public struct DoublePhiPodView: View {
    @Bindable var game: GameState
    @Bindable var dragState: PodDragState
    
    @ViewBuilder
    public var body: some View {
        VStack{
            Spacer(minLength: 0)
            HStack{
                PhiPodView(quadrantSide: Quadrant.topLeft, game: game, dragState: dragState)
                Spacer(minLength: 0)
                PhiPodView(quadrantSide: Quadrant.bottomRight, game: game, dragState: dragState)
            }
            Spacer(minLength: 0)
        }
    }
}






@MainActor
public struct PhiPodView: View {
    let quadrantSide: Quadrant
    @Bindable var game: GameState
    @Bindable var dragState: PodDragState
    
    @GestureState private var dragOffset: CGSize = .zero
    
    var index : Int {
        if quadrantSide == Quadrant.bottomLeft || quadrantSide == Quadrant.topLeft { return 0 }
        return 1  }
    ///var playerConfig: PlayerLayoutConfig {  PlayerLayoutConfig.config(for: index) }
    //private var isEliminated: Bool { game.players[index].isPlayerEliminated() || game.players[index].winner == true }
    private let halfPodSize = GameUIConstants.podSize * 0.5
    
    
    @ViewBuilder
    public var body: some View {
        phiPod
        .onTapGesture(count: 1) {
            handleSingleTap()
        }
        .offset(dragState.draggedPhiOffsets[index])
        .gesture(optimizedDragGesture)
        .background(frameReader)
        .compositingGroup()
        //.opacity(isEliminated ? 0.0 : 1.0)
        //.opacity(dragState.showPoisonDots[index] ? 0 : 1 )
        
    }
    
    @ViewBuilder
    private var phiPod: some View {
        OilButton(fillPercent: 1.0)
    }
    
    
    @ViewBuilder
    private var frameReader: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear {
                    if dragState.phiPodCenters[index] == nil {
                        dragState.phiPodCenters[index] = proxy.frame(in: .global).origin
                    }
                }
        }
    }
    
    @MainActor
    private var optimizedDragGesture: some Gesture {
        DragGesture(minimumDistance: 0.10)
        
            .updating($dragOffset) { value, state, transaction in
                /// This updates the @GestureState automatically
                state = value.translation
                
                /// Disable animations for smooth dragging
                transaction.animation = nil
                
                /// Update collision detection logic here if needed
                handleDragChanged( value)
            }
        
            .onEnded { value in
                handleDragEnded(value)
            }
    }
    
    @MainActor
    private func handleDragChanged(_ value: DragGesture.Value) {
        /// Always update visual position (smooth)
        dragState.draggedPhiOffsets[index] = value.translation
        
        /// Throttle expensive calculations
        guard dragState.shouldUpdate(), let origin = dragState.phiPodCenters[index] else { return }
        
        let draggedCenter = CGPoint(
            x: origin.x + value.translation.width + halfPodSize,
            y: origin.y + value.translation.height + halfPodSize
        )
        
        // Batch all the expensive checks
        performOverlapChecks(at: draggedCenter)
        
        
    }
    
    
    private func performOverlapChecks(at point: CGPoint) {
        if let quadrant = determineQuadrant(from: point){
            let _ = print("Quadrant: \(quadrant)")
            dragState.highlightedPhiQuadrantIndex = quadrant.rawValue
        } else {
            dragState.highlightedPhiQuadrantIndex = nil
        }
    }
    
    
    private func determineQuadrant(from globalLocation: CGPoint) -> Quadrant? {
        /// Center of the full container in global coordinates
        let center = CGPoint(x: 0.5*dragState.containerSize.width, y: 0.5*dragState.containerSize.height)
        
        /// Determine position relative to the center
        let relative = CGPoint(x: globalLocation.x - center.x,
                               y: globalLocation.y - center.y)
        
        if relative.x < 0, relative.y < 0 { return Quadrant.topLeft }
        if relative.x >= 0, relative.y < 0 { return Quadrant.topRight }
        if relative.x < 0, relative.y >= 0 { return Quadrant.bottomLeft }
        if relative.x >= 0, relative.y >= 0 { return Quadrant.bottomRight }
        
        return nil
    }
    
    
    private func handleDragEnded(_ value: DragGesture.Value) {
        guard let origin = dragState.phiPodCenters[index] else { return }
        
        let finalPosition = CGPoint(
            x: origin.x + value.translation.width + GameUIConstants.podSize * 0.5,
            y: origin.y + value.translation.height + GameUIConstants.podSize * 0.5
        )
        
        if let endedQuadrant = determineQuadrant(from: finalPosition){
            dragState.showPoisonDots[endedQuadrant.rawValue] = true
            dragState.showDamageButtonInQuadrant[endedQuadrant.rawValue] = true
            let _ = print("Dropped on: \(endedQuadrant)")
        }

        //let centerOverlap = dragState.findOverlappingFrame(point: finalPosition,
                                                     //          in: dragState.centerPodFrames)
       
        //} else { dragState.highlightedDamageLabelIndex = nil }
    
        resetDragState()
    }
    
    
    
    /**/
    private func handleSingleTap() {
        if index == 0 {
            dragState.showPoisonDots[Quadrant.topLeft.rawValue] = false
            dragState.showDamageButtonInQuadrant[Quadrant.topLeft.rawValue] = false

            dragState.showPoisonDots[Quadrant.bottomLeft.rawValue] = false
            dragState.showDamageButtonInQuadrant[Quadrant.bottomLeft.rawValue] = false

            
            //dragState.showDamageButtonInQuadrant[index].toggle()
        } else {
            dragState.showPoisonDots[Quadrant.topRight.rawValue] = false
            dragState.showDamageButtonInQuadrant[Quadrant.topRight.rawValue] = false
            
            dragState.showPoisonDots[Quadrant.bottomRight.rawValue] = false
            dragState.showDamageButtonInQuadrant[Quadrant.bottomRight.rawValue] = false
        }
        
        //dragState.highlightedPodIndex[index] = index
       // dragState.showPoisonDots[quadrantSide.rawValue] = false
    }
    
    /**/
    private func resetDragState() {
        dragState.draggedPhiOffsets[index] = .zero
        dragState.highlightedPhiQuadrantIndex = nil
    }
    
    
}











struct PoisonCounterView_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State private var poisonCount: Int = 4
        @State private var showDots: Bool = true
        
        var body: some View {
            VStack(spacing: 40) {
                
                LineSegment(radius: 30 , sign: -1.0 )
                    .stroke(Color.black, lineWidth:  5)
                   
                PhiSegments(poisonCounters: $poisonCount, isVisible: $showDots)
                    .border(.red)
                OilButton(fillPercent: 0.0)
                OilButton(fillPercent: 0.1)
                OilButton(fillPercent: 0.5)
                
                PoisonCounterView(count: $poisonCount, isVisible: $showDots)
                
                Button("Toggle Dots") {
                    showDots.toggle()
                }
                
                Text("Current Poison: \(poisonCount)")
                    .font(.headline)
            }
            .padding()
            .background(Color.black.opacity(0.05))
        }
    }
    
    static var previews: some View {
        PreviewWrapper()
            .previewLayout(.sizeThatFits)
    }
}
