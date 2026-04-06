import SwiftUI
import SwiftData
import Podwork

@MainActor
public struct FetchrView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Bindable var commanderStore = CommanderStore.shared
    @StateObject private var scryfallService = CommanderStore.shared.scryfallService
    @State private var selectedName: String = ""
    @State private var isPresented: Bool = false
    @State private var isLoading: Bool = false
    @State private var showingStatistics = false
    @State private var showingCommander = false
    @State var onReturn : (() -> Void)?
    @State var animationOpacity : Double = 0.5
    @State var containerSize: CGSize = UIScreen.main.bounds.size
    private let userDefaults = UserDefaults.standard
    
    @State private var showingErrorAlert = false
    @State private var errorMessage: String = ""

    public init(onReturn: (() -> Void)? = nil){
        self.onReturn = onReturn
    }
    
    public var body: some View {
        
        VStack(alignment: .leading, spacing: 8) {
            HStack( alignment: .top, spacing: 40){
                ZStack{
                    HStack{
                        Text("Fetchr")
                            .font(.largeTitle)
                            .bold()
                        Spacer(minLength: .zero)
                    }
                    
                    Spacer(minLength: .zero)
                        HStack{
                            Spacer(minLength: .zero)
                            Image(systemName: isLoading ? "cloud" : "cloud")
                                .rotationEffect( .degrees(0))
                                .foregroundStyle(Color.indigo.gradient)
                                .offset(x: -10, y: 0)
                                .font(.title)
                                .scaleEffect(x: 2.0, y: 2.0)
                        }
                        .animation(
                            .easeInOut(duration: 0.050).repeatForever(autoreverses: isLoading),
                            value: scryfallService.progress
                        )

                }
            }
            
            HStack (alignment: .center, spacing: 30){
                VStack(alignment: .leading, spacing: 16){

                    VStack(alignment: .leading){
                        if commanderStore.isLoaded {
                            HStack{
                                Text("\(commanderStore.commanders.count) Commanders loaded")
                                    .font(.caption)
                                //.foregroundColor(.secondary)
                      
                                    Image(systemName: commanderStore.commanders.count == 0 ? "person.text.rectangle.trianglebadge.exclamationmark" : "person.text.rectangle")
                                        .symbolRenderingMode(.hierarchical)
                                        .foregroundStyle( commanderStore.commanders.count == 0 ? Color.orange : Color.green)
                            }
                        }
                        
                        if let last = commanderStore.lastUpdateDate {
                            Text("Last Update: \(last.formatted(date: .abbreviated, time: .shortened))")
                            //Text("Last updated \(last, style: .date) at \(last, style: .time)")
                            .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                    }
                    // Action buttons
                    VStack(alignment: .leading, spacing: 26) {
             
                        Button(action: {
                            withAnimation(.spring(duration:0.05)) {isLoading = true
                                Task {
                                    animationOpacity = scryfallService.progress
                                    await commanderStore.refreshFromScryfall()
                                    withAnimation(.spring(duration:0.75)) {isLoading = false}
                                }}
                        }) {
                            
                            Label{
                                HStack(alignment:.lastTextBaseline){
                                    Text(isLoading ? "Updating" : "Update - download")
                                        .minimumScaleFactor(0.95)
                                        .lineLimit(1)
                                    
                                    
                                    HStack(alignment:.lastTextBaseline){
                                        if isLoading {
                                            var progPercent = scryfallService.progress
                                            Text("\(Int(progPercent * 100))%")
                                                .foregroundColor(Color.orange.opacity(0.8))
                                                .animation(
                                                    .easeInOut(duration: 0.050), value: scryfallService.progress)
                                            
                                        
                                                .onReceive(scryfallService.$progress) { newValue in
                                                    progPercent = newValue
                                                }

                                        }
                                        
                                        let bytes = commanderStore.lastDownloadSize ?? 15_000_000
                                            
                                            Text("(\(formatBytes(bytes)))")
                                                .foregroundStyle(.secondary)
                                                .bold()
                                        
                                    }
                                }
                                .lineLimit(1)
                                .minimumScaleFactor(0.9)
                            }
                                    
                            icon: {
                                if isLoading {
                                    ProgressView(value: scryfallService.progress)
                                        .progressViewStyle(.circular)
                                        .tint(.purple)
                                } else {
                                    Image(systemName: isLoading ?
                                          //"arrow.clockwise" :
                                          "circle.lefthalf.striped.horizontal" :
                                            "circle.lefthalf.striped.horizontal.inverse") }
                            }
                                    

                        }
                    }
                    .disabled(isLoading)
                    
                    Button(action: { showingStatistics.toggle() }) {
                        Label{ Text("Color Identity Details")
                                .minimumScaleFactor(0.95)
                                .lineLimit(1)
                        }
                        icon: { Image(systemName: "book") }
                    }
                    
                    HStack (alignment: .firstTextBaseline, spacing: isLoading ? 28 : 22){
                        Button(action: {isPresented.toggle()}) {
                            Label{ Text("Find a Commander")
                                    .minimumScaleFactor(0.95)
                                    .lineLimit(1)
                            }
                            icon: { Image(systemName: "text.page.badge.magnifyingglass") }
                        }
                    }
                    
                    
                    Button(action: {
                        print("returning from fetchr")
                        dismiss()} )
                    {
                    Label { Text("Done")
                            .minimumScaleFactor(0.95)
                            .lineLimit(1)
                    }
                    icon: { Image(systemName: isLoading ? "pawprint" : "dog" )}
                    }
                }
                
                if isLoading{

                    VStack(alignment: .leading){
                        ForEach(0..<3){ k in
                            let i : Double = pow(-1.0, Double(k))
                            HStack (alignment: .bottom, spacing: 0){
                                ForEach(k..<(3)){ n in
                                    
                                    Image(systemName: "pawprint.fill")
                                        .rotationEffect( .degrees(91))
                                        .foregroundStyle(Color.indigo.gradient)
                                        .offset(x: 0, y: 5)
                                        .opacity(scryfallService.progress)
                                    Image(systemName: "pawprint.fill")
                                        .rotationEffect( .degrees(91))
                                        .offset(x: 0, y: -5)
                                        .foregroundStyle(Color.indigo.gradient)
                                        .opacity(scryfallService.progress)
                                    
                                }
                                .font(.system(size: 8))
                                .animation(
                                    //.easeInOut(duration: 1.50).repeatForever(autoreverses: isLoading), value: animationOpacity)
                                    .easeInOut(duration: 0.50), value: scryfallService.progress)
                                
                            }
                            .padding(3)
                            .scaleEffect(x: 1.350, y: 0.870)

                            .rotationEffect( .degrees( ((-18 + Double(2*k)) * i) + (Double(k) * 180.0)))
                        }
                    }
                    .rotationEffect( .degrees( (10)))
                }
                
              
            }
            .sheet(isPresented: $showingStatistics) {
                StatisticsView(statistics: commanderStore.statistics)
            }
            
            .sheet(isPresented: $isPresented) {
                SelectCommanderView(
                    selectedName: $selectedName,
                    isPresented: $isPresented
                )
            }
        
            .onChange(of: isPresented, {
                print("isPresented has changed:",  isPresented, "selected name:", selectedName, "showcmdr:", showingCommander)
                if !isPresented {
                    if selectedName != "Not Entered" {
                        showingCommander = true
                        return }
                }
            showingCommander = false
            })
            .sheet(isPresented:  $showingCommander  ) {
                CommanderDetailView(
                    commanderName: selectedName
                )
            }
            Text(" ")
            HStack(alignment: .lastTextBaseline, spacing:2){
                Text("Data provided by")
                    .foregroundColor(Color.secondary)

                Text("Scryfall")
                    .foregroundColor(Color.purple.opacity(0.75))
                    .onTapGesture {
                        if let url = URL(string: "https://scryfall.com") {
                            UIApplication.shared.open(url)
                        }
                    }
//                Text("for more")
//                    .foregroundColor(Color.secondary)

                }
                .font(.caption)
                .frame(maxWidth: .infinity)
            
                //.border(.red)
                .alert("Download Error", isPresented: $showingErrorAlert, actions: {
                    Button("OK", role: .cancel) {}
                }, message: {
                    Text(errorMessage)
                })

        }
        .padding()
        //.frame(maxWidth: 0.85*containerSize.width)
        .frame(maxWidth: .infinity)
        .onAppear { commanderStore.setup(with: modelContext) }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5).gradient)
                .stroke(Color.black, lineWidth: 1)
                .background(Color.clear)
        )
        .onChange(of: commanderStore.loadingError ){ oldValue, newValue in
            if let error = newValue {
                errorMessage = error
                showingErrorAlert = true
            }
        }

    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Commander Detail View
