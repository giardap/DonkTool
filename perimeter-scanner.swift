import SwiftUI
import Foundation
import Combine
import Network

// MARK: - Enhanced DonkTool with Perimeter Scanner Integration

@Observable
class EnhancedAppState: AppState {
    // Existing DonkTool state...
    
    // New perimeter scanner state
    var perimeterScanner = PerimeterScannerManager()
    var ivreDashboard = IVREDashboardManager()
    var complianceManager = ComplianceManager()
    var threatIntelligence = ThreatIntelligenceManager()
    
    // Integration state
    var isPerimeterMonitoringActive = false
    var lastPerimeterScan: Date?
    var unauthorizedServicesCount = 0
    var complianceScore: Double = 0.0
    
    override init() {
        super.init()
        setupPerimeterIntegration()
    }
    
    private func setupPerimeterIntegration() {
        // Link perimeter scanner with existing vulnerability management
        perimeterScanner.onVulnerabilitiesDiscovered = { [weak self] vulnerabilities in
            self?.addVulnerabilities(vulnerabilities)
        }
        
        // Integration with existing network scanner
        perimeterScanner.onNewHostsDiscovered = { [weak self] hosts in
            for host in hosts {
                let target = Target(name: host.hostname ?? host.ip, ipAddress: host.ip)
                self?.addTarget(target)
            }
        }
    }
    
    func addVulnerabilities(_ vulnerabilities: [PerimeterVulnerability]) {
        for vulnData in vulnerabilities {
            let vulnerability = Vulnerability(
                cveId: vulnData.cveId,
                title: vulnData.title,
                description: vulnData.description,
                severity: vulnData.severity,
                port: vulnData.port,
                service: vulnData.service,
                discoveredAt: vulnData.discoveredAt
            )
            addVulnerability(vulnerability, targetIP: vulnData.targetIP)
        }
    }
}

// MARK: - Perimeter Scanner Manager

@Observable
class PerimeterScannerManager {
    var isScanning = false
    var scanProgress: Double = 0.0
    var currentResults: PerimeterScanResults?
    var unauthorizedServices: [UnauthorizedService] = []
    var scanHistory: [PerimeterScanResults] = []
    var monitoringTargets: [NetworkRange] = []
    var alertingRules: [AlertRule] = []
    
    // Callbacks for integration
    var onVulnerabilitiesDiscovered: (([PerimeterVulnerability]) -> Void)?
    var onNewHostsDiscovered: (([DiscoveredHost]) -> Void)?
    var onUnauthorizedServiceFound: ((UnauthorizedService) -> Void)?
    
    private let pythonBridge = PythonScannerBridge()
    private let websocketManager = WebSocketManager()
    
    init() {
        setupWebSocketConnection()
        loadConfiguration()
    }
    
    private func setupWebSocketConnection() {
        websocketManager.onMessageReceived = { [weak self] message in
            self?.handleRealTimeAlert(message)
        }
    }
    
    private func loadConfiguration() {
        // Load monitoring targets from configuration
        monitoringTargets = [
            NetworkRange(cidr: "10.0.0.0/24", description: "Internal Network"),
            NetworkRange(cidr: "192.168.1.0/24", description: "DMZ Network"),
            NetworkRange(cidr: "172.16.0.0/16", description: "Management Network")
        ]
        
        // Load default alerting rules
        alertingRules = [
            AlertRule(
                name: "High Risk Service Detected",
                condition: .serviceRisk(.high),
                severity: .critical,
                enabled: true
            ),
            AlertRule(
                name: "Database Service Exposed",
                condition: .portIn([1433, 3306, 5432, 27017]),
                severity: .critical,
                enabled: true
            ),
            AlertRule(
                name: "New Host Discovered",
                condition: .newHost,
                severity: .medium,
                enabled: true
            )
        ]
    }
    
