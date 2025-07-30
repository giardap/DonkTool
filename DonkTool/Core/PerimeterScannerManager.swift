//
//  PerimeterScannerManager.swift
//  DonkTool
//
//  Advanced Perimeter Scanner Integration with Python Backend
//

import Foundation
import SwiftUI
import Combine

// MARK: - Perimeter Scanner Data Models

struct PerimeterScanResults: Codable {
    let scanId: String
    let timestamp: String
    let targets: [String]
    let discovery: [DiscoveredHost]
    let ports: [HostPortScan]
    let services: [HostServiceScan]
    let vulnerabilities: [PerimeterVulnerability]
    let analysis: PerimeterAnalysis
    
    enum CodingKeys: String, CodingKey {
        case scanId = "scan_id"
        case timestamp, targets, discovery, ports, services, vulnerabilities, analysis
    }
}

struct PerimeterAnalysis: Codable {
    let totalHosts: Int
    let openPorts: Int
    let exposedServices: Int
    let highRiskFindings: Int
    let mediumRiskFindings: Int
    let recommendations: [String]
    
    enum CodingKeys: String, CodingKey {
        case totalHosts = "total_hosts"
        case openPorts = "open_ports"
        case exposedServices = "exposed_services"
        case highRiskFindings = "high_risk_findings"
        case mediumRiskFindings = "medium_risk_findings"
        case recommendations
    }
}

struct DiscoveredHost: Codable, Identifiable {
    let id = UUID()
    let ip: String
    let hostname: String?
    let mac: String?
    let vendor: String?
    let distance: Int?
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case ip, hostname, mac, vendor, distance, status
    }
}

struct HostPortScan: Codable, Identifiable {
    let id = UUID()
    let ip: String
    let ports: [PortDetail]
    
    enum CodingKeys: String, CodingKey {
        case ip, ports
    }
}

struct PortDetail: Codable, Identifiable {
    let id = UUID()
    let port: Int
    let portProtocol: String
    let state: String
    let service: String?
    let version: String?
    let banner: String?
    
    enum CodingKeys: String, CodingKey {
        case port
        case portProtocol = "protocol"
        case state, service, version, banner
    }
}

struct HostServiceScan: Codable, Identifiable {
    let id = UUID()
    let ip: String
    let port: Int
    let service: String
    let version: String?
    let info: String?
    let cpe: [String]
    let scripts: [String: String]
    
    enum CodingKeys: String, CodingKey {
        case ip, port, service, version, info, cpe, scripts
    }
}

struct PerimeterVulnerability: Codable, Identifiable {
    let id = UUID()
    let ip: String
    let port: Int
    let service: String
    let vulnerability: String
    let severity: String
    let description: String
    let solution: String?
    let cveId: String?
    let cvss: Double?
    
    enum CodingKeys: String, CodingKey {
        case ip, port, service, vulnerability, severity, description, solution
        case cveId = "cve_id"
        case cvss
    }
}

struct UnauthorizedService: Identifiable {
    let id = UUID()
    let ip: String
    let port: Int
    let service: String
    let risk: RiskLevel
    let discovered: Date
    
    enum RiskLevel: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }
    }
}

struct NetworkRange: Identifiable {
    let id = UUID()
    let cidr: String
    let description: String
}

struct AlertRule: Identifiable {
    let id = UUID()
    let name: String
    let condition: AlertCondition
    let enabled: Bool
    let notification: NotificationType
    
    enum AlertCondition {
        case newHost
        case openPort(Int)
        case serviceDetected(String)
        case vulnerabilityFound
        case serviceRisk(UnauthorizedService.RiskLevel)
    }
    
    enum NotificationType {
        case email(String)
        case webhook(URL)
        case inApp
    }
    
    func matches(service: UnauthorizedService) -> Bool {
        switch condition {
        case .serviceRisk(let level):
            return service.risk == level
        default:
            return false
        }
    }
}

// MARK: - Python Bridge

