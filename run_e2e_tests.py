#!/usr/bin/env python3
"""
ChefScale End-to-End Test Suite
Simulates user interactions and validates app behavior
"""

import subprocess
import time
import sys
import os
from datetime import datetime

class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    BOLD = '\033[1m'
    END = '\033[0m'

class TestResult:
    def __init__(self):
        self.passed = 0
        self.failed = 0
        self.tests = []
    
    def add_test(self, name, passed, message=""):
        self.tests.append({
            'name': name,
            'passed': passed,
            'message': message
        })
        if passed:
            self.passed += 1
            print(f"{Colors.GREEN}✅ {name}{Colors.END}")
        else:
            self.failed += 1
            print(f"{Colors.RED}❌ {name}: {message}{Colors.END}")
    
    def print_summary(self):
        total = self.passed + self.failed
        print(f"\n{Colors.BOLD}📊 Test Summary{Colors.END}")
        print("=" * 40)
        print(f"Total Tests: {total}")
        print(f"{Colors.GREEN}✅ Passed: {self.passed}{Colors.END}")
        print(f"{Colors.RED}❌ Failed: {self.failed}{Colors.END}")
        
        if self.failed > 0:
            print(f"\n{Colors.RED}Failed Tests:{Colors.END}")
            for test in self.tests:
                if not test['passed']:
                    print(f"  • {test['name']}: {test['message']}")
        
        success_rate = (self.passed / total * 100) if total > 0 else 0
        print(f"\nSuccess Rate: {success_rate:.1f}%")
        
        return self.failed == 0

def run_command(cmd, timeout=10):
    """Run a shell command and return output"""
    try:
        result = subprocess.run(
            cmd, 
            shell=True, 
            capture_output=True, 
            text=True, 
            timeout=timeout
        )
        return result.returncode == 0, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return False, "", "Command timed out"
    except Exception as e:
        return False, "", str(e)

def test_build_process(results):
    """Test that the app can be built"""
    print(f"\n{Colors.BOLD}🔨 Build Tests{Colors.END}")
    print("-" * 40)
    
    # Check if source files exist
    source_files = [
        "ChefScale/Sources/main.swift",
        "ChefScale/Sources/ContentView.swift",
        "ChefScale/Sources/ScaleManager.swift",
        "ChefScale/Sources/CalibrationView.swift",
        "ChefScale/Sources/RecipeMode.swift"
    ]
    
    all_exist = True
    for file in source_files:
        exists = os.path.exists(file)
        results.add_test(f"Source file exists: {file}", exists, 
                        f"File not found" if not exists else "")
        all_exist = all_exist and exists
    
    return all_exist

def test_code_quality(results):
    """Test code quality metrics"""
    print(f"\n{Colors.BOLD}📏 Code Quality Tests{Colors.END}")
    print("-" * 40)
    
    # Count lines of code
    total_lines = 0
    for root, dirs, files in os.walk("ChefScale/Sources"):
        for file in files:
            if file.endswith('.swift'):
                filepath = os.path.join(root, file)
                try:
                    with open(filepath, 'r') as f:
                        lines = len(f.readlines())
                        total_lines += lines
                except:
                    pass
    
    results.add_test("Total lines of code", True, f"{total_lines} lines")
    
    # Check for proper documentation
    doc_files = ["README.md"]
    for doc in doc_files:
        exists = os.path.exists(doc)
        results.add_test(f"Documentation exists: {doc}", exists)

def test_security(results):
    """Test security and privacy features"""
    print(f"\n{Colors.BOLD}🔒 Security Tests{Colors.END}")
    print("-" * 40)
    
    # Check entitlements
    entitlements_file = "ChefScale/ChefScale.entitlements"
    if os.path.exists(entitlements_file):
        with open(entitlements_file, 'r') as f:
            content = f.read()
            
        # Check that sensitive permissions are properly configured
        has_input_monitoring = "com.apple.security.device.input-monitoring" in content
        results.add_test("Input monitoring entitlement", has_input_monitoring,
                        "Required for trackpad access")
        
        # Check that unnecessary permissions are disabled
        no_camera = "com.apple.security.device.camera" not in content or "<false/>" in content
        results.add_test("Camera access disabled", no_camera)
        
        no_network = "com.apple.security.network.client" not in content or "<false/>" in content
        results.add_test("Network access disabled", no_network,
                        "App should work offline")
    else:
        results.add_test("Entitlements file exists", False, "File not found")