    func startPerimeterScan(ranges: [String] = []) async {
        let targetRanges = ranges.isEmpty ? monitoringTargets.map(\.cidr) : ranges
        
        isScanning = true
        scanProgress = 0.0
        
        do {
            currentResults = try await pythonBridge.executePerimeterScan(
                ranges: targetRanges
            ) { progress in
                DispatchQueue.main.async {
                    self.scanProgress = progress
                }
            }
            
            // Process results
            if let results = currentResults {
                await processPerimeterResults(results)
                scanHistory.append(results)
            }
            
        } catch {
            print("Perimeter scan failed: \(error)")
        }
        
        isScanning = false
    }
    
    func startContinuousMonitoring(intervalMinutes: Int = 60) {
        Task {
            while true {
                await startPerimeterScan()
                try? await Task.sleep(nanoseconds: UInt64(intervalMinutes * 60 * 1_000_000_000))
            }
        }
    }
    
    private func processPerimeterResults(_ results: PerimeterScanResults) async {
        // Extract unauthorized services
        unauthorizedServices = results.analysis.unauthorizedServices
        
        // Trigger callbacks
        onVulnerabilitiesDiscovered?(results.vulnerabilities)
        onNewHostsDiscovered?(results.discoveredHosts)
        
        // Check alerting rules
        for service in unauthorizedServices {
            for rule in alertingRules where rule.enabled {
                if rule.matches(service: service) {
                    await triggerAlert(rule: rule, service: service)
                }
            }
        }
    }
    
    private func triggerAlert(rule: AlertRule, service: UnauthorizedService) async {
        let alert = SecurityAlert(
            id: UUID(),
            title: rule.name,
            description: "Unauthorized \(service.serviceName) detected on \(service.ip):\(service.port)",
            severity: rule.severity,
            timestamp: Date(),
            source: .perimeterScanner,
            affectedAssets: [service.ip],
            recommendedActions: generateRecommendations(for: service)
        )
        
        // Send alert through notification system
        NotificationCenter.default.post(
            name: .securityAlertTriggered,
            object: alert
        )
        
        onUnauthorizedServiceFound?(service)
    }
    
    private func generateRecommendations(for service: UnauthorizedService) -> [String] {
        var recommendations: [String] = []
        
        switch service.riskLevel {
        case .critical:
            recommendations.append("Immediately disable or restrict access to this service")
            recommendations.append("Conduct forensic analysis to determine if compromise occurred")
        case .high:
            recommendations.append("Evaluate business justification for this service")
            recommendations.append("Implement additional access controls if service is legitimate")
        case .medium:
            recommendations.append("Document service in authorized services list if legitimate")
            recommendations.append("Apply security hardening measures")
        case .low:
            recommendations.append("Review service configuration and access requirements")
        }
        
        return recommendations
    }
    
    private func handleRealTimeAlert(_ message: WebSocketMessage) {
        switch message.type {
        case "unauthorized_service":
            if let serviceData = message.data as? [String: Any] {
                let service = UnauthorizedService(from: serviceData)
                DispatchQueue.main.async {
                    self.unauthorizedServices.append(service)
                    self.onUnauthorizedServiceFound?(service)
                }
            }
        case "scan_progress":
            if let progress = message.data as? Double {
                DispatchQueue.main.async {
                    self.scanProgress = progress
                }
            }
        default:
            break
        }
    }
}

// MARK: - IVRE Dashboard Manager

@Observable
class IVREDashboardManager {
    var isConnected = false
    var databaseStats: IVREDatabaseStats?
    var recentScans: [IVREScanSummary] = []
    var topVulnerabilities: [IVREVulnerability] = []
    var hostStatistics: IVREHostStatistics?
    
    private let apiClient = IVREAPIClient()
    
    init() {
        connectToIVRE()
    }
    
    private func connectToIVRE() {
        Task {
            do {
                let connected = try await apiClient.testConnection()
                await MainActor.run {
                    self.isConnected = connected
                    if connected {
                        self.loadDashboardData()
                    }
                }
            } catch {
                print("Failed to connect to IVRE: \(error)")
            }
        }
    }
    
