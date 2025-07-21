//
//  AttackFramework.swift
//  DonkTool
//
//  Integrated attack execution framework
//

import Foundation
import SwiftUI
import Combine

// MARK: - Attack Execution Framework

@Observable
class AttackFramework {
    var activeAttacks: [String: AttackSession] = [:]
    var attackHistory: [AttackResult] = []
    var isExecutingAttack = false
    
    // Tool availability status
    var toolsStatus: [AttackTool: ToolStatus] = [:]
    
    // Computed property for UI access
    var activeSessions: [AttackSession] {
        Array(activeAttacks.values).sorted { $0.startTime > $1.startTime }
    }
    
    // Get only running sessions
    var runningSessions: [AttackSession] {
        activeAttacks.values.filter { $0.status == .running }.sorted { $0.startTime > $1.startTime }
    }
    
    // Get completed sessions
    var completedSessions: [AttackSession] {
        activeAttacks.values.filter { $0.status == .completed || $0.status == .failed || $0.status == .stopped }.sorted { $0.startTime > $1.startTime }
    }
    
    // Reference to tool detection
    private let toolDetection = ToolDetection.shared
    
    // Real-time output callback
    private var realTimeOutputCallback: ((String) -> Void)?
    
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
    
    func setRealTimeOutputCallback(_ callback: @escaping (String) -> Void) {
        realTimeOutputCallback = callback
    }
    
    private func sendRealTimeOutput(_ message: String, sessionId: String? = nil) {
        print("🔄 Sending real-time output: \(message)")
        realTimeOutputCallback?(message)
        print("🔄 Callback called: \(realTimeOutputCallback != nil)")
        
        // Also update the session's output if sessionId is provided
        if let sessionId = sessionId, let session = activeAttacks[sessionId] {
            session.addOutput(message)
        }
    }
    
    func executeAttack(_ attack: AttackVector, target: String, port: Int) async -> AttackResult {
        print("🚀 ATTACK EXECUTION STARTED")
        print("🎯 Attack: \(attack.name)")
        print("🎯 Target: \(target):\(port)")
        print("🎯 Type: \(attack.attackType)")
        
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
        
        sendRealTimeOutput("=== DonkTool Attack Execution ===", sessionId: sessionId)
        sendRealTimeOutput("Attack: \(attack.name)", sessionId: sessionId)
        sendRealTimeOutput("Target: \(target):\(port)", sessionId: sessionId)
        sendRealTimeOutput("Type: \(attack.attackType.rawValue)", sessionId: sessionId)
        sendRealTimeOutput("Required Tools: \(attack.requirements.map { $0.name }.joined(separator: ", "))", sessionId: sessionId)
        sendRealTimeOutput("", sessionId: sessionId)
        
        // Substitute TARGET and PORT placeholders in commands
        let substitutedCommands = attack.commands.map { command in
            command
                .replacingOccurrences(of: "TARGET", with: target)
                .replacingOccurrences(of: "PORT", with: "\(port)")
        }
        
        sendRealTimeOutput("Commands to execute:", sessionId: sessionId)
        for command in substitutedCommands {
            sendRealTimeOutput("$ \(command)", sessionId: sessionId)
        }
        sendRealTimeOutput("", sessionId: sessionId)
        
        print("🔄 Executing attack type: \(attack.attackType)")
        
        let result: AttackResult
        
        switch attack.attackType {
        case .bruteForce:
            print("🔨 Executing brute force attack...")
            result = await executeBruteForceAttack(session)
        case .webDirectoryEnum:
            print("🌐 Executing directory enumeration...")
            result = await executeDirectoryEnumeration(session)
        case .vulnerabilityExploit:
            print("💥 Executing vulnerability exploit...")
            result = await executeVulnerabilityExploit(session)
        case .networkRecon:
            print("🔍 Executing network reconnaissance...")
            result = await executeNetworkReconnaissance(session)
        case .webVulnScan:
            print("🕷️ Executing web vulnerability scan...")
            result = await executeWebVulnerabilityScanning(session)
        }
        
        print("✅ Attack execution completed")
        print("📊 Success: \(result.success)")
        print("📝 Output lines: \(result.output.count)")
        
        // Update session status
        if let session = activeAttacks[sessionId] {
            if result.success {
                session.markCompleted()
                // Add findings from the result
                for finding in result.vulnerabilities {
                    session.addFinding(finding.description)
                }
                for credential in result.credentials {
                    session.addFinding("Found credential: \(credential.username):\(credential.password)")
                }
            } else {
                session.markFailed()
            }
        }
        
        // Generate evidence package automatically
        sendRealTimeOutput("", sessionId: sessionId)
        sendRealTimeOutput("=== Generating Evidence Package ===", sessionId: sessionId)
        
        Task {
            if let evidencePackage = await EvidenceManager.shared.generateEvidencePackage(from: result) {
                await MainActor.run {
                    self.sendRealTimeOutput("📁 Evidence package generated: \(evidencePackage.packageName)", sessionId: sessionId)
                    self.sendRealTimeOutput("📍 Location: \(evidencePackage.evidenceFiles.first?.filepath ?? "Unknown")", sessionId: sessionId)
                    self.sendRealTimeOutput("📊 Files created: \(evidencePackage.evidenceFiles.count)", sessionId: sessionId)
                }
            } else {
                await MainActor.run {
                    self.sendRealTimeOutput("⚠️ Failed to generate evidence package", sessionId: sessionId)
                }
            }
        }
        
        await MainActor.run {
            // Keep completed sessions for a while (don't remove immediately)
            // activeAttacks.removeValue(forKey: sessionId)
            attackHistory.append(result)
            
            // Update isExecutingAttack based on whether there are any running attacks
            isExecutingAttack = activeAttacks.values.contains { $0.status == .running }
        }
        
        return result
    }
    
    func stopAttack(_ sessionId: String) {
        if let session = activeAttacks[sessionId] {
            session.cancel()
            // Update isExecutingAttack after stopping
            isExecutingAttack = activeAttacks.values.contains { $0.status == .running }
        }
    }
    
    func cleanupCompletedSessions() {
        let currentTime = Date()
        let sessionTimeout: TimeInterval = 300 // Keep sessions for 5 minutes after completion
        
        let sessionsToRemove = activeAttacks.filter { (sessionId, session) in
            if session.status == .completed || session.status == .failed || session.status == .stopped {
                return currentTime.timeIntervalSince(session.startTime) > sessionTimeout
            }
            return false
        }
        
        for (sessionId, _) in sessionsToRemove {
            activeAttacks.removeValue(forKey: sessionId)
        }
        
        // Update execution state after cleanup
        isExecutingAttack = activeAttacks.values.contains { $0.status == .running }
    }
    
    func installTool(_ tool: AttackTool) async {
        await MainActor.run {
            toolsStatus[tool] = .installing
        }
        
        let success = await toolDetection.installTool(tool.commandName)
        
        await MainActor.run {
            toolsStatus[tool] = success ? .available : .failed
        }
    }
    
