import SwiftUI
import Combine
import Foundation

// MARK: - FlowState Manager
@MainActor
class FlowStateManager: ObservableObject {
    @Published var isPouring: Bool = false
    @Published var pourSpeed: Float = 0.0
    @Published var predictedFinalWeight: Float = 0.0
    @Published var containerCapacityWarning: Bool = false
    @Published var pourDirection: PourDirection = .none
    
    private var weightHistory: [WeightReading] = []
    private var containerPatterns: [ContainerPattern] = []
    private let maxHistorySize = 50
    
    enum PourDirection {
        case none, in, out
    }
    
    struct WeightReading {
        let weight: Float
        let timestamp: Date
    }
    
    struct ContainerPattern {
        let maxWeight: Float
        let pourPattern: [Float] // Rate of change over time
        let usageCount: Int
    }
    
    func updateWeight(_ weight: Float) {
        let reading = WeightReading(weight: weight, timestamp: Date())
        weightHistory.append(reading)
        
        if weightHistory.count > maxHistorySize {
            weightHistory.removeFirst()
        }
        
        analyzeFlowState()
        detectPourPattern()
        predictFinalWeight()
        checkContainerCapacity()
    }
    
    private func analyzeFlowState() {
        guard weightHistory.count >= 3 else { return }
        
        let recentReadings = Array(weightHistory.suffix(3))
        let weightChanges = zip(recentReadings.dropFirst(), recentReadings).map { current, previous in
            (current.weight - previous.weight) / Float(current.timestamp.timeIntervalSince(previous.timestamp))
        }
        
        let avgChangeRate = weightChanges.reduce(0, +) / Float(weightChanges.count)
        pourSpeed = abs(avgChangeRate)
        
        // Detect pouring vs static
        isPouring = pourSpeed > 2.0 // 2g/second threshold
        
        // Determine direction
        if avgChangeRate > 2.0 {
            pourDirection = .in
        } else if avgChangeRate < -2.0 {
            pourDirection = .out
        } else {
            pourDirection = .none
        }
    }
    
    private func detectPourPattern() {
        guard isPouring && weightHistory.count >= 10 else { return }
        
        let recentHistory = Array(weightHistory.suffix(10))
        let rates = zip(recentHistory.dropFirst(), recentHistory).map { current, previous in
            (current.weight - previous.weight) / Float(current.timestamp.timeIntervalSince(previous.timestamp))
        }
        
        // Analyze pour consistency for prediction accuracy
        let rateVariance = calculateVariance(rates)
        
        // Trigger haptic feedback for smooth pours
        if rateVariance < 0.5 && pourSpeed > 5.0 {
            providePourFeedback(.goodFlow)
        } else if rateVariance > 2.0 {
            providePourFeedback(.irregularFlow)
        }
    }
    
    private func predictFinalWeight() {
        guard isPouring && weightHistory.count >= 5 else {
            predictedFinalWeight = 0.0
            return
        }
        
        // Simple linear extrapolation based on current rate
        let currentWeight = weightHistory.last?.weight ?? 0.0
        let timeToStable = estimateTimeToStable()
        
        if timeToStable > 0 {
            predictedFinalWeight = currentWeight + (pourSpeed * timeToStable)
        } else {
            predictedFinalWeight = currentWeight
        }
    }
    
    private func estimateTimeToStable() -> Float {
        // Estimate based on deceleration pattern
        guard pourSpeed > 0 else { return 0 }
        
        // Simple heuristic: assume linear deceleration
        return pourSpeed / 2.0 // Will stop in ~2 seconds at current deceleration
    }
    
    private func checkContainerCapacity() {
        // Check against learned container patterns
        let currentWeight = weightHistory.last?.weight ?? 0.0
        
        for pattern in containerPatterns {
            let warningThreshold = pattern.maxWeight * 0.9
            if currentWeight > warningThreshold && predictedFinalWeight > pattern.maxWeight {
                containerCapacityWarning = true
                providePourFeedback(.capacityWarning)
                return
            }
        }
        
        containerCapacityWarning = false
    }
    
