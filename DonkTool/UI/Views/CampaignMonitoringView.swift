//
//  CampaignMonitoringView.swift
//  DonkTool
//
//  Real-time campaign monitoring dashboard
//

import SwiftUI
import Charts

struct CampaignMonitoringView: View {
    @State private var socialManager = SocialEngineeringManager()
    @State private var selectedCampaign: PhishingCampaign?
    @State private var showingNotificationHistory = false
    @State private var selectedTimeRange: TimeRange = .last24Hours
    @State private var autoRefreshEnabled = true
    @State private var refreshTimer: Timer?
    
    var activeCampaigns: [PhishingCampaign] {
        socialManager.campaigns.filter { $0.status == .active }
    }
    
    var body: some View {
        NavigationSplitView {
            // Campaign List Sidebar
            CampaignListSidebar(
                campaigns: activeCampaigns,
                selectedCampaign: $selectedCampaign,
                socialManager: socialManager
            )
        } detail: {
            if let campaign = selectedCampaign {
                CampaignMonitoringDetail(
                    campaign: campaign,
                    socialManager: socialManager,
                    selectedTimeRange: $selectedTimeRange,
                    autoRefreshEnabled: $autoRefreshEnabled
                )
            } else {
                MonitoringPlaceholderView()
            }
        }
        .onAppear {
            setupAutoRefresh()
        }
        .onDisappear {
            stopAutoRefresh()
        }
        .sheet(isPresented: $showingNotificationHistory) {
            NotificationHistoryView(socialManager: socialManager)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { showingNotificationHistory = true }) {
                    Label("Notifications", systemImage: "bell")
                }
                
                Button(action: toggleAutoRefresh) {
                    Label(
                        autoRefreshEnabled ? "Disable Auto-refresh" : "Enable Auto-refresh",
                        systemImage: autoRefreshEnabled ? "pause.circle" : "play.circle"
                    )
                }
            }
        }
    }
    
    private func setupAutoRefresh() {
        guard autoRefreshEnabled else { return }
        
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            // Refresh data - this will trigger UI updates automatically due to @Observable
        }
    }
    
    private func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func toggleAutoRefresh() {
        autoRefreshEnabled.toggle()
        if autoRefreshEnabled {
            setupAutoRefresh()
        } else {
            stopAutoRefresh()
        }
    }
}

// MARK: - Campaign List Sidebar

struct CampaignListSidebar: View {
    let campaigns: [PhishingCampaign]
    @Binding var selectedCampaign: PhishingCampaign?
    let socialManager: SocialEngineeringManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Active Campaigns")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            if campaigns.isEmpty {
                EmptyCampaignsList()
            } else {
                List(campaigns, selection: $selectedCampaign) { campaign in
                    CampaignListRow(campaign: campaign, socialManager: socialManager)
                        .tag(campaign)
                }
                .listStyle(.sidebar)
            }
            
            Spacer()
        }
        .frame(minWidth: 250)
        .onAppear {
            if selectedCampaign == nil && !campaigns.isEmpty {
                selectedCampaign = campaigns.first
            }
        }
    }
}

struct CampaignListRow: View {
    let campaign: PhishingCampaign
    let socialManager: SocialEngineeringManager
    
    var isMonitoring: Bool {
        socialManager.campaignMonitor?.monitoringCampaigns.contains(campaign.id) ?? false
    }
    
    var realTimeMetrics: RealTimeMetrics? {
        socialManager.getRealTimeMetrics(for: campaign.id)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(campaign.name)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(campaign.targetOrganization)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let metrics = realTimeMetrics {
                    HStack(spacing: 12) {
                        MetricBadge(
                            value: "\(metrics.emailsOpened)/\(metrics.emailsSent)",
                            label: "Opened",
                            color: .blue
                        )
                        
                        MetricBadge(
                            value: "\(metrics.linksClicked)",
                            label: "Clicked",
                            color: .orange
                        )
                        
                        if metrics.credentialsSubmitted > 0 {
                            MetricBadge(
                                value: "\(metrics.credentialsSubmitted)",
                                label: "Submitted",
                                color: .red
                            )
                        }
                    }
                    .font(.caption2)
                }
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Circle()
                    .fill(isMonitoring ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                
                Text(isMonitoring ? "Live" : "Offline")
                    .font(.caption2)
                    .foregroundColor(isMonitoring ? .green : .gray)
            }
        }
        .padding(.vertical, 4)
    }
}

struct MetricBadge: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct EmptyCampaignsList: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Active Campaigns")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Launch a campaign to start monitoring")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Campaign Monitoring Detail

struct CampaignMonitoringDetail: View {
    let campaign: PhishingCampaign
    let socialManager: SocialEngineeringManager
    @Binding var selectedTimeRange: TimeRange
    @Binding var autoRefreshEnabled: Bool
    
    var realTimeMetrics: RealTimeMetrics? {
        socialManager.getRealTimeMetrics(for: campaign.id)
    }
    
