import SwiftUI
import Foundation



public extension CGSize {
    public static func + (lhs: CGSize, rhs: CGSize) -> CGSize {
        return CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }
    
    public static func + (lhs: CGSize, rhs: CGFloat) -> CGSize {
        return CGSize(width: lhs.width + rhs, height: lhs.height + rhs)
    }
    
    
    public static func - (lhs: CGSize, rhs: CGSize) -> CGSize {
        return CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }
    
    public static func - (lhs: CGSize, rhs: CGFloat) -> CGSize {
        return CGSize(width: lhs.width - rhs, height: lhs.height - rhs)
    }
    
}



public extension CGPoint {
    static func + (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        return CGPoint(x: lhs.x, y: lhs.y + rhs)
    }
    static func - (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        return CGPoint(x: lhs.x, y: lhs.y - rhs)
    }
    
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    // You can also define the compound assignment operator +=
    static func += (lhs: inout CGPoint, rhs: CGPoint) {
        lhs = lhs + rhs
    }
    
    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    // You can also define the compound assignment operator +=
    static func -= (lhs: inout CGPoint, rhs: CGPoint) {
        lhs = lhs - rhs
    }
}

public extension CGFloat {
    var radiansToDegrees: CGFloat {
        self * 180 / .pi
    }
}

public extension CGFloat {
    var degreesToRadians: CGFloat {
        self * .pi / 180
    }
}


