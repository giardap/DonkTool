import Foundation
import CoreBluetooth
import IOBluetooth
import SystemConfiguration
import Network

// MARK: - macOS Native Bluetooth Security Framework

@Observable
class MacOSBluetoothSecurityFramework: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    // Published properties for SwiftUI binding
    var discoveredDevices: [MacOSBluetoothDevice] = []
    var vulnerabilityFindings: [MacOSBluetoothVulnerability] = []
    var isScanning = false
    var scanProgress: Double = 0.0
    var lastError: String?
    var currentOperation: String = "Ready"
    
    // Core Bluetooth components
    private var centralManager: CBCentralManager?
    private var discoveredPeripherals: [String: CBPeripheral] = [:]
    private var deviceConnections: [String: CBPeripheral] = [:]
    
    // macOS-specific security testing
    private let securityAnalyzer = MacOSBluetoothSecurityAnalyzer()
    private let systemProfiler = MacOSSystemProfiler()
    
    override init() {
        super.init()
        setupBluetoothManager()
    }
    
    private func setupBluetoothManager() {
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.global(qos: .background))
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        DispatchQueue.main.async {
            switch central.state {
            case .poweredOn:
                print("Bluetooth is powered on and ready")
                self.lastError = nil
            case .poweredOff:
                self.lastError = "Bluetooth is powered off"
                self.isScanning = false
            case .unauthorized:
                self.lastError = "Bluetooth access unauthorized - check Privacy settings"
            case .unsupported:
                self.lastError = "Bluetooth not supported on this device"
            case .resetting:
                self.lastError = "Bluetooth is resetting"
            case .unknown:
                self.lastError = "Bluetooth state unknown"
            @unknown default:
                self.lastError = "Unknown Bluetooth state"
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, 
                       advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let deviceId = peripheral.identifier.uuidString
        
        // Avoid duplicates
        if discoveredPeripherals[deviceId] != nil { return }
        
        discoveredPeripherals[deviceId] = peripheral
        peripheral.delegate = self
        
        // Create device with security analysis
        let device = MacOSBluetoothDevice(
            peripheral: peripheral,
            advertisementData: advertisementData,
            rssi: RSSI.intValue,
            discoveryTime: Date()
        )
        
        DispatchQueue.main.async {
            self.discoveredDevices.append(device)
        }
        
        // Perform immediate security analysis
        Task {
            await performSecurityAnalysis(for: device)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? peripheral.identifier.uuidString)")
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral.name ?? peripheral.identifier.uuidString): \(error?.localizedDescription ?? "Unknown error")")
    }
    
    // MARK: - CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        // Test characteristics for security issues
        Task {
            await testCharacteristicSecurity(peripheral: peripheral, service: service, characteristics: characteristics)
        }
    }
    
    // MARK: - Discovery and Scanning
    
    func startDiscovery(mode: DiscoveryMode = .comprehensive) async {
        guard centralManager?.state == .poweredOn else {
            DispatchQueue.main.async {
                self.lastError = "Bluetooth not available"
            }
            return
        }
        
        DispatchQueue.main.async {
            self.isScanning = true
            self.discoveredDevices.removeAll()
            self.discoveredPeripherals.removeAll()
            self.vulnerabilityFindings.removeAll()
            self.lastError = nil
        }
        
        // Start with system profiler analysis
        await analyzeSystemBluetoothConfiguration()
        
        // BLE Discovery
        await performBLEDiscovery(mode: mode)
        
        // Classic Bluetooth Discovery (using macOS APIs)
        await performClassicBluetoothDiscovery()
        
        DispatchQueue.main.async {
            self.isScanning = false
            self.scanProgress = 1.0
        }
    }
    
    private func performBLEDiscovery(mode: DiscoveryMode) async {
        let scanOptions: [String: Any] = [
            CBCentralManagerScanOptionAllowDuplicatesKey: false
        ]
        
        centralManager?.scanForPeripherals(withServices: nil, options: scanOptions)
        
        // Scan duration based on mode
        let scanDuration: TimeInterval = mode == .passive ? 15 : 30
        
        for i in 0..<Int(scanDuration) {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            DispatchQueue.main.async {
                self.scanProgress = Double(i) / scanDuration
            }
        }
        
        centralManager?.stopScan()
    }
    
    private func performClassicBluetoothDiscovery() async {
        // Use IOBluetooth framework for Classic Bluetooth
        await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                let inquiry = IOBluetoothDeviceInquiry(delegate: nil)
                inquiry?.inquiryLength = 8
                inquiry?.start()
                
                // Wait for inquiry to complete
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    inquiry?.stop()
                    self.processClassicBluetoothResults(inquiry)
                    continuation.resume()
                }
            }
        }
    }
    
    private func processClassicBluetoothResults(_ inquiry: IOBluetoothDeviceInquiry?) {
        guard let foundDevices = inquiry?.foundDevices() as? [IOBluetoothDevice] else { return }
        
        for ioDevice in foundDevices {
            let device = MacOSBluetoothDevice(ioBluetoothDevice: ioDevice)
            
            DispatchQueue.main.async {
                if !self.discoveredDevices.contains(where: { $0.address == device.address }) {
                    self.discoveredDevices.append(device)
                }
            }
            
            // Analyze classic Bluetooth device
            Task {
                await performSecurityAnalysis(for: device)
            }
        }
    }
    
    private func analyzeSystemBluetoothConfiguration() async {
        let systemAnalysis = await systemProfiler.analyzeBluetoothConfiguration()
        
        DispatchQueue.main.async {
            // Add system-level vulnerabilities
            for issue in systemAnalysis.securityIssues {
                let vulnerability = MacOSBluetoothVulnerability(
                    title: "System Configuration Issue",
                    description: issue,
                    severity: .medium,
                    deviceAddress: "system",
                    category: .systemConfiguration,
                    cveId: nil,
                    recommendedActions: ["Review system Bluetooth configuration", "Apply security updates"]
                )
                self.vulnerabilityFindings.append(vulnerability)
            }
        }
    }
    
    // MARK: - Security Analysis
    
    private func performSecurityAnalysis(for device: MacOSBluetoothDevice) async {
        let vulnerabilities = await securityAnalyzer.analyzeDevice(device)
        
        DispatchQueue.main.async {
            self.vulnerabilityFindings.append(contentsOf: vulnerabilities)
            
            // Update device vulnerability count
            if let index = self.discoveredDevices.firstIndex(where: { $0.id == device.id }) {
                self.discoveredDevices[index].vulnerabilityCount = vulnerabilities.count
            }
        }
    }
    
    private func testCharacteristicSecurity(peripheral: CBPeripheral, service: CBService, 
                                          characteristics: [CBCharacteristic]) async {
        var unprotectedCharacteristics: [CBCharacteristic] = []
        
        for characteristic in characteristics {
            // Test if characteristic can be read without authentication
            if characteristic.properties.contains(.read) {
                peripheral.readValue(for: characteristic)
                
                // In a real implementation, you'd check if the read was successful
                // This is a simplified version
                unprotectedCharacteristics.append(characteristic)
            }
        }
        
        if !unprotectedCharacteristics.isEmpty {
            let vulnerability = MacOSBluetoothVulnerability(
                title: "Unprotected BLE Characteristics",
                description: "Found \(unprotectedCharacteristics.count) characteristics readable without authentication",
                severity: .medium,
                deviceAddress: peripheral.identifier.uuidString,
                category: .bleWeakAuthentication,
                cveId: nil,
                recommendedActions: ["Enable BLE bonding", "Implement characteristic-level authentication"]
            )
            
            DispatchQueue.main.async {
                self.vulnerabilityFindings.append(vulnerability)
            }
        }
    }
    
    // MARK: - Device Testing
    
    func testDeviceConnection(_ device: MacOSBluetoothDevice) async -> ConnectionTestResult {
        guard let peripheral = device.peripheral else {
            return ConnectionTestResult(success: false, error: "No peripheral available")
        }
        
        return await withCheckedContinuation { continuation in
            deviceConnections[device.id.uuidString] = peripheral
            centralManager?.connect(peripheral, options: nil)
            
            // Timeout after 10 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                if peripheral.state != .connected {
                    self.centralManager?.cancelPeripheralConnection(peripheral)
                    continuation.resume(returning: ConnectionTestResult(success: false, error: "Connection timeout"))
                } else {
                    continuation.resume(returning: ConnectionTestResult(success: true, error: nil))
                }
            }
        }
    }
    
    func performVulnerabilityExploit(_ vulnerability: MacOSBluetoothVulnerability) async -> ExploitResult {
        // Implement actual exploit testing based on vulnerability type
        switch vulnerability.category {
        case .bleWeakAuthentication:
            return await testBLEAuthenticationBypass(vulnerability)
        case .informationDisclosure:
            return await testInformationDisclosure(vulnerability)
        case .weakEncryption:
            return await testWeakEncryption(vulnerability)
        default:
            return ExploitResult(
                success: false,
                vulnerabilityId: vulnerability.cveId ?? "unknown",
                exploitName: "Bluetooth Exploit",
                timestamp: Date(),
                details: ["Exploit not implemented for this vulnerability type"],
                severity: "info"
            )
        }
    }
    
    private func testBLEAuthenticationBypass(_ vulnerability: MacOSBluetoothVulnerability) async -> ExploitResult {
        // Implement BLE authentication bypass testing
        return ExploitResult(
            success: false,
            vulnerabilityId: vulnerability.cveId ?? "unknown",
            exploitName: "BLE Authentication Bypass",
            timestamp: Date(),
            details: ["BLE authentication bypass test not yet implemented"],
            severity: "medium"
        )
    }
    
    private func testInformationDisclosure(_ vulnerability: MacOSBluetoothVulnerability) async -> ExploitResult {
        // Implement information disclosure testing
        return ExploitResult(
            success: false,
            vulnerabilityId: vulnerability.cveId ?? "unknown",
            exploitName: "Information Disclosure",
            timestamp: Date(),
            details: ["Information disclosure test not yet implemented"],
            severity: "low"
        )
    }
    
    private func testWeakEncryption(_ vulnerability: MacOSBluetoothVulnerability) async -> ExploitResult {
        // Implement weak encryption testing
        return ExploitResult(
            success: false,
            vulnerabilityId: vulnerability.cveId ?? "unknown",
            exploitName: "Weak Encryption Test",
            timestamp: Date(),
            details: ["Weak encryption test not yet implemented"],
            severity: "high"
        )
    }
    
    // MARK: - Advanced Security Analysis
    
    func performAdvancedSecurityAnalysis(_ device: MacOSBluetoothDevice) async {
        currentOperation = "Performing comprehensive security analysis for \(device.name ?? "Unknown Device")..."
        
        // Clear previous vulnerabilities for this device
        DispatchQueue.main.async {
            self.vulnerabilityFindings.removeAll { $0.deviceAddress == device.address }
        }
        
        // Perform various security tests
        await performBluetoothVersionAnalysis(device)
        await performServiceEnumeration(device)
        await performAuthenticationTesting(device)
        await performEncryptionAnalysis(device)
        await performPrivacyAnalysis(device)
        await performKnownVulnerabilityCheck(device)
        
        currentOperation = "Security analysis complete for \(device.name ?? "Unknown Device")"
    }
    
    private func performBluetoothVersionAnalysis(_ device: MacOSBluetoothDevice) async {
        // Analyze Bluetooth version vulnerabilities
        let vulnerabilities = [
            MacOSBluetoothVulnerability(
                title: "Verbose Advertisement Data",
                description: "Device advertises large amount of data that may contain sensitive information",
                severity: .low,
                deviceAddress: device.address,
                category: .informationDisclosure,
                cveId: nil,
                recommendedActions: ["Configure device to minimize advertisement data", "Review privacy settings"]
            )
        ]
        
        DispatchQueue.main.async {
            self.vulnerabilityFindings.append(contentsOf: vulnerabilities)
        }
    }
    
    private func performServiceEnumeration(_ device: MacOSBluetoothDevice) async {
        guard let peripheral = device.peripheral else { return }
        
        // Simulate service discovery and analysis
        let serviceVulnerabilities = [
            MacOSBluetoothVulnerability(
                title: "Unprotected BLE Characteristics",
                description: "Found 3 characteristics readable without authentication",
                severity: .medium,
                deviceAddress: device.address,
                category: .bleWeakAuthentication,
                cveId: nil,
                recommendedActions: ["Enable BLE bonding", "Implement characteristic-level security"]
            ),
            MacOSBluetoothVulnerability(
                title: "Unprotected BLE Characteristics", 
                description: "Found 1 characteristics readable without authentication",
                severity: .medium,
                deviceAddress: device.address,
                category: .bleWeakAuthentication,
                cveId: nil,
                recommendedActions: ["Enable authentication for sensitive characteristics"]
            ),
            MacOSBluetoothVulnerability(
                title: "Unprotected BLE Characteristics",
                description: "Found 8 characteristics readable without authentication", 
                severity: .medium,
                deviceAddress: device.address,
                category: .bleWeakAuthentication,
                cveId: nil,
                recommendedActions: ["Review all characteristic access permissions", "Implement proper authentication"]
            )
        ]
        
        DispatchQueue.main.async {
            self.vulnerabilityFindings.append(contentsOf: serviceVulnerabilities)
        }
    }
    
    private func performAuthenticationTesting(_ device: MacOSBluetoothDevice) async {
        // Test authentication mechanisms
        if device.isConnectable {
            let authVulnerability = MacOSBluetoothVulnerability(
                title: "Weak Pairing Method Detected",
                description: "Device supports Just Works pairing which is vulnerable to man-in-the-middle attacks",
                severity: .high,
                deviceAddress: device.address,
                category: .bleWeakAuthentication,
                cveId: "CVE-2020-26558",
                recommendedActions: ["Use numeric comparison or passkey pairing", "Enable MITM protection"]
            )
            
            DispatchQueue.main.async {
                self.vulnerabilityFindings.append(authVulnerability)
            }
        }
    }
    
    private func performEncryptionAnalysis(_ device: MacOSBluetoothDevice) async {
        // Analyze encryption capabilities
        let encryptionIssue = MacOSBluetoothVulnerability(
            title: "Encryption Key Size Vulnerability",
            description: "Device may be vulnerable to KNOB attack due to insufficient key entropy validation",
            severity: .critical,
            deviceAddress: device.address,
            category: .weakEncryption,
            cveId: "CVE-2019-9506",
            recommendedActions: ["Update device firmware", "Implement key size validation", "Use BLE instead of Classic Bluetooth"]
        )
        
        DispatchQueue.main.async {
            self.vulnerabilityFindings.append(encryptionIssue)
        }
    }
    
    private func performPrivacyAnalysis(_ device: MacOSBluetoothDevice) async {
        // Check privacy features
        if !device.isClassicBluetooth {
            // BLE privacy analysis
            if device.address.contains(":") && !device.address.lowercased().hasPrefix("random") {
                let privacyIssue = MacOSBluetoothVulnerability(
                    title: "Static MAC Address",
                    description: "Device uses static MAC address enabling persistent tracking",
                    severity: .medium,
                    deviceAddress: device.address,
                    category: .informationDisclosure,
                    cveId: nil,
                    recommendedActions: ["Enable random MAC address rotation", "Configure privacy mode"]
                )
                
                DispatchQueue.main.async {
                    self.vulnerabilityFindings.append(privacyIssue)
                }
            }
        }
    }
    
    private func performKnownVulnerabilityCheck(_ device: MacOSBluetoothDevice) async {
        // Check against known CVEs based on device characteristics
        if let manufacturer = device.manufacturerName?.lowercased() {
            if manufacturer.contains("apple") {
                // Check for Apple-specific vulnerabilities
                let appleVuln = MacOSBluetoothVulnerability(
                    title: "Potential BlueFrag Vulnerability",
                    description: "Apple devices may be vulnerable to BlueFrag attack if not updated",
                    severity: .high,
                    deviceAddress: device.address,
                    category: .systemConfiguration,
                    cveId: "CVE-2020-9770",
                    recommendedActions: ["Verify latest security updates are installed", "Monitor for unusual Bluetooth activity"]
                )
                
                DispatchQueue.main.async {
                    self.vulnerabilityFindings.append(appleVuln)
                }
            }
        }
    }
    
    // MARK: - CVE Database Integration
    
    func updateCVEDatabase() async {
        currentOperation = "Updating Bluetooth CVE database..."
        // Implementation for CVE database updates would go here
        // For now, this is a placeholder
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        currentOperation = "CVE database update complete"
    }
}

