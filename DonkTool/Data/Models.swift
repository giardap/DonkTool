//
//  Models.swift
//  DonkTool
//
//  Data models for the application
//

import Foundation
import SwiftUI

struct Target: Identifiable, Codable {
    let id: UUID
    var name: String
    var ipAddress: String
    var domain: String?
    var vulnerabilities: [Vulnerability] = []
    
    init(name: String, ipAddress: String, domain: String? = nil) {
        self.id = UUID()
        self.name = name
        self.ipAddress = ipAddress
        self.domain = domain
        self.vulnerabilities = []
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
    
    init(cveId: String? = nil, title: String, description: String, severity: Severity, port: Int? = nil, service: String? = nil, discoveredAt: Date = Date()) {
        self.id = UUID()
        self.cveId = cveId
        self.title = title
        self.description = description
        self.severity = severity
        self.port = port
        self.service = service
        self.discoveredAt = discoveredAt
    }
    
    enum Severity: String, CaseIterable, Codable {
        case low, medium, high, critical, info
        
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
}

struct ScanResult: Identifiable, Codable {
    let id: UUID
    var targetId: UUID
    var scanType: ScanType
    var startTime: Date
    var endTime: Date?
    var status: ScanStatus
    var vulnerabilities: [Vulnerability] = []
    
    init(targetId: UUID, scanType: ScanType) {
        self.id = UUID()
        self.targetId = targetId
        self.scanType = scanType
        self.startTime = Date()
        self.status = .running
    }
    
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
}

struct ToolRequirement: Codable {
    let name: String
    let type: RequirementType
    let description: String
    
    enum RequirementType: String, Codable {
        case tool
        case optional
        case builtin
        case gui
    }
}

struct AttackVector: Identifiable, Codable {
    let id = UUID()
    let name: String
    let description: String
    let severity: Vulnerability.Severity
    let requirements: [ToolRequirement]
    let commands: [String]
    let references: [String]
    
    var isExecutable: Bool {
        return requirements.allSatisfy { requirement in
            switch requirement.type {
            case .tool:
                return ToolDetection.shared.isToolInstalled(requirement.name)
            case .optional:
                return true // Optional requirements don't block execution
            case .builtin:
                return true // Built-in tools are always available
            case .gui:
                return ToolDetection.shared.isToolInstalled(requirement.name)
            }
        }
    }
    
    var missingRequiredTools: [ToolRequirement] {
        return requirements.filter { requirement in
            requirement.type == .tool && !ToolDetection.shared.isToolInstalled(requirement.name)
        }
    }
    
    var availableTools: [ToolRequirement] {
        return requirements.filter { requirement in
            switch requirement.type {
            case .builtin:
                return true
            case .optional, .tool, .gui:
                return ToolDetection.shared.isToolInstalled(requirement.name)
            }
        }
    }
    
    var tools: [String] {
        return requirements.map { $0.name }
    }
    
    var attackType: AttackType = .networkRecon
    var difficulty: AttackDifficulty = .beginner
    
    enum AttackType: String, CaseIterable, Codable {
        case bruteForce = "Brute Force"
        case webDirectoryEnum = "Web Directory Enumeration"
        case vulnerabilityExploit = "Vulnerability Exploit"
        case networkRecon = "Network Reconnaissance"
        case webVulnScan = "Web Vulnerability Scan"
        
        var icon: String {
            switch self {
            case .bruteForce: return "key.fill"
            case .webDirectoryEnum: return "folder.fill"
            case .vulnerabilityExploit: return "exclamationmark.triangle.fill"
            case .networkRecon: return "network"
            case .webVulnScan: return "globe"
            }
        }
    }
    
    enum AttackDifficulty: String, CaseIterable, Codable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        case expert = "Expert"
        
        var color: Color {
            switch self {
            case .beginner: return .green
            case .intermediate: return .yellow
            case .advanced: return .orange
            case .expert: return .red
            }
        }
    }
    
    enum AttackSeverity: String, CaseIterable, Codable {
        case info = "Info"
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        
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
}

struct PortScanResult: Identifiable, Codable {
    let id = UUID()
    let port: Int
    let isOpen: Bool
    let service: String?
    let scanTime: Date
    let banner: String?
    let version: String?
    let attackVectors: [AttackVector]
    let riskLevel: RiskLevel
    
    enum RiskLevel: String, CaseIterable, Codable {
        case info = "Info"
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        
        var color: Color {
            switch self {
            case .info: return .blue
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }
        
        var rawValue: String {
            switch self {
            case .info: return "Info"
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            case .critical: return "Critical"
            }
        }
    }
    
    // Custom CodingKeys to handle the id property
    private enum CodingKeys: String, CodingKey {
        case port, isOpen, service, scanTime, banner, version, attackVectors, riskLevel
    }
    
    init(port: Int, isOpen: Bool, service: String?, scanTime: Date = Date(), banner: String? = nil, version: String? = nil, attackVectors: [AttackVector] = [], riskLevel: RiskLevel = .info) {
        self.port = port
        self.isOpen = isOpen
        self.service = service
        self.scanTime = scanTime
        self.banner = banner
        self.version = version
        self.attackVectors = attackVectors
        self.riskLevel = riskLevel
    }
}

struct WebTest: Hashable, CaseIterable {
    let name: String
    let description: String
    let severity: WebTestSeverity
    
    enum WebTestSeverity: String, CaseIterable {
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
    
    // OWASP Top 10 2021 Based Tests
    static let sqlInjection = WebTest(name: "SQL Injection", description: "Test for SQL injection vulnerabilities (A03:2021)", severity: .critical)
    static let xss = WebTest(name: "Cross-Site Scripting", description: "Test for XSS vulnerabilities (A03:2021)", severity: .critical)
    static let directoryTraversal = WebTest(name: "Directory Traversal", description: "Test for path traversal vulnerabilities (A01:2021)", severity: .high)
    static let authenticationBypass = WebTest(name: "Authentication Bypass", description: "Test for authentication bypass (A07:2021)", severity: .high)
    static let httpHeaderSecurity = WebTest(name: "HTTP Header Security", description: "Check for security headers (A05:2021)", severity: .medium)
    static let sslTlsConfiguration = WebTest(name: "SSL/TLS Configuration", description: "Test SSL/TLS configuration (A02:2021)", severity: .medium)
    
    // Additional OWASP Top 10 Tests
    static let brokenAccessControl = WebTest(name: "Broken Access Control", description: "Test for access control vulnerabilities (A01:2021)", severity: .critical)
    static let cryptographicFailures = WebTest(name: "Cryptographic Failures", description: "Test for weak cryptography (A02:2021)", severity: .high)
    static let insecureDesign = WebTest(name: "Insecure Design", description: "Test for design flaws and missing controls (A04:2021)", severity: .high)
    static let securityMisconfiguration = WebTest(name: "Security Misconfiguration", description: "Test for security misconfigurations (A05:2021)", severity: .medium)
    static let vulnerableComponents = WebTest(name: "Vulnerable Components", description: "Test for outdated/vulnerable components (A06:2021)", severity: .high)
    static let identificationFailures = WebTest(name: "Identification Failures", description: "Test for authentication and session issues (A07:2021)", severity: .high)
    static let dataIntegrityFailures = WebTest(name: "Data Integrity Failures", description: "Test for software/data integrity failures (A08:2021)", severity: .medium)
    static let loggingFailures = WebTest(name: "Logging Failures", description: "Test for insufficient logging and monitoring (A09:2021)", severity: .low)
    static let ssrf = WebTest(name: "Server-Side Request Forgery", description: "Test for SSRF vulnerabilities (A10:2021)", severity: .high)
    
    // Additional Modern Web Security Tests
    static let csrf = WebTest(name: "Cross-Site Request Forgery", description: "Test for CSRF vulnerabilities", severity: .medium)
    static let cors = WebTest(name: "CORS Misconfiguration", description: "Test for CORS policy issues", severity: .medium)
    static let clickjacking = WebTest(name: "Clickjacking", description: "Test for X-Frame-Options and CSP frame-ancestors", severity: .medium)
    static let fileUpload = WebTest(name: "File Upload", description: "Test for insecure file upload mechanisms", severity: .high)
    static let businessLogic = WebTest(name: "Business Logic", description: "Test for business logic flaws", severity: .medium)
    static let apiSecurity = WebTest(name: "API Security", description: "Test for REST/GraphQL API vulnerabilities", severity: .high)
    static let webSockets = WebTest(name: "WebSocket Security", description: "Test for WebSocket vulnerabilities", severity: .medium)
    static let csp = WebTest(name: "Content Security Policy", description: "Test CSP implementation and bypasses", severity: .medium)
    static let xxe = WebTest(name: "XML External Entities", description: "Test for XXE vulnerabilities", severity: .high)
    static let ldapInjection = WebTest(name: "LDAP Injection", description: "Test for LDAP injection vulnerabilities", severity: .high)
    static let commandInjection = WebTest(name: "Command Injection", description: "Test for OS command injection", severity: .critical)
    static let templateInjection = WebTest(name: "Template Injection", description: "Test for server-side template injection", severity: .high)
    static let deserializationAttacks = WebTest(name: "Deserialization", description: "Test for insecure deserialization", severity: .high)
    static let comprehensiveWebScan = WebTest(name: "Comprehensive Web Scan", description: "Full Nikto-based vulnerability assessment", severity: .critical)
    static let nucleiScan = WebTest(name: "Nuclei Vulnerability Scan", description: "Fast vulnerability scanner with 9000+ templates", severity: .critical)
    static let httpProbing = WebTest(name: "HTTP Service Analysis", description: "HTTPx-based service detection and analysis", severity: .medium)
    static let subdomainEnumeration = WebTest(name: "Subdomain Discovery", description: "Subfinder-based subdomain enumeration", severity: .medium)
    static let advancedFuzzing = WebTest(name: "Advanced Web Fuzzing", description: "FFuF-based parameter and directory fuzzing", severity: .high)
    static let sslTlsAnalysis = WebTest(name: "SSL/TLS Security Analysis", description: "SSLyze-based certificate and configuration testing", severity: .high)
    
    // DoS/Stress Testing (Only for authorized testing)
    static let httpStressTesting = WebTest(name: "HTTP Stress Testing", description: "Wrk-based load testing to identify capacity limits", severity: .medium)
    static let slowlorisTest = WebTest(name: "Slowloris Attack Test", description: "Test for slow HTTP DoS vulnerabilities", severity: .high)
    static let connectionExhaustion = WebTest(name: "Connection Exhaustion Test", description: "Test server connection limits", severity: .medium)
    
    static var allCases: [WebTest] {
        return [
            // OWASP Top 10 2021
            .brokenAccessControl, .cryptographicFailures, .sqlInjection, .insecureDesign,
            .securityMisconfiguration, .vulnerableComponents, .identificationFailures,
            .dataIntegrityFailures, .loggingFailures, .ssrf,
            
            // Classic Web Vulnerabilities
            .xss, .csrf, .directoryTraversal, .authenticationBypass, .fileUpload,
            
            // Modern Web Security
            .cors, .clickjacking, .businessLogic, .apiSecurity, .webSockets,
            .csp, .httpHeaderSecurity, .sslTlsConfiguration,
            
            // Injection Attacks
            .xxe, .ldapInjection, .commandInjection, .templateInjection,
            .deserializationAttacks,
            
            // Comprehensive Scanning
            .comprehensiveWebScan,
            
            // Modern Security Tools
            .nucleiScan, .httpProbing, .subdomainEnumeration, .advancedFuzzing, .sslTlsAnalysis,
            
            // DoS/Stress Testing (Authorized Use Only)
            .httpStressTesting, .slowlorisTest, .connectionExhaustion
        ]
    }
    
    var displayName: String {
        return name
    }
    
    var recommendations: String {
        switch self {
        // OWASP Top 10 2021
        case .brokenAccessControl:
            return "Implement proper authorization checks, use least privilege principle, deny by default"
        case .cryptographicFailures:
            return "Use strong encryption algorithms, proper key management, avoid hardcoded secrets"
        case .sqlInjection:
            return "Use parameterized queries, stored procedures, input validation, least privilege DB access"
        case .insecureDesign:
            return "Implement security by design, threat modeling, secure development lifecycle"
        case .securityMisconfiguration:
            return "Secure default configurations, regular security updates, remove unused features"
        case .vulnerableComponents:
            return "Keep components updated, use dependency scanning, remove unused dependencies"
        case .identificationFailures:
            return "Implement strong authentication, MFA, secure session management"
        case .dataIntegrityFailures:
            return "Implement digital signatures, code signing, CI/CD security"
        case .loggingFailures:
            return "Implement comprehensive logging, monitoring, incident response"
        case .ssrf:
            return "Validate and sanitize URLs, use allowlists, network segmentation"
            
        // Classic Web Vulnerabilities
        case .xss:
            return "Implement proper output encoding, Content Security Policy, input validation"
        case .csrf:
            return "Use CSRF tokens, SameSite cookies, validate referrer headers"
        case .directoryTraversal:
            return "Validate and sanitize file paths, use whitelist approach, chroot jails"
        case .authenticationBypass:
            return "Implement proper authentication and authorization checks, secure defaults"
        case .fileUpload:
            return "Validate file types, use safe storage location, scan uploaded files"
            
        // Modern Web Security
        case .cors:
            return "Configure CORS properly, avoid wildcard origins, validate credentials"
        case .clickjacking:
            return "Implement X-Frame-Options, CSP frame-ancestors directive"
        case .businessLogic:
            return "Implement proper business rules validation, rate limiting, sequence verification"
        case .apiSecurity:
            return "Implement proper API authentication, rate limiting, input validation"
        case .webSockets:
            return "Implement proper WebSocket authentication, input validation, rate limiting"
        case .csp:
            return "Implement strict Content Security Policy, avoid unsafe-inline and unsafe-eval"
        case .httpHeaderSecurity:
            return "Implement security headers: HSTS, CSP, X-Frame-Options, X-Content-Type-Options"
        case .sslTlsConfiguration:
            return "Use strong cipher suites, disable deprecated protocols, implement HSTS"
            
        // Injection Attacks
        case .xxe:
            return "Disable external entity processing, use secure XML parsers, input validation"
        case .ldapInjection:
            return "Use parameterized LDAP queries, input validation, escape special characters"
        case .commandInjection:
            return "Avoid system calls, use parameterized APIs, input validation, sandboxing"
        case .templateInjection:
            return "Use secure template engines, input validation, sandboxed execution"
        case .deserializationAttacks:
            return "Avoid deserializing untrusted data, use secure serialization formats, validation"
        case .comprehensiveWebScan:
            return "Comprehensive Nikto scan covering multiple vulnerability categories - review all findings"
        case .nucleiScan:
            return "High-speed template-based scanning - review matched vulnerability templates"
        case .httpProbing:
            return "Analyze HTTP headers, technologies, and service configurations"
        case .subdomainEnumeration:
            return "Map attack surface by discovering all subdomains - investigate exposed services"
        case .advancedFuzzing:
            return "Review discovered parameters and endpoints for further testing"
        case .sslTlsAnalysis:
            return "Update SSL/TLS configurations, disable weak ciphers, implement HSTS"
        case .httpStressTesting:
            return "Review load balancing, implement rate limiting, optimize server capacity"
        case .slowlorisTest:
            return "Configure connection timeouts, implement DDoS protection, use reverse proxy"
        case .connectionExhaustion:
            return "Set connection limits, implement connection pooling, monitor resource usage"
            
        default:
            return "Follow security best practices and industry standards"
        }
    }
}

// MARK: - DoS Testing Models (AUTHORIZED USE ONLY)

enum DoSTestType: String, CaseIterable {
    // Basic DoS Tests
    case httpStress = "HTTP Stress Testing"
    case slowloris = "Slowloris Attack"
    case connectionExhaustion = "Connection Exhaustion"
    
    // Advanced DoS Attack Vectors
    case hulkAttack = "HULK HTTP Flood"
    case goldenEyeAttack = "GoldenEye Layer 7 Attack"
    case synFlood = "SYN Flood Attack"
    case udpFlood = "UDP Flood Attack"
    case icmpFlood = "ICMP Flood Attack"
    case httpFlood = "HTTP Flood Attack"
    case slowHttpPost = "Slow HTTP POST Attack"
    case slowRead = "Slow Read Attack"
    case bandwidthExhaustion = "Bandwidth Exhaustion"
    case tcpReset = "TCP Reset Attack"
    case artilleryIo = "Artillery.io Load Testing"
    case thcSslDos = "THC-SSL-DOS Attack"
    case t50Attack = "T50 Multi-Protocol Flooder"
    case mhddosAttack = "MHDDoS Comprehensive Attack"
    case iPerf3Testing = "iPerf3 Network Testing"
    case torshammer = "Torshammer Slowloris"
    case pyloris = "PyLoris Attack"
    case xerxes = "Xerxes DoS Attack"
    case pentmenu = "PentMENU Multi-Attack"
    case hyenaDoS = "Hyena DoS Attack"
    
    var description: String {
        switch self {
        case .httpStress:
            return "Load testing to identify server capacity limits"
        case .slowloris:
            return "Slow HTTP attack testing for DoS vulnerabilities"
        case .connectionExhaustion:
            return "Test server connection handling limits"
        case .hulkAttack:
            return "HTTP Unique Request Flood - bypasses caching mechanisms"
        case .goldenEyeAttack:
            return "Layer 7 HTTP/HTTPS attack with random GET/POST requests"
        case .synFlood:
            return "TCP SYN flood attack to exhaust connection tables"
        case .udpFlood:
            return "UDP flood attack to consume bandwidth and resources"
        case .icmpFlood:
            return "ICMP flood attack (ping flood) to overwhelm network"
        case .httpFlood:
            return "Volumetric HTTP request flood attack"
        case .slowHttpPost:
            return "Slow HTTP POST attack with incomplete request bodies"
        case .slowRead:
            return "Slow read attack consuming server sockets"
        case .bandwidthExhaustion:
            return "Bandwidth consumption attack testing"
        case .tcpReset:
            return "TCP reset injection attack testing"
        case .artilleryIo:
            return "Artillery.io framework for load and stress testing"
        case .thcSslDos:
            return "SSL/TLS handshake exhaustion attack"
        case .t50Attack:
            return "Multi-protocol packet injection stress testing"
        case .mhddosAttack:
            return "Comprehensive DoS attack framework with multiple vectors"
        case .iPerf3Testing:
            return "Network performance and capacity testing"
        case .torshammer:
            return "Tor-based slow POST attack for anonymized testing"
        case .pyloris:
            return "Python-based Slowloris implementation with threading"
        case .xerxes:
            return "Multi-threaded DoS attack tool"
        case .pentmenu:
            return "Penetration testing menu with DoS modules"
        case .hyenaDoS:
            return "HTTP/HTTPS flood attack with evasion techniques"
        }
    }
    
    var severity: Vulnerability.Severity {
        switch self {
        case .httpStress, .connectionExhaustion, .artilleryIo, .iPerf3Testing:
            return .medium
        case .slowloris, .hulkAttack, .goldenEyeAttack, .slowHttpPost, .slowRead:
            return .high
        case .synFlood, .udpFlood, .icmpFlood, .httpFlood, .bandwidthExhaustion, .tcpReset, .thcSslDos, .t50Attack, .mhddosAttack, .torshammer, .pyloris, .xerxes, .pentmenu, .hyenaDoS:
            return .critical
        }
    }
    
    var toolRequired: String {
        switch self {
        case .httpStress:
            return "wrk"
        case .slowloris:
            return "slowhttptest"
        case .connectionExhaustion, .synFlood, .udpFlood, .icmpFlood, .tcpReset:
            return "hping3"
        case .hulkAttack:
            return "hulk"
        case .goldenEyeAttack:
            return "goldeneye"
        case .httpFlood, .slowHttpPost, .slowRead:
            return "slowhttptest"
        case .bandwidthExhaustion:
            return "iperf3"
        case .artilleryIo:
            return "artillery"
        case .thcSslDos:
            return "thc-ssl-dos"
        case .t50Attack:
            return "t50"
        case .mhddosAttack:
            return "mhddos"
        case .iPerf3Testing:
            return "iperf3"
        case .torshammer:
            return "torshammer"
        case .pyloris:
            return "pyloris"
        case .xerxes:
            return "xerxes"
        case .pentmenu:
            return "pentmenu"
        case .hyenaDoS:
            return "hyenados"
        }
    }
    
    var attackCategory: DoSAttackCategory {
        switch self {
        case .httpStress, .artilleryIo, .iPerf3Testing:
            return .legitimate
        case .slowloris, .hulkAttack, .goldenEyeAttack, .httpFlood, .slowHttpPost, .slowRead, .torshammer, .pyloris, .hyenaDoS:
            return .applicationLayer
        case .synFlood, .udpFlood, .icmpFlood, .connectionExhaustion, .bandwidthExhaustion, .tcpReset:
            return .networkLayer
        case .thcSslDos:
            return .protocolSpecific
        case .t50Attack, .mhddosAttack, .xerxes, .pentmenu:
            return .multiVector
        }
    }
}

enum DoSAttackCategory: String, CaseIterable {
    case legitimate = "Legitimate Testing"
    case applicationLayer = "Application Layer (L7)"
    case networkLayer = "Network Layer (L3/L4)"
    case protocolSpecific = "Protocol-Specific"
    case multiVector = "Multi-Vector"
    
    var color: Color {
        switch self {
        case .legitimate: return .green
        case .applicationLayer: return .yellow
        case .networkLayer: return .orange
        case .protocolSpecific: return .purple
        case .multiVector: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .legitimate: return "checkmark.shield"
        case .applicationLayer: return "globe"
        case .networkLayer: return "network"
        case .protocolSpecific: return "lock.shield"
        case .multiVector: return "exclamationmark.triangle.fill"
        }
    }
}

struct DoSTestResult: Identifiable {
    let id = UUID()
    let testType: DoSTestType
    let target: String
    let startTime: Date
    let duration: TimeInterval
    let authorized: Bool  // CRITICAL: Must be true
    let requestsPerSecond: Int?
    let concurrentConnections: Int?
    let averageResponseTime: Double?
    let successRate: Double?
    let vulnerabilityDetected: Bool
    let mitigationSuggestions: [String]
    let packetsTransmitted: Int?
    let bytesTransferred: UInt64?
    let errorRate: Double?
    let serverResponseCodes: [String: Int]?
    let networkLatency: Double?
    let memoryUsage: Double?
    let cpuUsage: Double?
    let toolOutput: String
    let riskAssessment: DoSRiskLevel
    
    var isLegitimate: Bool {
        return authorized && duration <= 300 // Max 5 minutes
    }
    
    var effectivenessScore: Double {
        guard vulnerabilityDetected else { return 0.0 }
        
        var score = 0.0
        
        // Factor in response time degradation
        if let avgResponseTime = averageResponseTime {
            if avgResponseTime > 5.0 { score += 0.3 }
            else if avgResponseTime > 2.0 { score += 0.2 }
            else if avgResponseTime > 1.0 { score += 0.1 }
        }
        
        // Factor in success rate drop
        if let successRate = successRate {
            if successRate < 0.5 { score += 0.4 }
            else if successRate < 0.8 { score += 0.3 }
            else if successRate < 0.95 { score += 0.2 }
        }
        
        // Factor in error rate
        if let errorRate = errorRate {
            if errorRate > 0.5 { score += 0.3 }
            else if errorRate > 0.2 { score += 0.2 }
            else if errorRate > 0.1 { score += 0.1 }
        }
        
        return min(score, 1.0)
    }
}

enum DoSRiskLevel: String, CaseIterable {
    case minimal = "Minimal Impact"
    case low = "Low Risk"
    case moderate = "Moderate Risk"
    case high = "High Risk"
    case critical = "Critical Vulnerability"
    
    var color: Color {
        switch self {
        case .minimal: return .green
        case .low: return .blue
        case .moderate: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

struct DoSTestConfiguration {
    let testType: DoSTestType
    let duration: TimeInterval
    let intensity: DoSIntensity
    let target: String
    let port: Int?
    let protocolType: NetworkProtocolType?
    let customParameters: [String: String]
    let authorizationConfirmed: Bool
    let ethicalUseAgreed: Bool
    
    var isValid: Bool {
        return authorizationConfirmed && ethicalUseAgreed && duration <= 300
    }
}

enum DoSIntensity: String, CaseIterable {
    case low = "Low Intensity"
    case medium = "Medium Intensity"
    case high = "High Intensity"
    case maximum = "Maximum Intensity"
    
    var description: String {
        switch self {
        case .low:
            return "Conservative testing with minimal impact"
        case .medium:
            return "Moderate testing with controlled impact"
        case .high:
            return "Aggressive testing with potential service impact"
        case .maximum:
            return "Maximum intensity testing - HIGH RISK"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .maximum: return .red
        }
    }
    
    var threadCount: Int {
        switch self {
        case .low: return 10
        case .medium: return 50
        case .high: return 200
        case .maximum: return 1000
        }
    }
    
    var requestsPerSecond: Int {
        switch self {
        case .low: return 100
        case .medium: return 500
        case .high: return 2000
        case .maximum: return 10000
        }
    }
}

enum NetworkProtocolType: String, CaseIterable {
    case tcp = "TCP"
    case udp = "UDP"
    case icmp = "ICMP"
    case http = "HTTP"
    case https = "HTTPS"
    case ssl = "SSL/TLS"
    
    var defaultPort: Int {
        switch self {
        case .tcp: return 80
        case .udp: return 53
        case .icmp: return 0
        case .http: return 80
        case .https: return 443
        case .ssl: return 443
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
        case pending
        case vulnerable
        case secure
        case error
    }
}

struct WebTestDetailView: View {
    let result: WebTestResult
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Test details
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(result.test.displayName)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            TestStatusBadge(status: result.status)
                        }
                        
                        Text("URL: \(result.url)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Tested: \(result.timestamp.formatted(date: .abbreviated, time: .standard))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Test description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Test Description")
                            .font(.headline)
                        
                        Text(result.test.description)
                            .font(.body)
                    }
                    
                    // Vulnerability details if found
                    if let vulnerability = result.vulnerability {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Vulnerability Found")
                                .font(.headline)
                                .foregroundColor(.red)
                            
                            Text(vulnerability.description)
                                .font(.body)
                            
                            Text("Severity: \(vulnerability.severity.rawValue)")
                                .font(.subheadline)
                                .foregroundColor(vulnerability.severity.color)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Test details
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Test Details")
                            .font(.headline)
                        
                        Text(result.details)
                            .font(.body)
                            .fontDesign(.monospaced)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .textSelection(.enabled)
                    }
                    
                    // Recommendations
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recommendations")
                            .font(.headline)
                        
                        Text(result.test.recommendations)
                            .font(.body)
                    }
                }
                .padding(24)
            }
            .navigationTitle("Test Results")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 500)
    }
}

struct TestStatusBadge: View {
    let status: WebTestResult.TestStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: statusIcon)
            Text(statusText)
        }
        .font(.caption)
        .fontWeight(.medium)
        .foregroundColor(statusColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.1))
        .cornerRadius(6)
    }
    
    private var statusIcon: String {
        switch status {
        case .pending: return "clock"
        case .vulnerable: return "exclamationmark.triangle.fill"
        case .secure: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        }
    }
    
    private var statusText: String {
        switch status {
        case .pending: return "Pending"
        case .vulnerable: return "Vulnerable"
        case .secure: return "Secure"
        case .error: return "Error"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .pending: return .blue
        case .vulnerable: return .red
        case .secure: return .green
        case .error: return .orange
        }
    }
}
