//
//  ActiveAttacksView.swift
//  DonkTool
//  Active attacks monitoring interface
//

import SwiftUI

struct ActiveAttacksView: View {
    @Environment(AppState.self) private var appState
    @State private var refreshTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                ActiveAttacksHeaderView()
                
                // Main content
                if appState.attackFramework.activeSessions.isEmpty {
                    EmptyActiveAttacksView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(appState.attackFramework.activeSessions, id: \.sessionId) { session in
                                ActiveAttackCard(session: session)
                            }
                        }
                        .padding(24)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Active Attacks")
            .onReceive(refreshTimer) { _ in
                // Refresh session data periodically and clean up old sessions
                appState.attackFramework.cleanupCompletedSessions()
            }
        }
    }
    
    @ViewBuilder
    private func ActiveAttacksHeaderView() -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "bolt.badge.clock")
                    .font(.title)
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Active Attacks")
                        .font(.headerPrimary)
                    
                    Text("\(appState.attackFramework.runningSessions.count) running, \(appState.attackFramework.completedSessions.count) completed")
                        .font(.captionPrimary)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Refresh") {
                    // Clean up old completed sessions and refresh
                    appState.attackFramework.cleanupCompletedSessions()
                }
                .secondaryButton()
                .controlSize(.small)
            }
        }
        .standardContainer()
        
        Divider()
    }
    
    @ViewBuilder
    private func EmptyActiveAttacksView() -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "bolt.slash")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
                .opacity(0.6)
            
            VStack(spacing: 8) {
                Text("No Active Attacks")
                    .font(.headerSecondary)
                
                Text("Execute attacks from the Network Scanner to see them here")
                    .font(.bodyPrimary)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Go to Network Scanner") {
                appState.currentTab = .networkScanner
            }
            .primaryButton()
            
            Spacer()
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}

struct ActiveAttackCard: View {
    let session: AttackSession
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            AttackCardHeader(session: session, isExpanded: $isExpanded)
            
            if isExpanded {
                AttackCardExpandedContent(session: session)
            }
        }
        .cardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: .radius_lg)
                .stroke(statusColor.opacity(0.3), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
    }
    
    private var statusColor: Color {
        switch session.status {
        case .running: return .orange
        case .completed: return .green
        case .failed: return .red
        case .stopped: return .gray
        }
    }
}

struct AttackCardHeader: View {
    let session: AttackSession
    @Binding var isExpanded: Bool
    
    var body: some View {
        HStack {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            // Attack info
            VStack(alignment: .leading, spacing: 2) {
                Text(session.attackName)
                    .font(.headerTertiary)
                
                Text("Target: \(session.target):\(session.port)")
                    .font(.captionPrimary)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Duration and status indicator
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatDuration(session.duration))
                    .font(.codeSmall)
                    .foregroundColor(.secondary)
                
                Text(session.status.rawValue.capitalized)
                    .font(.caption2)
                    .foregroundColor(statusColor)
                    .fontWeight(.medium)
            }
            
            // Expand button
            Button(action: { isExpanded.toggle() }) {
                Image(systemName: "chevron.down")
                    .font(.captionPrimary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .buttonStyle(.plain)
        }
        .padding(.spacing_md)
    }
    
    private var statusColor: Color {
        switch session.status {
        case .running: return .orange
        case .completed: return .green
        case .failed: return .red
        case .stopped: return .gray
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

struct AttackCardExpandedContent: View {
    let session: AttackSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            attackDetailsSection
            findingsSection
            consoleOutputSection
        }
    }
    
    private var attackDetailsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Attack Details")
                .font(.headerTertiary)
            
            statusRow
            startTimeRow
            
            if session.isCompleted {
                durationRow
                endTimeRow
            }
        }
    }
    
    private var statusRow: some View {
        HStack {
            Text("Status:")
                .font(.bodySecondary)
            Text(session.status.rawValue.capitalized)
                .foregroundColor(statusColor)
        }
    }
    
    private var startTimeRow: some View {
        HStack {
            Text("Started:")
                .font(.bodySecondary)
            Text(session.startTime, style: .time)
                .foregroundColor(.secondary)
        }
    }
    
    private var durationRow: some View {
        HStack {
            Text("Duration:")
                .font(.bodySecondary)
            Text(formatDuration(session.duration))
                .foregroundColor(.secondary)
        }
    }
    
