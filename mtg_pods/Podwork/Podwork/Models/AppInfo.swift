import Foundation
import SwiftData
import SwiftUI


@Model
public class PinnedCommander {
    public var name: String
    public init(name: String) {  self.name = name }
}

@Model
public class PinnedPod {
    public var id: String
    public init(podID: String) {  self.id = podID }
}

@Model
public class HiddenCommander {
    public var name: String
    public init(name: String) { self.name = name }
}



///  Not used yet
@Model
public class PurchaseReceipt {
    public var transactionID: String = ""
    public var purchaseDate: Date = Date.now
    public var itemID: String = ""
    public var quantity: Int = 0
    public var notes: String = ""

    public init(){}
}



///  Not used yet
@Model
public class InAppPurchases {
    public var uniqueID: String
    public var sentPodsTokens: Int
    public var newsCreatorBadge: Bool
    public var purchaseReceipts: [PurchaseReceipt]
    
    public init(uniqueID: String) {
        self.uniqueID = uniqueID
        self.sentPodsTokens = 100
        self.newsCreatorBadge = true
        self.purchaseReceipts = []
    }
    
    public init(uniqueID: String, advancedMode: Bool, sentPodsTokens: Int, contentCreatorBadge: Bool, purchaseReceipts: [PurchaseReceipt]) {
        self.uniqueID = uniqueID
        self.sentPodsTokens = sentPodsTokens
        self.newsCreatorBadge = contentCreatorBadge
        self.purchaseReceipts = purchaseReceipts
    }
    
}




@Model
final public class User_Info {
    
    /// Unique identifier for sending data that also is NOT the device id
    @Attribute(.unique) var uniqueID: String = ""
    private var newsCreatorBadge: Bool? = false
    
    /// Metadata for the users Instance.
    var paidApp: Bool = false
    public var firstUsage: Date? = nil
    var payDate: Date? = nil
    
    public var pinnedCommanderNames: [PinnedCommander] = []
    public var hiddenCommanderNames: [HiddenCommander] = []
    public var pinnedPodIDs: [PinnedPod] = []

    public init( uniqueID: String? = nil,
                 paidApp: Bool? = false,
                 pinnedCommanderNames: [PinnedCommander]? = [],
                 hiddenCommanderNames: [HiddenCommander]? = [],
                 pinnedPodIDs: [PinnedPod]? = [],
                 firstUsage: Date? = nil,
                 payDate: Date? = nil,
                 newsCreator: Bool? = nil) {

        self.uniqueID = uniqueID ?? UUID().uuidString
        self.paidApp = paidApp ?? false
        self.pinnedCommanderNames = pinnedCommanderNames ?? []
        self.hiddenCommanderNames = hiddenCommanderNames ?? []
        self.pinnedPodIDs = pinnedPodIDs ?? []
        
        if firstUsage != nil { self.firstUsage = firstUsage }
        if firstUsage == nil { self.firstUsage = Date.now }
        if payDate != nil { self.payDate = payDate }
        if newsCreator != nil { self.newsCreatorBadge = newsCreator }
    }
    
    public func checkFirstUse() -> Void {
        let savedFirstUseDate = UserDefaults.standard.object(forKey: "memberSince") as? Date

        if savedFirstUseDate == nil {
            print("Missing User Default parameter! Setting...")
            setFirstUseToUserDefaults()
        }
    }
    
    public func getFirstUsefromUserDefaults() -> Date?  {
        return self.firstUsage
    }
    
    public func setFirstUseToUserDefaults() -> Void {
        if self.firstUsage == nil { self.firstUsage = Date.now }
        print("... first usage 'memberSince' date: \(self.firstUsage)")
        UserDefaults.standard.set( self.firstUsage, forKey: "memberSince" )
    }
    
    public func getID() -> String { return uniqueID }
    public func getStartDate() -> Date { return self.firstUsage == nil ? Date.now : firstUsage! }
    
    public func newsBadge() -> Bool{
        if self.newsCreatorBadge == nil {return false}
        return self.newsCreatorBadge!
    }
}




@MainActor
public class App_Info: ObservableObject {
    private var modelContext: ModelContext?
    @Published public var userInfo: User_Info
    
    public init(userInfo: User_Info) {
        self.userInfo = userInfo
    }
    /// Use setup(modelContext) after init
    public func setup(_ context: ModelContext) {
        self.modelContext = context
    }
    
    
    // MARK: - User Info
    public func define(with id: String) {
        self.userInfo.uniqueID = id
    }
    
    public func saveUniqueID() {
        UserDefaults.standard.set(self.userInfo.uniqueID, forKey: "uniqueID")
    }
    
    public func deleteUniqueID() {
        UserDefaults.standard.removeObject( forKey: "uniqueID" )
    }
    
    public func getUniqueIDfromUserDefaults() -> String?  {
        return UserDefaults.standard.string(forKey: "uniqueID" )
    }
    
