//
//  IVREIntegrationView.swift
//  DonkTool
//
//  IVRE Network Intelligence Integration
//

import SwiftUI
import Foundation
import MapKit

struct IVREIntegrationView: View {
    @Environment(AppState.self) private var appState
    @State private var ivreManager = IVREManager()
    @State private var searchQuery = ""
    @State private var selectedTab = 0
    @State private var showingConfiguration = false
    @State private var useFreeSources = false
    @State private var selectedSource = "all"
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with connection status
            IVREHeaderView()
            
            // Search bar
            IVRESearchBar()
            
            // Tab view for different IVRE features
            TabView(selection: $selectedTab) {
                InternetSearchView(ivreManager: ivreManager)
                    .tabItem {
                        Label("Internet Search", systemImage: "globe")
                    }
                    .tag(0)
                
                PassiveDNSView(ivreManager: ivreManager)
                    .tabItem {
                        Label("Passive DNS", systemImage: "network")
                    }
                    .tag(1)
                
                FlowAnalysisView(ivreManager: ivreManager)
                    .tabItem {
                        Label("Flow Analysis", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    .tag(2)
                
                ThreatHuntingView()
                    .tabItem {
                        Label("Threat Hunting", systemImage: "magnifyingglass.circle")
                    }
                    .tag(3)
            }
        }
        .navigationTitle("IVRE Intelligence")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Settings") {
                    showingConfiguration = true
                }
            }
        }
        .sheet(isPresented: $showingConfiguration) {
            IVREConfigurationView()
        }
        .task {
            await ivreManager.initialize()
            // Load all hosts initially
            await ivreManager.search(query: "")
        }
    }
    
    @ViewBuilder
    private func IVREHeaderView() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("IVRE Network Intelligence")
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack(spacing: 16) {
                    ConnectionStatusBadge(isConnected: ivreManager.isConnected)
                    
                    if ivreManager.isConnected {
                        Text("Database: \(ivreManager.totalHosts) hosts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Last sync: \(ivreManager.lastSyncTime?.formatted(date: .omitted, time: .shortened) ?? "Never")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if ivreManager.isSyncing {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Syncing...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    @ViewBuilder
    private func IVRESearchBar() -> some View {
        VStack(spacing: 12) {
            HStack {
                TextField("Search (e.g., 'port:22 country:US' or 'apache version:2.4')", text: $searchQuery)
                    .textFieldStyle(.roundedBorder)
                
                Menu("Presets") {
                    ForEach(IVRESearchPresets.allPresets, id: \.name) { preset in
                        Button(preset.name) {
                            searchQuery = preset.query
                        }
                    }
                }
                .buttonStyle(.bordered)
                
                Button("Search") {
                    performSearch()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!ivreManager.isConnected && !useFreeSources)
            }
            
            // Free sources toggle
            HStack {
                Toggle("Use Free Sources", isOn: $useFreeSources)
                    .toggleStyle(.checkbox)
                
                if useFreeSources {
                    Picker("Source", selection: $selectedSource) {
                        Text("All Sources").tag("all")
                        Text("Shodan InternetDB").tag("internetdb")
                        Text("ThreatCrowd").tag("threatcrowd")
                        Text("URLScan.io").tag("urlscan")
                        Text("AlienVault OTX").tag("otx")
                    }
                    .pickerStyle(.menu)
                    .frame(width: 200)
                }
                
                Spacer()
                
                if useFreeSources {
                    Text("No API key required")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    private func performSearch() {
        Task {
            print("IVRE: Performing search with query: \(searchQuery)")
            print("IVRE: Use free sources: \(useFreeSources)")
            print("IVRE: Selected source: \(selectedSource)")
            
            if searchQuery.isEmpty {
                // If empty, search for all hosts
                await ivreManager.search(query: "")
            } else if useFreeSources {
                await ivreManager.searchFreeSources(query: searchQuery, source: selectedSource)
            } else {
                await ivreManager.search(query: searchQuery)
            }
        }
    }
}

// MARK: - IVRE Manager

@Observable
class IVREManager {
    var isConnected = false
    var isSyncing = false
    var isSearching = false
    var totalHosts = 0
    var lastSyncTime: Date?
    var searchResults: [IVREHost] = []
    var passiveDNSResults: [PassiveDNSRecord] = []
    var flowData: [NetworkFlow] = []
    var error: String?
    
    private var ivreClient: IVREAPIClient?
    private var configuration: IVREConfiguration?
    
    func initialize() async {
        await loadConfiguration()
        await connectToIVRE()
    }
    
    func search(query: String) async {
        guard let client = ivreClient else { 
            print("IVRE: No client available")
            return 
        }
        
        await MainActor.run {
            self.isSearching = true
            self.searchResults = []
            self.error = nil
        }
        
        do {
            print("IVRE: Starting search with query: \(query)")
            let results = try await client.searchHosts(query: query)
            print("IVRE: Got \(results.count) results")
            
            await MainActor.run {
                self.searchResults = results
                self.isSearching = false
                print("IVRE: Updated UI with \(self.searchResults.count) results")
            }
        } catch {
            print("IVRE search error: \(error)")
            await MainActor.run {
                self.error = error.localizedDescription
                self.isSearching = false
            }
        }
    }
    
    func searchFreeSources(query: String, source: String) async {
        print("IVRE: Searching free sources - \(source) for: \(query)")
        
        await MainActor.run {
            self.isSearching = true
            self.searchResults = []
            self.error = nil
        }
        
        guard let client = ivreClient else {
            await MainActor.run {
                self.error = "IVRE client not initialized"
                self.isSearching = false
            }
            return
        }
        
        do {
            // Call the free reconnaissance API
            let results = try await client.searchFreeSources(query: query, source: source)
            
            await MainActor.run {
                self.searchResults = results
                self.isSearching = false
            }
            
            print("IVRE: Found \(results.count) hosts from free sources")
            
        } catch {
            print("IVRE: Free source search error: \(error)")
            await MainActor.run {
                self.error = error.localizedDescription
                self.isSearching = false
            }
        }
    }
    
    private func isIPAddress(_ string: String) -> Bool {
        let parts = string.split(separator: ".")
        guard parts.count == 4 else { return false }
        
        for part in parts {
            guard let num = Int(part), num >= 0 && num <= 255 else {
                return false
            }
        }
        return true
    }
    
    func getPassiveDNS(domain: String) async -> [PassiveDNSRecord] {
        guard let client = ivreClient else { return [] }
        
        do {
            return try await client.getPassiveDNS(domain: domain)
        } catch {
            print("Passive DNS error: \(error)")
            return []
        }
    }
    
    func submitScanResults(_ scanResults: [PortScanResult], for target: String) async {
        guard let client = ivreClient else { return }
        
        let ivreData = convertScanResultsToIVREFormat(scanResults, target: target)
        
        do {
            try await client.submitScanData(ivreData)
        } catch {
            print("Failed to submit scan results: \(error)")
        }
    }
    
    private func loadConfiguration() async {
        // Load IVRE configuration from UserDefaults or config file
        let config = IVREConfiguration(
            serverURL: URL(string: "http://localhost:8080")!,
            databaseName: "ivre",
            apiKey: nil
        )
        
        await MainActor.run {
            self.configuration = config
        }
        
        print("IVRE Configuration loaded: \(config.serverURL)")
    }
    
    private func connectToIVRE() async {
        guard let config = configuration else { 
            print("IVRE Error: No configuration loaded")
            return 
        }
        
        ivreClient = IVREAPIClient(configuration: config)
        
        do {
            let status = try await ivreClient?.getStatus()
            await MainActor.run {
                self.isConnected = status?.isConnected ?? false
                self.totalHosts = status?.hostCount ?? 0
                self.lastSyncTime = Date()
            }
            print("IVRE Connected: \(self.isConnected), Hosts: \(self.totalHosts)")
        } catch {
            print("IVRE Connection Error: \(error)")
            await MainActor.run {
                self.isConnected = false
            }
        }
    }
    
    private func convertScanResultsToIVREFormat(_ results: [PortScanResult], target: String) -> IVREScanData {
        let host = IVREHost(
            id: "local_\(UUID().uuidString.prefix(12))",
            ip: target,
            hostname: nil,
            ports: results.map { result in
                IVREPort(
                    number: result.port,
                    portProtocol: "tcp",
                    state: result.isOpen ? "open" : "closed",
                    service: result.service,
                    product: nil,
                    version: result.version,
                    banner: result.banner,
                    cpe: [],
                    vulnerabilities: []
                )
            },
            geolocation: nil,
            certificates: [],
            lastSeen: Date(),
            firstSeen: Date(),
            asNumber: nil,
            country: nil
        )
        
        return IVREScanData(hosts: [host])
    }
}

// MARK: - Internet Search View

struct InternetSearchView: View {
    let ivreManager: IVREManager
    @State private var selectedCountry: String = "All"
    @State private var selectedPort: String = ""
    @State private var showingMap = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Advanced filters
            AdvancedFiltersPanel()
            
            // Results view with map option
            HStack {
                Text("\(ivreManager.searchResults.count) hosts found")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { showingMap.toggle() }) {
                    Image(systemName: showingMap ? "list.bullet" : "map")
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            
            if showingMap {
                InternetSearchMapView(hosts: ivreManager.searchResults)
            } else {
                InternetSearchListView(hosts: ivreManager.searchResults)
            }
        }
        .padding()
    }
}

struct AdvancedFiltersPanel: View {
    @State private var countryFilter = ""
    @State private var portFilter = ""
    @State private var serviceFilter = ""
    @State private var productFilter = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Advanced Filters")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                FilterField(title: "Country", text: $countryFilter, placeholder: "US, CN, RU")
                FilterField(title: "Port", text: $portFilter, placeholder: "22, 80, 443")
                FilterField(title: "Service", text: $serviceFilter, placeholder: "ssh, http, mysql")
                FilterField(title: "Product", text: $productFilter, placeholder: "apache, nginx")
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct FilterField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
        }
    }
}

struct InternetSearchMapView: View {
    let hosts: [IVREHost]
    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795), // Center of US
            span: MKCoordinateSpan(latitudeDelta: 50, longitudeDelta: 50)
        )
    )
    
    var body: some View {
        Map(position: $position) {
            ForEach(mapAnnotations) { annotation in
                Annotation(annotation.host.ip, coordinate: annotation.coordinate) {
                    HostMapMarker(annotation: annotation)
                }
            }
        }
        .frame(height: 400)
        .cornerRadius(8)
    }
    
    private var mapAnnotations: [HostMapAnnotation] {
        hosts.compactMap { host in
            guard let location = host.geolocation else { return nil }
            
            return HostMapAnnotation(
                coordinate: CLLocationCoordinate2D(
                    latitude: location.latitude,
                    longitude: location.longitude
                ),
                host: host
            )
        }
    }
}

