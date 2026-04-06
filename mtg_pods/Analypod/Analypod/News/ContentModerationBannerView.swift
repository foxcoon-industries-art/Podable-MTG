import SwiftUI


public struct ContentModerationBannerView: View {
    public let flaggedItems: [FlaggedContent]

    public init(flaggedItems: [FlaggedContent]) {
        self.flaggedItems = flaggedItems
    }

    public var body: some View {
        if !flaggedItems.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "exclamationmark.shield.fill")
                        .foregroundColor(.red)
                    Text("Content flagged — please revise before submitting")
                        .font(.headline)
                        .foregroundColor(.red)
                }

                Text("The following content must be changed before this story can be shared:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ForEach(flaggedItems) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(categoryColor(item.category))
                            .font(.caption)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Text(item.fieldLabel)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)

                                Text("—")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Text(item.category.rawValue)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(categoryColor(item.category).opacity(0.2))
                                    .cornerRadius(4)
                            }

                            Text("Contains: \"\(item.flaggedWord)\"")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                }
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(10)
        }
    }

    private func categoryColor(_ category: ModerationCategory) -> Color {
        switch category {
        case .profanity: return .orange
        case .slur: return .red
        case .threat: return .red
        case .explicit: return .orange
        }
    }
}
