import SwiftUI
import Podwork



@MainActor
public struct QuadrantBackground: View {
    public var activePlayerID: Int
    public var bombPodActive: Bool
    public var whoCalledBombPod: Int
    
    public var body: some View {
        backgroundQuadrants
    }
    
    @ViewBuilder
    private var backgroundQuadrants: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(colorForQuadrant(Quadrant.topLeft))
                    .border(colorForFirstBorder(Quadrant.topLeft), width: 10)
                    .border(colorForSecondBorder(Quadrant.topLeft), width: 5)
                
                Rectangle()
                    .fill(colorForQuadrant(Quadrant.topRight))
                    .border(colorForFirstBorder(Quadrant.topRight), width: 10)
                    .border(colorForSecondBorder(Quadrant.topRight), width: 5)
            }
            HStack(spacing: 0) {
                Rectangle()
                    .fill(colorForQuadrant(Quadrant.bottomLeft))
                    .border(colorForFirstBorder(Quadrant.bottomLeft), width: 10)
                    .border(colorForSecondBorder(Quadrant.bottomLeft), width: 5)
                
                Rectangle()
                    .fill(colorForQuadrant(Quadrant.bottomRight))
                    .border(colorForFirstBorder(Quadrant.bottomRight), width: 10)
                    .border(colorForSecondBorder(Quadrant.bottomRight), width: 5)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func colorForQuadrant(_ quadrant: Quadrant) -> AnyShapeStyle {
        activePlayerID == quadrant.rawValue ? AnyShapeStyle(quadrant.color.gradient.opacity(0.53)) : AnyShapeStyle(quadrant.color.tertiary)
    }
    private func colorForFirstBorder(_ quadrant: Quadrant) -> Color {
        activePlayerID == quadrant.rawValue ? Color.black : Color.clear
    }
    private func colorForSecondBorder(_ quadrant: Quadrant) -> Color {
        if bombPodActive { if whoCalledBombPod == quadrant.rawValue {return Color.red }}
        return activePlayerID == quadrant.rawValue ? Color.yellow : Color.clear
    }
}


@MainActor
struct GameOverBlurOverlay: View {
    let isDone: Bool

    var body: some View {
        Rectangle()
            .foregroundStyle(.thinMaterial)
            .background(Color.black.gradient.opacity(0.2))
            .frame(maxWidth:.infinity, maxHeight:.infinity)
            .opacity(isDone ? 0.9 : 0.0)
    }
    
    
}



// MARK: -



@MainActor
struct SingleQuadrantBackground: View {
    var activePlayerID: Int
    var quad: Quadrant
    
    var body: some View {
        Rectangle()
            .fill(colorForQuadrant(quad))
            .border(colorForFirstBorder(quad), width: 10)
            .border(colorForSecondBorder(quad), width: 5)
            //.frame(maxWidth:.infinity, maxHeight:.infinity)
    }
    
    private func colorForQuadrant(_ quadrant: Quadrant) -> AnyShapeStyle {
        activePlayerID == quadrant.rawValue ? AnyShapeStyle(quadrant.color.gradient) : AnyShapeStyle(quadrant.color.tertiary)
    }
    private func colorForFirstBorder(_ quadrant: Quadrant) -> Color {
        activePlayerID == quadrant.rawValue ? Color.black : Color.clear
    }
    private func colorForSecondBorder(_ quadrant: Quadrant) -> Color {
        activePlayerID == quadrant.rawValue ? Color.yellow : Color.clear
    }
}





@MainActor
public struct QuadrantDragPodsView_: View {
    
    @Bindable var game: GameState
    @Bindable var dragPod: PodDragState
    
    var spacingWidth: Double { 0.5*dragPod.containerSize.width - (GameUIConstants.podSize) }
    var spacingHeight: Double { 0.25*dragPod.containerSize.height - (0.5 * GameUIConstants.podSize) }// +  0.125 * GameUIConstants.podSize}
    //var spacingHeight: Double { 0.25*dragPod.containerSize.height - (0.5 * GameUIConstants.podSize) +  0.125 * GameUIConstants.podSize}
    
    public var body: some View { playerDragPods }
    
