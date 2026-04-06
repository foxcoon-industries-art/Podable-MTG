import SwiftUI
import Podwork


// MARK: - News Tab Entry Point
/// Thin wrapper that hands the ModelContext down to NewsView and resolves the
/// `canWriteNews` permission on first appearance.  All layout, theming, and
/// article-list logic now lives inside NewsView itself — mirroring the pattern
/// that DataStatsMainView and YeetPodView already use (custom header, no
/// NavigationView title).
public struct MegaMagicNewsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appInfo: App_Info

    @State private var canWriteNews: Bool

   public init(canWriteNews: Bool = false) {
        _canWriteNews = State(initialValue: canWriteNews)
    }

    public var body: some View {
        NewsView(modelContext: modelContext, canWriteNews: canWriteNews)
            .onAppear { canWriteNews = appInfo.userInfo.newsBadge() }
    }
}
