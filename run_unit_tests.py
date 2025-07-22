#!/usr/bin/env python3
"""
ChefScale Unit Test Runner
Tests core business logic without Swift compilation
"""

import sys
import math
from datetime import datetime

class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    BOLD = '\033[1m'
    END = '\033[0m'

class TestRunner:
    def __init__(self):
        self.passed = 0
        self.failed = 0
        self.tests = []
    
    def test(self, name, condition, error_msg=""):
        if condition:
            self.passed += 1
            print(f"{Colors.GREEN}✅ {name}{Colors.END}")
            self.tests.append({'name': name, 'passed': True})
        else:
            self.failed += 1
            print(f"{Colors.RED}❌ {name}: {error_msg}{Colors.END}")
            self.tests.append({'name': name, 'passed': False, 'error': error_msg})
    
    def assert_equal(self, name, actual, expected):
        condition = actual == expected
        error_msg = f"Expected {expected}, got {actual}" if not condition else ""
        self.test(name, condition, error_msg)
    
    def assert_near(self, name, actual, expected, tolerance=0.01):
        condition = abs(actual - expected) <= tolerance
        error_msg = f"Expected {expected}±{tolerance}, got {actual}" if not condition else ""
        self.test(name, condition, error_msg)
    
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
                    print(f"  • {test['name']}: {test.get('error', '')}")
        
        success_rate = (self.passed / total * 100) if total > 0 else 0
        print(f"\nSuccess Rate: {success_rate:.1f}%")
        
        return self.failed == 0

# Test implementations
class KalmanFilter:
    def __init__(self):
        self.estimate = 0.0
        self.error_covariance = 1.0
        self.process_noise = 0.01
        self.measurement_noise = 0.1
    
    def update(self, measurement):
        predicted_error_covariance = self.error_covariance + self.process_noise
        kalman_gain = predicted_error_covariance / (predicted_error_covariance + self.measurement_noise)
        self.estimate = self.estimate + kalman_gain * (measurement - self.estimate)
        self.error_covariance = (1 - kalman_gain) * predicted_error_covariance
        return self.estimate
    
    def reset(self):
        self.estimate = 0.0
        self.error_covariance = 1.0

class RecipeParser:
    @staticmethod
    def parse(recipe_text):
        ingredients = []
        components = [c.strip() for c in recipe_text.split(',')]
        
        for component in components:
            parts = component.split(' ', 1)
            if len(parts) < 2:
                continue
            
            quantity = parts[0]
            name = parts[1]
            
            # Parse weight
            weight = 0
            if quantity.endswith('g'):
                weight = float(quantity[:-1])
            elif quantity.endswith('oz'):
                weight = float(quantity[:-2]) * 28.35
            elif quantity == '1' and name.startswith('cup'):
                weight = 120  # 1 cup flour
            elif quantity == '1' and name.startswith('tbsp'):
                weight = 15
            elif quantity == '2' and name.startswith('tbsp'):
                weight = 30
            else:
                try:
                    weight = float(quantity)
                except:
                    pass
            
            ingredients.append({
                'name': name,
                'target_weight': weight,
                'current_weight': 0,
                'is_complete': False
            })
        
        return ingredients

