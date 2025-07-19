//
//  DashboardView.swift
//  DonkTool
//
//  Main dashboard interface
//

import SwiftUI
import Foundation

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                // Quick Stats Cards
                StatsCardView(
                    title: "Active Targets",
                    value: "\(appState.targets.count)",
                    icon: "target",
                    color: .blue
                )
                
                StatsCardView(
                    title: "Vulnerabilities Found",
                    value: "\(totalVulnerabilities)",
                    icon: "exclamationmark.triangle.fill",
                    color: .red
                )
                
                StatsCardView(
                    title: "Recent Scans",
                    value: "\(appState.lastScanResults.count)",
                    icon: "magnifyingglass",
                    color: .green
                )
                
                StatsCardView(
                    title: "CVE Database",
                    value: "\(appState.cveDatabase.count)",
                    icon: "shield.checkerboard",
                    color: .orange
                )
            }
            .padding()
            
            // Recent Activity
            VStack(alignment: .leading, spacing: 16) {
                Text("Recent Activity")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                
                if appState.lastScanResults.isEmpty {
                    ContentUnavailableView(
                        "No Recent Scans",
                        systemImage: "magnifyingglass",
                        description: Text("Start a scan to see results here")
                    )
                    .frame(height: 200)
                } else {
                    ForEach(appState.lastScanResults.prefix(5)) { result in
                        ScanResultRowView(result: result)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Dashboard")
    }
    
    private var totalVulnerabilities: Int {
        appState.targets.reduce(0) { $0 + $1.vulnerabilities.count }
    }
}

struct StatsCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct ScanResultRowView: View {
    let result: ScanResult
    
    var body: some View {
        HStack {
            Image(systemName: iconForScanType(result.scanType))
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(result.scanType.rawValue)
                    .fontWeight(.medium)
                Text(result.startTime, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(result.status.rawValue)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(backgroundColorForStatus(result.status))
                .cornerRadius(8)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func iconForScanType(_ type: ScanResult.ScanType) -> String {
        switch type {
        case .portScan: return "network"
        case .vulnScan: return "shield"
        case .webScan: return "globe"
        }
    }
    
    private func backgroundColorForStatus(_ status: ScanResult.ScanStatus) -> Color {
        switch status {
        case .running: return .blue.opacity(0.2)
        case .completed: return .green.opacity(0.2)
        case .failed: return .red.opacity(0.2)
        case .cancelled: return .gray.opacity(0.2)
        }
    }
}

#Preview {
    DashboardView()
        .environment(AppState())
}
