//
//  SocialEngineeringViews.swift
//  DonkTool
//
//  Social Engineering UI Components
//

import SwiftUI
import Charts
import WebKit

// MARK: - Main Social Engineering View

struct SocialEngineeringView: View {
    @Environment(AppState.self) private var appState
    @State private var socialManager = SocialEngineeringManager()
    @State private var selectedTab: Tab = .campaigns
    @State private var searchText = ""
    
    enum Tab: String, CaseIterable {
        case campaigns = "Campaigns"
        case templates = "Templates"
        case targets = "Targets"
        case analytics = "Analytics"
        case settings = "Settings"
        
        var icon: String {
            switch self {
            case .campaigns: return "envelope.badge"
            case .templates: return "doc.text"
            case .targets: return "person.3"
            case .analytics: return "chart.line.uptrend.xyaxis"
            case .settings: return "gearshape"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            SocialEngineeringHeader()
            
            // Tab bar
            HStack(spacing: 0) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    SocialEngineeringTabButton(
                        title: tab.rawValue,
                        icon: tab.icon,
                        isSelected: selectedTab == tab
                    ) {
                        selectedTab = tab
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Content
            Group {
                switch selectedTab {
                case .campaigns:
                    CampaignsView(socialManager: socialManager)
                case .templates:
                    TemplatesView(socialManager: socialManager)
                case .targets:
                    TargetsView(socialManager: socialManager)
                case .analytics:
                    AnalyticsView(socialManager: socialManager)
                case .settings:
                    SocialEngineeringSettingsView(socialManager: socialManager)
                }
            }
            .searchable(text: $searchText)
        }
        .navigationTitle("Social Engineering")
    }
}

struct SocialEngineeringHeader: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Social Engineering Framework")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Authorized phishing simulation and security awareness testing")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .foregroundColor(.orange)
                    
                    Text("Authorized Testing Only")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.red.opacity(0.05), .orange.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

// MARK: - Campaigns View

struct CampaignsView: View {
    var socialManager: SocialEngineeringManager
    @State private var showingNewCampaign = false
    @State private var selectedCampaign: PhishingCampaign?
    @State private var filterStatus: PhishingCampaign.CampaignStatus?
    
