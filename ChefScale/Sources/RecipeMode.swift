import SwiftUI
import Combine

struct RecipeModeView: View {
    @ObservedObject var scaleManager: ScaleManager
    @StateObject private var recipeManager = RecipeManager()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            headerView
            
            if recipeManager.ingredients.isEmpty {
                recipeInputView
            } else {
                activeRecipeView
            }
        }
        .padding()
        .frame(width: 500, height: 600)
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Recipe Mode")
                    .font(.title)
                    .fontWeight(.bold)
                
                if !recipeManager.ingredients.isEmpty {
                    Text("Follow the measurements below")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button("Close") {
                dismiss()
            }
        }
    }
    
    private var recipeInputView: some View {
        VStack(spacing: 16) {
            Text("Enter Recipe")
                .font(.headline)
            
            Text("Format: \"200g flour, 150g sugar, 3g salt\"")
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextEditor(text: $recipeManager.recipeInput)
                .frame(height: 150)
                .border(Color.gray.opacity(0.3))
            
            Button("Parse Recipe") {
                recipeManager.parseRecipe()
            }
            .buttonStyle(.borderedProminent)
            .disabled(recipeManager.recipeInput.isEmpty)
            
            if !recipeManager.parseError.isEmpty {
                Text(recipeManager.parseError)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }
    
    private var activeRecipeView: some View {
        VStack(spacing: 16) {
            // Current ingredient spotlight
            if let currentIngredient = recipeManager.currentIngredient {
                currentIngredientView(currentIngredient)
            }
            
            // Progress overview
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(recipeManager.ingredients) { ingredient in
                        ingredientRowView(ingredient)
                    }
                }
            }
            
            // Controls
            HStack {
                Button("Reset Recipe") {
                    recipeManager.reset()
                }
                
                Spacer()
                
                Button("Export Results") {
                    exportResults()
                }
                .disabled(!recipeManager.isComplete)
            }
        }
        .onReceive(scaleManager.$displayWeight) { weight in
            recipeManager.updateWeight(weight)
        }
        .onReceive(scaleManager.$isStable) { stable in
            if stable {
                recipeManager.checkAdvancement()
            }
        }
    }
    
    private func currentIngredientView(_ ingredient: RecipeIngredient) -> some View {
        VStack(spacing: 12) {
            Text(ingredient.name.capitalized)
                .font(.title2)
                .fontWeight(.semibold)
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: ingredient.progress)
                    .stroke(ingredient.progressColor, lineWidth: 8)
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: ingredient.progress)
                
                VStack {
                    Text("\(Int(ingredient.currentWeight))g")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("of \(Int(ingredient.targetWeight))g")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if ingredient.isComplete {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Complete!")
                        .fontWeight(.medium)
                }
                .transition(.scale.combined(with: .opacity))
            } else if ingredient.isInProgress {
                Text("Keep adding...")
                    .foregroundColor(.blue)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func ingredientRowView(_ ingredient: RecipeIngredient) -> some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(ingredient.statusColor)
                .frame(width: 12, height: 12)
            
            // Ingredient name
            Text(ingredient.name.capitalized)
                .font(.body)
                .fontWeight(ingredient.isCurrent ? .semibold : .regular)
            
            Spacer()
            
            // Progress
            HStack(spacing: 8) {
                Text("\(Int(ingredient.currentWeight))")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(ingredient.isCurrent ? .primary : .secondary)
                
                Text("/")
                    .foregroundColor(.secondary)
                
                Text("\(Int(ingredient.targetWeight))g")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
                
                if ingredient.isComplete {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(ingredient.isCurrent ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(6)
    }
    
    private func exportResults() {
        let results = recipeManager.generateReport()
        
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = "recipe_results_\(Date().timeIntervalSince1970).pdf"
        savePanel.allowedContentTypes = [.pdf]
        
        if savePanel.runModal() == .OK {
            if let url = savePanel.url {
                results.write(to: url)
            }
        }
    }
}

@MainActor
class RecipeManager: ObservableObject {
    @Published var recipeInput = ""
    @Published var ingredients: [RecipeIngredient] = []
    @Published var parseError = ""
    @Published var currentIngredientIndex = 0
    
    var currentIngredient: RecipeIngredient? {
        guard currentIngredientIndex < ingredients.count else { return nil }
        return ingredients[currentIngredientIndex]
    }
    
    var isComplete: Bool {
        ingredients.allSatisfy { $0.isComplete }
    }
    
    func parseRecipe() {
        parseError = ""
        ingredients = []
        
        let lines = recipeInput.components(separatedBy: .newlines)
            .flatMap { $0.components(separatedBy: ",") }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        for line in lines {
            if let ingredient = parseIngredientLine(line) {
                ingredients.append(ingredient)
            } else {
                parseError = "Could not parse: \(line)"
                return
            }
        }
        
        if ingredients.isEmpty {
            parseError = "No valid ingredients found"
        } else {
            markCurrentIngredient()
        }
    }
    
    private func parseIngredientLine(_ line: String) -> RecipeIngredient? {
        // Parse formats like "200g flour", "1 cup sugar", "2 tbsp oil"
        let regex = try! NSRegularExpression(pattern: #"(\d+(?:\.\d+)?)\s*(g|gram|grams|cup|cups|tbsp|tsp|oz)\s+(.+)"#, options: .caseInsensitive)
        let range = NSRange(location: 0, length: line.utf16.count)
        
        guard let match = regex.firstMatch(in: line, options: [], range: range) else {
            return nil
        }
        
        let amountString = String(line[Range(match.range(at: 1), in: line)!])
        let unitString = String(line[Range(match.range(at: 2), in: line)!]).lowercased()
        let nameString = String(line[Range(match.range(at: 3), in: line)!])
        
        guard let amount = Float(amountString) else { return nil }
        
        // Convert to grams
        let weightInGrams: Float
        switch unitString {
        case "g", "gram", "grams":
            weightInGrams = amount
        case "cup", "cups":
            // Approximate conversion based on ingredient type
            if nameString.lowercased().contains("flour") {
                weightInGrams = amount * 120
            } else if nameString.lowercased().contains("sugar") {
                weightInGrams = amount * 200
            } else {
                weightInGrams = amount * 150 // Default
            }
        case "tbsp":
            weightInGrams = amount * 15
        case "tsp":
            weightInGrams = amount * 5
        case "oz":
            weightInGrams = amount * 28.35
        default:
            return nil
        }
        
        return RecipeIngredient(
            id: UUID(),
            name: nameString,
            targetWeight: weightInGrams,
            originalAmount: amount,
            originalUnit: unitString
        )
    }
    
    func updateWeight(_ weight: Float) {
        guard currentIngredientIndex < ingredients.count else { return }
        ingredients[currentIngredientIndex].currentWeight = weight
    }
    
    func checkAdvancement() {
        guard let current = currentIngredient else { return }
        
        // Check if current ingredient is complete (within 2% tolerance)
        let tolerance: Float = max(2.0, current.targetWeight * 0.02)
        let difference = abs(current.currentWeight - current.targetWeight)
        
        if difference <= tolerance && !current.isComplete {
            ingredients[currentIngredientIndex].isComplete = true
            
            // Haptic feedback for completion
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
            
            // Move to next ingredient
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.advanceToNextIngredient()
            }
        }
    }
    
    private func advanceToNextIngredient() {
        if currentIngredientIndex < ingredients.count - 1 {
            currentIngredientIndex += 1
            markCurrentIngredient()
        }
    }
    
    private func markCurrentIngredient() {
        for i in ingredients.indices {
            ingredients[i].isCurrent = (i == currentIngredientIndex)
            ingredients[i].isInProgress = (i == currentIngredientIndex)
        }
    }
    
    func reset() {
        recipeInput = ""
        ingredients = []
        parseError = ""
        currentIngredientIndex = 0
    }
    
    func generateReport() -> NSAttributedString {
        let report = NSMutableAttributedString()
        
        // Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 18),
            .foregroundColor: NSColor.labelColor
        ]
        report.append(NSAttributedString(string: "Recipe Results\n\n", attributes: titleAttributes))
        
        // Timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        let timestampAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        report.append(NSAttributedString(string: "Created: \(dateFormatter.string(from: Date()))\n\n", attributes: timestampAttributes))
        
        // Ingredients
        for ingredient in ingredients {
            let name = ingredient.name.capitalized
            let actual = String(format: "%.1f", ingredient.currentWeight)
            let target = String(format: "%.1f", ingredient.targetWeight)
            let difference = ingredient.currentWeight - ingredient.targetWeight
            let diffString = String(format: "%+.1f", difference)
            
            let ingredientText = "\(name): \(actual)g (target: \(target)g, diff: \(diffString)g)\n"
            
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 14),
                .foregroundColor: NSColor.labelColor
            ]
            
            report.append(NSAttributedString(string: ingredientText, attributes: textAttributes))
        }
        
        return report
    }
}

