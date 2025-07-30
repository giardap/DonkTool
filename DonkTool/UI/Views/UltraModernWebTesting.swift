//
//  UltraModernWebTesting.swift
//  DonkTool
//
//  Ultra-modern web application testing interface
//

import SwiftUI
import Charts

struct UltraModernWebTesting: View {
    @Environment(AppState.self) private var appState
    @State private var targetURL = ""
    @State private var selectedTestCategory = "All"
    @State private var isScanning = false
    @State private var showResults = false
    @State private var selectedTest: WebTest?
    @State private var showTestDetails = false
    @State private var scanProgress = 0.0
    @State private var discoveredVulnerabilities: [WebVulnerability] = []
    
    let testCategories = ["All", "OWASP Top 10", "Authentication", "Injection", "XSS", "Configuration", "Custom"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xLarge) {
                // Header
                ModernWebTestingHeader()
                    .fadeIn(delay: 0.1)
                
                // Target Configuration
                TargetConfigSection(
                    targetURL: $targetURL,
                    isScanning: isScanning,
                    startScan: startComprehensiveScan
                )
                .slideIn(from: .bottom, delay: 0.2)
                
                // Test Selection
                TestSelectionSection(
                    selectedCategory: $selectedTestCategory,
                    categories: testCategories,
                    selectedTest: $selectedTest,
                    showTestDetails: $showTestDetails
                )
                .fadeIn(delay: 0.3)
                
                // Active Scan Dashboard
                if isScanning {
                    ActiveScanDashboard(
                        progress: scanProgress,
                        vulnerabilities: discoveredVulnerabilities
                    )
                    .transition(.slideAndFade)
                    .scaleIn(delay: 0.1)
                }
                
                // Results Section
                if showResults && !discoveredVulnerabilities.isEmpty {
                    VulnerabilityResultsSection(
                        vulnerabilities: discoveredVulnerabilities
                    )
                    .transition(.slideAndFade)
                    .fadeIn(delay: 0.4)
                }
            }
            .padding()
        }
        .background(Color.appPrimaryBackground)
        .sheet(isPresented: $showTestDetails) {
            if let test = selectedTest {
                ModernWebTestDetailsView(test: test, targetURL: targetURL)
            }
        }
        .onChange(of: appState.isWebScanning) { _, newValue in
            if !newValue && isScanning {
                withAnimation(.smoothSpring) {
                    isScanning = false
                    showResults = true
                    scanProgress = 1.0
                }
            }
        }
        .onChange(of: appState.webScanProgress) { _, newValue in
            if isScanning {
                withAnimation(.standardEaseInOut) {
                    scanProgress = newValue
                }
            }
        }
        .onChange(of: appState.webScanResults) { _, newResults in
            // Update vulnerabilities in real-time as they're discovered
            discoveredVulnerabilities = newResults.map { result in
                WebVulnerability(
                    type: result.type,
                    severity: mapSeverity(result.severity),
                    url: result.url,
                    parameter: nil,
                    evidence: result.details.first,
                    description: result.description
                )
            }
            if !discoveredVulnerabilities.isEmpty && !showResults {
                showResults = true
            }
        }
    }
    
    private func startComprehensiveScan() {
        guard !targetURL.isEmpty else { return }
        
        withAnimation(.spring()) {
            isScanning = true
            showResults = false
            scanProgress = 0.0
            discoveredVulnerabilities = []
        }
        
        // Get selected tests based on category
        let testsToRun = getFilteredTests()
        
        // Start real web scanning using AppState
        Task {
            let testNames = testsToRun.map { $0.name }
            await appState.startWebScan(targetURL: targetURL, selectedTools: testNames)
        }
    }
    
    private func mapSeverity(_ severity: WebScanResult.Severity) -> Vulnerability.Severity {
        switch severity {
        case .critical: return .critical
        case .high: return .high
        case .medium: return .medium
        case .low: return .low
        case .informational: return .low
        }
    }
    
    private func getFilteredTests() -> [WebTest] {
        let availableTests = WebTest.allCases
        
        if selectedTestCategory == "All" {
            return availableTests
        }
        
        // Since WebTest doesn't have categories built-in, we'll map them based on name
        return availableTests.filter { test in
            switch selectedTestCategory {
            case "OWASP Top 10":
                return test.name.contains("A0") || test.description.contains("A0")
            case "Authentication":
                return test.name.contains("Auth") || test.name.contains("Identification")
            case "Injection":
                return test.name.contains("Injection") || test.name.contains("XXE") || test.name.contains("Command")
            case "XSS":
                return test.name.contains("XSS") || test.name.contains("Cross-Site")
            case "Configuration":
                return test.name.contains("Configuration") || test.name.contains("SSL") || test.name.contains("Header")
            default:
                return true
            }
        }
    }
}