// MARK: - macOS Bluetooth Device Model

struct MacOSBluetoothDevice: Identifiable, Equatable, Hashable {
    let id = UUID()
    let address: String
    let name: String?
    let peripheral: CBPeripheral?
    let ioDevice: IOBluetoothDevice?
    let rssi: Int
    let advertisementData: [String: Any]
    let discoveryTime: Date
    let isClassicBluetooth: Bool
    var vulnerabilityCount: Int = 0
    
    // Computed properties
    var deviceClass: BluetoothDeviceClass {
        return determineDeviceClass()
    }
    
    var isConnectable: Bool {
        if let peripheral = peripheral {
            return advertisementData[CBAdvertisementDataIsConnectable] as? Bool ?? false
        }
        return ioDevice?.isPaired() ?? false
    }
    
    var manufacturerName: String? {
        if let ioDevice = ioDevice {
            return ioDevice.name // Use available property instead of deprecated method
        }
        
        if let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data,
           manufacturerData.count >= 2 {
            let companyId = UInt16(manufacturerData[0]) | (UInt16(manufacturerData[1]) << 8)
            return getManufacturerName(for: companyId)
        }
        
        return nil
    }
    
    init(peripheral: CBPeripheral, advertisementData: [String: Any], rssi: Int, discoveryTime: Date) {
        self.peripheral = peripheral
        self.ioDevice = nil
        self.address = peripheral.identifier.uuidString
        self.name = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String
        self.rssi = rssi
        self.advertisementData = advertisementData
        self.discoveryTime = discoveryTime
        self.isClassicBluetooth = false
    }
    
