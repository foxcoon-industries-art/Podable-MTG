import SwiftUI
import Podwork


// MARK: - Main Active Game View
@MainActor
struct ActiveGameView: View {
    @ObservationIgnored @Environment(\.modelContext) public var modelContext
    @ObservationIgnored @EnvironmentObject var app_Info: App_Info
    
    @State public var game: GameState = GameState()
    @State var dragPod: PodDragState = PodDragState()
    @State var inputs: QuadrantInputStates = QuadrantInputStates()
    
    @State private var exitGameView = false
    
    @State var containerSize: CGSize =  UIScreen.main.bounds.size
    
    /// Directly between center lines of damage buttons
    var spacingWidth : Double { 0.5*containerSize.width - GameUIConstants.podSize }
    var spacingHeight : Double { 0.5*containerSize.height - GameUIConstants.podSize  }
    
    // MARK: - Main Game View
    @ViewBuilder
    var body: some View {
        
        if self.game.finished { CasualEndGameView(gameState: self.game) }
        else if self.exitGameView { NavScreen() }
        else {
            
            ZStack{
                QuadrantBackground(activePlayerID: self.game.activePlayer(), bombPodActive: dragPod.bombModeActive, whoCalledBombPod: dragPod.playerDraggedPodOntoCenterPod)
                QuadrantCommanderDamageLayer(game: self.game, dragPod: self.dragPod)
                QuadrantDamageLayer(game: self.game, dragPod: self.dragPod)
                    .onPreferenceChange(DamageLabelPreferenceKey.self) { value in
                        self.dragPod.damageLabelFrames = value}
                
                    .zIndex( inputs.isPresented.contains(where: {$0 == true}) ?  0.9 : 1.11)
                QuadrantHiddenLayer(game: self.game, dragPod: self.dragPod)
                //GameOverBlurOverlay(isDone: self.game.finished)
                
                QuadrantInputLayer(game: self.game, dragPod: self.dragPod, inputs: inputs)
                    .zIndex(1)
                    .onPreferenceChange(CommanderBarFramePreferenceKey.self) { value in
                        self.dragPod.commanderBarFrames = value}
                    .onChange(of: self.game.players.map { $0.deckBracket }, { withAnimation {self.game.attemptEndGame() }})
                DoublePhiPodView(game: self.game, dragState: dragPod)
                
                QuadrantDragPodsView(game: self.game, dragPod: dragPod)
                
                /// Drag Pods for each Player
                VStack (alignment:.center, spacing: spacingHeight) {
                    HStack (alignment:.center, spacing: spacingWidth) {
                        PodView(quadrant: Quadrant.topLeft, game: self.game, dragState: self.dragPod)
                        PodView(quadrant: Quadrant.topRight, game: self.game, dragState: self.dragPod)
                    }
                    HStack (spacing: spacingWidth) {
                        PodView(quadrant: Quadrant.bottomLeft, game: self.game, dragState: self.dragPod)
                        PodView(quadrant: Quadrant.bottomRight, game: self.game, dragState: self.dragPod)
                    }
                }
                .zIndex( inputs.isPresented.contains(where: {$0 == true}) ?  0.9 : 1.1)
            
                
                if game.inTheEndGame && game.showEndGameRatings, game.winnerID != -1 {
                    ZStack{
                       
                        enterEndGameVibeExpl
//                        onChange(of: self.game.skipEndRatings,
//                                 {})
//                            //.onTapGesture{}
//                            .onChange(of: self.game.skipEndRatings,
//                                      {game.showEndGameRatings = false })
                    }
                    .zIndex(2)
                    .onChange(of: self.game.showEndGameRatings, {
                        print("Inside the endGame", game.inTheEndGame && game.showEndGameRatings)}  )

                }
                              //                                      {game.showEndGameRatings = false })
                
            
                CenterMenuButton(
                    bombModeActive: $dragPod.bombModeActive,
                    turnNumber: $game.currentActivePlayerTurnNumber,
                    isRotated:  $dragPod.centerRotation,
                    tutorialMode: $game.tutorialMode,
                    onNextTurn: { withAnimation(.bouncy(duration: 1.0)){self.passTurn()} },
                    onReturn: { idx, eliminationMethod in
                        self.dragPod.bombModeActive = false
                        self.game.onReturnFromStarPod(playerID: idx, method: eliminationMethod)
                        if self.game.finished{ return }
                        if self.game.activePlayer() == idx { passTurn() }
                    },
                    onApplyDamage: {self.bombPodActivated()},
                    onResetTurn: {withAnimation(.easeInOut(duration: 1.0)){self.game.resetTurn()}},
                    onExtraTurn: { idx in
                        withAnimation(.bouncy(duration: 1.0)) {
                            self.passTurn(extraTurn: idx)
                        }
                    },
                    onReturnToMain: {
                        Task{ await self.game.podCasts.deleteHistory() }
                        exitGameView = true
                    }
                )
                .onChange(of: game.tutorialMode, { prevMode, newMode in
                    if prevMode, !newMode { game.resetFromTutorialMode() }} )
                
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .preference(key: CenterPodFramePreferenceKey.self,
                                        value:{
                                var arr = Array<CGRect?>(repeating: nil, count: game.playerCount)
                                arr[dragPod.playerDraggedPodOntoCenterPod] = proxy.frame(in: .global)
                                return arr
                            }()
                            )
                    }
                        .clipShape( Circle() )
                        .frame(maxWidth: GameUIConstants.bombPodSize, maxHeight: GameUIConstants.bombPodSize)
                )
                .zIndex( inputs.isPresented.contains(where: {$0 == true}) ?  0.5 : 1.15)
                .opacity( game.inTheEndGame ? 0 : 1)
                
                //if game.tutorialMode {
                if false {
                    ZStack{
                        TutorialControls(
                            tutorialMode: $game.tutorialMode,
                            onReset: { game.resetFromTutorialMode() }
                        )
                        
                        VStack(spacing:0){
                            MirroredTutorialView()
                            TutorialOverlayView()
                            
                        }
                    }
                    .zIndex(.infinity)
                    
                }
            }
            .onPreferenceChange(CenterPodFramePreferenceKey.self) { value in
                dragPod.centerPodFrames = value}
            