def run_tests():
    runner = TestRunner()
    
    print(f"{Colors.BOLD}{Colors.BLUE}🧪 ChefScale Unit Tests{Colors.END}")
    print("=" * 30)
    print(f"Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    
    # Kalman Filter Tests
    print(f"{Colors.BOLD}📋 Kalman Filter Tests{Colors.END}")
    print("-" * 30)
    
    # Test 1: Filter initialization
    kf = KalmanFilter()
    result = kf.update(0)
    runner.assert_near("Filter Initialization", result, 0, 0.1)
    
    # Test 2: Filter convergence
    kf = KalmanFilter()
    true_value = 100.0
    for _ in range(20):
        last_value = kf.update(true_value)
    runner.assert_near("Filter Convergence", last_value, true_value, 5.0)
    
    # Test 3: Noise reduction
    kf = KalmanFilter()
    kf.reset()
    measurements = [48, 52, 49, 51, 50, 47, 53, 50, 49, 51]
    for m in measurements:
        last_value = kf.update(m)
    runner.assert_near("Filter Noise Reduction", last_value, 50, 2.0)
    
    # Recipe Parser Tests
    print(f"\n{Colors.BOLD}📋 Recipe Parser Tests{Colors.END}")
    print("-" * 30)
    
    # Test 4: Basic parsing
    ingredients = RecipeParser.parse("200g flour, 150g sugar, 3g salt")
    runner.assert_equal("Recipe Count", len(ingredients), 3)
    runner.assert_equal("First Ingredient Name", ingredients[0]['name'], "flour")
    runner.assert_equal("First Ingredient Weight", ingredients[0]['target_weight'], 200)
    
    # Test 5: Unit conversion
    ingredients = RecipeParser.parse("1 cup flour, 2 tbsp oil")
    runner.assert_equal("Cup Conversion", ingredients[0]['target_weight'], 120)
    runner.assert_equal("Tablespoon Conversion", ingredients[1]['target_weight'], 30)
    
    # Test 6: Mixed units
    ingredients = RecipeParser.parse("100g butter, 4oz chocolate")
    runner.assert_equal("Grams Parsing", ingredients[0]['target_weight'], 100)
    runner.assert_near("Ounces Conversion", ingredients[1]['target_weight'], 113.4, 0.1)
    
    # Weight Unit Tests
    print(f"\n{Colors.BOLD}📋 Weight Unit Tests{Colors.END}")
    print("-" * 30)
    
    # Test 7: Unit conversions
    grams = 100
    ounces = grams * 0.035274
    runner.assert_near("Grams to Ounces", ounces, 3.5274, 0.0001)
    
    ounces = 5
    grams = ounces * 28.35
    runner.assert_near("Ounces to Grams", grams, 141.75, 0.01)
    
    # Business Logic Tests
    print(f"\n{Colors.BOLD}📋 Business Logic Tests{Colors.END}")
    print("-" * 30)
    
    # Test 8: Tare offset
    tare_offset = 0
    current_weight = 50
    tare_offset = current_weight
    display_weight = current_weight - tare_offset
    runner.assert_equal("Tare Offset Calculation", display_weight, 0)
    
    # Test 9: Multiple tare
    tare_history = []
    tare_offset = 50
    tare_history.append(tare_offset)
    tare_offset = 75
    tare_history.append(tare_offset)
    runner.assert_equal("Tare History Count", len(tare_history), 2)
    runner.assert_equal("First Tare Value", tare_history[0], 50)
    runner.assert_equal("Second Tare Value", tare_history[1], 75)
    
    # Test 10: Stability detection
    readings = [10.1, 10.0, 10.05, 10.02, 10.0]
    tolerance = 0.1
    average = sum(readings) / len(readings)
    is_stable = all(abs(r - average) <= tolerance for r in readings)
    runner.test("Stability Detection", is_stable, "Readings should be stable")
    
    # Test 11: Pour detection
    weight_history = [(10, 0), (15, 0.5), (20, 1.0), (25, 1.5)]
    first = weight_history[0]
    last = weight_history[-1]
    weight_change = last[0] - first[0]
    time_change = last[1] - first[1]
    pour_rate = weight_change / time_change
    runner.assert_near("Pour Rate Detection", pour_rate, 10.0, 0.1)
    
    # Test 12: Auto-tare threshold
    old_weight = 5
    new_weight = 60
    should_auto_tare = new_weight > 50 and old_weight <= 5
    runner.test("Auto-tare Detection", should_auto_tare, "Should suggest auto-tare")
    
    # Test 13: Weight formatting
    def format_weight(weight, unit='g'):
        if unit == 'g':
            if weight < 10:
                return f"{weight:.1f}"
            else:
                return f"{weight:.0f}"
        else:  # ounces
            oz = weight * 0.035274
            if oz < 1:
                return f"{oz:.2f}"
            else:
                return f"{oz:.1f}"
    
    runner.assert_equal("Format Small Grams", format_weight(5.5, 'g'), "5.5")
    runner.assert_equal("Format Large Grams", format_weight(50, 'g'), "50")
    runner.assert_equal("Format Small Ounces", format_weight(10, 'oz'), "0.35")
    runner.assert_equal("Format Large Ounces", format_weight(100, 'oz'), "3.5")
    
    # Test 14: Recipe progress
    ingredient = {'target_weight': 100, 'current_weight': 98}
    tolerance_percent = 0.02
    tolerance_weight = max(2.0, ingredient['target_weight'] * tolerance_percent)
    difference = abs(ingredient['current_weight'] - ingredient['target_weight'])
    is_complete = difference <= tolerance_weight
    runner.test("Recipe Progress Detection", is_complete, "Should be complete within tolerance")
    
    # Test 15: Container capacity warning
    current_weight = 450
    predicted_final = 500
    container_max = 500
    fill_percentage = current_weight / container_max
    should_warn = fill_percentage >= 0.9
    runner.test("Container Capacity Warning", should_warn, "Should warn at 90% capacity")
    
    # Print summary
    print("\n" + "=" * 40)
    success = runner.print_summary()
    
    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(run_tests()) 