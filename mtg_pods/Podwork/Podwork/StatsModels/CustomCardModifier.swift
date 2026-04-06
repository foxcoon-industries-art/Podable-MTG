import SwiftUI
import Foundation


extension View {
    func chartBodyFormat() -> some View {
        modifier(ChartBodyStyleModifier())
            //.clipShape(RoundedRectangle(cornerRadius: 12.0))
    }
    func chartHeaderFormat() -> some View {
        modifier(ChartHeaderStyleModifier())
            // .clipShape(RoundedRectangle(cornerRadius: 12.0))
    }
}





struct ChartBodyStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(.tertiarySystemBackground))

            //.background(Color(.secondarySystemFill))
        
    }
}


struct ChartBodyStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 8)
            .background(Color(.secondarySystemFill))
    }
}



struct ChartFooterStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .bold()
            .foregroundStyle(Color.primary)
            .padding(.bottom, 8)
    }
}


struct ChartHeaderStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(.systemGray6))
    }
}