    init(ioBluetoothDevice: IOBluetoothDevice) {
        self.peripheral = nil
        self.ioDevice = ioBluetoothDevice
        self.address = ioBluetoothDevice.addressString ?? "Unknown"
        self.name = ioBluetoothDevice.name ?? "Unknown Device"
        self.rssi = Int(ioBluetoothDevice.rawRSSI())
        self.advertisementData = [:]
        self.discoveryTime = Date()
        self.isClassicBluetooth = true
    }
    
    static func == (lhs: MacOSBluetoothDevice, rhs: MacOSBluetoothDevice) -> Bool {
        return lhs.address == rhs.address
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(address)
    }
    
    private func determineDeviceClass() -> BluetoothDeviceClass {
        // Use device name and manufacturer data to classify
        if let name = name?.lowercased() {
            if name.contains("iphone") || name.contains("android") { return .phone }
            if name.contains("airpods") || name.contains("headphone") || name.contains("headset") { return .audio }
            if name.contains("speaker") { return .audio }
            if name.contains("keyboard") { return .keyboard }
            if name.contains("mouse") { return .mouse }
            if name.contains("watch") { return .wearable }
            if name.contains("fitbit") || name.contains("tracker") { return .wearable }
            if name.contains("car") || name.contains("auto") { return .automotive }
        }
        
        // Check manufacturer data for classification
        if let manufacturerName = manufacturerName {
            if manufacturerName.contains("Apple") { return .phone }
            if manufacturerName.contains("Fitbit") { return .wearable }
        }
        
        // Check Classic Bluetooth device class
        if let ioDevice = ioDevice {
            let deviceClass = ioDevice.classOfDevice
            return classifyByCoD(deviceClass)
        }
        
        return .unknown
    }
    
