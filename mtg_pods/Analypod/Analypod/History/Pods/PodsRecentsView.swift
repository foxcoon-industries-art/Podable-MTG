/*
import SwiftUI
import Podwork


@MainActor
struct PodsRecentsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.refresh) private var refreshAction
    
    @StateObject private var dataManager = GameDataManager.shared
    @State private var selectedGame: FinalPod?
    @State private var selectedGameID: String = ""
    @State private var selectedTurn: (game: String, turn: Int, player: Int)?
    @State private var showingGameDetails: Bool = false
    
    @State private var turnHistoryCache: [String: [Turn]] = [:]
    
    @State public var podCasts: [PodCastHistory] = []
    @State var selectedCommander : String = ""
    @State var flipStates: [String: PodDetails] = [:]
    @State var flip: PodDetails = PodDetails.recents
    @State var flippedPodID: String? = nil
    private let containerScale : CGFloat = 0.95
    private let sidePad : CGFloat = 6
    
    @State var showPodMap : Bool = false
    
    var body: some View {
        ZStack{
            VStack(spacing: sidePad ){
                
                if dataManager.finalStates.isEmpty {
                    EmptyNoDataView(statsScreen: EnhancedStatsScreens.pods)
                } else {
                    
                    ForEach(recentGames, id: \.gameID) { game in
                        
                        let flipState = flipStates[game.gameID, default: PodDetails.recents]
                        VStack (alignment:.center){
                            PodViewSwapper(for: game, with: turnHistoryCache)
                                .onChange(of: flippedPodID) { oldVal, newVal in
                                    if oldVal == nil {
                                        Task {
                                            await refreshAction?() }
                                    }
                                }
                            //                                .onTapGesture {
                            //                                    withAnimation(.spring(duration: 0.15)){
                            //
                            //                                        selectedGame = game
                            //                                        selectedGameID = game.gameID
                            //                                        let imutFlipState = flipStates
                            //                                        imutFlipState.forEach{ if $0.1 == PodDetails.flow { flipStates[$0.0] = PodDetails.recents } }
                            //                                        flipStates[game.gameID] = flipState == PodDetails.recents ? PodDetails.flow : PodDetails.recents
                            //                                    }
                            //                                }
                            
                        }
                        .onAppear{ loadTurnHistory(for: game.gameID) }
                    }
                    .cornerRadius(12)
                }
            }
            .onAppear{ Task { self.podCasts = try await PodCastHistory.loadAll(from: modelContext)} }
            .padding(sidePad)
        }
    }
    
    
    func share(_ myView : any View){
        let image = myView.asImage()
        //print("sharing")
        ShareLink(item: image, preview: SharePreview("Podable-Share-Pod", image: Image(uiImage: image))) {
            Label("Share", systemImage: "square.and.arrow.up")
        }
    }
    
    
    @MainActor
    func PodViewSwapper(for pod: FinalPod, with turnHistory: [String: [Turn]] ) -> AnyView {
        var podFlowCard = AnyView(ZStack{})
        if flippedPodID == pod.gameID {
            podFlowCard = AnyView(OptimizedGameFlowCard(
                game: pod,
                turnHistory: turnHistoryCache[pod.gameID] ?? [],
                on_Appear: {
                    loadTurnHistory(for: pod.gameID) },
                podCastHistory: podCasts.select(pod.gameID)
            )  )
        }
        func recentsCard() -> some View { RecentGameCard(pod: pod,
                                                         flippedPodID: $flippedPodID,
                                                         showingExtended: pod.gameID == flippedPodID,
                                                         onReturn: {
            Task { await dataManager.deleteGame(pod.gameID)
                await self.podCasts.select(pod.gameID).removePod(podID: pod.gameID )
                turnHistoryCache[ pod.gameID ] = nil
                flipStates[ pod.gameID ] = nil
            }
        },
                                                         onShare: podFlowCard .background(Color(.systemGray6))
        )
        .padding(sidePad)
        }
        
        //if flipStates[pod.gameID] == PodDetails.recents {
        if pod.gameID != flippedPodID {
            return AnyView(
                recentsCard()
                    .background(Color(.systemGray6))
            )}
        
        //if flipStates[pod.gameID] ==  PodDetails.flow {
        if pod.gameID == flippedPodID  {
            return AnyView(
                VStack(spacing:0){
                    recentsCard()
                    podFlowCard
                }
                    .background(Color(.systemGray6))
            )
        }
        
        return  AnyView( recentsCard()
            .background(Color(.systemGray6))
                         
        )
        
    }
    
    private var recentGames: [FinalPod] {
        Array(dataManager.finalStates
            .sorted { $0.date > $1.date }
            .prefix(10))
    }
    
    @MainActor
    private func loadTurnHistory(for gameID: String) {
        guard turnHistoryCache[gameID] == nil else { return }
        
        Task {
            let history = await dataManager.loadTurnHistory(for: gameID)
            await MainActor.run {
                turnHistoryCache[gameID] = history
            }
        }
    }
    
    /*
     @MainActor
     private func loadTurnHistory(for gameID: String) {
     guard turnHistoryCache[gameID] == nil else { return }
     
     Task {
     do {
     let history = try dataManager.podStorage.loadGameTurnHistory(gameID: gameID)
     await MainActor.run {
     turnHistoryCache[gameID] = history
     }
     } catch {
     print("Failed to load turn history for \(gameID): \(error)")
     await MainActor.run {
     turnHistoryCache[gameID] = []
     }
     
     }
     }
     }
     */
    
}



