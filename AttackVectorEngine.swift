//
//  AttackVectorEngine.swift
//  DonkTool
//
//  Intelligent Attack Vector Determination Engine
//

import Foundation
import SwiftUI

// MARK: - Attack Vector Intelligence Engine

@Observable
class AttackVectorEngine {
    private let cveDatabase: CVEDatabase
    private let serviceFingerprinter: ServiceFingerprinter
    private let exploitDatabase: ExploitDatabase
    
    init(cveDatabase: CVEDatabase) {
        self.cveDatabase = cveDatabase
        self.serviceFingerprinter = ServiceFingerprinter()
        self.exploitDatabase = ExploitDatabase()
    }
    
    // MARK: - Main Attack Vector Determination
    
    func determineAttackVectors(
        for target: ScanTarget,
        scanResults: [PortScanResult],
        webResults: [WebTestResult]? = nil
    ) async -> [IntelligentAttackVector] {
        
        var attackVectors: [IntelligentAttackVector] = []
        
        // 1. Service-specific vectors based on fingerprinting
        for result in scanResults where result.isOpen {
            let serviceVectors = await determineServiceAttackVectors(result)
            attackVectors.append(contentsOf: serviceVectors)
        }
        
        // 2. CVE-based vectors
        let cveVectors = await determineCVEBasedVectors(target, scanResults: scanResults)
        attackVectors.append(contentsOf: cveVectors)
        
        // 3. OS-specific vectors
        if let osInfo = target.osFingerprint {
            let osVectors = determineOSSpecificVectors(osInfo, scanResults: scanResults)
            attackVectors.append(contentsOf: osVectors)
        }
        
        // 4. Web application vectors
        if let webResults = webResults {
            let webVectors = determineWebAppVectors(webResults, scanResults: scanResults)
            attackVectors.append(contentsOf: webVectors)
        }
        
        // 5. Combined/chained attack vectors
        let chainedVectors = determineChainedAttackVectors(attackVectors, scanResults: scanResults)
        attackVectors.append(contentsOf: chainedVectors)
        
        // 6. Context-aware prioritization
        return prioritizeAttackVectors(attackVectors, target: target)
    }
    
    // MARK: - Service-Specific Attack Vectors
    
    private func determineServiceAttackVectors(_ scanResult: PortScanResult) async -> [IntelligentAttackVector] {
        var vectors: [IntelligentAttackVector] = []
        
        // Enhanced service fingerprinting
        let serviceInfo = await serviceFingerprinter.fingerprint(
            port: scanResult.port,
            banner: scanResult.banner,
            probes: true
        )
        
        switch serviceInfo.service {
        case .ssh:
            vectors.append(contentsOf: determineSSHAttackVectors(serviceInfo, port: scanResult.port))
        case .http, .https:
            vectors.append(contentsOf: determineWebAttackVectors(serviceInfo, port: scanResult.port))
        case .smb:
            vectors.append(contentsOf: determineSMBAttackVectors(serviceInfo, port: scanResult.port))
        case .database(let dbType):
            vectors.append(contentsOf: determineDatabaseAttackVectors(dbType, serviceInfo, port: scanResult.port))
        case .mail(let mailType):
            vectors.append(contentsOf: determineMailAttackVectors(mailType, serviceInfo, port: scanResult.port))
        case .ftp:
            vectors.append(contentsOf: determineFTPAttackVectors(serviceInfo, port: scanResult.port))
        case .rdp:
            vectors.append(contentsOf: determineRDPAttackVectors(serviceInfo, port: scanResult.port))
        case .vnc:
            vectors.append(contentsOf: determineVNCAttackVectors(serviceInfo, port: scanResult.port))
        case .custom(let name):
            vectors.append(contentsOf: determineCustomServiceVectors(name, serviceInfo, port: scanResult.port))
        default:
            vectors.append(contentsOf: determineGenericAttackVectors(serviceInfo, port: scanResult.port))
        }
        
        return vectors
    }
    
    private func determineSSHAttackVectors(_ serviceInfo: ServiceInfo, port: Int) -> [IntelligentAttackVector] {
        var vectors: [IntelligentAttackVector] = []
        
        // Version-specific vulnerabilities
        if let version = serviceInfo.version {
            // OpenSSH < 7.7 - Username enumeration
            if version.contains("OpenSSH") && isVersionOlder(version, than: "7.7") {
                vectors.append(IntelligentAttackVector(
                    id: "SSH-CVE-2018-15473",
                    name: "OpenSSH Username Enumeration",
                    description: "CVE-2018-15473 - Username enumeration via malformed packets",
                    category: .vulnerability,
                    severity: .medium,
                    reliability: .high,
                    tools: [
                        AttackTool(name: "ssh-audit", command: "ssh-audit -p \(port) {{target}}"),
                        AttackTool(name: "metasploit", command: "use auxiliary/scanner/ssh/ssh_enumusers")
                    ],
                    prerequisites: [],
                    chainable: true,
                    estimatedDuration: 60,
                    detectionRisk: .low,
                    evidence: "Version \(version) detected"
                ))
            }
            
            // Weak algorithms
            if serviceInfo.supportedAlgorithms?.contains(where: { isWeakAlgorithm($0) }) ?? false {
                vectors.append(IntelligentAttackVector(
                    id: "SSH-WEAK-CRYPTO",
                    name: "SSH Weak Cryptography",
                    description: "Weak encryption algorithms detected",
                    category: .misconfiguration,
                    severity: .medium,
                    reliability: .high,
                    tools: [
                        AttackTool(name: "ssh-audit", command: "ssh-audit -p \(port) {{target}}"),
                        AttackTool(name: "nmap", command: "nmap -p \(port) --script ssh2-enum-algos {{target}}")
                    ],
                    prerequisites: [],
                    chainable: false,
                    estimatedDuration: 30,
                    detectionRisk: .low,
                    evidence: "Weak algorithms: \(serviceInfo.supportedAlgorithms?.filter { isWeakAlgorithm($0) }.joined(separator: ", ") ?? "")"
                ))
            }
        }
        
        // Always include credential attacks
        vectors.append(IntelligentAttackVector(
            id: "SSH-BRUTE-FORCE",
            name: "SSH Credential Brute Force",
            description: "Attempt to brute force SSH credentials",
            category: .bruteForce,
            severity: .high,
            reliability: .medium,
            tools: [
                AttackTool(name: "hydra", command: "hydra -L {{userlist}} -P {{passlist}} -t 4 ssh://{{target}}:\(port)"),
                AttackTool(name: "medusa", command: "medusa -h {{target}} -n \(port) -U {{userlist}} -P {{passlist}} -M ssh"),
                AttackTool(name: "patator", command: "patator ssh_login host={{target}} port=\(port) user=FILE0 password=FILE1 0={{userlist}} 1={{passlist}}")
            ],
            prerequisites: ["userlist", "passlist"],
            chainable: false,
            estimatedDuration: 300,
            detectionRisk: .high,
            evidence: "SSH service detected on port \(port)"
        ))
        
        return vectors
    }
    
