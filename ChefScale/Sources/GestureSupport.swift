import SwiftUI
import Combine
import CoreGraphics

// MARK: - Gesture Detection Manager
@MainActor
class GestureManager: ObservableObject {
    @Published var lastDoubleTap: Date?
    @Published var shakeDetected = false
    
    private var tapHistory: [Date] = []
    private let doubleTapThreshold: TimeInterval = 0.5
    private var accelerometerSubscription: AnyCancellable?
    
    init() {
        // In a real implementation, this would monitor trackpad touch patterns
        // and system accelerometer for shake detection
    }
    
    func processTouchEvent(touches: [TouchPoint]) {
        detectDoubleTap(from: touches)
        detectShakeGesture()
    }
    
    private func detectDoubleTap(from touches: [TouchPoint]) {
        // Look for rapid touch-release-touch pattern
        let now = Date()
        
        // Check if we have exactly one touch
        if touches.count == 1 {
            tapHistory.append(now)
            
            // Keep only recent taps
            tapHistory = tapHistory.filter { now.timeIntervalSince($0) < 1.0 }
            
            // Check for double tap pattern
            if tapHistory.count >= 2 {
                let timeBetweenTaps = tapHistory.last!.timeIntervalSince(tapHistory[tapHistory.count - 2])
                
                if timeBetweenTaps < doubleTapThreshold {
                    lastDoubleTap = now
                    tapHistory.removeAll() // Reset after successful detection
                    
                    // Provide haptic feedback
                    NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
                }
            }
        }
    }
    
    private func detectShakeGesture() {
        // In a real implementation, this would monitor MacBook accelerometer
        // For now, we simulate with a timer-based approach
        
        // Simplified shake detection - would use actual motion data
        if shouldTriggerShake() {
            shakeDetected = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.shakeDetected = false
            }
        }
    }
    
    private func shouldTriggerShake() -> Bool {
        // Placeholder - in real implementation would analyze motion patterns
        return false
    }
}

struct TouchPoint {
    let id: Int
    let position: CGPoint
    let pressure: Float
    let timestamp: Date
}

// MARK: - Trackpad Gesture View
struct TrackpadGestureView: NSViewRepresentable {
    let onDoubleTap: () -> Void
    let onShake: () -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = TrackpadView()
        view.onDoubleTap = onDoubleTap
        view.onShake = onShake
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

class TrackpadView: NSView {
    var onDoubleTap: (() -> Void)?
    var onShake: (() -> Void)?
    
    private var lastTapTime: TimeInterval = 0
    private var tapCount = 0
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupTrackpadDetection()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupTrackpadDetection() {
        // Enable trackpad gesture recognition
        allowedTouchTypes = [.indirect]
        wantsRestingTouches = true
        
        // Monitor for shake gestures (simplified)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(motionDetected),
            name: NSNotification.Name("DeviceMotion"),
            object: nil
        )
    }
    
    override func touchesBegan(with event: NSEvent) {
        super.touchesBegan(with: event)
        
        let now = event.timestamp
        let timeSinceLastTap = now - lastTapTime
        
        if timeSinceLastTap < 0.5 { // Within double-tap window
            tapCount += 1
        } else {
            tapCount = 1
        }
        
        lastTapTime = now
        
        if tapCount == 2 {
            onDoubleTap?()
            tapCount = 0
        }
    }
    
    @objc private func motionDetected() {
        onShake?()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Smart Gesture Recognition
class SmartGestureRecognizer: ObservableObject {
    @Published var gestureState: GestureState = .idle
    @Published var confidence: Float = 0.0
    
    enum GestureState {
        case idle
        case detectingDoubleTap
        case detectingShake
        case pourGesture
        case precisePlacement
    }
    
    private var gestureHistory: [GestureEvent] = []
    
    struct GestureEvent {
        let type: EventType
        let timestamp: Date
        let confidence: Float
        
        enum EventType {
            case tap
            case pressure
            case motion
            case release
        }
    }
    
    func processEvent(_ event: GestureEvent) {
        gestureHistory.append(event)
        
        // Keep recent history
        let cutoff = Date().addingTimeInterval(-2.0)
        gestureHistory = gestureHistory.filter { $0.timestamp > cutoff }
        
        analyzeGesturePattern()
    }
    
    private func analyzeGesturePattern() {
        // Analyze recent events for gesture patterns
        let recentEvents = Array(gestureHistory.suffix(10))
        
        // Double-tap detection
        let taps = recentEvents.filter { $0.type == .tap }
        if taps.count >= 2 {
            let timeBetween = taps.last!.timestamp.timeIntervalSince(taps[taps.count - 2].timestamp)
            if timeBetween < 0.5 {
                gestureState = .detectingDoubleTap
                confidence = 0.9
                return
            }
        }
        
        // Pour gesture detection
        let pressureEvents = recentEvents.filter { $0.type == .pressure }
        if pressureEvents.count > 5 {
            let pressureVariance = calculateVariance(pressureEvents.map { $0.confidence })
            if pressureVariance > 0.3 {
                gestureState = .pourGesture
                confidence = min(pressureVariance, 1.0)
                return
            }
        }
        
        gestureState = .idle
        confidence = 0.0
    }
    
    private func calculateVariance(_ values: [Float]) -> Float {
        guard values.count > 1 else { return 0.0 }
        
        let mean = values.reduce(0, +) / Float(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Float(values.count)
        
        return sqrt(variance)
    }
}

// MARK: - Haptic Feedback Coordinator
class HapticCoordinator: ObservableObject {
    enum HapticPattern {
        case doubleTap
        case tare
        case ingredientDetected
        case targetReached
        case warning
        case flowStateChange
    }
    
    func triggerHaptic(_ pattern: HapticPattern) {
        let feedbackType: NSHapticFeedbackManager.FeedbackPattern
        
        switch pattern {
        case .doubleTap:
            feedbackType = .alignment
        case .tare:
            feedbackType = .levelChange
        case .ingredientDetected:
            feedbackType = .generic
        case .targetReached:
            feedbackType = .alignment
        case .warning:
            feedbackType = .generic
        case .flowStateChange:
            feedbackType = .generic
        }
        
        NSHapticFeedbackManager.defaultPerformer.perform(feedbackType, performanceTime: .now)
    }
    
    func triggerCustomPattern(intensity: Float, duration: TimeInterval) {
        // Custom haptic patterns for advanced feedback
        let basePattern: NSHapticFeedbackManager.FeedbackPattern = .generic
        
        // Adjust timing based on intensity
        let timing: NSHapticFeedbackManager.PerformanceTime = .now
        
        NSHapticFeedbackManager.defaultPerformer.perform(basePattern, performanceTime: timing)
        
        // For multiple pulses
        if duration > 0.1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NSHapticFeedbackManager.defaultPerformer.perform(basePattern, performanceTime: .now)
            }
        }
    }
} 