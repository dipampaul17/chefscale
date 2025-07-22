import XCTest
@testable import ChefScale

final class ChefScaleTests: XCTestCase {
    
    var scaleManager: ScaleManager!
    
    override func setUpWithError() throws {
        scaleManager = ScaleManager()
    }
    
    override func tearDownWithError() throws {
        scaleManager = nil
    }
    
    // MARK: - Core Weighing Tests
    
    func testScaleInitialization() throws {
        XCTAssertEqual(scaleManager.currentWeight, 0.0)
        XCTAssertEqual(scaleManager.displayWeight, 0.0)
        XCTAssertFalse(scaleManager.isStable)
        XCTAssertFalse(scaleManager.isActive)
        XCTAssertEqual(scaleManager.unit, .grams)
    }
    
    func testWeightUnitToggle() throws {
        XCTAssertEqual(scaleManager.unit, .grams)
        scaleManager.toggleUnit()
        XCTAssertEqual(scaleManager.unit, .ounces)
        scaleManager.toggleUnit()
        XCTAssertEqual(scaleManager.unit, .grams)
    }
    
    func testTareFunction() throws {
        // Simulate adding weight
        scaleManager.currentWeight = 50.0
        scaleManager.tare()
        
        XCTAssertEqual(scaleManager.tareHistory.count, 1)
        XCTAssertEqual(scaleManager.tareHistory.first, 50.0)
    }
    
    func testUndoTare() throws {
        // Add multiple tares
        scaleManager.currentWeight = 50.0
        scaleManager.tare()
        scaleManager.currentWeight = 30.0
        scaleManager.tare()
        
        XCTAssertEqual(scaleManager.tareHistory.count, 2)
        
        scaleManager.undoTare()
        XCTAssertEqual(scaleManager.tareHistory.count, 1)
    }
    
    func testRunningTotal() throws {
        scaleManager.displayWeight = 25.0
        scaleManager.tare()
        XCTAssertEqual(scaleManager.runningTotal, 25.0)
        
        scaleManager.displayWeight = 30.0
        scaleManager.tare()
        XCTAssertEqual(scaleManager.runningTotal, 55.0)
    }
    
    func testIngredientDetection() throws {
        // Test teaspoon detection
        scaleManager.displayWeight = 5.0
        scaleManager.detectIngredientType()
        XCTAssertEqual(scaleManager.detectedIngredient, "~1 tsp")
        
        // Test tablespoon detection
        scaleManager.displayWeight = 15.0
        scaleManager.detectIngredientType()
        XCTAssertEqual(scaleManager.detectedIngredient, "~1 tbsp")
        
        // Test cup of flour detection
        scaleManager.displayWeight = 120.0
        scaleManager.detectIngredientType()
        XCTAssertEqual(scaleManager.detectedIngredient, "~1 cup flour")
    }
    
    // MARK: - Calibration Tests
    
    func testCalibrationOffset() throws {
        let initialOffset = scaleManager.calibrationOffset
        scaleManager.calibrationOffset = 2.5
        XCTAssertEqual(scaleManager.calibrationOffset, 2.5)
        
        // Reset
        scaleManager.calibrationOffset = initialOffset
    }
    
    // MARK: - Kalman Filter Tests
    
    func testKalmanFilterStability() throws {
        let kalmanFilter = KalmanFilter()
        
        // Test that filter stabilizes around true value
        let trueValue: Float = 100.0
        var filteredValue: Float = 0.0
        
        for _ in 0..<50 {
            let noisyMeasurement = trueValue + Float.random(in: -2...2)
            filteredValue = kalmanFilter.update(measurement: noisyMeasurement)
        }
        
        XCTAssertEqual(filteredValue, trueValue, accuracy: 5.0)
    }
}

// MARK: - Recipe Mode Tests

final class RecipeModeTests: XCTestCase {
    
    var recipeManager: RecipeManager!
    
    override func setUpWithError() throws {
        recipeManager = RecipeManager()
    }
    
