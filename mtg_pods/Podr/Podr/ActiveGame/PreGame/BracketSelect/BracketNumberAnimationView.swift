import SwiftUI
import Podwork


enum Bracket: Int, CaseIterable {
    case bracket_minus1 = -1
    case bracket_0 = 0
    case bracket_1 = 1
    case bracket_2 = 2
    case bracket_3 = 3
    case bracket_4 = 4
    case bracket_5 = 5
    
    var displayName: String {
        switch self {
        case .bracket_minus1: return "No Bracket Set"
        case .bracket_0: return "Rule Zero"
        case .bracket_1: return BracketSystem.bracket_1.displayName
        case .bracket_2: return BracketSystem.bracket_2.displayName
        case .bracket_3: return BracketSystem.bracket_3.displayName
        case .bracket_4: return BracketSystem.bracket_4.displayName
        case .bracket_5: return BracketSystem.bracket_5.displayName
        }
    }
    
    var color: Color {
        switch self {
        case .bracket_minus1: return Color.brown.opacity(0.2)
        case .bracket_0: return Color.gray.opacity(0.2)
        case .bracket_1: return BracketSystem.bracket_1.color
        case .bracket_2: return BracketSystem.bracket_2.color
        case .bracket_3: return BracketSystem.bracket_3.color
        case .bracket_4: return BracketSystem.bracket_4.color
        case .bracket_5: return BracketSystem.bracket_5.color
        }
    }
    
    var emoji: String {
        switch self {
        case .bracket_minus1: return "❓"
        case .bracket_0: return "👌"
        case .bracket_1: return BracketSystem.bracket_1.emoji
        case .bracket_2: return BracketSystem.bracket_2.emoji
        case .bracket_3: return BracketSystem.bracket_3.emoji
        case .bracket_4: return BracketSystem.bracket_4.emoji
        case .bracket_5: return BracketSystem.bracket_5.emoji
        }
    }
}



@MainActor
struct BracketSelector: View {
    let playerIndex: Int
    @Binding var selectedBracket: Int
    var commanderName: String? = nil
    var commanderColor: Color? = nil
    
    @State var podTapped: Bool? = nil
    var onReturn: () -> Void
    
    public init(playerIndex: Int, selectedBracket: Binding<Int>, commanderName: String? = nil, commanderColor: Color? = nil, onReturn: (() -> Void)? = nil) {
        self.playerIndex = playerIndex
        self._selectedBracket = selectedBracket
        self.commanderName = commanderName
        self.commanderColor = commanderColor
        self.onReturn = onReturn == nil ? {} : onReturn!
    }
    
    @GestureState private var dragOffset: CGSize = .zero
    @State private var draggedOffsets: CGSize = .zero
    @State public var dragPoints: [CGPoint] = []
    @State public var origin: CGPoint = .zero
    @State var angleOfPod : Double =  .zero
    var twoPi : CGFloat = 2 * .pi
    
    //let angles = [-1.0, 0.0, 1.0, 2.0, 3.0 ].map{ $0 * (2.0 * .pi / 5.0) - ( 1.0 * .pi / 10.0)}
    //let angleBins = [-1.0, 0.0, 1.0, 2.0, 3.0, -2.0, -1.0].map{ $0 * (2.0 * .pi / 5.0) - ( 4.0 * .pi / 10.0) }
    
    // Set Number 1 in bottom left of star and 5 at bottom right point (increase like an odometer)
    let angles = [-1.0, 0.0, 1.0, 2.0, 3.0 ].map{ $0 * (2.0 * .pi / 5.0) - ( 9.0 * .pi / 10.0)}
    let angleBins = [-1.0, 0.0, 1.0, 2.0, 3.0, -2.0, -1.0 ].map{ $0 * (2.0 * .pi / 5.0) - ( 10.0 * .pi / 10.0) }
    let smallestAngle = -2.0 * (2.0 * .pi / 5.0) - ( 10.0 * .pi / 10.0)
    let largestAngle = 3.0 * (2.0 * .pi / 5.0) - ( 10.0 * .pi / 10.0)
    let R = GameUIConstants.podSize
    
    
    private var playerColor: Color {
        getColor(for: playerIndex)
    }
    
    var displayCommanderName: String {
        if let name = commanderName { return name }
        return ""
    }

    var displayCommanderColor: Color {
        if let color = commanderColor { return color }
        return Color.primary
    }
    
    var displayBracketTitle: String {
        let brkt = selectedBracket
        if brkt == 0 && podTapped == nil {return ""}
        if brkt == -1 {return ""}
        return "\(Bracket(rawValue: brkt)!.displayName)"
    }
    
