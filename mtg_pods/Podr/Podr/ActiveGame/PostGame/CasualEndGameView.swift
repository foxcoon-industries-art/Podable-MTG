import SwiftUI
import Podwork
import Analypod


struct CasualEndGameView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var sentPodsHistory: SentPodsHistory
    
    @Bindable var gameState: GameState
    @State private var navigateToMain = false
    @State private var navigateToStats = false
    @State private var showGameSummary = false
    
    var validPodCheck : Bool {
        let pod = gameState.gameOver
        guard pod != nil else { return false }
        let turnHistory = gameState.podHistory
        guard turnHistory.count > 0 else {return false}
        let validation = PodPassValidator.validatePodForPass(pod: pod!, turns: turnHistory)
        return validation.isValid
    }
    
    @State public var podCasts: [PodCastHistory] = []
    
    @ViewBuilder
    private var podFlowShow: some View {

        OptimizedGameFlowCard(
            game: gameState.gameOver!,
            turnHistory: gameState.podHistory,
            on_Appear: { },
            podCastHistory: podCasts.select(gameState.gameOver!.gameID)
        )
        .onAppear{ Task { self.podCasts = try await PodCastHistory.loadAll(from: modelContext)}
        }
        
    }
    
    
    var podPassedText : String {
        if validPodCheck { return "💎 Perfect!"}
        return "🔓 Unlocked!"
    }
    var podPassedExplText : String {
        if validPodCheck { return  "Share your Pod!"}
        return "Brackets Vibe Check!"
    }
    
    @State private var containerSize : CGSize = UIScreen.main.bounds.size

    
    var body: some View {
        if navigateToMain {
            NavScreen()
        }
        /*
        else if navigateToStats {
            ZStack{
                podFlowShow
                    //.rotationEffect(Angle(degrees:90))
                    //.frame(width: containerSize.height, height: containerSize.width)
                VStack(alignment:.leading){
                    HStack{
                        Button("Back"){
                            navigateToMain = true
                        }
                        Spacer()
                    }
                    .rotationEffect(Angle(degrees:90))
                    Spacer()
                }
            }
        }
        */
        else {
            ScrollView(.vertical, showsIndicators: false) {
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            PlayerColors.color(for: gameState.winnerID).opacity(0.1),
                            PlayerColors.color(for: gameState.winnerID).opacity(0.4),
                            PlayerColors.color(for: gameState.winnerID).opacity(0.1),
                            Color.black.opacity(0.1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                    
                    VStack(spacing: 30) {
                        Spacer()
                        
                        VStack(spacing: 20) {
                            
                            
                            
                            Text("Pod Complete!")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .customStroke(color: Color.black, width: 1)
                            
                            
                            HStack(alignment: .bottom){
                                Image(systemName: "laurel.leading")
                                    .font(.system(size:50))
                                    .foregroundStyle(Color.yellow)

                                ZStack{
                                    Circle()
                                        .foregroundStyle(PlayerColors.color(for: gameState.winnerID).gradient)
                                        .frame(width: 60, height: 60)
                                    //.overlay( )
                                    
                                    Text("👑")
                                        .font(.title)
                                        .customStroke(color: Color.black, width: 1)
                                        .offset(y:-35)
                                }
                                Image(systemName: "laurel.trailing")
                                    .font(.system(size:50))

                                    .foregroundStyle(Color.yellow)

                            }
                         
                            HStack(spacing: 15) {
                                
                                VStack(alignment: .center, spacing: 5) {
                                    Text("\(gameState.players[gameState.winnerID].commanderName)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(PlayerColors.color(for: gameState.winnerID))
                                        .customStroke(color: Color.black, width: 1)
                                    
                                    
                                    Text("\(gameState.assignWinMethod())")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                .scaleEffect(showGameSummary ? 1.1 : 0.90)
                                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: showGameSummary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 15)
                            
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color(.secondarySystemFill))
                                    .shadow(radius: 10)
                            )
                            
                        }
                        
                        
                        
                        
                        
                        
                        
                        //Spacer()
                        
                        
                        
                        VStack(spacing: 15) {
                            /*
                             Button(action: {
                             withAnimation(.spring()) {
                             showGameSummary.toggle()
                             }
                             }) {
                             HStack {
                             Image(systemName: showGameSummary ? "chevron.up" : "chevron.down")
                             Text(showGameSummary ? "Hide Summary" : "Show Game Summary")
                             }
                             .font(.body)
                             .foregroundColor(.blue)
                             .padding(.horizontal, 30)
                             .padding(.vertical, 12)
                             .background(
                             Capsule()
                             .stroke(Color.blue, lineWidth: 2)
                             )
                             }
                             */
                            
                            
                            
                            
                            if showGameSummary { podSummary }
                            
                            Spacer()
                            
                            
                            statsButton
                            if navigateToStats {
                                podFlowShow
                            }
                            homeButton
                            
                        }
                        
                        
                        // Spacer()
                    }
                    .padding()
                }
                .rotationEffect(Angle(degrees: PlayerLayoutConfig.config(for: gameState.winnerID).rotationAngle))
                .onAppear {
                    /// Auto-show summary after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation(.spring()) {
                            showGameSummary = true
                        }
                    }
                    sentPodsHistory.setup(modelContext)
                    do{
                        try sentPodsHistory.loadSentPods()
                    }
                    catch{
                        print("error with loading SentPods: \(error)")
                    }
                    
                }
            }
        }
    }
    
    
    
    @ViewBuilder
    private var podSummary : some View {
        VStack{
            Text("Pod Summary")
            VStack(spacing: 15) {
      
                VStack(spacing: 10) {
    
                    GameSummaryRow(
                        label: "Duration",
                        value: formatDuration(gameState.finalTime!.timeIntervalSince(gameState.gameDate))
                    )
                    
                    GameSummaryRow(
                        label: "Total Turns Played",
                        value: "\(gameState.currentActivePlayerTurnNumber)"
                    )
                    
                    
                    
                    if gameState.firstOutID != gameState.winnerID && gameState.firstOutID != -1 {
                        let firstOutName = gameState.players[gameState.firstOutID].commanderName
                        
                        GameSummaryRow(
                            label: "First Eliminated",
                            value: firstOutName
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.secondarySystemFill), lineWidth: 3)
                )
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            
            
            
            
            
            
            
            
            
            VStack{
                HStack{
                    ZStack {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.purple.gradient)
                        
                        if !validPodCheck {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 30))
                                .foregroundStyle(Color.white.gradient.opacity(0.9))
                                .customStroke(color: Color.black, width: 1)
                            
                        }
                    }
                    Text(podPassedText)
                        .font(.title2)
                        .bold()
                        .customStroke(color: Color.black, width: 1)
                    
                }
                Text(podPassedExplText)
                    .font(.headline)
                    .foregroundStyle(Color(.secondaryLabel))
            }
        }
        .padding()
        .background(
            Color(.tertiarySystemFill)
        )
        .cornerRadius(12)
    }
    
    

    
    @ViewBuilder
    private var homeButton : some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.5)) {
                navigateToMain = true
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: "house.fill")
                Text("Main Menu")
            }
            .font(.headline)
            .foregroundStyle(Color.white.gradient)
            .customStroke(color: Color.black, width: 1)
            .padding(.horizontal, 40)
            .padding(.vertical, 15)
            .background(
                Capsule()
                    .fill(Color.gray.gradient)
                    .shadow(radius: 5)
            )
        }
    }
    
    @ViewBuilder
    private var statsButton : some View {
        
        Button(action: {
            withAnimation(.easeInOut(duration: 0.5)) {
                navigateToStats.toggle()
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: "chart.xyaxis.line")
                Text(navigateToStats ? "Hide Pod History" : "View Pod History")
                    .bold()
            }
            .font(.headline)
            .foregroundStyle(Color.white.gradient)
            .customStroke(color: Color.black, width: 1)
            .padding(.horizontal, 40)
            .padding(.vertical, 15)
            .background(
                Capsule()
                    .fill(Color.brown.gradient)
                    .shadow(radius: 5)
            )
        }
        
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

struct GameSummaryRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

///#Preview { CasualEndGameView(gameState: GameState())}


struct CasualGameEndView_Previews: PreviewProvider {
    static var previews: some View {
        let previewUser = User_Info(uniqueID: "preview-user", paidApp: true)
        let previewAppInfo = App_Info(userInfo: previewUser)
        var sentPods = SentPodsHistory()
        let _ = UserDefaults.standard.set(true, forKey: "showTutorial")
        let _ = UserDefaults.standard.set(0, forKey: "firstPlayer")
        let _ = UserDefaults.standard.set([3,3,3,3], forKey: "selfRatedBrackets")
        let _ = UserDefaults.standard.set([true, true,true, true], forKey: "podPlayers")
        var previewGameState = GameState()
        let _ = previewGameState.players.map( {$0.deckBracket = [3,3,3,3]} )
        let _ = previewGameState.nextTurn()
        let _ = previewGameState.playerAltWins(who: 0)
       
        
        CasualEndGameView(gameState: previewGameState)
            .environmentObject(previewAppInfo)
            .environmentObject(sentPods)
            .environment(CommanderStore.shared)
            .previewDevice("iPhone 12 mini")
    }
    
}
