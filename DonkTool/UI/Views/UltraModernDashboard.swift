//
//  UltraModernDashboard.swift
//  DonkTool
//
//  Ultra-modern dashboard with stunning visuals
//

import SwiftUI
import Charts

struct UltraModernDashboard: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTimeRange = "24h"
    @State private var animateCards = false
    @State private var pulseAnimation = false
    
    let timeRanges = ["1h", "24h", "7d", "30d"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xLarge) {
                // Header
                UltraDashboardHeader(selectedTimeRange: $selectedTimeRange, timeRanges: timeRanges)
                    .padding(.horizontal)
                
                // Quick Actions
                QuickActionsSection()
                    .padding(.horizontal)
                
                // Stats Overview
                StatsOverviewSection()
                    .padding(.horizontal)
                
                // Activity Charts
                ActivityChartsSection()
                    .padding(.horizontal)
                
                // Recent Findings
                RecentFindingsSection()
                    .padding(.horizontal)
                
                // System Status
                SystemStatusSection()
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color.appPrimaryBackground)
        .onAppear {
            withAnimation(Animations.standard) {
                animateCards = true
            }
            withAnimation(Animation.easeInOut(duration: 1).repeatForever()) {
                pulseAnimation = true
            }
        }
    }
}

// MARK: - Dashboard Header
struct UltraDashboardHeader: View {
    @Binding var selectedTimeRange: String
    let timeRanges: [String]
    @State private var currentTime = Date()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: Spacing.medium) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Security Dashboard")
                        .font(Typography.largeTitle)
                        .foregroundStyle(Color.primaryGradient)
                    
                    Text(currentTime, style: .date)
                        .font(Typography.headline)
                        .foregroundColor(.secondary)
                    +
                    Text(" • ")
                        .font(Typography.headline)
                        .foregroundColor(.secondary)
                    +
                    Text(currentTime, style: .time)
                        .font(Typography.headline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Time Range Selector
                HStack(spacing: 0) {
                    ForEach(timeRanges, id: \.self) { range in
                        TimeRangeButton(
                            title: range,
                            isSelected: selectedTimeRange == range
                        ) {
                            withAnimation(Animations.quick) {
                                selectedTimeRange = range
                            }
                        }
                    }
                }
                .background(Color.appSecondaryBackground)
                .cornerRadius(10)
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
}

struct TimeRangeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.primaryAccent : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Quick Actions
struct QuickActionsSection: View {
    @Environment(AppState.self) private var appState
    
    let actions = [
        ("Network Scan", "network", Color.primaryAccent),
        ("Web Test", "globe", Color.tertiaryAccent),
        ("CVE Search", "magnifyingglass.circle", Color.warningOrange),
        ("Generate Report", "doc.text", Color.secondaryAccent)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            SectionHeader("Quick Actions", icon: "bolt.fill")
            
            HStack(spacing: Spacing.medium) {
                ForEach(actions, id: \.0) { action in
                    UltraQuickActionCard(
                        title: action.0,
                        icon: action.1,
                        color: action.2
                    ) {
                        handleAction(action.0)
                    }
                }
            }
        }
    }
    
    private func handleAction(_ action: String) {
        withAnimation(Animations.standard) {
            switch action {
            case "Network Scan":
                appState.currentTab = .securityScanner
            case "Web Test":
                appState.currentTab = .securityScanner
            case "CVE Search":
                appState.currentTab = .vulnerabilityDatabase
            case "Generate Report":
                appState.currentTab = .reporting
            default:
                break
            }
        }
    }
}

struct UltraQuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: color.opacity(0.3), radius: isHovered ? 12 : 8, x: 0, y: 4)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                        .symbolEffect(.bounce, value: isHovered)
                }
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: isHovered ? [color.opacity(0.3), color.opacity(0.1)] : [Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(Animations.spring, value: isPressed)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(Animations.quick) {
                isHovered = hovering
            }
        }
        .pressEvents {
            withAnimation(Animations.quick) {
                isPressed = true
            }
        } onRelease: {
            withAnimation(Animations.quick) {
                isPressed = false
            }
        }
    }
}

// MARK: - Stats Overview
struct StatsOverviewSection: View {
    @Environment(AppState.self) private var appState
    
    var criticalCount: Int {
        appState.getAllVulnerabilities().filter { $0.severity == .critical }.count
    }
    
