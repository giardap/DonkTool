//
//  FunctionalOSINTDashboard.swift
//  DonkTool
//
//  Modern OSINT Dashboard with NavigationSplitView layout
//

import SwiftUI
import Foundation

struct FunctionalOSINTDashboard: View {
    @Environment(AppState.self) private var appState
    @State private var searchTarget = ""
    @State private var selectedSearchType: OSINTSearchType = .domain
    @State private var selectedSources: Set<OSINTSource> = Set([
        .whois, .socialMedia, .breachData, .dnsRecon, .googleDorking
    ])
    @State private var isSearching = false
    @State private var searchResults: [OSINTFinding] = []
    @State private var searchHistory: [OSINTSearchHistory] = []
    @State private var showingAPIKeySettings = false
    @State private var currentSearchProgress: Double = 0.0
    @State private var currentSearchSource = ""
    @State private var selectedSidebar: String? = "sources"
    @State private var selectedResult: OSINTFinding?
    
    var body: some View {
        NavigationSplitView {
            // Source Configuration Sidebar
            sourceConfigurationSidebar
                .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 320)
        } content: {
            // Search and Results
            searchAndResultsView
                .navigationSplitViewColumnWidth(min: 400, ideal: 500, max: 600)
        } detail: {
            // Analysis Detail
            analysisDetailView
                .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 400)
        }
        .navigationSplitViewStyle(.prominentDetail)
        .sheet(isPresented: $showingAPIKeySettings) {
            InlineAPISettingsView()
        }
    }
    
    // MARK: - Source Configuration Sidebar
    
    private var sourceConfigurationSidebar: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "binoculars.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("OSINT Sources")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("\(selectedSources.count) selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // Quick selection controls
                HStack(spacing: 8) {
                    Button("Select All") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedSources = Set(OSINTSource.allCases)
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button("Clear") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedSources.removeAll()
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.surfaceBackground)
            .overlay(
                RoundedRectangle(cornerRadius: .radius_md)
                    .stroke(Color.borderPrimary.opacity(0.2), lineWidth: 1)
            )
            
            Divider()
            
            // Source categories
            List(selection: $selectedSidebar) {
                ForEach(groupedSources, id: \.category) { group in
                    Section(group.category) {
                        ForEach(group.sources, id: \.self) { source in
                            ModernSourceRow(
                                source: source,
                                isSelected: selectedSources.contains(source)
                            ) {
                                withAnimation(.easeInOut(duration: 0.1)) {
                                    if selectedSources.contains(source) {
                                        selectedSources.remove(source)
                                    } else {
                                        selectedSources.insert(source)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(Color.primaryBackground)
        }
        .navigationTitle("Sources")
    }
    
    // MARK: - Search and Results View
    
    private var searchAndResultsView: some View {
        VStack(spacing: 0) {
            // Improved search header with better layout
            VStack(spacing: 20) {
                // Main search row
                HStack(spacing: 16) {
                    // Search input with icon
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.title3)
                        
                        TextField("Enter target (domain, email, username, IP)", text: $searchTarget)
                            .font(.body)
                            .foregroundColor(.primary)
                            .accentColor(.blue)
                            .onSubmit {
                                if !searchTarget.isEmpty && !selectedSources.isEmpty {
                                    performOSINTSearch()
                                }
                            }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.secondaryBackground, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(searchTarget.isEmpty ? Color.borderPrimary.opacity(0.4) : Color.blue.opacity(0.6), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    
                    // Search type picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Search Type")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                        
                        Picker("Search Type", selection: $selectedSearchType) {
                            ForEach(OSINTSearchType.allCases, id: \.self) { type in
                                Text(type.rawValue.capitalized)
                                    .foregroundColor(.primary)
                                    .tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 160, height: 38)
                        .background(Color.secondaryBackground, in: RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.borderPrimary.opacity(0.4), lineWidth: 1)
                        )
                    }
                }
                
                // Action buttons row
                HStack(spacing: 12) {
                    Button(action: performOSINTSearch) {
                        HStack(spacing: 8) {
                            if isSearching {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "play.fill")
                            }
                            Text(isSearching ? "Searching..." : "Start OSINT Search")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(searchTarget.isEmpty || selectedSources.isEmpty || isSearching)
                    
                    Button("Clear") {
                        searchTarget = ""
                        searchResults.removeAll()
                    }
                    .buttonStyle(.bordered)
                    .disabled(searchTarget.isEmpty && searchResults.isEmpty)
                }
                
                // Progress indicator
                if isSearching {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Intelligence Gathering in Progress")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(Int(currentSearchProgress * 100))%")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                        
                        ProgressView(value: currentSearchProgress)
                            .progressViewStyle(.linear)
                            .tint(.blue)
                    }
                    .padding(.horizontal, 4)
                }
                
                // Quick stats
                if !searchResults.isEmpty {
                    HStack(spacing: 20) {
                        VStack(spacing: 2) {
                            Text("\(searchResults.count)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            Text("Findings")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 2) {
                            Text("\(Set(searchResults.map { $0.source }).count)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            Text("Sources")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 2) {
                            Text("\(searchResults.filter { $0.confidence == .high }.count)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                            Text("High Confidence")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding(20)
            .background(Color.surfaceBackground)
            
            Divider()
            
            // Results area
            resultsContentView
        }
        .navigationTitle("OSINT Intelligence")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("API Settings") {
                    showingAPIKeySettings = true
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    @ViewBuilder
    private var resultsContentView: some View {
        if searchResults.isEmpty && !isSearching {
            // Empty state
            VStack(spacing: 20) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 48, weight: .thin))
                    .foregroundStyle(.tertiary)
                
                VStack(spacing: 8) {
                    Text("Ready for Intelligence Gathering")
                        .font(.title3)
                        .fontWeight(.medium)
                    
                    Text("Select sources from the sidebar and enter a target to begin OSINT collection")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.primaryBackground)
        } else {
            // Results list
            List(selection: $selectedResult) {
                ForEach(searchResults) { finding in
                    ModernFindingRow(finding: finding)
                        .tag(finding)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.primaryBackground)
            .overlay(alignment: .topTrailing) {
                if !searchResults.isEmpty {
                    Menu {
                        Button("Export JSON") { exportResults(format: .json) }
                        Button("Export CSV") { exportResults(format: .csv) }
                        Button("Copy All") { copyResultsToClipboard() }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
            }
        }
    }
    
    // MARK: - Analysis Detail View
    
    private var analysisDetailView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Analysis")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if !searchResults.isEmpty {
                    Text("\(searchResults.count) findings")
                        .font(.caption)
                        .foregroundColor(.primary)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.borderPrimary.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            .padding()
            .background(Color.surfaceBackground)
            .overlay(
                RoundedRectangle(cornerRadius: .radius_md)
                    .stroke(Color.borderPrimary.opacity(0.2), lineWidth: 1)
            )
            
            Divider()
            
            if !searchResults.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                        // Statistics section
                        AnalysisStatsSection(findings: searchResults)
                        
                        // Confidence breakdown
                        AnalysisConfidenceSection(findings: searchResults)
                        
                        // Source breakdown
                        AnalysisSourceSection(findings: searchResults)
                        
                        // Recent searches
                        if !searchHistory.isEmpty {
                            AnalysisHistorySection(history: Array(searchHistory.prefix(5))) { history in
                                loadSearchFromHistory(history)
                            }
                        }
                    }
                    .padding()
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 32, weight: .thin))
                        .foregroundStyle(.tertiary)
                    
                    Text("Analysis will appear after search")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Analysis")
    }
    
    // MARK: - Helper Properties
    
    private var groupedSources: [SourceGroup] {
        [
            SourceGroup(category: "Core Intelligence", sources: [
                .whois, .dnsRecon, .googleDorking, .subdomainEnum
            ]),
            SourceGroup(category: "Security & Breaches", sources: [
                .breachData, .haveibeenpwned, .darkWebSearch
            ]),
            SourceGroup(category: "Social & People", sources: [
                .socialMedia, .linkedinOSINT, .peopleSearch, .sherlock
            ]),
            SourceGroup(category: "Technical Scanning", sources: [
                .shodan, .censys, .theHarvester, .sslAnalysis
            ]),
            SourceGroup(category: "Business & Records", sources: [
                .businessSearch, .publicRecords, .vehicleRecords, .phoneNumberLookup
            ]),
            SourceGroup(category: "Development & Code", sources: [
                .githubOSINT, .pastebin
            ]),
            SourceGroup(category: "Communication", sources: [
                .emailVerification, .socialConnections, .digitalFootprint
            ])
        ]
    }
    
    // MARK: - Functions
    
    private func performOSINTSearch() {
        guard !searchTarget.isEmpty && !selectedSources.isEmpty else { return }
        
        isSearching = true
        currentSearchProgress = 0.0
        searchResults.removeAll()
        
        // Add to search history
        let historyItem = OSINTSearchHistory(
            target: searchTarget,
            searchType: selectedSearchType,
            sources: Array(selectedSources),
            timestamp: Date(),
            resultCount: 0
        )
        
        Task {
            let osintModule = OSINTModule.shared
            let report = await osintModule.gatherIntelligence(
                target: searchTarget,
                searchType: selectedSearchType,
                sources: Array(selectedSources)
            )
            
            await MainActor.run {
                searchResults = report.findings
                isSearching = false
                currentSearchProgress = 1.0
                
                // Update history with result count
                var updatedHistory = historyItem
                updatedHistory.resultCount = report.findings.count
                searchHistory.insert(updatedHistory, at: 0)
                
                // Keep only last 10 searches
                if searchHistory.count > 10 {
                    searchHistory = Array(searchHistory.prefix(10))
                }
            }
        }
    }
    
    private func loadSearchFromHistory(_ history: OSINTSearchHistory) {
        searchTarget = history.target
        selectedSearchType = history.searchType
        selectedSources = Set(history.sources)
    }
    
    private func exportResults(format: OSINTExportFormat) {
        // TODO: Implement export functionality
        print("Exporting results as \(format)")
    }
    
    private func copyResultsToClipboard() {
        let content = searchResults.map { "\($0.source.rawValue): \($0.content)" }.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content, forType: .string)
    }
}

// MARK: - Modern UI Components

struct ModernSourceRow: View {
    let source: OSINTSource
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isSelected ? .blue : .secondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(source.rawValue)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(source.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // API indicator
                if apiBasedSources.contains(source) {
                    Image(systemName: "key.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private var apiBasedSources: Set<OSINTSource> {
        [.shodan, .haveibeenpwned, .emailVerification, .googleDorking, .censys, .githubOSINT]
    }
}

struct ModernFindingRow: View {
    let finding: OSINTFinding
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: finding.source.iconName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.blue)
                        .frame(width: 20)
                    
                    Text(finding.source.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    // Confidence indicator
                    Label(finding.confidence.rawValue, systemImage: "circle.fill")
                        .font(.caption)
                        .foregroundStyle(finding.confidence.color)
                        .labelStyle(.iconOnly)
                    
                    Text(finding.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(finding.content)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.borderPrimary.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Analysis Components

struct AnalysisStatsSection: View {
    let findings: [OSINTFinding]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                StatCard(title: "Total", value: "\(findings.count)", color: .blue)
                StatCard(title: "High Confidence", value: "\(highConfidenceCount)", color: .green)
                StatCard(title: "Sources", value: "\(uniqueSourcesCount)", color: .orange)
                StatCard(title: "Recent", value: "\(recentCount)", color: .purple)
            }
        }
    }
    
    private var highConfidenceCount: Int {
        findings.filter { $0.confidence == .high }.count
    }
    
    private var uniqueSourcesCount: Int {
        Set(findings.map { $0.source }).count
    }
    
    private var recentCount: Int {
        findings.filter { $0.timestamp.timeIntervalSinceNow > -3600 }.count
    }
}


struct AnalysisConfidenceSection: View {
    let findings: [OSINTFinding]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Confidence Distribution")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ForEach(confidenceBreakdown, id: \.confidence) { item in
                    HStack {
                        Circle()
                            .fill(item.confidence.color)
                            .frame(width: 8, height: 8)
                        
                        Text(item.confidence.rawValue.capitalized)
                            .font(.body)
                        
                        Spacer()
                        
                        Text("\(item.count)")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.borderPrimary.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    private var confidenceBreakdown: [(confidence: OSINTConfidence, count: Int)] {
        let grouped = Dictionary(grouping: findings, by: { $0.confidence })
        return grouped.map { (confidence: $0.key, count: $0.value.count) }
            .sorted { $0.confidence.sortOrder > $1.confidence.sortOrder }
    }
}

struct AnalysisSourceSection: View {
    let findings: [OSINTFinding]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Source Distribution")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 6) {
                ForEach(sourceBreakdown.prefix(5), id: \.source) { item in
                    HStack {
                        Image(systemName: item.source.iconName)
                            .font(.caption)
                            .foregroundStyle(.blue)
                            .frame(width: 16)
                        
                        Text(item.source.rawValue)
                            .font(.body)
                        
                        Spacer()
                        
                        Text("\(item.count)")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.borderPrimary.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    private var sourceBreakdown: [(source: OSINTSource, count: Int)] {
        let grouped = Dictionary(grouping: findings, by: { $0.source })
        return grouped.map { (source: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }
}

struct AnalysisHistorySection: View {
    let history: [OSINTSearchHistory]
    let onSelect: (OSINTSearchHistory) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Searches")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 4) {
                ForEach(history) { item in
                    Button(action: { onSelect(item) }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.target)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                
                                Text("\(item.searchType.rawValue) • \(item.resultCount) results")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(item.timestamp.formatted(date: .omitted, time: .shortened))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.borderPrimary.opacity(0.2), lineWidth: 1)
                    )
                }
            }
        }
    }
}

// MARK: - Data Models

enum OSINTExportFormat {
    case json
    case csv
}

struct SourceGroup: Equatable {
    let category: String
    let sources: [OSINTSource]
}

struct OSINTSearchHistory: Identifiable {
    let id = UUID()
    let target: String
    let searchType: OSINTSearchType
    let sources: [OSINTSource]
    let timestamp: Date
    var resultCount: Int
}

// MARK: - Extensions

extension OSINTSource {
    var description: String {
        switch self {
        case .whois: return "Domain registration information"
        case .shodan: return "Internet-connected device search"
        case .socialMedia: return "Social media profile discovery"
        case .breachData: return "Data breach exposure checking"
        case .dnsRecon: return "DNS record enumeration"
        case .googleDorking: return "Advanced Google search queries"
        case .githubOSINT: return "GitHub repository and user analysis"
        case .haveibeenpwned: return "Password breach verification"
        case .subdomainEnum: return "Subdomain discovery"
        case .peopleSearch: return "Public records people search"
        default: return "OSINT data collection"
        }
    }
    
    var iconName: String {
        switch self {
        case .whois: return "globe"
        case .shodan: return "network"
        case .socialMedia: return "person.2"
        case .breachData: return "exclamationmark.triangle"
        case .dnsRecon: return "server.rack"
        case .googleDorking: return "magnifyingglass"
        case .githubOSINT: return "chevron.left.forwardslash.chevron.right"
        case .haveibeenpwned: return "shield.lefthalf.filled"
        case .subdomainEnum: return "folder.badge.questionmark"
        case .peopleSearch: return "person.crop.circle"
        case .emailVerification: return "envelope"
        case .theHarvester: return "leaf"
        case .sherlock: return "magnifyingglass.circle"
        case .darkWebSearch: return "moon"
        case .businessSearch: return "building.2"
        case .vehicleRecords: return "car"
        case .phoneNumberLookup: return "phone"
        case .publicRecords: return "doc.text"
        case .linkedinOSINT: return "person.badge.plus"
        case .censys: return "eye"
        case .sslAnalysis: return "lock"
        case .socialConnections: return "link"
        case .digitalFootprint: return "footprints"
        case .pastebin: return "doc.plaintext"
        default: return "questionmark.circle"
        }
    }
}

extension OSINTConfidence {
    var color: Color {
        switch self {
        case .low: return .orange
        case .medium: return .yellow
        case .high: return .green
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        }
    }
}

// MARK: - Inline API Settings View

struct InlineAPISettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKeys: [String: String] = [:]
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("API Configuration")
                    .font(.headerPrimary)
                
                Text("Configure API keys for enhanced OSINT capabilities")
                    .font(.bodySecondary)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 16) {
                    APIKeyField(title: "Hunter.io API Key", key: "hunter", description: "Email finder and verification (25 free searches/month)")
                    APIKeyField(title: "Have I Been Pwned API Key", key: "haveibeenpwned", description: "Data breach checking service ($3.50/month)")
                    APIKeyField(title: "Google CSE API Key", key: "google_cse", description: "Custom search engine (100 free searches/day)")
                }
                
                Spacer()
            }
            .standardContainer()
            .navigationTitle("API Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { 
                        saveAPIKeys()
                        dismiss() 
                    }
                    .primaryButton()
                }
            }
        }
        .frame(width: 500, height: 400)
    }
    
    private func saveAPIKeys() {
        // Save API keys to UserDefaults or Keychain
        for (key, value) in apiKeys {
            UserDefaults.standard.set(value, forKey: "osint_api_\(key)")
        }
    }
}

struct APIKeyField: View {
    let title: String
    let key: String
    let description: String
    @State private var value: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headerTertiary)
            
            Text(description)
                .font(.captionPrimary)
                .foregroundColor(.secondary)
            
            SecureField("Enter API key", text: $value)
                .textFieldStyle(.roundedBorder)
        }
    }
}

#Preview {
    FunctionalOSINTDashboard()
        .environment(AppState())
        .frame(width: 1200, height: 800)
}