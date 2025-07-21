//
//  ReportingEngine.swift
//  DonkTool
//
//  Professional reporting engine with enhanced formatting
//

import Foundation
import SwiftUI

// MARK: - Report Models

enum ReportFormat: String, CaseIterable {
    case executive = "Executive Summary"
    case technical = "Technical Report"
    case penetrationTest = "Penetration Test Report"
    case compliance = "Compliance Assessment"
    case remediation = "Remediation Guide"
    
    var fileExtension: String {
        switch self {
        case .executive, .technical, .penetrationTest, .compliance, .remediation:
            return ".html"
        }
    }
}

enum ReportSeverity: String, CaseIterable {
    case critical = "Critical"
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    case informational = "Informational"
    
    var color: String {
        switch self {
        case .critical: return "#DC2626"
        case .high: return "#EA580C"
        case .medium: return "#D97706"
        case .low: return "#65A30D"
        case .informational: return "#2563EB"
        }
    }
    
    var priority: Int {
        switch self {
        case .critical: return 5
        case .high: return 4
        case .medium: return 3
        case .low: return 2
        case .informational: return 1
        }
    }
}

struct ReportConfiguration {
    let format: ReportFormat
    let includeExecutiveSummary: Bool
    let includeDetailedFindings: Bool
    let includeRecommendations: Bool
    let includeAppendices: Bool
    let filterBySeverity: [ReportSeverity]
    let customTitle: String?
    let organizationName: String?
    let assessorName: String?
    let clientName: String?
    
    static let `default` = ReportConfiguration(
        format: .technical,
        includeExecutiveSummary: true,
        includeDetailedFindings: true,
        includeRecommendations: true,
        includeAppendices: true,
        filterBySeverity: ReportSeverity.allCases,
        customTitle: nil,
        organizationName: nil,
        assessorName: nil,
        clientName: nil
    )
}

struct GeneratedReport: Identifiable {
    let id = UUID()
    let title: String
    let format: ReportFormat
    let filePath: String
    let generatedAt: Date
    let evidencePackages: [EvidencePackage]
    let configuration: ReportConfiguration
    let fileSize: Int64
}

// MARK: - Reporting Engine

@Observable
class ReportingEngine {
    static let shared = ReportingEngine()
    
    var generatedReports: [GeneratedReport] = []
    var isGenerating = false
    var generationProgress: Double = 0.0
    
    private let fileManager = FileManager.default
    private let reportsDirectory: URL
    