public enum PodDetails : Codable, Hashable, CaseIterable{
    case recents
    case flow
    
    mutating func toggle() {
        self = (self == PodDetails.recents) ? PodDetails.flow : PodDetails.recents
    }
    
    mutating func next() {
        let all = Self.allCases
        if let currentIndex = all.firstIndex(of: self) {
            let nextIndex = all.index(after: currentIndex)
            self = all[nextIndex % all.count]
        }
    }
}


// MARK: - Recent Game Card

struct RecentGameCard: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var appInfo: App_Info
    let pod: FinalPod
    @Binding var flippedPodID: String?
    @State var showingExtended: Bool
    //@Binding var details : PodDetails
    let onReturn: () -> Void
    var onShare: (any View)?
    @State private var trashable: Bool = true
    @State private var landScapeFrame: Bool = false
    var pinnedPods: [String] { appInfo.userInfo.pinnedPodIDs.map{$0.id}}
    var isPinned : Bool { pinnedPods.contains(pod.gameID)}
    var systemModeDark: Bool { colorScheme == .dark }
    var pinColor: Color { systemModeDark ? Color.brown : Color.black }
    var pinsideColor: Color { systemModeDark ? Color.cyan : Color.red }
    
    @State private var containerSize : CGSize = UIScreen.main.bounds.size
    
    
    @State var showPodPurchase: Bool = false
    @State var showInsertedView: Bool = false
    @State var setPodPass: Bool = false
    var sidePad : Double = 6
    
    public func deletePodID(_ podID: String) async {
        guard !appInfo.isPodPinned(podID) else { return }
        
    }
    
    var shareImage: UIImage {
        guard let shareView = onShare else { return UIImage() }
        return shareView.asImage() }
    
    
    var body: some View {
        HStack() {
            
            VStack(alignment: .leading, spacing: 2) {
                let winnersNames =  pod.winningCommander?.displayNames ?? "Unknown Winner"
                
                HStack(alignment: .center) {
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(Color.secondary)
                        .rotationEffect( showingExtended ? .degrees( 0) : .degrees(-90))
                    
                    
                    Text(winnersNames)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.green.gradient)
                        .lineLimit(winnersNames.contains("\n") ? 2 : 1)
                        .minimumScaleFactor(0.01)
                    
                        .onTapGesture {
                            if showingExtended == false {
                                withAnimation(.spring(duration: 0.15)) {
                                    flippedPodID = pod.gameID
                                    showingExtended = true
                                }
                            } else {
                                withAnimation(.spring(duration: 0.15)) {
                                    flippedPodID = nil
                                    showingExtended = false
                                }
                            }
                        }
                    
                    Spacer(minLength: .zero)
                    
                    
                    
                    
                    
                    ZStack(){
                        Image(systemName: isPinned ? "pin.fill" : "pin")
                            .font(.headline)
                            .foregroundStyle(pinsideColor)
                        
                        
                        Image(systemName: "pin")
                            .font(.headline)
                            .foregroundStyle( pinColor.gradient )
                            .onTapGesture {
                                withAnimation(.spring(duration: 0.2)){
                                    
                                    HapticFeedback.impact()
                                    if isPinned { appInfo.unpinPod(pod.gameID) }
                                    else {appInfo.pinPod(pod.gameID) }
                                }
                            }
                        
                    }
                    .rotationEffect(isPinned ? .degrees(45.0) : .degrees(0.0) )
                    .disabled(!isPinned && appInfo.hasMaxPodPins())
                    .padding()
                    .compositingGroup()
                }
                
                
                HStack(alignment: .center){
                    
                    
                    if !showingExtended {
                        
                        VStack(alignment: .leading){
                            Text("\(pod.date.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundColor(Color.secondary)
                            
                            HStack(alignment: .lastTextBaseline){
                                Text(pod.duration.formattedDuration())
                                    .font(.caption)
                                    .fontWeight(.medium)
                                
                                Text("\(pod.playedTurns) turns")
                                    .font(.caption)
                                    .foregroundColor(Color.secondary)
                            }
                            Spacer(minLength: .zero)
                        }
                        .padding(.horizontal, sidePad)
                        
                        Spacer(minLength: .zero)
                    }
                    
                    
                    
                    
                    
                    if showingExtended {
                        HStack(){
                            Button(role: .destructive) {
                                showingExtended = false
                                flippedPodID = nil
                                onReturn()
                            } label: {
                                Image( systemName: trashable ?  "trash.slash" : "trash"   )
                            }
                            .disabled( trashable)
                            //.disabled( appInfo.isPodPinned(pod.gameID) || !trashable )
                            //.disabled( !appInfo.isPodPinned(pod.gameID) && trashable  )
                            .disabled( appInfo.isPodPinned(pod.gameID) )
                            
                            
                            Toggle(isOn: $trashable){}
                                .scaleEffect(0.75)
                                .frame(maxWidth: 50)
                        }
                        
                    }
                    Spacer(minLength: .zero)
                    
                    if showingExtended {
                        ShareLink(item: shareImage, preview: SharePreview("Podable-Pod-Game", image: Image(uiImage: shareImage ))) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .imageScale(.small)
                                .padding(.trailing, 6 )
                        }
                    }
                    //}
                    
                }
                
                
                
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(12.0)
        //        .sheet(isPresented: $showPodPurchase, onDismiss: {} ) {
        //            VStack{
        //                Text("Pod Pass")
        //                    .font(.title)
        //
        //                Text("Declare this game data to be high quality")
        //
        //                ScrollView{
        //                    Text("Pod Pass will use automatic tools to verify your game meets a certain threshold of critera to be accepted into the validation teir of podsDB database. Pods yeeted with a Pod Pass are high quality games which we use to build high quality stats of legitimate games from the community. The splitting of game data into validated and regular sets lets us separate casual pods (which may miss crucial information due to missed actions) with pods who are focused on keeping accurate records of their games. We encourage all pods to be as attentive as possible, but we also understand the reality of playing MTG in person.\n")
        //
        //                    Text("Pod Pass will check typical conditions which need to be true in game but may be missed in recording. These include: \n - if a commander was cast before or during the turn a player dealt commander damage to an opponent. \n - a player's turn has an unrealistic duration (too short to even have drawn a card). \n - all commanders have been selected for all players (no defaults). \n - players selected their self-rated brackets and rated each player in the aftergame. \n ")
        //
        //                    Text("Certain values of the pod can be edited to correct certain mistakes. For example, a player may have cast a commander before or during their turn but not recorded it before they dealt damage to an opponent. In this case, the player can edit the turn to indicate when they did cast their commander. Another changable property would be the alternative loss declaration. It is possible to accidentally pick the wrong one (e.g. Concede instead of Mill) so this property can also be edited on the turn the player declaired the loss. Things which cannot be edited include the duration of players turns, bracket ratings, and commanders names. Please make sure to be mindful of this during gameplay.\n")
        //                }
        //                .padding()
        //                .frame(width: 0.9*containerSize.width, height: 0.2*containerSize.height)
        //                .border(Color.orange)
        //
        //                HStack{
        //                    Text("Select this pod for Pod Pass?")
        //                    Button(action: { setPodPass.toggle() }) {
        //                        Image(systemName: setPodPass ? "checkmark.square.fill" : "square")
        //                    }
        //                }
        //                Text("A pod can only be uploaded once.")
        //                    .foregroundStyle(.secondary)
        //            }
        //        }
    }
    
}




