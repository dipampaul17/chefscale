import Foundation
import Combine
import OpenMultitouchSupport

enum WeightUnit: String, CaseIterable {
    case grams = "g"
    case ounces = "oz"
}

@MainActor
class ScaleManager: ObservableObject {
    @Published var currentWeight: Float = 0.0
    @Published var displayWeight: Float = 0.0
    @Published var isStable: Bool = false
    @Published var isActive: Bool = false
    @Published var unit: WeightUnit = .grams
    @Published var tareHistory: [Float] = []
    @Published var runningTotal: Float = 0.0
    @Published var detectedIngredient: String?
    
    private let manager = OMSManager.shared()
    private var cancellables = Set<AnyCancellable>()
    private var pressureReadings: [Float] = []
    private var tareOffset: Float = 0.0
    private var lastStableWeight: Float = 0.0
    private var stableStartTime: Date?
    private var kalmanFilter = KalmanFilter()
    
    // Calibration settings
    var calibrationOffset: Float {
        get { UserDefaults.standard.float(forKey: "calibration_offset") }
        set { UserDefaults.standard.set(newValue, forKey: "calibration_offset") }
    }
    
    init() {
        setupWeightProcessing()
    }
    
    func startListening() {
        Task {
            for await touchData in manager.touchDataStream {
                await processTouchData(touchData)
            }
        }
        manager.startListening()
    }
    
    func stopListening() {
        manager.stopListening()
    }
    
    private func setupWeightProcessing() {
        // Process weight updates at 60fps
        Timer.publish(every: 1.0/60.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateWeight()
            }
            .store(in: &cancellables)
    }
    
    private func processTouchData(_ touches: [OMSTouchData]) async {
        // Only process if there's at least one active touch (finger contact required)
        let activeTouches = touches.filter { $0.state != .notTouching }
        
        guard !activeTouches.isEmpty else {
            await MainActor.run {
                self.isActive = false
                self.currentWeight = 0.0
            }
            return
        }
        
        // Sum pressure from all active touches
        let totalPressure = activeTouches.reduce(0) { $0 + $1.pressure }
        
        await MainActor.run {
            self.isActive = true
            self.addPressureReading(totalPressure)
        }
    }
    
    private func addPressureReading(_ pressure: Float) {
        // Apply calibration offset
        let calibratedPressure = max(0, pressure + calibrationOffset)
        
        // Apply Kalman filtering for noise reduction
        let filteredPressure = kalmanFilter.update(measurement: calibratedPressure)
        
        // Keep rolling window of readings
        pressureReadings.append(filteredPressure)
        if pressureReadings.count > 100 {
            pressureReadings.removeFirst()
        }
        
        // Calculate current weight (pressure is already in grams)
        currentWeight = max(0, filteredPressure - tareOffset)
    }
    
    private func updateWeight() {
        // Update display weight with smoothing
        let targetWeight = currentWeight
        let smoothingFactor: Float = 0.9
        displayWeight = displayWeight * smoothingFactor + targetWeight * (1 - smoothingFactor)
        
        // Check for weight stability
        let weightDifference = abs(displayWeight - lastStableWeight)
        
        if weightDifference < 0.1 { // ±0.1g tolerance
            if stableStartTime == nil {
                stableStartTime = Date()
            } else if Date().timeIntervalSince(stableStartTime!) > 0.5 { // 0.5 seconds
                isStable = true
            }
        } else {
            stableStartTime = nil
            isStable = false
            lastStableWeight = displayWeight
        }
        
        // Auto-tare detection
        if displayWeight > 50 && lastStableWeight < 5 {
            detectNewIngredient()
        }
        
        // Ingredient detection
        detectIngredientType()
    }
    
    func tare() {
        tareOffset = currentWeight + tareOffset
        tareHistory.append(tareOffset)
        if tareHistory.count > 10 {
            tareHistory.removeFirst()
        }
        
        // Add to running total
        if displayWeight > 0.1 {
            runningTotal += displayWeight
        }
        
        // Haptic feedback removed - handled by ContentView
    }
    
    func undoTare() {
        guard !tareHistory.isEmpty else { return }
        
        let lastTare = tareHistory.removeLast()
        runningTotal -= (lastTare - (tareHistory.last ?? 0))
        tareOffset = tareHistory.last ?? 0
        
        // Haptic feedback removed - handled by ContentView
    }
    
    func toggleUnit() {
        unit = unit == .grams ? .ounces : .grams
    }
    
    private func detectNewIngredient() {
        // Simple auto-tare suggestion logic
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // This would show a notification or dialog in a real app
            print("New ingredient detected - consider taring")
        }
    }
    
    private func detectIngredientType() {
        // Analyze weight patterns to detect common ingredients
        guard displayWeight > 1 else {
            detectedIngredient = nil
            return
        }
        
        // Simple heuristics for common measurements
        let weight = displayWeight
        
        if weight >= 4 && weight <= 6 {
            detectedIngredient = "~1 tsp"
        } else if weight >= 14 && weight <= 16 {
            detectedIngredient = "~1 tbsp"
        } else if weight >= 28 && weight <= 30 {
            detectedIngredient = "~1 oz"
        } else if weight >= 118 && weight <= 122 {
            detectedIngredient = "~1 cup flour"
        } else if weight >= 200 && weight <= 220 {
            detectedIngredient = "~1 cup sugar"
        } else {
            detectedIngredient = nil
        }
    }
}

// Simple Kalman Filter for noise reduction
class KalmanFilter {
    private var estimate: Float = 0.0
    private var errorCovariance: Float = 1.0
    private let processNoise: Float = 0.01
    private let measurementNoise: Float = 0.1
    
    func update(measurement: Float) -> Float {
        // Prediction
        let predictedErrorCovariance = errorCovariance + processNoise
        
        // Update
        let kalmanGain = predictedErrorCovariance / (predictedErrorCovariance + measurementNoise)
        estimate = estimate + kalmanGain * (measurement - estimate)
        errorCovariance = (1 - kalmanGain) * predictedErrorCovariance
        
        return estimate
    }
} 