    private var endTimeRow: some View {
        Group {
            if let endTime = session.endTime {
                HStack {
                    Text("Completed:")
                        .font(.bodySecondary)
                    Text(endTime, style: .time)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var findingsSection: some View {
        Group {
            if session.isCompleted {
                FindingsSummaryView(session: session)
            }
        }
    }
    
    private var consoleOutputSection: some View {
        Group {
            if !session.outputLines.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Console Output")
                        .font(.headerTertiary)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(session.outputLines.suffix(10), id: \.self) { line in
                                Text(line)
                                    .font(.codeSmall)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(8)
                    }
                    .frame(maxHeight: 120)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(6)
                }
            }
        }
        .padding(.spacing_md)
        .padding(.top, 0)
    }
    
    private var statusColor: Color {
        switch session.status {
        case .running: return .orange
        case .completed: return .green
        case .failed: return .red
        case .stopped: return .gray
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

struct FindingsSummaryView: View {
    let session: AttackSession
    @Environment(AppState.self) private var appState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Attack Findings")
                .font(.headerTertiary)
            
            if let attackResult = getAttackResult() {
                // Attack completion status
                HStack {
                    Image(systemName: attackResult.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(attackResult.success ? .green : .red)
                    
                    Text(attackResult.success ? "Attack Completed Successfully" : "Attack Failed or Found Issues")
                        .font(.bodySecondary)
                        .foregroundColor(attackResult.success ? .green : .red)
                }
                
                // Files discovered
                if !attackResult.files.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.blue)
                            Text("Files/Directories Found")
                                .font(.bodySecondary)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text("\(attackResult.files.count)")
                                .font(.captionPrimary)
                                .foregroundColor(.secondary)
                        }
                        
                        ScrollView {
                            VStack(alignment: .leading, spacing: 2) {
                                ForEach(attackResult.files.prefix(5), id: \.self) { file in
                                    HStack {
                                        Text("•")
                                            .foregroundColor(.blue)
                                        Text(file)
                                            .font(.codeSmall)
                                            .foregroundColor(.primary)
                                    }
                                }
                                if attackResult.files.count > 5 {
                                    Text("... and \(attackResult.files.count - 5) more")
                                        .font(.captionPrimary)
                                        .foregroundColor(.secondary)
                                        .italic()
                                }
                            }
                        }
                        .frame(maxHeight: 80)
                    }
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
                }
                
                // Vulnerabilities found
                if !attackResult.vulnerabilities.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("Vulnerabilities Found")
                                .font(.bodySecondary)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text("\(attackResult.vulnerabilities.count)")
                                .font(.captionPrimary)
                                .foregroundColor(.secondary)
                        }
                        
                        ScrollView {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(attackResult.vulnerabilities.prefix(3), id: \.id) { vuln in
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack {
                                            Text(vuln.type)
                                                .font(.bodySecondary)
                                                .fontWeight(.medium)
                                            
                                            Spacer()
                                            
                                            Text(vuln.severity.uppercased())
                                                .font(.captionPrimary)
                                                .fontWeight(.bold)
                                                .foregroundColor(severityColor(vuln.severity))
                                        }
                                        
                                        Text(vuln.description)
                                            .font(.captionPrimary)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }
                                    .padding(6)
                                    .background(Color.red.opacity(0.05))
                                    .cornerRadius(4)
                                }
                                if attackResult.vulnerabilities.count > 3 {
                                    Text("... and \(attackResult.vulnerabilities.count - 3) more")
                                        .font(.captionPrimary)
                                        .foregroundColor(.secondary)
                                        .italic()
                                }
                            }
                        }
                        .frame(maxHeight: 120)
                    }
                    .padding(8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
                }
                
                // Credentials found
                if !attackResult.credentials.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "key.fill")
                                .foregroundColor(.orange)
                            Text("Credentials Found")
                                .font(.bodySecondary)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text("\(attackResult.credentials.count)")
                                .font(.captionPrimary)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Valid credentials discovered during brute force attack")
                            .font(.captionPrimary)
                            .foregroundColor(.secondary)
                    }
                    .padding(8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
                }
                
                // Attack duration
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.secondary)
                    Text("Duration:")
                        .font(.bodySecondary)
                    Text(formatDuration(attackResult.duration))
                        .font(.bodySecondary)
                        .fontWeight(.medium)
                }
                
                // Show summary if no specific findings
                if attackResult.files.isEmpty && attackResult.vulnerabilities.isEmpty && attackResult.credentials.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("No Security Issues Found")
                                .font(.bodySecondary)
                                .fontWeight(.medium)
                        }
                        
                        Text("The target appears to be secure against this type of attack. No vulnerabilities, exposed files, or weak credentials were discovered.")
                            .font(.captionPrimary)
                            .foregroundColor(.secondary)
                    }
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
                }
                
            } else {
                // Still running or no result available
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                    Text("Attack in progress...")
                        .font(.bodySecondary)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func getAttackResult() -> AttackResult? {
        return appState.attackFramework.attackHistory.first { $0.sessionId == session.sessionId }
    }
    
    private func severityColor(_ severity: String) -> Color {
        switch severity.lowercased() {
        case "critical": return .red
        case "high": return .orange
        case "medium": return .yellow
        case "low": return .blue
        default: return .gray
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

#Preview {
    ActiveAttacksView()
        .environment(AppState())
        .frame(width: 1000, height: 700)
}