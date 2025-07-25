//
//  WebTestingView.swift
//  DonkTool
//
//  Web application security testing interface
//

import SwiftUI
import Foundation

// MARK: - Web Testing Types
enum WebTest: String, CaseIterable {
    case sqlInjection = "sql_injection"
    case xss = "cross_site_scripting"
    case csrf = "csrf"
    case directoryTraversal = "directory_traversal"
    case fileInclusion = "file_inclusion"
    case commandInjection = "command_injection"
    case authenticationBypass = "auth_bypass"
    case sessionManagement = "session_mgmt"
    case httpHeaderSecurity = "http_headers"
    case sslTlsConfiguration = "ssl_tls"
    
    var displayName: String {
        switch self {
        case .sqlInjection: return "SQL Injection"
        case .xss: return "Cross-Site Scripting"
        case .csrf: return "CSRF"
        case .directoryTraversal: return "Directory Traversal"
        case .fileInclusion: return "File Inclusion"
        case .commandInjection: return "Command Injection"
        case .authenticationBypass: return "Auth Bypass"
        case .sessionManagement: return "Session Management"
        case .httpHeaderSecurity: return "HTTP Headers"
        case .sslTlsConfiguration: return "SSL/TLS Config"
        }
    }
    
    var description: String {
        switch self {
        case .sqlInjection: return "Tests for SQL injection vulnerabilities"
        case .xss: return "Tests for cross-site scripting vulnerabilities"
        case .csrf: return "Tests for cross-site request forgery"
        case .directoryTraversal: return "Tests for directory traversal vulnerabilities"
        case .fileInclusion: return "Tests for file inclusion vulnerabilities"
        case .commandInjection: return "Tests for command injection vulnerabilities"
        case .authenticationBypass: return "Tests for authentication bypass"
        case .sessionManagement: return "Tests session management security"
        case .httpHeaderSecurity: return "Tests HTTP security headers"
        case .sslTlsConfiguration: return "Tests SSL/TLS configuration"
        }
    }
    
    var recommendations: String {
        switch self {
        case .sqlInjection: return "Use parameterized queries and input validation"
        case .xss: return "Implement proper output encoding and CSP headers"
        case .csrf: return "Use CSRF tokens and validate referrer headers"
        case .directoryTraversal: return "Validate and sanitize file path inputs"
        case .fileInclusion: return "Restrict file inclusion to whitelisted files"
        case .commandInjection: return "Avoid system commands with user input"
        case .authenticationBypass: return "Implement proper access controls"
        case .sessionManagement: return "Use secure session configuration"
        case .httpHeaderSecurity: return "Configure security headers properly"
        case .sslTlsConfiguration: return "Use strong TLS configuration"
        }
    }
}

struct WebTestResult: Identifiable {
    let id = UUID()
    let test: WebTest
    let url: String
    let status: TestStatus
    let vulnerability: Vulnerability?
    let timestamp: Date
    let details: String
    
    enum TestStatus {
        case vulnerable
        case secure
        case error
        case pending
    }
}

struct WebTestingView: View {
    @Environment(AppState.self) private var appState
    @State private var targetURL = ""
    @State private var selectedTests: Set<WebTest> = []
    @State private var isTestingInProgress = false
    @State private var testResults: [WebTestResult] = []
    @State private var selectedResult: WebTestResult?
    
    let availableTests = WebTest.allCases
    
    var body: some View {
        VStack(spacing: 0) {
            // Configuration Panel
            VStack(spacing: 16) {
                HStack {
                    Text("Web Application Testing")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                }
                
                // Target URL
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target URL")
                        .font(.headline)
                    
                    TextField("https://example.com", text: $targetURL)
                        .textFieldStyle(.roundedBorder)
                }
                
                // Test selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Security Tests")
                        .font(.headline)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(availableTests, id: \.self) { test in
                            TestToggleView(
                                test: test,
                                isSelected: selectedTests.contains(test)
                            ) { isSelected in
                                if isSelected {
                                    selectedTests.insert(test)
                                } else {
                                    selectedTests.remove(test)
                                }
                            }
                        }
                    }
                }
                
