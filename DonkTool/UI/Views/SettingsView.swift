//
//  SettingsView.swift
//  DonkTool
//
//  Settings interface with unified design system
//

import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var scanTimeout: Double = 5.0
    @State private var enableBannerGrabbing = true
    @State private var maxConcurrentScans = 50
    @State private var enableLogging = true
    @State private var autoUpdateCVE = true
    @State private var showingClearConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: .spacing_md) {
                HStack {
                    Image(systemName: "gear")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Settings")
                            .font(.headerPrimary)
                        
                        Text("Configure application preferences")
                            .font(.captionPrimary)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            .standardContainer()
            
            Divider()
            
            ScrollView {
                VStack(spacing: .spacing_lg) {
                    // Network Scanning Section
                    networkScanningSection
                    
                    // General Section
                    generalSection
                    
                    // Security Section
                    securitySection
                }
                .padding(.spacing_md)
            }
        }
        .navigationTitle("Settings")
        .confirmationDialog("Clear All Data", isPresented: $showingClearConfirmation) {
            Button("Clear All Data", role: .destructive) {
                clearAllData()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all targets, vulnerabilities, and scan results. This action cannot be undone.")
        }
    }
    
    private var networkScanningSection: some View {
        VStack(alignment: .leading, spacing: .spacing_md) {
            Text("Network Scanning")
                .sectionHeader()
            
            VStack(spacing: .spacing_sm) {
                // Scan Timeout
                VStack(alignment: .leading, spacing: .spacing_xs) {
                    HStack {
                        Text("Scan Timeout")
                            .font(.bodySecondary)
                        
                        Spacer()
                        
                        Text("\(Int(scanTimeout)) seconds")
                            .font(.captionPrimary)
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $scanTimeout, in: 1...30, step: 1)
                        .tint(.blue)
                }
                
                Divider()
                
                // Banner Grabbing Toggle
                Toggle("Enable Banner Grabbing", isOn: $enableBannerGrabbing)
                    .font(.bodySecondary)
                
                Divider()
                
                // Max Concurrent Scans
                VStack(alignment: .leading, spacing: .spacing_xs) {
                    HStack {
                        Text("Max Concurrent Scans")
                            .font(.bodySecondary)
                        
                        Spacer()
                        
                        Text("\(maxConcurrentScans)")
                            .font(.captionPrimary)
                            .foregroundColor(.secondary)
                    }
                    
                    Stepper("", value: $maxConcurrentScans, in: 1...200, step: 10)
                        .labelsHidden()
                }
            }
            .cardStyle()
        }
    }
    
    private var generalSection: some View {
        VStack(alignment: .leading, spacing: .spacing_md) {
            Text("General")
                .sectionHeader()
            
            VStack(spacing: .spacing_sm) {
                Toggle("Enable Logging", isOn: $enableLogging)
                    .font(.bodySecondary)
                
                Divider()
                
                Toggle("Auto-Update CVE Database", isOn: $autoUpdateCVE)
                    .font(.bodySecondary)
            }
            .cardStyle()
        }
    }
    
    private var securitySection: some View {
        VStack(alignment: .leading, spacing: .spacing_md) {
            Text("Security")
                .sectionHeader()
            
            VStack(spacing: .spacing_sm) {
                Button("Clear All Data") {
                    showingClearConfirmation = true
                }
                .dangerButton()
                .frame(maxWidth: .infinity)
                
                Text("This will permanently delete all stored data including targets, scan results, and configurations.")
                    .font(.captionPrimary)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .cardStyle()
        }
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