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
            // Header
            VStack(alignment: .leading, spacing: .spacing_md) {
                HStack {
                    Image(systemName: "doc.text")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Report Generation")
                            .font(.headerPrimary)
                        
                        Text("Create comprehensive security reports")
                            .font(.captionPrimary)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if isGeneratingReport {
                        HStack(spacing: .spacing_xs) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Generating...")
                                .font(.captionPrimary)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .standardContainer()
            
            Divider()
            
            ScrollView {
                VStack(spacing: .spacing_lg) {
                    // Report type selection
                    reportTypeSection
                    
                    // Target selection
                    targetSelectionSection
                    
                    // Report options
                    reportOptionsSection
                    
                    // Generate button
                    generateButtonSection
                }
                .padding(.spacing_md)
            }
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
    
    private var reportTypeSection: some View {
        VStack(alignment: .leading, spacing: .spacing_md) {
            Text("Report Type")
                .sectionHeader()
            
            VStack(spacing: .spacing_xs) {
                ForEach(ReportType.allCases, id: \.self) { type in
                    ReportTypeSelectionView(
                        type: type,
                        isSelected: selectedReportType == type
                    ) {
                        selectedReportType = type
                    }
                }
            }
            .cardStyle()
        }
    }
    
    private var targetSelectionSection: some View {
        VStack(alignment: .leading, spacing: .spacing_md) {
            HStack {
                Text("Include Targets")
                    .sectionHeader()
                
                Spacer()
                
                Button("Select All") {
                    selectedTargets = Set(appState.targets.map { $0.id })
                }
                .secondaryButton()
                .controlSize(.small)
                
                Button("Clear All") {
                    selectedTargets.removeAll()
                }
                .secondaryButton()
                .controlSize(.small)
            }
            
            if appState.targets.isEmpty {
                EmptyStateView(
                    icon: "network",
                    title: "No Targets Available",
                    subtitle: "Add targets in the Network Scanner to include them in reports",
                    action: nil
                )
                .frame(height: 200)
            } else {
                VStack(spacing: .spacing_xs) {
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
                .cardStyle()
            }
        }
    }
    
    private var reportOptionsSection: some View {
        VStack(alignment: .leading, spacing: .spacing_md) {
            Text("Report Options")
                .sectionHeader()
            
            VStack(spacing: .spacing_sm) {
                Toggle("Include Detailed Findings", isOn: $includeDetailedFindings)
                    .font(.bodySecondary)
                
                Divider()
                
                Toggle("Include Remediation Recommendations", isOn: $includeRecommendations)
                    .font(.bodySecondary)
            }
            .cardStyle()
        }
    }
    
    private var generateButtonSection: some View {
        VStack(spacing: .spacing_md) {
            if let reportData = generatedReportData {
                VStack(spacing: .spacing_md) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.green)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Report Generated")
                                .font(.headerTertiary)
                            
                            Text("Size: \(ByteCountFormatter.string(fromByteCount: Int64(reportData.count), countStyle: .file))")
                                .font(.captionPrimary)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    Button("Save Report") {
                        showingFilePicker = true
                    }
                    .primaryButton()
                    .frame(maxWidth: .infinity)
                }
                .cardStyle()
            }
            
            Button(action: generateReport) {
                HStack {
                    Image(systemName: "doc.text.fill")
                    Text("Generate PDF Report")
                }
            }
            .primaryButton()
            .frame(maxWidth: .infinity)
            .disabled(selectedTargets.isEmpty || isGeneratingReport)
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
            HStack(spacing: .spacing_md) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .blue : .secondary)
                
                VStack(alignment: .leading, spacing: .spacing_xs) {
                    Text(type.rawValue)
                        .font(.bodySecondary)
                        .foregroundColor(.primary)
                    
                    Text(type.description)
                        .font(.captionPrimary)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.spacing_sm)
            .background(isSelected ? Color.accentBackground : Color.clear, in: RoundedRectangle(cornerRadius: .radius_md))
            .overlay(
                RoundedRectangle(cornerRadius: .radius_md)
                    .stroke(isSelected ? Color.borderAccent : Color.clear, lineWidth: 1)
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
        Button(action: { onToggle(!isSelected) }) {
            HStack(spacing: .spacing_md) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundColor(isSelected ? .blue : .secondary)
                
                VStack(alignment: .leading, spacing: .spacing_xs) {
                    Text(target.name)
                        .font(.bodySecondary)
                        .foregroundColor(.primary)
                    
                    Text(target.ipAddress)
                        .font(.captionPrimary)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(target.vulnerabilities.count)")
                    .statusIndicator(.info)
            }
            .padding(.spacing_sm)
            .background(isSelected ? Color.accentBackground : Color.clear, in: RoundedRectangle(cornerRadius: .radius_md))
        }
        .buttonStyle(.plain)
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
