import Foundation
import SwiftUI
import Combine
import SwiftData
import Podwork


// ═══════════════════════════════════════════════════════════════
// MARK: - Data Models          ← UNCHANGED
// ═══════════════════════════════════════════════════════════════

struct NewsArticle: Codable, Identifiable {
    let id: String
    let date: String
    let headline: Headline
    let content: [ContentElement]
    let poll: Poll?
    var viewCount: Int?  /// Updatable from Request

    /// Local-only properties (not from JSON)
    var isPinned: Bool = false
    var userPollResponse: String? = nil
    var hasRead: Bool = false

    enum CodingKeys: String, CodingKey {
        case id, date, headline, content, poll
        case viewCount = "view_count"
    }
}

struct Headline: Codable {
    let title: String
    let image: ImageElement?
}

struct ImageElement: Codable {
    let url: String
    let caption: String
}

enum ContentElement: Codable {
    case body(String)
    case header(String)
    case image(ImageElement)

    enum CodingKeys: String, CodingKey {
        case type, text, url, caption
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "body":
            let text = try container.decode(String.self, forKey: .text)
            self = .body(text)
        case "header":
            let text = try container.decode(String.self, forKey: .text)
            self = .header(text)
        case "image":
            let url = try container.decode(String.self, forKey: .url)
            let caption = try container.decode(String.self, forKey: .caption)
            self = .image(ImageElement(url: url, caption: caption))
        default:
            throw DecodingError.dataCorruptedError(forKey: .type,
                                                   in: container,
                                                   debugDescription: "Unknown content type")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .body(let text):
            try container.encode("body", forKey: .type)
            try container.encode(text, forKey: .text)
        case .header(let text):
            try container.encode("header", forKey: .type)
            try container.encode(text, forKey: .text)
        case .image(let element):
            try container.encode("image", forKey: .type)
            try container.encode(element.url, forKey: .url)
            try container.encode(element.caption, forKey: .caption)
        }
    }
}

struct Poll: Codable {
    let question: String
    let options: [String]
}

struct PollResults: Codable {
    let articleId: String
    let results: [String: Int]
}

struct ViewedArticleResults: Codable {
    let articleId: String
    let viewCount: Int

    enum CodingKeys: String, CodingKey {
        case articleId = "article_id"
        case viewCount = "view_count"
    }
}


// ═══════════════════════════════════════════════════════════════
// MARK: - Image Cache          ← UNCHANGED
// ═══════════════════════════════════════════════════════════════

class ImageCache: @unchecked Sendable {
    @MainActor static let shared = ImageCache()
    private let cache = NSCache<NSString, NSData>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    @MainActor
    private init() {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("NewsImages")

        print("init image cache - dir creation")
        try? fileManager.createDirectory(at: cacheDirectory,
                                         withIntermediateDirectories: true,
                                         attributes: nil)
        print("init image cache done? ")
    }

    func getImage(for url: String) async -> Data? {
        print("Getting image... ")
        if let cachedData = cache.object(forKey: url as NSString) {
            print("...return image cached data!")
            return cachedData as Data
        }
        print("file url directory")
        let fileURL = cacheDirectory.appendingPathComponent(url.toBase64())
        print(fileURL)

        if let diskData = try? Data(contentsOf: fileURL) {
            print("return disk data ")
            cache.setObject(diskData as NSData, forKey: url as NSString)
            print(diskData)
            return diskData
        }

        guard let imageURL = URL(string: url) else {
            print("image url invalid")
            return nil
        }
        print("get image from web url ")
        do {
            print("await url... ")
            let (data, _) = try await URLSession.shared.data(from: imageURL)
            cache.setObject(data as NSData, forKey: url as NSString)
            try? data.write(to: fileURL)
            print("...done")
            return data
        } catch {
            print("Failed to download image: \(error)")
            return nil
        }
    }
}

extension String {
    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
    }
}



// ═══════════════════════════════════════════════════════════════
// MARK: - News Service         ← UNCHANGED
// ═══════════════════════════════════════════════════════════════

