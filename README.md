# ChefScale Pro

Transform your MacBook trackpad into a precision kitchen scale with sub-gram accuracy.

![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)
![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## ✨ Features

### 🎯 Precision Weighing
- **Sub-gram accuracy** with advanced Kalman filtering
- **Real-time display** at 60fps with smooth animations
- **Smart tare system** with auto-detection and history
- **Unit conversion** between grams and ounces

### 🍳 Recipe Mode
- Parse and track multiple ingredients
- Visual progress indicators
- Auto-advance when targets are reached
- Export results as formatted PDFs

### 💧 FlowState Detection
- Intelligent pour speed analysis
- Overflow prevention warnings
- Container size learning
- Final weight prediction

### 📊 Advanced Capabilities
- **Calibration mode** for fine-tuning accuracy
- **Ingredient recognition** using pressure patterns
- **Haptic feedback** for tactile response
- **Data export** in PDF, CSV, and JSON formats

## 🚀 Quick Start

### Requirements
- macOS 13.0 or later
- MacBook with Force Touch trackpad
- Xcode 16.0+ (for building from source)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/dipampaul17/chefscale.git
   cd chefscale
   ```

2. **Open in Xcode**
   ```bash
   open ChefScale.xcodeproj
   ```

3. **Build and run**
   - Press `Cmd + R` or click the Run button
   - Grant trackpad access when prompted

## 📖 Usage

### Basic Operation

1. **Launch ChefScale** - The app opens with the scale interface
2. **Place item on trackpad** - Weight displays instantly
3. **Tare (zero) the scale** - Click the tare button or press `T`
4. **Switch units** - Toggle between grams/ounces with one click

### Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `T` | Tare (zero) the scale |
| `C` | Open calibration mode |
| `R` | Toggle recipe mode |
| `Cmd+Z` | Undo last tare |
| `Cmd+E` | Export session data |

### Recipe Mode

1. Press `R` to enter recipe mode
2. Enter ingredients in format: `200g flour, 150g sugar, 3g salt`
3. The app guides you through each ingredient
4. Export results when complete

## 🔧 Calibration

For optimal accuracy:

1. Press `C` to enter calibration mode
2. Use arrow keys to adjust offset (-5g to +5g)
3. Monitor signal quality indicator
4. Export calibration logs for analysis

## 🏗 Architecture

ChefScale uses a modern SwiftUI architecture:

- **MVVM pattern** for clean separation of concerns
- **Combine framework** for reactive data flow
- **Custom trackpad integration** without external dependencies
- **Comprehensive test coverage** with unit and UI tests

## 🧪 Testing

Run the test suite:

```bash
# Unit tests
./run_tests.sh

# End-to-end tests
python3 run_e2e_tests.py
```

## 📝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## 📄 License

ChefScale Pro is available under the MIT License. See [LICENSE](LICENSE) for details.

## 🙏 Acknowledgments

Built with SwiftUI and the power of Force Touch trackpads. Special thanks to the macOS developer community for inspiration and support.

---

<p align="center">Made with ❤️ for precision cooking</p> 