    var isMonitoring: Bool {
        socialManager.campaignMonitor?.monitoringCampaigns.contains(campaign.id) ?? false
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                CampaignHeader(
                    campaign: campaign,
                    isMonitoring: isMonitoring,
                    socialManager: socialManager
                )
                
                if let metrics = realTimeMetrics {
                    // Real-time Metrics
                    RealTimeMetricsGrid(metrics: metrics)
                    
                    // Charts Section
                    CampaignChartsSection(metrics: metrics)
                    
                    // Department Breakdown
                    if !metrics.departmentBreakdown.isEmpty {
                        DepartmentBreakdownSection(departments: metrics.departmentBreakdown)
                    }
                    
                    // Risk Assessment
                    RiskAssessmentSection(metrics: metrics)
                    
                } else {
                    NoDataView(campaignName: campaign.name)
                }
            }
            .padding()
        }
        .navigationTitle("Campaign Monitor")
        .toolbar {
            ToolbarItemGroup(placement: .secondaryAction) {
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }
}

// MARK: - Campaign Header

struct CampaignHeader: View {
    let campaign: PhishingCampaign
    let isMonitoring: Bool
    let socialManager: SocialEngineeringManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(campaign.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(campaign.targetOrganization)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let launchedAt = campaign.launchedAt {
                        Text("Launched: \(launchedAt.formatted(.dateTime))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    HStack {
                        Circle()
                            .fill(isMonitoring ? Color.green : Color.gray)
                            .frame(width: 12, height: 12)
                        
                        Text(isMonitoring ? "Monitoring Active" : "Monitoring Stopped")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(isMonitoring ? .green : .gray)
                    }
                    
                    Button(action: toggleMonitoring) {
                        Text(isMonitoring ? "Stop Monitoring" : "Start Monitoring")
                            .font(.subheadline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(isMonitoring ? Color.red : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            
            // Campaign Status
            HStack {
                Label(campaign.status.rawValue, systemImage: campaign.status.icon)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(campaign.status.color.opacity(0.2))
                    .foregroundColor(campaign.status.color)
                    .cornerRadius(8)
                
                Spacer()
                
                Text("Last updated: \(Date().formatted(.dateTime.hour().minute()))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.systemGray))
        .cornerRadius(12)
    }
    
    private func toggleMonitoring() {
        if isMonitoring {
            socialManager.stopCampaignMonitoring(campaign.id)
        } else {
            socialManager.startCampaignMonitoring(campaign.id)
        }
    }
}

// MARK: - Real-time Metrics Grid

struct RealTimeMetricsGrid: View {
    let metrics: RealTimeMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Real-time Metrics")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                CampaignMetricCard(
                    title: "Emails Sent",
                    value: "\(metrics.emailsSent)",
                    subtitle: "of \(metrics.totalTargets) targets",
                    icon: "envelope",
                    color: .blue
                )
                
                CampaignMetricCard(
                    title: "Opened",
                    value: "\(metrics.emailsOpened)",
                    subtitle: "\(String(format: "%.1f%%", metrics.openRate)) open rate",
                    icon: "envelope.open",
                    color: .cyan
                )
                
                CampaignMetricCard(
                    title: "Clicked",
                    value: "\(metrics.linksClicked)",
                    subtitle: "\(String(format: "%.1f%%", metrics.clickRate)) click rate",
                    icon: "link",
                    color: .orange
                )
                
                CampaignMetricCard(
                    title: "Submitted",
                    value: "\(metrics.credentialsSubmitted)",
                    subtitle: "\(String(format: "%.1f%%", metrics.submissionRate)) submission rate",
                    icon: "exclamationmark.triangle.fill",
                    color: .red
                )
                
                CampaignMetricCard(
                    title: "Reported",
                    value: "\(metrics.reported)",
                    subtitle: "\(String(format: "%.1f%%", metrics.reportRate)) report rate",
                    icon: "checkmark.shield",
                    color: .green
                )
                
                CampaignMetricCard(
                    title: "Risk Score",
                    value: String(format: "%.0f", metrics.overallRiskScore),
                    subtitle: "out of 100",
                    icon: "chart.line.uptrend.xyaxis",
                    color: riskScoreColor(metrics.overallRiskScore)
                )
                
                if let avgTime = metrics.averageTimeToClick {
                    CampaignMetricCard(
                        title: "Avg Time to Click",
                        value: formatDuration(avgTime),
                        subtitle: "response time",
                        icon: "clock",
                        color: .purple
                    )
                }
            }
        }
    }
    
    private func riskScoreColor(_ score: Double) -> Color {
        switch score {
        case 0..<20: return .green
        case 20..<40: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }
    
    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "< 1m"
        }
    }
}

struct CampaignMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.systemGray))
        .cornerRadius(12)
    }
}

// MARK: - Campaign Charts Section

struct CampaignChartsSection: View {
    let metrics: RealTimeMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity Overview")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 16) {
                // Conversion Funnel Chart
                ConversionFunnelChart(metrics: metrics)
                    .frame(height: 200)
                
                // Response Rate Chart
                ResponseRateDonutChart(metrics: metrics)
                    .frame(height: 200)
            }
        }
    }
}

