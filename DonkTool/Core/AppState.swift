//
//  AppState.swift
//  DonkTool
//
//  Core application state management
//

import Foundation
import SwiftUI

// MARK: - Supporting Models (only those not in Models.swift)

struct NetworkPortScanResult: Identifiable, Hashable {
    let id = UUID()
    let port: Int
    let isOpen: Bool
    let service: String?
    let version: String?
    let banner: String?
    let riskLevel: RiskLevel
    let attackVectors: [NetworkAttackVector]
    let scanTime: Date = Date()
    
    enum RiskLevel: String, Hashable {
        case none, low, medium, high
        
        var color: Color {
            switch self {
            case .none: return .gray
            case .low: return .green
            case .medium: return .orange
            case .high: return .red
            }
        }
    }
}

struct WebScanResult: Identifiable, Hashable {
    let id = UUID()
    let type: String
    let description: String
    let url: String
    let severity: Severity
    let details: [String] // Detailed findings like directory names, vulnerabilities
    let timestamp: Date
    let fullOutput: [String] // Complete console output from the tool
    
    init(type: String, description: String, url: String, severity: Severity, details: [String], timestamp: Date, fullOutput: [String] = []) {
        self.type = type
        self.description = description
        self.url = url
        self.severity = severity
        self.details = details
        self.timestamp = timestamp
        self.fullOutput = fullOutput
    }
    
    enum Severity: String, Hashable {
        case informational, low, medium, high, critical
        
        var color: Color {
            switch self {
            case .informational: return .blue
            case .low: return .green
            case .medium: return .orange
            case .high: return .red
            case .critical: return .red
            }
        }
    }
}

struct NetworkAttackVector: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let description: String
    let severity: Severity
    let tools: [String]
    let commands: [String]
    
    enum Severity: String, Hashable {
        case low, medium, high
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .orange
            case .high: return .red
            }
        }
    }
}

// MARK: - AppState

@Observable
class AppState {
    var currentTab: MainTab = .dashboard
    var isScanning: Bool = false
    var lastScanResults: [ScanResult] = []
    var cveDatabase = CVEDatabase()
    var targets: [Target] = []
    var selectedTarget: String?
    var attackFramework = AttackFramework()
    
    // Integration components
    var integrationEngine = IntegrationEngine.shared
    var credentialVault = CredentialVault.shared
    var evidenceManager = EvidenceManager.shared
    
    // Network Scanning
    var isNetworkScanning: Bool = false
    var currentNetworkTarget: String = ""
    var networkScanProgress: Double = 0.0
    var networkScanResults: [NetworkPortScanResult] = []

    // Web Scanning
    var isWebScanning: Bool = false
    var currentWebTarget: String = ""
    var webScanProgress: Double = 0.0
    var webScanResults: [WebScanResult] = []
    var currentWebTestName: String = ""
    private var webScanTask: Task<Void, Never>?
    
    // Professional Bluetooth Security Testing
    var isBluetoothScanning: Bool = false
    var bluetoothScanProgress: Double = 0.0
    var bluetoothFramework = MacOSBluetoothSecurityFramework()
    var bluetoothVulnerabilities: [MacOSBluetoothVulnerability] = []
    var selectedBluetoothDevice: MacOSBluetoothDevice?
    
    // Advanced Bluetooth Shell with Live CVE Integration
    var bluetoothShellActive = false
    var currentBluetoothTarget: String = ""
    var liveCVEDatabase = LiveBluetoothCVEDatabase.shared
    var bluetoothExploitEngine: RealBluetoothExploitEngine?
    var bluetoothShell: BluetoothShell?
    var recentExploitResults: [RealExploitResult] = []
    
    // SearchSploit Integration
    var searchSploitManager = SearchSploitManager()
    var lastExploitSearch: [ExploitEntry] = []
    var isSearchingExploits = false
    
    // Real-time verbose output
    var currentToolOutput: [String] = []
    var currentToolCommand: String = ""
    var isVerboseMode: Bool = true
    var toolExecutionStartTime: Date?
    var toolExecutionStatus: String = ""
    
    // Active scanning state
    var activeScans: [String: String] = [:]
    var allVulnerabilities: [Vulnerability] = []
    
    // Helper method for updating verbose output
    @MainActor
    private func updateVerboseOutput(_ message: String) {
        if isVerboseMode {
            currentToolOutput.append(message)
        }
    }
    var selectedScanResult: ScanResult?
    var selectedTargetDetails: Target?
    var vulnerabilities: [Vulnerability] = []
    var selectedVulnerability: Vulnerability?
    var currentView: AppView = .home
    
    // MARK: - Computed Properties
    var count: Int {
        return cveDatabase.cves.count
    }
    
    enum MainTab: CaseIterable, Hashable {
        case dashboard
        case vulnerabilityDatabase
        case networkScanner
        case webTesting
        case packetSniffer
        case bluetoothSecurity
        case dosStressTesting
        case metasploitConsole
        case osintDashboard
        case activeAttacks
        case reporting
        case scriptLoader
        case settings
        
        var title: String {
            switch self {
            case .dashboard: return "Dashboard"
            case .vulnerabilityDatabase: return "Vulnerability Database"
            case .networkScanner: return "Network Scanner"
            case .webTesting: return "Web Testing"
            case .packetSniffer: return "Packet Sniffer"
            case .bluetoothSecurity: return "Bluetooth Security"
            case .dosStressTesting: return "DoS/Stress Testing"
            case .metasploitConsole: return "Metasploit Console"
            case .osintDashboard: return "OSINT Dashboard"
            case .activeAttacks: return "Active Attacks"
            case .reporting: return "Reporting"
            case .scriptLoader: return "Script Loader"
            case .settings: return "Settings"
            }
        }
        
        var systemImage: String {
            switch self {
            case .dashboard: return "gauge"
            case .vulnerabilityDatabase: return "shield.checkerboard"
            case .networkScanner: return "network"
            case .webTesting: return "globe"
            case .packetSniffer: return "point.3.connected.trianglepath.dotted"
            case .bluetoothSecurity: return "antenna.radiowaves.left.and.right"
            case .dosStressTesting: return "exclamationmark.triangle.fill"
            case .metasploitConsole: return "terminal.fill"
            case .osintDashboard: return "binoculars.fill"
            case .activeAttacks: return "bolt.badge.clock"
            case .reporting: return "doc.text"
            case .scriptLoader: return "doc.text.fill"
            case .settings: return "gear"
            }
        }
    }
    
    enum AppView: Hashable {
        case home
        case targetDetails
        case vulnerabilityDetails
    }
    
    init() {
        // Initialize Bluetooth components
        bluetoothShell = BluetoothShell()
        bluetoothExploitEngine = RealBluetoothExploitEngine()
        
        // Start CVE database update in background
        Task {
            await liveCVEDatabase.updateCVEDatabase()
        }
    }
    
    func addTarget(_ target: Target) {
        targets.append(target)
    }
    
    func removeTarget(_ target: Target) {
        targets.removeAll { $0.id == target.id }
    }
    
    // Network Scan Methods
    func startNetworkScan(target: String, portRange: String) {
        isNetworkScanning = true
        currentNetworkTarget = target
        // Mock scanning logic
    }
    
    func stopNetworkScan() {
        isNetworkScanning = false
        currentNetworkTarget = ""
    }
    
    // Web Scan Methods
    func startWebScan(targetURL: String, selectedTools: [String] = []) {
        isWebScanning = true
        currentWebTarget = targetURL
        webScanProgress = 0.0
        webScanResults.removeAll()
        
        // Execute real web vulnerability tests
        Task {
            await executeRealWebScanning(targetURL: targetURL, selectedTools: selectedTools)
        }
    }
    
    func stopWebScan() {
        isWebScanning = false
        currentWebTarget = ""
    }
    
    // Bluetooth Scan Methods
    // Professional Bluetooth Security Testing Methods
    func startBluetoothScan(mode: DiscoveryMode) {
        print("🚀 Starting professional Bluetooth security assessment - Mode: \(mode.rawValue)")
        
        isBluetoothScanning = true
        bluetoothScanProgress = 0.0
        bluetoothVulnerabilities.removeAll()
        
        Task {
            // Update CVE database first
            await bluetoothFramework.updateCVEDatabase()
            
            // Set up real-time progress monitoring
            let progressTask = Task {
                while isBluetoothScanning {
                    await MainActor.run {
                        self.bluetoothScanProgress = self.bluetoothFramework.scanProgress
                        // Update vulnerabilities in real-time
                        self.bluetoothVulnerabilities = self.bluetoothFramework.vulnerabilityFindings
                        
                        // Integrate Bluetooth vulnerabilities with main targets
                        self.integrateBluetoothVulnerabilities()
                    }
                    try? await Task.sleep(nanoseconds: 500_000_000) // Update every 0.5 seconds
                }
            }
            
            // Start the professional security scan
            await bluetoothFramework.startDiscovery(mode: mode)
            
            progressTask.cancel()
            await MainActor.run {
                self.isBluetoothScanning = false
                self.bluetoothScanProgress = 1.0
                self.bluetoothVulnerabilities = self.bluetoothFramework.vulnerabilityFindings
                
                // Final integration of vulnerabilities
                self.integrateBluetoothVulnerabilities()
                
                print("✅ Professional Bluetooth security assessment completed")
                print("📊 Results: \(self.bluetoothFramework.discoveredDevices.count) devices, \(self.bluetoothVulnerabilities.count) vulnerabilities")
            }
        }
    }
    
