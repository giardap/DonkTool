//
//  DoSTestingView.swift
//  DonkTool
//
//  Denial of Service Testing View for authorized penetration testing
//

import SwiftUI

struct DoSTestingView: View {
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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // CRITICAL ETHICAL NOTICE
                ethicalNoticeCard
                
                // Target Configuration
                targetConfigurationSection
                
                // Test Configuration
                testConfigurationSection
                
                // Attack Selection with improved layout
                attackSelectionSection
                
                // Authorization Section
                authorizationSection
                
                // Control Buttons
                controlButtonsSection
                
                // Console Output Section
                if showConsole || dosManager.isRunning || !dosManager.consoleOutput.isEmpty {
                    consoleSection
                }
                
                // Results Section
                if !testResults.isEmpty {
                    resultsSection
                }
            }
            .padding(.spacing_lg)
        }
        .navigationTitle("DoS/Stress Testing")
        .background(Color.primaryBackground)
        .preferredColorScheme(.dark)
        .onAppear {
            // Simple tool status refresh without forcing updates
            if ToolDetection.shared.toolStatus.isEmpty {
                Task {
                    await ToolDetection.shared.refreshToolStatus()
                }
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
                Task {
                    await executeDoSTests()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Do you have explicit written authorization to perform DoS testing on '\(selectedTarget)'? Unauthorized testing is illegal and can result in criminal charges.")
        }
    }
    
    private var ethicalNoticeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.title2)
                Text("AUTHORIZED USE ONLY")
                    .font(.headerSecondary)
                    .foregroundColor(.red)
            }
            
            Text("DoS testing tools are for defensive security assessment only. Use requires:")
                .font(.bodySecondary)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Written authorization from system owner")
                        .font(.captionPrimary)
                }
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Approved testing timeframe and scope")
                        .font(.captionPrimary)
                }
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Incident response procedures in place")
                        .font(.captionPrimary)
                }
            }
            
            Text("Unauthorized DoS attacks are illegal and can result in criminal charges.")
                .font(.captionPrimary)
                .foregroundColor(.red)
                .fontWeight(.semibold)
        }
        .padding(16)
        .background(Color.red.opacity(0.15))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.3), lineWidth: 2)
        )
    }
    
    private var targetConfigurationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "target")
                    .foregroundColor(.blue)
                    .font(.title3)
                Text("Target Configuration")
                    .font(.headerSecondary)
                Spacer()
            }
            
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Target Host:")
                            .font(.bodySecondary)
                        TextField("IP Address or Domain", text: $selectedTarget)
                            .textFieldStyle(.roundedBorder)
                            .background(Color.cardBackground)
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Port:")
                            .font(.bodySecondary)
                        TextField("Port", value: $selectedPort, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .background(Color.cardBackground)
                            .cornerRadius(8)
                            .frame(width: 80)
                    }
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Protocol:")
                            .font(.bodySecondary)
                        Picker("Protocol", selection: $selectedProtocol) {
                            ForEach(NetworkProtocolType.allCases, id: \.self) { protocolType in
                                Text(protocolType.rawValue).tag(protocolType)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
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
    
    private var testConfigurationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(.green)
                    .font(.title3)
                Text("Test Configuration")
                    .font(.headerSecondary)
                Spacer()
            }
            
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Intensity Level:")
                            .font(.bodySecondary)
                        Picker("Intensity", selection: $selectedIntensity) {
                            ForEach(DoSIntensity.allCases, id: \.self) { intensity in
                                Text(intensity.rawValue).tag(intensity)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(selectedIntensity.description)
                            .font(.captionPrimary)
                            .foregroundColor(.secondary)
                        Text("\(selectedIntensity.threadCount) threads, \(selectedIntensity.requestsPerSecond) req/s")
                            .font(.captionSecondary)
                            .foregroundColor(selectedIntensity.color)
                            .fontWeight(.medium)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Duration:")
                            .font(.bodySecondary)
                        Spacer()
                        Text("\(Int(testDuration)) seconds")
                            .font(.bodySecondary)
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $testDuration, in: 10...300, step: 10) {
                        Text("Duration")
                    }
                    
                    if testDuration > 180 {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text("Long duration tests may cause service disruption")
                                .font(.captionPrimary)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
        }
        .cardStyle()
    }
    
    private var attackSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.orange)
                    .font(.title3)
                Text("Attack Vector Selection")
                    .font(.headerSecondary)
                
                Spacer()
                
                Button(action: {
                    Task {
                        await ToolDetection.shared.refreshToolStatus()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh Tools")
                    }
                    .font(.captionPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
                }
                
                Text("\(selectedTestTypes.count) selected")
                    .font(.captionPrimary)
                    .foregroundColor(.secondary)
            }
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search attack vectors...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .background(Color.cardBackground)
                    .cornerRadius(8)
            }
            
            // Category Filter - Horizontal scrollable
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // "All" button
                    Button(action: {
                        selectedCategory = nil
                        updateSelectedTests()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.grid.2x2")
                            Text("All")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedCategory == nil ? Color.blue : Color.cardBackground.opacity(0.6))
                        .foregroundColor(selectedCategory == nil ? .white : .primary)
                        .cornerRadius(8)
                    }
                    
                    ForEach(DoSAttackCategory.allCases, id: \.self) { category in
                        Button(action: {
                            selectedCategory = selectedCategory == category ? nil : category
                            updateSelectedTests()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: category.icon)
                                Text(category.rawValue)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedCategory == category ? category.color : Color.cardBackground.opacity(0.6))
                            .foregroundColor(selectedCategory == category ? .white : .primary)
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal, 1)
            }
            
            // Attack Vector Grid - Much better organized
            let filteredTests = filteredDoSTests
            if filteredTests.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    Text("No attack vectors found")
                        .font(.headerSecondary)
                    Text("Try adjusting your search or category filter")
                        .font(.bodySecondary)
                        .foregroundColor(.secondary)
                }
                .padding(40)
                .frame(maxWidth: .infinity)
                .background(Color.cardBackground)
                .cornerRadius(12)
            } else {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2),
                    spacing: 16
                ) {
                    ForEach(filteredTests, id: \.self) { testType in
                        AttackTypeCard(
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
        }
        .cardStyle()
    }
    
    private var authorizationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(.red)
                    .font(.title3)
                Text("Legal Authorization")
                    .font(.headerSecondary)
                    .foregroundColor(.red)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $ethicalUseAgreed) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("I agree to use these tools ethically and legally")
                            .font(.bodySecondary)
                        Text("Following responsible disclosure and professional standards")
                            .font(.captionPrimary)
                            .foregroundColor(.secondary)
                    }
                }
                
                Toggle(isOn: $authorizationConfirmed) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("I have written authorization to test this target")
                            .font(.bodySecondary)
                        Text("Explicit permission from system owner with defined scope")
                            .font(.captionPrimary)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if !authorizationConfirmed || !ethicalUseAgreed {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    Text("Complete authorization requirements before testing")
                        .font(.captionPrimary)
                        .foregroundColor(.red)
                        .fontWeight(.medium)
                }
                .padding(8)
                .background(Color.red.opacity(0.15))
                .cornerRadius(6)
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Authorization confirmed - ready for testing")
                        .font(.captionPrimary)
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                }
                .padding(8)
                .background(Color.green.opacity(0.15))
                .cornerRadius(6)
            }
        }
        .padding(16)
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var controlButtonsSection: some View {
        VStack(spacing: 12) {
            if !canStartTest {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.orange)
                        Text("Complete all requirements before testing:")
                            .font(.bodySecondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        if selectedTarget.isEmpty {
                            Text("• Enter target host")
                                .font(.captionPrimary)
                                .foregroundColor(.secondary)
                        }
                        if selectedTestTypes.isEmpty {
                            Text("• Select at least one attack vector")
                                .font(.captionPrimary)
                                .foregroundColor(.secondary)
                        }
                        if !authorizationConfirmed {
                            Text("• Confirm written authorization")
                                .font(.captionPrimary)
                                .foregroundColor(.secondary)
                        }
                        if !ethicalUseAgreed {
                            Text("• Agree to ethical use policy")
                                .font(.captionPrimary)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(8)
            }
            
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    Button(action: startDoSTest) {
                        HStack(spacing: 8) {
                            if isRunning {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "play.fill")
                            }
                            Text(isRunning ? "Testing in Progress..." : "Start DoS Test")
                                .font(.headerTertiary)
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity)
                        .background(canStartTest && !isRunning ? Color.red : Color.gray)
                        .cornerRadius(12)
                    }
                    .disabled(!canStartTest || isRunning)
                    
                    if isRunning {
                        Button(action: stopDoSTest) {
                            HStack(spacing: 8) {
                                Image(systemName: "stop.fill")
                                Text("Stop Test")
                                    .font(.headerTertiary)
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .frame(maxWidth: .infinity)
                            .background(Color.orange)
                            .cornerRadius(12)
                        }
                    }
                }
                
                // Console and utility buttons
                HStack(spacing: 12) {
                    Button(action: {
                        showConsole.toggle()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: showConsole ? "terminal.fill" : "terminal")
                            Text(showConsole ? "Hide Console" : "Show Console")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(showConsole ? Color.blue : Color.gray.opacity(0.3))
                        .foregroundColor(showConsole ? .white : .primary)
                        .cornerRadius(8)
                    }
                    
                    if !dosManager.consoleOutput.isEmpty {
                        Button(action: {
                            dosManager.clearConsole()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "trash")
                                Text("Clear Console")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(8)
                        }
                    }
                    
                    Spacer()
                    
                    if dosManager.isRunning {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.7)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Progress: \(Int(dosManager.progress * 100))%")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                if !dosManager.currentCommand.isEmpty {
                                    Text("Running: \(dosManager.currentTest?.rawValue ?? "Unknown")")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    private var consoleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "terminal.fill")
                    .foregroundColor(.green)
                    .font(.title3)
                Text("Attack Console")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if dosManager.isRunning {
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
            
            VStack(alignment: .leading, spacing: 12) {
                if !dosManager.currentCommand.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Command:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        Text(dosManager.currentCommand)
                            .font(.system(.caption, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                
                ScrollView {
                    ScrollViewReader { proxy in
                        VStack(alignment: .leading, spacing: 0) {
                            if dosManager.consoleOutput.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "terminal")
                                        .font(.system(size: 32))
                                        .foregroundColor(.secondary)
                                    Text("Console output will appear here")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text("Start a DoS test to see real-time attack progress")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(40)
                            } else {
                                Text(dosManager.consoleOutput)
                                    .font(.system(.caption, design: .monospaced))
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                                    .id("consoleBottom")
                            }
                        }
                        .onChange(of: dosManager.consoleOutput) { _, _ in
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo("consoleBottom", anchor: .bottom)
                            }
                        }
                    }
                }
                .frame(height: 300)
                .background(Color.black.opacity(0.9))
                .foregroundColor(.green)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .cardStyle()
    }
    
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Test Results")
                .font(.headline)
                .fontWeight(.semibold)
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(testResults) { result in
                        DoSResultCard(result: result)
                    }
                }
            }
            .frame(maxHeight: 400)
        }
        .cardStyle()
    }
    
    private var filteredDoSTests: [DoSTestType] {
        var tests = DoSTestType.allCases
        
        // Filter by category
        if let category = selectedCategory {
            tests = tests.filter { $0.attackCategory == category }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            tests = tests.filter { 
                $0.rawValue.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText) ||
                $0.toolRequired.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return tests
    }
    
    private var canStartTest: Bool {
        return !selectedTarget.isEmpty &&
               !selectedTestTypes.isEmpty &&
               authorizationConfirmed &&
               ethicalUseAgreed &&
               !isRunning
    }
    
    private func updateSelectedTests() {
        // Keep current selection when filtering
    }
    
    private func startDoSTest() {
        guard canStartTest else { return }
        
        // Check if any selected tools are missing
        let missingTools = selectedTestTypes.filter { testType in
            !ToolDetection.shared.isToolInstalled(testType.toolRequired)
        }
        
        if !missingTools.isEmpty {
            // Show tool installation status
            let toolNames = missingTools.map { $0.toolRequired }.joined(separator: ", ")
            print("Missing tools: \(toolNames)")
            // Could show an alert here in the future
        }
        
        showingEthicalWarning = true
    }
    
    private func stopDoSTest() {
        isRunning = false
        dosManager.stopAllAttacks()
    }
    
    @MainActor
    private func executeDoSTests() async {
        isRunning = true
        showConsole = true  // Auto-show console when starting tests
        
        // Execute tests on background task to avoid blocking UI
        await Task.detached {
            let selectedTypes = await self.selectedTestTypes
            let duration = await self.testDuration
            let intensity = await self.selectedIntensity
            let target = await self.selectedTarget
            let port = await self.selectedPort
            let protocolType = await self.selectedProtocol
            let authConfirmed = await self.authorizationConfirmed
            let ethicalAgreed = await self.ethicalUseAgreed
            let manager = await self.dosManager
            
            for testType in selectedTypes {
                let config = DoSTestConfiguration(
                    testType: testType,
                    duration: duration,
                    intensity: intensity,
                    target: target,
                    port: port,
                    protocolType: protocolType,
                    customParameters: [:],
                    authorizationConfirmed: authConfirmed,
                    ethicalUseAgreed: ethicalAgreed
                )
                
                guard config.isValid else { continue }
                
                let result = await manager.executeTest(config: config)
                
                await MainActor.run {
                    self.testResults.append(result)
                }
            }
            
            await MainActor.run {
                self.isRunning = false
            }
        }.value
    }
}