// MARK: - Header
struct ModernWebTestingHeader: View {
    @State private var animateIcon = false
    @State private var pulseAnimation = false
    
    var body: some View {
        VStack(spacing: Spacing.medium) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        ZStack {
                            Image(systemName: "globe.badge.chevron.backward")
                                .font(.system(size: 36))
                                .foregroundStyle(Color.primaryGradient)
                                .symbolEffect(.variableColor.iterative.reversing, value: animateIcon)
                            
                            // Animated pulse ring
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [.tertiaryAccent.opacity(0.6), .primaryAccent.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                                .frame(width: 52, height: 52)
                                .scaleEffect(pulseAnimation ? 1.3 : 1.0)
                                .opacity(pulseAnimation ? 0 : 0.8)
                                .animation(.easeOut(duration: 2).repeatForever(autoreverses: false), value: pulseAnimation)
                        }
                        
                        Text("Web Security Testing")
                            .font(Typography.largeTitle)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.tertiaryAccent, .primaryAccent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    
                    Text("Comprehensive web application vulnerability scanner")
                        .font(Typography.headline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Quick Stats
                HStack(spacing: Spacing.medium) {
                    QuickStat(value: "9,247", label: "Tests Available", icon: "checkmark.shield", color: .tertiaryAccent)
                    QuickStat(value: "OWASP", label: "Compliance", icon: "shield.checkered", color: .primaryAccent)
                }
            }
        }
        .padding(.horizontal)
        .onAppear {
            animateIcon = true
            pulseAnimation = true
        }
    }
}

struct QuickStat: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Target Configuration
struct TargetConfigSection: View {
    @Binding var targetURL: String
    let isScanning: Bool
    let startScan: () -> Void
    
    @State private var isValidURL = false
    @State private var showAdvancedOptions = false
    @State private var followRedirects = true
    @State private var maxDepth = "3"
    @State private var includeSubdomains = false
    
    var body: some View {
        VStack(spacing: Spacing.medium) {
            ModernCard {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    Label("Target Configuration", systemImage: "link.circle.fill")
                        .font(Typography.headline)
                        .foregroundColor(.primary)
                    
                    // URL Input
                    HStack(spacing: Spacing.medium) {
                        Image(systemName: "globe")
                            .font(.title3)
                            .foregroundColor(.tertiaryAccent)
                        
                        TextField("Enter target URL (e.g., https://example.com)", text: $targetURL)
                            .textFieldStyle(.plain)
                            .font(.system(size: 16))
                            .onSubmit {
                                if isValidURL && !isScanning {
                                    startScan()
                                }
                            }
                            .onChange(of: targetURL) { _, newValue in
                                isValidURL = validateURL(newValue)
                            }
                        
                        if isValidURL {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.successGreen)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding()
                    .background(Color.appSecondaryBackground)
                    .cornerRadius(10)
                    
                    // Advanced Options Toggle
                    Button(action: {
                        withAnimation(.spring()) {
                            showAdvancedOptions.toggle()
                        }
                    }) {
                        HStack {
                            Label("Advanced Options", systemImage: "slider.horizontal.3")
                                .font(.subheadline)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .rotationEffect(.degrees(showAdvancedOptions ? 180 : 0))
                        }
                        .foregroundColor(.primaryAccent)
                    }
                    .buttonStyle(.plain)
                    
                    if showAdvancedOptions {
                        VStack(spacing: Spacing.small) {
                            Toggle("Follow Redirects", isOn: $followRedirects)
                            Toggle("Include Subdomains", isOn: $includeSubdomains)
                            
                            HStack {
                                Text("Max Crawl Depth:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Picker("", selection: $maxDepth) {
                                    ForEach(["1", "2", "3", "4", "5"], id: \.self) { depth in
                                        Text(depth).tag(depth)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 200)
                            }
                        }
                        .padding()
                        .background(Color.appSecondaryBackground.opacity(0.5))
                        .cornerRadius(8)
                        .transition(.asymmetric(
                            insertion: .push(from: .top).combined(with: .opacity),
                            removal: .push(from: .bottom).combined(with: .opacity)
                        ))
                    }
                }
            }
            .padding(.horizontal)
            
            // Scan Button
            HStack {
                Spacer()
                
                WebScanButton(
                    isScanning: isScanning,
                    isEnabled: isValidURL && !isScanning,
                    action: startScan
                )
                
                Spacer()
            }
        }
    }
    
    private func validateURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString),
              let scheme = url.scheme,
              ["http", "https"].contains(scheme.lowercased()) else {
            return false
        }
        return true
    }
}

