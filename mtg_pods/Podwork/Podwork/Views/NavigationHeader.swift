import SwiftUI

public struct NavigationBackButtonWithTitle: View {
    @Binding var title: String
    let color: Color
    let showBack: Bool
    let onBack: (() -> Void)?
    
    let width = UIScreen.main.bounds.width
    let height = 0.0476*UIScreen.main.bounds.height // (1/21)
    
    public init(title: Binding<String>, color: Color, showBack: Bool = false, onBack: (() -> Void)? = nil) {
        self._title = title
        self.color = color
        self.showBack = showBack
        self.onBack = onBack
    }
    
    public var body: some View {
        
        ZStack(alignment:.center) {
            if showBack {
                Button(action: {
                    HapticFeedback.impact(.light)
                    onBack?()
                }) {
                    HStack(spacing: 0) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text("Back")
                            .font(.body)
                            .bold()
                        
                        Spacer(minLength: .zero)
                    }
                    .foregroundColor(Color.white)
                    .customStroke(color: Color.black, width: 0.5)
                    .padding(.horizontal, 0.125*height)
                    .padding(.vertical, 8)
                }
            }
            if title.contains("\n") {
                let topTitle = title.split(separator: "\n").first ?? ""
                let bottomTitle = title.split(separator: "\n").last ?? ""
                
                VStack(alignment:.center,  spacing:0){
                    Text(topTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .customStroke(color: Color.white, width: 0.166)
                        .foregroundStyle(color.gradient.opacity(0.95))
                        .customStroke(color: Color.black, width: 0.666)
                        .frame(maxWidth: .infinity)
                    
                    Text(bottomTitle)
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .customStroke(color: Color.white, width: 0.166)
                        .foregroundStyle(color.gradient.opacity(0.95))
                        .customStroke(color: Color.black, width: 0.666)
                        .frame(maxWidth: .infinity)
                }
            }
            else {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                
                    .customStroke(color: Color.white, width: 0.166)
                    .foregroundStyle(color.gradient.opacity(0.95))
                    .customStroke(color: Color.black, width: 0.666)
                    .frame(maxWidth: .infinity)
            }
        }
        .background( Color.clear )
    }
}



