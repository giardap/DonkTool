//
//  AttackFramework.swift
//  DonkTool
//
//  Integrated attack execution framework
//

import Foundation
import SwiftUI

// MARK: - Attack Execution Framework

@Observable
class AttackFramework {
    var activeAttacks: [String: AttackSession] = [:]
    var attackHistory: [AttackResult] = []
    var isExecutingAttack = false
    
    // Tool availability status
    var toolsStatus: [AttackTool: ToolStatus] = [:]
    
    enum ToolStatus {
        case available
        case needsInstallation
        case installing
        case failed
        case unavailable
    }
    
    init() {
        Task {
            await checkToolAvailability()
        }
    }
    
    func executeAttack(_ attack: AttackVector, target: String, port: Int) async -> AttackResult {
        let sessionId = UUID().uuidString
        let session = AttackSession(
            id: sessionId,
            attack: attack,
            target: target,
            port: port,
            startTime: Date()
        )
        
        await MainActor.run {
            activeAttacks[sessionId] = session
            isExecutingAttack = true
        }
        
        let result: AttackResult
        
        switch attack.attackType {
        case .bruteForce:
            result = await executeBruteForceAttack(session)
        case .webDirectoryEnum:
            result = await executeDirectoryEnumeration(session)
        case .vulnerabilityExploit:
            result = await executeVulnerabilityExploit(session)
        case .networkRecon:
            result = await executeNetworkReconnaissance(session)
        case .webVulnScan:
            result = await executeWebVulnerabilityScanning(session)
        }
        
        await MainActor.run {
            activeAttacks.removeValue(forKey: sessionId)
            attackHistory.append(result)
            isExecutingAttack = activeAttacks.isEmpty
        }
        
        return result
    }
    
    func stopAttack(_ sessionId: String) {
        if let session = activeAttacks[sessionId] {
            session.cancel()
            activeAttacks.removeValue(forKey: sessionId)
        }
    }
    
    func installTool(_ tool: AttackTool) async {
        await MainActor.run {
            toolsStatus[tool] = .installing
        }
        
        let success = await performToolInstallation(tool)
        
        await MainActor.run {
            toolsStatus[tool] = success ? .available : .failed
        }
    }
    
    private func checkToolAvailability() async {
        for tool in AttackTool.allCases {
            let isInstalled = checkIfToolInstalled(tool)
            await MainActor.run {
                toolsStatus[tool] = isInstalled ? .available : .needsInstallation
            }
        }
    }
    
    // MARK: - Private Attack Implementations
    
    private func executeBruteForceAttack(_ session: AttackSession) async -> AttackResult {
        let startTime = Date()
        var output: [String] = []
        var credentials: [Credential] = []
        
        if session.attack.name.contains("SSH") {
            output.append("Starting SSH brute force attack...")
            output.append("Target: \(session.target):\(session.port)")
            
            // Use actual Hydra for SSH brute force
            let result = await executeHydraSSH(
                target: session.target,
                port: session.port,
                session: session
            )
            
            output.append(contentsOf: result.output)
            credentials.append(contentsOf: result.credentials)
        }
        
        return AttackResult(
            sessionId: session.id,
            attack: session.attack,
            target: session.target,
            port: session.port,
            startTime: startTime,
            endTime: Date(),
            success: !credentials.isEmpty,
            output: output,
            credentials: credentials,
            vulnerabilities: [],
            files: []
        )
    }
    
    private func executeDirectoryEnumeration(_ session: AttackSession) async -> AttackResult {
        let startTime = Date()
        var output: [String] = []
        var discoveredFiles: [String] = []
        
        output.append("Starting directory enumeration...")
        output.append("Target: http://\(session.target):\(session.port)")
        
        // Use actual Dirb for directory enumeration
        let result = await executeDirb(
            target: session.target,
            port: session.port,
            session: session
        )
        
        output.append(contentsOf: result.output)
        discoveredFiles.append(contentsOf: result.files)
        
        return AttackResult(
            sessionId: session.id,
            attack: session.attack,
            target: session.target,
            port: session.port,
            startTime: startTime,
            endTime: Date(),
            success: !discoveredFiles.isEmpty,
            output: output,
            credentials: [],
            vulnerabilities: [],
            files: discoveredFiles
        )
    }
    
