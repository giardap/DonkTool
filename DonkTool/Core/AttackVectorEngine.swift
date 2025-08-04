//
//  AttackVectorEngine.swift
//  DonkTool
//
//  Advanced attack vector generation and determination system
//

import Foundation
import SwiftUI

class AttackVectorEngine: ObservableObject {
    @Published var availableAttackVectors: [AttackVector] = []
    @Published var isGeneratingVectors = false
    
    private let cveDatabase: CVEDatabase
    private let toolDetection: ToolDetection
    
    init(cveDatabase: CVEDatabase = CVEDatabase(), toolDetection: ToolDetection = ToolDetection.shared) {
        self.cveDatabase = cveDatabase
        self.toolDetection = toolDetection
    }
    
    // MARK: - Service-Specific Attack Vector Generation
    
    func generateAttackVectors(for target: Target) async -> [AttackVector] {
        isGeneratingVectors = true
        defer { isGeneratingVectors = false }
        
        var attackVectors: [AttackVector] = []
        
        // Generate vectors for each vulnerability/service
        for vulnerability in target.vulnerabilities {
            if let service = vulnerability.service, let port = vulnerability.port {
                let serviceVectors = await generateServiceAttackVectors(
                    service: service,
                    port: port,
                    target: target.ipAddress,
                    vulnerability: vulnerability
                )
                attackVectors.append(contentsOf: serviceVectors)
            }
        }
        
        // Add generic reconnaissance vectors
        attackVectors.append(contentsOf: generateReconnaissanceVectors(for: target))
        
        // Sort by priority and effectiveness
        attackVectors.sort { $0.severity.rawValue > $1.severity.rawValue }
        
        let finalVectors = attackVectors
        await MainActor.run {
            self.availableAttackVectors = finalVectors
        }
        
        return attackVectors
    }
    
    private func generateServiceAttackVectors(service: String, port: Int, target: String, vulnerability: Vulnerability) async -> [AttackVector] {
        let serviceLower = service.lowercased()
        var vectors: [AttackVector] = []
        
        switch serviceLower {
        case "ssh", "openssh":
            vectors.append(contentsOf: generateSSHAttackVectors(port: port, target: target))
            
        case "http", "https", "apache", "nginx", "iis":
            vectors.append(contentsOf: generateWebAttackVectors(port: port, target: target, isHttps: serviceLower.contains("https")))
            
        case "ftp", "ftps":
            vectors.append(contentsOf: generateFTPAttackVectors(port: port, target: target))
            
        case "smtp", "smtps":
            vectors.append(contentsOf: generateSMTPAttackVectors(port: port, target: target))
            
        case "dns":
            vectors.append(contentsOf: generateDNSAttackVectors(port: port, target: target))
            
        case "mysql", "mariadb":
            vectors.append(contentsOf: generateMySQLAttackVectors(port: port, target: target))
            
        case "postgresql", "postgres":
            vectors.append(contentsOf: generatePostgreSQLAttackVectors(port: port, target: target))
            
        case "mssql", "sqlserver":
            vectors.append(contentsOf: generateMSSQLAttackVectors(port: port, target: target))
            
        case "smb", "netbios", "microsoft-ds":
            vectors.append(contentsOf: generateSMBAttackVectors(port: port, target: target))
            
        case "rdp", "ms-wbt-server":
            vectors.append(contentsOf: generateRDPAttackVectors(port: port, target: target))
            
        case "vnc":
            vectors.append(contentsOf: generateVNCAttackVectors(port: port, target: target))
            
        case "telnet":
            vectors.append(contentsOf: generateTelnetAttackVectors(port: port, target: target))
            
        case "snmp":
            vectors.append(contentsOf: generateSNMPAttackVectors(port: port, target: target))
            
        default:
            // Generic port-based attacks
            vectors.append(contentsOf: generateGenericPortAttackVectors(port: port, target: target, service: service))
        }
        
        // Add CVE-specific attack vectors if available
        if let cveId = vulnerability.cveId {
            let cveVectors = await generateCVEAttackVectors(cveId: cveId, target: target, port: port)
            vectors.append(contentsOf: cveVectors)
        }
        
        return vectors
    }
    
