//
//  ModernDashboardView.swift
//  DonkTool
//
//  Modern dashboard interface
//

import SwiftUI
import Charts

struct ModernDashboardView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // Header section
                DashboardHeader()
                
                // Key metrics grid
                MetricsGrid()
                
                // Charts and visualizations
                ChartsSection()
                
                // Recent activity and vulnerabilities
                HStack(alignment: .top, spacing: 20) {
                    RecentActivityCard()
                        .frame(maxWidth: .infinity)
                    
                    VulnerabilitiesCard()
                        .frame(maxWidth: .infinity)
                }
                
                // Active scans section
                if appState.isNetworkScanning || appState.isWebScanning {
                    ActiveScansSection()
                }
            }
            .padding(24)
        }
        .navigationTitle("Security Dashboard")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Refresh") {
                    // Refresh data
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

struct DashboardHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Security Assessment Overview")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Last updated: \(Date().formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    
                    Text("System Operational")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.quaternary, lineWidth: 1)
        )
    }
}

struct MetricsGrid: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
            MetricCard(
                title: "Active Targets",
                value: "\(appState.targets.count)",
                change: "+2",
                trend: .up,
                color: .blue,
                icon: "target"
            )
            
            MetricCard(
                title: "Total Vulnerabilities",
                value: "\(totalVulnerabilities)",
                change: criticalVulnerabilities > 0 ? "+\(criticalVulnerabilities)" : "0",
                trend: criticalVulnerabilities > 0 ? .down : .neutral,
                color: .red,
                icon: "exclamationmark.triangle.fill"
            )
            
            MetricCard(
                title: "Critical Issues",
                value: "\(criticalVulnerabilities)",
                change: "0",
                trend: .neutral,
                color: .orange,
                icon: "flame.fill"
            )
            
            MetricCard(
                title: "CVE Database",
                value: "\(appState.cveDatabase.count)",
                change: "Updated",
                trend: .up,
                color: .green,
                icon: "shield.checkerboard"
            )
        }
    }
    
    private var totalVulnerabilities: Int {
        appState.targets.reduce(0) { $0 + $1.vulnerabilities.count }
    }
    
    private var criticalVulnerabilities: Int {
        appState.targets.flatMap { $0.vulnerabilities }.filter { $0.severity == .critical }.count
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let change: String
    let trend: TrendDirection
    let color: Color
    let icon: String
    
    enum TrendDirection {
        case up, down, neutral
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .neutral: return .gray
            }
        }
        
        var systemImage: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "minus"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: trend.systemImage)
                        .font(.caption2)
                    Text(change)
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundColor(trend.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.quaternary, lineWidth: 1)
        )
    }
}

struct ChartsSection: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            VulnerabilityDistributionChart()
                .frame(maxWidth: .infinity)
            
            ScanActivityChart()
                .frame(maxWidth: .infinity)
        }
    }
}

struct VulnerabilityDistributionChart: View {
    @Environment(AppState.self) private var appState
    
