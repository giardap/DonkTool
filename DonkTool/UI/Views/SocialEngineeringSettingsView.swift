//
//  SocialEngineeringSettingsView.swift
//  DonkTool
//
//  Configuration and settings management for social engineering
//

import SwiftUI

struct SocialEngineeringSettingsView: View {
    @State private var configManager = SocialEngineeringConfigManager()
    @State private var selectedTab: SettingsTab = .smtp
    @State private var showingNewSMTPProfile = false
    @State private var showingConfigValidation = false
    @State private var showingImportExport = false
    @State private var validationIssues: [ConfigurationIssue] = []
    
    enum SettingsTab: String, CaseIterable {
        case smtp = "SMTP Profiles"
        case tracking = "Tracking Settings"
        case general = "General Settings"
        case notifications = "Notifications"
        case security = "Security"
        
        var icon: String {
            switch self {
            case .smtp: return "envelope.circle"
            case .tracking: return "antenna.radiowaves.left.and.right"
            case .general: return "gear"
            case .notifications: return "bell"
            case .security: return "shield"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            // Settings Sidebar
            List(SettingsTab.allCases, id: \.self, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
                    .tag(tab)
            }
            .navigationTitle("Settings")
            .listStyle(.sidebar)
            .frame(minWidth: 200)
        } detail: {
            // Settings Detail View
            Group {
                switch selectedTab {
                case .smtp:
                    SMTPProfilesView(configManager: configManager)
                case .tracking:
                    TrackingSettingsView(configManager: configManager)
                case .general:
                    GeneralSettingsView(configManager: configManager)
                case .notifications:
                    NotificationSettingsView(configManager: configManager)
                case .security:
                    SecuritySettingsView(configManager: configManager)
                }
            }
            .navigationTitle(selectedTab.rawValue)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("Validate Config") {
                        validateConfiguration()
                    }
                    
                    Button("Import/Export") {
                        showingImportExport = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingConfigValidation) {
            ConfigurationValidationView(issues: validationIssues)
        }
        .sheet(isPresented: $showingImportExport) {
            ImportExportView(configManager: configManager)
        }
    }
    
    private func validateConfiguration() {
        validationIssues = configManager.validateConfiguration()
        showingConfigValidation = true
    }
}

// MARK: - SMTP Profiles View

struct SMTPProfilesView: View {
    let configManager: SocialEngineeringConfigManager
    @State private var showingNewProfile = false
    @State private var selectedProfile: SMTPProfile?
    @State private var showingProfileEditor = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text("SMTP Profiles")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Menu("Add Profile") {
                    Button("New Profile") {
                        selectedProfile = SMTPProfile()
                        showingProfileEditor = true
                    }
                    
                    Divider()
                    
                    ForEach(ConfigurationPresets.allPresets, id: \.name) { preset in
                        Button(preset.name) {
                            selectedProfile = preset
                            showingProfileEditor = true
                        }
                    }
                }
                .menuStyle(.borderedButton)
            }
            
            // Profiles List
            if configManager.smtpProfiles.isEmpty {
                EmptyProfilesView()
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(configManager.smtpProfiles) { profile in
                        SMTPProfileCard(
                            profile: profile,
                            configManager: configManager,
                            onEdit: {
                                selectedProfile = profile
                                showingProfileEditor = true
                            }
                        )
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingProfileEditor) {
            if let profile = selectedProfile {
                SMTPProfileEditorView(
                    profile: profile,
                    configManager: configManager,
                    isPresented: $showingProfileEditor
                )
            }
        }
    }
}

struct SMTPProfileCard: View {
    let profile: SMTPProfile
    let configManager: SocialEngineeringConfigManager
    let onEdit: () -> Void
    @State private var isTestingConnection = false
    @State private var testResult: TestResult?
    
    enum TestResult {
        case success
        case failure(String)
        
