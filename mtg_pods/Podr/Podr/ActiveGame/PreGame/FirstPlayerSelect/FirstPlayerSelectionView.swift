import SwiftUI
import Podwork


struct PlayerPod: Identifiable {
    var id = UUID()
    var position: CGPoint
    var currentQuadrant: Quadrant? = nil
    var isSelected: Bool = false
    var isHighlighted: Bool = false
    var isPlaced: Bool = false
    var color: Color {
        guard let quadrant = currentQuadrant else {
            return Color.white
        }
        if isHighlighted {
            return Color.white
        }
        return PlayerColors.color(for: quadrant.rawValue)
    }
}

struct FirstPlayerSelectionView: View {
    @State var randomizeOnAppear: Bool?
    @State var podPlayers: [Bool]?
    //@State private var numberOfPlayers: Int = 4
    @State private var playerPods: [PlayerPod] = []
    @State private var occupiedQuadrants: [Quadrant: Int] = [:]
    @State private var hasQuadrantConflicts: Bool = false
    @State private var countdownActive: Bool = false
    @State private var countdownValue: Int = 3
    @State private var randomizingActive: Bool = false
    @State private var randomHighlightedIndex: Int? = nil
    @State private var winnerSelected: Bool = false
    @State private var winnerIndex: Int? = nil
    @State private var showConfetti: Bool = false
    @State private var navigateToGame: Bool = false
    @State private var holdCheckTimer: Timer? = nil
    @State private var spinCount = 0
    @State private var screenSize: CGSize = .zero
    
    @StateObject private var viewModel = CountdownViewModel()
    @State var containerSize : CGSize = UIScreen.main.bounds.size

    let quadPodMap = [Quadrant.bottomLeft, Quadrant.topLeft, Quadrant.topRight, Quadrant.bottomRight]
    let totalSpins = 56
    let initialInterval: Double = 0.015
    let maxInterval: Double = 0.21
    
    var playerPodsIndices : [Int] {
        let unwrappedPodPlayers = podPlayers ?? []
        let soln =  unwrappedPodPlayers.enumerated().compactMap { $0.1 ? $0.0 : nil }
        //print(soln)
        return soln
    }
    
    var numberOfPlayers: Int {
        let unwrappedPodPlayers = podPlayers ?? []
        return unwrappedPodPlayers.filter{ $0 }.count
    }
    var firstNotNonPlayer: Int {
        for (idx,ok) in (podPlayers!).enumerated() {
            if ok {
                return idx
            }
        }
        return 0
    }
    
    //@MainActor
    var body: some View {
        
        ZStack {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    quadrantView(.topLeft, color: Color.orange)
                    quadrantView(.topRight, color: Color.blue)
                }
                HStack(spacing: 0) {
                    quadrantView(.bottomLeft, color: Color.green)
                    quadrantView(.bottomRight, color: Color.purple)
                }
            }
            
            
            VStack {
                if hasQuadrantConflicts {
                    TutorialTextHeadlineBoxView(text: "Each player needs their own quadrant!")
                    
                }
                if countdownActive {
                    TutorialTextTitleBoxView(text:"Starting in: \(countdownValue)", color: Color.white, fontStyle: .headline)
                    
                }
                if randomizingActive {
                    TutorialTextTitleBoxView(text:"Randomizing first player...", color: Color.white, fontStyle: .headline)
                    
                }
                if winnerSelected, let winner = winnerIndex, winner < playerPods.count {
                    if let quadrant = playerPods[winner].currentQuadrant {
                        TutorialTextTitleBoxView(text:"\(quadrant.description) Quadrant goes first!", color: playerPods[winner].color)
                    }
                }
                if !hasQuadrantConflicts && !countdownActive && randomizingActive && !winnerSelected   {
                    TutorialTextTitleBoxView(text:"CASTING FIRST PLAYER\nChoose then (TAP) here.", color: Color.white, fontStyle: .footnote)

                        .onTapGesture(perform: {
                            if totalPlacedPods() == 1 {
                                let firstPlayerIndex = playerPods.map{$0.isPlaced}.firstIndex(where:{$0==true})
                                winnerIndex = playerPods[firstPlayerIndex!].currentQuadrant?.rawValue
                                self.selectWinner(firstPlayerIndex ?? 0)
                            }
                        })
                }
            }
            .position(x: 0.5 * containerSize.width, y: 0.075 * containerSize.height)
       