    // MARK: - SSH Attack Vectors
    
    private func generateSSHAttackVectors(port: Int, target: String) -> [AttackVector] {
        var vectors: [AttackVector] = []
        
        // SSH Brute Force
        vectors.append(AttackVector(
            name: "SSH Brute Force Attack",
            description: "Attempt to brute force SSH credentials using common usernames and passwords",
            severity: .high,
            requirements: [
                ToolRequirement(name: "hydra", type: .tool, description: "THC Hydra password cracker"),
                ToolRequirement(name: "nmap", type: .tool, description: "Network mapper for service detection")
            ],
            commands: [
                "hydra -L /usr/share/wordlists/common-users.txt -P /usr/share/wordlists/rockyou.txt ssh://\(target):\(port)",
                "hydra -l root -P /usr/share/wordlists/common-passwords.txt ssh://\(target):\(port)",
                "hydra -l admin -P /usr/share/wordlists/common-passwords.txt ssh://\(target):\(port)"
            ],
            references: [
                "https://github.com/vanhauser-thc/thc-hydra",
                "https://owasp.org/www-community/attacks/Brute_force_attack"
            ]
        ))
        
        // SSH Key Authentication Bypass
        vectors.append(AttackVector(
            name: "SSH Key Enumeration",
            description: "Enumerate SSH host keys and check for weak configurations",
            severity: .medium,
            requirements: [
                ToolRequirement(name: "ssh-keyscan", type: .builtin, description: "SSH key scanner"),
                ToolRequirement(name: "nmap", type: .tool, description: "Network mapper")
            ],
            commands: [
                "ssh-keyscan -p \(port) \(target)",
                "nmap -p \(port) --script ssh-hostkey \(target)",
                "nmap -p \(port) --script ssh-auth-methods \(target)"
            ],
            references: [
                "https://nmap.org/nsedoc/scripts/ssh-hostkey.html"
            ]
        ))
        
        // SSH Version Detection and Exploit Search
        vectors.append(AttackVector(
            name: "SSH Version Analysis",
            description: "Detect SSH version and search for known vulnerabilities",
            severity: .medium,
            requirements: [
                ToolRequirement(name: "nmap", type: .tool, description: "Network mapper"),
                ToolRequirement(name: "searchsploit", type: .optional, description: "Exploit database search")
            ],
            commands: [
                "nmap -p \(port) -sV --script ssh2-enum-algos \(target)",
                "nmap -p \(port) --script ssh-run \(target)"
            ],
            references: [
                "https://nmap.org/nsedoc/scripts/ssh2-enum-algos.html"
            ]
        ))
        
        return vectors
    }
    
    // MARK: - Web Attack Vectors
    
