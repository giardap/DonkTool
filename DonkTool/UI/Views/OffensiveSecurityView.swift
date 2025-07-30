//
//  OffensiveSecurityView.swift
//  DonkTool
//
//  Advanced offensive security tools interface
//

import SwiftUI

struct OffensiveSecurityView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory = "All"
    @State private var searchText = ""
    @State private var showingAttackConfig = false
    @State private var selectedAttack: OffensiveAttackVector?
    @State private var targetIP = ""
    @State private var targetDomain = ""
    @State private var targetPort = "80"
    @State private var showingToolInstaller = false
    
    let categories = ["All", "Reconnaissance", "Web Exploitation", "Wireless", "Password Cracking", "Network", "Fuzzing"]
    
    var filteredAttacks: [OffensiveAttackVector] {
        let attacks = AttackFramework.offensiveSecurityAttacks
        
        if selectedCategory == "All" && searchText.isEmpty {
            return attacks
        }
        
        return attacks.filter { attack in
            let matchesCategory = selectedCategory == "All" || 
                                attack.category.rawValue.localizedCaseInsensitiveContains(selectedCategory)
            let matchesSearch = searchText.isEmpty || 
                              attack.name.localizedCaseInsensitiveContains(searchText) ||
                              attack.description.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            OffensiveSecurityHeader(showingToolInstaller: $showingToolInstaller)
            
            // Category Filter
            CategoryFilterBar(selectedCategory: $selectedCategory, categories: categories)
            
            // Search Bar
            SearchBar(text: $searchText)
                .padding(.horizontal)
                .padding(.vertical, 8)
            
            // Attack Tools Grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(filteredAttacks, id: \.id) { attack in
                        AttackToolCard(attack: attack) {
                            // Reset state first to ensure state change
                            selectedAttack = nil
                            showingAttackConfig = false
                            
                            // Small delay to ensure state is reset
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                selectedAttack = attack
                                showingAttackConfig = true
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingAttackConfig) {
            if let attack = selectedAttack {
                AttackConfigurationView(
                    attack: attack,
                    targetIP: $targetIP,
                    targetDomain: $targetDomain,
                    targetPort: $targetPort
                )
                .id(attack.id) // Force refresh with unique ID
            } else {
                // Fallback content for debugging
                VStack {
                    Text("Error: No attack selected")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Button("Close") {
                        showingAttackConfig = false
                    }
                }
                .frame(minWidth: 400, minHeight: 300)
            }
        }
        .sheet(isPresented: $showingToolInstaller) {
            ToolInstallerView()
        }
    }
}