class NewsService: ObservableObject {
    private var modelContext: ModelContext
    @Published var articles: [NewsArticle] = []
    @Published var pinnedArticles: Set<String> = []
    @Published var readArticles: Set<String> = []
    @Published var isLoading = false
    @Published var error: Error?

    private let baseURL: String
    private let userDefaults = UserDefaults.standard
    private let pinnedKey = "pinned_articles"
    private let readKey = "read_articles"
    private let maxStoredArticles = 20
    private let example: String = jsonExample().jsonString
    @Published public var lastViewedArticleID: String?

    private func viewedApiURL(_ articleID: String) -> String{
        return "/articles/viewed/\(articleID)"
    }

    init(baseURL: String = "https://foxcoon-industries.ca/news", modelContext: ModelContext) {
        print("inside news service init")
        self.baseURL = baseURL
        self.modelContext = modelContext
        loadStoredArticlesFromSwiftData()
        loadSampleArticles()          // ← guarantees bundled articles exist before any network call
        loadPinnedArticles()
        applyReadStatusToArticles()
    }

    /// Decode the bundled sample articles and merge them in.  Called once at
    /// init so they are visible immediately — independent of the server.
    /// `mergeArticles` is idempotent by ID, so this is safe to call even when
    /// the same articles were already restored from SwiftData.
    private func loadSampleArticles() {
        print("📰 Loading sample articles...")
        guard let data = example.data(using: .utf8) else {
            print("❌ Failed to encode sample JSON string")
            return
        }
        do {
            let sampleResponse = try JSONDecoder().decode(NewsResponse.self, from: data)
            mergeArticles(sampleResponse.articles)
            print("✅ Loaded \(sampleResponse.articles.count) sample articles.")
        } catch {
            print("❌ Failed to decode sample articles: \(error)")
        }
    }

    // MARK: - Network Operations
    @MainActor
    func fetchLatestNews() async {
        print("🗞️🐕🐾Fetching the News...  ")
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601

        await MainActor.run {
            isLoading = true
            error = nil
        }

        guard let url = URL(string: "\(baseURL)/all") else {
            print("error with url")
            await MainActor.run {
                self.error = URLError(.badURL)
                self.isLoading = false
            }
            return
        }

        do {
            print("...loading from server...")
            let (data, _) = try await URLSession.shared.data(from: url)

            let response = try jsonDecoder.decode(NewsResponse.self, from: data)
            print("...merging server articles...")
            await MainActor.run {
                self.mergeArticles(response.articles)
                self.saveArticlesToSwiftData()
                self.isLoading = false
            }
        } catch {
            print("... error with parsing json!")
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }

    @MainActor
    func submitArticleAsViewed(articleID: String) async {
        guard let url = URL(string: "\(baseURL)\(viewedApiURL(articleID))") else {
            print("invalid view submission response")
            return }

        let articleIdx = articles.firstIndex(where: { $0.id == articleID })
        let previousViewCount = articleIdx != nil ? articles[articleIdx!].viewCount ?? 0 : 0

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = ["article_id": articleID]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let results = try? JSONDecoder().decode(ViewedArticleResults.self, from: data) {
                await MainActor.run {
                    if let index = articles.firstIndex(where: { $0.id == results.articleId }) {
                        articles[index].viewCount = results.viewCount}
                }
            }
        } catch {
            print("Failed to receive view count response: \(error)")
            if articleIdx != nil {
                articles[articleIdx!].viewCount = previousViewCount + 1
            }
        }
    }

    @MainActor
    func submitPollResponse(articleId: String, emoji: String) async {
        print("submit poll response ")
        guard let url = URL(string: "\(baseURL)/poll") else {
            print("invalid poll response")
            return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = ["articleId": articleId, "response": emoji]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let results = try? JSONDecoder().decode(PollResults.self, from: data) {
                await MainActor.run {
                    if let index = articles.firstIndex(where: { $0.id == articleId }) {
                        articles[index].userPollResponse = emoji
                    }
                }
            }
        } catch {
            print("Failed to submit poll response: \(error)")
        }
    }