    private func determineWebAttackVectors(_ serviceInfo: ServiceInfo, port: Int) -> [IntelligentAttackVector] {
        var vectors: [IntelligentAttackVector] = []
        let isSSL = port == 443 || serviceInfo.ssl
        let protocol = isSSL ? "https" : "http"
        
        // Technology-specific vectors
        if let tech = serviceInfo.detectedTechnology {
            switch tech {
            case .wordpress:
                vectors.append(contentsOf: getWordPressAttackVectors(protocol: protocol, port: port))
            case .joomla:
                vectors.append(contentsOf: getJoomlaAttackVectors(protocol: protocol, port: port))
            case .drupal:
                vectors.append(contentsOf: getDrupalAttackVectors(protocol: protocol, port: port))
            case .apache(let version):
                vectors.append(contentsOf: getApacheAttackVectors(version: version, protocol: protocol, port: port))
            case .nginx(let version):
                vectors.append(contentsOf: getNginxAttackVectors(version: version, protocol: protocol, port: port))
            case .iis(let version):
                vectors.append(contentsOf: getIISAttackVectors(version: version, protocol: protocol, port: port))
            default:
                break
            }
        }
        
        // Generic web vectors
        vectors.append(contentsOf: [
            IntelligentAttackVector(
                id: "WEB-DIR-ENUM",
                name: "Web Directory Enumeration",
                description: "Discover hidden directories and files",
                category: .discovery,
                severity: .low,
                reliability: .high,
                tools: [
                    AttackTool(name: "gobuster", command: "gobuster dir -u \(protocol)://{{target}}:\(port) -w {{wordlist}} -t 50"),
                    AttackTool(name: "dirb", command: "dirb \(protocol)://{{target}}:\(port) {{wordlist}}"),
                    AttackTool(name: "feroxbuster", command: "feroxbuster -u \(protocol)://{{target}}:\(port) -w {{wordlist}}")
                ],
                prerequisites: ["wordlist"],
                chainable: true,
                estimatedDuration: 180,
                detectionRisk: .medium,
                evidence: "Web service on port \(port)"
            ),
            
            IntelligentAttackVector(
                id: "WEB-VULN-SCAN",
                name: "Web Vulnerability Scan",
                description: "Comprehensive web application vulnerability scanning",
                category: .vulnerability,
                severity: .medium,
                reliability: .high,
                tools: [
                    AttackTool(name: "nikto", command: "nikto -h \(protocol)://{{target}}:\(port)"),
                    AttackTool(name: "nuclei", command: "nuclei -u \(protocol)://{{target}}:\(port) -t cves/"),
                    AttackTool(name: "wapiti", command: "wapiti -u \(protocol)://{{target}}:\(port)")
                ],
                prerequisites: [],
                chainable: true,
                estimatedDuration: 600,
                detectionRisk: .high,
                evidence: "Web service detected"
            )
        ])
        
        return vectors
    }
    
    private func determineSMBAttackVectors(_ serviceInfo: ServiceInfo, port: Int) -> [IntelligentAttackVector] {
        var vectors: [IntelligentAttackVector] = []
        
        // SMBGhost (CVE-2020-0796)
        if serviceInfo.version?.contains("SMBv3") ?? false {
            vectors.append(IntelligentAttackVector(
                id: "SMB-CVE-2020-0796",
                name: "SMBGhost Vulnerability",
                description: "Windows SMBv3 Client/Server Remote Code Execution",
                category: .vulnerability,
                severity: .critical,
                reliability: .medium,
                tools: [
                    AttackTool(name: "smbghost", command: "python3 smbghost.py {{target}} \(port)"),
                    AttackTool(name: "metasploit", command: "use exploit/windows/smb/cve_2020_0796_smbghost")
                ],
                prerequisites: [],
                chainable: false,
                estimatedDuration: 60,
                detectionRisk: .high,
                evidence: "SMBv3 detected"
            ))
        }
        
        // EternalBlue check
        vectors.append(IntelligentAttackVector(
            id: "SMB-MS17-010",
            name: "EternalBlue (MS17-010)",
            description: "Windows SMBv1 Remote Code Execution",
            category: .vulnerability,
            severity: .critical,
            reliability: .high,
            tools: [
                AttackTool(name: "metasploit", command: "use auxiliary/scanner/smb/smb_ms17_010"),
                AttackTool(name: "nmap", command: "nmap -p \(port) --script smb-vuln-ms17-010 {{target}}")
            ],
            prerequisites: [],
            chainable: false,
            estimatedDuration: 30,
            detectionRisk: .medium,
            evidence: "SMB service on port \(port)"
        ))
        
        return vectors
    }
    
    // MARK: - CVE-Based Attack Vectors
    