            /// Draggable pods
            ZStack(alignment: .center){
                ChooseQuadPod( hasConflict: checkForConflicts() )
                    .overlay( quadPodMap.allSatisfy({ !isPodPlaced(in: $0) } ) ? AnyView(EmptyView()) :  AnyView(Text("👇\n⭐️").font(.title))  )
                    .onTapGesture(count:1, perform: {
                        if totalPlacedPods() == 1 {
                            let firstPlayerIndex = playerPods.map{$0.isPlaced}.firstIndex(where:{$0==true})
                            winnerIndex = playerPods[firstPlayerIndex!].currentQuadrant?.rawValue
                            self.selectWinner(firstPlayerIndex ?? 0)
                        }
                    })
                
                
                ForEach(playerPods.indices, id: \.self) { index in
                  //  if !playerPods[index].isPlaced {
                    SelectionPod(
                        color: playerPods[index].color,
                        emoji: !podPlayers![index] ? "👇" : "",
                        highlighted: randomHighlightedIndex == index,
                        hasConflict: hasConflict(at: index)
                    )
                    .position(playerPods[index].position)
                    .onTapGesture(count: 2, perform: {
                        //print("pods", playerPods, playerPods.count)
                        
                            //print("double tap")
                            //startSpinDown()
                    })
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                if !countdownActive && !randomizingActive && !winnerSelected {
                                    playerPods[index].position = value.location
                                    let newQuadrant = determineQuadrant(position: value.location, in: containerSize)
                                    if playerPods[index].currentQuadrant != newQuadrant {
                                        if let oldQuadrant = playerPods[index].currentQuadrant {
                                            occupiedQuadrants[oldQuadrant] = nil
                                        }
                                        playerPods[index].currentQuadrant = newQuadrant
                                        updateQuadrantOccupancy(for: index, quadrant: newQuadrant)
                                    }
                                    checkPodsStatus()
                                }
                            }
                            .onEnded { value in
                                if !countdownActive && !randomizingActive && !winnerSelected {
                      
                                    let finalPosition = value.location
                                    let finalQuadrant = determineQuadrant(position: finalPosition, in: containerSize)
                                    let hasMatchingPod = playerPods.contains { $0.isPlaced && $0.currentQuadrant == finalQuadrant }
                                    
                                    if (distanceBetween(finalPosition, getInitialPodPosition(for: finalQuadrant.rawValue, in: containerSize) ) < GameUIConstants.podSize) && !hasMatchingPod {
                                        occupiedQuadrants[playerPods[index].currentQuadrant!] = nil
                                        playerPods.remove(at: index)
                                        resetSinglePod(for: index)
                                    }
                                    
                                    
                                    if (distanceBetween(finalPosition, getQuadrantCenter(for: finalQuadrant, in: containerSize) ) < GameUIConstants.podSize) && !hasMatchingPod { playerPods[index].isPlaced = true }
                                    checkPodsStatus()
                                }
                            }
                    )
                    
