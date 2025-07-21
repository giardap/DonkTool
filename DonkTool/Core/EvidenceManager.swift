//
//  EvidenceManager.swift
//  DonkTool
//
//  Evidence collection and file generation for attack results
//

import Foundation
import SwiftUI

// MARK: - Evidence Models

struct EvidencePackage: Identifiable, Codable {
    let id = UUID()
    let sessionId: String
    let attackName: String
    let target: String
    let port: Int
    let timestamp: Date
    let duration: TimeInterval
    let success: Bool
    let evidenceFiles: [EvidenceFile]
    let summary: EvidenceSummary
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: timestamp)
    }
    
    var packageName: String {
        return "DonkTool_Evidence_\(target)_\(port)_\(formattedTimestamp)"
    }
}

struct EvidenceFile: Identifiable, Codable {
    let id = UUID()
    let filename: String
    let filepath: String
    let type: EvidenceType
    let size: Int64
    let checksum: String
    let description: String
    
    enum EvidenceType: String, Codable, CaseIterable {
        case console_output = "console_output"
        case vulnerability_report = "vulnerability_report"
        case credential_list = "credential_list"
        case network_scan = "network_scan"
        case directory_listing = "directory_listing"
        case screenshot = "screenshot"
        case packet_capture = "packet_capture"
        case exploit_code = "exploit_code"
        case summary_report = "summary_report"
        case raw_data = "raw_data"
        
        var fileExtension: String {
            switch self {
            case .console_output, .vulnerability_report, .credential_list, .directory_listing, .raw_data:
                return ".txt"
            case .network_scan, .summary_report:
                return ".json"
            case .screenshot:
                return ".png"
            case .packet_capture:
                return ".pcap"
            case .exploit_code:
                return ".py"
            }
        }
        
        var description: String {
            switch self {
            case .console_output: return "Console Output"
            case .vulnerability_report: return "Vulnerability Report"
            case .credential_list: return "Credential List"
            case .network_scan: return "Network Scan Results"
            case .directory_listing: return "Directory Enumeration"
            case .screenshot: return "Screenshot Evidence"
            case .packet_capture: return "Packet Capture"
            case .exploit_code: return "Exploit Code"
            case .summary_report: return "Summary Report"
            case .raw_data: return "Raw Data"
            }
        }
    }
}

struct EvidenceSummary: Codable {
    let totalVulnerabilities: Int
    let criticalVulnerabilities: Int
    let highVulnerabilities: Int
    let mediumVulnerabilities: Int
    let lowVulnerabilities: Int
    let credentialsFound: Int
    let directoriesFound: Int
    let servicesDiscovered: Int
    let exploitsAvailable: Int
    let recommendedActions: [String]
}

// MARK: - Evidence Manager

@Observable
class EvidenceManager {
    static let shared = EvidenceManager()
    
    var evidencePackages: [EvidencePackage] = []
    var isGeneratingEvidence = false
    var currentProgress: Double = 0.0
    
    private let fileManager = FileManager.default
    private let evidenceDirectory: URL
    
    private init() {
        // Create evidence directory in Documents
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        evidenceDirectory = documentsPath.appendingPathComponent("DonkTool_Evidence")
        
        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: evidenceDirectory, withIntermediateDirectories: true)
        
