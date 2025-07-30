//
//  UltraModernBluetoothSecurity.swift
//  DonkTool
//
//  Ultra-modern Bluetooth security analysis interface with enhanced visualization
//

import SwiftUI
import Charts

struct UltraModernBluetoothSecurity: View {
    @Environment(AppState.self) private var appState
    @State private var selectedDevice: MacOSBluetoothDevice?
    @State private var discoveryMode: DiscoveryMode = .active
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var showOnlyVulnerable = false
    @State private var viewMode = ViewMode.grid
    @State private var showingDeviceDetails = false
    @State private var showingExploitExecution = false
    @State private var selectedExploit: BluetoothAttackVector?
    @State private var attackResults: [String: AttackExecutionResult] = [:]
    
    enum ViewMode: String, CaseIterable {
        case grid = "Grid"
        case list = "List"
        case map = "Map"
        
        var icon: String {
            switch self {
            case .grid: return "square.grid.2x2"
            case .list: return "list.bullet"
            case .map: return "map"
            }
        }
    }
    
    private var bluetoothFramework: MacOSBluetoothSecurityFramework {
        appState.bluetoothFramework
    }
    
    var filteredDevices: [MacOSBluetoothDevice] {
        var devices = bluetoothFramework.discoveredDevices
        
        if !searchText.isEmpty {
            devices = devices.filter { device in
                (device.name ?? "Unknown").localizedCaseInsensitiveContains(searchText) ||
                device.address.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if showOnlyVulnerable {
            devices = devices.filter { device in
                bluetoothFramework.vulnerabilityFindings.contains { $0.deviceAddress == device.address }
            }
        }
        
        return devices.sorted { $0.rssi > $1.rssi }
    }
    
    var vulnerableDeviceCount: Int {
        bluetoothFramework.discoveredDevices.filter { device in
            bluetoothFramework.vulnerabilityFindings.contains { $0.deviceAddress == device.address }
        }.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Modern Header
            ModernBluetoothHeader(
                isScanning: bluetoothFramework.isScanning,
                deviceCount: bluetoothFramework.discoveredDevices.count,
                vulnerableCount: vulnerableDeviceCount,
                discoveryMode: $discoveryMode,
                startScan: startScan,
                stopScan: stopScan
            )
            
            // Tab Bar
            BluetoothTabBarView(selectedTab: $selectedTab)
            
            // Main Content
            TabView(selection: $selectedTab) {
                // Scanner Tab
                BluetoothScannerTab(
                    devices: filteredDevices,
                    selectedDevice: $selectedDevice,
                    searchText: $searchText,
                    showOnlyVulnerable: $showOnlyVulnerable,
                    viewMode: $viewMode,
                    showingDeviceDetails: $showingDeviceDetails
                )
                .tag(0)
                
                // CVE Database Tab
                BluetoothCVETabView()
                    .tag(1)
                
                // Attack Vectors Tab
                BluetoothAttackVectorsTab(
                    selectedDevice: $selectedDevice,
                    showingExploitExecution: $showingExploitExecution,
                    selectedExploit: $selectedExploit,
                    attackResults: $attackResults
                )
                .tag(2)
            }
            .tabViewStyle(.automatic)
        }
        .background(Color.appPrimaryBackground)
        .sheet(isPresented: $showingDeviceDetails) {
            if let device = selectedDevice {
                BluetoothDeviceDetailSheet(
                    device: device,
                    bluetoothFramework: bluetoothFramework,
                    onExploitSelected: { exploit in
                        // Reset state first to ensure state change
                        selectedExploit = nil
                        showingExploitExecution = false
                        
                        // Small delay to ensure state is reset
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            selectedExploit = exploit
                            showingExploitExecution = true
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showingExploitExecution) {
            if let exploit = selectedExploit, let device = selectedDevice {
                BluetoothExploitExecutionView(
                    device: device,
                    exploit: exploit,
                    result: attackResults["\(exploit.name)-\(device.address)"]
                )
            }
        }
        .onAppear {
            if !bluetoothFramework.isScanning {
                Task {
                    await bluetoothFramework.startDiscovery(mode: discoveryMode)
                }
            }
        }
    }
    
    private func startScan() {
        Task {
            await bluetoothFramework.startDiscovery(mode: discoveryMode)
        }
    }
    
    private func stopScan() {
        // Bluetooth framework handles stopping automatically
    }
}

// MARK: - Header

struct ModernBluetoothHeader: View {
    let isScanning: Bool
    let deviceCount: Int
    let vulnerableCount: Int
    @Binding var discoveryMode: DiscoveryMode
    let startScan: () -> Void
    let stopScan: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .font(.system(size: 36))
                            .foregroundColor(.blue)
                        
                        Text("Bluetooth Security")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    
                    Text("Advanced Bluetooth device analysis and vulnerability detection")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Live Stats
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("\(deviceCount)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        Text("Devices")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 4) {
                        Text("\(vulnerableCount)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(vulnerableCount > 0 ? .orange : .green)
                        
                        Text("Vulnerable")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Discovery Mode Picker
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mode")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("", selection: $discoveryMode) {
                            Text("Passive").tag(DiscoveryMode.passive)
                            Text("Active").tag(DiscoveryMode.active)
                            Text("Aggressive").tag(DiscoveryMode.aggressive)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 180)
                    }
                    
                    // Scan Button
                    Button(action: isScanning ? stopScan : startScan) {
                        Label(
                            isScanning ? "Stop Scan" : "Start Scan",
                            systemImage: isScanning ? "stop.circle.fill" : "play.circle.fill"
                        )
                        .foregroundColor(.white)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(isScanning ? .red : .green)
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Tab Bar

struct BluetoothTabBarView: View {
    @Binding var selectedTab: Int
    
    let tabs = [
        ("Scanner", "antenna.radiowaves.left.and.right"),
        ("CVE Database", "shield.checkerboard"),
        ("Attack Vectors", "bolt.shield")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                BluetoothTabButton(
                    title: tabs[index].0,
                    icon: tabs[index].1,
                    isSelected: selectedTab == index,
                    action: { selectedTab = index }
                )
            }
        }
        .background(Color.appSecondaryBackground)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.3)),
            alignment: .bottom
        )
    }
}

struct BluetoothTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                
                Text(title)
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

// MARK: - Scanner Tab

struct BluetoothScannerTab: View {
    let devices: [MacOSBluetoothDevice]
    @Binding var selectedDevice: MacOSBluetoothDevice?
    @Binding var searchText: String
    @Binding var showOnlyVulnerable: Bool
    @Binding var viewMode: UltraModernBluetoothSecurity.ViewMode
    @Binding var showingDeviceDetails: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Control Bar
            ScannerControlBar(
                searchText: $searchText,
                showOnlyVulnerable: $showOnlyVulnerable,
                viewMode: $viewMode,
                deviceCount: devices.count
            )
            