    func checkToolAvailability() async {
        await toolDetection.refreshToolStatus()
        
        for tool in AttackTool.allCases {
            let isInstalled = toolDetection.isToolInstalled(tool.commandName)
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
            sessionId: session.sessionId,
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
        var scanSuccess = false
        
        output.append("Starting directory enumeration...")
        output.append("Target: http://\(session.target):\(session.port)")
        
        sendRealTimeOutput("=== Directory Enumeration Started ===", sessionId: session.sessionId)
        sendRealTimeOutput("Target: http://\(session.target):\(session.port)", sessionId: session.sessionId)
        sendRealTimeOutput("", sessionId: session.sessionId)
        
        // Try Gobuster first if available, fallback to Dirb
        if toolDetection.isToolInstalled("gobuster") {
            sendRealTimeOutput("Using Gobuster for directory enumeration...", sessionId: session.sessionId)
            let result = await executeGobuster(
                target: session.target,
                port: session.port,
                session: session
            )
            output.append(contentsOf: result.output)
            discoveredFiles.append(contentsOf: result.files)
            scanSuccess = result.success
        } else {
            sendRealTimeOutput("Using Dirb for directory enumeration...", sessionId: session.sessionId)
            let result = await executeDirb(
                target: session.target,
                port: session.port,
                session: session
            )
            output.append(contentsOf: result.output)
            discoveredFiles.append(contentsOf: result.files)
            scanSuccess = result.success
        }
        
        // Add summary
        let summary = discoveredFiles.isEmpty ? 
            "Scan completed successfully - no directories found" :
            "Scan completed - found \(discoveredFiles.count) directories/files"
            
        output.append("")
        output.append("=== Scan Summary ===")
        output.append(summary)
        
        sendRealTimeOutput("", sessionId: session.sessionId)
        sendRealTimeOutput("=== Scan Summary ===", sessionId: session.sessionId)
        sendRealTimeOutput(summary, sessionId: session.sessionId)
        
        return AttackResult(
            sessionId: session.sessionId,
            attack: session.attack,
            target: session.target,
            port: session.port,
            startTime: startTime,
            endTime: Date(),
            success: scanSuccess,
            output: output,
            credentials: [],
            vulnerabilities: [],
            files: discoveredFiles
        )
    }
    
    private func executeVulnerabilityExploit(_ session: AttackSession) async -> AttackResult {
        print("💥 === VULNERABILITY EXPLOIT STARTED ===")
        
        let startTime = Date()
        var output: [String] = []
        var foundVulnerabilities: [VulnerabilityFinding] = []
        
        output.append("Starting vulnerability exploitation...")
        output.append("Target: \(session.target):\(session.port)")
        
        sendRealTimeOutput("Starting vulnerability exploitation...", sessionId: session.sessionId)
        sendRealTimeOutput("Target: \(session.target):\(session.port)", sessionId: session.sessionId)
        sendRealTimeOutput("", sessionId: session.sessionId)
        
        // Check what tools are required for this specific attack
        let toolNames = session.attack.requirements.map { $0.name.lowercased() }
        
        // Execute SQLMap if it's in the requirements
        if toolNames.contains("sqlmap") {
            print("🔍 Executing SQLMap...")
            sendRealTimeOutput("=== Running SQLMap ===", sessionId: session.sessionId)
            let sqlmapResult = await executeSQLMap(
                target: session.target,
                port: session.port,
                session: session
            )
            
            print("🔍 SQLMap completed")
            sendRealTimeOutput("", sessionId: session.sessionId)
            sendRealTimeOutput("=== SQLMap completed ===", sessionId: session.sessionId)
            sendRealTimeOutput("", sessionId: session.sessionId)
            
            output.append(contentsOf: sqlmapResult.output)
            foundVulnerabilities.append(contentsOf: sqlmapResult.vulnerabilities)
        }
        
        // Execute Nikto if it's in the requirements
        if toolNames.contains("nikto") {
            print("🔍 Executing Nikto...")
            sendRealTimeOutput("=== Running Nikto ===", sessionId: session.sessionId)
            let niktoResult = await executeNikto(
                target: session.target,
                port: session.port,
                session: session
            )
            print("🔍 Nikto completed")
            sendRealTimeOutput("", sessionId: session.sessionId)
            sendRealTimeOutput("=== Nikto completed ===", sessionId: session.sessionId)
            sendRealTimeOutput("", sessionId: session.sessionId)
            
            output.append(contentsOf: niktoResult.output)
            foundVulnerabilities.append(contentsOf: niktoResult.vulnerabilities)
        }
        
        // If no specific tools are defined, run a generic vulnerability scan
        if !toolNames.contains("sqlmap") && !toolNames.contains("nikto") {
            sendRealTimeOutput("No specific vulnerability tools defined in requirements", sessionId: session.sessionId)
            sendRealTimeOutput("Running generic vulnerability assessment...", sessionId: session.sessionId)
            
            // Run SQLMap as a fallback for generic vulnerability testing
            let sqlmapResult = await executeSQLMap(
                target: session.target,
                port: session.port,
                session: session
            )
            
            output.append(contentsOf: sqlmapResult.output)
            foundVulnerabilities.append(contentsOf: sqlmapResult.vulnerabilities)
        }
        
        return AttackResult(
            sessionId: session.sessionId,
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
        output.append("Target: \(session.target):\(session.port)")
        
        // Execute the actual commands from the attack vector
        let substitutedCommands = session.attack.commands.map { command in
            command
                .replacingOccurrences(of: "TARGET", with: session.target)
                .replacingOccurrences(of: "PORT", with: "\(session.port)")
        }
        
        for command in substitutedCommands {
            let commandResult = await executeGenericCommand(command: command, session: session)
            output.append(contentsOf: commandResult.output)
            discoveredServices.append(contentsOf: commandResult.findings)
        }
        
        return AttackResult(
            sessionId: session.sessionId,
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
        var discoveredFiles: [String] = []
        
        output.append("Starting comprehensive web vulnerability scan...")
        output.append("Target: http://\(session.target):\(session.port)")
        
        sendRealTimeOutput("=== Comprehensive Web Vulnerability Scan ===", sessionId: session.sessionId)
        sendRealTimeOutput("Target: http://\(session.target):\(session.port)", sessionId: session.sessionId)
        sendRealTimeOutput("", sessionId: session.sessionId)
        
        // 1. HTTPx for service fingerprinting
        sendRealTimeOutput("Phase 1: Service fingerprinting with HTTPx", sessionId: session.sessionId)
        let httpxResult = await executeHTTPx(
            target: session.target,
            port: session.port,
            session: session
        )
        output.append(contentsOf: httpxResult.output)
        sendRealTimeOutput("", sessionId: session.sessionId)
        
        // 2. Nuclei for vulnerability detection (9000+ templates)
        sendRealTimeOutput("Phase 2: Nuclei vulnerability scanning", sessionId: session.sessionId)
        let nucleiResult = await executeNuclei(
            target: session.target,
            port: session.port,
            session: session
        )
        output.append(contentsOf: nucleiResult.output)
        foundVulnerabilities.append(contentsOf: nucleiResult.vulnerabilities)
        sendRealTimeOutput("", sessionId: session.sessionId)
        
        // 3. FFuF for advanced directory enumeration
        sendRealTimeOutput("Phase 3: Advanced directory fuzzing with FFuF", sessionId: session.sessionId)
        let ffufResult = await executeFFuF(
            target: session.target,
            port: session.port,
            session: session
        )
        output.append(contentsOf: ffufResult.output)
        discoveredFiles.append(contentsOf: ffufResult.files)
        sendRealTimeOutput("", sessionId: session.sessionId)
        
        // 4. WordPress scanning if detected
        if httpxResult.output.joined().lowercased().contains("wordpress") {
            sendRealTimeOutput("Phase 4: WordPress vulnerability scanning", sessionId: session.sessionId)
            let wpscanResult = await executeWPScan(
                target: session.target,
                port: session.port,
                session: session
            )
            output.append(contentsOf: wpscanResult.output)
            foundVulnerabilities.append(contentsOf: wpscanResult.vulnerabilities)
            sendRealTimeOutput("", sessionId: session.sessionId)
        }
        
        // 5. SSL/TLS scanning for HTTPS services
        if session.port == 443 || session.port == 8443 {
            sendRealTimeOutput("Phase 5: SSL/TLS security analysis", sessionId: session.sessionId)
            let sslscanResult = await executeSSLScan(
                target: session.target,
                port: session.port,
                session: session
            )
            output.append(contentsOf: sslscanResult.output)
            foundVulnerabilities.append(contentsOf: sslscanResult.vulnerabilities)
            sendRealTimeOutput("", sessionId: session.sessionId)
        }
        
        // 6. Legacy Nikto scan for additional coverage
        sendRealTimeOutput("Phase 6: Legacy Nikto scan for additional coverage", sessionId: session.sessionId)
        let niktoResult = await executeNikto(
            target: session.target,
            port: session.port,
            session: session
        )
        output.append(contentsOf: niktoResult.output)
        foundVulnerabilities.append(contentsOf: niktoResult.vulnerabilities)
        sendRealTimeOutput("", sessionId: session.sessionId)
        
        // 7. Fallback Gobuster if FFuF failed
        if discoveredFiles.isEmpty {
            sendRealTimeOutput("Phase 7: Fallback directory enumeration with Gobuster", sessionId: session.sessionId)
            let gobusterResult = await executeGobuster(
                target: session.target,
                port: session.port,
                session: session
            )
            output.append(contentsOf: gobusterResult.output)
            discoveredFiles.append(contentsOf: gobusterResult.files)
        }
        
        // Summary
        let summary = [
            "",
            "=== SCAN COMPLETED ===",
            "Total vulnerabilities found: \(foundVulnerabilities.count)",
            "Directories/files discovered: \(discoveredFiles.count)",
            "High/Critical vulnerabilities: \(foundVulnerabilities.filter { $0.severity == "high" || $0.severity == "critical" }.count)"
        ]
        
        output.append(contentsOf: summary)
        for line in summary {
            sendRealTimeOutput(line, sessionId: session.sessionId)
        }
        
        return AttackResult(
            sessionId: session.sessionId,
            attack: session.attack,
            target: session.target,
            port: session.port,
            startTime: startTime,
            endTime: Date(),
            success: !foundVulnerabilities.isEmpty || !discoveredFiles.isEmpty,
            output: output,
            credentials: [],
            vulnerabilities: foundVulnerabilities,
            files: discoveredFiles
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
        guard let hydraPath = toolDetection.getToolPath("hydra") else {
            output.append("Error: Hydra not found in system PATH")
            return (output, credentials)
        }
        process.executableURL = URL(fileURLWithPath: hydraPath)
        process.arguments = [
            "-L", userlistPath,
            "-P", passwordlistPath,
            "-t", "4",
            "-f",
            "ssh://\(target):\(port)"
        ]
        
        let commandLine = "hydra \(process.arguments?.joined(separator: " ") ?? "")"
        sendRealTimeOutput("$ \(commandLine)", sessionId: session.sessionId)
        sendRealTimeOutput("", sessionId: session.sessionId)
        
        do {
            try process.run()
            
            // Read output in real-time using a background task
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    let fileHandle = pipe.fileHandleForReading
                    var buffer = ""
                    
                    while process.isRunning {
                        let availableData = fileHandle.availableData
                        if !availableData.isEmpty {
                            if let newOutput = String(data: availableData, encoding: .utf8) {
                                buffer += newOutput
                                
                                // Process complete lines
                                let lines = buffer.components(separatedBy: .newlines)
                                let completeLines = lines.dropLast() // Last element might be incomplete
                                buffer = String(lines.last ?? "") // Keep incomplete line in buffer
                                
                                for line in completeLines {
                                    await MainActor.run {
                                        self.sendRealTimeOutput(line, sessionId: session.sessionId)
                                    }
                                }
                            }
                        }
                        
                        // Small delay to prevent excessive CPU usage
                        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
                    }
                    
                    // Read any remaining data
                    let remainingData = fileHandle.readDataToEndOfFile()
                    if !remainingData.isEmpty {
                        if let finalOutput = String(data: remainingData, encoding: .utf8) {
                            buffer += finalOutput
                            
                            // Process any remaining lines
                            let finalLines = buffer.components(separatedBy: .newlines)
                            for line in finalLines {
                                if !line.isEmpty {
                                    await MainActor.run {
                                        self.sendRealTimeOutput(line, sessionId: session.sessionId)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            process.waitUntilExit()
            
            let exitMessage = "Process completed with exit code: \(process.terminationStatus)"
            sendRealTimeOutput("", sessionId: session.sessionId)
            sendRealTimeOutput(exitMessage, sessionId: session.sessionId)
            
            // Get final output for parsing (this might be empty since we read it in real-time)
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let result = String(data: data, encoding: .utf8) ?? ""
            
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
    
    private func executeDirb(target: String, port: Int, session: AttackSession) async -> (output: [String], files: [String], success: Bool) {
        var output: [String] = []
        var files: [String] = []
        var scanSuccess = false  // Declare at function level
        
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        guard let dirbPath = toolDetection.getToolPath("dirb") else {
            let errorMsg = "Error: Dirb not found in system PATH"
            output.append(errorMsg)
            sendRealTimeOutput(errorMsg, sessionId: session.sessionId)
            sendRealTimeOutput("Searched paths: /usr/bin, /usr/local/bin, /opt/homebrew/bin", sessionId: session.sessionId)
            sendRealTimeOutput("Try: brew install dirb", sessionId: session.sessionId)
            return (output, files, false)
        }
        
        sendRealTimeOutput("Found Dirb at: \(dirbPath)", sessionId: session.sessionId)
        process.executableURL = URL(fileURLWithPath: dirbPath)
        
        // Construct proper target URL
        let targetURL: String
        if port == 80 {
            targetURL = "http://\(target)/"
        } else if port == 443 {
            targetURL = "https://\(target)/"
        } else {
            targetURL = "http://\(target):\(port)/"
        }
        
        // Create a custom wordlist if default doesn't exist
        let wordlistPath = await createDirbWordlist()
        
        process.arguments = [
            targetURL,
            wordlistPath,
            "-w",  // Don't show warnings
            "-r"   // Don't be recursive (faster for initial scan)
        ]
        
        let commandLine = "dirb \(process.arguments?.joined(separator: " ") ?? "")"
        sendRealTimeOutput("$ \(commandLine)", sessionId: session.sessionId)
        sendRealTimeOutput("Target URL: \(targetURL)", sessionId: session.sessionId)
        sendRealTimeOutput("", sessionId: session.sessionId)
        
        do {
            try process.run()
            
            // Set up a timeout for the scan (5 minutes max)
            let timeoutTask = Task {
                try await Task.sleep(nanoseconds: 300_000_000_000) // 5 minutes
                if process.isRunning {
                    process.terminate()
                    await MainActor.run {
                        self.sendRealTimeOutput("⏰ Directory scan timed out after 5 minutes", sessionId: session.sessionId)
                    }
                }
            }
            
            defer {
                timeoutTask.cancel()
            }
            
            // Read output in real-time using a background task
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    let fileHandle = pipe.fileHandleForReading
                    var buffer = ""
                    
                    while process.isRunning {
                        let availableData = fileHandle.availableData
                        if !availableData.isEmpty {
                            if let newOutput = String(data: availableData, encoding: .utf8) {
                                buffer += newOutput
                                
                                // Process complete lines
                                let lines = buffer.components(separatedBy: .newlines)
                                let completeLines = lines.dropLast() // Last element might be incomplete
                                buffer = String(lines.last ?? "") // Keep incomplete line in buffer
                                
                                for line in completeLines {
                                    await MainActor.run {
                                        self.sendRealTimeOutput(line, sessionId: session.sessionId)
                                    }
                                }
                            }
                        }
                        
                        // Small delay to prevent excessive CPU usage
                        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
                    }
                    
                    // Read any remaining data
                    let remainingData = fileHandle.readDataToEndOfFile()
                    if !remainingData.isEmpty {
                        if let finalOutput = String(data: remainingData, encoding: .utf8) {
                            buffer += finalOutput
                            
                            // Process any remaining lines
                            let finalLines = buffer.components(separatedBy: .newlines)
                            for line in finalLines {
                                if !line.isEmpty {
                                    await MainActor.run {
                                        self.sendRealTimeOutput(line, sessionId: session.sessionId)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            process.waitUntilExit()
            
            let exitCode = process.terminationStatus
            let exitMessage = "Process completed with exit code: \(exitCode)"
            sendRealTimeOutput("", sessionId: session.sessionId)
            sendRealTimeOutput(exitMessage, sessionId: session.sessionId)
            
            // Analyze exit code and provide detailed feedback
            var detailedResult = ""
            
            switch exitCode {
            case 0:
                scanSuccess = true
                detailedResult = "✅ Directory enumeration completed successfully"
            case 255:
                detailedResult = "❌ Tool execution failed - likely wordlist or target issues"
                if !FileManager.default.fileExists(atPath: wordlistPath) {
                    detailedResult += "\n   • Wordlist not found: \(wordlistPath)"
                } else {
                    detailedResult += "\n   • Wordlist found: \(wordlistPath)"
                }
                detailedResult += "\n   • Target may be unreachable: \(targetURL)"
                detailedResult += "\n   • Check network connectivity and target accessibility"
            case 1:
                detailedResult = "⚠️  Target accessible but no directories found"
                scanSuccess = true // Not necessarily a failure
            case 2:
                detailedResult = "❌ Target unreachable or connection failed"
            default:
                detailedResult = "❌ Unexpected error occurred (exit code: \(exitCode))"
            }
            
            output.append(detailedResult)
            sendRealTimeOutput("", sessionId: session.sessionId)
            sendRealTimeOutput("=== SCAN ANALYSIS ===", sessionId: session.sessionId)
            sendRealTimeOutput(detailedResult, sessionId: session.sessionId)
            
            if !scanSuccess {
                let troubleshooting = [
                    "🔧 TROUBLESHOOTING SUGGESTIONS:",
                    "• Verify target is accessible: curl -I \(targetURL)",
                    "• Check wordlist exists: ls -la \(wordlistPath)",
                    "• Test manual scan: dirb \(targetURL) \(wordlistPath) -w"
                ]
                output.append(contentsOf: troubleshooting)
                sendRealTimeOutput("", sessionId: session.sessionId)
                for suggestion in troubleshooting {
                    sendRealTimeOutput(suggestion, sessionId: session.sessionId)
                }
            }
            
            // Get final output for parsing (this might be empty since we read it in real-time)
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let result = String(data: data, encoding: .utf8) ?? ""
            
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
            sendRealTimeOutput("❌ Error executing Dirb: \(error.localizedDescription)", sessionId: session.sessionId)
            return (output, files, false)
        }
        
        // Use the detailed scan success determination from above
        if scanSuccess {
            sendRealTimeOutput("", sessionId: session.sessionId)
            if !files.isEmpty {
                sendRealTimeOutput("📁 Found \(files.count) directories/files:", sessionId: session.sessionId)
                for file in files.prefix(10) { // Show first 10 findings
                    sendRealTimeOutput("  • \(file)", sessionId: session.sessionId)
                }
                if files.count > 10 {
                    sendRealTimeOutput("  ... and \(files.count - 10) more", sessionId: session.sessionId)
                }
            } else {
                sendRealTimeOutput("📁 No directories found (this is normal for secure sites)", sessionId: session.sessionId)
            }
        } else {
            sendRealTimeOutput("", sessionId: session.sessionId)
            sendRealTimeOutput("❌ Dirb scan failed with exit code: \(process.terminationStatus)", sessionId: session.sessionId)
        }
        
        return (output, files, scanSuccess)
    }
    
    private func executeGobuster(target: String, port: Int, session: AttackSession) async -> (output: [String], files: [String], success: Bool) {
        var output: [String] = []
        var files: [String] = []
        var scanSuccess = false  // Declare at function level
        
        // Use the same wordlist as dirb for consistency
        let wordlistPath = await createDirbWordlist()
        
        // Validate wordlist path
        if wordlistPath.isEmpty {
            output.append("❌ Error: No wordlist available for directory enumeration")
            sendRealTimeOutput("❌ Error: No wordlist available for directory enumeration", sessionId: session.sessionId)
            return (output, files, false)
        }
        
        if !FileManager.default.fileExists(atPath: wordlistPath) {
            output.append("❌ Error: Wordlist not found at path: \(wordlistPath)")
            sendRealTimeOutput("❌ Error: Wordlist not found at path: \(wordlistPath)", sessionId: session.sessionId)
            return (output, files, false)
        }
        
        sendRealTimeOutput("📝 Using wordlist: \(wordlistPath)", sessionId: session.sessionId)
        
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        guard let gobusterPath = toolDetection.getToolPath("gobuster") else {
            output.append("Error: Gobuster not found in system PATH")
            sendRealTimeOutput("❌ Gobuster not found in system PATH", sessionId: session.sessionId)
            return (output, files, false)
        }
        process.executableURL = URL(fileURLWithPath: gobusterPath)
        process.arguments = [
            "dir",
            "-u", "http://\(target):\(port)",
            "-w", wordlistPath,
            "-t", "20",
            "-q"  // Quiet mode
        ]
        
        let commandLine = "gobuster \(process.arguments?.joined(separator: " ") ?? "")"
        sendRealTimeOutput("$ \(commandLine)", sessionId: session.sessionId)
        sendRealTimeOutput("", sessionId: session.sessionId)
        
        do {
            try process.run()
            
            // Set up a timeout for the scan (5 minutes max)
            let timeoutTask = Task {
                try await Task.sleep(nanoseconds: 300_000_000_000) // 5 minutes
                if process.isRunning {
                    process.terminate()
                    await MainActor.run {
                        self.sendRealTimeOutput("⏰ Directory scan timed out after 5 minutes", sessionId: session.sessionId)
                    }
                }
            }
            
            defer {
                timeoutTask.cancel()
            }
            
            // Read output in real-time using a background task
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    let fileHandle = pipe.fileHandleForReading
                    var buffer = ""
                    
                    while process.isRunning {
                        let availableData = fileHandle.availableData
                        if !availableData.isEmpty {
                            if let newOutput = String(data: availableData, encoding: .utf8) {
                                buffer += newOutput
                                
                                // Process complete lines
                                let lines = buffer.components(separatedBy: .newlines)
                                let completeLines = lines.dropLast() // Last element might be incomplete
                                buffer = String(lines.last ?? "") // Keep incomplete line in buffer
                                
                                for line in completeLines {
                                    await MainActor.run {
                                        self.sendRealTimeOutput(line, sessionId: session.sessionId)
                                    }
                                }
                            }
                        }
                        
                        // Small delay to prevent excessive CPU usage
                        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
                    }
                    
                    // Read any remaining data
                    let remainingData = fileHandle.readDataToEndOfFile()
                    if !remainingData.isEmpty {
                        if let finalOutput = String(data: remainingData, encoding: .utf8) {
                            buffer += finalOutput
                            
                            // Process any remaining lines
                            let finalLines = buffer.components(separatedBy: .newlines)
                            for line in finalLines {
                                if !line.isEmpty {
                                    await MainActor.run {
                                        self.sendRealTimeOutput(line, sessionId: session.sessionId)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            process.waitUntilExit()
            
            let exitCode = process.terminationStatus
            let exitMessage = "Process completed with exit code: \(exitCode)"
            sendRealTimeOutput("", sessionId: session.sessionId)
            sendRealTimeOutput(exitMessage, sessionId: session.sessionId)
            
            // Analyze exit code and provide detailed feedback
            var detailedResult = ""
            
            switch exitCode {
            case 0:
                scanSuccess = true
                detailedResult = "✅ Directory enumeration completed successfully"
            case 1:
                detailedResult = "❌ Tool execution failed - likely wordlist or target issues"
                if !FileManager.default.fileExists(atPath: wordlistPath) {
                    detailedResult += "\n   • Wordlist not found: \(wordlistPath)"
                } else {
                    detailedResult += "\n   • Wordlist found: \(wordlistPath)"
                }
                detailedResult += "\n   • Target may be unreachable or no results found"
            case 2:
                detailedResult = "❌ Target unreachable or connection failed"
            default:
                detailedResult = "❌ Unexpected error occurred (exit code: \(exitCode))"
            }
            
            output.append(detailedResult)
            sendRealTimeOutput("", sessionId: session.sessionId)
            sendRealTimeOutput("=== SCAN ANALYSIS ===", sessionId: session.sessionId)
            sendRealTimeOutput(detailedResult, sessionId: session.sessionId)
            
            if !scanSuccess {
                let troubleshooting = [
                    "🔧 TROUBLESHOOTING SUGGESTIONS:",
                    "• Verify target is accessible: curl -I http://\(target):\(port)/",
                    "• Check wordlist exists: ls -la \(wordlistPath)",
                    "• Test manual scan: gobuster dir -u http://\(target):\(port) -w \(wordlistPath) -q"
                ]
                output.append(contentsOf: troubleshooting)
                sendRealTimeOutput("", sessionId: session.sessionId)
                for suggestion in troubleshooting {
                    sendRealTimeOutput(suggestion, sessionId: session.sessionId)
                }
            }
            
            // Get final output for parsing (this might be empty since we read it in real-time)
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let result = String(data: data, encoding: .utf8) ?? ""
            
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
            sendRealTimeOutput("❌ Error executing Gobuster: \(error.localizedDescription)", sessionId: session.sessionId)
            return (output, files, false)
        }
        
        // Use the detailed scan success determination from above
        if scanSuccess {
            sendRealTimeOutput("", sessionId: session.sessionId)
            if !files.isEmpty {
                sendRealTimeOutput("📁 Found \(files.count) directories/files:", sessionId: session.sessionId)
                for file in files.prefix(10) { // Show first 10 findings
                    sendRealTimeOutput("  • \(file)", sessionId: session.sessionId)
                }
                if files.count > 10 {
                    sendRealTimeOutput("  ... and \(files.count - 10) more", sessionId: session.sessionId)
                }
            } else {
                sendRealTimeOutput("📁 No directories found (this is normal for secure sites)", sessionId: session.sessionId)
            }
        } else {
            sendRealTimeOutput("", sessionId: session.sessionId)
            sendRealTimeOutput("❌ Gobuster scan failed with exit code: \(process.terminationStatus)", sessionId: session.sessionId)
        }
        
        return (output, files, scanSuccess)
    }
    
    private func executeNmap(target: String, session: AttackSession) async -> (output: [String], services: [String]) {
        var output: [String] = []
        var services: [String] = []
        
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        guard let nmapPath = toolDetection.getToolPath("nmap") else {
            let errorMsg = "Error: Nmap not found in system PATH"
            output.append(errorMsg)
            sendRealTimeOutput(errorMsg, sessionId: session.sessionId)
            return (output, services)
        }
        process.executableURL = URL(fileURLWithPath: nmapPath)
        process.arguments = [
            "-sV",  // Service version detection
            "-sC",  // Script scan (safe scripts only)
            "-T4",  // Timing template (faster)
            "-n",   // No DNS resolution
            target
        ]
        
        let commandLine = "nmap \(process.arguments?.joined(separator: " ") ?? "")"
        print("🔍 Starting nmap execution...")
        sendRealTimeOutput("$ \(commandLine)", sessionId: session.sessionId)
        sendRealTimeOutput("", sessionId: session.sessionId)
        
        do {
            try process.run()
            
            // Read output in real-time using a background task
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    let fileHandle = pipe.fileHandleForReading
                    var buffer = ""
                    
                    while process.isRunning {
                        let availableData = fileHandle.availableData
                        if !availableData.isEmpty {
                            if let newOutput = String(data: availableData, encoding: .utf8) {
                                buffer += newOutput
                                
                                // Process complete lines
                                let lines = buffer.components(separatedBy: .newlines)
                                let completeLines = lines.dropLast() // Last element might be incomplete
                                buffer = String(lines.last ?? "") // Keep incomplete line in buffer
                                
                                for line in completeLines {
                                    await MainActor.run {
                                        self.sendRealTimeOutput(line, sessionId: session.sessionId)
                                    }
                                }
                            }
                        }
                        
                        // Small delay to prevent excessive CPU usage
                        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
                    }
                    
                    // Read any remaining data
                    let remainingData = fileHandle.readDataToEndOfFile()
                    if !remainingData.isEmpty {
                        if let finalOutput = String(data: remainingData, encoding: .utf8) {
                            buffer += finalOutput
                            
                            // Process any remaining lines
                            let finalLines = buffer.components(separatedBy: .newlines)
                            for line in finalLines {
                                if !line.isEmpty {
                                    await MainActor.run {
                                        self.sendRealTimeOutput(line, sessionId: session.sessionId)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            process.waitUntilExit()
            
            let exitMessage = "Process completed with exit code: \(process.terminationStatus)"
            print("🔍 Nmap completed with exit code: \(process.terminationStatus)")
            sendRealTimeOutput("", sessionId: session.sessionId)
            sendRealTimeOutput(exitMessage, sessionId: session.sessionId)
            
            // Get final output for parsing (this might be empty since we read it in real-time)
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let result = String(data: data, encoding: .utf8) ?? ""
            
            // Parse Nmap output for services
            let allLines = result.components(separatedBy: .newlines)
            for line in allLines {
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
            let errorMsg = "Error executing Nmap: \(error.localizedDescription)"
            output.append(errorMsg)
            sendRealTimeOutput(errorMsg, sessionId: session.sessionId)
        }
        
        return (output, services)
    }
    
    private func executeSQLMap(target: String, port: Int, session: AttackSession) async -> (output: [String], vulnerabilities: [VulnerabilityFinding]) {
        print("🔍 === SQLMAP EXECUTION STARTED ===")
        var output: [String] = []
        var vulnerabilities: [VulnerabilityFinding] = []
        
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        // Check if SQLMap is available via different methods
        var sqlmapPath: String?
        var usePython = false
        
        // First try direct command
        sqlmapPath = toolDetection.getToolPath("sqlmap")
        
        // If not found, try Python module approach
        if sqlmapPath == nil {
            // Check if sqlmap is available as Python module
            let pythonProcess = Process()
            pythonProcess.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
            pythonProcess.arguments = ["-m", "sqlmap", "--version"]
            
            let testPipe = Pipe()
            pythonProcess.standardOutput = testPipe
            pythonProcess.standardError = testPipe
            
            do {
                try pythonProcess.run()
                pythonProcess.waitUntilExit()
                if pythonProcess.terminationStatus == 0 {
                    sqlmapPath = "/usr/bin/python3"
                    usePython = true
                    print("✅ SQLMap found as Python module")
                }
            } catch {
                print("❌ Failed to test SQLMap Python module")
            }
        }
        
        guard let finalSqlmapPath = sqlmapPath else {
            let errorMsg = "Error: SQLMap not found. Install with: brew install sqlmap or pip3 install sqlmap"
            print("❌ \(errorMsg)")
            output.append(errorMsg)
            sendRealTimeOutput(errorMsg, sessionId: session.sessionId)
            return (output, vulnerabilities)
        }
        
        print("✅ SQLMap found at: \(finalSqlmapPath)")
        process.executableURL = URL(fileURLWithPath: finalSqlmapPath)
        
        if usePython {
            process.arguments = [
                "-m", "sqlmap",
                "-u", "http://\(target):\(port)/?id=1",
                "--batch",  // Non-interactive mode
                "--level=1",
                "--risk=1",
                "--timeout=30",
                "--retries=1"
            ]
        } else {
            process.arguments = [
                "-u", "http://\(target):\(port)/?id=1",
                "--batch",  // Non-interactive mode
                "--level=1",
                "--risk=1",
                "--timeout=30",
                "--retries=1"
            ]
        }
        
        let commandLine = usePython ? 
            "python3 -m sqlmap \(process.arguments?.dropFirst(2).joined(separator: " ") ?? "")" :
            "sqlmap \(process.arguments?.joined(separator: " ") ?? "")"
        print("🚀 Starting SQLMap with arguments: \(process.arguments ?? [])")
        sendRealTimeOutput("$ \(commandLine)", sessionId: session.sessionId)
        sendRealTimeOutput("", sessionId: session.sessionId)
        
        do {
            // Start the process
            try process.run()
            
            // Read output in real-time using a background task
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    let fileHandle = pipe.fileHandleForReading
                    var buffer = ""
                    
                    while process.isRunning {
                        let availableData = fileHandle.availableData
                        if !availableData.isEmpty {
                            if let newOutput = String(data: availableData, encoding: .utf8) {
                                buffer += newOutput
                                
                                // Process complete lines
                                let lines = buffer.components(separatedBy: .newlines)
                                let completeLines = lines.dropLast() // Last element might be incomplete
                                buffer = String(lines.last ?? "") // Keep incomplete line in buffer
                                
                                for line in completeLines {
                                    await MainActor.run {
                                        self.sendRealTimeOutput(line, sessionId: session.sessionId)
                                    }
                                }
                            }
                        }
                        
                        // Small delay to prevent excessive CPU usage
                        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
                    }
                    
                    // Read any remaining data
                    let remainingData = fileHandle.readDataToEndOfFile()
                    if !remainingData.isEmpty {
                        if let finalOutput = String(data: remainingData, encoding: .utf8) {
                            buffer += finalOutput
                            
                            // Process any remaining lines
                            let finalLines = buffer.components(separatedBy: .newlines)
                            for line in finalLines {
                                if !line.isEmpty {
                                    await MainActor.run {
                                        self.sendRealTimeOutput(line, sessionId: session.sessionId)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Wait for completion
            process.waitUntilExit()
            
            let exitMessage = "Process completed with exit code: \(process.terminationStatus)"
            print("🔍 SQLMap completed with exit code: \(process.terminationStatus)")
            sendRealTimeOutput("", sessionId: session.sessionId)
            sendRealTimeOutput(exitMessage, sessionId: session.sessionId)
            
            // Add helpful error messages based on exit codes
            if process.terminationStatus != 0 {
                switch process.terminationStatus {
                case 127:
                    let helpMsg = "💡 Command not found. Try: brew install sqlmap or pip3 install sqlmap"
                    sendRealTimeOutput(helpMsg, sessionId: session.sessionId)
                    output.append(helpMsg)
                case 1:
                    let helpMsg = "💡 SQLMap error - check target URL and parameters"
                    sendRealTimeOutput(helpMsg, sessionId: session.sessionId)
                    output.append(helpMsg)
                case 2:
                    let helpMsg = "💡 SQLMap usage error - invalid parameters"
                    sendRealTimeOutput(helpMsg, sessionId: session.sessionId)
                    output.append(helpMsg)
                default:
                    let helpMsg = "💡 SQLMap terminated unexpectedly. Check logs for details."
                    sendRealTimeOutput(helpMsg, sessionId: session.sessionId)
                    output.append(helpMsg)
                }
            }
            
            // Get final output for parsing (this might be empty since we read it in real-time)
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let result = String(data: data, encoding: .utf8) ?? ""
            
            // Parse SQLMap output for vulnerabilities
            let allLines = result.components(separatedBy: .newlines)
            for line in allLines {
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
            let errorMsg = "Error executing SQLMap: \(error.localizedDescription)"
            output.append(errorMsg)
            sendRealTimeOutput(errorMsg, sessionId: session.sessionId)
            
            // Add installation guidance
            let installMsg = "💡 Installation help: brew install sqlmap or pip3 install sqlmap"
            sendRealTimeOutput(installMsg, sessionId: session.sessionId)
            output.append(installMsg)
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
        
        // Check if Nikto is available via different methods
        var niktoPath: String?
        var usePerl = false
        
        // First try direct command
        niktoPath = toolDetection.getToolPath("nikto")
        
        // If not found, try Perl script approach
        if niktoPath == nil {
            // Try common Nikto installation paths
            let niktoScriptPaths = [
                "/usr/local/bin/nikto.pl",
                "/opt/homebrew/bin/nikto.pl", 
                "/usr/bin/nikto.pl"
            ]
            
            for scriptPath in niktoScriptPaths {
                if FileManager.default.fileExists(atPath: scriptPath) {
                    niktoPath = "/usr/bin/perl"
                    usePerl = true
                    break
                }
            }
        }
        
        guard let finalNiktoPath = niktoPath else {
            let errorMsg = "Error: Nikto not found. Install with: brew install nikto"
            output.append(errorMsg)
            sendRealTimeOutput(errorMsg, sessionId: session.sessionId)
            sendRealTimeOutput("Searched paths: /usr/bin, /usr/local/bin, /opt/homebrew/bin", sessionId: session.sessionId)
            sendRealTimeOutput("Try: brew install nikto", sessionId: session.sessionId)
            return (output, vulnerabilities)
        }
        
        sendRealTimeOutput("Found Nikto at: \(finalNiktoPath)", sessionId: session.sessionId)
        process.executableURL = URL(fileURLWithPath: finalNiktoPath)
        
        // Construct proper target URL
        let targetURL: String
        if port == 80 {
            targetURL = "http://\(target)"
        } else if port == 443 {
            targetURL = "https://\(target)"
        } else {
            targetURL = "http://\(target):\(port)"
        }
        
        process.arguments = [
            "-h", targetURL,
            "-C", "all",  // Check all vulnerabilities
            "-nointeractive",  // Don't prompt for user input
            "-timeout", "30"  // 30 second timeout per request
        ]
        
        let commandLine = "nikto \(process.arguments?.joined(separator: " ") ?? "")"
        sendRealTimeOutput("$ \(commandLine)", sessionId: session.sessionId)
        sendRealTimeOutput("Target URL: \(targetURL)", sessionId: session.sessionId)
        
        // Basic connectivity check
        sendRealTimeOutput("Checking connectivity to target...", sessionId: session.sessionId)
        let isReachable = await checkTargetConnectivity(targetURL)
        if isReachable {
            sendRealTimeOutput("✓ Target is reachable", sessionId: session.sessionId)
        } else {
            sendRealTimeOutput("⚠ Warning: Target may not be reachable", sessionId: session.sessionId)
        }
        sendRealTimeOutput("", sessionId: session.sessionId)
        
        do {
            sendRealTimeOutput("Starting Nikto process...", sessionId: session.sessionId)
            try process.run()
            sendRealTimeOutput("Nikto process started successfully", sessionId: session.sessionId)
            
            // Read output in real-time using a background task
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    let fileHandle = pipe.fileHandleForReading
                    var buffer = ""
                    
                    while process.isRunning {
                        let availableData = fileHandle.availableData
                        if !availableData.isEmpty {
                            if let newOutput = String(data: availableData, encoding: .utf8) {
                                buffer += newOutput
                                
                                // Process complete lines
                                let lines = buffer.components(separatedBy: .newlines)
                                let completeLines = lines.dropLast() // Last element might be incomplete
                                buffer = String(lines.last ?? "") // Keep incomplete line in buffer
                                
                                for line in completeLines {
                                    await MainActor.run {
                                        self.sendRealTimeOutput(line, sessionId: session.sessionId)
                                    }
                                }
                            }
                        }
                        
                        // Small delay to prevent excessive CPU usage
                        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
                    }
                    
                    // Read any remaining data
                    let remainingData = fileHandle.readDataToEndOfFile()
                    if !remainingData.isEmpty {
                        if let finalOutput = String(data: remainingData, encoding: .utf8) {
                            buffer += finalOutput
                            
                            // Process any remaining lines
                            let finalLines = buffer.components(separatedBy: .newlines)
                            for line in finalLines {
                                if !line.isEmpty {
                                    await MainActor.run {
                                        self.sendRealTimeOutput(line, sessionId: session.sessionId)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            process.waitUntilExit()
            
            let exitMessage = "Process completed with exit code: \(process.terminationStatus)"
            sendRealTimeOutput("", sessionId: session.sessionId)
            sendRealTimeOutput(exitMessage, sessionId: session.sessionId)
            
            // Get final output for parsing (this might be empty since we read it in real-time)
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let result = String(data: data, encoding: .utf8) ?? ""
            
            // Parse Nikto output for vulnerabilities
            let allLines = result.components(separatedBy: .newlines)
            for line in allLines {
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
            let errorMsg = "Error executing Nikto: \(error.localizedDescription)"
            output.append(errorMsg)
            sendRealTimeOutput(errorMsg, sessionId: session.sessionId)
        }
        
        return (output, vulnerabilities)
    }
    
    // MARK: - Advanced Tool Implementations
    
    private func executeNuclei(target: String, port: Int, session: AttackSession) async -> (output: [String], vulnerabilities: [VulnerabilityFinding]) {
        var output: [String] = []
        var vulnerabilities: [VulnerabilityFinding] = []
        
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        guard let nucleiPath = toolDetection.getToolPath("nuclei") else {
            let errorMsg = "Error: Nuclei not found in system PATH"
            output.append(errorMsg)
            sendRealTimeOutput(errorMsg, sessionId: session.sessionId)
            return (output, vulnerabilities)
        }
        
        process.executableURL = URL(fileURLWithPath: nucleiPath)
        
        let targetURL = "http://\(target):\(port)"
        process.arguments = [
            "-u", targetURL,
            "-silent",
            "-json",
            "-severity", "critical,high,medium"
        ]
        
        let commandLine = "nuclei \(process.arguments?.joined(separator: " ") ?? "")"
        sendRealTimeOutput("$ \(commandLine)", sessionId: session.sessionId)
        sendRealTimeOutput("", sessionId: session.sessionId)
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let result = String(data: data, encoding: .utf8) ?? ""
            
            let lines = result.components(separatedBy: .newlines)
            for line in lines {
                output.append(line)
                sendRealTimeOutput(line, sessionId: session.sessionId)
                
                // Parse JSON output for vulnerabilities
                if line.contains("{") && line.contains("template-id") {
                    if let jsonData = line.data(using: .utf8),
                       let nucleiResult = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                        
                        let templateId = nucleiResult["template-id"] as? String ?? "Unknown"
                        let info = nucleiResult["info"] as? [String: Any]
                        let severity = info?["severity"] as? String ?? "low"
                        let name = info?["name"] as? String ?? "Nuclei Detection"
                        
                        let vulnerability = VulnerabilityFinding(
                            type: "Nuclei Template: \(templateId)",
                            severity: severity,
                            description: name,
                            proof: line,
                            recommendation: "Review and patch the identified vulnerability"
                        )
                        vulnerabilities.append(vulnerability)
                    }
                }
            }
            
        } catch {
            let errorMsg = "Error executing Nuclei: \(error.localizedDescription)"
            output.append(errorMsg)
            sendRealTimeOutput(errorMsg, sessionId: session.sessionId)
        }
        
        return (output, vulnerabilities)
    }
    
    private func executeHTTPx(target: String, port: Int, session: AttackSession) async -> (output: [String], services: [String]) {
        var output: [String] = []
        var services: [String] = []
        
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        guard let httpxPath = toolDetection.getToolPath("httpx") else {
            let errorMsg = "Error: HTTPx not found in system PATH"
            output.append(errorMsg)
            sendRealTimeOutput(errorMsg, sessionId: session.sessionId)
            return (output, services)
        }
        
        process.executableURL = URL(fileURLWithPath: httpxPath)
        
        let targetURL = "\(target):\(port)"
        process.arguments = [
            "-u", targetURL,
            "-title",
            "-tech-detect",
            "-status-code",
            "-content-length",
            "-silent"
        ]
        
        let commandLine = "httpx \(process.arguments?.joined(separator: " ") ?? "")"
        sendRealTimeOutput("$ \(commandLine)", sessionId: session.sessionId)
        sendRealTimeOutput("", sessionId: session.sessionId)
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let result = String(data: data, encoding: .utf8) ?? ""
            
            let lines = result.components(separatedBy: .newlines)
            for line in lines {
                if !line.isEmpty {
                    output.append(line)
                    services.append(line)
                    sendRealTimeOutput(line, sessionId: session.sessionId)
                }
            }
            
        } catch {
            let errorMsg = "Error executing HTTPx: \(error.localizedDescription)"
            output.append(errorMsg)
            sendRealTimeOutput(errorMsg, sessionId: session.sessionId)
        }
        
        return (output, services)
    }
    
    private func executeWPScan(target: String, port: Int, session: AttackSession) async -> (output: [String], vulnerabilities: [VulnerabilityFinding]) {
        var output: [String] = []
        var vulnerabilities: [VulnerabilityFinding] = []
        
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        guard let wpscanPath = toolDetection.getToolPath("wpscan") else {
            let errorMsg = "Error: WPScan not found in system PATH"
            output.append(errorMsg)
            sendRealTimeOutput(errorMsg, sessionId: session.sessionId)
            return (output, vulnerabilities)
        }
        
        process.executableURL = URL(fileURLWithPath: wpscanPath)
        
        let targetURL = "http://\(target):\(port)"
        process.arguments = [
            "--url", targetURL,
            "--detection-mode", "aggressive",
            "--enumerate", "p,t,u",
            "--format", "json"
        ]
        
        let commandLine = "wpscan \(process.arguments?.joined(separator: " ") ?? "")"
        sendRealTimeOutput("$ \(commandLine)", sessionId: session.sessionId)
        sendRealTimeOutput("", sessionId: session.sessionId)
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let result = String(data: data, encoding: .utf8) ?? ""
            
            output.append(result)
            sendRealTimeOutput(result, sessionId: session.sessionId)
            
            // Parse WPScan JSON output
            if let jsonData = result.data(using: .utf8),
               let wpscanResult = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                
                // Extract vulnerabilities
                if let vulns = wpscanResult["vulnerabilities"] as? [[String: Any]] {
                    for vuln in vulns {
                        let title = vuln["title"] as? String ?? "WordPress Vulnerability"
                        let references = vuln["references"] as? [String: Any]
                        let wpvulndb = references?["wpvulndb"] as? [String] ?? []
                        
                        let vulnerability = VulnerabilityFinding(
                            type: "WordPress Vulnerability",
                            severity: "medium",
                            description: title,
                            proof: "WPScan detection: \(wpvulndb.joined(separator: ", "))",
                            recommendation: "Update WordPress core, themes, and plugins"
                        )
                        vulnerabilities.append(vulnerability)
                    }
                }
            }
            
        } catch {
            let errorMsg = "Error executing WPScan: \(error.localizedDescription)"
            output.append(errorMsg)
            sendRealTimeOutput(errorMsg, sessionId: session.sessionId)
        }
        
        return (output, vulnerabilities)
    }
    
    private func executeFFuF(target: String, port: Int, session: AttackSession) async -> (output: [String], files: [String]) {
        var output: [String] = []
        var files: [String] = []
        
        let wordlistPath = await createDirbWordlist()
        
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        guard let ffufPath = toolDetection.getToolPath("ffuf") else {
            let errorMsg = "Error: FFuF not found in system PATH"
            output.append(errorMsg)
            sendRealTimeOutput(errorMsg, sessionId: session.sessionId)
            return (output, files)
        }
        
        process.executableURL = URL(fileURLWithPath: ffufPath)
        
        let targetURL = "http://\(target):\(port)/FUZZ"
        process.arguments = [
            "-u", targetURL,
            "-w", wordlistPath,
            "-mc", "200,204,301,302,307,401,403",
            "-t", "20",
            "-silence"
        ]
        
        let commandLine = "ffuf \(process.arguments?.joined(separator: " ") ?? "")"
        sendRealTimeOutput("$ \(commandLine)", sessionId: session.sessionId)
        sendRealTimeOutput("", sessionId: session.sessionId)
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let result = String(data: data, encoding: .utf8) ?? ""
            
            let lines = result.components(separatedBy: .newlines)
            for line in lines {
                output.append(line)
                sendRealTimeOutput(line, sessionId: session.sessionId)
                
                // Parse FFuF output for discovered paths
                if line.contains("Status:") && (line.contains("200") || line.contains("301") || line.contains("302")) {
                    if let wordRange = line.range(of: ":: ") {
                        let path = String(line[wordRange.upperBound...]).components(separatedBy: " ").first ?? ""
                        if !path.isEmpty {
                            files.append(path)
                        }
                    }
                }
            }
            
        } catch {
            let errorMsg = "Error executing FFuF: \(error.localizedDescription)"
            output.append(errorMsg)
            sendRealTimeOutput(errorMsg, sessionId: session.sessionId)
        }
        
        return (output, files)
    }
    
    private func executeSSLScan(target: String, port: Int, session: AttackSession) async -> (output: [String], vulnerabilities: [VulnerabilityFinding]) {
        var output: [String] = []
        var vulnerabilities: [VulnerabilityFinding] = []
        
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        guard let sslscanPath = toolDetection.getToolPath("sslscan") else {
            let errorMsg = "Error: SSLScan not found in system PATH"
            output.append(errorMsg)
            sendRealTimeOutput(errorMsg, sessionId: session.sessionId)
            return (output, vulnerabilities)
        }
        
        process.executableURL = URL(fileURLWithPath: sslscanPath)
        process.arguments = [
            "--targets=\(target):\(port)",
            "--ssl2",
            "--ssl3",
            "--tlsall",
            "--show-certificate"
        ]
        
        let commandLine = "sslscan \(process.arguments?.joined(separator: " ") ?? "")"
        sendRealTimeOutput("$ \(commandLine)", sessionId: session.sessionId)
        sendRealTimeOutput("", sessionId: session.sessionId)
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let result = String(data: data, encoding: .utf8) ?? ""
            
            let lines = result.components(separatedBy: .newlines)
            for line in lines {
                output.append(line)
                sendRealTimeOutput(line, sessionId: session.sessionId)
                
                // Check for SSL/TLS vulnerabilities
                if line.lowercased().contains("sslv2") && line.lowercased().contains("enabled") {
                    let vulnerability = VulnerabilityFinding(
                        type: "SSL/TLS Vulnerability",
                        severity: "high",
                        description: "SSLv2 is enabled - deprecated and insecure protocol",
                        proof: line,
                        recommendation: "Disable SSLv2 and use TLS 1.2 or higher"
                    )
                    vulnerabilities.append(vulnerability)
                }
                
                if line.lowercased().contains("sslv3") && line.lowercased().contains("enabled") {
                    let vulnerability = VulnerabilityFinding(
                        type: "SSL/TLS Vulnerability",
                        severity: "high",
                        description: "SSLv3 is enabled - vulnerable to POODLE attack",
                        proof: line,
                        recommendation: "Disable SSLv3 and use TLS 1.2 or higher"
                    )
                    vulnerabilities.append(vulnerability)
                }
                
                if line.lowercased().contains("weak cipher") || line.lowercased().contains("null cipher") {
                    let vulnerability = VulnerabilityFinding(
                        type: "SSL/TLS Vulnerability",
                        severity: "medium",
                        description: "Weak or null cipher suites detected",
                        proof: line,
                        recommendation: "Configure strong cipher suites only"
                    )
                    vulnerabilities.append(vulnerability)
                }
            }
            
        } catch {
            let errorMsg = "Error executing SSLScan: \(error.localizedDescription)"
            output.append(errorMsg)
            sendRealTimeOutput(errorMsg, sessionId: session.sessionId)
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
    
    private func executeGenericCommand(command: String, session: AttackSession) async -> (output: [String], findings: [String]) {
        var output: [String] = []
        var findings: [String] = []
        
        // Parse the command to get tool name and arguments
        let components = command.components(separatedBy: " ")
        guard let toolName = components.first else {
            output.append("Error: Empty command")
            return (output, findings)
        }
        
        // Get the tool path
        guard let toolPath = toolDetection.getToolPath(toolName) else {
            let errorMsg = "Error: \(toolName) not found in system PATH"
            output.append(errorMsg)
            sendRealTimeOutput(errorMsg, sessionId: session.sessionId)
            return (output, findings)
        }
        
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        process.executableURL = URL(fileURLWithPath: toolPath)
        
        // Set arguments (skip the first component which is the tool name)
        if components.count > 1 {
            process.arguments = Array(components.dropFirst())
        }
        
        sendRealTimeOutput("$ \(command)", sessionId: session.sessionId)
        sendRealTimeOutput("", sessionId: session.sessionId)
        
        do {
            try process.run()
            
            // Read output in real-time using a background task
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    let fileHandle = pipe.fileHandleForReading
                    var buffer = ""
                    
                    while process.isRunning {
                        let availableData = fileHandle.availableData
                        if !availableData.isEmpty {
                            if let newOutput = String(data: availableData, encoding: .utf8) {
                                buffer += newOutput
                                
                                // Process complete lines
                                let lines = buffer.components(separatedBy: .newlines)
                                let completeLines = lines.dropLast() // Last element might be incomplete
                                buffer = String(lines.last ?? "") // Keep incomplete line in buffer
                                
                                for line in completeLines {
                                    await MainActor.run {
                                        self.sendRealTimeOutput(line, sessionId: session.sessionId)
                                    }
                                }
                            }
                        }
                        
                        // Small delay to prevent excessive CPU usage
                        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
                    }
                    
                    // Read any remaining data
                    let remainingData = fileHandle.readDataToEndOfFile()
                    if !remainingData.isEmpty {
                        if let finalOutput = String(data: remainingData, encoding: .utf8) {
                            buffer += finalOutput
                            
                            // Process any remaining lines
                            let finalLines = buffer.components(separatedBy: .newlines)
                            for line in finalLines {
                                if !line.isEmpty {
                                    await MainActor.run {
                                        self.sendRealTimeOutput(line, sessionId: session.sessionId)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            process.waitUntilExit()
            
            let exitMessage = "Process completed with exit code: \(process.terminationStatus)"
            sendRealTimeOutput("", sessionId: session.sessionId)
            sendRealTimeOutput(exitMessage, sessionId: session.sessionId)
            
            // Get final output for parsing (this might be empty since we read it in real-time)
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let result = String(data: data, encoding: .utf8) ?? ""
            
            // Parse output based on tool type
            let allLines = result.components(separatedBy: .newlines)
            for line in allLines {
                output.append(line)
                
                // Extract findings based on tool type
                if toolName == "nmap" {
                    if line.contains("/tcp") && line.contains("open") {
                        findings.append(line.trimmingCharacters(in: .whitespaces))
                    }
                } else if toolName == "hydra" {
                    if line.contains("login:") && line.contains("password:") {
                        findings.append(line.trimmingCharacters(in: .whitespaces))
                    }
                } else if toolName == "dirb" || toolName == "gobuster" {
                    if line.contains("==> DIRECTORY:") || line.contains("(Status: 200)") {
                        findings.append(line.trimmingCharacters(in: .whitespaces))
                    }
                } else if toolName == "nikto" {
                    if line.contains("OSVDB-") || line.contains("CVE-") {
                        findings.append(line.trimmingCharacters(in: .whitespaces))
                    }
                } else if toolName == "sqlmap" {
                    if line.contains("Parameter:") && line.contains("is vulnerable") {
                        findings.append(line.trimmingCharacters(in: .whitespaces))
                    }
                } else {
                    // Generic finding extraction - look for interesting patterns
                    if !line.trimmingCharacters(in: .whitespaces).isEmpty && 
                       !line.contains("Starting") && 
                       !line.contains("Nmap scan report") {
                        findings.append(line.trimmingCharacters(in: .whitespaces))
                    }
                }
            }
            
        } catch {
            let errorMsg = "Error executing \(toolName): \(error.localizedDescription)"
            output.append(errorMsg)
            sendRealTimeOutput(errorMsg, sessionId: session.sessionId)
        }
        
        return (output, findings)
    }
    
    private func checkTargetConnectivity(_ targetURL: String) async -> Bool {
        guard let url = URL(string: targetURL) else { return false }
        
        // For localhost or 127.0.0.1, assume reachable (they might not serve HTTP but be valid targets)
        if let host = url.host?.lowercased(),
           host == "localhost" || host == "127.0.0.1" || host.hasPrefix("192.168.") || host.hasPrefix("10.") {
            return true
        }
        
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 10 // 10 second timeout
            request.httpMethod = "HEAD" // Use HEAD instead of GET for faster check
            
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode < 500
            }
            return true
        } catch {
            // If connectivity check fails, still proceed with the scan
            // The actual tool will provide better error messages
            return true
        }
    }
    
    private func sendRealTimeOutput(_ output: String, sessionId: String) {
        if let callback = realTimeOutputCallback {
            callback(output)
        }
        
        // Also add to session output for Active Attacks view
        if let session = activeAttacks[sessionId] {
            session.addOutput(output)
        }
    }
    
    private func createDirbWordlist() async -> String {
        // Get user home directory properly
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        
        // First check if wordlist exists - prioritize user directory
        let defaultPaths = [
            "\(homeDir)/.local/share/wordlists/common.txt",
            "\(homeDir)/.local/share/wordlists/SecLists/Discovery/Web-Content/common.txt",
            "/usr/share/dirb/wordlists/common.txt",
            "/usr/local/share/dirb/wordlists/common.txt",
            "/opt/homebrew/share/dirb/wordlists/common.txt",
            "/usr/local/share/wordlists/common.txt",
            "/usr/local/share/wordlists/SecLists/Discovery/Web-Content/common.txt"
        ]
        
        for path in defaultPaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        // Create a custom wordlist in temp directory
        let tempDir = FileManager.default.temporaryDirectory
        let wordlistPath = tempDir.appendingPathComponent("dirb_wordlist.txt")
        
        // Common directory names for web enumeration
        let commonPaths = [
            "admin", "administrator", "api", "app", "apps", "assets", "backup", "backups",
            "bin", "blog", "cache", "cgi-bin", "config", "css", "data", "database", "db",
            "dev", "docs", "download", "downloads", "email", "error", "errors", "files",
            "forum", "ftp", "help", "home", "images", "img", "includes", "index", "info",
            "js", "lib", "library", "log", "logs", "mail", "news", "old", "pages", "php",
            "private", "public", "root", "scripts", "search", "secure", "shop", "src",
            "stats", "system", "temp", "test", "tmp", "tools", "upload", "uploads", "user",
            "users", "var", "web", "webmail", "www", "xml"
        ]
        
        let wordlistContent = commonPaths.joined(separator: "\n")
        
        do {
            try wordlistContent.write(to: wordlistPath, atomically: true, encoding: .utf8)
            print("✅ Created wordlist at: \(wordlistPath.path)")
            print("📁 Wordlist contains \(commonPaths.count) entries")
            return wordlistPath.path
        } catch {
            print("❌ Error creating wordlist at \(wordlistPath.path): \(error)")
            
            // Try creating a fallback wordlist in the current working directory
            let currentDir = FileManager.default.currentDirectoryPath
            let fallbackPath = "\(currentDir)/dirb_wordlist.txt"
            
            do {
                try wordlistContent.write(toFile: fallbackPath, atomically: true, encoding: .utf8)
                print("✅ Created fallback wordlist at: \(fallbackPath)")
                return fallbackPath
            } catch {
                print("❌ Failed to create fallback wordlist: \(error)")
                print("🔧 Attempting to use system wordlist...")
                
                // Final fallback: try to find any system wordlist
                let systemWordlists = [
                    "/usr/share/wordlists/dirb/common.txt",
                    "/usr/local/share/dirb/wordlists/common.txt",
                    "/opt/homebrew/share/dirb/wordlists/common.txt"
                ]
                
                for path in systemWordlists {
                    if FileManager.default.fileExists(atPath: path) {
                        print("✅ Using system wordlist: \(path)")
                        return path
                    }
                }
                
                print("❌ No wordlist available - returning empty path")
                return ""
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
    case netcat = "Netcat"
    case nuclei = "Nuclei"
    case httpx = "HTTPx"
    case subfinder = "Subfinder"
    case ffuf = "FFuF"
    case sslscan = "SSLScan"
    case whatweb = "WhatWeb"
    case wpscan = "WPScan"
    case john = "John the Ripper"
    case hashcat = "Hashcat"
    case enum4linux = "Enum4linux"
    case smbclient = "SMBClient"
    case rpcclient = "RPCClient"
    case ldapsearch = "LDAPSearch"
    case snmpwalk = "SNMPWalk"
    case crackmapexec = "CrackMapExec"
    case responder = "Responder"
    case impacket = "Impacket"
    case bloodhound = "BloodHound"
    case masscan = "Masscan"
    case rustscan = "RustScan"
    
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
        case .netcat: return "netcat"
        case .nuclei: return "nuclei"
        case .httpx: return "httpx"
        case .subfinder: return "subfinder"
        case .ffuf: return "ffuf"
        case .sslscan: return "sslscan"
        case .whatweb: return "whatweb"
        case .wpscan: return "wpscan"
        case .john: return "john"
        case .hashcat: return "hashcat"
        case .enum4linux: return "enum4linux"
        case .smbclient: return "smbclient"
        case .rpcclient: return "rpcclient"
        case .ldapsearch: return "ldapsearch"
        case .snmpwalk: return "snmpwalk"
        case .crackmapexec: return "crackmapexec"
        case .responder: return "responder"
        case .impacket: return "impacket-smbserver"
        case .bloodhound: return "bloodhound"
        case .masscan: return "masscan"
        case .rustscan: return "rustscan"
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
        case .netcat: return "netcat"
        case .nuclei: return "nuclei"
        case .httpx: return "httpx"
        case .subfinder: return "subfinder"
        case .ffuf: return "ffuf"
        case .sslscan: return "sslscan"
        case .whatweb: return "whatweb"
        case .wpscan: return "wpscan"
        case .john: return "john-jumbo"
        case .hashcat: return "hashcat"
        case .enum4linux: return "enum4linux-ng"
        case .smbclient: return "samba"
        case .rpcclient: return "samba"
        case .ldapsearch: return "openldap"
        case .snmpwalk: return "net-snmp"
        case .crackmapexec: return "crackmapexec"
        case .responder: return "responder"
        case .impacket: return "impacket"
        case .bloodhound: return "bloodhound"
        case .masscan: return "masscan"
        case .rustscan: return "rustscan"
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
        case .netcat: return "Network utility"
        case .nuclei: return "Fast vulnerability scanner with 9000+ templates"
        case .httpx: return "HTTP probe and service analyzer"
        case .subfinder: return "Passive subdomain discovery tool"
        case .ffuf: return "Fast web fuzzer written in Go"
        case .sslscan: return "SSL/TLS configuration analyzer"
        case .whatweb: return "Web application fingerprinting"
        case .wpscan: return "WordPress vulnerability scanner"
        case .john: return "Password hash cracker"
        case .hashcat: return "Advanced password recovery tool"
        case .enum4linux: return "SMB enumeration tool for Linux/Windows"
        case .smbclient: return "SMB/CIFS client for accessing shares"
        case .rpcclient: return "Windows RPC client for enumeration"
        case .ldapsearch: return "LDAP directory search utility"
        case .snmpwalk: return "SNMP network management scanner"
        case .crackmapexec: return "Swiss army knife for pentesting Windows/AD"
        case .responder: return "LLMNR, NBT-NS, and MDNS poisoner"
        case .impacket: return "Python network protocol toolkit"
        case .bloodhound: return "Active Directory attack path analysis"
        case .masscan: return "Fast TCP/UDP port scanner"
        case .rustscan: return "Modern port scanner built in Rust"
        }
    }
}

@Observable
class AttackSession {
    let sessionId: String
    let attack: AttackVector
    let target: String
    let port: Int
    let startTime: Date
    var endTime: Date?
    var isCancelled = false
    var status: AttackStatus = .running
    var outputLines: [String] = []
    var findings: [String] = []
    var completedCommands: Int = 0
    var totalCommands: Int = 0
    
    // Convenience properties for UI
    var attackName: String { attack.name }
    
    var duration: TimeInterval {
        if let endTime = endTime {
            return endTime.timeIntervalSince(startTime)
        } else {
            return Date().timeIntervalSince(startTime)
        }
    }
    
    var isCompleted: Bool {
        return status == .completed || status == .failed || status == .stopped
    }
    
    enum AttackStatus: String, CaseIterable {
        case running = "running"
        case completed = "completed"
        case failed = "failed"
        case stopped = "stopped"
    }
    
    init(id: String, attack: AttackVector, target: String, port: Int, startTime: Date) {
        self.sessionId = id
        self.attack = attack
        self.target = target
        self.port = port
        self.startTime = startTime
        self.totalCommands = attack.commands.count
    }
    
    func cancel() {
        isCancelled = true
        status = .stopped
        endTime = Date()
    }
    
    func addOutput(_ output: String) {
        outputLines.append(output)
    }
    
    func addFinding(_ finding: String) {
        findings.append(finding)
    }
    
    func markCommandCompleted() {
        completedCommands += 1
    }
    
    func markCompleted() {
        status = .completed
        endTime = Date()
    }
    
    func markFailed() {
        status = .failed
        endTime = Date()
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