            .background(GeometryReader { geometry in
                Color.black
                    .onAppear {
                        containerSize = geometry.size
                        dragPod.containerSize = geometry.size
                    }
                    .onChange(of: geometry.size) { _, newSize in
                        containerSize = newSize
                        dragPod.containerSize = newSize
                    }})
            
            .onAppear {
                if game.currentTurn.id == 0, game.podCasts.podID == "" {
                    self.app_Info.setup(modelContext)
                    if let initCasts = self.app_Info.createPodCastHistory() {
                        self.game.podCasts = initCasts
                        self.game.podID = self.game.podCasts.id()
                        print("Active Game View - podID setup as: \(self.game.podID)")
                    }
                }
            }
            
        }
    }
    
    
    
    @State var showUnlocked = false
    @State var hideLockLabel = false
    @ViewBuilder
    var enterEndGameVibeExpl : some View {
        ZStack{
            
            
            getColor(for: game.winnerID)
                .opacity(0.12)
                .background(.ultraThinMaterial)
                .opacity(0.93)
            
            InstructionOverlay(messages: [ "POD COMPLETE!" ],
                               timing: InstructionTiming(
                                fadeDuration: 0.45,
                                visibleDuration: 20.5
                               ))
            
            .scaleEffect(x:1.5, y:1.5)
            .rotationEffect(PlayerLayoutConfig.config(for: game.winnerID).isRotated ? .degrees(180) : .zero)
            
            
            VStack{
                if !hideLockLabel {
                    HStack{
                        Image(systemName: showUnlocked ? "lock.open.fill" : "lock.fill")
                        Image(systemName: showUnlocked ?  "": "key.horizontal.fill")
                    }
                        .font(.title)
                        .foregroundStyle(Color.yellow.gradient)
                        .customStroke(color: Color.black, width: 1)
                }
                
                InstructionOverlay(messages: [ " Vibe Check\n~ Unlocked ~", "Choose\nBrackets for \nhow the Pod \n~ actually ~\nplayed!", "TAP HERE \nto Rate \nthe Pod\n" ],
                                   timing: InstructionTiming(
                                    fadeDuration: 0.45,
                                    visibleDuration: 5.5
                                   ))
                .padding(PodableTheme.spacingXS)
                .background(.ultraThickMaterial)
                .cornerRadius(PodableTheme.radiusM)
                
            }
            .rotationEffect(PlayerLayoutConfig.config(for: game.winnerID).isRotated ? .degrees(180) : .zero)
            .position( Quadrant.getQuadrantCenter(for: game.winnerID, in: containerSize))
            .onTapGesture {
                withAnimation{
                    print("[Tapped] - Overlay")
                    print("self.game.showEndGameRatings", self.game.showEndGameRatings)
                    //game.inTheEndGame = false
                    self.game.showEndGameRatings = false
                }
            }
            
            Button(action:{
               print("[Button]")
                withAnimation{
                    self.game.skipEndRatings = true
                    self.game.attemptEndGame() }
                    //self.game.finished = true
                print("... skip End Ratings?", self.game.skipEndRatings)
                print("... finished?", self.game.finished)
                
            }){HStack{
                Text("Skip and End")
                Image(systemName: "dog")}}
                .buttonStyle(PressableButtonStyle())
                .offset(y: 30)
            
            
            
        }
        .background(GeometryReader { geometry in
            Color.clear
                .onAppear { containerSize = geometry.size }
        })
        .onAppear{
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.0) {
                withAnimation(.spring()) {
                    showUnlocked = false
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.spring()) {
                    showUnlocked = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                withAnimation(.spring()) {
                    hideLockLabel = true
                }
            }
        }
        ConfettiView(explosionCenter: Quadrant.getQuadrantCenter(for: game.winnerID))
        
        ConfettiView(explosionCenter: Quadrant.getQuadrantCenter(for: game.winnerID))
        
    }
    
    
    @ViewBuilder
    var _vibeCheckExpl : some View {
        ZStack{
            InstructionOverlay(messages: [ "Vibe Check Pod", "to Finish Game!" ],
                               timing: InstructionTiming(
                                fadeDuration: 0.45,
                                visibleDuration: 2.5
                               ))
        }
    }
    
    
    @MainActor
    public func passTurn(extraTurn: Int? = nil) {
        if let extraTurnPlayerID = extraTurn {
            self.game.nextTurn(extra: extraTurnPlayerID)
        } else {
            self.game.nextTurn() }
        
        dragPod.resetUIElements()
        dragPod.centerRotation = PlayerLayoutConfig.config(for: game.activePlayer()).isRotated
    }


    private func bombPodActivated() {
        Task {
            /// Animate the trigger from 0→1
            withAnimation(.spring(duration:  0.80)) {
                dragPod.isBombShakingQuadrants = true
                HapticFeedback.selection()
            }
            self.game.applyBombPodDamage(from: dragPod.playerDraggedPodOntoCenterPod)
            /// Reset after finishing
            try? await Task.sleep(nanoseconds: UInt64( 0.80 * 1_000_000_000))
            await MainActor.run {
                dragPod.isBombShakingQuadrants = false
            }
        }
    }
}

