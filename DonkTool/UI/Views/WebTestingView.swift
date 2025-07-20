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
    @State private var selectedTools: Set<String> = Set([
        "SQL Injection", "Web Vulnerability Scan", "Nuclei Template Scan", 
        "Directory Enumeration", "Advanced Directory Fuzzing", "XSS Detection",
        "OWASP ZAP Scan", "HTTP/HTTPS Analysis", "SSL/TLS Analysis",
        "HTTP Header Security", "Basic SSL Check"
    ])
    
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
                            .disabled(targetURL.isEmpty || selectedTools.isEmpty)
                            .primaryButton()
                        }
                    }
                }
                
                // Progress bar and tools info if scanning
                if appState.isWebScanning {
                    VStack(spacing: 12) {
                        ProgressView(value: appState.webScanProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                        
                        VStack(spacing: 4) {
                            Text("Running \(selectedTools.count) Selected Security Tools")
                                .font(.captionPrimary)
                                .foregroundColor(.secondary)
                            
                            if !appState.currentWebTestName.isEmpty {
                                Text("Current: \(appState.currentWebTestName)")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
                
                // Tools overview section when not scanning
                if !appState.isWebScanning {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Security Tools")
                                .font(.headerSecondary)
                            
                            Spacer()
                            
                            HStack(spacing: 8) {
                                Button("All") {
                                    selectedTools = Set([
                                        "SQL Injection", "Web Vulnerability Scan", "Nuclei Template Scan", 
                                        "Directory Enumeration", "Advanced Directory Fuzzing", "XSS Detection",
                                        "OWASP ZAP Scan", "HTTP/HTTPS Analysis", "SSL/TLS Analysis",
                                        "HTTP Header Security", "Basic SSL Check"
                                    ])
                                }
                                .buttonStyle(.link)
                                .font(.caption)
                                
                                Text("•")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                Button("None") {
                                    selectedTools.removeAll()
                                }
                                .buttonStyle(.link)
                                .font(.caption)
                                
                                Text("•")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                Text("\(selectedTools.count) of 11 selected")
                                    .font(.captionPrimary)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ClickableSecurityToolCard(
                                name: "SQLMap", 
                                description: "SQL injection detection", 
                                icon: "cylinder.split.1x2", 
                                toolKey: "SQL Injection",
                                isSelected: selectedTools.contains("SQL Injection")
                            ) {
                                toggleTool("SQL Injection")
                            }
                            
                            ClickableSecurityToolCard(
                                name: "Nikto", 
                                description: "Web vulnerability scanner", 
                                icon: "magnifyingglass.circle", 
                                toolKey: "Web Vulnerability Scan",
                                isSelected: selectedTools.contains("Web Vulnerability Scan")
                            ) {
                                toggleTool("Web Vulnerability Scan")
                            }
                            
                            ClickableSecurityToolCard(
                                name: "Nuclei", 
                                description: "9000+ vulnerability templates", 
                                icon: "bolt.circle", 
                                toolKey: "Nuclei Template Scan",
                                isSelected: selectedTools.contains("Nuclei Template Scan")
                            ) {
                                toggleTool("Nuclei Template Scan")
                            }
                            
                            ClickableSecurityToolCard(
                                name: "Gobuster", 
                                description: "Directory enumeration", 
                                icon: "folder.badge.questionmark", 
                                toolKey: "Directory Enumeration",
                                isSelected: selectedTools.contains("Directory Enumeration")
                            ) {
                                toggleTool("Directory Enumeration")
                            }
                            
                            ClickableSecurityToolCard(
                                name: "Feroxbuster", 
                                description: "Advanced directory fuzzing", 
                                icon: "folder.circle", 
                                toolKey: "Advanced Directory Fuzzing",
                                isSelected: selectedTools.contains("Advanced Directory Fuzzing")
                            ) {
                                toggleTool("Advanced Directory Fuzzing")
                            }
                            
                            ClickableSecurityToolCard(
                                name: "XSStrike", 
                                description: "Advanced XSS detection", 
                                icon: "exclamationmark.triangle", 
                                toolKey: "XSS Detection",
                                isSelected: selectedTools.contains("XSS Detection")
                            ) {
                                toggleTool("XSS Detection")
                            }
                            
                            ClickableSecurityToolCard(
                                name: "OWASP ZAP", 
                                description: "Comprehensive web scanner", 
                                icon: "shield.checkered", 
                                toolKey: "OWASP ZAP Scan",
                                isSelected: selectedTools.contains("OWASP ZAP Scan")
                            ) {
                                toggleTool("OWASP ZAP Scan")
                            }
                            
                            ClickableSecurityToolCard(
                                name: "HTTPx", 
                                description: "HTTP/HTTPS analysis", 
                                icon: "network", 
                                toolKey: "HTTP/HTTPS Analysis",
                                isSelected: selectedTools.contains("HTTP/HTTPS Analysis")
                            ) {
                                toggleTool("HTTP/HTTPS Analysis")
                            }
                            
                            ClickableSecurityToolCard(
                                name: "TestSSL.sh", 
                                description: "SSL/TLS deep analysis", 
                                icon: "lock.circle", 
                                toolKey: "SSL/TLS Analysis",
                                isSelected: selectedTools.contains("SSL/TLS Analysis")
                            ) {
                                toggleTool("SSL/TLS Analysis")
                            }
                            
                            ClickableSecurityToolCard(
                                name: "Headers", 
                                description: "HTTP security headers", 
                                icon: "doc.text.magnifyingglass", 
                                toolKey: "HTTP Header Security",
                                isSelected: selectedTools.contains("HTTP Header Security")
                            ) {
                                toggleTool("HTTP Header Security")
                            }
                            
                            ClickableSecurityToolCard(
                                name: "SSL Check", 
                                description: "Basic SSL verification", 
                                icon: "lock.shield", 
                                toolKey: "Basic SSL Check",
                                isSelected: selectedTools.contains("Basic SSL Check")
                            ) {
                                toggleTool("Basic SSL Check")
                            }
                        }
                    }
                    .padding(.horizontal)
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
        appState.startWebScan(targetURL: targetURL, selectedTools: Array(selectedTools))
        // Don't clear URL so user can see what's being scanned
    }
    
    private func toggleTool(_ toolKey: String) {
        if selectedTools.contains(toolKey) {
            selectedTools.remove(toolKey)
        } else {
            selectedTools.insert(toolKey)
        }
    }
}

struct WebScanResultRowView: View {
    let result: WebScanResult
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(result.type)
                    .font(.headerTertiary)
                
                Spacer()
                
                HStack(spacing: 8) {
                    if !result.details.isEmpty {
                        Text("\(result.details.count) details")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(result.severity.rawValue)
                        .statusIndicator(getSeverityStatus(result.severity))
                    
                    if !result.details.isEmpty {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded.toggle()
                            }
                        }) {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Text(result.description)
                .font(.bodyPrimary)
                .foregroundColor(.primary)
            
            HStack {
                Text(result.url)
                    .font(.captionPrimary)
                    .foregroundColor(.blue)
                    .lineLimit(1)
                
                Spacer()
                
                Text(result.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Detailed findings (expandable)
            if isExpanded && !result.details.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Detailed Findings:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    ForEach(Array(result.details.enumerated()), id: \.offset) { index, detail in
                        HStack(alignment: .top, spacing: 6) {
                            Text("\(index + 1).")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .frame(width: 20, alignment: .leading)
                            
                            Text(detail)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.top, 8)
                .padding(.leading, 12)
                .overlay(
                    Rectangle()
                        .frame(width: 2)
                        .foregroundColor(.blue.opacity(0.3)),
                    alignment: .leading
                )
            }
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

struct ClickableSecurityToolCard: View {
    let name: String
    let description: String
    let icon: String
    let toolKey: String
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.captionPrimary)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .foregroundColor(isSelected ? .primary : .secondary)
                    
                    Text(description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer(minLength: 0)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

#Preview {
    WebTestingView()
        .environment(AppState())
}
