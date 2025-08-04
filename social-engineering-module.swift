//
//  SocialEngineeringModule.swift
//  DonkTool
//
//  Social Engineering Framework for authorized penetration testing
//

import SwiftUI
import Foundation
import WebKit
import Combine

// MARK: - Legal Disclaimer
/*
 ⚠️ AUTHORIZED SECURITY TESTING ONLY ⚠️
 
 This module is designed for authorized penetration testing and security awareness training.
 
 REQUIREMENTS:
 • Written authorization from the organization
 • Signed penetration testing agreement
 • Compliance with local laws and regulations
 • Professional liability insurance
 
 PROHIBITED USES:
 • Unauthorized phishing attempts
 • Credential theft without permission
 • Targeting individuals without consent
 • Any malicious or illegal activities
 */

// MARK: - Social Engineering Data Models

struct PhishingCampaign: Identifiable, Codable {
    let id = UUID()
    var name: String
    var description: String
    var targetOrganization: String
    var status: CampaignStatus
    var createdAt: Date
    var launchedAt: Date?
    var completedAt: Date?
    var targets: [PhishingTarget]
    var emailTemplate: EmailTemplate
    var landingPage: LandingPageTemplate
    var metrics: CampaignMetrics
    var settings: CampaignSettings
    
    enum CampaignStatus: String, Codable, CaseIterable {
        case draft = "Draft"
        case ready = "Ready"
        case active = "Active"
        case paused = "Paused"
        case completed = "Completed"
        
        var color: Color {
            switch self {
            case .draft: return .gray
            case .ready: return .blue
            case .active: return .green
            case .paused: return .orange
            case .completed: return .purple
            }
        }
        
        var icon: String {
            switch self {
            case .draft: return "doc.text"
            case .ready: return "checkmark.circle"
            case .active: return "play.circle.fill"
            case .paused: return "pause.circle.fill"
            case .completed: return "checkmark.seal.fill"
            }
        }
    }
}

struct PhishingTarget: Identifiable, Codable {
    let id = UUID()
    var email: String
    var firstName: String
    var lastName: String
    var department: String?
    var position: String?
    var customFields: [String: String]
    var status: TargetStatus
    var emailSentAt: Date?
    var emailOpenedAt: Date?
    var linkClickedAt: Date?
    var credentialsSubmittedAt: Date?
    var reportedAsPhishingAt: Date?
    var interactions: [TargetInteraction]
    
    enum TargetStatus: String, Codable, CaseIterable {
        case pending = "Pending"
        case sent = "Sent"
        case opened = "Opened"
        case clicked = "Clicked"
        case submitted = "Submitted"
        case reported = "Reported"
        case bounced = "Bounced"
        case failed = "Failed"
        
        var color: Color {
            switch self {
            case .pending: return .gray
            case .sent: return .blue
            case .opened: return .cyan
            case .clicked: return .orange
            case .submitted: return .red
            case .reported: return .green
            case .bounced: return .yellow
            case .failed: return .red
            }
        }
    }
}

struct TargetInteraction: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let action: InteractionType
    let ipAddress: String?
    let userAgent: String?
    let location: String?
    let details: [String: String]
    
    enum InteractionType: String, Codable {
        case emailSent = "Email Sent"
        case emailOpened = "Email Opened"
        case linkClicked = "Link Clicked"
        case pageVisited = "Landing Page Visited"
        case credentialsEntered = "Credentials Entered"
        case attachmentOpened = "Attachment Opened"
        case reported = "Reported as Phishing"
    }
}

struct EmailTemplate: Identifiable, Codable {
    let id = UUID()
    var name: String
    var subject: String
    var senderName: String
    var senderEmail: String
    var replyTo: String?
    var htmlContent: String
    var textContent: String
    var attachments: [EmailAttachment]
    var trackingEnabled: Bool
    var category: TemplateCategory
    var difficulty: TemplateDifficulty
    var tags: [String]
    
    enum TemplateCategory: String, Codable, CaseIterable {
        case corporate = "Corporate Communication"
        case it = "IT Department"
        case hr = "Human Resources"
        case financial = "Financial"
        case social = "Social Media"
        case delivery = "Package Delivery"
        case password = "Password Reset"
        case security = "Security Alert"
        case custom = "Custom"
        
        var icon: String {
            switch self {
            case .corporate: return "building.2"
            case .it: return "desktopcomputer"
            case .hr: return "person.2"
            case .financial: return "dollarsign.circle"
            case .social: return "person.3"
            case .delivery: return "shippingbox"
            case .password: return "key"
            case .security: return "shield"
            case .custom: return "square.and.pencil"
            }
        }
    }
    