            // Device Display
            if devices.isEmpty {
                EmptyDeviceState()
            } else {
                switch viewMode {
                case .grid:
                    DeviceGridView(
                        devices: devices,
                        selectedDevice: $selectedDevice,
                        showingDeviceDetails: $showingDeviceDetails
                    )
                case .list:
                    DeviceListView(
                        devices: devices,
                        selectedDevice: $selectedDevice,
                        showingDeviceDetails: $showingDeviceDetails
                    )
                case .map:
                    DeviceMapView(
                        devices: devices,
                        selectedDevice: $selectedDevice
                    )
                }
            }
        }
    }
}

struct ScannerControlBar: View {
    @Binding var searchText: String
    @Binding var showOnlyVulnerable: Bool
    @Binding var viewMode: UltraModernBluetoothSecurity.ViewMode
    let deviceCount: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search devices...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .frame(maxWidth: 300)
            
            // Vulnerable Filter
            Toggle(isOn: $showOnlyVulnerable) {
                Label("Vulnerable Only", systemImage: "exclamationmark.shield")
            }
            .toggleStyle(.button)
            
            Spacer()
            
            // Device Count
            Text("\(deviceCount) devices")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
            
            // View Mode
            Picker("View", selection: $viewMode) {
                ForEach(UltraModernBluetoothSecurity.ViewMode.allCases, id: \.self) { mode in
                    Label(mode.rawValue, systemImage: mode.icon)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
}

// MARK: - Device Views

struct DeviceGridView: View {
    let devices: [MacOSBluetoothDevice]
    @Binding var selectedDevice: MacOSBluetoothDevice?
    @Binding var showingDeviceDetails: Bool
    @Environment(AppState.self) private var appState
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 280, maximum: 350))
            ], spacing: 16) {
                ForEach(devices, id: \.id) { device in
                    DeviceCard(
                        device: device,
                        isSelected: selectedDevice?.id == device.id,
                        vulnerabilityCount: appState.bluetoothFramework.vulnerabilityFindings
                            .filter { $0.deviceAddress == device.address }.count
                    ) {
                        // Reset state first to ensure state change
                        selectedDevice = nil
                        showingDeviceDetails = false
                        
                        // Small delay to ensure state is reset
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            selectedDevice = device
                            showingDeviceDetails = true
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct DeviceCard: View {
    let device: MacOSBluetoothDevice
    let isSelected: Bool
    let vulnerabilityCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: deviceIcon(for: device.deviceClass))
                        .font(.system(size: 24))
                        .foregroundColor(deviceColor(for: device.deviceClass))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(device.name ?? "Unknown Device")
                            .font(.system(size: 14, weight: .semibold))
                            .lineLimit(1)
                        
                        Text(device.address)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if vulnerabilityCount > 0 {
                        Label("\(vulnerabilityCount)", systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.orange)
                            .labelStyle(.iconOnly)
                            .help("\(vulnerabilityCount) vulnerabilities found")
                    }
                }
                
                // Signal Strength
                HStack {
                    SignalStrengthIndicator(rssi: device.rssi)
                    
                    Spacer()
                    
                    Text("\(device.rssi) dBm")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                // Tags
                HStack(spacing: 6) {
                    DeviceTag(
                        text: device.deviceClass.rawValue.capitalized,
                        color: .blue
                    )
                    
                    if device.isConnectable {
                        DeviceTag(
                            text: "Connectable",
                            color: .green
                        )
                    }
                    
                    DeviceTag(
                        text: device.isClassicBluetooth ? "Classic" : "BLE",
                        color: .purple
                    )
                }
            }
            .padding(16)
            .background(Color.appSurfaceBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color(NSColor.separatorColor), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
    
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
}

struct SignalStrengthIndicator: View {
    let rssi: Int
    
    var signalBars: Int {
        switch rssi {
        case -30...0: return 4
        case -50...(-31): return 3
        case -70...(-51): return 2
        case -90...(-71): return 1
        default: return 0
        }
    }
    
    var signalColor: Color {
        switch rssi {
        case -30...0: return .green
        case -50...(-31): return .yellow
        case -70...(-51): return .orange
        default: return .red
        }
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<4) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index < signalBars ? signalColor : Color.gray.opacity(0.3))
                    .frame(width: 3, height: CGFloat(6 + index * 2))
            }
        }
    }
}