    @ViewBuilder
    private var playerDragPods: some View {
        VStack (spacing: spacingHeight) {
            HStack (spacing: spacingWidth) {
                PodView(quadrant: Quadrant.topLeft, game: game, dragState: dragPod)
                PodView(quadrant: Quadrant.topRight, game: game, dragState: dragPod)
            }
            HStack (spacing: spacingWidth) {
                PodView(quadrant: Quadrant.bottomLeft, game: game, dragState: dragPod)
                PodView(quadrant: Quadrant.bottomRight, game: game, dragState: dragPod)
            }
        }
        .compositingGroup()
    }
    
    @ViewBuilder
    private func frameReader(_ quadrant : Quadrant) ->  some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear {
                    if dragPod.podCenters[quadrant.rawValue] == .zero {
                        let frame = proxy.frame(in: .global)
                        dragPod.podCenters[quadrant.rawValue] = CGPoint(x: frame.midX, y: frame.midY)
                    }
                }
        }
    }
}




// MARK: -


@MainActor
public struct QuadrantDamageLayer: View {
    
    let game: GameState
    var dragPod:  PodDragState
    @State public var shakeAttempts = 0
    
    public var body: some View {
        VStack(spacing: 0) {
            topQuads
            bottomQuads
        }
    }
    
    private var topQuads: some View {
        HStack(spacing: 0) {
            topLQuad
            topRQuad
        }
    }
    
    private var bottomQuads: some View {
        HStack(spacing: 0) {
            bottomLQuad
            bottomRRQuad
        }
    }
    
    private var topLQuad: some View { SingleQuadrantDamageView( quadrant: Quadrant.topLeft, game: game, dragPod: dragPod )}
    private var topRQuad: some View { SingleQuadrantDamageView( quadrant: Quadrant.topRight, game: game, dragPod: dragPod )}
    private var bottomLQuad: some View { SingleQuadrantDamageView( quadrant: Quadrant.bottomLeft, game: game, dragPod: dragPod )}
    private var bottomRRQuad: some View { SingleQuadrantDamageView( quadrant: Quadrant.bottomRight, game: game, dragPod: dragPod )}
}


@MainActor
public struct QuadrantCommanderDamageLayer: View {
    
    let game: GameState
    var dragPod:  PodDragState
    @State public var shakeAttempts = 0
    
    public var body: some View {
        VStack(spacing: 0) {
            topQuads
            bottomQuads
        }
    }
    
    private var topQuads: some View {
        HStack(spacing: 0) {
            topLQuad
            topRQuad
        }
    }
    
    private var bottomQuads: some View {
        HStack(spacing: 0) {
            bottomLQuad
            bottomRRQuad
        }
    }
    
    private var topLQuad: some View { SingleQuadrantCommanderDamageView( quadrant: Quadrant.topLeft, game: game, dragPod: dragPod )}
    private var topRQuad: some View { SingleQuadrantCommanderDamageView( quadrant: Quadrant.topRight, game: game, dragPod: dragPod )}
    private var bottomLQuad: some View { SingleQuadrantCommanderDamageView( quadrant: Quadrant.bottomLeft, game: game, dragPod: dragPod )}
    private var bottomRRQuad: some View { SingleQuadrantCommanderDamageView( quadrant: Quadrant.bottomRight, game: game, dragPod: dragPod )}
}










@MainActor
public struct SingleQuadrantDamageView: View {
    
    let quadrant: Quadrant
    @Bindable var game: GameState
    @Bindable var dragPod:  PodDragState
    
    @State var scaleRatio: CGFloat = 1.0
    @State var isShaking: Bool = false
    
    public var body: some View {
        quadrantDamageView
            .rotationEffect(Angle(degrees: PlayerLayoutConfig.config(for: current_player).rotationAngle))
            .opacity(game.players[current_player].eliminated || game.players[current_player].winner ? 0.0 : 1.0)
    }
    
