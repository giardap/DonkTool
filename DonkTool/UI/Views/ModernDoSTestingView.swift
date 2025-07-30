//
//  ModernDoSTestingView.swift
//  DonkTool
//
//  Modern DoS/Stress testing interface with comprehensive tool support
//

import SwiftUI
import Charts

struct ModernDoSTestingView: View {
    @Environment(AppState.self) private var appState
    @ObservedObject private var dosManager = DoSTestManager.shared
    @State private var selectedTarget = ""
    @State private var selectedPort = 80
    @State private var selectedProtocol: NetworkProtocolType = .http
    @State private var selectedIntensity: DoSIntensity = .low
    @State private var testDuration: Double = 60
    @State private var selectedTestTypes: Set<DoSTestType> = []
    @State private var authorizationConfirmed = false
    @State private var ethicalUseAgreed = false
    @State private var isRunning = false
    @State private var testResults: [DoSTestResult] = []
    @State private var showingEthicalWarning = false
    @State private var showingAuthorizationDialog = false
    @State private var currentOutput = ""
    @State private var selectedCategory: DoSAttackCategory? = nil
    @State private var searchText = ""
    @State private var showConsole = false
    @State private var selectedTab = 0
    @State private var showingAdvancedConfig = false
    @State private var showingResults = false
    @State private var currentResults: DoSTestResults?
    @State private var showingExecutionSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with tabs
            ModernHeaderSection(selectedTab: $selectedTab)
            
