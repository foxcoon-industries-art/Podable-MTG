import SwiftUI
import Podwork


@MainActor
struct BracketGridView: View {
    @Binding var selections: [Int?]
    @Binding var podPlayers: [Bool]
    var onComplete: (([Int], Bool) -> Void)? = nil
    
    @State var podEntered: [Bool] = [false, false, false, false]
    
    let rotAngle = [180.0, 180.0, 0.0, 0.0]
    @State var containerSize : CGSize = UIScreen.main.bounds.size
    
    var  halfWidth : CGFloat { 0.48*containerSize.width }
    var  halfHeight : CGFloat { 0.44*containerSize.height }
    
    func checkPlayerValidity() -> Bool {
        for (pos, playerID) in podPlayers.enumerated() {
            if playerID != false {
                guard selections[pos] != nil else {return false}
                //guard selections[pos] != -1 else {return false}
            }
        }
        
        return true
    }
    
    @State var randomizeFirstPlayer: Bool = false
   
    func saveToDefaults() -> Void {
        let safeBrackets = selections.map{ $0 == nil ? -1 : $0 }
        let _ = print("Saving brackets: \(safeBrackets)")
        let _ = print("Players: \(podPlayers)")
        UserDefaults.standard.set( safeBrackets , forKey: "selfRatedBrackets")
        UserDefaults.standard.set( podPlayers , forKey: "podPlayers")
    }
    