struct CommanderDetailView: View {
    let commanderName: String
    @StateObject private var dataManager = GameDataManager.shared
    @Bindable var commanderStore = CommanderStore.shared
    var commanderSelected: [ScryfallCommander] {
        let names = commanderName.components(separatedBy: " // ")
        return names.compactMap { name in
            commanderStore.commanders.first { $0.name == name }
        }
    }
    
    var cmdrStats : CommanderSummary? {
        dataManager.commanderStats[commanderName]
    }
    var playRate: Double? {
        dataManager.playrate(for: commanderName)
    }
    
    @ViewBuilder
    var performanceCard : some View {
        if cmdrStats != nil, playRate != nil {
            CommanderPerformanceCard(commander: commanderName, stats: cmdrStats!, playRate: playRate!)
        }
    }
    
    @ViewBuilder
    var cmdrDescription : some View {
        ForEach(commanderSelected, id: \.name) { commander in
            VStack(alignment: .leading, spacing: 8) {
                Text(commander.name)
                    .font(.title2)
                    .bold()
                
                HStack {
                    Label("\(commander.cmc) CMC", systemImage: "circle.hexagongrid.fill")
                    Spacer()
                    Text(commander.colorDescription)
                        .foregroundColor(.secondary)
                }
                
                if commander.hasPartner {
                    Label("Has Partner ability", systemImage: "person.2")
                        .foregroundColor(.blue)
                }
                
                if let partnersWith = commander.partnersWith, partnersWith != "partner" {
                    Label("Partners with: \(partnersWith)", systemImage: "link")
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
        }
    }
    
    
    @ViewBuilder
    var turnDurationsCard: some View {
        if cmdrStats != nil {
            TurnAnalysisRow(commander: commanderName,
                            cmdrSummary: cmdrStats!)
        }
    }
    
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                cmdrDescription
                performanceCard
                turnDurationsCard
            }
            .padding()
        }
        .navigationTitle("Commander Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var sortedCommanders: [(String, CommanderSummary)] {
        dataManager.commanderStats.sorted{ $0.key < $1.key }
            .sorted{ $0.value.wins > $1.value.wins }
            .sorted(by: { $0.value.games > $1.value.games })
    }
}