            // Main content
            Group {
                switch selectedTab {
                case 0:
                    mainTestingView
                case 1:
                    toolsOverviewView
                case 2:
                    historyView
                default:
                    mainTestingView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.primaryBackground)
        }
        .sheet(isPresented: $showingAdvancedConfig) {
            DoSAdvancedConfigSheet(
                selectedTestTypes: $selectedTestTypes,
                intensity: $selectedIntensity,
                duration: $testDuration
            )
        }
        .sheet(isPresented: $showingResults) {
            if let results = currentResults {
                DoSResultsSheet(results: results)
            }
        }
        .alert("Ethical Use Warning", isPresented: $showingEthicalWarning) {
            Button("I Understand", role: .destructive) {
                showingAuthorizationDialog = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("DoS testing can disrupt services and may be illegal if performed without authorization. Only test systems you own or have explicit written permission to test.")
        }
        .alert("Authorization Confirmation", isPresented: $showingAuthorizationDialog) {
            Button("Confirm Authorization") {
                authorizationConfirmed = true
                showingExecutionSheet = true
                Task {
                    await executeDoSTests()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Do you have explicit written authorization to perform DoS testing on '\(selectedTarget)'? Unauthorized testing is illegal and can result in criminal charges.")
        }
        .sheet(isPresented: $showingExecutionSheet) {
            DoSExecutionView(
                dosManager: dosManager,
                isRunning: $isRunning,
                selectedTestTypes: selectedTestTypes,
                target: selectedTarget,
                onDismiss: {
                    showingExecutionSheet = false
                    if !testResults.isEmpty {
                        showingResults = true
                    }
                }
            )
        }
    }
    
    private var mainTestingView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Ethical Notice
                EthicalNoticeCard()
                
                // Target Configuration
                TargetConfigurationCard(
                    selectedTarget: $selectedTarget,
                    selectedPort: $selectedPort,
                    selectedProtocol: $selectedProtocol
                )
                
                // Attack Selection
                AttackSelectionCard(
                    selectedTestTypes: $selectedTestTypes,
                    selectedCategory: $selectedCategory,
                    searchText: $searchText
                )
                
                // Test Configuration
                TestConfigurationCard(
                    selectedIntensity: $selectedIntensity,
                    testDuration: $testDuration,
                    showingAdvancedConfig: $showingAdvancedConfig
                )
                
                // Authorization
                AuthorizationCard(
                    ethicalUseAgreed: $ethicalUseAgreed,
                    authorizationConfirmed: $authorizationConfirmed
                )
                
                // Control Buttons
                ControlButtonsSection(
                    canStartTest: canStartTest,
                    isRunning: dosManager.isRunning,
                    startTest: startDoSTest,
                    stopTest: stopDoSTest
                )
                
                // Live Metrics
                if dosManager.isRunning {
                    LiveMetricsCard()
                }
                
                // Console - Always show when running
                if showConsole || dosManager.isRunning || isRunning || !dosManager.consoleOutput.isEmpty {
                    ConsoleCard(
                        output: dosManager.consoleOutput,
                        isRunning: dosManager.isRunning || isRunning,
                        currentCommand: dosManager.currentCommand
                    )
                    .frame(minHeight: 300)
                    .animation(.spring(), value: dosManager.isRunning)
                }
            }
            .padding()
        }
    }
    
    private var toolsOverviewView: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Available DoS Testing Tools")
                    .font(.system(size: 24, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(DoSTestType.allCases, id: \.self) { testType in
                        ToolOverviewCard(testType: testType)
                    }
                }
                .padding()
            }
        }
    }
    
    private var historyView: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Attack History")
                    .font(.system(size: 24, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                if testResults.isEmpty {
                    EmptyHistoryView()
                } else {
                    ForEach(testResults) { result in
                        HistoryCard(result: result)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private var canStartTest: Bool {
        !selectedTarget.isEmpty &&
        !selectedTestTypes.isEmpty &&
        authorizationConfirmed &&
        ethicalUseAgreed &&
        !isRunning
    }
    
    private func startDoSTest() {
        guard canStartTest else { return }
        showingEthicalWarning = true
    }
    
    private func stopDoSTest() {
        isRunning = false
        dosManager.stopAllAttacks()
    }
    
    @MainActor
    private func executeDoSTests() async {
        isRunning = true
        showConsole = true  // Automatically show console when starting
        selectedTab = 0     // Switch to attack config tab to see console
        
        // Execute tests using DoSTestManager
        for testType in selectedTestTypes {
            let config = DoSTestConfiguration(
                testType: testType,
                duration: testDuration,
                intensity: selectedIntensity,
                target: selectedTarget,
                port: selectedPort,
                protocolType: selectedProtocol,
                customParameters: [:],
                authorizationConfirmed: authorizationConfirmed,
                ethicalUseAgreed: ethicalUseAgreed
            )
            
            guard config.isValid else { continue }
            
            let result = await dosManager.executeTest(config: config)
            testResults.append(result)
            
            // Update current results with real data
            if let rps = result.requestsPerSecond,
               let successRate = result.successRate {
                let totalRequests = rps * Int(result.duration)
                let successfulReqs = Int(Double(totalRequests) * successRate)
                
                currentResults = DoSTestResults(
                    attackType: result.testType,
                    target: result.target,
                    duration: result.duration,
                    requestsSent: totalRequests,
                    successfulRequests: successfulReqs,
                    averageResponseTime: result.averageResponseTime ?? 0,
                    peakResponseTime: (result.averageResponseTime ?? 0) * 2.5,
                    bytesTransferred: Int(result.bytesTransferred ?? 0)
                )
            }
        }
        
        isRunning = false
        if !testResults.isEmpty {
            showingExecutionSheet = false
            showingResults = true
        }
    }
}

// MARK: - Components

struct ModernHeaderSection: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        VStack(spacing: 0) {
            // Title
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DoS/Stress Testing")
                        .font(.system(size: 28, weight: .bold))
                    Text("Authorized penetration testing only")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.red)
            }
            .padding()
            
            // Tabs
            HStack(spacing: 0) {
                ForEach(0..<3) { index in
                    Button(action: { selectedTab = index }) {
                        VStack(spacing: 4) {
                            Image(systemName: tabIcon(for: index))
                                .font(.system(size: 20))
                            Text(tabTitle(for: index))
                                .font(.system(size: 12, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundColor(selectedTab == index ? .accentColor : .secondary)
                        .background(
                            VStack(spacing: 0) {
                                Color.clear
                                if selectedTab == index {
                                    Rectangle()
                                        .fill(Color.accentColor)
                                        .frame(height: 2)
                                }
                            }
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
        }
    }
    
    private func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "bolt.fill"
        case 1: return "wrench.and.screwdriver"
        case 2: return "clock.arrow.circlepath"
        default: return "questionmark"
        }
    }
    
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "Testing"
        case 1: return "Tools"
        case 2: return "History"
        default: return "Unknown"
        }
    }
}

struct EthicalNoticeCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.title2)
                Text("AUTHORIZED USE ONLY")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.red)
            }
            
            Text("DoS testing tools are for defensive security assessment only. Use requires:")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach([
                    "Written authorization from system owner",
                    "Approved testing timeframe and scope",
                    "Incident response procedures in place"
                ], id: \.self) { requirement in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 14))
                        Text(requirement)
                            .font(.system(size: 13))
                    }
                }
            }
            
            Text("Unauthorized DoS attacks are illegal and can result in criminal charges.")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.red)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}

