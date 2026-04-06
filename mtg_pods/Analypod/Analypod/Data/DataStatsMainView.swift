import SwiftUI
import Charts
import Podwork

// MARK: - Statistics Category Enum
public enum StatsCategory: String, CaseIterable, Identifiable {
    case commanders = "Commander"
    case brackets = "Bracket"
    case turnOrder = "Turn Order"
    case duel = "Duel"

    public var id: String { rawValue }

    var icon: String {
        switch self {
        case .commanders: return "person.crop.rectangle.stack"
        case .brackets: return "square.stack.3d.up"
        case .turnOrder: return "arrow.trianglehead.clockwise"
        case .duel: return "person.2.fill"
        }
    }

    var description: String {
        switch self {
        case .commanders: return "Analyze Individual Commanders"
        case .brackets: return "Distributions for Pod Brackets"
        case .turnOrder: return "Designated Seating in Pods"
        case .duel: return "60-Card Duel Match Statistics"
        }
    }
}


// MARK: - Main Data Stats View
public struct DataStatsMainView: View {
    static public var shared = DataStatsMainView()
    @StateObject private var dataManager = GameDataManager.shared
    @Bindable var commanderStore = CommanderStore.shared
    @StateObject private var scryfallService = CommanderStore.shared.scryfallService
    
    @State private var selectedCategory: StatsCategory? = nil
    @State private var isLoading: Bool = false
    @State private var showingStatistics = false
    @Environment(\.dismiss) var dismiss
    
    @State private var containerSize : CGSize = .zero
    public init() {}
    
