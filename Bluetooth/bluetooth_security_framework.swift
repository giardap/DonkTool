import Foundation
import CoreBluetooth
import IOBluetooth
import Network

// MARK: - Core Bluetooth Security Framework

@Observable
class BluetoothSecurityFramework: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    // Published properties for SwiftUI binding
    var discoveredDevices: [BluetoothDevice] = []
    var activeScans: [BluetoothScan] = []
    var vulnerabilityFindings: [BluetoothVulnerability] = []
    var isScanning = false
    var scanProgress: Double = 0.0
    
    // Core Bluetooth components
    private var centralManager: CBCentralManager?
    private var discoveredPeripherals: [String: CBPeripheral] = [:]
    private var connectedPeripherals: [String: CBPeripheral] = [:]
    
    // Security testing components
    private let vulnerabilityScanner = BluetoothVulnerabilityScanner()
    private let exploitEngine = BluetoothExploitEngine()
    private let toolsManager = BluetoothToolsManager()
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.global(qos: .background))
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is powered on and ready")
        case .poweredOff:
            print("Bluetooth is powered off")
            isScanning = false
        case .unauthorized:
            print("Bluetooth access unauthorized")
        case .unsupported:
            print("Bluetooth not supported on this device")
        case .resetting:
            print("Bluetooth is resetting")
        case .unknown:
            print("Bluetooth state unknown")
        @unknown default:
            print("Unknown Bluetooth state")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let deviceId = peripheral.identifier.uuidString
        
        // Avoid duplicates
        if discoveredPeripherals[deviceId] != nil { return }
        
        discoveredPeripherals[deviceId] = peripheral
        peripheral.delegate = self
        
        // Create BluetoothDevice object
        let device = BluetoothDevice(
            macAddress: extractMACAddress(from: peripheral, advertisementData: advertisementData),
            name: peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String,
            rssi: RSSI.intValue,
            peripheral: peripheral,
            advertisementData: advertisementData,
            discoveryTime: Date()
        )
        
        DispatchQueue.main.async {
            self.discoveredDevices.append(device)
        }
        
        // Start vulnerability assessment
        Task {
            await assessDeviceVulnerabilities(device)
        }
    }
    
    // MARK: - Discovery and Scanning
    
    func startDiscovery(mode: DiscoveryMode = .active) async {
        guard centralManager?.state == .poweredOn else {
            print("Bluetooth not available")
            return
        }
        
        DispatchQueue.main.async {
            self.isScanning = true
            self.discoveredDevices.removeAll()
            self.discoveredPeripherals.removeAll()
        }
        
        switch mode {
        case .passive:
            await performBLEPassiveDiscovery()
        case .active:
            await performBLEActiveDiscovery()
        case .aggressive:
            await performAggressiveDiscovery()
        }
    }
    
    private func performBLEPassiveDiscovery() async {
        // BLE passive discovery
        centralManager?.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: false
        ])
        
        // Let it run for 30 seconds
        try? await Task.sleep(nanoseconds: 30_000_000_000)
        centralManager?.stopScan()
        
        DispatchQueue.main.async {
            self.isScanning = false
        }
    }
    
    private func performBLEActiveDiscovery() async {
        // Active BLE discovery with service enumeration
        await performBLEPassiveDiscovery()
        
        // Connect to discoverable devices for service enumeration
        for (_, peripheral) in discoveredPeripherals {
            centralManager?.connect(peripheral, options: nil)
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 second delay
        }
    }
    
    private func performAggressiveDiscovery() async {
        // Combine BLE discovery with classic Bluetooth scanning using tools
        await performBLEActiveDiscovery()
        await performClassicBluetoothDiscovery()
        await performHIDDiscovery()
    }
    
    private func performClassicBluetoothDiscovery() async {
        // Use hcitool for classic Bluetooth discovery
        let result = await toolsManager.executeHCITool(arguments: ["scan", "--length=8", "--flush"])
        let classicDevices = parseHCIToolOutput(result)
        
        DispatchQueue.main.async {
            for device in classicDevices {
                if !self.discoveredDevices.contains(where: { $0.macAddress == device.macAddress }) {
                    self.discoveredDevices.append(device)
                }
            }
        }
    }
    
    private func performHIDDiscovery() async {
        // Discover HID devices using specialized scanning
        let result = await toolsManager.executeBTScanner()
        let hidDevices = parseBTScannerOutput(result)
        
        DispatchQueue.main.async {
            for device in hidDevices {
                if !self.discoveredDevices.contains(where: { $0.macAddress == device.macAddress }) {
                    self.discoveredDevices.append(device)
                }
            }
        }
    }
    
    // MARK: - Vulnerability Assessment
    
    private func assessDeviceVulnerabilities(_ device: BluetoothDevice) async {
        let vulnerabilities = await vulnerabilityScanner.scanDevice(device)
        
        DispatchQueue.main.async {
            self.vulnerabilityFindings.append(contentsOf: vulnerabilities)
            
            // Update device with vulnerability count
            if let index = self.discoveredDevices.firstIndex(where: { $0.id == device.id }) {
                self.discoveredDevices[index].vulnerabilityCount = vulnerabilities.count
            }
        }
    }
    
    // MARK: - Utility Functions
    
    private func extractMACAddress(from peripheral: CBPeripheral, advertisementData: [String: Any]) -> String {
        // iOS doesn't expose real MAC addresses for privacy reasons
        // We'll use the peripheral identifier as a substitute
        return peripheral.identifier.uuidString
    }
    
    private func parseHCIToolOutput(_ output: String) -> [BluetoothDevice] {
        var devices: [BluetoothDevice] = []
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines {
            if line.contains(":") && line.count >= 17 {
                // Parse MAC address and device name from hcitool output
                let components = line.components(separatedBy: "\t")
                if components.count >= 2 {
                    let macAddress = components[0].trimmingCharacters(in: .whitespaces)
                    let deviceName = components[1].trimmingCharacters(in: .whitespaces)
                    
                    let device = BluetoothDevice(
                        macAddress: macAddress,
                        name: deviceName.isEmpty ? nil : deviceName,
                        rssi: -50, // Estimated
                        peripheral: nil,
                        advertisementData: [:],
                        discoveryTime: Date(),
                        isClassicBluetooth: true
                    )
                    devices.append(device)
                }
            }
        }
        
        return devices
    }
    
    private func parseBTScannerOutput(_ output: String) -> [BluetoothDevice] {
        // Parse btscanner output format
        var devices: [BluetoothDevice] = []
        // Implementation depends on btscanner output format
        return devices
    }
}