struct ConversionFunnelChart: View {
    let metrics: RealTimeMetrics
    
    var funnelData: [(String, Int, Color)] {
        [
            ("Sent", metrics.emailsSent, .blue),
            ("Opened", metrics.emailsOpened, .cyan),
            ("Clicked", metrics.linksClicked, .orange),
            ("Submitted", metrics.credentialsSubmitted, .red)
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Conversion Funnel")
                .font(.headline)
            
            Chart(Array(funnelData.enumerated()), id: \.offset) { index, data in
                BarMark(
                    x: .value("Stage", data.0),
                    y: .value("Count", data.1)
                )
                .foregroundStyle(data.2)
                .cornerRadius(4)
            }
            .chartYScale(domain: 0...max(1, metrics.emailsSent))
        }
        .padding()
        .background(Color(NSColor.systemGray))
        .cornerRadius(12)
    }
}

struct ResponseRateDonutChart: View {
    let metrics: RealTimeMetrics
    
    var chartData: [(String, Double, Color)] {
        [
            ("Clicked", metrics.clickRate, .orange),
            ("Reported", metrics.reportRate, .green),
            ("No Action", 100 - metrics.clickRate - metrics.reportRate, .gray)
        ].filter { $0.1 > 0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Response Breakdown")
                .font(.headline)
            
            Chart(chartData, id: \.0) { data in
                SectorMark(
                    angle: .value("Percentage", data.1)
                )
                .foregroundStyle(data.2)
                .opacity(0.8)
            }
            .chartBackground { chartProxy in
                Text("\(String(format: "%.1f%%", metrics.clickRate + metrics.reportRate))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(chartData, id: \.0) { data in
                    HStack {
                        Circle()
                            .fill(data.2)
                            .frame(width: 8, height: 8)
                        
                        Text(data.0)
                            .font(.caption)
                        
                        Spacer()
                        
                        Text("\(String(format: "%.1f%%", data.1))")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.systemGray))
        .cornerRadius(12)
    }
}

// MARK: - Department Breakdown Section

struct DepartmentBreakdownSection: View {
    let departments: [String: DepartmentMetrics]
    
    var sortedDepartments: [(String, DepartmentMetrics)] {
        departments.sorted { $0.value.successRate > $1.value.successRate }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Department Analysis")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                ForEach(sortedDepartments, id: \.0) { dept, metrics in
                    DepartmentRow(department: dept, metrics: metrics)
                }
            }
        }
        .padding()
        .background(Color(NSColor.systemGray))
        .cornerRadius(12)
    }
}

struct DepartmentRow: View {
    let department: String
    let metrics: DepartmentMetrics
    
    var riskColor: Color {
        switch metrics.successRate {
        case 0..<10: return .green
        case 10..<25: return .yellow
        case 25..<50: return .orange
        default: return .red
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(department)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(metrics.totalTargets) employees")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(metrics.clicked)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Clicked")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(metrics.submitted)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(riskColor)
                    Text("Submitted")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.1f%%", metrics.successRate))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(riskColor)
                    Text("Risk Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
    }
}

// MARK: - Risk Assessment Section

struct RiskAssessmentSection: View {
    let metrics: RealTimeMetrics
    
    var riskLevel: RiskLevel {
        switch metrics.overallRiskScore {
        case 0..<20: return .low
        case 20..<40: return .medium
        case 40..<60: return .high
        default: return .critical
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Risk Assessment")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Overall Risk Level:")
                            .font(.subheadline)
                        
                        Text(riskLevel.rawValue)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(riskLevel.color)
                        
                        Spacer()
                        
                        Text("\(String(format: "%.0f", metrics.overallRiskScore))/100")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(riskLevel.color)
                    }
                    
                    Text(riskLevel.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    // Risk Score Progress Bar
                    ProgressView(value: metrics.overallRiskScore, total: 100)
                        .progressViewStyle(LinearProgressViewStyle(tint: riskLevel.color))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                }
            }
        }
        .padding()
        .background(Color(NSColor.systemGray))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Views

struct MonitoringPlaceholderView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis.circle")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("Campaign Monitoring")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Select an active campaign from the sidebar to start monitoring")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct NoDataView: View {
    let campaignName: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Monitoring Data")
                .font(.headline)
            
            Text("Start monitoring \"\(campaignName)\" to see real-time analytics")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Notification History View

struct NotificationHistoryView: View {
    let socialManager: SocialEngineeringManager
    @Environment(\.dismiss) private var dismiss
    
    var notifications: [CampaignNotification] {
        socialManager.getLatestNotifications(limit: 50)
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(notifications) { notification in
                    NotificationRow(notification: notification)
                }
            }
            .navigationTitle("Notification History")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct NotificationRow: View {
    let notification: CampaignNotification
    
    var body: some View {
        HStack {
            Image(systemName: notification.type.icon)
                .foregroundColor(notification.type.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.message)
                    .font(.subheadline)
                    .fontWeight(notification.isRead ? .regular : .medium)
                
                Text(notification.timestamp.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !notification.isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    CampaignMonitoringView()
}