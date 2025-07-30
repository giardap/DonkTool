//
//  SudoManager.swift
//  DonkTool
//
//  Manages sudo privilege elevation for security tools
//

import Foundation
import SwiftUI
import Security

@Observable
class SudoManager {
    static let shared = SudoManager()
    
    var showSudoPrompt = false
    var sudoPassword = ""
    var sudoPromptTitle = ""
    var sudoPromptMessage = ""
    var pendingSudoCommand: (() -> Void)?
    
    private init() {}
    
    /// Request sudo privileges with user prompt
    func requestSudoPrivileges(
        title: String,
        message: String,
        command: @escaping () -> Void
    ) {
        sudoPromptTitle = title
        sudoPromptMessage = message
        pendingSudoCommand = command
        showSudoPrompt = true
    }
    
    /// Execute command with sudo privileges
    func executeSudoCommand(
        command: String,
        arguments: [String],
        password: String? = nil
    ) async throws -> (output: [String], exitCode: Int32) {
        
        var fullCommand = "sudo \(command)"
        if !arguments.isEmpty {
            fullCommand += " " + arguments.joined(separator: " ")
        }
        
        let process = Process()
        process.launchPath = "/bin/bash"
        process.arguments = ["-c", fullCommand]
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        let inputPipe = Pipe()
        
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        process.standardInput = inputPipe
        
        var outputLines: [String] = []
        var errorLines: [String] = []
        
        // Setup output monitoring
        let outputHandle = outputPipe.fileHandleForReading
        let errorHandle = errorPipe.fileHandleForReading
        
        outputHandle.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty {
                if let output = String(data: data, encoding: .utf8) {
                    let lines = output.components(separatedBy: .newlines).filter { !$0.isEmpty }
                    outputLines.append(contentsOf: lines)
                }
            }
        }
        
        errorHandle.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty {
                if let error = String(data: data, encoding: .utf8) {
                    let lines = error.components(separatedBy: .newlines).filter { !$0.isEmpty }
                    errorLines.append(contentsOf: lines)
                }
            }
        }
        
        try process.run()
        
        // If password is provided, send it to sudo
        if let password = password {
            let passwordData = "\(password)\n".data(using: .utf8)!
            try inputPipe.fileHandleForWriting.write(contentsOf: passwordData)
            inputPipe.fileHandleForWriting.closeFile()
        }
        
        process.waitUntilExit()
        
        // Close handlers
        outputHandle.readabilityHandler = nil
        errorHandle.readabilityHandler = nil
        
        // Combine output and error streams
        let allOutput = outputLines + errorLines
        
        return (output: allOutput, exitCode: process.terminationStatus)
    }
    
    /// Check if a command requires sudo privileges
    func requiresSudo(command: String) -> Bool {
        let sudoRequiredCommands = [
            "nmap", "masscan", "hping3", "tcpdump", "wireshark",
            "aircrack-ng", "airmon-ng", "airodump-ng", "aireplay-ng"
        ]
        
        return sudoRequiredCommands.contains { command.contains($0) }
    }
    
    /// Get sudo-enhanced version of command
    func sudoCommand(command: String, arguments: [String]) -> (command: String, arguments: [String]) {
        if requiresSudo(command: command) {
            return (command: "sudo", arguments: [command] + arguments)
        } else {
            return (command: command, arguments: arguments)
        }
    }
    
    /// Execute command with automatic sudo detection
    func executeCommand(
        command: String,
        arguments: [String] = [],
        requiresAuth: Bool = false
    ) async -> (output: [String], success: Bool) {
        
        if requiresAuth || requiresSudo(command: command) {
            // Try with sudo first
            do {
                let result = try await executeSudoCommand(command: command, arguments: arguments)
                return (output: result.output, success: result.exitCode == 0)
            } catch {
                // If sudo fails, try without sudo as fallback
                return await executeBasicCommand(command: command, arguments: arguments)
            }
        } else {
            return await executeBasicCommand(command: command, arguments: arguments)
        }
    }
    
    private func executeBasicCommand(command: String, arguments: [String]) async -> (output: [String], success: Bool) {
        let process = Process()
        process.launchPath = "/usr/bin/env"
        process.arguments = [command] + arguments
        
        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe
        
        var outputLines: [String] = []
        
        do {
            try process.run()
            
            let outputHandle = pipe.fileHandleForReading
            let errorHandle = errorPipe.fileHandleForReading
            
            while process.isRunning {
                let outputData = outputHandle.availableData
                let errorData = errorHandle.availableData
                
                if !outputData.isEmpty {
                    if let output = String(data: outputData, encoding: .utf8) {
                        let lines = output.components(separatedBy: .newlines).filter { !$0.isEmpty }
                        outputLines.append(contentsOf: lines)
                    }
                }
                
                if !errorData.isEmpty {
                    if let error = String(data: errorData, encoding: .utf8) {
                        let lines = error.components(separatedBy: .newlines).filter { !$0.isEmpty }
                        outputLines.append(contentsOf: lines)
                    }
                }
                
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
            
            process.waitUntilExit()
            
            return (output: outputLines, success: process.terminationStatus == 0)
            
        } catch {
            return (output: ["Error: \(error.localizedDescription)"], success: false)
        }
    }
    
    /// Clear sudo prompt state
    func clearSudoPrompt() {
        showSudoPrompt = false
        sudoPassword = ""
        sudoPromptTitle = ""
        sudoPromptMessage = ""
        pendingSudoCommand = nil
    }
    
    /// Execute pending sudo command with provided password
    func executePendingCommand(password: String) {
        sudoPassword = password
        pendingSudoCommand?()
        clearSudoPrompt()
    }
}

// MARK: - Sudo Prompt View
struct SudoPromptView: View {
    @Environment(\.dismiss) private var dismiss
    let sudoManager = SudoManager.shared
    @State private var password = ""
    @State private var showPassword = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)
                
                Text(sudoManager.sudoPromptTitle)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            // Message
            Text(sudoManager.sudoPromptMessage)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            // Warning
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                
                Text("Administrator privileges required")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
            
            // Password input
            VStack(alignment: .leading, spacing: 8) {
                Text("Password:")
                    .font(.headline)
                
                HStack {
                    Group {
                        if showPassword {
                            TextField("Enter your password", text: $password)
                        } else {
                            SecureField("Enter your password", text: $password)
                        }
                    }
                    .textFieldStyle(.roundedBorder)
                    
                    Button(action: {
                        showPassword.toggle()
                    }) {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    sudoManager.clearSudoPrompt()
                    dismiss()
                }
                .secondaryButton()
                
                Button("Authenticate") {
                    sudoManager.executePendingCommand(password: password)
                    dismiss()
                }
                .disabled(password.isEmpty)
                .primaryButton()
            }
        }
        .padding(24)
        .frame(width: 400)
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 20)
    }
}