    public func saveKVtoUserDefaults( k: String, v: Any) {
        UserDefaults.standard.set(v, forKey: k)
    }
    
    public func savePodPassBalanceToUserDefaults(balance: Int) {
        UserDefaults.standard.set(balance, forKey: "podPassBalance")
    }
    public func getPodPassBalanceFromUserDefaults() -> Int?  {
        return UserDefaults.standard.integer(forKey: "podPassBalance" )
    }
    
    private func saveDateAsString(date: Date, forKey key: String) {
        let dateString = DateFormatter.iso8601Full.string(from: date)
        UserDefaults.standard.set(dateString, forKey: key)
    }
    
    private func retrieveDateFromString(forKey key: String) -> Date? {
        if let dateString = UserDefaults.standard.string(forKey: key) {
            return DateFormatter.iso8601Full.date(from: dateString)
        }
        return nil
    }

    
    
    public func isPaidApp() -> Bool {
        self.userInfo.paidApp
    }
    
    public func maxPins() -> Int {
        self.userInfo.paidApp ? 20 : 5
    }
    
    func savePinned() throws {
        guard let modelContext = modelContext else { return }
        try modelContext.save()
    }
    

    
    // MARK: - Pinned Pods
    public func pinPod(_ podID: String) {
        let pinnedPodIDs = self.userInfo.pinnedPodIDs.map { $0.id }
        guard !pinnedPodIDs.contains(podID) else { return }
        guard pinnedPodIDs.count < maxPins() else { return }
        
        self.userInfo.pinnedPodIDs.append(PinnedPod(podID: podID))
        do { try savePinned() }
        catch { print("Error saving pinned pods") }
    }
    
    public func isPodPinned(_ podID: String) -> Bool {
        let _ = print("isPodPinned?", podID)
        let pinnedPodIDs = self.userInfo.pinnedPodIDs.map { $0.id }
        let _ = print("pinnedPodIDs?", pinnedPodIDs)
        guard pinnedPodIDs.count > 0 else { return false }
        let _ = print("count?", pinnedPodIDs.count, pinnedPodIDs.count > 0)
        let _ = print("contains?", pinnedPodIDs.contains(podID))
        guard pinnedPodIDs.contains(podID) else { return false }
        return true
    }
    
    public func unpinPod(_ podID: String) {
        if let index = self.userInfo.pinnedPodIDs.firstIndex(where: { $0.id == podID }) {
            self.userInfo.pinnedPodIDs.remove(at: index)
            do { try savePinned() }
            catch { print("Error saving pinned pods") }
        }
    }
    
    public func hasMaxPodPins() -> Bool{
        return self.userInfo.pinnedPodIDs.count == maxPins()
    }
    
    public func hasMaxCommanderPins() -> Bool{
        return self.userInfo.pinnedCommanderNames.count == maxPins()
    }
    
    // MARK: - Pinned Commanders
    public func pinCommander(_ commander: String) {
        let pinnedCommanders = self.userInfo.pinnedCommanderNames.map { $0.name }
        guard !pinnedCommanders.contains(commander) else { return }
        guard pinnedCommanders.count < maxPins() else { return }
        
        self.userInfo.pinnedCommanderNames.append(PinnedCommander(name: commander))
        do { try savePinned() }
        catch { print("Error saving commander pin") }
    }
    
    public func unpinCommander(_ commander: String) {
        if let index = self.userInfo.pinnedCommanderNames.firstIndex(where: { $0.name == commander }) {
            self.userInfo.pinnedCommanderNames.remove(at: index)
            do { try savePinned() }
            catch { print("Error saving commander unpin") }
        }
    }
    
    // MARK: - Hidden Commanders
    public func hideCommander(_ commander: String) {
        let hiddenCommanders = self.userInfo.hiddenCommanderNames.map { $0.name }
        guard !hiddenCommanders.contains(commander) else { return }
        
        self.userInfo.hiddenCommanderNames.append(HiddenCommander(name: commander))
        do { try savePinned() }
        catch { print("Error saving hidden commander") }
    }
    
    public func unhideCommander(_ commander: String) {
        if let index = self.userInfo.hiddenCommanderNames.firstIndex(where: { $0.name == commander }) {
            self.userInfo.hiddenCommanderNames.remove(at: index)
            do { try savePinned() }
            catch { print("Error unhiding commander") }
        }
    }
    
    public func createPodCastHistory() -> PodCastHistory? {
        guard let modelContext = modelContext else { return nil }
        let podCastHistoryInit = PodCastHistory(podID: self.assignPodID(), context: modelContext )
        return podCastHistoryInit
    }
    
    /**/
    public func assignPodID() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd:HH:mm:ss"
        let currentDate = dateFormatter.string(from: .now)
        //let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        let uniqueID = self.userInfo.getID()
        let podNumber = Int.random(in: 1...100)
        return "\(uniqueID)___\(podNumber)___\(currentDate)"
    }
    
    
    /**/
}