    var body: some View {
        ZStack{
            //bkg
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        quadrantView(index: 1, color: Color.orange)
                            .rotationEffect(Angle(degrees: rotAngle[0]))
                        quadrantView(index: 2, color: Color.blue)
                            .rotationEffect(Angle(degrees: rotAngle[1]))
                    }
                    
                    HStack(spacing: 0) {
                        quadrantView(index: 0, color: Color.green)
                            .rotationEffect(Angle(degrees: rotAngle[2]))
                        quadrantView(index: 3, color: Color.purple)
                            .rotationEffect(Angle(degrees: rotAngle[3]))
                    }
                }
                .frame(alignment: .center)
            }

            
            if checkPlayerValidity() {
                HStack{
                    HStack(spacing:-0.5*GameUIConstants.podSize){
                        Text("Randomize")
                            .rotationEffect(.degrees(-90))
                        Button(action: {
                            randomizeFirstPlayer = true
                            saveToDefaults()
                            onComplete?(selections.compactMap { $0 }, randomizeFirstPlayer)
                        }) {
                            Text("🎲")
                                .font(.title)
                                .bold()
                                .foregroundColor(Color.black)
                                .customStroke(color: Color.black, width: 0.50)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 15)
                                .background(Color.white.gradient)
                                .clipShape(Capsule())
                                .shadow(radius: 4)
                        }
                    }
                    .transition(.move(edge: .leading).combined(with: .opacity))
                    
                    Spacer()
                    
                    instructionsChoice
                    
                    Spacer()
                    HStack(spacing:-0.25*GameUIConstants.podSize){
                        
                        Button(action: {
                            randomizeFirstPlayer = false
                            saveToDefaults()
                            onComplete?(selections.compactMap { $0 }, randomizeFirstPlayer)
                        }) {
                            Text("⭐️")
                                .font(.title)
                                .bold()
                                .foregroundColor(Color.black)
                                .customStroke(color: Color.black, width: 0.50)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 15)
                                .background(Color.white.gradient)
                                .clipShape(Capsule())
                                .shadow(radius: 4)
                        }
                        
                        Text("Choose")
                            .rotationEffect(.degrees(90))
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
                .animation(.easeOut(duration: 3.7), value: selections)
            }
            else {
                
          
                                
                Circle()
                    .fill(Color.white.gradient)
                    .stroke(Color.black, lineWidth: 2)
                    .frame(width: 0.75*GameUIConstants.podSize)
                    //.overlay(PodableDoubleTap())
                    .overlay(Image(systemName: "sparkles")
                        .foregroundStyle(Color.yellow.gradient)
                        .font(.title)
                        .customStroke(color: Color.black, width: 0.5))
                
                instructionsBrackets
                    .padding(.horizontal, ViewUIConstants.sidePad)
                    .background(Capsule())
                    .background(.ultraThinMaterial)
                    .offset(y: 0.025*UIScreen.main.bounds.height)
                    .offset(y: 0.75*GameUIConstants.podSize)

                instructionsBrackets
                    .padding(.horizontal, ViewUIConstants.sidePad)
                    .background(Capsule())
                    .background(.ultraThinMaterial)
                    .rotationEffect(Angle(degrees: 180))
                    .offset(y: -0.025*UIScreen.main.bounds.height)
                    .offset(y: -0.75*GameUIConstants.podSize)
            }
        }
    }
    
    
    var instructionsBrackets: some View {
        InstructionOverlay(messages: [
            "Pick Your Bracket!",
            "Select a Deck for the Pod!" ,
            ],
           timing: InstructionTiming(fadeDuration: 1.45, visibleDuration: 2.5)
        )
    }
    
    var instructionsChoice: some View {
        InstructionOverlay(messages: [
            "First Player!",
        ],
        timing: InstructionTiming(fadeDuration: 1.45, visibleDuration: 2.5)
        )
    }
    
    var bkg: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Spacer()
                singleBkg( color: Color.orange)
                    .rotationEffect(Angle(degrees: rotAngle[0]))
                singleBkg( color: Color.blue)
                    .rotationEffect(Angle(degrees: rotAngle[1]))
                Spacer()
            }
            
            HStack(spacing: 0) {
                Spacer()
                singleBkg( color:  Color.green)
                    .rotationEffect(Angle(degrees: rotAngle[2]))
                
                singleBkg( color: Color.purple)
                    .rotationEffect(Angle(degrees: rotAngle[3]))
                Spacer()
            }
        }
    }
    
    
    private func singleBkg( color: Color) -> some View {
        Rectangle()
            .fill( AnyShapeStyle(color.tertiary))
            .zIndex(-2)
            .frame( maxWidth: 0.772*0.5*containerSize.width, maxHeight: 0.5*containerSize.height)
    }
    

    private func quadrantView(index: Int, color: Color) -> some View {
        /// Bracket (-1)  -> Remove bracket choice. / No player at seat index
        /// Bracket (0)  -> Rule zero bracket
        /// Bracket >= 0 ->  Player is playing
        ZStack {
                BracketSelector(playerIndex: index, selectedBracket: Binding(
                    get: {  selections[index] ?? -1 },
                    set: { selections[index] = $0
                        if $0 == -1 {
                            selections[index] = nil
                            podPlayers[index] = false}
                        if $0 != 0 { podPlayers[index] = true }
                    }
                ), onReturn: {withAnimation {
                    podEntered[index].toggle()
                    selections[index] = nil
                    podPlayers[index] = false
                }
            })
                .padding(.horizontal, 4)
                
        }
        .frame(width: halfWidth, height: halfHeight)
        .onAppear {
            if !podPlayers[index] {
                selections[index] = -1
            }
        }
    }
    
    
    @ViewBuilder
    func removedPlayerPod(_ index: Int) -> some View {
        Circle()
            .stroke(Color.black, lineWidth: 5)
            .fill( Color.gray.gradient)
            .frame(width: 0.75*GameUIConstants.podSize)
            .overlay(
                Text("X")
                    .font(.title)
                    .bold()
                    .foregroundStyle(Color.red.gradient)
                    .customStroke(color: Color.black, width: 1)
                    .opacity(podPlayers[index] ? 0 : 1)
            )
            .onTapGesture {
                withAnimation{
                    podPlayers[index] = true
                    selections[index] = -1
                }
            }
    }
}




struct BracketGridView_Previews: PreviewProvider {
    static var previews: some View {
        GatheringPodInfoView()
    }
}