class PerimeterPythonBridge {
    private let pythonScriptPath: String
    
    init() {
        self.pythonScriptPath = Bundle.main.path(forResource: "perimeter_scanner", ofType: "py") ?? ""
    }
    
    func executePerimeterScan(ranges: [String], progressHandler: @escaping (String, Double) -> Void) async throws -> PerimeterScanResults {
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = [pythonScriptPath, "--ranges"] + ranges + ["--format", "json"]
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        try process.run()
        
        // Read output
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        
        if let errorString = String(data: errorData, encoding: .utf8), !errorString.isEmpty {
            print("Python error: \(errorString)")
        }
        
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            throw PerimeterScanError.pythonScriptFailed
        }
        
        // Parse JSON output
        let decoder = JSONDecoder()
        return try decoder.decode(PerimeterScanResults.self, from: outputData)
    }
}

enum PerimeterScanError: Error {
    case pythonScriptFailed
    case invalidOutput
    case scanTimeout
}

// MARK: - Perimeter Scanner Manager

@Observable
@MainActor
class PerimeterScannerManager {
    static let shared = PerimeterScannerManager()
    
    var isScanning = false
    var scanProgress: Double = 0.0
    var currentResults: PerimeterScanResults?
    var unauthorizedServices: [UnauthorizedService] = []
    var scanHistory: [PerimeterScanResults] = []
    var monitoringTargets: [NetworkRange] = []
    var alertingRules: [AlertRule] = []
    var lastError: String?
    var currentPhase: String = ""
    
    // Callbacks for integration
    var onVulnerabilitiesDiscovered: (([PerimeterVulnerability]) -> Void)?
    var onNewHostsDiscovered: (([DiscoveredHost]) -> Void)?
    
    private let pythonBridge = PerimeterPythonBridge()
    private var monitoringTimer: Timer?
    
    private init() {
        setupDefaultConfiguration()
    }
    
    private func setupDefaultConfiguration() {
        // Load default monitoring targets
        monitoringTargets = [
            NetworkRange(cidr: "10.0.0.0/24", description: "Internal Network"),
            NetworkRange(cidr: "192.168.1.0/24", description: "Home Network"),
            NetworkRange(cidr: "172.16.0.0/16", description: "Private Network")
        ]
        
        // Load default alerting rules
        alertingRules = [
            AlertRule(
                name: "High Risk Service Detected",
                condition: .serviceRisk(.high),
                enabled: true,
                notification: .inApp
            ),
            AlertRule(
                name: "Critical Service Exposure",
                condition: .serviceRisk(.critical),
                enabled: true,
                notification: .inApp
            )
        ]
    }
    
    func startPerimeterScan(ranges: [String] = []) async {
        let targetRanges = ranges.isEmpty ? monitoringTargets.map(\.cidr) : ranges
        
        guard !targetRanges.isEmpty else {
            lastError = "No target ranges specified"
            return
        }
        
        isScanning = true
        scanProgress = 0.0
        lastError = nil
        currentPhase = "Initializing"
        
        do {
            currentResults = try await pythonBridge.executePerimeterScan(
                ranges: targetRanges
            ) { phase, progress in
                // This will be called synchronously for now
                Task { @MainActor in
                    self.currentPhase = phase
                    self.scanProgress = progress
                }
            }
            
            // Process results
            await processResults()
            
            // Save to history
            if let results = currentResults {
                scanHistory.append(results)
            }
            
            // Trigger callbacks
            if let vulnerabilities = currentResults?.vulnerabilities,
               !vulnerabilities.isEmpty {
                onVulnerabilitiesDiscovered?(vulnerabilities)
            }
            
            if let hosts = currentResults?.discovery,
               !hosts.isEmpty {
                onNewHostsDiscovered?(hosts)
            }
            
        } catch {
            lastError = "Scan failed: \(error.localizedDescription)"
        }
        
        isScanning = false
        currentPhase = ""
    }
    
