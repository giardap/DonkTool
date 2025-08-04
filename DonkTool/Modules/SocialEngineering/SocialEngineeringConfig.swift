//
//  SocialEngineeringConfig.swift
//  DonkTool
//
//  Configuration management for social engineering settings
//

import Foundation
import SwiftUI

// MARK: - Configuration Manager

@Observable
@MainActor
class SocialEngineeringConfigManager {
    var smtpProfiles: [SMTPProfile] = []
    var trackingSettings = TrackingSettings()
    var generalSettings = GeneralSettings()
    var notificationSettings = SENotificationSettings()
    
    private let dataStore = SecureConfigurationDataStore()
    
    init() {
        loadConfiguration()
    }
    
    // MARK: - SMTP Profile Management
    
    func createSMTPProfile(_ profile: SMTPProfile) {
        smtpProfiles.append(profile)
        saveConfiguration()
    }
    
    func updateSMTPProfile(_ profile: SMTPProfile) {
        if let index = smtpProfiles.firstIndex(where: { $0.id == profile.id }) {
            smtpProfiles[index] = profile
            saveConfiguration()
        }
    }
    
    func deleteSMTPProfile(_ profileId: UUID) {
        smtpProfiles.removeAll { $0.id == profileId }
        saveConfiguration()
    }
    
    func testSMTPProfile(_ profile: SMTPProfile) async throws -> Bool {
        let smtpManager = SMTPManager()
        let sendingProfile = SendingProfile(
            name: profile.name,
            smtpHost: profile.host,
            smtpPort: profile.port,
            username: profile.username,
            password: profile.password,
            useTLS: profile.useTLS,
            useStartTLS: profile.useStartTLS,
            sendRate: profile.sendRate
        )
        
        try smtpManager.testConnection(profile: sendingProfile)
        return true
    }
    
    // MARK: - Settings Management
    
    func updateTrackingSettings(_ settings: TrackingSettings) {
        trackingSettings = settings
        saveConfiguration()
    }
    
    func updateGeneralSettings(_ settings: GeneralSettings) {
        generalSettings = settings
        saveConfiguration()
    }
    
    func updateNotificationSettings(_ settings: SENotificationSettings) {
        notificationSettings = settings
        saveConfiguration()
    }
    
    // MARK: - Configuration Validation
    
    func validateConfiguration() -> [ConfigurationIssue] {
        var issues: [ConfigurationIssue] = []
        
        // Validate SMTP profiles
        for profile in smtpProfiles {
            if profile.host.isEmpty {
                issues.append(ConfigurationIssue(
                    type: .smtp,
                    severity: .error,
                    message: "SMTP profile '\(profile.name)' has empty host",
                    profileId: profile.id
                ))
            }
            
            if profile.username.isEmpty {
                issues.append(ConfigurationIssue(
                    type: .smtp,
                    severity: .warning,
                    message: "SMTP profile '\(profile.name)' has empty username",
                    profileId: profile.id
                ))
            }
            
            if profile.port < 1 || profile.port > 65535 {
                issues.append(ConfigurationIssue(
                    type: .smtp,
                    severity: .error,
                    message: "SMTP profile '\(profile.name)' has invalid port: \(profile.port)",
                    profileId: profile.id
                ))
            }
        }
        
        // Validate tracking settings
        if trackingSettings.trackingDomain.isEmpty {
            issues.append(ConfigurationIssue(
                type: .tracking,
                severity: .error,
                message: "Tracking domain is required",
                profileId: nil
            ))
        }
        
        if trackingSettings.landingPageDomain.isEmpty {
            issues.append(ConfigurationIssue(
                type: .tracking,
                severity: .error,
                message: "Landing page domain is required",
                profileId: nil
            ))
        }
        
        return issues
    }
    
    // MARK: - Data Persistence
    
    private func loadConfiguration() {
        let config = dataStore.loadConfiguration()
        self.smtpProfiles = config.smtpProfiles
        self.trackingSettings = config.trackingSettings
        self.generalSettings = config.generalSettings
        self.notificationSettings = config.notificationSettings
    }
    
