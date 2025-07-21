//
//  CollaborativeFramework.swift
//  DonkTool
//
//  Unified intelligence and automation framework for cross-tool collaboration
//

import SwiftUI
import Foundation

// MARK: - Unified Intelligence Engine

@Observable
class DonkToolIntelligenceEngine {
    // Centralized data correlation
    var unifiedTargetDatabase: [UnifiedTarget] = []
    var crossModuleFindings: [IntelligenceFinding] = []
    var automationWorkflows: [AutomationWorkflow] = []
    var credentialVault: CredentialVault = CredentialVault()
    
    // Module coordination
    var activeModules: Set<ModuleType> = []
    var moduleCoordinator = ModuleCoordinator()
    var intelligenceCorrelator = IntelligenceCorrelator()
    
    // MARK: - Automated Discovery Chain
    
    func handleNetworkDiscovery(_ scanResults: [PortScanResult], target: String) {
        let unifiedTarget = getOrCreateUnifiedTarget(target)
        
        for result in scanResults where result.isOpen {
            // Add port finding
            let portFinding = IntelligenceFinding(
                type: .networkService,
                source: .networkScanner,
                target: target,
                data: [
                    "port": "\(result.port)",
                    "service": result.service ?? "unknown",
                    "banner": result.banner ?? "",
                    "version": result.version ?? ""
                ],
                timestamp: Date(),
                confidence: 0.9
            )
            crossModuleFindings.append(portFinding)
            
            // Trigger automated follow-up actions
            triggerAutomatedActions(for: result, target: target)
        }
        
        // Correlate findings across modules
        intelligenceCorrelator.correlateFindings(crossModuleFindings)
    }
    
    private func triggerAutomatedActions(for result: PortScanResult, target: String) {
        // Web service discovery → automatic web testing
        if [80, 443, 8080, 8443].contains(result.port) {
            let webURL = result.port == 443 || result.port == 8443 ? 
                "https://\(target):\(result.port)" : 
                "http://\(target):\(result.port)"
            
            moduleCoordinator.triggerWebTesting(url: webURL, context: .discoveredFromNetworkScan)
        }
        
        // SSH discovery → credential testing
        if result.port == 22 {
            moduleCoordinator.triggerCredentialTesting(
                target: target,
                port: result.port,
                service: "SSH",
                credentials: credentialVault.getCredentialsForService("SSH")
            )
        }
        
        // Database services → specialized testing
        if [3306, 5432, 1433, 1521].contains(result.port) {
            moduleCoordinator.triggerDatabaseTesting(target: target, port: result.port)
        }
        
        // CVE correlation
        correlateCVEsForService(result, target: target)
    }
    
    // MARK: - CVE-Driven Exploitation
    
    private func correlateCVEsForService(_ result: PortScanResult, target: String) {
        guard let service = result.service, let version = result.version else { return }
        
        Task {
            let relevantCVEs = await findRelevantCVEs(service: service, version: version)
            
            for cve in relevantCVEs {
                let cveFinding = IntelligenceFinding(
                    type: .vulnerability,
                    source: .cveDatabase,
                    target: target,
                    data: [
                        "cve_id": cve.id,
                        "service": service,
                        "version": version,
                        "port": "\(result.port)",
                        "severity": cve.severity.rawValue,
                        "exploit_available": "\(cve.exploitAvailable)"
                    ],
                    timestamp: Date(),
                    confidence: 0.8
                )
                
                await MainActor.run {
                    self.crossModuleFindings.append(cveFinding)
                    
                    // Auto-suggest exploits for high-severity CVEs
                    if cve.severity == .critical || cve.severity == .high {
                        self.moduleCoordinator.suggestExploit(cve: cve, target: target, port: result.port)
                    }
                }
            }
        }
    }
    
    // MARK: - Cross-Protocol Intelligence Sharing
    
    func handleBluetoothDiscovery(_ devices: [String: CBPeripheral]) {
        for (deviceId, peripheral) in devices {
            let btFinding = IntelligenceFinding(
                type: .bluetoothDevice,
                source: .bluetoothShell,
                target: peripheral.name ?? deviceId,
                data: [
                    "device_id": deviceId,
                    "name": peripheral.name ?? "Unknown",
                    "state": peripheral.state.description
                ],
                timestamp: Date(),
                confidence: 0.9
            )
            crossModuleFindings.append(btFinding)
            
            // Cross-correlate with network targets
            correlateBluetoothWithNetwork(peripheral)
        }
    }
    
