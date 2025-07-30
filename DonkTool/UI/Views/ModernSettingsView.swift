//
//  ModernSettingsView.swift
//  DonkTool
//
//  Modern settings interface with tabbed navigation and visual preferences
//

import SwiftUI

struct ModernSettingsView: View {
    @Environment(AppState.self) private var appState
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTab: SettingsTab = .general
    
    // General Settings
    @AppStorage("autoUpdateCVE") private var autoUpdateCVE = true
    @AppStorage("enableLogging") private var enableLogging = true
    @AppStorage("verboseMode") private var verboseMode = false
    @AppStorage("saveReportsAutomatically") private var saveReportsAutomatically = false
    
    // Network Settings
    @AppStorage("scanTimeout") private var scanTimeout: Double = 5.0
    @AppStorage("maxConcurrentScans") private var maxConcurrentScans = 50
    @AppStorage("enableBannerGrabbing") private var enableBannerGrabbing = true
    @AppStorage("useCustomDNS") private var useCustomDNS = false
    @AppStorage("customDNSServer") private var customDNSServer = "8.8.8.8"
    
    // Security Settings
    @AppStorage("requireAuthentication") private var requireAuthentication = false
    @AppStorage("encryptReports") private var encryptReports = false
    @AppStorage("anonymizeData") private var anonymizeData = false
    @AppStorage("toolExecutionTimeout") private var toolExecutionTimeout: Double = 300.0
    
    // Appearance Settings
    @AppStorage("colorScheme") private var colorScheme = "system"
    @AppStorage("accentColor") private var accentColorName = "blue"
    @AppStorage("showAnimations") private var showAnimations = true
    @AppStorage("compactMode") private var compactMode = false
    
    // Advanced Settings
    @AppStorage("proxyEnabled") private var proxyEnabled = false
    @AppStorage("proxyServer") private var proxyServer = ""
    @AppStorage("proxyPort") private var proxyPort = "8080"
    
    @State private var showingClearConfirmation = false
    @State private var showingResetConfirmation = false
    
    enum SettingsTab: String, CaseIterable {
        case general = "General"
        case network = "Network"
        case security = "Security"
        case appearance = "Appearance"
        case advanced = "Advanced"
        
        var icon: String {
            switch self {
            case .general: return "gear"
            case .network: return "network"
            case .security: return "lock.shield"
            case .appearance: return "paintbrush"
            case .advanced: return "wrench.and.screwdriver"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Modern Header
            ModernSettingsHeader()
            
            // Tab Bar
            SettingsTabBar(selectedTab: $selectedTab)
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    switch selectedTab {
                    case .general:
                        GeneralSettingsSection(
                            autoUpdateCVE: $autoUpdateCVE,
                            enableLogging: $enableLogging,
                            verboseMode: $verboseMode,
                            saveReportsAutomatically: $saveReportsAutomatically
                        )
                    case .network:
                        NetworkSettingsSection(
                            scanTimeout: $scanTimeout,
                            maxConcurrentScans: $maxConcurrentScans,
                            enableBannerGrabbing: $enableBannerGrabbing,
                            useCustomDNS: $useCustomDNS,
                            customDNSServer: $customDNSServer
                        )
                    case .security:
                        SecuritySettingsSection(
                            requireAuthentication: $requireAuthentication,
                            encryptReports: $encryptReports,
                            anonymizeData: $anonymizeData,
                            toolExecutionTimeout: $toolExecutionTimeout
                        )
                    case .appearance:
                        AppearanceSettingsSection(
                            colorScheme: $colorScheme,
                            accentColorName: $accentColorName,
                            showAnimations: $showAnimations,
                            compactMode: $compactMode
                        )
                    case .advanced:
                        AdvancedSettingsSection(
                            proxyEnabled: $proxyEnabled,
                            proxyServer: $proxyServer,
                            proxyPort: $proxyPort,
                            showingClearConfirmation: $showingClearConfirmation,
                            showingResetConfirmation: $showingResetConfirmation
                        )
                    }
                }
                .padding(24)
            }
        }
        .alert("Clear All Data", isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("This will clear all scan results, vulnerabilities, and targets. This action cannot be undone.")
        }
        .alert("Reset Settings", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetAllSettings()
            }
        } message: {
            Text("This will reset all settings to their default values. This action cannot be undone.")
        }
    }
    
    private func clearAllData() {
        appState.targets.removeAll()
        appState.allVulnerabilities.removeAll()
        appState.lastScanResults.removeAll()
    }
    
    private func resetAllSettings() {
        // Reset all @AppStorage values to defaults
        autoUpdateCVE = true
        enableLogging = true
        verboseMode = false
        saveReportsAutomatically = false
        scanTimeout = 5.0
        maxConcurrentScans = 50
        enableBannerGrabbing = true
        useCustomDNS = false
        customDNSServer = "8.8.8.8"
        requireAuthentication = false
        encryptReports = false
        anonymizeData = false
        toolExecutionTimeout = 300.0
        colorScheme = "system"
        accentColorName = "blue"
        showAnimations = true
        compactMode = false
        proxyEnabled = false
        proxyServer = ""
        proxyPort = "8080"
    }
}

