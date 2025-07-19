//
//  CVEManagerView.swift
//  DonkTool
//
//  CVE management interface
//

import SwiftUI

struct CVEManagerView: View {
    @Environment(AppState.self) private var appState
    @State private var searchText = ""
    @State private var selectedSeverity: String? = nil
    @State private var isShowingDetail = false
    @State private var selectedCVE: CVEItem? = nil
    
    private let severityOptions = ["Critical", "High", "Medium", "Low"]
    
    var filteredCVEs: [CVEItem] {
        var filtered = appState.cveDatabase.searchCVEs(query: searchText)
        
        if let severity = selectedSeverity, !severity.isEmpty {
            filtered = filtered.filter { $0.baseSeverity?.lowercased() == severity.lowercased() }
        }
        
        return filtered.sorted { ($0.baseScore ?? 0) > ($1.baseScore ?? 0) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with controls
            VStack(spacing: 16) {
                HStack {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search CVEs...", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // Severity filter
                    Picker("Severity", selection: $selectedSeverity) {
                        Text("All Severities").tag(String?.none)
                        ForEach(severityOptions, id: \.self) { severity in
                            Text(severity).tag(String?.some(severity))
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: 150)
                    
                    Spacer()
                    
                    // Update button
                    Button("Update Database") {
                        Task {
                            await appState.cveDatabase.updateDatabase()
                        }
                    }
                    .disabled(appState.cveDatabase.isLoading)
                }
                
                // Stats row
                HStack {
                    Text("\(filteredCVEs.count) CVEs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let lastUpdate = appState.cveDatabase.lastUpdateTime {
                        Text("Last updated: \(lastUpdate, style: .relative) ago")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let error = appState.cveDatabase.lastError {
                        Text("Error: \(error)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // CVE List
            if appState.cveDatabase.isLoading {
                VStack {
                    ProgressView("Updating CVE Database...")
                        .padding()
                    Spacer()
                }
            } else if filteredCVEs.isEmpty {
                ContentUnavailableView(
                    "No CVEs Found",
                    systemImage: "shield.slash",
                    description: Text(searchText.isEmpty ? "Update the database to load CVEs" : "Try adjusting your search criteria")
                )
            } else {
                List(filteredCVEs) { cve in
                    CVERowView(cve: cve)
                        .onTapGesture {
                            selectedCVE = cve
                            isShowingDetail = true
                        }
                }
                .listStyle(.plain)
            }
        }
        .sheet(isPresented: $isShowingDetail) {
            if let cve = selectedCVE {
                CVEDetailView(cve: cve)
            }
        }
        .task {
            // Add small delay to prevent publishing during view updates
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms delay
            if appState.cveDatabase.cves.isEmpty && !appState.cveDatabase.isLoading {
                await appState.cveDatabase.updateDatabase()
            }
        }
    }
}

struct CVERowView: View {
    let cve: CVEItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(cve.id)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if let score = cve.baseScore {
                    CVSSScoreView(score: score, severity: cve.baseSeverity)
                }
            }
            
            Text(cve.description)
                .font(.body)
                .lineLimit(2)
                .foregroundColor(.primary)
            
            HStack {
                Spacer()
                
                Text(cve.publishedDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct CVSSScoreView: View {
    let score: Double
    let severity: String?
    
    var body: some View {
        HStack(spacing: 4) {
            Text(String(format: "%.1f", score))
                .font(.caption)
                .fontWeight(.semibold)
            
            if let severity = severity {
                Text(severity.uppercased())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(backgroundColorForSeverity(severity))
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
        }
    }
    
    private func backgroundColorForSeverity(_ severity: String) -> Color {
        switch severity.lowercased() {
        case "critical": return .red
        case "high": return .orange
        case "medium": return .yellow
        case "low": return .blue
        default: return .gray
        }
    }
}

struct CVEDetailView: View {
    let cve: CVEItem
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(cve.id)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        if let score = cve.baseScore {
                            CVSSScoreView(score: score, severity: cve.baseSeverity)
                        }
                    }
                    
                    Divider()
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        
                        Text(cve.description)
                            .font(.body)
                    }
                    
                    // Details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Details")
                            .font(.headline)
                        
                        
                        DetailRow(label: "Published", value: cve.publishedDate.formatted(date: .abbreviated, time: .omitted))
                        DetailRow(label: "Modified", value: cve.lastModifiedDate.formatted(date: .abbreviated, time: .omitted))
                    }
                    
                    // References
                    if !cve.references.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("References")
                                .font(.headline)
                            
                            ForEach(cve.references, id: \.self) { reference in
                                Link(reference, destination: URL(string: reference)!)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("CVE Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        // Close action handled by parent
                    }
                }
            }
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .fontWeight(.medium)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

#Preview {
    CVEManagerView()
        .environment(AppState())
}