    enum TemplateDifficulty: String, Codable, CaseIterable {
        case easy = "Easy"
        case medium = "Medium"
        case hard = "Hard"
        case expert = "Expert"
        
        var color: Color {
            switch self {
            case .easy: return .green
            case .medium: return .orange
            case .hard: return .red
            case .expert: return .purple
            }
        }
        
        var description: String {
            switch self {
            case .easy: return "Generic, obvious phishing indicators"
            case .medium: return "Some effort to appear legitimate"
            case .hard: return "Well-crafted, targeted content"
            case .expert: return "Highly sophisticated, spear-phishing"
            }
        }
    }
}

struct EmailAttachment: Identifiable, Codable {
    let id = UUID()
    var name: String
    var mimeType: String
    var size: Int
    var content: Data
    var isPayload: Bool
    var payloadType: PayloadType?
    
    enum PayloadType: String, Codable, CaseIterable {
        case macro = "Office Macro"
        case pdf = "PDF Exploit"
        case executable = "Executable"
        case script = "Script"
        case link = "Redirect Link"
    }
}

struct LandingPageTemplate: Identifiable, Codable {
    let id = UUID()
    var name: String
    var url: String
    var htmlContent: String
    var cssContent: String
    var jsContent: String
    var captureCredentials: Bool
    var redirectUrl: String?
    var customFields: [CustomFormField]
    var pageType: PageType
    
    enum PageType: String, Codable, CaseIterable {
        case login = "Login Page"
        case survey = "Survey"
        case download = "Download Page"
        case information = "Information Capture"
        case redirect = "Redirect Only"
        
        var icon: String {
            switch self {
            case .login: return "person.crop.circle"
            case .survey: return "doc.text.magnifyingglass"
            case .download: return "arrow.down.circle"
            case .information: return "info.circle"
            case .redirect: return "arrow.right.circle"
            }
        }
    }
}

struct CustomFormField: Identifiable, Codable {
    let id = UUID()
    var fieldName: String
    var fieldType: FieldType
    var placeholder: String
    var required: Bool
    var validation: String?
    
    enum FieldType: String, Codable, CaseIterable {
        case text = "Text"
        case email = "Email"
        case password = "Password"
        case number = "Number"
        case dropdown = "Dropdown"
        case checkbox = "Checkbox"
        case textarea = "Text Area"
    }
}

struct CampaignMetrics: Codable {
    var totalTargets: Int = 0
    var emailsSent: Int = 0
    var emailsOpened: Int = 0
    var linksClicked: Int = 0
    var credentialsSubmitted: Int = 0
    var reportedAsPhishing: Int = 0
    var failedDeliveries: Int = 0
    
    var openRate: Double {
        guard emailsSent > 0 else { return 0 }
        return Double(emailsOpened) / Double(emailsSent) * 100
    }
    
    var clickRate: Double {
        guard emailsOpened > 0 else { return 0 }
        return Double(linksClicked) / Double(emailsOpened) * 100
    }
    
    var submissionRate: Double {
        guard linksClicked > 0 else { return 0 }
        return Double(credentialsSubmitted) / Double(linksClicked) * 100
    }
    
    var reportRate: Double {
        guard emailsSent > 0 else { return 0 }
        return Double(reportedAsPhishing) / Double(emailsSent) * 100
    }
}

struct CampaignSettings: Codable {
    var sendingProfile: SendingProfile
    var schedule: CampaignSchedule
    var trackingOptions: TrackingOptions
    var notifications: NotificationSettings
}

struct SendingProfile: Identifiable, Codable {
    let id = UUID()
    var name: String
    var smtpHost: String
    var smtpPort: Int
    var username: String
    var password: String
    var useTLS: Bool
    var useStartTLS: Bool
    var sendRate: Int // emails per hour
}

struct CampaignSchedule: Codable {
    var startDate: Date
    var endDate: Date?
    var sendingDays: Set<Weekday>
    var sendingHours: ClosedRange<Int>
    var timezone: TimeZone
    
    enum Weekday: String, Codable, CaseIterable {
        case monday, tuesday, wednesday, thursday, friday, saturday, sunday
    }
}

struct TrackingOptions: Codable {
    var trackEmailOpens: Bool = true
    var trackLinkClicks: Bool = true
    var trackCredentials: Bool = true
    var trackUserAgent: Bool = true
    var trackLocation: Bool = true
    var useUniqueLinks: Bool = true
    var pixelTracking: Bool = true
}

