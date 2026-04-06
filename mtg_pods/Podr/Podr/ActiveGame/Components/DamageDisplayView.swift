import SwiftUI
import Podwork


public struct txtConst {
    public static let frameSize: Double = 24.0
}

struct DeltaRowStyleView: View {
    let text: String
    let color: Color
    let fontSize: CGFloat = 30.0
    var body: some View {
        Text("\(text)")
        //.font(.system(size: fontSize, weight: .semibold, design: .default))
            .font(.title)
            .bold()
            .fontWeight(.heavy)
            .foregroundStyle(color.gradient)
            .customStroke(color: Color.black, width: 0.50)
            .minimumScaleFactor(0.1)
            .lineLimit(1)
    }
}



/// In Use Method to Display CMDR dmg (in square box)
struct PodCommanderPartnerDamageView: View {
    let cmdrDmg: Int
    let color: Color
    let active: Bool
    var body: some View {
        Text("\(cmdrDmg)")
        //.font(.system(size: fontSize, weight: .bold, design: .default))
            .font(.title)
            .bold()
            .customStroke(color: Color.black, width: 0.50)
            .minimumScaleFactor(0.1)
            .lineLimit(1)
            .padding([.horizontal],3)
            .foregroundColor( active ? Color.white.opacity(1.0) : color)
            .frame(width: txtConst.frameSize, height: txtConst.frameSize)
            .background(active ? color : Color.white.opacity(1.0) )
            .minimumScaleFactor(0.1)
            .lineLimit(1)
            .border(Color.black, width:1)
        
    }
}


struct PodCommanderDamageView: View {
    let cmdrDmg: Int
    let color: Color
    var body: some View {
        Text("\(cmdrDmg)")
        //.font(.system(size: fontSize, weight: .bold, design: .default))
            .font(.title3)
            .bold()
            .customStroke(color: Color.black, width: 0.50)
            .minimumScaleFactor(0.1)
            .lineLimit(1)
            .padding([.horizontal],3)
            .foregroundColor(Color.white.opacity(1.0))
            .frame(width: txtConst.frameSize, height: txtConst.frameSize)
            .background(color)
            .minimumScaleFactor(0.1)
            .lineLimit(1)
            .border(.black, width:1)
    }
}


    /*
public var body: some View {
    HStack(spacing:0){
        
        Text("+")
        Text(dmgNumber)
    }
    .font(.headline)
    .monospacedDigit()
    //.bold()
    .fontWeight(.heavy)
    .foregroundColor( cmdr.activeCmdrIndex == prtnrCmdrIndex ? Color.white : getColor(for: cmdr.playerIndex)
    )
    .customStroke(color: Color.black, width: 0.750)
    .customStroke(color: cmdr.activeCmdrIndex == prtnrCmdrIndex ? getColor(for: cmdr.playerIndex) :  Color.white, width: 0.750)
    .customStroke(color: Color.black, width: 0.750)
    .opacity( showOpacity )
}
*/
struct PodDeltaCmdrDamageView: View {
    let cmdrDmg: Int
    let cmdrID: Int
    let fontSize: CGFloat = 26.0
    var body: some View {
        HStack(spacing:0){
            Text(" ")
            Text("\(cmdrDmg)")
        }
        .font(.system(size: fontSize, weight: .bold, design: .default))
            .monospacedDigit()
            .minimumScaleFactor(0.9)
            .lineLimit(1)
        //.bold()
            .fontWeight(.bold)
            .foregroundStyle(    getColor(for: cmdrID).gradient )
            .customStroke(color: Color.black, width: 0.750)
            .customStroke(color: getColor(for: cmdrID).opacity(0.5), width: 0.750)
            .customStroke(color: Color.black, width: 0.750)
            //.opacity( showOpacity )
    }
}



struct PlayerLifeTotalStyleView: View {
    let life: Int
    let scale: Double?
    var checkScale: Bool { guard scale != nil else {return false}
    return true}
    var scaleBy: Double { guard checkScale else {return 1.0}
        return scale!}
    var strike : Bool
    
    init(life: Int, scale: Double? = nil, strike: Bool? = nil) {
        self.life = life
        self.scale = scale
        self.attributedString = AttributedString("\(life)")
        self.strike = strike != nil ? strike ?? false : false
    }
    
    var attributedString : AttributedString
    
    var body: some View {
        Text( "\(life)" )
            .font(.system(size: scaleBy*50, weight: .semibold, design: .default))
            .foregroundStyle( Color.white )
            .strikethrough(self.strike, color: Color.red)
            .customStroke(color: Color.black, width: 1.20)
        //.shadow(color: .black.opacity(1.0), radius: 0.5)
            .minimumScaleFactor(0.8)
            .lineLimit(1)
    }
}