struct HostMapAnnotation: Identifiable {
    let id: UUID = UUID()
    let coordinate: CLLocationCoordinate2D
    let host: IVREHost
}

struct HostMapMarker: View {
    let annotation: HostMapAnnotation
    
    var body: some View {
        VStack {
            Image(systemName: "network")
                .foregroundColor(.blue)
                .background(Circle().fill(.white))
                .font(.caption)
            
            Text(annotation.host.ip)
                .font(.caption2)
                .padding(2)
                .background(.white.opacity(0.8))
                .cornerRadius(4)
        }
    }
}

struct InternetSearchListView: View {
    let hosts: [IVREHost]
    
    var body: some View {
        List(hosts) { host in
            IVREHostRowView(host: host)
        }
        .listStyle(.plain)
    }
}

struct IVREHostRowView: View {
    let host: IVREHost
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(host.ip)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    if let hostname = host.hostname {
                        Text(hostname)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if let location = host.geolocation {
                        Text("\(location.country) / AS\(location.asNumber)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("\(host.openPorts.count) open ports")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                }
                .buttonStyle(.plain)
            }
            
            if isExpanded {
                HostDetailsExpanded(host: host)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct HostDetailsExpanded: View {
    let host: IVREHost
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Open ports
            if !host.openPorts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Open Ports")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(host.openPorts, id: \.number) { port in
                            PortBadge(port: port)
                        }
                    }
                }
            }
            
