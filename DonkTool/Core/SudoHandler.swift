//
//  SudoHandler.swift
//  DonkTool
//
//  Handles sudo command execution with macOS authorization
//

import Foundation
import SwiftUI

@Observable
class SudoHandler {
    static let shared = SudoHandler()
    
    private init() {}
    
    /// Execute a command with sudo privileges using macOS authorization
    func executeWithSudo(command: String, arguments: [String], sessionId: String, outputHandler: @escaping (String) -> Void) async throws {
        // Create a temporary script that will be executed with privileges
        let scriptContent = """
        #!/bin/bash
        \(command) \(arguments.joined(separator: " "))
        """
        
        let tempScriptPath = "/tmp/donktool_sudo_\(UUID().uuidString).sh"
        try scriptContent.write(toFile: tempScriptPath, atomically: true, encoding: .utf8)
        
        // Make script executable
        try await Process.run(URL(fileURLWithPath: "/bin/chmod"), arguments: ["+x", tempScriptPath])
        
        // Use osascript to prompt for admin privileges
        let osascriptCommand = """
        do shell script "\(tempScriptPath)" with administrator privileges
        """
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", osascriptCommand]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        // Read output in real-time
        let outputHandle = pipe.fileHandleForReading
        outputHandle.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty, let output = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    outputHandler(output)
                }
            }
        }
        
        try process.run()
        process.waitUntilExit()
        
        // Clean up
        try? FileManager.default.removeItem(atPath: tempScriptPath)
        
        if process.terminationStatus != 0 {
            throw SudoError.authorizationFailed
        }
    }
    
    /// Check if a command requires sudo
    func requiresSudo(command: String) -> Bool {
        let sudoCommands = [
            "bettercap",
            "airmon-ng",
            "airodump-ng",
            "aireplay-ng",
            "aircrack-ng",
            "responder",
            "tcpdump",
            "masscan"
        ]
        
        return sudoCommands.contains { command.contains($0) }
    }
}

enum SudoError: LocalizedError {
    case authorizationFailed
    case commandNotFound
    
    var errorDescription: String? {
        switch self {
        case .authorizationFailed:
            return "Authorization failed. Admin privileges are required for this operation."
        case .commandNotFound:
            return "Command not found in system PATH"
        }
    }
}