    // MARK: - Local Storage
    private func mergeArticles(_ newArticles: [NewsArticle]) {
        print("merge articles")
        var updatedArticles = articles

        for newArticle in newArticles {
            if let existingIndex = updatedArticles.firstIndex(where: { $0.id == newArticle.id }) {
                var merged = newArticle
                merged.isPinned = updatedArticles[existingIndex].isPinned
                merged.userPollResponse = updatedArticles[existingIndex].userPollResponse
                updatedArticles[existingIndex] = merged
            } else {
                updatedArticles.insert(newArticle, at: 0)
            }
        }

        let pinnedArticles = updatedArticles.filter { $0.isPinned }
        let unpinnedArticles = updatedArticles.filter { !$0.isPinned }
            .prefix(maxStoredArticles - pinnedArticles.count)

        articles = pinnedArticles + unpinnedArticles
    }

    func toggleRead(for articleId: String) {
        if let index = articles.firstIndex(where: { $0.id == articleId }) {
            articles[index].hasRead = true
            readArticles.insert(articleId)
            saveReadArticles()
            saveArticlesToSwiftDisk()
        }
    }

    func togglePin(for articleId: String) {
        if let index = articles.firstIndex(where: { $0.id == articleId }) {
            articles[index].isPinned.toggle()

            if articles[index].isPinned {
                pinnedArticles.insert(articleId)
            } else {
                pinnedArticles.remove(articleId)
            }
            savePinnedArticles()
            saveArticlesToSwiftDisk()
        }
    }

    private func saveArticlesToSwiftDisk() {
        print("... saving downloaded articles to local disk...")
        for article in articles {
            if let encoded = try? JSONEncoder().encode(article) {
                let mmNews = MegaMagicNewsArticle(id: article.id, title: article.id, jsonContent: encoded)
                modelContext.insert(mmNews)
            }
        }
        try? modelContext.save()
        print("... done.")
    }

    private func saveReadArticles() {
        print("save read articles")
        userDefaults.set(Array(readArticles), forKey: readKey)
    }

    public func applyReadStatusToArticles() {
        print("load read articles")
        if let read = userDefaults.stringArray(forKey: readKey) {
            readArticles = Set(read)

            for i in articles.indices {
                articles[i].hasRead = readArticles.contains(articles[i].id)
            }
        }
    }

    private func savePinnedArticles() {
        print("save pinned articles")
        userDefaults.set(Array(pinnedArticles), forKey: pinnedKey)
    }

    private func loadPinnedArticles() {
        print("load pinned articles")
        if let pinned = userDefaults.stringArray(forKey: pinnedKey) {
            pinnedArticles = Set(pinned)

            for i in articles.indices {
                articles[i].isPinned = pinnedArticles.contains(articles[i].id)
            }
        }
    }

    func setContext(_ context: ModelContext) {
        self.modelContext = context
    }
}


// ═══════════════════════════════════════════════════════════════
// MARK: - SwiftData Persistence   ← UNCHANGED
// ═══════════════════════════════════════════════════════════════

extension NewsService {

    func saveArticlesToSwiftData() {
        print("💾 Saving articles to SwiftData...")
        guard !articles.isEmpty else { return }

        for article in articles {
            if let encoded = try? JSONEncoder().encode(article) {
                let existing = try? modelContext.fetch(
                    FetchDescriptor<MegaMagicNewsArticle>(
                        predicate: #Predicate { $0.id == article.id }
                    )
                )

                if let existing = existing?.first {
                    existing.jsonContent = encoded
                    existing.title = article.headline.title
                    existing.publishedDate = Date()
                } else {
                    let newArticle = MegaMagicNewsArticle(
                        id: article.id,
                        title: article.headline.title,
                        jsonContent: encoded,
                        publishedDate: Date()
                    )
                    modelContext.insert(newArticle)
                }
            }
        }
        do {
            try modelContext.save()
            print("✅ Articles saved to SwiftData.")
        } catch {
            print("❌ Error saving to SwiftData: \(error)")
        }
    }

