import SwiftUI
import Charts
import Podwork


public struct MetricPill: View {
    let title: String
    let value: String
    let color: Color
    
    public init(title: String, value: String, color: Color) {
        self.title = title
        self.value = value
        self.color = color
    }
    
    public var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .customStroke(color: Color.black, width: 0.5)
                .foregroundStyle(color)
              
            
            Text(title)
                .font(.caption2)
                .foregroundColor(Color.secondary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(color.tertiary)
        .cornerRadius(12)
        
    }
}



enum TrendDirection {
    case up
    case down
    case stable
    
    var iconName: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .stable: return "minus"
        }
    }
    
    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .stable: return .gray
        }
    }
    
    var description: String {
        switch self {
        case .up: return "Improving"
        case .down: return "Declining"
        case .stable: return "Stable"
        }
    }
}