            // Certificates
            if !host.certificates.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Certificates")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(host.certificates, id: \.serialNumber) { cert in
                        CertificateRow(certificate: cert)
                    }
                }
            }
            
            // Action buttons
            HStack {
                Button("Add to Targets") {
                    addToTargets(host)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Button("Full Details") {
                    showFullDetails(host)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("Related Hosts") {
                    findRelatedHosts(host)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.top, 8)
    }
    
    private func addToTargets(_ host: IVREHost) {
        // Add to DonkTool targets
    }
    
    private func showFullDetails(_ host: IVREHost) {
        // Show detailed view
    }
    
    private func findRelatedHosts(_ host: IVREHost) {
        // Search for related infrastructure
    }
}

struct PortBadge: View {
    let port: IVREPort
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(port.number)")
                .font(.caption)
                .fontWeight(.bold)
            
            if let service = port.service {
                Text(service)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(6)
        .background(port.isVulnerable ? Color.red.opacity(0.2) : Color.green.opacity(0.2))
        .cornerRadius(4)
    }
}

struct CertificateRow: View {
    let certificate: X509Certificate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(certificate.subject)
                .font(.caption)
                .fontWeight(.medium)
            
            Text("Issuer: \(certificate.issuer)")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            HStack {
                Text("Valid: \(certificate.validFrom.formatted(date: .abbreviated, time: .omitted)) - \(certificate.validTo.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if certificate.isExpired {
                    Text("EXPIRED")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                } else if certificate.isExpiringSoon {
                    Text("EXPIRES SOON")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(6)
    }
}

// MARK: - Data Models

struct IVREHost: Identifiable, Codable {
    let id: String
    let ip: String
    let hostname: String?
    let ports: [IVREPort]
    let geolocation: GeoLocation?
    let certificates: [X509Certificate]
    let lastSeen: Date
    let firstSeen: Date
    let asNumber: Int?
    let country: String?
    
    var openPorts: [IVREPort] {
        ports.filter { $0.state == "open" }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, ip, hostname, ports, geolocation, certificates, lastSeen, firstSeen, asNumber, country
    }
}

struct IVREPort: Identifiable, Codable {
    let id: UUID
    let number: Int
    let portProtocol: String
    let state: String
    let service: String?
    let product: String?
    let version: String?
    let banner: String?
    let cpe: [String]
    let vulnerabilities: [String]
    
    var isVulnerable: Bool {
        !vulnerabilities.isEmpty
    }
    
    init(id: UUID = UUID(), number: Int, portProtocol: String, state: String, service: String? = nil, product: String? = nil, version: String? = nil, banner: String? = nil, cpe: [String] = [], vulnerabilities: [String] = []) {
        self.id = id
        self.number = number
        self.portProtocol = portProtocol
        self.state = state
        self.service = service
        self.product = product
        self.version = version
        self.banner = banner
        self.cpe = cpe
        self.vulnerabilities = vulnerabilities
    }
    
    enum CodingKeys: String, CodingKey {
        case id, number
        case portProtocol = "protocol"
        case state, service, product, version, banner, cpe, vulnerabilities
    }
}

struct GeoLocation: Codable {
    let latitude: Double
    let longitude: Double
    let country: String
    let city: String?
    let asNumber: Int
    let asName: String
}

struct X509Certificate: Identifiable, Codable {
    let id: UUID
    let subject: String
    let issuer: String
    let serialNumber: String
    let validFrom: Date
    let validTo: Date
    let fingerprint: String
    let keySize: Int
    let algorithm: String
    
    var isExpired: Bool {
        validTo < Date()
    }
    
    var isExpiringSoon: Bool {
        let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        return validTo < thirtyDaysFromNow && !isExpired
    }
    
    enum CodingKeys: String, CodingKey {
        case id, subject, issuer, serialNumber, validFrom, validTo, fingerprint, keySize, algorithm
    }
}

struct PassiveDNSRecord: Identifiable, Codable {
    let id: UUID
    let domain: String
    let ip: String
    let recordType: String
    let firstSeen: Date
    let lastSeen: Date
    let count: Int
    
    enum CodingKeys: String, CodingKey {
        case id, domain, ip, recordType, firstSeen, lastSeen, count
    }
}

struct NetworkFlow: Identifiable, Codable {
    let id: UUID
    let sourceIP: String
    let destIP: String
    let sourcePort: Int
    let destPort: Int
    let flowProtocol: String
    let byteCount: Int
    let packetCount: Int
    let startTime: Date
    let endTime: Date
    
    enum CodingKeys: String, CodingKey {
        case id, sourceIP, destIP, sourcePort, destPort
        case flowProtocol = "protocol"
        case byteCount, packetCount, startTime, endTime
    }
}

// MARK: - Configuration

struct IVREConfiguration {
    let serverURL: URL
    let databaseName: String
    let apiKey: String?
    var enablePassiveDNS: Bool = true
    var enableFlowAnalysis: Bool = true
    var autoSync: Bool = false
    var syncInterval: TimeInterval = 3600 // 1 hour
}

struct IVREConfigurationView: View {
    @State private var serverURL = "http://localhost:8080"
    @State private var databaseName = "ivre"
    @State private var apiKey = ""
    @State private var enablePassiveDNS = true
    @State private var enableFlowAnalysis = true
    @State private var autoSync = false
    @State private var testResult = ""
    @State private var isTesting = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Server Configuration") {
                    TextField("Server URL", text: $serverURL)
                    TextField("Database Name", text: $databaseName)
                    SecureField("API Key (optional)", text: $apiKey)
                }
                
                Section("Features") {
                    Toggle("Enable Passive DNS", isOn: $enablePassiveDNS)
                    Toggle("Enable Flow Analysis", isOn: $enableFlowAnalysis)
                    Toggle("Auto-sync with DonkTool", isOn: $autoSync)
                }
                
                Section("Actions") {
                    Button("Test Connection") {
                        testConnection()
                    }
                    .disabled(isTesting)
                    
                    if isTesting {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    
                    if !testResult.isEmpty {
                        Text(testResult)
                            .font(.caption)
                            .foregroundColor(testResult.contains("✅") ? .green : .red)
                    }
                    
                    Button("Initialize Database") {
                        initializeDatabase()
                    }
                }
            }
            .navigationTitle("IVRE Configuration")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        saveConfiguration()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 500, height: 400)
    }
    
    private func testConnection() {
        isTesting = true
        testResult = ""
        
        Task {
            do {
                let testURL = URL(string: serverURL)!
                let statusURL = testURL.appendingPathComponent("/api/status")
                let (data, response) = try await URLSession.shared.data(from: statusURL)
                
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200,
                   let status = try? JSONDecoder().decode(IVREStatus.self, from: data) {
                    await MainActor.run {
                        self.testResult = "✅ Connected! Hosts: \(status.hostCount)"
                        self.isTesting = false
                    }
                } else {
                    await MainActor.run {
                        self.testResult = "❌ Connection failed"
                        self.isTesting = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.testResult = "❌ Error: \(error.localizedDescription)"
                    self.isTesting = false
                }
            }
        }
    }
    
    private func initializeDatabase() {
        // Initialize IVRE database
    }
    
    private func saveConfiguration() {
        // Save configuration
    }
}

