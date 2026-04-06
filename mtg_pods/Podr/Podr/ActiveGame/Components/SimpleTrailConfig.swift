import SwiftUI

// MARK: - Simplified Trail System
// A minimal, easy-to-integrate trail system for SwiftUI

/// Simple trail configuration
public struct SimpleTrailConfig {
    public var duration: TimeInterval = 1.0
    public var thickness: CGFloat = 15.0
    public var color: Color = .blue
    public var fadeOut: Bool = true
    
    public init(){
        duration = 1.0
        thickness = 15.0
        fadeOut = true
        color = .blue
    }
    
    public init(duration: TimeInterval, thickness: CGFloat, color: Color, fadeOut: Bool) {
        self.duration = duration
        self.thickness = thickness
        self.color = color
        self.fadeOut = fadeOut
    }
}

/// Manages a simple trail history
public class SimpleTrailManager: ObservableObject, Identifiable {
    public let id = UUID()
    @Published private(set) var positions: [(point: CGPoint, time: Date)] = []
    public let config: SimpleTrailConfig
    
    public init(config: SimpleTrailConfig = SimpleTrailConfig()) {
        self.config = config
    }
    
    public func add(_ position: CGPoint) {
        positions.append((position, Date()))
        cleanup()
    }
    
    private func cleanup() {
        let now = Date()
        positions.removeAll { now.timeIntervalSince($0.time) > config.duration }
    }
    
    public func clear() {
        positions.removeAll()
    }
}

/// Simple trail view
struct SimpleTrailView: View {
    @ObservedObject var trail: SimpleTrailManager
    
    var body: some View {
        Canvas { context, size in
            let positions = trail.positions
            guard positions.count >= 2 else { return }
            func scaleTail(_ i: Int) -> Double { pow((Double(i+i+i)/Double(positions.count)),-0.330) }
            let now = Date()
            
            // Draw trail segments
            for i in 0..<(positions.count - 1 ) {
                let start = positions[i]
                let end = positions[i+1]

            //for j in 1..<(positions.count - 1 ) {
                //let _ = print(j)
              //  let i = positions.count - (j )
              //  let start = positions[i - 1 ]
               // let end = positions[i  ]
                
                let age = now.timeIntervalSince(start.time)
                //let progress =  0.666 - 2*CGFloat(age / trail.config.duration)
                let progress = CGFloat(scaleTail(i) * trail.config.duration)
                
                var path = Path()
                path.move(to: start.point)
                path.addLine(to: end.point)
                
                //min(max(progress, 0.0), 1.0)
                //let opacity = trail.config.fadeOut ?  min(max( 1.0 - pow(progress,-1.0), -10.0), 2.0) : 1.0
                let opacity = trail.config.fadeOut ?  min(max(  pow(progress,1.0), -1.0), 1.0) : 1.0
                
                context.stroke(
                    path,
                   // with: .color(trail.config.color.opacity((2*scaleTail(i)/progress)*opacity)),
                    with: .color(trail.config.color.opacity(scaleTail(i)*opacity)),
                    style: StrokeStyle(
                        lineWidth: 0.5*scaleTail(i)*trail.config.thickness,
                        lineCap: .round,
                        lineJoin: .round
                    )
                    //lineWidth: scaleTail(i)*trail.config.thickness
                )
            }
        }
    }
}

/// Example: Circle with simple trail
struct CircleWithTrail: View {
    @State private var position: CGPoint = CGPoint(x: 200, y: 200)
    @StateObject private var trail = SimpleTrailManager(
        config: SimpleTrailConfig(
            duration: 1.0,
            thickness: 50,
            color: .gray,
            fadeOut: true
        )
    )
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            SimpleTrailView(trail: trail)
                .border(.red)
            
            Circle()
                .fill(.blue)
                .frame(width: 50, height: 50)
                .position(position)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            position = value.location
                            trail.add(value.location)
                        }
                )
        }
    }
}

struct SimpleTrail_Previews: PreviewProvider {
    static var previews: some View {
        CircleWithTrail()
    }
}



// MARK: - Trail Data Model

/// Represents a single point in the trail history
struct TrailPoint: Identifiable {
    let id = UUID()
    let position: CGPoint
    let timestamp: Date
    let velocity: CGVector
}

