//
//  ModernReportingView.swift
//  DonkTool
//
//  Modern report generation interface with charts and export options
//

import SwiftUI
import Charts
import UniformTypeIdentifiers

struct ModernReportingView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedReportType: ReportType = .executive
    @State private var selectedTargets = Set<UUID>()
    @State private var includeDetailedFindings = true
    @State private var includeRecommendations = true
    @State private var includeCharts = true
    @State private var includeTimeline = true
    @State private var isGeneratingReport = false
    @State private var showingExportOptions = false
    @State private var generatedReportData: Data?
    @State private var exportFormat: ExportFormat = .pdf
    @State private var searchText = ""
    
    enum ReportType: String, CaseIterable {
        case executive = "Executive Summary"
        case technical = "Technical Report"
        case detailed = "Detailed Findings"
        case compliance = "Compliance Report"
        case pentest = "Penetration Test Report"
        
        var icon: String {
            switch self {
            case .executive: return "chart.pie.fill"
            case .technical: return "terminal.fill"
            case .detailed: return "doc.text.magnifyingglass"
            case .compliance: return "checkmark.shield.fill"
            case .pentest: return "network.badge.shield.half.filled"
            }
        }
        
        var description: String {
            switch self {
            case .executive: return "High-level overview with risk metrics"
            case .technical: return "Technical details with exploitation steps"
            case .detailed: return "Comprehensive vulnerability analysis"
            case .compliance: return "Compliance-focused with remediation"
            case .pentest: return "Full penetration test documentation"
            }
        }
    }
    
    enum ExportFormat: String, CaseIterable {
        case pdf = "PDF"
        case html = "HTML"
        case json = "JSON"
        case csv = "CSV"
        case markdown = "Markdown"
        
        var icon: String {
            switch self {
            case .pdf: return "doc.richtext.fill"
            case .html: return "globe"
            case .json: return "curlybraces"
            case .csv: return "tablecells"
            case .markdown: return "text.quote"
            }
        }
    }
    
    var vulnerabilityStats: (critical: Int, high: Int, medium: Int, low: Int) {
        let vulns = selectedTargets.isEmpty ? appState.allVulnerabilities : 
            appState.allVulnerabilities.filter { vuln in
                appState.targets.contains { target in
                    selectedTargets.contains(target.id) && 
                    target.vulnerabilities.contains { $0.id == vuln.id }
                }
            }
        
        return (
            critical: vulns.filter { $0.severity == .critical }.count,
            high: vulns.filter { $0.severity == .high }.count,
            medium: vulns.filter { $0.severity == .medium }.count,
            low: vulns.filter { $0.severity == .low }.count
        )
    }
    
    var filteredTargets: [Target] {
        if searchText.isEmpty {
            return appState.targets
        }
        return appState.targets.filter { target in
            target.ipAddress.localizedCaseInsensitiveContains(searchText) ||
            target.hostname?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Modern Header
            ModernReportHeader()
            
            ScrollView {
                VStack(spacing: 24) {
                    HStack(alignment: .top, spacing: 24) {
                        // Left Panel - Configuration
                        VStack(spacing: 24) {
                            // Report Type Selection
                            ReportTypeSelector(selectedType: $selectedReportType)
                            
                            // Target Selection
                            TargetSelectionCard(
                                targets: filteredTargets,
                                selectedTargets: $selectedTargets,
                                searchText: $searchText
                            )
                            
                            // Report Options
                            ReportOptionsCard(
                                includeDetailedFindings: $includeDetailedFindings,
                                includeRecommendations: $includeRecommendations,
                                includeCharts: $includeCharts,
                                includeTimeline: $includeTimeline
                            )
                            
                            // Export Format
                            ExportFormatSelector(selectedFormat: $exportFormat)
                        }
                        .frame(width: 350)
                        
                        // Right Panel - Preview
                        VStack(spacing: 16) {
                            // Stats Overview
                            ReportStatsOverview(stats: vulnerabilityStats)
                            
                            // Report Preview
                            ReportPreviewCard(
                                reportType: selectedReportType,
                                selectedTargets: selectedTargets,
                                includeCharts: includeCharts
                            )
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 24)
                    
                    // Generate Button
                    HStack {
                        Spacer()
                        
                        Button(action: generateReport) {
                            Label(
                                isGeneratingReport ? "Generating..." : "Generate Report",
                                systemImage: isGeneratingReport ? "clock.fill" : "doc.badge.plus"
                            )
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.accentColor)
                            .cornerRadius(10)
                            .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(isGeneratingReport || (selectedTargets.isEmpty && selectedReportType != .executive))
                        .scaleEffect(isGeneratingReport ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isGeneratingReport)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .sheet(isPresented: $showingExportOptions) {
            if let reportData = generatedReportData {
                ExportOptionsSheet(
                    reportData: reportData,
                    format: exportFormat,
                    reportType: selectedReportType
                )
            }
        }
    }
    
    private func generateReport() {
        isGeneratingReport = true
        
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 second delay for demo
            
            await MainActor.run {
                // Generate actual report data based on format
                switch exportFormat {
                case .pdf:
                    generatedReportData = generatePDFReport()
                case .html:
                    generatedReportData = generateHTMLReport()
                case .json:
                    generatedReportData = generateJSONReport()
                case .csv:
                    generatedReportData = generateCSVReport()
                case .markdown:
                    generatedReportData = generateMarkdownReport()
                }
                
                isGeneratingReport = false
                showingExportOptions = true
            }
        }
    }
    
    private func generatePDFReport() -> Data {
        // Simplified PDF generation
        let content = """
        # Security Assessment Report
        
        Report Type: \(selectedReportType.rawValue)
        Generated: \(Date().formatted())
        
        ## Executive Summary
        
        Total Vulnerabilities: \(vulnerabilityStats.critical + vulnerabilityStats.high + vulnerabilityStats.medium + vulnerabilityStats.low)
        - Critical: \(vulnerabilityStats.critical)
        - High: \(vulnerabilityStats.high)
        - Medium: \(vulnerabilityStats.medium)
        - Low: \(vulnerabilityStats.low)
        
        ## Findings
        
        [Detailed findings would be included here]
        """
        
        return content.data(using: .utf8) ?? Data()
    }
    
    private func generateHTMLReport() -> Data {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Security Report</title>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; margin: 40px; }
                h1 { color: #333; }
                .stats { display: flex; gap: 20px; margin: 20px 0; }
                .stat-card { background: #f5f5f5; padding: 20px; border-radius: 8px; }
            </style>
        </head>
        <body>
            <h1>Security Assessment Report</h1>
            <div class="stats">
                <div class="stat-card">Critical: \(vulnerabilityStats.critical)</div>
                <div class="stat-card">High: \(vulnerabilityStats.high)</div>
                <div class="stat-card">Medium: \(vulnerabilityStats.medium)</div>
                <div class="stat-card">Low: \(vulnerabilityStats.low)</div>
            </div>
        </body>
        </html>
        """
        
        return html.data(using: .utf8) ?? Data()
    }
    
    private func generateJSONReport() -> Data {
        let report = [
            "type": selectedReportType.rawValue,
            "generated": ISO8601DateFormatter().string(from: Date()),
            "stats": [
                "critical": vulnerabilityStats.critical,
                "high": vulnerabilityStats.high,
                "medium": vulnerabilityStats.medium,
                "low": vulnerabilityStats.low
            ]
        ] as [String : Any]
        
        return (try? JSONSerialization.data(withJSONObject: report)) ?? Data()
    }
    
    private func generateCSVReport() -> Data {
        var csv = "Severity,Count\n"
        csv += "Critical,\(vulnerabilityStats.critical)\n"
        csv += "High,\(vulnerabilityStats.high)\n"
        csv += "Medium,\(vulnerabilityStats.medium)\n"
        csv += "Low,\(vulnerabilityStats.low)\n"
        
        return csv.data(using: .utf8) ?? Data()
    }
    
    private func generateMarkdownReport() -> Data {
        let markdown = """
        # Security Assessment Report
        
        **Report Type:** \(selectedReportType.rawValue)  
        **Generated:** \(Date().formatted())
        
        ## Summary
        
        | Severity | Count |
        |----------|-------|
        | Critical | \(vulnerabilityStats.critical) |
        | High | \(vulnerabilityStats.high) |
        | Medium | \(vulnerabilityStats.medium) |
        | Low | \(vulnerabilityStats.low) |
        
        ## Detailed Findings
        
        [Findings would be listed here]
        """
        
        return markdown.data(using: .utf8) ?? Data()
    }
}

// MARK: - Supporting Views

struct ModernReportHeader: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Report Generation")
                    .font(.system(size: 32, weight: .bold))
                Text("Create comprehensive security assessment reports")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Quick Stats
            HStack(spacing: 20) {
                ReportQuickStat(label: "Templates", value: "5", icon: "doc.text", color: .blue)
                ReportQuickStat(label: "Formats", value: "5", icon: "square.grid.3x2", color: .green)
            }
        }
        .padding(24)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct ReportQuickStat: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .semibold))
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ReportTypeSelector: View {
    @Binding var selectedType: ModernReportingView.ReportType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Report Type")
                .font(.system(size: 16, weight: .semibold))
            
            VStack(spacing: 8) {
                ForEach(ModernReportingView.ReportType.allCases, id: \.self) { type in
                    ReportTypeButton(
                        type: type,
                        isSelected: selectedType == type,
                        action: { selectedType = type }
                    )
                }
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct ReportTypeButton: View {
    let type: ModernReportingView.ReportType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: type.icon)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? .white : .accentColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(type.description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
            }
            .padding(12)
            .background(isSelected ? Color.accentColor : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct TargetSelectionCard: View {
    let targets: [Target]
    @Binding var selectedTargets: Set<UUID>
    @Binding var searchText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Target Selection")
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                Button(selectedTargets.count == targets.count ? "Deselect All" : "Select All") {
                    if selectedTargets.count == targets.count {
                        selectedTargets.removeAll()
                    } else {
                        selectedTargets = Set(targets.map { $0.id })
                    }
                }
                .font(.caption)
                .foregroundColor(.accentColor)
            }
            
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search targets...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(8)
            
            // Target List
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(targets) { target in
                        TargetRow(
                            target: target,
                            isSelected: selectedTargets.contains(target.id),
                            action: {
                                if selectedTargets.contains(target.id) {
                                    selectedTargets.remove(target.id)
                                } else {
                                    selectedTargets.insert(target.id)
                                }
                            }
                        )
                    }
                }
            }
            .frame(maxHeight: 200)
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct TargetRow: View {
    let target: Target
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(target.ipAddress)
                        .font(.system(size: 13, weight: .medium))
                    if let hostname = target.hostname {
                        Text(hostname)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text("\(target.vulnerabilities.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct ReportOptionsCard: View {
    @Binding var includeDetailedFindings: Bool
    @Binding var includeRecommendations: Bool
    @Binding var includeCharts: Bool
    @Binding var includeTimeline: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Report Options")
                .font(.system(size: 16, weight: .semibold))
            
            VStack(spacing: 8) {
                OptionToggle(
                    label: "Detailed Findings",
                    icon: "doc.text.magnifyingglass",
                    isOn: $includeDetailedFindings
                )
                
                OptionToggle(
                    label: "Recommendations",
                    icon: "lightbulb.fill",
                    isOn: $includeRecommendations
                )
                
                OptionToggle(
                    label: "Charts & Graphs",
                    icon: "chart.pie.fill",
                    isOn: $includeCharts
                )
                
                OptionToggle(
                    label: "Timeline View",
                    icon: "timeline.selection",
                    isOn: $includeTimeline
                )
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct OptionToggle: View {
    let label: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                Text(label)
                    .font(.system(size: 13))
            }
        }
        .toggleStyle(.switch)
    }
}

struct ExportFormatSelector: View {
    @Binding var selectedFormat: ModernReportingView.ExportFormat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export Format")
                .font(.system(size: 16, weight: .semibold))
            
            HStack(spacing: 8) {
                ForEach(ModernReportingView.ExportFormat.allCases, id: \.self) { format in
                    FormatButton(
                        format: format,
                        isSelected: selectedFormat == format,
                        action: { selectedFormat = format }
                    )
                }
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct FormatButton: View {
    let format: ModernReportingView.ExportFormat
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: format.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : .accentColor)
                
                Text(format.rawValue)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(width: 50, height: 50)
            .background(isSelected ? Color.accentColor : Color(NSColor.windowBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.clear : Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ReportStatsOverview: View {
    let stats: (critical: Int, high: Int, medium: Int, low: Int)
    
    var total: Int {
        stats.critical + stats.high + stats.medium + stats.low
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Vulnerability Overview")
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                Text("\(total) Total")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            // Severity Distribution Chart
            if total > 0 {
                Chart {
                    BarMark(
                        x: .value("Count", stats.critical),
                        y: .value("Severity", "Critical")
                    )
                    .foregroundStyle(.red)
                    
                    BarMark(
                        x: .value("Count", stats.high),
                        y: .value("Severity", "High")
                    )
                    .foregroundStyle(.orange)
                    
                    BarMark(
                        x: .value("Count", stats.medium),
                        y: .value("Severity", "Medium")
                    )
                    .foregroundStyle(.yellow)
                    
                    BarMark(
                        x: .value("Count", stats.low),
                        y: .value("Severity", "Low")
                    )
                    .foregroundStyle(.blue)
                }
                .frame(height: 120)
                .chartXAxis(.hidden)
            } else {
                Text("No vulnerabilities to display")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct ReportPreviewCard: View {
    let reportType: ModernReportingView.ReportType
    let selectedTargets: Set<UUID>
    let includeCharts: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Preview Header
                HStack {
                    Image(systemName: reportType.icon)
                        .font(.system(size: 24))
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(reportType.rawValue)
                            .font(.system(size: 20, weight: .semibold))
                        Text("Preview")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                Divider()
                
                // Sample Content
                VStack(alignment: .leading, spacing: 16) {
                    Text("Executive Summary")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("This security assessment was conducted to evaluate the security posture of the target infrastructure...")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    if includeCharts {
                        // Sample Chart
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Risk Distribution")
                                .font(.system(size: 14, weight: .medium))
                            
                            HStack(spacing: 4) {
                                ForEach(1...5, id: \.self) { _ in
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.accentColor.opacity(Double.random(in: 0.3...1.0)))
                                        .frame(height: CGFloat.random(in: 40...100))
                                }
                            }
                            .frame(height: 100)
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                    
                    Text("Key Findings")
                        .font(.system(size: 16, weight: .semibold))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        FindingPreviewRow(severity: .critical, title: "SQL Injection in Login Form")
                        FindingPreviewRow(severity: .high, title: "Outdated TLS Configuration")
                        FindingPreviewRow(severity: .medium, title: "Missing Security Headers")
                    }
                }
                
                Spacer()
            }
            .padding(20)
        }
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct FindingPreviewRow: View {
    let severity: Vulnerability.Severity
    let title: String
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(severity.color)
                .frame(width: 8, height: 8)
            
            Text(title)
                .font(.system(size: 13))
            
            Spacer()
        }
    }
}

struct ExportOptionsSheet: View {
    let reportData: Data
    let format: ModernReportingView.ExportFormat
    let reportType: ModernReportingView.ReportType
    @Environment(\.dismiss) private var dismiss
    @State private var showingSavePanel = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Report Generated Successfully")
                        .font(.system(size: 20, weight: .semibold))
                    Text("Your \(reportType.rawValue) is ready for export")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
            
            // Report Info
            VStack(spacing: 12) {
                ReportInfoRow(label: "Format", value: format.rawValue, icon: format.icon)
                ReportInfoRow(label: "Size", value: "\(reportData.count / 1024) KB", icon: "doc")
                ReportInfoRow(label: "Generated", value: Date().formatted(), icon: "clock")
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            // Actions
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Save As...") {
                    saveReport()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 450)
    }
    
    private func saveReport() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [getUTType()]
        savePanel.nameFieldStringValue = "Security_Report_\(Date().formatted(date: .numeric, time: .omitted))"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                try? reportData.write(to: url)
                dismiss()
            }
        }
    }
    
    private func getUTType() -> UTType {
        switch format {
        case .pdf: return .pdf
        case .html: return .html
        case .json: return .json
        case .csv: return .commaSeparatedText
        case .markdown: return .plainText
        }
    }
}

struct ReportInfoRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.system(size: 13, weight: .medium))
            
            Spacer()
        }
    }
}

#Preview {
    ModernReportingView()
        .environment(AppState())
        .frame(width: 1200, height: 800)
}