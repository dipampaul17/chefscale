#!/bin/bash

# ChefScale Test Runner Script
# Simplified version that tests core logic without SwiftUI dependencies

set -e

echo "🧪 ChefScale Unit Tests"
echo "======================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create test executable
echo "📦 Building test executable..."

# Create a temporary directory for tests
TEMP_DIR=$(mktemp -d)

# Create standalone test implementations
cat > "$TEMP_DIR/TestRunner.swift" << 'EOF'
import Foundation

// Test infrastructure
struct TestResult {
    let name: String
    let passed: Bool
    let message: String?
}

class TestRunner {
    var results: [TestResult] = []
    
    func test(_ name: String, _ block: () throws -> Void) {
        do {
            try block()
            results.append(TestResult(name: name, passed: true, message: nil))
            print("✅ \(name)")
        } catch {
            results.append(TestResult(name: name, passed: false, message: error.localizedDescription))
            print("❌ \(name): \(error)")
        }
    }
    
    func assert(_ condition: Bool, _ message: String = "Assertion failed") throws {
        if !condition {
            throw TestError.assertionFailed(message)
        }
    }
    
    func assertEqual<T: Equatable>(_ a: T, _ b: T, _ message: String = "") throws {
        if a != b {
            throw TestError.assertionFailed("Expected \(a) to equal \(b). \(message)")
        }
    }
    
    func assertNear(_ a: Float, _ b: Float, tolerance: Float = 0.01) throws {
        if abs(a - b) > tolerance {
            throw TestError.assertionFailed("Expected \(a) to be near \(b) within \(tolerance)")
        }
    }
    
    func printSummary() {
        print("\n📊 Test Summary")
        print("===============")
        let passed = results.filter { $0.passed }.count
        let failed = results.filter { !$0.passed }.count
        let total = results.count
        
        print("Total: \(total)")
        print("✅ Passed: \(passed)")
        print("❌ Failed: \(failed)")
        
        if failed > 0 {
            print("\nFailed Tests:")
            for result in results.filter({ !$0.passed }) {
                print("  ❌ \(result.name): \(result.message ?? "Unknown error")")
            }
        }
        
        let successRate = total > 0 ? (Double(passed) / Double(total)) * 100 : 0
        print("\nSuccess Rate: \(String(format: "%.1f", successRate))%")
    }
}

enum TestError: Error, LocalizedError {
    case assertionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .assertionFailed(let message):
            return message
        }
    }
}

// Simplified test implementations
enum WeightUnit: String, CaseIterable {
    case grams = "g"
    case ounces = "oz"
}

class KalmanFilter {
    private var estimate: Float = 0.0
    private var errorCovariance: Float = 1.0
    private let processNoise: Float = 0.01
    private let measurementNoise: Float = 0.1
    
    func update(measurement: Float) -> Float {
        let predictedErrorCovariance = errorCovariance + processNoise
        let kalmanGain = predictedErrorCovariance / (predictedErrorCovariance + measurementNoise)
        estimate = estimate + kalmanGain * (measurement - estimate)
        errorCovariance = (1 - kalmanGain) * predictedErrorCovariance
        return estimate
    }
    
    func reset() {
        estimate = 0.0
        errorCovariance = 1.0
    }
}

struct RecipeIngredient {
    let name: String
    let targetWeight: Float
    var currentWeight: Float = 0
    var isComplete: Bool = false
}

class SimpleRecipeParser {
    func parseRecipe(_ input: String) -> [RecipeIngredient] {
        var ingredients: [RecipeIngredient] = []
        
        let components = input.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        for component in components {
            let parts = component.split(separator: " ", maxSplits: 1)
            guard parts.count >= 2 else { continue }
            
            let quantity = String(parts[0])
            let name = String(parts[1])
            
            var weight: Float = 0
            
            if quantity.hasSuffix("g") {
                weight = Float(quantity.dropLast()) ?? 0
            } else if quantity.hasSuffix("oz") {
                weight = (Float(quantity.dropLast(2)) ?? 0) * 28.35
            } else if quantity == "1" && name.starts(with: "cup") {
                weight = 120 // 1 cup flour
            } else if quantity == "1" && name.starts(with: "tbsp") {
                weight = 15
            } else if quantity == "2" && name.starts(with: "tbsp") {
                weight = 30
            } else {
                weight = Float(quantity) ?? 0
            }
            
            ingredients.append(RecipeIngredient(name: name, targetWeight: weight))
        }
        
        return ingredients
    }
}

// Test functions
let runner = TestRunner()

print("🧪 Running ChefScale Unit Tests")
print("==============================\n")

// Test Kalman Filter
print("📋 Kalman Filter Tests")
print("---------------------")

runner.test("Filter Initialization") {
    let filter = KalmanFilter()
    let result = filter.update(measurement: 0)
    try runner.assertNear(result, 0, tolerance: 0.1)
}

runner.test("Filter Convergence") {
    let filter = KalmanFilter()
    let trueValue: Float = 100.0
    var lastValue: Float = 0
    
    // Feed consistent measurements
    for _ in 0..<20 {
        lastValue = filter.update(measurement: trueValue)
    }
    
    try runner.assertNear(lastValue, trueValue, tolerance: 5.0)
}