    private func generateWebAttackVectors(port: Int, target: String, isHttps: Bool) -> [AttackVector] {
        var vectors: [AttackVector] = []
        let protocolScheme = isHttps ? "https" : "http"
        let baseUrl = "\(protocolScheme)://\(target):\(port)"
        
        // Directory Enumeration
        vectors.append(AttackVector(
            name: "Web Directory Enumeration",
            description: "Discover hidden directories and files on the web server",
            severity: .medium,
            requirements: [
                ToolRequirement(name: "gobuster", type: .tool, description: "Directory/file brute forcer"),
                ToolRequirement(name: "dirb", type: .tool, description: "Web content scanner")
            ],
            commands: [
                "gobuster dir -u \(baseUrl) -w /usr/share/wordlists/dirb/common.txt",
                "dirb \(baseUrl) /usr/share/wordlists/dirb/common.txt",
                "gobuster dir -u \(baseUrl) -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -x php,html,txt,js"
            ],
            references: [
                "https://github.com/OJ/gobuster",
                "https://tools.kali.org/web-applications/dirb"
            ]
        ))
        
        // Nikto Web Vulnerability Scan
        vectors.append(AttackVector(
            name: "Comprehensive Web Vulnerability Scan",
            description: "Perform comprehensive web application vulnerability assessment",
            severity: .high,
            requirements: [
                ToolRequirement(name: "nikto", type: .tool, description: "Web server scanner")
            ],
            commands: [
                "nikto -h \(baseUrl) -p \(port)",
                "nikto -h \(baseUrl) -p \(port) -C all"
            ],
            references: [
                "https://cirt.net/Nikto2"
            ]
        ))
        
        // Nuclei Template-Based Scanning
        vectors.append(AttackVector(
            name: "Nuclei Template Scan",
            description: "Fast vulnerability scanner with 9000+ community templates",
            severity: .critical,
            requirements: [
                ToolRequirement(name: "nuclei", type: .tool, description: "Vulnerability scanner")
            ],
            commands: [
                "nuclei -u \(baseUrl) -t /Users/\(NSUserName())/nuclei-templates/",
                "nuclei -u \(baseUrl) -tags cve,owasp,top10",
                "nuclei -u \(baseUrl) -severity critical,high,medium"
            ],
            references: [
                "https://github.com/projectdiscovery/nuclei"
            ]
        ))
        
        // SQL Injection Testing
        vectors.append(AttackVector(
            name: "SQL Injection Assessment",
            description: "Test for SQL injection vulnerabilities using SQLMap",
            severity: .critical,
            requirements: [
                ToolRequirement(name: "sqlmap", type: .tool, description: "SQL injection testing tool")
            ],
            commands: [
                "sqlmap -u \(baseUrl) --batch --crawl=2",
                "sqlmap -u \(baseUrl) --forms --batch --risk=3 --level=3",
                "sqlmap -u \(baseUrl) --dbs --batch"
            ],
            references: [
                "https://sqlmap.org/",
                "https://owasp.org/www-community/attacks/SQL_Injection"
            ]
        ))
        
        // SSL/TLS Analysis (for HTTPS)
        if isHttps {
            vectors.append(AttackVector(
                name: "SSL/TLS Security Analysis",
                description: "Analyze SSL/TLS configuration for security weaknesses",
                severity: .high,
                requirements: [
                    ToolRequirement(name: "sslyze", type: .tool, description: "SSL configuration scanner"),
                    ToolRequirement(name: "nmap", type: .tool, description: "Network mapper")
                ],
                commands: [
                    "sslyze --regular \(target):\(port)",
                    "nmap -p \(port) --script ssl-enum-ciphers \(target)",
                    "nmap -p \(port) --script ssl-cert,ssl-date \(target)"
                ],
                references: [
                    "https://github.com/nabla-c0d3/sslyze"
                ]
            ))
        }
        
        return vectors
    }
    
    // MARK: - FTP Attack Vectors
    
    private func generateFTPAttackVectors(port: Int, target: String) -> [AttackVector] {
        var vectors: [AttackVector] = []
        
        // FTP Anonymous Login
        vectors.append(AttackVector(
            name: "FTP Anonymous Access Test",
            description: "Test for anonymous FTP access and enumerate accessible files",
            severity: .medium,
            requirements: [
                ToolRequirement(name: "ftp", type: .builtin, description: "FTP client"),
                ToolRequirement(name: "nmap", type: .tool, description: "Network mapper")
            ],
            commands: [
                "nmap -p \(port) --script ftp-anon \(target)",
                "echo 'anonymous' | ftp \(target) \(port)"
            ],
            references: [
                "https://nmap.org/nsedoc/scripts/ftp-anon.html"
            ]
        ))
        
        // FTP Brute Force
        vectors.append(AttackVector(
            name: "FTP Brute Force Attack",
            description: "Attempt to brute force FTP credentials",
            severity: .high,
            requirements: [
                ToolRequirement(name: "hydra", type: .tool, description: "THC Hydra password cracker")
            ],
            commands: [
                "hydra -L /usr/share/wordlists/common-users.txt -P /usr/share/wordlists/common-passwords.txt ftp://\(target):\(port)",
                "hydra -l anonymous -p anonymous ftp://\(target):\(port)"
            ],
            references: [
                "https://github.com/vanhauser-thc/thc-hydra"
            ]
        ))
        
        return vectors
    }
    
