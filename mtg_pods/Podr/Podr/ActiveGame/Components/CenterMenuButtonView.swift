import SwiftUI
import Podwork


@MainActor
struct CenterMenuButton: View {
    @Binding var bombModeActive: Bool
    @Binding var turnNumber: Int
    @Binding var isRotated: Bool
    @Binding var tutorialMode: Bool
    let onNextTurn: () -> Void
    let onReturn:  ((Int, EliminationMethod) -> Void)
    let onApplyDamage: (() -> Void)
    let onResetTurn: () -> Void
    let onExtraTurn: ((Int) -> Void)
    let onReturnToMain: (() -> Void)
    
    @State private var containerSize: CGSize =  UIScreen.main.bounds.size
    @State private var showResetConfirmation = false
    @State private var viewModel = TurnCycleViewModel()
    
    @State public var isMenuShowing  = false
    @State public var isHolding = false
    
    @GestureState private var isDetectingLongPress = false
    
    
    // ---------
    @State var initialPosition: CGPoint = .zero
    @GestureState private var dragOffset: CGSize = .zero  // Add @GestureState
    @State var lastDroppedQuadrant: Quadrant? = nil
    @State var bombQuadrantIndex = 0
    @State public var showBombMenu: Bool = false

    
    
    
    @ViewBuilder
    var body: some View {
        
        /*
        let bombPod = BombPodContainer(
            bombModeActive: $bombModeActive,
            initialPosition: CGPoint(
                x: 0.5*containerSize.width,
                y: 0.5*containerSize.height
            ),
            isRotated: $isRotated,
            onReturn: onReturn,
            onResetTurn: onResetTurn,
            onExtraTurn: onExtraTurn,
            viewModel: viewModel,
            showBombMenu: $isMenuShowing,
            turnNumber: turnNumber
        )
        */
        
        let bombPod = StarPodView(
            viewModel: viewModel,
            bombPod: bombModeActive,
            initialPosition: initialPosition
        )
        
        /// Gestures stacked to allow for haptic feedback after 1 second and 3 seconds before return menu
        let threeSecondPress = LongPressGesture(minimumDuration: 1)
            .updating($isDetectingLongPress) { currentState, gestureState, transaction in
                gestureState = currentState
                print("started 2sec long press")
            }
            .onEnded{ value in
                //isHolding = false
                if !bombModeActive {
                    HapticFeedback.impact()
                    HapticFeedback.impact()
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.warning)
                    showResetConfirmation = true
                }
            }
        
        let oneSecondPress = LongPressGesture(minimumDuration: 1)
            .updating($isDetectingLongPress) { currentState, gestureState, transaction in
                gestureState = currentState
                print("started 1sec long press")
            }
            .onEnded{ value in
                print("untapped 1sec long press")
                HapticFeedback.impact()
                // isHolding = true
            }
        
        let combined = oneSecondPress.sequenced(before: threeSecondPress)
        
        
        if showBombMenu, let quad = lastDroppedQuadrant {
            CenterPodMenuView(bombModeActive: $bombModeActive,
                              isRotated: $isRotated,
                              showBombMenu: $showBombMenu,
                              turnNumber: turnNumber,
                              onReturn: onReturn,
                              onResetTurn: onResetTurn,
                              onExtraTurn: onExtraTurn,
                              lastDroppedQuadrant: lastDroppedQuadrant
                              
            )
                .rotationEffect(Angle(degrees: PlayerLayoutConfig.config(for: bombQuadrantIndex).rotationAngle), anchor: .center)
                .frame(width: 0.5*containerSize.width, height: 0.5*containerSize.height)
                .position(centerPoint(for: quad, in: containerSize))
                .transition(.opacity)
                .zIndex(20)
        }
        
        
        
        
        bombPod

            .onTapGesture(count: 2) {
                // isHolding = false
                /// Disable double tapping in bomb pod menu
                if isMenuShowing { return }
                withAnimation {
                    if bombModeActive {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        onApplyDamage()
                        
                    } else {
                        onNextTurn()
                        viewModel.currentTurn = turnNumber
                        showBombMenu = false
                        //bombPod.showBombMenu = false
                        startText(msg: "Turn\n\(turnNumber)")
                    }
                }
            }

            .onTapGesture(count: 1) {
                // isHolding = false
                print("tapped once")
                if bombModeActive{ withAnimation { bombModeActive.toggle() } }
            }
        
            .gesture(combined)
            .alert(isPresented: $showResetConfirmation) {
                if !tutorialMode {
                    Alert(
                        title: Text("Return to Main Menu?"),
                        message: Text("Are you sure you want to exit back to the main menu?\nThe pod will NOT be logged."),
                        primaryButton: .destructive(Text("EXIT")) {
                            onReturnToMain()
                        },
                        secondaryButton: .cancel()
                    )}
                else {
                    Alert(
                        title: Text("Finish Tutorial"),
                        message: Text("Ready to Start the Game?"),
                        primaryButton: .destructive(Text("PLAY")) {
                            tutorialMode = false
                            viewModelSetup()
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
            .onAppear { HapticFeedback.impact(.medium) }
        
        
            .offset(dragOffset)  // Use the @GestureState directly
            .gesture(
                DragGesture(minimumDistance: 0.5*PodworkUIConstants.bombPodSize)
                    .updating($dragOffset) { value, state, transaction in
                        // Update the gesture state
                        state = value.translation
                        // Disable animations for smooth dragging
                        transaction.animation = nil
                    }
                    .onEnded { value in
                        // The total vector of the drag
                        let dragVector = CGPoint(x: value.translation.width, y: value.translation.height)
                        
                        // The final position on screen
                        let finalPosition = CGPoint(
                            x: initialPosition.x + value.translation.width,
                            y: initialPosition.y + value.translation.height
                        )
                        
                        print("Drag vector: \(dragVector)")
                        print("Final position: \(finalPosition)")
                        
                        handleDrop(locations: [finalPosition, dragVector], geometry: containerSize)
                    }
            )
            .position(initialPosition)
            .compositingGroup()
            .opacity(showBombMenu ? 0.0 : 1.0)
        
        
            .onChange(of: turnNumber) {
                viewModel.currentTurn = turnNumber
                startText(msg: "Turn\n\(turnNumber)")
            }
            .containerRelativeFrame(.horizontal)
            .containerRelativeFrame(.vertical)
        
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            containerSize = geometry.size
                        }
                        .onChange(of: geometry.size) { _, newSize in
                            containerSize = newSize
                        }
                }
            )
            .onAppear(
                perform: { viewModelSetup()
                    initialPosition = CGPoint(
                        x: 0.5*containerSize.width,
                        y: 0.5*containerSize.height
                    )
                }
            )
    }
    