/*
import SwiftUI
import Podwork


@MainActor
struct PodsRecentsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.refresh) private var refreshAction

    @StateObject private var dataManager = GameDataManager.shared
    @State private var selectedGame: FinalPod?
    @State private var selectedGameID: String = ""
    @State private var selectedTurn: (game: String, turn: Int, player: Int)?
    @State private var showingGameDetails: Bool = false
    
    @State private var turnHistoryCache: [String: [Turn]] = [:]
    
    @State public var podCasts: [PodCastHistory] = []
    @State var selectedCommander : String = ""
    @State var flipStates: [String: PodDetails] = [:]
    @State var flip: PodDetails = PodDetails.recents
    @State var flippedPodID: String? = nil
    private let containerScale : CGFloat = 0.95
    private let sidePad : CGFloat = 6

    @State var trashable : Bool = false
    @State var showingExtended: Bool = false
    @State var showPodMap : Bool = false
    
    var body: some View {
        ZStack{
            VStack(spacing: sidePad ){
                
                if dataManager.finalStates.isEmpty {
                    EmptyNoDataView(statsScreen: EnhancedStatsScreens.pods)
                } else {
                    
                    ForEach(recentGames, id: \.gameID) { game in
                        
                        let flipState = flipStates[game.gameID, default: PodDetails.recents]
                        VStack (alignment:.center){
                            PodViewSwapper(for: game, with: turnHistoryCache)
                                .onChange(of: flippedPodID) { oldVal, newVal in
                                    if oldVal == nil {
                                        Task {
                                            await refreshAction?() }
                                    }
                                }
//                                .onTapGesture {
//                                    withAnimation(.spring(duration: 0.15)){
//                                        
//                                        selectedGame = game
//                                        selectedGameID = game.gameID
//                                        let imutFlipState = flipStates
//                                        imutFlipState.forEach{ if $0.1 == PodDetails.flow { flipStates[$0.0] = PodDetails.recents } }
//                                        flipStates[game.gameID] = flipState == PodDetails.recents ? PodDetails.flow : PodDetails.recents
//                                    }
//                                }
                            
                        }
                        .onAppear{ loadTurnHistory(for: game.gameID) }
                    }
                    .cornerRadius(12)
                }
            }
            .onAppear{ Task { self.podCasts = try await PodCastHistory.loadAll(from: modelContext)} }
            .padding(sidePad)
        }
    }
    
    
    func share(_ myView : any View){
        let image = myView.asImage()
        //print("sharing")
        ShareLink(item: image, preview: SharePreview("Podable-Share-Pod", image: Image(uiImage: image))) {
            Label("Share", systemImage: "square.and.arrow.up")
        }
    }
    

    @MainActor
    func PodViewSwapper(for pod: FinalPod, with turnHistory: [String: [Turn]] ) -> AnyView {
        var podFlowCard = AnyView(ZStack{})
        if flippedPodID == pod.gameID {
            
        }
        
        @ViewBuilder
        func recentsCard() -> some View { RecentGameCard(pod: pod,
                                                        flippedPodID: $flippedPodID,
                                                         showingExtended: Binding(
                                                            get: { flippedPodID == pod.gameID },
                                                            set: { newVal in
                                                                flippedPodID = newVal ? pod.gameID : nil
                                                            }
                                                         ),
                                                         trashable: $trashable,
                                                        onReturn: {
            Task { await dataManager.deleteGame(pod.gameID)
                await self.podCasts.select(pod.gameID).removePod(podID: pod.gameID )
                turnHistoryCache[ pod.gameID ] = nil
                flipStates[ pod.gameID ] = nil
            }
                                                                    },
                                                         onShare: podFlowCard .background(Color(.systemGray6))
        )
        .padding(sidePad)
        }
            
        //if flipStates[pod.gameID] == PodDetails.recents {
        if pod.gameID != flippedPodID {
            return AnyView(
                recentsCard()
                .background(Color(.systemGray6))
            )}
        
        //if flipStates[pod.gameID] ==  PodDetails.flow {
        //if pod.gameID == flippedPodID  {
            
            podFlowCard = AnyView(OptimizedGameFlowCard(
                game: pod,
                turnHistory: turnHistoryCache[pod.gameID] ?? [],
                on_Appear: {
                    loadTurnHistory(for: pod.gameID) },
                podCastHistory: podCasts.select(pod.gameID)
            )  )
            
            
            return AnyView(
                VStack(spacing:0){
                    recentsCard()
                    podFlowCard
                }
            .background(Color(.systemGray6))
            )
        ///}
        
        //return  AnyView( recentsCard()
        //        .background(Color(.systemGray6))
                
       // )

    }
    
    private var recentGames: [FinalPod] {
        Array(dataManager.finalStates
            .sorted { $0.date > $1.date }
            .prefix(10))
    }
    
    @MainActor
    private func loadTurnHistory(for gameID: String) {
        guard turnHistoryCache[gameID] == nil else { return }
        
        Task {
            let history = await dataManager.loadTurnHistory(for: gameID)
            await MainActor.run {
                turnHistoryCache[gameID] = history
            }
        }
    }

    /*
    @MainActor
    private func loadTurnHistory(for gameID: String) {
        guard turnHistoryCache[gameID] == nil else { return }
        
        Task {
            do {
                let history = try dataManager.podStorage.loadGameTurnHistory(gameID: gameID)
                await MainActor.run {
                    turnHistoryCache[gameID] = history
                }
            } catch {
                print("Failed to load turn history for \(gameID): \(error)")
                await MainActor.run {
                    turnHistoryCache[gameID] = []
                }
                
            }
        }
    }
     */
    
}
        