    private func executeVulnerabilityExploit(_ session: AttackSession) async -> AttackResult {
        let startTime = Date()
        var output: [String] = []
        var foundVulnerabilities: [VulnerabilityFinding] = []
        
        output.append("Starting vulnerability exploitation...")
        output.append("Target: \(session.target):\(session.port)")
        
        // Use actual SQLMap and Nikto for vulnerability scanning
        let sqlmapResult = await executeSQLMap(
            target: session.target,
            port: session.port,
            session: session
        )
        
        let niktoResult = await executeNikto(
            target: session.target,
            port: session.port,
            session: session
        )
        
        output.append(contentsOf: sqlmapResult.output)
        output.append(contentsOf: niktoResult.output)
        foundVulnerabilities.append(contentsOf: sqlmapResult.vulnerabilities)
        foundVulnerabilities.append(contentsOf: niktoResult.vulnerabilities)
        
        return AttackResult(
            sessionId: session.id,
            attack: session.attack,
            target: session.target,
            port: session.port,
            startTime: startTime,
            endTime: Date(),
            success: !foundVulnerabilities.isEmpty,
            output: output,
            credentials: [],
            vulnerabilities: foundVulnerabilities,
            files: []
        )
    }
    
    private func executeNetworkReconnaissance(_ session: AttackSession) async -> AttackResult {
        let startTime = Date()
        var output: [String] = []
        var discoveredServices: [String] = []
        
        output.append("Starting network reconnaissance...")
        output.append("Target: \(session.target)")
        
        // Use actual Nmap for service detection and OS fingerprinting
        let nmapResult = await executeNmap(
            target: session.target,
            session: session
        )
        
        output.append(contentsOf: nmapResult.output)
        discoveredServices.append(contentsOf: nmapResult.services)
        
        return AttackResult(
            sessionId: session.id,
            attack: session.attack,
            target: session.target,
            port: session.port,
            startTime: startTime,
            endTime: Date(),
            success: !discoveredServices.isEmpty,
            output: output,
            credentials: [],
            vulnerabilities: [],
            files: discoveredServices
        )
    }
    
    private func executeWebVulnerabilityScanning(_ session: AttackSession) async -> AttackResult {
        let startTime = Date()
        var output: [String] = []
        var foundVulnerabilities: [VulnerabilityFinding] = []
        
        output.append("Starting comprehensive web vulnerability scan...")
        output.append("Target: http://\(session.target):\(session.port)")
        
        // Use actual Nikto for web vulnerability scanning
        let niktoResult = await executeNikto(
            target: session.target,
            port: session.port,
            session: session
        )
        
        // Use actual Gobuster for directory enumeration
        let gobusterResult = await executeGobuster(
            target: session.target,
            port: session.port,
            session: session
        )
        
        output.append(contentsOf: niktoResult.output)
        output.append(contentsOf: gobusterResult.output)
        foundVulnerabilities.append(contentsOf: niktoResult.vulnerabilities)
        
        return AttackResult(
            sessionId: session.id,
            attack: session.attack,
            target: session.target,
            port: session.port,
            startTime: startTime,
            endTime: Date(),
            success: !foundVulnerabilities.isEmpty,
            output: output,
            credentials: [],
            vulnerabilities: foundVulnerabilities,
            files: gobusterResult.files
        )
    }
    
    // MARK: - Real Tool Implementations
    
    private func executeHydraSSH(target: String, port: Int, session: AttackSession) async -> (output: [String], credentials: [Credential]) {
        var output: [String] = []
        var credentials: [Credential] = []
        
        // Create wordlists directory if it doesn't exist
        let wordlistsPath = createWordlistsDirectory()
        let userlistPath = "\(wordlistsPath)/common_users.txt"
        let passwordlistPath = "\(wordlistsPath)/common_passwords.txt"
        
        // Create common wordlists
        await createCommonWordlists(userlistPath: userlistPath, passwordlistPath: passwordlistPath)
        
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        process.launchPath = "/usr/local/bin/hydra"
        process.arguments = [
            "-L", userlistPath,
            "-P", passwordlistPath,
            "-t", "4",
            "-f",
            "ssh://\(target):\(port)"
        ]
        
        do {
            try process.run()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let result = String(data: data, encoding: .utf8) ?? ""
            
            process.waitUntilExit()
            
            // Parse Hydra output
            let lines = result.components(separatedBy: .newlines)
            for line in lines {
                output.append(line)
                
                // Look for successful login patterns
                if line.contains("login:") && line.contains("password:") {
                    let components = line.components(separatedBy: " ")
                    if let loginIndex = components.firstIndex(of: "login:"),
                       let passwordIndex = components.firstIndex(of: "password:"),
                       loginIndex + 1 < components.count,
                       passwordIndex + 1 < components.count {
                        
                        let username = components[loginIndex + 1]
                        let password = components[passwordIndex + 1]
                        
                        let credential = Credential(
                            username: username,
                            password: password,
                            service: "SSH",
                            port: port
                        )
                        credentials.append(credential)
                    }
                }
            }
            
        } catch {
            output.append("Error executing Hydra: \(error.localizedDescription)")
        }
        
        return (output, credentials)
    }
    