    public var body: some View {

        VStack (spacing: 0){
            // ── section header via unified theme ──
            PodableSectionHeader(
                title:     "Statistics",
                icon:      "chart.bar.xaxis",
                iconColor: .orange,
                style:     .primary
            )
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            
            Group {
                selectedCategory == nil ?
                AnyView( mainPanelView ) :
                AnyView( categoryDetailView )
            }
            
            .animation(.easeInOut(duration: 0.25), value: selectedCategory)
            .transition(.opacity)
            

        }
        .padding(.horizontal, PodableTheme.marginIPhone/2)
        
    }

    
    // MARK: - Main Panel View
    private var mainPanelView: some View {
        PodableContentCard {
            VStack(alignment: .center, spacing: PodableTheme.spacingS) {
                    //Spacer(minLength: .zero)
                    summaryCardsSection
                    //Spacer(minLength: .zero)
                    categoryButtonsSection
                    updateCommandersSectionWithLineBreaks
         
                }
                .padding(.horizontal, PodableTheme.spacingS)
                //.frame(maxHeight: .infinity)
                .background(.ultraThinMaterial)
        }
    }
    
    
    // MARK: - Summary Cards Section
    private var summaryCardsSection: some View {
        //VStack(alignment: .leading, spacing: PodableTheme.spacingS) {
            HStack(spacing: PodableTheme.spacingS) {
                StatisticsCardView(
                    title: "Pods",
                    value: "\(dataManager.podSummaryStats.totalGames)",
                    color: Color.orange,
                    subtitle: "Played"
                )
                .frame(minWidth: 0.3 * containerSize.width)
                
                StatisticsCardView(
                    title: "Time",
                    value: timeFormatDuration(dataManager.podSummaryStats.totalPlaytime),
                    color: Color.orange,
                    subtitle: "Total"
                )
                .layoutPriority(1) // Sets size to 1/2 screen width
                
                StatisticsCardView(
                    title: "Commanders",
                    value: "\(dataManager.podSummaryStats.totalCmdrsSeenPlayed)",
                    color: Color.orange,
                    subtitle: "Seen"
                )
                .frame(minWidth: 0.3 * containerSize.width)
            }
        // }
        //.padding(.horizontal, PodableTheme.spacingS)
        .padding(.top,        PodableTheme.spacingM)
        .padding(.bottom,     PodableTheme.spacingS)
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        self.containerSize = geometry.size
                    }
            }
        )
    }
    
    
    // MARK: - Category Buttons Section
    private var categoryButtonsSection: some View {
        VStack(alignment: .leading, spacing: PodableTheme.spacingL) {

            Divider()
                .padding(.vertical, PodableTheme.spacingS)
            
            //Spacer(minLength: .zero)
            
            VStack(spacing: PodableTheme.spacingM) {
                ForEach(StatsCategory.allCases) { category in
                    CategoryButton(category: category) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { selectedCategory = category }
                    }
                }
            }
        }
    }
    
    
    // MARK: - Update Commanders Section
    private var updateCommandersSectionWithLineBreaks: some View {
        VStack(alignment: .leading, spacing: PodableTheme.spacingM) {
            //Spacer(minLength: .zero)
            Divider()
                .padding(.vertical, PodableTheme.spacingM)
            updateCommandersSection
                .padding(.horizontal, 0)
                .padding(.bottom, PodableTheme.spacingM)
            Spacer(minLength: .zero)
            
        }
    }
    
    
    // MARK: - Update Commanders Section
    private var updateCommandersSection: some View {
        VStack(alignment: .leading, spacing: PodableTheme.spacingS) {
            PodableInfoCard {
                HStack(alignment: .center, spacing: PodableTheme.spacingM) {
                    Image(systemName: commanderStore.commanders.count == 0 ?
                          "person.text.rectangle.trianglebadge.exclamationmark" :
                            "person.text.rectangle")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(commanderStore.commanders.count == 0 ? Color.orange : Color.green)
                    .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(commanderStore.commanders.count) Commanders")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if let last = commanderStore.lastUpdateDate {
                            Text("Updated \(last.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.right")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.secondary)
                    }
                    .foregroundStyle(Color.orange)
                }
                .onTapGesture {
                    showingStatistics = true
                }
                .sheet(isPresented: $showingStatistics) {
                    StatisticsView(statistics: commanderStore.statistics)
                }
                .padding(PodableTheme.spacingM)

            }
            
            Button(action: {
                withAnimation(.spring(duration: 0.05)) {
                    isLoading = true
                }
                Task {
                    await commanderStore.refreshFromScryfall()
                    withAnimation(.spring(duration: 0.75)) {
                        isLoading = false
                    }
                }
            }) {
                HStack(spacing: PodableTheme.spacingS) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    
                    Text(isLoading ? "Updating..." : "Update Commander List")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if !isLoading {
                        Text("(\(formatBytes(commanderStore.lastDownloadSize ?? 15_000_000)))")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    } else {
                        Text("\(Int(scryfallService.progress * 100))%")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, PodableTheme.spacingS)
                .background(
                    RoundedRectangle(cornerRadius: PodableTheme.radiusM)
                        .fill(isLoading ? Color.gray : Color.indigo)
                )
                .foregroundColor(.white)
            }
            .padding(PodableTheme.spacingM)
            .disabled(isLoading)
        }
      

    }
    
    
    func chooseOutline(from selectedCategory: StatsCategory? ) -> Color {
        if let selectedCategory = selectedCategory {
            switch selectedCategory {
            case .commanders:
                return Color.red
            case .brackets:
                return Color.green
            case .turnOrder:
                return Color.blue
            case .duel:
                return Color.cyan
            }
        }
        return Color.gray
    }
    
    
    // MARK: - Category Detail View
    @ViewBuilder
    private var categoryDetailView: some View {
        VStack(spacing: 0) {
            PodableInfoCard {
                HStack {
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedCategory = nil
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.semibold))
                            Text(" ")
                                .font(.body)
                        }
                        .foregroundStyle(Color.orange)
                    }
                    
                    Spacer()
                    
                    if let category = selectedCategory {
                        Text(category.rawValue)
                            .font(.headline)
                            .foregroundStyle(Color.primary)
                    }
                    
                    Spacer()
                    
                    Color.clear
                        .frame(width: 60, height: 20)
                    
                }
                .padding(.horizontal, PodableTheme.spacingM)
                .padding(.vertical, PodableTheme.spacingS)
            }
            
            VStack(spacing: 0) {
                switch selectedCategory {
                case .commanders:
                    CommanderStatsListView()
                case .brackets:
                    BracketStatsListView()
                case .turnOrder:
                    TurnOrderStatsPanel()
                case .duel:
                    DuelStatsView()
                        .environmentObject(dataManager)
                case .none:
                    EmptyView()
                }
            }
            .padding(.top, PodableTheme.spacingS)
            .padding(.horizontal, PodableTheme.spacingS)
            .background(.ultraThinMaterial)
            Spacer(minLength: .zero)
        }
        .overlay(
            RoundedRectangle(cornerRadius: PodableTheme.radiusM)
                .stroke(chooseOutline(from: selectedCategory), lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: PodableTheme.radiusM))
    }
    
    
    @ViewBuilder
    public var initDownloadCommanders : some View {
        
        VStack(alignment:.center, spacing:10){
            Text("Quick Update")
                .bold()
                .font(.title3)
            
            PodableInfoCard {
                Text("Podable relies on other Community Tools for accurate Card Information.\n\nThe full list of Commanders can be updated anytime from the Stats menu.\n\nRemember to update the full list after every new set release!\n\nFetch Card Data from Scryfall?\n\n(Estimated: \(formatBytes(commanderStore.lastDownloadSize ?? 15_000_000)))").padding()
            }
            updateCommandersSection
                .padding([.top, .horizontal])
                
            
            HStack(spacing: 30){
                Button(action: {dismiss()} ){
                    Text("Exit")
                        .foregroundStyle(Color.red)
                }
                .buttonStyle(.bordered)
               
                
                Button(action: {dismiss()} ){
                    Text("Continue")
                        .bold()
                }
                .background(commanderStore.commanders.count == 0 ? Color.white.opacity(0.6) : Color.green)
                .buttonStyle(.bordered)
                .clipShape(Capsule())
                .disabled(commanderStore.commanders.count == 0 )
            }
        }
        .padding(.vertical, 20)
        .background(Color.gray.gradient.opacity(0.4))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: PodableTheme.radiusM))
    }
    
}











