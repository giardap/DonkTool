//
//  AttackExecutionView.swift
//  DonkTool
//  Attack execution interface
//

import SwiftUI

struct AttackExecutionView: View {
    let attackVector: AttackVector
    let target: String
    let port: Int
    
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var attackResult: AttackResult?
    @State private var isExecuting = false
    @State private var showingPreRequisites = false
    @State private var realTimeOutput: [String] = []
    @State private var executionStartTime: Date?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                AttackHeaderView()
                
                // Main content
                ScrollView {
                    VStack(spacing: 24) {
                        // Attack details
                        AttackDetailsCard()
                        
                        // Prerequisites check
                        PrerequisitesCard()
                        
                        // Execution controls
                        ExecutionControlsCard()
                        
                        // Results
                        if let result = attackResult {
                            AttackResultsCard(result: result)
                        } else if isExecuting {
                            AttackProgressCard()
                            RealTimeConsoleView()
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Attack Execution")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .onAppear {
            checkPrerequisites()
        }
    }
    
    @ViewBuilder
    private func AttackHeaderView() -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: attackVector.attackType.icon)
                    .font(.title)
                    .foregroundColor(attackVector.severity.color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(attackVector.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Target: \(target):\(port)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    AttackSeverityBadge(severity: .medium)
                    AttackDifficultyBadge(difficulty: attackVector.difficulty)
                }
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(NSColor.separatorColor)),
            alignment: .bottom
        )
    }
    
    @ViewBuilder
    private func AttackDetailsCard() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Attack Details")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                DetailRow(label: "Type", value: attackVector.attackType.rawValue)
                DetailRow(label: "Description", value: attackVector.description)
                
                if !attackVector.tools.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Required Tools:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack {
                            ForEach(attackVector.tools, id: \.self) { tool in
                                ToolBadge(tool: tool, isAvailable: isToolAvailable(tool))
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func PrerequisitesCard() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Prerequisites")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Check Again") {
                    checkPrerequisites()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            VStack(spacing: 8) {
                ForEach(attackVector.tools, id: \.self) { tool in
                    PrerequisiteRow(
                        tool: tool,
                        status: getToolStatus(tool)
                    ) {
                        installTool(tool)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func ExecutionControlsCard() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Execution")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                HStack {
                    Button(action: executeAttack) {
                        HStack {
                            if isExecuting {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Executing...")
                            } else {
                                Image(systemName: "play.fill")
                                Text("Execute Attack")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isExecuting || !allPrerequisitesMet)
                    
                    if isExecuting {
                        Button("Stop") {
                            stopAttack()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                if !allPrerequisitesMet {
                    Text("⚠️ Some prerequisites are not met. Install required tools to proceed.")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func AttackProgressCard() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Attack in Progress")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                ProgressView()
                    .scaleEffect(0.8)
            }
            
            Text("Executing \(attackVector.name) against \(target):\(port)...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private func AttackResultsCard(result: AttackResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Attack Results")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                ResultStatusBadge(success: result.success)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                // Summary
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Duration")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.2f seconds", result.duration))
                            .font(.headline)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Status")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(result.success ? "Success" : "Failed")
                            .font(.headline)
                            .foregroundColor(result.success ? .green : .red)
                    }
                }
                
                // Findings tabs
                AttackResultTabView(result: result)
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private var allPrerequisitesMet: Bool {
        attackVector.tools.allSatisfy { isToolAvailable($0) }
    }
    
    private func isToolAvailable(_ tool: String) -> Bool {
        if let attackTool = AttackTool.allCases.first(where: { $0.commandName == tool.lowercased() }) {
            return appState.attackFramework.toolsStatus[attackTool] == .available
        }
        return false
    }
    
    private func getToolStatus(_ tool: String) -> AttackFramework.ToolStatus {
        if let attackTool = AttackTool.allCases.first(where: { $0.commandName == tool.lowercased() }) {
            return appState.attackFramework.toolsStatus[attackTool] ?? .needsInstallation
        }
        
        // Fallback to ToolDetection for tools not in AttackTool enum
        if ToolDetection.shared.isToolInstalled(tool) {
            return .available
        }
        return .needsInstallation
    }
    
    private func installTool(_ tool: String) {
        if let attackTool = AttackTool.allCases.first(where: { $0.commandName == tool.lowercased() }) {
            Task {
                await appState.attackFramework.installTool(attackTool)
            }
        }
    }
    
    private func checkPrerequisites() {
        // Force refresh of tool status
        Task {
            await ToolDetection.shared.forceRefreshToolStatus()
            await appState.attackFramework.checkToolAvailability()
        }
    }
    
    private func executeAttack() {
        isExecuting = true
        attackResult = nil
        realTimeOutput = []
        executionStartTime = Date()
        
        // Set up real-time output callback
        appState.attackFramework.setRealTimeOutputCallback { output in
            print("📟 Real-time output received: \(output)")
            Task { @MainActor in
                self.realTimeOutput.append(output)
                print("📟 Added to realTimeOutput, count: \(self.realTimeOutput.count)")
            }
        }
        
        // Initialize real-time console
        realTimeOutput.append("Initializing attack execution...")
        
        Task {
            let result = await appState.attackFramework.executeAttack(attackVector, target: target, port: port)
            
            await MainActor.run {
                self.attackResult = result
                self.isExecuting = false
            }
        }
    }
    
    @ViewBuilder
    private func RealTimeConsoleView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Live Console Output")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if let startTime = executionStartTime {
                    Text("Running for \(formatDuration(Date().timeIntervalSince(startTime)))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            ScrollView {
                ScrollViewReader { proxy in
                    VStack(alignment: .leading, spacing: 2) {
                        if realTimeOutput.isEmpty {
                            Text("Initializing attack...")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.white)
                        } else {
                            ForEach(Array(realTimeOutput.enumerated()), id: \.offset) { index, line in
                                Text(line)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.white)
                                    .textSelection(.enabled)
                                    .id(index)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .onChange(of: realTimeOutput.count) { _, _ in
                        // Auto-scroll to bottom
                        if let lastIndex = realTimeOutput.indices.last {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(lastIndex, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            .frame(height: 300)
            .background(Color.black.opacity(0.9))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.vertical, 12)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func stopAttack() {
        // Implementation to stop ongoing attack
        isExecuting = false
    }
}

// MARK: - Supporting Views

struct AttackSeverityBadge: View {
    let severity: AttackVector.AttackSeverity
    
    var body: some View {
        Text(severity.rawValue.uppercased())
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(severity.color.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(4)
    }
}

struct AttackDifficultyBadge: View {
    let difficulty: AttackVector.AttackDifficulty
    
    var body: some View {
        Text(difficulty.rawValue)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(difficulty.color.opacity(0.2))
            .foregroundColor(difficulty.color)
            .cornerRadius(3)
    }
}


struct ToolBadge: View {
    let tool: String
    let isAvailable: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isAvailable ? .green : .red)
                .font(.caption)
            
            Text(tool)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isAvailable ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .cornerRadius(6)
    }
}

struct PrerequisiteRow: View {
    let tool: String
    let status: AttackFramework.ToolStatus
    let onInstall: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .frame(width: 20)
            
            Text(tool.capitalized)
                .font(.subheadline)
            
            Spacer()
            
            if status == .needsInstallation {
                Button("Install") {
                    onInstall()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else if status == .installing {
                ProgressView()
                    .scaleEffect(0.7)
            } else {
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(statusColor)
            }
        }
    }
    
    private var statusIcon: String {
        switch status {
        case .available: return "checkmark.circle.fill"
        case .needsInstallation: return "exclamationmark.triangle.fill"
        case .installing: return "arrow.clockwise.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .unavailable: return "questionmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .available: return .green
        case .needsInstallation: return .orange
        case .installing: return .blue
        case .failed: return .red
        case .unavailable: return .gray
        }
    }
    
    private var statusText: String {
        switch status {
        case .available: return "Available"
        case .needsInstallation: return "Not Installed"
        case .installing: return "Installing..."
        case .failed: return "Install Failed"
        case .unavailable: return "Unavailable"
        }
    }
}

struct ResultStatusBadge: View {
    let success: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: success ? "checkmark.circle.fill" : "xmark.circle.fill")
            Text(success ? "Success" : "Failed")
        }
        .font(.caption)
        .fontWeight(.medium)
        .foregroundColor(success ? .green : .red)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background((success ? Color.green : Color.red).opacity(0.1))
        .cornerRadius(6)
    }
}

struct AttackResultTabView: View {
    let result: AttackResult
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 16) {
            // Tab selector
            HStack(spacing: 0) {
                TabButton(title: "Output", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                
                if !result.credentials.isEmpty {
                    TabButton(title: "Credentials (\(result.credentials.count))", isSelected: selectedTab == 1) {
                        selectedTab = 1
                    }
                }
                
                if !result.vulnerabilities.isEmpty {
                    TabButton(title: "Vulnerabilities (\(result.vulnerabilities.count))", isSelected: selectedTab == 2) {
                        selectedTab = 2
                    }
                }
                
                if !result.files.isEmpty {
                    TabButton(title: "Files (\(result.files.count))", isSelected: selectedTab == 3) {
                        selectedTab = 3
                    }
                }
                
                Spacer()
            }
            
            // Tab content
            Group {
                switch selectedTab {
                case 0:
                    OutputTabView(output: result.output)
                case 1:
                    CredentialsTabView(credentials: result.credentials)
                case 2:
                    VulnerabilitiesTabView(vulnerabilities: result.vulnerabilities)
                case 3:
                    FilesTabView(files: result.files)
                default:
                    EmptyView()
                }
            }
            .frame(minHeight: 200)
        }
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color.clear)
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

struct OutputTabView: View {
    let output: [String]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(output.enumerated()), id: \.offset) { index, line in
                    Text(line)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .background(Color.black.opacity(0.05))
        .cornerRadius(8)
    }
}

struct CredentialsTabView: View {
    let credentials: [Credential]
    
    var body: some View {
        List(credentials) { credential in
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(credential.username):\(credential.password)")
                        .font(.headline)
                        .textSelection(.enabled)
                    
                    Spacer()
                    
                    Text(credential.service)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(3)
                }
                
                Text("Port: \(credential.port)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .listStyle(.plain)
    }
}

struct VulnerabilitiesTabView: View {
    let vulnerabilities: [VulnerabilityFinding]
    
    var body: some View {
        List(vulnerabilities) { vuln in
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(vuln.type)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(vuln.severity.uppercased())
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(severityColor(vuln.severity).opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(3)
                }
                
                Text(vuln.description)
                    .font(.body)
                
                if !vuln.proof.isEmpty {
                    Text("Proof: \(vuln.proof)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                }
            }
            .padding(.vertical, 4)
        }
        .listStyle(.plain)
    }
    
    private func severityColor(_ severity: String) -> Color {
        switch severity {
        case "critical": return .red
        case "high": return .orange
        case "medium": return .yellow
        case "low": return .green
        default: return .gray
        }
    }
}

struct FilesTabView: View {
    let files: [String]
    
    var body: some View {
        List(files, id: \.self) { file in
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.blue)
                
                Text(file)
                    .font(.body)
                    .textSelection(.enabled)
                
                Spacer()
            }
            .padding(.vertical, 2)
        }
        .listStyle(.plain)
    }
}

#Preview {
    AttackExecutionView(
        attackVector: AttackVector(
            name: "SSH Brute Force",
            description: "Attempt to brute force SSH credentials",
            severity: .high,
            requirements: [
                ToolRequirement(name: "hydra", type: .tool, description: "Network login cracker"),
                ToolRequirement(name: "nmap", type: .tool, description: "Network discovery tool")
            ],
            commands: ["hydra -L users.txt -P passwords.txt ssh://target"],
            references: ["https://github.com/vanhauser-thc/thc-hydra"]
        ),
        target: "192.168.1.100",
        port: 22
    )
}
