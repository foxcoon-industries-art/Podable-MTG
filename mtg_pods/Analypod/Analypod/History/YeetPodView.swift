import SwiftUI
import SwiftData
import Podwork
import CryptoKit




public extension Array where Element == (FinalPod, [Turn]) {
    func excludingDemoData() -> [(FinalPod, [Turn])] {
        return self.filter { pod, _ in
            !pod.gameID.hasPrefix("DEMO---")
        }
    }
}


// MARK: - YeetPodView
@MainActor
public struct YeetPodView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) public var dismiss
    
    public  let userDefaults = UserDefaults.standard
    
    @StateObject public var sentPodHistory = SentPodsHistory()
    @StateObject public  var dataManager = GameDataManager.shared
    
    @State private var yeetr = Yeetr()
    @State private var podsToYeet: [(FinalPod,[Turn])] = []
    
    
    @State private var showPodHistoryMap: Bool = false
    @State private var turnHistoryCache: [String: [Turn]] = [:]
    @State public var podCasts: [PodCastHistory] = []
    public var podToShow: FinalPod? {
        let podWithTurns = podsToYeet.filter{ $0.0.gameID == podSelectedForHistory }
        return podWithTurns.first?.0
    }
    public var turnToShow: [Turn]? {
        let podWithTurns = podsToYeet.filter{ $0.0.gameID == podSelectedForHistory }
        return podWithTurns.first?.1
    }
    @State var isPodRotated: Bool = false
    
    // UI & state
    @State private var isPresented: Bool = false
    @State private var isYeeting: Bool = false
    @State private var successfulYeet: Bool = false
    @State private var showingStatistics = false
    @State private var yeetProgress: Double = 0.0
    @State private var currentlyYeeting: String = ""
    @State public var containerSize: CGSize = UIScreen.main.bounds.size
    
    // Selection / passes
    @State private var selectedPodIDs: Set<String> = []
    @State private var attachPassForPod: [String: Bool] = [:]
    @State private var selectAll: Bool = false
    @State private var showYeetSelect: Bool = false
    @State private var purchasePodPasses: Bool = false
    
    @State private var podSelectedForHistory: String?
    
    // Pod Pass validation
    @State private var podPassEligibility: [String: Bool] = [:]
    @State private var podPassValidationMessages: [String: [String]] = [:]
    
    // Query existing saved PodPassEntities (so UI can reflect existing passes)
    @Query private var storedPodPasses: [PodPassEntity]
    
    var availablePodPasses: Int {
        sentPodHistory.getPodPassBalance()
    }
    
    var prevYeetedPods : [String] {
        return sentPodHistory.acceptedPodIDs()
    }
    
    var failedPodsToRetry: [(FinalPod,[Turn])] {
        let failedIDs = Set(sentPodHistory.failedPodIDs())
        return podsToYeet.filter { failedIDs.contains($0.0.gameID) }
    }
    
    var reducedPodsToYeet: [(FinalPod,[Turn])] {
        let podIDs = prevYeetedPods
        return podsToYeet.filter { !podIDs.contains( $0.0.gameID) }
    }
    
    var combinedPodsToYeet: [(FinalPod,[Turn])] {
        /// Combine new pods with failed pods for retry
        let newPods = reducedPodsToYeet
        let retryPods = failedPodsToRetry
        
        /// Use Set to avoid duplicates
        var uniquePodIDs = Set<String>()
        var combined: [(FinalPod,[Turn])] = []
        
        for pod in newPods + retryPods {
            if !uniquePodIDs.contains(pod.0.gameID) {
                uniquePodIDs.insert(pod.0.gameID)
                combined.append(pod)
            }
        }
        
        return combined
    }
    var currentTotalPodPasses : Int {
        availablePodPasses - totalPodsWithPodPass
    }
    var enoughPassesToAttach: Bool {
        currentTotalPodPasses > 0
    }
    
    var totalPodsWithPodPass : Int {
        attachPassForPod.filter{$0.value}.count
    }
    var totalPodsToPass : Int {
        selectedPodIDs.count
    }
    var totalPodsWithoutPodPass : Int {
        totalPodsToPass - totalPodsWithPodPass
    }

    /// Dynamic cloud icon: reflects whether pods are queued for upload.
    private var headerIcon: String {
        selectedPodIDs.count != 0 ? "cloud.fill" : "cloud.fill"
    }
    
    public init(){}
    
    public var body: some View {

        ScrollView {
            VStack(alignment: .center, spacing: 16) {
                // Commander Pods section
                VStack(alignment: .center, spacing: 0) {
                    PodableSectionHeader(
                        title:     "Pods",
                        icon:      headerIcon,
                        iconColor: .white,
                        style:     .stroke
                    )
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)

                    displayPodsView
                }

                // Duel Match History section
                DuelMatchHistoryView()
                    .environmentObject(dataManager)

                // Tournament History section
                TournamentHistoryView()
                    .environmentObject(dataManager)
            }
        }
        
        .sheet(isPresented: $showingStatistics) {
            SentPods_View(pods: sentPodHistory)
        }
    
        .sheet(isPresented: $showPodHistoryMap) {
            if podToShow != nil, turnToShow != nil, podSelectedForHistory != nil {
                OptimizedGameFlowCard(
                    game: podToShow!,
                    turnHistory: turnToShow! ,
                    on_Appear: {
                        loadTurnHistory(for: podSelectedForHistory!) },
                    podCastHistory: podCasts.select(podSelectedForHistory!),
                    isRotated: isPodRotated
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCompactAdaptation(
                    horizontal: .sheet,
                    vertical: .sheet)
                .onAppear{
                    Task {
                        self.podCasts = (try? await PodCastHistory.loadAll(from: modelContext)) ?? self.podCasts
                    }
                }
            }
        }
    
        .sheet(isPresented: $purchasePodPasses) {
            PodPassInfoView(isPresented: $purchasePodPasses)
                .environmentObject(sentPodHistory)
        }
    
        

        .onAppear {
            dataManager.includeDemoData = false
            dataManager.refreshAllData()
            //podsToYeet = dataManager.loadPodsWithTurnHistory().excludingDemoData()
            
            sentPodHistory.setup(modelContext)
            do{
                try sentPodHistory.loadSentPods()
            }
            catch{
                print("error with loading SentPods: \(error)")
            }

            refreshPodsToYeetState()

            Task {
                self.podCasts = (try? await PodCastHistory.loadAll(from: modelContext)) ?? []
            }
        }
    
        .padding(.horizontal, PodableTheme.marginIPhone/2)
    }
    
    
    //@ViewBuilder
    var selectedPod : any View {
        if podToShow != nil, turnToShow != nil, podSelectedForHistory != nil {
                let viewToShare = AnyView(
                    OptimizedGameFlowCard(
                        game: podToShow!,
                        turnHistory: turnToShow! ,
                        on_Appear: {
                            loadTurnHistory(for: podSelectedForHistory!) },
                        podCastHistory: podCasts.select(podSelectedForHistory!),
                        isRotated: false,
                        exportPod: true
                    ))
                return viewToShare
            }
        return AnyView(HStack{})
    }
    
    
