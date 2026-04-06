import SwiftUI
import Podwork


public struct CenterPodMenuView: View {
    @Binding var bombModeActive: Bool
    @Binding var isRotated: Bool
    @Binding public var showBombMenu: Bool
    @State var turnNumber: Int
    
    var onReturn:  ((Int, EliminationMethod) -> Void)?
    var onResetTurn: (()->Void)? = nil
    var onExtraTurn: ((Int) -> Void)?
    
    @State var lastDroppedQuadrant: Quadrant? = nil
    //@State var bombQuadrantIndex = 0
    
    @State var menu: MenuSelectOptions = MenuSelectOptions()

    @State var containerSize: CGSize = UIScreen.main.bounds.size
    
    @State var onResult: [Int : EliminationMethod] = [:]


    var bombQuadrantIndex : Int {
        guard lastDroppedQuadrant != nil else {return 0}
        return lastDroppedQuadrant!.rawValue
    }

    // Grab player check fom User Defaults - if not set, assume not playing
    var checkPlayer : Bool {
        let playable = UserDefaults.standard.array(forKey: "podPlayers") as? [Bool]
        guard playable != nil else {return false}
        guard playable!.count > bombQuadrantIndex else {return false}
        return playable![bombQuadrantIndex]
    }
        
    public var body: some View {
        
        ZStack{
            Rectangle( )
                .fill( bombModeActive ? AnyShapeStyle(Color.black.opacity(0.64)) : AnyShapeStyle(Color.black.opacity(0.64)))
            VStack{
                
                
                //// Bomb Mode Inactive
                /// ----------------------------------
                if !bombModeActive {
                    
                    //// Turns
                    /// ----------------------------------
                    if !menu.isTurnSelected && !menu.isAltWinsSelected   {
                        Menu{
                            Button("Select Turn"){ menu.showTurnOptions = true}} label: {
                                Label("Turn Menu", systemImage: "arrow.trianglehead.2.clockwise.rotate.90.page.on.clipboard")
                                    .minimumScaleFactor(0.75)
                                    .lineLimit(1)
                                    .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 30))
                                
                                //Spacer()
                            } primaryAction: {
                                menu.showTurnOptions = true
                                menu.showAltWinMenu = false
                                menu.showLossOptions = false
                                print(menu)
                                
                            }
                            .padding(.top)
                        
                        
                        Divider()
                            .padding(.vertical)
                    }
                    
                    
                    
                    
                    if menu.isTurnSelected {
                        Button(action: {
                            print(menu)
                            print("undo turn selected")
                            showBombMenu = false
                            onResetTurn?()
                            
                        }, label: { Label {
                            Text("Undo Turn")
                                .minimumScaleFactor(0.75)
                                .lineLimit(1)
                                .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 30))
                            
                        } icon: {
                            Image(systemName: "arrow.trianglehead.counterclockwise")
                        } } )
                        .padding(.top)
                        
                        
                        
                        Divider()
                            .padding(.vertical)
                        
                        
                        
                        Button(action: {
                            print(menu)
                            
                            print("extra turn selected")
                            showBombMenu = false
                            onExtraTurn?(bombQuadrantIndex)
                            
                        }, label: { Label {
                            Text("Extra Turn")
                                .minimumScaleFactor(0.75)
                                .lineLimit(1)
                                .strikethrough(!checkPlayer, color: Color.red)
                                .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 30))
                            
                        } icon: {
                            Image(systemName: "plus.arrow.trianglehead.clockwise")
                        } } )
                        .disabled(!checkPlayer)
                        
                        
                    }
                    
                    
                    //// Alt Wins
                    /// ----------------------------------
                    if !menu.isAltWinsSelected && !menu.isTurnSelected  {
                        Menu{
                            Button("Declare Win"){ menu.showAltWinMenu = true
                            }} label: {
                                Label("Declare Win", systemImage: "trophy.circle")
                                    .minimumScaleFactor(0.75)
                                    .lineLimit(1)
                                    .strikethrough(!checkPlayer, color: Color.red)
                                    .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 20))
                                //Spacer()
                            } primaryAction: {
                                
                                menu.showAltWinMenu = true
                                menu.showTurnOptions = false
                                menu.showLossOptions = false
                                print(menu)
                                print("Alt Win selected")
                                
                            }
                            .padding(.top)
                            .disabled(!checkPlayer)
                    }
                    
                    
                    
                    if menu.isAltWinsSelected {
                        Button(action: {
                            print(menu)
                            showBombMenu = false
                            onReturn?( bombQuadrantIndex, EliminationMethod.altWin)
                        }, label: { Label {
                            Text("Alt Win\nCondition")
                                .minimumScaleFactor(0.75)
                                .lineLimit(2)
                                .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 20))
                            
                        } icon: {
                            Image(systemName: "trophy")
                        } } )
                        .padding(.top)
                        
                    }
                    
                    
                }
                
                //// Bomb Mode Active
                /// ----------------------------------
                else if bombModeActive {
                    
                    //// Loss
                    /// ----------------------------------
                    
                    
                    if !menu.isLossSelected {
                        
                        /// Only allow Empty Seat in Early Game
                        if turnNumber < 2{
                            Button(action: {
                                showBombMenu = false
                                onReturn?(bombQuadrantIndex, EliminationMethod.emptySeat)
                                
                            }, label: { Label {
                                Text("No Player")
                                    .minimumScaleFactor(0.85)
                                    .lineLimit(1)
                                    .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 30))
                                
                            } icon: {
                                EliminationMethod.emptySeat.displayEmoji
                            } } )
                            .padding(.top)
                            //.disabled(viewModel.currentTurn >= 3)
                            
                            
                            Divider()
                                .padding(.vertical)
                        }
                        
                        Button(action: {
                            showBombMenu = false
                            onReturn?(bombQuadrantIndex, EliminationMethod.concede)
                            
                        }, label: { Label {
                            Text("Concede")
                                .minimumScaleFactor(0.95)
                                .lineLimit(1)
                                .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 40))
                            
                        } icon: {
                            EliminationMethod.concede.displayEmoji
                        } } )
                        
                        
                        
                        Divider()
                            .padding(.vertical)
                        
                        
                        Button(action: {
                            showBombMenu = false
                            onReturn?(bombQuadrantIndex, EliminationMethod.milled)
                            
                        }, label: { Label {
                            Text("Deck Milled")
                                .minimumScaleFactor(0.95)
                                .lineLimit(1)
                                .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 30))
                        } icon: {
                            EliminationMethod.milled.displayEmoji
                        } } )
                    }
                    
                }
                //// Back
                /// ----------------------------------
                
                Divider()
                    .padding(.vertical)
                
                Menu{
                    
                    Button("Cancel", role: .cancel){
                        menu.showAltWinMenu = false
                        menu.showTurnOptions = false
                        menu.showLossOptions = false
                        showBombMenu = false
                    }
                } label: {
                    Label("Cancel", systemImage: "xmark.circle")
                        .minimumScaleFactor(0.95)
                        .lineLimit(1)
                        .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 60))
                    
                } primaryAction: {
                    withAnimation(.spring(duration: 0.5)) {
                        showBombMenu = false
                        menu.showAltWinMenu = false
                        menu.showTurnOptions = false
                        menu.showLossOptions = false
                        bombModeActive = false
                    }
                }
                .padding(.bottom)
                
            }
            
            
            .containerRelativeFrame(.horizontal, count:2, spacing: 50.0)
            .contentMargins(.horizontal, 40.0)
            .foregroundColor(bombModeActive ? Color.black : Color.black)
            .bold()
            .background(bombModeActive ? Color.red : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 30.0))
        }
    }
}


struct MenuSelectOptions {
    var showAltWinMenu = false
    var showTurnOptions: Bool = false
    var showLossOptions = false
    
    var isTurnSelected: Bool {
        let selectedOptions = (showTurnOptions && !showAltWinMenu  && !showLossOptions)
        return selectedOptions
    }
    
    var isAltWinsSelected: Bool {
        let selectedOptions = ( showAltWinMenu && !showTurnOptions && !showLossOptions)
        return selectedOptions
    }
    
    
    var isLossSelected: Bool {
        let selectedOptions = ( showLossOptions && !showAltWinMenu && !showTurnOptions )
        return selectedOptions
    }
}