    private func determineCVEBasedVectors(_ target: ScanTarget, scanResults: [PortScanResult]) async -> [IntelligentAttackVector] {
        var vectors: [IntelligentAttackVector] = []
        
        // Get all identified services and versions
        let serviceVersions = scanResults.compactMap { result -> (service: String, version: String)? in
            guard let service = result.service,
                  let version = result.version else { return nil }
            return (service, version)
        }
        
        // Search CVE database for each service/version
        for (service, version) in serviceVersions {
            let cves = cveDatabase.searchCVEs(query: "\(service) \(version)")
                .filter { $0.baseSeverity != nil }
                .prefix(5) // Top 5 CVEs
            
            for cve in cves {
                if let exploit = exploitDatabase.getExploit(for: cve.id) {
                    vectors.append(IntelligentAttackVector(
                        id: cve.id,
                        name: "\(cve.id) - \(service) Vulnerability",
                        description: cve.description,
                        category: .vulnerability,
                        severity: mapCVESeverity(cve.severity),
                        reliability: exploit.reliability,
                        tools: exploit.tools.map { tool in
                            AttackTool(name: tool.name, command: tool.command.replacingOccurrences(of: "{{cve}}", with: cve.id))
                        },
                        prerequisites: exploit.prerequisites,
                        chainable: exploit.chainable,
                        estimatedDuration: exploit.estimatedDuration,
                        detectionRisk: exploit.detectionRisk,
                        evidence: "CVE Match: \(service) \(version)"
                    ))
                }
            }
        }
        
        return vectors
    }
    
    // MARK: - Chained Attack Vectors
    
    private func determineChainedAttackVectors(_ existingVectors: [IntelligentAttackVector], scanResults: [PortScanResult]) -> [IntelligentAttackVector] {
        var chainedVectors: [IntelligentAttackVector] = []
        
        // Look for vectors that can be chained
        let chainableVectors = existingVectors.filter { $0.chainable }
        
        // Username enumeration -> Credential attack chain
        if let enumVector = chainableVectors.first(where: { $0.id.contains("ENUM") }),
           scanResults.contains(where: { $0.port == 22 || $0.port == 3389 || $0.port == 21 }) {
            
            chainedVectors.append(IntelligentAttackVector(
                id: "CHAIN-ENUM-CREDS",
                name: "Username Enumeration to Credential Attack",
                description: "Chain username enumeration with targeted credential attacks",
                category: .chain,
                severity: .high,
                reliability: .high,
                tools: [
                    AttackTool(name: "custom", command: "# 1. Enumerate users\n\(enumVector.tools.first?.command ?? "")\n# 2. Targeted brute force\nhydra -L found_users.txt -P {{passlist}} {{service}}://{{target}}")
                ],
                prerequisites: ["passlist"],
                chainable: false,
                estimatedDuration: enumVector.estimatedDuration + 300,
                detectionRisk: .high,
                evidence: "Enumeration vector available"
            ))
        }
        
        // Web directory discovery -> targeted attacks
        if let webEnumVector = chainableVectors.first(where: { $0.id == "WEB-DIR-ENUM" }),
           let webVulnVector = existingVectors.first(where: { $0.id == "WEB-VULN-SCAN" }) {
            
            chainedVectors.append(IntelligentAttackVector(
                id: "CHAIN-WEB-DISCOVERY",
                name: "Web Discovery to Targeted Exploitation",
                description: "Discover web resources then perform targeted attacks",
                category: .chain,
                severity: .high,
                reliability: .high,
                tools: [
                    AttackTool(name: "custom", command: """
                    # 1. Directory enumeration
                    gobuster dir -u {{url}} -w {{wordlist}} -o dirs.txt
                    
                    # 2. Targeted scanning of found directories
                    cat dirs.txt | nuclei -t technologies/ -t cves/
                    
                    # 3. Parameter fuzzing on endpoints
                    ffuf -w {{params}}:PARAM -u {{url}}/FUZZ?PARAM=test
                    """)
                ],
                prerequisites: ["wordlist", "params"],
                chainable: false,
                estimatedDuration: 900,
                detectionRisk: .high,
                evidence: "Web enumeration available"
            ))
        }
        
        return chainedVectors
    }
    
    // MARK: - Prioritization
    
    private func prioritizeAttackVectors(_ vectors: [IntelligentAttackVector], target: ScanTarget) -> [IntelligentAttackVector] {
        return vectors.sorted { v1, v2 in
            // Priority calculation
            let v1Priority = calculateVectorPriority(v1, target: target)
            let v2Priority = calculateVectorPriority(v2, target: target)
            
            return v1Priority > v2Priority
        }
    }
    
    private func calculateVectorPriority(_ vector: IntelligentAttackVector, target: ScanTarget) -> Double {
        var priority = 0.0
        
        // Severity weight (0-40 points)
        priority += vector.severity.priorityWeight * 40
        
        // Reliability weight (0-30 points)
        priority += vector.reliability.rawValue * 30
        
        // Detection risk inverse (0-20 points)
        priority += (1.0 - vector.detectionRisk.rawValue) * 20
        
        // Time efficiency (0-10 points)
        let timeEfficiency = min(1.0, 300.0 / Double(vector.estimatedDuration))
        priority += timeEfficiency * 10
        
        // Bonus for CVEs
        if vector.id.starts(with: "CVE-") {
            priority += 15
        }
        
        // Bonus for chainable vectors
        if vector.chainable {
            priority += 10
        }
        
        return priority
    }
    
    // MARK: - Helper Methods
    
    private func isVersionOlder(_ version: String, than target: String) -> Bool {
        // Simple version comparison - can be enhanced
        let versionNumbers = version.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap(Int.init)
        let targetNumbers = target.components(separatedBy: ".").compactMap(Int.init)
        
        for i in 0..<min(versionNumbers.count, targetNumbers.count) {
            if versionNumbers[i] < targetNumbers[i] {
                return true
            } else if versionNumbers[i] > targetNumbers[i] {
                return false
            }
        }
        
        return false
    }
    
