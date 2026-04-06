import SwiftUI
import SwiftData


public struct SelectCommanderView: View {
    @Binding public var selectedName: String
    @Binding public var isPresented: Bool
    
    @Environment(\.modelContext) private var modelContext
    @Bindable public var commanderStore = CommanderStore.shared
    
    @State private var commanderName: String = ""
    @State private var partnerName: String = ""
    @State private var searchLetters: String = ""
    @State private var filteredCommanders: [ScryfallCommander] = []
    
    @State private var isPickingPartner = false
    @State private var hasPickedCommander = false
    @State private var showUsePartnerPrompt = false
    @State private var suggestedPartner: String = ""
    @State private var showAskToPickPartnerPrompt = false
    
    @State private var initialName : String = ""
    let steelGray = Color(white: 0.2745)
    
    let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".map { String($0) }
    
    let accentVariants: [String: [String]] = [
        "A": ["Á", "À", "Â", "Ä", "Æ"],
        "C": ["Ç"],
        "E": ["É", "È", "Ê", "Ë"],
        "I": ["Í", "Ì", "Î", "Ï"],
        "O": ["Ó", "Ò", "Ô", "Ö", "Ø"],
        "U": ["Ú", "Ù", "Û", "Ü"],
        "Y": ["Ý", "Ÿ"],
    ]
    
