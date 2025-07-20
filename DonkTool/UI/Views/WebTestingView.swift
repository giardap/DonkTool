//
//  WebTestingView.swift
//  DonkTool
//
//  Web application testing interface
//

import SwiftUI

struct WebTestingView: View {
    @Environment(AppState.self) private var appState
    @State private var targetURL = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Configuration Panel
            VStack(spacing: 16) {
                HStack {
                    Text("Web Application Scanner")
                        .font(.headerPrimary)
                    
                    Spacer()
                    
                    // Show scanning status if active
                    if appState.isWebScanning {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Scanning \(appState.currentWebTarget)...")
                                .font(.captionPrimary)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Target URL input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target URL")
                        .font(.headerSecondary)
                    
                    HStack {
                        TextField("https://example.com", text: $targetURL)
                            .textFieldStyle(.roundedBorder)
                            .disabled(appState.isWebScanning)
                        
                        if appState.isWebScanning {
                            Button("Stop Scan") {
                                appState.stopWebScan()
                            }
                            .secondaryButton()
                        } else {
                            Button(action: startWebScan) {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text("Start Scan")
                                }
                                .frame(minWidth: 120)
                            }
                            .disabled(targetURL.isEmpty)
                            .primaryButton()
                        }
                    }
                }
                
                // Progress bar if scanning
                if appState.isWebScanning {
                    ProgressView(value: appState.webScanProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                }
            }
            .padding()
            .standardContainer()
            
            Divider()
            
            // Results section
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Scan Results")
                        .font(.headerSecondary)
                    
                    Spacer()
                    
                    if !appState.webScanResults.isEmpty {
                        Text("\(appState.webScanResults.count) findings")
                            .font(.captionPrimary)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                if appState.webScanResults.isEmpty && !appState.isWebScanning {
                    ContentUnavailableView(
                        "No Web Scan Results",
                        systemImage: "globe.slash",
                        description: Text("Enter a target URL and start scanning")
                    )
                } else {
                    List(appState.webScanResults) { result in
                        WebScanResultRowView(result: result)
                    }
                    .listStyle(.plain)
                }
            }
        }
    }
    
    private func startWebScan() {
        guard !targetURL.isEmpty else { return }
        appState.startWebScan(targetURL: targetURL)
        targetURL = ""
    }
}

struct WebScanResultRowView: View {
    let result: WebScanResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(result.type)
                    .font(.headerTertiary)
                
                Spacer()
                
                Text(result.severity.rawValue)
                    .statusIndicator(getSeverityStatus(result.severity))
            }
            
            Text(result.description)
                .font(.bodyPrimary)
                .foregroundColor(.primary)
            
            Text(result.url)
                .font(.captionPrimary)
                .foregroundColor(.blue)
                .lineLimit(1)
        }
        .padding(.vertical, 8)
    }
    
    private func getSeverityStatus(_ severity: WebScanResult.Severity) -> StatusIndicator.StatusType {
        switch severity {
        case .high: return .danger
        case .medium: return .warning
        case .low: return .success
        case .informational: return .info
        }
    }
}

#Preview {
    WebTestingView()
        .environment(AppState())
}