    func loadStoredArticlesFromSwiftData() {
        print("📥 Loading stored articles from SwiftData...")
        do {
            let descriptor = FetchDescriptor<MegaMagicNewsArticle>(
                sortBy: [SortDescriptor(\.publishedDate, order: .reverse)]
            )
            let stored = try modelContext.fetch(descriptor)

            var loaded: [NewsArticle] = []
            for record in stored {
                if let decoded = try? JSONDecoder().decode(NewsArticle.self, from: record.jsonContent) {
                    loaded.append(decoded)
                }
            }
            self.articles = loaded
            print("✅ Loaded \(loaded.count) articles from SwiftData.")
        } catch {
            print("❌ Failed to load from SwiftData: \(error)")
        }
    }

    func deleteAllArticlesFromSwiftData() {
        print("🗑️ Deleting all saved articles from SwiftData...")
        do {
            try modelContext.delete(model: MegaMagicNewsArticle.self)
            try modelContext.save()
            print("✅ All SwiftData articles deleted.")
        } catch {
            print("❌ Failed to delete articles: \(error)")
        }
    }
}


struct NewsResponse: Codable {
    let articles: [NewsArticle]
}


// ═══════════════════════════════════════════════════════════════
// MARK: - News View            ← RESKINNED with unified theme
// ═══════════════════════════════════════════════════════════════
/// The main article-list view.  Now wrapped in PodableSectionPanel +
/// PodableContentCard to match the visual language of DataStatsMainView and
/// YeetPodView.  Controls (pin-filter, refresh, news-writer) moved into a
/// compact toolbar row inside the content card — consistent with how
/// CommanderStatsListView houses its search bar.

