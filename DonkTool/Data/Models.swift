//
//  Models.swift
//  DonkTool
//
//  Data model for penetration testing targets
//

import Foundation

struct Target: Identifiable, Codable {
    let id: UUID
    var name: String
    var ipAddress: String
    var domain: String?
    var ports: [Int]
    var notes: String
    var lastScanned: Date?
    var vulnerabilities: [Vulnerability]
    var status: TargetStatus
    
    enum TargetStatus: String, CaseIterable, Codable {
        case pending = "Pending"
        case scanning = "Scanning"
        case completed = "Completed"
        case failed = "Failed"
    }
    
    init(name: String, ipAddress: String, domain: String? = nil) {
        self.id = UUID()
        self.name = name
        self.ipAddress = ipAddress
        self.domain = domain
        self.ports = []
        self.notes = ""
        self.vulnerabilities = []
        self.status = .pending
    }
}

struct Vulnerability: Identifiable, Codable {
    let id: UUID
    var cveId: String?
    var title: String
    var description: String
    var severity: Severity
    var port: Int?
    var service: String?
    var discoveredAt: Date
    
    enum Severity: String, CaseIterable, Codable {
        case critical = "Critical"
        case high = "High"
        case medium = "Medium"
        case low = "Low"
        case info = "Informational"
        
        var color: String {
            switch self {
            case .critical: return "red"
            case .high: return "orange"
            case .medium: return "yellow"
            case .low: return "blue"
            case .info: return "gray"
            }
        }
    }
    
    init(cveId: String? = nil, title: String, description: String, severity: Severity, port: Int? = nil, service: String? = nil, discoveredAt: Date) {
        self.id = UUID()
        self.cveId = cveId
        self.title = title
        self.description = description
        self.severity = severity
        self.port = port
        self.service = service
        self.discoveredAt = discoveredAt
    }
}

struct ScanResult: Identifiable, Codable {
    let id: UUID
    var targetId: UUID
    var scanType: ScanType
    var startTime: Date
    var endTime: Date?
    var status: ScanStatus
    var results: [String: String] // Changed from [String: Any] to [String: String]
    var detailedResults: String? // Additional field for complex results
    
    enum ScanType: String, CaseIterable, Codable {
        case portScan = "Port Scan"
        case vulnScan = "Vulnerability Scan"
        case webScan = "Web Application Scan"
    }
    
    enum ScanStatus: String, CaseIterable, Codable {
        case running = "Running"
        case completed = "Completed"
        case failed = "Failed"
        case cancelled = "Cancelled"
    }
    
    init(targetId: UUID, scanType: ScanType) {
        self.id = UUID()
        self.targetId = targetId
        self.scanType = scanType
        self.startTime = Date()
        self.status = .running
        self.results = [:]
        self.detailedResults = nil
    }
    
    // Helper methods for working with results
    mutating func addResult(key: String, value: String) {
        results[key] = value
    }
    
    mutating func setDetailedResults(_ details: String) {
        detailedResults = details
    }
}
