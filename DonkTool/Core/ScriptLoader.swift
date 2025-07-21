//
//  ScriptLoader.swift
//  DonkTool
//
//  Custom script execution engine with auto-language detection
//

import Foundation
import SwiftUI

@Observable
class ScriptLoader {
    var isExecuting = false
    var output: [String] = []
    var scripts: [CustomScript] = []
    var selectedScript: CustomScript?
    
    func loadScript(from path: String) -> CustomScript? {
        guard FileManager.default.fileExists(atPath: path) else {
            return nil
        }
        
        let url = URL(fileURLWithPath: path)
        let name = url.deletingPathExtension().lastPathComponent
        let language = detectLanguage(from: url)
        
        return CustomScript(
            name: name,
            path: path,
            language: language,
            lastModified: getFileModificationDate(path) ?? Date()
        )
    }
    
    func detectLanguage(from url: URL) -> ScriptLanguage {
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "py":
            return .python
        case "sh", "bash":
            return .bash
        case "js":
            return .javascript
        case "rb":
            return .ruby
        case "pl":
            return .perl
        case "php":
            return .php
        case "swift":
            return .swift
        case "go":
            return .go
        case "rs":
            return .rust
        case "c":
            return .c
        case "cpp", "cc", "cxx":
            return .cpp
        case "java":
            return .java
        case "kt":
            return .kotlin
        case "ps1":
            return .powershell
        case "r":
            return .r
        case "lua":
            return .lua
        case "awk":
            return .awk
        case "sed":
            return .sed
        default:
            // Try to detect by shebang
            return detectByShebang(url) ?? .unknown
        }
    }
    
    private func detectByShebang(_ url: URL) -> ScriptLanguage? {
        guard let firstLine = try? String(contentsOf: url).components(separatedBy: .newlines).first else {
            return nil
        }
        
        if firstLine.hasPrefix("#!/") {
            let shebang = firstLine.lowercased()
            if shebang.contains("python") { return .python }
            if shebang.contains("bash") || shebang.contains("sh") { return .bash }
            if shebang.contains("node") { return .javascript }
            if shebang.contains("ruby") { return .ruby }
            if shebang.contains("perl") { return .perl }
            if shebang.contains("php") { return .php }
        }
        
        return nil
    }
    
    func executeScript(_ script: CustomScript, arguments: [String] = []) async {
        await MainActor.run {
            isExecuting = true
            output = []
            selectedScript = script
        }
        
        await runScript(script, with: arguments)
        
        await MainActor.run {
            isExecuting = false
        }
    }
    
    private func runScript(_ script: CustomScript, with arguments: [String]) async {
        let process = Process()
        let pipe = Pipe()
        let errorPipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = errorPipe
        
        // Set up execution based on language
        let (executable, args) = getExecutionCommand(for: script, with: arguments)
        
        guard let executablePath = executable else {
            await MainActor.run {
                output.append("❌ Interpreter not found for \(script.language.rawValue)")
            }
            return
        }
        
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = args
        
        // Set working directory to script location
        let scriptURL = URL(fileURLWithPath: script.path)
        process.currentDirectoryURL = scriptURL.deletingLastPathComponent()
        
        // Add initial output
        await MainActor.run {
            output.append("🚀 Executing: \(script.name)")
            output.append("📄 Language: \(script.language.rawValue)")
            output.append("📍 Path: \(script.path)")
            output.append("⚙️  Command: \(executablePath) \(args.joined(separator: " "))")
            output.append("")
            output.append(String(repeating: "=", count: 50))
            output.append("")
        }
        
        do {
            try process.run()
            
            // Create task for real-time stdout reading
            let stdoutTask = Task {
                let fileHandle = pipe.fileHandleForReading
                var buffer = Data()
                
                while process.isRunning {
                    let data = fileHandle.availableData
                    if !data.isEmpty {
                        buffer.append(data)
                        if let string = String(data: buffer, encoding: .utf8) {
                            let lines = string.components(separatedBy: .newlines)
                            if lines.count > 1 {
                                // Process complete lines
                                for line in lines.dropLast() {
                                    if !line.isEmpty {
                                        await MainActor.run {
                                            output.append(line)
                                        }
                                    }
                                }
                                // Keep the last incomplete line in buffer
                                buffer = lines.last?.data(using: .utf8) ?? Data()
                            }
                        }
                    }
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                }
                
                // Process any remaining data
                if !buffer.isEmpty, let finalString = String(data: buffer, encoding: .utf8), !finalString.isEmpty {
                    await MainActor.run {
                        output.append(finalString)
                    }
                }
            }
            
            // Create task for real-time stderr reading
            let stderrTask = Task {
                let fileHandle = errorPipe.fileHandleForReading
                while process.isRunning {
                    let data = fileHandle.availableData
                    if !data.isEmpty, let string = String(data: data, encoding: .utf8) {
                        let lines = string.components(separatedBy: .newlines).filter { !$0.isEmpty }
                        for line in lines {
                            await MainActor.run {
                                output.append("⚠️ \(line)")
                            }
                        }
                    }
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                }
            }
            
            process.waitUntilExit()
            
            // Cancel tasks
            stdoutTask.cancel()
            stderrTask.cancel()
            
            await MainActor.run {
                output.append("")
                output.append(String(repeating: "=", count: 50))
                let statusEmoji = process.terminationStatus == 0 ? "✅" : "❌"
                output.append("\(statusEmoji) Script completed with exit code: \(process.terminationStatus)")
            }
            
        } catch {
            await MainActor.run {
                output.append("❌ Execution failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func getExecutionCommand(for script: CustomScript, with arguments: [String]) -> (String?, [String]) {
        let args = [script.path] + arguments
        
        switch script.language {
        case .python:
            if let python = findExecutable("python3") {
                return (python, args)
            } else if let python = findExecutable("python") {
                return (python, args)
            }
            return (nil, [])
            
        case .bash:
            if let bash = findExecutable("bash") {
                return (bash, args)
            } else if let sh = findExecutable("sh") {
                return (sh, args)
            }
            return (nil, [])
            
        case .javascript:
            if let node = findExecutable("node") {
                return (node, args)
            }
            return (nil, [])
            
        case .ruby:
            if let ruby = findExecutable("ruby") {
                return (ruby, args)
            }
            return (nil, [])
            
        case .perl:
            if let perl = findExecutable("perl") {
                return (perl, args)
            }
            return (nil, [])
            
        case .php:
            if let php = findExecutable("php") {
                return (php, args)
            }
            return (nil, [])
            
        case .swift:
            if let swift = findExecutable("swift") {
                return (swift, args)
            }
            return (nil, [])
            
        case .go:
            if let go = findExecutable("go") {
                return (go, ["run"] + args)
            }
            return (nil, [])
            
        case .rust:
            // Rust needs compilation first
            if let rustc = findExecutable("rustc") {
                // This is simplified - real implementation would compile first
                return (rustc, ["--edition", "2021"] + args)
            }
            return (nil, [])
            
        case .java:
            if let java = findExecutable("java") {
                // This is simplified - real implementation would compile first
                return (java, args)
            }
            return (nil, [])
            
        case .powershell:
            if let pwsh = findExecutable("pwsh") {
                return (pwsh, ["-File"] + args)
            } else if let powershell = findExecutable("powershell") {
                return (powershell, ["-File"] + args)
            }
            return (nil, [])
            
        case .r:
            if let rscript = findExecutable("Rscript") {
                return (rscript, args)
            }
            return (nil, [])
            
        case .lua:
            if let lua = findExecutable("lua") {
                return (lua, args)
            }
            return (nil, [])
            
        case .awk:
            if let awk = findExecutable("awk") {
                return (awk, ["-f"] + args)
            }
            return (nil, [])
            
        case .sed:
            if let sed = findExecutable("sed") {
                return (sed, ["-f"] + args)
            }
            return (nil, [])
            
        case .unknown:
            // Try to make it executable and run directly
            let _ = makeExecutable(script.path)
            return (script.path, arguments)
            
        default:
            return (nil, [])
        }
    }
    
    private func findExecutable(_ name: String) -> String? {
        let paths = [
            "/usr/bin/\(name)",
            "/usr/local/bin/\(name)",
            "/opt/homebrew/bin/\(name)",
            "/bin/\(name)",
            "/usr/sbin/\(name)"
        ]
        
        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        // Try using 'which' command
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [name]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !path.isEmpty {
                    return path
                }
            }
        } catch {
            // Silently fail
        }
        
        return nil
    }
    
    private func makeExecutable(_ path: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/chmod")
        process.arguments = ["+x", path]
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    private func getFileModificationDate(_ path: String) -> Date? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            return attributes[.modificationDate] as? Date
        } catch {
            return nil
        }
    }
    
    func refreshScripts(in directory: String) {
        scripts.removeAll()
        
        guard let enumerator = FileManager.default.enumerator(atPath: directory) else {
            return
        }
        
        while let file = enumerator.nextObject() as? String {
            let fullPath = "\(directory)/\(file)"
            
            // Skip directories and hidden files
            if file.hasPrefix(".") || file.contains("/") {
                continue
            }
            
            if let script = loadScript(from: fullPath) {
                scripts.append(script)
            }
        }
        
        scripts.sort { $0.name < $1.name }
    }
    
    func clearOutput() {
        output.removeAll()
    }
}

