import SwiftUI
import Podwork

public struct CommanderNameBar: View {
    let labels: [String]
    let selectedIndex: Int
    var activeColor: Color
    var inactiveColor: Color = Color.white
    let leftRight: Bool
    let cmdrTaxes: [Int]
    let tapAction: (Int) -> Void
    let holdAction: (Int) -> Void
    
    var secondColor: Color = Color(.secondarySystemFill)

    
    public init(labels:[String], selectedIndex:Int, activeColor:Color, leftRight:Bool, cmdrTaxes: [Int], tapAction:  (@escaping(Int) -> Void), holdAction: (@escaping(Int)->Void) ) {
        self.labels = labels
        self.selectedIndex = selectedIndex
        self.activeColor = activeColor
        self.inactiveColor = Color.white
        self.leftRight = leftRight
        self.cmdrTaxes = cmdrTaxes
        self.tapAction = tapAction
        self.holdAction = holdAction
    }
    
   @ViewBuilder
    var taxLabels : some View {
        if cmdrTaxes == [0] || cmdrTaxes == [0,0] {
            Text(" Tax ")
                .foregroundStyle(Color.black.gradient)
                .padding(.horizontal, 8)
                .background(Capsule().stroke(Color.black, lineWidth:3).fill(Color.white.gradient))
        }
        else if cmdrTaxes.count == 1 {
            Text("\(cmdrTaxes.first!)")
                .foregroundStyle(Color.black.gradient)
                .padding(.horizontal, 8)
                .background(Capsule().stroke(Color.black, lineWidth:3).fill(activeColor.gradient.opacity(0.25)))
        }
        else if cmdrTaxes.count == 2 {
            
            HStack(spacing:-2){
                Text("\(cmdrTaxes[0])")
                    .foregroundStyle(Color.black.gradient )
                    .bold(selectedIndex == 0 ? true : false)
                    .padding(.horizontal, 8)
                    .background(
                        Capsule().stroke(selectedIndex == 0 ? Color.black : Color.clear, lineWidth:2)
                            .fill( selectedIndex == 0 ? activeColor.gradient.opacity(0.25) :  Color.gray.gradient.opacity(0.250) )
                    )
                    .zIndex( selectedIndex == 0 ? 1.1 : 0.9)
                
                
                Text("\(cmdrTaxes[1])")
                    .foregroundStyle(Color.black.gradient)
                    .bold(selectedIndex == 1 ? true : false)
                    .padding(.horizontal, 8)
                    .background(
                        Capsule().stroke(selectedIndex == 1 ? Color.black : Color.clear, lineWidth:2)
                            .fill( selectedIndex == 1 ? activeColor.gradient.opacity(0.25) :  Color.gray.gradient.opacity(0.250) )
                            )
                    .zIndex( selectedIndex == 1 ? 1.1 : 0.9)

            }
            //.padding(.horizontal, 4)
//            .background(
//                Capsule().stroke(Color.brown, lineWidth:1).fill(Color.white.gradient)
//                    
//            )
            
               
        }
    }
    
    
    @ViewBuilder
    var taxBubble : some View {
        ZStack(alignment: .top){
            HStack{
                Text("Increase ")
                    .font(.caption)
                    .frame(maxWidth:.infinity)
                
                Text("on Cast")
                    .font(.caption)
                    .frame(maxWidth:.infinity)
            }
            taxLabels
                .background(
                    Capsule().stroke(Color.brown, lineWidth:1).fill(Color.white.gradient)
                    
                )
        }
    }
    
    public var body: some View {
        // height 1/18, width: 1/16
        let height = (0.05555556 * UIScreen.main.bounds.height) / Double(labels.count)
        ZStack{
            
            VStack (spacing: 0 ) {
                ForEach(labels.indices, id: \.self) { index in
                    let cmdrTax = self.cmdrTaxes[index]
                    
                    
                    ZStack{
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedIndex == index ? activeColor : secondColor.opacity(1.0))
                            .overlay(
                                ZStack{
                                    
                                    HStack (spacing: 0) {
                                        
//                                        if !leftRight {
//                                            TaxLabel(cmdrTax: cmdrTax)
//                                        }
                                        Text(labels[index])
                                            .font(.title2)
                                            .bold(selectedIndex == index )
                                            .foregroundColor(selectedIndex == index ? inactiveColor : activeColor)
                                            .customStroke(color: selectedIndex == index ? Color.black : Color.clear, width: 0.50)
                                        
                                            .padding([.horizontal, .vertical], 3)
                                            .minimumScaleFactor(0.0015)
                                            .lineLimit(1)
                                            .frame(maxWidth: .infinity)
                                        
//                                        if leftRight {
//                                            TaxLabel(cmdrTax: cmdrTax)
//                                        }
                                        
                                    }
                                }
                            )
                            .frame(maxWidth: .infinity, maxHeight: height)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedIndex == index ? Color.black.gradient : Color.clear.gradient, lineWidth: selectedIndex == index ? 3 : 2)
                                
                            )
                        
                            .onTapGesture {
                                tapAction(index)
                            }
                            .onLongPressGesture(minimumDuration: 3.0) {
                                holdAction(index)
                            }
                        
                    }
                }
            }
            
            taxBubble
                .offset(y: labels.count == 2 ? -1.23*height : -0.61*height)
        }
    }
}



struct TaxLabel: View{
    let cmdrTax: Int
    
    
    var body: some View {
        if cmdrTax == 0 {
            Text("Tax")
                .font(.footnote)
                .multilineTextAlignment(.leading)
                .padding([.horizontal], 2)
                .padding([.horizontal], 2)
                //.customStroke(color: Color.black, width: 0.150)

        } else {
             Text("\(cmdrTax)")
                .font(.footnote)
                .multilineTextAlignment(.leading)
                .bold()
                .foregroundColor(Color.white)
                .customStroke(color: Color.black, width: 0.50)
                .padding([.horizontal], 4)
                .padding([.horizontal], 4)
        }
        
    }
}



// SwiftUI Preview
#Preview {
    VStack(spacing: 80){
        CommanderNameBar(labels: ["Nashi, Moon Sage's Legacy", "rawr"], selectedIndex:0, activeColor: Color.purple, leftRight: false, cmdrTaxes:  [2, 0], tapAction: { _ in }, holdAction: { _ in })
        
        CommanderNameBar(labels: ["Nashi, Moon Sage's Legacy", "rawr"], selectedIndex:1, activeColor: Color.purple, leftRight: true, cmdrTaxes:  [0, 2], tapAction: { _ in }, holdAction: { _ in })
            .frame(width: 200)
        
        CommanderNameBar(labels: ["Nashi, Moon Sage's Legacy"], selectedIndex:0, activeColor: Color.purple, leftRight: true, cmdrTaxes:  [0], tapAction: { _ in }, holdAction: { _ in })
            .frame(width: 200)
    }
}