//    func share(_ myView : any View){
//        let image = myView.asImage()
//        //print("sharing")
//        ShareLink(item: image, preview: SharePreview("Podable-Share-Pod", image: Image(uiImage: image))) {
//            Label("Share", systemImage: "square.and.arrow.up")
//        }
//    }
    
    var shareImage: UIImage {
        //guard let shareView = selectedPod else { return UIImage() }
        let shareView = selectedPod
        return shareView.asImage() }
    

    
    
    // MARK: - Pod Flow Toolbar
    @ViewBuilder
    private var displayPodFlowSelectButtons : some View {
        HStack(alignment: .bottom){
            selectAllButton
            //Button(action: {}){Label("Share", systemImage: "square.and.arrow.up").foregroundStyle(Color.blue)}

            
            Button(role: .destructive) {
                deletePod(podSelectedForHistory)
            } label:
            {Label("", systemImage: "trash")
                .foregroundStyle(podSelectedForHistory == nil ? Color.gray : Color.red)}
            .disabled( podSelectedForHistory == nil ? true : false)
            
            Spacer()
            
            ShareLink(item: shareImage, preview: SharePreview("Podable-Pod-Game", image: Image(uiImage: shareImage) ) ) {
                Label("Share", systemImage: "square.and.arrow.up")
                    .imageScale(.small)
                    .padding(.trailing, 6 )
            }
            .disabled( podSelectedForHistory == nil ? true : false)

            
      
            Button(action: {showPodHistoryMap = true}){
                Label("View Pod", systemImage: "rectangle.expand.diagonal")
                .foregroundStyle(podSelectedForHistory == nil ? Color.gray : Color.yellow)}
               // .frame(maxWidth: .infinity)
                .disabled( podSelectedForHistory == nil ? true : false)
            
    
        }
    }
    
    
    @ViewBuilder
    private var selectAllButton : some View {
        Button(action: {
            selectAll.toggle()
            if selectAll {
                selectedPodIDs = Set(combinedPodsToYeet.map { $0.0.gameID })
            } else {
                selectedPodIDs.removeAll()
            }
            for pod in combinedPodsToYeet {
                let id = pod.0.gameID
                if attachPassForPod[id] == nil { attachPassForPod[id] = false }
            }
        }) {
            Label("", systemImage: selectAll ? "checkmark.square.fill" : "checkmark.square")
        }
    }
    
    
    // MARK: - Pod List
    @ViewBuilder
    private var displayPodsView : some View {
        // ── inner card via unified theme ──
        PodableContentCard {
            GroupBox {
                VStack(spacing: PodableTheme.spacingS) {
                    displayPodFlowSelectButtons
                    Divider()
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: PodableTheme.spacingS) {
                            ForEach(groupedByDay(combinedPodsToYeet), id: \.0) { (groupTitle, items) in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(groupTitle).font(.subheadline).fontWeight(.semibold)
                                    ForEach(items, id: \.0.gameID) { pod, turns in
                                        PodSelectionRow(pod: pod,
                                                        turns: turns,
                                                        passesAttachable: enoughPassesToAttach,
                                                        isSelected: selectedPodIDs.contains(pod.gameID),
                                                        attachPass: attachPassForPod[pod.gameID] ?? (hasStoredPass(for: pod.gameID)),
                                                        isPodEligibleForPass: isPodEligibleForPass(pod.gameID),
                                                        validationMessages: getValidationMessages(for: pod.gameID),
                                                        onToggleSelect: { sel in
                                            if sel { selectedPodIDs.insert(pod.gameID) } else { selectedPodIDs.remove(pod.gameID) }
                                            if attachPassForPod[pod.gameID] == nil { attachPassForPod[pod.gameID] = false }
                                        },
                                                        onToggleAttachPass: { attach in
                                            attachPassForPod[pod.gameID] = attach
                                            if attach {selectedPodIDs.insert(pod.gameID)}
                                            if attach && !hasStoredPass(for: pod.gameID) {
                                                if let newPass = PodPassEntity.generate(for: pod.gameID) {
                                                    modelContext.insert(newPass)
                                                }
                                            } else if !attach {
                                                removeStoredPass(for: pod.gameID)
                                                selectedPodIDs.remove(pod.gameID)
                                                attachPassForPod[pod.gameID] = nil
                                            }
                                        })
                                        .overlay( RoundedRectangle(cornerRadius: PodableTheme.radiusS)
                                            .stroke( podSelectedForHistory == pod.gameID ? Color.yellow : Color.clear, lineWidth: 5)
                                            .fill(Color.clear))
                                        
                                        .onTapGesture {
                                            if let selectedPod = podSelectedForHistory, selectedPod == pod.gameID {
                                                podSelectedForHistory = nil
                                            } else { podSelectedForHistory = pod.gameID }
                                        }
                                        .clipShape(RoundedRectangle(cornerRadius: PodableTheme.radiusS))
                                        Divider()
                                    }
                                }
                            }
                        }
                        //.padding(.horizontal, PodableTheme.spacingS)
                       // .padding(.vertical, 14)
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .background(.ultraThinMaterial)
                    
                    Divider()

                    displayButtonsView
                    
                }
                .padding(.horizontal, 0)
            }
            .background(Color.white.gradient.opacity(0.75))
            .background(.ultraThinMaterial)
            .overlay(RoundedRectangle(cornerRadius: PodableTheme.radiusM).stroke(Color.white, lineWidth: 3))
            //.clipShape(RoundedRectangle(cornerRadius: PodableTheme.radiusM))

        }
    }
    
    
    // MARK: - Footer Buttons
    @ViewBuilder
    private var displayButtonsView : some View {
        HStack{
            //Spacer(minLength: .zero)
            VStack(alignment: .trailing, spacing: PodableTheme.spacingS) {
                
                HStack(spacing: 20){
                    
                    Button(action: {
                        showingStatistics.toggle()
                        isYeeting = false
                    }) {
                        Label("Sent", systemImage: "arrow.up.folder")
                    }
                    
                    
                }
            }
            Spacer(minLength: .zero)
            
        }
    }
    
    
    func deletePod(_ podID : String?) -> Void {
        guard let podID else { return }
        Task {
            showPodHistoryMap = false
            removeStoredPass(for: podID)
            selectedPodIDs.remove(podID)
            podSelectedForHistory = nil
            attachPassForPod[podID] = nil
            turnHistoryCache[podID] = nil
            await dataManager.deleteGame(podID)
            await self.podCasts.select(podID).removePod(podID: podID )
            podCasts.removeAll { $0.podID == podID }
            refreshPodsToYeetState()
        }
    }
    
    
    // MARK: - Helpers
    
    @MainActor
    private func loadTurnHistory(for gameID: String) {
        guard turnHistoryCache[gameID] == nil else { return }
        
        Task {
            let history = await dataManager.loadTurnHistory(for: gameID)
            await MainActor.run {
                turnHistoryCache[gameID] = history
            }
        }
    }

    @MainActor
    private func refreshPodsToYeetState() {
        podsToYeet = dataManager.loadPodsWithTurnHistory().excludingDemoData()

        let availableIDs = Set(podsToYeet.map { $0.0.gameID })
        let existingPassSelections = attachPassForPod
        turnHistoryCache = Dictionary(uniqueKeysWithValues: podsToYeet.map { ($0.0.gameID, $0.1) })
        attachPassForPod = Dictionary(uniqueKeysWithValues: availableIDs.map { id in
            (id, existingPassSelections[id] ?? hasStoredPass(for: id))
        })

        selectedPodIDs = Set(selectedPodIDs.filter { availableIDs.contains($0) })
        if selectAll {
            selectedPodIDs = availableIDs
        }

        if let selectedID = podSelectedForHistory,
           availableIDs.contains(selectedID) == false {
            podSelectedForHistory = nil
            showPodHistoryMap = false
        }

        validatePodsForPodPass()
    }

    @MainActor
    private func applyUpdatedPod(_ updatedPod: FinalPod, updatedHistory: PodCastHistory?) {
        if let podIndex = podsToYeet.firstIndex(where: { $0.0.gameID == updatedPod.gameID }) {
            podsToYeet[podIndex] = (updatedPod, podsToYeet[podIndex].1)
        }

        if let updatedHistory {
            if let existingIndex = podCasts.firstIndex(where: { $0.podID == updatedHistory.podID }) {
                podCasts[existingIndex] = updatedHistory
            } else {
                podCasts.append(updatedHistory)
            }
        }

        refreshPodsToYeetState()
    }
    
    private func groupedByDay(_ pods: [(FinalPod,[Turn])]) -> [(String, [(FinalPod,[Turn])])] {
        let grouped = Dictionary(grouping: pods) { (pair: (FinalPod,[Turn])) -> Date in
            Calendar.current.startOfDay(for: pair.0.date)
        }
        
        return grouped.keys.sorted(by: >).map { key -> (String, [(FinalPod,[Turn])]) in
            let items = grouped[key] ?? []
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return (formatter.string(from: key), items)
        }
    }
    
    private func hasStoredPass(for podID: String) -> Bool {
        return storedPodPasses.contains { $0.podID == podID }
    }
    
    private func removeStoredPass(for podID: String) {
        let matches = storedPodPasses.filter { $0.podID == podID }
        for m in matches {
            modelContext.delete(m)
        }
        try? modelContext.save()
    }
    
    private func passesSelectedFilter(_ passEntity: PodPassEntity) -> Bool {
        if let attach = attachPassForPod[passEntity.podID] {
            return attach && selectedPodIDs.contains(passEntity.podID)
        }
        return selectedPodIDs.contains(passEntity.podID)
    }
    
    private func validatePodsForPodPass() {
        podPassEligibility.removeAll()
        podPassValidationMessages.removeAll()

        for (pod, turns) in combinedPodsToYeet {
            let validation = PodPassValidator.validatePodForPass(pod: pod, turns: turns)
            podPassEligibility[pod.gameID] = validation.isValid
            if !validation.isValid {
                podPassValidationMessages[pod.gameID] = validation.failureDescriptions
                if hasStoredPass(for: pod.gameID) {
                    removeStoredPass(for: pod.gameID)
                }
            }
        }
    }
    
    private func isPodEligibleForPass(_ podID: String) -> Bool {
        return podPassEligibility[podID] ?? false
    }
    
    private func getValidationMessages(for podID: String) -> [String] {
        return podPassValidationMessages[podID] ?? []
    }
    
}

