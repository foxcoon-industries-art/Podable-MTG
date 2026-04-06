import Foundation

// MARK: - Statistical Extensions
extension Array where Element == Double {
    func mean() -> Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
    
    func standardDeviation() -> Double {
        guard count > 1 else { return 0 }
        let avg = mean()
        let sumOfSquaredDifferences = map { pow($0 - avg, 2) }.reduce(0, +)
        return sqrt(sumOfSquaredDifferences / Double(count - 1))
    }
    
    func confidenceInterval95() -> (lower: Double, upper: Double) {
        let avg = mean()
        let stdDev = standardDeviation()
        let margin = 1.96 * (stdDev / sqrt(Double(count))) // 95% CI
        return (avg - margin, avg + margin)
    }
    
    func formatted(decimals: Int = 1) -> String {
        String(format: "%.\(decimals)f", self.mean())
    }
    
    func formattedWithStdDev(decimals: Int = 1, avg: Double? = nil, std: Double? = nil) -> String {
        
        let average = avg != nil ? avg! : mean()
        let stdev = std != nil ? std! : standardDeviation()
        
        if stdev > 0 {
            return String(format: "%.\(decimals)f ± %.\(decimals)f", average, stdev)
        } else {
            return String(format: "%.\(decimals)f", average)
        }
    }
}

extension Array where Element == Int {
    func asDoubleArray() -> [Double] {
        return map { Double($0) }
    }
}
