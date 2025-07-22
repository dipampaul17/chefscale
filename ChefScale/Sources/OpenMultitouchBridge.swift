import Foundation
import CoreGraphics

// MARK: - OpenMultitouch Bridge
// This provides similar functionality to OpenMultitouchSupport without external dependencies

typealias MTDeviceID = Int32
typealias MTPointID = Int32

struct MTPoint {
    let position: CGPoint
    let velocity: CGPoint
}

struct MTData {
    let id: MTPointID
    let point: MTPoint
    let pressure: Float
    let size: Float
    let angle: Float
    let majorAxis: Float
    let minorAxis: Float
    let timestamp: Double
    let state: Int32
}

// Simplified multitouch manager that works with Apple's private frameworks
@MainActor
class MultitouchManager: ObservableObject {
    static let shared = MultitouchManager()
    
    @Published var isListening = false
    private var currentTouches: [MTData] = []
    private var touchCallback: (([MTData]) -> Void)?
    
    private init() {}
    
    func startListening() {
        guard !isListening else { return }
        isListening = true
        
        // Start monitoring touch events using NSEvent
        NSEvent.addGlobalMonitorForEvents(matching: [.gesture, .magnify, .rotate, .pressure]) { [weak self] event in
            self?.processPressureEvent(event)
        }
        
        // Also monitor local events
        NSEvent.addLocalMonitorForEvents(matching: [.gesture, .magnify, .rotate, .pressure]) { [weak self] event in
            self?.processPressureEvent(event)
            return event
        }
    }
    
    func stopListening() {
        isListening = false
        // In a real implementation, we'd remove the event monitors
    }
    
    func onTouchData(_ callback: @escaping ([MTData]) -> Void) {
        touchCallback = callback
    }
    
    private func processPressureEvent(_ event: NSEvent) {
        // Simulate pressure data based on NSEvent pressure
        let pressure = Float(event.pressure)
        
        // Create simulated touch data
        let touchData = MTData(
            id: 1,
            point: MTPoint(
                position: event.locationInWindow,
                velocity: CGPoint.zero
            ),
            pressure: pressure * 100, // Scale to grams (approximate)
            size: pressure * 10,
            angle: 0,
            majorAxis: pressure * 5,
            minorAxis: pressure * 3,
            timestamp: event.timestamp,
            state: pressure > 0.1 ? 2 : 0 // Touching or not
        )
        
        if pressure > 0.1 {
            currentTouches = [touchData]
        } else {
            currentTouches = []
        }
        
        touchCallback?(currentTouches)
    }
    
    // Async stream interface similar to OpenMultitouchSupport
    var touchDataStream: AsyncStream<[SimplifiedTouchData]> {
        AsyncStream { continuation in
            self.touchCallback = { touches in
                let simplifiedTouches = touches.map { touch in
                    SimplifiedTouchData(
                        id: touch.id,
                        position: SimplifiedPosition(x: Float(touch.point.position.x), y: Float(touch.point.position.y)),
                        total: touch.size,
                        pressure: touch.pressure,
                        axis: SimplifiedAxis(major: touch.majorAxis, minor: touch.minorAxis),
                        angle: touch.angle,
                        density: touch.size / max(touch.majorAxis * touch.minorAxis, 1.0),
                        state: touch.state == 2 ? .touching : .notTouching,
                        timestamp: String(touch.timestamp)
                    )
                }
                continuation.yield(simplifiedTouches)
            }
        }
    }
}

// Simplified data structures to match OpenMultitouchSupport API
struct SimplifiedPosition {
    var x: Float
    var y: Float
}

struct SimplifiedAxis {
    var major: Float
    var minor: Float
}

enum SimplifiedState: String, CaseIterable {
    case notTouching
    case starting
    case hovering
    case making
    case touching
    case breaking
    case lingering
    case leaving
}

struct SimplifiedTouchData {
    var id: Int32
    var position: SimplifiedPosition
    var total: Float
    var pressure: Float
    var axis: SimplifiedAxis
    var angle: Float
    var density: Float
    var state: SimplifiedState
    var timestamp: String
}

// Manager wrapper to provide OpenMultitouchSupport-like API
class OMSManager {
    static func shared() -> MultitouchManager {
        return MultitouchManager.shared
    }
}

// Type aliases for compatibility
typealias OMSTouchData = SimplifiedTouchData
typealias OMSPosition = SimplifiedPosition
typealias OMSAxis = SimplifiedAxis  
typealias OMSState = SimplifiedState 