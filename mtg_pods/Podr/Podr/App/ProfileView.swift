import SwiftUI
import SwiftData
import Podwork
import Analypod

struct ProfileView: View {
    @EnvironmentObject var appInfo: App_Info
    @StateObject var sentPodHistory = SentPodsHistory()
    @Environment(\.modelContext) private var modelContext

    @State private var profileStartDate = Date(timeIntervalSinceNow: -86400 * 150)
    @State private var availablePods = 3
    //@State private var totalPodsYeeted = 27
    //@State private var totalSentPodPasses = 1
    @State private var showPodAnimation = false
    @State private var isDarkModeEnabled = true
    @State private var notificationsEnabled = true
    private var maxProgress: Int = 100
    @State private var containerSize: CGSize = UIScreen.main.bounds.size
    @State private var unlocked: Int = 0
    
    // MARK: - Computed Properties
    private var profileAgeDays: Int {
        Calendar.current.dateComponents([.day], from: profileStartDate, to: Date()).day ?? 0
    }
    
    private var userShareID: String {
        guard let uniqueID = UserDefaults.standard.string(forKey: "uniqueID") else {
            return "0000"
        }
        let shareID = uniqueID.prefix(8)
        return String(shareID)
    }
    
    
    private var progress: Double {
        Double(totalSentPodPasses) / Double(maxProgress)
    }
    
    private var badgeUnlocked: Bool {
        totalSentPodPasses >= 5
    }
    
    private var totalSentPodPasses: Int {
        sentPodHistory.totalSentPodPasses() + 5
    }
    private var totalPodsYeeted: Int {
        sentPodHistory.totalAcceptedPods()
    }
    private func checkUnlocked() {
        unlocked = 0
        /// Creator Badge unlocked
        if totalSentPodPasses >= maxProgress { unlocked += 1 }
        
        /// Shared 1 Game
        if hasUnlockedOnePod { unlocked += 1 }
        /// Shared 5 Games
        if hasUnlockedFivePod { unlocked += 1 }
        
        
    }
    
    private var hasUnlockedOnePod: Bool { return totalPodsYeeted >= 1 ? true : false }
    private var hasUnlockedFivePod: Bool { return totalPodsYeeted >= 5 ? true : false }
    
    @ViewBuilder
    var aboutPodable : some View{
        VStack{
            Spacer()
            Text("Podable")
                .font(.largeTitle.bold())
                .foregroundStyle(Color.white.gradient)
                .customStroke(color: Color.black, width: 1)
            
            Text("👍  Its okay!")
                .font(.title2)
                .bold()
                .foregroundStyle(Color.white.gradient)
                .customStroke(color: Color.black, width: 1)
            Spacer()
            Spacer()
        }
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Futuristic gradient background
            LinearGradient(
                //colors: [Color(.sRGB, red: 0.1, green: 0.1, blue: 0.15), Color.purple.opacity(0.7), Color.indigo.opacity(0.5)],
                
                //colors : [Color.black.opacity(0.81),Color(.sRGB, red: 0.41, green: 0.1, blue: 0.55),Color.blue.opacity(0.57),Color.cyan.opacity(0.7), Color.white.opacity(0.65), Color.teal.opacity(0.65), Color.green.opacity(0.65),Color.brown.opacity(0.7), Color.orange.opacity(0.5)],
                
                colors: [Color.black.opacity(0.81),Color.indigo.opacity(0.31),Color(.sRGB, red: 0.41, green: 0.1, blue: 0.55),Color.blue.opacity(0.57),Color.cyan.opacity(0.67), Color.white.opacity(0.51), Color.white.opacity(0.6), Color.green.opacity(0.5),Color.brown.opacity(0.47), Color.orange.opacity(0.5)],
               //colors: [Color(.sRGB, red: 0.31, green: 0.21, blue: 0.85).opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            
            aboutPodable
            if showPodAnimation {
                PodUnlockAnimationView()
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear{
            profileStartDate = appInfo.userInfo.getStartDate()
            

            sentPodHistory.setup(modelContext)
            do{ try sentPodHistory.loadSentPods() }
            catch{print("error with loading SentPods: \(error)") }
            
            checkUnlocked()
            showPodUnlockAnimation()
        }
    }
    
    // MARK: - Helper Animation
    func showPodUnlockAnimation() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
            showPodAnimation = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation(.bouncy) {
                showPodAnimation = false
            }
        }
    }
    