struct WebScanButton: View {
    let isScanning: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    @State private var pulseAnimation = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: isScanning ? 
                                [Color.warningOrange, Color.dangerRed] :
                                [Color.tertiaryAccent, Color.primaryAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 56)
                
                if isScanning {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.5), lineWidth: 2)
                        .frame(width: 200, height: 56)
                        .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                        .opacity(pulseAnimation ? 0 : 1)
                        .animation(
                            .easeOut(duration: 1)
                            .repeatForever(autoreverses: false),
                            value: pulseAnimation
                        )
                }
                
                HStack(spacing: 12) {
                    Image(systemName: isScanning ? "stop.circle" : "play.circle.fill")
                        .font(.title3)
                    
                    Text(isScanning ? "Stop Scan" : "Start Scan")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
            }
            .shadow(color: Color.tertiaryAccent.opacity(0.3), radius: 12, x: 0, y: 6)
            .opacity(isEnabled ? 1.0 : 0.6)
            .scaleEffect(isEnabled ? 1.0 : 0.95)
            .animation(Animations.spring, value: isEnabled)
        }
        .disabled(!isEnabled)
        .buttonStyle(.plain)
        .onAppear {
            pulseAnimation = true
        }
    }
}

// MARK: - Test Selection
struct TestSelectionSection: View {
    @Binding var selectedCategory: String
    let categories: [String]
    @Binding var selectedTest: WebTest?
    @Binding var showTestDetails: Bool
    
    var availableTests: [WebTest] {
        WebTest.allCases
    }
    