    mutating func changeShowBombMenu(_ val : Bool){
        showBombMenu = val
    }
    
    func viewModelSetup(){
        viewModel.isRotated = isRotated
        viewModel.rotatedAngle = isRotated ? 180 : 0
        viewModel.nonRotatedAngle = isRotated ? 0 : 0
        viewModel.startCycle(for: tutorialMode ? "Tutorial\n✨Mode" : "Pod✨\nSetup")
    }

    
    public func startText(msg: String) {
        //viewModel.symbol = bombModeActive ? "💣" : "✨"
        viewModel.stopCycle()
        viewModel.endSetupPhase()
        viewModel.startCycle(for: msg)
        let rotation = isRotated
        viewModel.previousRotation = viewModel.isRotated
        viewModel.isRotated = rotation
        viewModel.applyRotation()
        viewModel.endSetupPhase()
    }
    
    func handleDrop(locations: [CGPoint], geometry: CGSize) {
        let location = locations[0]
        let distance = hypot(location.x , location.y )
        let buttonSize: CGFloat = GameUIConstants.bombPodSize
        
        if distance < buttonSize {
            //showBombMenu = false
            //changeShowBombMenu( false)
            if let quadrant = determineQuadrant(from: location, in: containerSize ) {
                lastDroppedQuadrant = quadrant
                bombQuadrantIndex = quadrant.rawValue
            }
            
        } else if let quadrant = determineQuadrant(from: location, in: geometry),
                  isNearQuadrantCenter(location, in: geometry, for: quadrant) {
            withAnimation(.spring(duration: 0.333)) {
                showBombMenu = true
                lastDroppedQuadrant = quadrant
                bombQuadrantIndex = quadrant.rawValue
            }
        } else {
            withAnimation(.spring(duration: 0.333)) {
                showBombMenu = false
                lastDroppedQuadrant = nil
            }
        }
    }
    
    private func determineQuadrant(from location: CGPoint, in geometry: CGSize) -> Quadrant? {
        let centerX = 0.5*geometry.width
        let centerY = 0.5*geometry.height
        
        if location.x < centerX && location.y < centerY {
            return Quadrant.topLeft
        } else if location.x >= centerX && location.y < centerY {
            return Quadrant.topRight
        } else if location.x < centerX && location.y >= centerY {
            return Quadrant.bottomLeft
        } else if location.x >= centerX && location.y >= centerY {
            return Quadrant.bottomRight
        } else {
            return nil
        }
    }
    
    
    func isNearQuadrantCenter(_ location: CGPoint, in geometry: CGSize, for quadrant: Quadrant) -> Bool {
        let buttonSize: CGFloat = GameUIConstants.bombPodSize
        let center = centerPoint(for: quadrant, in: geometry)
        return hypot(location.x - center.x, location.y - center.y) < buttonSize
    }
    
    
}


public func centerPoint(for quadrant: Quadrant, in geometry: CGSize) -> CGPoint {
    let w =  geometry.width
    let h = geometry.height
    let quarterW = 0.25*w
    let quarterH = 0.25*h
    
    switch quadrant {
    case Quadrant.topLeft: return CGPoint(x: quarterW, y: quarterH)
    case Quadrant.topRight: return CGPoint(x: 3 * quarterW, y: quarterH)
    case Quadrant.bottomLeft: return CGPoint(x: quarterW, y: 3 * quarterH)
    case Quadrant.bottomRight: return CGPoint(x: 3 * quarterW, y: 3 * quarterH)
    case Quadrant.center: return CGPoint(x: 2 * quarterW, y: 2 * quarterH)
    }
}




///////////================================================
/*
#Preview {
    GeometryReader { geometry in
        // State for preview
        StatefulPreviewWrapper((true,1)) { bombMode in
            
            CenterMenuButton(
                
                bombModeActive: bombMode.0,
                turnNumber: bombMode.1,
                isRotated:  bombMode.0,
                tutorialMode: bombMode.0,
                onNextTurn: {
                    print("Next turn triggered")
                },
                onReturn: { (playerIndex, eliminationMethod) in
                        print("Player \(playerIndex) : \(eliminationMethod)")
                },
                onApplyDamage: {
                    print("Bomb damage: test")
                },
                onResetTurn: {
                    print("Reset Turn triggered")
                },
                onExtraTurn: { idx in
                    print("Extra turn")
                },
                onReturnToMain: {}
            )
        }
    }
    
}
*/

struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State private var value: Value
    var content: (Binding<Value>) -> Content
    
    init(_ initialValue: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        self._value = State(initialValue: initialValue)
        self.content = content
    }
    
    var body: some View {
        content($value)
    }
}