    private func executeDirb(target: String, port: Int, session: AttackSession) async -> (output: [String], files: [String]) {
        var output: [String] = []
        var files: [String] = []
        
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        process.launchPath = "/usr/local/bin/dirb"
        process.arguments = [
            "http://\(target):\(port)/",
            "-w"  // Don't show warnings
        ]
        
        do {
            try process.run()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let result = String(data: data, encoding: .utf8) ?? ""
            
            process.waitUntilExit()
            
            // Parse Dirb output
            let lines = result.components(separatedBy: .newlines)
            for line in lines {
                output.append(line)
                
                // Look for discovered directories/files
                if line.contains("==> DIRECTORY:") {
                    let directory = line.replacingOccurrences(of: "==> DIRECTORY: ", with: "")
                    files.append(directory)
                } else if line.contains("+ http://") && line.contains("(CODE:200") {
                    if let url = line.components(separatedBy: " ").first {
                        let path = url.replacingOccurrences(of: "http://\(target):\(port)", with: "")
                        files.append(path)
                    }
                }
            }
            
        } catch {
            output.append("Error executing Dirb: \(error.localizedDescription)")
        }
        
        return (output, files)
    }
    
    private func executeGobuster(target: String, port: Int, session: AttackSession) async -> (output: [String], files: [String]) {
        var output: [String] = []
        var files: [String] = []
        
        let wordlistsPath = createWordlistsDirectory()
        let webWordlistPath = "\(wordlistsPath)/web_common.txt"
        
        // Create web directory wordlist
        await createWebWordlist(path: webWordlistPath)
        
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        process.launchPath = "/usr/local/bin/gobuster"
        process.arguments = [
            "dir",
            "-u", "http://\(target):\(port)",
            "-w", webWordlistPath,
            "-t", "20",
            "-q"  // Quiet mode
        ]
        
        do {
            try process.run()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let result = String(data: data, encoding: .utf8) ?? ""
            
            process.waitUntilExit()
            
            // Parse Gobuster output
            let lines = result.components(separatedBy: .newlines)
            for line in lines {
                output.append(line)
                
                // Look for discovered paths
                if line.contains("(Status: 200)") || line.contains("(Status: 301)") || line.contains("(Status: 302)") {
                    if let path = line.components(separatedBy: " ").first {
                        files.append(path)
                    }
                }
            }
            
        } catch {
            output.append("Error executing Gobuster: \(error.localizedDescription)")
        }
        
        return (output, files)
    }
    
    private func executeNmap(target: String, session: AttackSession) async -> (output: [String], services: [String]) {
        var output: [String] = []
        var services: [String] = []
        
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        process.launchPath = "/usr/local/bin/nmap"
        process.arguments = [
            "-sV",  // Service version detection
            "-O",   // OS detection
            "-A",   // Aggressive scan
            target
        ]
        
        do {
            try process.run()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let result = String(data: data, encoding: .utf8) ?? ""
            
            process.waitUntilExit()
            
            // Parse Nmap output
            let lines = result.components(separatedBy: .newlines)
            for line in lines {
                output.append(line)
                
                // Extract service information
                if line.contains("/tcp") && line.contains("open") {
                    services.append(line.trimmingCharacters(in: .whitespaces))
                }
                
                // Extract OS information
                if line.contains("OS details:") {
                    services.append(line.trimmingCharacters(in: .whitespaces))
                }
            }
            
        } catch {
            output.append("Error executing Nmap: \(error.localizedDescription)")
        }
        
        return (output, services)
    }
    