    // MARK: - Database Attack Vectors
    
    private func generateMySQLAttackVectors(port: Int, target: String) -> [AttackVector] {
        var vectors: [AttackVector] = []
        
        // MySQL Brute Force
        vectors.append(AttackVector(
            name: "MySQL Brute Force Attack",
            description: "Attempt to brute force MySQL database credentials",
            severity: .high,
            requirements: [
                ToolRequirement(name: "hydra", type: .tool, description: "THC Hydra password cracker"),
                ToolRequirement(name: "nmap", type: .tool, description: "Network mapper")
            ],
            commands: [
                "hydra -L /usr/share/wordlists/common-users.txt -P /usr/share/wordlists/common-passwords.txt mysql://\(target):\(port)",
                "nmap -p \(port) --script mysql-brute \(target)",
                "nmap -p \(port) --script mysql-empty-password \(target)"
            ],
            references: [
                "https://nmap.org/nsedoc/scripts/mysql-brute.html"
            ]
        ))
        
        // MySQL Information Gathering
        vectors.append(AttackVector(
            name: "MySQL Information Enumeration",
            description: "Enumerate MySQL version and configuration information",
            severity: .medium,
            requirements: [
                ToolRequirement(name: "nmap", type: .tool, description: "Network mapper")
            ],
            commands: [
                "nmap -p \(port) --script mysql-info \(target)",
                "nmap -p \(port) --script mysql-variables \(target)",
                "nmap -p \(port) --script mysql-databases \(target)"
            ],
            references: [
                "https://nmap.org/nsedoc/scripts/mysql-info.html"
            ]
        ))
        
        return vectors
    }
    
    private func generatePostgreSQLAttackVectors(port: Int, target: String) -> [AttackVector] {
        var vectors: [AttackVector] = []
        
        // PostgreSQL Brute Force
        vectors.append(AttackVector(
            name: "PostgreSQL Brute Force Attack",
            description: "Attempt to brute force PostgreSQL database credentials",
            severity: .high,
            requirements: [
                ToolRequirement(name: "hydra", type: .tool, description: "THC Hydra password cracker")
            ],
            commands: [
                "hydra -L /usr/share/wordlists/common-users.txt -P /usr/share/wordlists/common-passwords.txt postgres://\(target):\(port)",
                "hydra -l postgres -P /usr/share/wordlists/common-passwords.txt postgres://\(target):\(port)"
            ],
            references: [
                "https://github.com/vanhauser-thc/thc-hydra"
            ]
        ))
        
        return vectors
    }
    
    private func generateMSSQLAttackVectors(port: Int, target: String) -> [AttackVector] {
        var vectors: [AttackVector] = []
        
        // MSSQL Brute Force
        vectors.append(AttackVector(
            name: "MSSQL Brute Force Attack",
            description: "Attempt to brute force Microsoft SQL Server credentials",
            severity: .high,
            requirements: [
                ToolRequirement(name: "hydra", type: .tool, description: "THC Hydra password cracker"),
                ToolRequirement(name: "nmap", type: .tool, description: "Network mapper")
            ],
            commands: [
                "hydra -L /usr/share/wordlists/common-users.txt -P /usr/share/wordlists/common-passwords.txt mssql://\(target):\(port)",
                "nmap -p \(port) --script ms-sql-brute \(target)",
                "nmap -p \(port) --script ms-sql-empty-password \(target)"
            ],
            references: [
                "https://nmap.org/nsedoc/scripts/ms-sql-brute.html"
            ]
        ))
        
        return vectors
    }
    