    private func correlateBluetoothWithNetwork(_ peripheral: CBPeripheral) {
        // Look for network targets that might be the same device
        let deviceName = peripheral.name?.lowercased() ?? ""
        
        for target in unifiedTargetDatabase {
            if target.name.lowercased().contains(deviceName) || 
               deviceName.contains(target.name.lowercased()) {
                
                // Same device found on both network and Bluetooth
                let correlation = IntelligenceFinding(
                    type: .deviceCorrelation,
                    source: .intelligenceEngine,
                    target: target.ipAddress,
                    data: [
                        "network_target": target.name,
                        "bluetooth_device": peripheral.name ?? "Unknown",
                        "correlation_confidence": "0.7"
                    ],
                    timestamp: Date(),
                    confidence: 0.7
                )
                crossModuleFindings.append(correlation)
                
                // Suggest coordinated attack
                moduleCoordinator.suggestCoordinatedAttack(
                    networkTarget: target.ipAddress,
                    bluetoothDevice: peripheral.identifier.uuidString
                )
            }
        }
    }
    
    // MARK: - Credential and Data Sharing
    
    func handleWebTestingResults(_ results: [WebTestResult]) {
        for result in results {
            if let vulnerability = result.vulnerability {
                let webFinding = IntelligenceFinding(
                    type: .webVulnerability,
                    source: .webTester,
                    target: result.url,
                    data: [
                        "vulnerability_type": vulnerability.title,
                        "severity": vulnerability.severity.rawValue,
                        "url": result.url,
                        "test_type": result.test.displayName
                    ],
                    timestamp: Date(),
                    confidence: 0.8
                )
                crossModuleFindings.append(webFinding)
                
                // Extract potential credentials from web findings
                extractCredentialsFromWebFindings(result)
                
                // Suggest privilege escalation if web access gained
                if vulnerability.severity == .critical {
                    moduleCoordinator.suggestPrivilegeEscalation(target: extractHostFromURL(result.url))
                }
            }
        }
    }
    
    private func extractCredentialsFromWebFindings(_ result: WebTestResult) {
        // Look for common credential patterns in web findings
        let commonCredentials = [
            ("admin", "admin"),
            ("admin", "password"),
            ("test", "test"),
            ("guest", "guest")
        ]
        
        for (username, password) in commonCredentials {
            credentialVault.addCredential(
                Credential(
                    username: username,
                    password: password,
                    service: "Web",
                    port: extractPortFromURL(result.url),
                    source: .webTesting,
                    confidence: 0.5
                )
            )
        }
    }
    
    // MARK: - Automated Attack Chaining
    
    func planAttackChain(for target: String) -> AttackChain {
        let targetFindings = crossModuleFindings.filter { $0.target == target }
        let attackChain = AttackChain(target: target)
        
        // Phase 1: Information Gathering
        attackChain.addPhase(.reconnaissance, actions: [
            .networkScan(ports: "1-65535"),
            .bluetoothDiscovery,
            .webServiceEnumeration
        ])
        
        // Phase 2: Vulnerability Assessment  
        attackChain.addPhase(.vulnerability_assessment, actions: [
            .cveCorrelation,
            .webVulnerabilityScanning,
            .bluetoothVulnerabilityTesting
        ])
        
        // Phase 3: Exploitation (based on findings)
        var exploitActions: [AttackAction] = []
        
        for finding in targetFindings {
            switch finding.type {
            case .networkService:
                if let port = finding.data["port"], let service = finding.data["service"] {
                    exploitActions.append(.networkExploit(port: Int(port) ?? 0, service: service))
                }
            case .webVulnerability:
                exploitActions.append(.webExploit(url: finding.target))
            case .bluetoothDevice:
                exploitActions.append(.bluetoothExploit(deviceId: finding.target))
            default:
                break
            }
        }
        
        attackChain.addPhase(.exploitation, actions: exploitActions)
        
        // Phase 4: Post-Exploitation
        attackChain.addPhase(.post_exploitation, actions: [
            .privilegeEscalation,
            .lateralMovement,
            .dataExfiltration,
            .persistentAccess
        ])
        
        return attackChain
    }
    
    // MARK: - Unified Reporting Intelligence
    
    func generateUnifiedReport() -> UnifiedReport {
        let report = UnifiedReport()
        
        // Executive Summary
        report.executiveSummary = generateExecutiveSummary()
        
        // Technical Findings (correlated across modules)
        report.technicalFindings = correlateTechnicalFindings()
        
        // Attack Chains
        report.attackChains = generateAttackChainAnalysis()
        
        // Risk Assessment (cross-module risk scoring)
        report.riskAssessment = generateCrossModuleRiskAssessment()
        
        // Recommendations (prioritized by impact and exploitability)
        report.recommendations = generatePrioritizedRecommendations()
        
        return report
    }
    