struct SumChangeToLifeStyleView: View {
    let lifeAtTurnStart: Int
    let sumDeltaDmg: Int
    let fontSize: CGFloat = 20.0
    var body: some View {
        let sign = sumDeltaDmg <= 0 ? "-" : "+"
        let newTotalLife = lifeAtTurnStart + sumDeltaDmg
        HStack (alignment: .lastTextBaseline, spacing:0) {
            Text("\(sign)\(abs(sumDeltaDmg))")
            //.font(.system(size: fontSize, weight: .heavy, design: .default))
            //.bold()
                .font(.title3)
                .bold()
                .foregroundColor(sumDeltaDmg < 0 ? Color.red : Color.cyan)
                .customStroke(color: Color.black, width: 0.50)
                .minimumScaleFactor(0.1)
                .lineLimit(1)
            
            Text("  =  \(newTotalLife)")
            //.font(.system(size: fontSize, weight: .bold, design: .default))
                .font(.title3)
                .bold()
            //.foregroundColor(Color(white: 0.1745))
                .foregroundColor(Color(white: 0.5))
                .customStroke(color: Color.black, width: 0.50)
                .minimumScaleFactor(0.1)
                .lineLimit(1)
        }
    }
}



struct DamageDisplayView: View {
    @Bindable var game: GameState
    var current_player: Int
    var body: some View {
        VStack (alignment: .leading) {
            let deltaDamage = game.showDeltaLife(playerID: current_player)
            let currentTurnLife = game.showLife(playerID: current_player)
            let sumDeltaDmg = game.showSumDeltaLife(playerID: current_player)
            
            HStack (alignment: .lastTextBaseline, spacing:6) {
                
                VStack(alignment: .trailing, spacing:0){
                    if deltaDamage != 0 {
                        DeltaRowStyleView(text:"Δ( \(deltaDamage) )", color: deltaDamage < 0 ? Color.indigo : Color.cyan )
                    }
                    PlayerLifeTotalStyleView(life: currentTurnLife)
                }
                .minimumScaleFactor(0.1)
                .lineLimit(1)
                
                if sumDeltaDmg != 0 {
                    SumChangeToLifeStyleView(lifeAtTurnStart: currentTurnLife, sumDeltaDmg: sumDeltaDmg)
                        .minimumScaleFactor(0.1)
                        .lineLimit(1)
                }
            }
            
        }
        .padding([.top, .bottom], 0)
    }
}




struct LifePlusOrMinusSumEqualsView: View {
    let lifeAtTurnStart: Int
    let sumDeltaDmg: Int
    let fontSize: CGFloat = 30.0
    
    init(lifeAtTurnStart: Int, sumDeltaDmg: Int) {
        self.lifeAtTurnStart = lifeAtTurnStart
        self.sumDeltaDmg = sumDeltaDmg
        
        // Add Commander Damage inline to this
        // - Remove the delta-cmdr-damage from total labels
    }
    
    var body: some View {
        let sign = sumDeltaDmg <= 0 ? "-" : "+"
        let newTotalLife = lifeAtTurnStart + sumDeltaDmg
        HStack (alignment: .lastTextBaseline, spacing:5) {
           // DeltaRowStyleView(text: "(", color: sumDeltaDmg <= 0 ? Color.red : Color.cyan)
            
            /*
            Text("\(lifeAtTurnStart)")
                //.font(.title)
            //.font(.system(size: fontSize, weight: .bold, design: .default))
                .font(.system(size: 0.666*fontSize, weight: .heavy, design: .rounded))
                //.bold()
                .fontWeight(.heavy)
                .foregroundStyle(Color.brown.gradient)
                .customStroke(color: Color.black, width: 0.50)
                .minimumScaleFactor(0.1)
                .lineLimit(1)
            */
            
            if sumDeltaDmg != 0 {
                
                HStack(spacing:0){
                    Text("\(sign)")
                        .minimumScaleFactor(0.81)
                    
                    Text("\(abs(sumDeltaDmg))")
                        .minimumScaleFactor(0.1)
                }
                .font(.title)
                .fontWeight(.heavy)
                .foregroundStyle(sumDeltaDmg <= 0 ? Color.red.gradient : Color.cyan.gradient)
                .customStroke(color: Color.black, width: 0.50)
                .lineLimit(1)
          
            }
            
           // DeltaRowStyleView(text: ")", color: sumDeltaDmg <= 0 ? Color.red : Color.cyan)
       
        }
        
    }
}