struct DeviceTag: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.1))
            .cornerRadius(4)
    }
}

struct DeviceListView: View {
    let devices: [MacOSBluetoothDevice]
    @Binding var selectedDevice: MacOSBluetoothDevice?
    @Binding var showingDeviceDetails: Bool
    @Environment(AppState.self) private var appState
    
    var body: some View {
        List(devices, id: \.id) { device in
            DeviceListRow(
                device: device,
                isSelected: selectedDevice?.id == device.id,
                vulnerabilityCount: appState.bluetoothFramework.vulnerabilityFindings
                    .filter { $0.deviceAddress == device.address }.count
            ) {
                // Reset state first to ensure state change
                selectedDevice = nil
                showingDeviceDetails = false
                
                // Small delay to ensure state is reset
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    selectedDevice = device
                    showingDeviceDetails = true
                }
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
        .listStyle(.plain)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct DeviceListRow: View {
    let device: MacOSBluetoothDevice
    let isSelected: Bool
    let vulnerabilityCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Device Icon
                Image(systemName: deviceIcon(for: device.deviceClass))
                    .font(.system(size: 20))
                    .foregroundColor(deviceColor(for: device.deviceClass))
                    .frame(width: 30)
                
                // Device Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name ?? "Unknown Device")
                        .font(.system(size: 14, weight: .medium))
                    
                    HStack(spacing: 8) {
                        Text(device.address)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(device.deviceClass.rawValue.capitalized)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Stats
                HStack(spacing: 16) {
                    // Signal
                    VStack(alignment: .trailing, spacing: 2) {
                        SignalStrengthIndicator(rssi: device.rssi)
                        Text("\(device.rssi) dBm")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    // Vulnerabilities
                    if vulnerabilityCount > 0 {
                        VStack(alignment: .trailing, spacing: 2) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.orange)
                            Text("\(vulnerabilityCount) issues")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
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
}

struct DeviceMapView: View {
    let devices: [MacOSBluetoothDevice]
    @Binding var selectedDevice: MacOSBluetoothDevice?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background grid
                ForEach(0..<10) { row in
                    ForEach(0..<10) { col in
                        Rectangle()
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                            .frame(width: geometry.size.width / 10, height: geometry.size.height / 10)
                            .position(
                                x: CGFloat(col) * geometry.size.width / 10 + geometry.size.width / 20,
                                y: CGFloat(row) * geometry.size.height / 10 + geometry.size.height / 20
                            )
                    }
                }
                
                // Center point (your device)
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                // Devices positioned by signal strength
                ForEach(devices, id: \.id) { device in
                    DeviceMapNode(
                        device: device,
                        isSelected: selectedDevice?.id == device.id,
                        center: CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2),
                        maxRadius: min(geometry.size.width, geometry.size.height) / 2 - 50
                    ) {
                        selectedDevice = device
                    }
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct DeviceMapNode: View {
    let device: MacOSBluetoothDevice
    let isSelected: Bool
    let center: CGPoint
    let maxRadius: CGFloat
    let action: () -> Void
    
    var position: CGPoint {
        // Calculate distance based on signal strength
        let normalizedRSSI = CGFloat(max(min(device.rssi, -30), -100) + 100) / 70
        let distance = maxRadius * (1 - normalizedRSSI)
        
        // Random angle for positioning
        let angle = Double(device.address.hashValue % 360) * .pi / 180
        
        return CGPoint(
            x: center.x + distance * Darwin.cos(angle),
            y: center.y + distance * Darwin.sin(angle)
        )
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: deviceIcon(for: device.deviceClass))
                    .font(.system(size: 16))
                    .foregroundColor(deviceColor(for: device.deviceClass))
                
                Text(device.name ?? "Unknown")
                    .font(.system(size: 10))
                    .lineLimit(1)
                    .frame(maxWidth: 60)
            }
            .padding(8)
            .background(Color.appSurfaceBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color(NSColor.separatorColor), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 2)
        }
        .buttonStyle(.plain)
        .position(position)
    }
    
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
}

struct EmptyDeviceState: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Bluetooth Devices Found")
                .font(.system(size: 20, weight: .semibold))
            
            Text("Start scanning to discover nearby Bluetooth devices")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            if !appState.bluetoothFramework.isScanning {
                Button("Start Scan") {
                    Task {
                        await appState.bluetoothFramework.startDiscovery(mode: .active)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - CVE Database Tab

struct BluetoothCVETabView: View {
    @Environment(AppState.self) private var appState
    @State private var searchText = ""
    @State private var selectedSeverity: LiveCVEEntry.CVESeverity?
    @State private var showingExploitCode = false
    @State private var selectedCVE: LiveCVEEntry?
    
    var filteredCVEs: [LiveCVEEntry] {
        var cves = appState.liveCVEDatabase.currentCVEs
        
        if !searchText.isEmpty {
            cves = cves.filter { cve in
                cve.id.localizedCaseInsensitiveContains(searchText) ||
                cve.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let severity = selectedSeverity {
            cves = cves.filter { $0.severity == severity }
        }
        
        return cves.sorted { $0.baseScore > $1.baseScore }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // CVE Header
            CVEDatabaseHeader()
            
            // Filter Bar
            CVEFilterBar(
                searchText: $searchText,
                selectedSeverity: $selectedSeverity,
                cveCount: filteredCVEs.count
            )
            
            // CVE List
            if filteredCVEs.isEmpty {
                EmptyCVEState()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredCVEs) { cve in
                            CVECard(cve: cve) {
                                // Reset state first to ensure state change
                                selectedCVE = nil
                                showingExploitCode = false
                                
                                // Small delay to ensure state is reset
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    selectedCVE = cve
                                    showingExploitCode = true
                                }
                            }
                        }
                    }
                    .padding(24)
                }
                .background(Color(NSColor.controlBackgroundColor))
            }
        }
        .sheet(isPresented: $showingExploitCode) {
            if let cve = selectedCVE {
                CVEExploitSheet(cve: cve)
            }
        }
    }
}

struct CVEDatabaseHeader: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Bluetooth CVE Database")
                    .font(.system(size: 24, weight: .semibold))
                
                if let lastUpdate = appState.liveCVEDatabase.lastUpdate {
                    Text("Last updated: \(lastUpdate.formatted(date: .abbreviated, time: .shortened))")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // CVE Stats
            HStack(spacing: 20) {
                CVEStat(
                    value: "\(appState.liveCVEDatabase.criticalCVEs.count)",
                    label: "Critical",
                    color: .red
                )
                
                CVEStat(
                    value: "\(appState.liveCVEDatabase.highSeverityCVEs.count)",
                    label: "High",
                    color: .orange
                )
                
                CVEStat(
                    value: "\(appState.liveCVEDatabase.recentCVEs.count)",
                    label: "Recent",
                    color: .blue
                )
            }
            
            Button("Update Database") {
                Task {
                    await appState.liveCVEDatabase.updateCVEDatabase()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(appState.liveCVEDatabase.isUpdating)
        }
        .padding(24)
        .background(Color.appSurfaceBackground)
    }
}

struct CVEStat: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }
}

struct CVEFilterBar: View {
    @Binding var searchText: String
    @Binding var selectedSeverity: LiveCVEEntry.CVESeverity?
    let cveCount: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search CVEs...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .frame(maxWidth: 300)
            
            // Severity Filter
            Picker("Severity", selection: $selectedSeverity) {
                Text("All Severities").tag(LiveCVEEntry.CVESeverity?.none)
                ForEach(LiveCVEEntry.CVESeverity.allCases, id: \.self) { severity in
                    Text(severity.rawValue).tag(LiveCVEEntry.CVESeverity?.some(severity))
                }
            }
            .pickerStyle(.menu)
            .frame(width: 150)
            
            Spacer()
            
            Text("\(cveCount) CVEs")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
}

struct CVECard: View {
    let cve: LiveCVEEntry
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Text(cve.id)
                        .font(.system(size: 16, weight: .semibold))
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        // Severity Badge
                        Text(cve.severity.rawValue)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(cve.severity.color)
                            .cornerRadius(6)
                        
                        // CVSS Score
                        Text("CVSS: \(String(format: "%.1f", cve.baseScore))")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                    }
                }
                