    // MARK: - SMB Attack Vectors
    
    private func generateSMBAttackVectors(port: Int, target: String) -> [AttackVector] {
        var vectors: [AttackVector] = []
        
        // SMB Enumeration
        vectors.append(AttackVector(
            name: "SMB Share Enumeration",
            description: "Enumerate SMB shares and accessible resources",
            severity: .medium,
            requirements: [
                ToolRequirement(name: "smbclient", type: .tool, description: "SMB client"),
                ToolRequirement(name: "enum4linux", type: .optional, description: "SMB enumeration tool"),
                ToolRequirement(name: "nmap", type: .tool, description: "Network mapper")
            ],
            commands: [
                "smbclient -L //\(target) -N",
                "nmap -p \(port) --script smb-enum-shares \(target)",
                "nmap -p \(port) --script smb-enum-users \(target)"
            ],
            references: [
                "https://nmap.org/nsedoc/scripts/smb-enum-shares.html"
            ]
        ))
        
        // SMB Vulnerability Scan
        vectors.append(AttackVector(
            name: "SMB Vulnerability Assessment",
            description: "Scan for known SMB vulnerabilities including EternalBlue",
            severity: .critical,
            requirements: [
                ToolRequirement(name: "nmap", type: .tool, description: "Network mapper")
            ],
            commands: [
                "nmap -p \(port) --script smb-vuln-* \(target)",
                "nmap -p \(port) --script smb-vuln-ms17-010 \(target)",
                "nmap -p \(port) --script smb-vuln-cve2009-3103 \(target)"
            ],
            references: [
                "https://nmap.org/nsedoc/scripts/smb-vuln-ms17-010.html"
            ]
        ))
        
        return vectors
    }
    
    // MARK: - RDP Attack Vectors
    
    private func generateRDPAttackVectors(port: Int, target: String) -> [AttackVector] {
        var vectors: [AttackVector] = []
        
        // RDP Brute Force
        vectors.append(AttackVector(
            name: "RDP Brute Force Attack",
            description: "Attempt to brute force Remote Desktop Protocol credentials",
            severity: .high,
            requirements: [
                ToolRequirement(name: "hydra", type: .tool, description: "THC Hydra password cracker"),
                ToolRequirement(name: "nmap", type: .tool, description: "Network mapper")
            ],
            commands: [
                "hydra -L /usr/share/wordlists/common-users.txt -P /usr/share/wordlists/common-passwords.txt rdp://\(target):\(port)",
                "nmap -p \(port) --script rdp-brute \(target)"
            ],
            references: [
                "https://nmap.org/nsedoc/scripts/rdp-brute.html"
            ]
        ))
        
        // RDP Vulnerability Scan
        vectors.append(AttackVector(
            name: "RDP Vulnerability Assessment",
            description: "Scan for RDP vulnerabilities including BlueKeep",
            severity: .critical,
            requirements: [
                ToolRequirement(name: "nmap", type: .tool, description: "Network mapper")
            ],
            commands: [
                "nmap -p \(port) --script rdp-vuln-ms12-020 \(target)",
                "nmap -p \(port) --script rdp-enum-encryption \(target)"
            ],
            references: [
                "https://nmap.org/nsedoc/scripts/rdp-vuln-ms12-020.html"
            ]
        ))
        
        return vectors
    }
    
    // MARK: - Generic Attack Vectors
    
    private func generateGenericPortAttackVectors(port: Int, target: String, service: String) -> [AttackVector] {
        var vectors: [AttackVector] = []
        
        // Port-specific reconnaissance
        vectors.append(AttackVector(
            name: "Service Banner Grabbing",
            description: "Attempt to grab service banner and version information",
            severity: .low,
            requirements: [
                ToolRequirement(name: "nmap", type: .tool, description: "Network mapper"),
                ToolRequirement(name: "netcat", type: .builtin, description: "Network utility")
            ],
            commands: [
                "nmap -p \(port) -sV \(target)",
                "nc -nv \(target) \(port)"
            ],
            references: [
                "https://nmap.org/book/man-version-detection.html"
            ]
        ))
        
        return vectors
    }
    
