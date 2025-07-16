//
//  ReportingView.swift
//  DonkTool
//
//  Report generation and export interface
//

import SwiftUI

struct ReportingView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedReportType: ReportType = .executive
    @State private var isGeneratingReport = false
    @State private var generatedReports: [GeneratedReport] = []
    @State private var selectedTargets: Set<UUID> = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Report Configuration Panel
            VStack(spacing: 16) {
                HStack {
                    Text("Report Generation")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                }
                
                // Report type selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Report Type")
                        .font(.headline)
                    
                    Picker("Report Type", selection: $selectedReportType) {
                        ForEach(ReportType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Target selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Include Targets")
                        .font(.headline)
                    
                    if appState.targets.isEmpty {
                        Text("No targets available")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    } else {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(appState.targets) { target in
                                TargetSelectionView(
                                    target: target,
                                    isSelected: selectedTargets.contains(target.id)
                                ) { isSelected in
                                    if isSelected {
                                        selectedTargets.insert(target.id)
                                    } else {
                                        selectedTargets.remove(target.id)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Action buttons
                HStack {
                    Button("Select All Targets") {
                        selectedTargets = Set(appState.targets.map { $0.id })
                    }
                    .disabled(appState.targets.isEmpty)
                    
                    Button("Clear Selection") {
                        selectedTargets.removeAll()
                    }
                    
                    Spacer()
                    
                    Button("Generate Report") {
                        generateReport()
                    }
                    .disabled(selectedTargets.isEmpty || isGeneratingReport)
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Generated Reports
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Generated Reports")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if isGeneratingReport {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Generating...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                if generatedReports.isEmpty && !isGeneratingReport {
                    ContentUnavailableView(
                        "No Reports Generated",
                        systemImage: "doc.text",
                        description: Text("Select targets and generate your first report")
                    )
                } else {
                    List(generatedReports) { report in
                        ReportRowView(report: report) {
                            exportReport(report)
                        }
                    }
                    .listStyle(.plain)
                }
            }
        }
    }
    
    private func generateReport() {
        guard !selectedTargets.isEmpty else { return }
        
        isGeneratingReport = true
        
        Task {
            let targets = appState.targets.filter { selectedTargets.contains($0.id) }
            let report = await createActualReport(type: selectedReportType, targets: targets)
            
            await MainActor.run {
                generatedReports.insert(report, at: 0)
                isGeneratingReport = false
            }
        }
    }
    
    private func createActualReport(type: ReportType, targets: [Target]) async -> GeneratedReport {
        let vulnerabilityCount = targets.reduce(0) { $0 + $1.vulnerabilities.count }
        let criticalCount = targets.flatMap { $0.vulnerabilities }.filter { $0.severity == .critical }.count
        let highCount = targets.flatMap { $0.vulnerabilities }.filter { $0.severity == .high }.count
        
        // Generate actual PDF report
        let pdfData = await generatePDFReport(type: type, targets: targets)
        let fileSize = ByteCountFormatter.string(fromByteCount: Int64(pdfData.count), countStyle: .file)
        
        // Save PDF to Documents directory
        let fileName = "\(type.displayName.replacingOccurrences(of: " ", with: "_"))_Report_\(Date().formatted(date: .abbreviated, time: .omitted).replacingOccurrences(of: " ", with: "_")).pdf"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try pdfData.write(to: fileURL)
        } catch {
            print("Error saving PDF: \(error)")
        }
        
        return GeneratedReport(
            type: type,
            name: "\(type.displayName) Report - \(Date().formatted(date: .abbreviated, time: .omitted))",
            targetCount: targets.count,
            vulnerabilityCount: vulnerabilityCount,
            criticalCount: criticalCount,
            highCount: highCount,
            generatedAt: Date(),
            fileSize: fileSize,
            filePath: fileURL.path
        )
    }
    
    private func generatePDFReport(type: ReportType, targets: [Target]) async -> Data {
        let pdfData = NSMutableData()
        var pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        
        guard let consumer = CGDataConsumer(data: pdfData),
              let context = CGContext(consumer: consumer, mediaBox: &pageRect, nil) else {
            return Data()
        }
        
        // Title Page
        let pageInfo: CFDictionary? = nil
        context.beginPDFPage(pageInfo)
        
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 24),
            .foregroundColor: NSColor.black
        ]
        let title = "\(type.displayName)\nPenetration Testing Report"
        let titleString = NSAttributedString(string: title, attributes: titleAttributes)
        let titleLine = CTLineCreateWithAttributedString(titleString)
        context.textPosition = CGPoint(x: 50, y: 700)
        CTLineDraw(titleLine, context)
        
        let dateStr = "Generated: \(Date().formatted(date: .complete, time: .shortened))"
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.gray
        ]
        let dateString = NSAttributedString(string: dateStr, attributes: dateAttributes)
        let dateLine = CTLineCreateWithAttributedString(dateString)
        context.textPosition = CGPoint(x: 50, y: 650)
        CTLineDraw(dateLine, context)
        
        // Executive Summary
        var yPosition: CGFloat = 600
        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.black
        ]
        
        let summary = generateExecutiveSummary(targets: targets)
        let summaryLines = summary.components(separatedBy: .newlines)
        
        for line in summaryLines {
            let lineString = NSAttributedString(string: line, attributes: bodyAttributes)
            let ctLine = CTLineCreateWithAttributedString(lineString)
            context.textPosition = CGPoint(x: 50, y: yPosition)
            CTLineDraw(ctLine, context)
            yPosition -= 20
        }
        
        // Vulnerability Details
        for target in targets {
            if yPosition < 100 {
                context.endPDFPage()
                context.beginPDFPage(pageInfo)
                yPosition = 750
            }
            
            let targetTitle = "Target: \(target.name) (\(target.ipAddress))"
            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: 16),
                .foregroundColor: NSColor.black
            ]
            let targetString = NSAttributedString(string: targetTitle, attributes: headerAttributes)
            let targetLine = CTLineCreateWithAttributedString(targetString)
            context.textPosition = CGPoint(x: 50, y: yPosition)
            CTLineDraw(targetLine, context)
            yPosition -= 30
            
            for vulnerability in target.vulnerabilities {
                if yPosition < 100 {
                    context.endPDFPage()
                    context.beginPDFPage(pageInfo)
                    yPosition = 750
                }
                
                let vulnText = "• \(vulnerability.title) (\(vulnerability.severity.rawValue))"
                let vulnString = NSAttributedString(string: vulnText, attributes: bodyAttributes)
                let vulnLine = CTLineCreateWithAttributedString(vulnString)
                context.textPosition = CGPoint(x: 70, y: yPosition)
                CTLineDraw(vulnLine, context)
                yPosition -= 20
                
                let descText = "  \(vulnerability.description)"
                let descString = NSAttributedString(string: descText, attributes: bodyAttributes)
                let descLine = CTLineCreateWithAttributedString(descString)
                context.textPosition = CGPoint(x: 70, y: yPosition)
                CTLineDraw(descLine, context)
                yPosition -= 30
            }
            yPosition -= 20
        }
        
        context.endPDFPage()
        context.closePDF()
        
        return pdfData as Data
    }
    
    private func generateExecutiveSummary(targets: [Target]) -> String {
        let totalVulns = targets.reduce(0) { $0 + $1.vulnerabilities.count }
        let criticalCount = targets.flatMap { $0.vulnerabilities }.filter { $0.severity == .critical }.count
        let highCount = targets.flatMap { $0.vulnerabilities }.filter { $0.severity == .high }.count
        
        return """
        EXECUTIVE SUMMARY
        
        This penetration testing assessment was conducted on \(targets.count) target(s).
        
        Key Findings:
        • Total Vulnerabilities: \(totalVulns)
        • Critical Severity: \(criticalCount)
        • High Severity: \(highCount)
        
        Recommendations:
        • Address all critical and high severity vulnerabilities immediately
        • Implement proper security controls and monitoring
        • Conduct regular security assessments
        """
    }
    
    private func exportReport(_ report: GeneratedReport) {
        if let filePath = report.filePath {
            NSWorkspace.shared.selectFile(filePath, inFileViewerRootedAtPath: "")
        }
    }
}