    private func saveConfiguration() {
        let config = SocialEngineeringConfiguration(
            smtpProfiles: smtpProfiles,
            trackingSettings: trackingSettings,
            generalSettings: generalSettings,
            notificationSettings: notificationSettings
        )
        dataStore.saveConfiguration(config)
    }
    
    // MARK: - Reset Configuration
    
    func resetToDefaults() {
        smtpProfiles = []
        trackingSettings = TrackingSettings()
        generalSettings = GeneralSettings()
        notificationSettings = SENotificationSettings()
        saveConfiguration()
    }
    
    func exportConfiguration() -> Data? {
        let config = SocialEngineeringConfiguration(
            smtpProfiles: smtpProfiles,
            trackingSettings: trackingSettings,
            generalSettings: generalSettings,
            notificationSettings: notificationSettings
        )
        return try? JSONEncoder().encode(config)
    }
    
    func importConfiguration(_ data: Data) throws {
        let config = try JSONDecoder().decode(SocialEngineeringConfiguration.self, from: data)
        self.smtpProfiles = config.smtpProfiles
        self.trackingSettings = config.trackingSettings
        self.generalSettings = config.generalSettings
        self.notificationSettings = config.notificationSettings
        saveConfiguration()
    }
}

// MARK: - Configuration Data Models

struct SocialEngineeringConfiguration: Codable {
    let smtpProfiles: [SMTPProfile]
    let trackingSettings: TrackingSettings
    let generalSettings: GeneralSettings
    let notificationSettings: SENotificationSettings
}

struct SMTPProfile: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var host: String
    var port: Int
    var username: String
    var password: String
    var useTLS: Bool
    var useStartTLS: Bool
    var sendRate: Int // emails per hour
    var maxConnections: Int
    var connectionTimeout: TimeInterval
    var isDefault: Bool
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SMTPProfile, rhs: SMTPProfile) -> Bool {
        return lhs.id == rhs.id
    }
    
    init(
        id: UUID = UUID(),
        name: String = "",
        host: String = "",
        port: Int = 587,
        username: String = "",
        password: String = "",
        useTLS: Bool = true,
        useStartTLS: Bool = true,
        sendRate: Int = 100,
        maxConnections: Int = 5,
        connectionTimeout: TimeInterval = 30,
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.useTLS = useTLS
        self.useStartTLS = useStartTLS
        self.sendRate = sendRate
        self.maxConnections = maxConnections
        self.connectionTimeout = connectionTimeout
        self.isDefault = isDefault
    }
}

struct TrackingSettings: Codable, Equatable {
    var trackingDomain: String
    var landingPageDomain: String
    var useHTTPS: Bool
    var trackingPort: Int
    var enablePixelTracking: Bool
    var enableLinkTracking: Bool
    var enableGeolocation: Bool
    var anonymizeIPs: Bool
    var cookieSettings: CookieSettings
    var dataRetentionDays: Int
    
    init() {
        self.trackingDomain = "tracking.donktool.local"
        self.landingPageDomain = "secure.donktool.local"
        self.useHTTPS = true
        self.trackingPort = 8443
        self.enablePixelTracking = true
        self.enableLinkTracking = true
        self.enableGeolocation = false
        self.anonymizeIPs = true
        self.cookieSettings = CookieSettings()
        self.dataRetentionDays = 90
    }
}

struct CookieSettings: Codable, Equatable {
    var enableCookies: Bool
    var cookieDomain: String
    var cookieSecure: Bool
    var cookieHttpOnly: Bool
    var cookieExpirationDays: Int
    
    init() {
        self.enableCookies = true
        self.cookieDomain = ".donktool.local"
        self.cookieSecure = true
        self.cookieHttpOnly = true
        self.cookieExpirationDays = 30
    }
}

struct GeneralSettings: Codable, Equatable {
    var defaultCampaignDuration: Int // days
    var maxTargetsPerCampaign: Int
    var enableTemplateValidation: Bool
    var requireApprovalForLaunch: Bool
    var enableAuditLogging: Bool
    var auditLogRetentionDays: Int
    var enableDataEncryption: Bool
    var autoBackupEnabled: Bool
    var backupRetentionDays: Int
    