                    .opacity( index != firstNotNonPlayer ? 0 : 1)
                    .opacity( (randomizeOnAppear ?? false) ? 0 : 1)
                   // }
                }
                .opacity(randomizingActive ? 0 : 1)
            }
            
            if self.showConfetti, let winner = self.winnerIndex,
               let winnerQuadrant = playerPods[winner].currentQuadrant {
               let _ = print("Showing Confetti View")
                ConfettiView( explosionCenter: playerPods[winner].position )
                    .transition(.opacity)
            } else {
                if self.showConfetti {
                    let _ = print("Showing Confetti View")
                    let quad = Quadrant(rawValue: self.winnerIndex!)
                    ConfettiView( explosionCenter: getQuadrantCenter(for: quad!, in: containerSize) )
                        .transition(.opacity)
                }
            }
        }
        .onAppear {
            screenSize = containerSize
            //resetPods()
            
            if randomizeOnAppear != nil, randomizeOnAppear == true { //startSpinDown()
                //randomizingActive = true
                startRandomization()
           
            }
        }
        .onChange(of: containerSize, initial: true, { oldSize, newSize in
            screenSize = newSize
            resetPods()
        })
        
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        containerSize = geometry.size
                    }
                    .onChange(of: geometry.size) { _, newSize in
                        containerSize = newSize
                    }})
        
        .fullScreenCover(isPresented: $navigateToGame) {
            ActiveGameView()
                .statusBarHidden(true)
                .transition(.opacity)
        }
    }
    
    ///@MainActor
    private func quadrantView(_ quadrant: Quadrant, color: Color) -> some View {
        Rectangle()
            .fill(color.opacity( randomHighlightedIndex == quadrant.rawValue ? 0.8 : isPodInQuadrant(quadrant) ? 0.4 : 0.2 ))
            .overlay {
                Circle()
                    .fill( isPodPlaced(in: quadrant) ? AnyShapeStyle(color.gradient) : AnyShapeStyle(Color.clear) )
                    .stroke(Color.black.opacity(1.0), style: StrokeStyle(lineWidth: 2, dash: [5]))
                    .frame(width: GameUIConstants.bombPodSize, height: GameUIConstants.bombPodSize)
                    .scaleEffect(randomHighlightedIndex == quadrant.rawValue ? 1.45 : 1.0)
                    .opacity( playerPodsIndices.contains(quadrant.rawValue) ? 1 : 0 )
            }
            .compositingGroup()
            //.opacity( playerPodsIndices.contains(quadrant.rawValue) ? 1 : 0 )
            
    }
    
    private func resetPods() {
        playerPods = []
        occupiedQuadrants = [:]
        hasQuadrantConflicts = false
        for (i,pod) in podPlayers!.enumerated() {
            if !pod {
                updateQuadrantOccupancy(for: i, quadrant: quadPodMap[i])
            } else { resetSinglePod(for: i) }
            
        }
        holdCheckTimer?.invalidate()
        holdCheckTimer = nil
        countdownActive = false
        randomizingActive = false
        winnerSelected = false
        countdownValue = 3
    }
    
    private func resetSinglePod(for i: Int) {
        let pod = PlayerPod(
            position: getInitialPodPosition(for: i, in: containerSize)
        )
        playerPods.append(pod)
    }
    
    private func getInitialPodPosition(for index: Int, in size: CGSize) -> CGPoint {
        let centerX = 0.5 * size.width
        let centerY = 0.5 * size.height
        return CGPoint(x: centerX, y: centerY)
    }
    
    private func getQuadrantCenter(for quadrant: Quadrant, in size: CGSize) -> CGPoint {
        let width = size.width
        let height = size.height
        switch quadrant {
        case Quadrant.topLeft:
            return CGPoint(x: width * 0.25, y: height * 0.25)
        case Quadrant.topRight:
            return CGPoint(x: width * 0.75, y: height * 0.25)
        case Quadrant.bottomLeft:
            return CGPoint(x: width * 0.25, y: height * 0.75)
        case Quadrant.bottomRight:
            return CGPoint(x: width * 0.75, y: height * 0.75)
        
        case Quadrant.center:
            return CGPoint(x: width * 0.5, y: height * 0.5)
        }
    }
    
    private func determineQuadrant(position: CGPoint, in size: CGSize) -> Quadrant {
        let midX = 0.5 * size.width
        let midY = 0.5 * size.height
        if position.x < midX {
            if position.y < midY {
                return .topLeft
            } else {
                return .bottomLeft
            }
        } else {
            if position.y < midY {
                return .topRight
            } else {
                return .bottomRight
            }
        }
    }
    
    private func distanceBetween(_ point1: CGPoint, _ point2: CGPoint) -> CGFloat {
        let dx = point2.x - point1.x
        let dy = point2.y - point1.y
        return sqrt(dx * dx + dy * dy)
    }

    private func updateQuadrantOccupancy(for podIndex: Int, quadrant: Quadrant) {
        if let existingPodIndex = occupiedQuadrants[quadrant], existingPodIndex != podIndex {
            hasQuadrantConflicts = true
        } else {
            occupiedQuadrants[quadrant] = podIndex
            hasQuadrantConflicts = checkForConflicts()
        }
    }
    
    private func isPodInQuadrant(_ quadrant: Quadrant) -> Bool {
        return playerPods.contains { $0.currentQuadrant == quadrant }
    }
    
    private func isPodPlaced(in quadrant: Quadrant) -> Bool {
        return playerPods.contains { $0.isPlaced && $0.currentQuadrant == quadrant }
    }

    private func totalPlacedPods() -> Int {
        return playerPods.map( { $0.isPlaced}).count(where: {$0==true})
    }
    
    private func hasConflict(at index: Int) -> Bool {
        guard let quadrant = playerPods[index].currentQuadrant else {
            return false
        }

        let podsInSameQuadrant = playerPods.filter { $0.currentQuadrant == quadrant }.count
        return podsInSameQuadrant > 1
    }
    
    private func checkForConflicts() -> Bool {
        var quadrantCounts: [Quadrant: Int] = [:]
        for pod in playerPods {
            if let quadrant = pod.currentQuadrant {
                quadrantCounts[quadrant, default: 0] += 1
                if quadrantCounts[quadrant]! > 1 {
                    return true
                }
            }
        }
        return false
    }
    
    private func checkPodsStatus() {
        if hasQuadrantConflicts {
            countdownActive = false
            holdCheckTimer?.invalidate()
            holdCheckTimer = nil
            return
        }
        let allPodsPlaced = self.totalPlacedPods() == numberOfPlayers
        if !hasQuadrantConflicts && !countdownActive && allPodsPlaced {
            startCountdown()
        } else if countdownActive && (hasQuadrantConflicts) {
            countdownActive = false
            countdownValue = 3
            holdCheckTimer?.invalidate()
            holdCheckTimer = nil
        }
    }
    
    
    @MainActor
    func startCountdown() {
        countdownActive = true
        
        let placedPods = totalPlacedPods()
        if placedPods != 1 && placedPods != numberOfPlayers {
            startRandomization()
        }
            countdownActive = false
            startRandomization()
        }
    
    
    func cancelCountdown() {
        viewModel.cancelCountdown()
    }
    
