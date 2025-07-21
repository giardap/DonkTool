//
//  SearchSploitManager.swift
//  DonkTool
//
//  SearchSploit integration for real exploit payload retrieval
//

import Foundation
import SwiftUI

// MARK: - SearchSploit Manager

@Observable
class SearchSploitManager {
    var isSearching = false
    var lastSearchResults: [ExploitEntry] = []
    var searchError: String?
    
    private let searchSploitPath = "/opt/homebrew/bin/searchsploit"
    private let exploitDBPath = "/opt/homebrew/share/exploitdb"
    
    // MARK: - Search Functions
    
    func searchExploits(for cveId: String) async -> [ExploitEntry] {
        isSearching = true
        searchError = nil
        
        do {
            let results = try await executeSearchSploit(query: cveId)
            await MainActor.run {
                self.lastSearchResults = results
                self.isSearching = false
            }
            return results
        } catch {
            await MainActor.run {
                self.searchError = error.localizedDescription
                self.isSearching = false
                self.lastSearchResults = []
            }
            return []
        }
    }
    
    func searchExploitsByKeyword(_ keyword: String) async -> [ExploitEntry] {
        isSearching = true
        searchError = nil
        
        do {
            let results = try await executeSearchSploit(query: keyword)
            await MainActor.run {
                self.lastSearchResults = results
                self.isSearching = false
            }
            return results
        } catch {
            await MainActor.run {
                self.searchError = error.localizedDescription
                self.isSearching = false
                self.lastSearchResults = []
            }
            return []
        }
    }
    
    func getExploitCode(for exploit: ExploitEntry) async -> String? {
        guard !exploit.path.isEmpty else { return nil }
        
        let fullPath = "\(exploitDBPath)/\(exploit.path)"
        
        do {
            let content = try String(contentsOfFile: fullPath, encoding: .utf8)
            return content
        } catch {
            print("Error reading exploit file: \(error)")
            return nil
        }
    }
    
    // MARK: - Bluetooth-Specific Searches
    
    func searchBluetoothExploits() async -> [ExploitEntry] {
        let bluetoothKeywords = ["bluetooth", "blueborne", "knob", "bias", "ble", "rfcomm", "l2cap", "sdp"]
        var allResults: [ExploitEntry] = []
        
        for keyword in bluetoothKeywords {
            let results = await searchExploitsByKeyword(keyword)
            allResults.append(contentsOf: results)
        }
        
        // Remove duplicates based on path
        let uniqueResults = Array(Set(allResults))
        return uniqueResults.sorted { $0.title < $1.title }
    }
    
    func searchForCVE(_ cveId: String) async -> [ExploitEntry] {
        // Search for both CVE-YYYY-NNNN and YYYY-NNNN formats
        let normalizedCVE = cveId.uppercased()
        let shortCVE = normalizedCVE.replacingOccurrences(of: "CVE-", with: "")
        
        var allResults: [ExploitEntry] = []
        
        // Search with full CVE ID
        allResults.append(contentsOf: await searchExploits(for: normalizedCVE))
        
        // Search with short format if different
        if shortCVE != normalizedCVE {
            allResults.append(contentsOf: await searchExploits(for: shortCVE))
        }
        
        // Remove duplicates
        let uniqueResults = Array(Set(allResults))
        return uniqueResults
    }
    
    // MARK: - Installation Check
    
    func checkSearchSploitInstallation() -> SearchSploitStatus {
        // Check if searchsploit binary exists
        guard FileManager.default.fileExists(atPath: searchSploitPath) else {
            return .notInstalled
        }
        
        // Check if exploit database exists
        guard FileManager.default.fileExists(atPath: exploitDBPath) else {
            return .dbMissing
        }
        
        return .installed
    }
    
    func installSearchSploit() async -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/brew")
        process.arguments = ["install", "exploitdb"]
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            print("Failed to install SearchSploit: \(error)")
            return false
        }
    }
    
    // MARK: - Private Implementation
    
    private func executeSearchSploit(query: String) async throws -> [ExploitEntry] {
        guard checkSearchSploitInstallation() == .installed else {
            throw SearchSploitError.notInstalled
        }
        
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        process.executableURL = URL(fileURLWithPath: searchSploitPath)
        process.arguments = [
            "--json",        // JSON output for parsing
            "--exclude", "dos",  // Exclude DOS exploits to focus on relevant ones
            query
        ]
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        
        guard process.terminationStatus == 0 else {
            throw SearchSploitError.searchFailed
        }
        
        return try parseSearchSploitOutput(data)
    }
    
    private func parseSearchSploitOutput(_ data: Data) throws -> [ExploitEntry] {
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw SearchSploitError.invalidOutput
        }
        
        // SearchSploit JSON output format
        struct SearchSploitResult: Codable {
            let RESULTS_EXPLOIT: [SearchSploitExploit]?
            let RESULTS_SHELLCODE: [SearchSploitExploit]?
        }
        
        struct SearchSploitExploit: Codable {
            let Title: String
            let EDB_ID: String
            let Date: String
            let Author: String
            let `Type`: String
            let Platform: String
            let Path: String
        }
        
        do {
            let result = try JSONDecoder().decode(SearchSploitResult.self, from: data)
            var exploits: [ExploitEntry] = []
            
            // Process exploits
            if let exploitResults = result.RESULTS_EXPLOIT {
                for exploit in exploitResults {
                    let entry = ExploitEntry(
                        id: exploit.EDB_ID,
                        title: exploit.Title,
                        author: exploit.Author,
                        date: exploit.Date,
                        type: exploit.Type,
                        platform: exploit.Platform,
                        path: exploit.Path,
                        category: .exploit
                    )
                    exploits.append(entry)
                }
            }
            
            // Process shellcode
            if let shellcodeResults = result.RESULTS_SHELLCODE {
                for shellcode in shellcodeResults {
                    let entry = ExploitEntry(
                        id: shellcode.EDB_ID,
                        title: shellcode.Title,
                        author: shellcode.Author,
                        date: shellcode.Date,
                        type: shellcode.Type,
                        platform: shellcode.Platform,
                        path: shellcode.Path,
                        category: .shellcode
                    )
                    exploits.append(entry)
                }
            }
            
            return exploits
        } catch {
            print("JSON parsing error: \(error)")
            print("Raw output: \(jsonString)")
            throw SearchSploitError.parsingFailed
        }
    }
}

