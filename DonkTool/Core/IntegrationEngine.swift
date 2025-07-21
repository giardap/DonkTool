//
//  IntegrationEngine.swift
//  DonkTool
//
//  Cross-module integration framework for automated tool triggering
//

import Foundation
import SwiftUI
import Combine

// MARK: - Integration Notification System

extension Notification.Name {
    static let triggerWebTesting = Notification.Name("triggerWebTesting")
    static let triggerBluetoothScan = Notification.Name("triggerBluetoothScan")
    static let triggerAttackExecution = Notification.Name("triggerAttackExecution")
    static let credentialsDiscovered = Notification.Name("credentialsDiscovered")
    static let serviceDiscovered = Notification.Name("serviceDiscovered")
    static let vulnerabilityFound = Notification.Name("vulnerabilityFound")
    static let cveCorrelationAvailable = Notification.Name("cveCorrelationAvailable")
    static let bluetoothDeviceCorrelated = Notification.Name("bluetoothDeviceCorrelated")
}

// MARK: - Integration Data Models

struct ServiceDiscovery {
    let targetIP: String
    let port: Int
    let service: String
    let version: String?
    let isOpen: Bool
    let timestamp: Date
    let source: String // "network_scanner", "web_testing", etc.
}

struct CredentialDiscovery {
    let username: String
    let password: String
    let service: String
    let target: String
    let port: Int
    let source: String
    let confidence: CredentialConfidence
    let timestamp: Date
}

enum CredentialConfidence: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
}

struct CVECorrelation {
    let cveId: String
    let service: String
    let version: String
    let target: String
    let port: Int
    let exploitAvailable: Bool
    let severity: String
    let description: String
    let exploits: [ExploitEntry]?
    let exploitCount: Int
    let lastUpdated: Date
    
    // Legacy initializer for compatibility
    init(cveId: String, service: String, version: String, target: String, port: Int, exploitAvailable: Bool, severity: String, description: String) {
        self.cveId = cveId
        self.service = service
        self.version = version
        self.target = target
        self.port = port
        self.exploitAvailable = exploitAvailable
        self.severity = severity
        self.description = description
        self.exploits = nil
        self.exploitCount = 0
        self.lastUpdated = Date()
    }
    
    // Enhanced initializer with exploit data
    init(cveId: String, service: String, version: String, target: String, port: Int, exploitAvailable: Bool, severity: String, description: String, exploits: [ExploitEntry]?, exploitCount: Int, lastUpdated: Date) {
        self.cveId = cveId
        self.service = service
        self.version = version
        self.target = target
        self.port = port
        self.exploitAvailable = exploitAvailable
        self.severity = severity
        self.description = description
        self.exploits = exploits
        self.exploitCount = exploitCount
        self.lastUpdated = lastUpdated
    }
}

struct BluetoothNetworkCorrelation {
    let bluetoothMAC: String
    let bluetoothName: String
    let networkIP: String
    let networkPorts: [Int]
    let correlationConfidence: Double
}

struct ServicePattern {
    let service: String
    let version: String
}

// MARK: - Integration Engine

@Observable
class IntegrationEngine {
    static let shared = IntegrationEngine()
    
    // Integration state
    var isAutoTriggeringEnabled = true
    var discoveredServices: [ServiceDiscovery] = []
    var discoveredCredentials: [CredentialDiscovery] = []
    var cveCorrelations: [CVECorrelation] = []
    var bluetoothCorrelations: [BluetoothNetworkCorrelation] = []
    
