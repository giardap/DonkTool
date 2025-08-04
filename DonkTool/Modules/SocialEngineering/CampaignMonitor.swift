//
//  CampaignMonitor.swift
//  DonkTool
//
//  Real-time campaign monitoring and analytics system
//

import Foundation
import SwiftUI
import Combine
import UserNotifications

// MARK: - Campaign Monitor

@Observable
@MainActor
class CampaignMonitor {
    var isMonitoring = false
    var monitoringCampaigns: Set<UUID> = []
    var realTimeMetrics: [UUID: RealTimeMetrics] = [:]
    var liveNotifications: [CampaignNotification] = []
    
    private var monitoringTasks: [UUID: Task<Void, Never>] = [:]
    private var updateInterval: TimeInterval = 30.0 // 30 seconds
    private let socialManager: SocialEngineeringManager
    private let analyticsEngine = PhishingAnalyticsEngine()
    private let notificationManager = CampaignNotificationManager()
    
    init(socialManager: SocialEngineeringManager) {
        self.socialManager = socialManager
        setupNotificationObserver()
    }
    
    // MARK: - Monitoring Control
    
    func startMonitoring(campaignId: UUID) {
        guard !monitoringCampaigns.contains(campaignId) else { return }
        
        monitoringCampaigns.insert(campaignId)
        realTimeMetrics[campaignId] = RealTimeMetrics()
        
        let task = Task {
            await monitorCampaignProgress(campaignId: campaignId)
        }
        
        monitoringTasks[campaignId] = task
        isMonitoring = true
        
        print("📊 Started monitoring campaign: \(campaignId)")
    }
    
    func stopMonitoring(campaignId: UUID) {
        monitoringCampaigns.remove(campaignId)
        monitoringTasks[campaignId]?.cancel()
        monitoringTasks.removeValue(forKey: campaignId)
        realTimeMetrics.removeValue(forKey: campaignId)
        
        if monitoringCampaigns.isEmpty {
            isMonitoring = false
        }
        
        print("🛑 Stopped monitoring campaign: \(campaignId)")
    }
    
    func stopAllMonitoring() {
        for campaignId in monitoringCampaigns {
            stopMonitoring(campaignId: campaignId)
        }
    }
    
    // MARK: - Real-time Campaign Monitoring
    
    private func monitorCampaignProgress(campaignId: UUID) async {
        print("📈 Starting real-time monitoring for campaign: \(campaignId)")
        
        while monitoringCampaigns.contains(campaignId) && !Task.isCancelled {
            do {
                await updateCampaignMetrics(campaignId: campaignId)
                
                // Wait for the update interval
                try await Task.sleep(nanoseconds: UInt64(updateInterval * 1_000_000_000))
                
            } catch {
                if error is CancellationError {
                    print("📊 Campaign monitoring cancelled for: \(campaignId)")
                    break
                } else {
                    print("⚠️ Error monitoring campaign \(campaignId): \(error)")
                    
                    // Wait a bit before retrying on error
                    try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
                }
            }
        }
    }
    
    private func updateCampaignMetrics(campaignId: UUID) async {
        guard let campaign = socialManager.campaigns.first(where: { $0.id == campaignId }) else {
            stopMonitoring(campaignId: campaignId)
            return
        }
        
        // Generate fresh analytics
        if let analytics = socialManager.getCampaignAnalytics(campaignId) {
            let previousMetrics = realTimeMetrics[campaignId]
            let currentMetrics = RealTimeMetrics(
                timestamp: Date(),
                totalTargets: analytics.totalTargets,
                emailsSent: analytics.emailsSent,
                emailsOpened: analytics.emailsOpened,
                linksClicked: analytics.linksClicked,
                credentialsSubmitted: analytics.credentialsSubmitted,
                reported: analytics.reported,
                averageTimeToClick: analytics.averageTimeToClick,
                overallRiskScore: analytics.overallRiskScore,
                departmentBreakdown: analytics.departmentBreakdown,
                openRate: campaign.metrics.openRate,
                clickRate: campaign.metrics.clickRate,
                submissionRate: campaign.metrics.submissionRate,
                reportRate: campaign.metrics.reportRate
            )
            
            realTimeMetrics[campaignId] = currentMetrics
            
            // Check for significant changes and generate notifications
            if let previous = previousMetrics {
                await checkForSignificantChanges(
                    campaignId: campaignId,
                    campaign: campaign,
                    previous: previous,
                    current: currentMetrics
                )
            }
            
            // Log real-time progress
            logProgressUpdate(campaignId: campaignId, metrics: currentMetrics)
        }
    }
    
