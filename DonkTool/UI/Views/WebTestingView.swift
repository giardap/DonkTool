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
    @State private var integrationListenerActive = false
    
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
                            
                            if !appState.toolExecutionStatus.isEmpty {
                                Text(appState.toolExecutionStatus)
                                    .font(.caption2)
                                    .foregroundColor(.green)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        // Real-time verbose console output
                        if appState.isVerboseMode && !appState.currentToolOutput.isEmpty {
                            VerboseConsoleView(output: appState.currentToolOutput)
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
                                // Verbose mode toggle
                                Toggle("Verbose", isOn: Bindable(appState).isVerboseMode)
                                    .toggleStyle(.checkbox)
                                    .font(.caption)
                                
                                Text("•")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
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
        .onAppear {
            setupIntegrationListeners()
        }
        .onDisappear {
            removeIntegrationListeners()
        }
    }
    
    // MARK: - Integration Engine Hooks
    
    private func setupIntegrationListeners() {
        guard !integrationListenerActive else { return }
        integrationListenerActive = true
        
        // Listen for auto-triggered web testing from network scanner
        NotificationCenter.default.addObserver(
            forName: .triggerWebTesting,
            object: nil,
            queue: .main
        ) { notification in
            if let url = notification.object as? String {
                self.targetURL = url
                
                // Auto-start web testing with default tools
                let defaultTools = ["Web Vulnerability Scan", "Directory Enumeration", "XSS Detection"]
                self.selectedTools = Set(defaultTools)
                
                print("🔗 Integration: Auto-triggered web testing for \(url)")
                self.startWebScan()
            }
        }
    }
    
    private func removeIntegrationListeners() {
        integrationListenerActive = false
        NotificationCenter.default.removeObserver(self, name: .triggerWebTesting, object: nil)
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
    @State private var selectedTab = 0 // 0: Findings, 1: Full Output
    
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
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(getSeverityColor(result.severity).opacity(0.2))
                        .foregroundColor(getSeverityColor(result.severity))
                        .cornerRadius(4)
                    
                    if !result.details.isEmpty || !result.fullOutput.isEmpty {
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
            
            // Expandable detailed content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    // Tab selector
                    HStack(spacing: 16) {
                        Button(action: { selectedTab = 0 }) {
                            HStack(spacing: 4) {
                                Image(systemName: "list.bullet")
                                Text("Findings")
                                if !result.details.isEmpty {
                                    Text("(\(result.details.count))")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(selectedTab == 0 ? Color.blue.opacity(0.2) : Color.clear)
                            .foregroundColor(selectedTab == 0 ? .blue : .secondary)
                            .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: { selectedTab = 1 }) {
                            HStack(spacing: 4) {
                                Image(systemName: "terminal")
                                Text("Console Output")
                                if !result.fullOutput.isEmpty {
                                    Text("(\(result.fullOutput.count) lines)")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(selectedTab == 1 ? Color.blue.opacity(0.2) : Color.clear)
                            .foregroundColor(selectedTab == 1 ? .blue : .secondary)
                            .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                    }
                    
                    // Tab content
                    Group {
                        switch selectedTab {
                        case 0:
                            // Detailed findings
                            if !result.details.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
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
                                                .textSelection(.enabled)
                                        }
                                    }
                                }
                            } else {
                                Text("No detailed findings available")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                            
                        case 1:
                            // Full console output
                            if !result.fullOutput.isEmpty {
                                ScrollView {
                                    LazyVStack(alignment: .leading, spacing: 2) {
                                        ForEach(Array(result.fullOutput.enumerated()), id: \.offset) { index, line in
                                            HStack(alignment: .top, spacing: 8) {
                                                Text("\(index + 1)")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                    .frame(width: 30, alignment: .trailing)
                                                    .fontDesign(.monospaced)
                                                
                                                Text(line)
                                                    .font(.caption)
                                                    .fontDesign(.monospaced)
                                                    .foregroundColor(.primary)
                                                    .fixedSize(horizontal: false, vertical: true)
                                                    .textSelection(.enabled)
                                                
                                                Spacer()
                                            }
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 1)
                                            .background(index % 2 == 0 ? Color.clear : Color.gray.opacity(0.05))
                                        }
                                    }
                                }
                                .frame(maxHeight: 300)
                                .background(Color.black.opacity(0.02))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            } else {
                                Text("No console output available")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                            
                        default:
                            EmptyView()
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
        case .critical: return .danger
        case .high: return .danger
        case .medium: return .warning
        case .low: return .success
        case .informational: return .info
        }
    }
    
    private func getSeverityColor(_ severity: WebScanResult.Severity) -> Color {
        switch severity {
        case .critical: return .red
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        case .informational: return .blue
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

struct VerboseConsoleView: View {
    let output: [String]
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            consoleHeader
            
            if isExpanded {
                consoleContent
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var consoleHeader: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                isExpanded.toggle()
            }
        }) {
            HStack {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Live Tool Output")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(output.count) lines")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var consoleContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(output.enumerated()), id: \.offset) { index, line in
                        ConsoleLineView(index: index, line: line)
                    }
                }
            }
            .frame(maxHeight: 200)
            .background(Color.black.opacity(0.05))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .onChange(of: output.count) { _, newCount in
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo(newCount - 1, anchor: .bottom)
                }
            }
        }
    }
}

struct ConsoleLineView: View {
    let index: Int
    let line: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(index + 1)")
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .trailing)
                .fontDesign(.monospaced)
            
            Text(line)
                .font(.caption)
                .fontDesign(.monospaced)
                .foregroundColor(getLineColor(line))
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 1)
        .background(index % 2 == 0 ? Color.clear : Color.gray.opacity(0.05))
        .id(index)
    }
    
    private func getLineColor(_ line: String) -> Color {
        let lowerLine = line.lowercased()
        
        if lowerLine.contains("❌") || lowerLine.contains("error") || lowerLine.contains("failed") {
            return .red
        } else if lowerLine.contains("⚠️") || lowerLine.contains("warning") || lowerLine.contains("timeout") {
            return .orange
        } else if lowerLine.contains("✅") || lowerLine.contains("completed") || lowerLine.contains("success") {
            return .green
        } else if lowerLine.contains("🚨") || lowerLine.contains("vulnerability") || lowerLine.contains("found") {
            return .red
        } else if lowerLine.contains("🔧") || lowerLine.contains("🚀") || lowerLine.contains("command") {
            return .blue
        } else if lowerLine.contains("📍") || lowerLine.contains("target") {
            return .purple
        } else {
            return .primary
        }
    }
}

#Preview {
    WebTestingView()
        .environment(AppState())
}
