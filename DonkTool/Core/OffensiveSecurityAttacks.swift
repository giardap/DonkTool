//
//  OffensiveSecurityAttacks.swift
//  DonkTool
//
//  Advanced offensive security attack vectors
//

import Foundation

extension AttackFramework {
    
    // MARK: - Offensive Security Attack Vectors
    
    static let offensiveSecurityAttacks: [OffensiveAttackVector] = [
        
        // MARK: - Reconnaissance Attacks
        
        OffensiveAttackVector(
            id: "amass-enum",
            name: "Amass DNS Enumeration",
            description: "Comprehensive DNS enumeration and subdomain discovery using OWASP Amass",
            category: .reconnaissance,
            requiredTools: [.amass],
            commands: [
                "amass enum -passive -d TARGET -o /tmp/amass_TARGET.txt",
                "amass enum -active -d TARGET -o /tmp/amass_active_TARGET.txt",
                "amass intel -d TARGET -whois"
            ],
            severity: .info,
            estimatedDuration: 600
        ),
        
        OffensiveAttackVector(
            id: "theharvester-osint",
            name: "TheHarvester OSINT",
            description: "Gather emails, subdomains, hosts, employee names, open ports and banners",
            category: .reconnaissance,
            requiredTools: [.theHarvester],
            commands: [
                "theHarvester -d TARGET -b google,bing,duckduckgo,shodan,censys -l 500",
                "theHarvester -d TARGET -b linkedin -l 200",
                "theHarvester -d TARGET -b dnsdumpster,threatcrowd -l 500"
            ],
            severity: .info,
            estimatedDuration: 300
        ),
        
        OffensiveAttackVector(
            id: "recon-ng-full",
            name: "Recon-ng Full Scan",
            description: "Automated reconnaissance using Recon-ng framework",
            category: .reconnaissance,
            requiredTools: [.reconNg],
            commands: [
                "echo 'marketplace install all' | recon-ng",
                "echo 'modules load recon/domains-hosts/hackertarget && options set SOURCE TARGET && run' | recon-ng",
                "echo 'modules load recon/domains-hosts/threatcrowd && options set SOURCE TARGET && run' | recon-ng"
            ],
            severity: .info,
            estimatedDuration: 480
        ),
        
        // MARK: - Advanced XSS Detection
        
        OffensiveAttackVector(
            id: "xsstrike-advanced",
            name: "XSStrike Advanced XSS",
            description: "Advanced XSS detection with context analysis and WAF bypassing",
            category: .webExploitation,
            requiredTools: [.xsstrike],
            commands: [
                "python3 /opt/XSStrike/xsstrike.py -u 'http://TARGET:PORT' --crawl",
                "python3 /opt/XSStrike/xsstrike.py -u 'http://TARGET:PORT' --fuzzer",
                "python3 /opt/XSStrike/xsstrike.py -u 'http://TARGET:PORT' --params"
            ],
            severity: .high,
            estimatedDuration: 600
        ),
        
        OffensiveAttackVector(
            id: "dalfox-xss",
            name: "DalFox XSS Scanner",
            description: "Fast parameter analysis and XSS scanning with proof-of-concept generation",
            category: .webExploitation,
            requiredTools: [.dalfox],
            commands: [
                "dalfox url http://TARGET:PORT",
                "dalfox url http://TARGET:PORT --deep-domxss",
                "dalfox url http://TARGET:PORT --mining-dict-word"
            ],
            severity: .high,
            estimatedDuration: 300
        ),
        
        // MARK: - Parameter Discovery
        
        OffensiveAttackVector(
            id: "arjun-param",
            name: "Arjun Parameter Discovery",
            description: "HTTP parameter discovery for hidden parameters",
            category: .webExploitation,
            requiredTools: [.arjun],
            commands: [
                "arjun -u http://TARGET:PORT",
                "arjun -u http://TARGET:PORT -m POST",
                "arjun -u http://TARGET:PORT -m JSON"
            ],
            severity: .medium,
            estimatedDuration: 180
        ),
        
        OffensiveAttackVector(
            id: "paramspider",
            name: "ParamSpider Mining",
            description: "Mine parameters from web archives",
            category: .reconnaissance,
            requiredTools: [.paramspider],
            commands: [
                "paramspider -d TARGET",
                "paramspider -d TARGET --exclude woff,css,js,png,svg,jpg",
                "paramspider -d TARGET --level high"
            ],
            severity: .info,
            estimatedDuration: 120
        ),
        
        // MARK: - Wireless Attacks
        
        OffensiveAttackVector(
            id: "aircrack-wpa",
            name: "Aircrack-ng WPA Attack",
            description: "WPA/WPA2 handshake capture and cracking",
            category: .wireless,
            requiredTools: [.aircrackNg],
            commands: [
                "sudo airmon-ng start en0",
                "sudo airodump-ng -c TARGET --bssid PORT -w /tmp/capture en0mon",
                "sudo aireplay-ng -0 10 -a PORT en0mon",
                "sudo aircrack-ng -w /opt/SecLists/Passwords/WiFi-WPA/probable-v2-wpa-top4800.txt /tmp/capture*.cap"
            ],
            severity: .critical,
            estimatedDuration: 1800
        ),
        
        OffensiveAttackVector(
            id: "bettercap-mitm",
            name: "Bettercap MITM Attack",
            description: "Man-in-the-middle attack with credential harvesting",
            category: .wireless,
            requiredTools: [.bettercap],
            commands: [
                "sudo bettercap -iface en0 -eval 'net.probe on; net.sniff on'",
                "sudo bettercap -iface en0 -eval 'set arp.spoof.targets TARGET; arp.spoof on'",
                "sudo bettercap -iface en0 -eval 'set http.proxy.sslstrip true; http.proxy on'"
            ],
            severity: .critical,
            estimatedDuration: 600
        ),
        
        // MARK: - Password Attacks
        
        OffensiveAttackVector(
            id: "john-hash-crack",
            name: "John The Ripper Hash Cracking",
            description: "Crack password hashes using John the Ripper",
            category: .bruteForce,
            requiredTools: [.john],
            commands: [
                "john --wordlist=/opt/SecLists/Passwords/Leaked-Databases/rockyou.txt /tmp/hashes.txt",
                "john --show /tmp/hashes.txt",
                "john --format=raw-md5 /tmp/hashes.txt"
            ],
            severity: .high,
            estimatedDuration: 3600
        ),
        
        OffensiveAttackVector(
            id: "hashcat-gpu",
            name: "Hashcat GPU Cracking",
            description: "GPU-accelerated password hash cracking",
            category: .bruteForce,
            requiredTools: [.hashcat],
            commands: [
                "hashcat -m 0 /tmp/hashes.txt /opt/SecLists/Passwords/Leaked-Databases/rockyou.txt",
                "hashcat -m 1000 /tmp/hashes.txt /opt/SecLists/Passwords/Leaked-Databases/rockyou.txt",
                "hashcat -m 5600 /tmp/hashes.txt /opt/SecLists/Passwords/Leaked-Databases/rockyou.txt -r /usr/share/hashcat/rules/best64.rule"
            ],
            severity: .high,
            estimatedDuration: 7200
        ),
        
        // MARK: - SMB/Network Attacks
        
        OffensiveAttackVector(
            id: "smbmap-enum",
            name: "SMBMap Enumeration",
            description: "Enumerate SMB shares and permissions",
            category: .networkExploitation,
            requiredTools: [.smbmap],
            commands: [
                "smbmap -H TARGET",
                "smbmap -H TARGET -u guest",
                "smbmap -H TARGET -R --depth 5"
            ],
            severity: .medium,
            estimatedDuration: 180
        ),
        
        OffensiveAttackVector(
            id: "crackmapexec",
            name: "CrackMapExec Network Attack",
            description: "Network protocol attacks and credential testing",
            category: .networkExploitation,
            requiredTools: [.crackmapexec],
            commands: [
                "crackmapexec smb TARGET",
                "crackmapexec smb TARGET -u Administrator -p /opt/SecLists/Passwords/Common-Credentials/top-passwords-shortlist.txt",
                "crackmapexec smb TARGET --shares"
            ],
            severity: .high,
            estimatedDuration: 600
        ),
        
        OffensiveAttackVector(
            id: "responder-llmnr",
            name: "Responder LLMNR Poisoning",
            description: "LLMNR/NBT-NS/mDNS poisoning for credential harvesting",
            category: .networkExploitation,
            requiredTools: [.responder],
            commands: [
                "sudo python3 /opt/Responder/Responder.py -I en0 -A",
                "sudo python3 /opt/Responder/Responder.py -I en0 -wrf"
            ],
            severity: .critical,
            estimatedDuration: 1800
        ),
        
        // MARK: - WordPress Attacks
        
        OffensiveAttackVector(
            id: "wpscan-full",
            name: "WPScan Full Audit",
            description: "Comprehensive WordPress vulnerability scan",
            category: .webExploitation,
            requiredTools: [.wpscan],
            commands: [
                "wpscan --url http://TARGET:PORT --enumerate ap,at,cb,dbe",
                "wpscan --url http://TARGET:PORT --enumerate u",
                "wpscan --url http://TARGET:PORT --passwords /opt/SecLists/Passwords/Common-Credentials/top-passwords-shortlist.txt"
            ],
            severity: .high,
            estimatedDuration: 900
        ),
        
        // MARK: - Fuzzing Attacks
        
        OffensiveAttackVector(
            id: "afl-fuzz",
            name: "AFL++ Fuzzing",
            description: "Advanced fuzzing for vulnerability discovery",
            category: .fuzzing,
            requiredTools: [.aflPlusPlus],
            commands: [
                "afl-fuzz -i /tmp/inputs -o /tmp/afl_findings -- TARGET",
                "afl-plot /tmp/afl_findings /tmp/plot_data"
            ],
            severity: .high,
            estimatedDuration: 3600
        ),
        
        OffensiveAttackVector(
            id: "radamsa-fuzz",
            name: "Radamsa Input Mutation",
            description: "Generate malformed inputs for fuzzing",
            category: .fuzzing,
            requiredTools: [.radamsa],
            commands: [
                "echo 'test' | radamsa -n 1000 > /tmp/fuzz_inputs.txt",
                "radamsa /tmp/valid_input.txt -n 1000 | nc TARGET PORT"
            ],
            severity: .medium,
            estimatedDuration: 600
        ),
        
        // MARK: - Advanced Web Crawling
        
        OffensiveAttackVector(
            id: "photon-crawler",
            name: "Photon Web Crawler",
            description: "Advanced web crawling with data extraction",
            category: .reconnaissance,
            requiredTools: [.photon],
            commands: [
                "photon -u http://TARGET:PORT -l 3 -t 10",
                "photon -u http://TARGET:PORT --keys",
                "photon -u http://TARGET:PORT --dns --cookies"
            ],
            severity: .info,
            estimatedDuration: 600
        ),
        
        // MARK: - DNS Attacks
        
        OffensiveAttackVector(
            id: "dnsrecon-full",
            name: "DNSRecon Full Enumeration",
            description: "Comprehensive DNS reconnaissance",
            category: .reconnaissance,
            requiredTools: [.dnsrecon],
            commands: [
                "dnsrecon -d TARGET -t std",
                "dnsrecon -d TARGET -t brt -D /opt/SecLists/Discovery/DNS/deepmagic.com-prefixes-top50000.txt",
                "dnsrecon -d TARGET -t srv,axfr"
            ],
            severity: .info,
            estimatedDuration: 480
        ),
        
        OffensiveAttackVector(
            id: "sublist3r-enum",
            name: "Sublist3r Subdomain Enumeration",
            description: "Fast subdomain enumeration using multiple sources",
            category: .reconnaissance,
            requiredTools: [.sublist3r],
            commands: [
                "sublist3r -d TARGET -b -t 10 -o /tmp/sublist3r_TARGET.txt",
                "sublist3r -d TARGET -p 80,443,8080,8443"
            ],
            severity: .info,
            estimatedDuration: 300
        )
    ]
    
