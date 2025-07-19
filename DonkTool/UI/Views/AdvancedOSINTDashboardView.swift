//
//  AdvancedOSINTDashboardView.swift
//  DonkTool
//
//  Advanced OSINT Dashboard with Real Tool Integration
//

import SwiftUI

struct AdvancedOSINTDashboardView: View {
    @StateObject private var osint = OSINTModule.shared
    @State private var target = ""
    @State private var username = ""
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var fullName = ""
    @State private var selectedSources: Set<OSINTSource> = []
    @State private var showingSettings = false
    @State private var selectedSearchType = OSINTSearchType.domain
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Main Content
            if osint.isGathering {
                gatheringProgressView
            } else {
                configurationView
            }
            
            Divider()
            
            // Results
            resultsView
        }
        .sheet(isPresented: $showingSettings) {
            OSINTAPISettingsView(osint: osint)
        }
        .onAppear {
            if selectedSources.isEmpty {
                selectedSources = Set(OSINTSource.allCases.prefix(3))
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("OSINT Dashboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                HStack {
                    if osint.isGathering {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                    
                    Text(osint.statusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: { showingSettings = true }) {
                Image(systemName: "gear")
            }
            
            Button(action: clearAll) {
                Image(systemName: "trash")
            }
            .disabled(osint.findings.isEmpty)
        }
        .padding()
    }
    
    private var gatheringProgressView: some View {
        VStack(spacing: 16) {
            Text("Gathering Intelligence on \(target)")
                .font(.headline)
            
            ProgressView(value: osint.gatheringProgress)
                .progressViewStyle(LinearProgressViewStyle())
            
            Text("Current: \(osint.currentSource)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(Int(osint.gatheringProgress * 100))% Complete")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var configurationView: some View {
        VStack(spacing: 16) {
            // Search Type Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Search Type")
                    .font(.headline)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach(OSINTSearchType.allCases, id: \.self) { searchType in
                        searchTypeToggle(searchType)
                    }
                }
            }
            
            Divider()
            
            // Input Fields
            VStack(alignment: .leading, spacing: 12) {
                Text("Target Information")
                    .font(.headline)
                
                switch selectedSearchType {
                case .domain:
                    TextField(selectedSearchType.placeholder, text: $target)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                case .username:
                    TextField(selectedSearchType.placeholder, text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                case .email:
                    TextField(selectedSearchType.placeholder, text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                case .phone:
                    TextField(selectedSearchType.placeholder, text: $phoneNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                case .person:
                    TextField(selectedSearchType.placeholder, text: $fullName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                case .company:
                    TextField(selectedSearchType.placeholder, text: $target)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Button("Start OSINT Investigation") {
                    startGathering()
                }
                .buttonStyle(.borderedProminent)
                .disabled(getCurrentTarget().isEmpty || selectedSources.isEmpty)
                .frame(maxWidth: .infinity)
            }
            
            Divider()
            
            sourceSelectionView
        }
        .padding()
    }
    
    private var sourceSelectionView: some View {
        VStack(alignment: .leading) {
            Text("Intelligence Sources")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                ForEach(OSINTSource.allCases, id: \.self) { source in
                    sourceToggle(source)
                }
            }
        }
    }
    
    private func sourceToggle(_ source: OSINTSource) -> some View {
        Button(action: {
            if selectedSources.contains(source) {
                selectedSources.remove(source)
            } else {
                selectedSources.insert(source)
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: source.icon)
                    .font(.title3)
                
                Text(source.rawValue)
                    .font(.caption2)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(8)
            .background(
                selectedSources.contains(source) ? 
                Color.blue.opacity(0.2) : Color.gray.opacity(0.1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        selectedSources.contains(source) ? Color.blue : Color.clear,
                        lineWidth: 2
                    )
            )
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var resultsView: some View {
        VStack(alignment: .leading, spacing: 0) {
            if osint.findings.isEmpty {
                emptyStateView
            } else {
                findingsView
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass.circle")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("No Intelligence Gathered")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Configure a target and sources to begin")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var findingsView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Summary stats
            summaryView
            
            Divider()
            
            // Findings list
            List {
                ForEach(osint.findings) { finding in
                    FindingRowView(finding: finding)
                }
            }
            .listStyle(PlainListStyle())
        }
    }
    
    private var summaryView: some View {
        HStack {
            statItem("Findings", value: osint.findings.count, color: .blue)
            
            Spacer()
            
            statItem("Sources", value: Set(osint.findings.map(\.source)).count, color: .green)
            
            Spacer()
            
            statItem("High Confidence", 
                    value: osint.findings.filter { $0.confidence == .high }.count, 
                    color: .orange)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
    }
    
    private func statItem(_ label: String, value: Int, color: Color) -> some View {
        VStack {
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func searchTypeToggle(_ searchType: OSINTSearchType) -> some View {
        Button(action: {
            selectedSearchType = searchType
            // Update selected sources based on search type
            updateSourcesForSearchType(searchType)
        }) {
            VStack(spacing: 4) {
                Image(systemName: searchType.icon)
                    .font(.title3)
                
                Text(searchType.rawValue)
                    .font(.caption2)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(8)
            .background(
                selectedSearchType == searchType ? 
                Color.blue.opacity(0.2) : Color.gray.opacity(0.1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        selectedSearchType == searchType ? Color.blue : Color.clear,
                        lineWidth: 2
                    )
            )
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func getCurrentTarget() -> String {
        switch selectedSearchType {
        case .domain, .company: return target
        case .username: return username
        case .email: return email
        case .phone: return phoneNumber
        case .person: return fullName
        }
    }
    
    private func updateSourcesForSearchType(_ searchType: OSINTSearchType) {
        selectedSources.removeAll()
        
        switch searchType {
        case .domain:
            selectedSources = [.whois, .shodan, .subdomainEnum, .dnsRecon]
        case .username:
            selectedSources = [.sherlock, .socialMedia, .githubOSINT, .googleDorking]
        case .email:
            selectedSources = [.haveibeenpwned, .emailVerification, .theHarvester, .breachData]
        case .phone:
            selectedSources = [.phoneNumberLookup, .googleDorking, .socialMedia]
        case .person:
            selectedSources = [.socialMedia, .linkedinOSINT, .googleDorking, .breachData]
        case .company:
            selectedSources = [.whois, .linkedinOSINT, .googleDorking, .subdomainEnum]
        }
    }
    
    private func startGathering() {
        let targetToSearch = getCurrentTarget()
        Task {
            await osint.gatherIntelligence(target: targetToSearch, searchType: selectedSearchType, sources: Array(selectedSources))
        }
    }
    
    private func clearAll() {
        osint.clearFindings()
    }
}

// MARK: - Component Views

struct FindingRowView: View {
    let finding: OSINTFinding
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: finding.type.icon)
                    .foregroundColor(finding.type.color)
                    .font(.caption)
                
                Text(finding.type.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
                
                confidenceBadge
                
                Text(finding.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(finding.content)
                .font(.subheadline)
                .lineLimit(isExpanded ? nil : 2)
            
            HStack {
                sourceBadge
                
                Spacer()
                
                if !finding.metadata.isEmpty {
                    Button(isExpanded ? "Less" : "More") {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }
                    .font(.caption2)
                }
            }
            
            if isExpanded && !finding.metadata.isEmpty {
                metadataView
            }
        }
        .padding(.vertical, 4)
    }
    
    private var confidenceBadge: some View {
        Text(finding.confidence.rawValue)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(finding.confidence.color.opacity(0.2))
            .foregroundColor(finding.confidence.color)
            .cornerRadius(4)
    }
    
    private var sourceBadge: some View {
        HStack {
            Image(systemName: finding.source.icon)
                .font(.caption2)
            Text(finding.source.rawValue)
                .font(.caption2)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(4)
    }
    
    private var metadataView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Details")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            ForEach(Array(finding.metadata.keys), id: \.self) { key in
                HStack {
                    Text(key.capitalized)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(finding.metadata[key] ?? "")
                        .font(.caption2)
                        .lineLimit(2)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(6)
    }
}

struct OSINTAPISettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var osint: OSINTModule
    
    @State private var shodanKey = ""
    @State private var virustotalKey = ""
    @State private var hibpKey = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("OSINT API Configuration")
                .font(.title2)
                .fontWeight(.bold)
            
            Form {
                Section(header: Text("Shodan")) {
                    TextField("Shodan API Key", text: $shodanKey)
                    Text("Get your API key at https://shodan.io/account")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("VirusTotal")) {
                    TextField("VirusTotal API Key", text: $virustotalKey)
                    Text("Get your API key at https://www.virustotal.com/gui/my-apikey")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Have I Been Pwned")) {
                    TextField("HIBP API Key", text: $hibpKey)
                    Text("Get your API key at https://haveibeenpwned.com/API/Key")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 500, height: 300)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                
                Spacer()
                
                Button("Save") {
                    saveKeys()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .padding()
    }
    
    private func saveKeys() {
        if !shodanKey.isEmpty {
            osint.saveAPIKey(shodanKey, for: "shodan")
        }
        if !virustotalKey.isEmpty {
            osint.saveAPIKey(virustotalKey, for: "virustotal")
        }
        if !hibpKey.isEmpty {
            osint.saveAPIKey(hibpKey, for: "haveibeenpwned")
        }
    }
}

#Preview {
    AdvancedOSINTDashboardView()
}