    private func generateExecutiveSummary() -> ExecutiveSummary {
        let summary = ExecutiveSummary()
        
        // Count findings by severity across all modules
        let criticalFindings = crossModuleFindings.filter { 
            $0.data["severity"] == "critical" 
        }.count
        
        let highFindings = crossModuleFindings.filter { 
            $0.data["severity"] == "high" 
        }.count
        
        summary.overallRisk = determineOverallRisk()
        summary.criticalIssues = criticalFindings
        summary.highRiskIssues = highFindings
        summary.testedAssets = unifiedTargetDatabase.count
        summary.keyFindings = extractKeyFindings()
        
        return summary
    }
    
    // MARK: - Helper Methods
    
    private func getOrCreateUnifiedTarget(_ target: String) -> UnifiedTarget {
        if let existingTarget = unifiedTargetDatabase.first(where: { $0.ipAddress == target }) {
            return existingTarget
        }
        
        let newTarget = UnifiedTarget(
            id: UUID(),
            name: target,
            ipAddress: target,
            discoveredBy: [.networkScanner],
            firstSeen: Date(),
            lastSeen: Date()
        )
        
        unifiedTargetDatabase.append(newTarget)
        return newTarget
    }
    
    private func findRelevantCVEs(service: String, version: String) async -> [LiveCVEEntry] {
        // This would integrate with your CVE database
        return []
    }
    
    private func extractHostFromURL(_ url: String) -> String {
        guard let parsedURL = URL(string: url), let host = parsedURL.host else {
            return url
        }
        return host
    }
    
    private func extractPortFromURL(_ url: String) -> Int? {
        guard let parsedURL = URL(string: url) else { return nil }
        return parsedURL.port
    }
    
    private func determineOverallRisk() -> RiskLevel {
        let criticalCount = crossModuleFindings.filter { $0.data["severity"] == "critical" }.count
        
        if criticalCount > 0 {
            return .critical
        } else if crossModuleFindings.filter({ $0.data["severity"] == "high" }).count > 2 {
            return .high
        } else {
            return .medium
        }
    }
    
    private func extractKeyFindings() -> [String] {
        // Extract most significant findings across all modules
        return crossModuleFindings
            .filter { $0.confidence > 0.7 }
            .sorted { $0.confidence > $1.confidence }
            .prefix(5)
            .map { "\($0.type.rawValue) on \($0.target)" }
    }
    
    private func correlateTechnicalFindings() -> [TechnicalFinding] {
        // Group and correlate findings by target
        let groupedFindings = Dictionary(grouping: crossModuleFindings) { $0.target }
        
        return groupedFindings.map { (target, findings) in
            TechnicalFinding(
                target: target,
                findings: findings,
                riskScore: calculateRiskScore(for: findings),
                attackSurface: calculateAttackSurface(for: findings)
            )
        }
    }
    
    private func generateAttackChainAnalysis() -> [AttackChainAnalysis] {
        return unifiedTargetDatabase.map { target in
            let attackChain = planAttackChain(for: target.ipAddress)
            return AttackChainAnalysis(
                target: target.ipAddress,
                phases: attackChain.phases,
                estimatedTime: attackChain.estimatedExecutionTime,
                successProbability: attackChain.calculateSuccessProbability()
            )
        }
    }
    
    private func generateCrossModuleRiskAssessment() -> RiskAssessment {
        return RiskAssessment(
            networkRisk: calculateNetworkRisk(),
            webApplicationRisk: calculateWebRisk(),
            bluetoothRisk: calculateBluetoothRisk(),
            overallRisk: determineOverallRisk(),
            riskFactors: identifyRiskFactors()
        )
    }
    
    private func generatePrioritizedRecommendations() -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        // Critical vulnerabilities first
        let criticalFindings = crossModuleFindings.filter { $0.data["severity"] == "critical" }
        for finding in criticalFindings {
            recommendations.append(Recommendation(
                priority: .critical,
                category: finding.type,
                description: "Address critical \(finding.type.rawValue) on \(finding.target)",
                effort: .medium,
                impact: .high
            ))
        }
        
        // Cross-module patterns
        if hasCredentialReuse() {
            recommendations.append(Recommendation(
                priority: .high,
                category: .authentication,
                description: "Implement unique credentials across all services",
                effort: .low,
                impact: .high
            ))
        }
        