enum ReportType: String, CaseIterable {
    case executive = "executive"
    case technical = "technical"
    case compliance = "compliance"
    case summary = "summary"
    
    var displayName: String {
        switch self {
        case .executive: return "Executive Summary"
        case .technical: return "Technical Report"
        case .compliance: return "Compliance Report"
        case .summary: return "Quick Summary"
        }
    }
    
    var description: String {
        switch self {
        case .executive: return "High-level overview for management and stakeholders"
        case .technical: return "Detailed technical findings with remediation steps"
        case .compliance: return "Compliance-focused report for regulatory requirements"
        case .summary: return "Concise summary of key findings"
        }
    }
}

struct GeneratedReport: Identifiable {
    let id = UUID()
    let type: ReportType
    let name: String
    let targetCount: Int
    let vulnerabilityCount: Int
    let criticalCount: Int
    let highCount: Int
    let generatedAt: Date
    let fileSize: String
    let filePath: String?
    
    init(type: ReportType, name: String, targetCount: Int, vulnerabilityCount: Int, criticalCount: Int, highCount: Int, generatedAt: Date, fileSize: String, filePath: String? = nil) {
        self.type = type
        self.name = name
        self.targetCount = targetCount
        self.vulnerabilityCount = vulnerabilityCount
        self.criticalCount = criticalCount
        self.highCount = highCount
        self.generatedAt = generatedAt
        self.fileSize = fileSize
        self.filePath = filePath
    }
}

struct TargetSelectionView: View {
    let target: Target
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        Button(action: {
            onToggle(!isSelected)
        }) {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .blue : .secondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(target.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text("\(target.vulnerabilities.count) vulnerabilities")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.blue : Color.secondary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ReportRowView: View {
    let report: GeneratedReport
    let onExport: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(report.name)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(report.type.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    Label("\(report.targetCount)", systemImage: "target")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Label("\(report.vulnerabilityCount)", systemImage: "shield")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if report.criticalCount > 0 {
                        Label("\(report.criticalCount)", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Button("Export") {
                    onExport()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Text(report.generatedAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(report.fileSize)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ReportingView()
        .environmentObject(AppState())
}
