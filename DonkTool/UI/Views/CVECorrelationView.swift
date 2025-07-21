//
//  CVECorrelationView.swift
//  DonkTool
//
//  Real-time CVE correlation and exploit recommendation interface
//

import SwiftUI

struct CVECorrelationView: View {
    @Environment(AppState.self) private var appState
    @State private var searchSploitManager = SearchSploitManager()
    @State private var showingExploitDetail = false
    @State private var selectedCorrelation: CVECorrelation?
    @State private var selectedExploit: ExploitEntry?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with statistics
            VStack(spacing: 16) {
                HStack {
                    Text("CVE Auto-Correlation")
                        .font(.headerPrimary)
                    
                    Spacer()
                    
                    // Integration statistics
                    HStack(spacing: 16) {
                        StatisticView(
                            title: "CVE Matches",
                            value: "\(appState.integrationEngine.cveCorrelations.count)",
                            icon: "exclamationmark.triangle.fill",
                            color: .orange
                        )
                        
                        StatisticView(
                            title: "With Exploits",
                            value: "\(appState.integrationEngine.cveCorrelations.filter { $0.exploitAvailable }.count)",
                            icon: "bolt.fill",
                            color: .red
                        )
                        
                        StatisticView(
                            title: "Critical",
                            value: "\(appState.integrationEngine.cveCorrelations.filter { $0.severity == "CRITICAL" }.count)",
                            icon: "flame.fill",
                            color: .red
                        )
                    }
                }
                
                // SearchSploit status
                HStack {
                    Image(systemName: searchSploitManager.checkSearchSploitInstallation().icon)
                        .foregroundColor(searchSploitManager.checkSearchSploitInstallation().color)
                    
                    Text(searchSploitManager.checkSearchSploitInstallation().description)
                        .font(.captionPrimary)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if searchSploitManager.checkSearchSploitInstallation() != .installed {
                        Button("Install SearchSploit") {
                            Task {
                                _ = await searchSploitManager.installSearchSploit()
                            }
                        }
                        .primaryButton()
                    }
                }
            }
            .padding()
            .standardContainer()
            
            Divider()
            
            // CVE Correlations List
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Discovered Vulnerabilities")
                        .font(.headerSecondary)
                    
                    Spacer()
                    
                    if !appState.integrationEngine.cveCorrelations.isEmpty {
                        Text("\(appState.integrationEngine.cveCorrelations.count) correlations")
                            .font(.captionPrimary)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                if appState.integrationEngine.cveCorrelations.isEmpty {
                    ContentUnavailableView(
                        "No CVE Correlations",
                        systemImage: "shield.slash",
                        description: Text("Run network scans to discover services and auto-correlate with CVE database")
                    )
                } else {
                    List(appState.integrationEngine.cveCorrelations, id: \.cveId) { correlation in
                        CVECorrelationRowView(
                            correlation: correlation,
                            onExploitTapped: { exploit in
                                selectedExploit = exploit
                                selectedCorrelation = correlation
                                showingExploitDetail = true
                            },
                            onAutoExploitTapped: { correlation in
                                triggerAutoExploit(correlation)
                            }
                        )
                    }
                    .listStyle(.plain)
                }
            }
        }
        .sheet(isPresented: $showingExploitDetail) {
            if let exploit = selectedExploit, let correlation = selectedCorrelation {
                CVEExploitDetailView(exploit: exploit, correlation: correlation, searchSploitManager: searchSploitManager)
            }
        }
    }
    
    private func triggerAutoExploit(_ correlation: CVECorrelation) {
        // Trigger automated exploitation
        NotificationCenter.default.post(
            name: .triggerAttackExecution,
            object: correlation,
            userInfo: [
                "source": "cve_correlation_view",
                "auto_exploit_user_initiated": true
            ]
        )
    }
}

