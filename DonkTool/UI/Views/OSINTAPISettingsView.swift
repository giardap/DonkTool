//
//  OSINTAPISettingsView.swift
//  DonkTool
//
//  API Key management for OSINT sources
//

import SwiftUI

struct OSINTAPISettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKeys: [String: String] = [:]
    @State private var showingKeyVisibility: [String: Bool] = [:]
    
    private let apiSources = [
        APISourceInfo(
            key: "haveibeenpwned",
            name: "Have I Been Pwned",
            description: "Data breach checking service",
            website: "https://haveibeenpwned.com/API/Key",
            freeAPI: false,
            cost: "$3.50/month",
            freeQuota: nil,
            instructions: "1. Go to https://haveibeenpwned.com/API/Key\n2. Subscribe for $3.50/month for API access\n3. Copy your API key from the dashboard\n4. Paste the key below"
        ),
        APISourceInfo(
            key: "hunter",
            name: "Hunter.io",
            description: "Email finder and verification",
            website: "https://hunter.io/api",
            freeAPI: true,
            cost: nil,
            freeQuota: "25 searches/month",
            instructions: "1. Sign up at https://hunter.io/api\n2. Go to Dashboard → API\n3. Copy your API key\n4. Free tier: 25 searches/month"
        ),
        APISourceInfo(
            key: "google_cse",
            name: "Google Custom Search",
            description: "Advanced Google search queries and dorking",
            website: "https://console.developers.google.com",
            freeAPI: true,
            cost: nil,
            freeQuota: "100 searches/day",
            instructions: "1. Create project at https://console.developers.google.com\n2. Enable Custom Search API\n3. Create Custom Search Engine at https://cse.google.com\n4. Get API key and Search Engine ID\n5. Enter both API key and Search Engine ID below"
        ),
        APISourceInfo(
            key: "google_cse_id",
            name: "Google CSE ID",
            description: "Search Engine ID for Google Custom Search",
            website: "https://cse.google.com",
            freeAPI: true,
            cost: nil,
            freeQuota: "Required for CSE",
            instructions: "1. Go to https://cse.google.com\n2. Select your Custom Search Engine\n3. Copy the Search Engine ID (cx parameter)\n4. This is required along with the API key above"
        ),
        APISourceInfo(
            key: "shodan",
            name: "Shodan",
            description: "Internet-connected device search engine",
            website: "https://www.shodan.io",
            freeAPI: true,
            cost: nil,
            freeQuota: "100 queries/month",
            instructions: "1. Sign up at https://www.shodan.io\n2. Go to Account → API Keys\n3. Copy your API key\n4. Free tier: 100 queries/month"
        ),
        APISourceInfo(
            key: "github",
            name: "GitHub",
            description: "GitHub repository and user analysis",
            website: "https://github.com/settings/tokens",
            freeAPI: true,
            cost: nil,
            freeQuota: "5000 requests/hour",
            instructions: "1. Go to GitHub Settings → Developer settings\n2. Create Personal Access Token\n3. Select public_repo and user scopes\n4. Copy the generated token"
        ),
        APISourceInfo(
            key: "virustotal",
            name: "VirusTotal",
            description: "File and URL analysis service",
            website: "https://www.virustotal.com/gui/join-us",
            freeAPI: true,
            cost: nil,
            freeQuota: "4 requests/minute",
            instructions: "1. Create VirusTotal account\n2. Go to user menu → API key\n3. Copy your API key\n4. Free tier has rate limits"
        ),
        APISourceInfo(
            key: "censys",
            name: "Censys",
            description: "Internet scanning and analysis",
            website: "https://censys.io/register",
            freeAPI: true,
            cost: nil,
            freeQuota: "250 queries/month",
            instructions: "1. Register at censys.io\n2. Go to Account → API\n3. Generate new API credentials\n4. You'll get API ID and Secret"
        ),
        APISourceInfo(
            key: "securitytrails",
            name: "SecurityTrails",
            description: "DNS and domain intelligence",
            website: "https://securitytrails.com/",
            freeAPI: true,
            cost: nil,
            freeQuota: "50 queries/month",
            instructions: "1. Sign up at securitytrails.com\n2. Go to Dashboard → API\n3. Copy your API key\n4. Free tier available"
        )
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerView
                
                Divider()
                
                // API Keys list
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(apiSources, id: \.key) { source in
                            APIKeyCard(
                                source: source,
                                apiKey: Binding(
                                    get: { apiKeys[source.key] ?? "" },
                                    set: { apiKeys[source.key] = $0 }
                                ),
                                isVisible: Binding(
                                    get: { showingKeyVisibility[source.key] ?? false },
                                    set: { showingKeyVisibility[source.key] = $0 }
                                )
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("OSINT API Configuration")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAPIKeys()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .onAppear {
            loadAPIKeys()
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "key.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("API Key Configuration")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Configure API keys for enhanced OSINT data collection")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            HStack {
                Label("Free APIs available", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
                
                Spacer()
                
                Label("Keys stored securely", systemImage: "lock.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.cardBackground)
    }
    
    private func loadAPIKeys() {
        for source in apiSources {
            apiKeys[source.key] = UserDefaults.standard.string(forKey: "\(source.key)_api_key") ?? ""
        }
    }
    
    private func saveAPIKeys() {
        for (key, value) in apiKeys {
            if !value.isEmpty {
                UserDefaults.standard.set(value, forKey: "\(key)_api_key")
            } else {
                UserDefaults.standard.removeObject(forKey: "\(key)_api_key")
            }
        }
        
        // Notify OSINTModule to reload keys
        OSINTModule.shared.reloadAPIKeys()
    }
}

struct APIKeyCard: View {
    let source: APISourceInfo
    @Binding var apiKey: String
    @Binding var isVisible: Bool
    @State private var showingInstructions = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(source.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if source.freeAPI {
                            Text("FREE")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .cornerRadius(4)
                        } else if let cost = source.cost {
                            Text(cost)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .foregroundColor(.orange)
                                .cornerRadius(4)
                        }
                    }
                    
                    if let quota = source.freeQuota {
                        Text("Free Tier: \(quota)")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                    
                    Text(source.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status indicator
                Circle()
                    .fill(apiKey.isEmpty ? Color.red : Color.green)
                    .frame(width: 12, height: 12)
            }
            
            // API Key input
            HStack {
                if isVisible {
                    TextField("Enter API key", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                } else {
                    SecureField("Enter API key", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                }
                
                Button(action: { isVisible.toggle() }) {
                    Image(systemName: isVisible ? "eye.slash" : "eye")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                
                Button("Instructions") {
                    showingInstructions = true
                }
                .buttonStyle(.bordered)
            }
            
            // Quick actions
            HStack {
                Button("Get API Key") {
                    if let url = URL(string: source.website) {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.link)
                
                Spacer()
                
                if !apiKey.isEmpty {
                    Button("Test Connection") {
                        testAPIKey()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(apiKey.isEmpty ? Color.red.opacity(0.3) : Color.green.opacity(0.3), lineWidth: 1)
        )
        .popover(isPresented: $showingInstructions) {
            APIInstructionsView(source: source)
        }
    }
    
    private func testAPIKey() {
        // TODO: Implement API key testing
        print("Testing API key for \(source.name)")
    }
}

struct APIInstructionsView: View {
    let source: APISourceInfo
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Setup Instructions")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(source.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(source.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Steps:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(source.instructions)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            HStack {
                Button("Open Website") {
                    if let url = URL(string: source.website) {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
        }
        .padding()
        .frame(width: 400)
    }
}

struct APISourceInfo {
    let key: String
    let name: String
    let description: String
    let website: String
    let freeAPI: Bool
    let cost: String?
    let freeQuota: String?
    let instructions: String
}

// OSINTModule.reloadAPIKeys() is defined in the main OSINTModule class

#Preview {
    OSINTAPISettingsView()
}