struct NotificationSettings: Codable {
    var notifyOnOpen: Bool = false
    var notifyOnClick: Bool = true
    var notifyOnSubmit: Bool = true
    var notifyOnReport: Bool = true
    var notificationEmail: String?
    var webhookUrl: String?
}

// MARK: - Social Engineering Manager

@Observable
class SocialEngineeringManager {
    var campaigns: [PhishingCampaign] = []
    var emailTemplates: [EmailTemplate] = []
    var landingPageTemplates: [LandingPageTemplate] = []
    var sendingProfiles: [SendingProfile] = []
    
    private let dataStore = SocialEngineeringDataStore()
    private let campaignEngine = CampaignExecutionEngine()
    private let analyticsEngine = PhishingAnalyticsEngine()
    
    init() {
        loadData()
        loadDefaultTemplates()
    }
    
    func createCampaign(_ campaign: PhishingCampaign) {
        campaigns.append(campaign)
        saveCampaigns()
    }
    
    func updateCampaign(_ campaign: PhishingCampaign) {
        if let index = campaigns.firstIndex(where: { $0.id == campaign.id }) {
            campaigns[index] = campaign
            saveCampaigns()
        }
    }
    
    func deleteCampaign(_ campaignId: UUID) {
        campaigns.removeAll { $0.id == campaignId }
        saveCampaigns()
    }
    
    func launchCampaign(_ campaignId: UUID) async throws {
        guard let campaign = campaigns.first(where: { $0.id == campaignId }) else {
            throw CampaignError.campaignNotFound
        }
        
        guard campaign.status == .ready else {
            throw CampaignError.invalidStatus
        }
        
        var updatedCampaign = campaign
        updatedCampaign.status = .active
        updatedCampaign.launchedAt = Date()
        updateCampaign(updatedCampaign)
        
        try await campaignEngine.executeCampaign(updatedCampaign)
    }
    
    func pauseCampaign(_ campaignId: UUID) {
        guard var campaign = campaigns.first(where: { $0.id == campaignId }) else { return }
        campaign.status = .paused
        updateCampaign(campaign)
        campaignEngine.pauseCampaign(campaignId)
    }
    
    func resumeCampaign(_ campaignId: UUID) async throws {
        guard var campaign = campaigns.first(where: { $0.id == campaignId }) else { return }
        campaign.status = .active
        updateCampaign(campaign)
        try await campaignEngine.resumeCampaign(campaign)
    }
    
    func getCampaignAnalytics(_ campaignId: UUID) -> CampaignAnalytics? {
        guard let campaign = campaigns.first(where: { $0.id == campaignId }) else { return nil }
        return analyticsEngine.generateAnalytics(for: campaign)
    }
    
    // MARK: - Template Management
    
    func createEmailTemplate(_ template: EmailTemplate) {
        emailTemplates.append(template)
        saveEmailTemplates()
    }
    
    func createLandingPageTemplate(_ template: LandingPageTemplate) {
        landingPageTemplates.append(template)
        saveLandingPageTemplates()
    }
    
    func importTargetsFromCSV(_ csvData: Data) throws -> [PhishingTarget] {
        let csvString = String(data: csvData, encoding: .utf8) ?? ""
        return try CSVTargetParser.parse(csvString)
    }
    
    // MARK: - Data Persistence
    
    private func loadData() {
        campaigns = dataStore.loadCampaigns()
        emailTemplates = dataStore.loadEmailTemplates()
        landingPageTemplates = dataStore.loadLandingPageTemplates()
        sendingProfiles = dataStore.loadSendingProfiles()
    }
    
    private func saveCampaigns() {
        dataStore.saveCampaigns(campaigns)
    }
    
    private func saveEmailTemplates() {
        dataStore.saveEmailTemplates(emailTemplates)
    }
    
    private func saveLandingPageTemplates() {
        dataStore.saveLandingPageTemplates(landingPageTemplates)
    }
    
    private func loadDefaultTemplates() {
        if emailTemplates.isEmpty {
            emailTemplates = DefaultTemplates.emailTemplates
            saveEmailTemplates()
        }
        
        if landingPageTemplates.isEmpty {
            landingPageTemplates = DefaultTemplates.landingPageTemplates
            saveLandingPageTemplates()
        }
    }
}

// MARK: - Campaign Execution Engine

class CampaignExecutionEngine {
    private var activeCampaigns: [UUID: Task<Void, Error>] = [:]
    private let emailSender = EmailSendingService()
    private let trackingServer = TrackingServer()
    