// MARK: - PodSelectionRow
public struct PodSelectionRow: View {
    let pod: FinalPod
    let turns: [Turn]
    
    let passesAttachable: Bool
    
    let isSelected: Bool
    let attachPass: Bool
    let isPodEligibleForPass: Bool
    let validationMessages: [String]
    
    let onToggleSelect: (Bool) -> Void
    let onToggleAttachPass: (Bool) -> Void
    
    @State private var showValidationDetails = false
    
    private var shortID: String {
        "\(pod.gameID.prefix(14))...\(pod.gameID.suffix(8))"
    }
    private var shortName: String {
        "\(pod.winningCommander!.name.prefix(36))"
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                Button(action: {
                    onToggleSelect(!isSelected)
                    onToggleAttachPass(!attachPass) 
                }) {
                    Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                        .foregroundStyle( isPodEligibleForPass ? Color.green : Color.blue)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(shortName).font(.caption.monospaced())
                    let date = pod.date
                        HStack {
                            Text(date, style: .date).font(.caption2)
                            Text(date, style: .time).font(.caption2)
                        }.lineLimit(1)
                    
                    Text("\(pod.totalRounds) turns").font(.caption2).foregroundColor(.secondary)
                }
                Spacer(minLength: .zero)
                VStack(alignment: .trailing, spacing: 6) {
                    if isPodEligibleForPass {
                       // Button(action: { onToggleAttachPass(!attachPass) }) {
                       //     Image(systemName: attachPass ? "checkmark.square.fill" : "square")
                        //}
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 20, height: 20)
                        //.foregroundStyle(Color.green)
                        //.disabled( !passesAttachable && !attachPass)
                    } else {
                        Button(action: { showValidationDetails.toggle() }) {
                            Image(systemName: "exclamationmark.triangle.fill")
                        }
                        .frame(width: 20)
                        .foregroundStyle(Color.orange)
                    }
                }
            }
            
            if !isPodEligibleForPass && showValidationDetails {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Missing Details:")
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .bold()
                    ForEach(validationMessages, id: \.self) { message in
                        Text("• \(message)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.leading, 30)
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 6)
        //.background(isSelected ? (!attachPass ? Color.blue.tertiary : Color.green.tertiary) : Color.gray.tertiary)
        .background(isSelected ?  (isPodEligibleForPass ? Color.green.tertiary : Color.blue.tertiary  )  : Color.gray.tertiary )
        .cornerRadius(PodableTheme.radiusS)
    }
}




