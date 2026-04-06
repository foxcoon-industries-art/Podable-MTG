import SwiftUI



public struct CapBoardVeiw: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    public init(title: String, value: String, icon: String, color: Color) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
    }
    
    public var body: some View {
        VStack(alignment: .center, spacing: 8) {
//            Image(systemName: icon)
//                .font(.footnote)
//                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity)
                //.padding(.top, 4)
                .padding(.vertical, 8)
                .foregroundStyle(Color.white.gradient)
                //.padding(4)
                .background(Color(.secondarySystemFill))
            
            Text(title)
                .font(.caption)
                .bold()
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 4)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
      
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}




public struct CappedBoardVeiw: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    public init(title: String, value: String, icon: String, color: Color) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
    }
    
    public var body: some View {
        VStack(alignment: .center, spacing: 8) {
            //            Image(systemName: icon)
            //                .font(.footnote)
            //                .foregroundColor(color)
            
            
            Text(title)
                .font(.caption)
                .bold()
                .foregroundStyle(Color.white.gradient)
                .multilineTextAlignment(.center)
                //.padding(.horizontal, 4)
                .padding(.vertical, 6)
                .padding(.bottom, -4)
            
            
            Text(value)
                .font(.title)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity)
            //.padding(.top, 4)
                .padding(.vertical, 8)
                .foregroundStyle(Color.white.gradient)
            //.padding(4)
                .background(Color(.secondarySystemFill))
         
        }
        .frame(maxWidth: .infinity)
        
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