    func testRecipeParsing() throws {
        recipeManager.recipeInput = "200g flour, 150g sugar, 3g salt"
        recipeManager.parseRecipe()
        
        XCTAssertEqual(recipeManager.ingredients.count, 3)
        XCTAssertEqual(recipeManager.ingredients[0].name, "flour")
        XCTAssertEqual(recipeManager.ingredients[0].targetWeight, 200)
        XCTAssertEqual(recipeManager.ingredients[1].name, "sugar")
        XCTAssertEqual(recipeManager.ingredients[1].targetWeight, 150)
        XCTAssertEqual(recipeManager.ingredients[2].name, "salt")
        XCTAssertEqual(recipeManager.ingredients[2].targetWeight, 3)
    }
    
    func testRecipeWithDifferentUnits() throws {
        recipeManager.recipeInput = "1 cup flour, 2 tbsp oil, 1 tsp vanilla"
        recipeManager.parseRecipe()
        
        XCTAssertEqual(recipeManager.ingredients.count, 3)
        XCTAssertEqual(recipeManager.ingredients[0].targetWeight, 120) // 1 cup flour
        XCTAssertEqual(recipeManager.ingredients[1].targetWeight, 30)  // 2 tbsp
        XCTAssertEqual(recipeManager.ingredients[2].targetWeight, 5)   // 1 tsp
    }
    
    func testIngredientProgress() throws {
        var ingredient = RecipeIngredient(
            id: UUID(),
            name: "flour",
            targetWeight: 100,
            originalAmount: 100,
            originalUnit: "g"
        )
        
        ingredient.currentWeight = 50
        XCTAssertEqual(ingredient.progress, 0.5)
        
        ingredient.currentWeight = 100
        XCTAssertEqual(ingredient.progress, 1.0)
        
        ingredient.currentWeight = 150
        XCTAssertEqual(ingredient.progress, 1.0) // Capped at 1.0
    }
    
    func testRecipeAdvancement() throws {
        recipeManager.recipeInput = "100g flour, 50g sugar"
        recipeManager.parseRecipe()
        
        XCTAssertEqual(recipeManager.currentIngredientIndex, 0)
        
        // Simulate completing first ingredient
        recipeManager.ingredients[0].currentWeight = 100
        recipeManager.ingredients[0].isComplete = true
        recipeManager.currentIngredientIndex = 1
        
        XCTAssertEqual(recipeManager.currentIngredient?.name, "sugar")
    }
}

// MARK: - FlowState Tests

final class FlowStateTests: XCTestCase {
    
    var flowStateManager: FlowStateManager!
    
    override func setUpWithError() throws {
        flowStateManager = FlowStateManager()
    }
    
    func testPourDetection() throws {
        // Simulate pouring by adding increasing weights
        flowStateManager.updateWeight(10)
        Thread.sleep(forTimeInterval: 0.1)
        flowStateManager.updateWeight(15)
        Thread.sleep(forTimeInterval: 0.1)
        flowStateManager.updateWeight(20)
        
        XCTAssertTrue(flowStateManager.isPouring)
        XCTAssertEqual(flowStateManager.pourDirection, .in)
    }
    
    func testPourSpeedCalculation() throws {
        // Add weights at known intervals
        flowStateManager.updateWeight(0)
        Thread.sleep(forTimeInterval: 1.0)
        flowStateManager.updateWeight(10)
        
        // Pour speed should be approximately 10g/s
        XCTAssertGreaterThan(flowStateManager.pourSpeed, 5.0)
    }
    
    func testContainerCapacityWarning() throws {
        // Learn a container pattern
        flowStateManager.learnContainerPattern(maxWeight: 100)
        
        // Approach capacity
        flowStateManager.updateWeight(85)
        Thread.sleep(forTimeInterval: 0.1)
        flowStateManager.updateWeight(92)
        
        XCTAssertTrue(flowStateManager.containerCapacityWarning)
    }
}