struct TutorialControls: View {
    @Binding var tutorialMode: Bool
    let onReset: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
//            
//            HStack(spacing: 8){
//                Text("Tutorial")
//                    .font(.headline)
//                    .foregroundColor(.yellow)
//                Text("Mode")
//                    .font(.headline)
//                    .foregroundColor(.yellow)
//            }
//
//            Text("Practice the game mechanics before playing for real!")
//                .font(.caption)
//                .multilineTextAlignment(.center)
//                .foregroundColor(.white.opacity(0.8))
            
            VStack(spacing: 80) {
                VStack(spacing: 3){
                    tutorialLabel
                    Button(action: onReset) {
                        Label("Reset", systemImage: "arrow.clockwise")
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.pink.gradient)
                            .foregroundColor(Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1))
                            .cornerRadius(8)
                    }
                }
                .rotationEffect(.degrees(180))
                
                Spacer()
                VStack(spacing: 3){
                    tutorialLabel
                    Button(action: { tutorialMode = false }) {
                        Label("Done",  systemImage: "checkmark")
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.teal.gradient)
                            .foregroundColor(Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1))
                            .cornerRadius(8)
                    }
                    
                }
            }
        }
        .padding()
//        .background(
//            RoundedRectangle(cornerRadius: 12)
//                .fill(Color.black.opacity(0.85))
//        )
        .padding(.bottom, 40)
        .padding(.top, 40)
    }
    
    var tutorialLabel: some View {
        HStack(spacing: 8){
            Text("Tutorial")
                .font(.caption)
                .foregroundColor(.yellow)
                .customStroke(color: Color.black, width: 0.4)
            Text("Mode")
                .font(.caption)
                .foregroundColor(.yellow)
                .customStroke(color: Color.black, width: 0.4)
        }
        .minimumScaleFactor(0.5)
    }
}


// MARK: - Preference Keys

struct CommanderBarFramePreferenceKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: [CGRect?] = []
    
    static func reduce(value: inout [CGRect?], nextValue: () -> [CGRect?]) {
        if nextValue().count > value.count {
            value.append(contentsOf: Array(repeating: nil, count: nextValue().count - value.count))
        }
        
        for (i, frame) in nextValue().enumerated() {
            if let frame = frame {
                value[i] = frame
            }
        }
    }
}


struct CenterPodFramePreferenceKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: [CGRect?] = []
    
    static func reduce(value: inout [CGRect?], nextValue: () -> [CGRect?]) {
        if nextValue().count > value.count {
            value.append(contentsOf: Array(repeating: nil, count: nextValue().count - value.count))
        }
        
        for (i, frame) in nextValue().enumerated() {
            if let frame = frame {
                value[i] = frame
            }
        }
    }
}

struct DamageLabelPreferenceKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: [CGRect?] = []
    
    static func reduce(value: inout [CGRect?], nextValue: () -> [CGRect?]) {
        if nextValue().count > value.count {
            value.append(contentsOf: Array(repeating: nil, count: nextValue().count - value.count))
        }
        
        for (i, frame) in nextValue().enumerated() {
            if let frame = frame {
                value[i] = frame
            }
        }
    }
}



// MARK: - Preview







struct ActiveGameView_Previews: PreviewProvider {
    static var previews: some View {
        let previewUser = User_Info(uniqueID: "preview-user", paidApp: true)
        let previewAppInfo = App_Info(userInfo: previewUser)
        let _ = UserDefaults.standard.set(true, forKey: "showTutorial")
        let _ = UserDefaults.standard.set([true,true,true,true], forKey: "podPlayers")
        let _ = UserDefaults.standard.set([3,3,3,3], forKey: "selfRatedBrackets")
        
        ActiveGameView()
            .environmentObject(previewAppInfo)
            .environment(CommanderStore.shared)
            .previewDevice("iPhone 12 mini")
    }
}