    func stopBluetoothScan() {
        isBluetoothScanning = false
        bluetoothScanProgress = 0.0
        print("🛑 Stopping Bluetooth security assessment")
    }
    
    // Integration with main DonkTool vulnerability tracking
    private func integrateBluetoothVulnerabilities() {
        for btVuln in bluetoothVulnerabilities {
            // Convert Bluetooth vulnerability to main Vulnerability model
            let vulnerability = Vulnerability(
                cveId: btVuln.cveId,
                title: btVuln.title,
                description: btVuln.description,
                severity: btVuln.severity,
                port: nil,
                service: "Bluetooth",
                discoveredAt: btVuln.discoveredAt
            )
            
            // Find or create target for this Bluetooth device
            let deviceIdentifier = btVuln.deviceAddress
            
            if let existingTargetIndex = targets.firstIndex(where: { $0.ipAddress == deviceIdentifier }) {
                // Add to existing target
                if !targets[existingTargetIndex].vulnerabilities.contains(where: { $0.cveId == vulnerability.cveId }) {
                    targets[existingTargetIndex].vulnerabilities.append(vulnerability)
                }
            } else {
                // Create new target for Bluetooth device
                let newTarget = Target(
                    name: "Bluetooth Device (\(btVuln.deviceAddress))",
                    ipAddress: deviceIdentifier
                )
                targets.append(newTarget)
                // Add vulnerability to the newly created target
                if let newTargetIndex = targets.firstIndex(where: { $0.ipAddress == deviceIdentifier }) {
                    targets[newTargetIndex].vulnerabilities.append(vulnerability)
                }
            }
        }
    }
    
    
    // Medical Device Compliance Assessment
    func assessMedicalDeviceCompliance(_ device: MacOSBluetoothDevice) async -> MedicalDeviceAssessment {
        // Note: Medical device assessment needs to be implemented in macOS framework
        return MedicalDeviceAssessment(
            deviceInfo: MacOSDeviceInfo(
                name: device.name ?? "Unknown",
                address: device.address,
                manufacturer: device.manufacturerName,
                deviceClass: device.deviceClass
            ),
            complianceResults: [],
            riskAssessment: MacOSRiskAssessment(
                level: .low,
                factors: ["Basic assessment completed"],
                mitigations: ["Update device firmware", "Review security settings"]
            ),
            recommendations: ["Update device firmware", "Review security settings"]
        )
    }
    
    // Professional Bluetooth Exploit Execution
    func executeBluetoothExploit(_ vulnerability: MacOSBluetoothVulnerability) async -> ExploitResult {
        print("⚠️  Executing authorized Bluetooth exploit: \(vulnerability.title)")
        return await bluetoothFramework.performVulnerabilityExploit(vulnerability)
    }
    
    // Real web vulnerability scanning implementation
    private func executeRealWebScanning(targetURL: String, selectedTools: [String]) async {
        let allWebTests = [
            ("SQL Injection", { await self.executeRealSQLMapTest(targetURL: targetURL) }),
            ("Web Vulnerability Scan", { await self.executeRealNiktoTest(targetURL: targetURL) }),
            ("Nuclei Template Scan", { await self.executeNucleiScan(targetURL: targetURL) }),
            ("Directory Enumeration", { await self.executeRealDirectoryTest(targetURL: targetURL) }),
            ("Advanced Directory Fuzzing", { await self.executeFeroxbusterScan(targetURL: targetURL) }),
            ("XSS Detection", { await self.executeXSSStrikeScan(targetURL: targetURL) }),
            ("OWASP ZAP Scan", { await self.executeZAPScan(targetURL: targetURL) }),
            ("HTTP/HTTPS Analysis", { await self.executeHTTPxScan(targetURL: targetURL) }),
            ("SSL/TLS Analysis", { await self.executeTestSSLScan(targetURL: targetURL) }),
            ("HTTP Header Security", { await self.executeHTTPHeaderTest(targetURL: targetURL) }),
            ("Basic SSL Check", { await self.executeSSLTest(targetURL: targetURL) })
        ]
        
        // Filter tests based on selected tools
        let webTests = selectedTools.isEmpty ? allWebTests : allWebTests.filter { testName, _ in
            selectedTools.contains(testName)
        }
        
        let totalTests = webTests.count
        print("🔧 DEBUG: Starting web scan with \(totalTests) selected tools: \(selectedTools)")
        
        for (index, (testName, testFunc)) in webTests.enumerated() {
            // Update progress and current test name
            await MainActor.run {
                self.webScanProgress = Double(index) / Double(totalTests)
                self.currentWebTestName = testName
                self.currentToolOutput.removeAll()
                self.toolExecutionStartTime = Date()
                self.toolExecutionStatus = "Starting \(testName)..."
                self.currentToolOutput.append("🔧 Initializing \(testName)")
                self.currentToolOutput.append("📍 Target: \(targetURL)")
                self.currentToolOutput.append("⏰ Started at: \(Date().formatted(date: .omitted, time: .standard))")
            }
            
            // Check if task was cancelled
            if Task.isCancelled {
                print("🛑 DEBUG: Scan cancelled, stopping execution")
                await MainActor.run {
                    self.isWebScanning = false
                    self.currentWebTestName = "Scan cancelled"
                    self.toolExecutionStatus = "Cancelled"
                    self.currentToolOutput.append("❌ Scan cancelled by user")
                }
                return
            }
            
            print("🔍 Starting web test: \(testName)")
            
            // Update status to executing
            await MainActor.run {
                self.toolExecutionStatus = "Executing \(testName)..."
                self.currentToolOutput.append("🚀 Executing security tool...")
            }
            
            // Execute the test with timeout
            let result: WebScanResult?
            do {
                result = try await withTimeout(seconds: 300) { // 5 minute timeout per test
                    await testFunc()
                }
                print("✅ Completed web test: \(testName)")
                
                // Update completion status
                await MainActor.run {
                    let duration = self.toolExecutionStartTime?.timeIntervalSinceNow.magnitude ?? 0
                    self.toolExecutionStatus = "Completed \(testName) in \(String(format: "%.1f", duration))s"
                    self.currentToolOutput.append("✅ Tool execution completed successfully")
                    self.currentToolOutput.append("⏱️ Duration: \(String(format: "%.1f", duration)) seconds")
                    if let result = result {
                        self.currentToolOutput.append("📊 Found \(result.details.count) findings")
                        self.currentToolOutput.append("🔍 Severity: \(result.severity.rawValue)")
                    }
                }
                
            } catch {
                print("⏰ Timeout or error in web test: \(testName) - \(error)")
                await MainActor.run {
                    self.toolExecutionStatus = "Failed - \(testName)"
                    self.currentToolOutput.append("❌ Tool execution failed: \(error.localizedDescription)")
                }
                result = WebScanResult(
                    type: testName,
                    description: "Test timed out or failed: \(error.localizedDescription)",
                    url: targetURL,
                    severity: .informational,
                    details: [],
                    timestamp: Date()
                )
            }
            
            // Add result to UI
            await MainActor.run {
                if let scanResult = result {
                    self.webScanResults.append(scanResult)
                    
                    // Check for credential discoveries and vulnerability findings
                    self.processWebScanResultForIntegration(scanResult, targetURL: targetURL)
                }
            }
            
            // Small delay between tests
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }
        
        // Final check for cancellation
        if Task.isCancelled {
            await MainActor.run {
                self.isWebScanning = false
                self.currentWebTestName = "Scan cancelled"
            }
            return
        }
        
        // Complete the scan
        await MainActor.run {
            self.webScanProgress = 1.0
            self.currentWebTestName = "Scan completed"
            self.isWebScanning = false
            self.webScanTask = nil
        }
    }
    
    // MARK: - Integration Processing
    
    private func processWebScanResultForIntegration(_ result: WebScanResult, targetURL: String) {
        // Extract target information
        guard let url = URL(string: targetURL) else { return }
        let target = url.host ?? targetURL
        let port = url.port ?? (url.scheme == "https" ? 443 : 80)
        
        // Check for credential-related findings
        let credentialIndicators = [
            "username", "password", "login", "admin", "default credentials",
            "weak password", "credential", "auth", "authentication"
        ]
        
        for detail in result.details {
            let lowerDetail = detail.lowercased()
            
            // Look for credential patterns
            if credentialIndicators.contains(where: { lowerDetail.contains($0) }) {
                // Extract potential credentials using regex patterns
                extractAndNotifyCredentials(from: detail, target: target, port: port, source: result.type)
            }
        }
        
        // Check for vulnerability notifications
        if result.severity == .high || result.severity == .critical {
            NotificationCenter.default.post(
                name: .vulnerabilityFound,
                object: nil,
                userInfo: [
                    "target": target,
                    "port": port,
                    "type": result.type,
                    "severity": result.severity.rawValue,
                    "description": result.description,
                    "source": "web_scanner"
                ]
            )
        }
    }
    
