//
//  SettingsView.swift
//  DonkTool
//
//  Settings interface
//

import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var scanTimeout: Double = 5.0
    @State private var enableBannerGrabbing = true
    @State private var maxConcurrentScans = 50
    @State private var enableLogging = true
    @State private var autoUpdateCVE = true
    
    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Network Scanning") {
                    HStack {
                        Text("Scan Timeout:")
                        Spacer()
                        Text("\(Int(scanTimeout)) seconds")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $scanTimeout, in: 1...30, step: 1)
                    
                    Toggle("Enable Banner Grabbing", isOn: $enableBannerGrabbing)
                    
                    Stepper("Max Concurrent Scans: \(maxConcurrentScans)", 
                           value: $maxConcurrentScans, 
                           in: 1...200, 
                           step: 10)
                }
                
                Section("General") {
                    Toggle("Enable Logging", isOn: $enableLogging)
                    Toggle("Auto-Update CVE Database", isOn: $autoUpdateCVE)
                }
                
                Section("Security") {
                    Button("Clear All Data") {
                        clearAllData()
                    }
                    .foregroundColor(.red)
                }
            }
            .formStyle(.grouped)
        }
        .navigationTitle("Settings")
    }
    
    private func clearAllData() {
        appState.targets.removeAll()
        appState.allVulnerabilities.removeAll()
        appState.networkScanResults.removeAll()
        appState.webScanResults.removeAll()
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
}
