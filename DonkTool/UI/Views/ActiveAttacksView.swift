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
                // Refresh session data periodically
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
                    
                    Text("\(appState.attackFramework.activeSessions.count) running")
                        .font(.captionPrimary)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Refresh") {
                    // Force refresh
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
            
            // Duration
            Text(formatDuration(Date().timeIntervalSince(session.startTime)))
                .font(.codeSmall)
                .foregroundColor(.secondary)
            
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
            
            // Attack details
            VStack(alignment: .leading, spacing: 8) {
                Text("Attack Details")
                    .font(.headerTertiary)
                
                HStack {
                    Text("Status:")
                        .font(.bodySecondary)
                    Text(session.status.rawValue.capitalized)
                        .foregroundColor(statusColor)
                }
                
                HStack {
                    Text("Started:")
                        .font(.bodySecondary)
                    Text(session.startTime, style: .time)
                        .foregroundColor(.secondary)
                }
                
                if session.status == .completed || session.status == .failed {
                    HStack {
                        Text("Duration:")
                            .font(.bodySecondary)
                        Text(formatDuration(Date().timeIntervalSince(session.startTime)))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Console output
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

#Preview {
    ActiveAttacksView()
        .environment(AppState())
        .frame(width: 1000, height: 700)
}