        return recommendations.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    private func calculateRiskScore(for findings: [IntelligenceFinding]) -> Double {
        let criticalWeight = 4.0
        let highWeight = 3.0
        let mediumWeight = 2.0
        let lowWeight = 1.0
        
        var score = 0.0
        
        for finding in findings {
            switch finding.data["severity"] {
            case "critical": score += criticalWeight
            case "high": score += highWeight
            case "medium": score += mediumWeight
            case "low": score += lowWeight
            default: break
            }
        }
        
        return min(score / Double(findings.count), 4.0) // Normalized to 0-4 scale
    }
    
    private func calculateAttackSurface(for findings: [IntelligenceFinding]) -> Int {
        let uniqueAttackVectors = Set(findings.map { $0.type })
        return uniqueAttackVectors.count
    }
    
    private func calculateNetworkRisk() -> RiskLevel {
        let networkFindings = crossModuleFindings.filter { $0.source == .networkScanner }
        let criticalCount = networkFindings.filter { $0.data["severity"] == "critical" }.count
        
        return criticalCount > 0 ? .critical : .medium
    }
    
    private func calculateWebRisk() -> RiskLevel {
        let webFindings = crossModuleFindings.filter { $0.source == .webTester }
        let criticalCount = webFindings.filter { $0.data["severity"] == "critical" }.count
        
        return criticalCount > 0 ? .critical : .medium
    }
    
    private func calculateBluetoothRisk() -> RiskLevel {
        let btFindings = crossModuleFindings.filter { $0.source == .bluetoothShell }
        return btFindings.isEmpty ? .low : .medium
    }
    
    private func identifyRiskFactors() -> [String] {
        var factors: [String] = []
        
        if hasCredentialReuse() {
            factors.append("Credential reuse across services")
        }
        
        if hasUnencryptedServices() {
            factors.append("Unencrypted services exposed")
        }
        
        if hasOutdatedSoftware() {
            factors.append("Outdated software with known CVEs")
        }
        
        return factors
    }
    
    private func hasCredentialReuse() -> Bool {
        return credentialVault.detectCredentialReuse()
    }
    
    private func hasUnencryptedServices() -> Bool {
        return crossModuleFindings.contains { finding in
            finding.type == .networkService && 
            [21, 23, 80, 110].contains(Int(finding.data["port"] ?? "0"))
        }
    }
    
    private func hasOutdatedSoftware() -> Bool {
        return crossModuleFindings.contains { $0.type == .vulnerability }
    }
}

// MARK: - Module Coordination

@Observable
class ModuleCoordinator {
    func triggerWebTesting(url: String, context: DiscoveryContext) {
        NotificationCenter.default.post(
            name: .triggerWebTesting,
            object: nil,
            userInfo: ["url": url, "context": context]
        )
    }
    
    func triggerCredentialTesting(target: String, port: Int, service: String, credentials: [Credential]) {
        NotificationCenter.default.post(
            name: .triggerCredentialTesting,
            object: nil,
            userInfo: [
                "target": target,
                "port": port,
                "service": service,
                "credentials": credentials
            ]
        )
    }
    
    func triggerDatabaseTesting(target: String, port: Int) {
        NotificationCenter.default.post(
            name: .triggerDatabaseTesting,
            object: nil,
            userInfo: ["target": target, "port": port]
        )
    }
    
    func suggestExploit(cve: LiveCVEEntry, target: String, port: Int) {
        NotificationCenter.default.post(
            name: .suggestExploit,
            object: nil,
            userInfo: ["cve": cve, "target": target, "port": port]
        )
    }
    
    func suggestCoordinatedAttack(networkTarget: String, bluetoothDevice: String) {
        NotificationCenter.default.post(
            name: .suggestCoordinatedAttack,
            object: nil,
            userInfo: ["networkTarget": networkTarget, "bluetoothDevice": bluetoothDevice]
        )
    }
    
    func suggestPrivilegeEscalation(target: String) {
        NotificationCenter.default.post(
            name: .suggestPrivilegeEscalation,
            object: nil,
            userInfo: ["target": target]
        )
    }
}

// MARK: - Intelligence Correlation

class IntelligenceCorrelator {
    func correlateFindings(_ findings: [IntelligenceFinding]) {
        // Group findings by target
        let targetGroups = Dictionary(grouping: findings) { $0.target }
        
        for (target, targetFindings) in targetGroups {
            correlateFindingsForTarget(target, findings: targetFindings)
        }
    }
    
