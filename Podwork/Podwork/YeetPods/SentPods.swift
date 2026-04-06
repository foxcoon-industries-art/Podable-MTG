import Foundation
import SwiftData
import CryptoKit

// -------
// Records of Pods that were Sent to Server
// -------

@Model
public final class SentPodPass : @unchecked Sendable {
    public var podID: String
    public var podPass: Bool
    
    public init( podID: String,  podPass: Bool) {
        self.podID = podID
        self.podPass = podPass
    }
}



// Simple Codable struct used for building JSON payloads
public struct PodPass: Codable {
    public let podID: String
    public let passID: String
    public let valID: String
    
    public enum CodingKeys: String, CodingKey {
        case podID = "pod_id"
        case passID = "pass_id"
        case valID = "val_id"
    }
}



public extension Array where Element == PodPass {
    public func allPodIDs() -> [String] {
        return self.map{ $0.podID }
    }
}




/// Persistent implement of SentPods transaction record
/// - Needs to show if the pod had the consumable in-app item attached before sending
/// - Method to sum total number of sent pods with consumable attached
///
@Model
public final class SentPodsReceipt : @unchecked Sendable {
    public var podID: String
    public var timestamp: Date
    public var statusCode: String
    public var podPass: Bool
    
    public init( podID: String, timestamp: Date, statusCode: String) {
        self.timestamp = timestamp
        self.podID = podID
        self.statusCode = statusCode
        self.podPass = false
    }
    
    public init( podID: String, timestamp: Date, statusCode: String, podPass: Bool) {
        self.timestamp = timestamp
        self.podID = podID
        self.statusCode = statusCode
        self.podPass = podPass
    }
}



// Simple struct to hold the result
public struct SentPodsReceiptData {
    public let podID: String
    public let statusCode: Int
    public let timestamp: Date
    public let podPass: Bool
    
    public  init(podID: String, statusCode: Int, timestamp: Date, podPass: Bool){
        self.podID = podID
        self.statusCode = statusCode
        self.timestamp = timestamp
        self.podPass = podPass
    }
    
    public init(podID: String, statusCode: Int, timestamp: Date){
        self.podID = podID
        self.statusCode = statusCode
        self.timestamp = timestamp
        self.podPass = false
    }
}




// MARK: - PodPassEntity (SwiftData model)
@Model
public final class PodPassEntity {
    @Attribute(.unique) public var id: String = UUID().uuidString
    public var podID: String
    public var passID: String
    public var valID: String
    public var createdAt: Date
    
    public init(podID: String, passID: String, valID: String, createdAt: Date = Date()) {
        self.podID = podID
        self.passID = passID
        self.valID = valID
        self.createdAt = createdAt
    }
    
    /// Factory matching your commented PodPass initializer (uses UserDefaults uniqueID)
    public static func generate(for podID: String) -> PodPassEntity? {
        guard let uniqueID = UserDefaults.standard.string(forKey: "uniqueID") else {
            return nil
        }
        let passID = UUID().uuidString
        let podCode = "\(uniqueID)___\(podID)___\(passID)"
        let inputData = Data(podCode.utf8)
        let hashedDigest = SHA256.hash(data: inputData)
        let hashString = hashedDigest.map { String(format: "%02x", $0) }.joined()
        return PodPassEntity(podID: podID, passID: passID, valID: hashString, createdAt: Date())
    }
    
    /// Convert to the Codable PodPass (if you keep the old struct for building JSON)
    public func toCodable() -> PodPass {
        return PodPass(podID: podID, passID: passID, valID: valID)
    }
}






@Model
public class UsablePodPasses {
    @Attribute(.unique) public var uniqueID: String
    public var total: Int
    public init(uniqueID: String, total: Int) {
        self.uniqueID = uniqueID
        self.total = total
    }
    public func addOnePass() {
        self.total += 1
    }
}

 


public class SentPodsHistory: ObservableObject  {
    public var usablePodPasses: UsablePodPasses = UsablePodPasses(uniqueID: "init", total: 0)
    public var sentPodPasses: [SentPodPass] = []
    public var history : [SentPodsReceipt] = []
    public var unacceptedPods : [SentPodsReceipt] = []
    public var temp : [SentPodsReceipt] = []
    
    public  var modelContext: ModelContext?

    
    public func acceptedPodIDs() -> [String] { return history.map { $0.podID } }
    public func totalAcceptedPods() -> Int { return history.count }
    public func failedPodIDs() -> [String] { return unacceptedPods.map { $0.podID } }
    public func totalFailedPods() -> Int { return unacceptedPods.count }
    public func totalSent() -> Int { return history.count + unacceptedPods.count }
    public func totalSentPodPasses() -> Int { return sentPodPasses.count }
    public func setReceipts(with pods: [SentPodsReceipt]) { temp = pods }
    
    /// Consumable items
    ///
    ///  Not secure:  use sql or swift data instead
//    public func savePodPassBalanceToUserDefaults(balance: Int) {
//        UserDefaults.standard.set(balance, forKey: "podPassBalance")
//    }
    
//    public func getPodPassBalanceFromUserDefaults() -> Int?  {
//        return UserDefaults.standard.integer(forKey: "podPassBalance" ) ?? 0
//    }
    
    
    public init( ){

    }
    
