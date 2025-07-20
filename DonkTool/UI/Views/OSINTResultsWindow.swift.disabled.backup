//
//  OSINTResultsWindow.swift
//  DonkTool
//
//  Dedicated window for viewing OSINT investigation results
//

import SwiftUI
import Foundation

struct OSINTResultsWindow: View {
    @ObservedObject var osint: OSINTModule
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedFindingType: OSINTFindingType? = nil
    @State private var selectedConfidence: OSINTConfidence? = nil
    @State private var selectedSource: OSINTSource? = nil
    
    var filteredFindings: [OSINTFinding] {
        var results = osint.findings
        
        // Filter by search text
        if !searchText.isEmpty {
            results = results.filter { finding in
                finding.content.localizedCaseInsensitiveContains(searchText) ||
                finding.type.rawValue.localizedCaseInsensitiveContains(searchText) ||
                finding.source.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by type
        if let type = selectedFindingType {
            results = results.filter { $0.type == type }
        }
        
        // Filter by confidence
        if let confidence = selectedConfidence {
            results = results.filter { $0.confidence == confidence }
        }
        
        // Filter by source
        if let source = selectedSource {
            results = results.filter { $0.source == source }
        }
        
        return results.sorted { $0.timestamp > $1.timestamp }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with controls
            headerView
            
            Divider()
            
            // Filter bar
            filterBar
            
            Divider()
            
            // Main results area
            if filteredFindings.isEmpty {
                emptyResultsView
            } else {
                resultsListView
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("OSINT Investigation Results")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Showing \(filteredFindings.count) of \(osint.findings.count) findings")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Export button
            Button("Export Results") {
                exportResults()
            }
            .buttonStyle(.bordered)
            
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var filterBar: some View {
        HStack {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search findings...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .frame(maxWidth: 300)
            
            Spacer()
            
            // Filter controls
            HStack(spacing: 12) {
                // Type filter
                Picker("Type", selection: $selectedFindingType) {
                    Text("All Types").tag(nil as OSINTFindingType?)
                    ForEach(OSINTFindingType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type as OSINTFindingType?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 120)
                
                // Confidence filter
                Picker("Confidence", selection: $selectedConfidence) {
                    Text("All Confidence").tag(nil as OSINTConfidence?)
                    ForEach(OSINTConfidence.allCases, id: \.self) { confidence in
                        Text(confidence.rawValue).tag(confidence as OSINTConfidence?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 120)
                
                // Source filter
                Picker("Source", selection: $selectedSource) {
                    Text("All Sources").tag(nil as OSINTSource?)
                    ForEach(OSINTSource.allCases, id: \.self) { source in
                        Text(source.rawValue).tag(source as OSINTSource?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 120)
                
                // Clear filters
                Button("Clear Filters") {
                    selectedFindingType = nil
                    selectedConfidence = nil
                    selectedSource = nil
                    searchText = ""
                }
                .font(.caption)
            }
        }
        .padding()
    }
    
    private var emptyResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No Results Found")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            if !searchText.isEmpty || selectedFindingType != nil || selectedConfidence != nil || selectedSource != nil {
                Text("Try adjusting your filters or search terms")
                    .font(.body)
                    .foregroundColor(.secondary)
            } else {
                Text("No OSINT data has been gathered yet")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var resultsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredFindings) { finding in
                    DetailedFindingCard(finding: finding)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
    
    private func exportResults() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json, .plainText]
        panel.nameFieldStringValue = "osint-results-\(Date().formatted(.iso8601.year().month().day()))"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                exportToFile(url: url)
            }
        }
    }
    
    private func exportToFile(url: URL) {
        do {
            let exportData = ExportData(
                exportDate: Date(),
                totalFindings: filteredFindings.count,
                findings: filteredFindings.map { finding in
                    ExportFinding(
                        type: finding.type.rawValue,
                        source: finding.source.rawValue,
                        confidence: finding.confidence.rawValue,
                        content: finding.content,
                        metadata: finding.metadata,
                        timestamp: finding.timestamp
                    )
                }
            )
            
            if url.pathExtension == "json" {
                let jsonData = try JSONEncoder().encode(exportData)
                try jsonData.write(to: url)
            } else {
                let textContent = generateTextReport(exportData)
                try textContent.write(to: url, atomically: true, encoding: .utf8)
            }
        } catch {
            print("Export failed: \(error)")
        }
    }
    
    private func generateTextReport(_ data: ExportData) -> String {
        var report = """
        OSINT Investigation Results
        Export Date: \(data.exportDate.formatted(.dateTime))
        Total Findings: \(data.totalFindings)
        
        ================================
        
        """
        
        for (index, finding) in data.findings.enumerated() {
            report += """
            Finding #\(index + 1)
            Type: \(finding.type)
            Source: \(finding.source)
            Confidence: \(finding.confidence)
            Timestamp: \(finding.timestamp.formatted(.dateTime))
            
            Content:
            \(finding.content)
            
            """
            
            if !finding.metadata.isEmpty {
                report += "Additional Details:\n"
                for (key, value) in finding.metadata {
                    report += "  \(key): \(value)\n"
                }
            }
            
            report += "--------------------------------\n\n"
        }
        
        return report
    }
}

// MARK: - Supporting Views

struct DetailedFindingCard: View {
    let finding: OSINTFinding
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with improved spacing
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: finding.type.icon)
                        .foregroundColor(finding.type.color)
                        .font(.title)
                        .frame(width: 40, height: 40)
                        .background(finding.type.color.opacity(0.1))
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(finding.type.rawValue)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 8) {
                            Image(systemName: finding.source.icon)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(finding.source.rawValue)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    confidenceBadge
                    
                    Text(finding.timestamp.formatted(.relative(presentation: .named)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            // Content with improved typography
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Intelligence Gathered")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Priority indicator for high-value findings
                    if finding.content.contains("BREACH") || finding.content.contains("FOUND") || finding.content.contains("SENSITIVE") {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text("High Value")
                        }
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(4)
                    }
                }
                
                Text(finding.content)
                    .font(.body)
                    .lineSpacing(4)
                    .padding(16)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                    .textSelection(.enabled)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(finding.type.color.opacity(0.3), lineWidth: 1)
                    )
            }
            
            // Enhanced Metadata Section
            if !finding.metadata.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                                .font(.subheadline)
                            
                            Text("Technical Details")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isExpanded.toggle()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Text(isExpanded ? "Hide" : "Show")
                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    if isExpanded {
                        LazyVGrid(columns: [
                            GridItem(.flexible(minimum: 100)),
                            GridItem(.flexible(minimum: 200))
                        ], alignment: .leading, spacing: 12) {
                            ForEach(Array(finding.metadata.keys.sorted()), id: \.self) { key in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(formatMetadataKey(key))
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.secondary)
                                        .textCase(.uppercase)
                                    
                                    Text(finding.metadata[key] ?? "N/A")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .padding(8)
                                        .background(Color.blue.opacity(0.05))
                                        .cornerRadius(6)
                                        .textSelection(.enabled)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
            }
            
            // Enhanced Actions
            HStack(spacing: 12) {
                // URL actions
                if finding.content.contains("http") || !finding.metadata.filter({ $0.value.contains("http") }).isEmpty {
                    Button(action: {
                        if let url = URL(string: extractURL(from: finding.content)) {
                            NSWorkspace.shared.open(url)
                        } else {
                            // Try metadata URLs
                            for (_, value) in finding.metadata {
                                if value.contains("http"), let url = URL(string: value) {
                                    NSWorkspace.shared.open(url)
                                    break
                                }
                            }
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "globe")
                            Text("Open URL")
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                }
                
                Button(action: {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(finding.content, forType: .string)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                        Text("Copy")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                
                // Export individual finding
                Button(action: {
                    exportFinding()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                
                Spacer()
                
                // Risk indicator
                if finding.content.contains("BREACH") || finding.content.contains("ALERT") {
                    HStack(spacing: 4) {
                        Image(systemName: "shield.fill")
                        Text("Security Risk")
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(finding.type.color.opacity(0.2), lineWidth: 2)
        )
    }
    
    private func exportFinding() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json, .plainText]
        panel.nameFieldStringValue = "finding-\(finding.type.rawValue.lowercased().replacingOccurrences(of: " ", with: "-"))"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    let exportData = [
                        "type": finding.type.rawValue,
                        "source": finding.source.rawValue,
                        "confidence": finding.confidence.rawValue,
                        "content": finding.content,
                        "timestamp": finding.timestamp.formatted(.iso8601),
                        "metadata": finding.metadata
                    ] as [String: Any]
                    
                    if url.pathExtension == "json" {
                        let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
                        try jsonData.write(to: url)
                    } else {
                        let textContent = """
                        OSINT Finding Export
                        Type: \(finding.type.rawValue)
                        Source: \(finding.source.rawValue)
                        Confidence: \(finding.confidence.rawValue)
                        Timestamp: \(finding.timestamp.formatted(.dateTime))
                        
                        Content:
                        \(finding.content)
                        
                        Metadata:
                        \(finding.metadata.map { "\($0.key): \($0.value)" }.joined(separator: "\n"))
                        """
                        try textContent.write(to: url, atomically: true, encoding: .utf8)
                    }
                } catch {
                    print("Export failed: \(error)")
                }
            }
        }
    }
    
    private var confidenceBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(finding.confidence.color)
                .frame(width: 8, height: 8)
            
            Text(finding.confidence.rawValue)
                .font(.caption)
                .fontWeight(.bold)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(finding.confidence.color.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(finding.confidence.color.opacity(0.3), lineWidth: 1)
                )
        )
        .foregroundColor(finding.confidence.color)
    }
    
    private func formatMetadataKey(_ key: String) -> String {
        return key.replacingOccurrences(of: "_", with: " ")
                  .replacingOccurrences(of: "-", with: " ")
                  .capitalized
    }
    
    private func extractURL(from text: String) -> String {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        return matches?.first?.url?.absoluteString ?? text
    }
}

// MARK: - Export Data Models
// Note: ExportData and ExportFinding are defined in AdvancedOSINTDashboardView.swift

#Preview {
    OSINTResultsWindow(osint: OSINTModule.shared)
}