    var bracket : Bracket { Bracket(rawValue: selectedBracket) ?? Bracket.bracket_0}
    var isSelected : Bool {true}
    
    
    var body: some View {
      
        VStack(spacing: 0.45*R){
                VStack(spacing: -18){
                    bracketLabel
                    bracketDescriptionLabel
                }
                if podTapped == nil {
                    ZStack{
                        backgroundBall
                        bracketBalls
                    }
                } else {
                    if selectedBracket == -1 && podTapped == true {
                        mainPod
                    }
                    else {selectedBracketBall }
                }
            }
            .frame(maxWidth: .infinity)
        
    }
    
    
    @ViewBuilder
    var removedPlayerText : some View {
        ZStack{
            Text("X")
                .font(.title)
                .bold()
                .foregroundStyle(Color.red.gradient)
                .customStroke(color: Color.black, width: 1)
                .opacity( selectedBracket == -1 && podTapped == true ? 1 : 0)
            
            Image(systemName:"checkmark.circle.dotted")
                .font(.title)
                .foregroundStyle(Color.white.gradient)
                .opacity(selectedBracket >= 0  ? 1 : 0)
        }
    }
    
    
    
    
    
    let gaugeNames : [String] = ["gauge.with.dots.needle.0percent",
                                 "gauge.with.dots.needle.33percent",
                                 "gauge.with.dots.needle.50percent",
                                 "gauge.with.dots.needle.67percent",
                                 "gauge.with.dots.needle.100percent"]
    
