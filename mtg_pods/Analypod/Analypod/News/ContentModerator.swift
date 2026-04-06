import Foundation


// MARK: - Moderation Result Types

public struct ContentModerationResult: Sendable {
    public let isClean: Bool
    public let flaggedItems: [FlaggedContent]

    public init(isClean: Bool, flaggedItems: [FlaggedContent]) {
        self.isClean = isClean
        self.flaggedItems = flaggedItems
    }
}

public struct FlaggedContent: Identifiable, Sendable {
    public let id: UUID
    public let fieldLabel: String
    public let originalText: String
    public let flaggedWord: String
    public let category: ModerationCategory

    public init(fieldLabel: String, originalText: String, flaggedWord: String, category: ModerationCategory) {
        self.id = UUID()
        self.fieldLabel = fieldLabel
        self.originalText = originalText
        self.flaggedWord = flaggedWord
        self.category = category
    }
}

public enum ModerationCategory: String, CaseIterable, Sendable {
    case profanity = "Profanity"
    case slur = "Hate Speech"
    case threat = "Threatening Language"
    case explicit = "Explicit Content"

    public var color: String {
        switch self {
        case .profanity: return "orange"
        case .slur: return "red"
        case .threat: return "red"
        case .explicit: return "orange"
        }
    }
}


// MARK: - Content Moderator

public struct ContentModerator {

    /// Check a single string for flaggable content
    public static func check(_ text: String, fieldLabel: String = "") -> [FlaggedContent] {
        guard !text.isEmpty else { return [] }

        var flagged: [FlaggedContent] = []
        let normalized = normalizeSubstitutions(text)
        let lowered = normalized.lowercased()

        for (word, category) in moderationDictionary {
            if matchesWordBoundary(word: word, in: lowered) {
                flagged.append(FlaggedContent(
                    fieldLabel: fieldLabel,
                    originalText: text,
                    flaggedWord: word,
                    category: category
                ))
            }
        }

        return flagged
    }

    /// Check all text fields in a news article
    public static func checkArticle(title: String, thumbnailCaption: String = "",
                                     contents: [(text: String, label: String)]) -> ContentModerationResult {
        var allFlagged: [FlaggedContent] = []

        allFlagged.append(contentsOf: check(title, fieldLabel: "Title"))
        allFlagged.append(contentsOf: check(thumbnailCaption, fieldLabel: "Thumbnail Caption"))

        for content in contents {
            allFlagged.append(contentsOf: check(content.text, fieldLabel: content.label))
        }

        return ContentModerationResult(
            isClean: allFlagged.isEmpty,
            flaggedItems: allFlagged
        )
    }

    // MARK: - Private Helpers

    /// Normalize common letter substitutions used to evade filters
    private static func normalizeSubstitutions(_ text: String) -> String {
        var result = text
        let substitutions: [(String, String)] = [
            ("@", "a"), ("$", "s"), ("!", "i"), ("1", "i"),
            ("3", "e"), ("0", "o"), ("5", "s"), ("7", "t"),
            ("+", "t"), ("ph", "f")
        ]
        for (from, to) in substitutions {
            result = result.replacingOccurrences(of: from, with: to)
        }
        return result
    }

    /// Check if a word matches on word boundaries to avoid false positives
    private static func matchesWordBoundary(word: String, in text: String) -> Bool {
        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: word))\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return false
        }
        let range = NSRange(text.startIndex..., in: text)
        return regex.firstMatch(in: text, options: [], range: range) != nil
    }

    // MARK: - Moderation Dictionary

    /// Curated list of terms to flag. Conservative to minimize false positives.
    private static let moderationDictionary: [(String, ModerationCategory)] = [
        // Profanity
        ("fuck", .profanity),
        ("fucking", .profanity),
        ("fucker", .profanity),
        ("shit", .profanity),
        ("shitty", .profanity),
        ("bullshit", .profanity),
        ("damn", .profanity),
        ("damned", .profanity),
        ("ass", .profanity),
        ("asshole", .profanity),
        ("bitch", .profanity),
        ("bastard", .profanity),
        ("crap", .profanity),
        ("dick", .profanity),
        ("piss", .profanity),
        ("cunt", .profanity),
        ("whore", .profanity),
        ("slut", .profanity),
        ("douche", .profanity),
        ("douchebag", .profanity),

        // Hate speech / slurs
        ("nigger", .slur),
        ("nigga", .slur),
        ("faggot", .slur),
        ("fag", .slur),
        ("retard", .slur),
        ("retarded", .slur),
        ("spic", .slur),
        ("chink", .slur),
        ("kike", .slur),
        ("tranny", .slur),
        ("dyke", .slur),
        ("wetback", .slur),
        ("nazi", .slur),
        ("white supremacy", .slur),
        ("white power", .slur),

        // Threatening language
        ("kill yourself", .threat),
        ("kys", .threat),
        ("die in a fire", .threat),
        ("i will kill", .threat),
        ("i will murder", .threat),
        ("death threat", .threat),
        ("gonna kill", .threat),
        ("hope you die", .threat),

        // Explicit content
        ("porn", .explicit),
        ("pornography", .explicit),
        ("hentai", .explicit),
        ("nude", .explicit),
        ("naked", .explicit),
        ("sex", .explicit),
        ("sexual", .explicit),
        ("genitals", .explicit),
    ]
}