@MainActor
struct NewsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject var newsService: NewsService
    @State private var selectedArticle: NewsArticle?
    @State private var showingPinnedOnly = false
    @State private var showNewsWriter = false
    @State private var showGameStoryPicker = false
    @State private var showHidden = false
    let canWriteNews: Bool

    init(modelContext: ModelContext, canWriteNews: Bool = false) {
        _newsService = StateObject(wrappedValue: NewsService(modelContext: modelContext))
        self.canWriteNews = canWriteNews
    }

    var filteredArticles: [NewsArticle] {
        if showingPinnedOnly {
            return newsService.articles.filter { $0.isPinned }.sorted(by: { $0.date > $1.date })
        }
        return newsService.articles.sorted(by: { $0.date > $1.date })
    }

    var body: some View {
        //PodableSectionPanel(outerColor: PodableTheme.newsOuterColor, accentBorder: .purple) {
            VStack(spacing: 0) {

                // ── Section Header (title + newspaper icon) ──
                PodableSectionHeader(
                    title: "News",
                    icon: "newspaper",
                    iconColor: .purple,
                    style: .primary
                )
                .background(.ultraThinMaterial)

                // ── Inner Content Card ──
                PodableContentCard {
                    VStack(spacing: 0) {

                        // Compact toolbar row: pin filter · refresh · writer
                        newsToolbar

                        // Article list
                        ScrollView {
                            if newsService.isLoading && newsService.articles.isEmpty {
                                ProgressView()
                                    .frame(maxWidth: .infinity, minHeight: 200)

                            } else if filteredArticles.isEmpty {
                                EmptyStateView(showingPinnedOnly: showingPinnedOnly)
                                    .frame(minHeight: 300)

                            } else {
                                LazyVStack(spacing: PodableTheme.spacingM) {
                                    ForEach(filteredArticles, id: \.id) { article in
                                        ArticleCard(article: article, newsService: newsService)
                                            .onTapGesture {
                                                selectedArticle = article
                                                newsService.toggleRead(for: article.id)
                                            }
                                    }
                                }
                                .padding(.vertical,  PodableTheme.spacingS)
                                .padding(.horizontal, PodableTheme.spacingS)
                            }
                        }
                        .refreshable { await newsService.fetchLatestNews() }
                    }
                }
            }
        
            .padding(.horizontal, PodableTheme.marginIPhone/2)
        //}
        // Sheets live here so they can be presented from anywhere inside the panel
        .task { if newsService.articles.isEmpty { await newsService.fetchLatestNews() } }
        .sheet(item: $selectedArticle) { article in
            ArticleDetailView(article: article, newsService: newsService)
        }
        .sheet(isPresented: $showNewsWriter) {
            NewsArticleBuilderView()
        }
        .sheet(isPresented: $showGameStoryPicker) {
            GameStoryPickerView()
        }
        .onAppear {
            newsService.setContext(modelContext)
        }
    }

    // ── Compact toolbar inside the content card ──
    private var newsToolbar: some View {
        HStack(spacing: PodableTheme.spacingM) {

            // Pin-filter toggle
            Button { showingPinnedOnly.toggle() } label: {
                HStack(spacing: 4) {
                    Image(systemName: showingPinnedOnly ? "pin.circle.fill" : "pin")
                    if showingPinnedOnly {
                        Text("Pinned")
                            .font(.caption)
                    }
                }
                .foregroundStyle(showingPinnedOnly ? Color.orange : Color.secondary)
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.2), value: showingPinnedOnly)

            Spacer(minLength: .zero)
            
            
            Image(systemName: showHidden ? "eye.fill" :  "eye.slash" )
                .font(.callout)
                .foregroundStyle(showHidden ? Color.orange : Color.secondary)
                .onTapGesture {
                    withAnimation {
                        showHidden.toggle()
                    }
                }
            

            // Refresh button
            Button {
                Task { await newsService.fetchLatestNews() }
            } label: {
                Image(systemName: newsService.isLoading
                    ? "arrow.clockwise.circle.fill"
                    : "arrow.clockwise")
                    .foregroundStyle(Color.secondary)
            }
            .buttonStyle(.plain)
            .disabled(newsService.isLoading)

            // Pod story writer (always available)
            Button { showGameStoryPicker = true } label: {
                Image(systemName: "pencil.and.scribble")
                    .foregroundStyle(Color.purple)
            }
            .buttonStyle(.plain)

            // Badge-gated general news writer
            if canWriteNews {
                Button { showNewsWriter = true } label: {
                    ZStack {
                        Image(systemName: "shield")
                            .scaleEffect(1.5)
                            .foregroundStyle(Color.purple)
                        Image(systemName: "scroll.fill")
                            .scaleEffect(0.7)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .font(.callout)
        .padding(.horizontal, PodableTheme.spacingM)
        .padding(.vertical, PodableTheme.spacingS)
        .background(Color(.quaternarySystemFill))
        .cornerRadius(PodableTheme.radiusS)
        .padding(.horizontal, PodableTheme.spacingS)
        .padding(.top, PodableTheme.spacingS)
    }
}


// ═══════════════════════════════════════════════════════════════
// MARK: - Article Card         ← RESKINNED with unified theme
// ═══════════════════════════════════════════════════════════════
/// Each article row now uses the same card recipe as CategoryButton and
/// BracketStatRowCompact: `.systemGray6` fill, 12 pt radius, consistent padding.
/// Pin uses the shared PodablePinButton.  Unread indicator uses PodableUnreadBadge.

struct ArticleCard: View {
    let article: NewsArticle
    @ObservedObject var newsService: NewsService
    let isPinned : Bool

    init(article: NewsArticle, newsService: NewsService) {
        self.article = article
        self.newsService = newsService
        self.isPinned = newsService.pinnedArticles.contains(article.id)
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: PodableTheme.spacingS) {

            // ── Thumbnail (or placeholder) ──
            thumbAndPin

            // ── Title / Meta ──
            VStack(alignment: .leading, spacing: PodableTheme.spacingXS) {
                Text(article.headline.title)
                    .font(.headline)
                    .foregroundStyle(Color.primary)
                    .lineLimit(2)

                metaRow
            }
            .frame(maxWidth: .infinity)

            
        }
        .padding(PodableTheme.spacingS)
        .background(Color(.systemGray6))
        .cornerRadius(PodableTheme.radiusM)
    }
    
    
    
    
    @ViewBuilder
    private var thumbAndPin: some View {
        ZStack{
            thumbnailView
                .padding(.leading, PodableTheme.spacingS)
            pinButton
                .offset(x:-30, y:-30)
        }
    }
    
    
    
    @ViewBuilder
    private var pinButton: some View {
        // ── Pin button (matches CommanderStatRow placement) ──
        ZStack{
            PodablePinButton(
                isPinned: isPinned,
                onToggle: { newsService.togglePin(for: article.id) }
            )
         
            .padding(PodableTheme.spacingXS)
            .background(  Color.black.opacity(0.275)  )
            .background(.ultraThinMaterial)

        }
        .overlay(Circle()
            .stroke( isPinned ? Color.orange : Color.gray, lineWidth: 3))
        .clipShape(Circle())
    }

    // ── 68 × 68 thumbnail with rounded corners ──
    @ViewBuilder
    private var thumbnailView: some View {
        if let imageUrl = article.headline.image?.url {
            CachedAsyncImage(url: imageUrl)
                .scaledToFill()
                .frame(width: 74, height: 74)
                .clipped()
                .cornerRadius(PodableTheme.radiusS)
        } else {
            RoundedRectangle(cornerRadius: PodableTheme.radiusS)
                .fill(Color(.systemGray5))
                .frame(width: 74, height: 74)
                .overlay(
                    Image(systemName: "newspaper")
                        .font(.title2)
                        .foregroundStyle(Color.secondary)
                )
        }
    }

    // ── Date · badge · poll indicator ──
    private var metaRow: some View {
        VStack(alignment:.leading) {
        HStack(spacing: PodableTheme.spacingXS) {
            Text(formatDate(article.date))
                .font(.caption)
                .foregroundStyle(Color.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            
            Spacer(minLength: .zero)
        }
      
            HStack(alignment: .bottom, spacing: PodableTheme.spacingXS) {
                if !article.hasRead {
                    PodableUnreadBadge()
                }
                // Subtle poll indicator when article has a poll
                if article.poll != nil {
                    Image(systemName: "ellipsis.bubble.fill")
                        .font(.caption)
                        .foregroundStyle(Color.blue.opacity(0.6))
                }
                 else {
                     Spacer()
                    ArticleViewCounter(viewCount: article.viewCount ?? 0)
                         .onTapGesture{
                             
                         }
                }
                
               
            }
        }
    }

    // ── Date formatting (multi-pattern parser, unchanged logic) ──
    private func formatDate(_ dateString: String) -> String {
        let patterns = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss.SSSSSS",
            "yyyy-MM-dd HH:mm:ss.SSS",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd"
        ]

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        var parsedDate: Date? = nil

        for pattern in patterns {
            formatter.dateFormat = pattern
            if let d = formatter.date(from: dateString) {
                parsedDate = d
                break
            }
        }

        guard let date = parsedDate else { return dateString }

        let outputFormatter = DateFormatter()
        outputFormatter.dateStyle = .medium
        outputFormatter.timeStyle = .short
        return outputFormatter.string(from: date)
    }
}


// ═══════════════════════════════════════════════════════════════
// MARK: - Article View Counter ← UNCHANGED
// ═══════════════════════════════════════════════════════════════

struct ArticleViewCounter: View {
    let viewCount: Int

    private func quantize(_ views: Int) -> String {
        if views >= 1_000_000 {
            let millionViews = Int( Double(views) / Double(1_000_000) )
            let thousandViews = (millionViews * 100) - Int( Double(views) / Double(10_000) )
            let reducedViews = "\(millionViews.formatted()).\(thousandViews.formatted())"
            return "\(reducedViews)M views"
        }

        if views >= 1_000 && views < 1_000_000 {
            let reducedViews = Int( Double(views) / Double(1_000) )
            return "\(reducedViews.formatted())k views"
        }
        if views == 1 { return "" }
        if views == 0 { return "" }

        return "\(views.formatted()) views"
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "eye.fill")
                .font(.caption)
            Text("\(quantize(viewCount))")
                .font(.caption)
            .foregroundColor(.secondary)
        }
    }
}