    //MARK: -
    @ViewBuilder
    var profilePicWithUnlocks: some View {
        HStack(alignment: .top, spacing: 0) {
            // Profile Icon with overlay achievements
            VStack(alignment:.center, spacing:20){
                ZStack {
                    Circle()
                        .fill(Color.white.gradient.opacity(0.5))
                        .fill(.ultraThinMaterial)
                        .stroke(Color.black, lineWidth: 4)
                        .frame(width: 170, height: 170)
                        .overlay(
                            ZStack{
                                Image(systemName:  "person.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundStyle(Color.teal.gradient.opacity(0.85))
                                    .padding(35)
                                    .customStroke(color: Color.black, width: 1)
                            }
                        )
                    
                    
                    if badgeUnlocked {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 24))
                            .customStroke(color: Color.black, width: 0.5)
                            .rotationEffect(Angle(degrees:0))
                            .offset(x: 20, y: 30)
                            .transition(.scale.combined(with: .opacity))
                            .symbolEffect(.bounce)
                            .blur(radius: 4, opaque:false)
                            .opacity(0)
                        
                    }
                    
                    ZStack{
                        
                        Image(systemName: "circle.tophalf.filled.inverse")
                            .foregroundColor(.white)
                            .font(.system(size: 14))
                        //
                        //                                Image(systemName: "eye.half.closed")
                        //                                    .font(.system(size: 18))
                        //                                    .foregroundColor(.black)
                        
                        Image(systemName: "swirl.circle.righthalf.filled.inverse")
                            .foregroundStyle(Color.black.gradient)
                            .font(.system(size: 14))
                            .rotationEffect(.degrees(90+45))
                            .scaleEffect(x:-1, y:1)
                        
                        
                        
                        Image(systemName: "circle.fill")
                            .foregroundColor(.black)
                            .font(.system(size:4))
                            .offset(x: 0, y: -2)
                        
                    }
                    .rotationEffect(.degrees(180))
                    .offset(x: -10, y: -25)
                    
                    ZStack{
                        Image(systemName: "circle.bottomhalf.filled")
                            .foregroundColor(.white)
                            .font(.system(size: 14))
                        
                        Image(systemName: "swirl.circle.righthalf.filled")
                            .foregroundStyle(Color.black.gradient)
                            .font(.system(size: 14))
                            .rotationEffect(.degrees(-90+45))
                        
                        
                        Image(systemName: "circle.fill")
                            .foregroundColor(.black)
                            .font(.system(size:4))
                            .offset(x: 0, y: -2)
                        //.customStroke(color: Color.black, width: 1)
                        //
                        //                                Image(systemName: "eye.half.closed")
                        //                                    .font(.system(size: 18))
                        //                                    .foregroundColor(.black)
                        // .customStroke(color: Color.black, width: 1)
                    }
                    .rotationEffect(.degrees(180))
                    .offset(x: 10, y: -25)
                   
                    
                    Image(systemName: "mouth.fill")
                        .foregroundColor(.brown.opacity(1.4))
                        .customStroke(color: Color.black, width: 0.1)
                        .font(.system(size: 16))
                        .offset(x: 0, y: -8)
                        .transition(.scale.combined(with: .opacity))
                        .blur(radius: 2, opaque:false)
                        .opacity(0)

                    
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                        .customStroke(color: Color.black, width: 1)
                        .font(.system(size: 36))
                        .offset(x: 0, y: -55)
                        .transition(.scale.combined(with: .opacity))
                        //.blur(radius: 4, opaque:false)
                    
                    
                    Image(systemName: "tag.fill")
                        .foregroundColor(.yellow)
                        .customStroke(color: Color.black, width: 1)
                        .font(.system(size: 16))
                        .offset(x: 25, y: 30)
                        .rotationEffect(Angle(degrees: -90))
                        .transition(.scale.combined(with: .opacity))
                        .blur(radius: 5, opaque:false)
                        .opacity(0)

                    
                    Image(systemName: "wand.and.sparkles.inverse")
                        .foregroundColor(.yellow)
                        .customStroke(color: Color.black, width: 0.5)
                        .font(.system(size: 56))
                        .offset(x: -45, y: 20)
                    //.rotationEffect(Angle(degrees: -90))
                        .transition(.scale.combined(with: .opacity))
                        .symbolEffect(.wiggle.forward.byLayer, options: .nonRepeating)
                        .blur(radius: 6, opaque:false)
                        .opacity(0)

                }
                
                Text("Active for \(profileAgeDays) days")
                    .foregroundStyle(.white.opacity(0.8))
                    .font(.subheadline)
            }
        }
        }
        
    
    //MARK: -
    @ViewBuilder
    var achievementsTable : some View {
        VStack{
            HStack{
                Text("Achievements:")
                    .bold()
                Text("\(unlocked)")
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(Color.white.gradient)
            .background(Color.black)
            
            UnlockableAchievement(name: "Fresh Pod", unlocked: hasUnlockedOnePod, symbol: "person.fill")
            UnlockableAchievement(name: "Pod Master", unlocked: true, symbol: "crown")
            UnlockableAchievement(name: "Scent of Pod", unlocked: true, symbol: "crown")
            UnlockableAchievement(name: "Lethal Cmdr", unlocked: hasUnlockedFivePod, symbol: "crown")
            UnlockableAchievement(name: "Keeper of Sol", unlocked: hasUnlockedFivePod, symbol: "crown")
            UnlockableAchievement(name: "Bomb-Bro", unlocked: hasUnlockedFivePod, symbol: "crown")
            UnlockableAchievement(name: "Funny Nickname", unlocked: hasUnlockedFivePod, symbol: "crown")
            
        }
        .frame(width: containerSize.width * 0.8)
        //.padding()
        .clipShape(
            RoundedRectangle(cornerRadius: 12)
        )
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.gradient.opacity(0.15))
                .stroke(Color.black, lineWidth: 1)
        )
        .frame(maxWidth: .infinity)
        .padding()
    }
        
       
    //MARK: -
    @ViewBuilder
    var shareCodeLabel: some View {
        VStack{
            Text("Share Code:  \(userShareID)")
                .font(.title2.bold())
                .foregroundStyle(Color.white.gradient)
                .customStroke(color: Color.black, width: 1)
            //.padding()
                .padding(12)
                .background(
                    Capsule()
                        .foregroundStyle(Color.yellow.opacity(0.5))
                )
        Text("Input this when sharing Pod data with friends.")
        }
    }
    
    
    //MARK: -
    @ViewBuilder
    var headView : some View {
        VStack(spacing: 10) {
            // Header
            VStack(spacing: 0) {
                Text("Podable Profile")
                    .font(.title.bold())
                    .foregroundStyle(Color.white.gradient)
                    .customStroke(color: Color.black, width: 1)
                
                Text("Unlocked")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .customStroke(color: Color.black, width: 1)
                
            }
            
            profilePicWithUnlocks
            shareCodeLabel
            achievementsTable
            
            // Toggles
            //settingsMenuView
            Spacer()
            
            // Simulate Game Button
            Button(action: {
                withAnimation(.spring()) {
                    //totalSentPodPasses += 1
                }
            }) {
                Text("Play a Game 🎮")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient(colors: [.blue, .blue], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(14)
                    .foregroundColor(.white)
                    .shadow(color: Color.purple.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal)
        }
        .padding(.top, 20)
        
    }
    //MARK: -
        
    @ViewBuilder
    var achievementsListView : some View {
          CappedBoardVeiw(title: "Total Pods",
                     value: "\(Int(0))\n 0 \n",
                     icon: "gamecontroller.fill",
                     color:  .teal)
        //UnlockableAchievement(name: "PodKing", unlocked: hasUnlockedFivePod, symbol: "crown")
    }
    
    
    //MARK: -
    @ViewBuilder
    var settingsMenuView : some View {
        VStack{
            Text("Settings")
                .frame(alignment: .leading)
                .bold()
                .foregroundStyle(Color.white.gradient)
                .multilineTextAlignment(.center)
                .padding(.vertical, 6)
                .padding(.bottom, -4)
                .background(Color(.secondarySystemBackground))

            
            VStack(alignment: .leading, spacing: 15) {
                Toggle("Allow Yeeting Pod Data", isOn: $isDarkModeEnabled)
                Toggle("Download News Articles", isOn: $notificationsEnabled)
            }
            .toggleStyle(SwitchToggleStyle(tint: .purple))
            .padding()
            //.background(.ultraThinMaterial)
            .cornerRadius(16)
            .padding(.horizontal)
            .background(Color(.secondarySystemFill))

        }
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(8)
    }
    
    
    //MARK: -
    @ViewBuilder
    var progressForBadge: some View{
        HStack{
            Text("\(Int(progress * Double(maxProgress)))")
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(.orange)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(1))
                        .stroke(.black, lineWidth:2)
                )
            
                .cornerRadius(4)
                .frame(width: 80)
                .onChange(of: totalSentPodPasses) { newValue in
                    if newValue % 5 == 0 {
                        availablePods += 1
                        showPodUnlockAnimation()
                    }
                }
            Text("\(maxProgress)")
        }
    }
    
    
    //MARK: -
    @ViewBuilder
    var creatorBadge: some View{
        ZStack {
            Image(systemName: badgeUnlocked ? "shield" : "lock.shield")
                .font(.system(size: 60))
                .foregroundStyle(badgeUnlocked ? .purple : .gray.opacity(0.5))
                .symbolEffect(.bounce, value: badgeUnlocked)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                        .shadow(color: .purple.opacity(0.5), radius: 5)
                )
            
            Image(systemName:"heart.text.square" )//"scroll.fill")
            
                .font(.system(size: 24))
            //.scaleEffect(0.48)
                .foregroundStyle(Color.blue)
                .opacity(badgeUnlocked ? 1 : 0)
            
        }
        .background(.ultraThinMaterial)
        .clipShape( RoundedRectangle(cornerRadius: 22))
    }
    
}