    init() {
        self.defaultCampaignDuration = 30
        self.maxTargetsPerCampaign = 10000
        self.enableTemplateValidation = true
        self.requireApprovalForLaunch = false
        self.enableAuditLogging = true
        self.auditLogRetentionDays = 365
        self.enableDataEncryption = true
        self.autoBackupEnabled = true
        self.backupRetentionDays = 30
    }
}

struct SENotificationSettings: Codable, Equatable {
    var enableEmailNotifications: Bool
    var enablePushNotifications: Bool
    var notifyOnCampaignStart: Bool
    var notifyOnCampaignComplete: Bool
    var notifyOnCredentialSubmission: Bool
    var notifyOnPhishingReport: Bool
    var notifyOnHighRiskActivity: Bool
    var riskThreshold: Double
    var notificationEmail: String
    var webhookUrl: String?
    var slackWebhookUrl: String?
    
    init() {
        self.enableEmailNotifications = true
        self.enablePushNotifications = false
        self.notifyOnCampaignStart = true
        self.notifyOnCampaignComplete = true
        self.notifyOnCredentialSubmission = true
        self.notifyOnPhishingReport = true
        self.notifyOnHighRiskActivity = true
        self.riskThreshold = 50.0
        self.notificationEmail = ""
        self.webhookUrl = nil
        self.slackWebhookUrl = nil
    }
}

// MARK: - Configuration Issues

struct ConfigurationIssue: Identifiable {
    let id = UUID()
    let type: IssueType
    let severity: IssueSeverity
    let message: String
    let profileId: UUID?
    
    enum IssueType: String, CaseIterable {
        case smtp = "SMTP"
        case tracking = "Tracking"
        case general = "General"
        case notifications = "Notifications"
        case security = "Security"
    }
    
    enum IssueSeverity: String, CaseIterable {
        case error = "Error"
        case warning = "Warning"
        case info = "Info"
        
        var color: Color {
            switch self {
            case .error: return .red
            case .warning: return .orange
            case .info: return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .error: return "exclamationmark.triangle.fill"
            case .warning: return "exclamationmark.triangle"
            case .info: return "info.circle"
            }
        }
    }
}

// MARK: - Secure Configuration Data Store

class SecureConfigurationDataStore {
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private let configurationFileName = "se_configuration_encrypted.data"
    
    func loadConfiguration() -> SocialEngineeringConfiguration {
        do {
            let url = documentsDirectory.appendingPathComponent(configurationFileName)
            let encryptedData = try Data(contentsOf: url)
            let data = try CredentialEncryption.decrypt(encryptedData)
            let config = try JSONDecoder().decode(SocialEngineeringConfiguration.self, from: data)
            return config
        } catch {
            print("Failed to load encrypted configuration: \(error)")
            return createDefaultConfiguration()
        }
    }
    
    func saveConfiguration(_ configuration: SocialEngineeringConfiguration) {
        do {
            let data = try JSONEncoder().encode(configuration)
            let encryptedData = try CredentialEncryption.encrypt(data)
            
            let url = documentsDirectory.appendingPathComponent(configurationFileName)
            try encryptedData.write(to: url)
        } catch {
            print("Failed to save encrypted configuration: \(error)")
        }
    }
    
    private func createDefaultConfiguration() -> SocialEngineeringConfiguration {
        return SocialEngineeringConfiguration(
            smtpProfiles: [],
            trackingSettings: TrackingSettings(),
            generalSettings: GeneralSettings(),
            notificationSettings: SENotificationSettings()
        )
    }
}

// MARK: - Configuration Presets

struct ConfigurationPresets {
    
    static let awsSESProfile = SMTPProfile(
        name: "Amazon SES",
        host: "email-smtp.us-east-1.amazonaws.com",
        port: 587,
        username: "",
        password: "",
        useTLS: false,
        useStartTLS: true,
        sendRate: 200,
        maxConnections: 10,
        connectionTimeout: 30,
        isDefault: false
    )
    
    static let gmailProfile = SMTPProfile(
        name: "Gmail SMTP",
        host: "smtp.gmail.com",
        port: 587,
        username: "",
        password: "",
        useTLS: false,
        useStartTLS: true,
        sendRate: 100,
        maxConnections: 5,
        connectionTimeout: 30,
        isDefault: false
    )
    