// MARK: - Search Presets

struct IVRESearchPresets {
    static let allPresets = [
        SearchPreset(name: "Exposed SSH", query: "port:22 country:US"),
        SearchPreset(name: "Vulnerable Apache", query: "product:apache version:2.4.49"),
        SearchPreset(name: "Default Web Pages", query: "http.title:'Apache2 Ubuntu Default Page'"),
        SearchPreset(name: "Exposed RDP", query: "port:3389"),
        SearchPreset(name: "IoT Cameras", query: "product:hikvision,dahua,axis"),
        SearchPreset(name: "Exposed Databases", query: "port:3306,5432,1433,27017"),
        SearchPreset(name: "VPN Endpoints", query: "port:1723,500,4500"),
        SearchPreset(name: "Industrial Control", query: "port:502,44818 country:US"),
        SearchPreset(name: "Cloud Services", query: "cloud:aws,azure,gcp"),
        SearchPreset(name: "Certificate Authorities", query: "cert.issuer:'DigiCert Inc'")
    ]
}

struct SearchPreset {
    let name: String
    let query: String
}

// MARK: - API Client

class IVREAPIClient {
    private let configuration: IVREConfiguration
    private let session = URLSession.shared
    
    var baseURL: String {
        return configuration.serverURL.absoluteString
    }
    