    /// Set the model context for SwiftData operations
    public func setup(_ context: ModelContext) {
        self.modelContext = context
        try? loadUsablePodPasses()
    }
    
    public func loadUsablePodPasses() throws {
        guard let modelContext = modelContext else {
            print("⚠️ ModelContext not set when loading usable passes")
            return
        }
        
        let uniqueID = UserDefaults.standard.string(forKey: "uniqueID") ?? "default"
        let descriptor = FetchDescriptor<UsablePodPasses>(
            predicate: #Predicate { $0.uniqueID == uniqueID }
        )
        
        let matches = try modelContext.fetch(descriptor)
        
        if let existing = matches.first {
            self.usablePodPasses = existing
            print("Loaded existing usable passes: \(existing.total)")
        } else {
            let newPass = UsablePodPasses(uniqueID: uniqueID, total: 5)
            modelContext.insert(newPass)
            try modelContext.save()
            self.usablePodPasses = newPass
            print("Created new usable passes record")
        }
    }

    
    public func getPodPassBalance() -> Int {
        self.usablePodPasses.total
    }
    
    public func savePodPass() throws  {
        guard let modelContext = modelContext else { print("⚠️ ModelContext not set — cannot save PodPass"); return }
        //modelContext.insert( self.usablePodPasses )
        try modelContext.save()
        
    }
    
    public func savePodPassBalance(balance: Int) throws  {
        guard let modelContext = modelContext else { return }
        self.usablePodPasses.total = balance > 0 ? balance : 0
        try? savePodPass()
    }
    //    func savePodPassBalance(balance: Int) throws  {

    public func addOnePass(){
        self.usablePodPasses.addOnePass()
        try? savePodPass()
        print("saved +1 pass: \(self.usablePodPasses.total)")
    }
    
    
    /// Combined list of all pod IDs that have been sent (both accepted and failed)
    public func allSentPodIDs() -> [String] {
        return acceptedPodIDs() + failedPodIDs()
    }
    

    

    
    /// Loads commanders from SwiftData
    public func loadSentPods() throws  {
        guard let modelContext = modelContext else { return  }
        let descriptor = FetchDescriptor<SentPodsReceipt>(
            sortBy: [SortDescriptor(\.podID)]
        )
        let pods = try modelContext.fetch(descriptor)
        self.history = pods
    }
    
    public func saveSentPods() throws {
        guard let modelContext = modelContext else { return }
        self.history.forEach{ modelContext.insert( $0 ) }
        try modelContext.save()
    }
    
    /// PodPasses are for Pods which have yet to be yeeted.
    /// Update this in the finalpod data before sending
    public func loadPodPasses() throws  {
        guard let modelContext = modelContext else { return  }
        let descriptor = FetchDescriptor<SentPodPass>(
            sortBy: [SortDescriptor(\.podID)]
        )
        let podPasses = try modelContext.fetch(descriptor)
        self.sentPodPasses = podPasses
    }
    
    public func saveSentPodPasses() throws {
        guard let modelContext = modelContext else { return }
        self.sentPodPasses.forEach{ modelContext.insert( $0 ) }
        try modelContext.save()
    }
    

    /**/
    /// The other Status Codes need to be detected and catagorized for.
    ///  (Find info in "podsDB_api_endpoints.py")
    ///  Status codes now properly handled:
    ///  - 201: Created (Success)
    ///  - 400: Bad Request (Invalid data)
    ///  - 405: Method Not Allowed
    ///  - 409: Conflict (Duplicate pod)
    ///  - 500: Internal Server Error
    ///  - -1: Network/Connection Error
    ///
    public func updateSentPodHistory() {
        
        for pod in temp {
            
            if acceptedPodIDs().contains(pod.podID){
                continue
            }
            
            // Categorize status codes
            let isSuccess = pod.statusCode == "201"
            let isDuplicate = pod.statusCode == "409"
            let isServerError = pod.statusCode == "500" || pod.statusCode == "-1"
            let isBadRequest = pod.statusCode == "400" || pod.statusCode == "405"
            
            if failedPodIDs().contains(pod.podID) {
                unacceptedPods.removeAll { $0.podID == pod.podID }
                
                if isSuccess {
                    history.append(pod)
                    print("Pod moved from failed to accepted")
                } else if isDuplicate {
                    // Treat duplicates as successful (already in DB)
                    history.append(pod)
                    print("Pod already exists in database (duplicate)")
                } else {
                    unacceptedPods.append(pod)
                    print("Previous Pod rejected again - Status: \(pod.statusCode)")
                }
            }
            
            if !failedPodIDs().contains(pod.podID) && !isSuccess {
                if isDuplicate {
                    // Treat duplicates as successful
                    history.append(pod)
                    print("Pod already in database (duplicate)")
                } else {
                    unacceptedPods.append(pod)
                    let errorType = isBadRequest ? "Bad Request" :
                    isServerError ? "Server/Network Error" : "Unknown Error"
                    print("New Pod rejected - \(errorType) (Status: \(pod.statusCode))")
                }
            }
            
            if !acceptedPodIDs().contains(pod.podID) && isSuccess {
                history.append(pod)
                print("Pod accepted")
            }
        }
        temp = []
    }
   /* */
}
