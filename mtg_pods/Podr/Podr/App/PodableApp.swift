import SwiftUI
import Podwork
import SwiftData
import Analypod


/// Git Hub Commands
///
/// >  git add .
/// >  git commit -m "..."
/// >  git push origin main




//MARK: - MAIN PODABLE APP
@main
struct PodableApp: App {
    @StateObject private var dataManager = GameDataManager.shared
    @StateObject private var appInfo: App_Info
    @State private var sentPodHistory = SentPodsHistory()
        
    var sharedModelContainer: ModelContainer = {
        let schema = Schema( [
            ScryfallCommander.self,
            SentPodsReceipt.self,
            User_Info.self,
            PinnedPod.self,
            PinnedCommander.self,
            BombPodExplosion.self,
            PodCastTax.self,
            SolRingCasts.self,
            CachedBracketStatistics.self,
            LeaderboardRecord.self,
            UsablePodPasses.self,
            SentPodPass.self,
            PodPassEntity.self,
            MegaMagicNewsArticle.self,
            Turn.self,
            Player.self
        ] )
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true )
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)") }   }()
    
    init() { _appInfo = StateObject(wrappedValue: App_Info(userInfo: User_Info())) }
    
    var body: some Scene {
        WindowGroup {
            NavScreen()
                .preferredColorScheme(.dark)
                .statusBarHidden(true)
                .onAppear {
                    let context = sharedModelContainer.mainContext
                    appInfo.setup(context)
                    Task {
                        do {
                            let existingUser = try fetchOrCreateUser(context: context)
                            appInfo.userInfo = existingUser
                            print("... UniqueID: \(appInfo.userInfo.getID())")
                            /// Check user in defaults, add if not
                            let savedUID = appInfo.getUniqueIDfromUserDefaults()
                            if savedUID == nil { appInfo.saveUniqueID()
                                print("... uniqueID saved to User Defaults!")
                            }
                            
                        } catch { print("Error bootstrapping user info: \(error)") }
                    }
                }
                .environment(CommanderStore.shared)
                .environmentObject(sentPodHistory)
                .environmentObject(dataManager)
                .environmentObject(appInfo)
                .preferredColorScheme(.dark)

        }
        .modelContainer(sharedModelContainer)
        
    }
    
    /// Finds the existing User_Info or creates/saves a new one.
    private func fetchOrCreateUser(context: ModelContext) throws -> User_Info {
        let descriptor = FetchDescriptor<User_Info>()
        print("👤 User Profile... ")

        if let user = try context.fetch(descriptor).first {
            user.checkFirstUse()
            print("... Loaded User Profile!")
            return user
        } else {
            let newUser = User_Info()
            context.insert(newUser)
            try context.save()
            let firstDate = newUser.firstUsage
            UserDefaults.standard.set(firstDate, forKey: "memberSince" )
            print("... New User Profile Created!")
            return newUser
        }
    }
}


//MARK: - APPVIEW ENUM CHOICES
public enum AppView : Hashable, Decodable{
    case splash
    case main
    case newGame
    case newDuel
    case tournament
    case statistics
    case history
    case profile
    case news
}


