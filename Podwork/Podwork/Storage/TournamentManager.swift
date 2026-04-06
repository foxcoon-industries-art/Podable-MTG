import Foundation


// MARK: - Tournament Manager
/// Network client for communicating with the Podable Tournament Server.
/// Uses URLSession with no external dependencies, matching Podwork's pattern.
@Observable
@MainActor
public final class TournamentManager: Sendable {
    public static let shared = TournamentManager()

    public var currentTournament: TournamentInfo?
    public var serverURL: String = "http://127.0.0.1:5000"
    public var deviceID: String
    public var playerID: Int?
    public var playerName: String = ""
    public var isDeviceOwner: Bool = true
    public var isConnected: Bool = false
    public var isLoading: Bool = false
    public var errorMessage: String?

    private var pollingTimer: Timer?

    private init() {
        // Use a persistent device ID from UserDefaults
        if let saved = UserDefaults.standard.string(forKey: "podable_device_id") {
            self.deviceID = saved
        } else {
            let newID = UUID().uuidString
            UserDefaults.standard.set(newID, forKey: "podable_device_id")
            self.deviceID = newID
        }
    }


    // MARK: - Create Tournament

    public func createTournament(name: String) async throws -> (tournamentID: Int, code: String) {
        let url = URL(string: "\(serverURL)/api/tournament/create")!
        let body: [String: Any] = [
            "name": name,
            "organizer_device_id": deviceID
        ]
        let _ = print(body)
        let data = try await postRequest(url: url, body: body)
        let response = try JSONDecoder().decode(CreateTournamentResponse.self, from: data)
        let _ = print(response)
        // Fetch full tournament info
        let info = try await getTournamentStatus(id: response.tournamentID)
        let _ = print(info)
        self.currentTournament = info
        self.isConnected = true

        return (response.tournamentID, response.code)
    }


    // MARK: - Join Tournament

    public func joinTournament(code: String, playerName: String, isDeviceOwner: Bool) async throws {
        let url = URL(string: "\(serverURL)/api/tournament/join")!
        let body: [String: Any] = [
            "code": code.uppercased(),
            "player_name": playerName,
            "device_id": deviceID,
            "is_device_owner": isDeviceOwner
        ]

        let data = try await postRequest(url: url, body: body)
        let response = try JSONDecoder().decode(JoinTournamentResponse.self, from: data)

        self.playerID = response.playerID
        self.playerName = playerName
        self.isDeviceOwner = isDeviceOwner

        let info = try await getTournamentStatus(id: response.tournamentID)
        self.currentTournament = info
        self.isConnected = true
    }


    // MARK: - Get Tournament Status

    public func getTournamentStatus(id: Int) async throws -> TournamentInfo {
        let url = URL(string: "\(serverURL)/api/tournament/\(id)/status")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let info = try JSONDecoder().decode(TournamentInfo.self, from: data)
        let _ = print(info)
        return info
    }

    public func refreshStatus() async {
        guard let tournament = currentTournament else { return }
        do {
            let info = try await getTournamentStatus(id: tournament.tournamentID)
            self.currentTournament = info
        } catch {
            self.errorMessage = "Failed to refresh: \(error.localizedDescription)"
        }
    }


    // MARK: - Start Round

    public func startRound() async throws -> [TournamentPairingInfo] {
        guard let tournament = currentTournament else {
            throw TournamentError.noTournament
        }

        let url = URL(string: "\(serverURL)/api/tournament/\(tournament.tournamentID)/round/start")!
        let body: [String: Any] = ["organizer_device_id": deviceID]

        let data = try await postRequest(url: url, body: body)
        let response = try JSONDecoder().decode(StartRoundResponse.self, from: data)

        await refreshStatus()
        return response.pairings
    }


    // MARK: - Submit Game Result

    public func submitGameResult(
        roundNumber: Int,
        opponentID: Int,
        matchWins: Int,
        matchLosses: Int,
        gameDetails: [GameSubmissionDetail]
    ) async throws {
        guard let tournament = currentTournament, let playerID = playerID else {
            throw TournamentError.noTournament
        }

        let url = URL(string: "\(serverURL)/api/tournament/\(tournament.tournamentID)/game/submit")!

        let submission = GameSubmission(
            roundNumber: roundNumber,
            playerID: playerID,
            opponentID: opponentID,
            matchWins: matchWins,
            matchLosses: matchLosses,
            gameDetails: gameDetails
        )

        let bodyData = try JSONEncoder().encode(submission)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw TournamentError.serverError("Failed to submit game result")
        }

        await refreshStatus()
    }


    // MARK: - Get Standings

    public func getStandings() async throws -> [TournamentStandingInfo] {
        guard let tournament = currentTournament else {
            throw TournamentError.noTournament
        }

        let url = URL(string: "\(serverURL)/api/tournament/\(tournament.tournamentID)/standings")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(StandingsResponse.self, from: data)
        return response.standings
    }


    // MARK: - Close Tournament

    public func closeTournament() async throws {
        guard let tournament = currentTournament else {
            throw TournamentError.noTournament
        }

        let url = URL(string: "\(serverURL)/api/tournament/\(tournament.tournamentID)/close")!
        let body: [String: Any] = ["organizer_device_id": deviceID]
        let _ = try await postRequest(url: url, body: body)

        await refreshStatus()
    }


    // MARK: - Disconnect

    public func disconnect() {
        stopPolling()
        currentTournament = nil
        playerID = nil
        isConnected = false
    }


    // MARK: - Polling

    public func startPolling(interval: TimeInterval = 5.0) {
        stopPolling()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshStatus()
            }
        }
    }

    public func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }


    // MARK: - Private Helpers

    private func postRequest(url: URL, body: [String: Any]) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TournamentError.serverError("Invalid response")
        }

        if httpResponse.statusCode >= 400 {
            if let errorBody = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorBody["error"] as? String {
                throw TournamentError.serverError(errorMessage)
            }
            throw TournamentError.serverError("HTTP \(httpResponse.statusCode)")
        }

        return data
    }
}


// MARK: - Response Models

private struct CreateTournamentResponse: Codable {
    let tournamentID: Int
    let code: String

    enum CodingKeys: String, CodingKey {
        case tournamentID = "tournament_id"
        case code
    }
}

private struct JoinTournamentResponse: Codable {
    let tournamentID: Int
    let playerID: Int

    enum CodingKeys: String, CodingKey {
        case tournamentID = "tournament_id"
        case playerID = "player_id"
    }
}

private struct StartRoundResponse: Codable {
    let roundNumber: Int
    let pairings: [TournamentPairingInfo]

    enum CodingKeys: String, CodingKey {
        case roundNumber = "round_number"
        case pairings
    }
}

private struct StandingsResponse: Codable {
    let tournamentID: Int
    let round: Int
    let standings: [TournamentStandingInfo]

    enum CodingKeys: String, CodingKey {
        case tournamentID = "tournament_id"
        case round
        case standings
    }
}


// MARK: - Tournament Errors

public enum TournamentError: LocalizedError {
    case noTournament
    case serverError(String)
    case notOrganizer

    public var errorDescription: String? {
        switch self {
        case .noTournament: return "No active tournament"
        case .serverError(let message): return "Server error: \(message)"
        case .notOrganizer: return "Only the tournament organizer can perform this action"
        }
    }
}