    private func correlateFindingsForTarget(_ target: String, findings: [IntelligenceFinding]) {
        // Look for patterns that indicate specific attack scenarios
        
        // Pattern: Web service + SSH = potential web shell upload
        let hasWebService = findings.contains { $0.type == .networkService && $0.data["port"] == "80" }
        let hasSSH = findings.contains { $0.type == .networkService && $0.data["port"] == "22" }
        
        if hasWebService && hasSSH {
            let correlation = IntelligenceFinding(
                type: .attackOpportunity,
                source: .intelligenceEngine,
                target: target,
                data: [
                    "pattern": "web_ssh_combination",
                    "description": "Web service + SSH enables web shell upload attacks",
                    "suggested_attack": "Upload web shell via web vulnerability, then SSH for persistence"
                ],
                timestamp: Date(),
                confidence: 0.8
            )
            
            NotificationCenter.default.post(
                name: .correlationFound,
                object: correlation
            )
        }
        
        // Pattern: Multiple open ports = potential internal network access
        let openPorts = findings.filter { $0.type == .networkService }.count
        if openPorts > 10 {
            let correlation = IntelligenceFinding(
                type: .attackOpportunity,
                source: .intelligenceEngine,
                target: target,
                data: [
                    "pattern": "excessive_open_ports",
                    "description": "Many open ports suggest internal network exposure",
                    "suggested_attack": "Use as pivot point for lateral movement"
                ],
                timestamp: Date(),
                confidence: 0.7
            )
            
            NotificationCenter.default.post(
                name: .correlationFound,
                object: correlation
            )
        }
    }
}

// MARK: - Data Models

struct UnifiedTarget: Identifiable {
    let id: UUID
    let name: String
    let ipAddress: String
    var discoveredBy: [ModuleType]
    let firstSeen: Date
    var lastSeen: Date
    var findings: [IntelligenceFinding] = []
    var riskScore: Double = 0.0
}

struct IntelligenceFinding: Identifiable {
    let id = UUID()
    let type: FindingType
    let source: ModuleType
    let target: String
    let data: [String: String]
    let timestamp: Date
    let confidence: Double
}

enum FindingType: String, CaseIterable {
    case networkService = "Network Service"
    case webVulnerability = "Web Vulnerability"
    case bluetoothDevice = "Bluetooth Device"
    case vulnerability = "Vulnerability"
    case deviceCorrelation = "Device Correlation"
    case attackOpportunity = "Attack Opportunity"
    case credentialLeak = "Credential Leak"
}

enum ModuleType: String, CaseIterable {
    case networkScanner = "Network Scanner"
    case webTester = "Web Tester"
    case bluetoothShell = "Bluetooth Shell"
    case cveDatabase = "CVE Database"
    case attackExecutor = "Attack Executor"
    case intelligenceEngine = "Intelligence Engine"
}

enum DiscoveryContext {
    case discoveredFromNetworkScan
    case manualInput
    case correlatedFinding
}

// MARK: - Credential Management

@Observable
class CredentialVault {
    private var credentials: [Credential] = []
    
    func addCredential(_ credential: Credential) {
        credentials.append(credential)
    }
    
    func getCredentialsForService(_ service: String) -> [Credential] {
        return credentials.filter { $0.service.lowercased() == service.lowercased() }
    }
    
    func detectCredentialReuse() -> Bool {
        let uniqueCombinations = Set(credentials.map { "\($0.username):\($0.password)" })
        return uniqueCombinations.count < credentials.count
    }
}

struct Credential: Identifiable {
    let id = UUID()
    let username: String
    let password: String
    let service: String
    let port: Int?
    let source: ModuleType
    let confidence: Double
    let timestamp = Date()
}

// MARK: - Attack Chain Planning

struct AttackChain {
    let target: String
    var phases: [AttackPhase] = []
    
    mutating func addPhase(_ type: AttackPhaseType, actions: [AttackAction]) {
        phases.append(AttackPhase(type: type, actions: actions))
    }
    
    var estimatedExecutionTime: TimeInterval {
        return phases.reduce(0) { $0 + $1.estimatedTime }
    }
    
    func calculateSuccessProbability() -> Double {
        let phaseSuccessRates = phases.map { $0.successProbability }
        return phaseSuccessRates.reduce(1.0) { $0 * $1 }
    }
}

struct AttackPhase {
    let type: AttackPhaseType
    let actions: [AttackAction]
    
