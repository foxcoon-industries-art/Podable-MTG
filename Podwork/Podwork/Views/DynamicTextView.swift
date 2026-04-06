import SwiftUI

public struct TitleView: View {
    let text: String
    let color: Color
    public init(text: String, color: Color) {
        self.text = text
        self.color = color
    }
    public var body: some View {
        Text(text)
            .font(.title2)
            .bold()
            .foregroundColor(color)
            .padding(.vertical, 4)
            .shadow(color: Color.black, radius: 0.33)
            .lineLimit(1)
            .minimumScaleFactor(0.87)
    }
}


public struct SubtitleView: View {
    let text: String
    let color: Color
    public init(text: String, color: Color) {
        self.text = text
        self.color = color
    }
    public var body: some View {
        Text(text)
            .font(.title3)
            .foregroundColor(color)
            .padding(.top, 4)
            .shadow(color: Color.black, radius: 0.25)
    }
}


public struct BodyTextView: View {
    let text: String
    public init(text: String) { self.text = text}
    public var body: some View {
        Text(text)
            .font(.body)
            .multilineTextAlignment(.leading)
            .padding(.vertical, 2)
    }
}


public struct InfoBoxTextView: View {
    let text: String
    public init(text: String) { self.text = text}
    public var body: some View {
        Text(text)
            .font(.headline)
            .bold()
            .minimumScaleFactor(0.1)
            .lineLimit(12)
            .multilineTextAlignment(.center)
            .foregroundStyle(Color.white.gradient)
            .padding(18)
            .background(Color.black.opacity(0.63))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 12)
                .fill(Color.clear)
                .stroke(Color.white.opacity(0.5), lineWidth:3))
    }
}


public struct TutorialTextTitleBoxView: View {
    let text: String
    let color: AnyShapeStyle
    let fontStyle: Font?
    public init(text: String, color: Color, fontStyle: Font? = .title) {
        self.text = text
        
        self.color = color == Color.white ? AnyShapeStyle( Color.white.gradient) : AnyShapeStyle( color.gradient)
        self.fontStyle = fontStyle
    }
    public var body: some View {
        Text(text)
            .font( fontStyle ?? .title3 )
            .fontWeight(.heavy)
            .foregroundStyle(color)
            .shadow(radius: 3)
            .padding()
            .background(Color.black.secondary)
            .cornerRadius(12)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.75)
            .multilineTextAlignment(.center)
    }
}


public struct TutorialTextHeadlineBoxView: View {
    let text: String
    public init(text: String) {  self.text = text }
    
    public var body: some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(Color.white)
            .bold()
            .padding()
            .background(Color.red.opacity(0.7))
            .cornerRadius(12)
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .minimumScaleFactor(0.55)
    }
}

#Preview{
    TitleView(text:"Title View", color: .blue)
    SubtitleView(text:"Subtitle View", color: .blue)
    BodyTextView(text: "Body View")
    InfoBoxTextView(text: "A Tutorial Text Box with a long sentence with lots of many words within it.")
        .frame(width:200)
    TutorialTextTitleBoxView(text: "Title", color: .red)
    TutorialTextHeadlineBoxView(text: "A long list of words and stuff")
}
