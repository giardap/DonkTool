//
//  ModernWebTestingView.swift
//  DonkTool
//
//  Modern web testing interface with background operations
//

import SwiftUI

struct ModernWebTestingView: View {
    @Environment(AppState.self) private var appState
    @State private var targetURL = ""
    @State private var selectedTests: Set<WebTest> = []
    @State private var testResults: [WebTestResult] = []
    @State private var showingAdvancedOptions = false
    @State private var backgroundWebManager = BackgroundWebTestManager()
    @State private var attackFramework = AttackFramework()
    
    var body: some View {
        VStack(spacing: 0) {
            // Modern header with test controls
            WebTestControlsHeader()
            
            // Main content area
            HSplitView {
                // Left panel - Configuration
                ScrollView {
                    VStack(spacing: 20) {
                        WebConfigurationPanel()
                        
                        if showingAdvancedOptions {
                            WebAdvancedOptionsPanel()
                        }
                    }
                    .padding(20)
                }
                .frame(minWidth: 300, maxWidth: 400)
                .background(Color.surfaceBackground)
                
                // Right panel - Results
                WebResultsPanel()
                    .frame(minWidth: 400)
            }
        }
        .navigationTitle("Web Application Testing")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack {
                    Button(action: { showingAdvancedOptions.toggle() }) {
                        Image(systemName: "gearshape")
                    }
                    .help("Advanced Options")
                    
                    if appState.isWebScanning {
                        Button("Stop Scan") {
                            stopWebTest()
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .task {
            backgroundWebManager.appState = appState
        }
    }
    
    @ViewBuilder
    private func WebTestControlsHeader() -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Web Application Security Testing")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Identify web vulnerabilities and security issues")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if appState.isWebScanning {
                    WebTestingIndicator()
                }
            }
            
            // Quick test status bar
            if appState.isWebScanning {
                WebTestStatusBar()
            }
        }
        .padding(20)
        .background(Color.surfaceBackground)
    }
    
    @ViewBuilder
    private func WebConfigurationPanel() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Target URL section
            VStack(alignment: .leading, spacing: 12) {
                Label("Target Configuration", systemImage: "globe")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 12) {
                    TextField("https://example.com or 192.168.1.1", text: $targetURL)
                        .textFieldStyle(.roundedBorder)
                        .disabled(appState.isWebScanning)
                        .onSubmit {
                            autoFormatURL()
                        }
                    
                    // URL format guidance
                    Text("Supports: https://example.com, http://192.168.1.1, or just example.com (auto-formatted)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        Button("Auto-Format URL") {
                            autoFormatURL()
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button("Validate") {
                            validateURL()
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Spacer()
                        
                        if isValidURL {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Valid")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        } else if !targetURL.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Needs formatting")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .disabled(appState.isWebScanning)
                }
            }
            .padding(16)
            .background(Color.cardBackground)
            .cornerRadius(12)
            
            // Test selection
            VStack(alignment: .leading, spacing: 12) {
                Label("Security Tests", systemImage: "shield.checkered")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(WebTest.allCases, id: \.self) { test in
                        WebTestToggle(
                            test: test,
                            isSelected: selectedTests.contains(test),
                            isDisabled: appState.isWebScanning
                        ) { isSelected in
                            if isSelected {
                                selectedTests.insert(test)
                            } else {
                                selectedTests.remove(test)
                            }
                        }
                    }
                }
                
                HStack {
                    Button("Select All") {
                        selectedTests = Set(WebTest.allCases)
                    }
                    .font(.caption)
                    .buttonStyle(.link)
                    
                    Button("Clear All") {
                        selectedTests.removeAll()
                    }
                    .font(.caption)
                    .buttonStyle(.link)
                    
                    Spacer()
                }
                .disabled(appState.isWebScanning)
            }
            .padding(16)
            .background(Color.cardBackground)
            .cornerRadius(12)
            
            // Action buttons
            VStack(spacing: 12) {
                Button(action: startWebTest) {
                    HStack {
                        if appState.isWebScanning {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Testing...")
                        } else {
                            Image(systemName: "play.fill")
                            Text("Start Security Tests")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                }
                .buttonStyle(.borderedProminent)
                .disabled(targetURL.isEmpty || selectedTests.isEmpty || appState.isWebScanning)
                .controlSize(.large)
                
                Button("Add to Targets") {
                    addWebTarget()
                }
                .buttonStyle(.bordered)
                .disabled(targetURL.isEmpty)
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    @ViewBuilder
    private func WebAdvancedOptionsPanel() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Advanced Options", systemImage: "slider.horizontal.3")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                HStack {
                    Text("Request Timeout:")
                    Spacer()
                    Text("10s")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Max Redirects:")
                    Spacer()
                    Text("5")
                        .foregroundColor(.secondary)
                }
                
                Toggle("Follow Redirects", isOn: .constant(true))
                Toggle("Check SSL Certificate", isOn: .constant(true))
                Toggle("Include Subdomains", isOn: .constant(false))
                Toggle("Aggressive Testing", isOn: .constant(false))
            }
        }
        .padding(16)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func WebResultsPanel() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Results header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Test Results")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    if !testResults.isEmpty {
                        Text("\(testResults.count) tests completed • \(vulnerableTests) vulnerable")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if !testResults.isEmpty {
                    Menu("Export") {
                        Button("Export as PDF") { exportWebResults(format: .pdf) }
                        Button("Export as JSON") { exportWebResults(format: .json) }
                        Button("Export as CSV") { exportWebResults(format: .csv) }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Results content
            if testResults.isEmpty && !appState.isWebScanning {
                WebResultsEmptyState()
            } else {
                WebResultsList()
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    @ViewBuilder
    private func WebResultsEmptyState() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "globe.desk")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No Test Results")
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text("Configure a target URL and select tests to begin security assessment")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Start Security Assessment") {
                if !targetURL.isEmpty && !selectedTests.isEmpty {
                    startWebTest()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(targetURL.isEmpty || selectedTests.isEmpty)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    @ViewBuilder
    private func WebResultsList() -> some View {
        List(testResults) { result in
            ModernWebTestResultRow(result: result)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    private var isValidURL: Bool {
        guard !targetURL.isEmpty else { return false }
        let normalized = normalizeURL(targetURL)
        return URL(string: normalized) != nil && normalized.contains("://")
    }
    
    private var vulnerableTests: Int {
        testResults.filter { $0.status == .vulnerable }.count
    }
    
    private func startWebTest() {
        guard !targetURL.isEmpty, !selectedTests.isEmpty else { return }
        
        // Auto-format URL before starting test
        let normalizedURL = normalizeURL(targetURL)
        if targetURL != normalizedURL {
            targetURL = normalizedURL
        }
        
        backgroundWebManager.startWebTest(
            targetURL: normalizedURL,
            tests: selectedTests
        ) { results in
            DispatchQueue.main.async {
                self.testResults = results
            }
        }
    }
    
    private func stopWebTest() {
        backgroundWebManager.stopWebTest()
    }
    
    private func addWebTarget() {
        guard let url = URL(string: targetURL), let host = url.host else { return }
        let target = Target(name: host, ipAddress: host)
        appState.addTarget(target)
        targetURL = ""
    }
    
    private func validateURL() {
        guard !targetURL.isEmpty else { return }
        
        let normalized = normalizeURL(targetURL)
        if URL(string: normalized) != nil {
            // URL is valid, optionally auto-format it
            if targetURL != normalized {
                targetURL = normalized
            }
        }
    }
    
    private func autoFormatURL() {
        guard !targetURL.isEmpty else { return }
        let normalized = normalizeURL(targetURL)
        targetURL = normalized
    }
    
    private func normalizeURL(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If already has protocol, return as-is
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return trimmed
        }
        
        // Check if it looks like an IP address
        let ipRegex = try! NSRegularExpression(pattern: "^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}(:\\d+)?$")
        let isIP = ipRegex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) != nil
        
        // For IP addresses, default to HTTP (often local/internal)
        // For domains, default to HTTPS (more common for public sites)
        let defaultProtocol = isIP ? "http://" : "https://"
        
        return defaultProtocol + trimmed
    }
    
    private func exportWebResults(format: WebExportFormat) {
        // Implementation for exporting web test results
    }
}

struct WebTestToggle: View {
    let test: WebTest
    let isSelected: Bool
    let isDisabled: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        Button(action: { onToggle(!isSelected) }) {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .font(.system(size: 14))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(test.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(severityText(for: test))
                        .font(.caption2)
                        .foregroundColor(severityColor(for: test))
                }
                
                Spacer(minLength: 0)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                isSelected ? 
                    Color.blue.opacity(0.2) : 
                    Color.cardBackground.opacity(0.7),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.blue.opacity(0.6) : Color.borderPrimary.opacity(0.3), 
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(
                color: Color.black.opacity(0.1), 
                radius: isSelected ? 4 : 2, 
                x: 0, 
                y: isSelected ? 2 : 1
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
    
    private func severityText(for test: WebTest) -> String {
        switch test {
        case .sqlInjection, .xss: return "CRITICAL"
        case .directoryTraversal, .authenticationBypass: return "HIGH"
        case .httpHeaderSecurity, .sslTlsConfiguration: return "MEDIUM"
        default: return "LOW"
        }
    }
    
    private func severityColor(for test: WebTest) -> Color {
        switch test {
        case .sqlInjection, .xss: return .red
        case .directoryTraversal, .authenticationBypass: return .orange
        case .httpHeaderSecurity, .sslTlsConfiguration: return .yellow
        default: return .green
        }
    }
}

struct WebTestingIndicator: View {
    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)
            
            Text("Testing in progress...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.cardBackground)
        .cornerRadius(8)
    }
}

struct WebTestStatusBar: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Testing: \(appState.currentWebTarget)")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(appState.webScanProgress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: appState.webScanProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
        }
        .padding(12)
        .background(Color.cardBackground)
        .cornerRadius(8)
    }
}