    init(configuration: IVREConfiguration) {
        self.configuration = configuration
    }
    
    func getStatus() async throws -> IVREStatus {
        let url = configuration.serverURL.appendingPathComponent("/api/status")
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(IVREStatus.self, from: data)
    }
    
    func searchHosts(query: String) async throws -> [IVREHost] {
        let url = configuration.serverURL.appendingPathComponent("/cgi/scans")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let searchRequest = IVRESearchRequest(query: query, limit: 100)
        request.httpBody = try JSONEncoder().encode(searchRequest)
        
        let (data, response) = try await session.data(for: request)
        
        // Debug logging
        if let httpResponse = response as? HTTPURLResponse {
            print("IVRE Search Response: \(httpResponse.statusCode)")
        }
        
        // Try to parse the API response
        do {
            let apiResponse = try JSONDecoder().decode(IVREAPISearchResponse.self, from: data)
            print("IVRE Search Results: \(apiResponse.count) hosts found")
            print("IVRE API Hosts: \(apiResponse.hosts.count)")
            
            let domainHosts = apiResponse.hosts.map { apiHost -> IVREHost in
                let host = apiHost.toDomainModel()
                print("Converted host: \(host.ip) with \(host.ports.count) ports")
                return host
            }
            
            print("IVRE Domain Hosts: \(domainHosts.count)")
            return domainHosts
        } catch {
            print("IVRE Search Parse Error: \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response data: \(responseString.prefix(500))")
            }
            throw error
        }
    }
    
    func getPassiveDNS(domain: String) async throws -> [PassiveDNSRecord] {
        let url = configuration.serverURL.appendingPathComponent("/cgi/passivedns")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "rrname", value: domain)]
        
        guard let requestURL = components?.url else {
            throw IVREError.invalidURL
        }
        
        let (data, _) = try await session.data(from: requestURL)
        return try JSONDecoder().decode([PassiveDNSRecord].self, from: data)
    }
    
    func submitScanData(_ scanData: IVREScanData) async throws {
        let url = configuration.serverURL.appendingPathComponent("/api/submit")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpBody = try JSONEncoder().encode(scanData)
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw IVREError.submissionFailed
        }
    }
    
    func searchFreeSources(query: String, source: String) async throws -> [IVREHost] {
        let url = configuration.serverURL.appendingPathComponent("/api/free-recon/search")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["query": query, "source": source]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await session.data(for: request)
        
        // Debug logging
        if let httpResponse = response as? HTTPURLResponse {
            print("IVRE Free Search Response: \(httpResponse.statusCode)")
        }
        
        // Parse the response
        do {
            let freeReconResponse = try JSONDecoder().decode(FreeReconResponse.self, from: data)
            print("IVRE Free Search Results: \(freeReconResponse.count) hosts found")
            return freeReconResponse.hosts
        } catch {
            print("IVRE Free Search Parse Error: \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response data: \(responseString.prefix(500))")
            }
            throw error
        }
    }
}