/// Configuration for trail appearance and behavior
struct TrailConfig {
    var duration: TimeInterval = 3.0        // How long trail lasts (seconds)
    var maxSegments: Int = 40               // Maximum trail segments
    var initThickness: CGFloat = 20.0       // Starting trail width
    var endThickness: CGFloat = 2.0         // Ending trail width
    var initColor: Color = .blue            // Starting trail color
    var endColor: Color = .cyan.opacity(0)  // Ending trail color (fades out)
    var smoothness: CGFloat = 0.73           // Curve smoothness (0-1)
}

// MARK: - Trail Manager

/// Manages trail history and rendering for a draggable object
class TrailManager: ObservableObject {
    @Published var points: [TrailPoint] = []
    let config: TrailConfig
    
    private var lastPosition: CGPoint?
    private var lastTimestamp: Date?
    
    init(config: TrailConfig = TrailConfig()) {
        self.config = config
    }
    
    /// Add a new position to the trail
    func addPoint(_ position: CGPoint) {
        let now = Date()
        
        // Calculate velocity if we have a previous position
        let velocity: CGVector
        if let lastPos = lastPosition,
           let lastTime = lastTimestamp {
            let dt = now.timeIntervalSince(lastTime)
            if dt > 0 {
                velocity = CGVector(
                    dx: (position.x - lastPos.x) / dt,
                    dy: (position.y - lastPos.y) / dt
                )
            } else {
                velocity = .zero
            }
        } else {
            velocity = .zero
        }
        
        let point = TrailPoint(
            position: position,
            timestamp: now,
            velocity: velocity
        )
        
        points.append(point)
        
        // Trim old points based on duration
        cleanupOldPoints()
        
        // Limit maximum segments
        if points.count > config.maxSegments {
            points.removeFirst(points.count - config.maxSegments)
        }
        
        lastPosition = position
        lastTimestamp = now
    }
    
    /// Remove points older than the configured duration
    private func cleanupOldPoints() {
        let now = Date()
        points.removeAll { point in
            now.timeIntervalSince(point.timestamp) > config.duration
        }
    }
    
    /// Get interpolated values for rendering
    func getTrailData() -> [(position: CGPoint, progress: CGFloat, thickness: CGFloat, color: Color)] {
        //cleanupOldPoints()
        
        guard !points.isEmpty else { return [] }
        
        let now = Date()
        return points.map { point in
            let age = now.timeIntervalSince(point.timestamp)
            let progress = CGFloat(age / config.duration) // 0 = new, 1 = old
            
            // Interpolate thickness from init to end based on age
            let thickness = config.initThickness + (config.endThickness - config.initThickness) * progress
            
            // Interpolate color (this is approximate in SwiftUI)
            let color = interpolateColor(
                from: config.initColor,
                to: config.endColor,
                progress: progress
            )
            
            return (point.position, progress, thickness, color)
        }
    }
    
    /// Simple color interpolation
    private func interpolateColor(from: Color, to: Color, progress: CGFloat) -> Color {
        // SwiftUI doesn't have direct color interpolation, so we approximate with opacity
        // return from.opacity(Double(1.0 - progress))
        // Ensure the factor is clamped between 0 and 1
        let clampedFactor = min(max(progress, 0.0), 1.0)
        
        // Use the built-in mix function
        return from.mix(with: to, by: clampedFactor)
    }
    
    /// Clear all trail points
    func clear() {
        points.removeAll()
        lastPosition = nil
        lastTimestamp = nil
    }
}

// MARK: - Trail Shape

/// Custom Shape that renders the trail as a smooth path with variable width
struct TrailShape: Shape {
    let points: [(position: CGPoint, progress: CGFloat, thickness: CGFloat, color: Color)]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        guard points.count >= 2 else { return path }
        
        // Create smooth curve through points
        path.move(to: points[0].position)
        
        if points.count == 2 {
            path.addLine(to: points[1].position)
        } else {
            // Use quadratic curves for smoothness
            for i in 1..<points.count {
                let current = points[i].position
                
                if i < points.count - 1 {
                    let next = points[i + 1].position
                    let midPoint = CGPoint(
                        x: (current.x + next.x) / 2,
                        y: (current.y + next.y) / 2
                    )
                    path.addQuadCurve(to: midPoint, control: current)
                } else {
                    path.addLine(to: current)
                }
            }
        }
        
