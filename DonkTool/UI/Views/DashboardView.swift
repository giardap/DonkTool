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
    @State private var selectedTimeframe: TimeFrame = .last24Hours
    @State private var showingVulnerabilityDetails = false
    @State private var showingQuickScan = false
    
    enum TimeFrame: String, CaseIterable {
        case last24Hours = "Last 24 Hours"
        case lastWeek = "Last Week"  
        case lastMonth = "Last Month"
        case allTime = "All Time"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                statsGridSection
                quickActionsSection
                vulnerabilityOverviewSection
                recentActivitySection
                activeScansSection
            }
            .padding(.vertical)
        }
        .navigationTitle("Security Dashboard")
        .sheet(isPresented: $showingVulnerabilityDetails) {
            VulnerabilityDetailsView(vulnerabilities: allVulnerabilities)
        }
        .sheet(isPresented: $showingQuickScan) {
            QuickScanView()
        }
        .refreshable {
            await refreshDashboard()
        }
    }
    
    // MARK: - View Sections
    
    @ViewBuilder
    private var statsGridSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatsCardView(
                title: "Active Targets",
                value: "\(appState.targets.count)",
                icon: "target",
                color: .blue,
                trend: calculateTargetTrend()
            )
            
            StatsCardView(
                title: "Vulnerabilities Found",
                value: "\(totalVulnerabilities)",
                icon: "exclamationmark.triangle.fill",
                color: .red,
                trend: calculateVulnTrend(),
                action: { showingVulnerabilityDetails = true }
            )
            
            StatsCardView(
                title: "Critical Issues",
                value: "\(criticalVulnerabilities)",
                icon: "exclamationmark.octagon.fill",
                color: .red,
                trend: .neutral
            )
            
            StatsCardView(
                title: "Recent Scans",
                value: "\(appState.lastScanResults.count)",
                icon: "magnifyingglass",
                color: .green,
                trend: .neutral
            )
            
            StatsCardView(
                title: "CVE Database",
                value: "\(appState.cveDatabase.count + appState.liveCVEDatabase.currentCVEs.count)",
                icon: "shield.checkerboard",
                color: .orange,
                trend: .up
            )
            
            StatsCardView(
                title: "Bluetooth Devices",
                value: "\(appState.bluetoothFramework.discoveredDevices.count)",
                icon: "wave.3.right",
                color: .purple,
                trend: .neutral
            )
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Quick Actions")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Picker("Timeframe", selection: $selectedTimeframe) {
                    ForEach(TimeFrame.allCases, id: \.self) { timeframe in
                        Text(timeframe.rawValue).tag(timeframe)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 300)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionCard(
                    title: "Quick Scan",
                    icon: "bolt.fill",
                    color: .blue,
                    action: { showingQuickScan = true }
                )
                
                QuickActionCard(
                    title: "Bluetooth Scan",
                    icon: "wave.3.right",
                    color: .purple,
                    action: {
                        Task {
                            await appState.startBluetoothScan(mode: .active)
                        }
                    }
                )
                
                QuickActionCard(
                    title: "Network Scan", 
                    icon: "network",
                    color: .green,
                    action: {
                        Task {
                            await appState.startNetworkScan(target: "192.168.1.0/24", portRange: "1-1000")
                        }
                    }
                )
                
                QuickActionCard(
                    title: "Update CVEs",
                    icon: "arrow.clockwise",
                    color: .orange,
                    action: {
                        Task {
                            await appState.liveCVEDatabase.updateCVEDatabase()
                        }
                    }
                )
                
                QuickActionCard(
                    title: "Export Report",
                    icon: "doc.text",
                    color: .indigo,
                    action: { exportReport() }
                )
                
                QuickActionCard(
                    title: "View Logs",
                    icon: "list.bullet.rectangle",
                    color: .gray,
                    action: { /* Navigate to logs */ }
                )
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var vulnerabilityOverviewSection: some View {
        if totalVulnerabilities > 0 {
            VulnerabilityOverviewCard(
                criticalCount: criticalVulnerabilities,
                highCount: highVulnerabilities,
                mediumCount: mediumVulnerabilities,
                lowCount: lowVulnerabilities,
                onViewDetails: { showingVulnerabilityDetails = true }
            )
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("Last updated: \(Date(), style: .relative)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if appState.lastScanResults.isEmpty && appState.bluetoothVulnerabilities.isEmpty {
                ContentUnavailableView(
                    "No Recent Activity",
                    systemImage: "clock",
                    description: Text("Start a scan to see activity here")
                )
                .frame(height: 200)
            } else {
                VStack(spacing: 8) {
                    // Recent scan results
                    ForEach(appState.lastScanResults.prefix(3)) { result in
                        ScanResultRowView(result: result)
                    }
                    
                    // Recent Bluetooth vulnerabilities
                    ForEach(appState.bluetoothVulnerabilities.prefix(3)) { vuln in
                        BluetoothVulnRowView(vulnerability: vuln)
                    }
                    
                    if appState.lastScanResults.count > 3 || appState.bluetoothVulnerabilities.count > 3 {
                        Text("+ \(max(0, appState.lastScanResults.count + appState.bluetoothVulnerabilities.count - 6)) more items")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var activeScansSection: some View {
        if appState.isScanning || appState.isBluetoothScanning {
            ActiveScansCard(
                isNetworkScanning: appState.isScanning,
                isBluetoothScanning: appState.isBluetoothScanning,
                networkProgress: appState.networkScanProgress,
                bluetoothProgress: appState.bluetoothScanProgress
            )
            .padding(.horizontal)
        }
    }
    
    private var totalVulnerabilities: Int {
        let targetVulns = appState.targets.reduce(0) { $0 + $1.vulnerabilities.count }
        let bluetoothVulns = appState.bluetoothVulnerabilities.count
        return targetVulns + bluetoothVulns
    }
    
    private var criticalVulnerabilities: Int {
        let targetCritical = appState.targets.flatMap(\.vulnerabilities).filter { $0.severity == .critical }.count
        let bluetoothCritical = appState.bluetoothVulnerabilities.filter { $0.severity == .critical }.count
        return targetCritical + bluetoothCritical
    }
    
    private var highVulnerabilities: Int {
        let targetHigh = appState.targets.flatMap(\.vulnerabilities).filter { $0.severity == .high }.count
        let bluetoothHigh = appState.bluetoothVulnerabilities.filter { $0.severity == .high }.count
        return targetHigh + bluetoothHigh
    }
    
    private var mediumVulnerabilities: Int {
        let targetMedium = appState.targets.flatMap(\.vulnerabilities).filter { $0.severity == .medium }.count
        let bluetoothMedium = appState.bluetoothVulnerabilities.filter { $0.severity == .medium }.count
        return targetMedium + bluetoothMedium
    }
    
    private var lowVulnerabilities: Int {
        let targetLow = appState.targets.flatMap(\.vulnerabilities).filter { $0.severity == .low }.count
        let bluetoothLow = appState.bluetoothVulnerabilities.filter { $0.severity == .low }.count
        return targetLow + bluetoothLow
    }
    
    private var allVulnerabilities: [AnyVulnerability] {
        let targetVulns = appState.targets.flatMap(\.vulnerabilities).map { AnyVulnerability.target($0) }
        let bluetoothVulns = appState.bluetoothVulnerabilities.map { AnyVulnerability.bluetooth($0) }
        return targetVulns + bluetoothVulns
    }
    
    enum Trend {
        case up, down, neutral
        
        var icon: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .neutral: return "minus"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .neutral: return .gray
            }
        }
    }
    
    private func calculateTargetTrend() -> Trend {
        // Simple heuristic: if we have targets, trend is up
        return appState.targets.count > 0 ? .up : .neutral
    }
    
    private func calculateVulnTrend() -> Trend {
        // Simple heuristic: more vulnerabilities = up trend
        return totalVulnerabilities > 0 ? .up : .neutral
    }
    
    private func exportReport() {
        // TODO: Implement report export
        print("Exporting security report...")
    }
    
    private func refreshDashboard() async {
        // Refresh all data sources
        await appState.liveCVEDatabase.updateCVEDatabase()
        // TODO: Add more refresh logic
    }
}

// MARK: - Enhanced Stats Card

struct StatsCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var trend: DashboardView.Trend = .neutral
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: { action?() }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.title2)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: trend.icon)
                            .font(.caption)
                        Text("Trend")
                            .font(.caption2)
                    }
                    .foregroundColor(trend.color)
                }
                
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(12)
            .shadow(radius: 2)
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

