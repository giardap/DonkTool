//
//  PerimeterScannerView.swift
//  DonkTool
//
//  Advanced Perimeter Security Monitoring Interface
//

import SwiftUI
import Charts

struct PerimeterScannerView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab = 0
    @State private var showingConfiguration = false
    @State private var showingAlertRules = false
    @State private var showingExport = false
    @State private var selectedTimeRange = TimeRange.last24Hours
    
    enum TimeRange: String, CaseIterable {
        case realTime = "Real-time"
        case last24Hours = "Last 24 Hours"
        case last7Days = "Last 7 Days"
        case last30Days = "Last 30 Days"
        
        var icon: String {
            switch self {
            case .realTime: return "bolt.circle"
            case .last24Hours: return "clock"
            case .last7Days: return "calendar"
            case .last30Days: return "calendar.badge.clock"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Enhanced header with status
            PerimeterHeaderView()
            
            // Main content area
            HSplitView {
                // Left panel - Configuration and monitoring
                VStack(spacing: 20) {
                    MonitoringTargetsPanel()
                    AlertStatusPanel()
                    QuickActionsPanel()
                }
                .frame(minWidth: 300, maxWidth: 400)
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                
                // Right panel - Results and analysis
                VStack(spacing: 0) {
                    // Tab selector
                    PerimeterTabSelector(selectedTab: $selectedTab)
                    
                    // Tab content
                    TabView(selection: $selectedTab) {
                        PerimeterOverviewTab()
                            .tag(0)
                        
                        UnauthorizedServicesTab()
                            .tag(1)
                        
                        NetworkMapTab()
                            .tag(2)
                        
                        AlertHistoryTab()
                            .tag(3)
                        
                        ComplianceReportTab()
                            .tag(4)
                    }
                    .tabViewStyle(.automatic)
                }
            }
        }
        .navigationTitle("Perimeter Scanner")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if appState.perimeterScannerManager.isScanning {
                    ProgressView(value: appState.perimeterScannerManager.scanProgress)
                        .frame(width: 100)
                    
                    Text(appState.perimeterScannerManager.currentPhase)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Stop") {
                        // Stop scanning
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button("Start Scan") {
                        Task {
                            await appState.perimeterScannerManager.startPerimeterScan()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Button(action: { showingConfiguration = true }) {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.bordered)
                
                Button(action: { showingAlertRules = true }) {
                    Image(systemName: "bell.badge")
                }
                .buttonStyle(.bordered)
                
                Button(action: { showingExport = true }) {
                    Image(systemName: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
            }
        }
        .sheet(isPresented: $showingConfiguration) {
            PerimeterConfigurationView()
        }
        .sheet(isPresented: $showingAlertRules) {
            AlertRulesConfigurationView()
        }
        .sheet(isPresented: $showingExport) {
            ExportResultsView()
        }
    }
}

// MARK: - Header View

struct PerimeterHeaderView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Network Perimeter Security")
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack(spacing: 20) {
                    PerimeterStatusIndicator(
                        title: "Monitoring",
                        isActive: appState.perimeterScannerManager.monitoringTargets.count > 0,
                        color: .green
                    )
                    
                    if let lastScan = appState.perimeterScannerManager.scanHistory.last {
                        Text("Last scan: \(lastScan.timestamp)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if appState.perimeterScannerManager.unauthorizedServices.count > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("\(appState.perimeterScannerManager.unauthorizedServices.count) unauthorized services")
                                .fontWeight(.medium)
                        }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
            }
            
            Spacer()
            
            // Real-time activity indicator
            if appState.perimeterScannerManager.isScanning {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Scanning...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct PerimeterStatusIndicator: View {
    let title: String
    let isActive: Bool
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isActive ? color : Color.gray)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(isActive ? color.opacity(0.3) : Color.clear, lineWidth: 8)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: false), value: isActive)
                )
            
            Text(title)
                .font(.caption)
                .foregroundColor(isActive ? .primary : .secondary)
        }
    }
}

// MARK: - Left Panel Components

struct MonitoringTargetsPanel: View {
    @Environment(AppState.self) private var appState
    @State private var showingAddTarget = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Monitoring Targets", systemImage: "network")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { showingAddTarget = true }) {
                    Image(systemName: "plus.circle")
                }
                .buttonStyle(.plain)
            }
            
            VStack(spacing: 8) {
                ForEach(appState.perimeterScannerManager.monitoringTargets) { target in
                    MonitoringTargetRow(target: target)
                }
            }
            
            if appState.perimeterScannerManager.monitoringTargets.isEmpty {
                Text("No monitoring targets configured")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .sheet(isPresented: $showingAddTarget) {
            AddMonitoringTargetView()
        }
    }
}