    @ViewBuilder
    private var quadrantDamageView: some View {
        DisplayDamageView(game: self.game, current_player: current_player)
            .frame(height: 1.45*GameUIConstants.podSize, alignment: .bottom)
            .frame(maxWidth: 0.5*dragPod.containerSize.width)
            .shadow(color: dragPod.highlightedDamageLabelIndex == current_player ? Color.red : Color.clear, radius: 20)
            .shadow(color: (dragPod.highlightedPodIndex[current_player] != current_player) ? getColor(for: dragPod.highlightedPodIndex[current_player]) : Color.clear, radius: 5)
        
            .offset( y: -0.15*GameUIConstants.podSize )
            .allowsHitTesting(false)
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: DamageLabelPreferenceKey.self,
                                    value:{
                            var arr = Array<CGRect?>(repeating: nil, count: game.playerCount)
                            arr[current_player] = proxy.frame(in: .global)
                            return arr
                        }()
                        )
                }
            )
            .compositingGroup()
            .allowsHitTesting(false)
            .frame(width: 0.5*dragPod.containerSize.width)
            .frame(height: 0.5*dragPod.containerSize.height)
            .opacity(dragPod.showPoisonDots[current_player] ? 0 : 1)
    }
    
    var activePlayer: Int{ game.activePlayer() }
    var current_player: Int { quadrant.rawValue }
    var attacking_player: Int { PlayerColors.playerIndex(for: dragPod.damageFromQuadrantColors[current_player] ) }
    var playerConfig: PlayerLayoutConfig { PlayerLayoutConfig.config(for: current_player) }
    var isLeftSide: Bool { playerConfig.isLeftSide }
    
    func currentPlayerIsActivePlayer(_ quadrant: Quadrant) -> Bool { current_player == activePlayer }
    
    func damageColour(for playerID : Int) -> Color {
        dragPod.commanderDamage[playerID] ? dragPod.damageFromQuadrantColors[playerID] : Color.gray
    }
    
}





@MainActor
public struct SingleQuadrantCommanderDamageView: View {
    
    let quadrant: Quadrant
    @Bindable var game: GameState
    @Bindable var dragPod:  PodDragState
    
    @State var scaleRatio: CGFloat = 1.0
    @State var isShaking: Bool = false
    
    public var body: some View {
        ZStack{
            poisonCountersView
                ZStack{
                    commanderDamageDisplay
                    damageButtons
                    commanderDamageNumbersOnlyDisplay
                }
        }
        .rotationEffect(Angle(degrees: PlayerLayoutConfig.config(for: current_player).rotationAngle))
        .opacity(game.players[current_player].eliminated || game.players[current_player].winner ? 0.0 : 1.0)
    }
    
    private var buildCommanderDamageData: [CommanderDamagePlotData] {
        CommanderDamagePlotData.plotData(
            for: current_player,
            currentDamages: game.currentCommanderDamages(for: current_player),
            partners: game.whichPlayersHavePartner(),
            activeCommanders: game.indexOfPlayersActiveCommanders())
    }

    @ViewBuilder
    private var commanderDamageDisplay: some View {
        ConcentricCommanderDamageView(
            damageData: buildCommanderDamageData,
            currentPlayer: current_player,
            attackingPlayer: attacking_player,
            showAnimation: dragPod.commanderDamage[current_player]
        )
        .minimumScaleFactor(0.01)
        .allowsHitTesting(false)
    }
    