    private func isWeakAlgorithm(_ algorithm: String) -> Bool {
        let weakAlgorithms = [
            "arcfour", "3des-cbc", "blowfish-cbc", "cast128-cbc",
            "md5", "sha1", "dss", "rsa1024"
        ]
        return weakAlgorithms.contains(where: { algorithm.lowercased().contains($0) })
    }
    
    private func mapCVESeverity(_ severity: Vulnerability.Severity) -> AttackSeverity {
        switch severity {
        case .critical: return .critical
        case .high: return .high
        case .medium: return .medium
        case .low: return .low
        }
    }
}

// MARK: - Supporting Models

struct IntelligentAttackVector: Identifiable {
    let id: String
    let name: String
    let description: String
    let category: AttackCategory
    let severity: AttackSeverity
    let reliability: AttackReliability
    let tools: [AttackTool]
    let prerequisites: [String]
    let chainable: Bool
    let estimatedDuration: Int // seconds
    let detectionRisk: DetectionRisk
    let evidence: String
    
    enum AttackCategory {
        case vulnerability
        case misconfiguration
        case bruteForce
        case discovery
        case privilege
        case persistence
        case chain
        case custom
    }
    
    enum AttackReliability: Double {
        case high = 0.9
        case medium = 0.6
        case low = 0.3
    }
    
    enum DetectionRisk: Double {
        case low = 0.2
        case medium = 0.5
        case high = 0.8
        case guaranteed = 1.0
    }
}

struct AttackTool {
    let name: String
    let command: String
}

enum AttackSeverity {
    case critical, high, medium, low
    
    var priorityWeight: Double {
        switch self {
        case .critical: return 1.0
        case .high: return 0.75
        case .medium: return 0.5
        case .low: return 0.25
        }
    }
}

struct ScanTarget {
    let address: String
    let hostname: String?
    let osFingerprint: OSInfo?
    let tags: [String]
}

struct OSInfo {
    let name: String
    let version: String?
    let architecture: String?
    let kernel: String?
}

// MARK: - Service Fingerprinter

class ServiceFingerprinter {
    func fingerprint(port: Int, banner: String?, probes: Bool) async -> ServiceInfo {
        // Enhanced service detection logic
        var info = ServiceInfo()
        
        // Banner analysis
        if let banner = banner {
            info = parseServiceBanner(banner)
        }
        
        // Port-based defaults
        if info.service == .unknown {
            info.service = getDefaultService(for: port)
        }
        
        // Active probing if enabled
        if probes {
            let probeResults = await performServiceProbes(port: port)
            info.merge(with: probeResults)
        }
        
        return info
    }
    
    private func parseServiceBanner(_ banner: String) -> ServiceInfo {
        var info = ServiceInfo()
        
        // SSH detection
        if banner.contains("SSH") {
            info.service = .ssh
            info.version = extractVersion(from: banner, pattern: "SSH-[\\d.]+-(\\S+)")
        }
        // HTTP detection
        else if banner.contains("HTTP/") {
            info.service = .http
            info.version = extractVersion(from: banner, pattern: "Server: (\\S+)")
            
            // Technology detection
            if banner.contains("Apache") {
                info.detectedTechnology = .apache(extractVersion(from: banner, pattern: "Apache/([\\d.]+)"))
            } else if banner.contains("nginx") {
                info.detectedTechnology = .nginx(extractVersion(from: banner, pattern: "nginx/([\\d.]+)"))
            }
        }
        // Add more service detections...
        
        return info
    }
    
    private func extractVersion(from text: String, pattern: String) -> String? {
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text) {
            return String(text[range])
        }
        return nil
    }
    
    private func getDefaultService(for port: Int) -> ServiceType {
        switch port {
        case 22: return .ssh
        case 80: return .http
        case 443: return .https
        case 445: return .smb
        case 3306: return .database(.mysql)
        case 5432: return .database(.postgresql)
        case 21: return .ftp
        case 25: return .mail(.smtp)
        case 3389: return .rdp
        case 5900: return .vnc
        default: return .unknown
        }
    }
    
    private func performServiceProbes(port: Int) async -> ServiceInfo {
        // Implement active service probing
        return ServiceInfo()
    }
}

struct ServiceInfo {
    var service: ServiceType = .unknown
    var version: String?
    var ssl: Bool = false
    var supportedAlgorithms: [String]?
    var detectedTechnology: Technology?
    
    mutating func merge(with other: ServiceInfo) {
        if service == .unknown && other.service != .unknown {
            service = other.service
        }
        version = version ?? other.version
        ssl = ssl || other.ssl
        supportedAlgorithms = supportedAlgorithms ?? other.supportedAlgorithms
        detectedTechnology = detectedTechnology ?? other.detectedTechnology
    }
}

enum ServiceType {
    case ssh
    case http
    case https
    case smb
    case database(DatabaseType)
    case mail(MailType)
    case ftp
    case rdp
    case vnc
    case custom(String)
    case unknown
}

enum DatabaseType {
    case mysql
    case postgresql
    case mssql
    case oracle
    case mongodb
}

enum MailType {
    case smtp
    case pop3
    case imap
}

enum Technology {
    case wordpress
    case joomla
    case drupal
    case apache(String?)
    case nginx(String?)
    case iis(String?)
    case custom(String)
}

// MARK: - Exploit Database

class ExploitDatabase {
    struct ExploitInfo {
        let id: String
        let reliability: IntelligentAttackVector.AttackReliability
        let tools: [AttackTool]
        let prerequisites: [String]
        let chainable: Bool
        let estimatedDuration: Int
        let detectionRisk: IntelligentAttackVector.DetectionRisk
    }
    