    private func loadDashboardData() {
        Task {
            do {
                async let stats = apiClient.getDatabaseStats()
                async let scans = apiClient.getRecentScans()
                async let vulns = apiClient.getTopVulnerabilities()
                async let hosts = apiClient.getHostStatistics()
                
                let (dbStats, recentScanData, topVulnData, hostStats) = try await (stats, scans, vulns, hosts)
                
                await MainActor.run {
                    self.databaseStats = dbStats
                    self.recentScans = recentScanData
                    self.topVulnerabilities = topVulnData
                    self.hostStatistics = hostStats
                }
            } catch {
                print("Failed to load IVRE dashboard data: \(error)")
            }
        }
    }
    
    func queryHosts(filter: IVREHostFilter) async -> [IVREHost] {
        do {
            return try await apiClient.queryHosts(filter: filter)
        } catch {
            print("Failed to query IVRE hosts: \(error)")
            return []
        }
    }
    
    func exportScanResults(scanId: String, format: ExportFormat) async -> URL? {
        do {
            return try await apiClient.exportScan(scanId: scanId, format: format)
        } catch {
            print("Failed to export scan results: \(error)")
            return nil
        }
    }
}

// MARK: - Enhanced Main Content View

struct EnhancedContentView: View {
    @State private var appState = EnhancedAppState()
    @State private var selectedView: MainView = .dashboard
    
    enum MainView: String, CaseIterable {
        case dashboard = "Dashboard"
        case perimeterScanner = "Perimeter Scanner"
        case networkScanner = "Network Scanner"
        case webTesting = "Web Testing"
        case ivreDashboard = "IVRE Dashboard"
        case threatIntel = "Threat Intelligence"
        case compliance = "Compliance"
        case reporting = "Reporting"
        case settings = "Settings"
        
        var icon: String {
            switch self {
            case .dashboard: return "gauge"
            case .perimeterScanner: return "shield.checkerboard"
            case .networkScanner: return "network"
            case .webTesting: return "globe"
            case .ivreDashboard: return "server.rack"
            case .threatIntel: return "eye"
            case .compliance: return "checkmark.shield"
            case .reporting: return "doc.text"
            case .settings: return "gearshape"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            // Enhanced Sidebar
            List(MainView.allCases, id: \.self, selection: $selectedView) { view in
                NavigationLink(value: view) {
                    HStack {
                        Image(systemName: view.icon)
                            .frame(width: 20)
                        Text(view.rawValue)
                    }
                }
            }
            .navigationTitle("DonkTool Pro")
            .navigationSplitViewColumnWidth(min: 200, ideal: 250)
            
        } detail: {
            // Enhanced Detail View
            Group {
                switch selectedView {
                case .dashboard:
                    EnhancedDashboardView()
                case .perimeterScanner:
                    PerimeterScannerView()
                case .networkScanner:
                    ModernNetworkScannerView()
                case .webTesting:
                    ModernWebTestingView()
                case .ivreDashboard:
                    IVREDashboardView()
                case .threatIntel:
                    ThreatIntelligenceView()
                case .compliance:
                    ComplianceView()
                case .reporting:
                    ReportingView()
                case .settings:
                    SettingsView()
                }
            }
            .environment(appState)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Global status indicators
                if appState.perimeterScanner.isScanning {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Scanning...")
                        .font(.caption)
                }
                
                if appState.unauthorizedServicesCount > 0 {
                    Button("\(appState.unauthorizedServicesCount) Alerts") {
                        selectedView = .perimeterScanner
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
                
                // Quick actions
                Menu("Quick Actions") {
                    Button("Start Perimeter Scan") {
                        Task {
                            await appState.perimeterScanner.startPerimeterScan()
                        }
                    }
                    
                    Button("Generate Report") {
                        selectedView = .reporting
                    }
                    
                    Button("Check Compliance") {
                        selectedView = .compliance
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .onAppear {
            setupIntegrations()
        }
    }
    
    private func setupIntegrations() {
        // Setup cross-module integrations
        appState.perimeterScanner.onUnauthorizedServiceFound = { service in
            appState.unauthorizedServicesCount += 1
            
            // Show notification
            let notification = UNMutableNotificationContent()
            notification.title = "Unauthorized Service Detected"
            notification.body = "\(service.serviceName) on \(service.ip):\(service.port)"
            notification.sound = .default
            
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: notification,
                trigger: nil
            )
            
            UNUserNotificationCenter.current().add(request)
        }
        
        // Setup automatic perimeter monitoring
        if UserDefaults.standard.bool(forKey: "auto_perimeter_monitoring") {
            appState.perimeterScanner.startContinuousMonitoring()
        }
    }
}

// MARK: - Enhanced Dashboard View

struct EnhancedDashboardView: View {
    @Environment(EnhancedAppState.self) private var appState
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                // Security Status Overview
                SecurityStatusCard()
                
                // Perimeter Health
                PerimeterHealthCard()
                
                // Threat Intelligence
                ThreatIntelCard()
                
                // Compliance Score
                ComplianceScoreCard()
                
                // Recent Alerts
                RecentAlertsCard()
                
                // Scan Activity
                ScanActivityCard()
                
                // Asset Discovery
                AssetDiscoveryCard()
                
                // Risk Metrics
                RiskMetricsCard()
            }
            .padding()
            
            // Real-time Activity Feed
            VStack(alignment: .leading, spacing: 16) {
                Text("Real-time Activity")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                
                RealTimeActivityFeed()
            }
            .padding()
        }
        .navigationTitle("Security Operations Center")
        .refreshable {
            await refreshDashboard()
        }
    }
    
    private func refreshDashboard() async {
        // Refresh all dashboard data
        await appState.perimeterScanner.startPerimeterScan()
        appState.ivreDashboard.loadDashboardData()
        await appState.threatIntelligence.updateThreatFeeds()
    }
}

// MARK: - Perimeter Scanner View

struct PerimeterScannerView: View {
    @Environment(EnhancedAppState.self) private var appState
    @State private var showingConfiguration = false
    @State private var showingAlertingRules = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Enhanced header with real-time status
            PerimeterScannerHeader()
            