// MARK: - Time Formatting Extensions
public extension Double {
    /// Format a time interval as a human-readable duration
    public func formattedDuration() -> String {
        let hours = Int(self) / 3600
        let minutes = Int(self) % 3600 / 60
        let seconds = Int(self) % 60
        
        if hours > 0 {
            /// 10h 10m 10s
            return String(format: "%dh %dm %ds", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
    
    /// Format as a percentage with one decimal place
    public func asPercentage() -> String {
        return String(format: "%.1f%%", self)
    }
    
    /// Format with one decimal place
    public func formatted() -> String {
        return String(format: "%.1f", self)
    }
    
    /// Clamp a value between min and max
    public func clamped(min: Double = 0.0, max: Double = 1.0) -> Double {
        return Swift.min(Swift.max(self, min), max)
    }
}

public extension TimeInterval {
    /// Format duration into human-readable string
    /// Consistent formatting across the entire app
    func formattedDuration(style: DurationStyle = .compact) -> String {
        let hours = Int(self) / 3600
        let minutes = Int(self) % 3600 / 60
        let seconds = Int(self) % 60
        
        switch style {
        case .compact:
            if hours > 0 {
                return "\(hours)h \(minutes)m"
            } else if minutes > 0 {
                return "\(minutes)m"
            } else {
                return "\(seconds)s"
            }
        case .full:
            if hours > 0 {
                return "\(hours) hours \(minutes) minutes"
            } else if minutes > 0 {
                return "\(minutes) minutes \(seconds) seconds"
            } else {
                return "\(seconds) seconds"
            }
        case .abbreviated:
            if hours > 0 {
                return "\(hours):\(String(format: "%02d", minutes))"
            } else {
                return "\(minutes):\(String(format: "%02d", seconds))"
            }
        }
    }
    
    /// Convert to minutes as a double
    var minutes: Double {
        return self / 60.0
    }
    
    /// Convert to hours as a double
    var hours: Double {
        return self / 3600.0
    }
}

public enum DurationStyle {
    case compact    // "2h 30m", "45m", "30s"
    case full       // "2 hours 30 minutes"
    case abbreviated // "2:30", "0:45"
}

public func formatBytes(_ bytes: Int) -> String {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    return formatter.string(fromByteCount: Int64(bytes))
}

// MARK: - Performance Color Extensions
/*
extension Color {
    /// Performance-based color scaling
    static func performanceColor(for value: Double, in range: PerformanceRange) -> Color {
        switch range {
        case .winRate:
            return performanceGradient(value: value, min: 0, max: 100, colors: [.red, .orange, .yellow, .green])
        case .bracket:
            return performanceGradient(value: value, min: 1, max: 10, colors: [.gray, .blue, .purple, .orange, .red])
        case .efficiency:
            return performanceGradient(value: value, min: 0, max: 5, colors: [.gray, .blue, .green, .orange])
        case .turnDuration:
            // Inverted: faster is better
            return performanceGradient(value: 120 - value, min: 0, max: 120, colors: [.red, .orange, .green])
        case .intensity:
            return performanceGradient(value: value, min: 0, max: 1, colors: [.gray, .blue, .orange, .red])
        }
    }
    
    private static func performanceGradient(value: Double, min: Double, max: Double, colors: [Color]) -> Color {
        let normalizedValue = (value - min) / (max - min)
        let clampedValue = normalizedValue.clamped(min: 0.0, max: 1.0)
        
        guard colors.count > 1 else { return colors.first ?? .gray }
        
        let segmentSize = 1.0 / Double(colors.count - 1)
        let segmentIndex = Int(clampedValue / segmentSize)
        
        if segmentIndex >= colors.count - 1 {
            return colors.last!
        }
        
        // Linear interpolation between colors could be added here
        // For now, return the appropriate segment color
        return colors[segmentIndex]
    }
    
    /// Intensity-based heat map colors
    static func heatMapColor(intensity: Double) -> Color {
        switch intensity {
        case 0.0..<0.2:
            return Color(.systemGray6)
        case 0.2..<0.4:
            return Color.blue.opacity(0.4)
        case 0.4..<0.6:
            return Color.orange.opacity(0.6)
        case 0.6..<0.8:
            return Color.orange.opacity(0.8)
        default:
            return Color.red.opacity(0.9)
        }
    }
    
    /// Commander danger level colors
    static func dangerColor(for lifeTotal: Int) -> Color {
        switch lifeTotal {
        case ...5:
            return .red
        case 6...10:
            return .orange
        case 11...20:
            return .yellow
        default:
            return .green
        }
    }
}
*/

/*
public extension AnyShapeStyle {
    public static func == (lhs: AnyShapeStyle, rhs: AnyShapeStyle) -> Bool {
        return
    }
}
*/






public extension Color {
    /// Generate consistent performance colors across the app
    public static func performanceColor(for value: Double, in range: PerformanceRange) -> Color {
        switch range {
        case PerformanceRange.winRate:
            return winRateColor(value)
        case PerformanceRange.turnDuration:
            return turnSpeedColor(value)
        case PerformanceRange.efficiency:
            return efficiencyColor(value)
        case PerformanceRange.bracket:
            return bracketColor(Int(value))
        case PerformanceRange.intensity:
            return .blue
        }
    }
    
    private static func winRateColor(_ winRate: Double) -> Color {
        switch winRate {
        case 75...: return Color.green
        case 50..<75: return Color(red: 0.7, green: 0.8, blue: 0.0) // Yellow-green
        case 25..<50: return Color.orange
        case 0..<25: return Color.red
        default: return Color.blue
        }
    }
    
    private static func turnSpeedColor(_ duration: Double) -> Color {
        switch duration {
        case ..<30: return Color.green
        case 30..<60: return Color.orange
        case 60..<120: return Color(red: 1.0, green: 0.4, blue: 0.0)
        default: return Color.red
        }
    }
    
    private static func efficiencyColor(_ efficiency: Double) -> Color {
        switch efficiency {
        case 100...: return Color.green
        case 50..<100: return Color.orange
        case 25..<50: return Color(red: 1.0, green: 0.6, blue: 0.0)
        default: return Color.red
        }
    }
    
    private static func bracketColor(_ bracket: Int) -> Color {
        if let bracketSystem = BracketSystem(rawValue: bracket) {
            return bracketSystem.color
        }
        return .gray
    }
    
    // MARK: - Additional Color Utilities
    
    /// Create a color from hex string
    static func hex(_ hexString: String) -> Color {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// Get a lighter version of the color
    func lighter(by percentage: Double = 0.2) -> Color {
        return self.opacity(1.0 - percentage)
    }
    
    /// Get a darker version of the color
    func darker(by percentage: Double = 0.2) -> Color {
        // This is a simplified version - for full implementation would need color space conversion
        return self.opacity(1.0 + percentage)
    }
}


// MARK: - Supporting Views
public enum PerformanceRange {
    case winRate
    case bracket
    case efficiency
    case turnDuration
    case intensity
}

// MARK: - Statistical Analysis Extensions

public extension Collection where Element == Double {
    /// Calculate statistical measures
    var mean: Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
    
    var median: Double {
        guard !isEmpty else { return 0 }
        let sorted = self.sorted()
        let count = sorted.count
        
        if count % 2 == 0 {
            return (sorted[count/2 - 1] + sorted[count/2]) / 2.0
        } else {
            return sorted[count/2]
        }
    }
    
    var standardDeviation: Double {
        guard count > 1 else { return 0 }
        let mean = self.mean
        let variance = map { pow($0 - mean, 2) }.reduce(0, +) / Double(count - 1)
        return sqrt(variance)
    }
    
    var range: ClosedRange<Double> {
        guard let min = self.min(), let max = self.max() else {
            return 0...0
        }
        return min...max
    }
    
    /// Calculate percentiles
    func percentile(_ p: Double) -> Double {
        guard !isEmpty, p >= 0, p <= 100 else { return 0 }
        let sorted = self.sorted()
        let index = (p / 100.0) * Double(sorted.count - 1)
        
        if index == floor(index) {
            return sorted[Int(index)]
        } else {
            let lower = sorted[Int(floor(index))]
            let upper = sorted[Int(ceil(index))]
            return lower + (upper - lower) * (index - floor(index))
        }
    }
}

public extension Collection where Element == Int {
    /// Integer collection statistics
    var doubleArray: [Double] {
        return self.map { Double($0) }
    }
    
    var mean: Double {
        return doubleArray.mean
    }
    
    var median: Double {
        return doubleArray.median
    }
    
    var standardDeviation : Double {
        return doubleArray.standardDeviation
    }
}

public extension Collection where Element == TimeInterval {
    /// Time interval collection statistics
    var meanTime: TimeInterval {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / TimeInterval(count)
    }
    
    var medianTime: TimeInterval {
        guard !isEmpty else { return 0 }
        let sorted = self.sorted()
        let count = sorted.count
        
        if count % 2 == 0 {
            return (sorted[count/2 - 1] + sorted[count/2]) / 2.0
        } else {
            return sorted[count/2]
        }
    }
}

// MARK: - Commander Name Extensions

public extension String {
    /// Clean and format commander names
    func formattedCommanderName() -> String {
        let cleaned = self.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle partner commanders
        if cleaned.contains("//") {
            let parts = cleaned.components(separatedBy: "//")
            let cleanedParts = parts.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            return cleanedParts.joined(separator: " // ")
        }
        
        return cleaned
    }
    
    /// Check if this is a partner commander pairing
    var isPartnerPair: Bool {
        return contains("//")
    }
    
    /// Get the primary commander name (first part if partner pair)
    var primaryCommanderName: String {
        if isPartnerPair {
            let parts = components(separatedBy: "//")
            return parts.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? self
        }
        return self
    }
    
    /// Get the partner name (second part if partner pair)
    var partnerName: String? {
        if isPartnerPair {
            let parts = components(separatedBy: "//")
            return parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespacesAndNewlines) : nil
        }
        return nil
    }
    
    /// Capitalize first letter of each word
    var titleCased: String {
        return self.split(separator: " ").map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }.joined(separator: " ")
    }
}

// MARK: - Array Extensions

public extension Array {
    /// Safe subscript that returns nil for out-of-bounds access
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
    
    /// Remove elements that satisfy the predicate and return them
    mutating func removeAndReturn(where predicate: (Element) -> Bool) -> [Element] {
        let removed = self.filter(predicate)
        self.removeAll(where: predicate)
        return removed
    }
}

public extension Array where Element: Numeric {
    /// Sum of all elements
    var total: Element {
        return reduce(.zero, +)
    }
}

public extension Array where Element == Int {
    /// Count occurrences of each value
    func frequency() -> [Int: Int] {
        return Dictionary(grouping: self) { $0 }.mapValues { $0.count }
    }
}


extension DateFormatter {
    static let iso8601Full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}


// Extension to allow Date to conform to RawRepresentable for @AppStorage compatibility
extension Date: RawRepresentable {
    public var rawValue: String {
        return DateFormatter.iso8601Full.string(from: self)
    }
    
    public init?(rawValue: String) {
        guard let date = DateFormatter.iso8601Full.date(from: rawValue) else {
            return nil
        }
        self = date
    }
}

// MARK: - Date Extensions

public extension Date {
    /// Format date for display
    func formattedString(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    static let yearMonthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()
    
    func yearMonthDay() -> String {
        Self.yearMonthDayFormatter.string(from: self)
    }
    
    /// Get relative time string (e.g., "2 hours ago")
    func relativeTimeString() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Check if date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// Check if date is yesterday
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    /// Get start of day
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    /// Get end of day
    var endOfDay: Date {
        Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: self) ?? self
    }
}

// MARK: - View Modifiers

public struct PerformanceIndicator: ViewModifier {
    let value: Double
    let range: PerformanceRange
    let includeBackground: Bool
    
    public init(value: Double, range: PerformanceRange, includeBackground: Bool = false) {
        self.value = value
        self.range = range
        self.includeBackground = includeBackground
    }
    
    public func body(content: Content) -> some View {
        content
            .foregroundColor(.performanceColor(for: value, in: range))
            .background(
                includeBackground ? 
                Color.performanceColor(for: value, in: range).opacity(0.1) :
                Color.clear
            )
    }
}

public extension View {
    func performanceIndicator(_ value: Double, range: PerformanceRange, includeBackground: Bool = false) -> some View {
        modifier(PerformanceIndicator(value: value, range: range, includeBackground: includeBackground))
    }
    
    /// Apply conditional modifiers
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Apply optional modifiers
    @ViewBuilder
    func ifLet<Value, Content: View>(_ value: Value?, transform: (Self, Value) -> Content) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
}

// MARK: - Reusable Chart Components


public struct PerformanceProgressBar: View {
    let value: Double
    let maxValue: Double
    let range: PerformanceRange
    let showPercentage: Bool
    
    public init(value: Double, maxValue: Double = 100.0, range: PerformanceRange = .winRate, showPercentage: Bool = true) {
        self.value = value
        self.maxValue = maxValue
        self.range = range
        self.showPercentage = showPercentage
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(showPercentage ? "\(value, specifier: "%.1f")%" : "\(value, specifier: "%.1f")")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .performanceIndicator(value, range: range)
                Spacer()
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(Color.performanceColor(for: value, in: range))
                        .frame(width: geometry.size.width * min(1.0, value / maxValue), height: 6)
                        .cornerRadius(3)
                        .animation(.easeInOut(duration: 0.3), value: value)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Haptic Feedback


/// Input a Color to get its  (Hue - Saturation - Brightness - Alpha) values
public func getHsba(_ col: Color) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
    var hue: CGFloat  = 0.0
    var saturation: CGFloat = 0.0
    var brightness: CGFloat = 0.0
    var alpha: CGFloat = 0.0
    let uiColor = UIColor(col)
    
    uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
    return (hue, saturation, brightness, alpha)
}




@MainActor
public struct HapticFeedback {

    public static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    public static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    public static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - Data Validation

public enum ValidationError: LocalizedError {
    case invalidPlayerIndex(Int)
    case invalidCommanderName(String)
    case invalidBracket(Int)
    case invalidTurnData
    case missingData(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidPlayerIndex(let index):
            return "Invalid player index: \(index)"
        case .invalidCommanderName(let name):
            return "Invalid commander name: \(name)"
        case .invalidBracket(let bracket):
            return "Invalid bracket value: \(bracket)"
        case .invalidTurnData:
            return "Invalid turn data provided"
        case .missingData(let field):
            return "Missing required field: \(field)"
        }
    }
}

public struct DataValidator {
    public static func validatePlayerIndex(_ index: Int) throws {
        guard index >= 0 && index < 4 else {
            throw ValidationError.invalidPlayerIndex(index)
        }
    }
    
    public static func validateCommanderName(_ name: String) throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.invalidCommanderName(name)
        }
    }
    
    public static func validateBracket(_ bracket: Int) throws {
        guard bracket >= 0 && bracket <= 5 else {
            throw ValidationError.invalidBracket(bracket)
        }
    }
    
    public static func validateTurnData(_ turn: Turn) throws {
        guard turn.isValid else {
            throw ValidationError.invalidTurnData
        }
    }
}

// MARK: - File Management Utilities

public struct FileManagerUtils {
    public static func documentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    public static func createDirectoryIfNeeded(at url: URL) throws {
        if !FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
    
    public static func fileExists(at url: URL) -> Bool {
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    public static func removeFile(at url: URL) throws {
        if fileExists(at: url) {
            try FileManager.default.removeItem(at: url)
        }
    }
}