//MARK: - NAV SCREEN
struct NavScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(CommanderStore.self) var commanderStore
    @Environment(\.dismiss) var dismiss
    @State private var showDownloadCommanders: Bool = false
    @State private var currentView: AppView = AppView.splash
    @State private var animate = false
    @State private var bkgColor: Color = Color.blue
    @State private var path = NavigationPath()
    @State private var skipInitSetup = true
    private let animationDuration: Double = 0.750
    private let splashDisplayDuration: Double = 2.0
    
    var body: some View {
        ZStack {
            NavigationStack(path: $path) {
                EmptyView()
                    .navigationDestination(for: AppView.self) { naView in
                        ZStack {
                            //backgroundView
                             //   .statusBarHidden(true)
                            
                            switch naView {
                            case AppView.splash:
                                SplashScreenAnimationView(animate: $animate) {
                                    withAnimation(.smooth(duration: animationDuration)) {
                                    }
                                }
                                .transition(.asymmetric(
                                    insertion: .opacity,
                                    removal: .scale(scale: 0.8).combined(with: .opacity)
                                ))
                                .navigationBarBackButtonHidden(true)
                                
                            case AppView.main:
                                // MainMenuView
                                ZStack{
                                    
                                    MainMenuView { view in
                                        withAnimation(.easeInOut(duration: animationDuration)) {
                                            bkgColor = Color.blue
                                            path.append(view)
                                        }
                                    }
                                    
                                    if !skipInitSetup {
                                        InitCommanderInstall(closeWindow:$skipInitSetup)
                                            .padding()
                                    }
                                }
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 1.2).combined(with: .opacity),
                                    removal: .opacity
                                ))
                                .navigationBarBackButtonHidden(true)
                                
                                .onAppear{
                                    Task{
                                        await MainActor.run { commanderStore.setup(with: modelContext)}
                                        /// Allow time for DB to load
                                        try? await Task.sleep(nanoseconds: UInt64( 1_000_000_000))
                                        showDownloadCommanders = commanderStore.commanders.isEmpty
                                        if showDownloadCommanders == true { skipInitSetup = false }
                                    }
                                    print("Commanders need to be downloaded?", showDownloadCommanders)
                                }
                                .onChange(of: commanderStore.commanders){
                                    showDownloadCommanders = commanderStore.commanders.isEmpty
                                    if showDownloadCommanders == false {
                                        skipInitSetup = true
                                    }
                                }
                                /*
                                .alert(isPresented: $showDownloadCommanders) {
                                    Alert(
                                        title: Text(" ⚠️ Update Data"),
                                        message: Text("Podable relies on other Community tools for accurate card information.\n\nCommander card data can be updated anytime with Fetchr (See More).\n\nRemember to update the list after every new set release!\n\nDownload Commander card data?\n\n(Estimated: \(formatBytes(commanderStore.lastDownloadSize ?? 15_000_000)))"),
                                        primaryButton: .default( Text("Download") ) { path.append(AppView.fetchr) },
                                        secondaryButton: .cancel()
                                    )
                                }
                                */
                          
                                
                            case AppView.newGame:
                                TransferFromMenuView(screenType: ScreenCategoryView.newPod) {
                                    withAnimation(.easeInOut(duration: animationDuration)) {
                                        bkgColor = Color.green
                                        path.removeLast()
                                    }
                                }
                                .transition(.scale)

                            case AppView.newDuel:
                                DuelMatchContainerView(match: DuelMatch())
                                    .transition(.scale)
                                    .navigationBarBackButtonHidden(true)

                            case AppView.tournament:
                                TournamentHubView {
                                    withAnimation(.easeInOut(duration: animationDuration)) {
                                        bkgColor = Color.blue
                                        path.removeLast()
                                    }
                                }
                                .transition(.scale)
                                .navigationBarBackButtonHidden(true)
                                
                            case AppView.statistics:
                                TransferFromMenuView(screenType: ScreenCategoryView.statistics) {
                                    withAnimation(.easeInOut(duration: animationDuration)) {
                                        bkgColor = Color.orange
                                        path.removeLast()
                                    }
                                }
                                .transition(.slide)
                                
                            case AppView.history:
                                TransferFromMenuView(screenType: ScreenCategoryView.history) {
                                    withAnimation(.easeInOut(duration: animationDuration)) {
                                        bkgColor = Color.purple
                                        path.removeLast()
                                    }
                                }
                                .transition(.slide)
                                .navigationBarBackButtonHidden(true)
                                
                                
                            case AppView.news:
                                
                                TransferFromMenuView(screenType: ScreenCategoryView.news) { withAnimation(.easeInOut(duration: animationDuration)) {
                                        bkgColor = Color.purple
                                        path.removeLast()
                                    }
                                }
                                .transition(.slide)
                                
                                
                            case AppView.profile:
                               ProfileView()
                                .transition(.slide)
                            }
                        }
                    }
            }
        }
        .onAppear {
            bkgColor = Color.blue
            path.append(AppView.splash)
            commanderStore.setup(with: modelContext)
            DispatchQueue.main.asyncAfter(deadline: .now() + splashDisplayDuration) {
                if currentView == AppView.splash {
                    withAnimation(.easeInOut(duration: animationDuration)) {
                        path.append(AppView.main)
                    }
                }
            }
        }
    }
    
    private var backgroundView: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(bkgColor.gradient.opacity(0.55))
                .frame(width: geometry.size.width, height: geometry.size.height * 0.95)
                .offset(x: 0, y: geometry.size.height * 0.025)
                .animation(.easeInOut(duration: animationDuration), value: bkgColor)
        }
        .background(Color.black.gradient)
    }
}