    func executeCampaign(_ campaign: PhishingCampaign) async throws {
        let task = Task {
            try await runCampaign(campaign)
        }
        
        activeCampaigns[campaign.id] = task
        
        do {
            try await task.value
        } catch {
            activeCampaigns.removeValue(forKey: campaign.id)
            throw error
        }
    }
    
    func pauseCampaign(_ campaignId: UUID) {
        activeCampaigns[campaignId]?.cancel()
        activeCampaigns.removeValue(forKey: campaignId)
    }
    
    func resumeCampaign(_ campaign: PhishingCampaign) async throws {
        try await executeCampaign(campaign)
    }
    
    private func runCampaign(_ campaign: PhishingCampaign) async throws {
        // Set up tracking endpoints
        await trackingServer.setupCampaignEndpoints(campaign)
        
        // Process targets based on schedule
        let schedule = campaign.settings.schedule
        let sendRate = campaign.settings.sendingProfile.sendRate
        
        for target in campaign.targets where target.status == .pending {
            // Check if within scheduled time
            guard isWithinSchedule(schedule) else {
                try await Task.sleep(nanoseconds: 60_000_000_000) // Wait 1 minute
                continue
            }
            
            // Check for cancellation
            try Task.checkCancellation()
            
            // Send phishing email
            let trackingId = generateTrackingId(campaign: campaign, target: target)
            let personalizedEmail = personalizeEmail(
                template: campaign.emailTemplate,
                target: target,
                trackingId: trackingId
            )
            
            do {
                try await emailSender.sendEmail(
                    personalizedEmail,
                    to: target,
                    using: campaign.settings.sendingProfile
                )
                
                // Update target status
                updateTargetStatus(target, status: .sent, in: campaign)
                
                // Rate limiting
                let delaySeconds = 3600.0 / Double(sendRate)
                try await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
                
            } catch {
                updateTargetStatus(target, status: .failed, in: campaign)
                print("Failed to send email to \(target.email): \(error)")
            }
        }
        
        // Mark campaign as completed
        markCampaignCompleted(campaign)
    }
    
    private func isWithinSchedule(_ schedule: CampaignSchedule) -> Bool {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let weekday = calendar.component(.weekday, from: now)
        
        // Check if current hour is within sending hours
        guard schedule.sendingHours.contains(hour) else { return false }
        
        // Check if current day is in sending days
        let currentWeekday = Weekday.from(weekday: weekday)
        return schedule.sendingDays.contains(currentWeekday)
    }
    
    private func generateTrackingId(campaign: PhishingCampaign, target: PhishingTarget) -> String {
        let data = "\(campaign.id.uuidString)-\(target.id.uuidString)".data(using: .utf8)!
        return data.base64EncodedString()
    }
    
    private func personalizeEmail(template: EmailTemplate, target: PhishingTarget, trackingId: String) -> PersonalizedEmail {
        var content = template.htmlContent
        
        // Replace placeholders
        content = content.replacingOccurrences(of: "{{firstName}}", with: target.firstName)
        content = content.replacingOccurrences(of: "{{lastName}}", with: target.lastName)
        content = content.replacingOccurrences(of: "{{email}}", with: target.email)
        content = content.replacingOccurrences(of: "{{department}}", with: target.department ?? "")
        content = content.replacingOccurrences(of: "{{position}}", with: target.position ?? "")
        
        // Add tracking pixel
        if template.trackingEnabled {
            let trackingPixel = "<img src=\"https://tracking.example.com/pixel/\(trackingId)\" width=\"1\" height=\"1\" />"
            content = content.replacingOccurrences(of: "</body>", with: "\(trackingPixel)</body>")
        }
        
        // Update links with tracking
        content = addLinkTracking(content, trackingId: trackingId)
        
        return PersonalizedEmail(
            subject: personalizeText(template.subject, target: target),
            htmlContent: content,
            textContent: personalizeText(template.textContent, target: target),
            senderName: template.senderName,
            senderEmail: template.senderEmail,
            replyTo: template.replyTo,
            attachments: template.attachments,
            trackingId: trackingId
        )
    }
    
    private func personalizeText(_ text: String, target: PhishingTarget) -> String {
        var result = text
        result = result.replacingOccurrences(of: "{{firstName}}", with: target.firstName)
        result = result.replacingOccurrences(of: "{{lastName}}", with: target.lastName)
        result = result.replacingOccurrences(of: "{{email}}", with: target.email)
        result = result.replacingOccurrences(of: "{{department}}", with: target.department ?? "")
        result = result.replacingOccurrences(of: "{{position}}", with: target.position ?? "")
        
        // Replace custom fields
        for (key, value) in target.customFields {
            result = result.replacingOccurrences(of: "{{\(key)}}", with: value)
        }
        
        return result
    }
    