    var filteredTests: [WebTest] {
        if selectedCategory == "All" {
            return availableTests
        }
        // Since WebTest doesn't have categories, return all for now
        return availableTests
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            SectionHeader("Security Tests", subtitle: "Select tests to run", icon: "checkmark.shield")
                .padding(.horizontal)
            
            // Category Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.small) {
                    ForEach(categories, id: \.self) { category in
                        CategoryPill(
                            title: category,
                            isSelected: selectedCategory == category,
                            count: availableTests.count
                        ) {
                            withAnimation(.spring()) {
                                selectedCategory = category
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Test Grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: Spacing.medium) {
                    ForEach(filteredTests, id: \.name) { test in
                        ModernWebTestCard(test: test) {
                            // Reset state first to ensure state change
                            selectedTest = nil
                            showTestDetails = false
                            
                            // Small delay to ensure state is reset
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                selectedTest = test
                                showTestDetails = true
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .frame(maxHeight: 300)
        }
    }
}

struct CategoryPill: View {
    let title: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                
                Text("\(count)")
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.white.opacity(0.2) : Color.gray.opacity(0.2))
                    .cornerRadius(10)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? AnyShapeStyle(Color.primaryGradient) : AnyShapeStyle(Color.appSecondaryBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ModernWebTestCard: View {
    let test: WebTest
    let action: () -> Void
    
    @State private var isHovered = false
    
    var severityColor: Color {
        switch test.severity {
        case .critical: return .dangerRed
        case .high: return .warningOrange
        case .medium: return .yellow
        case .low: return .tertiaryAccent
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                HStack {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.title3)
                        .foregroundColor(severityColor)
                    
                    Spacer()
                    
                    Text(test.severity.rawValue)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondaryText.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Text(test.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(test.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Spacer()
                
                HStack {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(severityColor)
                            .frame(width: 6, height: 6)
                        Text(test.severity.rawValue.capitalized)
                            .font(.caption2)
                            .foregroundColor(severityColor)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(height: 140)
            .background(isHovered ? severityColor.opacity(0.05) : Color.appCardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isHovered ? severityColor.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: isHovered ? severityColor.opacity(0.1) : .clear, radius: 8)
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(Animations.spring, value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Active Scan Dashboard
struct ActiveScanDashboard: View {
    @Environment(AppState.self) private var appState
    let progress: Double
    let vulnerabilities: [WebVulnerability]
    
    @State private var animateChart = false
    @State private var showingConsole = false
    
    var severityCounts: [String: Int] {
        Dictionary(grouping: vulnerabilities, by: { $0.severity.rawValue })
            .mapValues { $0.count }
    }
    
    var body: some View {
        ModernCard {
            VStack(spacing: Spacing.large) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Scan in Progress")
                            .font(Typography.title3)
                        
                        Text("\(vulnerabilities.count) vulnerabilities found")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Console button
                    Button(action: { 
                        // Reset state first to ensure state change
                        showingConsole = false
                        
                        // Small delay to ensure state is reset
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            showingConsole = true
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "terminal")
                                .font(.caption)
                            Text("Console")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.tertiaryAccent.opacity(0.2))
                        .foregroundColor(.tertiaryAccent)
                        .cornerRadius(6)
                    }
                    
                    // Live indicator
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.tertiaryAccent)
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle()
                                    .stroke(Color.tertiaryAccent, lineWidth: 8)
                                    .blur(radius: 4)
                                    .opacity(animateChart ? 0 : 1)
                                    .animation(
                                        .easeInOut(duration: 1)
                                        .repeatForever(autoreverses: true),
                                        value: animateChart
                                    )
                            )
                        
                        Text("LIVE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.tertiaryAccent)
                    }
                }
                
                // Progress
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Overall Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .tint(Color.primaryGradient)
                        .scaleEffect(y: 2)
                }
                
                // Real-time chart
                if !vulnerabilities.isEmpty {
                    VulnerabilityChart(severityCounts: severityCounts)
                        .frame(height: 150)
                }
                
                // Current Phase
                CurrentPhaseIndicator(progress: progress)
            }
        }
        .padding(.horizontal)
        .onAppear {
            animateChart = true
        }
        .sheet(isPresented: $showingConsole) {
            WebScanConsoleView()
        }
    }
}

struct VulnerabilityChart: View {
    let severityCounts: [String: Int]
    @State private var animateChart = false
    
    var chartData: [(String, Int, Color)] {
        [
            ("Critical", severityCounts["critical"] ?? 0, .dangerRed),
            ("High", severityCounts["high"] ?? 0, .warningOrange),
            ("Medium", severityCounts["medium"] ?? 0, .yellow),
            ("Low", severityCounts["low"] ?? 0, .tertiaryAccent),
            ("Info", severityCounts["info"] ?? 0, .infoBlue)
        ]
    }
    
    var body: some View {
        Chart(chartData, id: \.0) { item in
            BarMark(
                x: .value("Severity", item.0),
                y: .value("Count", animateChart ? item.1 : 0)
            )
            .foregroundStyle(item.2)
            .cornerRadius(4)
            .annotation(position: .top) {
                if item.1 > 0 {
                    Text("\(item.1)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(item.2)
                }
            }
        }
        .chartYScale(domain: 0...10)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                animateChart = true
            }
        }
    }
}

struct CurrentPhaseIndicator: View {
    let progress: Double
    
    var currentPhase: String {
        switch progress {
        case 0..<0.2: return "Initializing Scanner"
        case 0.2..<0.4: return "Crawling Website"
        case 0.4..<0.6: return "Testing Injection Points"
        case 0.6..<0.8: return "Analyzing Responses"
        case 0.8..<1.0: return "Finalizing Results"
        default: return "Scan Complete"
        }
    }
    
    var phaseIcon: String {
        switch progress {
        case 0..<0.2: return "gear"
        case 0.2..<0.4: return "safari"
        case 0.4..<0.6: return "syringe"
        case 0.6..<0.8: return "magnifyingglass"
        case 0.8..<1.0: return "checkmark.seal"
        default: return "checkmark.circle.fill"
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: phaseIcon)
                .font(.caption)
                .foregroundColor(.tertiaryAccent)
                .symbolEffect(.pulse)
            
            Text(currentPhase)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(8)
        .background(Color.tertiaryAccent.opacity(0.1))
        .cornerRadius(6)
    }
}

// MARK: - Results Section
struct VulnerabilityResultsSection: View {
    let vulnerabilities: [WebVulnerability]
    @State private var selectedVulnerability: WebVulnerability?
    @State private var showDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack {
                SectionHeader(
                    "Scan Results",
                    subtitle: "\(vulnerabilities.count) vulnerabilities found",
                    icon: "exclamationmark.triangle.fill"
                )
                
                Spacer()
                
                // Export options
                Menu {
                    Button("Export as PDF", action: {})
                    Button("Export as JSON", action: {})
                    Button("Export as CSV", action: {})
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                        .font(.subheadline)
                }
                .menuStyle(.borderlessButton)
            }
            .padding(.horizontal)
            
            // Summary Cards
            SummaryCardsSection(vulnerabilities: vulnerabilities)
            
            // Vulnerability List
            ModernCard {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Detailed Findings")
                        .font(.headline)
                    
                    ScrollView {
                        VStack(spacing: Spacing.small) {
                            ForEach(vulnerabilities) { vuln in
                                VulnerabilityRow(vulnerability: vuln) {
                                    // Reset state first to ensure state change
                                    selectedVulnerability = nil
                                    showDetails = false
                                    
                                    // Small delay to ensure state is reset
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                        selectedVulnerability = vuln
                                        showDetails = true
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                }
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $showDetails) {
            if let vuln = selectedVulnerability {
                VulnerabilityDetailsView(vulnerability: vuln)
            }
        }
    }
}

struct SummaryCardsSection: View {
    let vulnerabilities: [WebVulnerability]
    
    var criticalCount: Int {
        vulnerabilities.filter { $0.severity == .critical }.count
    }
    
    var highCount: Int {
        vulnerabilities.filter { $0.severity == .high }.count
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.medium) {
                SummaryCard(
                    title: "Risk Score",
                    value: calculateRiskScore(),
                    subtitle: "Overall security rating",
                    icon: "gauge.high",
                    color: riskColor()
                )
                
                SummaryCard(
                    title: "Critical",
                    value: "\(criticalCount)",
                    subtitle: "Immediate action required",
                    icon: "exclamationmark.octagon",
                    color: .dangerRed
                )
                
                SummaryCard(
                    title: "High",
                    value: "\(highCount)",
                    subtitle: "Address soon",
                    icon: "exclamationmark.triangle",
                    color: .warningOrange
                )
                
                SummaryCard(
                    title: "Total",
                    value: "\(vulnerabilities.count)",
                    subtitle: "All findings",
                    icon: "list.bullet.circle",
                    color: .primaryAccent
                )
            }
            .padding(.horizontal)
        }
    }
    
    private func calculateRiskScore() -> String {
        let score = 100 - (criticalCount * 20 + highCount * 10)
        return "\(max(0, score))%"
    }
    
    private func riskColor() -> Color {
        let score = 100 - (criticalCount * 20 + highCount * 10)
        switch score {
        case 80...100: return .successGreen
        case 60..<80: return .yellow
        case 40..<60: return .warningOrange
        default: return .dangerRed
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    @State private var showValue = false
    
    var body: some View {
        ModernCard {
            VStack(alignment: .leading, spacing: Spacing.small) {
                HStack {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                    
                    Spacer()
                }
                
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .opacity(showValue ? 1 : 0)
                    .animation(.easeIn(duration: 0.5), value: showValue)
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 150)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.5).delay(0.1)) {
                showValue = true
            }
        }
    }
}

struct VulnerabilityRow: View {
    let vulnerability: WebVulnerability
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.medium) {
                // Severity indicator
                Circle()
                    .fill(vulnerability.severity.color)
                    .frame(width: 8, height: 8)
                    .glow(color: vulnerability.severity.color, radius: 4)
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(vulnerability.type)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(vulnerability.url)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Parameter
                if let param = vulnerability.parameter {
                    Text(param)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondaryText.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(isHovered ? Color.appSecondaryBackground : Color.clear)
            .cornerRadius(8)
            .scaleEffect(isHovered ? 1.01 : 1.0)
            .animation(Animations.quick, value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Models
struct ModernWebTest: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let severity: Vulnerability.Severity
    let description: String
    let owasp: String?
}

struct WebVulnerability: Identifiable {
    let id = UUID()
    let type: String
    let severity: Vulnerability.Severity
    let url: String
    let parameter: String?
    let evidence: String?
    let description: String
}

// MARK: - Detail Views
struct ModernWebTestDetailsView: View {
    let test: WebTest
    let targetURL: String
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    
    func severityColor(for severity: WebTest.WebTestSeverity) -> Color {
        switch severity {
        case .critical: return .dangerRed
        case .high: return .warningOrange
        case .medium: return .yellow
        case .low: return .tertiaryAccent
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(test.name)
                        .font(Typography.title2)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(severityColor(for: test.severity))
                            .frame(width: 6, height: 6)
                        Text(test.severity.rawValue.capitalized)
                            .font(.caption)
                            .foregroundColor(severityColor(for: test.severity))
                    }
                }
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
            .padding()
            .background(Color.appSecondaryBackground)
            
            ScrollView {
                VStack(spacing: Spacing.large) {
                    // Test details implementation
                    Text("Test configuration and execution details...")
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            
            // Execute button
            HStack {
                Spacer()
                
                GradientButton("Run Test", icon: "play.fill", gradient: Color.primaryGradient) {
                    // Execute single test
                    Task {
                        await appState.startWebScan(targetURL: targetURL, selectedTools: [test.name])
                    }
                    dismiss()
                }
            }
            .padding()
            .background(Color.appSecondaryBackground)
        }
        .frame(width: 600, height: 500)
        .background(Color.appPrimaryBackground)
    }
}

struct VulnerabilityDetailsView: View {
    let vulnerability: WebVulnerability
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(vulnerability.type)
                        .font(Typography.title2)
                    
                    Text(vulnerability.url)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
            .padding()
            .background(Color.appSecondaryBackground)
            
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.large) {
                    // Vulnerability details
                    ModernCard {
                        VStack(alignment: .leading, spacing: Spacing.medium) {
                            Text("Description")
                                .font(.headline)
                            
                            Text(vulnerability.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            if let evidence = vulnerability.evidence {
                                Text("Evidence")
                                    .font(.headline)
                                    .padding(.top)
                                
                                Text(evidence)
                                    .font(.system(size: 12, design: .monospaced))
                                    .padding()
                                    .background(Color.codeSurface)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .frame(width: 700, height: 600)
        .background(Color.appPrimaryBackground)
    }
}

// MARK: - Web Scan Console View
struct WebScanConsoleView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Web Scan Console")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 12) {
                        if !appState.currentWebTestName.isEmpty {
                            Label(appState.currentWebTestName, systemImage: "checkmark.shield")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if !appState.currentWebTarget.isEmpty {
                            Label(appState.currentWebTarget, systemImage: "globe")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if appState.isWebScanning {
                            HStack(spacing: 4) {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("Scanning...")
                                    .font(.caption)
                                    .foregroundColor(.tertiaryAccent)
                            }
                        } else {
                            Label("Idle", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
            .padding()
            .background(Color.appSecondaryBackground)
            
            Divider()
            
            // Progress
            if appState.isWebScanning {
                VStack(spacing: 4) {
                    HStack {
                        Text("Overall Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(appState.webScanProgress * 100))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    
                    ProgressView(value: appState.webScanProgress)
                        .progressViewStyle(.linear)
                        .tint(Color.primaryGradient)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            
            Divider()
            
            // Output Terminal
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(appState.currentToolOutput.enumerated()), id: \.offset) { index, line in
                            WebOutputLine(text: line)
                                .id(index)
                        }
                        
                        if appState.currentToolOutput.isEmpty && appState.isWebScanning {
                            Text("Initializing web scan...")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
                .background(Color.black.opacity(0.95))
                .onChange(of: appState.currentToolOutput) { _, _ in
                    withAnimation {
                        proxy.scrollTo(appState.currentToolOutput.count - 1, anchor: .bottom)
                    }
                }
            }
        }
        .frame(width: 800, height: 600)
        .background(Color.appPrimaryBackground)
    }
}

struct WebOutputLine: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 13, design: .monospaced))
            .foregroundColor(lineColor)
            .textSelection(.enabled)
    }
    
    private var lineColor: Color {
        if text.contains("❌") || text.contains("ERROR") || text.contains("FAILED") {
            return .red
        } else if text.contains("✅") || text.contains("SUCCESS") || text.contains("FOUND") {
            return .green
        } else if text.contains("⚠️") || text.contains("WARNING") {
            return .yellow
        } else if text.contains("🔧") || text.contains("📍") || text.contains("💡") {
            return .tertiaryAccent
        } else if text.contains("→") || text.contains("•") {
            return .primaryAccent
        } else {
            return .primary
        }
    }
}

#Preview {
    UltraModernWebTesting()
        .environment(AppState())
        .frame(width: 1200, height: 800)
}