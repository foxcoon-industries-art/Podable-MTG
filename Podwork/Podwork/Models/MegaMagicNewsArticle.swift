import Foundation
import SwiftData


// ═══════════════════════════════════════════════════════════════
// MARK: - SwiftData Model      ← UNCHANGED
// ═══════════════════════════════════════════════════════════════

@Model
public final class MegaMagicNewsArticle {
    @Attribute(.unique) public var id: String
    public var title: String
    public var jsonContent: Data
    public var publishedDate: Date

    public init(id: String = UUID().uuidString,
         title: String,
         jsonContent: Data,
         publishedDate: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.jsonContent = jsonContent
        self.publishedDate = publishedDate
    }
}
