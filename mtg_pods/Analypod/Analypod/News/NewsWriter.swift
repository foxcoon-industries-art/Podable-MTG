import SwiftUI
import PhotosUI


// MARK: - Data Models
struct ArticleContent: Identifiable, Codable {
    let id = UUID()
    let type: ContentType
    var text: String
    var imageData: Data?
    var caption: String
    
    enum ContentType: String, CaseIterable, Codable {
        case body = "body"
        case header = "header"
        case image = "image"
        
        var displayName: String {
            switch self {
            case .body: return "Body Paragraph"
            case .header: return "Header"
            case .image: return "Image"
            }
        }
    }
}

struct ArticlePoll: Codable {
    var question: String
    var options: [String]
}

struct NewsArticleDraft {
    var title: String = ""
    var thumbnailImageData: Data?
    var thumbnailCaption: String = ""
    var content: [ArticleContent] = []
    var poll: ArticlePoll?
    
    var hasPoll: Bool = false
}

// MARK: - JSON Models for server communication
struct ServerArticleRequest: Codable {
    let title: String
    let thumbnailImage: String // Base64 encoded
    let thumbnailCaption: String
    let content: [ServerContent]
    let poll: ArticlePoll?
}

struct ServerContent: Codable {
    let type: String
    let text: String?
    let image: String? // Base64 encoded
    let caption: String?
}

struct NewsArticleBuilderView: View {
    @State private var article = NewsArticleDraft()
    @State private var showingImagePicker = false
    @State private var imagePickerType: ImagePickerType = .thumbnail
    @State private var selectedContentIndex: Int?
    @State private var showingContentOptions = false
    @State private var isSubmitting = false
    @State private var submitMessage = ""
    @State private var showingJSONPreview = false // Add this
    @State private var previewJSON = "" // Add this
    private let newsURL: String =  "https://foxcoon-industries.ca/news"
    /// testing IP address :  "http://127.0.0.1:8080"
    