// MARK: - Quick Action Card

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Vulnerability Overview Card

struct VulnerabilityOverviewCard: View {
    let criticalCount: Int
    let highCount: Int
    let mediumCount: Int
    let lowCount: Int
    let onViewDetails: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Vulnerability Overview")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View Details", action: onViewDetails)
                    .buttonStyle(.borderedProminent)
            }
            
            HStack(spacing: 16) {
                VulnSeverityView(count: criticalCount, severity: "Critical", color: .red)
                VulnSeverityView(count: highCount, severity: "High", color: .orange)
                VulnSeverityView(count: mediumCount, severity: "Medium", color: .yellow)
                VulnSeverityView(count: lowCount, severity: "Low", color: .blue)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct VulnSeverityView: View {
    let count: Int
    let severity: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(severity)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Bluetooth Vulnerability Row

struct BluetoothVulnRowView: View {
    let vulnerability: MacOSBluetoothVulnerability
    
    var body: some View {
        HStack {
            Image(systemName: "wave.3.right")
                .foregroundColor(.purple)
            
            VStack(alignment: .leading) {
                Text(vulnerability.title)
                    .fontWeight(.medium)
                Text("Device: \(vulnerability.deviceAddress)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(vulnerability.severity.rawValue)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(backgroundColorForSeverity(vulnerability.severity))
                .cornerRadius(8)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(8)
    }
    
    private func backgroundColorForSeverity(_ severity: Vulnerability.Severity) -> Color {
        switch severity {
        case .critical: return .red.opacity(0.2)
        case .high: return .orange.opacity(0.2)
        case .medium: return .yellow.opacity(0.2)
        case .low: return .blue.opacity(0.2)
        case .info: return .gray.opacity(0.2)
        }
    }
}

// MARK: - Active Scans Card

struct ActiveScansCard: View {
    let isNetworkScanning: Bool
    let isBluetoothScanning: Bool
    let networkProgress: Double
    let bluetoothProgress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Active Scans")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                if isNetworkScanning {
                    ScanProgressView(
                        title: "Network Scan",
                        progress: networkProgress,
                        icon: "network",
                        color: .green
                    )
                }
                
                if isBluetoothScanning {
                    ScanProgressView(
                        title: "Bluetooth Scan",
                        progress: bluetoothProgress,
                        icon: "wave.3.right",
                        color: .purple
                    )
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ScanProgressView: View {
    let title: String
    let progress: Double
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .fontWeight(.medium)
                
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: color))
                
                Text("\(Int(progress * 100))% complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Supporting Types

enum AnyVulnerability {
    case target(Vulnerability)
    case bluetooth(MacOSBluetoothVulnerability)
    
    var title: String {
        switch self {
        case .target(let vuln): return vuln.title
        case .bluetooth(let vuln): return vuln.title
        }
    }
    
    var severity: Vulnerability.Severity {
        switch self {
        case .target(let vuln): return vuln.severity
        case .bluetooth(let vuln): return vuln.severity
        }
    }
}

// MARK: - Placeholder Views

struct VulnerabilityDetailsView: View {
    let vulnerabilities: [AnyVulnerability]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(vulnerabilities.indices, id: \.self) { index in
                    let vuln = vulnerabilities[index]
                    VStack(alignment: .leading) {
                        Text(vuln.title)
                            .fontWeight(.medium)
                        Text(vuln.severity.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("All Vulnerabilities")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct QuickScanView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var target = "192.168.1.0/24"
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Target (IP/CIDR)", text: $target)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                
                Button("Start Quick Scan") {
                    // TODO: Implement quick scan
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
            .navigationTitle("Quick Scan")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
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
        .background(Color.cardBackground)
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