// MARK: - Bluetooth Device Model

struct BluetoothDevice: Identifiable, Equatable {
    let id = UUID()
    let macAddress: String
    let name: String?
    let rssi: Int
    let peripheral: CBPeripheral?
    let advertisementData: [String: Any]
    let discoveryTime: Date
    let isClassicBluetooth: Bool
    var vulnerabilityCount: Int = 0
    
    // Computed properties
    var deviceClass: BluetoothDeviceClass {
        return determineDeviceClass()
    }
    
    var bluetoothVersion: BluetoothVersion {
        return determineBluetoothVersion()
    }
    
    var services: [BluetoothService] {
        guard let peripheral = peripheral else { return [] }
        return extractServices(from: peripheral)
    }
    
    var isConnectable: Bool {
        return advertisementData[CBAdvertisementDataIsConnectable] as? Bool ?? false
    }
    
    var txPowerLevel: Int? {
        return advertisementData[CBAdvertisementDataTxPowerLevelKey] as? Int
    }
    
    var manufacturerData: Data? {
        return advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
    }
    
    init(macAddress: String, name: String?, rssi: Int, peripheral: CBPeripheral?, 
         advertisementData: [String: Any], discoveryTime: Date, isClassicBluetooth: Bool = false) {
        self.macAddress = macAddress
        self.name = name
        self.rssi = rssi
        self.peripheral = peripheral
        self.advertisementData = advertisementData
        self.discoveryTime = discoveryTime
        self.isClassicBluetooth = isClassicBluetooth
    }
    
    static func == (lhs: BluetoothDevice, rhs: BluetoothDevice) -> Bool {
        return lhs.macAddress == rhs.macAddress
    }
    