    @ViewBuilder
    private var commanderDamageNumbersOnlyDisplay: some View {
        /// See: -- for offset from +/- delta placement of label
        CommanderDamageDeltasOnlyView(
            damageData: buildCommanderDamageData,
            currentPlayer: current_player,
            attackingPlayer: attacking_player,
            showAnimation: dragPod.commanderDamage[current_player]
        )
        .minimumScaleFactor(0.01)
        .frame(maxWidth: 0.9*0.5*dragPod.containerSize.width )
        .frame(maxHeight: 0.9*0.5*dragPod.containerSize.width)
        .padding(2)
        .allowsHitTesting(false)
    }
    
    
    @MainActor
    @ViewBuilder
    private var damageButtons: some View {
        ZStack{
            VStack(alignment: .center, spacing: -0.125*GameUIConstants.podSize*0.0) {
                DamageButtonView(
                    action: {
                        dragPod.showDamageButtonInQuadrant[current_player] = true
                       // HapticFeedback.impact(.medium)
                        /// Use Buttons for Poison Counters (up=remove)
                        if dragPod.showPoisonDots[current_player] {
                            game.addPoison(to: current_player)
                        }
                        else {
                            game.removeDamage(from: attacking_player,
                                              to: current_player,
                                              as: dragPod.commanderDamage[current_player] )
                        }
                    },
                    text: "↑",
                    color: dragPod.showPoisonDots[current_player] ? Color.white : damageColour(for: current_player),
                    width:  2.5 * GameUIConstants.podSize,
                    showButton:  dragPod.showDamageButtonInQuadrant[current_player]
                )
                .multilineTextAlignment(.center)
                .contentShape(Rectangle())
                
                DamageButtonView(
                    action: {
                        dragPod.showDamageButtonInQuadrant[current_player] = true
                        //HapticFeedback.impact(.medium)
                        
                        /// Use Buttons for Poison Counters (down=increase)
                        if dragPod.showPoisonDots[current_player] {
                            game.subtractPoison(from: current_player)
                        }
                        else {
                            game.applyDamage(from: attacking_player,
                                             to: current_player,
                                             as: dragPod.commanderDamage[current_player] )
                        }
                    },
                    text: "↓",
                    color: dragPod.showPoisonDots[current_player] ? Color.white : damageColour(for: current_player),
                    width: 2.5 * GameUIConstants.podSize,
                    showButton:  dragPod.showDamageButtonInQuadrant[current_player]
                )
                .multilineTextAlignment(.center)
                .contentShape(Rectangle())
                
//                Rectangle()
//                    .fill(Color.clear)
//                    .frame( height: ViewUIConstants.cmdrBarHeight)
                    
            }
            .padding(.top, ViewUIConstants.sidePad)
            .opacity( dragPod.showDamageButtonInQuadrant[current_player] ? 1.0 : 0.0815)
            .mask{
                ZStack{
                    RoundedRectangle(cornerRadius:12).opacity(1)
                    Circle()
                        .frame(width: 1.25*GameUIConstants.buttonSize)
                        .blendMode(.destinationOut)
                    //.border(.red)
                }
                //.offset(y: -ViewUIConstants.cmdrBarHeight/2)
                .compositingGroup()
                
            }
            
            Circle()
                .fill(Color.black.opacity(0.5))
                .frame(width: 1.33*GameUIConstants.buttonSize)
                .opacity(0.5)
                .allowsHitTesting(true)
        }
    }
    
    @ViewBuilder
    var poisonCountersView: some View {
        ZStack{
            
            HStack{
                PhiSegments(
                    poisonCounters: Binding(
                        get: { game.showTotalInfect(playerID: current_player) },
                        set: { newValue in
                            let base = game.players[current_player].infect
                            let delta = newValue - base
                            let currentDelta = game.showDeltaPoison(playerIndex: current_player)
                            
                            if delta > currentDelta {
                                game.addPoison(to: current_player)
                            } else if delta < currentDelta {
                                game.subtractPoison(from: current_player)
                            }
                        }
                    ),
                    isVisible: $dragPod.showPoisonDots[current_player]
                )
               
            }
        }
        .frame(maxWidth: 0.5*dragPod.containerSize.width)
        .zIndex(10)
        .compositingGroup()
    }
    
    
    var activePlayer: Int{ game.activePlayer() }
    var current_player: Int { quadrant.rawValue }
    var attacking_player: Int { PlayerColors.playerIndex(for: dragPod.damageFromQuadrantColors[current_player] ) }
    var playerConfig: PlayerLayoutConfig { PlayerLayoutConfig.config(for: current_player) }
    var isLeftSide: Bool { playerConfig.isLeftSide }
    
    func currentPlayerIsActivePlayer(_ quadrant: Quadrant) -> Bool { current_player == activePlayer }
       
    func damageColour(for playerID : Int) -> Color {
        dragPod.commanderDamage[playerID] ? dragPod.damageFromQuadrantColors[playerID] : Color.gray
    }
}


@MainActor
public struct QuadrantHiddenLayer: View {
    
    @Bindable var game: GameState
    @Bindable var dragPod:  PodDragState
    