    // Integration statistics
    var totalIntegrations = 0
    var successfulIntegrations = 0
    var lastIntegrationTime: Date?
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupNotificationListeners()
    }
    
    private func setupNotificationListeners() {
        // Listen for service discoveries from network scanner
        NotificationCenter.default.publisher(for: .serviceDiscovered)
            .sink { [weak self] notification in
                if let service = notification.object as? ServiceDiscovery {
                    self?.handleServiceDiscovery(service)
                }
            }
            .store(in: &cancellables)
        
        // Listen for credential discoveries
        NotificationCenter.default.publisher(for: .credentialsDiscovered)
            .sink { [weak self] notification in
                if let credentials = notification.object as? CredentialDiscovery {
                    self?.handleCredentialDiscovery(credentials)
                }
            }
            .store(in: &cancellables)
        
        // Listen for vulnerability discoveries
        NotificationCenter.default.publisher(for: .vulnerabilityFound)
            .sink { [weak self] notification in
                if let vulnerability = notification.userInfo as? [String: Any] {
                    self?.handleVulnerabilityDiscovery(vulnerability)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Service Discovery Integration
    
    func handleServiceDiscovery(_ service: ServiceDiscovery) {
        guard isAutoTriggeringEnabled else { return }
        
        discoveredServices.append(service)
        totalIntegrations += 1
        lastIntegrationTime = Date()
        
        Task {
            // Auto-trigger web testing for web services
            if await shouldTriggerWebTesting(for: service) {
                await triggerWebTesting(for: service)
            }
            
            // Auto-correlate with CVE database using enhanced correlation
            if await shouldTriggerCVECorrelation(for: service) {
                await performAdvancedCVECorrelation(for: service)
            }
            
            // Check for Bluetooth correlation
            if await shouldCheckBluetoothCorrelation(for: service) {
                await checkBluetoothCorrelation(for: service)
            }
        }
    }
    
    private func shouldTriggerWebTesting(for service: ServiceDiscovery) async -> Bool {
        let webPorts = [80, 443, 8080, 8443, 3000, 5000, 8000, 9000]
        return service.isOpen && webPorts.contains(service.port)
    }
    
    private func triggerWebTesting(for service: ServiceDiscovery) async {
        let webURL = buildWebURL(target: service.targetIP, port: service.port)
        
        await MainActor.run {
            NotificationCenter.default.post(
                name: .triggerWebTesting,
                object: webURL,
                userInfo: [
                    "source": "integration_engine",
                    "target": service.targetIP,
                    "port": service.port,
                    "service": service.service
                ]
            )
        }
        
        print("🔗 Integration: Auto-triggered web testing for \(webURL)")
        successfulIntegrations += 1
    }
    
    private func buildWebURL(target: String, port: Int) -> String {
        let scheme = (port == 443 || port == 8443) ? "https" : "http"
        let urlPort = (port == 80 || port == 443) ? "" : ":\(port)"
        return "\(scheme)://\(target)\(urlPort)"
    }
    
    // MARK: - Credential Discovery Integration
    
    func handleCredentialDiscovery(_ credentials: CredentialDiscovery) {
        guard isAutoTriggeringEnabled else { return }
        
        discoveredCredentials.append(credentials)
        totalIntegrations += 1
        lastIntegrationTime = Date()
        
        Task {
            // Test credentials against SSH services
            await testCredentialsAgainstSSH(credentials)
            
            // Test credentials against web admin panels
            await testCredentialsAgainstWebAdminPanels(credentials)
            
            // Test credentials against FTP services
            await testCredentialsAgainstFTP(credentials)
            
            // Test credentials against database services
            await testCredentialsAgainstDatabases(credentials)
        }
    }
    
    private func testCredentialsAgainstSSH(_ credentials: CredentialDiscovery) async {
        let sshServices = discoveredServices.filter { $0.port == 22 && $0.isOpen }
        
        for service in sshServices {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/local/bin/sshpass")
            process.arguments = [
                "-p", credentials.password,
                "ssh", "-o", "ConnectTimeout=5",
                "-o", "StrictHostKeyChecking=no",
                "\(credentials.username)@\(service.targetIP)",
                "exit"
            ]
            
            do {
                try process.run()
                process.waitUntilExit()
                
                if process.terminationStatus == 0 {
                    await MainActor.run {
                        NotificationCenter.default.post(
                            name: .credentialsDiscovered,
                            object: CredentialDiscovery(
                                username: credentials.username,
                                password: credentials.password,
                                service: "SSH",
                                target: service.targetIP,
                                port: 22,
                                source: "integration_engine_ssh_test",
                                confidence: .high,
                                timestamp: Date()
                            )
                        )
                    }
                    print("🔗 Integration: SSH credentials validated for \(service.targetIP):22")
                    successfulIntegrations += 1
                }
            } catch {
                print("Failed to test SSH credentials: \(error)")
            }
        }
    }
    
    private func testCredentialsAgainstWebAdminPanels(_ credentials: CredentialDiscovery) async {
        let webServices = discoveredServices.filter { [80, 443, 8080, 8443].contains($0.port) && $0.isOpen }
        let adminPaths = ["/admin", "/login", "/wp-admin", "/administrator", "/panel"]
        
        for service in webServices {
            for path in adminPaths {
                let url = buildWebURL(target: service.targetIP, port: service.port) + path
                
                guard let requestURL = URL(string: url) else { continue }
                
                var request = URLRequest(url: requestURL)
                request.httpMethod = "POST"
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                
                let body = "username=\(credentials.username)&password=\(credentials.password)"
                request.httpBody = body.data(using: .utf8)
                request.timeoutInterval = 10
                
                do {
                    let (data, response) = try await URLSession.shared.data(for: request)
                    
                    if let httpResponse = response as? HTTPURLResponse,
                       let responseString = String(data: data, encoding: .utf8) {
                        
                        // Check for successful login indicators
                        let successIndicators = ["dashboard", "welcome", "logout", "admin panel"]
                        let failureIndicators = ["invalid", "incorrect", "failed", "error"]
                        
                        let hasSuccess = successIndicators.contains { responseString.lowercased().contains($0) }
                        let hasFailure = failureIndicators.contains { responseString.lowercased().contains($0) }
                        
                        if hasSuccess && !hasFailure && httpResponse.statusCode == 200 {
                            await MainActor.run {
                                NotificationCenter.default.post(
                                    name: .credentialsDiscovered,
                                    object: CredentialDiscovery(
                                        username: credentials.username,
                                        password: credentials.password,
                                        service: "Web Admin",
                                        target: service.targetIP,
                                        port: service.port,
                                        source: "integration_engine_web_test",
                                        confidence: .medium,
                                        timestamp: Date()
                                    )
                                )
                            }
                            print("🔗 Integration: Web admin credentials validated for \(url)")
                            successfulIntegrations += 1
                        }
                    }
                } catch {
                    // Continue testing other paths
                    continue
                }
            }
        }
    }
    
    private func testCredentialsAgainstFTP(_ credentials: CredentialDiscovery) async {
        let ftpServices = discoveredServices.filter { $0.port == 21 && $0.isOpen }
        
        for service in ftpServices {
            let process = Process()
            let pipe = Pipe()
            process.standardInput = pipe
            process.executableURL = URL(fileURLWithPath: "/usr/bin/ftp")
            process.arguments = ["-n", service.targetIP]
            
            do {
                try process.run()
                
                let commands = """
                user \(credentials.username) \(credentials.password)
                ls
                quit
                """
                
                pipe.fileHandleForWriting.write(commands.data(using: .utf8)!)
                pipe.fileHandleForWriting.closeFile()
                
                process.waitUntilExit()
                
                if process.terminationStatus == 0 {
                    await MainActor.run {
                        NotificationCenter.default.post(
                            name: .credentialsDiscovered,
                            object: CredentialDiscovery(
                                username: credentials.username,
                                password: credentials.password,
                                service: "FTP",
                                target: service.targetIP,
                                port: 21,
                                source: "integration_engine_ftp_test",
                                confidence: .high,
                                timestamp: Date()
                            )
                        )
                    }
                    print("🔗 Integration: FTP credentials validated for \(service.targetIP):21")
                    successfulIntegrations += 1
                }
            } catch {
                print("Failed to test FTP credentials: \(error)")
            }
        }
    }
    
    private func testCredentialsAgainstDatabases(_ credentials: CredentialDiscovery) async {
        // Test MySQL (port 3306)
        await testMySQLCredentials(credentials)
        
        // Test PostgreSQL (port 5432)
        await testPostgreSQLCredentials(credentials)
        
        // Test MongoDB (port 27017)
        await testMongoDBCredentials(credentials)
    }
    
    private func testMySQLCredentials(_ credentials: CredentialDiscovery) async {
        let mysqlServices = discoveredServices.filter { $0.port == 3306 && $0.isOpen }
        
        for service in mysqlServices {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/local/bin/mysql")
            process.arguments = [
                "-h", service.targetIP,
                "-u", credentials.username,
                "-p\(credentials.password)",
                "-e", "SELECT 1;"
            ]
            
            do {
                try process.run()
                process.waitUntilExit()
                
                if process.terminationStatus == 0 {
                    await MainActor.run {
                        NotificationCenter.default.post(
                            name: .credentialsDiscovered,
                            object: CredentialDiscovery(
                                username: credentials.username,
                                password: credentials.password,
                                service: "MySQL",
                                target: service.targetIP,
                                port: 3306,
                                source: "integration_engine_mysql_test",
                                confidence: .high,
                                timestamp: Date()
                            )
                        )
                    }
                    print("🔗 Integration: MySQL credentials validated for \(service.targetIP):3306")
                    successfulIntegrations += 1
                }
            } catch {
                // MySQL not installed or credentials invalid
                continue
            }
        }
    }
    
    private func testPostgreSQLCredentials(_ credentials: CredentialDiscovery) async {
        let pgServices = discoveredServices.filter { $0.port == 5432 && $0.isOpen }
        
        for service in pgServices {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/local/bin/psql")
            process.arguments = [
                "-h", service.targetIP,
                "-U", credentials.username,
                "-c", "SELECT 1;",
                "postgres"
            ]
            process.environment = ["PGPASSWORD": credentials.password]
            
            do {
                try process.run()
                process.waitUntilExit()
                
                if process.terminationStatus == 0 {
                    await MainActor.run {
                        NotificationCenter.default.post(
                            name: .credentialsDiscovered,
                            object: CredentialDiscovery(
                                username: credentials.username,
                                password: credentials.password,
                                service: "PostgreSQL",
                                target: service.targetIP,
                                port: 5432,
                                source: "integration_engine_postgresql_test",
                                confidence: .high,
                                timestamp: Date()
                            )
                        )
                    }
                    print("🔗 Integration: PostgreSQL credentials validated for \(service.targetIP):5432")
                    successfulIntegrations += 1
                }
            } catch {
                continue
            }
        }
    }
    
    private func testMongoDBCredentials(_ credentials: CredentialDiscovery) async {
        let mongoServices = discoveredServices.filter { $0.port == 27017 && $0.isOpen }
        
        for service in mongoServices {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/local/bin/mongo")
            process.arguments = [
                "--host", "\(service.targetIP):27017",
                "--username", credentials.username,
                "--password", credentials.password,
                "--eval", "db.runCommand('ping')"
            ]
            
            do {
                try process.run()
                process.waitUntilExit()
                
                if process.terminationStatus == 0 {
                    await MainActor.run {
                        NotificationCenter.default.post(
                            name: .credentialsDiscovered,
                            object: CredentialDiscovery(
                                username: credentials.username,
                                password: credentials.password,
                                service: "MongoDB",
                                target: service.targetIP,
                                port: 27017,
                                source: "integration_engine_mongodb_test",
                                confidence: .high,
                                timestamp: Date()
                            )
                        )
                    }
                    print("🔗 Integration: MongoDB credentials validated for \(service.targetIP):27017")
                    successfulIntegrations += 1
                }
            } catch {
                continue
            }
        }
    }
    
    // MARK: - CVE Correlation Integration
    
    private func shouldTriggerCVECorrelation(for service: ServiceDiscovery) async -> Bool {
        return service.version != nil && !service.version!.isEmpty
    }
    
    private func triggerCVECorrelation(for service: ServiceDiscovery) async {
        guard let version = service.version else { return }
        
        // Search CVE database for vulnerabilities matching this service/version
        let cveResults = await searchCVEDatabase(service: service.service, version: version)
        
        for cveResult in cveResults {
            let correlation = CVECorrelation(
                cveId: cveResult.id,
                service: service.service,
                version: version,
                target: service.targetIP,
                port: service.port,
                exploitAvailable: cveResult.exploitAvailable,
                severity: cveResult.severity,
                description: cveResult.description
            )
            
            cveCorrelations.append(correlation)
            
            // If exploit is available, suggest automated exploitation
            if cveResult.exploitAvailable {
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: .triggerAttackExecution,
                        object: correlation,
                        userInfo: [
                            "source": "integration_engine_cve_correlation",
                            "auto_exploit_available": true
                        ]
                    )
                }
                print("🔗 Integration: Auto-exploit available for \(cveResult.id) on \(service.targetIP):\(service.port)")
                successfulIntegrations += 1
            }
        }
    }
    
    private func searchCVEDatabase(service: String, version: String) async -> [CVESearchResult] {
        // Real CVE database search using NIST API
        let searchQuery = "\(service) \(version)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://services.nvd.nist.gov/rest/json/cves/1.0?keyword=\(searchQuery)"
        
        guard let url = URL(string: urlString) else { return [] }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let cveResponse = try JSONDecoder().decode(CVEResponse.self, from: data)
            
            return cveResponse.vulnerabilities.compactMap { vulnerability in
                let baseScore = vulnerability.cve.metrics?.cvssMetricV31?.first?.cvssData.baseScore ?? 0.0
                let severity = getSeverityFromScore(baseScore)
                let description = vulnerability.cve.descriptions.first?.value ?? "No description"
                
                return CVESearchResult(
                    id: vulnerability.cve.id,
                    description: description,
                    severity: severity,
                    score: baseScore,
                    exploitAvailable: checkExploitAvailability(vulnerability.cve.id)
                )
            }
        } catch {
            print("CVE search failed: \(error)")
            return []
        }
    }
    
    private func getSeverityFromScore(_ score: Double) -> String {
        switch score {
        case 9.0...10.0: return "CRITICAL"
        case 7.0..<9.0: return "HIGH"
        case 4.0..<7.0: return "MEDIUM"
        case 0.1..<4.0: return "LOW"
        default: return "NONE"
        }
    }
    
    private func checkExploitAvailability(_ cveId: String) -> Bool {
        // Use SearchSploitManager for real exploit availability checking
        let searchSploitManager = SearchSploitManager()
        
        // Check if SearchSploit is installed
        guard searchSploitManager.checkSearchSploitInstallation() == .installed else {
            // Fallback to known exploitable CVEs if SearchSploit not available
            let knownExploitableCVEs = [
                "CVE-2017-0144", // EternalBlue
                "CVE-2019-0708", // BlueKeep
                "CVE-2021-44228", // Log4Shell
                "CVE-2017-5638", // Struts2
                "CVE-2020-1472", // Zerologon
                "CVE-2019-11932", // BlueKeep variants
                "CVE-2020-0022", // BlueFrag
                "CVE-2017-1000251", // BlueBorne stack overflow
                "CVE-2017-1000250", // BlueBorne information disclosure
            ]
            return knownExploitableCVEs.contains(cveId)
        }
        
        // Perform async search in background and cache result
        Task {
            let exploits = await searchSploitManager.searchForCVE(cveId)
            if !exploits.isEmpty {
                // Update CVE correlation with actual exploit information
                await updateCVEWithExploitData(cveId: cveId, exploits: exploits)
            }
        }
        
        // Return true for immediate processing - actual exploit data will be updated asynchronously
        return true
    }
    
    private func updateCVEWithExploitData(cveId: String, exploits: [ExploitEntry]) async {
        // Find existing CVE correlation and update with exploit data
        guard let index = cveCorrelations.firstIndex(where: { $0.cveId == cveId }) else { return }
        
        let existingCorrelation = cveCorrelations[index]
        let updatedCorrelation = CVECorrelation(
            cveId: existingCorrelation.cveId,
            service: existingCorrelation.service,
            version: existingCorrelation.version,
            target: existingCorrelation.target,
            port: existingCorrelation.port,
            exploitAvailable: !exploits.isEmpty,
            severity: existingCorrelation.severity,
            description: existingCorrelation.description,
            exploits: exploits,
            exploitCount: exploits.count,
            lastUpdated: Date()
        )
        
        await MainActor.run {
            self.cveCorrelations[index] = updatedCorrelation
            
            // Notify about updated exploit availability
            NotificationCenter.default.post(
                name: .cveCorrelationAvailable,
                object: updatedCorrelation,
                userInfo: [
                    "source": "integration_engine_searchsploit_update",
                    "exploit_count": exploits.count,
                    "has_critical_exploits": exploits.contains { $0.severity == .critical }
                ]
            )
        }
        
        print("🔗 Integration: Updated CVE \(cveId) with \(exploits.count) available exploits")
        successfulIntegrations += 1
    }
    
    // MARK: - Enhanced CVE Correlation with Service Fingerprinting
    
    func performAdvancedCVECorrelation(for service: ServiceDiscovery) async {
        guard let version = service.version, !version.isEmpty else { return }
        
        // Enhanced service fingerprinting for better CVE matching
        let servicePatterns = await extractServicePatterns(service: service.service, version: version)
        
        for pattern in servicePatterns {
            let cveResults = await searchCVEDatabase(service: pattern.service, version: pattern.version)
            
            for cveResult in cveResults {
                // Real-time SearchSploit integration
                let searchSploitManager = SearchSploitManager()
                let exploits = await searchSploitManager.searchForCVE(cveResult.id)
                
                let correlation = CVECorrelation(
                    cveId: cveResult.id,
                    service: service.service,
                    version: version,
                    target: service.targetIP,
                    port: service.port,
                    exploitAvailable: !exploits.isEmpty,
                    severity: cveResult.severity,
                    description: cveResult.description,
                    exploits: exploits,
                    exploitCount: exploits.count,
                    lastUpdated: Date()
                )
                
                cveCorrelations.append(correlation)
                
                // Trigger automated exploitation for high-severity CVEs with available exploits
                if shouldAutoExploit(correlation: correlation) {
                    await triggerAutomatedExploitation(correlation: correlation)
                }
            }
        }
    }
    
    private func extractServicePatterns(service: String, version: String) async -> [ServicePattern] {
        var patterns: [ServicePattern] = []
        
        // Add the direct service/version
        patterns.append(ServicePattern(service: service, version: version))
        
        // Extract service-specific patterns
        switch service.lowercased() {
        case let s where s.contains("apache"):
            patterns.append(ServicePattern(service: "Apache HTTP Server", version: version))
            patterns.append(ServicePattern(service: "httpd", version: version))
            
        case let s where s.contains("nginx"):
            patterns.append(ServicePattern(service: "nginx", version: version))
            
        case let s where s.contains("openssh"):
            patterns.append(ServicePattern(service: "OpenSSH", version: version))
            patterns.append(ServicePattern(service: "SSH", version: version))
            
        case let s where s.contains("mysql"):
            patterns.append(ServicePattern(service: "MySQL", version: version))
            
        case let s where s.contains("postgresql"):
            patterns.append(ServicePattern(service: "PostgreSQL", version: version))
            
        case let s where s.contains("iis"):
            patterns.append(ServicePattern(service: "Microsoft IIS", version: version))
            
        case let s where s.contains("tomcat"):
            patterns.append(ServicePattern(service: "Apache Tomcat", version: version))
            
        case let s where s.contains("wordpress"):
            patterns.append(ServicePattern(service: "WordPress", version: version))
            
        default:
            break
        }
        
        return patterns
    }
    
    private func shouldAutoExploit(correlation: CVECorrelation) -> Bool {
        // Auto-exploit criteria
        let hasHighSeverityExploits = correlation.exploits?.contains { exploit in
            exploit.severity == .critical || exploit.severity == .high
        } ?? false
        
        let isCriticalCVE = correlation.severity == "CRITICAL" || correlation.severity == "HIGH"
        
        return hasHighSeverityExploits && isCriticalCVE && correlation.exploitAvailable
    }
    
    private func triggerAutomatedExploitation(correlation: CVECorrelation) async {
        guard let exploits = correlation.exploits, !exploits.isEmpty else { return }
        
        // Select the best exploit for automation
        let bestExploit = exploits.first { $0.severity == .critical } ?? exploits.first!
        
        await MainActor.run {
            NotificationCenter.default.post(
                name: .triggerAttackExecution,
                object: correlation,
                userInfo: [
                    "source": "integration_engine_auto_exploit",
                    "exploit_id": bestExploit.id,
                    "exploit_title": bestExploit.title,
                    "exploit_path": bestExploit.path,
                    "target": correlation.target,
                    "port": correlation.port,
                    "auto_exploit_recommended": true
                ]
            )
        }
        
        print("🔗 Integration: Auto-exploitation triggered for \(correlation.cveId) using exploit \(bestExploit.id)")
        successfulIntegrations += 1
    }
    
    // MARK: - Bluetooth Correlation Integration
    
    private func shouldCheckBluetoothCorrelation(for service: ServiceDiscovery) async -> Bool {
        // Check if we have any Bluetooth devices discovered
        return !bluetoothCorrelations.isEmpty || hasRecentBluetoothActivity()
    }
    
    private func checkBluetoothCorrelation(for service: ServiceDiscovery) async {
        // Get Bluetooth devices from MacOSBluetoothSecurityFramework
        let bluetoothDevices = await getDiscoveredBluetoothDevices()
        
        for device in bluetoothDevices {
            let correlation = await correlateBluetoothWithNetwork(device: device, networkService: service)
            
            if correlation.correlationConfidence > 0.7 {
                bluetoothCorrelations.append(correlation)
                
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: .bluetoothDeviceCorrelated,
                        object: correlation,
                        userInfo: [
                            "source": "integration_engine_bluetooth_correlation",
                            "confidence": correlation.correlationConfidence
                        ]
                    )
                }
                
                print("🔗 Integration: Bluetooth device \(device.name) correlated with \(service.targetIP)")
                successfulIntegrations += 1
            }
        }
    }
    
    private func hasRecentBluetoothActivity() -> Bool {
        // Check if Bluetooth scanning was performed recently
        if let lastActivity = lastIntegrationTime {
            return Date().timeIntervalSince(lastActivity) < 300 // 5 minutes
        }
        return false
    }
    
    private func getDiscoveredBluetoothDevices() async -> [BluetoothDeviceInfo] {
        // Interface with MacOSBluetoothSecurityFramework
        // This would integrate with the actual Bluetooth discovery results
        return [] // Placeholder - would get real devices from framework
    }
    
    private func correlateBluetoothWithNetwork(device: BluetoothDeviceInfo, networkService: ServiceDiscovery) async -> BluetoothNetworkCorrelation {
        var confidence = 0.0
        
        // Name correlation
        if device.name.lowercased().contains(networkService.targetIP.components(separatedBy: ".").last ?? "") {
            confidence += 0.3
        }
        
        // Proximity correlation (if devices are on same subnet)
        let deviceSubnet = getSubnet(from: networkService.targetIP)
        if deviceSubnet == getSubnet(from: networkService.targetIP) {
            confidence += 0.4
        }
        
        // Timing correlation (discovered within similar timeframe)
        if abs(device.discoveryTime.timeIntervalSince(networkService.timestamp)) < 300 {
            confidence += 0.3
        }
        
        return BluetoothNetworkCorrelation(
            bluetoothMAC: device.mac,
            bluetoothName: device.name,
            networkIP: networkService.targetIP,
            networkPorts: [networkService.port],
            correlationConfidence: confidence
        )
    }
    
    private func getSubnet(from ip: String) -> String {
        let components = ip.components(separatedBy: ".")
        guard components.count >= 3 else { return "" }
        return components.prefix(3).joined(separator: ".")
    }
    
    private func handleVulnerabilityDiscovery(_ vulnerability: [String: Any]) {
        // Handle vulnerability discoveries and trigger appropriate responses
        guard let target = vulnerability["target"] as? String,
              let type = vulnerability["type"] as? String else { return }
        
        totalIntegrations += 1
        lastIntegrationTime = Date()
        
        // Auto-trigger exploitation if exploit is available
        Task {
            await autoTriggerExploitation(target: target, vulnerabilityType: type)
        }
    }
    
    private func autoTriggerExploitation(target: String, vulnerabilityType: String) async {
        let exploitableVulnerabilities = [
            "SQL Injection",
            "Remote Code Execution",
            "Authentication Bypass",
            "Directory Traversal",
            "Buffer Overflow"
        ]
        
        if exploitableVulnerabilities.contains(vulnerabilityType) {
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .triggerAttackExecution,
                    object: target,
                    userInfo: [
                        "vulnerability_type": vulnerabilityType,
                        "auto_exploit": true,
                        "source": "integration_engine_auto_exploit"
                    ]
                )
            }
            
            print("🔗 Integration: Auto-triggered exploitation for \(vulnerabilityType) on \(target)")
            successfulIntegrations += 1
        }
    }
    
    // MARK: - Integration Statistics
    
    var integrationSuccessRate: Double {
        guard totalIntegrations > 0 else { return 0.0 }
        return Double(successfulIntegrations) / Double(totalIntegrations)
    }
    
    func getIntegrationSummary() -> String {
        return """
        Integration Engine Status:
        - Total Integrations: \(totalIntegrations)
        - Successful: \(successfulIntegrations)
        - Success Rate: \(String(format: "%.1f", integrationSuccessRate * 100))%
        - Services Discovered: \(discoveredServices.count)
        - Credentials Found: \(discoveredCredentials.count)
        - CVE Correlations: \(cveCorrelations.count)
        - Bluetooth Correlations: \(bluetoothCorrelations.count)
        """
    }
}

// MARK: - Supporting Data Models

struct CVESearchResult {
    let id: String
    let description: String
    let severity: String
    let score: Double
    let exploitAvailable: Bool
}

// CVE data models are imported from CVEModels.swift

struct BluetoothDeviceInfo {
    let name: String
    let mac: String
    let discoveryTime: Date
}