    // MARK: - Change Detection and Notifications
    
    private func checkForSignificantChanges(
        campaignId: UUID,
        campaign: PhishingCampaign,
        previous: RealTimeMetrics,
        current: RealTimeMetrics
    ) async {
        // Check for new email opens
        if current.emailsOpened > previous.emailsOpened {
            let newOpens = current.emailsOpened - previous.emailsOpened
            await addNotification(
                campaignId: campaignId,
                type: .emailOpened,
                message: "\(newOpens) new email(s) opened in \(campaign.name)",
                details: ["count": String(newOpens), "total": String(current.emailsOpened)]
            )
        }
        
        // Check for new link clicks (high priority)
        if current.linksClicked > previous.linksClicked {
            let newClicks = current.linksClicked - previous.linksClicked
            await addNotification(
                campaignId: campaignId,
                type: .linkClicked,
                message: "⚠️ \(newClicks) new link click(s) in \(campaign.name)",
                details: ["count": String(newClicks), "total": String(current.linksClicked)]
            )
        }
        
        // Check for credential submissions (critical priority)
        if current.credentialsSubmitted > previous.credentialsSubmitted {
            let newSubmissions = current.credentialsSubmitted - previous.credentialsSubmitted
            await addNotification(
                campaignId: campaignId,
                type: .credentialSubmitted,
                message: "🚨 \(newSubmissions) credential submission(s) in \(campaign.name)",
                details: ["count": String(newSubmissions), "total": String(current.credentialsSubmitted)]
            )
        }
        
        // Check for phishing reports (positive outcome)
        if current.reported > previous.reported {
            let newReports = current.reported - previous.reported
            await addNotification(
                campaignId: campaignId,
                type: .phishingReported,
                message: "✅ \(newReports) phishing report(s) in \(campaign.name)",
                details: ["count": String(newReports), "total": String(current.reported)]
            )
        }
        
        // Check for significant risk score changes
        let riskChange = abs(current.overallRiskScore - previous.overallRiskScore)
        if riskChange > 10.0 {
            let direction = current.overallRiskScore > previous.overallRiskScore ? "increased" : "decreased"
            await addNotification(
                campaignId: campaignId,
                type: .riskScoreChange,
                message: "📈 Risk score \(direction) by \(String(format: "%.1f", riskChange)) points",
                details: [
                    "previous": String(format: "%.1f", previous.overallRiskScore),
                    "current": String(format: "%.1f", current.overallRiskScore),
                    "change": String(format: "%.1f", riskChange)
                ]
            )
        }
    }
    
    private func addNotification(
        campaignId: UUID,
        type: NotificationType,
        message: String,
        details: [String: String]
    ) async {
        let notification = CampaignNotification(
            campaignId: campaignId,
            type: type,
            message: message,
            details: details,
            timestamp: Date(),
            isRead: false
        )
        
        liveNotifications.insert(notification, at: 0)
        
        // Limit notification history to 100 items
        if liveNotifications.count > 100 {
            liveNotifications = Array(liveNotifications.prefix(100))
        }
        
        // Send system notification if enabled
        await notificationManager.sendNotification(notification)
    }
    
    // MARK: - Progress Logging
    