    let nonLetterVariants: [String: [String]] = [
        "_": ["-", "?", "@", "\\", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
    ]

    let letterButtonSize = 35.0
    let nLetterColumns = 4
    let nListNames = 27// 12
    
    let generator = UIImpactFeedbackGenerator(style: .medium)
    
    private func mediumForceHapticFeedback() {
        generator.impactOccurred()
    }
    
    public init(selectedName: Binding<String>, isPresented: Binding<Bool>) {
        self._selectedName = selectedName
        self._isPresented = isPresented
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            if !showUsePartnerPrompt && !showAskToPickPartnerPrompt && !hasPickedCommander {
                if !(filteredCommanders.count <= nListNames && !filteredCommanders.isEmpty) {
                    Spacer(minLength: .zero)
                    
                    // Letter grid
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 4),
                        count: nLetterColumns),
                        spacing: 4) {
                            
                        ForEach(alphabet, id: \.self) { letter in
                            Button(action: {
                                mediumForceHapticFeedback()
                                searchLetters.append(letter)
                                filterCommanders()
                            }) {
                                Text(letter)
                                    .bold()
                                    .foregroundColor(Color.white)
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: letterButtonSize)
                                    .background(Color.blue.tertiary)
                                    .cornerRadius(8)
                            }
                            .contextMenu {
                                if let variants = accentVariants[letter] {
                                    ForEach(variants, id: \.self) { variant in
                                        Button(variant) {
                                            searchLetters.append(variant)
                                            filterCommanders()
                                        }
                                    }
                                }
                            }
                            .foregroundColor(Color.white)
                            .background(Color.blue.tertiary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .frame(height: letterButtonSize)
                            .cornerRadius(4)
                        }
                        
                        Button(action:  {
                            mediumForceHapticFeedback()
                            searchLetters.append(" ")
                            filterCommanders()
                        }) {
                            Text("_")
                                .foregroundColor(Color.white)
                                .bold()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.gray.tertiary)
                                .cornerRadius(8)
                        }
                        .contextMenu {
                            if let variants = nonLetterVariants["_"] {
                                ForEach(variants, id: \.self) { variant in
                                    Button(variant) {
                                        searchLetters.append(variant)
                                        filterCommanders()
                                    }
                                }
                            }
                        }
                  
                        
                        Button(action: {
                            mediumForceHapticFeedback()
                            if !searchLetters.isEmpty {
                                searchLetters.removeLast()
                                filterCommanders()
                            }
                        }) {
                            Text("⌫")
                                .foregroundColor(Color.white)
                                .bold()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.red.tertiary)
                                .cornerRadius(8)
                        }
                    }
                }
                
                if filteredCommanders.count <= nListNames && !filteredCommanders.isEmpty {
                    List(filteredCommanders, id: \.name) { commander in
                        Button(commander.name) {
                            if isPickingPartner {
                                partnerName = commander.name
                                suggestedPartner = commander.name
                                showUsePartnerPrompt = true
                            } else {
                                commanderName = commander.name
                                handleCommanderSelection(commander)
                            }
                            mediumForceHapticFeedback()
                            searchLetters = ""
                            filteredCommanders = []
                        }
                    }
                    .listStyle(PlainListStyle())
                } else {
                    HStack(alignment: .firstTextBaseline){
                        Text("Search: ")
                            .font(.title2)
                            .bold()
                        Text("\(searchLetters)")
                            .font(.title2)
                    }
                    .foregroundColor(Color.white)
                }
            }
            
            if !commanderName.isEmpty && !isPickingPartner && hasPickedCommander && !showUsePartnerPrompt && !showAskToPickPartnerPrompt {
                Text("Commander:")
                    .bold()
                    .foregroundColor(Color.white)
                Text(commanderName)
                    .bold()
                    .foregroundColor(Color.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            
            if showUsePartnerPrompt { partnerPromptView }
            
            if showAskToPickPartnerPrompt { askPartnerPromptView }
            
            HStack(spacing: 30) {
                if !showUsePartnerPrompt && !isPickingPartner && !showAskToPickPartnerPrompt && hasPickedCommander {
                    Button("Ok") {
                        mediumForceHapticFeedback()
                        finalizeSelection()
                    }
                    .bold()
                    .foregroundColor(Color.green)
                    .padding(.bottom, 16)
                }
                
                Button("Cancel") {
                    mediumForceHapticFeedback()
                    resetSelection()
                }
                .foregroundColor(Color.red)
                .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity)
        }
        .background(steelGray)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            commanderStore.setup(with: modelContext)
            initialName = selectedName
        }
    }
    
    // MARK: - View Components
    
    private var partnerPromptView: some View {
        VStack(spacing: 8) {
            Spacer()
            
            Text("Commander:")
                .foregroundColor(.white)
            Text(commanderName)
                .bold()
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            
            Spacer()
            
            Text("Use Partner:")
                .foregroundColor(.white)
            Text("\(suggestedPartner)?")
                .foregroundColor(.white)
                .bold()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            
            HStack (spacing: 24){
                Button("Yes") {
                    mediumForceHapticFeedback()
                    partnerName = suggestedPartner
                    finalizeSelection()
                }
                .foregroundColor(Color.green)
                
                Button("No") {
                    mediumForceHapticFeedback()
                    finalizeSelection()
                }
                .foregroundColor(Color.red)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    private var askPartnerPromptView: some View {
        VStack(spacing: 8) {
            Spacer()
            
            Text("Commander:")
                .foregroundColor(Color.white)
            Text(commanderName)
                .bold()
                .foregroundColor(Color.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            
            Spacer()
            
            Text("Would you like to choose a partner?")
                .foregroundColor(Color.white)
                .bold()
            
            HStack (spacing: 24) {
                Button("Yes") {
                    mediumForceHapticFeedback()
                    isPickingPartner = true
                    showAskToPickPartnerPrompt = false
                    filterToPartnerEligibleCommanders()
                }
                .foregroundColor(Color.green)
                .bold()
                
                Button("No") {
                    mediumForceHapticFeedback()
                    finalizeSelection()
                }
                .foregroundColor(Color.red)
                .bold()
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helper Methods

    private func filterCommanders() {
        guard !searchLetters.isEmpty else {
            filteredCommanders = []
            return
        }
        
        let foldedSearch = searchLetters.foldingForSearch
        
        if isPickingPartner {
            filteredCommanders = commanderStore.partnerEligibleCommanders().filter {
                $0.name.foldingForSearch.hasPrefix(foldedSearch)
            }
        } else {
            filteredCommanders = commanderStore.commanders.filter {
                $0.name.foldingForSearch.hasPrefix(foldedSearch)
            }
        }
    }
    private func checkCommanderCoverage() {
        for commander in commanderStore.commanders {
            let foldedName = commander.name.foldingForSearch
            if !foldedName.allSatisfy({ char in
                alphabet.contains(String(char).uppercased())
                || accentVariants.values.flatMap { $0 }.contains { $0.lowercased() == String(char).lowercased() }
                || char == " "
            }) {
                print("⚠️ Missing support for commander: \(commander.name)")
            }
        }
    }

 
    private func filterToPartnerEligibleCommanders() {
        /// Get the selected commander to check for specific partners
        if let commander = commanderStore.commanders.first(where: { $0.name == commanderName }) {
            let eligiblePartners = commanderStore.partnersFor(commander: commander)
            
            /// Reset search and show all eligible partners
            searchLetters = ""
            filteredCommanders = eligiblePartners
        }
    }
    
    private func handleCommanderSelection(_ commander: ScryfallCommander) {
        if let specificPartner = commander.partnersWith, specificPartner != "partner", specificPartner != "doctor" {
            /// Has a specific partner
            suggestedPartner = specificPartner
            showUsePartnerPrompt = true
        } else if commander.hasPartner {
            /// Can partner with any partner commander
            showAskToPickPartnerPrompt = true
        } else {
            /// No partner ability
            hasPickedCommander = true
        }
    }
    
    private func finalizeSelection() {
        var namesToReturn = [commanderName]
        if !partnerName.isEmpty && partnerName != "partner" {
            namesToReturn.append(partnerName)
        }
        selectedName = namesToReturn.joined(separator: " // ")
        isPresented = false
    }
    
    private func resetSelection() {
        searchLetters = ""
        filteredCommanders = []
        commanderName = ""
        partnerName = ""
        //selectedName = "Not Entered"
        selectedName = initialName
        isPickingPartner = false
        hasPickedCommander = false
        showUsePartnerPrompt = false
        showAskToPickPartnerPrompt = false
        isPresented = false
    }
}

extension String {
    var foldingForSearch: String {
        self.folding(options: .diacriticInsensitive, locale: .current).lowercased()
    }
}

// MARK: - Preview
struct SelectCommander_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State private var selectedName: String = ""
        @State private var isPresented: Bool = true
        
        var body: some View {
            SelectCommanderView(
                selectedName: $selectedName,
                isPresented: $isPresented
            )
        }
    }
    
    static var previews: some View {
        PreviewWrapper()
            .preferredColorScheme(.dark)
            .modelContainer(for: ScryfallCommander.self, inMemory: true)
    }
}
