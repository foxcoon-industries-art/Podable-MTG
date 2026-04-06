import SwiftUI
import Podwork

/*
 NOT MAIN METHOD
 */


/*
// MARK: - Statistics Category Enum
public enum StatsCategory: String, CaseIterable, Identifiable {
    case commanders = "By Commander"
    case brackets = "By Bracket"
    case turnOrder = "By Turn Order"
    
    public var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .commanders: return "person.text.rectangle"
        case .brackets: return "chart.bar.xaxis"
        case .turnOrder: return "arrow.triangle.turn.up.right.circle"
        }
    }
    
    var description: String {
        switch self {
        case .commanders: return "View stats for individual commanders"
        case .brackets: return "Compare performance across power brackets"
        case .turnOrder: return "Analyze win rates by turn position"
        }
    }
}
*/





// MARK: - Main Fetchr View
@MainActor
public struct FetchrMainView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var dataManager = GameDataManager.shared
    @Bindable var commanderStore = CommanderStore.shared
    @StateObject private var scryfallService = CommanderStore.shared.scryfallService
    
    @State private var selectedCategory: StatsCategory? = nil
    @State private var isLoading: Bool = false
    @State private var showingErrorAlert = false
    @State private var errorMessage: String = ""
    
    private let sidePad: CGFloat = 6
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            if selectedCategory == nil {
                // Main category selection view
                mainPanel
                    .transition(.opacity)
            } else {
                // Category detail view with same background
                categoryDetailView
                    .transition(.opacity)
            }
        }
        .onAppear {
            commanderStore.setup(with: modelContext)
        }
        .onChange(of: commanderStore.loadingError) { oldValue, newValue in
            if let error = newValue {
                errorMessage = error
                showingErrorAlert = true
            }
        }
        .alert("Download Error", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    

    
    // MARK: - Main Panel
    private var mainPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerSection
            
            // Summary Statistics Cards
            summaryStatsCards
            
            // Category Selection Buttons
            categoryButtons
            
            // Update Commanders Button
            updateCommandersButton
            
          
            Spacer()
            
            // Scryfall Attribution
            scryfallAttribution
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5).gradient)
                .stroke(Color.black, lineWidth: 1)
        )
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .top, spacing: 40) {
            Text("Data")
                .font(.largeTitle)
                .bold()
            
            Spacer()
            
            Image(systemName: isLoading ? "cloud" : "cloud")
                .font(.title)
                .scaleEffect(x: 2.0, y: 2.0)
                .foregroundStyle(Color.indigo.gradient)
                .offset(x: -10, y: 0)
                .animation(
                    .easeInOut(duration: 0.050).repeatForever(autoreverses: isLoading),
                    value: scryfallService.progress
                )
        }
    }
    
    // MARK: - Summary Stats Cards
    private var summaryStatsCards: some View {
        HStack(spacing: sidePad * 0.5) {
            StatisticsCardView(
                title: "Pods",
                value: "\(dataManager.podSummaryStats.totalGames)",
                color: Color.orange,
                subtitle: "Played"
            )
            .frame(minWidth: 0.25 * UIScreen.main.bounds.size.width)
            
            StatisticsCardView(
                title: "Time",
                value: timeFormatDuration(dataManager.podSummaryStats.totalPlaytime),
                color: Color.orange,
                subtitle: "Total"
            )
            .layoutPriority(1)
            
            StatisticsCardView(
                title: "Commanders",
                value: "\(dataManager.podSummaryStats.totalCmdrsSeenPlayed)",
                color: Color.orange,
                subtitle: "Seen"
            )
            .frame(minWidth: 0.25 * UIScreen.main.bounds.size.width)
        }
        .padding(.horizontal, sidePad)
    }
    
    // MARK: - Category Buttons
    private var categoryButtons: some View {
        VStack(spacing: 12) {
            Text("Statistics:")
                .font(.title)
            
            ForEach(StatsCategory.allCases) { category in
                Button(action: {
                    withAnimation(.spring()) {
                        selectedCategory = category
                    }
                }) {
                    HStack {
                        Image(systemName: category.icon)
                            .font(.title3)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.rawValue)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(category.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, sidePad)
    }
    
  
    
    // MARK: - Update Commanders Button
    private var updateCommandersButton: some View {
        VStack(alignment: .leading, spacing: 8) {
            if commanderStore.isLoaded {
                HStack {
                    Text("\(commanderStore.commanders.count) Commanders loaded")
                        .font(.caption)
                    
                    Image(systemName: commanderStore.commanders.count == 0 ?
                          "person.text.rectangle.trianglebadge.exclamationmark" :
                          "person.text.rectangle")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(commanderStore.commanders.count == 0 ? Color.orange : Color.green)
                }
            }
            
            if let last = commanderStore.lastUpdateDate {
                Text("Last Update: \(last.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Button(action: {
                withAnimation(.spring(duration: 0.05)) {
                    isLoading = true
                    Task {
                        await commanderStore.refreshFromScryfall()
                        withAnimation(.spring(duration: 0.75)) {
                            isLoading = false
                        }
                    }
                }
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.purple)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.title3)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isLoading ? "Updating Commanders..." : "Update Commanders")
                            .font(.headline)
                        
                        if isLoading {
                            Text("\(Int(scryfallService.progress * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else if let bytes = commanderStore.lastDownloadSize {
                            Text("Download size: \(formatBytes(bytes))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .disabled(isLoading)
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, sidePad)
    }
    
    // MARK: - Scryfall Attribution
    private var scryfallAttribution: some View {
        HStack(alignment: .lastTextBaseline, spacing: 2) {
            Text("Data provided by")
                .foregroundColor(.secondary)
            
            Text("Scryfall")
                .foregroundColor(Color.purple.opacity(0.75))
                .onTapGesture {
                    if let url = URL(string: "https://scryfall.com") {
                        UIApplication.shared.open(url)
                    }
                }
        }
        .font(.caption)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Category Detail View
    private var categoryDetailView: some View {
        VStack(spacing: 0) {
            // Back button and header
            categoryHeader
            
            // Content based on selected category
            ScrollView {
                VStack(spacing: 16) {
                    switch selectedCategory {
                    case .commanders:
                        EmptyView()
                        //FetchrCommanderList()
                        //CommanderStatsListView()
                    case .brackets:
                        FetchrBracketList()
                        //BracketStatsListView()
                    case .turnOrder:
                        FetchrTurnOrderList()
                        //TurnOrderStatsListView()
                    case .duel:
                        EmptyView()
                    case .none:
                        EmptyView()
                    }
                }
                .padding()
            }
            Spacer(minLength: .zero)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5).gradient)
                .stroke(Color.black, lineWidth: 1)
        )
    }
    
    // MARK: - Category Header
    private var categoryHeader: some View {
        HStack {
            Button(action: {
                withAnimation(.spring()) {
                    selectedCategory = nil
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.caption)
                    Text("Back")
                        .font(.subheadline)
                }
                .foregroundColor(.orange)
            }
            
            Spacer()
            
            if let category = selectedCategory {
                HStack {
                    Image(systemName: category.icon)
                        .font(.title3)
                    Text(category.rawValue)
                        .font(.title2)
                        .bold()
                }
            }
            
            Spacer()
            
            // Invisible spacer to balance layout
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.caption)
                Text("Back")
                    .font(.subheadline)
            }
            .opacity(0)
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Helper Functions
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Preview
#Preview {
    FetchrMainView()
}