        var color: Color {
            switch self {
            case .success: return .green
            case .failure: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .failure: return "xmark.circle.fill"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(profile.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                if profile.isDefault {
                    Text("DEFAULT")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Host: \(profile.host)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Port: \(profile.port)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Rate: \(profile.sendRate) emails/hour")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Button("Test Connection") {
                    testConnection()
                }
                .buttonStyle(.bordered)
                .disabled(isTestingConnection)
                
                if isTestingConnection {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                
                if let result = testResult {
                    Image(systemName: result.icon)
                        .foregroundColor(result.color)
                }
                
                Spacer()
                
                Menu {
                    Button("Edit") {
                        onEdit()
                    }
                    
                    Button("Duplicate") {
                        var newProfile = profile
                        newProfile.name = "\(profile.name) Copy"
                        newProfile.isDefault = false
                        configManager.createSMTPProfile(newProfile)
                    }
                    
                    if !profile.isDefault {
                        Button("Set as Default") {
                            var updatedProfile = profile
                            updatedProfile.isDefault = true
                            
                            // Remove default from other profiles
                            for otherProfile in configManager.smtpProfiles {
                                if otherProfile.id != profile.id && otherProfile.isDefault {
                                    var otherUpdated = otherProfile
                                    otherUpdated.isDefault = false
                                    configManager.updateSMTPProfile(otherUpdated)
                                }
                            }
                            
                            configManager.updateSMTPProfile(updatedProfile)
                        }
                    }
                    
                    Divider()
                    
                    Button("Delete", role: .destructive) {
                        configManager.deleteSMTPProfile(profile.id)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .menuStyle(.borderlessButton)
            }
        }
        .padding()
        .background(Color(NSColor.systemGray))
        .cornerRadius(12)
    }
    
    private func testConnection() {
        isTestingConnection = true
        testResult = nil
        
        Task {
            do {
                let success = try await configManager.testSMTPProfile(profile)
                await MainActor.run {
                    testResult = success ? .success : .failure("Connection failed")
                    isTestingConnection = false
                }
            } catch {
                await MainActor.run {
                    testResult = .failure(error.localizedDescription)
                    isTestingConnection = false
                }
            }
        }
    }
}

struct SMTPProfileEditorView: View {
    @State private var profile: SMTPProfile
    let configManager: SocialEngineeringConfigManager
    @Binding var isPresented: Bool
    @State private var isEditing: Bool
    
    init(profile: SMTPProfile, configManager: SocialEngineeringConfigManager, isPresented: Binding<Bool>) {
        self._profile = State(initialValue: profile)
        self.configManager = configManager
        self._isPresented = isPresented
        self.isEditing = configManager.smtpProfiles.contains { $0.id == profile.id }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Configuration") {
                    TextField("Profile Name", text: $profile.name)
                    TextField("SMTP Host", text: $profile.host)
                    TextField("Port", value: $profile.port, format: .number)
                    TextField("Username", text: $profile.username)
                    SecureField("Password", text: $profile.password)
                }
                
                Section("Security Settings") {
                    Toggle("Use TLS", isOn: $profile.useTLS)
                    Toggle("Use STARTTLS", isOn: $profile.useStartTLS)
                    Toggle("Set as Default", isOn: $profile.isDefault)
                }
                
                Section("Performance Settings") {
                    HStack {
                        Text("Send Rate:")
                        Spacer()
                        TextField("Rate", value: $profile.sendRate, format: .number)
                            .frame(width: 80)
                        Text("emails/hour")
                    }
                    
                    HStack {
                        Text("Max Connections:")
                        Spacer()
                        TextField("Connections", value: $profile.maxConnections, format: .number)
                            .frame(width: 80)
                    }
                    
                    HStack {
                        Text("Connection Timeout:")
                        Spacer()
                        TextField("Timeout", value: $profile.connectionTimeout, format: .number)
                            .frame(width: 80)
                        Text("seconds")
                    }
                }
                
                Section("Validation") {
                    if !profile.validationIssues.isEmpty {
                        ForEach(profile.validationIssues, id: \.self) { issue in
                            Label(issue, systemImage: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                        }
                    } else {
                        Label("Configuration is valid", systemImage: "checkmark.circle")
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit SMTP Profile" : "New SMTP Profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(!profile.isValid)
                }
            }
        }
    }
    
    private func saveProfile() {
        if isEditing {
            configManager.updateSMTPProfile(profile)
        } else {
            configManager.createSMTPProfile(profile)
        }
        isPresented = false
    }
}

struct EmptyProfilesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "envelope.circle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No SMTP Profiles")
                .font(.headline)
            
            Text("Add an SMTP profile to start sending phishing emails")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Tracking Settings View

struct TrackingSettingsView: View {
    let configManager: SocialEngineeringConfigManager
    @State private var settings: TrackingSettings
    
    init(configManager: SocialEngineeringConfigManager) {
        self.configManager = configManager
        self._settings = State(initialValue: configManager.trackingSettings)
    }
    