    static let outlook365Profile = SMTPProfile(
        name: "Office 365",
        host: "smtp.office365.com",
        port: 587,
        username: "",
        password: "",
        useTLS: false,
        useStartTLS: true,
        sendRate: 150,
        maxConnections: 8,
        connectionTimeout: 30,
        isDefault: false
    )
    
    static let sendGridProfile = SMTPProfile(
        name: "SendGrid",
        host: "smtp.sendgrid.net",
        port: 587,
        username: "apikey",
        password: "",
        useTLS: false,
        useStartTLS: true,
        sendRate: 300,
        maxConnections: 15,
        connectionTimeout: 30,
        isDefault: false
    )
    
    static let mailgunProfile = SMTPProfile(
        name: "Mailgun",
        host: "smtp.mailgun.org",
        port: 587,
        username: "",
        password: "",
        useTLS: false,
        useStartTLS: true,
        sendRate: 250,
        maxConnections: 12,
        connectionTimeout: 30,
        isDefault: false
    )
    
    static let allPresets: [SMTPProfile] = [
        awsSESProfile,
        gmailProfile,
        outlook365Profile,
        sendGridProfile,
        mailgunProfile
    ]
    
    static func getPreset(named name: String) -> SMTPProfile? {
        return allPresets.first { $0.name == name }
    }
}

// MARK: - Configuration Validation Extensions

extension SMTPProfile {
    var isValid: Bool {
        return !host.isEmpty && !username.isEmpty && port > 0 && port <= 65535
    }
    
    var validationIssues: [String] {
        var issues: [String] = []
        
        if host.isEmpty {
            issues.append("Host is required")
        }
        
        if username.isEmpty {
            issues.append("Username is required")
        }
        
        if password.isEmpty {
            issues.append("Password is required")
        }
        
        if port < 1 || port > 65535 {
            issues.append("Port must be between 1 and 65535")
        }
        
        if sendRate < 1 {
            issues.append("Send rate must be at least 1 email per hour")
        }
        
        if maxConnections < 1 || maxConnections > 50 {
            issues.append("Max connections must be between 1 and 50")
        }
        
        return issues
    }
}

extension TrackingSettings {
    var isValid: Bool {
        return !trackingDomain.isEmpty && !landingPageDomain.isEmpty && trackingPort > 0
    }
    
    var validationIssues: [String] {
        var issues: [String] = []
        
        if trackingDomain.isEmpty {
            issues.append("Tracking domain is required")
        }
        
        if landingPageDomain.isEmpty {
            issues.append("Landing page domain is required")
        }
        
        if trackingPort < 1 || trackingPort > 65535 {
            issues.append("Tracking port must be between 1 and 65535")
        }
        
        if dataRetentionDays < 1 {
            issues.append("Data retention must be at least 1 day")
        }
        
        return issues
    }
}

// MARK: - Configuration Export/Import Utilities

struct ConfigurationExporter {
    static func exportToJSON(_ configuration: SocialEngineeringConfiguration) -> String? {
        guard let data = try? JSONEncoder().encode(configuration) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    static func importFromJSON(_ jsonString: String) throws -> SocialEngineeringConfiguration {
        guard let data = jsonString.data(using: .utf8) else {
            throw ConfigurationError.invalidJSON
        }
        
        return try JSONDecoder().decode(SocialEngineeringConfiguration.self, from: data)
    }
    
    static func exportToFile(_ configuration: SocialEngineeringConfiguration, url: URL) throws {
        let data = try JSONEncoder().encode(configuration)
        try data.write(to: url)
    }
    
    static func importFromFile(url: URL) throws -> SocialEngineeringConfiguration {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(SocialEngineeringConfiguration.self, from: data)
    }
}

enum ConfigurationError: LocalizedError {
    case invalidJSON
    case fileNotFound
    case encryptionFailed
    case decryptionFailed
    case validationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidJSON:
            return "Invalid JSON format"
        case .fileNotFound:
            return "Configuration file not found"
        case .encryptionFailed:
            return "Failed to encrypt configuration data"
        case .decryptionFailed:
            return "Failed to decrypt configuration data"
        case .validationFailed(let message):
            return "Configuration validation failed: \(message)"
        }
    }
}