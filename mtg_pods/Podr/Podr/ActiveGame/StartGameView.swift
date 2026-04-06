import SwiftUI
import Podwork


@MainActor
public struct StartNewPodrView: View {
    public init() { }
    
    public var body: some View {
        ZStack{
                QuadrantBackground(activePlayerID: -1, bombPodActive: false, whoCalledBombPod: -1)
                    .background(Color.black)
                    .background(Color.brown.gradient.opacity(0.7))

                GatheringPodInfoView()
        }
    }
}



@MainActor
public struct GatheringPodInfoView: View {
    @State private var navigateToStartGame = false
    @State private var bracketSelections: [Int?] = Array(repeating: nil, count: 4)
    @State var selectedRandom: Bool = false
    @State var podPlayers: [Bool] = [true, true, true, true]
    
    public var body: some View {
        ZStack{
            if navigateToStartGame {
                FirstPlayerSelectionView(randomizeOnAppear: selectedRandom, podPlayers: podPlayers)
                    .cornerRadius(12.0)
                    .transition(.opacity)
            }
            
            else {
                BracketGridView(selections: $bracketSelections,
                                podPlayers: $podPlayers) { selected, randomizeFirstPlayer in
                    selectedRandom = randomizeFirstPlayer
                    withAnimation{
                        navigateToStartGame = true
                    }
                }
            }
        }
    }
}





struct NewGameView_Previews: PreviewProvider {
    static var previews: some View {
        StartNewPodrView()
    }
}




struct GatheringPodView_Previews: PreviewProvider {
    static var previews: some View {
        let previewUser = User_Info(uniqueID: "preview-user", paidApp: true)
        let previewAppInfo = App_Info(userInfo: previewUser)
        
        
        GatheringPodInfoView()
            .environment(CommanderStore.shared)
            .environmentObject(previewAppInfo)
        
            .previewDevice("iPhone 12 mini")
    }
    
}