        return path
    }
}

// MARK: - Trail Renderer View

/// Renders the trail with gradient colors and variable thickness
struct TrailRenderer: View {
    let trailData: [(position: CGPoint, progress: CGFloat, thickness: CGFloat, color: Color)]
    let config: TrailConfig
    
    var travelDirection: Bool {
        let startPoint = trailData.first!.position
        let finalPoint = trailData.last!.position
        let movedUp = startPoint.y > finalPoint.y
        return movedUp
    }
    
    var body: some View {
        ZStack {
            // Render multiple layers for smooth gradient effect
            /*
             ForEach(Array(trailData.enumerated()), id: \.offset) { index, data in
             if index < trailData.count - 1 {
             // Draw segment between this point and next
             Path { path in
             path.move(to: data.position)
             path.addLine(to: trailData[index + 1].position)
             }
             .stroke(
             data.color,
             style: StrokeStyle(
             lineWidth: data.thickness,
             lineCap: .round,
             lineJoin: .round
             )
             )
             }
             }
             */
            // Alternative: single smooth path with gradient
            if trailData.count >= 2 {
                TrailShape(points: trailData)
                    .stroke(
                        LinearGradient(
                            colors: [config.initColor, config.endColor],
                            startPoint: travelDirection ? .top : .bottom,
                            endPoint: travelDirection ? .bottom : .top
                        ),
                        style: StrokeStyle(
                            lineWidth: config.initThickness,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .opacity(0.710) // Blend with segment-based rendering
            }
        }
    }
}

// MARK: - Draggable Circle with Trail

/// A draggable circle that leaves a trail behind it
struct DraggableCircleWithTrail: View {
    let id: UUID
    let color: Color
    let radius: CGFloat
    
    @StateObject private var trailManager: TrailManager
    @State private var position: CGPoint
    @State private var isDragging = false
    
    init(
        id: UUID = UUID(),
        position: CGPoint,
        color: Color = .blue,
        radius: CGFloat = 25,
        trailConfig: TrailConfig = TrailConfig()
    ) {
        self.id = id
        self.color = color
        self.radius = radius
        self._position = State(initialValue: position)
        self._trailManager = StateObject(wrappedValue: TrailManager(config: trailConfig))
    }
    
    var body: some View {
        ZStack {
            // Render trail
            TrailRenderer(
                trailData: trailManager.getTrailData(),
                config: trailManager.config
            )
            
            // The draggable circle
            Circle()
                .fill(color)
                .frame(width: radius * 2, height: radius * 2)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
                .shadow(color: color.opacity(0.5), radius: isDragging ? 10 : 5)
                .scaleEffect(isDragging ? 1.1 : 1.0)
                .position(position)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if !isDragging {
                                isDragging = true
                            }
                            position = value.location
                            trailManager.addPoint(value.location)
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
        }
    }
}

// MARK: - Demo View

/// Demo view showing multiple circles with trails
struct TrailDemoView: View {
    @State private var circles: [CircleData] = [
        CircleData(
            position: CGPoint(x: 300, y: 200),
            color: .blue,
            config: TrailConfig(
                duration: 2.0,
                initThickness: 20,
                endThickness: 2,
                initColor: .blue,
                endColor: .cyan.opacity(0)
            )
        )
        /**/
        ,
        CircleData(
            position: CGPoint(x: 100, y: 200),
            color: .red,
            config: TrailConfig(
                duration: 3.5,
                initThickness: 15,
                endThickness: 1,
                initColor: .red,
                endColor: .orange.opacity(0)
            )
        ),
        CircleData(
            position: CGPoint(x: 200, y: 200),
            color: .green,
            config: TrailConfig(
                duration: 0.8,
                initThickness: 50,
                endThickness: 3,
                initColor: .green.opacity(1.0),
                endColor: Color.purple.opacity(1.0)
            )
        )
        /**/
    ]
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            // Instructions
            VStack {
                Text("Drag the circles around!")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                
                Spacer()
            }
            
            // Draggable circles with trails
            ForEach(circles) { circleData in
                DraggableCircleWithTrail(
                    id: circleData.id,
                    position: circleData.position,
                    color: circleData.color,
                    radius: 25,
                    trailConfig: circleData.config
                )
            }
        }
    }
}