    func getExploit(for cveId: String) -> ExploitInfo? {
        // Mock implementation - would connect to real exploit databases
        let knownExploits: [String: ExploitInfo] = [
            "CVE-2024-3094": ExploitInfo(
                id: "CVE-2024-3094",
                reliability: .high,
                tools: [
                    AttackTool(name: "xz-exploit", command: "python3 xz_exploit.py {{target}}"),
                    AttackTool(name: "metasploit", command: "use exploit/linux/misc/xz_backdoor")
                ],
                prerequisites: [],
                chainable: false,
                estimatedDuration: 60,
                detectionRisk: .medium
            ),
            "CVE-2021-44228": ExploitInfo(
                id: "CVE-2021-44228",
                reliability: .high,
                tools: [
                    AttackTool(name: "log4j-scan", command: "python3 log4j-scan.py -u {{url}}"),
                    AttackTool(name: "nuclei", command: "nuclei -u {{url}} -t cves/2021/CVE-2021-44228.yaml")
                ],
                prerequisites: ["ldap_server"],
                chainable: true,
                estimatedDuration: 30,
                detectionRisk: .high
            )
        ]
        
        return knownExploits[cveId]
    }
}

// MARK: - Technology-Specific Attack Vectors

extension AttackVectorEngine {
    private func getWordPressAttackVectors(protocol: String, port: Int) -> [IntelligentAttackVector] {
        return [
            IntelligentAttackVector(
                id: "WP-ENUM",
                name: "WordPress Enumeration",
                description: "Enumerate WordPress users, plugins, and themes",
                category: .discovery,
                severity: .low,
                reliability: .high,
                tools: [
                    AttackTool(name: "wpscan", command: "wpscan --url \(protocol)://{{target}}:\(port) --enumerate ap,at,cb,dbe"),
                    AttackTool(name: "nuclei", command: "nuclei -u \(protocol)://{{target}}:\(port) -t technologies/wordpress/")
                ],
                prerequisites: [],
                chainable: true,
                estimatedDuration: 180,
                detectionRisk: .medium,
                evidence: "WordPress detected"
            ),
            
            IntelligentAttackVector(
                id: "WP-XMLRPC",
                name: "WordPress XML-RPC Brute Force",
                description: "Exploit XML-RPC for credential attacks",
                category: .bruteForce,
                severity: .high,
                reliability: .high,
                tools: [
                    AttackTool(name: "wpscan", command: "wpscan --url \(protocol)://{{target}}:\(port) --passwords {{passlist}} --usernames admin"),
                    AttackTool(name: "wpxmlrpcbrute", command: "python3 wpxmlrpcbrute.py -u \(protocol)://{{target}}:\(port)/xmlrpc.php -w {{passlist}}")
                ],
                prerequisites: ["passlist"],
                chainable: false,
                estimatedDuration: 300,
                detectionRisk: .high,
                evidence: "WordPress XML-RPC endpoint likely available"
            )
        ]
    }
    
    private func getJoomlaAttackVectors(protocol: String, port: Int) -> [IntelligentAttackVector] {
        return [
            IntelligentAttackVector(
                id: "JOOMLA-SCAN",
                name: "Joomla Security Scan",
                description: "Scan for Joomla vulnerabilities and misconfigurations",
                category: .vulnerability,
                severity: .medium,
                reliability: .high,
                tools: [
                    AttackTool(name: "joomscan", command: "joomscan -u \(protocol)://{{target}}:\(port)"),
                    AttackTool(name: "nuclei", command: "nuclei -u \(protocol)://{{target}}:\(port) -t technologies/joomla/")
                ],
                prerequisites: [],
                chainable: true,
                estimatedDuration: 240,
                detectionRisk: .medium,
                evidence: "Joomla CMS detected"
            )
        ]
    }
    
    private func getDrupalAttackVectors(protocol: String, port: Int) -> [IntelligentAttackVector] {
        return [
            IntelligentAttackVector(
                id: "DRUPAL-ENUM",
                name: "Drupal Enumeration",
                description: "Enumerate Drupal version and modules",
                category: .discovery,
                severity: .low,
                reliability: .high,
                tools: [
                    AttackTool(name: "droopescan", command: "droopescan scan drupal -u \(protocol)://{{target}}:\(port)"),
                    AttackTool(name: "nuclei", command: "nuclei -u \(protocol)://{{target}}:\(port) -t technologies/drupal/")
                ],
                prerequisites: [],
                chainable: true,
                estimatedDuration: 120,
                detectionRisk: .low,
                evidence: "Drupal CMS detected"
            )
        ]
    }
    
    private func getApacheAttackVectors(version: String?, protocol: String, port: Int) -> [IntelligentAttackVector] {
        var vectors: [IntelligentAttackVector] = []
        
        // Apache Struts vulnerabilities
        vectors.append(IntelligentAttackVector(
            id: "APACHE-STRUTS",
            name: "Apache Struts Vulnerability Scan",
            description: "Check for Apache Struts vulnerabilities",
            category: .vulnerability,
            severity: .critical,
            reliability: .medium,
            tools: [
                AttackTool(name: "struts-scan", command: "python3 struts-scan.py -u \(protocol)://{{target}}:\(port)"),
                AttackTool(name: "nuclei", command: "nuclei -u \(protocol)://{{target}}:\(port) -t cves/ -tags struts")
            ],
            prerequisites: [],
            chainable: false,
            estimatedDuration: 120,
            detectionRisk: .medium,
            evidence: "Apache server detected"
        ))
        
        return vectors
    }
    
    private func getNginxAttackVectors(version: String?, protocol: String, port: Int) -> [IntelligentAttackVector] {
        return [
            IntelligentAttackVector(
                id: "NGINX-CONFIG",
                name: "Nginx Misconfiguration Check",
                description: "Check for common Nginx misconfigurations",
                category: .misconfiguration,
                severity: .medium,
                reliability: .high,
                tools: [
                    AttackTool(name: "nuclei", command: "nuclei -u \(protocol)://{{target}}:\(port) -t misconfiguration/nginx/"),
                    AttackTool(name: "nikto", command: "nikto -h \(protocol)://{{target}}:\(port) -Plugins @@ALL")
                ],
                prerequisites: [],
                chainable: true,
                estimatedDuration: 180,
                detectionRisk: .low,
                evidence: "Nginx server detected"
            )
        ]
    }
    