// ═══════════════════════════════════════════════════════════════
// MARK: - Article Detail View  ← UNCHANGED
// ═══════════════════════════════════════════════════════════════

struct ArticleDetailView: View {
    let article: NewsArticle
    @ObservedObject var newsService: NewsService
    @Environment(\.dismiss) var dismiss
    @State private var selectedEmoji: String?

    var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(article.headline.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("\(formatDateLong(article.date))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        if let imageElement = article.headline.image {
                            VStack(alignment: .leading, spacing: 4) {
                                CachedAsyncImage(url: imageElement.url)
                                    .aspectRatio(contentMode: .fit)
                                    .cornerRadius(12)

                                Text(imageElement.caption)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                        }
                    }
                    .padding(.horizontal)

                    Divider()

                    // Content
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(Array(article.content.enumerated()), id: \.offset) { _, element in
                            let _ = print("Content: ",article.content)
                            ContentElementView(element: element)
                        }
                    }
                    .padding(.horizontal)

                    // Poll Section
                    let _ = print("article.poll")
                    if let poll = article.poll {
                        let _ = print("article.poll inside")
                        PollView(
                            poll: poll,
                            articleId: article.id,
                            selectedEmoji: $selectedEmoji,
                            newsService: newsService
                        )
                        .padding()
                        .background(Color(UIColor.tertiarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // Bottom spacing
                    Color.clear.frame(height: 40)
                }
            }
            .onAppear {
                Task {
                    await newsService.submitArticleAsViewed(articleID: article.id)
                }
            }
            .navigationBarTitleDisplayMode(.inline)

//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button {
//                        newsService.togglePin(for: article.id)
//                    } label: {
//                        Image(systemName: article.isPinned ? "pin.fill" : "pin")
//                            .foregroundColor(article.isPinned ? .orange : .primary)
//                    }
//                }
//
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button("Done") {
//                        print("Dismiss pressed")
//                        dismiss()
//                    }
//                }
//            }

    }
    private func formatDateLong(_ dateString: String) -> String {
        let patterns = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss.SSSSSS",
            "yyyy-MM-dd HH:mm:ss.SSS",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd"
        ]

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        var parsedDate: Date? = nil

        for pattern in patterns {
            formatter.dateFormat = pattern
            if let d = formatter.date(from: dateString) {
                parsedDate = d
                break
            }
        }

        guard let date = parsedDate else { return dateString }

        let outputFormatter = DateFormatter()
        outputFormatter.dateStyle = .long
        outputFormatter.timeStyle = .short
        return outputFormatter.string(from: date)
    }
}