    private func logProgressUpdate(campaignId: UUID, metrics: RealTimeMetrics) {
        let progress = """
        
        📊 Campaign Progress Update [\(Date().formatted(.dateTime.hour().minute().second()))]
        ├─ Campaign ID: \(campaignId.uuidString.suffix(8))
        ├─ Emails Sent: \(metrics.emailsSent)/\(metrics.totalTargets)
        ├─ Opened: \(metrics.emailsOpened) (\(String(format: "%.1f%%", metrics.openRate)))
        ├─ Clicked: \(metrics.linksClicked) (\(String(format: "%.1f%%", metrics.clickRate)))
        ├─ Submitted: \(metrics.credentialsSubmitted) (\(String(format: "%.1f%%", metrics.submissionRate)))
        ├─ Reported: \(metrics.reported) (\(String(format: "%.1f%%", metrics.reportRate)))
        └─ Risk Score: \(String(format: "%.1f", metrics.overallRiskScore))/100
        
        """
        
        print(progress)
        
        // Log department breakdown if available
        if !metrics.departmentBreakdown.isEmpty {
            print("📋 Department Breakdown:")
            for (dept, deptMetrics) in metrics.departmentBreakdown.sorted(by: { $0.key < $1.key }) {
                print("   \(dept): \(deptMetrics.submitted)/\(deptMetrics.totalTargets) submitted (\(String(format: "%.1f%%", deptMetrics.successRate)))")
            }
        }
        
        // Log average response times
        if let avgTimeToClick = metrics.averageTimeToClick {
            print("⏱️ Average time to click: \(formatDuration(avgTimeToClick))")
        }
    }
    
    // MARK: - Real-time Analytics API
    
    func getRealTimeMetrics(for campaignId: UUID) -> RealTimeMetrics? {
        return realTimeMetrics[campaignId]
    }
    
    func getLatestNotifications(limit: Int = 10) -> [CampaignNotification] {
        return Array(liveNotifications.prefix(limit))
    }
    
    func markNotificationAsRead(_ notificationId: UUID) {
        if let index = liveNotifications.firstIndex(where: { $0.id == notificationId }) {
            liveNotifications[index].isRead = true
        }
    }
    
    func clearNotifications(for campaignId: UUID) {
        liveNotifications.removeAll { $0.campaignId == campaignId }
    }
    
    func getAllMonitoredCampaigns() -> [UUID] {
        return Array(monitoringCampaigns)
    }
    
    // MARK: - Historical Analysis
    
    func generateProgressReport(for campaignId: UUID, timeRange: TimeRange = .last24Hours) -> ProgressReport? {
        guard let campaign = socialManager.campaigns.first(where: { $0.id == campaignId }),
              let currentMetrics = realTimeMetrics[campaignId] else {
            return nil
        }
        
        let report = ProgressReport(
            campaignId: campaignId,
            campaignName: campaign.name,
            timeRange: timeRange,
            currentMetrics: currentMetrics,
            trendAnalysis: analyzeTrends(campaignId: campaignId, timeRange: timeRange),
            riskAssessment: calculateRiskAssessment(currentMetrics),
            recommendations: generateRecommendations(currentMetrics),
            generatedAt: Date()
        )
        
        return report
    }
    
    private func analyzeTrends(campaignId: UUID, timeRange: TimeRange) -> TrendAnalysis {
        // This would analyze historical data to show trends
        // For now, returning basic analysis
        return TrendAnalysis(
            openRateTrend: .stable,
            clickRateTrend: .increasing,
            submissionRateTrend: .decreasing,
            reportRateTrend: .increasing
        )
    }
    
    private func calculateRiskAssessment(_ metrics: RealTimeMetrics) -> CampaignRiskAssessment {
        let riskLevel: RiskLevel
        switch metrics.overallRiskScore {
        case 0..<20:
            riskLevel = .low
        case 20..<40:
            riskLevel = .medium
        case 40..<60:
            riskLevel = .high
        default:
            riskLevel = .critical
        }
        
        return CampaignRiskAssessment(
            level: riskLevel,
            score: metrics.overallRiskScore,
            factors: [
                "Click Rate": metrics.clickRate,
                "Submission Rate": metrics.submissionRate,
                "Report Rate": metrics.reportRate
            ],
            description: riskLevel.description
        )
    }
    