    private func getIISAttackVectors(version: String?, protocol: String, port: Int) -> [IntelligentAttackVector] {
        return [
            IntelligentAttackVector(
                id: "IIS-SHORTNAME",
                name: "IIS Short Name Scanner",
                description: "Enumerate files using IIS 8.3 short name vulnerability",
                category: .discovery,
                severity: .medium,
                reliability: .high,
                tools: [
                    AttackTool(name: "iis-shortname-scanner", command: "java -jar IIS-ShortName-Scanner.jar \(protocol)://{{target}}:\(port)"),
                    AttackTool(name: "gobuster", command: "gobuster dir -u \(protocol)://{{target}}:\(port) -w {{wordlist}} --wildcard")
                ],
                prerequisites: ["wordlist"],
                chainable: true,
                estimatedDuration: 240,
                detectionRisk: .low,
                evidence: "IIS server detected"
            )
        ]
    }
    
    private func determineDatabaseAttackVectors(_ dbType: DatabaseType, _ serviceInfo: ServiceInfo, port: Int) -> [IntelligentAttackVector] {
        switch dbType {
        case .mysql:
            return getMySQLAttackVectors(serviceInfo, port: port)
        case .postgresql:
            return getPostgreSQLAttackVectors(serviceInfo, port: port)
        case .mssql:
            return getMSSQLAttackVectors(serviceInfo, port: port)
        case .mongodb:
            return getMongoDBAttackVectors(serviceInfo, port: port)
        case .oracle:
            return getOracleAttackVectors(serviceInfo, port: port)
        }
    }
    
    private func getMySQLAttackVectors(_ serviceInfo: ServiceInfo, port: Int) -> [IntelligentAttackVector] {
        return [
            IntelligentAttackVector(
                id: "MYSQL-ENUM",
                name: "MySQL Enumeration",
                description: "Enumerate MySQL database information",
                category: .discovery,
                severity: .low,
                reliability: .high,
                tools: [
                    AttackTool(name: "nmap", command: "nmap -p \(port) --script mysql-enum,mysql-info {{target}}"),
                    AttackTool(name: "metasploit", command: "use auxiliary/scanner/mysql/mysql_version")
                ],
                prerequisites: [],
                chainable: true,
                estimatedDuration: 60,
                detectionRisk: .low,
                evidence: "MySQL service on port \(port)"
            )
        ]
    }
    
    private func getPostgreSQLAttackVectors(_ serviceInfo: ServiceInfo, port: Int) -> [IntelligentAttackVector] {
        return [
            IntelligentAttackVector(
                id: "PGSQL-BRUTE",
                name: "PostgreSQL Credential Attack",
                description: "Attempt to brute force PostgreSQL credentials",
                category: .bruteForce,
                severity: .high,
                reliability: .medium,
                tools: [
                    AttackTool(name: "hydra", command: "hydra -L {{userlist}} -P {{passlist}} postgres://{{target}}:\(port)"),
                    AttackTool(name: "metasploit", command: "use auxiliary/scanner/postgres/postgres_login")
                ],
                prerequisites: ["userlist", "passlist"],
                chainable: false,
                estimatedDuration: 300,
                detectionRisk: .high,
                evidence: "PostgreSQL service on port \(port)"
            )
        ]
    }
    
    private func getMSSQLAttackVectors(_ serviceInfo: ServiceInfo, port: Int) -> [IntelligentAttackVector] {
        return [
            IntelligentAttackVector(
                id: "MSSQL-XPCMDSHELL",
                name: "MSSQL xp_cmdshell Check",
                description: "Check if xp_cmdshell is enabled for command execution",
                category: .misconfiguration,
                severity: .critical,
                reliability: .medium,
                tools: [
                    AttackTool(name: "nmap", command: "nmap -p \(port) --script ms-sql-xp-cmdshell {{target}}"),
                    AttackTool(name: "metasploit", command: "use auxiliary/scanner/mssql/mssql_xp_cmdshell")
                ],
                prerequisites: ["mssql_creds"],
                chainable: false,
                estimatedDuration: 60,
                detectionRisk: .medium,
                evidence: "MSSQL service on port \(port)"
            )
        ]
    }
    
    private func getMongoDBAttackVectors(_ serviceInfo: ServiceInfo, port: Int) -> [IntelligentAttackVector] {
        return [
            IntelligentAttackVector(
                id: "MONGODB-NOAUTH",
                name: "MongoDB No Authentication",
                description: "Check for MongoDB instances without authentication",
                category: .misconfiguration,
                severity: .critical,
                reliability: .high,
                tools: [
                    AttackTool(name: "nmap", command: "nmap -p \(port) --script mongodb-info {{target}}"),
                    AttackTool(name: "metasploit", command: "use auxiliary/scanner/mongodb/mongodb_login")
                ],
                prerequisites: [],
                chainable: false,
                estimatedDuration: 30,
                detectionRisk: .low,
                evidence: "MongoDB service on port \(port)"
            )
        ]
    }
    
    private func getOracleAttackVectors(_ serviceInfo: ServiceInfo, port: Int) -> [IntelligentAttackVector] {
        return [
            IntelligentAttackVector(
                id: "ORACLE-TNS",
                name: "Oracle TNS Listener Attack",
                description: "Enumerate and attack Oracle TNS listener",
                category: .vulnerability,
                severity: .high,
                reliability: .medium,
                tools: [
                    AttackTool(name: "tnscmd", command: "tnscmd10g version -h {{target}} -p \(port)"),
                    AttackTool(name: "odat", command: "odat.py all -s {{target}} -p \(port)")
                ],
                prerequisites: [],
                chainable: true,
                estimatedDuration: 180,
                detectionRisk: .medium,
                evidence: "Oracle service on port \(port)"
            )
        ]
    }
    
