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
    
    enum Severity: String, Hashable {
        case informational, low, medium, high
        
        var color: Color {
            switch self {
            case .informational: return .blue
            case .low: return .green
            case .medium: return .orange
            case .high: return .red
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
    
    // Active scanning state
    var activeScans: [String: String] = [:]
    var allVulnerabilities: [Vulnerability] = []
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
        case cveManager
        case networkScanner
        case webTesting
        case dosStressTesting
        case activeAttacks
        case reporting
        case settings
        
        var title: String {
            switch self {
            case .dashboard: return "Dashboard"
            case .cveManager: return "CVE Manager"
            case .networkScanner: return "Network Scanner"
            case .webTesting: return "Web Testing"
            case .dosStressTesting: return "DoS/Stress Testing"
            case .activeAttacks: return "Active Attacks"
            case .reporting: return "Reporting"
            case .settings: return "Settings"
            }
        }
        
        var systemImage: String {
            switch self {
            case .dashboard: return "gauge"
            case .cveManager: return "shield.checkerboard"
            case .networkScanner: return "network"
            case .webTesting: return "globe"
            case .dosStressTesting: return "exclamationmark.triangle.fill"
            case .activeAttacks: return "bolt.badge.clock"
            case .reporting: return "doc.text"
            case .settings: return "gear"
            }
        }
    }
    
    enum AppView: Hashable {
        case home
        case targetDetails
        case vulnerabilityDetails
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
    func startWebScan(targetURL: String) {
        isWebScanning = true
        currentWebTarget = targetURL
        // Mock scanning logic
    }
    
    func stopWebScan() {
        isWebScanning = false
        currentWebTarget = ""
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


// MARK: - Mock Data Extensions

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
        WebScanResult(type: "SQL Injection", description: "Found a potential SQL injection point.", url: "https://example.com/login", severity: .high)
    }
}

extension NetworkAttackVector {
    static var mockSsh: NetworkAttackVector {
        NetworkAttackVector(name: "SSH Brute Force", description: "Default credentials for SSH.", severity: .high, tools: ["hydra", "nmap"], commands: ["hydra -l root -P /path/to/passwords.txt ssh://<TARGET>"])
    }
}