    var body: some View {
        Form {
            Section("Domain Configuration") {
                TextField("Tracking Domain", text: $settings.trackingDomain)
                TextField("Landing Page Domain", text: $settings.landingPageDomain)
                Toggle("Use HTTPS", isOn: $settings.useHTTPS)
                HStack {
                    Text("Tracking Port:")
                    Spacer()
                    TextField("Port", value: $settings.trackingPort, format: .number)
                        .frame(width: 80)
                }
            }
            
            Section("Tracking Features") {
                Toggle("Enable Pixel Tracking", isOn: $settings.enablePixelTracking)
                Toggle("Enable Link Tracking", isOn: $settings.enableLinkTracking)
                Toggle("Enable Geolocation", isOn: $settings.enableGeolocation)
                Toggle("Anonymize IP Addresses", isOn: $settings.anonymizeIPs)
            }
            
            Section("Cookie Settings") {
                Toggle("Enable Cookies", isOn: $settings.cookieSettings.enableCookies)
                TextField("Cookie Domain", text: $settings.cookieSettings.cookieDomain)
                Toggle("Secure Cookies", isOn: $settings.cookieSettings.cookieSecure)
                Toggle("HTTP-Only Cookies", isOn: $settings.cookieSettings.cookieHttpOnly)
                HStack {
                    Text("Cookie Expiration:")
                    Spacer()
                    TextField("Days", value: $settings.cookieSettings.cookieExpirationDays, format: .number)
                        .frame(width: 80)
                    Text("days")
                }
            }
            
            Section("Data Retention") {
                HStack {
                    Text("Data Retention Period:")
                    Spacer()
                    TextField("Days", value: $settings.dataRetentionDays, format: .number)
                        .frame(width: 80)
                    Text("days")
                }
            }
        }
        .navigationTitle("Tracking Settings")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    configManager.updateTrackingSettings(settings)
                }
            }
        }
        .onChange(of: settings) { _, newValue in
            configManager.updateTrackingSettings(newValue)
        }
    }
}

// MARK: - General Settings View

struct GeneralSettingsView: View {
    let configManager: SocialEngineeringConfigManager
    @State private var settings: GeneralSettings
    
    init(configManager: SocialEngineeringConfigManager) {
        self.configManager = configManager
        self._settings = State(initialValue: configManager.generalSettings)
    }
    
    var body: some View {
        Form {
            Section("Campaign Defaults") {
                HStack {
                    Text("Default Campaign Duration:")
                    Spacer()
                    TextField("Days", value: $settings.defaultCampaignDuration, format: .number)
                        .frame(width: 80)
                    Text("days")
                }
                
                HStack {
                    Text("Max Targets per Campaign:")
                    Spacer()
                    TextField("Count", value: $settings.maxTargetsPerCampaign, format: .number)
                        .frame(width: 100)
                }
            }
            
            Section("Validation & Approval") {
                Toggle("Enable Template Validation", isOn: $settings.enableTemplateValidation)
                Toggle("Require Approval for Launch", isOn: $settings.requireApprovalForLaunch)
                Toggle("Enable Audit Logging", isOn: $settings.enableAuditLogging)
                
                if settings.enableAuditLogging {
                    HStack {
                        Text("Audit Log Retention:")
                        Spacer()
                        TextField("Days", value: $settings.auditLogRetentionDays, format: .number)
                            .frame(width: 80)
                        Text("days")
                    }
                }
            }
            
            Section("Data Management") {
                Toggle("Enable Data Encryption", isOn: $settings.enableDataEncryption)
                Toggle("Auto Backup Enabled", isOn: $settings.autoBackupEnabled)
                
                if settings.autoBackupEnabled {
                    HStack {
                        Text("Backup Retention:")
                        Spacer()
                        TextField("Days", value: $settings.backupRetentionDays, format: .number)
                            .frame(width: 80)
                        Text("days")
                    }
                }
            }
        }
        .navigationTitle("General Settings")
        .onChange(of: settings) { _, newValue in
            configManager.updateGeneralSettings(newValue)
        }
    }
}

// MARK: - Notification Settings View

struct NotificationSettingsView: View {
    let configManager: SocialEngineeringConfigManager
    @State private var settings: SENotificationSettings
    
    init(configManager: SocialEngineeringConfigManager) {
        self.configManager = configManager
        self._settings = State(initialValue: configManager.notificationSettings)
    }
    