struct TargetConfigurationCard: View {
    @Binding var selectedTarget: String
    @Binding var selectedPort: Int
    @Binding var selectedProtocol: NetworkProtocolType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Target Configuration", systemImage: "target")
                .font(.system(size: 20, weight: .semibold))
            
            VStack(spacing: 16) {
                // Target Input
                HStack {
                    Image(systemName: "globe")
                        .foregroundColor(.secondary)
                    
                    TextField("Enter target URL or IP address", text: $selectedTarget)
                        .textFieldStyle(.plain)
                }
                .padding(12)
                .background(Color(NSColor.windowBackgroundColor))
                .cornerRadius(8)
                
                // Port and Protocol
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Port")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        TextField("Port", value: $selectedPort, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Protocol")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Picker("Protocol", selection: $selectedProtocol) {
                            ForEach(NetworkProtocolType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: selectedProtocol) { _, newValue in
                            selectedPort = newValue.defaultPort
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .cardStyle()
    }
}

struct AttackSelectionCard: View {
    @Binding var selectedTestTypes: Set<DoSTestType>
    @Binding var selectedCategory: DoSAttackCategory?
    @Binding var searchText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Attack Vectors", systemImage: "bolt.fill")
                    .font(.system(size: 20, weight: .semibold))
                
                Spacer()
                
                Text("\(selectedTestTypes.count) selected")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search attack vectors...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
            
            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    DoSCategoryChip(
                        title: "All",
                        isSelected: selectedCategory == nil,
                        action: { selectedCategory = nil }
                    )
                    
                    ForEach(DoSAttackCategory.allCases, id: \.self) { category in
                        DoSCategoryChip(
                            title: category.rawValue,
                            isSelected: selectedCategory == category,
                            action: { selectedCategory = category }
                        )
                    }
                }
            }
            
            // Attack Grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(filteredTestTypes, id: \.self) { testType in
                        DoSAttackVectorCard(
                            testType: testType,
                            isSelected: selectedTestTypes.contains(testType),
                            isInstalled: ToolDetection.shared.isToolInstalled(testType.toolRequired)
                        ) {
                            if selectedTestTypes.contains(testType) {
                                selectedTestTypes.remove(testType)
                            } else {
                                selectedTestTypes.insert(testType)
                            }
                        }
                    }
                }
            }
            .frame(height: 300)
        }
        .cardStyle()
    }
    
    private var filteredTestTypes: [DoSTestType] {
        var types = DoSTestType.allCases
        
        if let category = selectedCategory {
            types = types.filter { $0.attackCategory == category }
        }
        
        if !searchText.isEmpty {
            types = types.filter {
                $0.rawValue.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return types
    }
}

struct TestConfigurationCard: View {
    @Binding var selectedIntensity: DoSIntensity
    @Binding var testDuration: Double
    @Binding var showingAdvancedConfig: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Test Configuration", systemImage: "gearshape.fill")
                    .font(.system(size: 20, weight: .semibold))
                
                Spacer()
                
                Button("Advanced") {
                    showingAdvancedConfig = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            HStack(spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Intensity")
                        .font(.system(size: 14, weight: .medium))
                    
                    Picker("Intensity", selection: $selectedIntensity) {
                        ForEach(DoSIntensity.allCases, id: \.self) { intensity in
                            Text(intensity.rawValue).tag(intensity)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Text(selectedIntensity.description)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Duration")
                            .font(.system(size: 14, weight: .medium))
                        Spacer()
                        Text("\(Int(testDuration)) seconds")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $testDuration, in: 10...300, step: 10)
                    
                    if testDuration > 180 {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 12))
                            Text("Long duration tests may cause service disruption")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.orange)
                    }
                }
            }
        }
        .cardStyle()
    }
}