//MARK: - SPLASH SCREEN
struct SplashScreenAnimationView: View {
    @Binding var animate: Bool
    @State var dragPod = PodsOnMainDragState()
    //let steelGray = Color(white: 0.4345)
    let steelGray = Color(white: 0.8545)
    let onComplete: () -> Void
    
    var body: some View {
        ZStack{
            VStack {
                Spacer()
                Text("Podable")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(Color.blue.gradient)
                    .customStroke(color: Color.brown, width: 0.20)
                    .customStroke(color: Color.black, width: 1.05125)
                    .padding(10)
                    .scaleEffect(animate ? 1.0 : 0.8)
                    .opacity(animate ? 1.0 : 0.0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6), value: animate)
                Spacer()
                AnimatedPodsView(animate: $animate, dragPod: $dragPod)
                Spacer()
                Text("Log • Pod • Cast")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.gray.gradient)
                    .multilineTextAlignment(.center)
                    .opacity(animate ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 1.0).delay(0.5), value: animate)
                Spacer()
            }
            .padding()
            .background( RoundedRectangle(cornerRadius: 30)
                .fill(steelGray.gradient)
                .stroke(Color.black, lineWidth: 3)
                .background(Color.clear)
                .background(.ultraThinMaterial)
                .opacity(0.2))
            
            .cornerRadius(17)
            .shadow(color: Color.black, radius: 8)
            .scaleEffect(animate ? 1.0 : 0.9)
            .onAppear {
                animate = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    onComplete()
                }
            }
            .onDisappear {
                animate = false
            }
        }
    }
}


//MARK: - AMIMATED PODS
@MainActor
struct AnimatedPodsView: View {
    @Binding var animate: Bool
    @Binding var dragPod : PodsOnMainDragState

    @MainActor
    var body: some View {
        ZStack{
            HStack (spacing: 25){
                Text("((( ")
                    .rotationEffect(Angle(degrees: -10))
                    .font(.system(size: 58, weight: .ultraLight))
                    .foregroundColor(Color.black)
                    .customStroke(color: Color.cyan, width: 0.5)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                    .shadow(radius: 5)
                    .opacity(animate ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 1.0), value: animate)
                
                ZStack {
                    /// Pod 1: Curved motion
                    Circle()
                        .fill(Color.blue.gradient)
                        .stroke(Color.black, lineWidth: 1)
                        .frame(width: 40, height: 50)
                        .offset(
                            x: animate ? 0 : -40,
                            y: animate ? 30 : -20
                        )
                        .scaleEffect(animate ? 1.2 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                            value: animate
                        )
                        .shadow(radius: 2)
                    
                    
                    /// Pod 2: Bouncing
                    Circle()
                        .fill(Color.green.gradient)
                        .stroke(Color.black, lineWidth: 1)
                        .frame(width: 50, height: 40)
                        .offset(x: 20, y: animate ? -20 : 20)
                        .scaleEffect(animate ? 1.2 : 1.0)
                        .animation(
                            .interpolatingSpring(stiffness: 50, damping: 2)
                            .repeatForever(autoreverses: true),
                            value: animate
                        )
                        .shadow(radius: 2)
                    
                    
                    /// Pod 3: Spiral rotation
                    Circle()
                        .fill(Color.purple.gradient)
                        .stroke(Color.black, lineWidth: 1)
                        .frame(width: 40, height: 50)
                        .offset(x: 30, y: animate ? 20 : -20)
                        .rotationEffect(Angle(degrees: animate ? 220 : 0))
                        .scaleEffect(animate ? 1.2 : 1.0)
                        .animation(
                            .easeInOut(duration: 2.4).repeatForever(autoreverses: true),
                            value: animate
                        )
                        .shadow(radius: 2)
                    
                    
                    /// Pod 4: Shake effect
                    Circle()
                        .fill(Color.orange.gradient)
                        .stroke(Color.black, lineWidth: 1)
                        .frame(width: 50, height: 40)
                        .offset(x: animate ? 30 : -10)
                        .scaleEffect(animate ? 1.2 : 1.0)
                        .animation(
                            .easeInOut(duration: 0.55).repeatForever(autoreverses: true),
                            value: animate
                        )
                        .shadow(radius: 2)
                }
                .padding(.vertical)
                
                Text(")))")
                    .rotationEffect(Angle(degrees: 10))
                    .font(.system(size: 58, weight: .ultraLight))
                    .foregroundColor(Color.black)
                    .customStroke(color: Color.cyan, width: 0.5)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                    .shadow(radius: 2)
                    .opacity(animate ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 1.0).delay(0.2), value: animate)
            }