            HSplitView {
                // Configuration Panel
                VStack(spacing: 20) {
                    MonitoringTargetsPanel()
                    AlertingRulesPanel()
                    ScanSchedulePanel()
                    CompliancePanel()
                }
                .frame(minWidth: 350, maxWidth: 450)
                .padding(20)
                .background(Color(NSColor.controlBackgroundColor))
                
                // Results and Analysis
                VStack(spacing: 0) {
                    ResultsTabView()
                }
            }
        }
        .navigationTitle("Perimeter Scanner")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if appState.perimeterScanner.isScanning {
                    ProgressView(value: appState.perimeterScanner.scanProgress)
                        .frame(width: 100)
                    
                    Button("Stop") {
                        // Stop scanning
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button("Start Scan") {
                        Task {
                            await appState.perimeterScanner.startPerimeterScan()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Button("Configure") {
                    showingConfiguration = true
                }
                .buttonStyle(.bordered)
                
                Button("Alerts") {
                    showingAlertingRules = true
                }
                .buttonStyle(.bordered)
            }
        }
        .sheet(isPresented: $showingConfiguration) {
            PerimeterConfigurationView()
        }
        .sheet(isPresented: $showingAlertingRules) {
            AlertingRulesView()
        }
    }
}

// MARK: - Python Scanner Bridge

class PythonScannerBridge {
    private let pythonPath = "/usr/bin/python3"
    private let scannerScript = "/opt/donktool/scripts/perimeter_scanner.py"
    
    func executePerimeterScan(
        ranges: [String],
        progressCallback: @escaping (Double) -> Void = { _ in }
    ) async throws -> PerimeterScanResults {
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: pythonPath)
        process.arguments = [
            scannerScript,
            "--ranges", ranges.joined(separator: ","),
            "--output-format", "json",
            "--progress-callback"
        ]
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        try process.run()
        