    private func determineMailAttackVectors(_ mailType: MailType, _ serviceInfo: ServiceInfo, port: Int) -> [IntelligentAttackVector] {
        switch mailType {
        case .smtp:
            return [
                IntelligentAttackVector(
                    id: "SMTP-ENUM",
                    name: "SMTP User Enumeration",
                    description: "Enumerate valid email addresses via SMTP",
                    category: .discovery,
                    severity: .medium,
                    reliability: .high,
                    tools: [
                        AttackTool(name: "smtp-user-enum", command: "smtp-user-enum -M VRFY -U {{userlist}} -t {{target}} -p \(port)"),
                        AttackTool(name: "metasploit", command: "use auxiliary/scanner/smtp/smtp_enum")
                    ],
                    prerequisites: ["userlist"],
                    chainable: true,
                    estimatedDuration: 120,
                    detectionRisk: .medium,
                    evidence: "SMTP service on port \(port)"
                )
            ]
        case .pop3, .imap:
            return [
                IntelligentAttackVector(
                    id: "MAIL-BRUTE",
                    name: "Mail Service Credential Attack",
                    description: "Brute force mail service credentials",
                    category: .bruteForce,
                    severity: .high,
                    reliability: .medium,
                    tools: [
                        AttackTool(name: "hydra", command: "hydra -L {{userlist}} -P {{passlist}} {{target}} \(mailType == .pop3 ? "pop3" : "imap") -s \(port)"),
                        AttackTool(name: "metasploit", command: "use auxiliary/scanner/\(mailType == .pop3 ? "pop3" : "imap")/\(mailType)_login")
                    ],
                    prerequisites: ["userlist", "passlist"],
                    chainable: false,
                    estimatedDuration: 300,
                    detectionRisk: .high,
                    evidence: "\(mailType) service on port \(port)"
                )
            ]
        }
    }
    
    private func determineFTPAttackVectors(_ serviceInfo: ServiceInfo, port: Int) -> [IntelligentAttackVector] {
        return [
            IntelligentAttackVector(
                id: "FTP-ANON",
                name: "FTP Anonymous Access",
                description: "Check for anonymous FTP access",
                category: .misconfiguration,
                severity: .medium,
                reliability: .high,
                tools: [
                    AttackTool(name: "nmap", command: "nmap -p \(port) --script ftp-anon {{target}}"),
                    AttackTool(name: "ftp", command: "ftp {{target}} \(port) # Try anonymous:anonymous@")
                ],
                prerequisites: [],
                chainable: true,
                estimatedDuration: 30,
                detectionRisk: .low,
                evidence: "FTP service on port \(port)"
            ),
            
            IntelligentAttackVector(
                id: "FTP-BOUNCE",
                name: "FTP Bounce Attack",
                description: "Check for FTP bounce attack vulnerability",
                category: .vulnerability,
                severity: .high,
                reliability: .medium,
                tools: [
                    AttackTool(name: "nmap", command: "nmap -p \(port) --script ftp-bounce {{target}}"),
                    AttackTool(name: "metasploit", command: "use auxiliary/scanner/ftp/ftp_bounce")
                ],
                prerequisites: [],
                chainable: false,
                estimatedDuration: 60,
                detectionRisk: .low,
                evidence: "FTP service on port \(port)"
            )
        ]
    }
    
    private func determineRDPAttackVectors(_ serviceInfo: ServiceInfo, port: Int) -> [IntelligentAttackVector] {
        return [
            IntelligentAttackVector(
                id: "RDP-BLUEKEEP",
                name: "BlueKeep Vulnerability (CVE-2019-0708)",
                description: "Check for BlueKeep RDP vulnerability",
                category: .vulnerability,
                severity: .critical,
                reliability: .high,
                tools: [
                    AttackTool(name: "metasploit", command: "use auxiliary/scanner/rdp/cve_2019_0708_bluekeep"),
                    AttackTool(name: "rdpscan", command: "rdpscan {{target}}:\(port)")
                ],
                prerequisites: [],
                chainable: false,
                estimatedDuration: 30,
                detectionRisk: .low,
                evidence: "RDP service on port \(port)"
            ),
            
            IntelligentAttackVector(
                id: "RDP-BRUTE",
                name: "RDP Credential Attack",
                description: "Brute force RDP credentials",
                category: .bruteForce,
                severity: .high,
                reliability: .medium,
                tools: [
                    AttackTool(name: "hydra", command: "hydra -L {{userlist}} -P {{passlist}} rdp://{{target}}:\(port)"),
                    AttackTool(name: "crowbar", command: "crowbar -b rdp -s {{target}}/32 -p \(port) -U {{userlist}} -C {{passlist}}")
                ],
                prerequisites: ["userlist", "passlist"],
                chainable: false,
                estimatedDuration: 600,
                detectionRisk: .high,
                evidence: "RDP service on port \(port)"
            )
        ]
    }
    
    private func determineVNCAttackVectors(_ serviceInfo: ServiceInfo, port: Int) -> [IntelligentAttackVector] {
        return [
            IntelligentAttackVector(
                id: "VNC-NOAUTH",
                name: "VNC No Authentication",
                description: "Check for VNC servers without authentication",
                category: .misconfiguration,
                severity: .critical,
                reliability: .high,
                tools: [
                    AttackTool(name: "nmap", command: "nmap -p \(port) --script vnc-info {{target}}"),
                    AttackTool(name: "metasploit", command: "use auxiliary/scanner/vnc/vnc_none_auth")
                ],
                prerequisites: [],
                chainable: false,
                estimatedDuration: 30,
                detectionRisk: .low,
                evidence: "VNC service on port \(port)"
            )
        ]
    }
    
