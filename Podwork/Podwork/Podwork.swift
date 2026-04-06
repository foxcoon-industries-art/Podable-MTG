import Foundation
import SwiftUI


/// Main framework entry point and configuration
public final class Podwork {
    @MainActor public static let shared = Podwork()
    
    public let version = "1.0.0"
    public let buildNumber = "1"
    
    private init() {
        setupFramework()
    }
    
    private func setupFramework() {
        // Initialize core components
        print("🚀 Podwork Framework v\(version) (\(buildNumber)) initialized")
    }
    
    /// Get framework information
    public var info: FrameworkInfo {
        return FrameworkInfo(
            name: "Podwork",
            version: version,
            buildNumber: buildNumber,
            description: "Core framework for Commander game tracking and statistics"
        )
    }
}

/// Framework information structure
public struct FrameworkInfo {
    public let name: String
    public let version: String
    public let buildNumber: String
    public let description: String
    
    public init(name: String, version: String, buildNumber: String, description: String) {
        self.name = name
        self.version = version
        self.buildNumber = buildNumber
        self.description = description
    }
    
    public var displayString: String {
        return "\(name) v\(version) (\(buildNumber))"
    }
}

// MARK: - Public API Exports

// Re-export all public types for easy importing

// Models
public typealias PodworkPlayer = Player
public typealias PodworkGameState = GameState
public typealias PodworkFinalPod = FinalPod
public typealias PodworkCommander = Commander
public typealias PodworkTurn = Turn

// Enums and Constants
public typealias PodworkEliminationMethod = EliminationMethod
public typealias PodworkQuadrant = Quadrant
public typealias PodworkBracketSystem = BracketSystem

// Managers
public typealias PodworkStorageManager = PodStorageManager
public typealias PodworkSQLiteManager = SQLiteManager

// Data Structures
public typealias PodworkTextBlock = TextBlock
public typealias PodworkViewContent = ViewContent

// Utilities and Extensions - these are imported automatically with the framework

// Constants
public typealias PodworkConstants = GameConstants
public typealias PodworkUIConstants = GameUIConstants
public typealias PodworkPlayerColors = PlayerColors

// MARK: - Framework Initialization Helpers

//@MainActor
public extension Podwork {
    /// Initialize all framework components
     @MainActor static func initializeAll() -> Bool {
        do {
            // Initialize storage
            let _ = SQLiteManager.shared
                        
            // Initialize storage manager
            let _ = PodStorageManager.shared
            
            print("✅ All Podwork components initialized successfully")
            return true
        } catch {
            print("❌ Failed to initialize Podwork components: \(error)")
            return false
        }
    }
    
    /// Get system information
    var systemInfo: SystemInfo {
        return SystemInfo(
            framework: info,
            device: UIDevice.current.model,
            osVersion: UIDevice.current.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        )
    }
}

public struct SystemInfo {
    public let framework: FrameworkInfo
    public let device: String
    public let osVersion: String
    public let appVersion: String
    
    public init(framework: FrameworkInfo, device: String, osVersion: String, appVersion: String) {
        self.framework = framework
        self.device = device
        self.osVersion = osVersion
        self.appVersion = appVersion
    }
    
    public var description: String {
        return """
        \(framework.displayString)
        Device: \(device)
        OS: iOS \(osVersion)
        App: v\(appVersion)
        """
    }
}

// MARK: - Error Types

public enum PodworkError: LocalizedError {
    case initializationFailed(String)
    case componentNotAvailable(String)
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .initializationFailed(let message):
            return "Podwork initialization failed: \(message)"
        case .componentNotAvailable(let component):
            return "Podwork component not available: \(component)"
        case .configurationError(let message):
            return "Podwork configuration error: \(message)"
        }
    }
}