        // Monitor progress through stderr
        Task {
            for try await line in errorPipe.fileHandleForReading.bytes.lines {
                if line.hasPrefix("PROGRESS:") {
                    let progressStr = String(line.dropFirst(9))
                    if let progress = Double(progressStr) {
                        progressCallback(progress)
                    }
                }
            }
        }
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw ScannerError.pythonScriptFailed(errorMessage)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(PerimeterScanResults.self, from: outputData)
    }
}

// MARK: - Data Models

struct PerimeterScanResults: Codable {
    let scanId: String
    let timestamp: Date
    let targets: [String]
    let discoveredHosts: [DiscoveredHost]
    let vulnerabilities: [PerimeterVulnerability]
    let analysis: PerimeterAnalysis
}

struct PerimeterAnalysis: Codable {
    let unauthorizedServices: [UnauthorizedService]
    let newHosts: [DiscoveredHost]
    let serviceChanges: [ServiceChange]
    let vulnerabilityChanges: [VulnerabilityChange]
    let complianceViolations: [ComplianceViolation]
}

struct UnauthorizedService: Codable, Identifiable {
    let id = UUID()
    let ip: String
    let port: Int
    let serviceName: String
    let version: String?
    let firstDetected: Date
    let riskLevel: RiskLevel
    let confidence: Double
    
    enum RiskLevel: String, Codable, CaseIterable {
        case critical = "Critical"
        case high = "High"
        case medium = "Medium"
        case low = "Low"
        
        var color: Color {
            switch self {
            case .critical: return .red
            case .high: return .orange
            case .medium: return .yellow
            case .low: return .green
            }
        }
    }
}

struct DiscoveredHost: Codable, Identifiable {
    let id = UUID()
    let ip: String
    let hostname: String?
    let macAddress: String?
    let operatingSystem: String?
    let openPorts: [Int]
    let firstSeen: Date
    let lastSeen: Date
    let confidence: Double
}

struct PerimeterVulnerability: Codable {
    let cveId: String?
    let title: String
    let description: String
    let severity: Vulnerability.Severity
    let targetIP: String
    let port: Int?
    let service: String?
    let discoveredAt: Date
    let exploitAvailable: Bool
    let references: [String]
}

struct NetworkRange: Codable, Identifiable {
    let id = UUID()
    let cidr: String
    let description: String
    let enabled: Bool = true
    let priority: Int = 1
}

struct AlertRule: Codable, Identifiable {
    let id = UUID()
    let name: String
    let condition: AlertCondition
    let severity: AlertSeverity
    let enabled: Bool
    let notificationChannels: [NotificationChannel] = [.inApp, .email]
    
    enum AlertCondition: Codable {
        case serviceRisk(RiskLevel)
        case portIn([Int])
        case newHost
        case serviceChange
        case vulnerabilityFound(Vulnerability.Severity)
        
        enum RiskLevel: String, Codable {
            case critical, high, medium, low
        }
    }
    
    enum AlertSeverity: String, Codable {
        case critical = "Critical"
        case high = "High" 
        case medium = "Medium"
        case low = "Low"
    }
    
    enum NotificationChannel: String, Codable, CaseIterable {
        case inApp = "In-App"
        case email = "Email"
        case slack = "Slack"
        case webhook = "Webhook"
        case sms = "SMS"
    }
    
    func matches(service: UnauthorizedService) -> Bool {
        switch condition {
        case .serviceRisk(let riskLevel):
            return service.riskLevel.rawValue.lowercased() == riskLevel.rawValue
        case .portIn(let ports):
            return ports.contains(service.port)
        case .newHost:
            return false // Handled separately
        case .serviceChange:
            return false // Handled separately
        case .vulnerabilityFound:
            return false // Handled separately
        }
    }
}

enum ScannerError: Error {
    case pythonScriptFailed(String)
    case invalidConfiguration
    case networkError(String)
    case parseError(String)
}

// MARK: - Extensions

extension Notification.Name {
    static let securityAlertTriggered = Notification.Name("securityAlertTriggered")
    static let perimeterScanCompleted = Notification.Name("perimeterScanCompleted")
    static let unauthorizedServiceDetected = Notification.Name("unauthorizedServiceDetected")
}

struct SecurityAlert {
    let id: UUID
    let title: String
    let description: String
    let severity: AlertRule.AlertSeverity
    let timestamp: Date
    let source: AlertSource
    let affectedAssets: [String]
    let recommendedActions: [String]
    
    enum AlertSource {
        case perimeterScanner
        case networkScanner
        case webScanner
        case threatIntelligence
        case compliance
    }
}

// MARK: - Sample Preview

#Preview {
    EnhancedContentView()
        .frame(width: 1400, height: 900)
}