    var highCount: Int {
        appState.getAllVulnerabilities().filter { $0.severity == .high }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            SectionHeader("Security Overview", subtitle: "Real-time threat analysis", icon: "shield.lefthalf.filled")
            
            HStack(spacing: Spacing.medium) {
                UltraStatCard(
                    title: "Active Targets",
                    value: "\(appState.targets.count)",
                    icon: "target",
                    color: .primaryAccent,
                    trend: .up(12)
                )
                
                UltraStatCard(
                    title: "Vulnerabilities",
                    value: "\(appState.getAllVulnerabilities().count)",
                    icon: "exclamationmark.shield",
                    color: .warningOrange,
                    trend: .down(8),
                    alert: criticalCount > 0
                )
                
                UltraStatCard(
                    title: "Critical Issues",
                    value: "\(criticalCount)",
                    icon: "exclamationmark.triangle",
                    color: .dangerRed,
                    trend: .neutral,
                    alert: criticalCount > 0
                )
                
                UltraStatCard(
                    title: "CVE Database",
                    value: formatNumber(appState.cveDatabase.count),
                    icon: "server.rack",
                    color: .secondaryAccent,
                    trend: .up(523)
                )
            }
        }
    }
    
    private func formatNumber(_ num: Int) -> String {
        if num >= 1000 {
            return String(format: "%.1fK", Double(num) / 1000.0)
        }
        return "\(num)"
    }
}

struct UltraStatCard: View {
    enum Trend {
        case up(Int)
        case down(Int)
        case neutral
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "minus"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return .successGreen
            case .down: return .dangerRed
            case .neutral: return .gray
            }
        }
        
        var value: String {
            switch self {
            case .up(let val): return "+\(val)%"
            case .down(let val): return "-\(val)%"
            case .neutral: return "0%"
            }
        }
    }
    
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: Trend
    var alert: Bool = false
    
    @State private var isHovered = false
    @State private var showValue = false
    
    var body: some View {
        ModernCard {
            VStack(alignment: .leading, spacing: Spacing.small) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Spacer()
                    
                    if alert {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.dangerRed)
                            .symbolEffect(.pulse.byLayer, options: .repeating)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())
                        .opacity(showValue ? 1 : 0)
                        .animation(.easeIn(duration: 0.5), value: showValue)
                    
                    Text(title)
                        .font(Typography.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: trend.icon)
                        .font(.caption2)
                    Text(trend.value)
                        .font(.caption2.weight(.medium))
                }
                .foregroundColor(trend.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(trend.color.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: isHovered ? [color.opacity(0.3), color.opacity(0.1)] : [Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(Animations.spring, value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.5).delay(0.1)) {
                showValue = true
            }
        }
    }
}

// MARK: - Activity Charts
struct ActivityChartsSection: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            SectionHeader("Security Activity", subtitle: "Last 24 hours", icon: "chart.line.uptrend.xyaxis")
            
            HStack(spacing: Spacing.medium) {
                // Vulnerability Trend Chart
                ModernCard {
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Vulnerability Trend")
                            .font(Typography.headline)
                        
                        VulnerabilityTrendChart()
                            .frame(height: 200)
                    }
                }
                
                // Severity Distribution
                ModernCard {
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Severity Distribution")
                            .font(Typography.headline)
                        
                        SeverityDistributionChart()
                            .frame(height: 200)
                    }
                }
            }
        }
    }
}

struct VulnerabilityTrendChart: View {
    @State private var animateChart = false
    
    let data: [(hour: Int, count: Int)] = [
        (0, 12), (1, 15), (2, 8), (3, 20), (4, 25), (5, 18),
        (6, 30), (7, 28), (8, 35), (9, 32), (10, 38), (11, 42),
        (12, 45), (13, 40), (14, 48), (15, 52), (16, 55), (17, 50),
        (18, 58), (19, 62), (20, 65), (21, 60), (22, 68), (23, 70)
    ]
    
    var body: some View {
        Chart(data, id: \.hour) { item in
            LineMark(
                x: .value("Hour", item.hour),
                y: .value("Count", animateChart ? item.count : 0)
            )
            .foregroundStyle(Color.primaryGradient)
            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            
            AreaMark(
                x: .value("Hour", item.hour),
                y: .value("Count", animateChart ? item.count : 0)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.primaryAccent.opacity(0.3), Color.primaryAccent.opacity(0.0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .chartYScale(domain: 0...80)
        .chartXAxis {
            AxisMarks(values: [0, 6, 12, 18, 23]) { value in
                AxisValueLabel {
                    if let hour = value.as(Int.self) {
                        Text("\(hour):00")
                            .font(.caption2)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1)) {
                animateChart = true
            }
        }
    }
}

struct SeverityDistributionChart: View {
    @Environment(AppState.self) private var appState
    @State private var animateChart = false
    
    var severityData: [(severity: String, count: Int, color: Color)] {
        let vulns = appState.getAllVulnerabilities()
        return [
            ("Critical", vulns.filter { $0.severity == .critical }.count, .dangerRed),
            ("High", vulns.filter { $0.severity == .high }.count, .warningOrange),
            ("Medium", vulns.filter { $0.severity == .medium }.count, .yellow),
            ("Low", vulns.filter { $0.severity == .low }.count, .tertiaryAccent),
            ("Info", vulns.filter { $0.severity == .info }.count, .infoBlue)
        ]
    }
    
    var body: some View {
        Chart(severityData, id: \.severity) { item in
            BarMark(
                x: .value("Severity", item.severity),
                y: .value("Count", animateChart ? item.count : 0)
            )
            .foregroundStyle(item.color)
            .cornerRadius(4)
        }
        .chartYScale(domain: 0...20)
        .onAppear {
            withAnimation(.easeInOut(duration: 1)) {
                animateChart = true
            }
        }
    }
}

// MARK: - Recent Findings
struct RecentFindingsSection: View {
    @Environment(AppState.self) private var appState
    
    var recentVulnerabilities: [Vulnerability] {
        Array(appState.getAllVulnerabilities().sorted(by: { $0.discoveredDate > $1.discoveredDate }).prefix(5))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack {
                SectionHeader("Recent Findings", subtitle: "Latest security discoveries", icon: "exclamationmark.bubble")
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        appState.currentTab = .activeAttacks
                    }
                }) {
                    Text("View All")
                        .font(.subheadline)
                        .foregroundColor(.primaryAccent)
                }
                .buttonStyle(.plain)
            }
            
            if recentVulnerabilities.isEmpty {
                EmptyFindingsCard()
            } else {
                VStack(spacing: Spacing.small) {
                    ForEach(recentVulnerabilities) { vuln in
                        FindingRow(vulnerability: vuln)
                    }
                }
            }
        }
    }
}