// MARK: - Supporting Views

struct ModernSettingsHeader: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Settings")
                    .font(.system(size: 32, weight: .bold))
                Text("Configure your security testing preferences")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Settings Stats
            HStack(spacing: 20) {
                SettingsStat(label: "Profiles", value: "3", icon: "person.2.fill", color: .blue)
                SettingsStat(label: "Tools", value: "24", icon: "wrench.fill", color: .green)
            }
        }
        .padding(24)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct SettingsStat: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .semibold))
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct SettingsTabBar: View {
    @Binding var selectedTab: ModernSettingsView.SettingsTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(ModernSettingsView.SettingsTab.allCases, id: \.self) { tab in
                SettingsTabButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    action: { selectedTab = tab }
                )
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(NSColor.separatorColor)),
            alignment: .bottom
        )
    }
}

struct SettingsTabButton: View {
    let tab: ModernSettingsView.SettingsTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                
                Text(tab.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color(NSColor.windowBackgroundColor) : Color.clear)
            .overlay(
                Rectangle()
                    .frame(height: 3)
                    .foregroundColor(isSelected ? .accentColor : .clear),
                alignment: .bottom
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings Sections

struct GeneralSettingsSection: View {
    @Binding var autoUpdateCVE: Bool
    @Binding var enableLogging: Bool
    @Binding var verboseMode: Bool
    @Binding var saveReportsAutomatically: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            SettingsCard(title: "Database", icon: "cylinder.fill") {
                SettingsToggle(
                    title: "Auto-update CVE Database",
                    subtitle: "Automatically fetch latest vulnerabilities",
                    isOn: $autoUpdateCVE,
                    icon: "arrow.triangle.2.circlepath"
                )
            }
            
            SettingsCard(title: "Logging", icon: "doc.text.fill") {
                SettingsToggle(
                    title: "Enable Logging",
                    subtitle: "Save scan activities to log files",
                    isOn: $enableLogging,
                    icon: "text.append"
                )
                
                SettingsToggle(
                    title: "Verbose Mode",
                    subtitle: "Show detailed output during operations",
                    isOn: $verboseMode,
                    icon: "text.magnifyingglass"
                )
            }
            
            SettingsCard(title: "Reports", icon: "doc.richtext.fill") {
                SettingsToggle(
                    title: "Auto-save Reports",
                    subtitle: "Automatically save generated reports",
                    isOn: $saveReportsAutomatically,
                    icon: "square.and.arrow.down"
                )
            }
        }
    }
}

struct NetworkSettingsSection: View {
    @Binding var scanTimeout: Double
    @Binding var maxConcurrentScans: Int
    @Binding var enableBannerGrabbing: Bool
    @Binding var useCustomDNS: Bool
    @Binding var customDNSServer: String
    
    var body: some View {
        VStack(spacing: 20) {
            SettingsCard(title: "Scanning", icon: "antenna.radiowaves.left.and.right") {
                SettingsSlider(
                    title: "Scan Timeout",
                    value: $scanTimeout,
                    range: 1...30,
                    unit: "seconds",
                    icon: "timer"
                )
                
                SettingsStepper(
                    title: "Max Concurrent Scans",
                    value: $maxConcurrentScans,
                    range: 1...100,
                    icon: "square.stack.3d.up"
                )
                
                SettingsToggle(
                    title: "Banner Grabbing",
                    subtitle: "Retrieve service banners during scans",
                    isOn: $enableBannerGrabbing,
                    icon: "text.badge.checkmark"
                )
            }
            
            SettingsCard(title: "DNS", icon: "network") {
                SettingsToggle(
                    title: "Use Custom DNS",
                    subtitle: "Override system DNS settings",
                    isOn: $useCustomDNS,
                    icon: "personalhotspot"
                )
                
                if useCustomDNS {
                    SettingsTextField(
                        title: "DNS Server",
                        text: $customDNSServer,
                        placeholder: "8.8.8.8",
                        icon: "server.rack"
                    )
                }
            }
        }
    }
}

struct SecuritySettingsSection: View {
    @Binding var requireAuthentication: Bool
    @Binding var encryptReports: Bool
    @Binding var anonymizeData: Bool
    @Binding var toolExecutionTimeout: Double
    
    var body: some View {
        VStack(spacing: 20) {
            SettingsCard(title: "Authentication", icon: "lock.fill") {
                SettingsToggle(
                    title: "Require Authentication",
                    subtitle: "Protect access with system authentication",
                    isOn: $requireAuthentication,
                    icon: "person.badge.key"
                )
            }
            
            SettingsCard(title: "Data Protection", icon: "shield.fill") {
                SettingsToggle(
                    title: "Encrypt Reports",
                    subtitle: "Encrypt generated reports at rest",
                    isOn: $encryptReports,
                    icon: "lock.doc"
                )
                
                SettingsToggle(
                    title: "Anonymize Data",
                    subtitle: "Remove identifying information from exports",
                    isOn: $anonymizeData,
                    icon: "eye.slash"
                )
            }
            
            SettingsCard(title: "Execution Limits", icon: "clock.arrow.circlepath") {
                SettingsSlider(
                    title: "Tool Execution Timeout",
                    value: $toolExecutionTimeout,
                    range: 60...600,
                    unit: "seconds",
                    icon: "timer"
                )
            }
        }
    }
}