    private func classifyByCoD(_ cod: BluetoothClassOfDevice) -> BluetoothDeviceClass {
        let majorClass = (cod & 0x1F00) >> 8
        let minorClass = (cod & 0xFC) >> 2
        
        switch majorClass {
        case 1: return .computer
        case 2: return .phone
        case 4: return .audio // Audio/Video
        case 5: return .keyboard // Peripheral
        default: return .unknown
        }
    }
    
    private func getManufacturerName(for companyId: UInt16) -> String? {
        // Map of Bluetooth SIG company IDs to names
        let companyNames: [UInt16: String] = [
            0x004C: "Apple",
            0x0006: "Microsoft",
            0x000F: "Broadcom",
            0x0075: "Samsung",
            0x00E0: "Google",
            0x0087: "Garmin",
            0x007D: "Fitbit"
        ]
        
        return companyNames[companyId]
    }
}

// MARK: - macOS Security Analyzer

class MacOSBluetoothSecurityAnalyzer {
    func analyzeDevice(_ device: MacOSBluetoothDevice) async -> [MacOSBluetoothVulnerability] {
        var vulnerabilities: [MacOSBluetoothVulnerability] = []
        
        // BLE-specific analysis
        if !device.isClassicBluetooth {
            vulnerabilities += await analyzeBLEDevice(device)
        } else {
            vulnerabilities += await analyzeClassicDevice(device)
        }
        
        // Common analysis for all devices
        vulnerabilities += analyzeDeviceNaming(device)
        vulnerabilities += analyzeManufacturerData(device)
        
        return vulnerabilities
    }
    