            PodsOnMainView(index: 0, dragState: dragPod,  animate: $animate)
        }
    }
}


/**/
//MARK: - MAIN MENU - DRAG POD ONTO BUTTONS
@MainActor
struct MainMenuView: View {
    @State var ani: Bool = false
    @State var dragPods = PodsOnMainDragState()
    let steelGray = Color(white: 0.8345)
    let onNavigate: (AppView) -> Void
    let buttonSpread = 0.25
    
    
    //MARK: - FULL BUILD OF THE MENU SCREEN
    @MainActor
    var body: some View {
        ZStack(alignment:.center){
            
            // Extends TOP and BOTTOM edge of phone to match Interior
            QuadrantBackground(activePlayerID: -1, bombPodActive: false, whoCalledBombPod: 0)
                .background(Color.black.shimmer())
                .statusBarHidden(true)
                .compositingGroup()
                .ignoresSafeArea(.all)
            // Mask-like extension for Color matching
            Rectangle()
                .foregroundStyle(Color.black.gradient)
            // Main Background
            QuadrantBackground(activePlayerID: -1, bombPodActive: false, whoCalledBombPod: 0)
                .background(Color.black.shimmer())
            
            
            
            
            // Title
            podableTitleLabel
            
            // Info loop
            InstructionOverlay(messages: [
                "Commander Life Tracker",
                "Swipe  ⚪️👈  Pod",
                "Deck Bracket Ratings",
                "Statistics from Games",
                "Detailed Turn History",
                "Community News",
                "60-Card Duel Mode",
                "Best-of-Three Matches",
                "Tournament Mode"],
                               timing: InstructionTiming(fadeDuration: 1.45, visibleDuration: 2.5)
            ).offset(y: -0.325*UIScreen.main.bounds.height)

            // Main Menus Buttons
            buttonArray
            
            // Dragable Pod to show off the Drag Feature
            AnimatedPodsView(animate: $ani, dragPod: $dragPods)

            // Hidden User Profile
            firstDateLabel
        }
        .onAppear { ani = true}
        .onChange(of:  dragPods.selectedMenuButtonIndex ?? -1 ){ prev, curVal in
            if prev != curVal, curVal >= 0{
                
                let selectView = [AppView.newGame, AppView.history, AppView.news, AppView.statistics, AppView.newGame, AppView.profile, AppView.newDuel, AppView.tournament]
                dragPods.selectedMenuButtonIndex = nil
                onNavigate(selectView[curVal])
            }
        }
        .onPreferenceChange(ButtonFrameKey.self) { frames in
            // Capture all button frames
            for (idx, frame) in frames {
                if idx < dragPods.menuButtonFrames.count {
                    dragPods.menuButtonFrames[idx] = frame
                    let _ = print("button Frame", idx, frame)
                }
            }
        }
    }
    
    
    //MARK: - PODABLE TITLE
    @ViewBuilder
    var podableTitleLabel: some View{
        MultiOutlinedText(
            text: "Podable",
            font: .system(size: 50, weight: .light, design: .rounded),
            strokeWidth: 1.75,
            strokeColor: [ Color.black, Color.white, Color.black],
            fillColor: Color.blue
        )
        .modifier(buttonFrameMod(index:4, dragPod: $dragPods))
        .offset(y: -0.4*UIScreen.main.bounds.height)
    }
    
    
    //MARK: - BUTTONS IN QUADRANTS
    @ViewBuilder
    @MainActor
    var buttonArray: some View{
        VStack(spacing: 12) {
            HStack(){
                VStack( alignment:.center, spacing: buttonSpread*UIScreen.main.bounds.height) {
                    menuSection(
                        title: "",
                        buttonText: "• New Pod •",
                        buttonColor: getColor(for: 0), //Color.green,
                        action: { onNavigate(.newGame) } )
                    .modifier(buttonFrameMod(index:0, dragPod: $dragPods))

                    menuSection(
                        title: "",
                        buttonText: " •   Stats   • ",
                        buttonColor: getColor(for: 3), //Color.purple,
                        action: { onNavigate(.statistics) } )
                    .modifier(buttonFrameMod(index:3, dragPod: $dragPods))
                }
                .frame(maxWidth:.infinity)

                VStack(alignment:.center, spacing: buttonSpread*UIScreen.main.bounds.height){
                    menuSection(
                        title: "",
                        buttonText: "• History •",
                        buttonColor: getColor(for: 1), //Color.orange,
                        action: { onNavigate(.history) } )
                    .modifier(buttonFrameMod(index:1, dragPod: $dragPods))

                    menuSection(
                        title: "",
                        buttonText: " •  News  • ",
                        buttonColor: getColor(for: 2),//Color.blue,
                        action: { onNavigate(.news) } )
                    .modifier(buttonFrameMod(index:2, dragPod: $dragPods))
                }
                .frame(maxWidth:.infinity)
            }

            // New 60-Card Format Buttons
            HStack(spacing: 12) {
                menuSection(
                    title: "",
                    buttonText: "• Duel •",
                    buttonColor: Color.cyan,
                    action: { onNavigate(.newDuel) } )
                .modifier(buttonFrameMod(index:6, dragPod: $dragPods))

                menuSection(
                    title: "",
                    buttonText: "• Tournament •",
                    buttonColor: Color.yellow,
                    action: { onNavigate(.tournament) } )
                .modifier(buttonFrameMod(index:7, dragPod: $dragPods))
            }
            .padding(.horizontal, 8)
        }
    }
    
    
   
    
    