    private func addLinkTracking(_ html: String, trackingId: String) -> String {
        // This is a simplified version - real implementation would use proper HTML parsing
        var result = html
        
        // Find all links and add tracking
        let pattern = #"href="(https?://[^"]+)""#
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let matches = regex.matches(in: html, range: NSRange(html.startIndex..., in: html))
            
            for match in matches.reversed() {
                if let range = Range(match.range(at: 1), in: html) {
                    let originalUrl = String(html[range])
                    let trackedUrl = "https://tracking.example.com/click/\(trackingId)?url=\(originalUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
                    result.replaceSubrange(range, with: trackedUrl)
                }
            }
        }
        
        return result
    }
    
    private func updateTargetStatus(_ target: PhishingTarget, status: PhishingTarget.TargetStatus, in campaign: PhishingCampaign) {
        // Implementation would update the target status in the campaign
    }
    
    private func markCampaignCompleted(_ campaign: PhishingCampaign) {
        // Implementation would mark the campaign as completed
    }
}

// MARK: - Email Sending Service

class EmailSendingService {
    func sendEmail(_ email: PersonalizedEmail, to target: PhishingTarget, using profile: SendingProfile) async throws {
        // This is a placeholder - real implementation would use SMTP
        print("Sending email to \(target.email) via \(profile.smtpHost)")
        
        // Simulate sending delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // In production, this would:
        // 1. Connect to SMTP server
        // 2. Authenticate
        // 3. Send the email
        // 4. Handle delivery status
    }
}

// MARK: - Tracking Server

class TrackingServer {
    private var campaignEndpoints: [UUID: CampaignEndpoint] = [:]
    
    func setupCampaignEndpoints(_ campaign: PhishingCampaign) async {
        let endpoint = CampaignEndpoint(
            campaign: campaign,
            pixelHandler: handlePixelRequest,
            clickHandler: handleClickRequest,
            landingPageHandler: handleLandingPageRequest
        )
        
        campaignEndpoints[campaign.id] = endpoint
        
        // In production, this would set up actual web server endpoints
    }
    
    private func handlePixelRequest(trackingId: String, request: TrackingRequest) async {
        // Log email open event
        if let (campaignId, targetId) = decodeTrackingId(trackingId) {
            logInteraction(
                campaignId: campaignId,
                targetId: targetId,
                action: .emailOpened,
                request: request
            )
        }
    }
    
    private func handleClickRequest(trackingId: String, url: String, request: TrackingRequest) async {
        // Log link click event
        if let (campaignId, targetId) = decodeTrackingId(trackingId) {
            logInteraction(
                campaignId: campaignId,
                targetId: targetId,
                action: .linkClicked,
                request: request
            )
        }
    }
    
    private func handleLandingPageRequest(trackingId: String, formData: [String: String]?, request: TrackingRequest) async {
        // Log landing page interaction
        if let (campaignId, targetId) = decodeTrackingId(trackingId) {
            if let formData = formData, !formData.isEmpty {
                logInteraction(
                    campaignId: campaignId,
                    targetId: targetId,
                    action: .credentialsEntered,
                    request: request,
                    details: formData
                )
            } else {
                logInteraction(
                    campaignId: campaignId,
                    targetId: targetId,
                    action: .pageVisited,
                    request: request
                )
            }
        }
    }
    
    private func decodeTrackingId(_ trackingId: String) -> (campaignId: UUID, targetId: UUID)? {
        guard let data = Data(base64Encoded: trackingId),
              let string = String(data: data, encoding: .utf8) else { return nil }
        
        let parts = string.split(separator: "-")
        guard parts.count == 2,
              let campaignId = UUID(uuidString: String(parts[0])),
              let targetId = UUID(uuidString: String(parts[1])) else { return nil }
        
        return (campaignId, targetId)
    }
    
    private func logInteraction(
        campaignId: UUID,
        targetId: UUID,
        action: TargetInteraction.InteractionType,
        request: TrackingRequest,
        details: [String: String] = [:]
    ) {
        let interaction = TargetInteraction(
            timestamp: Date(),
            action: action,
            ipAddress: request.ipAddress,
            userAgent: request.userAgent,
            location: request.location,
            details: details
        )
        
        // Store interaction in database
        // Update campaign metrics
        // Send notifications if configured
    }
}

// MARK: - Analytics Engine