                // Description
                Text(cve.description)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                // Footer
                HStack {
                    Label(
                        "Published: \(cve.published.formatted(date: .abbreviated, time: .omitted))",
                        systemImage: "calendar"
                    )
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if cve.exploitCode != nil {
                        Label("Exploit Available", systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(16)
            .background(Color.appSurfaceBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}

struct EmptyCVEState: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "shield.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No CVEs Found")
                .font(.system(size: 20, weight: .semibold))
            
            Text("Try adjusting your filters or updating the database")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Attack Vectors Tab

struct BluetoothAttackVectorsTab: View {
    @Binding var selectedDevice: MacOSBluetoothDevice?
    @Binding var showingExploitExecution: Bool
    @Binding var selectedExploit: BluetoothAttackVector?
    @Binding var attackResults: [String: AttackExecutionResult]
    
    var body: some View {
        if let device = selectedDevice {
            AttackVectorView(
                device: device,
                showingExploitExecution: $showingExploitExecution,
                selectedExploit: $selectedExploit,
                attackResults: $attackResults
            )
        } else {
            NoDeviceSelectedView()
        }
    }
}

struct AttackVectorView: View {
    let device: MacOSBluetoothDevice
    @Binding var showingExploitExecution: Bool
    @Binding var selectedExploit: BluetoothAttackVector?
    @Binding var attackResults: [String: AttackExecutionResult]
    @Environment(AppState.self) private var appState
    
    var availableAttacks: [BluetoothAttackVector] {
        // This would be dynamically generated based on device vulnerabilities
        return []
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Device Summary
                AttackTargetSummary(device: device)
                
                // Available Attacks
                VStack(alignment: .leading, spacing: 16) {
                    Text("Available Attack Vectors")
                        .font(.system(size: 20, weight: .semibold))
                    
                    if availableAttacks.isEmpty {
                        NoAttacksAvailable()
                    } else {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 300, maximum: 400))
                        ], spacing: 16) {
                            ForEach(availableAttacks) { attack in
                                AttackVectorCard(
                                    attack: attack,
                                    device: device,
                                    result: attackResults["\(attack.name)-\(device.address)"]
                                ) {
                                    // Reset state first to ensure state change
                                    selectedExploit = nil
                                    showingExploitExecution = false
                                    
                                    // Small delay to ensure state is reset
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                        selectedExploit = attack
                                        showingExploitExecution = true
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct AttackTargetSummary: View {
    let device: MacOSBluetoothDevice
    @Environment(AppState.self) private var appState
    
    var vulnerabilityCount: Int {
        appState.bluetoothFramework.vulnerabilityFindings
            .filter { $0.deviceAddress == device.address }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Attack Target")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.secondary)
            
            HStack(spacing: 20) {
                // Device Icon
                Image(systemName: deviceIcon(for: device.deviceClass))
                    .font(.system(size: 32))
                    .foregroundColor(deviceColor(for: device.deviceClass))
                
                // Device Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name ?? "Unknown Device")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text(device.address)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Vulnerability Badge
                if vulnerabilityCount > 0 {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(vulnerabilityCount)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.orange)
                        
                        Text("Vulnerabilities")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(16)
            .background(Color.appSurfaceBackground)
            .cornerRadius(12)
        }
    }
    
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
}

struct AttackVectorCard: View {
    let attack: BluetoothAttackVector
    let device: MacOSBluetoothDevice
    let result: AttackExecutionResult?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: attack.icon)
                        .font(.system(size: 20))
                        .foregroundColor(attack.severityColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(attack.name)
                            .font(.system(size: 14, weight: .semibold))
                        
                        if let cveId = attack.cveId {
                            Text(cveId)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if let result = result {
                        Image(systemName: result.status.icon)
                            .font(.system(size: 16))
                            .foregroundColor(result.status.color)
                    }
                }
                
                // Description
                Text(attack.description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // Footer
                HStack {
                    // Difficulty
                    Label(attack.difficulty.rawValue, systemImage: "gauge")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Action
                    if result?.status == .running {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Text("Execute")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(attack.severityColor)
                            .cornerRadius(6)
                    }
                }
            }
            .padding(16)
            .background(Color.appSurfaceBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .disabled(result?.status == .running)
    }
}

struct NoAttacksAvailable: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 32))
                .foregroundColor(.green)
            
            Text("No Attack Vectors Available")
                .font(.system(size: 16, weight: .semibold))
            
            Text("This device appears to be secure against known Bluetooth attacks")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.green.opacity(0.05))
        .cornerRadius(12)
    }
}

struct NoDeviceSelectedView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bolt.shield")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Device Selected")
                .font(.system(size: 20, weight: .semibold))
            
            Text("Select a Bluetooth device from the Scanner tab to view available attack vectors")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Detail Sheet