// MARK: - Statistics View
// MARK: - Statistics View
struct StatisticsView: View {
    let statistics: CommanderIdentityStatistics
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("OVERVIEW") {
                    LabeledContent("Total Commanders", value: "\(statistics.totalCommanders)")
                    LabeledContent("Average CMC", value: statistics.formattedAverageCMC + "  ±" + statistics.formattedCMCstdev)
                }
                .listRowSeparatorTint(Color.white, edges: .all)
                
            
                
                sectionView("COLORLESS", combos: noColorCombos)
                sectionView("MONO-COLOR", combos: monoColorCombos)
                sectionView("TWO-COLOR", combos: twoColorCombos)
                sectionView("THREE-COLOR", combos: threeColorCombos)
                sectionView("FOUR-COLOR", combos: fourColorCombos)
                sectionView("FIVE-COLOR", combos: ["WUBRG"])
                
                
                Section("PARTNERS") {
                    LabeledContent("Partner Commanders", value: "\(statistics.partnersCount) (\(String(format: "%.1f%%", statistics.partnerPercentage)))")
                }
                .listRowSeparatorTint(Color.white, edges: .all)
                
                
                Section("Special Names") {
                    LabeledContent("Needs Accents / Non-ASCII", value: "\(statistics.specialNameCount)")
                    LabeledContent("ASCII-safe", value: "\(statistics.asciiSafeCount)")
                }
                
                
            }
            //.listStyle(.plain) // bars & spaces between sections in sectionView
            //.listStyle(.automatic) // island style section around sections in section view
            .listStyle(.grouped) // section around items, extends to edge
            //.listStyle(.inset) // No seperation of sections (default?)
            //.listStyle(.insetGrouped) // island style section around sections in section view - smaller section items?
            //.listStyle(.sidebar) //
            
            
            .navigationTitle("Commander Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Section Builder
    
    private func sectionView(_ title: String, combos: [String]) -> some View {
        let total = combos.reduce(0) { $0 + (statistics.colorBins[$1]?.count ?? 0) }
        
        let fullCMC = combos.flatMap{ statistics.colorBins[$0]?.rawCMC ?? [] }
        let avgCMCsection = fullCMC.mean
        let stdCMCsection = fullCMC.standardDeviation
        

        let percent = statistics.totalCommanders > 0 ? Double(total) / Double(statistics.totalCommanders) * 100 : 0
        
        return Section(header:
            VStack{
            HStack{
                Spacer()
                Text("percent   ")
                Text("total")
                Text("avg CMC ±std")
            }
            .font(Font.system(.caption).smallCaps())
            
            HStack{
                Text("\(title):")
                Spacer()
                Text("\(String(format: "%.1f", percent))%   ")
                Text("   \(total)   ")
                //Text("   (\(String(format: "%.1f", avgCMC)))  \t")
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("    \(String(format: "%.1f", avgCMCsection))")
                    Text(" ±\(String(format: "%.1f", stdCMCsection))")
                        .font(.caption)
                        .foregroundColor(.secondary)
              
                }
            }
            
            
        }) {
            ForEach(combos, id: \.self) { combo in
                let colors = combo.manaColors
                statRow(for: combo)
                    .listRowBackground(LinearGradient(
                        colors: colors.isEmpty ? [.gray.opacity(0.3)] : colors.map { $0.opacity(0.5) },
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                
                    .listRowSeparatorTint(Color.white, edges: .all)
            }
        }
    }
    
    
    // MARK: - Row
    
    private func statRow(for combo: String) -> some View {
        guard let bin = statistics.colorBins[combo] else { return AnyView(EmptyView()) }
        
        let label = ScryfallCommander.commonColorCombinations[combo] ?? combo
        let colors = combo.manaColors
        
        return AnyView(
            HStack(spacing: 8){
                
                Text(label)
                    .bold()
                    .foregroundColor(Color.white)
                    .customStroke(color: Color.black, width: 0.5)
                    .frame(alignment: .leading)
                
                HStack(){
                    HStack(spacing: 2) {
                            ForEach(colors.indices, id: \.self) { i in
                                Circle()
                                    .fill(colors[i])
                                    .frame(width: 16, height: 16)
                                    .overlay(Circle()
                                        .stroke( colors[i] == Color.black ? Color.white :
                                            Color.black, lineWidth: 0.75))
                            }
                        }
                }
    
                Spacer(minLength: .zero)
                
                Text("\(bin.count)  ")
                    .bold()
                    .foregroundColor(Color.white)
                    .customStroke(color: Color.black, width: 0.5)
                
                //Spacer(minLength: 5)
//                Text("  (\(String(format: "%.1f", bin.avgCMC)))")
//                    .bold()
//                    .foregroundColor(Color.white)
//                    .customStroke(color: Color.black, width: 0.5)
//                
                // Average CMC ± Std Dev
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("    \(String(format: "%.1f", bin.avgCMC))")
                        .bold()
                        .foregroundColor(Color.white)
                        .customStroke(color: Color.black, width: 0.5)
                    Text(" ±\(String(format: "%.1f", bin.stdCMC))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(6)
            //.frame(maxWidth: .infinity)
//            .background(
//                LinearGradient(
//                    colors: colors.isEmpty ? [.gray.opacity(0.3)] : colors.map { $0.opacity(0.3) },
//                    startPoint: .leading,
//                    endPoint: .trailing
//                )
//                .cornerRadius(6)
//            )
            
        )
    }
    
    // MARK: - Combo Groups

    private var noColorCombos: [String] { ["C"] }
    private var monoColorCombos: [String] { ["W","U","B","R","G"] }
    private var twoColorCombos: [String] { ["WU","WB","WR","WG","UB","UR","UG","BR","BG","RG"] }
    private var threeColorCombos: [String] { ["WUB","WUR","WUG","WBR","WBG","WRG","UBR","UBG","URG","BRG"] }
    private var fourColorCombos: [String] { ["WUBR","WUBG","WURG","WBRG","UBRG"] }
}





/*
// MARK: - Statistics View
struct StatisticsView: View {
    let statistics: CommanderStatistics
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Overview") {
                    LabeledContent("Total Commanders", value: "\(statistics.totalCommanders)")
                    LabeledContent("Average CMC", value: statistics.formattedAverageCMC)
                }
                
                Section("Colors") {
                    LabeledContent("Unique Color Identities", value: "\(statistics.uniqueColors)")
                    LabeledContent("Colorless", value: "\(statistics.colorlessCommanders)")
                    LabeledContent("Multicolor", value: "\(statistics.multicolorCommanders) (\(String(format: "%.1f%%", statistics.multicolorPercentage)))")
                }
                
                Section("Partners") {
                    LabeledContent("Partner Commanders", value: "\(statistics.partnersCount) (\(String(format: "%.1f%%", statistics.partnerPercentage)))")
                }
            }
            .navigationTitle("Commander Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
 */

/* Struc Structure
 

 // MARK: - Statistics Model
 struct CommanderStatistics {
 let totalCommanders: Int
 let colorlessCommanders: Int
 let multicolorCommanders: Int
 let partnersCount: Int
 let uniqueColors: Int
 let averageCMC: Double
 let colorIdentityDistribution: [String: Int]
 
 var formattedAverageCMC: String {
 String(format: "%.1f", averageCMC)
 }
 
 var multicolorPercentage: Double {
 totalCommanders > 0 ? Double(multicolorCommanders) / Double(totalCommanders) * 100 : 0
 }
 
 var partnerPercentage: Double {
 totalCommanders > 0 ? Double(partnersCount) / Double(totalCommanders) * 100 : 0
 }
 
 static func fromCommanders(_ commanders : [ScryfallCommander]) -> CommanderStatistics {
 let colorlessCount = commanders.filter { $0.colorIdentity.isEmpty }.count
 let multicolorCount = commanders.filter { $0.colorIdentity.count > 1 }.count
 let partnerCount = commanders.filter { $0.hasPartner }.count
 let uniqueColors = Set(commanders.map { $0.colorIdentity }).count
 let averageCMC = commanders.isEmpty ? 0 : Double(commanders.reduce(0) { $0 + $1.cmc }) / Double(commanders.count)
 
 var colorIdentityBins : [String:Int] = [:]
 commanders.forEach {
 colorIdentityBins[String($0.colorIdentity), default: 0] += 1
 }
 
 return CommanderStatistics(
 totalCommanders: commanders.count,
 colorlessCommanders: colorlessCount,
 multicolorCommanders: multicolorCount,
 partnersCount: partnerCount,
 uniqueColors: uniqueColors,
 averageCMC: averageCMC,
 colorIdentityDistribution: colorIdentityBins
 )
 
 }
 }
 */



// MARK: - Preview
#Preview {
    FetchrView()
        .modelContainer(for: [ScryfallCommander.self], inMemory: true)
}