    private func executeSQLMap(target: String, port: Int, session: AttackSession) async -> (output: [String], vulnerabilities: [VulnerabilityFinding]) {
        var output: [String] = []
        var vulnerabilities: [VulnerabilityFinding] = []
        
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        process.launchPath = "/usr/local/bin/sqlmap"
        process.arguments = [
            "-u", "http://\(target):\(port)/?id=1",
            "--batch",  // Non-interactive mode
            "--level=1",
            "--risk=1"
        ]
        
        do {
            try process.run()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let result = String(data: data, encoding: .utf8) ?? ""
            
            process.waitUntilExit()
            
            // Parse SQLMap output
            let lines = result.components(separatedBy: .newlines)
            for line in lines {
                output.append(line)
                
                // Look for SQL injection vulnerabilities
                if line.contains("Parameter:") && line.contains("is vulnerable") {
                    let vulnerability = VulnerabilityFinding(
                        type: "SQL Injection",
                        severity: "critical",
                        description: "SQL injection vulnerability detected",
                        proof: line,
                        recommendation: "Use parameterized queries and input validation"
                    )
                    vulnerabilities.append(vulnerability)
                }
            }
            
        } catch {
            output.append("Error executing SQLMap: \(error.localizedDescription)")
        }
        
        return (output, vulnerabilities)
    }
    
    private func executeNikto(target: String, port: Int, session: AttackSession) async -> (output: [String], vulnerabilities: [VulnerabilityFinding]) {
        var output: [String] = []
        var vulnerabilities: [VulnerabilityFinding] = []
        
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        process.launchPath = "/usr/local/bin/nikto"
        process.arguments = [
            "-h", "\(target):\(port)",
            "-Format", "txt"
        ]
        
        do {
            try process.run()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let result = String(data: data, encoding: .utf8) ?? ""
            
            process.waitUntilExit()
            
            // Parse Nikto output
            let lines = result.components(separatedBy: .newlines)
            for line in lines {
                output.append(line)
                
                // Look for vulnerabilities in Nikto output
                if line.contains("OSVDB-") || line.contains("CVE-") {
                    let vulnerability = VulnerabilityFinding(
                        type: "Web Vulnerability",
                        severity: determineSeverityFromNikto(line),
                        description: line,
                        proof: line,
                        recommendation: "Review and patch the identified vulnerability"
                    )
                    vulnerabilities.append(vulnerability)
                }
            }
            
        } catch {
            output.append("Error executing Nikto: \(error.localizedDescription)")
        }
        
        return (output, vulnerabilities)
    }
    
    // MARK: - Utility Methods
    
    private func createWordlistsDirectory() -> String {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let wordlistsPath = "\(documentsPath)/DonkTool/wordlists"
        
        try? FileManager.default.createDirectory(atPath: wordlistsPath, withIntermediateDirectories: true, attributes: nil)
        
        return wordlistsPath
    }
    
    private func createCommonWordlists(userlistPath: String, passwordlistPath: String) async {
        let commonUsers = [
            "admin", "administrator", "root", "user", "test", "guest",
            "oracle", "postgres", "mysql", "ftp", "mail", "www",
            "daemon", "nobody", "bin", "sys", "sync", "games"
        ]
        
        let commonPasswords = [
            "password", "123456", "password123", "admin", "root",
            "toor", "pass", "test", "guest", "qwerty", "12345",
            "letmein", "welcome", "monkey", "dragon", "master",
            "login", "abc123", "password1", "1234567890"
        ]
        
        let userlist = commonUsers.joined(separator: "\n")
        let passwordlist = commonPasswords.joined(separator: "\n")
        
        try? userlist.write(toFile: userlistPath, atomically: true, encoding: .utf8)
        try? passwordlist.write(toFile: passwordlistPath, atomically: true, encoding: .utf8)
    }
    
    private func createWebWordlist(path: String) async {
        let webPaths = [
            "admin", "administrator", "login", "wp-admin", "phpmyadmin",
            "backup", "backups", "config", "database", "db", "sql",
            "uploads", "images", "css", "js", "api", "v1", "v2",
            "test", "dev", "staging", "robots.txt", "sitemap.xml",
            ".htaccess", "web.config", "phpinfo.php", "info.php",
            "index.php", "index.html", "default.php", "default.html"
        ]
        
        let wordlist = webPaths.joined(separator: "\n")
        try? wordlist.write(toFile: path, atomically: true, encoding: .utf8)
    }
    