struct AuthorizationCard: View {
    @Binding var ethicalUseAgreed: Bool
    @Binding var authorizationConfirmed: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Legal Authorization", systemImage: "checkmark.shield.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.red)
            
            VStack(spacing: 12) {
                Toggle(isOn: $ethicalUseAgreed) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("I agree to use these tools ethically and legally")
                            .font(.system(size: 14, weight: .medium))
                        Text("Following responsible disclosure and professional standards")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                Toggle(isOn: $authorizationConfirmed) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("I have written authorization to test this target")
                            .font(.system(size: 14, weight: .medium))
                        Text("Explicit permission from system owner with defined scope")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if !authorizationConfirmed || !ethicalUseAgreed {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    Text("Complete authorization requirements before testing")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                }
                .padding(8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .padding()
        .background(Color.red.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.2), lineWidth: 1)
        )
    }
}

struct ControlButtonsSection: View {
    let canStartTest: Bool
    let isRunning: Bool
    let startTest: () -> Void
    let stopTest: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: startTest) {
                HStack {
                    if isRunning {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "play.fill")
                    }
                    Text(isRunning ? "Testing in Progress..." : "Start DoS Test")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!canStartTest || isRunning)
            
            if isRunning {
                Button(action: stopTest) {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("Stop Test")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(.red)
            }
        }
    }
}

// Supporting components
struct DoSCategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

struct DoSAttackVectorCard: View {
    let testType: DoSTestType
    let isSelected: Bool
    let isInstalled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: testType.attackCategory.icon)
                        .foregroundColor(testType.attackCategory.color)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                
                Text(testType.rawValue)
                    .font(.system(size: 14, weight: .semibold))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                Text(testType.description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text(testType.severity.rawValue)
                        .font(.system(size: 10, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(testType.severity.color.opacity(0.2))
                        .foregroundColor(testType.severity.color)
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    if !isInstalled {
                        Label("Not Installed", systemImage: "exclamationmark.triangle")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding(12)
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isInstalled)
    }
}

struct LiveMetricsCard: View {
    @ObservedObject private var dosManager = DoSTestManager.shared
    @State private var lastResult: DoSTestResult?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Live Attack Metrics", systemImage: "chart.line.uptrend.xyaxis")
                .font(.system(size: 20, weight: .semibold))
            
            HStack(spacing: 16) {
                MetricDisplay(
                    title: "Requests/sec",
                    value: lastResult?.requestsPerSecond != nil ? "\(lastResult!.requestsPerSecond!)" : "0",
                    color: .blue
                )
                MetricDisplay(
                    title: "Success Rate",
                    value: String(format: "%.1f%%", (lastResult?.successRate ?? 0) * 100),
                    color: .green
                )
                MetricDisplay(
                    title: "Avg Response",
                    value: lastResult?.averageResponseTime != nil ? String(format: "%.0fms", lastResult!.averageResponseTime! * 1000) : "0ms",
                    color: .orange
                )
                MetricDisplay(
                    title: "Bandwidth",
                    value: formatBandwidth(Int(lastResult?.bytesTransferred ?? 0)),
                    color: .purple
                )
            }
            
            if dosManager.isRunning {
                // Progress bar
                ProgressView(value: dosManager.progress)
                    .progressViewStyle(.linear)
                    .tint(.blue)
                
                Text("Running: \(dosManager.currentTest?.rawValue ?? "Unknown") - \(Int(dosManager.progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .cardStyle()
    }
    
    private func formatBandwidth(_ bytesPerSecond: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        return "\(formatter.string(fromByteCount: Int64(bytesPerSecond)))/s"
    }
}

struct MetricDisplay: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ConsoleCard: View {
    let output: String
    let isRunning: Bool
    let currentCommand: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Attack Console", systemImage: "terminal.fill")
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                if isRunning {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.6)
                        Text("Live Output")
                            .font(.caption)
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    }
                }
            }
            
            if !currentCommand.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Command:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Text(currentCommand)
                        .font(.system(.caption, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            
            ScrollViewReader { proxy in
                ScrollView {
                    Text(output.isEmpty ? "Console output will appear here..." : output)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(output.isEmpty ? .secondary : .green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .id("consoleBottom")
                        .textSelection(.enabled)
                }
                .onChange(of: output) { _, _ in
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo("consoleBottom", anchor: .bottom)
                    }
                }
            }
            .frame(height: 300)
            .background(Color.black.opacity(0.9))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
        }
        .cardStyle()
    }
}