    var vulnerabilityData: [ChartData] {
        let vulnerabilities = appState.getAllVulnerabilities()
        let critical = vulnerabilities.filter { $0.severity == .critical }.count
        let high = vulnerabilities.filter { $0.severity == .high }.count
        let medium = vulnerabilities.filter { $0.severity == .medium }.count
        let low = vulnerabilities.filter { $0.severity == .low }.count
        
        return [
            ChartData(category: "Critical", value: critical, color: .red),
            ChartData(category: "High", value: high, color: .orange),
            ChartData(category: "Medium", value: medium, color: .yellow),
            ChartData(category: "Low", value: low, color: .green)
        ].filter { $0.value > 0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Vulnerability Distribution")
                .font(.headline)
                .fontWeight(.semibold)
            
            if vulnerabilityData.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No vulnerabilities found")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
            } else {
                Chart(vulnerabilityData, id: \.category) { item in
                    SectorMark(
                        angle: .value("Count", item.value),
                        innerRadius: .ratio(0.4),
                        angularInset: 2
                    )
                    .foregroundStyle(item.color)
                    .opacity(0.8)
                }
                .frame(height: 200)
                .chartLegend(position: .bottom, alignment: .center)
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

struct ScanActivityChart: View {
    // TODO: Replace with real scan activity data from AppState
    let placeholderData = [
        ChartData(category: "Mon", value: 0, color: .blue),
        ChartData(category: "Tue", value: 0, color: .blue),
        ChartData(category: "Wed", value: 0, color: .blue),
        ChartData(category: "Thu", value: 0, color: .blue),
        ChartData(category: "Fri", value: 0, color: .blue),
        ChartData(category: "Sat", value: 0, color: .blue),
        ChartData(category: "Sun", value: 0, color: .blue)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Scan Activity (7 days)")
                .font(.headline)
                .fontWeight(.semibold)
            
            Chart(placeholderData, id: \.category) { item in
                BarMark(
                    x: .value("Day", item.category),
                    y: .value("Scans", item.value)
                )
                .foregroundStyle(.blue.gradient)
                .cornerRadius(4)
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

struct ChartData {
    let category: String
    let value: Int
    let color: Color
}

struct RecentActivityCard: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .fontWeight(.semibold)
            
            if appState.lastScanResults.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 24))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No recent activity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(height: 120)
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 12) {
                    ForEach(appState.lastScanResults.prefix(3)) { result in
                        ActivityRow(result: result)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

struct ActivityRow: View {
    let result: ScanResult
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconForScanType(result.scanType))
                .font(.system(size: 16))
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(result.scanType.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(result.startTime.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            ScanStatusBadge(status: result.status)
        }
        .padding(.vertical, 4)
    }
    
    private func iconForScanType(_ type: ScanResult.ScanType) -> String {
        switch type {
        case .portScan: return "network"
        case .vulnScan: return "shield"
        case .webScan: return "globe"
        }
    }
}

struct ScanStatusBadge: View {
    let status: ScanResult.ScanStatus
    
    var body: some View {
        Text(status.rawValue)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(4)
    }
    
    private var backgroundColor: Color {
        switch status {
        case .running: return .blue.opacity(0.2)
        case .completed: return .green.opacity(0.2)
        case .failed: return .red.opacity(0.2)
        case .cancelled: return .gray.opacity(0.2)
        }
    }
    
    private var foregroundColor: Color {
        switch status {
        case .running: return .blue
        case .completed: return .green
        case .failed: return .red
        case .cancelled: return .gray
        }
    }
}

struct VulnerabilitiesCard: View {
    @Environment(AppState.self) private var appState
    
    var recentVulnerabilities: [Vulnerability] {
        appState.getAllVulnerabilities()
            .sorted { $0.discoveredAt > $1.discoveredAt }
            .prefix(5)
            .map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Vulnerabilities")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to vulnerabilities view
                }
                .font(.caption)
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
            }
            
            if recentVulnerabilities.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green.opacity(0.7))
                    
                    Text("No vulnerabilities found")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(height: 120)
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 12) {
                    ForEach(recentVulnerabilities) { vulnerability in
                        VulnerabilityRow(vulnerability: vulnerability)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

struct VulnerabilityRow: View {
    let vulnerability: Vulnerability
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(vulnerability.severity.color)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(vulnerability.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(vulnerability.discoveredAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(vulnerability.severity.rawValue.uppercased())
                .font(.caption2)
                .fontWeight(.bold)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(vulnerability.severity.color.opacity(0.2))
                .foregroundColor(vulnerability.severity.color)
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
    }
}

struct ActiveScansSection: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Active Scans")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                if appState.isNetworkScanning {
                    ScanProgressCard(
                        title: "Network Port Scan",
                        target: appState.currentNetworkTarget,
                        progress: appState.networkScanProgress,
                        color: .blue,
                        icon: "network"
                    )
                }
                
                if appState.isWebScanning {
                    ScanProgressCard(
                        title: "Web Application Scan",
                        target: appState.currentWebTarget,
                        progress: appState.webScanProgress,
                        color: .green,
                        icon: "globe"
                    )
                }
            }
        }
        .padding(20)
        .background(Color.orange.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }
}

struct ScanProgressCard: View {
    let title: String
    let target: String
    let progress: Double
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: color))
                
                Text("Target: \(target)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
}

#Preview {
    ModernDashboardView()
        .environment(AppState())
        .frame(width: 1000, height: 800)
}