struct IVREStatus: Codable {
    let isConnected: Bool
    let hostCount: Int
    let version: String
}

struct IVRESearchRequest: Codable {
    let query: String
    let limit: Int
    let skip: Int
    
    init(query: String, limit: Int, skip: Int = 0) {
        self.query = query
        self.limit = limit
        self.skip = skip
    }
}

struct IVRESearchResponse: Codable {
    let hosts: [IVREHost]
    let count: Int
}

struct IVREScanData: Codable {
    let hosts: [IVREHost]
    let scanner: String
    let timestamp: Date
    
    init(hosts: [IVREHost], scanner: String = "DonkTool", timestamp: Date = Date()) {
        self.hosts = hosts
        self.scanner = scanner
        self.timestamp = timestamp
    }
}

enum IVREError: Error {
    case invalidURL
    case submissionFailed
    case connectionFailed
}

// MARK: - Supporting Views

struct ConnectionStatusBadge: View {
    let isConnected: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isConnected ? .green : .red)
                .frame(width: 8, height: 8)
            
            Text(isConnected ? "Connected" : "Disconnected")
                .font(.caption)
                .foregroundColor(isConnected ? .green : .red)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background((isConnected ? Color.green : Color.red).opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Passive DNS View

struct PassiveDNSView: View {
    let ivreManager: IVREManager
    @State private var domain = ""
    @State private var dnsRecords: [PassiveDNSRecord] = []
    @State private var isLoading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Passive DNS Lookup")
                    .font(.headline)
                
                HStack {
                    TextField("Domain (e.g., example.com)", text: $domain)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Query") {
                        queryPassiveDNS()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(domain.isEmpty || isLoading)
                }
            }
            
            if isLoading {
                ProgressView("Querying passive DNS...")
                    .frame(maxWidth: .infinity)
            } else if dnsRecords.isEmpty {
                ContentUnavailableView(
                    "No DNS Records",
                    systemImage: "network.slash",
                    description: Text("Enter a domain to query passive DNS records")
                )
            } else {
                PassiveDNSResultsView(records: dnsRecords)
            }
        }
        .padding()
    }
    
    private func queryPassiveDNS() {
        isLoading = true
        
        Task {
            let records = await ivreManager.getPassiveDNS(domain: domain)
            
            await MainActor.run {
                self.dnsRecords = records
                self.isLoading = false
            }
        }
    }
}