struct AttackTypeCard: View {
    let testType: DoSTestType
    let isSelected: Bool
    let isInstalled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: testType.attackCategory.icon)
                        .foregroundColor(testType.attackCategory.color)
                        .font(.title3)
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title3)
                        }
                        
                        if !isInstalled {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                    }
                }
                
                // Title
                Text(testType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                // Description
                Text(testType.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                // Footer
                HStack {
                    // Severity badge
                    Text(testType.severity.rawValue)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(testType.severity.color.opacity(0.2))
                        .foregroundColor(testType.severity.color)
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    // Tool name
                    Text(testType.toolRequired)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                }
                
                // Installation status
                if !isInstalled {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text("\(testType.toolRequired) not found")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .fontWeight(.medium)
                    }
                    .padding(.top, 4)
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.green)
                        Text("\(testType.toolRequired) ready")
                            .font(.caption2)
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(16)
            .background(
                isSelected ? Color.blue.opacity(0.2) : 
                Color.cardBackground.opacity(0.8)
            )
            .foregroundColor(.primary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.blue : 
                        isInstalled ? Color.gray.opacity(0.3) : Color.orange.opacity(0.5), 
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
        }
        .disabled(!isInstalled)
        .opacity(isInstalled ? 1.0 : 0.8)
    }
}