// ═══════════════════════════════════════════════════════════════
// MARK: - Content Element View ← UNCHANGED
// ═══════════════════════════════════════════════════════════════

struct ContentElementView: View {
    let element: ContentElement

    var body: some View {
        switch element {
        case .body(let text):
            Text(text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)

        case .header(let text):
            Text(text)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 8)

        case .image(let imageElement):
            VStack(alignment: .leading, spacing: 4) {
                CachedAsyncImage(url: imageElement.url)
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(8)

                Text(imageElement.caption)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
            .padding(.vertical, 4)
        }
    }
}


// ═══════════════════════════════════════════════════════════════
// MARK: - Poll View            ← UNCHANGED
// ═══════════════════════════════════════════════════════════════

struct PollView: View {
    let poll: Poll
    let articleId: String
    @Binding var selectedEmoji: String?
    @ObservedObject var newsService: NewsService
    @State private var hasVoted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(poll.question)
                .font(.headline)

            HStack(spacing: 20) {
                ForEach(poll.options, id: \.self) { emoji in
                    Button {
                        if !hasVoted {
                            selectedEmoji = emoji
                            hasVoted = true
                            Task {
                                await newsService.submitPollResponse(
                                    articleId: articleId,
                                    emoji: emoji
                                )
                            }
                        }
                    } label: {
                        Text(emoji)
                            .font(.system(size: 30))
                            .scaleEffect(selectedEmoji == emoji ? 1.2 : 1.0)
                            .opacity(hasVoted && selectedEmoji != emoji ? 0.5 : 1.0)
                    }
                    .disabled(hasVoted)
                }
            }
            .frame(maxWidth: .infinity)