    private func generateReconnaissanceVectors(for target: Target) -> [AttackVector] {
        var vectors: [AttackVector] = []
        
        // Port Scanning
        vectors.append(AttackVector(
            name: "Comprehensive Port Scan",
            description: "Perform comprehensive port scan to discover all open services",
            severity: .medium,
            requirements: [
                ToolRequirement(name: "nmap", type: .tool, description: "Network mapper")
            ],
            commands: [
                "nmap -sS -A -O \(target.ipAddress)",
                "nmap -p- --min-rate 1000 \(target.ipAddress)",
                "nmap -sU --top-ports 1000 \(target.ipAddress)"
            ],
            references: [
                "https://nmap.org/book/man.html"
            ]
        ))
        
        // DNS Enumeration
        if let domain = target.domain {
            vectors.append(AttackVector(
                name: "DNS Enumeration",
                description: "Enumerate DNS records and subdomains",
                severity: .medium,
                requirements: [
                    ToolRequirement(name: "dig", type: .builtin, description: "DNS lookup utility"),
                    ToolRequirement(name: "subfinder", type: .tool, description: "Subdomain discovery tool")
                ],
                commands: [
                    "dig @8.8.8.8 \(domain) ANY",
                    "subfinder -d \(domain)",
                    "dig @8.8.8.8 \(domain) AXFR"
                ],
                references: [
                    "https://github.com/projectdiscovery/subfinder"
                ]
            ))
        }
        
        return vectors
    }
    
    // MARK: - CVE-Based Attack Vectors
    
    private func generateCVEAttackVectors(cveId: String, target: String, port: Int) async -> [AttackVector] {
        var vectors: [AttackVector] = []
        
        // Search for CVE in our database
        let searchResults = await MainActor.run {
            cveDatabase.searchCVEs(query: cveId)
        }
        
        if let cveItem = searchResults.first {
            let severity: Vulnerability.Severity
            if let baseScore = cveItem.baseScore {
                switch baseScore {
                case 0.0..<4.0: severity = .low
                case 4.0..<7.0: severity = .medium
                case 7.0..<9.0: severity = .high
                default: severity = .critical
                }
            } else {
                severity = .medium
            }
            
            vectors.append(AttackVector(
                name: "CVE-\(cveId) Exploit",
                description: cveItem.description,
                severity: severity,
                requirements: [
                    ToolRequirement(name: "searchsploit", type: .optional, description: "Exploit database search"),
                    ToolRequirement(name: "metasploit", type: .optional, description: "Metasploit framework")
                ],
                commands: [
                    "searchsploit \(cveId)",
                    "msfconsole -q -x 'search \(cveId); exit'"
                ],
                references: [
                    "https://cve.mitre.org/cgi-bin/cvename.cgi?name=\(cveId)",
                    "https://nvd.nist.gov/vuln/detail/\(cveId)"
                ] + cveItem.references
            ))
        }
        
        return vectors
    }
    
    // MARK: - Additional Service-Specific Vectors
    
    private func generateSMTPAttackVectors(port: Int, target: String) -> [AttackVector] {
        var vectors: [AttackVector] = []
        
        vectors.append(AttackVector(
            name: "SMTP User Enumeration",
            description: "Enumerate valid email addresses via SMTP VRFY/EXPN",
            severity: .medium,
            requirements: [
                ToolRequirement(name: "nmap", type: .tool, description: "Network mapper")
            ],
            commands: [
                "nmap -p \(port) --script smtp-enum-users \(target)",
                "nmap -p \(port) --script smtp-commands \(target)"
            ],
            references: [
                "https://nmap.org/nsedoc/scripts/smtp-enum-users.html"
            ]
        ))
        
        return vectors
    }
    
