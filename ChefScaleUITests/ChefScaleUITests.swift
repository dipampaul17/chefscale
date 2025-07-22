import XCTest

final class ChefScaleUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Main UI Tests
    
    func testMainUIElements() throws {
        // Check that main UI elements exist
        XCTAssertTrue(app.staticTexts["0"].exists || app.staticTexts["0.0"].exists, "Weight display should show 0")
        XCTAssertTrue(app.buttons["TARE"].exists, "Tare button should exist")
        XCTAssertTrue(app.buttons["g"].exists || app.buttons["oz"].exists, "Unit button should exist")
        XCTAssertTrue(app.buttons["Recipe"].exists, "Recipe button should exist")
    }
    
    func testTareButton() throws {
        let tareButton = app.buttons["TARE"]
        XCTAssertTrue(tareButton.exists)
        
        // Tap tare button
        tareButton.tap()
        
        // Should still show 0 if no weight
        XCTAssertTrue(app.staticTexts["0"].exists || app.staticTexts["0.0"].exists)
    }
    
    func testUnitToggle() throws {
        let unitButton = app.buttons["g"]
        XCTAssertTrue(unitButton.exists)
        
        // Toggle to ounces
        unitButton.tap()
        
        // Should now show oz
        XCTAssertTrue(app.buttons["oz"].exists)
        
        // Toggle back to grams
        app.buttons["oz"].tap()
        XCTAssertTrue(app.buttons["g"].exists)
    }
    
    func testRecipeMode() throws {
        let recipeButton = app.buttons["Recipe"]
        XCTAssertTrue(recipeButton.exists)
        
        // Open recipe mode
        recipeButton.tap()
        
        // Check recipe mode UI
        XCTAssertTrue(app.staticTexts["Recipe Mode"].exists)
        XCTAssertTrue(app.staticTexts["Enter Recipe"].exists || app.textViews.count > 0)
        
        // Close recipe mode
        if app.buttons["Close"].exists {
            app.buttons["Close"].tap()
        }
    }
    
    // MARK: - Calibration Mode Tests
    
    func testCalibrationMode() throws {
        // Press 'C' key to open calibration
        app.typeText("c")
        
        // Check calibration UI elements
        XCTAssertTrue(app.staticTexts["Calibration Mode"].exists)
        XCTAssertTrue(app.staticTexts["Raw Sensor Data"].exists)
        XCTAssertTrue(app.buttons["Apply & Close"].exists)
        
        // Test offset adjustment buttons
        if app.buttons["+0.1g"].exists {
            app.buttons["+0.1g"].tap()
        }
        
        if app.buttons["-0.1g"].exists {
            app.buttons["-0.1g"].tap()
        }
        
        // Close calibration
        app.buttons["Cancel"].tap()
    }
    
    // MARK: - Sleep Mode Tests
    
    func testSleepModeUI() throws {
        // In a real test, we'd wait for 2 minutes or mock the timer
        // For now, just check initial state
        
        XCTAssertFalse(app.staticTexts["Touch trackpad to wake"].exists)
    }
    
    // MARK: - Keyboard Shortcuts Tests
    
    func testKeyboardShortcuts() throws {
        // Test Recipe shortcut
        app.typeText("r")
        XCTAssertTrue(app.staticTexts["Recipe Mode"].exists)
        app.buttons["Close"].tap()
        
        // Test Calibration shortcut
        app.typeText("c")
        XCTAssertTrue(app.staticTexts["Calibration Mode"].exists)
        app.buttons["Cancel"].tap()
        
        // Test spacebar for tare
        app.typeText(" ")
        // Should not crash and weight should still be 0
        XCTAssertTrue(app.staticTexts["0"].exists || app.staticTexts["0.0"].exists)
    }
    
    // MARK: - Recipe Input Tests
    
    func testRecipeInput() throws {
        app.buttons["Recipe"].tap()
        
        let textView = app.textViews.firstMatch
        if textView.exists {
            textView.tap()
            textView.typeText("100g flour, 50g sugar")
            
            // Parse recipe
            app.buttons["Parse Recipe"].tap()
            
            // Should show ingredients
            XCTAssertTrue(app.staticTexts["Flour"].exists || app.staticTexts["flour"].exists)
            XCTAssertTrue(app.staticTexts["Sugar"].exists || app.staticTexts["sugar"].exists)
        }
        
        app.buttons["Close"].tap()
    }
    
    // MARK: - Status Indicators Tests
    
    func testStatusIndicators() throws {
        // Check for hint text
        XCTAssertTrue(app.staticTexts.element(matching: NSPredicate(format: "label CONTAINS[c] 'Press'")).exists)
        
        // Check unit display
        XCTAssertTrue(app.staticTexts["g"].exists || app.staticTexts["oz"].exists)
    }
}

// MARK: - Performance Tests

final class ChefScalePerformanceTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        app = XCUIApplication()
        app.launch()
    }
    
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    func testUIResponsiveness() throws {
        measure {
            // Toggle units multiple times
            for _ in 0..<10 {
                if app.buttons["g"].exists {
                    app.buttons["g"].tap()
                } else if app.buttons["oz"].exists {
                    app.buttons["oz"].tap()
                }
            }
        }
    }
    
    func testRecipeModePerformance() throws {
        measure {
            app.buttons["Recipe"].tap()
            
            if app.buttons["Close"].exists {
                app.buttons["Close"].tap()
            }
        }
    }
} 