struct MonitoringTargetRow: View {
    let target: NetworkRange
    @State private var isEnabled = true
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(target.cidr)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(target.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .toggleStyle(.switch)
                .scaleEffect(0.7)
        }
        .padding(8)
        .background(Color.white.opacity(0.5))
        .cornerRadius(6)
    }
}

struct AlertStatusPanel: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Alert Status", systemImage: "bell.badge")
                .font(.headline)
            
            HStack(spacing: 16) {
                AlertMetric(
                    value: "\(appState.perimeterScannerManager.alertingRules.filter(\.enabled).count)",
                    label: "Active Rules",
                    color: .blue
                )
                
                AlertMetric(
                    value: "\(appState.perimeterScannerManager.unauthorizedServices.filter { $0.risk == .critical }.count)",
                    label: "Critical",
                    color: .red
                )
                
                AlertMetric(
                    value: "\(appState.perimeterScannerManager.unauthorizedServices.filter { $0.risk == .high }.count)",
                    label: "High",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct AlertMetric: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct QuickActionsPanel: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Quick Actions", systemImage: "bolt.circle")
                .font(.headline)
            
            VStack(spacing: 8) {
                QuickActionButton(
                    title: "Emergency Scan",
                    icon: "exclamationmark.shield",
                    color: .red
                ) {
                    Task {
                        await appState.perimeterScannerManager.startPerimeterScan()
                    }
                }
                
                QuickActionButton(
                    title: "Enable Monitoring",
                    icon: "eye.circle",
                    color: .blue
                ) {
                    appState.perimeterScannerManager.startContinuousMonitoring()
                }
                
                QuickActionButton(
                    title: "Export Report",
                    icon: "doc.text",
                    color: .green
                ) {
                    exportReport()
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func exportReport() {
        // Export functionality
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(title)
                    .fontWeight(.medium)
                
                Spacer()
            }
            .padding(8)
            .background(color.opacity(0.1))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tab Selector

struct PerimeterTabSelector: View {
    @Binding var selectedTab: Int
    
    let tabs = [
        ("Overview", "chart.pie"),
        ("Unauthorized Services", "exclamationmark.shield"),
        ("Network Map", "map"),
        ("Alert History", "clock.arrow.circlepath"),
        ("Compliance", "checkmark.shield")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                PerimeterTabButton(
                    title: tabs[index].0,
                    icon: tabs[index].1,
                    isSelected: selectedTab == index
                ) {
                    withAnimation {
                        selectedTab = index
                    }
                }
            }
        }
        .padding(4)
        .background(Color.gray.opacity(0.1))
    }
}

struct PerimeterTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(isSelected ? .accentColor : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tab Views

struct PerimeterOverviewTab: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary cards
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    OverviewCard(
                        title: "Total Hosts",
                        value: "\(appState.perimeterScannerManager.currentResults?.discovery.count ?? 0)",
                        icon: "server.rack",
                        color: .blue
                    )
                    
                    OverviewCard(
                        title: "Open Ports",
                        value: "\(appState.perimeterScannerManager.currentResults?.analysis.openPorts ?? 0)",
                        icon: "network",
                        color: .green
                    )
                    
                    OverviewCard(
                        title: "Services",
                        value: "\(appState.perimeterScannerManager.currentResults?.analysis.exposedServices ?? 0)",
                        icon: "externaldrive.connected.to.line.below",
                        color: .orange
                    )
                    
                    OverviewCard(
                        title: "Vulnerabilities",
                        value: "\(appState.perimeterScannerManager.currentResults?.vulnerabilities.count ?? 0)",
                        icon: "exclamationmark.triangle",
                        color: .red
                    )
                }
                
                // Risk distribution chart
                RiskDistributionChart()
                
                // Recent discoveries
                RecentDiscoveriesSection()
                
                // Recommendations
                RecommendationsSection()
            }
            .padding()
        }
    }
}