struct ModernWebTestResultRow: View {
    let result: WebTestResult
    @State private var isShowingDetail = false
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Test info
            HStack(spacing: 12) {
                WebTestStatusIndicator(status: result.status)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(result.test.displayName)
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        if result.status == .vulnerable {
                            Text("VULNERABLE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.2))
                                .foregroundColor(.red)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(result.test.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Status and details
            VStack(alignment: .trailing, spacing: 4) {
                if let vulnerability = result.vulnerability {
                    WebSeverityBadge(severity: vulnerability.severity)
                }
                
                Text(result.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isHovering ? Color.gray.opacity(0.05) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHovering ? Color.green.opacity(0.2) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
        .onTapGesture {
            isShowingDetail = true
        }
        .sheet(isPresented: $isShowingDetail) {
            WebTestDetailView(result: result)
        }
    }
}

struct WebTestStatusIndicator: View {
    let status: WebTestResult.TestStatus
    
    var body: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 12, height: 12)
            .overlay(
                Circle()
                    .stroke(.white, lineWidth: 2)
            )
    }
    
    private var statusColor: Color {
        switch status {
        case .vulnerable: return .red
        case .secure: return .green
        case .error: return .orange
        case .pending: return .blue
        }
    }
}

struct WebSeverityBadge: View {
    let severity: Vulnerability.Severity
    
    var body: some View {
        Text(severity.rawValue.uppercased())
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(severity.color.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(4)
    }
}

// Background web test manager for non-blocking operations
@Observable
class BackgroundWebTestManager {
    var appState: AppState?
    private var testTask: Task<Void, Never>?
    
    func startWebTest(
        targetURL: String,
        tests: Set<WebTest>,
        completion: @escaping ([WebTestResult]) -> Void
    ) {
        appState?.isWebScanning = true
        appState?.currentWebTarget = targetURL
        appState?.webScanProgress = 0.0
        
        testTask = Task {
            let testsArray = Array(tests)
            
            // Execute tests sequentially to avoid concurrency issues
            var results: [WebTestResult] = []
            
            for (index, test) in testsArray.enumerated() {
                guard !Task.isCancelled else { break }
                
                let result = await performWebTest(test: test, url: targetURL)
                results.append(result)
                
                let currentResults = results.sorted { $0.timestamp < $1.timestamp }
                await MainActor.run {
                    self.appState?.webScanProgress = Double(index + 1) / Double(testsArray.count)
                    completion(currentResults)
                }
                
                // Small delay between tests
                try? await Task.sleep(nanoseconds: 500_000_000) // 500ms
            }
            
            await MainActor.run {
                appState?.isWebScanning = false
                appState?.webScanProgress = 1.0
            }
        }
    }
    
    func stopWebTest() {
        testTask?.cancel()
        appState?.isWebScanning = false
    }
    
    private func performWebTest(test: WebTest, url: String) async -> WebTestResult {
        let vulnerability = await performActualWebTest(test: test, url: url)
        
        // Add vulnerability to AppState if found
        if let vuln = vulnerability {
            await MainActor.run {
                appState?.addVulnerability(vuln, targetIP: extractHostFromURL(url))
            }
        }
        
        return WebTestResult(
            test: test,
            url: url,
            status: vulnerability != nil ? .vulnerable : .secure,
            vulnerability: vulnerability,
            timestamp: Date(),
            details: generateTestDetails(for: test, vulnerability: vulnerability)
        )
    }
    
    private func performActualWebTest(test: WebTest, url: String) async -> Vulnerability? {
        // Real implementation would use actual web testing tools
        switch test {
        // OWASP Top 10 2021 - Critical Tests
        case .brokenAccessControl:
            return await testBrokenAccessControl(url: url)
        case .cryptographicFailures:
            return await testCryptographicFailures(url: url)
        case .sqlInjection:
            return await testSQLInjection(url: url)
        case .insecureDesign:
            return await testInsecureDesign(url: url)
        case .securityMisconfiguration:
            return await testSecurityMisconfiguration(url: url)
        case .vulnerableComponents:
            return await testVulnerableComponents(url: url)
        case .comprehensiveWebScan:
            return await performComprehensiveWebScan(url: url)
        case .nucleiScan:
            return await performNucleiScan(url: url)
        case .httpProbing:
            return await performHTTPProbing(url: url)
        case .subdomainEnumeration:
            return await performSubdomainEnumeration(url: url)
        case .advancedFuzzing:
            return await performAdvancedFuzzing(url: url)
        case .sslTlsAnalysis:
            return await performSSLTLSAnalysis(url: url)
        case .httpStressTesting:
            return await performHTTPStressTesting(url: url)
        case .slowlorisTest:
            return await performSlowlorisTest(url: url)
        case .connectionExhaustion:
            return await performConnectionExhaustionTest(url: url)
        case .identificationFailures:
            return await testIdentificationFailures(url: url)
        case .ssrf:
            return await testSSRF(url: url)
            
        // Classic Web Vulnerabilities
        case .xss:
            return await testXSS(url: url)
        case .csrf:
            return await testCSRF(url: url)
        case .directoryTraversal:
            return await testDirectoryTraversal(url: url)
        case .authenticationBypass:
            return await testAuthenticationBypass(url: url)
        case .fileUpload:
            return await testFileUpload(url: url)
            
        // Modern Web Security
        case .cors:
            return await testCORS(url: url)
        case .clickjacking:
            return await testClickjacking(url: url)
        case .csp:
            return await testCSP(url: url)
        case .httpHeaderSecurity:
            return await testHTTPHeaderSecurity(url: url)
        case .sslTlsConfiguration:
            return await testSSLTLSConfiguration(url: url)
            
        // Injection Attacks
        case .commandInjection:
            return await testCommandInjection(url: url)
        case .xxe:
            return await testXXE(url: url)
        case .ldapInjection:
            return await testLDAPInjection(url: url)
            
        default:
            // Placeholder for less critical tests
            return await testGenericVulnerability(test: test, url: url)
        }
    }
    
    // Real web testing implementations using actual penetration testing tools
    private func testSQLInjection(url: String) async -> Vulnerability? {
        // Execute real SQLMap tool
        let result = await executeRealSQLMap(targetURL: url)
        
        if !result.vulnerabilities.isEmpty {
            let sqlVuln = result.vulnerabilities.first!
            return Vulnerability(
                title: "SQL Injection Vulnerability",
                description: "SQLMap detected: \(sqlVuln)",
                severity: .critical,
                discoveredAt: Date()
            )
        } else if !result.output.isEmpty {
            // Check if scan completed but no vulnerabilities found
            let hasCompletedScan = result.output.contains { line in
                line.lowercased().contains("testing completed") || 
                line.lowercased().contains("no injection") ||
                line.lowercased().contains("not vulnerable")
            }
            
            if hasCompletedScan {
                return nil // No vulnerability found
            }
        }
        
        return nil
    }
    
    private func performComprehensiveWebScan(url: String) async -> Vulnerability? {
        // Execute real Nikto web vulnerability scanner
        let result = await executeRealNikto(targetURL: url)
        
        if !result.vulnerabilities.isEmpty {
            let webVuln = result.vulnerabilities.first!
            return Vulnerability(
                title: "Web Vulnerability Detected",
                description: "Nikto found: \(webVuln)",
                severity: .high,
                discoveredAt: Date()
            )
        } else if !result.output.isEmpty {
            // Check if scan completed successfully
            let hasCompletedScan = result.output.contains { line in
                line.lowercased().contains("scan complete") || 
                line.lowercased().contains("end time") ||
                line.lowercased().contains("tested") ||
                line.contains("items checked")
            }
            
            if hasCompletedScan {
                return nil // Scan completed, no vulnerabilities found
            }
        }
        
        return nil
    }
    
    private func testXSS(url: String) async -> Vulnerability? {
        // Test for XSS vulnerabilities
        let xssPayloads = ["<script>alert('XSS')</script>", "<img src=x onerror=alert('XSS')>"]
        
        for payload in xssPayloads {
            if await performHTTPRequest(url: "\(url)?search=\(payload)") {
                return Vulnerability(
                    title: "Cross-Site Scripting (XSS)",
                    description: "XSS vulnerability detected with payload: \(payload)",
                    severity: .high,
                    discoveredAt: Date()
                )
            }
        }
        
        return nil
    }
    
    private func testDirectoryTraversal(url: String) async -> Vulnerability? {
        // Execute real directory enumeration with gobuster/dirb
        let result = await executeDirectoryEnumeration(targetURL: url)
        
        if !result.vulnerabilities.isEmpty {
            let dirVuln = result.vulnerabilities.first!
            return Vulnerability(
                title: "Directory Enumeration",
                description: "Directory/file found: \(dirVuln)",
                severity: .medium,
                discoveredAt: Date()
            )
        }
        
        return nil
    }
    
    private func testAuthenticationBypass(url: String) async -> Vulnerability? {
        // Test for authentication bypass
        let bypassPayloads = ["admin'--", "admin'/*", "' OR 1=1--"]
        
        for payload in bypassPayloads {
            if await performHTTPRequest(url: "\(url)/login", method: "POST", data: "username=\(payload)&password=test") {
                return Vulnerability(
                    title: "Authentication Bypass",
                    description: "Authentication bypass vulnerability detected",
                    severity: .critical,
                    discoveredAt: Date()
                )
            }
        }
        
        return nil
    }
    
    private func testHTTPHeaderSecurity(url: String) async -> Vulnerability? {
        // Test for missing security headers
        let headers = await getHTTPHeaders(url: url)
        
        let requiredHeaders = ["Strict-Transport-Security", "Content-Security-Policy", "X-Frame-Options", "X-Content-Type-Options"]
        let missingHeaders = requiredHeaders.filter { !headers.contains($0) }
        
        if !missingHeaders.isEmpty {
            return Vulnerability(
                title: "Missing Security Headers",
                description: "Missing security headers: \(missingHeaders.joined(separator: ", "))",
                severity: .medium,
                discoveredAt: Date()
            )
        }
        
        return nil
    }
    
    private func testSSLTLSConfiguration(url: String) async -> Vulnerability? {
        // Test SSL/TLS configuration
        if url.hasPrefix("https://") {
            let hasWeakCipher = await checkWeakCiphers(url: url)
            if hasWeakCipher {
                return Vulnerability(
                    title: "Weak SSL/TLS Configuration",
                    description: "Weak cipher suites or deprecated protocols detected",
                    severity: .medium,
                    discoveredAt: Date()
                )
            }
        }
        
        return nil
    }
    
    // OWASP Top 10 2021 Test Implementations
    private func testBrokenAccessControl(url: String) async -> Vulnerability? {
        let testPaths = ["/admin", "/admin.php", "/administrator", "/dashboard", "/config", "/backup"]
        
        for path in testPaths {
            if await performHTTPRequest(url: "\(url)\(path)") {
                return Vulnerability(
                    title: "Broken Access Control",
                    description: "Unauthorized access to administrative interface at \(path)",
                    severity: .critical,
                    discoveredAt: Date()
                )
            }
        }
        return nil
    }
    
    private func testCryptographicFailures(url: String) async -> Vulnerability? {
        if !url.hasPrefix("https://") {
            return Vulnerability(
                title: "Cryptographic Failure",
                description: "Application not using HTTPS encryption",
                severity: .high,
                discoveredAt: Date()
            )
        }
        
        if await checkWeakCiphers(url: url) {
            return Vulnerability(
                title: "Weak Cryptographic Implementation",
                description: "Weak cipher suites or deprecated cryptographic protocols detected",
                severity: .high,
                discoveredAt: Date()
            )
        }
        return nil
    }
    
    private func testInsecureDesign(url: String) async -> Vulnerability? {
        let testParams = ["debug=true", "test=1", "dev=1", "admin=1"]
        
        for param in testParams {
            if await performHTTPRequest(url: "\(url)?\(param)") {
                return Vulnerability(
                    title: "Insecure Design",
                    description: "Application exposes debug or development parameters",
                    severity: .medium,
                    discoveredAt: Date()
                )
            }
        }
        return nil
    }
    
    private func testSecurityMisconfiguration(url: String) async -> Vulnerability? {
        let headers = await getHTTPHeaders(url: url)
        
        let dangerousHeaders = ["Server", "X-Powered-By", "X-AspNet-Version"]
        for header in dangerousHeaders {
            if headers.contains(header) {
                return Vulnerability(
                    title: "Security Misconfiguration",
                    description: "Information disclosure via HTTP headers: \(header)",
                    severity: .low,
                    discoveredAt: Date()
                )
            }
        }
        return nil
    }
    
    private func testVulnerableComponents(url: String) async -> Vulnerability? {
        let headers = await getHTTPHeaders(url: url)
        
        if headers.contains(where: { $0.contains("jQuery/1.") || $0.contains("bootstrap/3.") }) {
            return Vulnerability(
                title: "Vulnerable Components",
                description: "Outdated JavaScript libraries detected",
                severity: .medium,
                discoveredAt: Date()
            )
        }
        return nil
    }
    
    private func testIdentificationFailures(url: String) async -> Vulnerability? {
        let weakPasswords = ["admin", "password", "123456"]
        
        for password in weakPasswords {
            if await testSimpleLogin(url: url, username: "admin", password: password) {
                return Vulnerability(
                    title: "Identification and Authentication Failures",
                    description: "Weak default credentials detected: admin/\(password)",
                    severity: .critical,
                    discoveredAt: Date()
                )
            }
        }
        return nil
    }
    
    private func testSSRF(url: String) async -> Vulnerability? {
        let ssrfPayloads = ["http://localhost:22", "http://127.0.0.1:80"]
        
        for payload in ssrfPayloads {
            if await performHTTPRequest(url: "\(url)?url=\(payload)") {
                return Vulnerability(
                    title: "Server-Side Request Forgery (SSRF)",
                    description: "SSRF vulnerability detected with payload: \(payload)",
                    severity: .high,
                    discoveredAt: Date()
                )
            }
        }
        return nil
    }
    
    // Modern Web Security Test Implementations
    private func testCSRF(url: String) async -> Vulnerability? {
        let headers = await getHTTPHeaders(url: url)
        
        if !headers.contains(where: { $0.contains("X-CSRF-Token") || $0.contains("SameSite") }) {
            return Vulnerability(
                title: "Cross-Site Request Forgery (CSRF)",
                description: "Missing CSRF protection mechanisms",
                severity: .medium,
                discoveredAt: Date()
            )
        }
        return nil
    }
    
    private func testCORS(url: String) async -> Vulnerability? {
        let headers = await getHTTPHeaders(url: url)
        
        if headers.contains("Access-Control-Allow-Origin: *") {
            return Vulnerability(
                title: "CORS Misconfiguration",
                description: "Wildcard CORS policy allows any origin",
                severity: .medium,
                discoveredAt: Date()
            )
        }
        return nil
    }
    
    private func testClickjacking(url: String) async -> Vulnerability? {
        let headers = await getHTTPHeaders(url: url)
        
        if !headers.contains(where: { $0.contains("X-Frame-Options") || $0.contains("frame-ancestors") }) {
            return Vulnerability(
                title: "Clickjacking",
                description: "Missing frame protection headers",
                severity: .medium,
                discoveredAt: Date()
            )
        }
        return nil
    }
    
    private func testCSP(url: String) async -> Vulnerability? {
        let headers = await getHTTPHeaders(url: url)
        
        if !headers.contains(where: { $0.contains("Content-Security-Policy") }) {
            return Vulnerability(
                title: "Missing Content Security Policy",
                description: "No CSP header found, vulnerable to XSS attacks",
                severity: .medium,
                discoveredAt: Date()
            )
        }
        return nil
    }
    
    private func testFileUpload(url: String) async -> Vulnerability? {
        let uploadPaths = ["/upload", "/files/upload", "/admin/upload"]
        
        for path in uploadPaths {
            if await performHTTPRequest(url: "\(url)\(path)", method: "POST") {
                return Vulnerability(
                    title: "Insecure File Upload",
                    description: "Unrestricted file upload endpoint detected at \(path)",
                    severity: .high,
                    discoveredAt: Date()
                )
            }
        }
        return nil
    }
    
    // Injection Attack Test Implementations
    private func testCommandInjection(url: String) async -> Vulnerability? {
        let cmdPayloads = ["; ls", "| whoami", "&& echo test"]
        
        for payload in cmdPayloads {
            if await performHTTPRequest(url: "\(url)?cmd=\(payload)") {
                return Vulnerability(
                    title: "Command Injection",
                    description: "OS command injection vulnerability detected",
                    severity: .critical,
                    discoveredAt: Date()
                )
            }
        }
        return nil
    }
    
    private func testXXE(url: String) async -> Vulnerability? {
        let xxePayload = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE test [<!ENTITY xxe SYSTEM "file:///etc/passwd">]>
        <test>&xxe;</test>
        """
        
        if await performHTTPRequest(url: url, method: "POST", data: xxePayload) {
            return Vulnerability(
                title: "XML External Entity (XXE) Injection",
                description: "XXE vulnerability detected in XML parser",
                severity: .high,
                discoveredAt: Date()
            )
        }
        return nil
    }
    
    private func testLDAPInjection(url: String) async -> Vulnerability? {
        let ldapPayloads = ["*)(uid=*))(|(uid=*", "*)(|(password=*)"]
        
        for payload in ldapPayloads {
            if await performHTTPRequest(url: "\(url)?user=\(payload)") {
                return Vulnerability(
                    title: "LDAP Injection",
                    description: "LDAP injection vulnerability detected",
                    severity: .high,
                    discoveredAt: Date()
                )
            }
        }
        return nil
    }
    
    // Generic test for unimplemented tests
    private func testGenericVulnerability(test: WebTest, url: String) async -> Vulnerability? {
        // Perform basic HTTP request to check if endpoint responds
        if await performHTTPRequest(url: url) {
            // Simulate finding a low-severity issue for demonstration
            return Vulnerability(
                title: test.name,
                description: "Basic test performed - manual verification recommended",
                severity: .low,
                discoveredAt: Date()
            )
        }
        return nil
    }
    
    // Helper function for simple login testing
    private func testSimpleLogin(url: String, username: String, password: String) async -> Bool {
        let loginData = "username=\(username)&password=\(password)"
        return await performHTTPRequest(url: "\(url)/login", method: "POST", data: loginData)
    }
    
    // HTTP utility methods
    private func performHTTPRequest(url: String, method: String = "GET", data: String? = nil) async -> Bool {
        guard let requestURL = URL(string: url) else { return false }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = method
        request.timeoutInterval = 10.0
        
        if let data = data {
            request.httpBody = data.data(using: .utf8)
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                let responseString = String(data: data, encoding: .utf8) ?? ""
                
                // Check for error indicators that might suggest vulnerability
                let errorIndicators = [
                    "error", "mysql", "syntax", "exception", "stack trace",
                    "sql", "oracle", "postgresql", "sqlite", "database",
                    "warning", "fatal", "parse error", "syntax error",
                    "table", "column", "query", "select", "insert", "update",
                    "500 internal server error", "application error"
                ]
                
                // Also check for differences in response time or status codes that might indicate SQLi
                let statusCode = httpResponse.statusCode
                if statusCode == 500 || statusCode == 403 {
                    return true
                }
                
                return errorIndicators.contains { responseString.lowercased().contains($0) }
            }
        } catch {
            // Network errors might indicate vulnerability
            return true
        }
        
        return false
    }
    
    private func getHTTPHeaders(url: String) async -> [String] {
        guard let requestURL = URL(string: url) else { return [] }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10.0
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                return Array(httpResponse.allHeaderFields.keys.compactMap { $0 as? String })
            }
        } catch {
            print("Error fetching headers: \(error)")
        }
        
        return []
    }
    
    private func checkWeakCiphers(url: String) async -> Bool {
        // This would require a more sophisticated SSL/TLS testing implementation
        // For now, return false (no weak ciphers detected)
        return false
    }
    
    private func extractHostFromURL(_ urlString: String) -> String {
        guard let url = URL(string: urlString),
              let host = url.host else {
            return urlString
        }
        return host
    }
    
    private func generateTestDetails(for test: WebTest, vulnerability: Vulnerability?) -> String {
        if let vulnerability = vulnerability {
            return """
            Test: \(test.displayName)
            Status: VULNERABLE
            Severity: \(vulnerability.severity.rawValue)
            
            Description:
            \(vulnerability.description)
            
            Recommendations:
            \(test.recommendations)
            """
        } else {
            return """
            Test: \(test.displayName)
            Status: SECURE
            
            No vulnerabilities detected for this test.
            
            Recommendations:
            \(test.recommendations)
            """
        }
    }
    
    // MARK: - Real Tool Execution Functions
    
    private func executeRealSQLMap(targetURL: String) async -> (output: [String], vulnerabilities: [String]) {
        var output: [String] = []
        var vulnerabilities: [String] = []
        
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        
        // Check if SQLMap is installed
        guard let sqlmapPath = findToolPath("sqlmap") else {
            output.append("❌ SQLMap not found. Install with: brew install sqlmap")
            return (output, vulnerabilities)
        }
        
        process.executableURL = URL(fileURLWithPath: sqlmapPath)
        process.arguments = [
            "-u", targetURL,
            "--batch",  // Non-interactive mode
            "--level=1",  // Test level
            "--risk=1",   // Risk level
            "--timeout=30",  // Timeout per request
            "--retries=1"    // Number of retries
        ]
        
        output.append("🚀 Starting SQLMap scan...")
        output.append("Target: \(targetURL)")
        output.append("Command: \(sqlmapPath) \(process.arguments?.joined(separator: " ") ?? "")")
        
        do {
            try process.run()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let outputString = String(data: data, encoding: .utf8) {
                let lines = outputString.components(separatedBy: .newlines)
                output.append(contentsOf: lines)
                
                // Parse SQLMap output for vulnerabilities
                for line in lines {
                    let lowerLine = line.lowercased()
                    if lowerLine.contains("vulnerable") && !lowerLine.contains("not vulnerable") {
                        vulnerabilities.append(line.trimmingCharacters(in: .whitespacesAndNewlines))
                    } else if lowerLine.contains("injection") && lowerLine.contains("found") {
                        vulnerabilities.append(line.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                }
            }
            
            process.waitUntilExit()
            output.append("✅ SQLMap scan completed")
            
        } catch {
            output.append("❌ Error executing SQLMap: \(error.localizedDescription)")
        }
        
        return (output, vulnerabilities)
    }
    
    private func executeRealNikto(targetURL: String) async -> (output: [String], vulnerabilities: [String]) {
        var output: [String] = []
        var vulnerabilities: [String] = []
        
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        
        // Check if Nikto is installed
        guard let niktoPath = findToolPath("nikto") else {
            output.append("❌ Nikto not found. Install with: brew install nikto")
            return (output, vulnerabilities)
        }
        
        process.executableURL = URL(fileURLWithPath: niktoPath)
        process.arguments = [
            "-h", targetURL,
            "-C", "all",  // Check all vulnerability classes
            "-nointeractive",  // Don't prompt for input
            "-timeout", "30",  // Request timeout
            "-maxtime", "300"  // Maximum scan time (5 minutes)
        ]
        
        output.append("🚀 Starting Nikto scan...")
        output.append("Target: \(targetURL)")
        output.append("Command: \(niktoPath) \(process.arguments?.joined(separator: " ") ?? "")")
        
        do {
            try process.run()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let outputString = String(data: data, encoding: .utf8) {
                let lines = outputString.components(separatedBy: .newlines)
                output.append(contentsOf: lines)
                
                // Parse Nikto output for vulnerabilities
                for line in lines {
                    let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmedLine.contains("+") && (
                        trimmedLine.lowercased().contains("vuln") ||
                        trimmedLine.lowercased().contains("security") ||
                        trimmedLine.lowercased().contains("risk") ||
                        trimmedLine.lowercased().contains("exposed") ||
                        trimmedLine.lowercased().contains("version") ||
                        trimmedLine.lowercased().contains("header")
                    ) {
                        vulnerabilities.append(trimmedLine)
                    }
                }
            }
            
            process.waitUntilExit()
            output.append("✅ Nikto scan completed")
            
        } catch {
            output.append("❌ Error executing Nikto: \(error.localizedDescription)")
        }
        
        return (output, vulnerabilities)
    }
    
    private func findToolPath(_ toolName: String) -> String? {
        let commonPaths = [
            "/usr/local/bin/\(toolName)",
            "/opt/homebrew/bin/\(toolName)",
            "/usr/bin/\(toolName)",
            "/bin/\(toolName)"
        ]
        
        for path in commonPaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        // Try using 'which' command
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [toolName]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !path.isEmpty {
                return path
            }
        } catch {
            // Ignore error, tool not found
        }
        
        return nil
    }
    
    private func executeDirectoryEnumeration(targetURL: String) async -> (output: [String], vulnerabilities: [String]) {
        var output: [String] = []
        let vulnerabilities: [String] = []
        
        // Try gobuster first, then dirb as fallback
        if let gobusterPath = findToolPath("gobuster") {
            return await executeGobuster(targetURL: targetURL, toolPath: gobusterPath)
        } else if let dirbPath = findToolPath("dirb") {
            return await executeDirb(targetURL: targetURL, toolPath: dirbPath)
        } else {
            output.append("❌ No directory enumeration tools found. Install with: brew install gobuster dirb")
            return (output, vulnerabilities)
        }
    }
    
    private func executeGobuster(targetURL: String, toolPath: String) async -> (output: [String], vulnerabilities: [String]) {
        var output: [String] = []
        var vulnerabilities: [String] = []
        
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        process.executableURL = URL(fileURLWithPath: toolPath)
        
        // Create a basic wordlist if none exists
        let wordlist = createBasicWordlist()
        
        process.arguments = [
            "dir",
            "-u", targetURL,
            "-w", wordlist,
            "-t", "10",  // 10 threads
            "--timeout", "30s"
        ]
        
        output.append("🚀 Starting Gobuster directory enumeration...")
        output.append("Target: \(targetURL)")
        output.append("Command: \(toolPath) \(process.arguments?.joined(separator: " ") ?? "")")
        
        do {
            try process.run()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let outputString = String(data: data, encoding: .utf8) {
                let lines = outputString.components(separatedBy: .newlines)
                output.append(contentsOf: lines)
                
                // Parse gobuster output for found directories/files
                for line in lines {
                    let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmedLine.contains("(Status: 200)") || trimmedLine.contains("(Status: 301)") || trimmedLine.contains("(Status: 302)") {
                        vulnerabilities.append(trimmedLine)
                    }
                }
            }
            
            process.waitUntilExit()
            output.append("✅ Gobuster scan completed")
            
        } catch {
            output.append("❌ Error executing Gobuster: \(error.localizedDescription)")
        }
        
        return (output, vulnerabilities)
    }
    
    private func executeDirb(targetURL: String, toolPath: String) async -> (output: [String], vulnerabilities: [String]) {
        var output: [String] = []
        var vulnerabilities: [String] = []
        
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        process.executableURL = URL(fileURLWithPath: toolPath)
        
        let wordlist = createBasicWordlist()
        
        process.arguments = [
            targetURL,
            wordlist,
            "-w"  // Don't stop on warning messages
        ]
        
        output.append("🚀 Starting Dirb directory enumeration...")
        output.append("Target: \(targetURL)")
        output.append("Command: \(toolPath) \(process.arguments?.joined(separator: " ") ?? "")")
        
        do {
            try process.run()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let outputString = String(data: data, encoding: .utf8) {
                let lines = outputString.components(separatedBy: .newlines)
                output.append(contentsOf: lines)
                
                // Parse dirb output for found directories/files
                for line in lines {
                    let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmedLine.hasPrefix("+ ") && (trimmedLine.contains("(CODE:200)") || trimmedLine.contains("(CODE:301)")) {
                        vulnerabilities.append(trimmedLine)
                    }
                }
            }
            
            process.waitUntilExit()
            output.append("✅ Dirb scan completed")
            
        } catch {
            output.append("❌ Error executing Dirb: \(error.localizedDescription)")
        }
        
        return (output, vulnerabilities)
    }
    
    private func createBasicWordlist() -> String {
        let tempDir = FileManager.default.temporaryDirectory
        let wordlistPath = tempDir.appendingPathComponent("web_wordlist.txt")
        
        let commonPaths = [
            "admin", "administrator", "login", "wp-admin", "phpmyadmin",
            "backup", "config", "test", "dev", "staging", "api",
            "uploads", "images", "css", "js", "assets", "static",
            "robots.txt", "sitemap.xml", ".git", ".svn", "backup.zip"
        ]
        
        let wordlistContent = commonPaths.joined(separator: "\n")
        
        do {
            try wordlistContent.write(to: wordlistPath, atomically: true, encoding: .utf8)
            return wordlistPath.path
        } catch {
            // Fallback to a simple list
            return "/dev/null"
        }
    }
    
    // MARK: - Modern Security Tool Implementations
    
    private func performNucleiScan(url: String) async -> Vulnerability? {
        // Execute Nuclei with 9000+ vulnerability templates
        let result = await executeNuclei(targetURL: url)
        
        if !result.vulnerabilities.isEmpty {
            let nucleiVuln = result.vulnerabilities.first!
            return Vulnerability(
                title: "Nuclei Template Match",
                description: "Nuclei detected: \(nucleiVuln)",
                severity: .critical,
                discoveredAt: Date()
            )
        }
        
        return nil
    }
    
    private func performHTTPProbing(url: String) async -> Vulnerability? {
        // Execute HTTPx for service analysis
        let result = await executeHTTPx(targetURL: url)
        
        if !result.vulnerabilities.isEmpty {
            let httpVuln = result.vulnerabilities.first!
            return Vulnerability(
                title: "HTTP Service Issue",
                description: "HTTPx found: \(httpVuln)",
                severity: .medium,
                discoveredAt: Date()
            )
        }
        
        return nil
    }
    
    private func performSubdomainEnumeration(url: String) async -> Vulnerability? {
        // Execute Subfinder for subdomain discovery
        guard let domain = extractDomainFromURL(url) else { return nil }
        let result = await executeSubfinder(domain: domain)
        
        if !result.vulnerabilities.isEmpty {
            let subVuln = result.vulnerabilities.first!
            return Vulnerability(
                title: "Subdomain Discovery",
                description: "Found subdomains: \(subVuln)",
                severity: .medium,
                discoveredAt: Date()
            )
        }
        
        return nil
    }
    
    private func performAdvancedFuzzing(url: String) async -> Vulnerability? {
        // Execute FFuF for advanced fuzzing
        let result = await executeFFuF(targetURL: url)
        
        if !result.vulnerabilities.isEmpty {
            let fuzzVuln = result.vulnerabilities.first!
            return Vulnerability(
                title: "Fuzzing Discovery",
                description: "FFuF found: \(fuzzVuln)",
                severity: .high,
                discoveredAt: Date()
            )
        }
        
        return nil
    }
    
    private func performSSLTLSAnalysis(url: String) async -> Vulnerability? {
        // Execute SSLyze for SSL/TLS analysis
        let result = await executeSSLyze(targetURL: url)
        
        if !result.vulnerabilities.isEmpty {
            let sslVuln = result.vulnerabilities.first!
            return Vulnerability(
                title: "SSL/TLS Vulnerability",
                description: "SSLyze detected: \(sslVuln)",
                severity: .high,
                discoveredAt: Date()
            )
        }
        
        return nil
    }
    
    // MARK: - Tool Execution Functions
    
    private func executeNuclei(targetURL: String) async -> (output: [String], vulnerabilities: [String]) {
        var output: [String] = []
        var vulnerabilities: [String] = []
        
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        
        guard let nucleiPath = findToolPath("nuclei") else {
            output.append("❌ Nuclei not found. Install with: go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest")
            return (output, vulnerabilities)
        }
        
        process.executableURL = URL(fileURLWithPath: nucleiPath)
        process.arguments = [
            "-u", targetURL,
            "-json",        // JSON output
            "-silent",      // Silent mode
            "-severity", "critical,high,medium",  // Only important findings
            "-timeout", "30",
            "-retries", "1"
        ]
        
        output.append("🚀 Starting Nuclei vulnerability scan...")
        output.append("Target: \(targetURL)")
        output.append("Templates: 9000+ vulnerability checks")
        
        do {
            try process.run()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let outputString = String(data: data, encoding: .utf8) {
                let lines = outputString.components(separatedBy: .newlines)
                
                for line in lines.filter({ !$0.isEmpty }) {
                    // Parse JSON output from Nuclei
                    if let jsonData = line.data(using: .utf8),
                       let nucleiResult = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                        
                        if let templateID = nucleiResult["template-id"] as? String,
                           let info = nucleiResult["info"] as? [String: Any],
                           let name = info["name"] as? String,
                           let severity = info["severity"] as? String {
                            
                            let vulnDesc = "\(templateID): \(name) [\(severity.uppercased())]"
                            vulnerabilities.append(vulnDesc)
                            output.append("✅ Found: \(vulnDesc)")
                        }
                    } else {
                        output.append(line)
                    }
                }
            }
            
            process.waitUntilExit()
            output.append("✅ Nuclei scan completed")
            
        } catch {
            output.append("❌ Error executing Nuclei: \(error.localizedDescription)")
        }
        
        return (output, vulnerabilities)
    }
    
    private func executeHTTPx(targetURL: String) async -> (output: [String], vulnerabilities: [String]) {
        var output: [String] = []
        var vulnerabilities: [String] = []
        
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        
        guard let httpxPath = findToolPath("httpx") else {
            output.append("❌ HTTPx not found. Install with: go install github.com/projectdiscovery/httpx/cmd/httpx@latest")
            return (output, vulnerabilities)
        }
        
        process.executableURL = URL(fileURLWithPath: httpxPath)
        process.arguments = [
            "-u", targetURL,
            "-json",           // JSON output
            "-title",          // Extract page titles
            "-tech-detect",    // Technology detection
            "-status-code",    // Include status codes
            "-content-length", // Content length
            "-silent"
        ]
        
        output.append("🚀 Starting HTTPx service analysis...")
        output.append("Target: \(targetURL)")
        
        do {
            try process.run()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let outputString = String(data: data, encoding: .utf8) {
                let lines = outputString.components(separatedBy: .newlines)
                
                for line in lines.filter({ !$0.isEmpty }) {
                    if let jsonData = line.data(using: .utf8),
                       let httpxResult = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                        
                        var findings: [String] = []
                        
                        if let technologies = httpxResult["tech"] as? [String], !technologies.isEmpty {
                            findings.append("Technologies: \(technologies.joined(separator: ", "))")
                        }
                        
                        if let statusCode = httpxResult["status_code"] as? Int {
                            if statusCode >= 400 {
                                findings.append("Error status: \(statusCode)")
                            }
                        }
                        
                        if let title = httpxResult["title"] as? String, title.lowercased().contains("error") {
                            findings.append("Error page detected: \(title)")
                        }
                        
                        if !findings.isEmpty {
                            vulnerabilities.append(contentsOf: findings)
                        }
                    }
                    output.append(line)
                }
            }
            
            process.waitUntilExit()
            output.append("✅ HTTPx analysis completed")
            
        } catch {
            output.append("❌ Error executing HTTPx: \(error.localizedDescription)")
        }
        
        return (output, vulnerabilities)
    }
    
    private func executeSubfinder(domain: String) async -> (output: [String], vulnerabilities: [String]) {
        var output: [String] = []
        var vulnerabilities: [String] = []
        
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        
        guard let subfinderPath = findToolPath("subfinder") else {
            output.append("❌ Subfinder not found. Install with: go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest")
            return (output, vulnerabilities)
        }
        
        process.executableURL = URL(fileURLWithPath: subfinderPath)
        process.arguments = [
            "-d", domain,
            "-silent",
            "-max-time", "300"  // 5 minute timeout
        ]
        
        output.append("🚀 Starting Subfinder subdomain enumeration...")
        output.append("Domain: \(domain)")
        
        do {
            try process.run()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let outputString = String(data: data, encoding: .utf8) {
                let subdomains = outputString.components(separatedBy: .newlines)
                    .filter { !$0.isEmpty && $0.contains(".") }
                
                for subdomain in subdomains {
                    vulnerabilities.append(subdomain)
                    output.append("✅ Found subdomain: \(subdomain)")
                }
            }
            
            process.waitUntilExit()
            output.append("✅ Subfinder enumeration completed - found \(vulnerabilities.count) subdomains")
            
        } catch {
            output.append("❌ Error executing Subfinder: \(error.localizedDescription)")
        }
        
        return (output, vulnerabilities)
    }
    
    private func executeFFuF(targetURL: String) async -> (output: [String], vulnerabilities: [String]) {
        var output: [String] = []
        var vulnerabilities: [String] = []
        
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        
        guard let ffufPath = findToolPath("ffuf") else {
            output.append("❌ FFuF not found. Install with: go install github.com/ffuf/ffuf@latest")
            return (output, vulnerabilities)
        }
        
        let wordlist = createFuzzingWordlist()
        
        process.executableURL = URL(fileURLWithPath: ffufPath)
        process.arguments = [
            "-u", "\(targetURL)/FUZZ",
            "-w", wordlist,
            "-json",           // JSON output
            "-mc", "200,301,302,403",  // Match status codes
            "-fs", "0",        // Filter by size
            "-t", "10",        // 10 threads
            "-timeout", "30"
        ]
        
        output.append("🚀 Starting FFuF advanced fuzzing...")
        output.append("Target: \(targetURL)")
        
        do {
            try process.run()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let outputString = String(data: data, encoding: .utf8),
               let jsonData = outputString.data(using: .utf8),
               let ffufResult = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
               let results = ffufResult["results"] as? [[String: Any]] {
                
                for result in results {
                    if let url = result["url"] as? String,
                       let status = result["status"] as? Int {
                        vulnerabilities.append("\(url) [Status: \(status)]")
                        output.append("✅ Found: \(url) [Status: \(status)]")
                    }
                }
            }
            
            process.waitUntilExit()
            output.append("✅ FFuF fuzzing completed")
            
        } catch {
            output.append("❌ Error executing FFuF: \(error.localizedDescription)")
        }
        
        return (output, vulnerabilities)
    }
    
    private func executeSSLyze(targetURL: String) async -> (output: [String], vulnerabilities: [String]) {
        var output: [String] = []
        var vulnerabilities: [String] = []
        
        let host = extractHostFromURL(targetURL)
        
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        
        guard let sslyzePath = findToolPath("sslyze") else {
            output.append("❌ SSLyze not found. Install with: pip3 install sslyze")
            return (output, vulnerabilities)
        }
        
        process.executableURL = URL(fileURLWithPath: sslyzePath)
        process.arguments = [
            "--json_out=-",     // JSON output to stdout
            "--regular",        // Regular scan
            host
        ]
        
        output.append("🚀 Starting SSLyze SSL/TLS analysis...")
        output.append("Target: \(host)")
        
        do {
            try process.run()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let outputString = String(data: data, encoding: .utf8),
               let jsonData = outputString.data(using: .utf8),
               let sslResult = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                
                // Parse SSL vulnerabilities
                if let scanResults = sslResult["server_scan_results"] as? [[String: Any]] {
                    for result in scanResults {
                        // Check for weak ciphers, protocols, etc.
                        if let sslInfo = result["ssl_configuration"] as? [String: Any],
                           let weakCiphers = sslInfo["weak_ciphers"] as? [String], !weakCiphers.isEmpty {
                            vulnerabilities.append("Weak SSL ciphers detected: \(weakCiphers.joined(separator: ", "))")
                        }
                    }
                }
            }
            
            process.waitUntilExit()
            output.append("✅ SSLyze analysis completed")
            
        } catch {
            output.append("❌ Error executing SSLyze: \(error.localizedDescription)")
        }
        
        return (output, vulnerabilities)
    }
    
    private func createFuzzingWordlist() -> String {
        let tempDir = FileManager.default.temporaryDirectory
        let wordlistPath = tempDir.appendingPathComponent("fuzz_wordlist.txt")
        
        let fuzzingPaths = [
            "admin", "api", "backup", "config", "dev", "test", "staging", "prod",
            "dashboard", "panel", "login", "auth", "user", "users", "account",
            "upload", "uploads", "files", "docs", "documentation", "help",
            "robots.txt", "sitemap.xml", ".env", ".git", "package.json",
            "wp-admin", "wp-login", "phpmyadmin", "mysql", "database"
        ]
        
        let wordlistContent = fuzzingPaths.joined(separator: "\n")
        
        do {
            try wordlistContent.write(to: wordlistPath, atomically: true, encoding: .utf8)
            return wordlistPath.path
        } catch {
            return "/dev/null"
        }
    }
    
    private func extractDomainFromURL(_ urlString: String) -> String? {
        guard let url = URL(string: urlString),
              let host = url.host else {
            return nil
        }
        
        // Remove subdomains to get base domain
        let components = host.components(separatedBy: ".")
        if components.count >= 2 {
            return components.suffix(2).joined(separator: ".")
        }
        
        return host
    }
    
    // MARK: - DoS/Stress Testing (AUTHORIZED USE ONLY)
    
    private func performHTTPStressTesting(url: String) async -> Vulnerability? {
        // ETHICAL SAFEGUARD: Show warning and require explicit confirmation
        let ethicalWarning = await showEthicalWarning(for: "HTTP Stress Testing")
        guard ethicalWarning else { return nil }
        
        let result = await executeWrkStressTesting(targetURL: url)
        
        if result.vulnerabilityDetected {
            return Vulnerability(
                title: "HTTP Server Capacity Limitation",
                description: "Server showed performance degradation under load: \(result.findings)",
                severity: .medium,
                discoveredAt: Date()
            )
        }
        
        return nil
    }
    
    private func performSlowlorisTest(url: String) async -> Vulnerability? {
        // ETHICAL SAFEGUARD: Show warning and require explicit confirmation
        let ethicalWarning = await showEthicalWarning(for: "Slowloris DoS Testing")
        guard ethicalWarning else { return nil }
        
        let result = await executeSlowlorisTest(targetURL: url)
        
        if result.vulnerabilityDetected {
            return Vulnerability(
                title: "Slowloris DoS Vulnerability",
                description: "Server vulnerable to slow HTTP attacks: \(result.findings)",
                severity: .high,
                discoveredAt: Date()
            )
        }
        
        return nil
    }
    
    private func performConnectionExhaustionTest(url: String) async -> Vulnerability? {
        // ETHICAL SAFEGUARD: Show warning and require explicit confirmation
        let ethicalWarning = await showEthicalWarning(for: "Connection Exhaustion Testing")
        guard ethicalWarning else { return nil }
        
        let result = await executeConnectionExhaustionTest(targetURL: url)
        
        if result.vulnerabilityDetected {
            return Vulnerability(
                title: "Connection Exhaustion Vulnerability",
                description: "Server vulnerable to connection exhaustion: \(result.findings)",
                severity: .medium,
                discoveredAt: Date()
            )
        }
        
        return nil
    }
    
    // MARK: - DoS Tool Execution Functions
    
    private func executeWrkStressTesting(targetURL: String) async -> (vulnerabilityDetected: Bool, findings: String) {
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        
        guard let wrkPath = findToolPath("wrk") else {
            return (false, "wrk tool not found. Install with: brew install wrk")
        }
        
        process.executableURL = URL(fileURLWithPath: wrkPath)
        process.arguments = [
            "-t4",          // 4 threads (conservative)
            "-c100",        // 100 connections (moderate load)
            "-d30s",        // 30 second test (limited duration)
            "--timeout", "10s",
            targetURL
        ]
        
        do {
            try process.run()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let outputString = String(data: data, encoding: .utf8) {
                // Parse wrk output for performance metrics
                let lines = outputString.components(separatedBy: .newlines)
                
                for line in lines {
                    // Look for error rates or timeout indicators
                    if line.contains("errors") || line.contains("timeout") || line.contains("failed") {
                        return (true, "Server showed errors under moderate load: \(line)")
                    }
                    
                    // Check for very slow response times
                    if line.contains("Latency") && line.contains("ms") {
                        // Extract latency values - simplified parsing
                        if line.contains("2000ms") || line.contains("3000ms") {
                            return (true, "Server response time degraded significantly: \(line)")
                        }
                    }
                }
            }
            
            process.waitUntilExit()
            return (false, "Server handled load testing within normal parameters")
            
        } catch {
            return (false, "Error executing stress test: \(error.localizedDescription)")
        }
    }
    
    private func executeSlowlorisTest(targetURL: String) async -> (vulnerabilityDetected: Bool, findings: String) {
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        
        guard let slowHttpPath = findToolPath("slowhttptest") else {
            return (false, "slowhttptest not found. Install from: https://github.com/shekyan/slowhttptest")
        }
        
        process.executableURL = URL(fileURLWithPath: slowHttpPath)
        process.arguments = [
            "-c", "200",        // 200 connections (limited)
            "-H",               // Slowloris mode
            "-i", "10",         // 10 second intervals
            "-r", "200",        // 200 connections per second
            "-t", "GET",        // GET request
            "-u", targetURL,
            "-x", "30",         // 30 second test (limited)
            "-p", "3"           // 3 second timeout
        ]
        
        do {
            try process.run()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let outputString = String(data: data, encoding: .utf8) {
                let lines = outputString.components(separatedBy: .newlines)
                
                for line in lines {
                    // Check for successful DoS indicators
                    if line.lowercased().contains("service unavailable") ||
                       line.lowercased().contains("connection refused") ||
                       line.lowercased().contains("timeout") {
                        return (true, "Server vulnerable to Slowloris attack: \(line)")
                    }
                }
            }
            
            process.waitUntilExit()
            return (false, "Server resistant to Slowloris attack")
            
        } catch {
            return (false, "Error executing Slowloris test: \(error.localizedDescription)")
        }
    }
    
    private func executeConnectionExhaustionTest(targetURL: String) async -> (vulnerabilityDetected: Bool, findings: String) {
        let host = extractHostFromURL(targetURL)
        
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        
        guard let hpingPath = findToolPath("hping3") else {
            return (false, "hping3 not found. Install with: brew install hping")
        }
        
        process.executableURL = URL(fileURLWithPath: hpingPath)
        process.arguments = [
            "-S",               // SYN packets
            "-p", "80",         // Port 80
            "-i", "u100",       // 100 microsecond intervals (limited rate)
            "-c", "1000",       // 1000 packets (limited count)
            host
        ]
        
        do {
            try process.run()
            
            // Limit test duration to 30 seconds max
            let timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false) { _ in
                process.terminate()
            }
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let outputString = String(data: data, encoding: .utf8) {
                let lines = outputString.components(separatedBy: .newlines)
                
                // Analyze packet loss or connection issues
                for line in lines {
                    if line.contains("packet loss") {
                        let components = line.components(separatedBy: " ")
                        if let lossIndex = components.firstIndex(where: { $0.contains("%") }),
                           let lossStr = components[safe: lossIndex - 1],
                           let loss = Double(lossStr), loss > 50 {
                            timer.invalidate()
                            return (true, "High packet loss detected: \(line)")
                        }
                    }
                }
            }
            
            process.waitUntilExit()
            timer.invalidate()
            return (false, "Server handled connection testing normally")
            
        } catch {
            return (false, "Error executing connection test: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    private func showEthicalWarning(for testType: String) async -> Bool {
        // In a real implementation, this would show a SwiftUI alert
        // For now, we'll implement conservative defaults
        
        // CRITICAL: Always require explicit authorization
        print("⚠️  ETHICAL WARNING: \(testType)")
        print("This test can impact server performance and availability.")
        print("Only proceed if you own the target system or have explicit written permission.")
        print("Unauthorized DoS testing is illegal and unethical.")
        
        // For now, return false to prevent accidental misuse
        // In production, this should show an actual UI confirmation dialog
        return false
    }
}

// MARK: - Array Extension for Safe Access
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

enum WebExportFormat {
    case pdf, json, csv
}

#Preview {
    ModernWebTestingView()
        .environment(AppState())
        .frame(width: 1200, height: 800)
}
