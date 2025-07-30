//
//  ToolManager.swift
//  DonkTool
//
//  Dynamic tool path resolution and management
//

import Foundation

/// Manages external security tool discovery and validation
@MainActor
class ToolManager {
    static let shared = ToolManager()
    
    // Cache for discovered tool paths
    private var toolPathCache: [String: String] = [:]
    
    // Common installation paths for various tools
    private let searchPaths = [
        "/opt/homebrew/bin",
        "/opt/homebrew/sbin",
        "/usr/local/bin",
        "/usr/local/sbin",
        "/usr/bin",
        "/usr/sbin",
        "/bin",
        "/sbin",
        NSHomeDirectory() + "/go/bin",
        NSHomeDirectory() + "/.cargo/bin",
        NSHomeDirectory() + "/.local/bin",
        "/opt/metasploit-framework/bin",
        "/Applications/OWASP ZAP.app/Contents/MacOS",
        "/opt/testssl",
        "/opt/xsstrike"
    ]
    
    // Tool installation commands
    private let installCommands: [String: String] = [
        "sqlmap": "brew install sqlmap",
        "nikto": "brew install nikto",
        "gobuster": "brew install gobuster",
        "dirb": "brew install dirb",
        "nuclei": "brew install nuclei",
        "feroxbuster": "brew install feroxbuster",
        "httpx": "go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest",
        "testssl.sh": "brew install testssl",
        "hydra": "brew install thc-hydra",
        "hping3": "brew install hping",
        "wrk": "brew install wrk",
        "slowhttptest": "brew install slowhttptest",
        "xsstrike": "pip3 install xsstrike",
        "sshpass": "brew install hudochenkov/sshpass/sshpass",
        "zap.sh": "brew install --cask owasp-zap",
        "msfconsole": "brew install metasploit",
        "searchsploit": "brew install exploitdb",
        "nmap": "brew install nmap",
        "ffuf": "brew install ffuf",
        "sslyze": "pip3 install sslyze",
        "subfinder": "brew install subfinder"
    ]
    
    private init() {}
    
    /// Find the full path for a tool
    func findToolPath(_ toolName: String) -> String? {
        // Check cache first
        if let cachedPath = toolPathCache[toolName] {
            if FileManager.default.fileExists(atPath: cachedPath) {
                return cachedPath
            } else {
                // Invalidate cache if file no longer exists
                toolPathCache.removeValue(forKey: toolName)
            }
        }
        
        // Search in common paths
        for basePath in searchPaths {
            let fullPath = "\(basePath)/\(toolName)"
            if FileManager.default.fileExists(atPath: fullPath) {
                // Check if executable
                if FileManager.default.isExecutableFile(atPath: fullPath) {
                    toolPathCache[toolName] = fullPath
                    return fullPath
                }
            }
        }
        
        // Try alternate names
        let alternateNames = getAlternateNames(for: toolName)
        for altName in alternateNames {
            for basePath in searchPaths {
                let fullPath = "\(basePath)/\(altName)"
                if FileManager.default.fileExists(atPath: fullPath) &&
                   FileManager.default.isExecutableFile(atPath: fullPath) {
                    toolPathCache[toolName] = fullPath
                    return fullPath
                }
            }
        }
        
        // Fallback to 'which' command
        return findUsingWhich(toolName)
    }
    
    /// Get alternate names for tools
    private func getAlternateNames(for toolName: String) -> [String] {
        switch toolName {
        case "hping3": return ["hping", "hping2"]
        case "testssl": return ["testssl.sh", "testssl"]
        case "zap": return ["zap.sh", "OWASP ZAP.sh"]
        case "slowloris": return ["slowloris.py", "slowloris.pl"]
        case "goldeneye": return ["goldeneye.py", "GoldenEye.py"]
        default: return []
        }
    }
    