struct RecipeIngredient: Identifiable {
    let id: UUID
    let name: String
    let targetWeight: Float
    let originalAmount: Float
    let originalUnit: String
    
    var currentWeight: Float = 0.0
    var isComplete: Bool = false
    var isCurrent: Bool = false
    var isInProgress: Bool = false
    
    var progress: Double {
        Double(min(currentWeight / targetWeight, 1.0))
    }
    
    var progressColor: Color {
        if isComplete { return .green }
        if progress > 0.8 { return .orange }
        return .blue
    }
    
    var statusColor: Color {
        if isComplete { return .green }
        if isCurrent { return .blue }
        return .gray
    }
}

extension NSAttributedString {
    func write(to url: URL) {
        let printInfo = NSPrintInfo.shared
        printInfo.paperSize = NSSize(width: 612, height: 792) // Letter size
        printInfo.topMargin = 72
        printInfo.bottomMargin = 72
        printInfo.leftMargin = 72
        printInfo.rightMargin = 72
        
        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: printInfo.paperSize.width - printInfo.leftMargin - printInfo.rightMargin, height: printInfo.paperSize.height - printInfo.topMargin - printInfo.bottomMargin))
        textView.textStorage?.setAttributedString(self)
        
        let printOperation = NSPrintOperation(view: textView, printInfo: printInfo)
        printOperation.jobTitle = "Recipe Results"
        
        let pdfData = textView.dataWithPDF(inside: textView.bounds)
        try? pdfData.write(to: url)
    }
}

extension UTType {
    static var pdf: UTType {
        UTType.pdf
    }
} 