    @ViewBuilder
    // No Player Label
    // Bracket (-1) : Unselect
    // Bracket (0) :  Bracket zero
    var mainPod : some View {
        Circle()
            .foregroundStyle(getColor(for:playerIndex).gradient)
            .overlay(Circle().fill(Color.gray).opacity(podTapped == true && selectedBracket == -1 ? 1 : 0))
            .overlay(Circle().stroke(Color.black, lineWidth: 1))
            
            .overlay(removedPlayerText)
            .frame(width: GameUIConstants.podSize)
            .offset(dragOffset)
            .gesture(optimizedDragGesture)
            .background(frameReader)
            .onTapGesture(count: 1){
                withAnimation{
                    if podTapped == true {
                        podTapped = nil
                        selectedBracket = -1
                    }
                }
            }
    }
    
    
    @ViewBuilder
    var pod : some View {
        Circle()
            .frame(width: 0.75*GameUIConstants.podSize)
    }
    
    
    @ViewBuilder
    var backgroundBall : some View {
        Circle()
            .background(Color.white.opacity(0.01).clipShape(Circle()))
            .background(.ultraThinMaterial)
            .overlay(Image(systemName: selectedBracket > 0 ?  gaugeNames[selectedBracket-1] : "" ).font(.largeTitle) )
            .opacity(0.1)
            .frame(width: 1.75*GameUIConstants.podSize)
            .clipShape(Circle())
            .onTapGesture(count: 2){
                withAnimation{
                    if podTapped == nil {
                        selectedBracket = 0
                        podTapped = true
                    }
                    else if podTapped == true {
                        selectedBracket = -1
                        podTapped = nil
                    }
                }
            }
            .onLongPressGesture(minimumDuration: 1.0){
              
                if selectedBracket == -1 {
                    selectedBracket = 0
                }
                if selectedBracket > -1 {
                    selectedBracket = -1
                    podTapped = true
                    onReturn()
                }
            
            }
    }
    
    
    @ViewBuilder
    // Bracket Zero Label
    var selectedBracketBall : some View {
        ZStack{
            Circle()
                .background(Color.white.opacity(0.01).clipShape(Circle()))
                .background(.ultraThinMaterial)
                .frame(width: 1.75*GameUIConstants.podSize)
                .clipShape(Circle())
                .foregroundStyle(  Bracket(rawValue: selectedBracket)?.color.gradient ?? Bracket.bracket_0.color.gradient )
            
                .overlay( Circle()
                    .stroke(Color.yellow, lineWidth: 4 )
                        .fill(Color.clear)
                )
            
            Text("\(selectedBracket)")
                .font(.largeTitle)
                .bold()
                .foregroundStyle(  Color.white.gradient )
                .customStroke(color: Color.black, width: 1.0)
        }
        .onTapGesture(count: 2){
            withAnimation{
                if podTapped == nil {
                    podTapped = true
                }
                else if podTapped == true {
                    podTapped = nil
                    selectedBracket = -1
                }
            }
        }
    }
    
    
    @ViewBuilder
    var bracketBalls : some View {
        ZStack{
            ForEach(Array(angles.enumerated()), id: \.offset){ idx, ang in
                ZStack{
                    pod
                        .foregroundStyle( selectedBracket == idx+1 ? Bracket(rawValue: idx+1)?.color.gradient ?? Bracket.bracket_0.color.gradient : Color.clear.gradient)
                    
                        .overlay( Circle()
                            .stroke(selectedBracket == idx+1 ? Color.yellow : Color.clear, lineWidth:
                                        selectedBracket == idx+1 ? 4 : 1)
                                .fill(Color.clear)
                        )
                        .offset(x: R * cos(ang), y: R * sin(ang ) )
                    
                    Text("\(idx+1)")
                        .font(.largeTitle)
                        .bold()
                        .foregroundStyle( selectedBracket == idx+1 ? Color.white.gradient : Bracket(rawValue: idx+1)?.color.gradient ?? Bracket.bracket_0.color.gradient )
                        .customStroke(color: Color.black, width: 1.0)
                        .offset(x: R * cos(ang), y: R * sin(ang) )
                    
                    if let _ = podTapped, selectedBracket == idx+1  {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(Color.yellow.gradient)
                    }
                }
                .opacity(selectedBracket == idx+1 ? 1 : 0.5)
                .onTapGesture(count: 1){
                    withAnimation{
                        if selectedBracket == idx+1 {
                            selectedBracket = -1
                            podTapped = nil
                        }
                        else { selectedBracket = idx+1  }
                        
                    }
                }
                
            }
        }
    }
    
    
    @ViewBuilder
    var bracketDescriptionLabel : some View {
        Text( displayBracketTitle )
            .font(Font.system(.subheadline).smallCaps())
            .bold()
            .foregroundStyle(Color.white.gradient)
            .minimumScaleFactor(1.666)
            .allowsTightening(true)
            .lineLimit(1)
            .padding(.vertical, 10)
            .padding(.top, 3)
            .frame(maxWidth:.infinity)
            .frame(alignment: .center)
    }
        
    
    @ViewBuilder
    var bracketLabel : some View {
        Text(  "Bracket \(selectedBracket)")
            .font(.title3)
            .bold()
            .foregroundColor(selectedBracket > 0 ?  bracket.color : Color.white)
            .customStroke(color: Color.black , width: isSelected ? 1.0 : 0.25)
            .opacity(selectedBracket < 1 ? 0 : 1)
    }
    
    
    @MainActor
    var optimizedDragGesture: some Gesture {
        DragGesture(minimumDistance: GameUIConstants.podSize / 3)
            .updating($dragOffset) { value, state, transaction in
                /// This updates the @GestureState automatically
                state = value.translation
                
                /// Disable animations for smooth dragging
                transaction.animation = nil
                
                /// Update collision detection logic here if needed
                draggedOffsets = state
                
                let newPoint = CGPoint(
                    x: value.translation.width,
                    y: value.translation.height)
                setNewDragPoint(newPoint)
                
            }
        
            .onEnded { value in
                HapticFeedback.selection()
            }
    }
    
    
    public func setNewDragPoint(_ point: CGPoint) {
        dragPoints.append(point)
        calculateBracketFromAngle()
        dragPoints = [point]
    }
    
    
    @MainActor func calculateBracketFromAngle() {
        guard dragPoints.count >= 2 else { return }
        
        let lastIndex = dragPoints.count - 1
        //let prevPoint = dragPoints[lastIndex - 1]
        let currentPoint = dragPoints[lastIndex]
        
        //let angle1 = atan2(prevPoint.y - origin.y, prevPoint.x - origin.x)
        let angle2 = atan2(currentPoint.y - origin.y, currentPoint.x - origin.x)
        
        angleOfPod = angle2
        let delta =  angle2
        let highBound = angle2 + twoPi
        let lowBound = angle2 - twoPi
        //if angle2 < 0 { delta = -1.0 * angle2 }
        //if angle2 > 0 { delta = twoPi - angle2 }
        
        for bracket in (0..<6) {
            if  angleBins[bracket] < delta && delta  < angleBins[bracket+1] {
                selectedBracket = bracket + 1
                if bracket ==  5 { selectedBracket = 5 }
                return
            }
            if  angleBins[bracket] < highBound && highBound  < angleBins[bracket+1] {
                selectedBracket = bracket + 1
                if bracket ==  5 { selectedBracket = 5 }
                return
            }
            if  angleBins[bracket] < lowBound && lowBound  < angleBins[bracket+1] {
                selectedBracket = bracket + 1
                if bracket ==  5 { selectedBracket = 5 }
                return
            }
        }
        
    }
    
    
    @ViewBuilder
    private var frameReader: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear {
                    if origin == .zero {
                        origin = proxy.frame(in: .local).origin
                    }
                }
        }
    }
}


struct BracketButton: View {
    let bracket: Bracket
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .center, spacing: 2) {
                Text("\(bracket.rawValue)")
                    .font(.headline)
                    .bold()
                    .foregroundColor(isSelected ? Color.white : bracket.color)
                    .customStroke(color: isSelected ? Color.black : Color.white, width: isSelected ? 1.0 : 0.25)
                    .padding(4)
            }
            .frame(maxWidth: 40)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? bracket.color: Color(.systemGray4))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.clear)
                    .stroke(Color.black, lineWidth: 3)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}





struct BracketNumberAnimationView_PreviewWrapper<Value, Content: View>: View {
    @State var value: Value
    var content: (Binding<Value>) -> Content
    
    init(_ value: Value, content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: value)
        self.content = content
    }
    var body: some View {
        content($value)
    }
}


#Preview {
    BracketNumberAnimationView_PreviewWrapper(0) { binding in
        BracketSelector(playerIndex: 3, selectedBracket: binding)
            .padding()
    }
}


#Preview {
    BracketNumberAnimationView_PreviewWrapper(0) { binding in
        BracketSelector(playerIndex: 3,
                        selectedBracket: binding,
                        commanderName: "Test",
                        commanderColor: Color.red
        )
        .padding()
    }
}