//    @MainActor
//    private func startSpinDown() {
//        
//        for i in playerPodsIndices {
//            playerPods[i].currentQuadrant = Quadrant(rawValue:i)
//            playerPods[i].isPlaced = true
//            occupiedQuadrants[ Quadrant(rawValue:i)! ] = i
//        }
//        randomizingActive = true
//        let delay = 0.02
//        spinCount = 0
//        let spinRange = Int.random(in: 24..<totalSpins)
//        //print(spinRange)
//        spinDownDelay(delay: delay, lastSpin: 0, maxSpin: spinRange)
//        
//        
//        
//        func spinDownDelay(delay: Double, lastSpin: Int, maxSpin: Int) {
//            guard lastSpin < maxSpin else {
//                let firstPlayerIndex = playerPods.map{$0.currentQuadrant?.rawValue}.firstIndex(where:{$0==randomHighlightedIndex})
//                self.selectWinner(firstPlayerIndex ?? 0)
//                return  }
//            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
//                randomHighlightedIndex = playerPodsIndices.randomElement()
//                //randomHighlightedIndex = (lastSpin + 1) % numberOfPlayers
//                let newDelay = min(delay * 1.1, maxInterval)
//                let newSpin = (lastSpin + 1)
//                spinDownDelay(delay: newDelay, lastSpin: newSpin, maxSpin: maxSpin)
//            }
//        }
//    }
//    
    
    
   //@MainActor
    private func startRandomization() {
        withAnimation{}
            randomizingActive = true
        
            spinCount = 0
            spinWithDelay(delay: initialInterval)
        
    }
    
    //@MainActor
    private func spinWithDelay(delay: Double) {
        guard spinCount < totalSpins else {
            let firstPlayerIndex = playerPods.map{$0.currentQuadrant?.rawValue}.firstIndex(where:{$0==randomHighlightedIndex})
            self.selectWinner(firstPlayerIndex ?? 0)
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            
            self.randomHighlightedIndex = playerPodsIndices.randomElement()
            //self.randomHighlightedIndex = Int.random(in: 0..<playerPods.count)
            spinCount += 1
            let newDelay = min(delay * 1.1, maxInterval)
            spinWithDelay(delay: newDelay)
        }
    }
  
    //@MainActor
    private func selectWinner(_ index: Int) {
        print("[Select Winner]")
        randomizingActive = false
        winnerSelected = true
        print("self.randomHighlightedIndex: \(self.randomHighlightedIndex)")
        
        if let winnerQuadrant = playerPods[index].currentQuadrant {
            winnerIndex = index
            print("winnerIndex: \(winnerIndex) | quad: ", playerPods[index].currentQuadrant)
            print("Setting InitGameValues from [FirstPlayerSelect]")
            UserDefaults.standard.set(winnerQuadrant.rawValue, forKey: "firstPlayer")
            self.showConfetti = true
        } else {
            print("[Confetti On]")
            self.showConfetti = true
            self.winnerIndex = self.randomHighlightedIndex!
            print("winnerIndex: \(winnerIndex) | quad: ", playerPods[index].currentQuadrant)
            UserDefaults.standard.set(self.randomHighlightedIndex!, forKey: "firstPlayer")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            print("[Confetti Off]")
            self.showConfetti = false
            navigateToGame = true
        }
    }
}


@MainActor
public final class CountdownViewModel: ObservableObject {
    @Published public var countdownValue = 5
    @Published public var countdownActive = false
    
    private var countdownTask: Task<Void, Never>?
    