// MARK: - Data Models

struct ExploitEntry: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let author: String
    let date: String
    let type: String
    let platform: String
    let path: String
    let category: ExploitCategory
    
    enum ExploitCategory: String, Codable, CaseIterable {
        case exploit = "exploit"
        case shellcode = "shellcode"
        case paper = "paper"
        case tool = "tool"
        
        var icon: String {
            switch self {
            case .exploit: return "bolt.fill"
            case .shellcode: return "terminal.fill"
            case .paper: return "doc.text.fill"
            case .tool: return "wrench.and.screwdriver.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .exploit: return .red
            case .shellcode: return .orange
            case .paper: return .blue
            case .tool: return .green
            }
        }
    }
    
    var severity: ExploitSeverity {
        let lowerTitle = title.lowercased()
        if lowerTitle.contains("remote") && lowerTitle.contains("code") {
            return .critical
        } else if lowerTitle.contains("privilege") || lowerTitle.contains("escalation") {
            return .high
        } else if lowerTitle.contains("denial") || lowerTitle.contains("dos") {
            return .medium
        } else {
            return .low
        }
    }
    
    enum ExploitSeverity: String, CaseIterable {
        case critical = "critical"
        case high = "high"
        case medium = "medium"
        case low = "low"
        
        var color: Color {
            switch self {
            case .critical: return .red
            case .high: return .orange
            case .medium: return .yellow
            case .low: return .green
            }
        }
    }
}

enum SearchSploitStatus {
    case installed
    case notInstalled
    case dbMissing
    
    var description: String {
        switch self {
        case .installed: return "SearchSploit is installed and ready"
        case .notInstalled: return "SearchSploit not installed"
        case .dbMissing: return "SearchSploit installed but database missing"
        }
    }
    
    var icon: String {
        switch self {
        case .installed: return "checkmark.circle.fill"
        case .notInstalled: return "xmark.circle.fill"
        case .dbMissing: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .installed: return .green
        case .notInstalled: return .red
        case .dbMissing: return .orange
        }
    }
}

enum SearchSploitError: Error, LocalizedError {
    case notInstalled
    case searchFailed
    case invalidOutput
    case parsingFailed
    
    var errorDescription: String? {
        switch self {
        case .notInstalled:
            return "SearchSploit is not installed. Install with: brew install exploitdb"
        case .searchFailed:
            return "SearchSploit search failed"
        case .invalidOutput:
            return "Invalid output from SearchSploit"
        case .parsingFailed:
            return "Failed to parse SearchSploit results"
        }
    }
}

// MARK: - Bluetooth CVE Integration

extension SearchSploitManager {
    func searchExploitsForBluetoothCVE(_ cve: LiveCVEEntry) async -> [ExploitEntry] {
        // Search for exploits related to this specific CVE
        var results = await searchForCVE(cve.id)
        
        // Also search for exploits related to affected products
        for product in cve.affectedProducts {
            let productResults = await searchExploitsByKeyword(product)
            results.append(contentsOf: productResults)
        }
        
        // Remove duplicates and sort by relevance
        let uniqueResults = Array(Set(results))
        return uniqueResults.sorted { exploit1, exploit2 in
            // Prioritize by severity and then by date
            if exploit1.severity != exploit2.severity {
                return exploit1.severity.rawValue < exploit2.severity.rawValue
            }
            return exploit1.date > exploit2.date
        }
    }
    
    func getRecommendedExploitsForTarget(_ deviceType: BluetoothDeviceClass) async -> [ExploitEntry] {
        let keywords: [String]
        
        switch deviceType {
        case .phone:
            keywords = ["android bluetooth", "ios bluetooth", "mobile bluetooth"]
        case .computer:
            keywords = ["windows bluetooth", "linux bluetooth", "macos bluetooth"]
        case .audio:
            keywords = ["bluetooth audio", "a2dp", "bluetooth headset"]
        case .automotive:
            keywords = ["car bluetooth", "automotive", "vehicle"]
        case .medical:
            keywords = ["medical bluetooth", "healthcare", "bluetooth medical"]
        case .iot:
            keywords = ["iot bluetooth", "smart device", "bluetooth iot"]
        default:
            keywords = ["bluetooth", "ble"]
        }
        
        var allResults: [ExploitEntry] = []
        for keyword in keywords {
            let results = await searchExploitsByKeyword(keyword)
            allResults.append(contentsOf: results)
        }
        
        return Array(Set(allResults)).sorted { $0.severity.rawValue < $1.severity.rawValue }
    }
}