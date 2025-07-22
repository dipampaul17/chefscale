import SwiftUI
import Foundation
import UniformTypeIdentifiers

// MARK: - Data Export Manager
@MainActor
class DataExportManager: ObservableObject {
    @Published var isExporting = false
    @Published var exportProgress: Float = 0.0
    @Published var lastExportURL: URL?
    
    enum ExportFormat {
        case pdf
        case csv
        case json
    }
    
    enum ExportType {
        case session
        case calibration
        case recipe
        case fullReport
    }
    
    func exportSession(_ session: MeasurementSession, format: ExportFormat = .pdf) {
        isExporting = true
        exportProgress = 0.0
        
        Task {
            do {
                let url = try await generateSessionExport(session, format: format)
                await MainActor.run {
                    self.lastExportURL = url
                    self.isExporting = false
                    self.exportProgress = 1.0
                }
            } catch {
                await MainActor.run {
                    self.isExporting = false
                    print("Export failed: \(error)")
                }
            }
        }
    }
    
    private func generateSessionExport(_ session: MeasurementSession, format: ExportFormat) async throws -> URL {
        switch format {
        case .pdf:
            return try await generatePDFReport(session)
        case .csv:
            return try generateCSVData(session)
        case .json:
            return try generateJSONData(session)
        }
    }
    
    private func generatePDFReport(_ session: MeasurementSession) async throws -> URL {
        await updateProgress(0.2)
        
        let report = createFormattedReport(session)
        
        await updateProgress(0.6)
        
        let url = getExportURL(filename: "chefscale_session_\(session.id).pdf", type: .pdf)
        
        await updateProgress(0.8)
        
        try await writePDFReport(report, to: url)
        
        await updateProgress(1.0)
        
        return url
    }
    
    private func createFormattedReport(_ session: MeasurementSession) -> NSAttributedString {
        let report = NSMutableAttributedString()
        
        // Header
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: NSColor.labelColor
        ]
        
        report.append(NSAttributedString(string: "ChefScale Pro - Measurement Session\n\n", attributes: headerAttributes))
        
        // Session metadata
        let metadataAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .medium
        
        let metadata = """
        Session ID: \(session.id)
        Date: \(dateFormatter.string(from: session.startTime))
        Duration: \(formatDuration(session.duration))
        Total Measurements: \(session.measurements.count)
        
        """
        
        report.append(NSAttributedString(string: metadata, attributes: metadataAttributes))
        