    @ViewBuilder private var topLeft : some View { SingleQuadrantHiddenView( quadrant: Quadrant.topLeft, game: game, dragPod: dragPod) }
    @ViewBuilder private var topRight : some View { SingleQuadrantHiddenView( quadrant: Quadrant.topRight, game: game, dragPod: dragPod) }
    
    @ViewBuilder private var bottomLeft : some View { SingleQuadrantHiddenView( quadrant: Quadrant.bottomLeft, game: game, dragPod: dragPod) }
    @ViewBuilder private var bottomRight : some View { SingleQuadrantHiddenView( quadrant: Quadrant.bottomRight, game: game, dragPod: dragPod) }
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                topLeft
                topRight
            }
            HStack(spacing: 0) {
                bottomLeft
                bottomRight
            }
        }
    }
}





@MainActor
public struct SingleQuadrantHiddenView: View {
    
    var quadrant: Quadrant
    @Bindable var game: GameState
    @Bindable var dragPod:  PodDragState
    
    @State var scaleRatio: CGFloat = 1.0
    @State var isShaking: Bool = false
    
    public var body: some View {
        ZStack{
            solRingView
                .offset(y: -0.18*dragPod.containerSize.height)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .rotationEffect(Angle(degrees: PlayerLayoutConfig.config(for: current_player).rotationAngle))
        .opacity(game.players[current_player].eliminated || game.players[current_player].winner ? 0.0 : 1.0)
    }
    
    
    var activePlayer: Int{ game.activePlayer() }
    var current_player: Int { quadrant.rawValue }
    var attacking_player: Int { PlayerColors.playerIndex(for: dragPod.damageFromQuadrantColors[current_player] ) }
    var playerConfig: PlayerLayoutConfig { PlayerLayoutConfig.config(for: current_player) }
    var isLeftSide: Bool { playerConfig.isLeftSide }
    func currentPlayerIsActivePlayer(_ quadrant: Quadrant) -> Bool { current_player == activePlayer }
    func damageColour(for playerID : Int) -> Color {
        dragPod.commanderDamage[playerID] ? dragPod.damageFromQuadrantColors[playerID] : Color.gray
    }
    
    @ViewBuilder
    var solRingView: some View {
        
        Text("Sol Ring")
            .font(.largeTitle)
            .customStroke(color: Color.black, width: 1.0)
            .bold()
            .foregroundColor(Color.yellow)
            .transition(.opacity)
            .scaleEffect(dragPod.animateSolRing[current_player] ? scaleRatio : scaleRatio)
            .opacity( dragPod.animateSolRing[current_player] ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses:  dragPod.animateSolRing[current_player]), value: dragPod.animateSolRing[current_player])
        
            .onAppear {
                if !dragPod.animateSolRing[current_player] {
                    dragPod.animateSolRing[current_player] = dragPod.solrings[current_player].showText
                }
            }
            .onDisappear{
                dragPod.animateSolRing[current_player] = dragPod.solrings[current_player].showText
            }
        
            .onChange(of: dragPod.solrings[current_player].showText ) {
                dragPod.animateSolRing[current_player] = dragPod.solrings[current_player].showText
            }
            .opacity(dragPod.solrings[current_player].showText ? 1.0 : 0.0)
    }
}










@MainActor
public struct QuadrantInputLayer: View {
    
    @Bindable var game: GameState
    @Bindable var dragPod:  PodDragState
    @Bindable var inputs: QuadrantInputStates
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                SingleQuadrantInputView( quadrant: Quadrant.topLeft, game: game, dragPod: dragPod, inputs:inputs )
                SingleQuadrantInputView( quadrant: Quadrant.topRight, game: game, dragPod: dragPod, inputs:inputs )
            }
            HStack(spacing: 0) {
                SingleQuadrantInputView( quadrant: Quadrant.bottomLeft, game: game, dragPod: dragPod, inputs:inputs )
                SingleQuadrantInputView( quadrant: Quadrant.bottomRight, game: game, dragPod: dragPod, inputs:inputs )
            }
        }
    }
}











@MainActor
public struct SingleQuadrantInputView: View {
    
    let quadrant: Quadrant
    @Bindable var game: GameState
    @Bindable var dragPod:  PodDragState
    @Bindable var inputs: QuadrantInputStates