/// In Use Method for Regular Damage
struct DisplayDamageView: View {
    @Bindable var game: GameState
    var current_player: Int
    let deltaDamage: Int
    let currentTurnLife: Int
    let sumDeltaDmg: Int
    let lifeAfterDmg: Int
    let sumDeltaCmdrDmg: Int
    
    init(game: GameState, current_player: Int) {
        self.game = game
        self.current_player = current_player
        
        deltaDamage = game.showDeltaLife(playerID: current_player)
        currentTurnLife = game.showLife(playerID: current_player)
        sumDeltaDmg = game.showSumDeltaLife(playerID: current_player)
        lifeAfterDmg = currentTurnLife + sumDeltaDmg
        sumDeltaCmdrDmg = game.getDeltaCmdrDamagesFromAllPlayers(for: current_player).reduce(0, +)
    }
    var body: some View {

        VStack (alignment: .center) {
   
            
            VStack(spacing: -8) {
              
                HStack (alignment: .lastTextBaseline, spacing:6) {
                    
                    if sumDeltaDmg != 0 || sumDeltaCmdrDmg != 0 {
                        //  Damage Deltas Moved above the Pod
                        HStack(alignment: .center, spacing:0){
                            if sumDeltaDmg != 0 {
                            LifePlusOrMinusSumEqualsView(lifeAtTurnStart: currentTurnLife, sumDeltaDmg: deltaDamage)
                            }
                            
                            if sumDeltaCmdrDmg != 0 {
                                ForEach(Array(game.getDeltaCmdrDamagesFromAllPlayers(for: current_player).enumerated()), id:\.offset){ idx,cmdrDmg in
                                    let _ = print( "\(cmdrDmg)")
                                    if cmdrDmg != 0 {
                                        PodDeltaCmdrDamageView(cmdrDmg: cmdrDmg, cmdrID: idx)
                                        
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, PodableTheme.spacingS)
                        .background(Capsule()
                            .fill(Color(.tertiarySystemFill).gradient.opacity(0.99))
                            .clipShape(Capsule()))
                        //.minimumScaleFactor(0.1)
                        //.lineLimit(1)
                        //.offset(y: deltaDamage > 0 ?  2.250*GameUIConstants.podSize :  -1.250*GameUIConstants.podSize  )
                        .offset(y: -1.1250*GameUIConstants.podSize  )
                    }
                    
                    if sumDeltaDmg == 0 && sumDeltaCmdrDmg == 0 {
                            PlayerLifeTotalStyleView(life: currentTurnLife)
                          
                    }
                    
                }
                
                // Prev Life with Strikethrough  with  New Life Below
                if sumDeltaDmg != 0 || sumDeltaCmdrDmg != 0 {
                    VStack(spacing:-8){
                        PlayerLifeTotalStyleView(life: currentTurnLife, scale: 0.5, strike: true)
                        
                        PlayerLifeTotalStyleView(life: lifeAfterDmg, scale: 1.2)
                            .minimumScaleFactor(0.1)
                            .lineLimit(1)
                    }
                }
                
            }
        
            
        }
        .padding([.top, .bottom], 0)
        //.frame(maxHeight: .infinity)
    }
}



struct DamageDisplayView_Previews: PreviewProvider {
    static var previews: some View {
        let s = GameState()
        s.removeDamage(from: 1, to: 2, as: true)
        s.removeDamage(from: 3, to: 2, as: true)
        s.removeDamage(from: 3, to: 2, as: true)
        s.removeDamage(from: 3, to: 2, as: false)
        s.applyDamage(from: 1, to: 2, as: false)
        s.applyDamage(from: 1, to: 2, as: false)
        s.applyDamage(from: 1, to: 2, as: false)
        s.applyDamage(from: 1, to: 2, as: false)
        s.applyDamage(from: 1, to: 2, as: false)
        s.applyDamage(from: 1, to: 2, as: false)
        
        
        return VStack {
            DeltaRowStyleView(text: "Δ(    )", color: .indigo)
            PodCommanderDamageView(cmdrDmg: 15, color: .red)
                .padding()
                .border(.green)
            PodDeltaCmdrDamageView(cmdrDmg: 15, cmdrID: 1)
            PlayerLifeTotalStyleView(life: 105)
            SumChangeToLifeStyleView(lifeAtTurnStart: 40, sumDeltaDmg: 20)
            DamageDisplayView(game: s, current_player: 2)
                .border(Color.green)
            DisplayDamageView(game: s, current_player: 2)
                .border(Color.blue)
        }
    }
}