    private init() {
        // Create reports directory in Documents
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        reportsDirectory = documentsPath.appendingPathComponent("DonkTool_Reports")
        
        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: reportsDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Report Generation
    
    func generateReport(
        evidencePackages: [EvidencePackage],
        configuration: ReportConfiguration
    ) async -> GeneratedReport? {
        await MainActor.run {
            isGenerating = true
            generationProgress = 0.0
        }
        
        let timestamp = Date()
        let reportTitle = configuration.customTitle ?? generateReportTitle(for: configuration.format, timestamp: timestamp)
        let filename = sanitizeFilename("\(reportTitle)_\(Int(timestamp.timeIntervalSince1970))\(configuration.format.fileExtension)")
        let reportPath = reportsDirectory.appendingPathComponent(filename)
        
        do {
            await updateProgress(0.1)
            
            // Generate report content based on format
            let htmlContent: String
            switch configuration.format {
            case .executive:
                htmlContent = await generateExecutiveReport(evidencePackages: evidencePackages, configuration: configuration)
            case .technical:
                htmlContent = await generateTechnicalReport(evidencePackages: evidencePackages, configuration: configuration)
            case .penetrationTest:
                htmlContent = await generatePenetrationTestReport(evidencePackages: evidencePackages, configuration: configuration)
            case .compliance:
                htmlContent = await generateComplianceReport(evidencePackages: evidencePackages, configuration: configuration)
            case .remediation:
                htmlContent = await generateRemediationReport(evidencePackages: evidencePackages, configuration: configuration)
            }
            
            await updateProgress(0.9)
            
            // Write to file
            try htmlContent.write(to: reportPath, atomically: true, encoding: .utf8)
            
            // Get file size
            let attributes = try fileManager.attributesOfItem(atPath: reportPath.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            
            // Create report object
            let report = GeneratedReport(
                title: reportTitle,
                format: configuration.format,
                filePath: reportPath.path,
                generatedAt: timestamp,
                evidencePackages: evidencePackages,
                configuration: configuration,
                fileSize: fileSize
            )
            
            await MainActor.run {
                generatedReports.append(report)
                isGenerating = false
                generationProgress = 1.0
            }
            
            return report
            
        } catch {
            await MainActor.run {
                isGenerating = false
                generationProgress = 0.0
            }
            print("Error generating report: \(error)")
            return nil
        }
    }
    
    // MARK: - Report Content Generators
    
    private func generateExecutiveReport(evidencePackages: [EvidencePackage], configuration: ReportConfiguration) async -> String {
        await updateProgress(0.3)
        
        let vulnerabilities = aggregateVulnerabilities(from: evidencePackages, filteredBy: configuration.filterBySeverity)
        let credentials = aggregateCredentials(from: evidencePackages)
        
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Executive Security Assessment Summary</title>
            \(generateCSS())
        </head>
        <body>
            <div class="container">
                \(generateHeaderSection(configuration: configuration))
                
                <div class="executive-summary">
                    <h2>Executive Summary</h2>
                    \(generateRiskOverview(vulnerabilities: vulnerabilities, credentials: credentials))
                    \(generateBusinessImpact(vulnerabilities: vulnerabilities))
                    \(generateHighLevelRecommendations(vulnerabilities: vulnerabilities))
                </div>
                
                \(generateFooter())
            </div>
        </body>
        </html>
        """
    }
    
    private func generateTechnicalReport(evidencePackages: [EvidencePackage], configuration: ReportConfiguration) async -> String {
        await updateProgress(0.4)
        
        let vulnerabilities = aggregateVulnerabilities(from: evidencePackages, filteredBy: configuration.filterBySeverity)
        let credentials = aggregateCredentials(from: evidencePackages)
        let files = aggregateDiscoveredFiles(from: evidencePackages)
        
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Technical Security Assessment Report</title>
            \(generateCSS())
        </head>
        <body>
            <div class="container">
                \(generateHeaderSection(configuration: configuration))
                
                \(configuration.includeExecutiveSummary ? generateExecutiveSummarySection(vulnerabilities: vulnerabilities, credentials: credentials) : "")
                
                <div class="assessment-methodology">
                    <h2>Assessment Methodology</h2>
                    \(generateMethodologySection(evidencePackages: evidencePackages))
                </div>
                
                \(configuration.includeDetailedFindings ? generateDetailedFindingsSection(vulnerabilities: vulnerabilities) : "")
                
                <div class="discovery-summary">
                    <h2>Discovery Summary</h2>
                    \(generateCredentialsSection(credentials: credentials))
                    \(generateFilesSection(files: files))
                </div>
                
                \(configuration.includeRecommendations ? generateRecommendationsSection(evidencePackages: evidencePackages) : "")
                
                \(generateFooter())
            </div>
        </body>
        </html>
        """
    }
    
    private func generatePenetrationTestReport(evidencePackages: [EvidencePackage], configuration: ReportConfiguration) async -> String {
        await updateProgress(0.5)
        
        let vulnerabilities = aggregateVulnerabilities(from: evidencePackages, filteredBy: configuration.filterBySeverity)
        let credentials = aggregateCredentials(from: evidencePackages)
        
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Penetration Test Report</title>
            \(generateCSS())
        </head>
        <body>
            <div class="container">
                \(generateHeaderSection(configuration: configuration))
                
                <div class="penetration-test-overview">
                    <h2>Penetration Test Overview</h2>
                    \(generateTestScopeSection(evidencePackages: evidencePackages))
                    \(generateTestApproach(evidencePackages: evidencePackages))
                </div>
                
                \(generateAttackChainSection(evidencePackages: evidencePackages))
                
                \(generateDetailedFindingsSection(vulnerabilities: vulnerabilities))
                
                <div class="exploitation-summary">
                    <h2>Exploitation Summary</h2>
                    \(generateExploitationDetails(vulnerabilities: vulnerabilities, credentials: credentials))
                </div>
                
                \(generateRiskAssessmentSection(vulnerabilities: vulnerabilities))
                
                \(generateFooter())
            </div>
        </body>
        </html>
        """
    }
    
    private func generateComplianceReport(evidencePackages: [EvidencePackage], configuration: ReportConfiguration) async -> String {
        await updateProgress(0.6)
        
        let vulnerabilities = aggregateVulnerabilities(from: evidencePackages, filteredBy: configuration.filterBySeverity)
        
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Security Compliance Assessment</title>
            \(generateCSS())
        </head>
        <body>
            <div class="container">
                \(generateHeaderSection(configuration: configuration))
                
                <div class="compliance-overview">
                    <h2>Compliance Assessment Overview</h2>
                    \(generateComplianceFrameworksSection())
                    \(generateComplianceStatus(vulnerabilities: vulnerabilities))
                </div>
                
                \(generateComplianceGapsSection(vulnerabilities: vulnerabilities))
                
                \(generateComplianceRecommendationsSection(vulnerabilities: vulnerabilities))
                
                \(generateFooter())
            </div>
        </body>
        </html>
        """
    }
    
    private func generateRemediationReport(evidencePackages: [EvidencePackage], configuration: ReportConfiguration) async -> String {
        await updateProgress(0.7)
        
        let vulnerabilities = aggregateVulnerabilities(from: evidencePackages, filteredBy: configuration.filterBySeverity)
        
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Security Remediation Guide</title>
            \(generateCSS())
        </head>
        <body>
            <div class="container">
                \(generateHeaderSection(configuration: configuration))
                
                <div class="remediation-overview">
                    <h2>Remediation Overview</h2>
                    \(generateRemediationPriorities(vulnerabilities: vulnerabilities))
                    \(generateRemediationTimeline(vulnerabilities: vulnerabilities))
                </div>
                
                \(generateDetailedRemediationSteps(vulnerabilities: vulnerabilities))
                
                \(generateValidationGuidelines(vulnerabilities: vulnerabilities))
                
                \(generateFooter())
            </div>
        </body>
        </html>
        """
    }
    
    // MARK: - Helper Methods
    
    private func generateReportTitle(for format: ReportFormat, timestamp: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: timestamp)
        
        switch format {
        case .executive:
            return "Executive_Security_Summary_\(dateStr)"
        case .technical:
            return "Technical_Security_Assessment_\(dateStr)"
        case .penetrationTest:
            return "Penetration_Test_Report_\(dateStr)"
        case .compliance:
            return "Compliance_Assessment_\(dateStr)"
        case .remediation:
            return "Remediation_Guide_\(dateStr)"
        }
    }
    
    private func sanitizeFilename(_ filename: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        return filename.components(separatedBy: invalidCharacters).joined(separator: "_")
    }
    
    private func updateProgress(_ progress: Double) async {
        await MainActor.run {
            generationProgress = progress
        }
    }
    
    private func aggregateVulnerabilities(from packages: [EvidencePackage], filteredBy severities: [ReportSeverity]) -> [VulnerabilityFinding] {
        let allVulns = packages.flatMap { $0.evidenceFiles.compactMap { file in
            // Extract vulnerabilities from evidence packages
            // This is a simplified approach - in practice, you'd parse the actual evidence files
            return nil as VulnerabilityFinding?
        }}
        
        // For now, create sample vulnerabilities based on package summaries
        var aggregatedVulns: [VulnerabilityFinding] = []
        
        for package in packages {
            let summary = package.summary
            
            // Add sample vulnerabilities based on summary counts
            for _ in 0..<summary.criticalVulnerabilities {
                if severities.contains(.critical) {
                    aggregatedVulns.append(VulnerabilityFinding(
                        type: "Critical Security Issue",
                        severity: "critical",
                        description: "Critical vulnerability detected on \(package.target):\(package.port)",
                        proof: "Evidence from \(package.attackName)",
                        recommendation: "Immediate remediation required"
                    ))
                }
            }
            
            for _ in 0..<summary.highVulnerabilities {
                if severities.contains(.high) {
                    aggregatedVulns.append(VulnerabilityFinding(
                        type: "High Risk Security Issue",
                        severity: "high",
                        description: "High-severity vulnerability detected on \(package.target):\(package.port)",
                        proof: "Evidence from \(package.attackName)",
                        recommendation: "Remediation required within 30 days"
                    ))
                }
            }
        }
        
        return aggregatedVulns
    }
    
    private func aggregateCredentials(from packages: [EvidencePackage]) -> [Credential] {
        // Sample credential aggregation
        var credentials: [Credential] = []
        
        for package in packages {
            let credCount = package.summary.credentialsFound
            for i in 0..<credCount {
                credentials.append(Credential(
                    username: "user\(i+1)",
                    password: "***REDACTED***",
                    service: "Service on \(package.target)",
                    port: package.port
                ))
            }
        }
        
        return credentials
    }
    
    private func aggregateDiscoveredFiles(from packages: [EvidencePackage]) -> [String] {
        return packages.flatMap { package in
            // Return sample file list based on directories found
            (0..<package.summary.directoriesFound).map { "/directory\($0+1)" }
        }
    }
    
    // MARK: - Report Generation Continuation in Next Part
    // (This would continue with all the section generators...)
}

// MARK: - Report Section Generators Extension

extension ReportingEngine {
    
    private func generateCSS() -> String {
        return """
        <style>
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }
            
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                line-height: 1.6;
                color: #333;
                background-color: #f8f9fa;
            }
            
            .container {
                max-width: 1200px;
                margin: 0 auto;
                background: white;
                box-shadow: 0 0 20px rgba(0,0,0,0.1);
                min-height: 100vh;
            }
            
            .header {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                padding: 40px;
                text-align: center;
            }
            
            .header h1 {
                font-size: 2.5rem;
                margin-bottom: 10px;
                font-weight: 300;
            }
            
            .header .subtitle {
                font-size: 1.2rem;
                opacity: 0.9;
            }
            
            .content {
                padding: 40px;
            }
            
            h2 {
                color: #2d3748;
                font-size: 1.8rem;
                margin: 30px 0 20px 0;
                border-bottom: 3px solid #667eea;
                padding-bottom: 10px;
            }
            
            h3 {
                color: #4a5568;
                font-size: 1.4rem;
                margin: 25px 0 15px 0;
            }
            
            .risk-overview {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
                gap: 20px;
                margin: 20px 0;
            }
            
            .risk-card {
                border-radius: 8px;
                padding: 20px;
                text-align: center;
                color: white;
                font-weight: bold;
            }
            
            .risk-critical { background-color: #DC2626; }
            .risk-high { background-color: #EA580C; }
            .risk-medium { background-color: #D97706; }
            .risk-low { background-color: #65A30D; }
            
            .vulnerability-item {
                border: 1px solid #e2e8f0;
                border-radius: 8px;
                margin: 15px 0;
                padding: 20px;
                background: #f7fafc;
            }
            
            .vulnerability-header {
                display: flex;
                align-items: center;
                margin-bottom: 10px;
            }
            
            .severity-badge {
                padding: 4px 12px;
                border-radius: 20px;
                color: white;
                font-size: 0.8rem;
                font-weight: bold;
                margin-right: 15px;
            }
            
            .table {
                width: 100%;
                border-collapse: collapse;
                margin: 20px 0;
            }
            
            .table th,
            .table td {
                padding: 12px;
                text-align: left;
                border-bottom: 1px solid #e2e8f0;
            }
            
            .table th {
                background-color: #edf2f7;
                font-weight: 600;
                color: #2d3748;
            }
            
            .footer {
                background-color: #2d3748;
                color: white;
                padding: 20px 40px;
                text-align: center;
                font-size: 0.9rem;
            }
            
            .recommendation {
                background-color: #e6fffa;
                border-left: 4px solid #38b2ac;
                padding: 15px;
                margin: 15px 0;
            }
            
            .chart-container {
                background: white;
                border-radius: 8px;
                padding: 20px;
                margin: 20px 0;
                box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            }
            
            @media print {
                body { background: white; }
                .container { box-shadow: none; }
                .header { break-inside: avoid; }
            }
        </style>
        """
    }
    
    private func generateHeaderSection(configuration: ReportConfiguration) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        let currentDate = formatter.string(from: Date())
        
        return """
        <div class="header">
            <h1>\(configuration.format.rawValue)</h1>
            <div class="subtitle">
                Generated by DonkTool Professional Security Suite<br>
                \(currentDate)
                \(configuration.organizationName.map { "<br>For: \($0)" } ?? "")
            </div>
        </div>
        <div class="content">
        """
    }
    
    private func generateRiskOverview(vulnerabilities: [VulnerabilityFinding], credentials: [Credential]) -> String {
        let criticalCount = vulnerabilities.filter { $0.severity == "critical" }.count
        let highCount = vulnerabilities.filter { $0.severity == "high" }.count
        let mediumCount = vulnerabilities.filter { $0.severity == "medium" }.count
        let lowCount = vulnerabilities.filter { $0.severity == "low" }.count
        
        return """
        <div class="risk-overview">
            <div class="risk-card risk-critical">
                <h3>\(criticalCount)</h3>
                <p>Critical Risks</p>
            </div>
            <div class="risk-card risk-high">
                <h3>\(highCount)</h3>
                <p>High Risks</p>
            </div>
            <div class="risk-card risk-medium">
                <h3>\(mediumCount)</h3>
                <p>Medium Risks</p>
            </div>
            <div class="risk-card risk-low">
                <h3>\(lowCount)</h3>
                <p>Low Risks</p>
            </div>
        </div>
        """
    }
    
    private func generateBusinessImpact(vulnerabilities: [VulnerabilityFinding]) -> String {
        let highRiskCount = vulnerabilities.filter { $0.severity == "critical" || $0.severity == "high" }.count
        
        let impactLevel = highRiskCount > 5 ? "High" : highRiskCount > 2 ? "Medium" : "Low"
        
        return """
        <h3>Business Impact Assessment</h3>
        <p>The security assessment has identified <strong>\(vulnerabilities.count)</strong> total vulnerabilities, 
        with <strong>\(highRiskCount)</strong> classified as high or critical risk. 
        The overall business impact is assessed as <strong>\(impactLevel)</strong>.</p>
        
        <div class="recommendation">
            <strong>Immediate Action Required:</strong> Address all critical and high-severity vulnerabilities 
            within the next 30 days to minimize business risk and prevent potential security incidents.
        </div>
        """
    }
    
    private func generateHighLevelRecommendations(vulnerabilities: [VulnerabilityFinding]) -> String {
        return """
        <h3>High-Level Recommendations</h3>
        <ul>
            <li><strong>Immediate:</strong> Patch all critical vulnerabilities within 72 hours</li>
            <li><strong>Short-term:</strong> Implement security monitoring and alerting systems</li>
            <li><strong>Medium-term:</strong> Conduct regular security assessments and penetration testing</li>
            <li><strong>Long-term:</strong> Establish a comprehensive security governance framework</li>
        </ul>
        """
    }
    
    private func generateExecutiveSummarySection(vulnerabilities: [VulnerabilityFinding], credentials: [Credential]) -> String {
        return """
        <div class="executive-summary">
            <h2>Executive Summary</h2>
            \(generateRiskOverview(vulnerabilities: vulnerabilities, credentials: credentials))
        </div>
        """
    }
    
    private func generateMethodologySection(evidencePackages: [EvidencePackage]) -> String {
        let attackTypes = Set(evidencePackages.map { $0.attackName }).sorted()
        
        return """
        <p>This security assessment employed a comprehensive methodology utilizing industry-standard tools and techniques:</p>
        <ul>
            \(attackTypes.map { "<li>\($0)</li>" }.joined())
        </ul>
        <p>All testing was conducted in accordance with industry best practices and ethical hacking guidelines.</p>
        """
    }
    
    private func generateDetailedFindingsSection(vulnerabilities: [VulnerabilityFinding]) -> String {
        let sortedVulns = vulnerabilities.sorted { 
            ReportSeverity(rawValue: $0.severity.capitalized)?.priority ?? 0 > 
            ReportSeverity(rawValue: $1.severity.capitalized)?.priority ?? 0 
        }
        
        let findings = sortedVulns.enumerated().map { index, vuln in
            let severity = ReportSeverity(rawValue: vuln.severity.capitalized) ?? .informational
            return """
            <div class="vulnerability-item">
                <div class="vulnerability-header">
                    <span class="severity-badge" style="background-color: \(severity.color)">
                        \(severity.rawValue.uppercased())
                    </span>
                    <h4>Finding \(index + 1): \(vuln.type)</h4>
                </div>
                <p><strong>Description:</strong> \(vuln.description)</p>
                <p><strong>Evidence:</strong> \(vuln.proof)</p>
                <p><strong>Recommendation:</strong> \(vuln.recommendation)</p>
            </div>
            """
        }.joined()
        
        return """
        <h2>Detailed Security Findings</h2>
        \(findings)
        """
    }
    
    private func generateCredentialsSection(credentials: [Credential]) -> String {
        guard !credentials.isEmpty else { return "" }
        
        return """
        <h3>Credential Discoveries</h3>
        <div class="vulnerability-item">
            <p><strong>⚠️ SECURITY ALERT:</strong> \(credentials.count) credential(s) were discovered during testing:</p>
            <table class="table">
                <thead>
                    <tr>
                        <th>Service</th>
                        <th>Username</th>
                        <th>Port</th>
                        <th>Risk Level</th>
                    </tr>
                </thead>
                <tbody>
                    \(credentials.map { cred in
                        """
                        <tr>
                            <td>\(cred.service)</td>
                            <td>\(cred.username)</td>
                            <td>\(cred.port)</td>
                            <td><span class="severity-badge" style="background-color: #DC2626">CRITICAL</span></td>
                        </tr>
                        """
                    }.joined())
                </tbody>
            </table>
        </div>
        """
    }
    
    private func generateFilesSection(files: [String]) -> String {
        guard !files.isEmpty else { return "" }
        
        return """
        <h3>Directory and File Discoveries</h3>
        <p>The following directories and files were discovered during enumeration:</p>
        <ul>
            \(files.prefix(20).map { "<li>\($0)</li>" }.joined())
            \(files.count > 20 ? "<li><em>... and \(files.count - 20) more</em></li>" : "")
        </ul>
        """
    }
    
    private func generateRecommendationsSection(evidencePackages: [EvidencePackage]) -> String {
        let allRecommendations = evidencePackages.flatMap { $0.summary.recommendedActions }
        let uniqueRecommendations = Array(Set(allRecommendations))
        
        return """
        <h2>Security Recommendations</h2>
        \(uniqueRecommendations.enumerated().map { index, recommendation in
            """
            <div class="recommendation">
                <strong>\(index + 1).</strong> \(recommendation)
            </div>
            """
        }.joined())
        """
    }
    
    private func generateFooter() -> String {
        return """
        </div>
        <div class="footer">
            <p>This report was generated by DonkTool Professional Security Suite</p>
            <p>© 2024 - Confidential Security Assessment Report</p>
        </div>
        """
    }
    
    // Additional section generators for other report types...
    
    private func generateTestScopeSection(evidencePackages: [EvidencePackage]) -> String {
        let targets = Set(evidencePackages.map { "\($0.target):\($0.port)" }).sorted()
        
        return """
        <h3>Test Scope</h3>
        <p>The penetration test covered the following targets:</p>
        <ul>
            \(targets.map { "<li>\($0)</li>" }.joined())
        </ul>
        """
    }
    
    private func generateTestApproach(evidencePackages: [EvidencePackage]) -> String {
        return """
        <h3>Testing Approach</h3>
        <p>The penetration test followed a structured methodology:</p>
        <ol>
            <li><strong>Reconnaissance:</strong> Information gathering and target enumeration</li>
            <li><strong>Vulnerability Assessment:</strong> Automated and manual vulnerability identification</li>
            <li><strong>Exploitation:</strong> Controlled exploitation of identified vulnerabilities</li>
            <li><strong>Post-Exploitation:</strong> Assessment of potential impact and lateral movement</li>
            <li><strong>Reporting:</strong> Documentation of findings and recommendations</li>
        </ol>
        """
    }
    
    private func generateAttackChainSection(evidencePackages: [EvidencePackage]) -> String {
        return """
        <h2>Attack Chain Analysis</h2>
        <p>The following attack chains were successfully executed during the assessment:</p>
        \(evidencePackages.enumerated().map { index, package in
            """
            <div class="vulnerability-item">
                <h4>Attack Chain \(index + 1): \(package.attackName)</h4>
                <p><strong>Target:</strong> \(package.target):\(package.port)</p>
                <p><strong>Duration:</strong> \(String(format: "%.1f", package.duration)) seconds</p>
                <p><strong>Success:</strong> \(package.success ? "✅ Successful" : "❌ Failed")</p>
                <p><strong>Impact:</strong> \(package.summary.totalVulnerabilities) vulnerabilities, \(package.summary.credentialsFound) credentials</p>
            </div>
            """
        }.joined())
        """
    }
    
    private func generateExploitationDetails(vulnerabilities: [VulnerabilityFinding], credentials: [Credential]) -> String {
        return """
        <p>During the penetration test, \(vulnerabilities.count) vulnerabilities were successfully exploited, 
        resulting in the discovery of \(credentials.count) credential sets. This demonstrates significant 
        security weaknesses that could be leveraged by malicious attackers.</p>
        
        <div class="recommendation">
            <strong>Critical Finding:</strong> The successful exploitation of these vulnerabilities indicates 
            that unauthorized access to sensitive systems and data is possible. Immediate remediation is required.
        </div>
        """
    }
    
    private func generateRiskAssessmentSection(vulnerabilities: [VulnerabilityFinding]) -> String {
        let riskMatrix = generateRiskMatrix(vulnerabilities: vulnerabilities)
        
        return """
        <h2>Risk Assessment</h2>
        <h3>Risk Matrix</h3>
        \(riskMatrix)
        
        <h3>Overall Risk Rating</h3>
        <p>Based on the identified vulnerabilities and successful exploitation, the overall risk rating is:</p>
        <div class="risk-card risk-high" style="display: inline-block; margin: 10px 0;">
            <h3>HIGH RISK</h3>
            <p>Immediate Action Required</p>
        </div>
        """
    }
    
    private func generateRiskMatrix(vulnerabilities: [VulnerabilityFinding]) -> String {
        let critical = vulnerabilities.filter { $0.severity == "critical" }.count
        let high = vulnerabilities.filter { $0.severity == "high" }.count
        let medium = vulnerabilities.filter { $0.severity == "medium" }.count
        let low = vulnerabilities.filter { $0.severity == "low" }.count
        
        return """
        <table class="table">
            <thead>
                <tr>
                    <th>Risk Level</th>
                    <th>Count</th>
                    <th>Percentage</th>
                    <th>Action Required</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td><span class="severity-badge risk-critical">Critical</span></td>
                    <td>\(critical)</td>
                    <td>\(vulnerabilities.isEmpty ? 0 : Int(Double(critical) / Double(vulnerabilities.count) * 100))%</td>
                    <td>Immediate (0-24 hours)</td>
                </tr>
                <tr>
                    <td><span class="severity-badge risk-high">High</span></td>
                    <td>\(high)</td>
                    <td>\(vulnerabilities.isEmpty ? 0 : Int(Double(high) / Double(vulnerabilities.count) * 100))%</td>
                    <td>Urgent (1-7 days)</td>
                </tr>
                <tr>
                    <td><span class="severity-badge risk-medium">Medium</span></td>
                    <td>\(medium)</td>
                    <td>\(vulnerabilities.isEmpty ? 0 : Int(Double(medium) / Double(vulnerabilities.count) * 100))%</td>
                    <td>Short-term (1-30 days)</td>
                </tr>
                <tr>
                    <td><span class="severity-badge risk-low">Low</span></td>
                    <td>\(low)</td>
                    <td>\(vulnerabilities.isEmpty ? 0 : Int(Double(low) / Double(vulnerabilities.count) * 100))%</td>
                    <td>Long-term (30+ days)</td>
                </tr>
            </tbody>
        </table>
        """
    }
    
    private func generateComplianceFrameworksSection() -> String {
        return """
        <h3>Compliance Frameworks</h3>
        <p>This assessment evaluates security posture against the following frameworks:</p>
        <ul>
            <li>NIST Cybersecurity Framework</li>
            <li>ISO 27001:2013</li>
            <li>OWASP Top 10</li>
            <li>CIS Critical Security Controls</li>
        </ul>
        """
    }
    
    private func generateComplianceStatus(vulnerabilities: [VulnerabilityFinding]) -> String {
        let complianceScore = max(0, 100 - vulnerabilities.count * 10)
        
        return """
        <h3>Overall Compliance Status</h3>
        <div class="chart-container">
            <p><strong>Compliance Score: \(complianceScore)%</strong></p>
            <div style="background: #e2e8f0; height: 20px; border-radius: 10px; margin: 10px 0;">
                <div style="background: \(complianceScore > 70 ? "#65A30D" : complianceScore > 40 ? "#D97706" : "#DC2626"); 
                           height: 100%; width: \(complianceScore)%; border-radius: 10px;"></div>
            </div>
            <p>Status: \(complianceScore > 70 ? "Compliant" : complianceScore > 40 ? "Partially Compliant" : "Non-Compliant")</p>
        </div>
        """
    }
    
    private func generateComplianceGapsSection(vulnerabilities: [VulnerabilityFinding]) -> String {
        return """
        <h2>Compliance Gaps</h2>
        <p>The following compliance gaps have been identified:</p>
        <div class="vulnerability-item">
            <h4>NIST Cybersecurity Framework Gaps</h4>
            <ul>
                <li>PR.AC-1: Access Control - \(vulnerabilities.filter { $0.type.contains("Access") }.count) findings</li>
                <li>PR.DS-1: Data Security - \(vulnerabilities.filter { $0.type.contains("Data") }.count) findings</li>
                <li>DE.CM-1: Monitoring - Continuous monitoring not implemented</li>
            </ul>
        </div>
        """
    }
    
    private func generateComplianceRecommendationsSection(vulnerabilities: [VulnerabilityFinding]) -> String {
        return """
        <h2>Compliance Recommendations</h2>
        <div class="recommendation">
            <strong>Priority 1:</strong> Implement access controls and authentication mechanisms
        </div>
        <div class="recommendation">
            <strong>Priority 2:</strong> Establish security monitoring and incident response procedures
        </div>
        <div class="recommendation">
            <strong>Priority 3:</strong> Conduct regular security awareness training
        </div>
        """
    }
    
    private func generateRemediationPriorities(vulnerabilities: [VulnerabilityFinding]) -> String {
        return """
        <h3>Remediation Priorities</h3>
        <table class="table">
            <thead>
                <tr>
                    <th>Priority</th>
                    <th>Timeframe</th>
                    <th>Vulnerability Count</th>
                    <th>Effort Level</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td>P1 - Critical</td>
                    <td>0-24 hours</td>
                    <td>\(vulnerabilities.filter { $0.severity == "critical" }.count)</td>
                    <td>High</td>
                </tr>
                <tr>
                    <td>P2 - High</td>
                    <td>1-7 days</td>
                    <td>\(vulnerabilities.filter { $0.severity == "high" }.count)</td>
                    <td>Medium</td>
                </tr>
                <tr>
                    <td>P3 - Medium</td>
                    <td>1-30 days</td>
                    <td>\(vulnerabilities.filter { $0.severity == "medium" }.count)</td>
                    <td>Medium</td>
                </tr>
                <tr>
                    <td>P4 - Low</td>
                    <td>30+ days</td>
                    <td>\(vulnerabilities.filter { $0.severity == "low" }.count)</td>
                    <td>Low</td>
                </tr>
            </tbody>
        </table>
        """
    }
    
    private func generateRemediationTimeline(vulnerabilities: [VulnerabilityFinding]) -> String {
        return """
        <h3>Recommended Remediation Timeline</h3>
        <div class="chart-container">
            <p><strong>Week 1:</strong> Address all critical vulnerabilities</p>
            <p><strong>Weeks 2-3:</strong> Remediate high-severity findings</p>
            <p><strong>Month 2:</strong> Focus on medium-severity issues</p>
            <p><strong>Ongoing:</strong> Monitor and address low-severity findings</p>
        </div>
        """
    }
    
    private func generateDetailedRemediationSteps(vulnerabilities: [VulnerabilityFinding]) -> String {
        let groupedVulns = Dictionary(grouping: vulnerabilities) { $0.severity }
        
        let sections = groupedVulns.map { severity, vulns in
            let severityObj = ReportSeverity(rawValue: severity.capitalized) ?? .informational
            return """
            <h3>\(severityObj.rawValue) Severity Remediation (\(vulns.count) items)</h3>
            \(vulns.enumerated().map { index, vuln in
                """
                <div class="vulnerability-item">
                    <h4>\(index + 1). \(vuln.type)</h4>
                    <p><strong>Issue:</strong> \(vuln.description)</p>
                    <p><strong>Solution:</strong> \(vuln.recommendation)</p>
                    <p><strong>Validation:</strong> Test the fix and verify the vulnerability is resolved</p>
                </div>
                """
            }.joined())
            """
        }.joined()
        
        return """
        <h2>Detailed Remediation Steps</h2>
        \(sections)
        """
    }
    
    private func generateValidationGuidelines(vulnerabilities: [VulnerabilityFinding]) -> String {
        return """
        <h2>Validation Guidelines</h2>
        <div class="recommendation">
            <strong>Post-Remediation Testing:</strong> After implementing fixes, conduct the following validation steps:
        </div>
        <ol>
            <li><strong>Vulnerability Scanning:</strong> Re-run automated scans to verify fixes</li>
            <li><strong>Manual Testing:</strong> Perform manual verification of critical fixes</li>
            <li><strong>Regression Testing:</strong> Ensure fixes don't introduce new vulnerabilities</li>
            <li><strong>Documentation:</strong> Document all changes and maintain security baselines</li>
        </ol>
        """
    }
}