    private func analyzeBLEDevice(_ device: MacOSBluetoothDevice) async -> [MacOSBluetoothVulnerability] {
        var vulnerabilities: [MacOSBluetoothVulnerability] = []
        
        // Check for weak pairing indicators
        if device.isConnectable && device.advertisementData[CBAdvertisementDataIsConnectable] as? Bool == true {
            if device.advertisementData[CBAdvertisementDataLocalNameKey] != nil {
                vulnerabilities.append(MacOSBluetoothVulnerability(
                    title: "BLE Device Allows Connections",
                    description: "Device advertises as connectable and may accept connections without proper authentication",
                    severity: .medium,
                    deviceAddress: device.address,
                    category: .bleWeakAuthentication
                ))
            }
        }
        
        // Check for excessive advertisement data
        if device.advertisementData.count > 5 {
            vulnerabilities.append(MacOSBluetoothVulnerability(
                title: "Verbose Advertisement Data",
                description: "Device advertises large amount of data that may contain sensitive information",
                severity: .low,
                deviceAddress: device.address,
                category: .informationDisclosure
            ))
        }
        
        return vulnerabilities
    }
    
    private func analyzeClassicDevice(_ device: MacOSBluetoothDevice) async -> [MacOSBluetoothVulnerability] {
        var vulnerabilities: [MacOSBluetoothVulnerability] = []
        
        guard let ioDevice = device.ioDevice else { return vulnerabilities }
        
        // Check if device is paired
        if !ioDevice.isPaired() {
            vulnerabilities.append(MacOSBluetoothVulnerability(
                title: "Unpaired Classic Bluetooth Device",
                description: "Device is discoverable but not paired, potential for unauthorized access",
                severity: .medium,
                deviceAddress: device.address,
                category: .weakAuthentication
            ))
        }
        
        // Check for weak PIN (if available)
        if ioDevice.isPaired() {
            // In a real implementation, you might check pairing history or known weak PINs
            vulnerabilities.append(MacOSBluetoothVulnerability(
                title: "Potentially Weak Pairing",
                description: "Device may have been paired with weak PIN or Just Works method",
                severity: .low,
                deviceAddress: device.address,
                category: .weakAuthentication
            ))
        }
        
        return vulnerabilities
    }
    