class PhishingAnalyticsEngine {
    func generateAnalytics(for campaign: PhishingCampaign) -> CampaignAnalytics {
        var analytics = CampaignAnalytics()
        
        // Calculate basic metrics
        analytics.totalTargets = campaign.targets.count
        analytics.emailsSent = campaign.targets.filter { $0.status != .pending }.count
        analytics.emailsOpened = campaign.targets.filter { $0.emailOpenedAt != nil }.count
        analytics.linksClicked = campaign.targets.filter { $0.linkClickedAt != nil }.count
        analytics.credentialsSubmitted = campaign.targets.filter { $0.credentialsSubmittedAt != nil }.count
        analytics.reported = campaign.targets.filter { $0.reportedAsPhishingAt != nil }.count
        
        // Calculate time-based metrics
        analytics.averageTimeToOpen = calculateAverageTime(
            targets: campaign.targets,
            startTime: \.emailSentAt,
            endTime: \.emailOpenedAt
        )
        
        analytics.averageTimeToClick = calculateAverageTime(
            targets: campaign.targets,
            startTime: \.emailOpenedAt,
            endTime: \.linkClickedAt
        )
        
        analytics.averageTimeToSubmit = calculateAverageTime(
            targets: campaign.targets,
            startTime: \.linkClickedAt,
            endTime: \.credentialsSubmittedAt
        )
        
        // Department analysis
        analytics.departmentBreakdown = analyzeDepartments(campaign.targets)
        
        // Risk score calculation
        analytics.overallRiskScore = calculateRiskScore(campaign)
        
        return analytics
    }
    
    private func calculateAverageTime(
        targets: [PhishingTarget],
        startTime: KeyPath<PhishingTarget, Date?>,
        endTime: KeyPath<PhishingTarget, Date?>
    ) -> TimeInterval? {
        let validTargets = targets.compactMap { target -> TimeInterval? in
            guard let start = target[keyPath: startTime],
                  let end = target[keyPath: endTime] else { return nil }
            return end.timeIntervalSince(start)
        }
        
        guard !validTargets.isEmpty else { return nil }
        return validTargets.reduce(0, +) / Double(validTargets.count)
    }
    
    private func analyzeDepartments(_ targets: [PhishingTarget]) -> [String: DepartmentMetrics] {
        var breakdown: [String: DepartmentMetrics] = [:]
        
        for target in targets {
            let dept = target.department ?? "Unknown"
            var metrics = breakdown[dept] ?? DepartmentMetrics()
            
            metrics.totalTargets += 1
            if target.emailOpenedAt != nil { metrics.opened += 1 }
            if target.linkClickedAt != nil { metrics.clicked += 1 }
            if target.credentialsSubmittedAt != nil { metrics.submitted += 1 }
            if target.reportedAsPhishingAt != nil { metrics.reported += 1 }
            
            breakdown[dept] = metrics
        }
        
        return breakdown
    }
    
    private func calculateRiskScore(_ campaign: PhishingCampaign) -> Double {
        let metrics = campaign.metrics
        
        // Weight factors for risk calculation
        let clickWeight = 0.3
        let submitWeight = 0.5
        let reportWeight = -0.2 // Negative because reporting is good
        
        let clickRate = metrics.clickRate / 100
        let submitRate = metrics.submissionRate / 100
        let reportRate = metrics.reportRate / 100
        
        let riskScore = (clickRate * clickWeight) + 
                       (submitRate * submitWeight) + 
                       (reportRate * reportWeight)
        
        return min(max(riskScore * 100, 0), 100) // Normalize to 0-100
    }
}

// MARK: - Supporting Types

struct PersonalizedEmail {
    let subject: String
    let htmlContent: String
    let textContent: String
    let senderName: String
    let senderEmail: String
    let replyTo: String?
    let attachments: [EmailAttachment]
    let trackingId: String
}

struct CampaignEndpoint {
    let campaign: PhishingCampaign
    let pixelHandler: (String, TrackingRequest) async -> Void
    let clickHandler: (String, String, TrackingRequest) async -> Void
    let landingPageHandler: (String, [String: String]?, TrackingRequest) async -> Void
}

struct TrackingRequest {
    let ipAddress: String?
    let userAgent: String?
    let location: String?
    let timestamp: Date
}

struct CampaignAnalytics {
    var totalTargets: Int = 0
    var emailsSent: Int = 0
    var emailsOpened: Int = 0
    var linksClicked: Int = 0
    var credentialsSubmitted: Int = 0
    var reported: Int = 0
    
    var averageTimeToOpen: TimeInterval?
    var averageTimeToClick: TimeInterval?
    var averageTimeToSubmit: TimeInterval?
    