struct OverviewCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct RiskDistributionChart: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Risk Distribution")
                .font(.headline)
            
            if let results = appState.perimeterScannerManager.currentResults {
                Chart {
                    BarMark(
                        x: .value("Risk", "Critical"),
                        y: .value("Count", results.analysis.highRiskFindings)
                    )
                    .foregroundStyle(.red)
                    
                    BarMark(
                        x: .value("Risk", "High"),
                        y: .value("Count", results.analysis.mediumRiskFindings)
                    )
                    .foregroundStyle(.orange)
                    
                    BarMark(
                        x: .value("Risk", "Medium"),
                        y: .value("Count", 5) // Placeholder
                    )
                    .foregroundStyle(.yellow)
                    
                    BarMark(
                        x: .value("Risk", "Low"),
                        y: .value("Count", 10) // Placeholder
                    )
                    .foregroundStyle(.green)
                }
                .frame(height: 200)
            } else {
                Text("No scan data available")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct RecentDiscoveriesSection: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Discoveries")
                .font(.headline)
            
            if let hosts = appState.perimeterScannerManager.currentResults?.discovery.prefix(5) {
                ForEach(hosts) { host in
                    DiscoveredHostRow(host: host)
                }
            } else {
                Text("No recent discoveries")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct DiscoveredHostRow: View {
    let host: DiscoveredHost
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(host.ip)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if let hostname = host.hostname {
                    Text(hostname)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let vendor = host.vendor {
                Text(vendor)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(host.status)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(host.status == "up" ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                .cornerRadius(4)
        }
        .padding(8)
        .background(Color.white.opacity(0.5))
        .cornerRadius(6)
    }
}

struct RecommendationsSection: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Security Recommendations")
                .font(.headline)
            
            if let recommendations = appState.perimeterScannerManager.currentResults?.analysis.recommendations {
                ForEach(recommendations, id: \.self) { recommendation in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        
                        Text(recommendation)
                            .font(.caption)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(8)
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Unauthorized Services Tab

struct UnauthorizedServicesTab: View {
    @Environment(AppState.self) private var appState
    @State private var selectedRiskFilter: UnauthorizedService.RiskLevel?
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter bar
            HStack {
                TextField("Search services...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
                
                Picker("Risk Level", selection: $selectedRiskFilter) {
                    Text("All").tag(UnauthorizedService.RiskLevel?.none)
                    ForEach(UnauthorizedService.RiskLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(UnauthorizedService.RiskLevel?.some(level))
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 300)
                
                Spacer()
                
                Text("\(filteredServices.count) services found")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            // Services list
            List(filteredServices) { service in
                UnauthorizedServiceRow(service: service)
            }
            .listStyle(.plain)
        }
    }
    
    private var filteredServices: [UnauthorizedService] {
        appState.perimeterScannerManager.unauthorizedServices
            .filter { service in
                (selectedRiskFilter == nil || service.risk == selectedRiskFilter) &&
                (searchText.isEmpty || service.service.localizedCaseInsensitiveContains(searchText))
            }
            .sorted { $0.risk.rawValue < $1.risk.rawValue }
    }
}

struct UnauthorizedServiceRow: View {
    let service: UnauthorizedService
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Risk indicator
                Circle()
                    .fill(service.risk.color)
                    .frame(width: 10, height: 10)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(service.ip):\(service.port)")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text(service.service)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(service.risk.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(service.risk.color.opacity(0.2))
                    .foregroundColor(service.risk.color)
                    .cornerRadius(6)
                
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                }
                .buttonStyle(.plain)
            }
            
            if isExpanded {
                ServiceDetailsView(service: service)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct ServiceDetailsView: View {
    let service: UnauthorizedService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("First Detected", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(service.discovered.formatted())
                    .font(.caption)
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button("Investigate") {
                    // Investigate service
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("Whitelist") {
                    // Add to whitelist
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("Block") {
                    // Block service
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(.red)
            }
            .padding(.top, 8)
        }
        .padding(.leading, 20)
    }
}

// MARK: - Network Map Tab

struct NetworkMapTab: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        VStack {
            Text("Network Topology Map")
                .font(.headline)
                .padding()
            
            // Placeholder for network visualization
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
                
                VStack(spacing: 20) {
                    Image(systemName: "network")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("Network visualization")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }
}

// MARK: - Alert History Tab

struct AlertHistoryTab: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        VStack {
            Text("Alert History")
                .font(.headline)
                .padding()
            
            List {
                Text("No alerts recorded")
                    .foregroundColor(.secondary)
            }
            .listStyle(.plain)
        }
    }
}

// MARK: - Compliance Report Tab

struct ComplianceReportTab: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Compliance Status")
                    .font(.headline)
                
                // Compliance metrics
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ComplianceCard(
                        framework: "PCI DSS",
                        score: 0.85,
                        status: "Compliant"
                    )
                    
                    ComplianceCard(
                        framework: "HIPAA",
                        score: 0.78,
                        status: "Needs Review"
                    )
                    
                    ComplianceCard(
                        framework: "SOC 2",
                        score: 0.92,
                        status: "Compliant"
                    )
                }
            }
            .padding()
        }
    }
}

