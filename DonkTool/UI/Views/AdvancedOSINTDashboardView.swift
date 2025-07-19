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
    @State private var showingResults = false
    @State private var selectedSearchType = OSINTSearchType.domain
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Main Content - give it fixed height to prevent overflow
            VStack {
                if osint.isGathering {
                    gatheringProgressView
                } else {
                    configurationView
                }
            }
            .frame(maxHeight: osint.findings.isEmpty ? .infinity : 400)
            
            // Results Section
            Divider()
            
            if osint.findings.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No Intelligence Gathered")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Text("Configure a target and sources above, then start an investigation to see results here.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.opacity(0.02))
            } else {
                // Results display
                VStack(alignment: .leading, spacing: 0) {
                    // Results header
                    HStack {
                        Text("Intelligence Results")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button("Clear All") {
                            clearAll()
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(4)
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    
                    // Summary stats
                    summaryView
                    
                    Divider()
                    
                    // Findings list with proper frame
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(osint.findings) { finding in
                                FindingRowView(finding: finding)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 12)
                    }
                    .frame(minHeight: 300, maxHeight: .infinity)
                }
                .background(Color.gray.opacity(0.02))
            }
        }
        .sheet(isPresented: $showingSettings) {
            OSINTAPISettingsView(osint: osint)
        }
        .sheet(isPresented: $showingResults) {
            OSINTResultsWindow(osint: osint)
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
    
    
    private var summaryView: some View {
        VStack(spacing: 8) {
            HStack {
                statItem("Total Findings", value: osint.findings.count, color: .blue)
                
                Spacer()
                
                statItem("Active Sources", value: Set(osint.findings.map(\.source)).count, color: .green)
                
                Spacer()
                
                statItem("High Confidence", 
                        value: osint.findings.filter { $0.confidence == .high }.count, 
                        color: .orange)
                
                Spacer()
                
                statItem("URLs Found", 
                        value: osint.findings.filter { $0.content.contains("http") }.count, 
                        color: .purple)
            }
            
            // Additional stats row
            HStack {
                statItem("Social Media", 
                        value: osint.findings.filter { $0.type.rawValue.contains("Social") || $0.source == .socialMedia }.count, 
                        color: .mint)
                
                Spacer()
                
                statItem("Emails", 
                        value: osint.findings.filter { $0.content.contains("@") && $0.content.contains(".") }.count, 
                        color: .cyan)
                
                Spacer()
                
                statItem("Recent (1h)", 
                        value: osint.findings.filter { Date().timeIntervalSince($0.timestamp) < 3600 }.count, 
                        color: .indigo)
                
                Spacer()
                
                // Placeholder for balance
                statItem("", value: 0, color: .clear)
                    .opacity(0)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(8)
        .padding(.horizontal)
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
        VStack(alignment: .leading, spacing: 10) {
            // Header row with type, confidence, and timestamp
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: finding.type.icon)
                        .foregroundColor(finding.type.color)
                        .font(.title3)
                    
                    Text(finding.type.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(finding.type.color)
                }
                
                Spacer()
                
                confidenceBadge
                
                Text(finding.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Main content with better formatting
            VStack(alignment: .leading, spacing: 6) {
                Text(finding.content)
                    .font(.body)
                    .lineLimit(isExpanded ? nil : 3)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Source and action buttons
                HStack {
                    sourceBadge
                    
                    Spacer()
                    
                    if !finding.metadata.isEmpty || finding.content.count > 150 {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded.toggle()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Text(isExpanded ? "Show Less" : "Show More")
                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Copy button for URLs and useful data
                    if finding.content.contains("http") || finding.content.contains("@") {
                        Button(action: {
                            copyToClipboard(finding.content)
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // Expanded metadata view
            if isExpanded && !finding.metadata.isEmpty {
                metadataView
            }
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(8)
        .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text("Additional Details")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible(minimum: 80)),
                GridItem(.flexible(minimum: 120))
            ], alignment: .leading, spacing: 8) {
                ForEach(Array(finding.metadata.keys.sorted()), id: \.self) { key in
                    Group {
                        Text(formatMetadataKey(key))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(formatMetadataValue(finding.metadata[key] ?? ""))
                            .font(.caption)
                            .foregroundColor(.primary)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            
            // Show raw content if it's different from display content
            if !finding.metadata.isEmpty && finding.metadata.count > 0 {
                Divider()
                
                HStack {
                    Text("Source: \(finding.source.rawValue)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Confidence: \(finding.confidence.rawValue)")
                        .font(.caption2)
                        .foregroundColor(finding.confidence.color)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(8)
    }
    
    private func formatMetadataKey(_ key: String) -> String {
        return key.replacingOccurrences(of: "_", with: " ")
                  .replacingOccurrences(of: "-", with: " ")
                  .capitalized
    }
    
    private func formatMetadataValue(_ value: String) -> String {
        // Format URLs nicely
        if value.hasPrefix("http") {
            return value
        }
        
        // Format other values
        return value.isEmpty ? "N/A" : value
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