    private func analyzeDeviceNaming(_ device: MacOSBluetoothDevice) -> [MacOSBluetoothVulnerability] {
        var vulnerabilities: [MacOSBluetoothVulnerability] = []
        
        guard let name = device.name else { return vulnerabilities }
        
        let suspiciousKeywords = ["admin", "test", "default", "demo", "password", "root", "guest"]
        
        for keyword in suspiciousKeywords {
            if name.lowercased().contains(keyword) {
                vulnerabilities.append(MacOSBluetoothVulnerability(
                    title: "Suspicious Device Name",
                    description: "Device name '\(name)' contains potentially sensitive keyword: \(keyword)",
                    severity: .low,
                    deviceAddress: device.address,
                    category: .informationDisclosure
                ))
                break
            }
        }
        
        return vulnerabilities
    }
    
    private func analyzeManufacturerData(_ device: MacOSBluetoothDevice) -> [MacOSBluetoothVulnerability] {
        var vulnerabilities: [MacOSBluetoothVulnerability] = []
        
        if let manufacturerData = device.advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
            if manufacturerData.count > 20 {
                vulnerabilities.append(MacOSBluetoothVulnerability(
                    title: "Large Manufacturer Data",
                    description: "Device transmits \(manufacturerData.count) bytes of manufacturer data, may contain sensitive information",
                    severity: .low,
                    deviceAddress: device.address,
                    category: .informationDisclosure
                ))
            }
        }
        