struct UnlockableAchievement: View{
    var name: String
    var unlocked: Bool
    var symbol : String
    
    var body: some View {
        HStack{
            Spacer()
            Text(unlocked ? "☑️" : "🔲")
                .frame(minWidth: 30)
                .padding(.horizontal, 6)

            Spacer(minLength: .zero)
            
            Text("\(name)")
                .frame(maxWidth: .infinity)
            
            Spacer(minLength: .zero)
            Image(systemName: unlocked ? symbol : "questionmark")
                .frame(minWidth: 30)
                .padding(.horizontal, 6)
        }
        .frame(maxWidth:.infinity)
    }
}

// MARK: - Components
struct StatCardView: View {
    var title: String
    var value: String
    var color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                //.font(.system(size: 24, weight: .bold))
                .font(.title)
                .bold()
                .foregroundColor(color)
                .customStroke(color: Color.black, width: 1)
            Text(title)
                .font(.footnote)
                //.foregroundColor(.white.opacity(0.7))
                .foregroundColor(Color.secondary)
                .customStroke(color: Color.black, width: 0.25)
        }
        .multilineTextAlignment(.center)
        .lineLimit(2)
       
        .padding(10)
        //.frame(maxWidth: .infinity)
        //.background(.gray)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

@MainActor
struct PodUnlockAnimationView: View {
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 0.5

    
    func randomXOffset() -> CGFloat { CGFloat.random(in: -175.0 ..< 175.0)}
    func randomYOffset() -> CGFloat { CGFloat.random(in: -400.0 ..< -200.0)}
    func randomSize() -> CGFloat { CGFloat.random(in: 0.10 ..< 0.3250)}
    func randomRotation() -> CGFloat { CGFloat.random(in: 0 ..< 360)}
    func randomTime() -> CGFloat { CGFloat.random(in: 0 ..< 1)}
    
 
    
