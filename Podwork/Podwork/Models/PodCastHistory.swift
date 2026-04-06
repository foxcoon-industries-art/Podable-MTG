import Foundation
import SwiftData


@MainActor
public class PodCastHistory: ObservableObject {
    @Published public var podID: String
    @Published public var bombPods: [BombPodExplosion] = []
    @Published public var castTax: [PodCastTax] = []
    @Published public var solRings: [SolRingCasts] = []
    @Published public var finishedSetup: Bool = false
    
    private var modelContext: ModelContext?
    
    public init(podID: String) {
        self.podID = podID
    }

    public init(podID: String, context: ModelContext) {
        self.podID = podID
        self.setup(context)
    }
    
    public func setup(_ context: ModelContext) {
        self.modelContext = context
        self.finishedSetup = true
    }
    
    // MARK: - Load from persistence
    /// Loads all PodCastHistory managers by discovering unique podIDs
    /// from the persisted leaf models.
    public static func loadAll(from context: ModelContext) async throws -> [PodCastHistory] {
        // Fetch all leaf model data
        let bombs = try context.fetch(FetchDescriptor<BombPodExplosion>())
        let taxes = try context.fetch(FetchDescriptor<PodCastTax>())
        let rings = try context.fetch(FetchDescriptor<SolRingCasts>())
        
        // Collect all distinct podIDs
        let allIDs = Set(bombs.map(\.podID) + taxes.map(\.podID) + rings.map(\.podID))
        
        var histories: [PodCastHistory] = []
        
        for id in allIDs {
            let history = PodCastHistory(podID: id)
            history.setup(context)
            
            history.bombPods = bombs.filter { $0.podID == id }
            history.castTax  = taxes.filter { $0.podID == id }
            history.solRings = rings.filter { $0.podID == id }
            
            histories.append(history)
        }
        
        return histories
    }
    