    //MARK: - MENU BUTTON STYLE - DETECTABLE FRAME FOR DRAG POD
    @MainActor
    private struct buttonFrameMod: ViewModifier {
        let index: Int
        @Binding var dragPod: PodsOnMainDragState
        
        @MainActor
        public func body(content: Content) -> some View {
            content
                .background(buttonFrameReader)
                .overlay(
                    Capsule()
                        .stroke(dragPod.highlightedMenuButtonIndex == index ? Color.yellow.gradient : Color.clear.gradient, lineWidth: 8)
                )
        }
        
        @ViewBuilder
        private var buttonFrameReader: some View {
            GeometryReader { proxy in
                Color.clear
                    .preference(
                        key: ButtonFrameKey.self,
                        value: [index: proxy.frame(in: .global)]
                    )
            }
        }
    }
    
    //MARK: - MENU BUTTONS FOR NAVIGATION
    @ViewBuilder
    private func menuSection(title: String, buttonText: String, buttonColor: Color, action: @escaping () -> Void) -> some View {
            Button(action: {
                HapticFeedback.impact(.medium)
                ani=false
                action()
            }) {
                Text(buttonText)
                    .modifier(EnhancedMenuButtonStyle(backgroundColor: buttonColor))
            }
            .buttonStyle(PressableButtonStyle())
    }

    
    //MARK: - FIRST DATE AND USER PROFILE
    @ViewBuilder
    var firstDateLabel: some View{
        VStack{
            Spacer()
            HStack(spacing:0){
                Text("Member Since: ")
                    .bold()
                    .foregroundStyle(Color.white.gradient)
                Text("\(safeFirstDay)")
                    .foregroundStyle(Color.white.gradient)
                    .italic()
            }
            .font(.callout)
            .modifier(buttonFrameMod(index:5, dragPod: $dragPods))
        }
     
    }
    
    var firstUseDate : Date? {
        return UserDefaults.standard.object(forKey: "memberSince") as? Date
    }
    var safeFirstDay : String {
        firstUseDate == nil ? Date.now.yearMonthDay() : firstUseDate!.yearMonthDay()
    }
}
/**/

//MARK: - MENU BUTTON STYLE
@MainActor
struct EnhancedMenuButtonStyle: ViewModifier {
    let backgroundColor: Color
    