struct ToolOverviewCard: View {
    let testType: DoSTestType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: testType.attackCategory.icon)
                    .font(.system(size: 24))
                    .foregroundColor(testType.attackCategory.color)
                
                Spacer()
                
                if ToolDetection.shared.isToolInstalled(testType.toolRequired) {
                    Label("Installed", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                } else {
                    Label("Not Installed", systemImage: "xmark.circle")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }
            }
            
            Text(testType.rawValue)
                .font(.system(size: 16, weight: .semibold))
            
            Text(testType.description)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
            
            HStack {
                Label(testType.severity.rawValue, systemImage: "exclamationmark.triangle")
                    .font(.system(size: 11))
                    .foregroundColor(testType.severity.color)
                
                Spacer()
                
                Text(testType.toolRequired)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(height: 180)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct HistoryCard: View {
    let result: DoSTestResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.testType.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                    Text(result.target)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(result.startTime.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text(result.riskAssessment.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(result.riskAssessment.color.opacity(0.2))
                        .foregroundColor(result.riskAssessment.color)
                        .cornerRadius(4)
                }
            }
            
            if let successRate = result.successRate, let rps = result.requestsPerSecond {
                HStack(spacing: 24) {
                    Label("\(Int(successRate * 100))% Success", systemImage: "checkmark.circle")
                        .font(.system(size: 12))
                    
                    Label("\(rps) RPS", systemImage: "speedometer")
                        .font(.system(size: 12))
                    
                    Label("\(Int(result.duration))s", systemImage: "timer")
                        .font(.system(size: 12))
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No attack history yet")
                .font(.system(size: 18, weight: .medium))
            
            Text("Your DoS test results will appear here")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(60)
    }
}

struct DoSAdvancedConfigSheet: View {
    @Binding var selectedTestTypes: Set<DoSTestType>
    @Binding var intensity: DoSIntensity
    @Binding var duration: Double
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Advanced Configuration")
                    .font(.system(size: 20, weight: .semibold))
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Advanced settings per test type
                    ForEach(Array(selectedTestTypes), id: \.self) { testType in
                        VStack(alignment: .leading, spacing: 12) {
                            Label(testType.rawValue, systemImage: testType.attackCategory.icon)
                                .font(.system(size: 16, weight: .semibold))
                            
                            // Test-specific parameters would go here
                            Text("Advanced parameters for \(testType.rawValue)")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
        }
        .frame(width: 600, height: 500)
    }
}

struct DoSResultsSheet: View {
    let results: DoSTestResults
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Attack Results")
                        .font(.system(size: 24, weight: .semibold))
                    
                    Text("\(results.attackType.rawValue) - \(results.target)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button("Export") {
                        // Export results
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(24)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Results Content
            ScrollView {
                VStack(spacing: 20) {
                    // Summary Stats
                    HStack(spacing: 16) {
                        ResultStatCard(
                            label: "Total Requests",
                            value: "\(results.requestsSent)",
                            icon: "arrow.up.circle",
                            color: .blue
                        )
                        
                        ResultStatCard(
                            label: "Success Rate",
                            value: formatSuccessRate(results.successfulRequests, results.requestsSent),
                            icon: "checkmark.circle",
                            color: .green
                        )
                        
                        ResultStatCard(
                            label: "Avg Response",
                            value: "\(Int(results.averageResponseTime))ms",
                            icon: "timer",
                            color: .orange
                        )
                        
                        ResultStatCard(
                            label: "Data Transferred",
                            value: formatBytes(results.bytesTransferred),
                            icon: "arrow.up.arrow.down",
                            color: .purple
                        )
                    }
                    
                    // Analysis
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Target Response Analysis")
                            .font(.system(size: 16, weight: .semibold))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            AnalysisItem(
                                label: "Server resilience",
                                value: results.successfulRequests > Int(Double(results.requestsSent) * 0.8) ? "High" : "Moderate",
                                color: results.successfulRequests > Int(Double(results.requestsSent) * 0.8) ? .green : .orange
                            )
                            
                            AnalysisItem(
                                label: "Rate limiting detected",
                                value: results.averageResponseTime > 1000 ? "Yes" : "No",
                                color: results.averageResponseTime > 1000 ? .orange : .gray
                            )
                        }
                    }
                }
                .padding()
            }
        }
        .frame(width: 800, height: 600)
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    private func formatSuccessRate(_ successful: Int, _ total: Int) -> String {
        guard total > 0 else { return "0%" }
        let rate = Double(successful) / Double(total)
        let percentage = Int(rate * 100)
        return "\(percentage)%"
    }
}

