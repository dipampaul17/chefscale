# ChefScale Pro - Project Structure

## 📁 Directory Overview

```
chefscale/
├── ChefScale.xcodeproj/         # Xcode project configuration
├── ChefScale/                   # Main application
│   ├── Info.plist              # App metadata and permissions
│   ├── ChefScale.entitlements  # Security entitlements
│   └── Sources/                # Swift source files
│       ├── main.swift          # App entry point
│       ├── ContentView.swift   # Main UI view
│       ├── ScaleManager.swift  # Core weighing logic
│       ├── CalibrationView.swift    # Calibration interface
│       ├── RecipeMode.swift         # Recipe guidance system
│       ├── AdvancedFeatures.swift   # FlowState & AI features
│       ├── GestureSupport.swift     # Touch gesture handling
│       ├── DataExport.swift         # Export functionality
│       └── OpenMultitouchBridge.swift # Trackpad integration
├── ChefScaleTests/             # Unit tests
│   ├── ChefScaleTests.swift    # Test implementations
│   └── Info.plist
├── ChefScaleUITests/           # UI tests
│   ├── ChefScaleUITests.swift  # UI test implementations
│   └── Info.plist
├── run_tests.sh                # Shell script for running tests
├── run_e2e_tests.py           # Python E2E test suite
├── README.md                   # Project documentation
├── LICENSE                     # MIT License
├── CONTRIBUTING.md            # Contribution guidelines
└── .gitignore                 # Git ignore patterns
```

## 🏗 Architecture

### Core Components

1. **ScaleManager** (`ScaleManager.swift`)
   - Handles trackpad pressure detection
   - Implements Kalman filtering for noise reduction
   - Manages calibration and tare operations
   - Provides weight calculations and unit conversion

2. **ContentView** (`ContentView.swift`)
   - Main UI implementation
   - Integrates all features (FlowState, Recipe Mode, etc.)
   - Handles keyboard shortcuts and gestures
   - Manages sleep/wake states

3. **OpenMultitouchBridge** (`OpenMultitouchBridge.swift`)
   - Interfaces with macOS trackpad APIs
   - Provides pressure data stream
   - Simulates OpenMultitouchSupport API

### Feature Modules

4. **CalibrationView** (`CalibrationView.swift`)
   - Advanced calibration interface
   - Raw sensor data visualization
   - Signal quality analysis
   - Export calibration logs

5. **RecipeMode** (`RecipeMode.swift`)
   - Recipe parsing and management
   - Progress tracking for ingredients
   - Auto-advancement logic
   - PDF export for results

6. **AdvancedFeatures** (`AdvancedFeatures.swift`)
   - FlowState pour detection
   - Ingredient recognition AI
   - Enhanced weight display
   - Container capacity warnings

7. **GestureSupport** (`GestureSupport.swift`)
   - Double-tap detection
   - Shake gestures
   - Haptic feedback coordination
   - Smart gesture recognition

8. **DataExport** (`DataExport.swift`)
   - Session data management
   - PDF/CSV/JSON export
   - Recipe card generation
   - Measurement history

## 🔄 Data Flow

```
Trackpad Pressure → OpenMultitouchBridge → ScaleManager → ContentView
                                               ↓
                                        [Features & UI]
                                               ↓
                                         User Interface
```

## 🧪 Testing Strategy

- **Unit Tests**: Test individual components in isolation
- **UI Tests**: Validate user interface interactions
- **E2E Tests**: Verify complete user workflows
- **Performance Tests**: Ensure 60fps and responsiveness

## 🔑 Key Design Patterns

1. **MVVM**: Clear separation of views and logic
2. **Observable Objects**: Reactive data flow with Combine
3. **Dependency Injection**: Testable architecture
4. **Protocol-Oriented**: Flexible and extensible design

## 📝 Code Style

- Swift 6.0 language features
- SwiftUI for all UI components
- Async/await for asynchronous operations
- Comprehensive error handling
- Clear naming conventions 