    private func extractAndNotifyCredentials(from detail: String, target: String, port: Int, source: String) {
        // Common credential patterns
        let patterns = [
            // username:password format
            #"(\w+):(\w+)"#,
            // admin/password format  
            #"(\w+)/(\w+)"#,
            // user="admin" pass="password" format
            #"user[=\"']([^\"']+)[\"'].*pass[=\"']([^\"']+)[\"']"#,
            // Default credentials mentions
            #"default.*(\w+).*(\w+)"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let matches = regex.matches(in: detail, options: [], range: NSRange(detail.startIndex..., in: detail))
                
                for match in matches {
                    guard match.numberOfRanges >= 3 else { continue }
                    
                    let usernameRange = Range(match.range(at: 1), in: detail)
                    let passwordRange = Range(match.range(at: 2), in: detail)
                    
                    if let usernameRange = usernameRange, let passwordRange = passwordRange {
                        let username = String(detail[usernameRange])
                        let password = String(detail[passwordRange])
                        
                        // Filter out obviously false positives
                        guard !username.isEmpty && !password.isEmpty &&
                              username.count > 2 && password.count > 2 &&
                              username != password else { continue }
                        
                        let credentialDiscovery = CredentialDiscovery(
                            username: username,
                            password: password,
                            service: "Web",
                            target: target,
                            port: port,
                            source: "web_scanner_\(source.lowercased())",
                            confidence: determineCredentialConfidence(username: username, password: password, context: detail),
                            timestamp: Date()
                        )
                        
                        NotificationCenter.default.post(
                            name: .credentialsDiscovered,
                            object: credentialDiscovery
                        )
                        
                        print("🔐 Integration: Discovered credentials \(username):\(password) from \(source)")
                    }
                }
            }
        }
    }
    
    private func determineCredentialConfidence(username: String, password: String, context: String) -> CredentialConfidence {
        let lowConfidenceKeywords = ["test", "demo", "example", "sample"]
        let highConfidenceKeywords = ["admin", "root", "administrator", "default"]
        
        let contextLower = context.lowercased()
        let usernameLower = username.lowercased()
        let passwordLower = password.lowercased()
        
        // High confidence indicators
        if highConfidenceKeywords.contains(usernameLower) ||
           contextLower.contains("default") ||
           contextLower.contains("credentials found") {
            return .high
        }
        
        // Low confidence indicators  
        if lowConfidenceKeywords.contains(usernameLower) ||
           lowConfidenceKeywords.contains(passwordLower) ||
           username == password {
            return .low
        }
        
        return .medium
    }
    
    // Real tool implementations for web testing
    private func executeRealSQLMapTest(targetURL: String) async -> WebScanResult? {
        let result = await executeSQLMapCommand(targetURL: targetURL)
        
        if !result.vulnerabilities.isEmpty {
            return WebScanResult(
                type: "SQL Injection",
                description: "SQLMap detected SQL injection vulnerability: \(result.vulnerabilities.first!)",
                url: targetURL,
                severity: .high,
                details: result.vulnerabilities,
                timestamp: Date(),
                fullOutput: result.output
            )
        } else if result.output.contains(where: { 
            $0.contains("testing completed") || 
            $0.contains("not vulnerable") || 
            $0.contains("all tested parameters do not appear to be injectable") ||
            $0.contains("done") ||
            $0.contains("tested") 
        }) {
            return WebScanResult(
                type: "SQL Injection",
                description: "No SQL injection vulnerabilities detected",
                url: targetURL,
                severity: .informational,
                details: ["Scan completed successfully", "No injectable parameters found"],
                timestamp: Date(),
                fullOutput: result.output
            )
        } else if result.output.isEmpty {
            return WebScanResult(
                type: "SQL Injection",
                description: "SQLMap failed to execute or no output received",
                url: targetURL,
                severity: .low,
                details: ["Check if SQLMap is properly installed", "Verify target URL is accessible"],
                timestamp: Date(),
                fullOutput: ["Error: No output from SQLMap execution"]
            )
        } else {
            // SQLMap ran but results are inconclusive
            return WebScanResult(
                type: "SQL Injection",
                description: "SQLMap scan completed with inconclusive results",
                url: targetURL,
                severity: .informational,
                details: ["Scan completed but no clear vulnerability status", "Check full output for details"],
                timestamp: Date(),
                fullOutput: result.output
            )
        }
    }
    
    private func executeRealNiktoTest(targetURL: String) async -> WebScanResult? {
        let result = await executeNiktoCommand(targetURL: targetURL)
        
        if !result.vulnerabilities.isEmpty {
            return WebScanResult(
                type: "Web Vulnerability",
                description: "Nikto found vulnerabilities: \(result.vulnerabilities.first!)",
                url: targetURL,
                severity: .medium,
                details: result.vulnerabilities,
                timestamp: Date(),
                fullOutput: result.output
            )
        } else if result.output.contains(where: { $0.contains("scan complete") || $0.contains("tested") }) {
            return WebScanResult(
                type: "Web Vulnerability Scan",
                description: "Nikto scan completed - no major vulnerabilities found",
                url: targetURL,
                severity: .informational,
                details: ["Scan completed successfully"],
                timestamp: Date(),
                fullOutput: result.output
            )
        } else {
            return WebScanResult(
                type: "Web Vulnerability Scan",
                description: "Nikto scan completed with inconclusive results",
                url: targetURL,
                severity: .informational,
                details: ["Check full output for details"],
                timestamp: Date(),
                fullOutput: result.output
            )
        }
    }
    
    private func executeRealDirectoryTest(targetURL: String) async -> WebScanResult? {
        let result = await executeDirectoryEnumerationCommand(targetURL: targetURL)
        
        if !result.files.isEmpty {
            return WebScanResult(
                type: "Directory Enumeration",
                description: "Found \(result.files.count) accessible directories/files: \(result.files.prefix(3).joined(separator: ", "))\(result.files.count > 3 ? "..." : "")",
                url: targetURL,
                severity: .medium,
                details: result.files,
                timestamp: Date()
            )
        } else if result.success {
            return WebScanResult(
                type: "Directory Enumeration",
                description: "Directory scan completed - no accessible directories found",
                url: targetURL,
                severity: .informational,
                details: [],
                timestamp: Date()
            )
        }
        
        return nil
    }
    
    private func executeHTTPHeaderTest(targetURL: String) async -> WebScanResult? {
        // Add console output for transparency
        await updateVerboseOutput("🔍 Starting HTTP Header Security Analysis...")
        await updateVerboseOutput("Target: \(targetURL)")
        await updateVerboseOutput("")
        
        let headers = await getHTTPHeaders(targetURL: targetURL)
        
        // Show discovered headers in console
        await updateVerboseOutput("📋 Discovered HTTP Headers:")
        if headers.isEmpty {
            await updateVerboseOutput("  ⚠️ No headers could be retrieved")
        } else {
            for header in headers.sorted() {
                await updateVerboseOutput("  • \(header)")
            }
        }
        await updateVerboseOutput("")
        
        let requiredHeaders = ["Strict-Transport-Security", "Content-Security-Policy", "X-Frame-Options", "X-Content-Type-Options"]
        let missingHeaders = requiredHeaders.filter { requiredHeader in
            !headers.contains { $0.lowercased().contains(requiredHeader.lowercased()) }
        }
        
        // Show security analysis in console
        await updateVerboseOutput("🔐 Security Header Analysis:")
        for header in requiredHeaders {
            let isPresent = headers.contains { $0.lowercased().contains(header.lowercased()) }
            let status = isPresent ? "✅ Present" : "❌ Missing"
            await updateVerboseOutput("  \(status): \(header)")
        }
        await updateVerboseOutput("")
        
        if !missingHeaders.isEmpty {
            await updateVerboseOutput("⚠️ Security Issues Found:")
            for header in missingHeaders {
                await updateVerboseOutput("  • Missing: \(header)")
            }
            await updateVerboseOutput("💡 Recommendation: Add missing security headers to improve protection")
            
            return WebScanResult(
                type: "HTTP Header Security",
                description: "Missing security headers: \(missingHeaders.joined(separator: ", "))",
                url: targetURL,
                severity: .medium,
                details: missingHeaders,
                timestamp: Date()
            )
        } else {
            await updateVerboseOutput("✅ All required security headers are present")
            await updateVerboseOutput("🛡️ Website has good header security configuration")
            
            return WebScanResult(
                type: "HTTP Header Security",
                description: "All required security headers are present",
                url: targetURL,
                severity: .informational,
                details: [],
                timestamp: Date()
            )
        }
    }
    
    private func executeSSLTest(targetURL: String) async -> WebScanResult? {
        // Add console output for transparency
        await updateVerboseOutput("🔒 Starting Basic SSL/TLS Security Check...")
        await updateVerboseOutput("Target: \(targetURL)")
        await updateVerboseOutput("")
        
        if !targetURL.hasPrefix("https://") {
            await updateVerboseOutput("⚠️ Protocol Analysis:")
            await updateVerboseOutput("  • Protocol: HTTP (insecure)")
            await updateVerboseOutput("  • Encryption: None")
            await updateVerboseOutput("  • Data Protection: Plaintext transmission")
            await updateVerboseOutput("")
            await updateVerboseOutput("❌ CRITICAL: Website not using HTTPS encryption")
            await updateVerboseOutput("💡 Recommendation: Implement SSL/TLS certificate and redirect HTTP to HTTPS")
            
            return WebScanResult(
                type: "SSL/TLS Configuration",
                description: "Website not using HTTPS encryption",
                url: targetURL,
                severity: .high,
                details: ["No HTTPS encryption", "Data transmitted in plaintext"],
                timestamp: Date()
            )
        }
        
        // Basic SSL check
        guard let url = URL(string: targetURL) else { 
            await updateVerboseOutput("❌ Invalid URL format for SSL testing")
            return nil 
        }
        
        await updateVerboseOutput("🔍 Attempting HTTPS connection...")
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                await updateVerboseOutput("✅ SSL/TLS Connection Analysis:")
                await updateVerboseOutput("  • HTTPS Connection: Successful")
                await updateVerboseOutput("  • Status Code: \(httpResponse.statusCode)")
                await updateVerboseOutput("  • SSL Certificate: Valid (basic check)")
                await updateVerboseOutput("  • Protocol: HTTPS")
                
                // Check for security headers
                let securityHeaders = httpResponse.allHeaderFields.keys.compactMap { $0 as? String }
                    .filter { header in
                        let lowerHeader = header.lowercased()
                        return lowerHeader.contains("strict-transport-security") ||
                               lowerHeader.contains("content-security-policy") ||
                               lowerHeader.contains("x-frame-options")
                    }
                
                if !securityHeaders.isEmpty {
                    await updateVerboseOutput("  • Security Headers: Present (\(securityHeaders.count) found)")
                } else {
                    await updateVerboseOutput("  • Security Headers: Missing or limited")
                }
                
                await updateVerboseOutput("")
                await updateVerboseOutput("✅ Basic SSL check passed - connection secured")
                await updateVerboseOutput("💡 Note: For comprehensive SSL analysis, use TestSSL.sh tool")
                
                return WebScanResult(
                    type: "SSL/TLS Configuration",
                    description: "HTTPS connection successful - basic SSL check passed",
                    url: targetURL,
                    severity: .informational,
                    details: ["SSL certificate valid", "HTTPS connection established"],
                    timestamp: Date()
                )
            }
        } catch {
            await updateVerboseOutput("❌ SSL/TLS Connection Failed:")
            await updateVerboseOutput("  • Error: \(error.localizedDescription)")
            await updateVerboseOutput("  • Possible causes:")
            await updateVerboseOutput("    - Invalid SSL certificate")
            await updateVerboseOutput("    - Expired certificate")
            await updateVerboseOutput("    - Self-signed certificate")
            await updateVerboseOutput("    - Network connectivity issues")
            await updateVerboseOutput("")
            await updateVerboseOutput("💡 Recommendation: Check certificate validity and configuration")
            
            return WebScanResult(
                type: "SSL/TLS Configuration",
                description: "SSL/TLS connection failed: \(error.localizedDescription)",
                url: targetURL,
                severity: .high,
                details: ["Connection error: \(error.localizedDescription)"],
                timestamp: Date()
            )
        }
        
        return nil
    }
    
    // Command execution methods
    private func executeSQLMapCommand(targetURL: String) async -> (output: [String], vulnerabilities: [String]) {
        var output: [String] = []
        var vulnerabilities: [String] = []
        
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        
        // Check if SQLMap is installed
        guard let sqlmapPath = findWebToolPath("sqlmap") else {
            output.append("❌ SQLMap not found. Install with: brew install sqlmap")
            await updateVerboseOutput("❌ SQLMap not found. Install with: brew install sqlmap")
            return (output, vulnerabilities)
        }
        
        // Set up proper environment for Python execution
        var environment = ProcessInfo.processInfo.environment
        
        // Add common paths to ensure Python can be found
        let currentPath = environment["PATH"] ?? ""
        let additionalPaths = [
            "/opt/homebrew/bin",
            "/opt/homebrew/opt/python@3.13/bin",
            "/usr/local/bin",
            "/usr/bin",
            "/bin"
        ]
        let newPath = (additionalPaths + [currentPath]).joined(separator: ":")
        environment["PATH"] = newPath
        
        // Determine the best way to execute SQLMap
        let pythonPaths = [
            "/opt/homebrew/opt/python@3.13/bin/python3.13",
            "/opt/homebrew/bin/python3",
            "/usr/local/bin/python3",
            "/usr/bin/python3"
        ]
        
        var pythonPath: String? = nil
        for path in pythonPaths {
            if FileManager.default.fileExists(atPath: path) {
                pythonPath = path
                break
            }
        }
        
        if let pythonPath = pythonPath {
            // Run with explicit Python interpreter for better compatibility
            process.executableURL = URL(fileURLWithPath: pythonPath)
            process.arguments = [
                sqlmapPath,
                "-u", targetURL,
                "--batch",  // Non-interactive mode
                "--level=1",  // Test level
                "--risk=1",   // Risk level
                "--timeout=30",  // Timeout per request
                "--retries=1"    // Number of retries
            ]
        } else {
            // Fallback to direct execution
            process.executableURL = URL(fileURLWithPath: sqlmapPath)
            process.arguments = [
                "-u", targetURL,
                "--batch",  // Non-interactive mode
                "--level=1",  // Test level
                "--risk=1",   // Risk level
                "--timeout=30",  // Timeout per request
                "--retries=1"    // Number of retries
            ]
        }
        
        process.environment = environment
        
        // Update verbose output with command details
        let commandDescription = pythonPath != nil ? 
            "\(pythonPath!) \(sqlmapPath) -u \(targetURL) --batch --level=1 --risk=1 --timeout=30 --retries=1" :
            "\(sqlmapPath) -u \(targetURL) --batch --level=1 --risk=1 --timeout=30 --retries=1"
        await updateVerboseOutput("🔧 SQLMap Command: \(commandDescription)")
        await updateVerboseOutput("🚀 Starting SQLMap SQL injection detection...")
        await updateVerboseOutput("📍 Target: \(targetURL)")
        await updateVerboseOutput("⚙️ Parameters: Level=1, Risk=1, Timeout=30s")
        
        output.append("🚀 Starting SQLMap scan...")
        output.append("Target: \(targetURL)")
        
        do {
            try process.run()
            await updateVerboseOutput("$ \(commandDescription)")
            await updateVerboseOutput("")
            
            // Set a timeout for the process (5 minutes)
            let timeoutTask = Task {
                try await Task.sleep(nanoseconds: 300_000_000_000) // 5 minutes
                if process.isRunning {
                    process.terminate()
                    await updateVerboseOutput("⏰ SQLMap scan timed out after 5 minutes")
                }
            }
            
            defer {
                timeoutTask.cancel()
            }
            
            // Stream real-time output using async approach
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    let fileHandle = pipe.fileHandleForReading
                    var buffer = ""
                    
                    while process.isRunning {
                        let availableData = fileHandle.availableData
                        if !availableData.isEmpty {
                            if let newOutput = String(data: availableData, encoding: .utf8) {
                                buffer += newOutput
                                
                                // Process complete lines
                                let lines = buffer.components(separatedBy: .newlines)
                                let completeLines = lines.dropLast() // Last element might be incomplete
                                buffer = String(lines.last ?? "") // Keep incomplete line in buffer
                                
                                for line in completeLines {
                                    let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                                    if !trimmedLine.isEmpty {
                                        await MainActor.run {
                                            Task {
                                                await self.updateVerboseOutput(trimmedLine)
                                            }
                                        }
                                        output.append(trimmedLine)
                                        
                                        // Check for vulnerabilities in real-time
                                        let lowerLine = trimmedLine.lowercased()
                                        if (lowerLine.contains("vulnerable") && !lowerLine.contains("not vulnerable")) ||
                                           (lowerLine.contains("injection") && lowerLine.contains("found")) {
                                            vulnerabilities.append(trimmedLine)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Small delay to prevent excessive CPU usage
                        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                    }
                    
                    // Read any remaining data
                    let remainingData = fileHandle.readDataToEndOfFile()
                    if !remainingData.isEmpty {
                        if let finalOutput = String(data: remainingData, encoding: .utf8) {
                            buffer += finalOutput
                            
                            // Process any remaining lines
                            let finalLines = buffer.components(separatedBy: .newlines)
                            for line in finalLines {
                                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !trimmedLine.isEmpty {
                                    await MainActor.run {
                                        Task {
                                            await self.updateVerboseOutput(trimmedLine)
                                        }
                                    }
                                    output.append(trimmedLine)
                                    
                                    // Check for vulnerabilities in final output
                                    let lowerLine = trimmedLine.lowercased()
                                    if (lowerLine.contains("vulnerable") && !lowerLine.contains("not vulnerable")) ||
                                       (lowerLine.contains("injection") && lowerLine.contains("found")) {
                                        vulnerabilities.append(trimmedLine)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Wait for process to complete
            process.waitUntilExit()
            
            await updateVerboseOutput("")
            await updateVerboseOutput("SQLMap scan completed with exit code: \(process.terminationStatus)")
            output.append("✅ SQLMap scan completed")
            
        } catch {
            output.append("❌ Error executing SQLMap: \(error.localizedDescription)")
        }
        
        return (output, vulnerabilities)
    }
    
    private func executeNiktoCommand(targetURL: String) async -> (output: [String], vulnerabilities: [String]) {
        var output: [String] = []
        var vulnerabilities: [String] = []
        
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        
        // Check if Nikto is installed
        guard let niktoPath = findWebToolPath("nikto") else {
            output.append("❌ Nikto not found. Install with: brew install nikto")
            await updateVerboseOutput("❌ Nikto not found. Install with: brew install nikto")
            return (output, vulnerabilities)
        }
        
        let commandArgs = [
            "-h", targetURL,
            "-C", "all",  // Check all vulnerability classes
            "-nointeractive",  // Don't prompt for input
            "-timeout", "30",  // Request timeout
            "-maxtime", "300"  // Maximum scan time (5 minutes)
        ]
        
        process.executableURL = URL(fileURLWithPath: niktoPath)
        process.arguments = commandArgs
        
        // Update verbose output with command details
        await updateVerboseOutput("🔧 Nikto Command: \(niktoPath) \(commandArgs.joined(separator: " "))")
        await updateVerboseOutput("🚀 Starting Nikto web vulnerability scan...")
        await updateVerboseOutput("📍 Target: \(targetURL)")
        await updateVerboseOutput("⚙️ Parameters: All checks, 30s timeout, 5min max time")
        
        output.append("🚀 Starting Nikto scan...")
        output.append("Target: \(targetURL)")
        
        do {
            try process.run()
            await updateVerboseOutput("$ \(niktoPath) \(commandArgs.joined(separator: " "))")
            await updateVerboseOutput("")
            
            // Set a timeout for the process (5 minutes)
            let timeoutTask = Task {
                try await Task.sleep(nanoseconds: 300_000_000_000) // 5 minutes
                if process.isRunning {
                    process.terminate()
                    await updateVerboseOutput("⏰ Nikto scan timed out after 5 minutes")
                }
            }
            
            defer {
                timeoutTask.cancel()
            }
            
            // Stream real-time output using async approach
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    let fileHandle = pipe.fileHandleForReading
                    var buffer = ""
                    
                    while process.isRunning {
                        let availableData = fileHandle.availableData
                        if !availableData.isEmpty {
                            if let newOutput = String(data: availableData, encoding: .utf8) {
                                buffer += newOutput
                                
                                // Process complete lines
                                let lines = buffer.components(separatedBy: .newlines)
                                let completeLines = lines.dropLast() // Last element might be incomplete
                                buffer = String(lines.last ?? "") // Keep incomplete line in buffer
                                
                                for line in completeLines {
                                    let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                                    if !trimmedLine.isEmpty {
                                        await MainActor.run {
                                            Task {
                                                await self.updateVerboseOutput(trimmedLine)
                                            }
                                        }
                                        output.append(trimmedLine)
                                        
                                        // Check for vulnerabilities in real-time
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
                            }
                        }
                        
                        // Small delay to prevent excessive CPU usage
                        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                    }
                    
                    // Read any remaining data
                    let remainingData = fileHandle.readDataToEndOfFile()
                    if !remainingData.isEmpty {
                        if let finalOutput = String(data: remainingData, encoding: .utf8) {
                            buffer += finalOutput
                            
                            // Process any remaining lines
                            let finalLines = buffer.components(separatedBy: .newlines)
                            for line in finalLines {
                                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !trimmedLine.isEmpty {
                                    await MainActor.run {
                                        Task {
                                            await self.updateVerboseOutput(trimmedLine)
                                        }
                                    }
                                    output.append(trimmedLine)
                                    
                                    // Check for vulnerabilities in final output
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
                        }
                    }
                }
            }
            
            // Wait for process to complete
            process.waitUntilExit()
            
            await updateVerboseOutput("")
            await updateVerboseOutput("Nikto scan completed with exit code: \(process.terminationStatus)")
            output.append("✅ Nikto scan completed")
            
        } catch {
            output.append("❌ Error executing Nikto: \(error.localizedDescription)")
        }
        
        return (output, vulnerabilities)
    }
    
    private func executeDirectoryEnumerationCommand(targetURL: String) async -> (output: [String], files: [String], success: Bool) {
        var output: [String] = []
        let files: [String] = []
        
        // Try gobuster first, then dirb as fallback
        if let gobusterPath = findWebToolPath("gobuster") {
            let result = await executeGobusterWeb(targetURL: targetURL, toolPath: gobusterPath)
            return (result.output, result.files, result.success)
        } else if let dirbPath = findWebToolPath("dirb") {
            let result = await executeDirbWeb(targetURL: targetURL, toolPath: dirbPath)
            return (result.output, result.files, result.success)
        } else {
            output.append("❌ No directory enumeration tools found. Install with: brew install gobuster dirb")
            return (output, files, false)
        }
    }
    
    private func executeGobusterWeb(targetURL: String, toolPath: String) async -> (output: [String], files: [String], success: Bool) {
        var output: [String] = []
        var files: [String] = []
        
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        process.executableURL = URL(fileURLWithPath: toolPath)
        
        // Create wordlist for web testing
        let wordlist = createWebWordlist()
        
        process.arguments = [
            "dir",
            "-u", targetURL,
            "-w", wordlist,
            "-t", "10",  // 10 threads
            "--timeout", "30s"
        ]
        
        output.append("🚀 Starting Gobuster directory enumeration...")
        output.append("Target: \(targetURL)")
        
        do {
            try process.run()
            await updateVerboseOutput("$ \(toolPath) \(process.arguments?.joined(separator: " ") ?? "")")
            await updateVerboseOutput("")
            
            // Set a timeout
            let timeoutTask = Task {
                try await Task.sleep(nanoseconds: 300_000_000_000) // 5 minutes
                if process.isRunning {
                    process.terminate()
                    await updateVerboseOutput("⏰ Gobuster scan timed out after 5 minutes")
                }
            }
            
            defer {
                timeoutTask.cancel()
            }
            
            // Stream real-time output using async approach
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    let fileHandle = pipe.fileHandleForReading
                    var buffer = ""
                    
                    while process.isRunning {
                        let availableData = fileHandle.availableData
                        if !availableData.isEmpty {
                            if let newOutput = String(data: availableData, encoding: .utf8) {
                                buffer += newOutput
                                
                                // Process complete lines
                                let lines = buffer.components(separatedBy: .newlines)
                                let completeLines = lines.dropLast() // Last element might be incomplete
                                buffer = String(lines.last ?? "") // Keep incomplete line in buffer
                                
                                for line in completeLines {
                                    let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                                    if !trimmedLine.isEmpty {
                                        await MainActor.run {
                                            Task {
                                                await self.updateVerboseOutput(trimmedLine)
                                            }
                                        }
                                        output.append(trimmedLine)
                                        
                                        // Parse gobuster output for found directories/files in real-time
                                        if trimmedLine.contains("(Status: 200)") || trimmedLine.contains("(Status: 301)") || trimmedLine.contains("(Status: 302)") {
                                            // Extract just the path from gobuster output (format: /path (Status: XXX) [Size: XXX])
                                            if let pathMatch = trimmedLine.components(separatedBy: " ").first {
                                                files.append(pathMatch)
                                            } else {
                                                files.append(trimmedLine)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Small delay to prevent excessive CPU usage
                        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                    }
                    
                    // Read any remaining data
                    let remainingData = fileHandle.readDataToEndOfFile()
                    if !remainingData.isEmpty {
                        if let finalOutput = String(data: remainingData, encoding: .utf8) {
                            buffer += finalOutput
                            
                            // Process any remaining lines
                            let finalLines = buffer.components(separatedBy: .newlines)
                            for line in finalLines {
                                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !trimmedLine.isEmpty {
                                    await MainActor.run {
                                        Task {
                                            await self.updateVerboseOutput(trimmedLine)
                                        }
                                    }
                                    output.append(trimmedLine)
                                    
                                    // Parse final output for found directories/files
                                    if trimmedLine.contains("(Status: 200)") || trimmedLine.contains("(Status: 301)") || trimmedLine.contains("(Status: 302)") {
                                        if let pathMatch = trimmedLine.components(separatedBy: " ").first {
                                            files.append(pathMatch)
                                        } else {
                                            files.append(trimmedLine)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Wait for process to complete
            process.waitUntilExit()
            
            await updateVerboseOutput("")
            await updateVerboseOutput("Gobuster scan completed with exit code: \(process.terminationStatus)")
            output.append("✅ Gobuster scan completed")
            
            return (output, files, true)
            
        } catch {
            output.append("❌ Error executing Gobuster: \(error.localizedDescription)")
            return (output, files, false)
        }
    }
    
    private func executeDirbWeb(targetURL: String, toolPath: String) async -> (output: [String], files: [String], success: Bool) {
        var output: [String] = []
        var files: [String] = []
        
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        process.executableURL = URL(fileURLWithPath: toolPath)
        
        let wordlist = createWebWordlist()
        
        process.arguments = [
            targetURL,
            wordlist,
            "-w"  // Don't stop on warning messages
        ]
        
        output.append("🚀 Starting Dirb directory enumeration...")
        output.append("Target: \(targetURL)")
        
        do {
            try process.run()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let outputString = String(data: data, encoding: .utf8) {
                let lines = outputString.components(separatedBy: .newlines)
                output.append(contentsOf: lines.filter { !$0.isEmpty })
                
                // Parse dirb output for found directories/files
                for line in lines {
                    let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmedLine.hasPrefix("+ ") && (trimmedLine.contains("(CODE:200)") || trimmedLine.contains("(CODE:301)")) {
                        files.append(trimmedLine)
                    }
                }
            }
            
            process.waitUntilExit()
            output.append("✅ Dirb scan completed")
            
            return (output, files, true)
            
        } catch {
            output.append("❌ Error executing Dirb: \(error.localizedDescription)")
            return (output, files, false)
        }
    }
    
    private func getHTTPHeaders(targetURL: String) async -> [String] {
        guard let url = URL(string: targetURL) else { return [] }
        
        var request = URLRequest(url: url)
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
    
    private func findWebToolPath(_ toolName: String) -> String? {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        let commonPaths = [
            "/usr/local/bin/\(toolName)",
            "/opt/homebrew/bin/\(toolName)",
            "/usr/bin/\(toolName)",
            "/bin/\(toolName)",
            "\(homeDir)/go/bin/\(toolName)",
            "\(homeDir)/.cargo/bin/\(toolName)",
            "\(homeDir)/.local/bin/\(toolName)"
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
    
    private func createWebWordlist() -> String {
        let tempDir = FileManager.default.temporaryDirectory
        let wordlistPath = tempDir.appendingPathComponent("web_wordlist.txt")
        
        let commonWebPaths = [
            "admin", "administrator", "login", "wp-admin", "phpmyadmin",
            "backup", "config", "test", "dev", "staging", "api",
            "uploads", "images", "css", "js", "assets", "static",
            "robots.txt", "sitemap.xml", ".git", ".svn", "backup.zip",
            "dashboard", "panel", "control", "manager", "system",
            "database", "db", "sql", "mysql", "data", "files",
            "docs", "documentation", "help", "support", "contact"
        ]
        
        let wordlistContent = commonWebPaths.joined(separator: "\n")
        
        do {
            try wordlistContent.write(to: wordlistPath, atomically: true, encoding: .utf8)
            return wordlistPath.path
        } catch {
            return "/dev/null"
        }
    }
    
    // MARK: - Advanced Web Security Tool Implementations
    
    private func executeNucleiScan(targetURL: String) async -> WebScanResult? {
        let result = await executeNucleiCommand(targetURL: targetURL)
        
        if !result.vulnerabilities.isEmpty {
            return WebScanResult(
                type: "Nuclei Vulnerability Scan",
                description: "Found \(result.vulnerabilities.count) vulnerabilities: \(result.vulnerabilities.prefix(3).joined(separator: ", "))",
                url: targetURL,
                severity: .high,
                details: result.vulnerabilities,
                timestamp: Date()
            )
        } else if !result.output.isEmpty {
            return WebScanResult(
                type: "Nuclei Vulnerability Scan", 
                description: "Nuclei scan completed - no critical vulnerabilities found",
                url: targetURL,
                severity: .informational,
                details: [],
                timestamp: Date()
            )
        }
        
        return nil
    }
    
    private func executeFeroxbusterScan(targetURL: String) async -> WebScanResult? {
        let result = await executeFeroxbusterCommand(targetURL: targetURL)
        
        if !result.files.isEmpty {
            return WebScanResult(
                type: "Advanced Directory Fuzzing",
                description: "Feroxbuster found \(result.files.count) directories/files with recursive scanning",
                url: targetURL,
                severity: .medium,
                details: [],
                timestamp: Date()
            )
        } else if result.success {
            return WebScanResult(
                type: "Advanced Directory Fuzzing",
                description: "Feroxbuster recursive scan completed - no accessible paths found",
                url: targetURL,
                severity: .informational,
                details: [],
                timestamp: Date()
            )
        }
        
        return nil
    }
    
    private func executeXSSStrikeScan(targetURL: String) async -> WebScanResult? {
        let result = await executeXSSStrikeCommand(targetURL: targetURL)
        
        if !result.vulnerabilities.isEmpty {
            return WebScanResult(
                type: "XSS Vulnerability Detection",
                description: "XSStrike detected XSS vulnerabilities: \(result.vulnerabilities.first!)",
                url: targetURL,
                severity: .high,
                details: result.vulnerabilities,
                timestamp: Date()
            )
        } else if !result.output.isEmpty && result.output.contains(where: { $0.contains("scan completed") }) {
            return WebScanResult(
                type: "XSS Vulnerability Detection",
                description: "XSStrike scan completed - no XSS vulnerabilities found",
                url: targetURL,
                severity: .informational,
                details: [],
                timestamp: Date()
            )
        }
        
        return nil
    }
    
    private func executeZAPScan(targetURL: String) async -> WebScanResult? {
        let result = await executeZAPCommand(targetURL: targetURL)
        
        if !result.vulnerabilities.isEmpty {
            return WebScanResult(
                type: "OWASP ZAP Comprehensive Scan",
                description: "ZAP found \(result.vulnerabilities.count) security issues including active/passive findings",
                url: targetURL,
                severity: .medium,
                details: [],
                timestamp: Date()
            )
        } else if !result.output.isEmpty {
            return WebScanResult(
                type: "OWASP ZAP Comprehensive Scan",
                description: "ZAP baseline scan completed - no major security issues detected",
                url: targetURL,
                severity: .informational,
                details: [],
                timestamp: Date()
            )
        }
        
        return nil
    }
    
    private func executeHTTPxScan(targetURL: String) async -> WebScanResult? {
        let result = await executeHTTPxCommand(targetURL: targetURL)
        
        if !result.technologies.isEmpty || !result.statusIssues.isEmpty {
            var findings: [String] = []
            if !result.technologies.isEmpty {
                findings.append("Technologies: \(result.technologies.joined(separator: ", "))")
            }
            if !result.statusIssues.isEmpty {
                findings.append("Issues: \(result.statusIssues.joined(separator: ", "))")
            }
            
            return WebScanResult(
                type: "HTTP/HTTPS Analysis",
                description: "HTTPx analysis: \(findings.joined(separator: " | "))",
                url: targetURL,
                severity: result.statusIssues.isEmpty ? .informational : .medium,
                details: findings,
                timestamp: Date()
            )
        }
        
        return nil
    }
    
    private func executeTestSSLScan(targetURL: String) async -> WebScanResult? {
        guard targetURL.hasPrefix("https://") else {
            return WebScanResult(
                type: "SSL/TLS Deep Analysis",
                description: "Target not using HTTPS - SSL/TLS analysis skipped",
                url: targetURL,
                severity: .high,
                details: ["No HTTPS protocol", "SSL/TLS analysis not applicable"],
                timestamp: Date()
            )
        }
        
        let result = await executeTestSSLCommand(targetURL: targetURL)
        
        if !result.vulnerabilities.isEmpty {
            return WebScanResult(
                type: "SSL/TLS Deep Analysis",
                description: "TestSSL found SSL/TLS issues: \(result.vulnerabilities.prefix(2).joined(separator: ", "))",
                url: targetURL,
                severity: .medium,
                details: result.vulnerabilities,
                timestamp: Date()
            )
        } else if !result.output.isEmpty && result.output.contains(where: { $0.contains("Done") }) {
            return WebScanResult(
                type: "SSL/TLS Deep Analysis",
                description: "TestSSL analysis completed - SSL/TLS configuration appears secure",
                url: targetURL,
                severity: .informational,
                details: [],
                timestamp: Date()
            )
        }
        
        return nil
    }
    
    // MARK: - Tool Command Execution Methods
    
    private func executeNucleiCommand(targetURL: String) async -> (output: [String], vulnerabilities: [String]) {
        var output: [String] = []
        var vulnerabilities: [String] = []
        
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        
        guard let nucleiPath = findWebToolPath("nuclei") else {
            output.append("❌ Nuclei not found. Install with: go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest")
            return (output, vulnerabilities)
        }
        
        process.executableURL = URL(fileURLWithPath: nucleiPath)
        process.arguments = [
            "-u", targetURL,
            "-json",        // JSON output for parsing
            "-silent",      // Silent mode
            "-severity", "critical,high,medium",  // Important findings only
            "-timeout", "30",
            "-retries", "1",
            "-rate-limit", "50"  // Conservative rate limiting
        ]
        
        output.append("🚀 Starting Nuclei vulnerability scan with 9000+ templates...")
        output.append("Target: \(targetURL)")
        
        do {
            try process.run()
            
            // Set timeout
            let timeoutTask = Task {
                try await Task.sleep(nanoseconds: 600_000_000_000) // 10 minutes
                if process.isRunning {
                    process.terminate()
                    output.append("⏰ Nuclei scan timed out after 10 minutes")
                }
            }
            
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
            timeoutTask.cancel()
            output.append("✅ Nuclei scan completed with \(vulnerabilities.count) findings")
            
        } catch {
            output.append("❌ Error executing Nuclei: \(error.localizedDescription)")
        }
        
        return (output, vulnerabilities)
    }
    
    private func executeFeroxbusterCommand(targetURL: String) async -> (output: [String], files: [String], success: Bool) {
        var output: [String] = []
        var files: [String] = []
        
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        
        guard let feroxPath = findWebToolPath("feroxbuster") else {
            output.append("❌ Feroxbuster not found. Install with: cargo install feroxbuster")
            return (output, files, false)
        }
        
        let wordlist = createWebWordlist()
        
        process.executableURL = URL(fileURLWithPath: feroxPath)
        process.arguments = [
            "-u", targetURL,
            "-w", wordlist,
            "-d", "3",        // Depth of 3
            "-t", "50",       // 50 threads
            "--timeout", "30",
            "-q",             // Quiet mode
            "--json"          // JSON output
        ]
        
        output.append("🚀 Starting Feroxbuster recursive directory scan...")
        output.append("Target: \(targetURL)")
        
        do {
            try process.run()
            
            // Set timeout
            let timeoutTask = Task {
                try await Task.sleep(nanoseconds: 600_000_000_000) // 10 minutes
                if process.isRunning {
                    process.terminate()
                    output.append("⏰ Feroxbuster scan timed out after 10 minutes")
                }
            }
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let outputString = String(data: data, encoding: .utf8) {
                let lines = outputString.components(separatedBy: .newlines)
                
                for line in lines.filter({ !$0.isEmpty }) {
                    if let jsonData = line.data(using: .utf8),
                       let feroxResult = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                        
                        if let url = feroxResult["url"] as? String,
                           let status = feroxResult["status"] as? Int,
                           status == 200 || status == 301 || status == 302 {
                            files.append("\(url) [Status: \(status)]")
                            output.append("✅ Found: \(url) [Status: \(status)]")
                        }
                    } else {
                        output.append(line)
                    }
                }
            }
            
            process.waitUntilExit()
            timeoutTask.cancel()
            output.append("✅ Feroxbuster scan completed with \(files.count) findings")
            
            return (output, files, true)
            
        } catch {
            output.append("❌ Error executing Feroxbuster: \(error.localizedDescription)")
            return (output, files, false)
        }
    }
    
    private func executeXSSStrikeCommand(targetURL: String) async -> (output: [String], vulnerabilities: [String]) {
        var output: [String] = []
        var vulnerabilities: [String] = []
        
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        
        // Check if XSStrike is installed
        let xssStrikePath = "/opt/xsstrike/xsstrike.py"
        guard FileManager.default.fileExists(atPath: xssStrikePath) else {
            output.append("❌ XSStrike not found. Install with: git clone https://github.com/s0md3v/XSStrike.git /opt/xsstrike")
            return (output, vulnerabilities)
        }
        
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = [
            xssStrikePath,
            "-u", targetURL,
            "--crawl",      // Crawl for parameters
            "--blind",      // Test for blind XSS
            "--timeout", "30"
        ]
        
        output.append("🚀 Starting XSStrike XSS detection scan...")
        output.append("Target: \(targetURL)")
        
        do {
            try process.run()
            
            // Set timeout
            let timeoutTask = Task {
                try await Task.sleep(nanoseconds: 300_000_000_000) // 5 minutes
                if process.isRunning {
                    process.terminate()
                    output.append("⏰ XSStrike scan timed out after 5 minutes")
                }
            }
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let outputString = String(data: data, encoding: .utf8) {
                let lines = outputString.components(separatedBy: .newlines)
                output.append(contentsOf: lines.filter { !$0.isEmpty })
                
                // Parse XSStrike output for vulnerabilities
                for line in lines {
                    let lowerLine = line.lowercased()
                    if lowerLine.contains("xss") && (lowerLine.contains("vulnerable") || lowerLine.contains("found")) {
                        vulnerabilities.append(line.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                }
            }
            
            process.waitUntilExit()
            timeoutTask.cancel()
            output.append("✅ XSStrike scan completed")
            
        } catch {
            output.append("❌ Error executing XSStrike: \(error.localizedDescription)")
        }
        
        return (output, vulnerabilities)
    }
    
    private func executeZAPCommand(targetURL: String) async -> (output: [String], vulnerabilities: [String]) {
        var output: [String] = []
        var vulnerabilities: [String] = []
        
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        
        // Check for ZAP installation (Docker or native)
        if FileManager.default.fileExists(atPath: "/usr/local/bin/docker") {
            // Use Docker version
            process.executableURL = URL(fileURLWithPath: "/usr/local/bin/docker")
            process.arguments = [
                "run", "--rm",
                "owasp/zap2docker-stable",
                "zap-baseline.py",
                "-t", targetURL,
                "-J", "zap-report.json"  // JSON output
            ]
        } else if let zapPath = findWebToolPath("zap.sh") {
            // Use native installation
            process.executableURL = URL(fileURLWithPath: zapPath)
            process.arguments = [
                "-cmd",
                "-quickurl", targetURL,
                "-quickout", "/tmp/zap-output.json"
            ]
        } else {
            output.append("❌ OWASP ZAP not found. Install with: brew install --cask owasp-zap or use Docker")
            return (output, vulnerabilities)
        }
        
        output.append("🚀 Starting OWASP ZAP comprehensive scan...")
        output.append("Target: \(targetURL)")
        
        do {
            try process.run()
            
            // Set timeout
            let timeoutTask = Task {
                try await Task.sleep(nanoseconds: 900_000_000_000) // 15 minutes
                if process.isRunning {
                    process.terminate()
                    output.append("⏰ ZAP scan timed out after 15 minutes")
                }
            }
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let outputString = String(data: data, encoding: .utf8) {
                let lines = outputString.components(separatedBy: .newlines)
                output.append(contentsOf: lines.filter { !$0.isEmpty })
                
                // Parse ZAP output for vulnerabilities
                for line in lines {
                    if line.contains("WARN") || line.contains("FAIL") || line.contains("Medium") || line.contains("High") {
                        vulnerabilities.append(line.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                }
            }
            
            process.waitUntilExit()
            timeoutTask.cancel()
            output.append("✅ OWASP ZAP scan completed")
            
        } catch {
            output.append("❌ Error executing OWASP ZAP: \(error.localizedDescription)")
        }
        
        return (output, vulnerabilities)
    }
    
    private func executeHTTPxCommand(targetURL: String) async -> (output: [String], technologies: [String], statusIssues: [String]) {
        var output: [String] = []
        var technologies: [String] = []
        var statusIssues: [String] = []
        
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        
        guard let httpxPath = findWebToolPath("httpx") else {
            output.append("❌ HTTPx not found. Install with: go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest")
            return (output, technologies, statusIssues)
        }
        
        process.executableURL = URL(fileURLWithPath: httpxPath)
        process.arguments = [
            "-u", targetURL,
            "-json",           // JSON output
            "-title",          // Extract page titles
            "-tech-detect",    // Technology detection
            "-status-code",    // Include status codes
            "-content-length", // Content length
            "-response-time",  // Response time
            "-silent"
        ]
        
        output.append("🚀 Starting HTTPx HTTP/HTTPS analysis...")
        output.append("Target: \(targetURL)")
        
        do {
            try process.run()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let outputString = String(data: data, encoding: .utf8) {
                let lines = outputString.components(separatedBy: .newlines)
                
                for line in lines.filter({ !$0.isEmpty }) {
                    if let jsonData = line.data(using: .utf8),
                       let httpxResult = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                        
                        // Extract technologies
                        if let techs = httpxResult["tech"] as? [String], !techs.isEmpty {
                            technologies.append(contentsOf: techs)
                        }
                        
                        // Check for status code issues
                        if let statusCode = httpxResult["status_code"] as? Int {
                            if statusCode >= 400 {
                                statusIssues.append("HTTP \(statusCode) error")
                            }
                        }
                        
                        // Check for suspicious titles
                        if let title = httpxResult["title"] as? String {
                            if title.lowercased().contains("error") || title.lowercased().contains("exception") {
                                statusIssues.append("Error page detected: \(title)")
                            }
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
        
        return (output, technologies, statusIssues)
    }
    
    private func executeTestSSLCommand(targetURL: String) async -> (output: [String], vulnerabilities: [String]) {
        var output: [String] = []
        var vulnerabilities: [String] = []
        
        // Add console output for transparency
        await updateVerboseOutput("🔍 Starting TestSSL.sh Comprehensive Analysis...")
        await updateVerboseOutput("Target: \(targetURL)")
        await updateVerboseOutput("")
        
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        
        // Check multiple possible TestSSL.sh locations
        let possiblePaths = [
            "/opt/testssl/testssl.sh",
            "/usr/local/bin/testssl.sh",
            "/opt/homebrew/bin/testssl.sh",
            "./testssl.sh",
            "/usr/share/testssl/testssl.sh"
        ]
        
        var testSSLPath: String?
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                testSSLPath = path
                break
            }
        }
        
        guard let finalTestSSLPath = testSSLPath else {
            let errorMsg = "❌ TestSSL.sh not found in any common location"
            let installMsg = "💡 Install with: git clone https://github.com/drwetter/testssl.sh.git /opt/testssl"
            let altInstallMsg = "Or: brew install testssl"
            
            output.append(errorMsg)
            output.append(installMsg)
            output.append(altInstallMsg)
            
            await updateVerboseOutput(errorMsg)
            await updateVerboseOutput("")
            await updateVerboseOutput("Checked locations:")
            for path in possiblePaths {
                await updateVerboseOutput("  • \(path) - Not found")
            }
            await updateVerboseOutput("")
            await updateVerboseOutput(installMsg)
            await updateVerboseOutput(altInstallMsg)
            
            return (output, vulnerabilities)
        }
        
        await updateVerboseOutput("✅ TestSSL.sh found at: \(finalTestSSLPath)")
        
        // Extract host from URL
        guard let url = URL(string: targetURL), let host = url.host else {
            output.append("❌ Invalid URL for SSL testing")
            return (output, vulnerabilities)
        }
        
        process.executableURL = URL(fileURLWithPath: finalTestSSLPath)
        process.arguments = [
            "--fast",           // Fast scan mode
            "--quiet",          // Reduce output
            "--jsonfile", "/tmp/testssl-\(UUID().uuidString).json",
            host
        ]
        
        output.append("🚀 Starting TestSSL.sh comprehensive SSL/TLS analysis...")
        output.append("Target: \(host)")
        
        await updateVerboseOutput("🚀 Executing TestSSL.sh with parameters:")
        await updateVerboseOutput("  • Target: \(host)")
        await updateVerboseOutput("  • Mode: Fast scan")
        await updateVerboseOutput("  • Output: Quiet mode")
        await updateVerboseOutput("  • Timeout: 10 minutes")
        await updateVerboseOutput("")
        
        do {
            try process.run()
            
            // Set timeout
            let timeoutTask = Task {
                try await Task.sleep(nanoseconds: 600_000_000_000) // 10 minutes
                if process.isRunning {
                    process.terminate()
                    output.append("⏰ TestSSL scan timed out after 10 minutes")
                }
            }
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let outputString = String(data: data, encoding: .utf8) {
                let lines = outputString.components(separatedBy: .newlines)
                let filteredLines = lines.filter { !$0.isEmpty }
                output.append(contentsOf: filteredLines)
                
                // Show real-time output to user
                await updateVerboseOutput("📋 TestSSL.sh Analysis Results:")
                for line in filteredLines.prefix(20) { // Show first 20 lines
                    await updateVerboseOutput(line)
                }
                if filteredLines.count > 20 {
                    await updateVerboseOutput("... (\(filteredLines.count - 20) more lines)")
                }
                await updateVerboseOutput("")
                
                // Parse TestSSL output for vulnerabilities
                await updateVerboseOutput("🔍 Analyzing for vulnerabilities...")
                for line in lines {
                    let lowerLine = line.lowercased()
                    if (lowerLine.contains("vulnerable") || lowerLine.contains("weak") || lowerLine.contains("insecure")) &&
                       !lowerLine.contains("not vulnerable") {
                        vulnerabilities.append(line.trimmingCharacters(in: .whitespacesAndNewlines))
                        await updateVerboseOutput("⚠️ Found: \(line.trimmingCharacters(in: .whitespacesAndNewlines))")
                    }
                }
                
                if vulnerabilities.isEmpty {
                    await updateVerboseOutput("✅ No significant vulnerabilities detected")
                } else {
                    await updateVerboseOutput("❌ Found \(vulnerabilities.count) potential SSL/TLS issues")
                }
            }
            
            process.waitUntilExit()
            timeoutTask.cancel()
            output.append("✅ TestSSL.sh analysis completed")
            await updateVerboseOutput("✅ TestSSL.sh analysis completed successfully")
            
        } catch {
            output.append("❌ Error executing TestSSL.sh: \(error.localizedDescription)")
            await updateVerboseOutput("❌ Error executing TestSSL.sh: \(error.localizedDescription)")
        }
        
        return (output, vulnerabilities)
    }
    
    // MARK: - Timeout Helper
    
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    private struct TimeoutError: Error, LocalizedError {
        var errorDescription: String? {
            return "Operation timed out"
        }
    }
    
    // Method to add vulnerabilities from any source
    func addVulnerability(_ vulnerability: Vulnerability, targetIP: String) {
        // Add to global vulnerabilities list
        allVulnerabilities.append(vulnerability)
        
        // Add to specific target
        if let targetIndex = targets.firstIndex(where: { $0.ipAddress == targetIP }) {
            targets[targetIndex].vulnerabilities.append(vulnerability)
        } else {
            // Create new target if it doesn't exist
            var newTarget = Target(name: targetIP, ipAddress: targetIP)
            newTarget.vulnerabilities.append(vulnerability)
            targets.append(newTarget)
        }
    }
    
    // Method to get all vulnerabilities for dashboard
    func getAllVulnerabilities() -> [Vulnerability] {
        return targets.flatMap { $0.vulnerabilities }
    }
    
    // Method to get vulnerability count by severity
    func getVulnerabilityCount(severity: Vulnerability.Severity) -> Int {
        return getAllVulnerabilities().filter { $0.severity == severity }.count
    }
}


// MARK: - Development & Preview Mock Data Extensions
// These mock extensions are for SwiftUI previews and development testing only
// They should NOT be used for actual security testing or production data

#if DEBUG
extension Vulnerability {
    static var mock: Vulnerability {
        Vulnerability(
            title: "SQL Injection", 
            description: "SQL Injection vulnerability found.", 
            severity: .high, 
            port: 80
        )
    }
    
    static var mockLow: Vulnerability {
        Vulnerability(
            title: "Outdated jQuery", 
            description: "Outdated jQuery version.", 
            severity: .low, 
            port: 443, 
            discoveredAt: Date().addingTimeInterval(-3600)
        )
    }
}

extension Target {
    static var mock: Target {
        Target(
            name: "Test Server", 
            ipAddress: "192.168.1.100"
        )
    }
    
    static var mock2: Target {
        Target(
            name: "Web Server", 
            ipAddress: "10.0.0.5"
        )
    }
}

extension ScanResult {
    static var mock: ScanResult {
        ScanResult(
            targetId: UUID(),
            scanType: .vulnScan
        )
    }
}

extension NetworkPortScanResult {
    static var mockOpen: NetworkPortScanResult {
        NetworkPortScanResult(port: 80, isOpen: true, service: "http", version: "Apache/2.4.1", banner: "Apache Server Banner", riskLevel: .medium, attackVectors: [.mockSsh])
    }
    static var mockClosed: NetworkPortScanResult {
        NetworkPortScanResult(port: 23, isOpen: false, service: "telnet", version: nil, banner: nil, riskLevel: .none, attackVectors: [])
    }
}

extension WebScanResult {
    static var mock: WebScanResult {
        WebScanResult(type: "SQL Injection", description: "Found a potential SQL injection point.", url: "https://example.com/login", severity: .high, details: ["Injection point in login form"], timestamp: Date())
    }
}

extension NetworkAttackVector {
    static var mockSsh: NetworkAttackVector {
        NetworkAttackVector(name: "SSH Brute Force", description: "Default credentials for SSH.", severity: .high, tools: ["hydra", "nmap"], commands: ["hydra -l root -P /path/to/passwords.txt ssh://<TARGET>"])
    }
}
#endif

// MARK: - macOS Bluetooth Supporting Types
// Structs moved to BluetoothModels.swift to avoid duplicates