struct AppearanceSettingsSection: View {
    @Binding var colorScheme: String
    @Binding var accentColorName: String
    @Binding var showAnimations: Bool
    @Binding var compactMode: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    let accentColors = [
        ("Blue", Color.blue),
        ("Purple", Color.purple),
        ("Pink", Color.pink),
        ("Red", Color.red),
        ("Orange", Color.orange),
        ("Green", Color.green)
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            SettingsCard(title: "Theme", icon: "paintbrush.fill") {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Color Scheme", systemImage: "circle.lefthalf.filled")
                        .font(.system(size: 14, weight: .medium))
                    
                    HStack(spacing: 12) {
                        ForEach(ThemeManager.Theme.allCases, id: \.self) { theme in
                            ColorSchemeButton(
                                scheme: theme.rawValue,
                                isSelected: themeManager.currentTheme == theme,
                                action: { themeManager.currentTheme = theme }
                            )
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Label("Accent Color", systemImage: "paintpalette")
                        .font(.system(size: 14, weight: .medium))
                    
                    HStack(spacing: 8) {
                        ForEach(accentColors, id: \.0) { name, color in
                            AccentColorButton(
                                color: color,
                                isSelected: accentColorName == name.lowercased(),
                                action: { accentColorName = name.lowercased() }
                            )
                        }
                    }
                }
            }
            
            SettingsCard(title: "Display", icon: "display") {
                SettingsToggle(
                    title: "Show Animations",
                    subtitle: "Enable interface animations and transitions",
                    isOn: $showAnimations,
                    icon: "play.circle"
                )
                
                SettingsToggle(
                    title: "Compact Mode",
                    subtitle: "Reduce spacing for more content",
                    isOn: $compactMode,
                    icon: "rectangle.compress.vertical"
                )
            }
        }
    }
}

struct AdvancedSettingsSection: View {
    @Binding var proxyEnabled: Bool
    @Binding var proxyServer: String
    @Binding var proxyPort: String
    @Binding var showingClearConfirmation: Bool
    @Binding var showingResetConfirmation: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            SettingsCard(title: "Proxy", icon: "arrow.triangle.swap") {
                SettingsToggle(
                    title: "Use Proxy",
                    subtitle: "Route traffic through proxy server",
                    isOn: $proxyEnabled,
                    icon: "arrow.right.arrow.left.circle"
                )
                
                if proxyEnabled {
                    SettingsTextField(
                        title: "Proxy Server",
                        text: $proxyServer,
                        placeholder: "proxy.example.com",
                        icon: "server.rack"
                    )
                    
                    SettingsTextField(
                        title: "Proxy Port",
                        text: $proxyPort,
                        placeholder: "8080",
                        icon: "number"
                    )
                }
            }
            
            SettingsCard(title: "Data Management", icon: "externaldrive.fill") {
                VStack(spacing: 12) {
                    Button(action: { showingClearConfirmation = true }) {
                        HStack {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                            Text("Clear All Data")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { showingResetConfirmation = true }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 14))
                            Text("Reset All Settings")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.orange)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Settings Components

struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.accentColor)
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            
            VStack(spacing: 16) {
                content
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct SettingsToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let icon: String
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
    }
}

struct SettingsSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                
                Spacer()
                
                Text("\(Int(value)) \(unit)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(4)
            }
            
            Slider(value: $value, in: range)
                .controlSize(.small)
        }
    }
}

struct SettingsStepper: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let icon: String
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            
            Spacer()
            
            Stepper("\(value)", value: $value, in: range)
                .labelsHidden()
                .controlSize(.small)
            
            Text("\(value)")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(width: 40)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(4)
        }
    }
}

struct SettingsTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            
            Spacer()
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)
                .controlSize(.small)
        }
    }
}

struct ColorSchemeButton: View {
    let scheme: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: iconForScheme)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(scheme)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(width: 80, height: 60)
            .background(isSelected ? Color.accentColor : Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
    var iconForScheme: String {
        switch scheme {
        case "System": return "laptopcomputer"
        case "Light": return "sun.max.fill"
        case "Dark": return "moon.fill"
        default: return "circle"
        }
    }
}

struct AccentColorButton: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 32, height: 32)
                .overlay(
                    Circle()
                        .stroke(Color.primary, lineWidth: isSelected ? 3 : 0)
                        .padding(2)
                )
                .shadow(color: color.opacity(0.3), radius: isSelected ? 4 : 0)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ModernSettingsView()
        .environment(AppState())
        .frame(width: 800, height: 600)
}