struct FindingRow: View {
    let vulnerability: Vulnerability
    @State private var isHovered = false
    
    var body: some View {
        ModernCard {
            HStack(spacing: Spacing.medium) {
                // Severity Indicator
                Circle()
                    .fill(severityColor(vulnerability.severity))
                    .frame(width: 8, height: 8)
                    .glow(color: severityColor(vulnerability.severity), radius: 4)
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(vulnerability.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        if let cve = vulnerability.cveId {
                            Text(cve)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.tertiaryText)
                        
                        Text(vulnerability.discoveredDate, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Actions
                HStack(spacing: 8) {
                    StatusBadge(
                        status: vulnerability.isPatched ? .success : .warning,
                        text: vulnerability.isPatched ? "Patched" : "Open"
                    )
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isHovered ? 0 : -90))
                        .animation(Animations.quick, value: isHovered)
                }
            }
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private func severityColor(_ severity: Vulnerability.Severity) -> Color {
        switch severity {
        case .critical: return .dangerRed
        case .high: return .warningOrange
        case .medium: return .yellow
        case .low: return .tertiaryAccent
        case .info: return .infoBlue
        }
    }
}

struct EmptyFindingsCard: View {
    var body: some View {
        ModernCard {
            VStack(spacing: Spacing.medium) {
                Image(systemName: "checkmark.shield")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.primaryGradient)
                
                Text("No recent vulnerabilities")
                    .font(Typography.headline)
                    .foregroundColor(.primary)
                
                Text("Your systems are secure")
                    .font(Typography.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.large)
        }
    }
}

// MARK: - System Status
struct SystemStatusSection: View {
    @Environment(AppState.self) private var appState
    
    let services = [
        ("Network Scanner", "antenna.radiowaves.left.and.right", true),
        ("Web Testing Engine", "globe", true),
        ("CVE Database", "server.rack", true),
        ("IVRE Integration", "cylinder.split.1x2", false),
        ("Bluetooth Scanner", "wave.3.right", true)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            SectionHeader("System Status", subtitle: "Service health monitoring", icon: "heart.text.square")
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.medium) {
                ForEach(services, id: \.0) { service in
                    ServiceStatusCard(
                        name: service.0,
                        icon: service.1,
                        isOnline: service.2
                    )
                }
            }
        }
    }
}

struct ServiceStatusCard: View {
    let name: String
    let icon: String
    let isOnline: Bool
    
    @State private var pulse = false
    
    var body: some View {
        ModernCard {
            HStack(spacing: Spacing.small) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isOnline ? .successGreen : .gray)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(isOnline ? "Online" : "Offline")
                        .font(.caption2)
                        .foregroundColor(isOnline ? .successGreen : .gray)
                }
                
                Spacer()
                
                Circle()
                    .fill(isOnline ? Color.successGreen : Color.gray)
                    .frame(width: 8, height: 8)
                    .scaleEffect(pulse && isOnline ? 1.2 : 1.0)
                    .animation(
                        isOnline ? Animation.easeInOut(duration: 1).repeatForever(autoreverses: true) : .default,
                        value: pulse
                    )
            }
        }
        .onAppear {
            pulse = true
        }
    }
}

// MARK: - Helper Extensions
extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            if pressing {
                onPress()
            } else {
                onRelease()
            }
        }, perform: {})
    }
}

struct UltraModernDashboard_Previews: PreviewProvider {
    static var previews: some View {
        UltraModernDashboard()
            .environment(AppState())
            .frame(width: 1200, height: 800)
    }
}