        // Measurements table
        let tableHeader = "Measurements:\n\n"
        let tableHeaderAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: NSColor.labelColor
        ]
        
        report.append(NSAttributedString(string: tableHeader, attributes: tableHeaderAttributes))
        
        // Table content
        let tableAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
            .foregroundColor: NSColor.labelColor
        ]
        
        let tableHeader2 = String(format: "%-20s %-10s %-15s %-20s\n", "Time", "Weight", "Ingredient", "Notes")
        report.append(NSAttributedString(string: tableHeader2, attributes: tableAttributes))
        
        let separator = String(repeating: "-", count: 70) + "\n"
        report.append(NSAttributedString(string: separator, attributes: tableAttributes))
        
        for measurement in session.measurements {
            let timeString = formatTime(measurement.timestamp)
            let weightString = String(format: "%.1fg", measurement.weight)
            let ingredientString = measurement.ingredient ?? "Unknown"
            let notesString = measurement.notes ?? ""
            
            let row = String(format: "%-20s %-10s %-15s %-20s\n", 
                           timeString, weightString, ingredientString, notesString)
            report.append(NSAttributedString(string: row, attributes: tableAttributes))
        }
        
        // Summary statistics
        let summaryHeader = "\n\nSummary Statistics:\n\n"
        report.append(NSAttributedString(string: summaryHeader, attributes: tableHeaderAttributes))
        
        let stats = calculateSessionStatistics(session)
        let summaryAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.labelColor
        ]
        
        let summary = """
        Total Weight Measured: \(String(format: "%.1f", stats.totalWeight))g
        Average Measurement: \(String(format: "%.1f", stats.averageWeight))g
        Largest Measurement: \(String(format: "%.1f", stats.maxWeight))g
        Smallest Measurement: \(String(format: "%.1f", stats.minWeight))g
        Accuracy Rating: \(stats.accuracyRating)
        
        Generated by ChefScale Pro • \(Date().formatted())
        """
        
        report.append(NSAttributedString(string: summary, attributes: summaryAttributes))
        
        return report
    }
    
    private func writePDFReport(_ report: NSAttributedString, to url: URL) async throws {
        let printInfo = NSPrintInfo.shared
        printInfo.paperSize = NSSize(width: 612, height: 792) // Letter size
        printInfo.topMargin = 50
        printInfo.bottomMargin = 50
        printInfo.leftMargin = 50
        printInfo.rightMargin = 50
        
        let textView = NSTextView(frame: NSRect(
            x: 0, y: 0,
            width: printInfo.paperSize.width - printInfo.leftMargin - printInfo.rightMargin,
            height: printInfo.paperSize.height - printInfo.topMargin - printInfo.bottomMargin
        ))
        
        textView.textStorage?.setAttributedString(report)
        
        let pdfData = textView.dataWithPDF(inside: textView.bounds)
        try pdfData.write(to: url)
    }
    
    private func generateCSVData(_ session: MeasurementSession) throws -> URL {
        var csv = "Timestamp,Weight(g),Ingredient,Notes,Accuracy\n"
        
        for measurement in session.measurements {
            let timestamp = ISO8601DateFormatter().string(from: measurement.timestamp)
            let weight = String(format: "%.2f", measurement.weight)
            let ingredient = (measurement.ingredient ?? "").replacingOccurrences(of: ",", with: ";")
            let notes = (measurement.notes ?? "").replacingOccurrences(of: ",", with: ";")
            let accuracy = String(format: "%.1f", measurement.accuracy)
            
            csv += "\(timestamp),\(weight),\(ingredient),\(notes),\(accuracy)\n"
        }
        
        let url = getExportURL(filename: "chefscale_session_\(session.id).csv", type: .csv)
        try csv.write(to: url, atomically: true, encoding: .utf8)
        
        return url
    }
    
    private func generateJSONData(_ session: MeasurementSession) throws -> URL {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try encoder.encode(session)
        
        let url = getExportURL(filename: "chefscale_session_\(session.id).json", type: .json)
        try data.write(to: url)
        
        return url
    }
    
    private func getExportURL(filename: String, type: UTType) -> URL {
        let documentsPath = FileManager.default.urls(for: .documentsDirectory, in: .userDomainMask)[0]
        let chefscaleFolder = documentsPath.appendingPathComponent("ChefScale Exports")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: chefscaleFolder, withIntermediateDirectories: true)
        
        return chefscaleFolder.appendingPathComponent(filename)
    }
    
    private func updateProgress(_ progress: Float) async {
        await MainActor.run {
            self.exportProgress = progress
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    private func calculateSessionStatistics(_ session: MeasurementSession) -> SessionStatistics {
        let weights = session.measurements.map { $0.weight }
        
        return SessionStatistics(
            totalWeight: weights.reduce(0, +),
            averageWeight: weights.isEmpty ? 0 : weights.reduce(0, +) / Float(weights.count),
            maxWeight: weights.max() ?? 0,
            minWeight: weights.min() ?? 0,
            accuracyRating: calculateAccuracyRating(session)
        )
    }
    
    private func calculateAccuracyRating(_ session: MeasurementSession) -> String {
        let accuracies = session.measurements.map { $0.accuracy }
        let averageAccuracy = accuracies.isEmpty ? 0 : accuracies.reduce(0, +) / Float(accuracies.count)
        
        switch averageAccuracy {
        case 0.9...1.0: return "Excellent"
        case 0.8..<0.9: return "Very Good"
        case 0.7..<0.8: return "Good"
        case 0.6..<0.7: return "Fair"
        default: return "Needs Calibration"
        }
    }
}

// MARK: - Data Models
struct MeasurementSession: Codable, Identifiable {
    let id: String
    let startTime: Date
    let duration: TimeInterval
    let measurements: [WeightMeasurement]
    let calibrationData: CalibrationSnapshot?
    
    init() {
        self.id = UUID().uuidString
        self.startTime = Date()
        self.duration = 0
        self.measurements = []
        self.calibrationData = nil
    }
}

struct WeightMeasurement: Codable, Identifiable {
    let id: String
    let timestamp: Date
    let weight: Float
    let unit: String
    let ingredient: String?
    let notes: String?
    let accuracy: Float
    let isStable: Bool
    
    init(weight: Float, unit: WeightUnit, ingredient: String? = nil) {
        self.id = UUID().uuidString
        self.timestamp = Date()
        self.weight = weight
        self.unit = unit.rawValue
        self.ingredient = ingredient
        self.notes = nil
        self.accuracy = 1.0
        self.isStable = true
    }
}

struct CalibrationSnapshot: Codable {
    let offset: Float
    let timestamp: Date
    let signalQuality: Float
    let noiseLevel: Float
    let temperature: Float?
}

struct SessionStatistics {
    let totalWeight: Float
    let averageWeight: Float
    let maxWeight: Float
    let minWeight: Float
    let accuracyRating: String
}

// MARK: - Recipe Card Generator
class RecipeCardGenerator {
    static func createRecipeCard(_ recipe: [RecipeIngredient], actualMeasurements: [Float]) -> NSAttributedString {
        let card = NSMutableAttributedString()
        
        // Recipe card header
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 20, weight: .bold),
            .foregroundColor: NSColor.labelColor
        ]
        
        card.append(NSAttributedString(string: "Recipe Card\n\n", attributes: titleAttributes))
        
        // Ingredients list
        for (index, ingredient) in recipe.enumerated() {
            let actual = index < actualMeasurements.count ? actualMeasurements[index] : 0
            let target = ingredient.targetWeight
            let difference = actual - target
            let percentOff = abs(difference) / target * 100
            
            let ingredientText = String(format: "%@ - Target: %.1fg, Actual: %.1fg", 
                                      ingredient.name.capitalized, target, actual)
            
            let ingredientAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 14),
                .foregroundColor: NSColor.labelColor
            ]
            
            card.append(NSAttributedString(string: ingredientText, attributes: ingredientAttributes))
            
            // Accuracy indicator
            if percentOff < 2 {
                let accuracyText = " ✓ Perfect\n"
                let accuracyAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 12),
                    .foregroundColor: NSColor.systemGreen
                ]
                card.append(NSAttributedString(string: accuracyText, attributes: accuracyAttributes))
            } else if percentOff < 5 {
                let accuracyText = " ○ Good\n"
                let accuracyAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 12),
                    .foregroundColor: NSColor.systemOrange
                ]
                card.append(NSAttributedString(string: accuracyText, attributes: accuracyAttributes))
            } else {
                let accuracyText = String(format: " △ %.1f%% off\n", percentOff)
                let accuracyAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 12),
                    .foregroundColor: NSColor.systemRed
                ]
                card.append(NSAttributedString(string: accuracyText, attributes: accuracyAttributes))
            }
        }
        
        // Footer
        let footerText = "\n\nMeasured with ChefScale Pro\n\(Date().formatted())"
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        
        card.append(NSAttributedString(string: footerText, attributes: footerAttributes))
        
        return card
    }
}

// MARK: - UTType Extensions
extension UTType {
    static var csv: UTType {
        UTType(filenameExtension: "csv")!
    }
    
    static var json: UTType {
        UTType(filenameExtension: "json")!
    }
} 