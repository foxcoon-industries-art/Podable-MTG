import Foundation
import Podwork
import CryptoKit

// -------
// Structs that are formatted for Passing Data to the Server
// -------


//MARK: - Key using podID
public struct PassPod: Codable {
    public var podID: String
    public var podUpload:  PodUpload
    
    public init(finalState: FinalPod, turns:[Turn] ){
        self.podID = finalState.gameID
        self.podUpload = PodUpload(finalState: finalState, turns: turns)
    }
    
    public func toJson() -> String {
        let jsonPodData = try! JSONEncoder().encode(self.podUpload)
        return String(data: jsonPodData, encoding: .utf8)!
    }
}



//MARK: - JSON Ready Data
public struct PodUpload: Codable {
    public var pod: String
    public var turns: [String]
    
    public init(finalState: FinalPod, turns:[Turn] ){
        let jsonPodData = try! JSONEncoder().encode(finalState)
        self.pod = String(data: jsonPodData, encoding: .utf8)!
        
        let sparseTurns = turns.map {$0.toSendableTurn()}
        let jsonSparseTurns = sparseTurns.map { try! JSONEncoder().encode($0) }
        self.turns = jsonSparseTurns.map  { String(data: $0, encoding: .utf8)! }
    }
    
    public enum CodingKeys: String, CodingKey {
        case pod = "pod"
        case turns = "turns"
    }
}



//MARK: - Array Extensions
public extension Array where Element == (FinalPod,[Turn]) {
    public func toPassPodDict() -> Dictionary<String, PodUpload> {
        let podsToSend = self.map { PassPod(finalState: $0.0, turns: $0.1) }
        let podDict = Dictionary(uniqueKeysWithValues: podsToSend.map {($0.podID, $0.podUpload)} )
        return podDict
    }
    
    public func toPassPods() -> [PassPod] {
        return self.map { PassPod(finalState: $0.0, turns: $0.1) }
    }
}




//MARK: - Turn into SendableTurn for sending to server

/// Needs to be updated to reflect current Turn struct
///  API keys for pod acceptance can be found in
///    podDB_api_endpoints.py
///
///
public struct SendableTurn: Codable {
    public var id: Int
    public var activePlayer: Int
    public var round: Int
    
    public var deltaLife: [Int]
    public var deltaInfect: [Int]
    public var deltaCmdrDamage: [[Int]]
    public var deltaPrtnrDamage: [[Int]]
    
    public var whenTurnEnded: Date
    public var turnDuration: TimeInterval
    
    public enum CodingKeys: String, CodingKey {
        case id = "id"
        case activePlayer = "active_player"
        case round = "round"
        case deltaLife = "del_life"
        case deltaInfect = "del_poison"
        case deltaCmdrDamage = "del_cmdr"
        case deltaPrtnrDamage = "del_prtnr"
        case whenTurnEnded = "when_turn_ended"
        case turnDuration = "duration"
    }
}


//MARK: - Turn Extensions
public extension Turn {
    func toSendableTurn() -> SendableTurn {
        return  SendableTurn(
            id: id,
            activePlayer: activePlayer,
            round: round,
            deltaLife: deltaLife,
            deltaInfect: deltaInfect,
            deltaCmdrDamage: deltaCmdrDamage,
            deltaPrtnrDamage: deltaPrtnrDamage,
            whenTurnEnded: whenTurnEnded,
            turnDuration: turnDuration
        )
    }
}






/*
 //MARK: - PODPASS
 /// Use list of PodPass and attach to BatchPodUpload
 ///
 /// PodPass( podID: podID )
 
 struct PodPass: Codable {
 let podID: String
 let passID: String
 let valID: String
 
 init?(podID: String) {
 guard let uniqueID = UserDefaults.standard.string(forKey: "uniqueID") else {return nil}
 self.podID = podID
 let passID = UUID().uuidString
 self.passID = passID
 let podCode = "\(uniqueID)___\(podID)___\(passID)"
 let inputData = Data(podCode.utf8)
 let hashedDigest = SHA256.hash(data: inputData)
 let hashString = hashedDigest.compactMap { String(format: "%02x", $0) }.joined()
 self.valID = hashString
 }
 enum CodingKeys: String, CodingKey {
 case podID = "pod_id"
 case passID = "pass_id"
 case valID = "val_id"
 }
 }
 
 
 //MARK: - Batch Upload Structure
 /// Structure for sending multiple pods in a single request
 struct BatchPodUpload: Codable {
 var pods: [String: PodUpload]
 var count: Int
 var passes: [PodPass]? = nil
 
 init(pods: [(FinalPod, [Turn])]) {
 self.pods = pods.toPassPodDict()
 self.count = pods.count
 }
 
 init(pods: [(FinalPod, [Turn])], podPasses: [PodPass]) {
 self.pods = pods.toPassPodDict()
 self.count = pods.count
 self.passes = podPasses
 }
 }
 
 */
