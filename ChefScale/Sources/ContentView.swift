import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var scaleManager = ScaleManager()
    @StateObject private var flowStateManager = FlowStateManager()
    @StateObject private var ingredientAnalyzer = IngredientAnalyzer()
    @StateObject private var hapticCoordinator = HapticCoordinator()
    @StateObject private var gestureManager = GestureManager()
    @State private var showCalibration = false
    @State private var showRecipeMode = false
    @State private var lastActiveTime = Date()
    @State private var isSleeping = false
    @State private var lastMilestoneWeight: Float = 0
    
    var body: some View {
        ZStack {
            Color(NSColor.windowBackgroundColor)
                .ignoresSafeArea()
            
            if isSleeping {
                sleepingView
            } else {
                activeScaleView
            }
            
            // Invisible trackpad gesture detection layer
            TrackpadGestureView(
                onDoubleTap: {
                    scaleManager.tare()
                    hapticCoordinator.triggerHaptic(.doubleTap)
                },
                onShake: {
                    scaleManager.undoTare()
                    hapticCoordinator.triggerHaptic(.tare)
                }
            )
            .opacity(0.001) // Nearly invisible but still receives events
        }
        .onAppear {
            scaleManager.startListening()
        }
        .onDisappear {
            scaleManager.stopListening()
        }
        .onKeyDown { event in
            handleKeyPress(event)
        }
        .onReceive(scaleManager.$currentWeight) { weight in
            if weight > 0.1 {
                lastActiveTime = Date()
                if isSleeping {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isSleeping = false
                    }
                }
            }
            
            // Update FlowState and ingredient analysis
            flowStateManager.updateWeight(weight)
            ingredientAnalyzer.analyzeCurrentMeasurement(
                weight: weight,
                density: 1.0, // Would get from touch data in real implementation
                context: []
            )
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            checkSleepState()
        }
        // Haptic feedback for weight milestones
        .onReceive(scaleManager.$displayWeight) { weight in
            checkWeightMilestones(weight)
        }
        // Haptic feedback for flow state changes
        .onReceive(flowStateManager.$isPouring) { isPouring in
            if isPouring {
                hapticCoordinator.triggerHaptic(.flowStateChange)
            }
        }
        // Haptic feedback for ingredient detection
        .onReceive(ingredientAnalyzer.$suggestions) { suggestions in
            if let first = suggestions.first, first.confidence > 0.8 {
                hapticCoordinator.triggerHaptic(.ingredientDetected)
            }
        }
    }
    
    private var sleepingView: some View {
        VStack(spacing: 20) {
            Image(systemName: "scale.3d")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
                .opacity(0.6)
                .scaleEffect(breathingScale)
                .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: breathingScale)
            
            Text("Touch trackpad to wake")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
    
    private var breathingScale: CGFloat {
        isSleeping ? 1.1 : 1.0
    }
    
    private var activeScaleView: some View {
        VStack(spacing: 20) {
            HStack {
                Button("Recipe") {
                    showRecipeMode = true
                }
                .font(.caption)
                .foregroundColor(.blue)
                
                Spacer()
                
                unitToggleButton
                tareButton
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Enhanced weight display with FlowState
            EnhancedWeightDisplay(
                weight: scaleManager.displayWeight,
                unit: scaleManager.unit,
                isStable: scaleManager.isStable,
                isActive: scaleManager.isActive,
                predictedWeight: flowStateManager.isPouring ? flowStateManager.predictedFinalWeight : nil
            )
            
            // FlowState indicators
            if flowStateManager.isPouring {
                flowStateIndicators
            }
            
            // Ingredient suggestions
            if let suggestion = ingredientAnalyzer.suggestions.first,
               suggestion.confidence > 0.7 {
                ingredientSuggestionView(suggestion)
            }
            
            Spacer()
            
            statusIndicatorView
        }
        .padding()
        .sheet(isPresented: $showCalibration) {
            CalibrationView(scaleManager: scaleManager)
        }
        .sheet(isPresented: $showRecipeMode) {
            RecipeModeView(scaleManager: scaleManager)
        }
    }
    
    private var flowStateIndicators: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                // Pour speed indicator
                HStack(spacing: 4) {
                    Image(systemName: "drop.fill")
                        .foregroundColor(.blue)
                    Text("\(flowStateManager.pourSpeed, specifier: "%.1f")g/s")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .transition(.scale.combined(with: .opacity))
                
                // Pour direction
                if flowStateManager.pourDirection != .none {
                    Image(systemName: flowStateManager.pourDirection == .in ? "arrow.down" : "arrow.up")
                        .foregroundColor(flowStateManager.pourDirection == .in ? .green : .orange)
                        .font(.caption)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            
            // Capacity warning
            if flowStateManager.containerCapacityWarning {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Container nearly full!")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: flowStateManager.containerCapacityWarning)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.blue.opacity(0.2), lineWidth: 1)
                )
        )
        .animation(.easeInOut(duration: 0.2), value: flowStateManager.isPouring)
    }
    
    private func ingredientSuggestionView(_ suggestion: IngredientAnalyzer.IngredientSuggestion) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
                .font(.caption)
            
            Text("Detected: \(suggestion.name)")
                .font(.caption)
                .foregroundColor(.primary)
            
            Text("\(Int(suggestion.confidence * 100))%")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.gray.opacity(0.2)))
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.yellow.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .scale.combined(with: .opacity)
        ))
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: suggestion)
    }
    
    private var statusIndicatorView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                // Tare history indicator
                HStack(spacing: 4) {
                    ForEach(0..<min(scaleManager.tareHistory.count, 5), id: \.self) { _ in
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 6, height: 6)
                    }
                    
                    if scaleManager.tareHistory.count > 5 {
                        Text("+\(scaleManager.tareHistory.count - 5)")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                // Running total
                if scaleManager.runningTotal > 0.1 {
                    Text("Total: \(formatWeight(scaleManager.runningTotal)) \(scaleManager.unit.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Quick actions hint
            Text("Press 'C' for calibration • Press 'R' for recipe mode • Double-tap trackpad to tare")
                .font(.caption2)
                .foregroundColor(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
    }
    
    private var unitToggleButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                scaleManager.toggleUnit()
            }
        }) {
            Text(scaleManager.unit.rawValue)
                .font(.headline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var tareButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                scaleManager.tare()
                hapticCoordinator.triggerHaptic(.tare)
            }
        }) {
            Text("TARE")
                .font(.headline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.1))
                .foregroundColor(.primary)
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatWeight(_ weight: Float) -> String {
        switch scaleManager.unit {
        case .grams:
            if weight < 10 {
                return String(format: "%.1f", weight)
            } else {
                return String(format: "%.0f", weight)
            }
        case .ounces:
            let oz = weight * 0.035274
            if oz < 1 {
                return String(format: "%.2f", oz)
            } else {
                return String(format: "%.1f", oz)
            }
        }
    }
    
    private func handleKeyPress(_ event: NSEvent) {
        switch event.charactersIgnoringModifiers?.lowercased() {
        case "c":
            showCalibration = true
        case "r":
            showRecipeMode = true
        case "t": // T for tare
            scaleManager.tare()
            hapticCoordinator.triggerHaptic(.tare)
        case " ": // Spacebar for tare
            scaleManager.tare()
            hapticCoordinator.triggerHaptic(.tare)
        case "z" where event.modifierFlags.contains(.command):
            scaleManager.undoTare()
            hapticCoordinator.triggerHaptic(.tare)
        default:
            if event.keyCode == 53 { // Escape
                NSApplication.shared.terminate(nil)
            }
        }
    }
    
    private func checkSleepState() {
        let timeSinceLastActivity = Date().timeIntervalSince(lastActiveTime)
        if timeSinceLastActivity > 120 && !isSleeping { // 2 minutes
            withAnimation(.easeInOut(duration: 1.0)) {
                isSleeping = true
            }
        }
    }
    
    private func checkWeightMilestones(_ weight: Float) {
        // Provide haptic feedback every 10g
        let milestone = Float(Int(weight / 10) * 10)
        if milestone > lastMilestoneWeight && weight > 0.1 {
            hapticCoordinator.triggerCustomPattern(intensity: 0.3, duration: 0.1)
            lastMilestoneWeight = milestone
        }
        
        // Reset milestone tracking when weight drops significantly
        if weight < lastMilestoneWeight - 20 {
            lastMilestoneWeight = milestone
        }
    }
}

// MARK: - Key Event Handling
extension View {
    func onKeyDown(perform action: @escaping (NSEvent) -> Void) -> some View {
        self.background(KeyEventView(onKeyDown: action))
    }
}

struct KeyEventView: NSViewRepresentable {
    let onKeyDown: (NSEvent) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = KeyCaptureView()
        view.onKeyDown = onKeyDown
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

class KeyCaptureView: NSView {
    var onKeyDown: ((NSEvent) -> Void)?
    
    override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        onKeyDown?(event)
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }
} 