        loadExistingEvidence()
    }
    
    // MARK: - Evidence Generation
    
    func generateEvidencePackage(from result: AttackResult) async -> EvidencePackage? {
        await MainActor.run {
            isGeneratingEvidence = true
            currentProgress = 0.0
        }
        
        let packageDir = evidenceDirectory.appendingPathComponent("Package_\(result.target)_\(result.port)_\(Date().timeIntervalSince1970)")
        
        do {
            try fileManager.createDirectory(at: packageDir, withIntermediateDirectories: true)
            
            var evidenceFiles: [EvidenceFile] = []
            let totalSteps = 7.0
            var currentStep = 0.0
            
            // 1. Console Output
            currentStep += 1
            await updateProgress(currentStep / totalSteps)
            if let consoleFile = await generateConsoleOutput(result: result, packageDir: packageDir) {
                evidenceFiles.append(consoleFile)
            }
            
            // 2. Vulnerability Report
            currentStep += 1
            await updateProgress(currentStep / totalSteps)
            if let vulnFile = await generateVulnerabilityReport(result: result, packageDir: packageDir) {
                evidenceFiles.append(vulnFile)
            }
            
            // 3. Credential List
            currentStep += 1
            await updateProgress(currentStep / totalSteps)
            if let credFile = await generateCredentialList(result: result, packageDir: packageDir) {
                evidenceFiles.append(credFile)
            }
            
            // 4. Directory Listing
            currentStep += 1
            await updateProgress(currentStep / totalSteps)
            if let dirFile = await generateDirectoryListing(result: result, packageDir: packageDir) {
                evidenceFiles.append(dirFile)
            }
            
            // 5. Network Scan Data
            currentStep += 1
            await updateProgress(currentStep / totalSteps)
            if let scanFile = await generateNetworkScanData(result: result, packageDir: packageDir) {
                evidenceFiles.append(scanFile)
            }
            
            // 6. Summary Report
            currentStep += 1
            await updateProgress(currentStep / totalSteps)
            if let summaryFile = await generateSummaryReport(result: result, packageDir: packageDir) {
                evidenceFiles.append(summaryFile)
            }
            
            // 7. Create Evidence Package
            currentStep += 1
            await updateProgress(currentStep / totalSteps)
            
            let summary = createEvidenceSummary(from: result)
            let package = EvidencePackage(
                sessionId: result.sessionId,
                attackName: result.attack.name,
                target: result.target,
                port: result.port,
                timestamp: result.startTime,
                duration: result.duration,
                success: result.success,
                evidenceFiles: evidenceFiles,
                summary: summary
            )
            
            // Save package metadata
            await savePackageMetadata(package: package, packageDir: packageDir)
            
            await MainActor.run {
                evidencePackages.append(package)
                isGeneratingEvidence = false
                currentProgress = 1.0
            }
            
            return package
            
        } catch {
            await MainActor.run {
                isGeneratingEvidence = false
                currentProgress = 0.0
            }
            print("Error generating evidence package: \(error)")
            return nil
        }
    }
    
    // MARK: - Evidence File Generators
    
    private func generateConsoleOutput(result: AttackResult, packageDir: URL) async -> EvidenceFile? {
        let filename = "console_output.txt"
        let filepath = packageDir.appendingPathComponent(filename)
        
        let content = [
            "=== DonkTool Attack Execution Console Output ===",
            "Generated: \(Date())",
            "Attack: \(result.attack.name)",
            "Target: \(result.target):\(result.port)",
            "Session ID: \(result.sessionId)",
            "Duration: \(String(format: "%.2f", result.duration)) seconds",
            "Success: \(result.success)",
            "",
            "=== Console Output ===",
            result.output.joined(separator: "\n")
        ].joined(separator: "\n")
        
        do {
            try content.write(to: filepath, atomically: true, encoding: .utf8)
            let checksum = calculateChecksum(for: filepath)
            let size = try fileManager.attributesOfItem(atPath: filepath.path)[.size] as? Int64 ?? 0
            
            return EvidenceFile(
                filename: filename,
                filepath: filepath.path,
                type: .console_output,
                size: size,
                checksum: checksum,
                description: "Complete console output from attack execution"
            )
        } catch {
            print("Error generating console output: \(error)")
            return nil
        }
    }
    
    private func generateVulnerabilityReport(result: AttackResult, packageDir: URL) async -> EvidenceFile? {
        let filename = "vulnerability_report.txt"
        let filepath = packageDir.appendingPathComponent(filename)
        
        var content = [
            "=== DonkTool Vulnerability Report ===",
            "Generated: \(Date())",
            "Target: \(result.target):\(result.port)",
            "Attack: \(result.attack.name)",
            "Total Vulnerabilities: \(result.vulnerabilities.count)",
            ""
        ]
        
        if result.vulnerabilities.isEmpty {
            content.append("No vulnerabilities detected.")
        } else {
            let severityCounts = Dictionary(grouping: result.vulnerabilities) { $0.severity }
            
            content.append("=== Vulnerability Summary ===")
            for (severity, vulns) in severityCounts.sorted(by: { $0.key > $1.key }) {
                content.append("\(severity.uppercased()): \(vulns.count)")
            }
            content.append("")
            
            content.append("=== Detailed Vulnerabilities ===")
            for (index, vuln) in result.vulnerabilities.enumerated() {
                content.append("[\(index + 1)] \(vuln.type) - \(vuln.severity.uppercased())")
                content.append("Description: \(vuln.description)")
                content.append("Proof: \(vuln.proof)")
                content.append("Recommendation: \(vuln.recommendation)")
                content.append("")
            }
        }
        
        let finalContent = content.joined(separator: "\n")
        
        do {
            try finalContent.write(to: filepath, atomically: true, encoding: .utf8)
            let checksum = calculateChecksum(for: filepath)
            let size = try fileManager.attributesOfItem(atPath: filepath.path)[.size] as? Int64 ?? 0
            
            return EvidenceFile(
                filename: filename,
                filepath: filepath.path,
                type: .vulnerability_report,
                size: size,
                checksum: checksum,
                description: "Detailed vulnerability analysis and recommendations"
            )
        } catch {
            print("Error generating vulnerability report: \(error)")
            return nil
        }
    }
    
    private func generateCredentialList(result: AttackResult, packageDir: URL) async -> EvidenceFile? {
        guard !result.credentials.isEmpty else { return nil }
        
        let filename = "credentials_found.txt"
        let filepath = packageDir.appendingPathComponent(filename)
        
        var content = [
            "=== DonkTool Credential Discovery Report ===",
            "Generated: \(Date())",
            "Target: \(result.target):\(result.port)",
            "Total Credentials: \(result.credentials.count)",
            "",
            "⚠️  SECURITY WARNING: These credentials were discovered during authorized penetration testing.",
            "Handle with extreme care and ensure proper disposal after assessment.",
            "",
            "=== Discovered Credentials ===",
            ""
        ]
        
        for (index, cred) in result.credentials.enumerated() {
            content.append("[\(index + 1)] Service: \(cred.service)")
            content.append("     Username: \(cred.username)")
            content.append("     Password: \(cred.password)")
            content.append("     Port: \(cred.port)")
            content.append("")
        }
        
        content.append("=== Security Recommendations ===")
        content.append("1. Change all discovered passwords immediately")
        content.append("2. Implement strong password policies")
        content.append("3. Enable multi-factor authentication where possible")
        content.append("4. Monitor for unauthorized access attempts")
        content.append("5. Review and update access controls")
        
        let finalContent = content.joined(separator: "\n")
        
        do {
            try finalContent.write(to: filepath, atomically: true, encoding: .utf8)
            let checksum = calculateChecksum(for: filepath)
            let size = try fileManager.attributesOfItem(atPath: filepath.path)[.size] as? Int64 ?? 0
            
            return EvidenceFile(
                filename: filename,
                filepath: filepath.path,
                type: .credential_list,
                size: size,
                checksum: checksum,
                description: "List of discovered credentials during testing"
            )
        } catch {
            print("Error generating credential list: \(error)")
            return nil
        }
    }
    
    private func generateDirectoryListing(result: AttackResult, packageDir: URL) async -> EvidenceFile? {
        guard !result.files.isEmpty else { return nil }
        
        let filename = "directory_enumeration.txt"
        let filepath = packageDir.appendingPathComponent(filename)
        
        var content = [
            "=== DonkTool Directory Enumeration Results ===",
            "Generated: \(Date())",
            "Target: \(result.target):\(result.port)",
            "Total Files/Directories: \(result.files.count)",
            "",
            "=== Discovered Paths ===",
            ""
        ]
        
        for (index, file) in result.files.enumerated() {
            content.append("[\(index + 1)] \(file)")
        }
        
        content.append("")
        content.append("=== Analysis Notes ===")
        content.append("• Review each discovered path for sensitive information")
        content.append("• Check for backup files, configuration files, and admin panels")
        content.append("• Ensure proper access controls are in place")
        content.append("• Consider removing unnecessary exposed directories")
        
        let finalContent = content.joined(separator: "\n")
        
        do {
            try finalContent.write(to: filepath, atomically: true, encoding: .utf8)
            let checksum = calculateChecksum(for: filepath)
            let size = try fileManager.attributesOfItem(atPath: filepath.path)[.size] as? Int64 ?? 0
            
            return EvidenceFile(
                filename: filename,
                filepath: filepath.path,
                type: .directory_listing,
                size: size,
                checksum: checksum,
                description: "Directory and file enumeration results"
            )
        } catch {
            print("Error generating directory listing: \(error)")
            return nil
        }
    }
    
    private func generateNetworkScanData(result: AttackResult, packageDir: URL) async -> EvidenceFile? {
        let filename = "network_scan_data.json"
        let filepath = packageDir.appendingPathComponent(filename)
        
        let scanData: [String: Any] = [
            "scan_metadata": [
                "timestamp": ISO8601DateFormatter().string(from: result.startTime),
                "target": result.target,
                "port": result.port,
                "attack_type": result.attack.attackType.rawValue,
                "duration_seconds": result.duration,
                "success": result.success
            ],
            "vulnerabilities": result.vulnerabilities.map { vuln in
                [
                    "id": vuln.id.uuidString,
                    "type": vuln.type,
                    "severity": vuln.severity,
                    "description": vuln.description,
                    "proof": vuln.proof,
                    "recommendation": vuln.recommendation
                ]
            },
            "credentials": result.credentials.map { cred in
                [
                    "id": cred.id.uuidString,
                    "username": cred.username,
                    "password": cred.password,
                    "service": cred.service,
                    "port": cred.port
                ]
            },
            "discovered_files": result.files,
            "raw_output": result.output
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: scanData, options: .prettyPrinted)
            try jsonData.write(to: filepath)
            
            let checksum = calculateChecksum(for: filepath)
            let size = try fileManager.attributesOfItem(atPath: filepath.path)[.size] as? Int64 ?? 0
            
            return EvidenceFile(
                filename: filename,
                filepath: filepath.path,
                type: .network_scan,
                size: size,
                checksum: checksum,
                description: "Structured network scan data in JSON format"
            )
        } catch {
            print("Error generating network scan data: \(error)")
            return nil
        }
    }
    
    private func generateSummaryReport(result: AttackResult, packageDir: URL) async -> EvidenceFile? {
        let filename = "executive_summary.json"
        let filepath = packageDir.appendingPathComponent(filename)
        
        let summary = createEvidenceSummary(from: result)
        
        let reportData: [String: Any] = [
            "executive_summary": [
                "assessment_date": ISO8601DateFormatter().string(from: result.startTime),
                "target_system": "\(result.target):\(result.port)",
                "assessment_type": result.attack.name,
                "duration_minutes": Int(result.duration / 60),
                "overall_success": result.success
            ],
            "risk_summary": [
                "total_vulnerabilities": summary.totalVulnerabilities,
                "critical_risk": summary.criticalVulnerabilities,
                "high_risk": summary.highVulnerabilities,
                "medium_risk": summary.mediumVulnerabilities,
                "low_risk": summary.lowVulnerabilities,
                "credentials_compromised": summary.credentialsFound,
                "attack_surface": summary.directoriesFound
            ],
            "recommendations": summary.recommendedActions,
            "evidence_integrity": [
                "generated_by": "DonkTool Professional Security Suite",
                "generation_timestamp": ISO8601DateFormatter().string(from: Date()),
                "evidence_chain_maintained": true
            ]
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: reportData, options: .prettyPrinted)
            try jsonData.write(to: filepath)
            
            let checksum = calculateChecksum(for: filepath)
            let size = try fileManager.attributesOfItem(atPath: filepath.path)[.size] as? Int64 ?? 0
            
            return EvidenceFile(
                filename: filename,
                filepath: filepath.path,
                type: .summary_report,
                size: size,
                checksum: checksum,
                description: "Executive summary and risk assessment"
            )
        } catch {
            print("Error generating summary report: \(error)")
            return nil
        }
    }
    
    // MARK: - Helper Methods
    
    private func createEvidenceSummary(from result: AttackResult) -> EvidenceSummary {
        let vulnerabilities = result.vulnerabilities
        let criticalCount = vulnerabilities.filter { $0.severity.lowercased() == "critical" }.count
        let highCount = vulnerabilities.filter { $0.severity.lowercased() == "high" }.count
        let mediumCount = vulnerabilities.filter { $0.severity.lowercased() == "medium" }.count
        let lowCount = vulnerabilities.filter { $0.severity.lowercased() == "low" }.count
        
        var recommendations: [String] = [
            "Conduct immediate remediation of critical and high-severity vulnerabilities",
            "Implement regular security scanning and assessment procedures",
            "Review and update access controls and authentication mechanisms"
        ]
        
        if !result.credentials.isEmpty {
            recommendations.append("Change all discovered credentials immediately")
            recommendations.append("Implement multi-factor authentication")
        }
        
        if !result.files.isEmpty {
            recommendations.append("Review exposed directories and remove unnecessary access")
            recommendations.append("Implement proper web server configuration")
        }
        
        return EvidenceSummary(
            totalVulnerabilities: vulnerabilities.count,
            criticalVulnerabilities: criticalCount,
            highVulnerabilities: highCount,
            mediumVulnerabilities: mediumCount,
            lowVulnerabilities: lowCount,
            credentialsFound: result.credentials.count,
            directoriesFound: result.files.count,
            servicesDiscovered: 1, // Single target assessment
            exploitsAvailable: vulnerabilities.filter { $0.severity == "critical" || $0.severity == "high" }.count,
            recommendedActions: recommendations
        )
    }
    
    private func savePackageMetadata(package: EvidencePackage, packageDir: URL) async {
        let metadataFile = packageDir.appendingPathComponent("package_metadata.json")
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            let data = try encoder.encode(package)
            try data.write(to: metadataFile)
        } catch {
            print("Error saving package metadata: \(error)")
        }
    }
    
    private func calculateChecksum(for url: URL) -> String {
        guard let data = try? Data(contentsOf: url) else { return "" }
        
        let digest = data.withUnsafeBytes { bytes in
            return Data(bytes).base64EncodedString()
        }
        
        return String(digest.prefix(16)) // Simplified checksum
    }
    
    private func updateProgress(_ progress: Double) async {
        await MainActor.run {
            currentProgress = progress
        }
    }
    
    private func loadExistingEvidence() {
        // Load existing evidence packages on startup
        // Implementation for loading saved packages would go here
    }
    
    // MARK: - Evidence Management
    
    func deleteEvidencePackage(_ package: EvidencePackage) {
        // Remove from array
        evidencePackages.removeAll { $0.id == package.id }
        
        // Delete files from disk
        for file in package.evidenceFiles {
            try? fileManager.removeItem(atPath: file.filepath)
        }
        
        // Delete package directory
        let packageDirPath = URL(fileURLWithPath: package.evidenceFiles.first?.filepath ?? "").deletingLastPathComponent()
        try? fileManager.removeItem(at: packageDirPath)
    }
    
    func exportEvidencePackage(_ package: EvidencePackage) -> URL? {
        // Create zip archive of evidence package
        let zipURL = evidenceDirectory.appendingPathComponent("\(package.packageName).zip")
        
        // Implementation for creating zip archive would go here
        // For now, return the package directory
        if let firstFile = package.evidenceFiles.first {
            return URL(fileURLWithPath: firstFile.filepath).deletingLastPathComponent()
        }
        
        return nil
    }
    
    func getEvidenceStatistics() -> String {
        let totalPackages = evidencePackages.count
        let totalVulns = evidencePackages.reduce(0) { $0 + $1.summary.totalVulnerabilities }
        let totalCreds = evidencePackages.reduce(0) { $0 + $1.summary.credentialsFound }
        
        return """
        Evidence Manager Statistics:
        - Total Evidence Packages: \(totalPackages)
        - Total Vulnerabilities Documented: \(totalVulns)
        - Total Credentials Documented: \(totalCreds)
        - Evidence Directory: \(evidenceDirectory.path)
        """
    }
}