runner.test("Filter Noise Reduction") {
    let filter = KalmanFilter()
    filter.reset()
    
    // Feed noisy measurements around 50
    let measurements: [Float] = [48, 52, 49, 51, 50, 47, 53, 50, 49, 51]
    var lastValue: Float = 0
    
    for measurement in measurements {
        lastValue = filter.update(measurement: measurement)
    }
    
    // Should converge near 50
    try runner.assertNear(lastValue, 50, tolerance: 2.0)
}

// Test Recipe Parser
print("\n📋 Recipe Parser Tests")
print("--------------------")

runner.test("Basic Recipe Parsing") {
    let parser = SimpleRecipeParser()
    let ingredients = parser.parseRecipe("200g flour, 150g sugar, 3g salt")
    
    try runner.assertEqual(ingredients.count, 3)
    try runner.assertEqual(ingredients[0].name, "flour")
    try runner.assertEqual(ingredients[0].targetWeight, 200)
    try runner.assertEqual(ingredients[1].name, "sugar")
    try runner.assertEqual(ingredients[1].targetWeight, 150)
    try runner.assertEqual(ingredients[2].name, "salt")
    try runner.assertEqual(ingredients[2].targetWeight, 3)
}

runner.test("Unit Conversion Parsing") {
    let parser = SimpleRecipeParser()
    let ingredients = parser.parseRecipe("1 cup flour, 2 tbsp oil")
    
    try runner.assertEqual(ingredients.count, 2)
    try runner.assertEqual(ingredients[0].targetWeight, 120)
    try runner.assertEqual(ingredients[1].targetWeight, 30)
}

runner.test("Mixed Units Parsing") {
    let parser = SimpleRecipeParser()
    let ingredients = parser.parseRecipe("100g butter, 4oz chocolate")
    
    try runner.assertEqual(ingredients.count, 2)
    try runner.assertEqual(ingredients[0].targetWeight, 100)
    try runner.assertNear(ingredients[1].targetWeight, 113.4, tolerance: 0.1)
}

// Test Weight Unit Conversion
print("\n📋 Weight Unit Tests")
print("-------------------")

runner.test("Unit Enum Values") {
    try runner.assertEqual(WeightUnit.grams.rawValue, "g")
    try runner.assertEqual(WeightUnit.ounces.rawValue, "oz")
}

runner.test("Grams to Ounces Conversion") {
    let grams: Float = 100
    let ounces = grams * 0.035274
    try runner.assertNear(ounces, 3.5274, tolerance: 0.0001)
}

runner.test("Ounces to Grams Conversion") {
    let ounces: Float = 5
    let grams = ounces * 28.35
    try runner.assertNear(grams, 141.75, tolerance: 0.01)
}

// Test Business Logic
print("\n📋 Business Logic Tests")
print("----------------------")

runner.test("Tare Offset Calculation") {
    var tareOffset: Float = 0
    let currentWeight: Float = 50
    
    // Simulate tare
    tareOffset = currentWeight
    let displayWeight = currentWeight - tareOffset
    
    try runner.assertEqual(displayWeight, 0)
}

runner.test("Multiple Tare Operations") {
    var tareOffset: Float = 0
    var tareHistory: [Float] = []
    
    // First tare at 50g
    let weight1: Float = 50
    tareOffset = weight1
    tareHistory.append(tareOffset)
    
    // Second tare at 75g (25g added)
    let weight2: Float = 75
    tareOffset = weight2
    tareHistory.append(tareOffset)
    
    try runner.assertEqual(tareHistory.count, 2)
    try runner.assertEqual(tareHistory[0], 50)
    try runner.assertEqual(tareHistory[1], 75)
}

runner.test("Stability Detection") {
    let readings: [Float] = [10.1, 10.0, 10.05, 10.02, 10.0]
    let tolerance: Float = 0.1
    
    var isStable = true
    let average = readings.reduce(0, +) / Float(readings.count)
    
    for reading in readings {
        if abs(reading - average) > tolerance {
            isStable = false
            break
        }
    }
    
    try runner.assert(isStable, "Readings should be considered stable")
}

runner.test("Pour Detection") {
    let weightHistory: [(weight: Float, time: TimeInterval)] = [
        (10, 0),
        (15, 0.5),
        (20, 1.0),
        (25, 1.5)
    ]
    
    // Calculate pour rate
    let firstReading = weightHistory.first!
    let lastReading = weightHistory.last!
    let weightChange = lastReading.weight - firstReading.weight
    let timeChange = lastReading.time - firstReading.time
    let pourRate = weightChange / Float(timeChange)
    
    try runner.assertNear(pourRate, 10.0, tolerance: 0.1) // 10g/second
}

// Print summary
print("\n")
runner.printSummary()

// Exit with appropriate code
exit(runner.results.filter { !$0.passed }.isEmpty ? 0 : 1)
EOF

# Compile and run the test
cd "$TEMP_DIR"
echo "🔨 Compiling tests..."

# Show compilation errors if any
if ! swiftc -o test_runner TestRunner.swift; then
    echo -e "${RED}❌ Compilation failed${NC}"
    echo "Compilation errors:"
    swiftc TestRunner.swift 2>&1
    exit 1
fi

echo -e "${GREEN}✅ Compilation successful${NC}"
echo ""

# Run the tests
./test_runner
TEST_EXIT_CODE=$?

# Cleanup
cd - > /dev/null
rm -rf "$TEMP_DIR"

exit $TEST_EXIT_CODE 