    var departmentBreakdown: [String: DepartmentMetrics] = [:]
    var overallRiskScore: Double = 0
}

struct DepartmentMetrics {
    var totalTargets: Int = 0
    var opened: Int = 0
    var clicked: Int = 0
    var submitted: Int = 0
    var reported: Int = 0
    
    var openRate: Double {
        guard totalTargets > 0 else { return 0 }
        return Double(opened) / Double(totalTargets) * 100
    }
    
    var clickRate: Double {
        guard opened > 0 else { return 0 }
        return Double(clicked) / Double(opened) * 100
    }
    
    var submitRate: Double {
        guard clicked > 0 else { return 0 }
        return Double(submitted) / Double(clicked) * 100
    }
}

// MARK: - Data Store

class SocialEngineeringDataStore {
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    func loadCampaigns() -> [PhishingCampaign] {
        let url = documentsDirectory.appendingPathComponent("phishing_campaigns.json")
        guard let data = try? Data(contentsOf: url),
              let campaigns = try? JSONDecoder().decode([PhishingCampaign].self, from: data) else {
            return []
        }
        return campaigns
    }
    
    func saveCampaigns(_ campaigns: [PhishingCampaign]) {
        let url = documentsDirectory.appendingPathComponent("phishing_campaigns.json")
        if let data = try? JSONEncoder().encode(campaigns) {
            try? data.write(to: url)
        }
    }
    
    func loadEmailTemplates() -> [EmailTemplate] {
        let url = documentsDirectory.appendingPathComponent("email_templates.json")
        guard let data = try? Data(contentsOf: url),
              let templates = try? JSONDecoder().decode([EmailTemplate].self, from: data) else {
            return []
        }
        return templates
    }
    
    func saveEmailTemplates(_ templates: [EmailTemplate]) {
        let url = documentsDirectory.appendingPathComponent("email_templates.json")
        if let data = try? JSONEncoder().encode(templates) {
            try? data.write(to: url)
        }
    }
    
    func loadLandingPageTemplates() -> [LandingPageTemplate] {
        let url = documentsDirectory.appendingPathComponent("landing_templates.json")
        guard let data = try? Data(contentsOf: url),
              let templates = try? JSONDecoder().decode([LandingPageTemplate].self, from: data) else {
            return []
        }
        return templates
    }
    
    func saveLandingPageTemplates(_ templates: [LandingPageTemplate]) {
        let url = documentsDirectory.appendingPathComponent("landing_templates.json")
        if let data = try? JSONEncoder().encode(templates) {
            try? data.write(to: url)
        }
    }
    
    func loadSendingProfiles() -> [SendingProfile] {
        let url = documentsDirectory.appendingPathComponent("sending_profiles.json")
        guard let data = try? Data(contentsOf: url),
              let profiles = try? JSONDecoder().decode([SendingProfile].self, from: data) else {
            return []
        }
        return profiles
    }
}

// MARK: - Utility Classes

struct CSVTargetParser {
    static func parse(_ csvString: String) throws -> [PhishingTarget] {
        let lines = csvString.components(separatedBy: .newlines)
        guard let headerLine = lines.first else {
            throw ParseError.emptyFile
        }
        
        let headers = headerLine.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        var targets: [PhishingTarget] = []
        
        for (index, line) in lines.dropFirst().enumerated() where !line.isEmpty {
            let values = line.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            
            guard values.count == headers.count else {
                throw ParseError.invalidRow(index + 1)
            }
            
            var customFields: [String: String] = [:]
            var email = ""
            var firstName = ""
            var lastName = ""
            var department: String?
            var position: String?
            
            for (header, value) in zip(headers, values) {
                switch header.lowercased() {
                case "email", "e-mail", "emailaddress":
                    email = value
                case "firstname", "first name", "first":
                    firstName = value
                case "lastname", "last name", "last":
                    lastName = value
                case "department", "dept":
                    department = value
                case "position", "title", "jobtitle":
                    position = value
                default:
                    customFields[header] = value
                }
            }
            
            guard !email.isEmpty else {
                throw ParseError.missingEmail(index + 1)
            }
            
            let target = PhishingTarget(
                email: email,
                firstName: firstName,
                lastName: lastName,
                department: department,
                position: position,
                customFields: customFields,
                status: .pending,
                emailSentAt: nil,
                emailOpenedAt: nil,
                linkClickedAt: nil,
                credentialsSubmittedAt: nil,
                reportedAsPhishingAt: nil,
                interactions: []
            )
            
            targets.append(target)
        }
        
        return targets
    }
    
    enum ParseError: LocalizedError {
        case emptyFile
        case invalidRow(Int)
        case missingEmail(Int)
        
