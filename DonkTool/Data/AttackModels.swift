//
//  AttackModels.swift
//  DonkTool
//
//  Attack framework data models
//

import Foundation
import SwiftUI

// MARK: - Offensive Security Attack Vector
// This is a new type specifically for offensive security tools
struct OffensiveAttackVector: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let category: AttackCategory
    let requiredTools: [OffensiveAttackTool]
    let commands: [String]
    let severity: AttackSeverity
    let estimatedDuration: Int // seconds
    
    var isExecutable: Bool {
        requiredTools.allSatisfy { tool in
            ToolDetection.shared.isToolInstalled(tool.rawValue)
        }
    }
}

// MARK: - Attack Category

enum AttackCategory: String, CaseIterable, Codable {
    case reconnaissance = "reconnaissance"
    case bruteForce = "bruteforce"
    case webExploitation = "web"
    case networkExploitation = "network"
    case dosStress = "dos"
    case vulnerability = "vulnerability"
    case wireless = "wireless"
    case fuzzing = "fuzzing"
    case passwordCracking = "passwordCracking"
    
    var displayName: String {
        switch self {
        case .reconnaissance: return "Reconnaissance"
        case .bruteForce: return "Brute Force"
        case .webExploitation: return "Web Exploitation"
        case .networkExploitation: return "Network Exploitation"
        case .dosStress: return "DoS/Stress Testing"
        case .vulnerability: return "Vulnerability Assessment"
        case .wireless: return "Wireless Attacks"
        case .fuzzing: return "Fuzzing"
        case .passwordCracking: return "Password Cracking"
        }
    }
}

// MARK: - Offensive Attack Tool

struct OffensiveAttackTool: RawRepresentable, Hashable, Codable {
    let rawValue: String
    
    init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    // Offensive security tools
    static let amass = OffensiveAttackTool(rawValue: "amass")
    static let theHarvester = OffensiveAttackTool(rawValue: "theharvester")
    static let reconNg = OffensiveAttackTool(rawValue: "recon-ng")
    static let xsstrike = OffensiveAttackTool(rawValue: "xsstrike")
    static let dalfox = OffensiveAttackTool(rawValue: "dalfox")
    static let arjun = OffensiveAttackTool(rawValue: "arjun")
    static let paramspider = OffensiveAttackTool(rawValue: "paramspider")
    static let aircrackNg = OffensiveAttackTool(rawValue: "aircrack-ng")
    static let bettercap = OffensiveAttackTool(rawValue: "bettercap")
    static let john = OffensiveAttackTool(rawValue: "john")
    static let hashcat = OffensiveAttackTool(rawValue: "hashcat")
    static let smbmap = OffensiveAttackTool(rawValue: "smbmap")
    static let crackmapexec = OffensiveAttackTool(rawValue: "crackmapexec")
    static let responder = OffensiveAttackTool(rawValue: "responder")
    static let wpscan = OffensiveAttackTool(rawValue: "wpscan")
    static let aflPlusPlus = OffensiveAttackTool(rawValue: "afl++")
    static let radamsa = OffensiveAttackTool(rawValue: "radamsa")
    static let photon = OffensiveAttackTool(rawValue: "photon")
    static let dnsrecon = OffensiveAttackTool(rawValue: "dnsrecon")
    static let sublist3r = OffensiveAttackTool(rawValue: "sublist3r")
}

// MARK: - Attack Severity

enum AttackSeverity: String, CaseIterable, Codable {
    case info = "info"
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var color: Color {
        switch self {
        case .info: return .blue
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Offensive Attack Session

struct OffensiveAttackSession: Identifiable {
    let id = UUID()
    let sessionId: String
    let attack: OffensiveAttackVector
    let target: String
    let port: Int
    let startTime: Date
    var endTime: Date?
    var status: AttackStatus = .preparing
    var output: [String] = []
    var progress: Double = 0.0
    
    var duration: TimeInterval {
        if let endTime = endTime {
            return endTime.timeIntervalSince(startTime)
        } else {
            return Date().timeIntervalSince(startTime)
        }
    }
}

// MARK: - Attack Status

enum AttackStatus: String, CaseIterable {
    case preparing = "Preparing"
    case running = "Running"
    case completed = "Completed"
    case failed = "Failed"
    case stopped = "Stopped"
    
    var icon: String {
        switch self {
        case .preparing: return "clock.fill"
        case .running: return "play.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .stopped: return "stop.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .preparing: return .gray
        case .running: return .blue
        case .completed: return .green
        case .failed: return .red
        case .stopped: return .orange
        }
    }
}

// MARK: - Offensive Attack Result

struct OffensiveAttackResult: Identifiable, Codable {
    let id: UUID
    let sessionId: String
    let attack: OffensiveAttackVector
    let target: String
    let port: Int
    let startTime: Date
    let endTime: Date
    let success: Bool
    let output: [String]
    let credentials: [OffensiveCredential]
    let vulnerabilities: [OffensiveVulnerabilityFinding]
    let files: [String]
    
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, sessionId, attack, target, port, startTime, endTime, success, output, credentials, vulnerabilities, files
    }
    
    init(id: UUID = UUID(), sessionId: String, attack: OffensiveAttackVector, target: String, port: Int, startTime: Date, endTime: Date, success: Bool, output: [String], credentials: [OffensiveCredential], vulnerabilities: [OffensiveVulnerabilityFinding], files: [String]) {
        self.id = id
        self.sessionId = sessionId
        self.attack = attack
        self.target = target
        self.port = port
        self.startTime = startTime
        self.endTime = endTime
        self.success = success
        self.output = output
        self.credentials = credentials
        self.vulnerabilities = vulnerabilities
        self.files = files
    }
}

// MARK: - Offensive Credential

struct OffensiveCredential: Identifiable, Codable {
    let id: UUID
    let username: String
    let password: String
    let service: String
    let host: String
    let port: Int
    let discoveredAt: Date
    
    init(id: UUID = UUID(), username: String, password: String, service: String, host: String, port: Int, discoveredAt: Date) {
        self.id = id
        self.username = username
        self.password = password
        self.service = service
        self.host = host
        self.port = port
        self.discoveredAt = discoveredAt
    }
}

// MARK: - Offensive Vulnerability Finding

struct OffensiveVulnerabilityFinding: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let severity: String
    let cveId: String?
    let evidence: String?
    let remediation: String?
    let affectedComponent: String?
    
    init(id: UUID = UUID(), title: String, description: String, severity: String, cveId: String? = nil, evidence: String? = nil, remediation: String? = nil, affectedComponent: String? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.severity = severity
        self.cveId = cveId
        self.evidence = evidence
        self.remediation = remediation
        self.affectedComponent = affectedComponent
    }
}

// MARK: - Offensive Port Scan Result

struct OffensivePortScanResult: Identifiable, Codable {
    let id: UUID
    let port: Int
    let service: String?
    let version: String?
    let banner: String?
    let isOpen: Bool
    
    init(id: UUID = UUID(), port: Int, service: String? = nil, version: String? = nil, banner: String? = nil, isOpen: Bool) {
        self.id = id
        self.port = port
        self.service = service
        self.version = version
        self.banner = banner
        self.isOpen = isOpen
    }
}