public struct InitCommanderInstall : View {
    static public var shared = DataStatsMainView()
    @StateObject private var dataManager = GameDataManager.shared
    @Bindable var commanderStore = CommanderStore.shared
    @StateObject private var scryfallService = CommanderStore.shared.scryfallService
    
    @State private var selectedCategory: StatsCategory? = nil
    @State private var isLoading: Bool = false
    @State private var showingStatistics = false
    @Environment(\.dismiss) var dismiss
    
    @Binding var closeWindow : Bool
    public init(closeWindow: Binding<Bool>) {
        self._closeWindow  = closeWindow
    }
    
    public var body: some View {
        
        initDownloadCommanders
    }
    
    
    @ViewBuilder
    var initDownloadCommanders : some View {
        
        VStack(alignment:.center, spacing:10){
            Text("Quick Update")
                .bold()
                .font(.title3)
            
            PodableInfoCard {
                Text("Podable relies on other Community Tools for accurate Card Information.\n\nThe full list of Commanders can be updated anytime from the Stats menu.\n\nRemember to update the full list after every new set release!\n\nFetch Card Data from Scryfall?\n\n(Estimated: \(formatBytes(commanderStore.lastDownloadSize ?? 15_000_000)))").padding()
            }
            updateCommandersSection
                .padding([.top, .horizontal])
            
            
            HStack(spacing: 30){
                Button(action: {closeWindow = true} ){
                    Text("Exit")
                        .foregroundStyle(Color.red)
                }
                .buttonStyle(.bordered)
                
                
                Button(action: {closeWindow = true} ){
                    Text("Continue")
                        .bold()
                    // .foregroundStyle(commanderStore.commanders.count == 0 ? Color.gray : Color.green)
                }
                .background(commanderStore.commanders.count == 0 ? Color.white.opacity(0.6) : Color.green)
                .buttonStyle(.bordered)
                .clipShape(Capsule())
                .disabled(commanderStore.commanders.count == 0 )
            }
            
            scryfallAttribution
        }
        .padding(.vertical, 20)
        .background(Color.gray.gradient.opacity(0.4))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: PodableTheme.radiusM))
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
    
    
    private var updateCommandersSection: some View {
        VStack(alignment: .leading, spacing: PodableTheme.spacingS) {
            PodableInfoCard {
                HStack(alignment: .center, spacing: PodableTheme.spacingM) {
                    Image(systemName: commanderStore.commanders.count == 0 ?
                          "person.text.rectangle.trianglebadge.exclamationmark" :
                            "person.text.rectangle")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(commanderStore.commanders.count == 0 ? Color.orange : Color.green)
                    .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(commanderStore.commanders.count) Commanders")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if let last = commanderStore.lastUpdateDate {
                            Text("Updated \(last.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.right")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.secondary)
                    }
                    .foregroundStyle(Color.orange)
                }
                .onTapGesture {
                    showingStatistics = true
                }
                .sheet(isPresented: $showingStatistics) {
                    StatisticsView(statistics: commanderStore.statistics)
                }
                .padding(PodableTheme.spacingM)
                
            }
            //Spacer(minLength: .zero)
            
            Button(action: {
                withAnimation(.spring(duration: 0.05)) {
                    isLoading = true
                }
                Task {
                    await commanderStore.refreshFromScryfall()
                    withAnimation(.spring(duration: 0.75)) {
                        isLoading = false
                    }
                }
            }) {
                HStack(spacing: PodableTheme.spacingS) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    
                    Text(isLoading ? "Updating..." : "Update Commander List")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if !isLoading {
                        Text("(\(formatBytes(commanderStore.lastDownloadSize ?? 15_000_000)))")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    } else {
                        Text("\(Int(scryfallService.progress * 100))%")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, PodableTheme.spacingS)
                .background(
                    RoundedRectangle(cornerRadius: PodableTheme.radiusM)
                        .fill(isLoading ? Color.gray : Color.indigo)
                )
                .foregroundColor(.white)
            }
            .padding(PodableTheme.spacingM)
            .disabled(isLoading)
        }
    }
    
}

// MARK: - Category Button
struct CategoryButton: View {
    let category: StatsCategory
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            // ── info card container via unified theme ──
            PodableInfoCard {
                HStack(spacing: PodableTheme.spacingM) {
                    Image(systemName: category.icon)
                        .font(.title2)
                        .foregroundStyle(Color.orange.gradient)
                        .frame(width: 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(category.rawValue)")
                            .font(.headline)
                            .foregroundStyle(Color.primary)
                        
                        Text(category.description)
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.secondary)
                }
                .padding(PodableTheme.spacingM)
            }
        }
        .buttonStyle(.plain)
    }
}


// MARK: - Preview
#Preview {
    DataStatsMainView()
}

// MARK: - Preview
#Preview {
    DataStatsMainView.shared.initDownloadCommanders
}
