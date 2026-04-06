import SwiftUI
import Podwork


struct GameStoryBuilderView: View {
    let game: FinalPod
    let turns: [Turn]

    @State private var article = NewsArticleDraft()
    @State private var showingImagePicker = false
    @State private var imagePickerTarget: ImagePickerType = .thumbnail
    @State private var showingContentOptions = false
    @State private var isSubmitting = false
    @State private var submitMessage = ""
    @State private var showingJSONPreview = false
    @State private var previewJSON = ""

    // Content moderation
    @State private var moderationResults: [FlaggedContent] = []
    @State private var hasRunModeration = false

    private let newsURL: String = "https://foxcoon-industries.ca/news"

    enum ImagePickerType {
        case thumbnail
        case content(Int)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    gameContextHeader
                    headerSection
                    thumbnailSection
                    contentSection
                    pollSection

                    // Content moderation banner
                    if !moderationResults.isEmpty {
                        ContentModerationBannerView(flaggedItems: moderationResults)
                    }

                    validationSection
                    submitSection
                }
                .padding()
            }
            .navigationTitle("Pod Story")
            .sheet(isPresented: $showingImagePicker) {
                GameImagePickerView(game: game, turns: turns) { selectedImage in
                    handleImageSelection(imageData: selectedImage.jpegData(compressionQuality: 0.8) ?? Data())
                }
            }
            .sheet(isPresented: $showingJSONPreview) {
                JSONPreviewView(jsonString: previewJSON)
            }
            .actionSheet(isPresented: $showingContentOptions) {
                ActionSheet(
                    title: Text("Add Content"),
                    buttons: [
                        .default(Text("Header")) { addContent(type: .header) },
                        .default(Text("Story Paragraph")) { addContent(type: .body) },
                        .default(Text("Pod - Image")) {
                            addContent(type: .image)
                            // Auto-open picker for the just-added image
                            let newIndex = article.content.count - 1
                            imagePickerTarget = .content(newIndex)
                            showingImagePicker = true
                        },
                        .cancel()
                    ]
                )
            }
            .onChange(of: article.title) { _, _ in runModeration() }
        }
    }

    // MARK: - Game Context Header

    private var gameContextHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "gamecontroller.fill")
                    .foregroundColor(.purple)
                Text("Pod Story")
                    .font(.headline)
                    .foregroundColor(.purple)
            }

            HStack(spacing: 12) {
                if let winner = game.winningCommander {
                    Label(winner.displayNames, systemImage: "crown.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }

                Label("\(game.totalRounds) rounds", systemImage: "arrow.triangle.2.circlepath")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Label(game.formattedDuration, systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Commander list
            HStack(spacing: 6) {
                ForEach(game.commanders.rePartner.sorted(by: { $0.turnOrder < $1.turnOrder }),
                        id: \.turnOrder) { cmdr in
                    HStack(spacing: 3) {
                        Circle()
                            .fill(getColor(for: cmdr.turnOrder))
                            .frame(width: 8, height: 8)
                        Text(String(cmdr.name.prefix(12)))
                            .font(.caption2)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(10)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Article Title")
                .font(.headline)
            TextField("Enter your story title...", text: $article.title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }

    // MARK: - Thumbnail Section

    private var thumbnailSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Thumbnail Image")
                .font(.headline)

            Button {
                imagePickerTarget = .thumbnail
                showingImagePicker = true
            } label: {
                if let imageData = article.thumbnailImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(10)
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                        .overlay(
                            VStack {
                                Image(systemName: "chart.bar.xaxis")
                                    .font(.largeTitle)
                                Text("Tap to select game visualization")
                                    .font(.caption)
                            }
                            .foregroundColor(.gray)
                        )
                }
            }

            TextField("Thumbnail caption...", text: $article.thumbnailCaption)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: article.thumbnailCaption) { _, _ in runModeration() }
        }
    }

    // MARK: - Content Section

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Story Content")
                    .font(.headline)
                Spacer()
                Button("Add Content") {
                    showingContentOptions = true
                }
                .buttonStyle(.borderedProminent)
            }

            ForEach(Array(article.content.enumerated()), id: \.element.id) { index, content in
                GameStoryContentItemView(
                    content: $article.content[index],
                    onImageTap: {
                        imagePickerTarget = .content(index)
                        showingImagePicker = true
                    },
                    onDelete: {
                        article.content.remove(at: index)
                        runModeration()
                    },
                    onTextChange: { runModeration() }
                )
            }
        }
    }

    // MARK: - Poll Section

    private var pollSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Include Poll", isOn: $article.hasPoll)
                .font(.headline)

            if article.hasPoll {
                VStack(alignment: .leading, spacing: 10) {
                    TextField("Poll question...", text: Binding(
                        get: { article.poll?.question ?? "" },
                        set: { newValue in
                            if article.poll == nil {
                                article.poll = ArticlePoll(question: newValue, options: ["😊", "😔", "😮", "🤔", "❤️"])
                            } else {
                                article.poll?.question = newValue
                            }
                            runModeration()
                        }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                    Text("Poll Options (Emojis)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack {
                        ForEach(article.poll?.options ?? [], id: \.self) { emoji in
                            Text(emoji)
                                .font(.title2)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            } else {
                EmptyView()
                    .onAppear { article.poll = nil }
            }
        }
    }

    // MARK: - Validation

    private var validationIssues: [String] {
        var issues: [String] = []

        if article.title.isEmpty {
            issues.append("Article title is required")
        }
        if article.thumbnailImageData == nil {
            issues.append("Thumbnail image is required — select a game visualization")
        }
        if article.content.isEmpty {
            issues.append("At least one content item is required")
        }
        for (index, content) in article.content.enumerated() {
            switch content.type {
            case .body, .header:
                if content.text.isEmpty {
                    issues.append("\(content.type.displayName) #\(index + 1) is empty")
                }
            case .image:
                if content.imageData == nil {
                    issues.append("Image #\(index + 1) not selected")
                }
            }
        }
        if article.hasPoll, let poll = article.poll, poll.question.isEmpty {
            issues.append("Poll question is empty")
        }
        if !moderationResults.isEmpty {
            issues.append("Content has \(moderationResults.count) flagged item(s) — revise before submitting")
        }

        return issues
    }

    private var validationSection: some View {
        Group {
            if !validationIssues.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Issues to fix:")
                            .font(.headline)
                            .foregroundColor(.orange)
                    }

                    ForEach(validationIssues, id: \.self) { issue in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "minus")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text(issue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(10)
            }
        }
    }

    // MARK: - Submit Section

    private var submitSection: some View {
        VStack(spacing: 10) {
            Button(action: generateJSONPreview) {
                HStack {
                    Image(systemName: "eye")
                    Text("Preview JSON")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(canSubmit ? Color.orange : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(!canSubmit)

            Button(action: submitArticle) {
                HStack {
                    if isSubmitting {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Image(systemName: "paperplane.fill")
                    Text(isSubmitting ? "Publishing..." : "Publish Story")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(canSubmit ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(!canSubmit || isSubmitting)

            if !submitMessage.isEmpty {
                Text(submitMessage)
                    .foregroundColor(submitMessage.contains("Error") ? .red : .green)
                    .font(.caption)
            }
        }
    }

    private var canSubmit: Bool {
        !article.title.isEmpty &&
        article.thumbnailImageData != nil &&
        !article.content.isEmpty &&
        moderationResults.isEmpty
    }

    // MARK: - Content Moderation

    private func runModeration() {
        var contentItems: [(text: String, label: String)] = []

        for (index, content) in article.content.enumerated() {
            switch content.type {
            case .body:
                contentItems.append((text: content.text, label: "Body #\(index + 1)"))
            case .header:
                contentItems.append((text: content.text, label: "Header #\(index + 1)"))
            case .image:
                contentItems.append((text: content.caption, label: "Image Caption #\(index + 1)"))
            }
        }

        if let poll = article.poll {
            contentItems.append((text: poll.question, label: "Poll Question"))
        }

        let result = ContentModerator.checkArticle(
            title: article.title,
            thumbnailCaption: article.thumbnailCaption,
            contents: contentItems
        )

        moderationResults = result.flaggedItems
        hasRunModeration = true
    }

    // MARK: - Helper Methods

    private func addContent(type: ArticleContent.ContentType) {
        let newContent = ArticleContent(
            type: type,
            text: "",
            imageData: nil,
            caption: ""
        )
        article.content.append(newContent)
    }

    private func handleImageSelection(imageData: Data) {
        switch imagePickerTarget {
        case .thumbnail:
            article.thumbnailImageData = imageData
        case .content(let index):
            if index < article.content.count {
                article.content[index].imageData = imageData
            }
        }
    }

    private func submitArticle() {
        // Final moderation check — MUST be clean before sending
        runModeration()
        guard moderationResults.isEmpty else {
            submitMessage = "Error: Content has flagged items. Please revise."
            return
        }
        guard canSubmit else { return }

        isSubmitting = true
        submitMessage = ""

        Task {
            do {
                let jsonData = try convertToJSON()
                await sendToServer(jsonData: jsonData)
            } catch {
                await MainActor.run {
                    submitMessage = "Error: \(error.localizedDescription)"
                    isSubmitting = false
                }
            }
        }
    }

    private func convertToJSON() throws -> Data {
        var serverContent: [ServerContent] = []

        for content in article.content {
            switch content.type {
            case .body, .header:
                serverContent.append(ServerContent(
                    type: content.type.rawValue,
                    text: content.text,
                    image: nil,
                    caption: nil
                ))
            case .image:
                let imageBase64 = content.imageData?.base64EncodedString() ?? ""
                serverContent.append(ServerContent(
                    type: content.type.rawValue,
                    text: nil,
                    image: imageBase64,
                    caption: content.caption
                ))
            }
        }

        let thumbnailBase64 = article.thumbnailImageData?.base64EncodedString() ?? ""

        let serverRequest = ServerArticleRequest(
            title: article.title,
            thumbnailImage: thumbnailBase64,
            thumbnailCaption: article.thumbnailCaption,
            content: serverContent,
            poll: article.poll
        )

        return try JSONEncoder().encode(serverRequest)
    }

    private func sendToServer(jsonData: Data) async {
        guard let url = URL(string: newsURL + "/create_article") else {
            await MainActor.run {
                submitMessage = "Error: Invalid server URL"
                isSubmitting = false
            }
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        do {
            let (_, response) = try await URLSession.shared.data(for: request)

            await MainActor.run {
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 201 {
                    submitMessage = "Story published successfully!"
                } else {
                    submitMessage = "Error: Failed to publish story"
                }
                isSubmitting = false
            }
        } catch {
            await MainActor.run {
                submitMessage = "Error: \(error.localizedDescription)"
                isSubmitting = false
            }
        }
    }

    private func generateJSONPreview() {
        do {
            let previewData = createPreviewJSON()
            let jsonData = try JSONSerialization.data(withJSONObject: previewData, options: .prettyPrinted)
            previewJSON = String(data: jsonData, encoding: .utf8) ?? "Error generating preview"
            showingJSONPreview = true
        } catch {
            previewJSON = "Error: \(error.localizedDescription)"
            showingJSONPreview = true
        }
    }

    private func createPreviewJSON() -> [String: Any] {
        var contentArray: [[String: Any]] = []

        for (index, content) in article.content.enumerated() {
            switch content.type {
            case .body, .header:
                contentArray.append([
                    "type": content.type.rawValue,
                    "text": content.text.isEmpty ? "[Empty \(content.type.displayName)]" : content.text
                ])
            case .image:
                contentArray.append([
                    "type": content.type.rawValue,
                    "image": content.imageData != nil ? "[GAME_VIZ_IMAGE_\(index + 1)]" : "[NO_IMAGE_SELECTED]",
                    "caption": content.caption.isEmpty ? "[Empty caption]" : content.caption
                ])
            }
        }

        var previewData: [String: Any] = [
            "title": article.title.isEmpty ? "[Empty title]" : article.title,
            "thumbnailImage": article.thumbnailImageData != nil ? "[GAME_VIZ_THUMBNAIL]" : "[NO_THUMBNAIL]",
            "thumbnailCaption": article.thumbnailCaption.isEmpty ? "[Empty caption]" : article.thumbnailCaption,
            "content": contentArray,
            "gameID": game.gameID,
            "gameDuration": game.formattedDuration,
            "winner": game.winningCommanderName ?? "Unknown"
        ]

        if let poll = article.poll {
            previewData["poll"] = [
                "question": poll.question.isEmpty ? "[Empty poll question]" : poll.question,
                "options": poll.options
            ]
        }

        return previewData
    }
}


// MARK: - Content Item View (Pod Story variant)

struct GameStoryContentItemView: View {
    @Binding var content: ArticleContent
    let onImageTap: () -> Void
    let onDelete: () -> Void
    let onTextChange: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(content.type.displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Button("Delete") { onDelete() }
                    .foregroundColor(.red)
                    .font(.caption)
            }

            switch content.type {
            case .body:
                TextEditor(text: $content.text)
                    .frame(minHeight: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3))
                    )
                    .onChange(of: content.text) { _, _ in onTextChange() }

            case .header:
                TextField("Header text...", text: $content.text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.headline)
                    .onChange(of: content.text) { _, _ in onTextChange() }

            case .image:
                Button(action: onImageTap) {
                    if let imageData = content.imageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 150)
                            .clipped()
                            .cornerRadius(8)
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 150)
                            .overlay(
                                VStack {
                                    Image(systemName: "chart.bar.xaxis")
                                    Text("Tap to select game visualization")
                                        .font(.caption)
                                }
                                .foregroundColor(.gray)
                            )
                    }
                }

                TextField("Image caption...", text: $content.caption)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.caption)
                    .onChange(of: content.caption) { _, _ in onTextChange() }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
}