        var errorDescription: String? {
            switch self {
            case .emptyFile:
                return "CSV file is empty"
            case .invalidRow(let row):
                return "Invalid data at row \(row)"
            case .missingEmail(let row):
                return "Missing email address at row \(row)"
            }
        }
    }
}

// MARK: - Default Templates

struct DefaultTemplates {
    static let emailTemplates: [EmailTemplate] = [
        EmailTemplate(
            name: "IT Security Update",
            subject: "Urgent: Security Update Required",
            senderName: "IT Department",
            senderEmail: "it-security@company.com",
            replyTo: nil,
            htmlContent: """
            <html>
            <body style="font-family: Arial, sans-serif;">
                <h2>Security Update Required</h2>
                <p>Dear {{firstName}},</p>
                <p>Our security team has detected unusual activity on your account. Please verify your credentials immediately to prevent account suspension.</p>
                <p><a href="{{link}}" style="background-color: #0066cc; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">Verify Account</a></p>
                <p>This link will expire in 24 hours.</p>
                <p>Best regards,<br>IT Security Team</p>
            </body>
            </html>
            """,
            textContent: "Security Update Required. Please verify your account.",
            attachments: [],
            trackingEnabled: true,
            category: .security,
            difficulty: .medium,
            tags: ["it", "security", "urgent"]
        ),
        
        EmailTemplate(
            name: "Password Expiration",
            subject: "Your password will expire in 3 days",
            senderName: "Password Manager",
            senderEmail: "noreply@company.com",
            replyTo: nil,
            htmlContent: """
            <html>
            <body>
                <p>Hello {{firstName}},</p>
                <p>Your password for {{email}} will expire in 3 days.</p>
                <p>Click here to reset your password: <a href="{{link}}">Reset Password</a></p>
                <p>If you have any questions, please contact IT support.</p>
            </body>
            </html>
            """,
            textContent: "Your password will expire soon. Please reset it.",
            attachments: [],
            trackingEnabled: true,
            category: .password,
            difficulty: .easy,
            tags: ["password", "expiration"]
        )
    ]
    
    static let landingPageTemplates: [LandingPageTemplate] = [
        LandingPageTemplate(
            name: "Corporate Login Page",
            url: "/login",
            htmlContent: """
            <!DOCTYPE html>
            <html>
            <head>
                <title>Company Login</title>
                <link rel="stylesheet" href="styles.css">
            </head>
            <body>
                <div class="login-container">
                    <img src="logo.png" alt="Company Logo">
                    <h2>Sign In</h2>
                    <form id="loginForm">
                        <input type="email" name="email" placeholder="Email" required>
                        <input type="password" name="password" placeholder="Password" required>
                        <button type="submit">Sign In</button>
                    </form>
                    <p><a href="#">Forgot password?</a></p>
                </div>
                <script src="script.js"></script>
            </body>
            </html>
            """,
            cssContent: """
            body {
                font-family: Arial, sans-serif;
                background-color: #f0f0f0;
                display: flex;
                justify-content: center;
                align-items: center;
                height: 100vh;
                margin: 0;
            }
            .login-container {
                background: white;
                padding: 40px;
                border-radius: 8px;
                box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                width: 300px;
            }
            """,
            jsContent: """
            document.getElementById('loginForm').addEventListener('submit', function(e) {
                e.preventDefault();
                // Capture credentials
                const formData = new FormData(e.target);
                const data = Object.fromEntries(formData);
                
                // Send to tracking server
                fetch('/track', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify(data)
                });
                
                // Redirect
                setTimeout(() => {
                    window.location.href = 'https://company.com';
                }, 1000);
            });
            """,
            captureCredentials: true,
            redirectUrl: "https://company.com",
            customFields: [],
            pageType: .login
        )
    ]
}

// MARK: - Error Types

enum CampaignError: LocalizedError {
    case campaignNotFound
    case invalidStatus
    case noTargets
    case smtpConnectionFailed
    case templateNotFound
    
    var errorDescription: String? {
        switch self {
        case .campaignNotFound:
            return "Campaign not found"
        case .invalidStatus:
            return "Campaign is not in the correct status for this operation"
        case .noTargets:
            return "Campaign has no targets"
        case .smtpConnectionFailed:
            return "Failed to connect to SMTP server"
        case .templateNotFound:
            return "Email or landing page template not found"
        }
    }
}

// MARK: - Extensions

extension CampaignSchedule.Weekday {
    static func from(weekday: Int) -> Weekday? {
        switch weekday {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return nil
        }
    }
}