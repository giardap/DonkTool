import Foundation
import Combine

@Observable
class ToolDetection {
    static let shared = ToolDetection()
    
    private init() {
        // Initialize with known working tools to avoid cycles
        setupInitialToolStatus()
        
        Task {
            await refreshToolStatus()
        }
    }
    
    private func setupInitialToolStatus() {
        // Based on TOOLS_STATUS.md and newly installed tools - mark known working tools as available
        let knownWorkingTools = [
            // Core penetration testing tools
            "wrk": true,
            "feroxbuster": true, 
            "nuclei": true,
            "httpx": true,
            "subfinder": true,
            "katana": true,
            "sslyze": true,
            "dirsearch": true,
            "nmap": true,
            "nikto": true,
            "sqlmap": true,
            "gobuster": true,
            "dirb": true,
            "ffuf": true,
            "hping3": true,
            "iperf3": true,
            "python3": true,
            "curl": true,
            
            // Newly installed DoS testing tools
            "slowhttptest": true,
            "goldeneye": true,
            "hulk": true,
            "t50": true,
            "thc-ssl-dos": true,
            "artillery": true,
            "mhddos": true,
            "torshammer": true,
            "pyloris": true,
            "xerxes": true,
            "pentmenu": true,
            "hyenados": true,  // Maps to hyenae
            "hyenae": true
        ]
        
        for (tool, status) in knownWorkingTools {
            toolStatus[tool] = status
        }
    }
    
    var toolStatus: [String: Bool] = [:]
    var lastRefresh: Date?
    
    // Tool aliases and variations
    private let toolAliases: [String: [String]] = [
        "nmap": ["nmap"],
        "burpsuite": ["burpsuite", "burp-suite", "burp", "BurpSuiteCommunity", "BurpSuitePro"],
        "gobuster": ["gobuster"],
        "dirb": ["dirb"],
        "nikto": ["nikto", "nikto.pl"],
        "sqlmap": ["sqlmap", "sqlmap.py"],
        "metasploit": ["msfconsole", "metasploit"],
        "john": ["john", "john-the-ripper"],
        "hydra": ["hydra", "thc-hydra"],
        "wireshark": ["wireshark", "tshark"],
        "openssl": ["openssl"],
        "curl": ["curl"],
        "wget": ["wget"],
        "netcat": ["netcat", "nc"],
        
        // Modern Go-based tools
        "nuclei": ["nuclei"],
        "httpx": ["httpx"],
        "subfinder": ["subfinder"],
        "katana": ["katana"],
        "ffuf": ["ffuf"],
        
        // Python tools
        "sslyze": ["sslyze"],
        "dirsearch": ["dirsearch"],
        "wfuzz": ["wfuzz"],
        
        // DoS/Stress testing tools
        "wrk": ["wrk"],
        "hping3": ["hping3", "hping"],
        "slowhttptest": ["slowhttptest"],
        "siege": ["siege"],
        "iperf3": ["iperf3", "iperf"],
        "artillery": ["artillery"],
        "vegeta": ["vegeta"],
        
        // Advanced DoS tools
        "hulk": ["hulk"],
        "goldeneye": ["goldeneye"],
        "t50": ["t50"],
        "mhddos": ["mhddos"],
        "torshammer": ["torshammer"],
        "pyloris": ["pyloris"],
        "xerxes": ["xerxes"],
        "pentmenu": ["pentmenu"],
        "hyenados": ["hyenados"],
        "thc-ssl-dos": ["thc-ssl-dos"],
        
        // Rust tools
        "feroxbuster": ["feroxbuster"]
    ]
    
    // Paths where tools might be installed
    private let searchPaths = [
        "/usr/bin",
        "/usr/local/bin",
        "/opt/homebrew/bin",
        "/usr/sbin",
        "/usr/local/sbin",
        "/Applications", // For GUI apps
        "/Applications/Burp Suite Community Edition.app/Contents/MacOS",
        "/Applications/Burp Suite Professional.app/Contents/MacOS",
        "/Applications/Wireshark.app/Contents/MacOS",
        "~/Applications",
        "/opt/metasploit-framework/bin",
        
        // Go tools path
        "~/go/bin",
        "/Users/giardap/go/bin",
        
        // Python tools paths
        "~/.local/bin",
        "/Users/giardap/.local/bin",
        
        // Cargo/Rust tools
        "~/.cargo/bin",
        "/Users/giardap/.cargo/bin",
        
        // PNPM global tools
        "/Users/giardap/Library/pnpm",
        "/Users/giardap/Library/pnpm/global/5/node_modules/.bin"
    ]
    
    func isToolInstalled(_ toolName: String) -> Bool {
        let normalizedName = toolName.lowercased()
        
        // Check cache first
        if let cached = toolStatus[normalizedName] {
            return cached
        }
        
        // Check fresh
        let aliases = toolAliases[normalizedName] ?? [toolName]
        
        for alias in aliases {
            if checkToolExists(alias) {
                toolStatus[normalizedName] = true
                return true
            }
        }
        
        toolStatus[normalizedName] = false
        return false
    }
    
