#!/bin/bash

# ChefScale Test Runner Script
# This script runs all tests without requiring full Xcode installation

set -e

echo "🧪 ChefScale Test Runner"
echo "========================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create test executable
echo "📦 Building test executable..."
echo ""

# Compile all source files together with tests
SOURCES=(
    "ChefScale/Sources/main.swift"
    "ChefScale/Sources/ContentView.swift"
    "ChefScale/Sources/ScaleManager.swift"
    "ChefScale/Sources/CalibrationView.swift"
    "ChefScale/Sources/RecipeMode.swift"
    "ChefScale/Sources/AdvancedFeatures.swift"
    "ChefScale/Sources/GestureSupport.swift"
    "ChefScale/Sources/DataExport.swift"
    "ChefScale/Sources/OpenMultitouchBridge.swift"
)

# Create a temporary directory for tests
TEMP_DIR=$(mktemp -d)
echo "Using temporary directory: $TEMP_DIR"

# Copy source files to temp directory
for source in "${SOURCES[@]}"; do
    cp "$source" "$TEMP_DIR/"
done

# Create a simple test runner
cat > "$TEMP_DIR/TestRunner.swift" << 'EOF'
import Foundation

// Simple test runner without XCTest
struct TestResult {
    let name: String
    let passed: Bool
    let message: String?
}

class TestRunner {
    var results: [TestResult] = []
    var currentTest: String = ""
    
    func test(_ name: String, _ block: () throws -> Void) {
        currentTest = name
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
    
    func assertNotNil(_ value: Any?, _ message: String = "Value was nil") throws {
        if value == nil {
            throw TestError.assertionFailed(message)
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

enum TestError: Error {
    case assertionFailed(String)
}

// Run tests
let runner = TestRunner()

print("🧪 Running ChefScale Tests")
print("=========================\n")

// Test ScaleManager
@MainActor
func testScaleManager() throws {
    print("\n📋 ScaleManager Tests")
    print("--------------------")
    
    let scaleManager = ScaleManager()
    
    runner.test("Scale Initialization") {
        try runner.assertEqual(scaleManager.currentWeight, 0.0)
        try runner.assertEqual(scaleManager.displayWeight, 0.0)
        try runner.assert(!scaleManager.isStable)
        try runner.assert(!scaleManager.isActive)
    }
    
    runner.test("Unit Toggle") {
        try runner.assertEqual(scaleManager.unit, .grams)
        scaleManager.toggleUnit()
        try runner.assertEqual(scaleManager.unit, .ounces)
        scaleManager.toggleUnit()
        try runner.assertEqual(scaleManager.unit, .grams)
    }
    
    runner.test("Tare Function") {
        scaleManager.currentWeight = 50.0
        scaleManager.tare()
        try runner.assertEqual(scaleManager.tareHistory.count, 1)
    }
    
    runner.test("Running Total") {
        scaleManager.displayWeight = 25.0
        scaleManager.tare()
        try runner.assertEqual(scaleManager.runningTotal, 25.0)
    }
}

// Test RecipeManager
@MainActor
func testRecipeManager() throws {
    print("\n📋 RecipeManager Tests")
    print("---------------------")
    
    let recipeManager = RecipeManager()
    
    runner.test("Recipe Parsing") {
        recipeManager.recipeInput = "200g flour, 150g sugar, 3g salt"
        recipeManager.parseRecipe()
        
        try runner.assertEqual(recipeManager.ingredients.count, 3)
        try runner.assertEqual(recipeManager.ingredients[0].name, "flour")
        try runner.assertEqual(recipeManager.ingredients[0].targetWeight, 200)
    }
    
    runner.test("Different Units Parsing") {
        recipeManager.recipeInput = "1 cup flour, 2 tbsp oil"
        recipeManager.parseRecipe()
        
        try runner.assertEqual(recipeManager.ingredients.count, 2)
        try runner.assertEqual(recipeManager.ingredients[0].targetWeight, 120) // 1 cup flour
        try runner.assertEqual(recipeManager.ingredients[1].targetWeight, 30)  // 2 tbsp
    }
}

// Test Kalman Filter
func testKalmanFilter() throws {
    print("\n📋 Kalman Filter Tests")
    print("---------------------")
    
    runner.test("Filter Stability") {
        let kalmanFilter = KalmanFilter()
        let trueValue: Float = 100.0
        var filteredValue: Float = 0.0
        
        for _ in 0..<50 {
            let noisyMeasurement = trueValue + Float.random(in: -2...2)
            filteredValue = kalmanFilter.update(measurement: noisyMeasurement)
        }
        
        // Check if filtered value is within 5% of true value
        let difference = abs(filteredValue - trueValue)
        try runner.assert(difference < 5.0, "Kalman filter should converge to true value")
    }
}

// Test FlowState
@MainActor
func testFlowState() throws {
    print("\n📋 FlowState Tests")
    print("-----------------")
    
    let flowState = FlowStateManager()
    
    runner.test("Pour Detection") {
        flowState.updateWeight(10)
        Thread.sleep(forTimeInterval: 0.1)
        flowState.updateWeight(15)
        Thread.sleep(forTimeInterval: 0.1)
        flowState.updateWeight(20)
        
        // Should detect pouring
        try runner.assert(flowState.pourSpeed > 0)
    }
}

// Run all tests
Task { @MainActor in
    do {
        try testScaleManager()
        try testRecipeManager()
        try testKalmanFilter()
        try testFlowState()
    } catch {
        print("Test execution error: \(error)")
    }
    
    print("\n")
    runner.printSummary()
    
    // Exit with appropriate code
    exit(runner.results.filter { !$0.passed }.isEmpty ? 0 : 1)
}

// Keep the run loop running
RunLoop.main.run()
EOF

# Build the test executable
echo "🔨 Compiling tests..."
cd "$TEMP_DIR"

# Try to build with available Swift compiler
if command -v swift &> /dev/null; then
    swift build -c release 2>/dev/null || {
        # If swift build fails, try direct compilation
        swiftc -O -o chefscale_tests *.swift -framework SwiftUI -framework AppKit 2>/dev/null || {
            echo -e "${YELLOW}⚠️  Warning: Could not compile with optimization. Trying without...${NC}"
            swiftc -o chefscale_tests *.swift -framework SwiftUI -framework AppKit || {
                echo -e "${RED}❌ Failed to compile tests${NC}"
                echo "Please ensure Swift is properly installed"
                exit 1
            }
        }
    }
else
    echo -e "${RED}❌ Swift compiler not found${NC}"
    echo "Please install Xcode or Swift toolchain"
    exit 1
fi

echo -e "${GREEN}✅ Compilation successful${NC}"
echo ""

# Run the tests
echo "🚀 Running tests..."
echo ""
./chefscale_tests

# Cleanup
cd - > /dev/null
rm -rf "$TEMP_DIR" 