struct PassiveDNSResultsView: View {
    let records: [PassiveDNSRecord]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DNS Resolution History")
                .font(.headline)
            
            List(records) { record in
                PassiveDNSRecordRow(record: record)
            }
            .listStyle(.plain)
        }
    }
}

struct PassiveDNSRecordRow: View {
    let record: PassiveDNSRecord
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.ip)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(record.domain)
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(record.recordType)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
                
                Text("Seen \(record.count) times")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("\(record.firstSeen.formatted(date: .abbreviated, time: .omitted)) - \(record.lastSeen.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Flow Analysis View

struct FlowAnalysisView: View {
    let ivreManager: IVREManager
    @State private var selectedTimeRange: TimeRange = .last24Hours
    @State private var selectedProtocol: String = "All"
    
    enum TimeRange: String, CaseIterable {
        case last1Hour = "Last Hour"
        case last24Hours = "Last 24 Hours"
        case last7Days = "Last 7 Days"
        case last30Days = "Last 30 Days"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Network Flow Analysis")
                    .font(.headline)
                
                Spacer()
                
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.menu)
                
                Picker("Protocol", selection: $selectedProtocol) {
                    Text("All").tag("All")
                    Text("TCP").tag("TCP")
                    Text("UDP").tag("UDP")
                    Text("ICMP").tag("ICMP")
                }
                .pickerStyle(.menu)
            }
            
            FlowVisualizationView(flows: ivreManager.flowData)
            
            FlowTableView(flows: ivreManager.flowData)
        }
        .padding()
    }
}