    var filteredCampaigns: [PhishingCampaign] {
        socialManager.campaigns.filter { campaign in
            filterStatus == nil || campaign.status == filterStatus
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                // Filter buttons
                HStack(spacing: 8) {
                    FilterButton(title: "All", isSelected: filterStatus == nil) {
                        filterStatus = nil
                    }
                    
                    ForEach(PhishingCampaign.CampaignStatus.allCases, id: \.self) { status in
                        FilterButton(
                            title: status.rawValue,
                            isSelected: filterStatus == status,
                            color: status.color
                        ) {
                            filterStatus = status
                        }
                    }
                }
                
                Spacer()
                
                Button(action: { showingNewCampaign = true }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("New Campaign")
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            Divider()
            
            // Campaign list
            if filteredCampaigns.isEmpty {
                EmptyCampaignsView(showingNewCampaign: $showingNewCampaign)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredCampaigns) { campaign in
                            CampaignCard(
                                campaign: campaign,
                                socialManager: socialManager
                            ) {
                                selectedCampaign = campaign
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingNewCampaign) {
            NewCampaignWizard(socialManager: socialManager)
        }
        .sheet(item: $selectedCampaign) { campaign in
            CampaignDetailView(campaign: campaign, socialManager: socialManager)
        }
    }
}

struct CampaignCard: View {
    let campaign: PhishingCampaign
    let socialManager: SocialEngineeringManager
    let onSelect: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(campaign.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(campaign.targetOrganization)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                CampaignStatusBadge(status: campaign.status)
            }
            
            // Description
            if !campaign.description.isEmpty {
                Text(campaign.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // Metrics
            HStack(spacing: 24) {
                MetricView(
                    title: "Targets",
                    value: "\(campaign.targets.count)",
                    icon: "person.3"
                )
                
                MetricView(
                    title: "Sent",
                    value: "\(campaign.metrics.emailsSent)",
                    icon: "envelope"
                )
                
                MetricView(
                    title: "Opened",
                    value: "\(campaign.metrics.emailsOpened)",
                    icon: "envelope.open"
                )
                
                MetricView(
                    title: "Clicked",
                    value: "\(campaign.metrics.linksClicked)",
                    icon: "link"
                )
                
                MetricView(
                    title: "Submitted",
                    value: "\(campaign.metrics.credentialsSubmitted)",
                    icon: "exclamationmark.triangle.fill",
                    color: .red
                )
            }
            
            Divider()
            
            // Actions
            HStack {
                Text("Created \(campaign.createdAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                CampaignActionButtons(
                    campaign: campaign,
                    socialManager: socialManager
                )
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHovering ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 2)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
        .onTapGesture {
            onSelect()
        }
    }
}

struct CampaignStatusBadge: View {
    let status: PhishingCampaign.CampaignStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.caption)
            
            Text(status.rawValue)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.2))
        .foregroundColor(status.color)
        .cornerRadius(6)
    }
}

struct MetricView: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = .primary
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct CampaignActionButtons: View {
    let campaign: PhishingCampaign
    let socialManager: SocialEngineeringManager
    
    var body: some View {
        HStack(spacing: 8) {
            switch campaign.status {
            case .draft:
                Button("Edit") {
                    // Edit campaign
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("Ready") {
                    // Mark as ready
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
            case .ready:
                Button("Launch") {
                    Task {
                        try? await socialManager.launchCampaign(campaign.id)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
            case .active:
                Button("Pause") {
                    socialManager.pauseCampaign(campaign.id)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .foregroundColor(.orange)
                
            case .paused:
                Button("Resume") {
                    Task {
                        try? await socialManager.resumeCampaign(campaign.id)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
            case .completed:
                Button("View Report") {
                    // Show report
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            Button("Details") {
                // Show details
            }
            .buttonStyle(.link)
            .controlSize(.small)
        }
    }
}

// MARK: - New Campaign Wizard

struct NewCampaignWizard: View {
    var socialManager: SocialEngineeringManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep = 1
    @State private var campaignName = ""
    @State private var campaignDescription = ""
    @State private var targetOrganization = ""
    @State private var selectedTemplate: EmailTemplate?
    @State private var selectedLandingPage: LandingPageTemplate?
    @State private var importedTargets: [PhishingTarget] = []
    @State private var selectedSendingProfile: SendingProfile?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                CampaignWizardProgress(currentStep: currentStep, totalSteps: 5)
                
                // Content
                Group {
                    switch currentStep {
                    case 1:
                        BasicInfoStep(
                            name: $campaignName,
                            description: $campaignDescription,
                            organization: $targetOrganization
                        )
                    case 2:
                        TemplateSelectionStep(
                            emailTemplates: socialManager.emailTemplates,
                            selectedTemplate: $selectedTemplate
                        )
                    case 3:
                        LandingPageSelectionStep(
                            landingPages: socialManager.landingPageTemplates,
                            selectedPage: $selectedLandingPage
                        )
                    case 4:
                        TargetImportStep(
                            targets: $importedTargets
                        )
                    case 5:
                        ReviewAndLaunchStep(
                            campaignName: campaignName,
                            targetCount: importedTargets.count,
                            template: selectedTemplate,
                            landingPage: selectedLandingPage
                        )
                    default:
                        EmptyView()
                    }
                }
                .frame(maxHeight: .infinity)
                
                Divider()
                
                // Navigation buttons
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    if currentStep > 1 {
                        Button("Previous") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    if currentStep < 5 {
                        Button("Next") {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!canProceed)
                    } else {
                        Button("Create Campaign") {
                            createCampaign()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            }
            .navigationTitle("New Phishing Campaign")
            .frame(width: 800, height: 600)
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 1: return !campaignName.isEmpty && !targetOrganization.isEmpty
        case 2: return selectedTemplate != nil
        case 3: return selectedLandingPage != nil
        case 4: return !importedTargets.isEmpty
        default: return true
        }
    }
    
    private func createCampaign() {
        let campaign = PhishingCampaign(
            name: campaignName,
            description: campaignDescription,
            targetOrganization: targetOrganization,
            status: .draft,
            createdAt: Date(),
            launchedAt: nil,
            completedAt: nil,
            targets: importedTargets,
            emailTemplate: selectedTemplate!,
            landingPage: selectedLandingPage!,
            metrics: CampaignMetrics(),
            settings: CampaignSettings(
                sendingProfile: selectedSendingProfile ?? SendingProfile(
                    name: "Default",
                    smtpHost: "smtp.example.com",
                    smtpPort: 587,
                    username: "",
                    password: "",
                    useTLS: true,
                    useStartTLS: false,
                    sendRate: 50
                ),
                schedule: CampaignSchedule(
                    startDate: Date(),
                    endDate: nil,
                    sendingDays: Array(CampaignSchedule.Weekday.allCases),
                    sendingHours: Array(9...17),
                    timezone: TimeZone.current.identifier
                ),
                tracking: TrackingOptions(),
                notifications: NotificationSettings()
            )
        )
        
        socialManager.createCampaign(campaign)
        dismiss()
    }
}

struct CampaignWizardProgress: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(1...totalSteps, id: \.self) { step in
                HStack(spacing: 0) {
                    Circle()
                        .fill(step <= currentStep ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Text("\(step)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        )
                    
                    if step < totalSteps {
                        Rectangle()
                            .fill(step < currentStep ? Color.accentColor : Color.gray.opacity(0.3))
                            .frame(height: 2)
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Wizard Steps

struct BasicInfoStep: View {
    @Binding var name: String
    @Binding var description: String
    @Binding var organization: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Campaign Information")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Campaign Name", systemImage: "envelope.badge")
                        .font(.headline)
                    
                    TextField("Q3 Security Awareness", text: $name)
                        .textFieldStyle(.roundedBorder)
                    
                    Text("Choose a descriptive name for internal reference")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Label("Target Organization", systemImage: "building.2")
                        .font(.headline)
                    
                    TextField("Acme Corporation", text: $organization)
                        .textFieldStyle(.roundedBorder)
                    
                    Text("The organization you have authorization to test")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Label("Description", systemImage: "doc.text")
                        .font(.headline)
                    
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(NSColor.separatorColor))
                        )
                    
                    Text("Additional notes about the campaign objectives")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Legal reminder
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                
                Text("Ensure you have written authorization before proceeding")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
    }
}

struct TemplateSelectionStep: View {
    let emailTemplates: [EmailTemplate]
    @Binding var selectedTemplate: EmailTemplate?
    @State private var previewTemplate: EmailTemplate?
    @State private var filterCategory: EmailTemplate.TemplateCategory?
    @State private var filterDifficulty: EmailTemplate.TemplateDifficulty?
    
    var filteredTemplates: [EmailTemplate] {
        emailTemplates.filter { template in
            (filterCategory == nil || template.category == filterCategory) &&
            (filterDifficulty == nil || template.difficulty == filterDifficulty)
        }
    }
    
    var body: some View {
        HSplitView {
            // Template list
            VStack(alignment: .leading, spacing: 16) {
                Text("Select Email Template")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                // Filters
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Category:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Category", selection: $filterCategory) {
                            Text("All").tag(nil as EmailTemplate.TemplateCategory?)
                            ForEach(EmailTemplate.TemplateCategory.allCases, id: \.self) { category in
                                Label(category.rawValue, systemImage: category.icon)
                                    .tag(category as EmailTemplate.TemplateCategory?)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                    
                    HStack {
                        Text("Difficulty:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Difficulty", selection: $filterDifficulty) {
                            Text("All").tag(nil as EmailTemplate.TemplateDifficulty?)
                            ForEach(EmailTemplate.TemplateDifficulty.allCases, id: \.self) { difficulty in
                                Text(difficulty.rawValue)
                                    .tag(difficulty as EmailTemplate.TemplateDifficulty?)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                }
                
                Divider()
                
                // Template grid
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible())], spacing: 12) {
                        ForEach(filteredTemplates) { template in
                            EmailTemplateCard(
                                template: template,
                                isSelected: selectedTemplate?.id == template.id
                            ) {
                                selectedTemplate = template
                                previewTemplate = template
                            }
                        }
                    }
                }
            }
            .frame(minWidth: 300)
            .padding()
            
            // Preview
            if let preview = previewTemplate {
                EmailTemplatePreview(template: preview)
                    .frame(minWidth: 400)
            } else {
                VStack {
                    Image(systemName: "envelope")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("Select a template to preview")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct EmailTemplateCard: View {
    let template: EmailTemplate
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: template.category.icon)
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.headline)
                    
                    Text(template.subject)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                DifficultyBadge(difficulty: template.difficulty)
            }
            
            HStack {
                Label(template.senderName, systemImage: "person")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !template.tags.isEmpty {
                    Text(template.tags.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            onSelect()
        }
    }
}

struct DifficultyBadge: View {
    let difficulty: EmailTemplate.TemplateDifficulty
    
    var body: some View {
        Text(difficulty.rawValue)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(difficulty.color.opacity(0.2))
            .foregroundColor(difficulty.color)
            .cornerRadius(4)
    }
}

struct EmailTemplatePreview: View {
    let template: EmailTemplate
    @State private var showHTML = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Preview header
            VStack(alignment: .leading, spacing: 8) {
                Text("Preview")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("From:")
                            .fontWeight(.medium)
                        Text("\(template.senderName) <\(template.senderEmail)>")
                        Spacer()
                    }
                    .font(.caption)
                    
                    HStack {
                        Text("Subject:")
                            .fontWeight(.medium)
                        Text(template.subject)
                        Spacer()
                    }
                    .font(.caption)
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
            }
            .padding()
            
            Divider()
            
            // Toggle between HTML and text
            Picker("View", selection: $showHTML) {
                Text("HTML").tag(true)
                Text("Text").tag(false)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Content preview
            if showHTML {
                HTMLPreview(html: template.htmlContent)
            } else {
                ScrollView {
                    Text(template.textContent)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct HTMLPreview: View {
    let html: String
    
    var body: some View {
        WebView(html: html)
            .background(Color.white)
    }
}

struct WebView: NSViewRepresentable {
    let html: String
    
    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(html, baseURL: nil)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Prevent navigation
            if navigationAction.navigationType == .linkActivated {
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }
}

struct LandingPageSelectionStep: View {
    let landingPages: [LandingPageTemplate]
    @Binding var selectedPage: LandingPageTemplate?
    @State private var previewPage: LandingPageTemplate?
    
    var body: some View {
        HSplitView {
            // Landing page list
            VStack(alignment: .leading, spacing: 16) {
                Text("Select Landing Page")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Choose the page targets will see after clicking the phishing link")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Divider()
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(landingPages) { page in
                            LandingPageCard(
                                page: page,
                                isSelected: selectedPage?.id == page.id
                            ) {
                                selectedPage = page
                                previewPage = page
                            }
                        }
                    }
                }
            }
            .frame(minWidth: 300)
            .padding()
            
            // Preview
            if let preview = previewPage {
                LandingPagePreview(page: preview)
                    .frame(minWidth: 400)
            } else {
                VStack {
                    Image(systemName: "globe")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("Select a landing page to preview")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct LandingPageCard: View {
    let page: LandingPageTemplate
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: page.pageType.icon)
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(page.name)
                        .font(.headline)
                    
                    Text(page.pageType.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if page.captureCredentials {
                    Label("Captures Data", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            HStack {
                Label(page.url, systemImage: "link")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if page.redirectUrl != nil {
                    Image(systemName: "arrow.right.circle")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            onSelect()
        }
    }
}

struct LandingPagePreview: View {
    let page: LandingPageTemplate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Preview header
            HStack {
                Text("Landing Page Preview")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if page.captureCredentials {
                    Label("Credential Capture Enabled", systemImage: "lock.open")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            .padding()
            
            Divider()
            
            // HTML preview
            WebView(html: generateFullHTML(page: page))
                .background(Color.white)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private func generateFullHTML(page: LandingPageTemplate) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <style>\(page.cssContent)</style>
        </head>
        <body>
            \(page.htmlContent)
            <script>\(page.jsContent)</script>
        </body>
        </html>
        """
    }
}

struct TargetImportStep: View {
    @Binding var targets: [PhishingTarget]
    @State private var showingImporter = false
    @State private var importError: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Import Targets")
                .font(.title2)
                .fontWeight(.semibold)
            
            if targets.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "person.3")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No targets imported yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Import a CSV file with target email addresses")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Button("Import CSV") {
                        showingImporter = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Target list
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("\(targets.count) targets imported")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button("Import More") {
                            showingImporter = true
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Clear All") {
                            targets.removeAll()
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                    }
                    
                    // Target preview table
                    Table(targets) {
                        TableColumn("Email", value: \.email)
                        TableColumn("First Name", value: \.firstName)
                        TableColumn("Last Name", value: \.lastName)
                        TableColumn("Department") { target in
                            Text(target.department ?? "-")
                        }
                        TableColumn("Position") { target in
                            Text(target.position ?? "-")
                        }
                    }
                }
                .padding()
            }
            
            if let error = importError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    Spacer()
                    
                    Button("Dismiss") {
                        importError = nil
                    }
                    .buttonStyle(.link)
                    .controlSize(.small)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    importCSV(from: url)
                }
            case .failure(let error):
                importError = error.localizedDescription
            }
        }
    }
    
    private func importCSV(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let csvString = String(data: data, encoding: .utf8) ?? ""
            let importedTargets = try CSVTargetParser.parse(csvString)
            targets.append(contentsOf: importedTargets)
        } catch {
            importError = error.localizedDescription
        }
    }
}

struct ReviewAndLaunchStep: View {
    let campaignName: String
    let targetCount: Int
    let template: EmailTemplate?
    let landingPage: LandingPageTemplate?
    
    @State private var agreedToTerms = false
    @State private var confirmedAuthorization = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Review Campaign")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Summary
            VStack(alignment: .leading, spacing: 16) {
                SummaryRow(label: "Campaign Name", value: campaignName)
                SummaryRow(label: "Targets", value: "\(targetCount) recipients")
                SummaryRow(label: "Email Template", value: template?.name ?? "None")
                SummaryRow(label: "Landing Page", value: landingPage?.name ?? "None")
                SummaryRow(label: "Estimated Duration", value: calculateDuration())
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            Divider()
            
            // Legal confirmations
            VStack(alignment: .leading, spacing: 16) {
                Text("Legal Requirements")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Toggle(isOn: $confirmedAuthorization) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("I confirm that I have written authorization to conduct this phishing simulation")
                            .font(.body)
                        
                        Text("This includes permission from the target organization's leadership")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Toggle(isOn: $agreedToTerms) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("I understand this tool is for authorized security testing only")
                            .font(.body)
                        
                        Text("Unauthorized use may violate computer fraud and abuse laws")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
            
            Spacer()
            
            if !agreedToTerms || !confirmedAuthorization {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text("You must confirm all legal requirements before creating the campaign")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
    }
    
    private func calculateDuration() -> String {
        let hoursNeeded = Double(targetCount) / 50.0 // 50 emails per hour
        if hoursNeeded < 1 {
            return "< 1 hour"
        } else if hoursNeeded < 24 {
            return "\(Int(hoursNeeded)) hours"
        } else {
            let days = Int(hoursNeeded / 24)
            return "\(days) days"
        }
    }
}

struct SummaryRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Supporting Views

struct EmptyCampaignsView: View {
    @Binding var showingNewCampaign: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "envelope.badge")
                .font(.system(size: 64))
                .foregroundColor(.gray.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No Campaigns Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Create your first phishing campaign to test security awareness")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { showingNewCampaign = true }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Create Campaign")
                }
                .frame(minWidth: 150)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    var color: Color = .accentColor
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color.opacity(0.2) : Color.clear)
                .foregroundColor(isSelected ? color : .secondary)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? color : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct SocialEngineeringTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .accentColor : .secondary)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Additional Views (Templates, Targets, Analytics, Settings)

struct TemplatesView: View {
    var socialManager: SocialEngineeringManager
    @State private var selectedTemplate: EmailTemplate?
    @State private var showingTemplateEditor = false
    @State private var searchText = ""
    
    var filteredTemplates: [EmailTemplate] {
        if searchText.isEmpty {
            return socialManager.emailTemplates
        } else {
            return socialManager.emailTemplates.filter { template in
                template.name.localizedCaseInsensitiveContains(searchText) ||
                template.subject.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            // Template List
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Email Templates")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button(action: { showingTemplateEditor = true }) {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.borderless)
                }
                .padding()
                
                SearchField(text: $searchText, placeholder: "Search templates...")
                    .padding(.horizontal)
                
                List(filteredTemplates, selection: $selectedTemplate) { template in
                    TemplateRowView(template: template)
                        .tag(template)
                }
                .listStyle(.sidebar)
            }
            .frame(minWidth: 300)
        } detail: {
            // Template Detail
            if let template = selectedTemplate {
                TemplateDetailView(template: template, socialManager: socialManager)
            } else {
                VStack {
                    Image(systemName: "envelope.badge")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    Text("Select a template to view details")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $showingTemplateEditor) {
            TemplateEditorView(socialManager: socialManager)
        }
    }
}

struct TemplateRowView: View {
    let template: EmailTemplate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(template.name)
                    .font(.headline)
                
                Spacer()
                
                CategoryBadge(category: template.category)
            }
            
            Text(template.subject)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            HStack {
                DifficultyIndicator(difficulty: template.difficulty)
                
                Spacer()
                
                if template.trackingEnabled {
                    Image(systemName: "location.circle.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct TemplateDetailView: View {
    let template: EmailTemplate
    var socialManager: SocialEngineeringManager
    @State private var showingPreview = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(template.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button("Preview") {
                            showingPreview = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    Text(template.subject)
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        CategoryBadge(category: template.category)
                        DifficultyIndicator(difficulty: template.difficulty)
                        
                        if template.trackingEnabled {
                            Label("Tracking Enabled", systemImage: "location.circle.fill")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                    }
                }
                
                Divider()
                
                // Content Preview
                VStack(alignment: .leading, spacing: 12) {
                    Text("Content Preview")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("From: \(template.senderName) <\(template.senderEmail)>")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Subject: \(template.subject)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Divider()
                        
                        Text(template.textContent.isEmpty ? "HTML content only" : template.textContent)
                            .font(.body)
                            .padding()
                            .background(Color(.controlBackgroundColor))
                            .cornerRadius(8)
                    }
                }
                
                if !template.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
                            .font(.headline)
                        
                        SocialEngineeringFlowLayout(template.tags) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(6)
                        }
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingPreview) {
            TemplatePreviewView(template: template)
        }
    }
}

struct TemplateEditorView: View {
    var socialManager: SocialEngineeringManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var subject = ""
    @State private var senderName = ""
    @State private var senderEmail = ""
    @State private var replyTo = ""
    @State private var htmlContent = ""
    @State private var textContent = ""
    @State private var category: EmailTemplate.TemplateCategory = .phishing
    @State private var difficulty: EmailTemplate.TemplateDifficulty = .easy
    @State private var trackingEnabled = true
    @State private var tags: [String] = []
    @State private var newTag = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    TextField("Template Name", text: $name)
                    TextField("Subject Line", text: $subject)
                    TextField("Sender Name", text: $senderName)
                    TextField("Sender Email", text: $senderEmail)
                    TextField("Reply-To (optional)", text: $replyTo)
                }
                
                Section("Classification") {
                    Picker("Category", selection: $category) {
                        ForEach(EmailTemplate.TemplateCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue.capitalized)
                        }
                    }
                    
                    Picker("Difficulty", selection: $difficulty) {
                        ForEach(EmailTemplate.TemplateDifficulty.allCases, id: \.self) { diff in
                            Text(diff.rawValue.capitalized)
                        }
                    }
                    
                    Toggle("Enable Tracking", isOn: $trackingEnabled)
                }
                
                Section("Content") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("HTML Content")
                            .font(.headline)
                        TextEditor(text: $htmlContent)
                            .frame(minHeight: 200)
                            .font(.system(.body, design: .monospaced))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Plain Text Content")
                            .font(.headline)
                        TextEditor(text: $textContent)
                            .frame(minHeight: 100)
                            .font(.system(.body, design: .monospaced))
                    }
                }
                
                Section("Tags") {
                    HStack {
                        TextField("Add tag", text: $newTag)
                        Button("Add") {
                            if !newTag.isEmpty {
                                tags.append(newTag)
                                newTag = ""
                            }
                        }
                        .disabled(newTag.isEmpty)
                    }
                    
                    if !tags.isEmpty {
                        SocialEngineeringFlowLayout(tags) { tag in
                            HStack(spacing: 4) {
                                Text(tag)
                                Button(action: { tags.removeAll { $0 == tag } }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(6)
                        }
                    }
                }
            }
            .navigationTitle("New Template")
            // .navigationBarTitleDisplayMode(.inline) // Not available on macOS
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTemplate()
                    }
                    .disabled(name.isEmpty || subject.isEmpty || senderEmail.isEmpty)
                }
            }
        }
    }
    
    private func saveTemplate() {
        let template = EmailTemplate(
            name: name,
            subject: subject,
            senderName: senderName,
            senderEmail: senderEmail,
            replyTo: replyTo.isEmpty ? nil : replyTo,
            htmlContent: htmlContent,
            textContent: textContent,
            attachments: [],
            trackingEnabled: trackingEnabled,
            category: category,
            difficulty: difficulty,
            tags: tags
        )
        
        socialManager.createEmailTemplate(template)
        dismiss()
    }
}

struct TargetsView: View {
    var socialManager: SocialEngineeringManager
    @State private var selectedCampaign: PhishingCampaign?
    @State private var showingCSVImporter = false
    @State private var searchText = ""
    
    var activeCampaigns: [PhishingCampaign] {
        socialManager.campaigns.filter { $0.status == .active || $0.status == .ready }
    }
    
    var selectedCampaignTargets: [PhishingTarget] {
        selectedCampaign?.targets ?? []
    }
    
    var filteredTargets: [PhishingTarget] {
        if searchText.isEmpty {
            return selectedCampaignTargets
        } else {
            return selectedCampaignTargets.filter { target in
                target.email.localizedCaseInsensitiveContains(searchText) ||
                target.firstName.localizedCaseInsensitiveContains(searchText) ||
                target.lastName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Target Management")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Import CSV") {
                    showingCSVImporter = true
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedCampaign == nil)
            }
            .padding()
            
            // Campaign Selection
            if !activeCampaigns.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select Campaign")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Picker("Campaign", selection: $selectedCampaign) {
                        Text("Select Campaign").tag(nil as PhishingCampaign?)
                        ForEach(activeCampaigns) { campaign in
                            Text("\(campaign.name) (\(campaign.targets.count) targets)")
                                .tag(campaign as PhishingCampaign?)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal)
                }
                .padding(.bottom)
            }
            
            if let campaign = selectedCampaign {
                VStack(alignment: .leading, spacing: 0) {
                    // Search
                    SearchField(text: $searchText, placeholder: "Search targets...")
                        .padding(.horizontal)
                    
                    // Target Stats
                    TargetStatsView(targets: campaign.targets)
                        .padding()
                    
                    Divider()
                    
                    // Target List
                    List(filteredTargets) { target in
                        TargetRowView(target: target)
                    }
                    .listStyle(.plain)
                }
            } else {
                VStack {
                    Image(systemName: "target")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    Text("Select a campaign to view targets")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Import targets from CSV or add them manually")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .fileImporter(
            isPresented: $showingCSVImporter,
            allowedContentTypes: [.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            handleCSVImport(result: result)
        }
    }
    
    private func handleCSVImport(result: Result<[URL], Error>) {
        do {
            guard let fileURL = try result.get().first else { return }
            let csvData = try Data(contentsOf: fileURL)
            let targets = try socialManager.importTargetsFromCSV(csvData)
            
            // Add targets to selected campaign
            if var campaign = selectedCampaign {
                campaign.targets.append(contentsOf: targets)
                socialManager.updateCampaign(campaign)
                selectedCampaign = campaign
            }
        } catch {
            print("CSV import failed: \(error)")
        }
    }
}

struct TargetStatsView: View {
    let targets: [PhishingTarget]
    
    var stats: (total: Int, sent: Int, opened: Int, clicked: Int, submitted: Int) {
        let total = targets.count
        let sent = targets.filter { $0.emailSentAt != nil }.count
        let opened = targets.filter { $0.emailOpenedAt != nil }.count
        let clicked = targets.filter { $0.linkClickedAt != nil }.count
        let submitted = targets.filter { $0.credentialsSubmittedAt != nil }.count
        
        return (total, sent, opened, clicked, submitted)
    }
    
    var body: some View {
        HStack(spacing: 20) {
            SocialEngineeringStatCard(title: "Total", value: stats.total, color: .blue)
            SocialEngineeringStatCard(title: "Sent", value: stats.sent, color: .orange)
            SocialEngineeringStatCard(title: "Opened", value: stats.opened, color: .yellow)
            SocialEngineeringStatCard(title: "Clicked", value: stats.clicked, color: .purple)
            SocialEngineeringStatCard(title: "Submitted", value: stats.submitted, color: .red)
        }
    }
}

struct SocialEngineeringStatCard: View {
    let title: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct TargetRowView: View {
    let target: PhishingTarget
    
    var statusColor: Color {
        switch target.status {
        case .pending: return .gray
        case .sent: return .blue
        case .opened: return .orange
        case .clicked: return .yellow  
        case .submitted: return .red
        case .reported: return .green
        case .failed: return .red
        case .bounced: return .gray
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(target.firstName) \(target.lastName)")
                    .font(.headline)
                
                Text(target.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let department = target.department {
                    Text(department)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                
                Text(target.status.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let sentAt = target.emailSentAt {
                    Text(sentAt, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct AnalyticsView: View {
    var socialManager: SocialEngineeringManager
    @State private var selectedCampaign: PhishingCampaign?
    @State private var timeRange: AnalyticsTimeRange = .last30Days
    
    enum AnalyticsTimeRange: String, CaseIterable {
        case last7Days = "Last 7 Days"
        case last30Days = "Last 30 Days" 
        case last90Days = "Last 90 Days"
        case allTime = "All Time"
    }
    
    var campaignsToAnalyze: [PhishingCampaign] {
        if let selected = selectedCampaign {
            return [selected]
        } else {
            return socialManager.campaigns.filter { $0.status == .completed || $0.status == .active }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Text("Analytics Dashboard")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    HStack {
                        Picker("Campaign", selection: $selectedCampaign) {
                            Text("All Campaigns").tag(nil as PhishingCampaign?)
                            ForEach(socialManager.campaigns) { campaign in
                                Text(campaign.name).tag(campaign as PhishingCampaign?)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        Picker("Time Range", selection: $timeRange) {
                            ForEach(AnalyticsTimeRange.allCases, id: \.self) { range in
                                Text(range.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                .padding()
                
                if !campaignsToAnalyze.isEmpty {
                    // Overall Metrics
                    OverallMetricsView(campaigns: campaignsToAnalyze)
                        .padding(.horizontal)
                    
                    // Success Rate Chart
                    SuccessRateChartView(campaigns: campaignsToAnalyze)
                        .padding(.horizontal)
                    
                    // Department Breakdown
                    DepartmentBreakdownView(campaigns: campaignsToAnalyze)
                        .padding(.horizontal)
                    
                    // Campaign Performance
                    CampaignPerformanceView(campaigns: campaignsToAnalyze)
                        .padding(.horizontal)
                        
                } else {
                    VStack {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary)
                        Text("No campaign data available")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Complete some campaigns to see analytics")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
                }
            }
        }
    }
}

struct OverallMetricsView: View {
    let campaigns: [PhishingCampaign]
    
    var metrics: (totalTargets: Int, emailsSent: Int, opened: Int, clicked: Int, submitted: Int, reported: Int) {
        let allTargets = campaigns.flatMap { $0.targets }
        return (
            totalTargets: allTargets.count,
            emailsSent: allTargets.filter { $0.emailSentAt != nil }.count,
            opened: allTargets.filter { $0.emailOpenedAt != nil }.count,
            clicked: allTargets.filter { $0.linkClickedAt != nil }.count,
            submitted: allTargets.filter { $0.credentialsSubmittedAt != nil }.count,
            reported: allTargets.filter { $0.reportedAsPhishingAt != nil }.count
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overall Performance")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                SocialEngineeringMetricCard(title: "Total Targets", value: metrics.totalTargets, subtitle: nil, color: .blue)
                SocialEngineeringMetricCard(title: "Emails Sent", value: metrics.emailsSent, subtitle: "\(percentage(metrics.emailsSent, of: metrics.totalTargets))%", color: .orange)
                SocialEngineeringMetricCard(title: "Opened", value: metrics.opened, subtitle: "\(percentage(metrics.opened, of: metrics.emailsSent))%", color: .yellow)
                SocialEngineeringMetricCard(title: "Clicked", value: metrics.clicked, subtitle: "\(percentage(metrics.clicked, of: metrics.opened))%", color: .purple)
                SocialEngineeringMetricCard(title: "Submitted", value: metrics.submitted, subtitle: "\(percentage(metrics.submitted, of: metrics.clicked))%", color: .red)
                SocialEngineeringMetricCard(title: "Reported", value: metrics.reported, subtitle: "\(percentage(metrics.reported, of: metrics.emailsSent))%", color: .green)
            }
        }
    }
    
    private func percentage(_ numerator: Int, of denominator: Int) -> Int {
        guard denominator > 0 else { return 0 }
        return Int(Double(numerator) / Double(denominator) * 100)
    }
}

struct SocialEngineeringMetricCard: View {
    let title: String
    let value: Int
    let subtitle: String?
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct SuccessRateChartView: View {
    let campaigns: [PhishingCampaign]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Success Rates")
                .font(.headline)
            
            // Simple bar chart representation
            HStack(alignment: .bottom, spacing: 8) {
                ChartBar(title: "Open Rate", value: openRate, color: .yellow)
                ChartBar(title: "Click Rate", value: clickRate, color: .purple)
                ChartBar(title: "Submit Rate", value: submitRate, color: .red)
                ChartBar(title: "Report Rate", value: reportRate, color: .green)
            }
            .frame(height: 150)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var openRate: Double {
        let allTargets = campaigns.flatMap { $0.targets }
        let sent = allTargets.filter { $0.emailSentAt != nil }.count
        let opened = allTargets.filter { $0.emailOpenedAt != nil }.count
        return sent > 0 ? Double(opened) / Double(sent) : 0
    }
    
    private var clickRate: Double {
        let allTargets = campaigns.flatMap { $0.targets }
        let opened = allTargets.filter { $0.emailOpenedAt != nil }.count
        let clicked = allTargets.filter { $0.linkClickedAt != nil }.count
        return opened > 0 ? Double(clicked) / Double(opened) : 0
    }
    
    private var submitRate: Double {
        let allTargets = campaigns.flatMap { $0.targets }
        let clicked = allTargets.filter { $0.linkClickedAt != nil }.count
        let submitted = allTargets.filter { $0.credentialsSubmittedAt != nil }.count
        return clicked > 0 ? Double(submitted) / Double(clicked) : 0
    }
    
    private var reportRate: Double {
        let allTargets = campaigns.flatMap { $0.targets }
        let sent = allTargets.filter { $0.emailSentAt != nil }.count
        let reported = allTargets.filter { $0.reportedAsPhishingAt != nil }.count
        return sent > 0 ? Double(reported) / Double(sent) : 0
    }
}

struct ChartBar: View {
    let title: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            VStack {
                Spacer()
                Rectangle()
                    .fill(color)
                    .frame(height: max(value * 120, 5))
            }
            .frame(maxHeight: 120)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("\(Int(value * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct DepartmentBreakdownView: View {
    let campaigns: [PhishingCampaign]
    
    var departmentStats: [(department: String, total: Int, submitted: Int)] {
        let allTargets = campaigns.flatMap { $0.targets }
        let grouped = Dictionary(grouping: allTargets) { $0.department ?? "Unknown" }
        
        return grouped.map { department, targets in
            let submitted = targets.filter { $0.credentialsSubmittedAt != nil }.count
            return (department, targets.count, submitted)
        }.sorted { $0.total > $1.total }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Department Breakdown")
                .font(.headline)
            
            VStack(spacing: 8) {
                ForEach(departmentStats.prefix(5), id: \.department) { stat in
                    HStack {
                        Text(stat.department)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(stat.submitted)/\(stat.total)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("\(stat.total > 0 ? Int(Double(stat.submitted) / Double(stat.total) * 100) : 0)%")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(stat.submitted > stat.total / 2 ? .red : .green)
                            .frame(minWidth: 40, alignment: .trailing)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct CampaignPerformanceView: View {
    let campaigns: [PhishingCampaign]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Campaign Performance")
                .font(.headline)
            
            VStack(spacing: 8) {
                ForEach(campaigns.prefix(5)) { campaign in
                    CampaignPerformanceRow(campaign: campaign)
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct CampaignPerformanceRow: View {
    let campaign: PhishingCampaign
    
    var submitRate: Int {
        let targets = campaign.targets
        let sent = targets.filter { $0.emailSentAt != nil }.count
        let submitted = targets.filter { $0.credentialsSubmittedAt != nil }.count
        return sent > 0 ? Int(Double(submitted) / Double(sent) * 100) : 0
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(campaign.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(campaign.targets.count) targets")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(submitRate)%")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(submitRate > 50 ? .red : .green)
        }
        .padding(.vertical, 4)
    }
}


struct SMTPProfileRow: View {
    let profile: SendingProfile
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(profile.smtpHost):\(profile.smtpPort)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                if profile.useTLS || profile.useStartTLS {
                    Image(systemName: "lock.shield")
                        .foregroundColor(.green)
                }
                
                Text("\(profile.sendRate)/hr")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Helper Views and Components

struct SearchField: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
        }
        .padding(8)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct CategoryBadge: View {
    let category: EmailTemplate.TemplateCategory
    
    var body: some View {
        Label(category.rawValue, systemImage: category.icon)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(8)
    }
}

struct DifficultyIndicator: View {
    let difficulty: EmailTemplate.TemplateDifficulty
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<4) { index in
                Circle()
                    .fill(index < difficultyLevel ? difficulty.color : Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
            
            Text(difficulty.rawValue)
                .font(.caption)
                .foregroundColor(difficulty.color)
        }
    }
    
    private var difficultyLevel: Int {
        switch difficulty {
        case .easy: return 1
        case .medium: return 2
        case .hard: return 3
        case .expert: return 4
        }
    }
}

struct SocialEngineeringFlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let content: (Data.Element) -> Content
    
    init(_ data: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.content = content
    }
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 8) {
            let chunked = data.chunked(into: 3)
            ForEach(Array(chunked.enumerated()), id: \.offset) { _, chunk in
                HStack {
                    ForEach(Array(chunk), id: \.self) { item in
                        content(item)
                    }
                    Spacer()
                }
            }
        }
    }
}

extension RandomAccessCollection {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[index(startIndex, offsetBy: $0)..<index(startIndex, offsetBy: Swift.min($0 + size, count))])
        }
    }
}

struct TemplatePreviewView: View {
    let template: EmailTemplate
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Subject: \(template.subject)")
                            .font(.headline)
                        
                        Text("From: \(template.senderName) <\(template.senderEmail)>")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    if !template.htmlContent.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("HTML Content")
                                .font(.headline)
                            
                            // In a real implementation, you'd use WKWebView here
                            Text(template.htmlContent)
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .background(Color(.controlBackgroundColor))
                                .cornerRadius(8)
                        }
                    }
                    
                    if !template.textContent.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Text Content")
                                .font(.headline)
                            
                            Text(template.textContent)
                                .font(.body)
                                .padding()
                                .background(Color(.controlBackgroundColor))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Email Preview")
            // .navigationBarTitleDisplayMode(.inline) // Not available on macOS
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CampaignDetailView: View {
    let campaign: PhishingCampaign
    let socialManager: SocialEngineeringManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Campaign header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(campaign.name)
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                
                                Text(campaign.targetOrganization)
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            CampaignStatusBadge(status: campaign.status)
                                .scaleEffect(1.2)
                        }
                        
                        if !campaign.description.isEmpty {
                            Text(campaign.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Quick metrics
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            QuickMetricCard(
                                title: "Open Rate",
                                value: String(format: "%.1f%%", campaign.metrics.openRate),
                                icon: "envelope.open",
                                color: .blue
                            )
                            
                            QuickMetricCard(
                                title: "Click Rate",
                                value: String(format: "%.1f%%", campaign.metrics.clickRate),
                                icon: "link",
                                color: .orange
                            )
                            
                            QuickMetricCard(
                                title: "Submission Rate",
                                value: String(format: "%.1f%%", campaign.metrics.submissionRate),
                                icon: "exclamationmark.triangle",
                                color: .red
                            )
                            
                            QuickMetricCard(
                                title: "Report Rate",
                                value: String(format: "%.1f%%", campaign.metrics.reportRate),
                                icon: "flag",
                                color: .green
                            )
                        }
                    }
                    
                    // Detailed sections
                    Divider()
                    
                    // Target breakdown
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Target Breakdown")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        // Target status chart would go here
                        Text("Chart placeholder - target status visualization")
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Divider()
                    
                    // Recent activity
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Activity")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        // Activity timeline would go here
                        Text("Activity timeline placeholder")
                            .frame(height: 300)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("Campaign Details")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 900, height: 700)
    }
}

struct QuickMetricCard: View {
    let title: String
    let value: String
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
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 150)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}