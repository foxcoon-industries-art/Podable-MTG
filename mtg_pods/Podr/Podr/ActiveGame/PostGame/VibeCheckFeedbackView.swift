import SwiftUI
import Podwork


struct PlayerFeedbackView: View {
    // Player-specific properties
    let currentPlayer: Int
    let commanderNames: [String]
    let otherPlayerIndices: [Int]
    
    // Rating state
    @Binding var showingRating: Bool
    @Binding var ratingIndex: Int
    @Binding var deckRatings: [Int]
    @Binding var isPresented: Bool
    
    @State var temporaryRating : Int = -1

    func enteredRating(for idx : Int) -> Bool {
        return deckRatings[idx] > 0
    }
    
    
    @ViewBuilder
    var opponentRatingsCircles : some View {
        HStack{
            Spacer(minLength: .zero)
            Spacer(minLength: .zero)
            ForEach(0..<4){ idx in
                if idx != currentPlayer {
                    Circle()
                        .foregroundStyle( enteredRating(for:idx) ? getColor(for:idx).gradient : Color.gray.gradient)
                        .frame(width: 0.15*GameUIConstants.podSize)
                    Spacer(minLength: .zero)
                }
            }
            Spacer(minLength: .zero)

        }
        .padding(.vertical, 3)
    }
    
    
    @ViewBuilder
    var opponentCmdrLabel : some View {
        VStack(spacing:0){
            Text("Vibe from:")
                .foregroundStyle(Color.white.gradient)
            
            Text("\(commanderNames[otherPlayerIndices[ratingIndex]])")
                .font(.title2)
                .foregroundStyle(getColor(for:otherPlayerIndices[ratingIndex]).gradient)
                .bold()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            
            opponentRatingsCircles
        }
    }
    
    
    func enteredBracketRating(tgt targetIndex: Int, total totalToRate: Int) -> Void {
        withAnimation {
            //Bracket of zero : do nothing
            if temporaryRating == 0 { return }
            // Update bracket rating of target player
            deckRatings[targetIndex] = temporaryRating
            temporaryRating = 0
            // Keep track of total players rated
            if ratingIndex+1 == totalToRate {  print("ratings for player:", currentPlayer, deckRatings) }
            ratingIndex += 1
            // Finish when all players rated
            if ratingIndex == totalToRate {
                isPresented = false
            }
        }
        
    }
    
    
    var body: some View {
        VStack(spacing: 0) {
            
            if showingRating {
                let totalToRate = otherPlayerIndices.count
                
                if ratingIndex < totalToRate {
                    let targetIndex = otherPlayerIndices[ratingIndex]
                    
                    Spacer(minLength: 0)
                    VStack(alignment: .center, spacing: 0) {
                        Spacer(minLength: 0)

                        opponentCmdrLabel
                        
                        BracketSelector(
                            playerIndex: targetIndex,
                            selectedBracket: Binding(
                            get: { temporaryRating },
                            set: { temporaryRating = $0  }),
                            commanderName: commanderNames[targetIndex],
                            commanderColor: PlayerColors.color(for: targetIndex),
                            onReturn: {enteredBracketRating(tgt: targetIndex, total:totalToRate)}
                        )
                     
                        Spacer(minLength: 0)
                        
                
                        Button(action: { enteredBracketRating(tgt: targetIndex, total:totalToRate) }
                        ) {
                            Text(ratingIndex + 1 == totalToRate ? "Done!" : "→")
                                .font(.body)
                                .modifier(EnhancedMenuButtonStyle(backgroundColor: Color.blue))
                            }
                            .disabled(temporaryRating < 0)
                        
                        Spacer(minLength: 0)
                    }
                } else if ratingIndex == totalToRate {
                    Text("✔ Vibe Check")
                        .font(.headline)
                        .foregroundStyle(Color.gray)}
            }
        }
        .frame(maxWidth: .infinity,  maxHeight: .infinity)
    }
    
    
}