struct FlowVisualizationView: View {
    let flows: [NetworkFlow]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Traffic Overview")
                .font(.subheadline)
                .fontWeight(.medium)
            
            // Simple flow visualization placeholder
            Rectangle()
                .fill(Color.blue.opacity(0.1))
                .frame(height: 200)
                .overlay(
                    Text("Flow Visualization\n\(flows.count) flows")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.blue)
                )
                .cornerRadius(8)
        }
    }
}

struct FlowTableView: View {
    let flows: [NetworkFlow]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Flow Details")
                .font(.subheadline)
                .fontWeight(.medium)
            
            List(flows) { flow in
                FlowRowView(flow: flow)
            }
            .listStyle(.plain)
        }
    }
}

struct FlowRowView: View {
    let flow: NetworkFlow
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(flow.sourceIP):\(flow.sourcePort) → \(flow.destIP):\(flow.destPort)")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("\(flow.flowProtocol) • \(flow.byteCount) bytes • \(flow.packetCount) packets")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(flow.startTime.formatted(date: .omitted, time: .shortened))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Threat Hunting View

struct ThreatHuntingView: View {
    @State private var iocInput = ""
    @State private var threatResults: [ThreatIntelligence] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Threat Hunting")
                .font(.headline)
            
            HStack {
                TextField("IOC (IP, domain, hash)", text: $iocInput)
                    .textFieldStyle(.roundedBorder)
                
                Button("Hunt") {
                    performThreatHunt()
                }
                .buttonStyle(.borderedProminent)
            }
            
            if threatResults.isEmpty {
                ContentUnavailableView(
                    "No Threat Data",
                    systemImage: "magnifyingglass.circle",
                    description: Text("Enter an IOC to begin threat hunting")
                )
            } else {
                ThreatResultsView(results: threatResults)
            }
        }
        .padding()
    }
    
    private func performThreatHunt() {
        // Implement threat hunting logic
    }
}

struct ThreatIntelligence: Identifiable {
    let id: UUID = UUID()
    let ioc: String
    let type: String
    let riskScore: Int
    let lastSeen: Date
    let relatedHosts: [String]
    let campaigns: [String]
}

struct ThreatResultsView: View {
    let results: [ThreatIntelligence]
    
    var body: some View {
        List(results) { result in
            ThreatIntelligenceRow(intelligence: result)
        }
        .listStyle(.plain)
    }
}

struct ThreatIntelligenceRow: View {
    let intelligence: ThreatIntelligence
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(intelligence.ioc)
                    .font(.headline)
                
                Spacer()
                
                RiskScoreBadge(score: intelligence.riskScore)
            }
            
            Text("Type: \(intelligence.type)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Last seen: \(intelligence.lastSeen.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if !intelligence.relatedHosts.isEmpty {
                Text("Related hosts: \(intelligence.relatedHosts.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct RiskScoreBadge: View {
    let score: Int
    
    var body: some View {
        Text("\(score)")
            .font(.caption)
            .fontWeight(.bold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(riskColor.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(4)
    }
    
    private var riskColor: Color {
        switch score {
        case 80...100: return .red
        case 60...79: return .orange
        case 40...59: return .yellow
        default: return .green
        }
    }
}

// MARK: - Environment Extension
// (Already defined at the top of the file)

struct IVREIntegrationView_Previews: PreviewProvider {
    static var previews: some View {
        IVREIntegrationView()
            .environment(AppState())
            .frame(width: 1200, height: 800)
    }
}