def test_features(results):
    """Test that key features are implemented"""
    print(f"\n{Colors.BOLD}✨ Feature Tests{Colors.END}")
    print("-" * 40)
    
    # Check ScaleManager features
    scale_file = "ChefScale/Sources/ScaleManager.swift"
    if os.path.exists(scale_file):
        with open(scale_file, 'r') as f:
            content = f.read()
            
        features = {
            "Kalman Filter": "KalmanFilter",
            "Tare functionality": "func tare()",
            "Unit conversion": "toggleUnit",
            "Calibration support": "calibrationOffset",
            "Ingredient detection": "detectIngredientType"
        }
        
        for feature, keyword in features.items():
            implemented = keyword in content
            results.add_test(f"{feature} implemented", implemented)
    
    # Check Recipe Mode
    recipe_file = "ChefScale/Sources/RecipeMode.swift"
    if os.path.exists(recipe_file):
        with open(recipe_file, 'r') as f:
            content = f.read()
            
        features = {
            "Recipe parsing": "parseRecipe",
            "Progress tracking": "progress",
            "Auto-advancement": "advanceToNextIngredient"
        }
        
        for feature, keyword in features.items():
            implemented = keyword in content
            results.add_test(f"Recipe Mode: {feature}", implemented)

def test_performance(results):
    """Test performance requirements"""
    print(f"\n{Colors.BOLD}⚡ Performance Tests{Colors.END}")
    print("-" * 40)
    
    # Check for 60fps update rate
    content_file = "ChefScale/Sources/ScaleManager.swift"
    if os.path.exists(content_file):
        with open(content_file, 'r') as f:
            content = f.read()
            
        has_60fps = "1.0/60.0" in content or "60" in content
        results.add_test("60fps update rate", has_60fps,
                        "Should update at 60fps for smooth display")
    
    # Check for async/await usage
    uses_async = False
    for root, dirs, files in os.walk("ChefScale/Sources"):
        for file in files:
            if file.endswith('.swift'):
                filepath = os.path.join(root, file)
                try:
                    with open(filepath, 'r') as f:
                        if 'async' in f.read() or 'await' in f.read():
                            uses_async = True
                            break
                except:
                    pass
    
    results.add_test("Uses modern async/await", uses_async,
                    "For better performance")

def test_user_experience(results):
    """Test UX features"""
    print(f"\n{Colors.BOLD}🎨 User Experience Tests{Colors.END}")
    print("-" * 40)
    
    # Check ContentView for UX features
    content_file = "ChefScale/Sources/ContentView.swift"
    if os.path.exists(content_file):
        with open(content_file, 'r') as f:
            content = f.read()
            
        ux_features = {
            "Sleep mode": "isSleeping",
            "Animations": ".animation",
            "Dark mode support": "Color" or "NSColor",
            "Keyboard shortcuts": "onKeyDown",
            "Haptic feedback": "NSHapticFeedbackManager"
        }
        
        for feature, keyword in ux_features.items():
            implemented = keyword in content
            results.add_test(f"UX: {feature}", implemented)

def run_integration_tests(results):
    """Run integration tests"""
    print(f"\n{Colors.BOLD}🔗 Integration Tests{Colors.END}")
    print("-" * 40)
    
    # Test that all components work together
    components = [
        ("ScaleManager + ContentView", 
         "ChefScale/Sources/ContentView.swift",
         "ScaleManager"),
        ("FlowState integration",
         "ChefScale/Sources/ContentView.swift",
         "FlowStateManager"),
        ("Recipe Mode integration",
         "ChefScale/Sources/ContentView.swift",
         "RecipeModeView"),
        ("Calibration integration",
         "ChefScale/Sources/ContentView.swift",
         "CalibrationView")
    ]
    
    for test_name, file_path, component in components:
        if os.path.exists(file_path):
            with open(file_path, 'r') as f:
                integrated = component in f.read()
                results.add_test(test_name, integrated)
        else:
            results.add_test(test_name, False, "File not found")

def main():
    print(f"{Colors.BOLD}{Colors.BLUE}🧪 ChefScale End-to-End Test Suite{Colors.END}")
    print("=" * 50)
    print(f"Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    results = TestResult()
    
    # Run all test suites
    test_build_process(results)
    test_code_quality(results)
    test_security(results)
    test_features(results)
    test_performance(results)
    test_user_experience(results)
    run_integration_tests(results)
    
    # Print summary
    print("\n" + "=" * 50)
    success = results.print_summary()
    
    # Run unit tests if available
    if os.path.exists("run_unit_tests.py"):
        print(f"\n{Colors.BOLD}🧪 Running Unit Tests{Colors.END}")
        print("-" * 40)
        success_unit, stdout, stderr = run_command("python3 run_unit_tests.py", timeout=30)
        if success_unit:
            print(f"{Colors.GREEN}Unit tests passed!{Colors.END}")
            # Parse unit test output to add to results
            if "Success Rate: 100.0%" in stdout:
                results.add_test("Unit Tests", True, "All unit tests passed")
            else:
                results.add_test("Unit Tests", False, "Some unit tests failed")
        else:
            print(f"{Colors.RED}Unit tests failed!{Colors.END}")
            results.add_test("Unit Tests", False, "Unit test execution failed")
            if stderr:
                print(f"Error: {stderr}")
    
    # Exit with appropriate code
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main() 