    var activePlayer: Int{ game.activePlayer() }
    var current_player: Int { quadrant.rawValue }
    var playerConfig: PlayerLayoutConfig {PlayerLayoutConfig.config(for: current_player)}
    var isLeftSide: Bool { playerConfig.isLeftSide }
    var podPlayers: [Bool] {
        let podplayers = UserDefaults.standard.array( forKey: "podPlayers") as? [Bool]
        if podplayers == nil {return [true, true, true, true]}
        return podplayers!
    }
    var otherPlayers: [Int] {
        // Doesn't count self-ratings or rating non-players.
        game.players.enumerated() .filter { $0.offset != current_player && podPlayers[$0.offset] } .map { $0.offset }
    }
    var hasDiedOrWon: Bool {
        game.players[current_player].eliminated || game.players[current_player].winner
    }
    var emptySeat: Bool { game.players[current_player].eliminationMethod == EliminationMethod.emptySeat }
    
    public var body: some View {
        ZStack{
            //  causalEndGameMessage
            GameOverBlurOverlay(isDone:  hasDiedOrWon)
                .opacity(hasDiedOrWon ? 1.0 : 0.0)
            
            endGameMessage
            
            selectCommanderKeyboard
            VStack{
                playerFeedbackView
                
                commanderNameBarView
            }

        }
        .rotationEffect(Angle(degrees: playerConfig.rotationAngle))
        .opacity(emptySeat ? 0.0 : 1.0)
    }
    
    @ViewBuilder
    var selectCommanderKeyboard: some View {
        SelectCommanderView(
            selectedName: Binding(
                get: { game.players[current_player].commanderName },
                set: { newName in
                    game.players[current_player].setCommanderPartnerName(names: newName)
                }
            ),
            isPresented: $inputs.isPresented[current_player]
        )
        .padding(1)
        .opacity( inputs.isPresented[current_player] ? 1.0 : 0.0)
        .zIndex(.infinity)
    }
    
    
    var checkBracketsEntered : Bool {
        inputs.ratingIndex[current_player] == otherPlayers.count
    }
    
    @ViewBuilder
    var vibeCheckButton : some View {
        if !inputs.showingRating[current_player] {
            Button("Vibe Check") {
                withAnimation {
                    inputs.showingRating[current_player] = true
                    inputs.ratingIndex[current_player] = 0
                }
            }
            .font(.subheadline)
            .modifier(EnhancedMenuButtonStyle(backgroundColor: Color.blue))
            .opacity(checkBracketsEntered ? 0 : 1)
            .opacity(inputs.isPresented[current_player] ? 0.0 : 1.0)

        }
    }
    
    @ViewBuilder
    var vibeChecked : some View {
        if !checkBracketsEntered {
            vibeCheckButton
        } else {
            Text(checkBracketsEntered ? "✔ Vibe Checked" : "Check Vibes")
                .font(.headline)
                .foregroundStyle(Color.gray)
        }
    }
    
    var checkCommanderEntered : Bool {
        game.commanderLog(for: current_player) ==  true
    }
    
    @ViewBuilder
    var cmdrEnteredButton : some View {
        if !inputs.isPresented[current_player] {
            Button("☐ Commander") {
                withAnimation {
                    inputs.isPresented[current_player] = true
                }
            }
            .font(.subheadline)
            .modifier(EnhancedMenuButtonStyle(backgroundColor: Color.blue))
            .opacity(checkCommanderEntered ? 0 : 1)
        }
    }
    
    @ViewBuilder
    var enterCmdrChecked: some View {
        Text(game.commanderLog(for: current_player) ? "✔  Commander" : "⚠  Commander" )
            .font(.headline)
            .foregroundStyle(Color.gray)
        
        //if !checkCommanderEntered {  cmdrEnteredButton } else { }
    }
    
