import Foundation
import SwiftUI


public enum AppError: LocalizedError, Equatable {
    case databaseError(String)
    case networkError(String)
    case validationError(String)
    case dataLoadError(String)
    
    public var errorDescription: String? {
        switch self {
        case .databaseError(let message):
            return "Database Error: \(message)"
        case .networkError(let message):
            return "Network Error: \(message)"
        case .validationError(let message):
            return "Validation Error: \(message)"
        case .dataLoadError(let message):
            return "Data Load Error: \(message)"
        }
    }
}


public struct ErrorView: View {

    public let error: AppError

    public init(error: AppError) {
        self.error = error
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Something went wrong")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(error.localizedDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8)
    }
}


public struct LoadingView: View {
    public var message: String = "Loading..."

    public init(message: String) {
        self.message = message
    }
    
    public var body: some View {
        return  VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Error Types

public enum DataManagerError: LocalizedError {
    case databaseSetupError(String)
    case initializationFailed(String)
    case dataLoadError(String)
    case saveError(String)
    case exportError(String)
    case importError(String)
    case networkError(String)
    case validationError(String)
    case noDataFound
    case noStatisticsData
    
    public var errorDescription: String? {
        switch self {
        case .databaseSetupError(let message):
            return "Database setup failed: \(message)"
        case .initializationFailed(let message):
            return "Initialization failed: \(message)"
        case .dataLoadError(let message):
            return "Data load error: \(message)"
        case .saveError(let message):
            return "Save error: \(message)"
        case .exportError(let message):
            return "Export error: \(message)"
        case .importError(let message):
            return "Import error: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .validationError(let message):
            return "Validation error: \(message)"
        case .noDataFound:
            return "No game data found"
        case .noStatisticsData:
            return "No statistics data available"
        }
    }
}