    private func generateRecommendations(_ metrics: RealTimeMetrics) -> [String] {
        var recommendations: [String] = []
        
        if metrics.clickRate > 30 {
            recommendations.append("High click rate detected - implement additional email security training")
        }
        
        if metrics.submissionRate > 10 {
            recommendations.append("Credential submissions occurring - enforce MFA and review security policies")
        }
        
        if metrics.reportRate < 20 {
            recommendations.append("Low reporting rate - improve phishing reporting processes and employee awareness")
        }
        
        if metrics.overallRiskScore > 50 {
            recommendations.append("Critical risk level - immediate security intervention required")
        }
        
        if recommendations.isEmpty {
            recommendations.append("Continue monitoring - security awareness appears adequate")
        }
        
        return recommendations
    }
    
    // MARK: - Configuration
    
    func setUpdateInterval(_ interval: TimeInterval) {
        updateInterval = max(10.0, interval) // Minimum 10 seconds
    }
    
    func getUpdateInterval() -> TimeInterval {
        return updateInterval
    }
    
    // MARK: - Notification Observer
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: .targetStatusUpdated,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let campaignId = notification.userInfo?["campaignId"] as? UUID,
                  self.monitoringCampaigns.contains(campaignId) else { return }
            
            // Trigger immediate update for this campaign
            Task {
                await self.updateCampaignMetrics(campaignId: campaignId)
            }
        }
    }
    
    // MARK: - Utility Functions
    
    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
    
    deinit {
        // Tasks will be automatically cancelled when deallocated
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Data Models

struct RealTimeMetrics {
    let timestamp: Date = Date()
    let totalTargets: Int
    let emailsSent: Int
    let emailsOpened: Int
    let linksClicked: Int
    let credentialsSubmitted: Int
    let reported: Int
    let averageTimeToClick: TimeInterval?
    let overallRiskScore: Double
    let departmentBreakdown: [String: DepartmentMetrics]
    let openRate: Double
    let clickRate: Double
    let submissionRate: Double
    let reportRate: Double
    
    init() {
        self.totalTargets = 0
        self.emailsSent = 0
        self.emailsOpened = 0
        self.linksClicked = 0
        self.credentialsSubmitted = 0
        self.reported = 0
        self.averageTimeToClick = nil
        self.overallRiskScore = 0.0
        self.departmentBreakdown = [:]
        self.openRate = 0.0
        self.clickRate = 0.0
        self.submissionRate = 0.0
        self.reportRate = 0.0
    }
    
    init(
        timestamp: Date = Date(),
        totalTargets: Int,
        emailsSent: Int,
        emailsOpened: Int,
        linksClicked: Int,
        credentialsSubmitted: Int,
        reported: Int,
        averageTimeToClick: TimeInterval?,
        overallRiskScore: Double,
        departmentBreakdown: [String: DepartmentMetrics],
        openRate: Double,
        clickRate: Double,
        submissionRate: Double,
        reportRate: Double
    ) {
        self.totalTargets = totalTargets
        self.emailsSent = emailsSent
        self.emailsOpened = emailsOpened
        self.linksClicked = linksClicked
        self.credentialsSubmitted = credentialsSubmitted
        self.reported = reported
        self.averageTimeToClick = averageTimeToClick
        self.overallRiskScore = overallRiskScore
        self.departmentBreakdown = departmentBreakdown
        self.openRate = openRate
        self.clickRate = clickRate
        self.submissionRate = submissionRate
        self.reportRate = reportRate
    }
}

struct CampaignNotification: Identifiable {
    let id = UUID()
    let campaignId: UUID
    let type: NotificationType
    let message: String
    let details: [String: String]
    let timestamp: Date
    var isRead: Bool
}

enum NotificationType: String, CaseIterable {
    case emailOpened = "Email Opened"
    case linkClicked = "Link Clicked"
    case credentialSubmitted = "Credential Submitted"
    case phishingReported = "Phishing Reported"
    case riskScoreChange = "Risk Score Change"
    case campaignCompleted = "Campaign Completed"
    
    var icon: String {
        switch self {
        case .emailOpened: return "envelope.open"
        case .linkClicked: return "link"
        case .credentialSubmitted: return "exclamationmark.triangle.fill"
        case .phishingReported: return "checkmark.shield"
        case .riskScoreChange: return "chart.line.uptrend.xyaxis"
        case .campaignCompleted: return "checkmark.seal.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .emailOpened: return .blue
        case .linkClicked: return .orange
        case .credentialSubmitted: return .red
        case .phishingReported: return .green
        case .riskScoreChange: return .purple
        case .campaignCompleted: return .blue
        }
    }
    
    var priority: Int {
        switch self {
        case .credentialSubmitted: return 3
        case .linkClicked: return 2
        case .riskScoreChange: return 2
        case .phishingReported: return 1
        case .emailOpened: return 1
        case .campaignCompleted: return 1
        }
    }
}

struct ProgressReport {
    let campaignId: UUID
    let campaignName: String
    let timeRange: TimeRange
    let currentMetrics: RealTimeMetrics
    let trendAnalysis: TrendAnalysis
    let riskAssessment: CampaignRiskAssessment
    let recommendations: [String]
    let generatedAt: Date
}

enum TimeRange: String, CaseIterable {
    case last1Hour = "Last 1 Hour"
    case last6Hours = "Last 6 Hours"
    case last24Hours = "Last 24 Hours"
    case last7Days = "Last 7 Days"
    
    var duration: TimeInterval {
        switch self {
        case .last1Hour: return 3600
        case .last6Hours: return 21600
        case .last24Hours: return 86400
        case .last7Days: return 604800
        }
    }
}

struct TrendAnalysis {
    let openRateTrend: Trend
    let clickRateTrend: Trend
    let submissionRateTrend: Trend
    let reportRateTrend: Trend
}

enum Trend: String, CaseIterable {
    case increasing = "Increasing"
    case decreasing = "Decreasing"
    case stable = "Stable"
    
    var icon: String {
        switch self {
        case .increasing: return "arrow.up.right"
        case .decreasing: return "arrow.down.right"
        case .stable: return "minus"
        }
    }
    
    var color: Color {
        switch self {
        case .increasing: return .red
        case .decreasing: return .green
        case .stable: return .gray
        }
    }
}

struct CampaignRiskAssessment {
    let level: RiskLevel
    let score: Double
    let factors: [String: Double]
    let description: String
}

enum RiskLevel: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
    
    var description: String {
        switch self {
        case .low:
            return "Excellent security awareness. Low risk of successful phishing attacks."
        case .medium:
            return "Moderate risk. Some employees may be susceptible to phishing attempts."
        case .high:
            return "High risk. Significant number of employees vulnerable to phishing attacks."
        case .critical:
            return "Critical risk. Organization is highly vulnerable to phishing attacks."
        }
    }
}

// MARK: - Campaign Notification Manager

@MainActor
class CampaignNotificationManager {
    private let userNotificationCenter = UNUserNotificationCenter.current()
    
    init() {
        requestNotificationPermission()
    }
    
    private func requestNotificationPermission() {
        Task {
            do {
                let granted = try await userNotificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
                if granted {
                    print("✅ Notification permissions granted")
                } else {
                    print("❌ Notification permissions denied")
                }
            } catch {
                print("⚠️ Error requesting notification permissions: \(error)")
            }
        }
    }
    
    func sendNotification(_ notification: CampaignNotification) async {
        // Only send system notifications for high-priority events
        guard notification.type.priority >= 2 else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "DonkTool Social Engineering"
        content.body = notification.message
        content.sound = .default
        content.userInfo = [
            "campaignId": notification.campaignId.uuidString,
            "type": notification.type.rawValue,
            "timestamp": notification.timestamp.timeIntervalSince1970
        ]
        
        let request = UNNotificationRequest(
            identifier: notification.id.uuidString,
            content: content,
            trigger: nil
        )
        
        do {
            try await userNotificationCenter.add(request)
        } catch {
            print("⚠️ Failed to send notification: \(error)")
        }
    }
}