    /// Use 'which' command to find tool
    private func findUsingWhich(_ toolName: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [toolName]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe() // Discard errors
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !path.isEmpty {
                    toolPathCache[toolName] = path
                    return path
                }
            }
        } catch {
            // Ignore errors from which command
        }
        
        return nil
    }
    
    /// Check if a tool is installed
    func isToolInstalled(_ toolName: String) -> Bool {
        return findToolPath(toolName) != nil
    }
    
    /// Get installation command for a tool
    func getInstallCommand(for toolName: String) -> String {
        return installCommands[toolName] ?? "Tool installation command not found. Check documentation."
    }
    
    /// Verify all required tools are installed
    func verifyRequiredTools() -> [(tool: String, installed: Bool, installCmd: String)] {
        let requiredTools = [
            "nmap", "sqlmap", "nikto", "gobuster", "nuclei",
            "httpx", "hydra", "wrk", "slowhttptest"
        ]
        
        return requiredTools.map { tool in
            (tool: tool,
             installed: isToolInstalled(tool),
             installCmd: getInstallCommand(for: tool))
        }
    }
    
    /// Get Python3 path (for Python-based tools)
    func getPython3Path() -> String? {
        let pythonPaths = [
            "/opt/homebrew/opt/python@3.13/bin/python3.13",
            "/opt/homebrew/opt/python@3.12/bin/python3.12",
            "/opt/homebrew/bin/python3",
            "/usr/local/bin/python3",
            "/usr/bin/python3"
        ]
        
        for path in pythonPaths {
            if FileManager.default.fileExists(atPath: path) &&
               FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        
        return findUsingWhich("python3")
    }
    
    /// Clear the tool path cache
    func clearCache() {
        toolPathCache.removeAll()
    }
    
    /// Get all discovered tool paths
    func getDiscoveredTools() -> [String: String] {
        return toolPathCache
    }
    
    /// Check tool installation status
    func checkToolInstallation(tool: String) -> (isInstalled: Bool, path: String?) {
        if let path = findToolPath(tool) {
            return (isInstalled: true, path: path)
        }
        return (isInstalled: false, path: nil)
    }
}

// MARK: - Tool Categories

extension ToolManager {
    enum ToolCategory {
        case webScanning
        case networkScanning
        case exploitation
        case bruteForce
        case dosStress
        case bluetooth
        case reporting
        
        var tools: [String] {
            switch self {
            case .webScanning:
                return ["sqlmap", "nikto", "gobuster", "dirb", "nuclei", "feroxbuster", "httpx", "testssl.sh", "xsstrike", "zap.sh", "ffuf"]
            case .networkScanning:
                return ["nmap", "masscan", "zmap", "rustscan"]
            case .exploitation:
                return ["msfconsole", "searchsploit", "metasploit"]
            case .bruteForce:
                return ["hydra", "medusa", "john", "hashcat"]
            case .dosStress:
                return ["hping3", "wrk", "slowhttptest", "goldeneye", "slowloris", "t50"]
            case .bluetooth:
                return ["hcitool", "gatttool", "bluetoothctl", "bluesnarfer"]
            case .reporting:
                return ["wkhtmltopdf", "pandoc"]
            }
        }
    }
    
    /// Check if all tools in a category are installed
    func checkCategoryTools(_ category: ToolCategory) -> [(tool: String, installed: Bool)] {
        return category.tools.map { tool in
            (tool: tool, installed: isToolInstalled(tool))
        }
    }
}

// MARK: - Sudo Check

extension ToolManager {
    /// Check if a tool requires sudo
    func requiresSudo(_ toolName: String) -> Bool {
        let sudoTools = ["hping3", "hping", "masscan", "t50", "nmap"]
        return sudoTools.contains(toolName)
    }
    
    /// Get sudo-wrapped command if needed
    func wrapCommandIfNeeded(_ toolPath: String, toolName: String) -> String {
        if requiresSudo(toolName) {
            return "sudo \(toolPath)"
        }
        return toolPath
    }
}