    // MARK: - Tool Execution Methods
    
    func executeOffensiveTool(_ tool: String, args: [String], session: OffensiveAttackSession) async -> (output: [String], findings: [String]) {
        var output: [String] = []
        var findings: [String] = []
        
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        // Check if tool exists
        guard let toolPath = ToolDetection.shared.getToolPath(tool) ?? which(tool) else {
            output.append("❌ Tool '\(tool)' not found. Please run install-offsec-tools.sh")
            return (output, findings)
        }
        
        process.executableURL = URL(fileURLWithPath: toolPath)
        process.arguments = args
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        do {
            try process.run()
            
            // Read output in real-time
            let outputHandle = outputPipe.fileHandleForReading
            let errorHandle = errorPipe.fileHandleForReading
            
            // Process output
            if let outputData = try? outputHandle.readDataToEndOfFile(),
               let outputString = String(data: outputData, encoding: .utf8) {
                let lines = outputString.components(separatedBy: .newlines)
                output.append(contentsOf: lines.filter { !$0.isEmpty })
                
                // Parse findings based on tool
                findings = parseToolFindings(tool: tool, output: lines)
            }
            
            // Process errors
            if let errorData = try? errorHandle.readDataToEndOfFile(),
               let errorString = String(data: errorData, encoding: .utf8),
               !errorString.isEmpty {
                output.append("⚠️ Errors: \(errorString)")
            }
            
            process.waitUntilExit()
            
        } catch {
            output.append("❌ Failed to execute \(tool): \(error.localizedDescription)")
        }
        
        return (output, findings)
    }
    
