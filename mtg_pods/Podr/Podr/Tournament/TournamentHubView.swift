import SwiftUI
import Podwork


// MARK: - Tournament Hub View
/// Entry point for tournament mode. Create or join a tournament.
public struct TournamentHubView: View {
    @State private var tournamentManager = TournamentManager.shared
    @State private var mode: TournamentHubMode = .menu
    @State private var tournamentName: String = ""
    @State private var joinCode: String = ""
    @State private var playerName: String = ""
    @State private var isDeviceOwner: Bool = true
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showLobby: Bool = false

    let onBack: () -> Void

    public init(onBack: @escaping () -> Void) {
        self.onBack = onBack
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if showLobby {
                if tournamentManager.isConnected {
                    TournamentLobbyView(onBack: {
                        tournamentManager.disconnect()
                        showLobby = false
                    })
                }
            } else {
                mainContent
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 24) {
            // Back button
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundStyle(Color.white)
                }
                Spacer()
            }
            .padding(.horizontal)

            Spacer()

            // Title
            VStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.yellow)
                Text("Tournament Mode")
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(Color.white)
            }

            switch mode {
            case .menu:
                menuView
            case .create:
                createView
            case .join:
                joinView
            }

            // Error
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Color.red)
                    .padding()
            }

            Spacer()
        }
    }

    @ViewBuilder
    private var menuView: some View {
        VStack(spacing: 16) {
            Button(action: { mode = .create }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Tournament")
                }
                .font(.title3)
                .bold()
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Capsule().fill(Color.yellow.gradient))
            }

            Button(action: { mode = .join }) {
                HStack {
                    Image(systemName: "person.badge.plus")
                    Text("Join Tournament")
                }
                .font(.title3)
                .bold()
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Capsule().fill(Color.blue.gradient))
            }
        }
        .padding(.horizontal, 32)
    }

    @ViewBuilder
    private var createView: some View {
        VStack(spacing: 16) {
            Text("Create Tournament")
                .font(.title2)
                .foregroundStyle(Color.white)

            TextField("Tournament Name", text: $tournamentName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 32)

            // Server URL
            TextField("Server URL", text: $tournamentManager.serverURL)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(.horizontal, 32)

            Button(action: createTournament) {
                if isLoading {
                    ProgressView()
                        .tint(Color.black)
                } else {
                    Text("Create")
                        .bold()
                }
            }
            .foregroundStyle(Color.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Capsule().fill(Color.yellow.gradient))
            .padding(.horizontal, 32)
            .disabled(tournamentName.isEmpty || isLoading)

            Button("Cancel") { mode = .menu }
                .foregroundStyle(Color.gray)
        }
    }

    @ViewBuilder
    private var joinView: some View {
        VStack(spacing: 16) {
            Text("Join Tournament")
                .font(.title2)
                .foregroundStyle(Color.white)

            TextField("Tournament Code", text: $joinCode)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .padding(.horizontal, 32)

            TextField("Your Name", text: $playerName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 32)

            // Server URL
            TextField("Server URL", text: $tournamentManager.serverURL)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(.horizontal, 32)

            Toggle("I have my own device", isOn: $isDeviceOwner)
                .padding(.horizontal, 32)
                .foregroundStyle(Color.white)

            Button(action: joinTournament) {
                if isLoading {
                    ProgressView()
                        .tint(Color.black)
                } else {
                    Text("Join")
                        .bold()
                }
            }
            .foregroundStyle(Color.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Capsule().fill(Color.blue.gradient))
            .padding(.horizontal, 32)
            .disabled(joinCode.isEmpty || playerName.isEmpty || isLoading)

            Button("Cancel") { mode = .menu }
                .foregroundStyle(Color.gray)
        }
    }

    private func createTournament() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let (_, _) = try await tournamentManager.createTournament(name: tournamentName)
                showLobby = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func joinTournament() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await tournamentManager.joinTournament(
                    code: joinCode,
                    playerName: playerName,
                    isDeviceOwner: isDeviceOwner
                )
                showLobby = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

enum TournamentHubMode {
    case menu
    case create
    case join
}