    /// Convenience method to load a single pod history by ID
    public static func load(from context: ModelContext, podID: String) async throws -> PodCastHistory {
        let history = PodCastHistory(podID: podID)
        history.setup(context)
        
        history.bombPods = try context.fetch(FetchDescriptor<BombPodExplosion>(predicate: #Predicate { $0.podID == podID }))
        history.castTax  = try context.fetch(FetchDescriptor<PodCastTax>(predicate: #Predicate { $0.podID == podID }))
        history.solRings = try context.fetch(FetchDescriptor<SolRingCasts>(predicate: #Predicate { $0.podID == podID }))
        
        return history
    }
    
    // MARK: - Save
    public func saveAll() async throws {
        guard let modelContext = modelContext else { return }
        self.bombPods.forEach { modelContext.insert($0) }
        self.castTax.forEach { modelContext.insert($0) }
        self.solRings.forEach { modelContext.insert($0) }
        try modelContext.save()
    }
    
    // MARK: - Add receipts
    public func addBombReceipt(turnID: Int, playerID: Int, increment: Int = 1) throws {
        guard let modelContext = self.modelContext else { print("[Bomb] no model context."); return }
        var bombPod : BombPodExplosion? = nil
        if let existing = bombPods.first(where: { $0.turnID == turnID && $0.playerID == playerID }) {
            existing.total += increment
            bombPod = existing
        } else {
            let newReceipt = BombPodExplosion(podID: self.podID, turnID: turnID, playerID: playerID, total: increment)
            bombPods.append(newReceipt)
            modelContext.insert(newReceipt)
            bombPod = newReceipt
        }
        guard let usedBomb = bombPod else { print("BombPod was NOT created properly.") ; return }
        print("💣 BombPod Used \(usedBomb.total) times! Player: \(playerID), Turn: \(turnID), Pod: \(self.podID)")
        try modelContext.save()
    }
    
    public func addCastTaxReceipt(turnID: Int, playerID: Int, casting: String, isPartner: Bool, increment: Int = 1) throws {
        guard let modelContext = self.modelContext else { print("[Tax] no model context."); return }
        if var existing = castTax.first(where: { $0.turnID == turnID && $0.playerID == playerID && $0.casting == casting }) {
            existing.total += increment
        } else {
            let newReceipt = PodCastTax(podID: self.podID, turnID: turnID, playerID: playerID, casting: casting, isPartner: isPartner, total: increment)
            castTax.append(newReceipt)
            modelContext.insert(newReceipt)
        }
        print("🪄 Commander was Cast! Player: \(playerID), Cast: \(casting), Turn: \(turnID), Pod: \(self.podID)")
        try modelContext.save()
    }
    
    public func removeCastTaxFromReceipt(turnID: Int, playerID: Int, casting: String, isPartner: Bool, increment: Int = 1) throws {
        guard let modelContext = self.modelContext else { print("[Tax] no model context."); return }
        if var existing = castTax.first(where: { $0.turnID == turnID && $0.playerID == playerID && $0.casting == casting }) {
            existing.total -= increment
            if existing.total <= 0 {
                Task { await removeCastTaxReceipt(existing) }
            } else {
                try modelContext.save()
            }
        }
    }

    public func castCount(on turnID: Int, for playerID: Int, isPartner: Bool) -> Int {
        castTax
            .filter { $0.turnID == turnID && $0.playerID == playerID && $0.isPartner == isPartner }
            .reduce(0) { partialResult, receipt in
                partialResult + max(receipt.total, 0)
            }
    }

    public func setCastCount(on turnID: Int, playerID: Int, casting: String, isPartner: Bool, to desiredCount: Int) throws {
        guard let modelContext = self.modelContext else { print("[Tax] no model context."); return }

        let normalizedCount = max(0, desiredCount)
        let normalizedCasting = casting.trimmingCharacters(in: .whitespacesAndNewlines)
        let matchingReceipts = castTax.filter {
            $0.turnID == turnID && $0.playerID == playerID && $0.isPartner == isPartner
        }

        if normalizedCount == 0 {
            for receipt in matchingReceipts {
                if let index = castTax.firstIndex(where: { $0 === receipt }) {
                    castTax.remove(at: index)
                }
                modelContext.delete(receipt)
            }

            try modelContext.save()
            return
        }

        if let keeper = matchingReceipts.first {
            if normalizedCasting.isEmpty == false {
                keeper.casting = normalizedCasting
            }
            keeper.total = normalizedCount

            for duplicate in matchingReceipts.dropFirst() {
                if let index = castTax.firstIndex(where: { $0 === duplicate }) {
                    castTax.remove(at: index)
                }
                modelContext.delete(duplicate)
            }
        } else {
            let receipt = PodCastTax(
                podID: self.podID,
                turnID: turnID,
                playerID: playerID,
                casting: normalizedCasting,
                isPartner: isPartner,
                total: normalizedCount
            )
            castTax.append(receipt)
            modelContext.insert(receipt)
        }

        try modelContext.save()
    }

    public func renameCastReceipts(for playerID: Int, isPartner: Bool, to newName: String) throws {
        guard let modelContext = self.modelContext else { print("[Tax] no model context."); return }

        let normalizedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedName.isEmpty == false else { return }

        let matchingReceipts = castTax.filter { $0.playerID == playerID && $0.isPartner == isPartner }
        guard matchingReceipts.isEmpty == false else { return }

        for receipt in matchingReceipts {
            receipt.casting = normalizedName
        }

        let receiptsByTurn = Dictionary(grouping: matchingReceipts, by: \.turnID)
        for receipts in receiptsByTurn.values where receipts.count > 1 {
            guard let keeper = receipts.first else { continue }

            keeper.casting = normalizedName
            keeper.total = receipts.reduce(0) { partialResult, receipt in
                partialResult + max(receipt.total, 0)
            }

            for duplicate in receipts.dropFirst() {
                if let index = castTax.firstIndex(where: { $0 === duplicate }) {
                    castTax.remove(at: index)
                }
                modelContext.delete(duplicate)
            }
        }

        try modelContext.save()
    }
    
    
    @MainActor
    public func addSolRingReceipt(turnID: Int, playerID: Int, increment: Int = 1) throws {
        guard let modelContext = self.modelContext else { print("[SolRing] no model context."); return }
        if let existing = solRings.first(where: { $0.turnID == turnID && $0.playerID == playerID }) {
            existing.total += increment
        } else {
            let newReceipt = SolRingCasts(podID: self.podID, turnID: turnID, playerID: playerID, total: increment)
            modelContext.insert(newReceipt)
            solRings.append(newReceipt)
        }
        print("💍 Sol Ring Cast! Player: \(playerID), Turn: \(turnID), Pod: \(self.podID)")
        try modelContext.save()
    }
    
    public func id() -> String {  self.podID }
 

    // MARK: - Queries
    func bomb(for podID : String, turn turnID : Int) -> Int? {
        let bpods = bombPods.filter { $0.podID == podID && $0.turnID == turnID }
        return bpods.first?.total ?? nil
    }
    
    
    public func getTurnsWithBombs(turnID: Int) -> [BombPodExplosion] {
        bombPods.filter { $0.turnID == turnID }
    }
    
    public func getTurnsWithCastTax(turnID: Int) -> [PodCastTax] {
        castTax.filter { $0.turnID == turnID }
    }
    
    @MainActor
    public func getCastTaxFor(playerID: Int) -> [PodCastTax] {
        castTax.filter { $0.playerID == playerID }
    }
    
    public func getTurnsWithSolRings(for podID: String) -> [Int] {
        solRings.map{ $0.turnID }
    }
    
    public func wasSolRingPlayed(on turnID: Int, by playerID: Int, in podID: String) -> Bool {
        let rings = solRings.filter { $0.podID == podID }
        for ring in rings {
            if ring.turnID == turnID && ring.playerID == playerID {
                print("pod:", podID, "ring turn:", ring.turnID, "player:", ring.playerID)
                return true
            }
        }
        return false
    }
    
    public func wasBombPodPlayed(on turnID: Int, by playerID: Int, in podID: String) -> Bool {
        let bombs = bombPods.filter { $0.podID == podID }
        for bomb in bombs {
            if bomb.turnID == turnID && bomb.playerID == playerID {
                print("pod:", podID, "bomb turn:", bomb.turnID, "player:", bomb.playerID)
                return true
            }
        }
        return false
    }
    
    public func wasTaxPaid(on turnID: Int, by playerID: Int, in podID: String) -> Bool {
        let taxes = castTax.filter { $0.podID == podID }
        for tax in taxes {
            if tax.turnID == turnID && tax.playerID == playerID {
                print("pod:", podID, "tax turn:", tax.turnID, "player:", tax.playerID)
                return true
            }
        }
        return false
    }
    
    // MARK: - Delete Data
    public func deleteHistory() async {
        guard let modelContext = modelContext else { return }

        self.bombPods.forEach {if $0.podID == self.podID { modelContext.delete($0) }}
        self.castTax.forEach {if $0.podID == self.podID { modelContext.delete($0) }}
        self.solRings.forEach {if $0.podID == self.podID { modelContext.delete($0) }}
        self.bombPods.removeAll()
        self.castTax.removeAll()
        self.solRings.removeAll()
    
    }
    
    public func removeBombReceipt(_ receipt: BombPodExplosion) async {
        guard let modelContext = modelContext else { return }
        if let index = self.bombPods.firstIndex(where: { $0 === receipt }) {
            self.bombPods.remove(at: index)
            modelContext.delete(receipt)
        }
        try? modelContext.save()
    }
    
    public func removeCastTaxReceipt(_ receipt: PodCastTax) async {
        guard let modelContext = modelContext else { return }
        if let index = self.castTax.firstIndex(where: { $0 === receipt }) {
            self.castTax.remove(at: index)
            modelContext.delete(receipt)
        }
        try? modelContext.save()
    }
    

    public func removeSolRingReceipt(_ receipt: SolRingCasts) async {
        guard let modelContext = modelContext else { return }
        if let index = self.solRings.firstIndex(where: { $0 === receipt }) {
            self.solRings.remove(at: index)
            modelContext.delete(receipt)
        }
        try? modelContext.save()
    }

    //@MainActor
    public func removePod(podID: String) async {
        let rings = self.solRings.filter { $0.podID == podID }
        let taxes = self.castTax.filter {  $0.podID == podID }
        let bombs = self.bombPods.filter { $0.podID == podID }

        for ring in rings {await removeSolRingReceipt(ring)}
        for tax in taxes {await removeCastTaxReceipt(tax)}
        for bomb in bombs {await removeBombReceipt(bomb)}
        guard let modelContext = modelContext else { return }
        try? modelContext.save()
    }
    
    /// Returns all actions for a given player on a specific turn.
    public func getActions(for turnID: Int, playerID: Int) -> PlayerTurnActions {
        let bombs = bombPods.filter { $0.turnID == turnID && $0.playerID == playerID }
        let taxes = castTax.filter { $0.turnID == turnID && $0.playerID == playerID }
        let rings = solRings.filter { $0.turnID == turnID && $0.playerID == playerID }
        
        return PlayerTurnActions(
            turnID: turnID,
            playerID: playerID,
            bombs: bombs,
            taxes: taxes,
            rings: rings
        )
    }
}



// MARK: - Models
@Model
final public class BombPodExplosion: @unchecked Sendable {
    var podID: String
    var turnID: Int
    var playerID: Int
    var total: Int
    
    public init(podID: String, turnID: Int, playerID: Int, total: Int) {
        self.podID = podID
        self.turnID = turnID
        self.playerID = playerID
        self.total = total
    }
}

@Model
final public class PodCastTax: @unchecked Sendable {
    var podID: String
    var turnID: Int
    var playerID: Int
    var casting: String
    var isPartner: Bool
    var total: Int
    
    public init(podID: String, turnID: Int, playerID: Int, casting: String, isPartner: Bool, total: Int) {
        self.podID = podID
        self.turnID = turnID
        self.playerID = playerID
        self.casting = casting
        self.isPartner = isPartner
        self.total = total
    }
}

@Model
final public class SolRingCasts: @unchecked Sendable {
    var podID: String
    var turnID: Int
    var playerID: Int
    var total: Int
    
    public init(podID: String, turnID: Int, playerID: Int, total: Int) {
        self.podID = podID
        self.turnID = turnID
        self.playerID = playerID
        self.total = total
    }
}


// MARK: - EXTENSION FOR PODCASTHISTORY ARRAYS
public extension Array where  Element == PodCastHistory {
    @MainActor
    public func select(_ podID : String) -> PodCastHistory {
        let pod = self.filter {$0.podID == podID }.first
        return pod ?? PodCastHistory(podID: podID)
    }
}



// MARK: - TURN ACTIONS
public struct PlayerTurnActions {
    /// A convenience wrapper for all actions on a given turn by a given player
    let turnID: Int
    let playerID: Int
    let bombs: [BombPodExplosion]
    let taxes: [PodCastTax]
    let rings: [SolRingCasts]
    
    public var isEmpty: Bool {
        bombs.isEmpty && taxes.isEmpty && rings.isEmpty
    }

    /// Returns a list of emojis representing the actions taken
    public var emojiOverlays: [String] {
        var emojis: [String] = []
        
        if !bombs.isEmpty {
            emojis.append("💣")
        }
        if !rings.isEmpty {
            emojis.append("💍")
        }
        if !taxes.isEmpty {
            emojis.append("🧾") // or 📜, whatever symbol you prefer
        }
        
        return emojis
    }
}