// MARK: - Data Models

struct CustomScript: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let language: ScriptLanguage
    let lastModified: Date
    
    var fileSize: String {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: path),
              let size = attributes[.size] as? Int64 else {
            return "Unknown"
        }
        
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

enum ScriptLanguage: String, CaseIterable {
    case python = "Python"
    case bash = "Bash/Shell"
    case javascript = "JavaScript"
    case ruby = "Ruby"
    case perl = "Perl"
    case php = "PHP"
    case swift = "Swift"
    case go = "Go"
    case rust = "Rust"
    case c = "C"
    case cpp = "C++"
    case java = "Java"
    case kotlin = "Kotlin"
    case powershell = "PowerShell"
    case r = "R"
    case lua = "Lua"
    case awk = "AWK"
    case sed = "Sed"
    case unknown = "Unknown"
    
    var icon: String {
        switch self {
        case .python: return "🐍"
        case .bash: return "🐚"
        case .javascript: return "🟨"
        case .ruby: return "💎"
        case .perl: return "🐪"
        case .php: return "🐘"
        case .swift: return "🦉"
        case .go: return "🐹"
        case .rust: return "🦀"
        case .c: return "⚙️"
        case .cpp: return "⚙️"
        case .java: return "☕"
        case .kotlin: return "🎯"
        case .powershell: return "💙"
        case .r: return "📊"
        case .lua: return "🌙"
        case .awk: return "🔧"
        case .sed: return "✂️"
        case .unknown: return "❓"
        }
    }
    
    var color: Color {
        switch self {
        case .python: return .blue
        case .bash: return .green
        case .javascript: return .yellow
        case .ruby: return .red
        case .perl: return .purple
        case .php: return .indigo
        case .swift: return .orange
        case .go: return .cyan
        case .rust: return .brown
        case .c, .cpp: return .gray
        case .java: return .brown
        case .kotlin: return .purple
        case .powershell: return .blue
        case .r: return .blue
        case .lua: return .indigo
        case .awk, .sed: return .secondary
        case .unknown: return .secondary
        }
    }
}

struct ScriptExecutionResult {
    let success: Bool
    let output: [String]
    let exitCode: Int
}

