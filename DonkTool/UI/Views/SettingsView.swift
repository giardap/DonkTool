//
//  SettingsView.swift
//  DonkTool
//
//  Application settings and preferences
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("autoUpdateCVE") private var autoUpdateCVE = true
    @AppStorage("updateIntervalHours") private var updateIntervalHours = 24.0
    @AppStorage("maxConcurrentScans") private var maxConcurrentScans = 5.0
    @AppStorage("scanTimeout") private var scanTimeout = 30.0
    @AppStorage("enableLogging") private var enableLogging = true
    @AppStorage("logLevel") private var logLevel = "info"
    @AppStorage("dataRetentionDays") private var dataRetentionDays = 30.0
    @AppStorage("exportFormat") private var exportFormat = "pdf"
    
    private let logLevels = ["debug", "info", "warning", "error"]
    private let exportFormats = ["pdf", "html", "json", "csv"]
    
    var body: some View {
        Form {
            Section("CVE Database") {
                Toggle("Auto-update CVE Database", isOn: $autoUpdateCVE)
                
                VStack(alignment: .leading) {
                    Text("Update Interval: \(Int(updateIntervalHours)) hours")
                        .font(.caption)
                    Slider(value: $updateIntervalHours, in: 1...168, step: 1)
                }
                .disabled(!autoUpdateCVE)
            }
            
            Section("Scanning") {
                VStack(alignment: .leading) {
                    Text("Max Concurrent Scans: \(Int(maxConcurrentScans))")
                        .font(.caption)
                    Slider(value: $maxConcurrentScans, in: 1...20, step: 1)
                }
                
                VStack(alignment: .leading) {
                    Text("Scan Timeout: \(Int(scanTimeout)) seconds")
                        .font(.caption)
                    Slider(value: $scanTimeout, in: 5...300, step: 5)
                }
            }
            
            Section("Logging") {
                Toggle("Enable Logging", isOn: $enableLogging)
                
                Picker("Log Level", selection: $logLevel) {
                    ForEach(logLevels, id: \.self) { level in
                        Text(level.capitalized).tag(level)
                    }
                }
                .disabled(!enableLogging)
            }
            
            Section("Data Management") {
                VStack(alignment: .leading) {
                    Text("Data Retention: \(Int(dataRetentionDays)) days")
                        .font(.caption)
                    Slider(value: $dataRetentionDays, in: 1...365, step: 1)
                }
                
                HStack {
                    Button("Clear Scan History") {
                        clearScanHistory()
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("Export Data") {
                        exportAllData()
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            Section("Export Settings") {
                Picker("Default Export Format", selection: $exportFormat) {
                    ForEach(exportFormats, id: \.self) { format in
                        Text(format.uppercased()).tag(format)
                    }
                }
            }
            
            Section("About") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("DonkTool")
                            .font(.headline)
                        Spacer()
                        Text("v1.0.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("A native macOS penetration testing suite")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("⚠️ Legal Notice")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                        
                        Text("This tool is intended for authorized penetration testing only. Users must obtain proper authorization before testing any systems.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section("Advanced") {
                Button("Reset to Defaults") {
                    resetToDefaults()
                }
                .foregroundColor(.red)
                
                Button("Show Legal Disclaimer") {
                    showLegalDisclaimer()
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
    }
    
    private func clearScanHistory() {
        // Implementation to clear scan history
        print("Clearing scan history...")
    }
    
    private func exportAllData() {
        // Implementation to export all data
        print("Exporting all data...")
    }
    
    private func resetToDefaults() {
        autoUpdateCVE = true
        updateIntervalHours = 24.0
        maxConcurrentScans = 5.0
        scanTimeout = 30.0
        enableLogging = true
        logLevel = "info"
        dataRetentionDays = 30.0
        exportFormat = "pdf"
    }
    
    private func showLegalDisclaimer() {
        // Implementation to show legal disclaimer
        print("Showing legal disclaimer...")
    }
}

#Preview {
    SettingsView()
}