// MARK: - SentPods_View
public struct SentPods_View: View {
    let pods: SentPodsHistory
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var searchText = ""
    @State private var showOnlyFailed = false
    
    @Query private var podPasses: [PodPassEntity]
    
    private var filteredAcceptedPods: [SentPodsReceipt] {
        if searchText.isEmpty {
            return pods.history
        }
        return pods.history.filter { $0.podID.localizedCaseInsensitiveContains(searchText) }
    }
    
    private var filteredFailedPods: [SentPodsReceipt] {
        if searchText.isEmpty {
            return pods.unacceptedPods
        }
        return pods.unacceptedPods.filter { $0.podID.localizedCaseInsensitiveContains(searchText) }
    }
    
    private var groupedAcceptedByDateAndPass: [Date: (withPass: [SentPodsReceipt], withoutPass: [SentPodsReceipt])] {
        let byDate = Dictionary(grouping: filteredAcceptedPods) { pod in
            Calendar.current.startOfDay(for: pod.timestamp)
        }
        
        var result: [Date: (withPass: [SentPodsReceipt], withoutPass: [SentPodsReceipt])] = [:]
        for (date, receipts) in byDate {
            var withPass: [SentPodsReceipt] = []
            var withoutPass: [SentPodsReceipt] = []
            for r in receipts {
                let hasPass = podPasses.contains(where: { $0.podID == r.podID })
                if hasPass { withPass.append(r) } else { withoutPass.append(r) }
            }
            result[date] = (withPass: withPass.sorted { $0.timestamp > $1.timestamp }, withoutPass: withoutPass.sorted { $0.timestamp > $1.timestamp })
        }
        return result
    }
    
