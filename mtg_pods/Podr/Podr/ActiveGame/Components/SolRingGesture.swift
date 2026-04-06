import SwiftUI
import CoreHaptics
import Podwork
import Foundation



@MainActor
@Observable
public class SolRingGesture: ObservableObject {
    public var dragPoints: [CGPoint] = []
    public var revolutions: CGFloat = 0
    public var showText: Bool = false
    public var totalRings: Int = 0
    private var twoPi : CGFloat = 2 * .pi
    private var oneOverTwoPi : CGFloat = 1.0 / (2 * .pi)
    
    public func setNewDragPoint(_ point: CGPoint, around center: CGPoint) {
        dragPoints.append(point)
        calculateRevolutions(center: center)
        dragPoints = [point]
    }
    
    @MainActor func calculateRevolutions(center : CGPoint) {
        guard dragPoints.count >= 2 else { return }
        
        let lastIndex = dragPoints.count - 1
        let prevPoint = dragPoints[lastIndex - 1]
        let currentPoint = dragPoints[lastIndex]
        
        let angle1 = atan2(prevPoint.y - center.y, prevPoint.x - center.x)
        let angle2 = atan2(currentPoint.y - center.y, currentPoint.x - center.x)
        
        var delta = angle2 - angle1
        if delta > .pi { delta -= twoPi }
        if delta < -.pi { delta += twoPi }
        
        revolutions += delta  * oneOverTwoPi
        

        if abs(revolutions) >= 1.75 {
            if !showText {
                triggerSolRing()
                let newRing = self.totalRings + 1
                self.totalRings = newRing
            }
        }
    }
    
    @MainActor func triggerSolRing()  {
        withAnimation {
            showText = true
        }
        HapticFeedback.impact(.medium)
    }
    
    public func resetDrag() {
        showText = false
        dragPoints.removeAll()
        revolutions = 0
    }
}