struct ResultStatCard: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .semibold))
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )
    }
}

struct AnalysisItem: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Data Models

struct DoSTestResults {
    let attackType: DoSTestType
    let target: String
    let duration: Double
    let requestsSent: Int
    let successfulRequests: Int
    let averageResponseTime: Double
    let peakResponseTime: Double
    let bytesTransferred: Int
}

// MARK: - DoS Execution View
struct DoSExecutionView: View {
    @ObservedObject var dosManager: DoSTestManager
    @Binding var isRunning: Bool
    let selectedTestTypes: Set<DoSTestType>
    let target: String
    let onDismiss: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DoS Attack Execution")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 12) {
                        Label(target, systemImage: "network")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let currentTest = dosManager.currentTest {
                            Label(currentTest.rawValue, systemImage: "bolt.fill")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                        
                        Spacer()
                        
                        if dosManager.isRunning {
                            HStack(spacing: 4) {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("Running...")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
                
                Spacer()
                
                Button("Close") {
                    onDismiss()
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
            .padding()
            .background(Color.appSecondaryBackground)
            
            Divider()
            
            // Progress
            if dosManager.isRunning || isRunning {
                VStack(spacing: 8) {
                    HStack {
                        Text("Attack Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(dosManager.progress * 100))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    
                    ProgressView(value: dosManager.progress)
                        .progressViewStyle(.linear)
                        .tint(Color.orange)
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
            
            Divider()
            
            // Current Command
            if !dosManager.currentCommand.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Executing Command:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Text(dosManager.currentCommand)
                        .font(.system(size: 12, design: .monospaced))
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(6)
                        .textSelection(.enabled)
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
            
            Divider()
            
            // Console Output
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(dosManager.consoleOutput.split(separator: "\n").enumerated().map { ($0.offset, String($0.element)) }, id: \.0) { index, line in
                            DoSOutputLine(text: line)
                                .id(index)
                        }
                        
                        if dosManager.consoleOutput.isEmpty && dosManager.isRunning {
                            Text("Initializing DoS attack...")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
                .background(Color.black.opacity(0.95))
                .onChange(of: dosManager.consoleOutput) { _, _ in
                    withAnimation {
                        let lines = dosManager.consoleOutput.split(separator: "\n")
                        if !lines.isEmpty {
                            proxy.scrollTo(lines.count - 1, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Control Buttons
            HStack(spacing: 16) {
                if dosManager.isRunning {
                    Button(action: {
                        dosManager.stopAllAttacks()
                    }) {
                        Label("Stop Attack", systemImage: "stop.circle.fill")
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                Text("Tests: \(selectedTestTypes.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.appSecondaryBackground)
        }
        .frame(width: 800, height: 600)
        .background(Color.appPrimaryBackground)
    }
}

struct DoSOutputLine: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 12, design: .monospaced))
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
        } else if text.contains("🔧") || text.contains("💡") || text.contains("⚡") {
            return .orange
        } else if text.contains("→") || text.contains("•") {
            return .blue
        } else {
            return .primary
        }
    }
}

#Preview {
    ModernDoSTestingView()
        .environment(AppState())
        .frame(width: 1200, height: 800)
}