struct CVECorrelationRowView: View {
    let correlation: CVECorrelation
    let onExploitTapped: (ExploitEntry) -> Void
    let onAutoExploitTapped: (CVECorrelation) -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // CVE ID and severity
                VStack(alignment: .leading, spacing: 4) {
                    Text(correlation.cveId)
                        .font(.headerTertiary)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 8) {
                        Text(correlation.severity)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(getSeverityColor(correlation.severity).opacity(0.2))
                            .foregroundColor(getSeverityColor(correlation.severity))
                            .cornerRadius(4)
                        
                        if correlation.exploitAvailable {
                            HStack(spacing: 4) {
                                Image(systemName: "bolt.fill")
                                Text("\(correlation.exploitCount) exploits")
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                    }
                }
                
                Spacer()
                
                // Target information
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(correlation.target):\(correlation.port)")
                        .font(.captionPrimary)
                        .foregroundColor(.blue)
                    
                    Text(correlation.service)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Expand button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            // CVE Description
            Text(correlation.description)
                .font(.bodyPrimary)
                .foregroundColor(.primary)
                .lineLimit(isExpanded ? nil : 2)
            
            // Expandable content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                    
                    // Service details
                    HStack {
                        Text("Service:")
                            .font(.captionPrimary)
                            .fontWeight(.medium)
                        Text("\(correlation.service) \(correlation.version)")
                            .font(.captionPrimary)
                        
                        Spacer()
                        
                        Text("Last Updated:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(correlation.lastUpdated, style: .relative)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    // Available exploits
                    if let exploits = correlation.exploits, !exploits.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Available Exploits (\(exploits.count))")
                                    .font(.captionPrimary)
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                // Auto-exploit button for critical vulnerabilities
                                if correlation.severity == "CRITICAL" || correlation.severity == "HIGH" {
                                    Button("Auto-Exploit") {
                                        onAutoExploitTapped(correlation)
                                    }
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red.opacity(0.2))
                                    .foregroundColor(.red)
                                    .cornerRadius(4)
                                }
                            }
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
                                ForEach(exploits) { exploit in
                                    ExploitCardView(exploit: exploit) {
                                        onExploitTapped(exploit)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.top, 8)
                .padding(.leading, 12)
                .overlay(
                    Rectangle()
                        .frame(width: 2)
                        .foregroundColor(.blue.opacity(0.3)),
                    alignment: .leading
                )
            }
        }
        .padding(.vertical, 8)
    }
    
    private func getSeverityColor(_ severity: String) -> Color {
        switch severity {
        case "CRITICAL": return .red
        case "HIGH": return .orange
        case "MEDIUM": return .yellow
        case "LOW": return .green
        default: return .blue
        }
    }
}

struct ExploitCardView: View {
    let exploit: ExploitEntry
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: exploit.category.icon)
                    .font(.system(size: 14))
                    .foregroundColor(exploit.category.color)
                    .frame(width: 16)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("EDB-\(exploit.id)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text(exploit.type)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer(minLength: 0)
                
                Image(systemName: "arrow.right.circle")
                    .font(.system(size: 12))
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(exploit.severity.color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct CVEExploitDetailView: View {
    let exploit: ExploitEntry
    let correlation: CVECorrelation
    let searchSploitManager: SearchSploitManager
    
    @State private var exploitCode: String?
    @State private var isLoadingCode = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                // Exploit header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("EDB-\(exploit.id)")
                            .font(.headerSecondary)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Text(exploit.severity.rawValue.uppercased())
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(exploit.severity.color.opacity(0.2))
                            .foregroundColor(exploit.severity.color)
                            .cornerRadius(4)
                    }
                    
                    Text(exploit.title)
                        .font(.bodyPrimary)
                        .fontWeight(.medium)
                    
                    HStack {
                        Text("Author: \(exploit.author)")
                            .font(.captionPrimary)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("Date: \(exploit.date)")
                            .font(.captionPrimary)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Platform: \(exploit.platform)")
                            .font(.captionPrimary)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("Type: \(exploit.type)")
                            .font(.captionPrimary)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .standardContainer()
                
                // Target information
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target Information")
                        .font(.headerTertiary)
                        .fontWeight(.medium)
                    
                    HStack {
                        Text("Target:")
                        Text("\(correlation.target):\(correlation.port)")
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Text("Service:")
                        Text(correlation.service)
                            .fontWeight(.medium)
                    }
                    .font(.captionPrimary)
                }
                .padding()
                .standardContainer()
                
                // Exploit code
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Exploit Code")
                            .font(.headerTertiary)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        if isLoadingCode {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else if exploitCode == nil {
                            Button("Load Code") {
                                loadExploitCode()
                            }
                            .primaryButton()
                        }
                    }
                    
                    if let code = exploitCode {
                        ScrollView {
                            Text(code)
                                .font(.caption)
                                .fontDesign(.monospaced)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.black.opacity(0.05))
                                .cornerRadius(8)
                        }
                        .frame(maxHeight: 300)
                    } else if !isLoadingCode {
                        Text("Click 'Load Code' to view the exploit source code")
                            .font(.captionPrimary)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                .padding()
                .standardContainer()
                
                Spacer()
            }
            .navigationTitle("Exploit Details")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func loadExploitCode() {
        isLoadingCode = true
        Task {
            let code = await searchSploitManager.getExploitCode(for: exploit)
            await MainActor.run {
                self.exploitCode = code ?? "Failed to load exploit code"
                self.isLoadingCode = false
            }
        }
    }
}

struct StatisticView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(value)
                    .font(.headerTertiary)
                    .fontWeight(.bold)
            }
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    CVECorrelationView()
        .environment(AppState())
}