    private var groupedFailedPods: [Date: [SentPodsReceipt]] {
        Dictionary(grouping: filteredFailedPods) { pod in
            Calendar.current.startOfDay(for: pod.timestamp)
        }
    }
    
    public var body: some View {
        NavigationView {
            List {
                Section("YeetPods Overview") {
                    LabeledContent("Total Pods Sent", value: "\(pods.totalSent())")
                    LabeledContent("Accepted", value: "\(pods.totalAcceptedPods())")
                        .foregroundColor(.green)
                    LabeledContent("Failed to Send", value: "\(pods.totalFailedPods())")
                        .foregroundColor(pods.totalFailedPods() > 0 ? .orange : .secondary)
                }
                
                if !filteredAcceptedPods.isEmpty {
                    ForEach(groupedAcceptedByDateAndPass.keys.sorted(by: >), id: \.self) { date in
                        let tuple = groupedAcceptedByDateAndPass[date] ?? ([],[])
                        let withPass = tuple.withPass
                        let withoutPass = tuple.withoutPass
                        Section(header: HStack {
                            Text(date, style: .date)
                            Spacer()
                            Text("\(withPass.count + withoutPass.count)")
                                .foregroundColor(.secondary)
                        }) {
                            if !withPass.isEmpty {
                                DisclosureGroup("With Pod Pass (\(withPass.count))") {
                                    ForEach(withPass, id: \.podID) { pod in
                                        PodReceiptRow(pod: pod, showStatus: false)
                                    }
                                }
                            }
                            if !withoutPass.isEmpty {
                                DisclosureGroup("Without Pod Pass (\(withoutPass.count))") {
                                    ForEach(withoutPass, id: \.podID) { pod in
                                        PodReceiptRow(pod: pod, showStatus: false)
                                    }
                                }
                            }
                        }
                    }
                }
                
                if !filteredFailedPods.isEmpty {
                    Section {
                        ForEach(filteredFailedPods.sorted(by: { $0.timestamp > $1.timestamp }), id: \.podID) { pod in
                            PodReceiptRow(pod: pod, showStatus: true)
                        }
                    } header: {
                        HStack {
                            Text("Failed Pods (Will Retry)")
                            Spacer()
                            Text("\(filteredFailedPods.count)")
                                .foregroundColor(.secondary)
                        }
                    } footer: {
                        Text("These pods will be automatically retried on next yeet.")
                            .font(.caption)
                    }
                }
                
                if filteredAcceptedPods.isEmpty && filteredFailedPods.isEmpty && !searchText.isEmpty {
                    Section {
                        Text("No pods match '\(searchText)'")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Yeet History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if pods.totalFailedPods() > 0 {
                        Button {
                            showOnlyFailed.toggle()
                        } label: {
                            Label(showOnlyFailed ? "Show All" : "Show Failed Only",
                                  systemImage: showOnlyFailed ? "line.3.horizontal.decrease.circle" : "exclamationmark.triangle")
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}


// MARK: - Receipt Row
public struct PodReceiptRow: View {
    let pod: SentPodsReceipt
    let showStatus: Bool
    
    private var statusColor: Color {
        switch pod.statusCode {
        case "201": return .green
        case "409": return .yellow
        case "-1": return .red
        case "400": return .orange
        case "500": return .teal
        default: return .orange
        }
    }
    
    private var statusText: String {
        switch pod.statusCode {
        case "201": return "Accepted"
        case "409": return "Duplicate"
        case "-1": return "Network Error"
        case "400": return "Invalid Data"
        case "500": return "Server Error"
        default: return "Error \(pod.statusCode)"
        }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Pod ID")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(pod.podID.prefix(8))...\(pod.podID.suffix(8))")
                    .font(.caption)
                    .fontDesign(.monospaced)
            }
            
            HStack {
                Text("Sent")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(pod.timestamp, style: .date)
                    .font(.caption2)
                Text(pod.timestamp, style: .time)
                    .font(.caption2)
            }
            
            if showStatus {
                HStack {
                    Text("Status")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Label(statusText, systemImage: statusColor == .green ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundColor(statusColor)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Previews
#Preview {
    YeetPodView()
        .modelContainer(for: [SentPodsReceipt.self, PodPassEntity.self], inMemory: true)
}


// MARK: - Pod Pass Info Sheet
public struct PodPassInfoView: View {
    @EnvironmentObject var sentPodsHistory: SentPodsHistory
    @Binding var isPresented: Bool
    @State private var containerSize : CGSize = UIScreen.main.bounds.size

    
    public var body: some View {
        NavigationView {
            VStack(spacing: PodableTheme.spacingM) {
                
                Text("Pod Passes")
                    .font(.largeTitle)
                    .bold()
                
                ZStack{
                    Image(systemName: "star.circle")
                        .font(.system(size: 80))
                        .foregroundStyle(Color.purple.gradient)
                        .customStroke(color: Color.blue, width: 0.5)

                    
                    Text("\(sentPodsHistory.usablePodPasses.total)")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundStyle(Color.green.gradient)
                        .customStroke(color: Color.black, width: 1)
                    
                }
                Text("Current Balance")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
            
                
                Divider()
                Text("Declare high quality game data!")
                
                                ScrollView{
                                    Text("Pods yeeted with a Pod Pass are high quality games which we use to build high quality stats from the community. Splitting game data into validated and regular sets lets us separate casual pods (which may miss crucial information due to missed actions) with pods who are focused on keeping accurate records. We encourage all pods to be as attentive as possible, but we also understand the reality of playing MTG in person.\n")
                
                                    Text("Before adding a Pod Pass, please check these conditions which may are typically missed during gameplay. \n- The commander was cast before (or during) a turn where a player deals commander damage.\n- Turns do not have unrealistic durations (i.e. too short to even have drawn a card).\n- All commander names have been input for all players (no defaults).\n - All players rated brackets for each player in the aftergame.\n")
                
                                    Text("Please do not attach a Pod Pass to any games that do not meet these minimum criteria.")
                                }
                                .padding()
                                .background(Color.secondary.opacity(0.1))
                                .frame(width: 0.9*containerSize.width, height: 0.2*containerSize.height)
                                .border(Color.orange)
                
                
                // ── info card container via unified theme ──
                PodableInfoCard {
                    VStack(alignment: .leading, spacing: PodableTheme.spacingM) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Earn 1 Pod Pass for each game played!")
                        }
                        
                        HStack {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundColor(.blue)
                            Text("Use Pod Passes to declare special games!")
                        }
                        
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(.orange)
                            Text("Cloud stats help improve the community meta!")
                        }
                    }
                    .padding()
                }
                
                Spacer()
                
                Button("Got It!") {
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationBarItems(trailing: Button("Close") {
                isPresented = false
            })
        }
    }
}