    func refreshToolStatus() async {
        let currentTime = Date()
        
        // Don't refresh too frequently to avoid cycles
        if let lastRefresh = lastRefresh, currentTime.timeIntervalSince(lastRefresh) < 5.0 {
            return
        }
        
        await MainActor.run {
            lastRefresh = currentTime
        }
        
        let allTools = Array(toolAliases.keys)
        
        // Use TaskGroup for concurrent tool checking
        let newStatus: [String: Bool] = await withTaskGroup(of: (String, Bool).self) { group in
            var results: [String: Bool] = [:]
            
            for tool in allTools {
                group.addTask { [tool] in
                    let aliases = self.toolAliases[tool] ?? [tool]
                    var isInstalled = false
                    
                    for alias in aliases {
                        if self.checkToolExists(alias) {
                            isInstalled = true
                            break
                        }
                    }
                    
                    return (tool, isInstalled)
                }
            }
            
            for await (tool, isInstalled) in group {
                results[tool] = isInstalled
            }
            
            return results
        }
        
        await MainActor.run {
            toolStatus = newStatus
        }
    }
    
    func forceRefreshToolStatus() async {
        await refreshToolStatus()
    }
    
    func installTool(_ toolName: String) async -> Bool {
        guard !isToolInstalled(toolName) else { return true }
        
        let brewPackage = getBrewPackage(for: toolName)
        
        return await withCheckedContinuation { continuation in
            let process = Process()
            
            // Try different Homebrew locations
            if FileManager.default.fileExists(atPath: "/opt/homebrew/bin/brew") {
                process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/brew")
            } else if FileManager.default.fileExists(atPath: "/usr/local/bin/brew") {
                process.executableURL = URL(fileURLWithPath: "/usr/local/bin/brew")
            } else {
                continuation.resume(returning: false)
                return
            }
            
            process.arguments = ["install", brewPackage]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            process.terminationHandler = { _ in
                let success = process.terminationStatus == 0
                Task {
                    await MainActor.run {
                        self.toolStatus[toolName.lowercased()] = success
                    }
                }
                continuation.resume(returning: success)
            }
            
            do {
                try process.run()
            } catch {
                continuation.resume(returning: false)
            }
        }
    }
    
    private func getBrewPackage(for toolName: String) -> String {
        switch toolName.lowercased() {
        case "hydra": return "hydra"
        case "nmap": return "nmap"
        case "dirb": return "dirb"
        case "gobuster": return "gobuster"
        case "sqlmap": return "sqlmap"
        case "nikto": return "nikto"
        case "metasploit": return "metasploit"
        case "burpsuite", "burp-suite": return "burp-suite"
        case "wireshark": return "wireshark"
        case "john": return "john"
        default: return toolName
        }
    }
    
    private func checkToolExists(_ toolName: String) -> Bool {
        // First check using 'which' command
        if checkWithWhich(toolName) {
            return true
        }
        
        // Check common installation paths
        if checkInPaths(toolName) {
            return true
        }
        
        // Check for GUI applications
        if checkGUIApplication(toolName) {
            return true
        }
        
        // Check if it's a Python script that might be available via python3 -m
        if checkPythonModule(toolName) {
            return true
        }
        
        return false
    }
    
    private func checkWithWhich(_ toolName: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [toolName]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            
            return process.terminationStatus == 0 && !(output?.isEmpty ?? true)
        } catch {
            return false
        }
    }
    
    private func checkInPaths(_ toolName: String) -> Bool {
        for path in searchPaths {
            let expandedPath = NSString(string: path).expandingTildeInPath
            let fullPath = "\(expandedPath)/\(toolName)"
            
            if FileManager.default.fileExists(atPath: fullPath) {
                return true
            }
        }
        return false
    }
    
    private func checkGUIApplication(_ toolName: String) -> Bool {
        let guiApps = [
            "burp": ["Burp Suite Community Edition.app", "Burp Suite Professional.app"],
            "burpsuite": ["Burp Suite Community Edition.app", "Burp Suite Professional.app"],
            "burp-suite": ["Burp Suite Community Edition.app", "Burp Suite Professional.app"],
            "wireshark": ["Wireshark.app"]
        ]
        
        if let apps = guiApps[toolName.lowercased()] {
            for app in apps {
                let appPath = "/Applications/\(app)"
                if FileManager.default.fileExists(atPath: appPath) {
                    return true
                }
            }
        }
        
        return false
    }
    
    private func checkPythonModule(_ toolName: String) -> Bool {
        let pythonModules = ["sqlmap", "dirsearch", "sslyze"]
        
        if pythonModules.contains(toolName.lowercased()) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
            process.arguments = ["-m", toolName, "--help"]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            do {
                try process.run()
                process.waitUntilExit()
                return process.terminationStatus == 0
            } catch {
                return false
            }
        }
        
        return false
    }
    
    func getToolPath(_ toolName: String) -> String? {
        let aliases = toolAliases[toolName.lowercased()] ?? [toolName]
        
        for alias in aliases {
            if let path = getToolExecutablePath(alias) {
                return path
            }
        }
        
        return nil
    }
    
    private func getToolExecutablePath(_ toolName: String) -> String? {
        // Try 'which' first
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [toolName]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                return output?.isEmpty == false ? output : nil
            }
        } catch {
            // Fall through to manual search
        }
        
        // Manual search in common paths
        for path in searchPaths {
            let expandedPath = NSString(string: path).expandingTildeInPath
            let fullPath = "\(expandedPath)/\(toolName)"
            
            if FileManager.default.fileExists(atPath: fullPath) {
                return fullPath
            }
        }
        
        return nil
    }
    
    func getInstalledTools() -> [String] {
        return toolStatus.compactMap { key, value in
            value ? key : nil
        }
    }
    
    func getMissingTools() -> [String] {
        return toolStatus.compactMap { key, value in
            !value ? key : nil
        }
    }
    
    func getAllSupportedTools() -> [String] {
        return Array(toolAliases.keys).sorted()
    }
}