            if hasVoted {
                Text("Thanks for your feedback!")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}


// ═══════════════════════════════════════════════════════════════
// MARK: - Cached Async Image  ← UNCHANGED
// ═══════════════════════════════════════════════════════════════

struct CachedAsyncImage: View {
    let url: String
    @State private var imageData: Data?
    @State private var isLoading = true

    var body: some View {
        Group {
            let _ = print("cachedAsyncImage")
            if let imageData = imageData,
               let uiImage = UIImage(data: imageData) {
                let _ = print("loading ui image")

                Image(uiImage: uiImage)
                    .resizable()

            } else if isLoading {
                let _ = print("is loading ", isLoading)

                Rectangle()
                    .foregroundColor(Color(UIColor.tertiarySystemBackground))
                    .overlay(
                        ProgressView().progressViewStyle(CircularProgressViewStyle())
                    )
                    .aspectRatio(16/9, contentMode: .fit)

            } else {
                let _ = print("showing photo")

                Rectangle()
                    .foregroundColor(Color(UIColor.tertiarySystemBackground))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.secondary)
                    )
                    .aspectRatio(16/9, contentMode: .fit)
            }
        }
        .task {
            imageData = await ImageCache.shared.getImage(for: url)
            isLoading = false
            print("Image data returned to image cache!")
        }
    }
}


// ═══════════════════════════════════════════════════════════════
// MARK: - Empty State View     ← RESKINNED
// ═══════════════════════════════════════════════════════════════
/// Styled to sit cleanly inside PodableContentCard with the app's dark-mode
/// palette rather than the previous solid teal background.

struct EmptyStateView: View {
    let showingPinnedOnly: Bool

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: showingPinnedOnly ? "pin.slash" : "newspaper")
                .font(.system(size: 48))
                .foregroundStyle(
                    showingPinnedOnly ? Color.orange.gradient : Color.purple.gradient
                )
                .opacity(0.6)

            Text(showingPinnedOnly ? "No Pinned Articles" : "No Articles Available")
                .font(.headline)
                .foregroundStyle(Color.primary)

            Text(showingPinnedOnly ?
                 "Pin articles to save them here" :
                 "Pull to refresh for the latest news")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}


// ═══════════════════════════════════════════════════════════════
// MARK: - Legacy Banners       (kept for any remaining references)
// ═══════════════════════════════════════════════════════════════
/// BreakingNewsBanner and NewsReviewBanner are retained so that any code
/// outside this file that still references them compiles.  New code should
/// prefer PodableUnreadBadge from PodableTheme.

struct BreakingNewsBanner: View {
    @State private var pulseAnimation = false
    var body: some View {
        PodableUnreadBadge(label: "Mega", color: .purple)
    }
}

struct NewsReviewBanner: View {
    var body: some View {
        PodableUnreadBadge(label: "Review", color: .orange)
    }
}


// ═══════════════════════════════════════════════════════════════
// MARK: - Preview
// ═══════════════════════════════════════════════════════════════

#Preview{
    let container =  try! ModelContainer(for: MegaMagicNewsArticle.self )
    let context = ModelContext(container)

    NewsView(modelContext: context)
}