    private func parseToolFindings(tool: String, output: [String]) -> [String] {
        var findings: [String] = []
        
        switch tool {
        case "amass":
            // Parse Amass subdomain findings
            findings = output.filter { line in
                line.contains(".") && !line.contains("Querying") && !line.contains("-->")
            }
            
        case "theharvester":
            // Parse TheHarvester findings
            for line in output {
                if line.contains("@") || (line.contains(".") && !line.contains("Searching")) {
                    findings.append(line.trimmingCharacters(in: .whitespaces))
                }
            }
            
        case "xsstrike", "dalfox":
            // Parse XSS findings
            findings = output.filter { line in
                line.lowercased().contains("vulnerable") ||
                line.lowercased().contains("payload") ||
                line.contains("XSS")
            }
            
        case "john", "hashcat":
            // Parse cracked passwords
            findings = output.filter { line in
                line.contains(":") && !line.contains("Session") && !line.contains("Status")
            }
            
        default:
            // Generic finding detection
            findings = output.filter { line in
                line.contains("found") ||
                line.contains("vulnerable") ||
                line.contains("VULNERABLE") ||
                line.contains("SUCCESS")
            }
        }
        
        return findings
    }
    
    private func which(_ command: String) -> String? {
        let process = Process()
        let pipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [command]
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            
            return path?.isEmpty == false ? path : nil
        } catch {
            return nil
        }
    }
}

// MARK: - Custom Tool Names Extension

extension OffensiveAttackTool {
    static func custom(_ name: String) -> OffensiveAttackTool {
        return OffensiveAttackTool(rawValue: name)
    }
}