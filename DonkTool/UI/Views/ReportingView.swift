//
//  ReportingView.swift
//  DonkTool
//
//  Report generation interface with real PDF creation
//

import SwiftUI
import UniformTypeIdentifiers

struct ReportingView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedReportType: ReportType = .executive
    @State private var selectedTargets: Set<UUID> = []
    @State private var includeDetailedFindings = true
    @State private var includeRecommendations = true
    @State private var isGeneratingReport = false
    @State private var showingFilePicker = false
    @State private var generatedReportData: Data?
    
    enum ReportType: String, CaseIterable {
        case executive = "Executive Summary"
        case technical = "Technical Report"
        case detailed = "Detailed Findings"
        case compliance = "Compliance Report"
        
        var description: String {
            switch self {
            case .executive: return "High-level overview for management"
            case .technical: return "Technical details for IT teams"
            case .detailed: return "Comprehensive vulnerability report"
            case .compliance: return "Compliance-focused findings"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Configuration Panel
            VStack(spacing: 20) {
                HStack {
                    Text("Report Generation")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if isGeneratingReport {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Generating report...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Report type selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Report Type")
                        .font(.headline)
                    
                    ForEach(ReportType.allCases, id: \.self) { type in
                        ReportTypeSelectionView(
                            type: type,
                            isSelected: selectedReportType == type
                        ) {
                            selectedReportType = type
                        }
                    }
                }
                
                Divider()
                
                // Target selection
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Include Targets")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button("Select All") {
                            selectedTargets = Set(appState.targets.map { $0.id })
                        }
                        
                        Button("Clear All") {
                            selectedTargets.removeAll()
                        }
                    }
                    
                    if appState.targets.isEmpty {
                        Text("No targets available. Add targets in the Network Scanner.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    } else {
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
                
                Divider()
                
                // Report options
                VStack(alignment: .leading, spacing: 12) {
                    Text("Report Options")
                        .font(.headline)
                    
                    Toggle("Include Detailed Findings", isOn: $includeDetailedFindings)
                    Toggle("Include Remediation Recommendations", isOn: $includeRecommendations)
                }
                
                // Generate button
                Button(action: generateReport) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                        Text("Generate PDF Report")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                }
                .disabled(selectedTargets.isEmpty || isGeneratingReport)
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Preview/Status section
            VStack {
                if let reportData = generatedReportData {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.green)
                        
                        Text("Report Generated Successfully")
                            .font(.headline)
                        
                        Text("Size: \(ByteCountFormatter.string(fromByteCount: Int64(reportData.count), countStyle: .file))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Save Report") {
                            showingFilePicker = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    ContentUnavailableView(
                        "No Report Generated",
                        systemImage: "doc.text",
                        description: Text("Configure your report settings and generate a PDF")
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .fileExporter(
            isPresented: $showingFilePicker,
            document: generatedReportData.map { PDFDocument(data: $0) },
            contentType: .pdf,
            defaultFilename: generateFilename()
        ) { result in
            switch result {
            case .success(let url):
                print("Report saved to: \(url)")
            case .failure(let error):
                print("Failed to save report: \(error)")
            }
        }
    }
    
    private func generateReport() {
        guard !selectedTargets.isEmpty else { return }
        
        isGeneratingReport = true
        
        Task {
            let targets = appState.targets.filter { selectedTargets.contains($0.id) }
            let reportData = await generatePDFReport(type: selectedReportType, targets: targets)
            
            await MainActor.run {
                generatedReportData = reportData
                isGeneratingReport = false
            }
        }
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
        let title = "\(type.rawValue)\nPenetration Testing Report"
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
        let totalVulnerabilities = targets.reduce(0) { $0 + $1.vulnerabilities.count }
        let criticalCount = targets.flatMap { $0.vulnerabilities }.filter { $0.severity == .critical }.count
        let highCount = targets.flatMap { $0.vulnerabilities }.filter { $0.severity == .high }.count
        
        return """
        EXECUTIVE SUMMARY
        
        This penetration testing assessment was conducted on \(targets.count) target(s) to identify security vulnerabilities and weaknesses.
        
        KEY FINDINGS:
        • Total vulnerabilities identified: \(totalVulnerabilities)
        • Critical severity: \(criticalCount)
        • High severity: \(highCount)
        • Targets assessed: \(targets.count)
        
        The assessment revealed several security concerns that require immediate attention. Critical and high-severity vulnerabilities should be addressed as a priority to reduce the organization's risk exposure.
        
        RECOMMENDATIONS:
        1. Implement a vulnerability management program
        2. Regular security assessments and monitoring
        3. Security awareness training for staff
        4. Network segmentation and access controls
        
        DETAILED FINDINGS:
        """
    }
    
    private func generateFilename() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        return "PenTest_Report_\(selectedReportType.rawValue.replacingOccurrences(of: " ", with: "_"))_\(dateString).pdf"
    }
}

struct ReportTypeSelectionView: View {
    let type: ReportingView.ReportType
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(isSelected ? .blue : .secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(type.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct TargetSelectionView: View {
    let target: Target
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack {
            Button(action: { onToggle(!isSelected) }) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(target.name)
                    .font(.headline)
                
                Text(target.ipAddress)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(target.vulnerabilities.count) vulnerabilities")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct PDFDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.pdf] }
    
    var data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}

#Preview {
    ReportingView()
        .environment(AppState())
}