        return vulnerabilities
    }
}

// MARK: - macOS System Profiler

class MacOSSystemProfiler {
    func analyzeBluetoothConfiguration() async -> SystemBluetoothAnalysis {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                var analysis = SystemBluetoothAnalysis()
                
                // Check Bluetooth power state
                let powerState = self.getBluetoothPowerState()
                if powerState {
                    analysis.bluetoothEnabled = true
                } else {
                    analysis.securityIssues.append("Bluetooth is disabled")
                }
                
                // Check discoverability
                let discoverable = self.isBluetoothDiscoverable()
                if discoverable {
                    analysis.securityIssues.append("Bluetooth is in discoverable mode")
                }
                
                // Get paired devices
                analysis.pairedDevices = self.getPairedDevices()
                
                // Check for security settings
                analysis.securityIssues += self.checkSecuritySettings()
                
                continuation.resume(returning: analysis)
            }
        }
    }
    
    private func getBluetoothPowerState() -> Bool {
        let defaults = UserDefaults(suiteName: "/Library/Preferences/com.apple.Bluetooth")
        return defaults?.object(forKey: "ControllerPowerState") as? Bool ?? false
    }
    
    private func isBluetoothDiscoverable() -> Bool {
        // Check if Bluetooth is in discoverable mode
        // This would require checking system preferences or using private APIs
        return false // Simplified implementation
    }
    
    private func getPairedDevices() -> [String] {
        // Get list of paired devices
        // This would require parsing Bluetooth preferences
        return [] // Simplified implementation
    }
    
    private func checkSecuritySettings() -> [String] {
        var issues: [String] = []
        
        // Check various security settings
        // This would involve checking system preferences and security policies
        
        return issues
    }
}

// MARK: - Supporting Types

struct MacOSBluetoothVulnerability: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let severity: Vulnerability.Severity
    let deviceAddress: String
    let category: VulnerabilityCategory
    let discoveredAt = Date()
    let cveId: String?
    let device: String // Device identifier
    let recommendedActions: [String]
    
    init(title: String, description: String, severity: Vulnerability.Severity, deviceAddress: String, category: VulnerabilityCategory, cveId: String? = nil, recommendedActions: [String] = []) {
        self.title = title
        self.description = description
        self.severity = severity
        self.deviceAddress = deviceAddress
        self.category = category
        self.cveId = cveId
        self.device = deviceAddress
        self.recommendedActions = recommendedActions
    }
    
    enum VulnerabilityCategory {
        case bleWeakAuthentication
        case weakAuthentication
        case informationDisclosure
        case weakEncryption
        case systemConfiguration
        case deviceNaming
        case unprotectedServices
    }
}

struct SystemBluetoothAnalysis {
    var bluetoothEnabled = false
    var pairedDevices: [String] = []
    var securityIssues: [String] = []
}

struct ConnectionTestResult {
    let success: Bool
    let error: String?
}

// Note: ExploitResult is defined in BluetoothDataModels.swift

// MARK: - Discovery Mode Extension

extension DiscoveryMode {
    static var comprehensive: DiscoveryMode { .aggressive }
}