    private func calculateVariance(_ values: [Float]) -> Float {
        guard values.count > 1 else { return 0.0 }
        
        let mean = values.reduce(0, +) / Float(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Float(values.count)
        
        return sqrt(variance)
    }
    
    func learnContainerPattern(maxWeight: Float) {
        // Learn container capacity from usage patterns
        let rates = weightHistory.compactMap { reading in
            pourSpeed // Simplified - should calculate actual rates
        }
        
        let pattern = ContainerPattern(maxWeight: maxWeight, pourPattern: rates, usageCount: 1)
        
        if let existingIndex = containerPatterns.firstIndex(where: { abs($0.maxWeight - maxWeight) < 10 }) {
            containerPatterns[existingIndex] = ContainerPattern(
                maxWeight: (containerPatterns[existingIndex].maxWeight + maxWeight) / 2,
                pourPattern: pattern.pourPattern,
                usageCount: containerPatterns[existingIndex].usageCount + 1
            )
        } else {
            containerPatterns.append(pattern)
        }
    }
    
    private func providePourFeedback(_ type: HapticFeedbackType) {
        NSHapticFeedbackManager.defaultPerformer.perform(type.nsHapticType, performanceTime: .now)
    }
}

enum HapticFeedbackType {
    case goodFlow
    case irregularFlow
    case capacityWarning
    case measurementTick
    case targetReached
    
    var nsHapticType: NSHapticFeedbackManager.FeedbackPattern {
        switch self {
        case .goodFlow:
            return .generic
        case .irregularFlow:
            return .generic
        case .capacityWarning:
            return .generic
        case .measurementTick:
            return .alignment
        case .targetReached:
            return .levelChange
        }
    }
}

// MARK: - Smart Ingredient Analyzer
@MainActor
class IngredientAnalyzer: ObservableObject {
    @Published var suggestions: [IngredientSuggestion] = []
    @Published var confidence: Float = 0.0
    
    private var measurementHistory: [MeasurementSession] = []
    private let commonIngredients = IngredientDatabase.shared
    
    struct MeasurementSession {
        let weight: Float
        let timestamp: Date
        let context: String // Previous ingredients in session
        let density: Float // From pressure distribution
    }
    
    struct IngredientSuggestion {
        let name: String
        let confidence: Float
        let reason: String
        let nextLikely: [String]
    }
    
    func analyzeCurrentMeasurement(weight: Float, density: Float, context: [String]) {
        let session = MeasurementSession(
            weight: weight,
            timestamp: Date(),
            context: context.joined(separator: ", "),
            density: density
        )
        
        measurementHistory.append(session)
        generateSuggestions(for: session)
    }
    
    private func generateSuggestions(for session: MeasurementSession) {
        var newSuggestions: [IngredientSuggestion] = []
        
        // Weight-based matching
        let weightMatches = commonIngredients.findByWeight(session.weight)
        for match in weightMatches {
            let confidence = calculateWeightConfidence(session.weight, target: match.typicalWeight)
            if confidence > 0.6 {
                newSuggestions.append(IngredientSuggestion(
                    name: match.name,
                    confidence: confidence,
                    reason: "Weight match (\(Int(session.weight))g)",
                    nextLikely: match.commonlyFollowedBy
                ))
            }
        }
        
        // Context-based suggestions
        let contextSuggestions = analyzeContext(session.context)
        newSuggestions.append(contentsOf: contextSuggestions)
        
        // Density-based refinement
        newSuggestions = refineBySensed(suggestions: newSuggestions, density: session.density)
        
        // Sort by confidence
        suggestions = newSuggestions.sorted { $0.confidence > $1.confidence }.prefix(3).map { $0 }
        confidence = suggestions.first?.confidence ?? 0.0
    }
    
    private func calculateWeightConfidence(_ actual: Float, target: Float) -> Float {
        let difference = abs(actual - target)
        let tolerance = max(2.0, target * 0.1) // 10% or 2g minimum
        
        if difference <= tolerance {
            return 1.0 - (difference / tolerance)
        } else {
            return max(0.0, 1.0 - (difference / target))
        }
    }
    
    private func analyzeContext(_ context: String) -> [IngredientSuggestion] {
        // Analyze previous ingredients to suggest next likely ingredients
        let words = context.lowercased().components(separatedBy: .whitespacesAndPunctuation)
        var suggestions: [IngredientSuggestion] = []
        
        // Baking context detection
        if words.contains("flour") || words.contains("sugar") {
            suggestions.append(IngredientSuggestion(
                name: "eggs",
                confidence: 0.7,
                reason: "Common in baking",
                nextLikely: ["butter", "vanilla", "salt"]
            ))
        }
        
        // Cooking context detection
        if words.contains("onion") || words.contains("garlic") {
            suggestions.append(IngredientSuggestion(
                name: "oil",
                confidence: 0.8,
                reason: "For sautéing",
                nextLikely: ["salt", "pepper", "herbs"]
            ))
        }
        
        return suggestions
    }
    
    private func refineBySensed(_ suggestions: [IngredientSuggestion], density: Float) -> [IngredientSuggestion] {
        return suggestions.map { suggestion in
            let expectedDensity = commonIngredients.getDensity(for: suggestion.name)
            let densityMatch = 1.0 - abs(density - expectedDensity) / expectedDensity
            
            return IngredientSuggestion(
                name: suggestion.name,
                confidence: suggestion.confidence * densityMatch,
                reason: suggestion.reason,
                nextLikely: suggestion.nextLikely
            )
        }
    }
}

// MARK: - Ingredient Database
class IngredientDatabase {
    static let shared = IngredientDatabase()
    