struct ComplianceCard: View {
    let framework: String
    let score: Double
    let status: String
    
    var body: some View {
        VStack(spacing: 12) {
            Text(framework)
                .font(.headline)
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                
                Circle()
                    .trim(from: 0, to: score)
                    .stroke(scoreColor, lineWidth: 8)
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 60, height: 60)
            
            Text("\(Int(score * 100))%")
                .font(.title3)
                .fontWeight(.bold)
            
            Text(status)
                .font(.caption)
                .foregroundColor(scoreColor)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var scoreColor: Color {
        if score >= 0.8 {
            return .green
        } else if score >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Configuration Views

struct PerimeterConfigurationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var pythonPath = "/usr/bin/python3"
    @State private var scanInterval = 60
    @State private var enableAutoScan = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Scanner Configuration") {
                    TextField("Python Path", text: $pythonPath)
                    
                    Stepper("Scan Interval: \(scanInterval) minutes", value: $scanInterval, in: 15...1440, step: 15)
                    
                    Toggle("Enable Automatic Scanning", isOn: $enableAutoScan)
                }
                
                Section("Network Ranges") {
                    Text("Configure monitoring targets in the main interface")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Perimeter Scanner Configuration")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        // Save configuration
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 500, height: 400)
    }
}

struct AlertRulesConfigurationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    
    var body: some View {
        NavigationStack {
            List(appState.perimeterScannerManager.alertingRules) { rule in
                AlertRuleRow(rule: rule)
            }
            .navigationTitle("Alert Rules")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 600, height: 400)
    }
}

struct AlertRuleRow: View {
    let rule: AlertRule
    @State private var isEnabled: Bool
    
    init(rule: AlertRule) {
        self.rule = rule
        self._isEnabled = State(initialValue: rule.enabled)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(rule.name)
                    .font(.headline)
                
                Text(rule.condition.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .toggleStyle(.switch)
        }
        .padding(.vertical, 4)
    }
}

struct AddMonitoringTargetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var cidr = ""
    @State private var description = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Network Range") {
                    TextField("CIDR (e.g., 192.168.1.0/24)", text: $cidr)
                    TextField("Description", text: $description)
                }
            }
            .navigationTitle("Add Monitoring Target")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Add") {
                        let target = NetworkRange(cidr: cidr, description: description)
                        appState.perimeterScannerManager.addMonitoringTarget(target)
                        dismiss()
                    }
                    .disabled(cidr.isEmpty || description.isEmpty)
                }
            }
        }
        .frame(width: 400, height: 200)
    }
}

struct ExportResultsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var selectedFormat = PerimeterScannerManager.ExportFormat.json
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Export Scan Results")
                    .font(.headline)
                
                Picker("Format", selection: $selectedFormat) {
                    Text("JSON").tag(PerimeterScannerManager.ExportFormat.json)
                    Text("CSV").tag(PerimeterScannerManager.ExportFormat.csv)
                    Text("PDF").tag(PerimeterScannerManager.ExportFormat.pdf)
                }
                .pickerStyle(.segmented)
                
                Button("Export") {
                    if let data = appState.perimeterScannerManager.exportResults(format: selectedFormat) {
                        // Save data
                    }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 300, height: 200)
    }
}

// MARK: - Extensions

extension AlertRule.AlertCondition {
    var description: String {
        switch self {
        case .newHost:
            return "New host discovered on network"
        case .openPort(let port):
            return "Port \(port) is open"
        case .serviceDetected(let service):
            return "Service '\(service)' detected"
        case .vulnerabilityFound:
            return "Vulnerability discovered"
        case .serviceRisk(let level):
            return "\(level.rawValue.capitalized) risk service detected"
        }
    }
}

#Preview {
    PerimeterScannerView()
        .environment(AppState())
        .frame(width: 1200, height: 800)
}