// Helper struct for demo
struct CircleData: Identifiable {
    let id = UUID()
    var position: CGPoint
    let color: Color
    var config: TrailConfig
}

// MARK: - Preview

//#Preview {    TrailDemoView()        //.frame(width: 800, height: 600)}


struct TrailDemo_Previews: PreviewProvider {
    static var previews: some View {
        TrailDemoView()
    }
}

// MARK: - Advanced: Physics-Based Trail (Inspired by Python Implementation)

/// Advanced trail with physics simulation (like the Python version)
class PhysicsTrailManager: ObservableObject {
    @Published var points: [PhysicsTrailPoint] = []
    let config: TrailConfig
    let gravity: CGVector // Like the Python version's gravity
    
    init(config: TrailConfig = TrailConfig(), gravity: CGVector = CGVector(dx: 0, dy: 100)) {
        self.config = config
        self.gravity = gravity
    }
    
    func addPoint(_ position: CGPoint, velocity: CGVector) {
        let point = PhysicsTrailPoint(
            position: position,
            velocity: velocity,
            timestamp: Date()
        )
        points.append(point)
        
        // Update physics for all points
        updatePhysics()
        
        cleanupOldPoints()
        
        if points.count > config.maxSegments {
            points.removeFirst(points.count - config.maxSegments)
        }
    }
    
    private func updatePhysics() {
        let now = Date()
        
        for i in 0..<points.count {
            let age = now.timeIntervalSince(points[i].timestamp)
            
            // Apply physics: position = initial_position + velocity * t + 0.5 * gravity * t^2
            let t = CGFloat(age)
            let gravityOffset = CGVector(
                dx: 0.5 * gravity.dx * t * t,
                dy: 0.5 * gravity.dy * t * t
            )
            
            points[i].currentPosition = CGPoint(
                x: points[i].position.x + points[i].velocity.dx * t + gravityOffset.dx,
                y: points[i].position.y + points[i].velocity.dy * t + gravityOffset.dy
            )
        }
    }
    
    private func cleanupOldPoints() {
        let now = Date()
        points.removeAll { point in
            now.timeIntervalSince(point.timestamp) > config.duration
        }
    }
    
    func getTrailData() -> [(position: CGPoint, progress: CGFloat, thickness: CGFloat, color: Color)] {
        updatePhysics()
        //cleanupOldPoints()
        
        let now = Date()
        return points.map { point in
            let age = now.timeIntervalSince(point.timestamp)
            let progress = CGFloat(age / config.duration)
            
            let thickness = config.initThickness + (config.endThickness - config.initThickness) * progress
            let color = config.initColor.opacity(Double(1.0 - progress))
            
            return (point.currentPosition, progress, thickness, color)
        }
    }
}

struct PhysicsTrailPoint: Identifiable {
    let id = UUID()
    let position: CGPoint // Initial position
    let velocity: CGVector
    let timestamp: Date
    var currentPosition: CGPoint // Updated by physics
    
    init(position: CGPoint, velocity: CGVector, timestamp: Date) {
        self.position = position
        self.velocity = velocity
        self.timestamp = timestamp
        self.currentPosition = position
    }
}

// MARK: - Usage Examples

/*
 SIMPLE USAGE:
 
 struct ContentView: View {
 var body: some View {
 DraggableCircleWithTrail(
 position: CGPoint(x: 200, y: 200),
 color: .blue,
 radius: 30,
 trailConfig: TrailConfig(
 duration: 1.5,
 initThickness: 20,
 endThickness: 2,
 initColor: .blue,
 endColor: .cyan.opacity(0)
 )
 )
 }
 }
 
 CUSTOM CONFIGURATION:
 
 let customConfig = TrailConfig(
 duration: 2.0,              // 2 second trail
 maxSegments: 100,           // Higher quality
 initThickness: 30.0,        // Thick trail
 endThickness: 1.0,          // Thin at end
 initColor: .purple,         // Start purple
 endColor: .pink.opacity(0), // Fade to transparent pink
 smoothness: 0.5             // Smoother curves
 )
 
 DraggableCircleWithTrail(
 position: CGPoint(x: 300, y: 300),
 color: .purple,
 trailConfig: customConfig
 )
 
 MULTIPLE CIRCLES:
 
 See TrailDemoView above for an example with multiple draggable circles,
 each with their own trail configuration.
 */