    struct IngredientInfo {
        let name: String
        let typicalWeight: Float
        let density: Float
        let commonlyFollowedBy: [String]
        let category: String
    }
    
    private let ingredients: [IngredientInfo] = [
        // Baking ingredients
        IngredientInfo(name: "flour", typicalWeight: 120, density: 0.6, commonlyFollowedBy: ["sugar", "eggs", "butter"], category: "baking"),
        IngredientInfo(name: "sugar", typicalWeight: 200, density: 0.8, commonlyFollowedBy: ["eggs", "butter", "vanilla"], category: "baking"),
        IngredientInfo(name: "butter", typicalWeight: 225, density: 0.9, commonlyFollowedBy: ["eggs", "vanilla", "salt"], category: "baking"),
        IngredientInfo(name: "eggs", typicalWeight: 50, density: 1.0, commonlyFollowedBy: ["milk", "vanilla"], category: "baking"),
        
        // Cooking ingredients
        IngredientInfo(name: "onion", typicalWeight: 150, density: 0.9, commonlyFollowedBy: ["garlic", "oil"], category: "cooking"),
        IngredientInfo(name: "garlic", typicalWeight: 5, density: 1.1, commonlyFollowedBy: ["oil", "herbs"], category: "cooking"),
        IngredientInfo(name: "oil", typicalWeight: 15, density: 0.9, commonlyFollowedBy: ["salt", "pepper"], category: "cooking"),
        
        // Spices and seasonings
        IngredientInfo(name: "salt", typicalWeight: 5, density: 2.2, commonlyFollowedBy: ["pepper"], category: "seasoning"),
        IngredientInfo(name: "pepper", typicalWeight: 2, density: 0.5, commonlyFollowedBy: ["herbs"], category: "seasoning"),
        IngredientInfo(name: "vanilla", typicalWeight: 5, density: 0.8, commonlyFollowedBy: ["extract"], category: "flavoring"),
    ]
    
    func findByWeight(_ weight: Float) -> [IngredientInfo] {
        return ingredients.filter { ingredient in
            let tolerance = max(5.0, ingredient.typicalWeight * 0.2)
            return abs(weight - ingredient.typicalWeight) <= tolerance
        }
    }
    
    func getDensity(for name: String) -> Float {
        return ingredients.first { $0.name.lowercased() == name.lowercased() }?.density ?? 1.0
    }
    
    func getNextLikely(after ingredient: String) -> [String] {
        return ingredients.first { $0.name.lowercased() == ingredient.lowercased() }?.commonlyFollowedBy ?? []
    }
}

// MARK: - Enhanced Weight Display
struct EnhancedWeightDisplay: View {
    let weight: Float
    let unit: WeightUnit
    let isStable: Bool
    let isActive: Bool
    let predictedWeight: Float?
    
    var body: some View {
        ZStack {
            // Breathing glow effect
            if isActive {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .scaleEffect(breathingScale)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: breathingScale)
            }
            
            VStack(spacing: 8) {
                // Main weight display
                Text(formatWeight(weight))
                    .font(.system(size: 72, weight: dynamicWeight, design: .rounded))
                    .foregroundColor(isStable ? .green : .primary)
                    .scaleEffect(isActive ? 1.0 : 0.95)
                    .shadow(color: .black.opacity(weightShadowOpacity), radius: weightShadowRadius, x: 0, y: 2)
                
                // Unit
                Text(unit.rawValue)
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                // Predicted weight (ghost number)
                if let predicted = predictedWeight, predicted > weight + 5 {
                    Text("→ \(formatWeight(predicted))")
                        .font(.title3)
                        .foregroundColor(.blue.opacity(0.7))
                        .transition(.opacity)
                }
            }
        }
    }
    
    private var breathingScale: CGFloat {
        isActive ? 1.05 : 1.0
    }
    
    private var dynamicWeight: Font.Weight {
        if weight < 10 { return .light }
        if weight < 50 { return .regular }
        if weight < 100 { return .medium }
        if weight < 500 { return .semibold }
        return .bold
    }
    
    private var weightShadowOpacity: Double {
        Double(min(weight / 500.0, 0.3))
    }
    
    private var weightShadowRadius: CGFloat {
        CGFloat(weight / 100.0).clamped(to: 0...10)
    }
    
    private func formatWeight(_ weight: Float) -> String {
        switch unit {
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
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
} 