    private func generateDNSAttackVectors(port: Int, target: String) -> [AttackVector] {
        var vectors: [AttackVector] = []
        
        vectors.append(AttackVector(
            name: "DNS Zone Transfer Attack",
            description: "Attempt DNS zone transfer to enumerate all DNS records",
            severity: .high,
            requirements: [
                ToolRequirement(name: "dig", type: .builtin, description: "DNS lookup utility"),
                ToolRequirement(name: "nmap", type: .tool, description: "Network mapper")
            ],
            commands: [
                "dig @\(target) AXFR",
                "nmap -p \(port) --script dns-zone-transfer \(target)"
            ],
            references: [
                "https://nmap.org/nsedoc/scripts/dns-zone-transfer.html"
            ]
        ))
        
        return vectors
    }
    
    private func generateVNCAttackVectors(port: Int, target: String) -> [AttackVector] {
        var vectors: [AttackVector] = []
        
        vectors.append(AttackVector(
            name: "VNC Authentication Bypass",
            description: "Test for VNC authentication bypass vulnerabilities",
            severity: .high,
            requirements: [
                ToolRequirement(name: "nmap", type: .tool, description: "Network mapper")
            ],
            commands: [
                "nmap -p \(port) --script vnc-brute \(target)",
                "nmap -p \(port) --script vnc-info \(target)"
            ],
            references: [
                "https://nmap.org/nsedoc/scripts/vnc-brute.html"
            ]
        ))
        
        return vectors
    }
    
    private func generateTelnetAttackVectors(port: Int, target: String) -> [AttackVector] {
        var vectors: [AttackVector] = []
        
        vectors.append(AttackVector(
            name: "Telnet Brute Force Attack",
            description: "Attempt to brute force Telnet credentials",
            severity: .high,
            requirements: [
                ToolRequirement(name: "hydra", type: .tool, description: "THC Hydra password cracker")
            ],
            commands: [
                "hydra -L /usr/share/wordlists/common-users.txt -P /usr/share/wordlists/common-passwords.txt telnet://\(target):\(port)"
            ],
            references: [
                "https://github.com/vanhauser-thc/thc-hydra"
            ]
        ))
        
        return vectors
    }
    
    private func generateSNMPAttackVectors(port: Int, target: String) -> [AttackVector] {
        var vectors: [AttackVector] = []
        
        vectors.append(AttackVector(
            name: "SNMP Community String Brute Force",
            description: "Brute force SNMP community strings",
            severity: .medium,
            requirements: [
                ToolRequirement(name: "nmap", type: .tool, description: "Network mapper"),
                ToolRequirement(name: "hydra", type: .tool, description: "THC Hydra password cracker")
            ],
            commands: [
                "nmap -p \(port) --script snmp-brute \(target)",
                "hydra -P /usr/share/wordlists/snmp-community-strings.txt snmp://\(target)"
            ],
            references: [
                "https://nmap.org/nsedoc/scripts/snmp-brute.html"
            ]
        ))
        
        return vectors
    }
}

// MARK: - Attack Vector Priority Calculator

extension AttackVectorEngine {
    func calculateAttackPriority(for vector: AttackVector, target: Target) -> Double {
        var priority: Double = 0.0
        
        // Base priority from severity
        switch vector.severity {
        case .critical: priority += 10.0
        case .high: priority += 7.5
        case .medium: priority += 5.0
        case .low: priority += 2.5
        case .info: priority += 1.0
        }
        
        // Tool availability bonus
        if vector.isExecutable {
            priority += 2.0
        } else {
            priority -= 1.0
        }
        
        // Service-specific bonuses
        if vector.name.contains("SSH") || vector.name.contains("RDP") {
            priority += 1.5 // Remote access = higher priority
        }
        
        if vector.name.contains("Web") || vector.name.contains("HTTP") {
            priority += 1.0 // Web attacks are common
        }
        
        return priority
    }
}