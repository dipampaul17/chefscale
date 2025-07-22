# ChefScale Pro

> Transform your MacBook trackpad into the world's most precise kitchen scale

ChefScale Pro leverages the Force Touch sensors in modern MacBook trackpads to create an incredibly accurate digital kitchen scale. With sub-gram precision and intelligent features, it's the only scale you'll ever need for cooking and baking.

![ChefScale Demo](https://via.placeholder.com/600x400/2563eb/ffffff?text=ChefScale+Pro)

## ✨ Features

### Core Weighing Engine
- **Sub-gram accuracy** - Precise measurements down to 0.1g
- **Real-time display** - 60fps+ updates with smooth animations
- **Instant tare** - Zero the scale with one tap or double-tap gesture
- **Unit conversion** - Toggle between grams and ounces
- **Smart stability detection** - Visual feedback when weight is stable

### Intelligent Features
- **Auto-tare detection** - Suggests when to zero for new ingredients
- **Ingredient recognition** - Identifies common measurements (tsp, tbsp, cups)
- **Recipe mode** - Guided measurements with progress tracking
- **FlowState™** - Predictive pour detection with overflow warnings
- **Haptic feedback** - Physical sensations for perfect measurements

### Professional Polish
- **Beautiful UI** - Clean, minimal design following Dieter Rams principles
- **Dark mode support** - High contrast mode perfect for kitchens
- **Export functionality** - Save measurements as formatted PDFs
- **Calibration system** - Fine-tune accuracy with advanced tools
- **Sleep mode** - Auto-sleep after 2 minutes, wake on touch

## 🚀 Quick Start

### Requirements
- macOS 13.0 or later
- MacBook with Force Touch trackpad (2015 or newer)
- Xcode 16.0+ (for building from source)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/chefscale/chefscale-pro.git
   cd chefscale-pro
   ```

2. **Install dependencies**
   ```bash
   swift package resolve
   ```

3. **Build and run**
   ```bash
   swift run ChefScale
   ```

   Or open in Xcode:
   ```bash
   open Package.swift
   ```

4. **Disable App Sandbox** (Required)
   - In Xcode: Project Settings → Signing & Capabilities → Remove "App Sandbox"
   - This is required for trackpad access

## 📖 Usage Guide

### Basic Weighing
1. **Launch ChefScale** - The app will display "0g" 
2. **Place finger on trackpad** - Required for pressure detection
3. **Add ingredients** - Weight updates in real-time
4. **Tare as needed** - Tap TARE button or double-tap trackpad

### Recipe Mode
1. **Enter recipe** - Format: "200g flour, 150g sugar, 3g salt"
2. **Follow guidance** - Visual progress rings show completion
3. **Auto-advance** - Moves to next ingredient when target reached
4. **Export results** - Save actual vs. target measurements

### Calibration (Advanced)
1. **Press 'C' key** - Opens calibration mode
2. **View raw data** - See pressure readings and signal quality
3. **Adjust offset** - Fine-tune accuracy (±5g range)
4. **Export logs** - Save calibration data as CSV

## 🎯 Accuracy Tips

### For Best Results
- **Keep finger in contact** - Capacitance detection required
- **Use center of trackpad** - Most sensitive area
- **Avoid electrical interference** - Keep away from phones/chargers
- **Calibrate regularly** - Especially after major temperature changes
- **Clean trackpad** - Remove oils and debris

### Limitations
- **Maximum weight**: ~3.5kg (trackpad protection limit)
- **Conductive objects**: Wrap in paper/cloth to prevent interference
- **Size constraint**: Items must fit entirely on trackpad
- **Finger requirement**: Must maintain skin contact during weighing

## 🛠 Technical Details

### Architecture
```
ChefScale/
├── Sources/
│   ├── main.swift              # App entry point
│   ├── ContentView.swift       # Main UI
│   ├── ScaleManager.swift      # Core weighing logic
│   ├── CalibrationView.swift   # Calibration interface
│   ├── RecipeMode.swift        # Guided measurements
│   └── AdvancedFeatures.swift  # FlowState & intelligence
├── Package.swift               # Dependencies
├── Info.plist                  # App configuration
└── README.md                   # This file
```

### Key Technologies
- **OpenMultitouchSupport** - Raw trackpad data access
- **SwiftUI** - Modern, reactive interface
- **Combine** - Reactive data streams
- **Kalman Filter** - Noise reduction algorithm
- **Core Haptics** - Tactile feedback

### Data Flow
1. **Raw pressure** → OpenMultitouchSupport
2. **Filtering** → Kalman filter for smoothing
3. **Calibration** → Apply user offset correction
4. **Display** → Real-time UI updates at 60fps
5. **Intelligence** → Pattern recognition and suggestions

## 🎨 Design Philosophy

Following Jack Dorsey's principles of doing less, better:

- **One purpose**: Weighing ingredients with unprecedented precision
- **No feature creep**: No timers, nutrition tracking, or social features
- **Every detail matters**: Sub-gram accuracy, smooth animations, perfect typography
- **Constraint as feature**: Finger requirement becomes hygiene benefit
- **Local first**: All data stays on your device

## 🔧 Advanced Features

### FlowState™ Pour Detection
- Analyzes pour rate and predicts final weight
- Shows "ghost number" of predicted result
- Warns before container overflow
- Learns common container sizes

### Smart Ingredient Recognition
- Detects common measurements (1 tsp ≈ 5g, 1 tbsp ≈ 15g)
- Suggests next likely ingredients based on context
- Learns from usage patterns
- Provides confidence ratings

### Haptic Intelligence
- Different patterns for different ingredient types
- Smooth pour vs. rough pour feedback
- Warning vibrations for capacity limits
- Success patterns for target achievement

## 📊 Calibration Science

ChefScale uses advanced signal processing for maximum accuracy:

### Kalman Filtering
```swift
// Reduces sensor noise while maintaining responsiveness
let kalmanGain = predictedError / (predictedError + measurementNoise)
estimate = estimate + kalmanGain * (measurement - estimate)
```

### Rolling Average
- 100-sample window for stability detection
- Weighted average favoring recent readings
- Outlier rejection for spurious signals

### Temperature Compensation
- Automatic drift correction
- Baseline recalibration during idle periods
- Thermal stability monitoring

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

### Reporting Issues
- Use GitHub Issues for bug reports
- Include macOS version and MacBook model
- Provide steps to reproduce
- Attach calibration logs if relevant

## 📜 License

ChefScale Pro is released under the MIT License. See [LICENSE](LICENSE) for details.

---

**Made with ❤️ for cooks who care about precision**

*ChefScale Pro - Because every gram matters.* 