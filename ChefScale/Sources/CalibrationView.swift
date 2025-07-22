import SwiftUI
import OpenMultitouchSupport

struct CalibrationView: View {
    @ObservedObject var scaleManager: ScaleManager
    @Environment(\.dismiss) private var dismiss
    @State private var rawReadings: [OMSTouchData] = []
    @State private var offsetAdjustment: Float = 0.0
    @State private var isRecording = false
    @State private var calibrationLog: [CalibrationEntry] = []
    
    var body: some View {
        VStack(spacing: 20) {
            headerView
            
            rawDataView
            
            calibrationControlsView
            
            signalQualityView
            
            actionButtonsView
        }
        .padding()
        .frame(width: 500, height: 600)
        .onAppear {
            offsetAdjustment = scaleManager.calibrationOffset
            startRawDataCapture()
        }
        .onDisappear {
            stopRawDataCapture()
        }
    }
    
    private var headerView: some View {
        VStack {
            Text("Calibration Mode")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Press 'C' to access • Fine-tune for sub-gram accuracy")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var rawDataView: some View {
        GroupBox("Raw Sensor Data") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Active Touches:")
                    Spacer()
                    Text("\(rawReadings.count)")
                        .fontWeight(.semibold)
                }
                
                ForEach(Array(rawReadings.enumerated()), id: \.offset) { index, touch in
                    HStack {
                        Text("Touch \(index + 1):")
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Pressure: \(touch.pressure, specifier: "%.2f")g")
                            Text("Density: \(touch.density, specifier: "%.3f")")
                            Text("Total: \(touch.total, specifier: "%.2f")")
                        }
                        .font(.system(.caption, design: .monospaced))
                    }
                }
                
                if rawReadings.isEmpty {
                    Text("No touches detected")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 150)
        }
    }
    
    private var calibrationControlsView: some View {
        GroupBox("Calibration Adjustment") {
            VStack(spacing: 12) {
                HStack {
                    Text("Offset:")
                    Spacer()
                    Text("\(offsetAdjustment, specifier: "%.2f")g")
                        .font(.system(.body, design: .monospaced))
                }
                
                HStack {
                    Button("−1g") { adjustOffset(-1.0) }
                    Button("−0.1g") { adjustOffset(-0.1) }
                    
                    Spacer()
                    
                    Slider(value: $offsetAdjustment, in: -5.0...5.0, step: 0.01)
                        .frame(width: 200)
                    
                    Spacer()
                    
                    Button("+0.1g") { adjustOffset(0.1) }
                    Button("+1g") { adjustOffset(1.0) }
                }
                
                Button("Reset to Zero") {
                    offsetAdjustment = 0.0
                    applyCalibration()
                }
                .buttonStyle(.borderless)
            }
        }
    }
    
    private var signalQualityView: some View {
        GroupBox("Signal Quality") {
            VStack(spacing: 8) {
                HStack {
                    Text("Status:")
                    Spacer()
                    Text(signalQuality)
                        .foregroundColor(signalQualityColor)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Noise Level:")
                    Spacer()
                    Text(noiseLevel)
                        .font(.system(.body, design: .monospaced))
                }
                
                HStack {
                    Text("Current Reading:")
                    Spacer()
                    Text("\(scaleManager.currentWeight, specifier: "%.2f")g")
                        .font(.system(.body, design: .monospaced))
                }
            }
        }
    }
    
    private var actionButtonsView: some View {
        HStack(spacing: 16) {
            Button("Export Log") {
                exportCalibrationLog()
            }
            .disabled(calibrationLog.isEmpty)
            
            Button("Record Reading") {
                recordCalibrationPoint()
            }
            
            Spacer()
            
            Button("Cancel") {
                dismiss()
            }
            
            Button("Apply & Close") {
                applyCalibration()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var signalQuality: String {
        let variance = calculateVariance()
        if variance < 0.1 { return "Stable" }
        if variance < 0.5 { return "Good" }
        if variance < 1.0 { return "Fair" }
        return "Unstable"
    }
    
    private var signalQualityColor: Color {
        let variance = calculateVariance()
        if variance < 0.1 { return .green }
        if variance < 0.5 { return .blue }
        if variance < 1.0 { return .orange }
        return .red
    }
    
    private var noiseLevel: String {
        let variance = calculateVariance()
        return String(format: "±%.3f", variance)
    }
    
    private func adjustOffset(_ delta: Float) {
        offsetAdjustment = max(-5.0, min(5.0, offsetAdjustment + delta))
        applyCalibration()
    }
    
    private func applyCalibration() {
        scaleManager.calibrationOffset = offsetAdjustment
    }
    
    private func calculateVariance() -> Float {
        guard rawReadings.count > 1 else { return 0.0 }
        
        let pressures = rawReadings.map { $0.pressure }
        let mean = pressures.reduce(0, +) / Float(pressures.count)
        let variance = pressures.map { pow($0 - mean, 2) }.reduce(0, +) / Float(pressures.count)
        
        return sqrt(variance)
    }
    
    private func startRawDataCapture() {
        Task {
            for await touches in OMSManager.shared().touchDataStream {
                await MainActor.run {
                    self.rawReadings = touches.filter { $0.state != .notTouching }
                }
            }
        }
    }
    
    private func stopRawDataCapture() {
        // The async stream will automatically stop when the view disappears
    }
    
    private func recordCalibrationPoint() {
        let entry = CalibrationEntry(
            timestamp: Date(),
            rawPressure: rawReadings.reduce(0) { $0 + $1.pressure },
            adjustedPressure: scaleManager.currentWeight,
            offset: offsetAdjustment,
            touchCount: rawReadings.count,
            signalQuality: calculateVariance()
        )
        
        calibrationLog.append(entry)
    }
    
    private func exportCalibrationLog() {
        let csvContent = generateCSV()
        
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = "calibration_log_\(Date().timeIntervalSince1970).csv"
        savePanel.allowedContentTypes = [.commaSeparatedText]
        
        if savePanel.runModal() == .OK {
            if let url = savePanel.url {
                try? csvContent.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
    
    private func generateCSV() -> String {
        var csv = "Timestamp,Raw Pressure,Adjusted Pressure,Offset,Touch Count,Signal Quality\n"
        
        for entry in calibrationLog {
            csv += "\(entry.timestamp),\(entry.rawPressure),\(entry.adjustedPressure),\(entry.offset),\(entry.touchCount),\(entry.signalQuality)\n"
        }
        
        return csv
    }
}

struct CalibrationEntry {
    let timestamp: Date
    let rawPressure: Float
    let adjustedPressure: Float
    let offset: Float
    let touchCount: Int
    let signalQuality: Float
}

import UniformTypeIdentifiers

extension UTType {
    static var commaSeparatedText: UTType {
        UTType(filenameExtension: "csv")!
    }
} 