    var body: some View {
        
        
            ForEach(0..<6){ _ in
                let dx = randomXOffset()
                let dy = randomYOffset()
                let dr = randomSize()
                let dt = randomRotation()
                let rt = randomTime()
                var starInstance = sparkles(dt:dt, rt: rt)
                    //.scaleEffect(dr)
                    .offset(x: dx, y: dy)
                   
                starInstance
                    //.rotationEffect(.degrees(randomRotation()))
            }
        }
    
    
    func sparkles(dt : CGFloat, rt : CGFloat) -> some View {
       return Image(systemName: "sparkles")
            .font(.system(size: 50))
            .foregroundStyle(Color.yellow.gradient.opacity(0.74))
            .customStroke(color: Color.blue, width: 1)
            .rotationEffect(.degrees(rotation))
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.linear(duration: 4.2  ).repeatForever(autoreverses: false)) {
                    rotation = 360 + dt
                    
                }
                withAnimation(.linear) {
                    scale = rt
                }
            }
            .shadow(color: .indigo.opacity(0.8), radius: 25)
        
    
    }
}




struct Profile_Previews: PreviewProvider {
    static var previews: some View {
        let previewUser = User_Info(uniqueID: "preview-user", paidApp: true)
        let previewAppInfo = App_Info(userInfo: previewUser)
        let container =  try! ModelContainer(for: SentPodPass.self, SentPodsReceipt.self )
        let context = ModelContext(container)
        
        
        ProfileView()
            .environmentObject(previewAppInfo)
            .modelContainer(container)
    }
    
}