struct BluetoothDeviceDetailSheet: View {
    let device: MacOSBluetoothDevice
    let bluetoothFramework: MacOSBluetoothSecurityFramework
    let onExploitSelected: (BluetoothAttackVector) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var vulnerabilities: [MacOSBluetoothVulnerability] {
        bluetoothFramework.vulnerabilityFindings.filter { $0.deviceAddress == device.address }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: deviceIcon(for: device.deviceClass))
                    .font(.system(size: 32))
                    .foregroundColor(deviceColor(for: device.deviceClass))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name ?? "Unknown Device")
                        .font(.system(size: 24, weight: .semibold))
                    
                    Text(device.address)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(24)
            .background(Color.appSurfaceBackground)
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Device Information
                    DeviceInfoSection(device: device)
                    
                    // Vulnerabilities
                    BluetoothVulnerabilitiesSection(vulnerabilities: vulnerabilities)
                    
                    // Available Attacks
                    BluetoothAttackOptionsSection(
                        device: device,
                        vulnerabilities: vulnerabilities,
                        onExploitSelected: onExploitSelected
                    )
                }
                .padding(24)
            }
        }
        .frame(width: 800, height: 600)
    }
    
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
}

struct DeviceInfoSection: View {
    let device: MacOSBluetoothDevice
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Device Information")
                .font(.system(size: 18, weight: .semibold))
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                BluetoothInfoItem(label: "Device Class", value: device.deviceClass.rawValue.capitalized)
                BluetoothInfoItem(label: "Signal Strength", value: "\(device.rssi) dBm")
                BluetoothInfoItem(label: "Type", value: device.isClassicBluetooth ? "Classic Bluetooth" : "Bluetooth LE")
                BluetoothInfoItem(label: "Connectable", value: device.isConnectable ? "Yes" : "No")
                