    var body: some View {
        Form {
            Section("Notification Types") {
                Toggle("Email Notifications", isOn: $settings.enableEmailNotifications)
                Toggle("Push Notifications", isOn: $settings.enablePushNotifications)
            }
            
            Section("Campaign Events") {
                Toggle("Campaign Start", isOn: $settings.notifyOnCampaignStart)
                Toggle("Campaign Complete", isOn: $settings.notifyOnCampaignComplete)
                Toggle("Credential Submission", isOn: $settings.notifyOnCredentialSubmission)
                Toggle("Phishing Report", isOn: $settings.notifyOnPhishingReport)
                Toggle("High Risk Activity", isOn: $settings.notifyOnHighRiskActivity)
                
                if settings.notifyOnHighRiskActivity {
                    HStack {
                        Text("Risk Threshold:")
                        Spacer()
                        TextField("Threshold", value: $settings.riskThreshold, format: .number)
                            .frame(width: 80)
                        Text("%")
                    }
                }
            }
            
            Section("Delivery Settings") {
                TextField("Notification Email", text: $settings.notificationEmail)
                    .textContentType(.emailAddress)
                
                TextField("Webhook URL (Optional)", text: Binding(
                    get: { settings.webhookUrl ?? "" },
                    set: { settings.webhookUrl = $0.isEmpty ? nil : $0 }
                ))
                
                TextField("Slack Webhook URL (Optional)", text: Binding(
                    get: { settings.slackWebhookUrl ?? "" },
                    set: { settings.slackWebhookUrl = $0.isEmpty ? nil : $0 }
                ))
            }
        }
        .navigationTitle("Notifications")
        .onChange(of: settings) { _, newValue in
            configManager.updateNotificationSettings(newValue)
        }
    }
}

// MARK: - Security Settings View

struct SecuritySettingsView: View {
    let configManager: SocialEngineeringConfigManager
    @State private var showingResetConfirmation = false
    
    var body: some View {
        Form {
            Section("Data Protection") {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Encryption Status")
                            .font(.headline)
                        Text("All sensitive data is encrypted using AES-256-GCM")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "lock.fill")
                        .foregroundColor(.green)
                }
            }
            
            Section("Configuration Management") {
                Button("Reset to Defaults") {
                    showingResetConfirmation = true
                }
                .foregroundColor(.orange)
                
                Button("Clear All Data", role: .destructive) {
                    // Implementation would go here
                }
            }
            
            Section("Security Information") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Security Features:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("• All SMTP credentials are encrypted at rest")
                    Text("• Campaign data is stored with AES-256 encryption")
                    Text("• Tracking data is anonymized by default")
                    Text("• Audit logs track all system activities")
                    Text("• Configuration files are encrypted")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Security")
        .alert("Reset Configuration", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                configManager.resetToDefaults()
            }
        } message: {
            Text("This will reset all settings to their default values. This action cannot be undone.")
        }
    }
}

// MARK: - Configuration Validation View

struct ConfigurationValidationView: View {
    let issues: [ConfigurationIssue]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                if issues.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.green)
                        
                        Text("Configuration Valid")
                            .font(.headline)
                        
                        Text("All settings are properly configured")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(issues) { issue in
                        HStack {
                            Image(systemName: issue.severity.icon)
                                .foregroundColor(issue.severity.color)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(issue.message)
                                    .font(.subheadline)
                                
                                Text("\(issue.type.rawValue) • \(issue.severity.rawValue)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Configuration Validation")
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

// MARK: - Import/Export View

struct ImportExportView: View {
    let configManager: SocialEngineeringConfigManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingExporter = false
    @State private var showingImporter = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                    
                    Text("Export Configuration")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Save your current settings to a file")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Export Settings") {
                        showingExporter = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Divider()
                
                VStack(spacing: 16) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                    
                    Text("Import Configuration")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Load settings from a file")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Import Settings") {
                        showingImporter = true
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Import/Export")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .fileExporter(
            isPresented: $showingExporter,
            document: ConfigurationDocument(configManager.exportConfiguration() ?? Data()),
            contentType: .json,
            defaultFilename: "se_configuration.json"
        ) { result in
            // Handle export result
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            // Handle import result
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    do {
                        let data = try Data(contentsOf: url)
                        try configManager.importConfiguration(data)
                    } catch {
                        print("Import failed: \(error)")
                    }
                }
            case .failure(let error):
                print("File selection failed: \(error)")
            }
        }
    }
}

// MARK: - Configuration Document

import UniformTypeIdentifiers

struct ConfigurationDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    var data: Data
    
    init(_ data: Data) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}

#Preview {
    SocialEngineeringSettingsView()
}