public enum PodDetails : Codable, Hashable, CaseIterable{
    case recents
    case flow
    
    mutating func toggle() {
        self = (self == PodDetails.recents) ? PodDetails.flow : PodDetails.recents
    }
    
    mutating func next() {
        let all = Self.allCases
        if let currentIndex = all.firstIndex(of: self) {
            let nextIndex = all.index(after: currentIndex)
            self = all[nextIndex % all.count]
        }
    }
}


// MARK: - Recent Game Card


@MainActor
struct RecentGameCard: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var appInfo: App_Info
    let pod: FinalPod
    @Binding var flippedPodID: String?
    @Binding var showingExtended: Bool
    @Binding var trashable: Bool
    //@Binding var details : PodDetails
    let onReturn: () -> Void
    var onShare: (any View)?
    var pinnedPods: [String] { appInfo.userInfo.pinnedPodIDs.map{$0.id} }
    var isPinned : Bool { appInfo.isPodPinned(pod.gameID) }
    var systemModeDark: Bool { colorScheme == .dark }
    var pinColor: Color { systemModeDark ? Color.brown : Color.black }
    var pinsideColor: Color { systemModeDark ? Color.cyan : Color.red }
    var trashLabel: String { trashable ? "trash" : "trash.slash" }
    @State private var containerSize : CGSize = UIScreen.main.bounds.size
    var sidePad : Double = 6

 
    
    var shareImage: UIImage {
        guard let shareView = onShare else { return UIImage() }
        return shareView.asImage() }
    
    var winnersBracketColor : Color {
        guard pod.winningCommander != nil else { return Color.gray }
        let winningBracket = pod.winningCommander!.bracketRating
        //let bracketColor = BracketSystem(rawValue: winningBracket)!.secondColor
        return bracketColor(winningBracket)
    }

    var body: some View {
        HStack() {
            
            VStack(alignment: .leading, spacing: 2) {
                let winnersNames =  pod.winningCommander?.displayNames ?? "Unknown Winner"
                
                HStack(alignment: .center) {
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(Color.secondary)
                        .rotationEffect( showingExtended ? .degrees( 0) : .degrees(-90))

                    
                    
                    VStack(alignment: .leading){
                        Text("\(pod.date.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(Color.secondary)
                        
                        HStack(alignment: .lastTextBaseline){
                            Text(pod.duration.formattedDuration())
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Text("\(pod.playedTurns) turns")
                                .font(.caption)
                                .foregroundColor(Color.secondary)
                        }
                        Spacer(minLength: .zero)
                    }
                    //.padding(.horizontal, sidePad)
                    .padding( sidePad)
                    
                    //Spacer(minLength: .zero)
                    
                    
                    
                    
                    Spacer(minLength: .zero)
                    

                    
                    Text(winnersNames)
                        .font(.body)
                        .fontWeight(.semibold)
                    //.foregroundStyle(Color.green.gradient)
                        .foregroundStyle(winnersBracketColor.gradient)
                        .lineLimit(winnersNames.contains("\n") ? 2 : 1)
                        .minimumScaleFactor(0.01)
                    
                    //}
                    
                
                   
//                    
//                    ZStack(){
//                        Image(systemName: isPinned ? "pin.fill" : "pin")
//                            .font(.headline)
//                            .foregroundStyle(pinsideColor)
//                        
//                        
//                        Image(systemName: "pin")
//                            .font(.headline)
//                            .foregroundStyle( pinColor.gradient )
//                           
//                        
//                    }
//                    .onTapGesture {
//                        HapticFeedback.impact()
//                        withAnimation(.spring(duration: 0.2)){
//                            if isPinned { appInfo.unpinPod(pod.gameID) }
//                            else { appInfo.pinPod(pod.gameID) }
//                        }
//                    }
//                    .drawingGroup()
//                    .rotationEffect(isPinned ? .degrees(45.0) : .degrees(0.0) )
//                    .disabled(!isPinned && appInfo.hasMaxPodPins())
//                    .padding()
//                    
                   
                    //
                }
                
                .onTapGesture {
                    if showingExtended == false {
                        withAnimation(.spring(duration: 0.15)) {
                            flippedPodID = pod.gameID
                            showingExtended = true
                        }
                        
                    } else {
                        withAnimation(.spring(duration: 0.15)) {
                            flippedPodID = nil
                            showingExtended = false
                        }
                    }
                }

                
                HStack(alignment: .center){
                
                    if showingExtended {
                        HStack(){
                            Button(role: .destructive) {
                                showingExtended = false
                                flippedPodID = nil
                                onReturn()
                            } label: {
                                Image( systemName: trashLabel  )
                            }
                            .disabled( self.trashable == false )
                            
                            
                            //.disabled( appInfo.isPodPinned(pod.gameID) )
                            //.disabled( isPinned )
                    
                            //.disabled( appInfo.isPodPinned(pod.gameID) || !trashable )
                            //.disabled( !appInfo.isPodPinned(pod.gameID) && trashable  )
                            
                            
                            Toggle(isOn: $trashable){}
                                .onChange(of: self.trashable) {
                                    withAnimation(.spring(duration: 0.05)){
                                    }
                                }
                                .toggleStyle(.switch)
                                .scaleEffect(0.75)
                                .frame(maxWidth: 50)
                            
                        }
                     

                        Spacer(minLength: .zero)
                    
                        ShareLink(item: shareImage, preview: SharePreview("Podable-Pod-Game", image: Image(uiImage: shareImage ))) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .imageScale(.small)
                                .padding(.trailing, 6 )
                            }
                        }
                    }
                
                
                
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(12.0)
 
 }
 
 }
 */
//        .sheet(isPresented: $showPodPurchase, onDismiss: {} ) {
//            VStack{
//                Text("Pod Pass")
//                    .font(.title)
//                
//                Text("Declare this game data to be high quality")
//                
//                ScrollView{
//                    Text("Pod Pass will use automatic tools to verify your game meets a certain threshold of critera to be accepted into the validation teir of podsDB database. Pods yeeted with a Pod Pass are high quality games which we use to build high quality stats of legitimate games from the community. The splitting of game data into validated and regular sets lets us separate casual pods (which may miss crucial information due to missed actions) with pods who are focused on keeping accurate records of their games. We encourage all pods to be as attentive as possible, but we also understand the reality of playing MTG in person.\n")
//                    
//                    Text("Pod Pass will check typical conditions which need to be true in game but may be missed in recording. These include: \n - if a commander was cast before or during the turn a player dealt commander damage to an opponent. \n - a player's turn has an unrealistic duration (too short to even have drawn a card). \n - all commanders have been selected for all players (no defaults). \n - players selected their self-rated brackets and rated each player in the aftergame. \n ")
//                    
//                    Text("Certain values of the pod can be edited to correct certain mistakes. For example, a player may have cast a commander before or during their turn but not recorded it before they dealt damage to an opponent. In this case, the player can edit the turn to indicate when they did cast their commander. Another changable property would be the alternative loss declaration. It is possible to accidentally pick the wrong one (e.g. Concede instead of Mill) so this property can also be edited on the turn the player declaired the loss. Things which cannot be edited include the duration of players turns, bracket ratings, and commanders names. Please make sure to be mindful of this during gameplay.\n")
//                }
//                .padding()
//                .frame(width: 0.9*containerSize.width, height: 0.2*containerSize.height)
//                .border(Color.orange)
//                
//                HStack{
//                    Text("Select this pod for Pod Pass?")
//                    Button(action: { setPodPass.toggle() }) {
//                        Image(systemName: setPodPass ? "checkmark.square.fill" : "square")
//                    }
//                }
//                Text("A pod can only be uploaded once.")
//                    .foregroundStyle(.secondary)
//            }
//        }

*/
