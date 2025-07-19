//
//  ContentView.swift
//  DonkTool
//
//  Main application interface with modern design
//

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            ModernSidebarView()
                .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 320)
        } detail: {
            DetailView()
        }
        .overlay(alignment: .topTrailing) {
            if appState.isNetworkScanning || appState.isWebScanning {
                ActiveScansIndicator()
                    .padding()
            }
        }
    }
}

struct ModernSidebarView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        VStack(spacing: 0) {
            // Cleaner header
            VStack(spacing: 20) {
                HStack {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.linearGradient(
                            colors: [.blue, .purple], 
                            startPoint: .topLeading, 
                            endPoint: .bottomTrailing
                        ))
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text("DonkTool")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Text("Penetration Testing")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Simplified navigation
            VStack(spacing: 8) {
                ForEach(AppState.MainTab.allCases, id: \.self) { tab in
                    CleanTabButton(
                        tab: tab,
                        isSelected: appState.currentTab == tab,
                        hasActivity: hasActivity(for: tab)
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            appState.currentTab = tab
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            
            Spacer()
            
            // Compact active scans indicator
            if appState.isNetworkScanning || appState.isWebScanning {
                CompactActiveScansCard()
                    .padding(.horizontal, 16)
            }
            
            // Quick stats at bottom
            CompactStatsView()
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private func hasActivity(for tab: AppState.MainTab) -> Bool {
        switch tab {
        case .networkScanner: return appState.isNetworkScanning
        case .webTesting: return appState.isWebScanning
        case .cveManager: return appState.cveDatabase.isLoading
        default: return false
        }
    }
}

struct CleanTabButton: View {
    let tab: AppState.MainTab
    let isSelected: Bool
    let hasActivity: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .frame(width: 20)
                
                Text(tab.title)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if hasActivity {
                    Circle()
                        .fill(.orange)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

struct CompactActiveScansCard: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Active Scans")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            VStack(spacing: 4) {
                if appState.isNetworkScanning {
                    CompactScanRow(
                        title: "Network",
                        progress: appState.networkScanProgress,
                        color: .blue
                    )
                }
                
                if appState.isWebScanning {
                    CompactScanRow(
                        title: "Web",
                        progress: appState.webScanProgress,
                        color: .green
                    )
                }
            }
        }
        .padding(12)
        .background(Color.orange.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }
}

struct CompactScanRow: View {
    let title: String
    let progress: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(y: 0.6)
            
            Text("\(Int(progress * 100))%")
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

struct CompactStatsView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        HStack(spacing: 16) {
            CompactStatItem(
                value: "\(appState.targets.count)",
                label: "Targets",
                color: .blue
            )
            
            CompactStatItem(
                value: "\(appState.getAllVulnerabilities().count)",
                label: "Vulns",
                color: .red
            )
            
            CompactStatItem(
                value: "\(appState.cveDatabase.count)",
                label: "CVEs",
                color: .orange
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(6)
    }
}

struct CompactStatItem: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ActiveScansIndicator: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        HStack(spacing: 8) {
            if appState.isNetworkScanning {
                ScanBadge(type: "Network", color: .blue)
            }
            
            if appState.isWebScanning {
                ScanBadge(type: "Web", color: .green)
            }
        }
    }
}

struct ScanBadge: View {
    let type: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            ProgressView()
                .scaleEffect(0.6)
            
            Text("\(type) Scan")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .foregroundColor(color)
        .cornerRadius(8)
    }
}

struct QuickActionButton: View {
    var body: some View {
        Button(action: {
            // Quick scan action
        }) {
            HStack {
                Image(systemName: "bolt.fill")
                Text("Quick Scan")
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 36)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.regular)
    }
}

struct DetailView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        Group {
            switch appState.currentTab {
            case .dashboard:
                ModernDashboardView()
            case .cveManager:
                CVEManagerView()
            case .networkScanner:
                ModernNetworkScannerView()
            case .webTesting:
                ModernWebTestingView()
            case .dosStressTesting:
                DoSTestingView()
            case .activeAttacks:
                ActiveAttacksView()
            case .reporting:
                ReportingView()
            case .settings:
                SettingsView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

#Preview {
    ContentView()
        .environment(AppState())
        .frame(width: 1200, height: 800)
}