    enum ImagePickerType {
        case thumbnail
        case content(Int)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    thumbnailSection
                    contentSection
                    pollSection
                    validationSection
                    submitSection
                }
                .padding()
            }
            .navigationTitle("Create Article")
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(imagePickerType: imagePickerType) { imageData in
                    handleImageSelection(imageData: imageData)
                }
            }
            .sheet(isPresented: $showingJSONPreview) {
                JSONPreviewView(jsonString: previewJSON)
            }
            .actionSheet(isPresented: $showingContentOptions) {
                ActionSheet(
                    title: Text("Add Content"),
                    buttons: [
                        .default(Text("Header")) {
                            addContent(type: .header)
                        },
                        .default(Text("Body Paragraph")) {
                            addContent(type: .body)
                        },
                        .default(Text("Image")) {
                            addContent(type: .image)
                        },
                        .cancel()
                    ]
                )
            }
        }
    }
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Article Title")
                .font(.headline)
            TextField("Enter article title...", text: $article.title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
    
    // MARK: - Thumbnail Section
    private var thumbnailSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Thumbnail Image")
                .font(.headline)
            
            Button(action: {
                imagePickerType = .thumbnail
                showingImagePicker = true
            }) {
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
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                Text("Tap to add thumbnail")
                            }
                                .foregroundColor(.gray)
                        )
                }
            }
            
            TextField("Thumbnail caption...", text: $article.thumbnailCaption)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
    
    // MARK: - Content Section
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Article Content")
                    .font(.headline)
                Spacer()
                Button("Add Content") {
                    showingContentOptions = true
                }
                .buttonStyle(.borderedProminent)
            }
            
            ForEach(Array(article.content.enumerated()), id: \.element.id) { index, content in
                ContentItemView(
                    content: $article.content[index],
                    onImageTap: {
                        imagePickerType = .content(index)
                        showingImagePicker = true
                    },
                    onDelete: {
                        article.content.remove(at: index)
                    }
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
                        }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Text("Poll Options (Emojis)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    /// Simple emoji options - you could make this more sophisticated
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
                    .onAppear{ article.poll = nil }
                
            }
        }
    }

    private var validationIssues: [String] {
        var issues: [String] = []
        
        if article.title.isEmpty {
            issues.append("Article title is required")
        }
        
        if article.thumbnailImageData == nil {
            issues.append("Thumbnail image is required")
        }
        
        if article.content.isEmpty {
            issues.append("At least one content item is required")
        }
        
        /// Check for empty content items
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
                    Text(isSubmitting ? "Publishing..." : "Publish Article")
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
    
    // MARK: - Helper Properties
    private var canSubmit: Bool {
        !article.title.isEmpty &&
        article.thumbnailImageData != nil &&
        !article.content.isEmpty
    }
    
    // MARK: - Helper Methods
    private func addContent(type: ArticleContent.ContentType) {
        let newContent = ArticleContent(
            type: type,
            text: "",
            imageData: type == .image ? nil : nil,
            caption: ""
        )
        article.content.append(newContent)
    }
    
    private func handleImageSelection(imageData: Data) {
        switch imagePickerType {
        case .thumbnail:
            article.thumbnailImageData = imageData
        case .content(let index):
            if index < article.content.count {
                article.content[index].imageData = imageData
            }
        }
    }
    
    private func submitArticle() {
        guard canSubmit else { return }
        
        isSubmitting = true
        submitMessage = ""
        
        Task {
            do {
                let explortableJsonData = try convertToJSON()
                print("\(explortableJsonData)")
                
                await sendToServer(jsonData: explortableJsonData)
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
                    submitMessage = "Article published successfully!"
                    // Optionally reset the form
                    // article = NewsArticleDraft()
                } else {
                    submitMessage = "Error: Failed to publish article"
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
    
    // MARK: - JSON Preview Methods
    private func generateJSONPreview() {
        do {
            let previewData = createPreviewJSON()
            let jsonData = try JSONSerialization.data(withJSONObject: previewData, options: .prettyPrinted)
            previewJSON = String(data: jsonData, encoding: .utf8) ?? "Error generating preview"
            showingJSONPreview = true
        } catch {
            previewJSON = "Error generating preview: \(error.localizedDescription)"
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
                var imageContent: [String: Any] = [
                    "type": content.type.rawValue,
                    "image": content.imageData != nil ? "[IMAGE_DATA_\(index + 1)] (\(formatImageDataSize(content.imageData)))" : "[NO_IMAGE_SELECTED]",
                    "caption": content.caption.isEmpty ? "[Empty caption]" : content.caption
                ]
                contentArray.append(imageContent)
            }
        }
        
        var previewData: [String: Any] = [
            "title": article.title.isEmpty ? "[Empty title]" : article.title,
            "thumbnailImage": article.thumbnailImageData != nil ? "[THUMBNAIL_IMAGE_DATA] (\(formatImageDataSize(article.thumbnailImageData)))" : "[NO_THUMBNAIL_SELECTED]",
            "thumbnailCaption": article.thumbnailCaption.isEmpty ? "[Empty caption]" : article.thumbnailCaption,
            "content": contentArray
        ]
        
        if let poll = article.poll {
            previewData["poll"] = [
                "question": poll.question.isEmpty ? "[Empty poll question]" : poll.question,
                "options": poll.options
            ]
        }
        
        return previewData
    }
    
    private func formatImageDataSize(_ data: Data?) -> String {
        guard let data = data else { return "0 KB" }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(data.count))
    }
}


struct ContentItemView: View {
    @Binding var content: ArticleContent
    let onImageTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(content.type.displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Button("Delete") {
                    onDelete()
                }
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
                
            case .header:
                TextField("Header text...", text: $content.text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.headline)
                
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
                                    Image(systemName: "photo")
                                    Text("Tap to add image")
                                        .font(.caption)
                                }
                                    .foregroundColor(.gray)
                            )
                    }
                }
                
                TextField("Image caption...", text: $content.caption)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.caption)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
}


struct ImagePicker: UIViewControllerRepresentable {
    let imagePickerType: NewsArticleBuilderView.ImagePickerType
    let completion: (Data) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }
            
            provider.loadObject(ofClass: UIImage.self) { image, _ in
                guard let image = image as? UIImage,
                      let imageData = image.jpegData(compressionQuality: 0.8) else { return }
                
                DispatchQueue.main.async {
                    self.parent.completion(imageData)
                }
            }
        }
    }
}


struct JSONPreviewView: View {
    let jsonString: String
    @Environment(\.dismiss) private var dismiss
    @State private var showingCopyAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(jsonString)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .textSelection(.enabled) // iOS 15+ feature for text selection
                }
            }
            .navigationTitle("JSON Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: copyToClipboard) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.clipboard")
                            Text("Copy")
                        }
                    }
                }
            }
            .alert("Copied to Clipboard", isPresented: $showingCopyAlert) {
                Button("OK") { }
            } message: {
                Text("JSON has been copied to your clipboard")
            }
        }
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = jsonString
        showingCopyAlert = true
    }
}

#Preview{
    NewsArticleBuilderView()
}

