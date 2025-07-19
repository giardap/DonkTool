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
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: finding.type.icon)
                        .foregroundColor(finding.type.color)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(finding.type.rawValue)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Source: \(finding.source.rawValue)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    confidenceBadge
                    
                    Text(finding.timestamp.formatted(.relative(presentation: .named)))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text("Intelligence Gathered:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(finding.content)
                    .font(.body)
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                    .textSelection(.enabled)
            }
            
            // Metadata (if available)
            if !finding.metadata.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Additional Details:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button(isExpanded ? "Hide Details" : "Show Details") {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded.toggle()
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    
                    if isExpanded {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], alignment: .leading, spacing: 8) {
                            ForEach(Array(finding.metadata.keys.sorted()), id: \.self) { key in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(formatMetadataKey(key))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                    
                                    Text(finding.metadata[key] ?? "N/A")
                                        .font(.caption)
                                        .padding(6)
                                        .background(Color.blue.opacity(0.05))
                                        .cornerRadius(4)
                                        .textSelection(.enabled)
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.03))
                        .cornerRadius(8)
                    }
                }
            }
            
            // Actions
            HStack {
                if finding.content.contains("http") {
                    Button("Open URL") {
                        if let url = URL(string: extractURL(from: finding.content)) {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                
                Button("Copy Content") {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(finding.content, forType: .string)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Spacer()
            }
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 2)
    }
    
    private var confidenceBadge: some View {
        Text(finding.confidence.rawValue)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(finding.confidence.color.opacity(0.2))
            .foregroundColor(finding.confidence.color)
            .cornerRadius(6)
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

struct ExportData: Codable {
    let exportDate: Date
    let totalFindings: Int
    let findings: [ExportFinding]
}

struct ExportFinding: Codable {
    let type: String
    let source: String
    let confidence: String
    let content: String
    let metadata: [String: String]
    let timestamp: Date
}

#Preview {
    OSINTResultsWindow(osint: OSINTModule.shared)
}