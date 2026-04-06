import Foundation
import Podwork



// Reuse your BatchPodUpload commented struct but make it available here
public struct BatchPodUpload: Codable {
    public var pods: [String: PodUpload] // assume PodUpload is defined in Podwork or elsewhere
    public var count: Int
    public var passes: [PodPass]? = nil
    
    public init(pods: [(FinalPod, [Turn])]) {
        self.pods = pods.toPassPodDict()
        self.count = pods.count
    }
    
    public init(pods: [(FinalPod, [Turn])], podPasses: [PodPass]) {
        self.pods = pods.toPassPodDict()
        self.count = pods.count
        self.passes = podPasses
    }
}



public class Yeetr {
    private let local_serverURL = "http://127.0.0.1:8080/pods"  //"http://127.0.0.1:5000" //"https://your-domain.com/submit"
    private let podDB_ServerURL = "https://foxcoon-industries.ca/pods"  //"http://127.0.0.1:5000" ///"https://your-domain.com/submit"
    
    private var podDB_URL : String {
        //return local_serverURL
        return podDB_ServerURL
    }
    
    public init() {
    }
    @MainActor
    /// Enhanced async function that submits pods with batching and throttling
    /// First attempts batch upload, falls back to throttled individual uploads if needed
    public func yeetPods_(pods: [(FinalPod, [Turn])] , podPasses: [PodPass]  ) async -> [SentPodsReceiptData] {
        guard !pods.isEmpty else { return [] }
        
        /// Convert to PassPod format
        //let passPods = pods.map { PassPod(finalState: $0.0, turns: $0.1) }
        let passPods = pods.toPassPods()
        
        /// Try batch upload first for efficiency
        /// If batch fails or isn't available, fall back to throttled individual uploads
        ///
        if pods.count > 0 {
            // Try batch upload for larger sets
            let batchResult = await submitBatchPods(pods: pods, podPasses: podPasses)
            
            // If batch was successful (got results for all pods), return them
            if batchResult.count == pods.count {
                return batchResult
            }
            
            // Otherwise fall through to individual uploads
            print("Batch upload unavailable or failed, falling back to individual uploads")
        }
        return []
//
//        // Submit pods individually with throttling to prevent server overload
//        var results: [SentPodsReceiptData] = []
//        
//        
//        for (index, passPod) in passPods.enumerated() {
//            let result = await submitSinglePod(passPod)
//            results.append(result)
//            
//            // Add small delay between requests (except for last one)
//            if index < passPods.count - 1 {
//                try? await Task.sleep(nanoseconds: 250_000_000) // 250ms delay
//            }
//        }
//        
//        return results
    }
    
    /*
    @MainActor
    /// Clean async function that submits pods and returns results
    func yeetPods_(pods: [(FinalPod, [Turn])]) async -> [SentPodsReceiptData] {
        guard !pods.isEmpty else { return [] }
        
        /// Convert to PassPod format
        let passPods = pods.map { PassPod(finalState: $0.0, turns: $0.1) }
        
        /// Current: Submit each pod and collect results
        ///
        /// Needed: Combine all submissions into a single item to upload
        /// - Potentially mitigate the server freezing up from too many requests sent at once.
        ///
        var results: [SentPodsReceiptData] = []
        
        for passPod in passPods {
            let result = await submitSinglePod(passPod)
            results.append(result)
        }
        
        return results
    }
    */
    ///  Submit single pod seems good in theory, but what happens if many people are
    ///  doing this all at once?
    ///  It seems to crash my server by overloading the requests and having python try to
    ///  access the db at the same time from multiple api calls to close in time.
    ///
    ///  The solution I think would be to bundle multiple pods together before passing.
    ///  However, this then puts extra strain on the server side, as it needs to process each
    ///  pod to make sure they are valid before adding them to the podDB.
    ///
    ///
    ///
    
    /**/
    @MainActor
    private func submitSinglePod(_ pod: PassPod) async -> SentPodsReceiptData {
        guard let url = URL(string: "\(podDB_URL)/upload_pod") else {
            return SentPodsReceiptData(podID: pod.podID, statusCode: -1, timestamp: Date())
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        
        /// Is it possible to upload them all, and then listen for responses as the server adds them?
        /// Could we show the user in real time the pods getting added to the db,
        /// like as a loading bar kind of thing?  "5/10 pods hit the cloud"
        
        do {
            request.httpBody = try JSONEncoder().encode(pod.podUpload)
            let (_, response) = try await URLSession.shared.data(for: request)
            
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            return SentPodsReceiptData(podID: pod.podID, statusCode: statusCode, timestamp: Date())
        } catch {
            print("Error submitting pod \(pod.podID): \(error) ")
            return SentPodsReceiptData(podID: pod.podID, statusCode: -1, timestamp: Date())
        }
    }
    /**/
    

    @MainActor
    /// Batch upload multiple pods in a single request
    /// Returns results for all pods, or empty array if batch endpoint not available
    func submitBatchPods(pods: [(FinalPod, [Turn])], podPasses: [PodPass]) async -> [SentPodsReceiptData] {
        guard let url = URL(string: "\(podDB_URL)/upload") else {
            return []
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0 // Longer timeout for batch operations
        
        do {
            let batchUpload = BatchPodUpload(pods: pods, podPasses: podPasses)
       
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(batchUpload)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
            }
            request.httpBody = try JSONEncoder().encode(batchUpload)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            
            // If endpoint doesn't exist (404) or method not allowed (405), return empty to trigger fallback
            if statusCode == 404 || statusCode == 405 {
                return []
            }
            
            // Try to parse batch response
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let results = json["results"] as? [[String: Any]] {
                
                var receipts: [SentPodsReceiptData] = []
                for result in results {
                    if let podID = result["pod_id"] as? String,
                       let code = result["status_code"] as? Int {
                        
                        let pass = result["pod_pass"] as? Bool
                        
                        receipts.append(SentPodsReceiptData(
                            podID: podID,
                            statusCode: code,
                            timestamp: Date(),
                            podPass: pass ?? false
                        ))
                    }
                }
                return receipts
            }
            
            // If we got a 201/200 but couldn't parse, assume all succeeded
            if statusCode == 201 || statusCode == 200 {
                let allPods = podPasses.allPodIDs()
                
                return pods.map { pod in
                    SentPodsReceiptData(podID: pod.0.gameID,
                                        statusCode: statusCode,
                                        timestamp: Date(),
                                        podPass: allPods.contains( pod.0.gameID ) )
                }
            }
            
            return []
            
        } catch {
            print("Batch upload error: \(error)")
            return []
        }
    }
    
 
    
    @MainActor
    func commanderFetch(name: String) async -> [String: Any] {
    //@MainActor
    //func commanderFetch(name: String) async -> [String: Any] {
        
        /// URL is not implemented
        guard let url = URL(string: "\(podDB_URL)/commander/\(name)") else {
            return [:]
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            print(response)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            
            print(statusCode)
            
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            print("json", json ?? [:])
            
            return json ?? [:]
        } catch {
            print("Error: \(error)")
            return [:]
        }

    }
    
}