struct DoSResultCard: View {
    let result: DoSTestResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.testType.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Target: \(result.target)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Duration: \(Int(result.duration))s")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(result.riskAssessment.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(result.riskAssessment.color.opacity(0.2))
                        .foregroundColor(result.riskAssessment.color)
                        .cornerRadius(6)
                    
                    if result.vulnerabilityDetected {
                        Text("Vulnerable")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                    } else {
                        Text("Resilient")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
            }
            
            // Performance Metrics
            if let rps = result.requestsPerSecond, let successRate = result.successRate {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("RPS")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(rps)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Success Rate")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(successRate * 100))%")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(successRate > 0.9 ? .green : successRate > 0.7 ? .orange : .red)
                    }
                    
                    if let avgResponse = result.averageResponseTime {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Avg Response")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(String(format: "%.2f", avgResponse))s")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(avgResponse < 1.0 ? .green : avgResponse < 3.0 ? .orange : .red)
                        }
                    }
                    
                    Spacer()
                }
            }
            
            // Mitigation Suggestions
            if !result.mitigationSuggestions.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mitigation Suggestions:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    ForEach(result.mitigationSuggestions.prefix(3), id: \.self) { suggestion in
                        Text("• \(suggestion)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.elevatedBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
    }
}

#Preview {
    DoSTestingView()
        .environment(AppState())
}