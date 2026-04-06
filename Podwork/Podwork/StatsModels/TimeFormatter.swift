import Foundation

public func timeFormatDuration(_ duration: Double) -> String {
    let hours = Int(duration) / 3600
    let minutes = Int(duration) % 3600 / 60
    
    if hours > 0 {
        return "\(hours)h \(minutes)m"
    } else if minutes > 0 {
        return "\(minutes)m"
    }
    else {
        return "\(Int(duration))s"
    }
}

public func formatTimeToSeconds(_ duration: Double) -> String {

    let hours = Int(duration) / 3600
    let minutes = Int(duration) % 3600 / 60
    let seconds = Int(duration) - hours*(3600) - minutes*(60)
    
    if hours > 0 {
        return "\(hours)h \(minutes)m \(Int(seconds))s"
    } else if minutes > 0 {
        return "\(minutes)m \(Int(seconds))s"
    }
    else {
        return "\(Int(seconds))s"
    }
}
