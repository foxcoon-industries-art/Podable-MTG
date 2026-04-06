import SwiftUI

public struct SGFExportView: View {
    @State private var jsonString: String = ""
    @State private var isExporting: Bool = false
    
    // Accept either a GameState (live game) or GameRecord (already converted)
    public var gameState: GameState?
    public var gameRecord: GameRecord?
    
    public init(gameState: GameState? = nil, gameRecord: GameRecord? = nil) {
        self.gameState = gameState
        self.gameRecord = gameRecord
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
//            NavigationHeader(
//                title: "Game Export",
//                subtitle: "Standard Game Format (SGF v2.0)",
//                showBackButton: true
//            )
            
            // Content
            if isExporting {
                ProgressView("Generating JSON...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    Text(jsonString)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .textSelection(.enabled) // Allow user to copy text
                }
            }
            
            // Footer Actions
            VStack(spacing: 12) {
                Button(action: copyToClipboard) {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text("Copy JSON")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                
                ShareLink(item: jsonString) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share File")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
        }
        .task {
            await generateJSON()
        }
    }
    
    private func generateJSON() async {
        isExporting = true
        defer { isExporting = false }
        
        // 1. Get the record
        let record: GameRecord
        if let existing = gameRecord {
            record = existing
        } else if let state = gameState {
            // Run conversion on MainActor
            record = await MainActor.run {
                state.exportGameRecord()
            }
        } else {
            jsonString = "Error: No game data provided."
            return
        }
        
        // 2. Encode to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601 // ISO8601 is best for JSON dates
        
        do {
            let data = try encoder.encode(record)
            if let string = String(data: data, encoding: .utf8) {
                jsonString = string
            } else {
                jsonString = "Error: Failed to convert data to string."
            }
        } catch {
            jsonString = "Error encoding JSON: \(error.localizedDescription)"
        }
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = jsonString
    }
}

// MARK: - Preview Logic
#Preview {
    // 1. Generate realistic demo data
    let demoData = DemoDataGenerator.demoData(count: 1).first!
    let (finalPod, turns) = (demoData.0, demoData.1)
    
    // 2. Reconstruct a minimal GameState for the preview
    // This bridges the gap between your Generator (FinalPod based) and the View (GameState based)
    let state = GameState()
    
    // Load History
    state.podHistory = turns
    state.gameDate = finalPod.date
    state.gameOver = finalPod
    
    // Load Players from Commanders
    state.players = []
    for (i, cmdr) in finalPod.commanders.enumerated() {
        let p = Player(
            commanderName: cmdr.name,
            partnerName: cmdr.partner,
            id: i,
            bracket: 0
        )
        // Load bracket from the generated data if available
        p.deckBracket[i] = cmdr.bracketRating
        state.players.append(p)
    }
    
    // 3. Render View
    return SGFExportView(gameState: state)
}