// MARK: - Ingredient Analysis Tests

final class IngredientAnalyzerTests: XCTestCase {
    
    var analyzer: IngredientAnalyzer!
    
    override func setUpWithError() throws {
        analyzer = IngredientAnalyzer()
    }
    
    func testIngredientSuggestions() throws {
        analyzer.analyzeCurrentMeasurement(weight: 120, density: 0.6, context: [])
        
        XCTAssertFalse(analyzer.suggestions.isEmpty)
        
        // Should suggest flour (120g is typical cup of flour)
        let flourSuggestion = analyzer.suggestions.first { $0.name == "flour" }
        XCTAssertNotNil(flourSuggestion)
        XCTAssertGreaterThan(flourSuggestion?.confidence ?? 0, 0.6)
    }
    
    func testContextBasedSuggestions() throws {
        analyzer.analyzeCurrentMeasurement(weight: 50, density: 1.0, context: ["flour", "sugar"])
        
        // In baking context, 50g might be eggs
        let eggSuggestion = analyzer.suggestions.first { $0.name == "eggs" }
        XCTAssertNotNil(eggSuggestion)
    }
}

// MARK: - Data Export Tests

final class DataExportTests: XCTestCase {
    
    var exportManager: DataExportManager!
    
    override func setUpWithError() throws {
        exportManager = DataExportManager()
    }
    
    func testSessionCreation() throws {
        let session = MeasurementSession()
        
        XCTAssertNotNil(session.id)
        XCTAssertEqual(session.measurements.count, 0)
        XCTAssertEqual(session.duration, 0)
    }
    
    func testMeasurementCreation() throws {
        let measurement = WeightMeasurement(weight: 50.5, unit: .grams, ingredient: "flour")
        
        XCTAssertEqual(measurement.weight, 50.5)
        XCTAssertEqual(measurement.unit, "g")
        XCTAssertEqual(measurement.ingredient, "flour")
        XCTAssertTrue(measurement.isStable)
    }
    
    func testRecipeCardGeneration() throws {
        let ingredients = [
            RecipeIngredient(id: UUID(), name: "flour", targetWeight: 100, originalAmount: 100, originalUnit: "g"),
            RecipeIngredient(id: UUID(), name: "sugar", targetWeight: 50, originalAmount: 50, originalUnit: "g")
        ]
        
        let actualMeasurements: [Float] = [98, 52]
        
        let card = RecipeCardGenerator.createRecipeCard(ingredients, actualMeasurements: actualMeasurements)
        
        XCTAssertGreaterThan(card.length, 0)
        XCTAssertTrue(card.string.contains("flour"))
        XCTAssertTrue(card.string.contains("sugar"))
    }
}

// MARK: - Gesture Detection Tests

final class GestureTests: XCTestCase {
    
    var gestureManager: GestureManager!
    
    override func setUpWithError() throws {
        gestureManager = GestureManager()
    }
    
    func testDoubleTapDetection() throws {
        let touch1 = TouchPoint(id: 1, position: .zero, pressure: 1.0, timestamp: Date())
        let touch2 = TouchPoint(id: 1, position: .zero, pressure: 1.0, timestamp: Date().addingTimeInterval(0.3))
        
        gestureManager.processTouchEvent(touches: [touch1])
        gestureManager.processTouchEvent(touches: [touch2])
        
        XCTAssertNotNil(gestureManager.lastDoubleTap)
    }
    
    func testGestureStateDetection() throws {
        let recognizer = SmartGestureRecognizer()
        
        // Simulate tap events
        let tapEvent = SmartGestureRecognizer.GestureEvent(
            type: .tap,
            timestamp: Date(),
            confidence: 0.9
        )
        
        recognizer.processEvent(tapEvent)
        recognizer.processEvent(tapEvent)
        
        XCTAssertEqual(recognizer.gestureState, .detectingDoubleTap)
        XCTAssertGreaterThan(recognizer.confidence, 0.8)
    }
} 