    private func determineDeviceClass() -> BluetoothDeviceClass {
        // Analyze manufacturer data, service UUIDs, and device name to determine class
        if let manufacturerData = manufacturerData {
            return classifyByManufacturerData(manufacturerData)
        }
        
        if let name = name?.lowercased() {
            return classifyByName(name)
        }
        
        return .unknown
    }
    
    private func determineBluetoothVersion() -> BluetoothVersion {
        // Analyze advertisement data to determine BT version
        if isClassicBluetooth {
            return .v2_1 // Most classic devices
        }
        
        // BLE devices
        if advertisementData.keys.contains(CBAdvertisementDataServiceUUIDsKey) {
            return .v4_0 // BLE minimum
        }
        
        return .unknown
    }
    
    private func extractServices(from peripheral: CBPeripheral) -> [BluetoothService] {
        var services: [BluetoothService] = []
        
        if let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
            for uuid in serviceUUIDs {
                services.append(BluetoothService(uuid: uuid.uuidString, name: getServiceName(for: uuid)))
            }
        }
        
        return services
    }
    
    private func classifyByManufacturerData(_ data: Data) -> BluetoothDeviceClass {
        // Apple devices
        if data.starts(with: [0x4C, 0x00]) { return .phone }
        // Samsung devices
        if data.starts(with: [0x75, 0x00]) { return .phone }
        // Fitbit devices
        if data.starts(with: [0x7D, 0x00]) { return .fitnessTracker }
        
        return .unknown
    }
    
    private func classifyByName(_ name: String) -> BluetoothDeviceClass {
        if name.contains("iphone") || name.contains("android") { return .phone }
        if name.contains("headset") || name.contains("headphone") { return .headset }
        if name.contains("speaker") { return .speaker }
        if name.contains("keyboard") { return .keyboard }
        if name.contains("mouse") { return .mouse }
        if name.contains("watch") { return .smartwatch }
        if name.contains("fitbit") || name.contains("tracker") { return .fitnessTracker }
        if name.contains("lock") { return .smartLock }
        if name.contains("light") || name.contains("bulb") { return .smartLight }
        if name.contains("car") || name.contains("auto") { return .automotive }
        
        return .unknown
    }
    
    private func getServiceName(for uuid: CBUUID) -> String {
        // Map common service UUIDs to names
        let serviceNames: [String: String] = [
            "180F": "Battery Service",
            "1800": "Generic Access",
            "1801": "Generic Attribute",
            "180A": "Device Information",
            "1812": "Human Interface Device",
            "110A": "Audio Source",
            "110B": "Audio Sink",
            "1108": "Headset",
            "111E": "Handsfree",
            "1200": "PnP Information"
        ]
        
        return serviceNames[uuid.uuidString] ?? "Unknown Service"
    }
}

// MARK: - Supporting Types

enum DiscoveryMode: String, CaseIterable {
    case passive = "Passive"
    case active = "Active" 
    case aggressive = "Aggressive"
    
    var description: String {
        switch self {
        case .passive: return "Listen for advertising devices"
        case .active: return "Actively probe discovered devices"
        case .aggressive: return "Comprehensive enumeration and testing"
        }
    }
}

enum BluetoothDeviceClass: String, CaseIterable {
    case computer = "Computer"
    case phone = "Phone"
    case headset = "Audio/Headset"
    case speaker = "Audio/Speaker"
    case keyboard = "Input/Keyboard"
    case mouse = "Input/Mouse"
    case smartwatch = "Wearable/Watch"
    case fitnessTracker = "Wearable/Fitness"
    case smartLock = "IoT/Lock"
    case smartLight = "IoT/Lighting"
    case medical = "Medical Device"
    case automotive = "Automotive"
    case industrial = "Industrial"
    case unknown = "Unknown"
    