                if let manufacturer = device.manufacturerName {
                    BluetoothInfoItem(label: "Manufacturer", value: manufacturer)
                }
            }
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct BluetoothInfoItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(size: 14, weight: .medium))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct BluetoothVulnerabilitiesSection: View {
    let vulnerabilities: [MacOSBluetoothVulnerability]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Security Analysis")
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                if vulnerabilities.isEmpty {
                    Label("Secure", systemImage: "checkmark.shield.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                } else {
                    Label("\(vulnerabilities.count) Issues", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.orange)
                }
            }
            
            if vulnerabilities.isEmpty {
                Text("No security issues detected")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
            } else {
                VStack(spacing: 12) {
                    ForEach(vulnerabilities) { vulnerability in
                        VulnerabilityCard(vulnerability: vulnerability)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct VulnerabilityCard: View {
    let vulnerability: MacOSBluetoothVulnerability
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: severityIcon(vulnerability.severity))
                    .foregroundColor(severityColor(vulnerability.severity))
                
                Text(vulnerability.title)
                    .font(.system(size: 14, weight: .medium))
                
                Spacer()
                
                Text(vulnerability.severity.rawValue.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(severityColor(vulnerability.severity))
                    .cornerRadius(4)
            }
            
            Text(vulnerability.description)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            if let cveId = vulnerability.cveId {
                Text(cveId)
                    .font(.system(size: 11))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(12)
        .background(Color.appSurfaceBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(severityColor(vulnerability.severity).opacity(0.3), lineWidth: 1)
        )
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

struct BluetoothAttackOptionsSection: View {
    let device: MacOSBluetoothDevice
    let vulnerabilities: [MacOSBluetoothVulnerability]
    let onExploitSelected: (BluetoothAttackVector) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bolt.shield.fill")
                    .foregroundColor(.red)
                
                Text("Attack Options")
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                Text("⚠️ Authorized Use Only")
                    .font(.system(size: 11))
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
            }
            
            Text("Available attack vectors based on device vulnerabilities")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Exploit Execution View

struct BluetoothExploitExecutionView: View {
    let device: MacOSBluetoothDevice
    let exploit: BluetoothAttackVector
    let result: AttackExecutionResult?
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ExploitExecutionHeader(
                exploit: exploit,
                device: device,
                result: result,
                dismiss: { dismiss() }
            )
            
            // Tab Selection
            Picker("", selection: $selectedTab) {
                Text("Output").tag(0)
                Text("Exploit Code").tag(1)
                Text("Payload").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Content
            TabView(selection: $selectedTab) {
                ExploitOutputView(result: result)
                    .tag(0)
                
                ExploitCodeView(code: exploit.exploitCode)
                    .tag(1)
                
                ExploitPayloadView(payload: exploit.payload)
                    .tag(2)
            }
            .tabViewStyle(.automatic)
        }
        .frame(width: 800, height: 600)
    }
}

struct ExploitExecutionHeader: View {
    let exploit: BluetoothAttackVector
    let device: MacOSBluetoothDevice
    let result: AttackExecutionResult?
    let dismiss: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: exploit.icon)
                .font(.system(size: 24))
                .foregroundColor(exploit.severityColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exploit.name)
                    .font(.system(size: 18, weight: .semibold))
                
                Text("Target: \(device.name ?? device.address)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let result = result {
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: result.status.icon)
                            .foregroundColor(result.status.color)
                        
                        Text(statusText(result.status))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(result.status.color)
                    }
                    
                    if result.status != .running {
                        Text("Duration: \(String(format: "%.1fs", result.duration))")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(20)
        .background(Color.appSurfaceBackground)
    }
    
    private func statusText(_ status: AttackExecutionResult.ExecutionStatus) -> String {
        switch status {
        case .running: return "Running"
        case .completed: return "Completed"
        case .failed: return "Failed"
        }
    }
}

struct ExploitOutputView: View {
    let result: AttackExecutionResult?
    
    var body: some View {
        ScrollView {
            if let result = result {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(result.output.enumerated()), id: \.offset) { index, line in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(width: 40, alignment: .trailing)
                            
                            Text(line)
                                .font(.system(size: 12, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 2)
                        .background(index % 2 == 0 ? Color.clear : Color.gray.opacity(0.05))
                    }
                }
            } else {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Waiting for execution...")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct ExploitCodeView: View {
    let code: String
    
    var body: some View {
        ScrollView {
            Text(code)
                .font(.system(size: 12, design: .monospaced))
                .textSelection(.enabled)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct ExploitPayloadView: View {
    let payload: String
    
    var body: some View {
        ScrollView {
            Text(payload)
                .font(.system(size: 12, design: .monospaced))
                .textSelection(.enabled)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - CVE Exploit Sheet

struct CVEExploitSheet: View {
    let cve: LiveCVEEntry
    @Environment(\.dismiss) private var dismiss
    @State private var exploitCode: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(cve.id)
                        .font(.system(size: 20, weight: .semibold))
                    
                    Text("Exploit Code Viewer")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button("Copy Code") {
                        NSPasteboard.general.setString(exploitCode, forType: .string)
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(20)
            .background(Color.appSurfaceBackground)
            
            Divider()
            
            // Warning
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                
                Text("WARNING: Use only for authorized penetration testing")
                    .font(.system(size: 12, weight: .medium))
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.orange.opacity(0.1))
            
            // Exploit Code
            ScrollView {
                Text(exploitCode)
                    .font(.system(size: 12, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 800, height: 600)
        .onAppear {
            generateExploitCode()
        }
    }
    
    private func generateExploitCode() {
        // This would generate appropriate exploit code based on the CVE
        exploitCode = """
        #!/usr/bin/env python3
        # Exploit for \(cve.id)
        # Severity: \(cve.severity.rawValue)
        # CVSS Score: \(cve.baseScore)
        
        import bluetooth
        import struct
        
        def exploit():
            # Exploit implementation
            pass
        
        if __name__ == "__main__":
            exploit()
        """
    }
}

// MARK: - Preview

#Preview {
    UltraModernBluetoothSecurity()
        .environment(AppState())
        .frame(width: 1200, height: 800)
}