struct OffensiveSecurityHeader: View {
    @Binding var showingToolInstaller: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Offensive Security Arsenal")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Advanced penetration testing tools")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { showingToolInstaller = true }) {
                    Label("Install Tools", systemImage: "arrow.down.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
            
            // Warning Banner
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
                
                Text("Use these tools only on systems you own or have explicit permission to test")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.yellow.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct CategoryFilterBar: View {
    @Binding var selectedCategory: String
    let categories: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    OffensiveCategoryChip(
                        title: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }
}

struct OffensiveCategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

struct AttackToolCard: View {
    let attack: OffensiveAttackVector
    let action: () -> Void
    @State private var isHovered = false
    
    var categoryIcon: String {
        switch attack.category {
        case .reconnaissance: return "magnifyingglass.circle.fill"
        case .webExploitation: return "globe.badge.chevron.backward"
        case .bruteForce: return "key.fill"
        case .passwordCracking: return "key.fill"
        case .networkExploitation: return "network"
        case .dosStress: return "bolt.fill"
        case .vulnerability: return "exclamationmark.shield.fill"
        case .wireless: return "wifi"
        case .fuzzing: return "waveform.path.ecg"
        default: return "hammer.fill"
        }
    }
    
    var categoryColor: Color {
        switch attack.category {
        case .reconnaissance: return .blue
        case .webExploitation: return .green
        case .bruteForce: return .orange
        case .passwordCracking: return .orange
        case .networkExploitation: return .purple
        case .dosStress: return .red
        case .vulnerability: return .yellow
        case .wireless: return .purple
        case .fuzzing: return .indigo
        default: return .gray
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: categoryIcon)
                        .font(.title2)
                        .foregroundColor(categoryColor)
                    
                    Spacer()
                    
                    SeverityBadge(severity: attack.severity)
                }
                
                // Title
                Text(attack.name)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Description
                Text(attack.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Footer
                HStack {
                    // Required Tools
                    HStack(spacing: 4) {
                        Image(systemName: "wrench.fill")
                            .font(.caption2)
                        Text("\(attack.requiredTools.count) tools")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Duration
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                        Text(formatDuration(attack.estimatedDuration))
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(height: 180)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isHovered ? categoryColor.opacity(0.5) : Color.gray.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: isHovered ? categoryColor.opacity(0.2) : .clear, radius: 8)
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        } else if seconds < 3600 {
            return "\(seconds / 60)m"
        } else {
            return "\(seconds / 3600)h"
        }
    }
}

struct SeverityBadge: View {
    let severity: AttackSeverity
    
    var color: Color {
        switch severity {
        case .info: return .blue
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
    
    var body: some View {
        Text(severity.rawValue.uppercased())
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(4)
    }
}

struct AttackConfigurationView: View {
    let attack: OffensiveAttackVector
    @Binding var targetIP: String
    @Binding var targetDomain: String
    @Binding var targetPort: String
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var useCustomWordlist = false
    @State private var customWordlistPath = ""
    @State private var attackOptions: [String: Bool] = [:]
    @State private var showingAttackProgress = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(attack.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(attack.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Target Configuration
                    GroupBox("Target Configuration") {
                        VStack(alignment: .leading, spacing: 12) {
                            if attack.category == .reconnaissance {
                                TextField("Domain (e.g., example.com)", text: $targetDomain)
                                    .textFieldStyle(.roundedBorder)
                            } else {
                                TextField("IP Address", text: $targetIP)
                                    .textFieldStyle(.roundedBorder)
                                
                                TextField("Port", text: $targetPort)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Attack Options
                    if !attackOptions.isEmpty {
                        GroupBox("Attack Options") {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(Array(attackOptions.keys.sorted()), id: \.self) { option in
                                    Toggle(option, isOn: Binding(
                                        get: { attackOptions[option] ?? false },
                                        set: { attackOptions[option] = $0 }
                                    ))
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    
                    // Required Tools
                    GroupBox("Required Tools") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(attack.requiredTools, id: \.self) { tool in
                                HStack {
                                    Image(systemName: checkToolInstalled(tool) ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(checkToolInstalled(tool) ? .green : .red)
                                    
                                    Text(tool.rawValue)
                                        .font(.system(.body, design: .monospaced))
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Commands Preview
                    GroupBox("Commands to Execute") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(attack.commands, id: \.self) { command in
                                Text(preprocessCommand(command))
                                    .font(.system(size: 11, design: .monospaced))
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.black.opacity(0.05))
                                    .cornerRadius(4)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Warning
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        
                        Text("Ensure you have permission to test the target system")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding()
            }
            
            // Execute Button
            HStack {
                Spacer()
                
                Button("Execute Attack") {
                    executeAttack()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!canExecuteAttack())
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 600, height: 700)
        .onAppear {
            setupAttackOptions()
        }
        .sheet(isPresented: $showingAttackProgress) {
            AttackProgressView(
                attack: attack,
                target: targetDomain.isEmpty ? targetIP : targetDomain,
                port: Int(targetPort) ?? 80
            )
        }
    }
    
    private func setupAttackOptions() {
        // Set up attack-specific options
        switch attack.id {
        case "amass-enum":
            attackOptions = [
                "Active Scanning": true,
                "Passive Only": false,
                "Include WHOIS": true
            ]
        case "xsstrike-advanced":
            attackOptions = [
                "Crawl Website": true,
                "Fuzzer Mode": true,
                "Parameter Discovery": true
            ]
        case "aircrack-wpa":
            attackOptions = [
                "Monitor Mode": true,
                "Deauth Attack": true,
                "Use GPU": false
            ]
        default:
            break
        }
    }
    
    private func checkToolInstalled(_ tool: OffensiveAttackTool) -> Bool {
        return ToolDetection.shared.isToolInstalled(tool.rawValue)
    }
    
    private func preprocessCommand(_ command: String) -> String {
        return command
            .replacingOccurrences(of: "TARGET", with: targetDomain.isEmpty ? targetIP : targetDomain)
            .replacingOccurrences(of: "PORT", with: targetPort)
    }
    
    private func canExecuteAttack() -> Bool {
        let hasTarget = !targetIP.isEmpty || !targetDomain.isEmpty
        let allToolsInstalled = attack.requiredTools.allSatisfy { checkToolInstalled($0) }
        return hasTarget && allToolsInstalled
    }
    
    private func executeAttack() {
        showingAttackProgress = true
    }
}

struct ToolInstallerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isInstalling = false
    @State private var installOutput = ""
    @State private var installProgress = 0.0
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Offensive Security Tools Installer")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("This will install advanced penetration testing tools")
                .foregroundColor(.secondary)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ToolCategorySection(
                        title: "Reconnaissance Tools",
                        tools: ["Amass", "theHarvester", "Recon-ng", "DNSRecon", "Sublist3r"],
                        icon: "magnifyingglass.circle.fill",
                        color: .blue
                    )
                    
                    ToolCategorySection(
                        title: "Web Application Testing",
                        tools: ["XSStrike", "DalFox", "Arjun", "Photon", "WPScan"],
                        icon: "globe.badge.chevron.backward",
                        color: .green
                    )
                    
                    ToolCategorySection(
                        title: "Wireless Tools",
                        tools: ["Aircrack-ng", "Bettercap", "Wifite2"],
                        icon: "wifi",
                        color: .purple
                    )
                    
                    ToolCategorySection(
                        title: "Password Cracking",
                        tools: ["John the Ripper", "Hashcat", "Hydra", "SecLists"],
                        icon: "key.fill",
                        color: .orange
                    )
                    
                    ToolCategorySection(
                        title: "Network Tools",
                        tools: ["SMBMap", "CrackMapExec", "Impacket", "Responder"],
                        icon: "network",
                        color: .indigo
                    )
                }
                .padding()
            }
            
            if isInstalling {
                VStack(spacing: 12) {
                    ProgressView(value: installProgress)
                        .progressViewStyle(.linear)
                    
                    ScrollView {
                        Text(installOutput)
                            .font(.system(size: 10, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 100)
                    .padding(8)
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(8)
                }
            }
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("Install All Tools") {
                    installTools()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isInstalling)
            }
        }
        .padding()
        .frame(width: 600, height: 700)
    }
    
    private func installTools() {
        isInstalling = true
        installOutput = "Starting installation...\n"
        
        Task {
            let scriptPath = "/Users/giardap/Documents/GitHub/DonkTool/install-offsec-tools.sh"
            
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = [scriptPath]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            do {
                try process.run()
                
                let handle = pipe.fileHandleForReading
                handle.readabilityHandler = { handle in
                    let data = handle.availableData
                    if let output = String(data: data, encoding: .utf8) {
                        DispatchQueue.main.async {
                            self.installOutput += output
                            self.installProgress = min(self.installProgress + 0.1, 0.9)
                        }
                    }
                }
                
                process.waitUntilExit()
                
                DispatchQueue.main.async {
                    self.installProgress = 1.0
                    self.installOutput += "\n✅ Installation complete!"
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.dismiss()
                    }
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.installOutput += "\n❌ Installation failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct ToolCategorySection: View {
    let title: String
    let tools: [String]
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
            }
            
            ForEach(tools, id: \.self) { tool in
                HStack {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(tool)
                        .font(.system(.body, design: .monospaced))
                }
                .padding(.leading, 20)
            }
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search tools...", text: $text)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}