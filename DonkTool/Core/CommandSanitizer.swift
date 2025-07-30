//
//  CommandSanitizer.swift
//  DonkTool
//
//  Command input sanitization to prevent injection attacks
//

import Foundation

/// Sanitizes command inputs to prevent injection attacks
struct CommandSanitizer {
    
    /// Characters that should be escaped in shell commands
    private static let dangerousCharacters = CharacterSet(charactersIn: ";|&`$(){}[]<>\"'\\*?~")
    
    /// Characters allowed in URLs
    private static let urlAllowedCharacters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~:/?#[]@!$&'()*+,;=")
    
    /// Characters allowed in IP addresses
    private static let ipAllowedCharacters = CharacterSet(charactersIn: "0123456789.")
    
    /// Characters allowed in hostnames
    private static let hostnameAllowedCharacters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-.")
    
    /// Sanitize a general shell argument
    static func sanitizeShellArgument(_ input: String) -> String {
        // Remove any null bytes
        var sanitized = input.replacingOccurrences(of: "\0", with: "")
        
        // Escape dangerous characters
        for char in dangerousCharacters.allCharacters() {
            sanitized = sanitized.replacingOccurrences(of: String(char), with: "\\\(char)")
        }
        
        // Remove any newlines or carriage returns
        sanitized = sanitized.replacingOccurrences(of: "\n", with: "")
        sanitized = sanitized.replacingOccurrences(of: "\r", with: "")
        
        return sanitized
    }
    
    /// Sanitize a URL for use in commands
    static func sanitizeURL(_ url: String) -> String? {
        // First, try to parse as URL to validate structure
        guard let parsedURL = URL(string: url) else {
            return nil
        }
        
        // Ensure it's http or https
        guard let scheme = parsedURL.scheme,
              ["http", "https"].contains(scheme.lowercased()) else {
            return nil
        }
        
        // Remove any characters not allowed in URLs
        let sanitized = url.unicodeScalars
            .filter { urlAllowedCharacters.contains($0) }
            .map { String($0) }
            .joined()
        
        // Verify the sanitized URL is still valid
        guard URL(string: sanitized) != nil else {
            return nil
        }
        
        return sanitized
    }
    
    /// Sanitize an IP address
    static func sanitizeIPAddress(_ ip: String) -> String? {
        // Remove any non-IP characters
        let sanitized = ip.unicodeScalars
            .filter { ipAllowedCharacters.contains($0) }
            .map { String($0) }
            .joined()
        
        // Validate IP format
        let parts = sanitized.split(separator: ".")
        guard parts.count == 4 else { return nil }
        
        for part in parts {
            guard let num = Int(part),
                  num >= 0 && num <= 255 else {
                return nil
            }
        }
        
        return sanitized
    }
    
    /// Sanitize a hostname
    static func sanitizeHostname(_ hostname: String) -> String? {
        // Remove any non-hostname characters
        let sanitized = hostname.unicodeScalars
            .filter { hostnameAllowedCharacters.contains($0) }
            .map { String($0) }
            .joined()
        
        // Basic hostname validation
        guard !sanitized.isEmpty,
              !sanitized.hasPrefix("-"),
              !sanitized.hasSuffix("-"),
              !sanitized.contains("..") else {
            return nil
        }
        
        return sanitized
    }
    
    /// Sanitize a port number
    static func sanitizePort(_ port: String) -> Int? {
        // Remove any non-numeric characters
        let sanitized = port.filter { $0.isNumber }
        
        guard let portNum = Int(sanitized),
              portNum > 0 && portNum <= 65535 else {
            return nil
        }
        
        return portNum
    }
    
