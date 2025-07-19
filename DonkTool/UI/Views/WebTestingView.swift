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
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // Show scanning status if active
                    if appState.isWebScanning {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Scanning \(appState.currentWebTarget)...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Target URL input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target URL")
                        .font(.headline)
                    
                    HStack {
                        TextField("https://example.com", text: $targetURL)
                            .textFieldStyle(.roundedBorder)
                            .disabled(appState.isWebScanning)
                        
                        if appState.isWebScanning {
                            Button("Stop Scan") {
                                appState.stopWebScan()
                            }
                            .buttonStyle(.bordered)
                        } else {
                            Button(action: startWebScan) {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text("Start Scan")
                                }
                                .frame(minWidth: 120)
                            }
                            .disabled(targetURL.isEmpty)
                            .buttonStyle(.borderedProminent)
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
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Results section
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Scan Results")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if !appState.webScanResults.isEmpty {
                        Text("\(appState.webScanResults.count) findings")
                            .font(.caption)
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
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(result.severity.rawValue)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(result.severity.color.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
            
            Text(result.description)
                .font(.body)
                .foregroundColor(.primary)
            
            Text(result.url)
                .font(.caption)
                .foregroundColor(.blue)
                .lineLimit(1)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    WebTestingView()
        .environment(AppState())
}