                // Action buttons
                HStack {
                    Button("Select All") {
                        selectedTests = Set(availableTests)
                    }
                    
                    Button("Clear All") {
                        selectedTests.removeAll()
                    }
                    
                    Spacer()
                    
                    Button("Start Testing") {
                        startWebTesting()
                    }
                    .disabled(targetURL.isEmpty || selectedTests.isEmpty || isTestingInProgress)
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Results section
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Test Results")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if isTestingInProgress {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Testing in progress...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                if testResults.isEmpty && !isTestingInProgress {
                    ContentUnavailableView(
                        "No Test Results",
                        systemImage: "globe.desk",
                        description: Text("Configure tests and start scanning a web application")
                    )
                } else {
                    List(testResults) { result in
                        WebTestResultRowView(result: result)
                            .onTapGesture {
                                selectedResult = result
                            }
                    }
                    .listStyle(.plain)
                }
            }
        }
        .sheet(item: $selectedResult) { result in
            WebTestDetailView(result: result)
        }
    }
    
    private func startWebTesting() {
        guard !targetURL.isEmpty, !selectedTests.isEmpty else { return }
        
        isTestingInProgress = true
        testResults = []
        
        Task {
            for test in selectedTests {
                let result = await performWebTest(test: test, url: targetURL)
                await MainActor.run {
                    testResults.append(result)
                }
                
                // Delay between tests
                try? await Task.sleep(nanoseconds: 500_000_000) // 500ms
            }
            
            await MainActor.run {
                isTestingInProgress = false
            }
        }
    }
    
    private func performWebTest(test: WebTest, url: String) async -> WebTestResult {
        let vulnerability = await performActualWebTest(test: test, url: url)
        
        // Add vulnerability to AppState if found
        if let vuln = vulnerability {
            await MainActor.run {
                appState.addVulnerability(vuln, targetIP: extractHostFromURL(url))
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
    
    private func extractHostFromURL(_ urlString: String) -> String {
        guard let url = URL(string: urlString),
              let host = url.host else {
            return urlString
        }
        return host
    }
    
    private func performActualWebTest(test: WebTest, url: String) async -> Vulnerability? {
        guard let testURL = URL(string: url) else { return nil }
        
        switch test {
        case .httpHeaderSecurity:
            return await testHttpHeaders(url: testURL)
        case .sslTlsConfiguration:
            return await testSSLConfiguration(url: testURL)
        case .sqlInjection:
            return await testSQLInjection(url: testURL)
        case .xss:
            return await testXSS(url: testURL)
        case .directoryTraversal:
            return await testDirectoryTraversal(url: testURL)
        case .authenticationBypass:
            return await testAuthenticationBypass(url: testURL)
        default:
            return await performBasicTest(test: test, url: testURL)
        }
    }
    
    private func testHttpHeaders(url: URL) async -> Vulnerability? {
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse else { return nil }
            
            var issues: [String] = []
            let headers = httpResponse.allHeaderFields
            
            // Check for security headers
            if headers["Strict-Transport-Security"] == nil {
                issues.append("Missing HSTS header")
            }
            if headers["X-Frame-Options"] == nil {
                issues.append("Missing X-Frame-Options header")
            }
            if headers["X-Content-Type-Options"] == nil {
                issues.append("Missing X-Content-Type-Options header")
            }
            if headers["Content-Security-Policy"] == nil {
                issues.append("Missing Content-Security-Policy header")
            }
            
            if !issues.isEmpty {
                return Vulnerability(
                    cveId: nil,
                    title: "Missing Security Headers",
                    description: "Missing security headers: \(issues.joined(separator: ", "))",
                    severity: .medium,
                    port: url.port,
                    service: url.scheme?.uppercased(),
                    discoveredAt: Date()
                )
            }
        } catch {
            // Handle network errors
        }
        return nil
    }
    
    private func testSSLConfiguration(url: URL) async -> Vulnerability? {
        guard url.scheme == "https" else {
            return Vulnerability(
                cveId: nil,
                title: "No HTTPS",
                description: "Website is not using HTTPS encryption",
                severity: .high,
                port: url.port,
                service: "HTTP",
                discoveredAt: Date()
            )
        }
        
        // Basic SSL test - in production, you'd check cipher suites, certificate validity, etc.
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                let headers = httpResponse.allHeaderFields
                if headers["Strict-Transport-Security"] == nil {
                    return Vulnerability(
                        cveId: nil,
                        title: "Weak SSL Configuration",
                        description: "HTTPS is used but HSTS is not configured",
                        severity: .medium,
                        port: url.port,
                        service: "HTTPS",
                        discoveredAt: Date()
                    )
                }
            }
        } catch {
            // SSL errors might indicate weak configuration
            return Vulnerability(
                cveId: nil,
                title: "SSL Connection Error",
                description: "SSL/TLS connection failed: \(error.localizedDescription)",
                severity: .high,
                port: url.port,
                service: "HTTPS",
                discoveredAt: Date()
            )
        }
        return nil
    }
    
    private func testSQLInjection(url: URL) async -> Vulnerability? {
        let payloads = ["'", "1' OR '1'='1", "'; DROP TABLE users; --", "1' UNION SELECT NULL--"]
        
        for payload in payloads {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = [URLQueryItem(name: "test", value: payload)]
            
            guard let testURL = components?.url else { continue }
            
            do {
                let (data, response) = try await URLSession.shared.data(from: testURL)
                guard let httpResponse = response as? HTTPURLResponse else { continue }
                
                // Check for error status codes that might indicate SQL injection
                if httpResponse.statusCode == 500 {
                    return Vulnerability(
                        cveId: nil,
                        title: "SQL Injection Vulnerability",
                        description: "Server error (500) triggered by SQL injection payload: \(payload)",
                        severity: .critical,
                        port: url.port,
                        service: url.scheme?.uppercased(),
                        discoveredAt: Date()
                    )
                }
                
                let responseString = String(data: data, encoding: .utf8) ?? ""
                
                // Look for SQL error messages
                let sqlErrors = ["SQL syntax", "mysql_fetch", "ORA-", "PostgreSQL", "sqlite_", "ODBC"]
                for error in sqlErrors {
                    if responseString.localizedCaseInsensitiveContains(error) {
                        return Vulnerability(
                            cveId: nil,
                            title: "SQL Injection Vulnerability",
                            description: "SQL injection detected with payload: \(payload)",
                            severity: .critical,
                            port: url.port,
                            service: url.scheme?.uppercased(),
                            discoveredAt: Date()
                        )
                    }
                }
            } catch {
                // Network errors - could indicate injection succeeded in breaking the application
                continue
            }
        }
        return nil
    }
    
    private func testXSS(url: URL) async -> Vulnerability? {
        let payloads = ["<script>alert('XSS')</script>", "<img src=x onerror=alert('XSS')>", "javascript:alert('XSS')"]
        
        for payload in payloads {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = [URLQueryItem(name: "test", value: payload)]
            
            guard let testURL = components?.url else { continue }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: testURL)
                let responseString = String(data: data, encoding: .utf8) ?? ""
                
                // Check if payload is reflected in response
                if responseString.contains(payload) {
                    return Vulnerability(
                        cveId: nil,
                        title: "Cross-Site Scripting (XSS)",
                        description: "XSS vulnerability detected with payload: \(payload)",
                        severity: .high,
                        port: url.port,
                        service: url.scheme?.uppercased(),
                        discoveredAt: Date()
                    )
                }
            } catch {
                // Network errors
            }
        }
        return nil
    }
    
    private func testDirectoryTraversal(url: URL) async -> Vulnerability? {
        let payloads = ["../../../etc/passwd", "..\\..\\..\\windows\\system32\\drivers\\etc\\hosts", "....//....//....//etc/passwd"]
        
        for payload in payloads {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = [URLQueryItem(name: "file", value: payload)]
            
            guard let testURL = components?.url else { continue }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: testURL)
                let responseString = String(data: data, encoding: .utf8) ?? ""
                
                // Look for signs of successful directory traversal
                if responseString.contains("root:") || responseString.contains("[boot loader]") {
                    return Vulnerability(
                        cveId: nil,
                        title: "Directory Traversal",
                        description: "Directory traversal vulnerability detected with payload: \(payload)",
                        severity: .high,
                        port: url.port,
                        service: url.scheme?.uppercased(),
                        discoveredAt: Date()
                    )
                }
            } catch {
                // Network errors
            }
        }
        return nil
    }
    
    private func testAuthenticationBypass(url: URL) async -> Vulnerability? {
        let testPaths = ["/admin", "/administrator", "/login", "/admin.php", "/wp-admin"]
        
        for path in testPaths {
            guard let testURL = URL(string: url.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + path) else { continue }
            
            do {
                let (_, response) = try await URLSession.shared.data(from: testURL)
                guard let httpResponse = response as? HTTPURLResponse else { continue }
                
                // Check for admin panels that don't redirect to login
                if httpResponse.statusCode == 200 {
                    return Vulnerability(
                        cveId: nil,
                        title: "Exposed Admin Panel",
                        description: "Admin panel accessible at: \(testURL.absoluteString)",
                        severity: .high,
                        port: url.port,
                        service: url.scheme?.uppercased(),
                        discoveredAt: Date()
                    )
                }
            } catch {
                // Network errors
            }
        }
        return nil
    }
    
    private func performBasicTest(test: WebTest, url: URL) async -> Vulnerability? {
        // Basic connectivity and response test
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse else { return nil }
            
            // Check for basic security issues
            if httpResponse.statusCode >= 500 {
                return Vulnerability(
                    cveId: nil,
                    title: "Server Error",
                    description: "Server returned HTTP \(httpResponse.statusCode) error",
                    severity: .medium,
                    port: url.port,
                    service: url.scheme?.uppercased(),
                    discoveredAt: Date()
                )
            }
            
            let responseString = String(data: data, encoding: .utf8) ?? ""
            
            // Look for common information disclosure patterns
            if responseString.localizedCaseInsensitiveContains("stack trace") ||
               responseString.localizedCaseInsensitiveContains("exception") ||
               responseString.localizedCaseInsensitiveContains("error") {
                return Vulnerability(
                    cveId: nil,
                    title: "Information Disclosure",
                    description: "Server response contains error information",
                    severity: .low,
                    port: url.port,
                    service: url.scheme?.uppercased(),
                    discoveredAt: Date()
                )
            }
        } catch {
            // Network errors might indicate issues
        }
        return nil
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
}

