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
    @StateObject private var ivreManager = IVREManager()
    @State private var searchQuery = ""
    @State private var selectedTab = 0
    @State private var showingConfiguration = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with connection status
            IVREHeaderView()
            
            // Search bar
            IVRESearchBar()
            
            // Tab view for different IVRE features
            TabView(selection: $selectedTab) {
                InternetSearchView()
                    .tabItem {
                        Label("Internet Search", systemImage: "globe")
                    }
                    .tag(0)
                
                PassiveDNSView()
                    .tabItem {
                        Label("Passive DNS", systemImage: "network")
                    }
                    .tag(1)
                
                FlowAnalysisView()
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
            .disabled(searchQuery.isEmpty || !ivreManager.isConnected)
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    private func performSearch() {
        Task {
            await ivreManager.search(query: searchQuery)
        }
    }
}

// MARK: - IVRE Manager

@Observable
class IVREManager {
    var isConnected = false
    var isSyncing = false
    var totalHosts = 0
    var lastSyncTime: Date?
    var searchResults: [IVREHost] = []
    var passiveDNSResults: [PassiveDNSRecord] = []
    var flowData: [NetworkFlow] = []
    
    private var ivreClient: IVREAPIClient?
    private var configuration: IVREConfiguration?
    
    func initialize() async {
        await loadConfiguration()
        await connectToIVRE()
    }
    
    func search(query: String) async {
        guard let client = ivreClient else { return }
        
        do {
            let results = try await client.searchHosts(query: query)
            await MainActor.run {
                self.searchResults = results
            }
        } catch {
            print("IVRE search error: \(error)")
        }
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
            serverURL: URL(string: "http://localhost")!,
            databaseName: "ivre",
            apiKey: nil
        )
        
        await MainActor.run {
            self.configuration = config
        }
    }
    
    private func connectToIVRE() async {
        guard let config = configuration else { return }
        
        ivreClient = IVREAPIClient(configuration: config)
        
        do {
            let status = try await ivreClient?.getStatus()
            await MainActor.run {
                self.isConnected = status?.isConnected ?? false
                self.totalHosts = status?.hostCount ?? 0
            }
        } catch {
            await MainActor.run {
                self.isConnected = false
            }
        }
    }
    
    private func convertScanResultsToIVREFormat(_ results: [PortScanResult], target: String) -> IVREScanData {
        let host = IVREHost(
            ip: target,
            hostname: nil,
            ports: results.map { result in
                IVREPort(
                    number: result.port,
                    protocol: "tcp",
                    state: result.isOpen ? "open" : "closed",
                    service: result.service,
                    banner: result.banner,
                    version: result.version
                )
            },
            scanTime: Date(),
            scanner: "DonkTool"
        )
        
        return IVREScanData(hosts: [host])
    }
}

// MARK: - Internet Search View

struct InternetSearchView: View {
    @Environment(\.ivreManager) private var ivreManager
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
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795), // Center of US
        span: MKCoordinateSpan(latitudeDelta: 50, longitudeDelta: 50)
    )
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: mapAnnotations) { annotation in
            MapAnnotation(coordinate: annotation.coordinate) {
                HostMapMarker(annotation: annotation)
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
    let id = UUID()
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

struct IVREHost: Identifiable {
    let id = UUID()
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
}

struct IVREPort: Identifiable {
    let id = UUID()
    let number: Int
    let protocol: String
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
}

struct GeoLocation {
    let latitude: Double
    let longitude: Double
    let country: String
    let city: String?
    let asNumber: Int
    let asName: String
}

struct X509Certificate: Identifiable {
    let id = UUID()
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
}

struct PassiveDNSRecord: Identifiable {
    let id = UUID()
    let domain: String
    let ip: String
    let recordType: String
    let firstSeen: Date
    let lastSeen: Date
    let count: Int
}

struct NetworkFlow: Identifiable {
    let id = UUID()
    let sourceIP: String
    let destIP: String
    let sourcePort: Int
    let destPort: Int
    let protocol: String
    let byteCount: Int
    let packetCount: Int
    let startTime: Date
    let endTime: Date
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
    @State private var serverURL = "http://localhost"
    @State private var databaseName = "ivre"
    @State private var apiKey = ""
    @State private var enablePassiveDNS = true
    @State private var enableFlowAnalysis = true
    @State private var autoSync = false
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
        // Test IVRE connection
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
        
        let (data, _) = try await session.data(for: request)
        let response = try JSONDecoder().decode(IVRESearchResponse.self, from: data)
        
        return response.hosts
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
}

struct IVREStatus: Codable {
    let isConnected: Bool
    let hostCount: Int
    let version: String
}

struct IVRESearchRequest: Codable {
    let query: String
    let limit: Int
    let skip: Int = 0
}

struct IVRESearchResponse: Codable {
    let hosts: [IVREHost]
    let count: Int
}

struct IVREScanData: Codable {
    let hosts: [IVREHost]
    let scanner: String = "DonkTool"
    let timestamp: Date = Date()
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
    @Environment(\.ivreManager) private var ivreManager
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
    @Environment(\.ivreManager) private var ivreManager
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
                
                Text("\(flow.protocol) • \(flow.byteCount) bytes • \(flow.packetCount) packets")
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
    let id = UUID()
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

private struct IVREManagerKey: EnvironmentKey {
    static let defaultValue = IVREManager()
}

extension EnvironmentValues {
    var ivreManager: IVREManager {
        get { self[IVREManagerKey.self] }
        set { self[IVREManagerKey.self] = newValue }
    }
}

#Preview {
    IVREIntegrationView()
        .environment(AppState())
        .frame(width: 1200, height: 800)
}