    private func determineCustomServiceVectors(_ name: String, _ serviceInfo: ServiceInfo, port: Int) -> [IntelligentAttackVector] {
        // Generic vectors for unknown services
        return [
            IntelligentAttackVector(
                id: "CUSTOM-ENUM",
                name: "\(name) Service Enumeration",
                description: "Enumerate custom service information",
                category: .discovery,
                severity: .low,
                reliability: .medium,
                tools: [
                    AttackTool(name: "nmap", command: "nmap -p \(port) -sV --script banner {{target}}"),
                    AttackTool(name: "nc", command: "nc -nv {{target}} \(port)")
                ],
                prerequisites: [],
                chainable: true,
                estimatedDuration: 60,
                detectionRisk: .low,
                evidence: "\(name) service on port \(port)"
            )
        ]
    }
    
    private func determineGenericAttackVectors(_ serviceInfo: ServiceInfo, port: Int) -> [IntelligentAttackVector] {
        return [
            IntelligentAttackVector(
                id: "GENERIC-PROBE",
                name: "Generic Service Probe",
                description: "Probe unknown service for information",
                category: .discovery,
                severity: .low,
                reliability: .low,
                tools: [
                    AttackTool(name: "nmap", command: "nmap -p \(port) -sV -sC {{target}}"),
                    AttackTool(name: "amap", command: "amap -b {{target}} \(port)")
                ],
                prerequisites: [],
                chainable: true,
                estimatedDuration: 120,
                detectionRisk: .low,
                evidence: "Unknown service on port \(port)"
            )
        ]
    }
    
    private func determineOSSpecificVectors(_ osInfo: OSInfo, scanResults: [PortScanResult]) -> [IntelligentAttackVector] {
        var vectors: [IntelligentAttackVector] = []
        
        if osInfo.name.lowercased().contains("windows") {
            // Windows-specific vectors
            vectors.append(contentsOf: [
                IntelligentAttackVector(
                    id: "WIN-MIMIKATZ",
                    name: "Windows Credential Dumping",
                    description: "Attempt to dump Windows credentials using Mimikatz techniques",
                    category: .privilege,
                    severity: .critical,
                    reliability: .medium,
                    tools: [
                        AttackTool(name: "crackmapexec", command: "crackmapexec smb {{target}} -u {{user}} -p {{pass}} -M mimikatz"),
                        AttackTool(name: "impacket", command: "secretsdump.py {{domain}}/{{user}}:{{pass}}@{{target}}")
                    ],
                    prerequisites: ["valid_creds"],
                    chainable: false,
                    estimatedDuration: 120,
                    detectionRisk: .high,
                    evidence: "Windows OS detected: \(osInfo.name)"
                ),
                
                IntelligentAttackVector(
                    id: "WIN-PSEXEC",
                    name: "PsExec Remote Execution",
                    description: "Attempt remote command execution via PsExec",
                    category: .privilege,
                    severity: .high,
                    reliability: .high,
                    tools: [
                        AttackTool(name: "impacket", command: "psexec.py {{domain}}/{{user}}:{{pass}}@{{target}}"),
                        AttackTool(name: "metasploit", command: "use exploit/windows/smb/psexec")
                    ],
                    prerequisites: ["valid_creds"],
                    chainable: false,
                    estimatedDuration: 60,
                    detectionRisk: .high,
                    evidence: "Windows with SMB service"
                )
            ])
        } else if osInfo.name.lowercased().contains("linux") {
            // Linux-specific vectors
            vectors.append(IntelligentAttackVector(
                id: "LINUX-KERNEL",
                name: "Linux Kernel Exploit Check",
                description: "Check for kernel vulnerabilities based on version",
                category: .vulnerability,
                severity: .high,
                reliability: .medium,
                tools: [
                    AttackTool(name: "linux-exploit-suggester", command: "bash linux-exploit-suggester.sh --kernel \(osInfo.kernel ?? "unknown")"),
                    AttackTool(name: "kernelpop", command: "python3 kernelpop.py --kernel \(osInfo.kernel ?? "unknown")")
                ],
                prerequisites: [],
                chainable: true,
                estimatedDuration: 60,
                detectionRisk: .low,
                evidence: "Linux kernel: \(osInfo.kernel ?? "unknown")"
            ))
        }
        
        return vectors
    }
    
    private func determineWebAppVectors(_ webResults: [WebTestResult], scanResults: [PortScanResult]) -> [IntelligentAttackVector] {
        var vectors: [IntelligentAttackVector] = []
        
        // Analyze web test results for specific vulnerabilities
        for result in webResults {
            if result.status == .vulnerable, let vuln = result.vulnerability {
                switch vuln.title {
                case let title where title.contains("SQL Injection"):
                    vectors.append(IntelligentAttackVector(
                        id: "WEB-SQLI-EXPLOIT",
                        name: "SQL Injection Exploitation",
                        description: "Exploit confirmed SQL injection vulnerability",
                        category: .vulnerability,
                        severity: .critical,
                        reliability: .high,
                        tools: [
                            AttackTool(name: "sqlmap", command: "sqlmap -u {{url}} --batch --dump"),
                            AttackTool(name: "ghauri", command: "ghauri -u {{url}} --batch")
                        ],
                        prerequisites: [],
                        chainable: false,
                        estimatedDuration: 300,
                        detectionRisk: .high,
                        evidence: "Confirmed SQLi: \(vuln.description)"
                    ))
                    
                case let title where title.contains("XSS"):
                    vectors.append(IntelligentAttackVector(
                        id: "WEB-XSS-EXPLOIT",
                        name: "XSS Exploitation",
                        description: "Exploit confirmed XSS vulnerability",
                        category: .vulnerability,
                        severity: .high,
                        reliability: .high,
                        tools: [
                            AttackTool(name: "xsstrike", command: "xsstrike -u {{url}} --crawl"),
                            AttackTool(name: "dalfox", command: "dalfox -u {{url}}")
                        ],
                        prerequisites: [],
                        chainable: true,
                        estimatedDuration: 180,
                        detectionRisk: .medium,
                        evidence: "Confirmed XSS: \(vuln.description)"
                    ))
                    
                default:
                    break
                }
            }
        }
        
        return vectors
    }
}