    func body(content: Content) -> some View {
        ZStack{
            content
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.white.gradient)
                .customStroke(color: Color.black, width: 1.50)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .background(
                            .brown.gradient
                                .opacity(1.0))
                        .background(.ultraThinMaterial.opacity(0.26))
                        .foregroundStyle(
                            backgroundColor.gradient
                            .opacity(0.5))
                    )
                .overlay(Capsule().stroke(Color.black, lineWidth: 6) )
                .clipShape(Capsule())
        }
    }
}


// MARK: - PRESSABLE BUTTON STYLE MODIFIER
@MainActor
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(duration: 0.05), value: configuration.isPressed)
    }
}



// MARK: - BACKGROUND FOR ALL MAIN MENUS
struct BackgroundFourSquareView: View {
    var body: some View {
        let safeAreaTop = UIApplication.shared.keyWindow?.safeAreaInsets.top ?? .zero
        let safeAreaBottom = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? .zero
        let safeArea = safeAreaTop - safeAreaBottom

        QuadrantBackground(activePlayerID: -1, bombPodActive: false, whoCalledBombPod: 0)
            .background(Color.black)
            .statusBarHidden(true)
            .compositingGroup()
            .offset(y: safeArea/3 )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(.all)
    }
}


//MARK: - APPVIEW ENUM CHOICES
public enum ScreenCategoryView : Hashable, Decodable{
    case main
    case newPod
    case newDuel
    case tournament
    case statistics
    case history
    case news
}


// MARK: - TABS FOR MAIN MENUS
struct TransferFromMenuView: View {
    @State var screenType : ScreenCategoryView? = nil
    @State var title : String = ""
    @State private var selectedTab = 0
    @State private var startPod = false
    let onBack: () -> Void
    
    var body: some View {
        ZStack {
            NavigationView {
                TabView(selection: $screenType) {
                    
                    Tab("New Pod", systemImage: "star.circle", value: ScreenCategoryView.newPod){
                        ZStack{
                            BackgroundFourSquareView()
                            backBar
                            if !startPod {
                                startPodButton
                            }else {
                                StartNewPodrView()
                            }
                        }
                    }
                    
                    Tab("Stats", systemImage: "chart.pie", value: ScreenCategoryView.statistics){
                        ZStack{
                            BackgroundFourSquareView()
                            DataStatsMainView()
                        }
                    }
                    
                    Tab("History", systemImage: "map", value: ScreenCategoryView.history){
                        ZStack{
                            BackgroundFourSquareView()
                            YeetPodView()
                        }
                    }
                    
                    Tab("News", systemImage: "newspaper", value: ScreenCategoryView.news){
                        ZStack{
                            BackgroundFourSquareView()
                            MegaMagicNewsView()
                        }
                    }
                }
            }
            .transition(.opacity)
        }
        
        //.transition(.identity)
        .navigationBarBackButtonHidden(true)
    }
    
    @ViewBuilder
    var backBar : some View {
        VStack{
            NavigationBackButtonWithTitle(title: $title, color: Color.green, showBack: true) { onBack() }
            Spacer()
        }
        .zIndex(1)
    }
    
    
    @ViewBuilder
    var startPodButton : some View {
        Text("Start Pod")
            .font(.title)
            .foregroundStyle(Color.black.gradient)
            .padding()
            .background(Color.white.gradient.opacity(0.7))
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .onTapGesture {withAnimation{ startPod = true }}
    }
}








struct PerformanceNavView_Previews: PreviewProvider {
    static var previews: some View {
        let previewUser = User_Info(uniqueID: "preview-user", paidApp: true)
        let previewAppInfo = App_Info(userInfo: previewUser)
        
        NavScreen()
            .environmentObject(previewAppInfo)
            .environment(CommanderStore.shared)
            .environmentObject(GameDataManager.shared)
    }
}



#Preview {
    Intro_StatefulPreviewWrapper(true) { _ in
        NavScreen()
            .environmentObject(GameDataManager.shared)
            .environment(CommanderStore.shared)
    }
}



struct Intro_StatefulPreviewWrapper<Value, Content: View>: View {
    @State private var value: Value
    var content: (Binding<Value>) -> Content
    
    init(_ initialValue: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        self._value = State(initialValue: initialValue)
        self.content = content  }
    
    var body: some View {  content($value) }
}