    func startContinuousMonitoring(intervalMinutes: Int = 60) {
        stopMonitoring()
        
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(intervalMinutes * 60), repeats: true) { _ in
            Task {
                await self.startPerimeterScan()
            }
        }
    }
    
    func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    private func processResults() async {
        guard let results = currentResults else { return }
        
        // Identify unauthorized services
        unauthorizedServices.removeAll()
        
        for service in results.services {
            if isUnauthorized(service) {
                let risk = assessRisk(service)
                let unauthorizedService = UnauthorizedService(
                    ip: service.ip,
                    port: service.port,
                    service: service.service,
                    risk: risk,
                    discovered: Date()
                )
                unauthorizedServices.append(unauthorizedService)
            }
        }
        
        // Check alerting rules
        for service in unauthorizedServices {
            for rule in alertingRules where rule.enabled {
                if rule.matches(service: service) {
                    await triggerAlert(rule: rule, service: service)
                }
            }
        }
    }
    
    private func isUnauthorized(_ service: HostServiceScan) -> Bool {
        // Define authorized services
        let authorizedServices = ["ssh", "http", "https", "dns"]
        let authorizedPorts = [22, 80, 443, 53]
        
        return !authorizedServices.contains(service.service.lowercased()) &&
               !authorizedPorts.contains(service.port)
    }
    
    private func assessRisk(_ service: HostServiceScan) -> UnauthorizedService.RiskLevel {
        // Risk assessment logic
        let highRiskServices = ["telnet", "ftp", "rlogin", "vnc", "rdp"]
        let criticalPorts = [23, 135, 139, 445, 3389]
        
        if criticalPorts.contains(service.port) {
            return .critical
        } else if highRiskServices.contains(service.service.lowercased()) {
            return .high
        } else if service.port < 1024 {
            return .medium
        } else {
            return .low
        }
    }
    
    private func triggerAlert(rule: AlertRule, service: UnauthorizedService) async {
        switch rule.notification {
        case .inApp:
            // Handle in-app notification
            print("ALERT: \(rule.name) - \(service.service) on \(service.ip):\(service.port)")
        case .email(let address):
            // Send email alert
            print("Email alert to \(address)")
        case .webhook(let url):
            // Send webhook
            print("Webhook to \(url)")
        }
    }
    
    // MARK: - Public Methods
    
    func addMonitoringTarget(_ range: NetworkRange) {
        monitoringTargets.append(range)
    }
    
    func removeMonitoringTarget(_ range: NetworkRange) {
        monitoringTargets.removeAll { $0.id == range.id }
    }
    
    func addAlertingRule(_ rule: AlertRule) {
        alertingRules.append(rule)
    }
    
    func toggleAlertingRule(_ ruleId: UUID) {
        if let index = alertingRules.firstIndex(where: { $0.id == ruleId }) {
            alertingRules[index] = AlertRule(
                name: alertingRules[index].name,
                condition: alertingRules[index].condition,
                enabled: !alertingRules[index].enabled,
                notification: alertingRules[index].notification
            )
        }
    }
    
    func exportResults(format: ExportFormat) -> Data? {
        guard let results = currentResults else { return nil }
        
        switch format {
        case .json:
            return try? JSONEncoder().encode(results)
        case .csv:
            return generateCSV(from: results).data(using: .utf8)
        case .pdf:
            // Generate PDF report
            return nil
        }
    }
    
    private func generateCSV(from results: PerimeterScanResults) -> String {
        var csv = "IP,Hostname,Port,Service,Risk,Vulnerability\n"
        
        for vuln in results.vulnerabilities {
            csv += "\(vuln.ip),\(results.discovery.first { $0.ip == vuln.ip }?.hostname ?? ""),\(vuln.port),\(vuln.service),\(vuln.severity),\(vuln.vulnerability)\n"
        }
        
        return csv
    }
    
    enum ExportFormat {
        case json
        case csv
        case pdf
    }
}