    var estimatedTime: TimeInterval {
        return actions.reduce(0) { $0 + $1.estimatedTime }
    }
    
    var successProbability: Double {
        return actions.map { $0.successProbability }.reduce(1.0) { $0 * $1 }
    }
}

enum AttackPhaseType: String, CaseIterable {
    case reconnaissance = "Reconnaissance"
    case vulnerability_assessment = "Vulnerability Assessment"
    case exploitation = "Exploitation"
    case post_exploitation = "Post-Exploitation"
}

enum AttackAction {
    case networkScan(ports: String)
    case bluetoothDiscovery
    case webServiceEnumeration
    case cveCorrelation
    case webVulnerabilityScanning
    case bluetoothVulnerabilityTesting
    case networkExploit(port: Int, service: String)
    case webExploit(url: String)
    case bluetoothExploit(deviceId: String)
    case privilegeEscalation
    case lateralMovement
    case dataExfiltration
    case persistentAccess
    
    var estimatedTime: TimeInterval {
        switch self {
        case .networkScan: return 300 // 5 minutes
        case .bluetoothDiscovery: return 60 // 1 minute
        case .webServiceEnumeration: return 120 // 2 minutes
        case .cveCorrelation: return 30 // 30 seconds
        case .webVulnerabilityScanning: return 600 // 10 minutes
        case .bluetoothVulnerabilityTesting: return 300 // 5 minutes
        case .networkExploit: return 180 // 3 minutes
        case .webExploit: return 120 // 2 minutes
        case .bluetoothExploit: return 240 // 4 minutes
        case .privilegeEscalation: return 300 // 5 minutes
        case .lateralMovement: return 600 // 10 minutes
        case .dataExfiltration: return 120 // 2 minutes
        case .persistentAccess: return 180 // 3 minutes
        }
    }
    
    var successProbability: Double {
        switch self {
        case .networkScan, .bluetoothDiscovery, .webServiceEnumeration, .cveCorrelation:
            return 0.95 // High success rate for discovery
        case .webVulnerabilityScanning, .bluetoothVulnerabilityTesting:
            return 0.85 // Good success rate for vulnerability testing
        case .networkExploit, .webExploit, .bluetoothExploit:
            return 0.60 // Moderate success rate for exploitation
        case .privilegeEscalation, .lateralMovement:
            return 0.40 // Lower success rate for advanced techniques
        case .dataExfiltration, .persistentAccess:
            return 0.70 // Good success rate if exploitation successful
        }
    }
}

// MARK: - Unified Reporting

struct UnifiedReport {
    var executiveSummary: ExecutiveSummary?
    var technicalFindings: [TechnicalFinding] = []
    var attackChains: [AttackChainAnalysis] = []
    var riskAssessment: RiskAssessment?
    var recommendations: [Recommendation] = []
}

struct ExecutiveSummary {
    var overallRisk: RiskLevel = .low
    var criticalIssues: Int = 0
    var highRiskIssues: Int = 0
    var testedAssets: Int = 0
    var keyFindings: [String] = []
}

struct TechnicalFinding {
    let target: String
    let findings: [IntelligenceFinding]
    let riskScore: Double
    let attackSurface: Int
}

struct AttackChainAnalysis {
    let target: String
    let phases: [AttackPhase]
    let estimatedTime: TimeInterval
    let successProbability: Double
}

struct RiskAssessment {
    let networkRisk: RiskLevel
    let webApplicationRisk: RiskLevel
    let bluetoothRisk: RiskLevel
    let overallRisk: RiskLevel
    let riskFactors: [String]
}

struct Recommendation {
    let priority: Priority
    let category: FindingType
    let description: String
    let effort: Effort
    let impact: Impact
    
    enum Priority: Int, CaseIterable {
        case critical = 4
        case high = 3
        case medium = 2
        case low = 1
    }
    
    enum Effort: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
    }
    
    enum Impact: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
    }
}

enum RiskLevel: String, CaseIterable {
    case critical = "Critical"
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let triggerWebTesting = Notification.Name("triggerWebTesting")
    static let triggerCredentialTesting = Notification.Name("triggerCredentialTesting")
    static let triggerDatabaseTesting = Notification.Name("triggerDatabaseTesting")
    static let suggestExploit = Notification.Name("suggestExploit")
    static let suggestCoordinatedAttack = Notification.Name("suggestCoordinatedAttack")
    static let suggestPrivilegeEscalation = Notification.Name("suggestPrivilegeEscalation")
    static let correlationFound = Notification.Name("correlationFound")
}