    public func startCountdown() {
        countdownActive = true
        
        countdownTask = Task {
            while countdownValue > 1 {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                countdownValue -= 1
            }
            
            // Final step once countdown ends
            countdownActive = false
        }
    }
    
    public func cancelCountdown() {
        countdownTask?.cancel()
        countdownTask = nil
        countdownActive = false
    }

}


@MainActor
struct ChooseQuadPod: View {
    let hasConflict: Bool
    
    var body: some View {
        Circle()
            .fill(hasConflict ? Color.red : Color.white)
            .opacity( 0.7)
            .frame(width: 90, height: 90)
            .shadow(radius: 4)
 
    }
}
    


@MainActor
struct SelectionPod: View {
    let color: Color
    let emoji: String
    let highlighted: Bool
    let hasConflict: Bool
    var body: some View {
        ZStack {
            Circle()
                .fill(hasConflict ? Color.red : color)
                .opacity(highlighted ? 1.0 : 0.7)
                .frame(width: 90, height: 90)
                .shadow(radius: 4)
            Text(emoji)
                .font(.largeTitle)
            if highlighted {
                Circle()
                    .stroke(Color.white, lineWidth: 3)
                    .shadow(color: color, radius: 5)
                    .frame(width: 96, height: 96)
            }
            if hasConflict {
                Image(systemName: "exclamationmark.circle")
                    .font(.system(size: 24))
                    .foregroundColor(Color.white)
                    .offset(y: -30)
            }
        }
        .scaleEffect(highlighted ? 1.2 : 1.0)
        .animation(.spring(), value: highlighted)
    }
}

@MainActor
struct ConfettiView: View {
    //var winnerQuadrant: Quadrant
    var explosionCenter: CGPoint
    @State private var particles: [ConfettiParticle] = []
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                        .onAppear {
                            withAnimation(.easeOut(duration: particle.duration)) {
                                if let index = particles.firstIndex(where: { $0.id == particle.id }) {
                                    particles[index].position = particle.endPosition
                                    particles[index].opacity = 0
                                }
                            }
                        }
                }
            }
            .onAppear {
                let _ = print("Confetti started 🎉")
                let _ = print("\(explosionCenter))")
                generateConfetti(in: geometry.size, at: explosionCenter)
            }
        }
    }
    
    private func generateConfetti(in size: CGSize, at center: CGPoint) {
        let colors: [Color] = [.red, .yellow, .blue, .green, .pink, .purple]
        var newParticles: [ConfettiParticle] = []
        let quadrantCenter = center
        for _ in 0..<150 {
            let randomSize = CGFloat.random(in: 5...15)
            let startingPoint = CGPoint(
                x: quadrantCenter.x + CGFloat.random(in: -50...50),
                y: quadrantCenter.y + CGFloat.random(in: -50...50)
            )
            let endPosition = CGPoint(
                x: startingPoint.x + CGFloat.random(in: -150...150),
                y: startingPoint.y + CGFloat.random(in: -150...150)
            )
            let duration = Double.random(in: 1.0...2.0)
            let particle = ConfettiParticle(
                id: UUID(),
                color: colors.randomElement()!,
                size: randomSize,
                position: startingPoint,
                endPosition: endPosition,
                opacity: 1,
                duration: duration
            )
            newParticles.append(particle)
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                if let index = particles.firstIndex(where: { $0.id == particle.id }) {
                    particles.remove(at: index)
                }
            }
        }
        particles = newParticles
    }
    
    private func getQuadrantCenter(for quadrant: Quadrant, in size: CGSize) -> CGPoint {
        let width = size.width
        let height = size.height
        switch quadrant {
        case Quadrant.topLeft:
            return CGPoint(x: width * 0.25, y: height * 0.25)
        case Quadrant.topRight:
            return CGPoint(x: width * 0.75, y: height * 0.25)
        case Quadrant.bottomLeft:
            return CGPoint(x: width * 0.25, y: height * 0.75)
        case Quadrant.bottomRight:
            return CGPoint(x: width * 0.75, y: height * 0.75)
        case Quadrant.center:
            return CGPoint(x: width * 0.5, y: height * 0.5)
        }
    }
}


struct ConfettiParticle: Identifiable {
    let id: UUID
    let color: Color
    let size: CGFloat
    var position: CGPoint
    let endPosition: CGPoint
    var opacity: Double
    let duration: Double
}





#Preview {
    FirstPlayerSelectionView(podPlayers: [true,true,false,true])
}

#Preview {
    ConfettiView( explosionCenter: CGPoint(x: 50, y:50))
}