    private func determineSeverityFromNikto(_ line: String) -> String {
        if line.lowercased().contains("critical") || line.contains("CVE-") {
            return "critical"
        } else if line.lowercased().contains("high") || line.contains("OSVDB-") {
            return "high"
        } else if line.lowercased().contains("medium") {
            return "medium"
        } else {
            return "low"
        }
    }
    
    private func checkIfToolInstalled(_ tool: AttackTool) -> Bool {
        let paths = ["/usr/local/bin/", "/opt/homebrew/bin/", "/usr/bin/"]
        
        for path in paths {
            let fullPath = path + tool.commandName
            if FileManager.default.fileExists(atPath: fullPath) {
                return true
            }
        }
        
        return false
    }
    
    private func performToolInstallation(_ tool: AttackTool) async -> Bool {
        let process = Process()
        
        // Try Homebrew first
        if FileManager.default.fileExists(atPath: "/opt/homebrew/bin/brew") {
            process.launchPath = "/opt/homebrew/bin/brew"
        } else if FileManager.default.fileExists(atPath: "/usr/local/bin/brew") {
            process.launchPath = "/usr/local/bin/brew"
        } else {
            return false
        }
        
        process.arguments = ["install", tool.brewPackage]
        
        return await withCheckedContinuation { continuation in
            process.terminationHandler = { _ in
                continuation.resume(returning: process.terminationStatus == 0)
            }
            
            do {
                try process.run()
            } catch {
                continuation.resume(returning: false)
            }
        }
    }
}

// MARK: - Supporting Data Structures

enum AttackTool: String, CaseIterable {
    case hydra = "Hydra"
    case nmap = "Nmap"
    case dirb = "Dirb"
    case gobuster = "Gobuster"
    case sqlmap = "SQLMap"
    case nikto = "Nikto"
    case metasploit = "Metasploit"
    case burpsuite = "Burp Suite"
    
    var commandName: String {
        switch self {
        case .hydra: return "hydra"
        case .nmap: return "nmap"
        case .dirb: return "dirb"
        case .gobuster: return "gobuster"
        case .sqlmap: return "sqlmap"
        case .nikto: return "nikto"
        case .metasploit: return "msfconsole"
        case .burpsuite: return "burpsuite"
        }
    }
    
    var brewPackage: String {
        switch self {
        case .hydra: return "hydra"
        case .nmap: return "nmap"
        case .dirb: return "dirb"
        case .gobuster: return "gobuster"
        case .sqlmap: return "sqlmap"
        case .nikto: return "nikto"
        case .metasploit: return "metasploit"
        case .burpsuite: return "burp-suite"
        }
    }
    
    var description: String {
        switch self {
        case .hydra: return "Network login cracker"
        case .nmap: return "Network discovery and security auditing"
        case .dirb: return "Web content scanner"
        case .gobuster: return "Directory/file enumeration tool"
        case .sqlmap: return "Automatic SQL injection exploitation"
        case .nikto: return "Web server scanner"
        case .metasploit: return "Penetration testing framework"
        case .burpsuite: return "Web application security testing"
        }
    }
}

@Observable
class AttackSession {
    let id: String
    let attack: AttackVector
    let target: String
    let port: Int
    let startTime: Date
    var isCancelled = false
    
    init(id: String, attack: AttackVector, target: String, port: Int, startTime: Date) {
        self.id = id
        self.attack = attack
        self.target = target
        self.port = port
        self.startTime = startTime
    }
    
    func cancel() {
        isCancelled = true
    }
}

struct AttackResult: Identifiable {
    let id = UUID()
    let sessionId: String
    let attack: AttackVector
    let target: String
    let port: Int
    let startTime: Date
    let endTime: Date
    let success: Bool
    let output: [String]
    let credentials: [Credential]
    let vulnerabilities: [VulnerabilityFinding]
    let files: [String]
    
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
}

struct Credential: Identifiable {
    let id = UUID()
    let username: String
    let password: String
    let service: String
    let port: Int
}

struct VulnerabilityFinding: Identifiable {
    let id = UUID()
    let type: String
    let severity: String
    let description: String
    let proof: String
    let recommendation: String
}

struct WebVulnResult {
    let isVulnerable: Bool
    let severity: String
    let description: String
    let proof: String
}