    /// Sanitize a file path (for wordlists, etc.)
    static func sanitizeFilePath(_ path: String) -> String? {
        // Prevent directory traversal
        guard !path.contains("..") else { return nil }
        
        // Remove null bytes
        let sanitized = path.replacingOccurrences(of: "\0", with: "")
        
        // Ensure it's not trying to access sensitive areas
        let forbiddenPaths = ["/etc/passwd", "/etc/shadow", "~/.ssh", "/System", "/private"]
        for forbidden in forbiddenPaths {
            if sanitized.contains(forbidden) {
                return nil
            }
        }
        
        return sanitized
    }
    
    /// Validate and sanitize a command before execution
    static func validateCommand(_ command: String, arguments: [String]) -> (isValid: Bool, sanitizedArgs: [String]) {
        // Check if command itself is in allowed list
        let allowedCommands = [
            "nmap", "sqlmap", "nikto", "gobuster", "dirb", "nuclei",
            "feroxbuster", "httpx", "testssl.sh", "hydra", "hping3",
            "wrk", "slowhttptest", "ffuf", "sslyze", "subfinder",
            "masscan", "zmap", "rustscan", "john", "hashcat"
        ]
        
        let commandName = URL(fileURLWithPath: command).lastPathComponent
        guard allowedCommands.contains(commandName) else {
            return (false, [])
        }
        
        // Sanitize each argument
        let sanitizedArgs = arguments.map { sanitizeShellArgument($0) }
        
        // Additional validation based on command
        switch commandName {
        case "sqlmap":
            // Ensure URL argument is valid
            if let urlIndex = arguments.firstIndex(of: "-u"),
               urlIndex + 1 < arguments.count {
                let url = arguments[urlIndex + 1]
                guard sanitizeURL(url) != nil else {
                    return (false, [])
                }
            }
            
        case "nmap":
            // Validate target IP/hostname
            if let target = arguments.last {
                if !target.hasPrefix("-") {
                    guard sanitizeIPAddress(target) != nil ||
                          sanitizeHostname(target) != nil else {
                        return (false, [])
                    }
                }
            }
            
        default:
            break
        }
        
        return (true, sanitizedArgs)
    }
}

// MARK: - CharacterSet Extension

extension CharacterSet {
    func allCharacters() -> [Character] {
        var characters: [Character] = []
        for plane: UInt8 in 0...16 where self.hasMember(inPlane: plane) {
            for unicode in UInt32(plane) << 16 ..< UInt32(plane + 1) << 16 {
                if let scalar = UnicodeScalar(unicode), self.contains(scalar) {
                    characters.append(Character(scalar))
                }
            }
        }
        return characters
    }
}

// MARK: - Process Extension for Safe Execution

extension Process {
    /// Execute a command with sanitized inputs
    static func safeExecute(
        command: String,
        arguments: [String],
        timeout: TimeInterval = 300
    ) async throws -> (output: String, exitCode: Int32) {
        // Validate and sanitize
        let (isValid, sanitizedArgs) = CommandSanitizer.validateCommand(command, arguments: arguments)
        guard isValid else {
            throw CommandError.invalidCommand
        }
        
        // Check if command requires sudo
        let toolName = URL(fileURLWithPath: command).lastPathComponent
        if await ToolManager.shared.requiresSudo(toolName) {
            // Use UserConfirmation for sudo operations
            return try await UserConfirmation.shared.executeSudoCommand(command, arguments: sanitizedArgs)
        }
        
        // Regular execution
        let process = Process()
        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = sanitizedArgs
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        
        // Wait with timeout
        let startTime = Date()
        while process.isRunning && Date().timeIntervalSince(startTime) < timeout {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        }
        
        if process.isRunning {
            process.terminate()
            throw CommandError.timeout
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        return (output: output, exitCode: process.terminationStatus)
    }
}

enum CommandError: LocalizedError {
    case invalidCommand
    case timeout
    case executionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidCommand:
            return "Invalid or potentially dangerous command"
        case .timeout:
            return "Command execution timed out"
        case .executionFailed(let message):
            return "Command execution failed: \(message)"
        }
    }
}