import Foundation
import SwiftUI


// MARK: - [Used in Podr] - AboutScreens to load JSON file of updatable "About" Info
public class ViewContentLoader {
    public static func load(from fileName: String) -> ViewContent? {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else { return nil }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(ViewContent.self, from: data)
            print("JSON file loaded successfully: \(fileName)")
            return decoded
        } catch {
            print("Failed to decode \(fileName): \(error)")
            return nil
        }
    }
}

// MARK: -
public enum TextBlock: Codable {
    case title(String)
    case subtitle(String)
    case body(String)
    
    public enum CodingKeys: String, CodingKey {
        case title, subtitle, body
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let title = try container.decodeIfPresent(String.self, forKey: .title) {
            self = TextBlock.title(title)
        } else if let subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle) {
            self = TextBlock.subtitle(subtitle)
        } else if let body = try container.decodeIfPresent(String.self, forKey: .body) {
            self = TextBlock.body(body)
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unknown text block type")
            )
        }
    }
}

public typealias ViewContent = [String: [TextBlock]]


// MARK: - FAQ Stuff
struct FAQSection: Identifiable {
    let id = UUID()
    let title: String
    let content: [TextBlock] /// excludes the title itself
}


public struct DynamicTextFromJsonView: View {
    public let viewName: String
    public let textBlocks: [TextBlock]
    public var titleColor: Color = .purple
    public init(viewName: String, textBlocks: [TextBlock], titleColor: Color = .purple) {
        self.viewName = viewName
        self.textBlocks = textBlocks
        self.titleColor = titleColor
    }
    var sections: [FAQSection] { return groupFAQContent(textBlocks) }
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(sections) { section in
                    FAQCard(section: section, textColor: titleColor)
                }
                .padding(.horizontal, 6)
            }
        }
    }
}


func groupFAQContent(_ items: [TextBlock]) -> [FAQSection] {
    var sections: [FAQSection] = []
    var currentTitle: String?
    var currentContent: [TextBlock] = []

    for item in items {
        switch item {
        case .title(let titleText):
            if let existingTitle = currentTitle {
                sections.append(FAQSection(title: existingTitle, content: currentContent))
            }
            currentTitle = titleText
            currentContent = []
        default:
            currentContent.append(item)
        }
    }
    
    if let existingTitle = currentTitle {
        sections.append(FAQSection(title: existingTitle, content: currentContent))
    }
    return sections
}


struct FAQCard: View {
    let section: FAQSection
    let textColor: Color
    @State private var isExpanded = false
    var content : FAQSection { section }
    var title: String {  section.title  }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading){
                HStack(alignment: .center) {
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                        .padding(8)
                    TitleView(text: title, color: textColor)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .fixedSize(horizontal: false, vertical: true)
                .contentShape(Rectangle())
            }
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(0..<section.content.count, id: \.self) { index in
                        switch section.content[index]  {
                        case .body(let text):
                            BodyTextView(text: text)
                                .padding(.horizontal)
                            
                        case .subtitle(let text):
                            SubtitleView(text: text, color: textColor)
                                .padding(.horizontal)
                            
                        case .title:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color(.secondarySystemFill))
                .fixedSize(horizontal: false, vertical: true)
                .transition(.opacity)
            }
        }
        .onTapGesture {
            withAnimation(.spring()) {
                isExpanded.toggle()
            }
        }
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