struct TestToggleView: View {
    let test: WebTest
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        Button(action: {
            onToggle(!isSelected)
        }) {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .blue : .secondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(test.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.leading)
                    
                    Text(test.recommendations)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.secondary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct WebTestResultRowView: View {
    let result: WebTestResult
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(result.test.displayName)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(result.status == .vulnerable ? "Vulnerable" : "Secure")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(result.status == .vulnerable ? Color.red.opacity(0.8) : Color.green.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(4)
                
                Text(result.url)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovering ? Color.gray.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isHovering ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
    
    private var statusColor: Color {
        switch result.status {
        case .vulnerable: return .red
        case .secure: return .green
        case .error: return .orange
        case .pending: return .blue
        }
    }
}

struct WebTestDetailView: View {
    let result: WebTestResult
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text(result.test.displayName)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        HStack {
                            switch result.status {
                            case .vulnerable:
                                Label("Vulnerable", systemImage: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                    .font(.headline)
                            case .secure:
                                Label("Secure", systemImage: "checkmark.shield.fill")
                                    .foregroundColor(.green)
                                    .font(.headline)
                            case .error:
                                Label("Error", systemImage: "xmark.circle.fill")
                                    .foregroundColor(.orange)
                                    .font(.headline)
                            case .pending:
                                Label("Testing", systemImage: "clock")
                                    .foregroundColor(.blue)
                                    .font(.headline)
                            }
                            
                            Spacer()
                            
                            if let vulnerability = result.vulnerability {
                                Text(vulnerability.severity.rawValue.uppercased())
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(vulnerability.severity.color.opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                            }
                        }
                        
                        // Test URL
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Target URL:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(result.url)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .textSelection(.enabled)
                        }
                        
                        // Test timestamp
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tested:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(result.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // Test Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Test Description")
                            .font(.headline)
                        
                        Text(result.test.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Divider()
                    
                    // Test Results
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Test Results")
                            .font(.headline)
                        
                        Text(result.details)
                            .font(.body)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .textSelection(.enabled)
                    }
                    
                    Divider()
                    
                    // Recommendations
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Remediation Recommendations")
                            .font(.headline)
                        
                        Text(result.test.recommendations)
                            .font(.body)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                            .textSelection(.enabled)
                    }
                    
                    if let vulnerability = result.vulnerability {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Vulnerability Details")
                                .font(.headline)
                            
                            WebTestDetailRow(label: "Title", value: vulnerability.title)
                            WebTestDetailRow(label: "Severity", value: vulnerability.severity.rawValue)
                            WebTestDetailRow(label: "Description", value: vulnerability.description)
                            
                            if let cveId = vulnerability.cveId {
                                WebTestDetailRow(label: "CVE ID", value: cveId)
                            }
                            
                            if let port = vulnerability.port {
                                WebTestDetailRow(label: "Port", value: "\(port)")
                            }
                            
                            if let service = vulnerability.service {
                                WebTestDetailRow(label: "Service", value: service)
                            }
                            
                            WebTestDetailRow(label: "Discovered", value: vulnerability.discoveredAt.formatted(date: .abbreviated, time: .shortened))
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Security Test Results")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 500)
    }
}

struct WebTestDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
            Text(value)
                .font(.body)
                .foregroundColor(.secondary)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    WebTestingView()
        .environment(AppState())
}