    @ViewBuilder
    var endGameMessage: some View {
        VStack{
            //Text("Thanks for Playing!")
            //    .font(.headline)
            ///    .foregroundStyle(Color.gray)
            
            //enterCmdrChecked
            
            vibeChecked
        }
        .opacity(hasDiedOrWon ? 1.0 : 0.0)
        //.opacity(inputs.showingRating[current_player] ? 0.0 : 1.0)
    }
    
    
    @ViewBuilder
    var playerFeedbackView: some View {
        PlayerFeedbackView(
            currentPlayer: current_player,
            commanderNames: game.getCommanderPartnerNamesForAllPlayers(),
            otherPlayerIndices: otherPlayers,
            showingRating: $inputs.showingRating[current_player],
            ratingIndex: $inputs.ratingIndex[current_player],
            deckRatings: $game.players[current_player].deckBracket,
            isPresented: $inputs.isPresented[current_player],
        )
        .opacity( hasDiedOrWon  ? 1.0 : 0.0)
        .opacity(checkBracketsEntered ? 0 : 1)
    }
    
    func taxColor() -> Color {
        if dragPod.taxUp[current_player] {
            return  Color.yellow
        }
        return Color.pink
    }
    
    @ViewBuilder
    var commanderNameBarView: some View {
        CommanderNameBar(
            labels: game.getCommanderPartnerNames(for: current_player),
            selectedIndex: game.indexOfActiveCommander(for: current_player),
            activeColor: PlayerColors.color(for: current_player),
            leftRight: !isLeftSide,
            cmdrTaxes: game.commanderTaxes(for: current_player),
            tapAction: { _ in
                if !game.commanderLog(for:current_player) {
                    inputs.isPresented[current_player] = true
                } else {
                    if game.playerHasPartner(for: current_player) {
                        game.swapActiveCommander(for: current_player)
                    }
                }
            },
            holdAction: { _ in
                inputs.isPresented[current_player] = true
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(dragPod.highlightedCommanderBarIndex == current_player ? taxColor().gradient : Color.clear.gradient, lineWidth: 8)
        )
        .background(
            GeometryReader { proxy in
                Color.clear
                    .preference(
                        key: CommanderBarFramePreferenceKey.self,
                        value: {
                            var arr = Array<CGRect?>(repeating: nil, count: game.playerCount)
                            arr[current_player] = proxy.frame(in: .global)
                            return arr
                        }()
                    )
            }
        )
        .opacity( !inputs.isPresented[current_player] ? 1.0 : 0.0)
        .zIndex(2)
    }
}













@MainActor
public struct QuadrantDragPodsView: View {
    
    @Bindable var game: GameState
    @Bindable var dragPod: PodDragState
    
    var spacingWidth: Double { 0.5*dragPod.containerSize.width - (GameUIConstants.podSize) }
    var spacingHeight: Double { 0.25*dragPod.containerSize.height - (0.5 * GameUIConstants.podSize) +  0.125 * GameUIConstants.podSize}
    //var spacingHeight: Double { 0.25*dragPod.containerSize.height - (0.5 * GameUIConstants.podSize) +  0.125 * GameUIConstants.podSize}
    
    public var body: some View { podsDragView }
 
    @ViewBuilder
    private var podsDragView: some View {
        ZStack{
            ForEach(dragPod.dragTrails){ trail in
                SimpleTrailView(trail: trail)
            }
            .allowsHitTesting(false)
        }
    }
    
    @ViewBuilder
    private var playerDragPods: some View {
        VStack (spacing: spacingHeight) {
            HStack (spacing: spacingWidth) {
                PodView(quadrant: Quadrant.topLeft, game: game, dragState: dragPod)
                PodView(quadrant: Quadrant.topRight, game: game, dragState: dragPod)
            }
            HStack (spacing: spacingWidth) {
                PodView(quadrant: Quadrant.bottomLeft, game: game, dragState: dragPod)
                PodView(quadrant: Quadrant.bottomRight, game: game, dragState: dragPod)
            }
        }
        .compositingGroup()
    }
    
    @ViewBuilder
    private func frameReader(_ quadrant : Quadrant) ->  some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear {
                    if dragPod.podCenters[quadrant.rawValue] == .zero {
                        let frame = proxy.frame(in: .global)
                        dragPod.podCenters[quadrant.rawValue] = CGPoint(x: frame.midX, y: frame.midY)
                    }
                }
        }
    }
}



#Preview{
    ZStack{
        QuadrantBackground(activePlayerID: -1, bombPodActive: false, whoCalledBombPod: -1)
    GameOverBlurOverlay(isDone: true)
    }
}