    var iconName: String {
        switch self {
        case .computer: return "desktopcomputer"
        case .phone: return "iphone"
        case .headset: return "headphones"
        case .speaker: return "speaker"
        case .keyboard: return "keyboard"
        case .mouse: return "computermouse"
        case .smartwatch: return "applewatch"
        case .fitnessTracker: return "figure.walk"
        case .smartLock: return "lock"
        case .smartLight: return "lightbulb"
        case .medical: return "cross.case"
        case .automotive: return "car"
        case .industrial: return "gear"
        case .unknown: return "questionmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .computer: return .blue
        case .phone: return .green
        case .headset, .speaker: return .purple
        case .keyboard, .mouse: return .orange
        case .smartwatch, .fitnessTracker: return .pink
        case .smartLock, .smartLight: return .yellow
        case .medical: return .red
        case .automotive: return .black
        case .industrial: return .gray
        case .unknown: return .secondary
        }
    }
}

enum BluetoothVersion: String, CaseIterable {
    case v1_0 = "1.0"
    case v1_1 = "1.1"
    case v1_2 = "1.2"
    case v2_0 = "2.0 + EDR"
    case v2_1 = "2.1 + EDR"
    case v3_0 = "3.0 + HS"
    case v4_0 = "4.0 LE"
    case v4_1 = "4.1 LE"
    case v4_2 = "4.2 LE"
    case v5_0 = "5.0"
    case v5_1 = "5.1"
    case v5_2 = "5.2"
    case v5_3 = "5.3"
    case unknown = "Unknown"
    
    var isVulnerableToKNOB: Bool {
        switch self {
        case .v1_0, .v1_1, .v1_2, .v2_0, .v2_1, .v3_0, .v4_0, .v4_1, .v4_2:
            return true
        default:
            return false
        }
    }
}

struct BluetoothService: Identifiable {
    let id = UUID()
    let uuid: String
    let name: String
    let isPrimary: Bool
    let characteristics: [BluetoothCharacteristic]
    
    init(uuid: String, name: String, isPrimary: Bool = true, characteristics: [BluetoothCharacteristic] = []) {
        self.uuid = uuid
        self.name = name
        self.isPrimary = isPrimary
        self.characteristics = characteristics
    }
}

struct BluetoothCharacteristic: Identifiable {
    let id = UUID()
    let uuid: String
    let name: String
    let properties: CBCharacteristicProperties
    let value: Data?
}

struct BluetoothScan: Identifiable {
    let id = UUID()
    let startTime: Date
    let endTime: Date?
    let mode: DiscoveryMode
    let devicesFound: Int
    let vulnerabilitiesFound: Int
}

// MARK: - Tools Manager

class BluetoothToolsManager {
    private let toolsPath = "/usr/local/bin"
    
    func executeHCITool(arguments: [String]) async -> String {
        return await executeCommand(tool: "hcitool", arguments: arguments)
    }
    
    func executeSDPTool(arguments: [String]) async -> String {
        return await executeCommand(tool: "sdptool", arguments: arguments)
    }
    
    func executeBTScanner() async -> String {
        return await executeCommand(tool: "btscanner", arguments: ["-i"])
    }
    
    func executeRedfang(arguments: [String]) async -> String {
        return await executeCommand(tool: "redfang", arguments: arguments)
    }
    
    private func executeCommand(tool: String, arguments: [String]) async -> String {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                let process = Process()
                let pipe = Pipe()
                
                process.standardOutput = pipe
                process.standardError = pipe
                
                // Try different possible paths
                let possiblePaths = [
                    "/usr/local/bin/\(tool)",
                    "/opt/homebrew/bin/\(tool)",
                    "/usr/bin/\(tool)",
                    "~/bluetooth_tools/\(tool)/\(tool)"
                ]
                
                var launchPath: String?
                for path in possiblePaths {
                    let expandedPath = NSString(string: path).expandingTildeInPath
                    if FileManager.default.fileExists(atPath: expandedPath) {
                        launchPath = expandedPath
                        break
                    }
                }
                
                guard let validPath = launchPath else {
                    continuation.resume(returning: "Error: \(tool) not found")
                    return
                }
                
                process.launchPath = validPath
                process.arguments = arguments
                process.environment = ProcessInfo.processInfo.environment
                
                do {
                    try process.run()
                    
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8) ?? ""
                    
                    process.waitUntilExit()
                    continuation.resume(returning: output)
                } catch {
                    continuation.resume(returning: "Error executing \(tool): \(error.localizedDescription)")
                }
            }
        }
    }
}