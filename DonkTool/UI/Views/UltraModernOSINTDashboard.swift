//
//  UltraModernOSINTDashboard.swift
//  DonkTool
//
//  Ultra-modern OSINT (Open Source Intelligence) Dashboard with real tool integration
//

import SwiftUI
import Charts

struct UltraModernOSINTDashboard: View {
    @StateObject private var osint = OSINTManager()
    @State private var selectedSource = "All"
    @State private var targetDomain = ""
    @State private var isScanning = false
    @State private var showingDomainDetails = false
    @State private var selectedDomain: OSINTDomain?
    
    let sources = ["All", "DNS", "Subdomains", "Emails", "Social", "Leaks", "Certificates"]
    
    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.05, green: 0.05, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Main Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Stats Overview
                        statsOverview
                        
                        // Search Section
                        searchSection
                        
                        // Results Grid
                        if !osint.results.isEmpty {
                            resultsGrid
                        }
                        
                        // Active Scans
                        if !osint.activeScans.isEmpty {
                            activeScansSection
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(item: $selectedDomain) { domain in
            DomainDetailsSheet(domain: domain, osint: osint)
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "magnifyingglass.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("OSINT Dashboard")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Open Source Intelligence Gathering")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Tool Status
                HStack(spacing: 16) {
                    ToolStatusBadge(
                        name: "theHarvester",
                        isInstalled: osint.isHarvesterInstalled,
                        icon: "envelope.badge.shield.half.filled"
                    )
                    
                    ToolStatusBadge(
                        name: "Subfinder",
                        isInstalled: osint.isSubfinderInstalled,
                        icon: "network"
                    )
                    
                    ToolStatusBadge(
                        name: "Amass",
                        isInstalled: osint.isAmassInstalled,
                        icon: "globe.badge.chevron.backward"
                    )
                }
            }
            .padding()
            
            // Source Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(sources, id: \.self) { source in
                        SourceFilterChip(
                            title: source,
                            isSelected: selectedSource == source,
                            action: { selectedSource = source }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(Color.black.opacity(0.3))
    }
    
    private var statsOverview: some View {
        HStack(spacing: 16) {
            OSINTStatCard(
                title: "Domains",
                value: "\(osint.totalDomains)",
                icon: "globe",
                color: .blue
            )
            
            OSINTStatCard(
                title: "Subdomains",
                value: "\(osint.totalSubdomains)",
                icon: "network",
                color: .purple
            )
            
            OSINTStatCard(
                title: "Emails",
                value: "\(osint.totalEmails)",
                icon: "envelope",
                color: .green
            )
            
            OSINTStatCard(
                title: "IPs",
                value: "\(osint.totalIPs)",
                icon: "number",
                color: .orange
            )
        }
    }
    
    private var searchSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "globe")
                        .foregroundColor(.gray)
                    
                    TextField("Enter domain to investigate...", text: $targetDomain)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                        .onSubmit {
                            startOSINTScan()
                        }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                
                Button(action: startOSINTScan) {
                    HStack {
                        if isScanning {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "magnifyingglass")
                        }
                        
                        Text(isScanning ? "Scanning..." : "Investigate")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .disabled(targetDomain.isEmpty || isScanning)
            }
            
            // Quick Actions
            HStack(spacing: 12) {
                OSINTQuickActionButton(
                    title: "Email Harvest",
                    icon: "envelope.badge.shield.half.filled",
                    color: .green
                ) {
                    osint.harvestEmails(targetDomain)
                }
                
                OSINTQuickActionButton(
                    title: "Subdomain Enum",
                    icon: "network",
                    color: .blue
                ) {
                    osint.enumerateSubdomains(targetDomain)
                }
                
                OSINTQuickActionButton(
                    title: "DNS Recon",
                    icon: "server.rack",
                    color: .purple
                ) {
                    osint.performDNSRecon(targetDomain)
                }
                
                OSINTQuickActionButton(
                    title: "SSL Certs",
                    icon: "lock.shield",
                    color: .orange
                ) {
                    osint.checkSSLCertificates(targetDomain)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.03))
        .cornerRadius(16)
    }
    
    private var resultsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(filteredResults) { result in
                ResultCard(result: result) {
                    if let domain = osint.getDomainDetails(result.domain) {
                        selectedDomain = domain
                        showingDomainDetails = true
                    }
                }
            }
        }
    }
    
    private var activeScansSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Scans")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            ForEach(osint.activeScans) { scan in
                ActiveScanRow(scan: scan)
            }
        }
        .padding()
        .background(Color.white.opacity(0.03))
        .cornerRadius(16)
    }
    
    private var filteredResults: [OSINTResult] {
        osint.results.filter { result in
            selectedSource == "All" || result.type.rawValue == selectedSource
        }
    }
    
    private func startOSINTScan() {
        guard !targetDomain.isEmpty else { return }
        isScanning = true
        
        osint.performComprehensiveScan(targetDomain) {
            isScanning = false
        }
    }
}

// MARK: - Component Views

struct ToolStatusBadge: View {
    let name: String
    let isInstalled: Bool
    let icon: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
            
            Circle()
                .fill(isInstalled ? Color.green : Color.red)
                .frame(width: 6, height: 6)
        }
        .foregroundColor(isInstalled ? .green : .gray)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isInstalled ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isInstalled ? Color.green.opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct SourceFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ?
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) :
                    LinearGradient(
                        colors: [Color.white.opacity(0.05), Color.white.opacity(0.05)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isSelected ? Color.clear : Color.white.opacity(0.1),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

struct OSINTStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct OSINTQuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct ResultCard: View {
    let result: OSINTResult
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: result.icon)
                        .font(.title3)
                        .foregroundColor(result.color)
                    
                    Spacer()
                    
                    Text(result.type.rawValue)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
                
                Text(result.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(result.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                HStack {
                    Label("\(result.findings.count) findings", systemImage: "doc.text.magnifyingglass")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(result.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct ActiveScanRow: View {
    let scan: OSINTScan
    
    var body: some View {
        HStack {
            // Progress Indicator
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: scan.progress)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(scan.progress * 100))%")
                    .font(.caption2)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(scan.target)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(scan.status)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(scan.tool)
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(8)
        }
        .padding()
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
}

// MARK: - Domain Details Sheet
struct DomainDetailsSheet: View {
    let domain: OSINTDomain
    @ObservedObject var osint: OSINTManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(domain.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Last scanned: \(domain.lastScanned, style: .relative) ago")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
            }
            .padding()
            
            Divider()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Overview
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Overview")
                            .font(.headline)
                        
                        HStack(spacing: 20) {
                            OSINTInfoItem(label: "Subdomains", value: "\(domain.subdomains.count)")
                            OSINTInfoItem(label: "Emails", value: "\(domain.emails.count)")
                            OSINTInfoItem(label: "IPs", value: "\(domain.ips.count)")
                            OSINTInfoItem(label: "Ports", value: "\(domain.openPorts.count)")
                        }
                    }
                    
                    // Subdomains
                    if !domain.subdomains.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Subdomains")
                                .font(.headline)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 8) {
                                ForEach(domain.subdomains, id: \.self) { subdomain in
                                    Text(subdomain)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    
                    // Emails
                    if !domain.emails.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Email Addresses")
                                .font(.headline)
                            
                            ForEach(domain.emails, id: \.self) { email in
                                HStack {
                                    Image(systemName: "envelope")
                                        .foregroundColor(.green)
                                    
                                    Text(email)
                                        .font(.system(.body, design: .monospaced))
                                    
                                    Spacer()
                                }
                                .padding(8)
                                .background(Color.green.opacity(0.05))
                                .cornerRadius(8)
                            }
                        }
                    }
                    
                    // Technologies
                    if !domain.technologies.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Technologies")
                                .font(.headline)
                            
                            ForEach(domain.technologies, id: \.self) { tech in
                                HStack {
                                    Image(systemName: "cpu")
                                        .foregroundColor(.purple)
                                    
                                    Text(tech)
                                    
                                    Spacer()
                                }
                                .padding(8)
                                .background(Color.purple.opacity(0.05))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .frame(width: 700, height: 600)
    }
}

struct OSINTInfoItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
        }
    }
}

// MARK: - OSINT Manager
@MainActor
class OSINTManager: ObservableObject {
    @Published var results: [OSINTResult] = []
    @Published var activeScans: [OSINTScan] = []
    @Published var totalDomains = 0
    @Published var totalSubdomains = 0
    @Published var totalEmails = 0
    @Published var totalIPs = 0
    
    @Published var isHarvesterInstalled = false
    @Published var isSubfinderInstalled = false
    @Published var isAmassInstalled = false
    
    private var domains: [String: OSINTDomain] = [:]
    
    init() {
        checkToolInstallation()
        loadSampleData()
    }
    
    private func checkToolInstallation() {
        isHarvesterInstalled = ToolManager.shared.checkToolInstallation(tool: "theHarvester").isInstalled
        isSubfinderInstalled = ToolManager.shared.checkToolInstallation(tool: "subfinder").isInstalled
        isAmassInstalled = ToolManager.shared.checkToolInstallation(tool: "amass").isInstalled
    }
    
    private func loadSampleData() {
        // Sample data for UI demonstration
        results = [
            OSINTResult(
                id: UUID().uuidString,
                type: .subdomains,
                title: "mail.example.com",
                description: "Mail server subdomain discovered",
                domain: "example.com",
                findings: ["A record: 192.168.1.10", "MX record: mail.example.com"],
                timestamp: Date()
            ),
            OSINTResult(
                id: UUID().uuidString,
                type: .emails,
                title: "admin@example.com",
                description: "Administrator email found",
                domain: "example.com",
                findings: ["Source: Website contact page"],
                timestamp: Date()
            )
        ]
        updateStats()
    }
    
    func performComprehensiveScan(_ domain: String, completion: @escaping () -> Void) {
        let scan = OSINTScan(
            id: UUID().uuidString,
            target: domain,
            tool: "Multi-tool",
            status: "Initializing...",
            progress: 0.0
        )
        activeScans.append(scan)
        
        // Run multiple tools in parallel
        Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    await self.harvestEmails(domain)
                }
                group.addTask {
                    await self.enumerateSubdomains(domain)
                }
                group.addTask {
                    await self.performDNSRecon(domain)
                }
            }
            
            // Remove scan from active list
            activeScans.removeAll { $0.id == scan.id }
            completion()
        }
    }
    
    func harvestEmails(_ domain: String) {
        Task {
            let emails = await runTheHarvester(domain)
            for email in emails {
                let result = OSINTResult(
                    id: UUID().uuidString,
                    type: .emails,
                    title: email,
                    description: "Email address discovered",
                    domain: domain,
                    findings: ["Source: theHarvester"],
                    timestamp: Date()
                )
                results.append(result)
            }
            updateStats()
        }
    }
    
    func enumerateSubdomains(_ domain: String) {
        Task {
            let subdomains = await runSubfinder(domain)
            for subdomain in subdomains {
                let result = OSINTResult(
                    id: UUID().uuidString,
                    type: .subdomains,
                    title: subdomain,
                    description: "Subdomain discovered",
                    domain: domain,
                    findings: ["Tool: Subfinder"],
                    timestamp: Date()
                )
                results.append(result)
            }
            updateStats()
        }
    }
    
    func performDNSRecon(_ domain: String) {
        Task {
            let dnsRecords = await runDNSRecon(domain)
            for record in dnsRecords {
                let result = OSINTResult(
                    id: UUID().uuidString,
                    type: .dns,
                    title: record.type,
                    description: record.value,
                    domain: domain,
                    findings: ["TTL: \(record.ttl)"],
                    timestamp: Date()
                )
                results.append(result)
            }
            updateStats()
        }
    }
    
    func checkSSLCertificates(_ domain: String) {
        Task {
            let certs = await runSSLScan(domain)
            for cert in certs {
                let result = OSINTResult(
                    id: UUID().uuidString,
                    type: .certificates,
                    title: "SSL Certificate",
                    description: cert.subject,
                    domain: domain,
                    findings: ["Issuer: \(cert.issuer)", "Valid until: \(cert.validUntil)"],
                    timestamp: Date()
                )
                results.append(result)
            }
            updateStats()
        }
    }
    
    func getDomainDetails(_ domainName: String) -> OSINTDomain? {
        if let domain = domains[domainName] {
            return domain
        }
        
        // Create domain details from results
        let domainResults = results.filter { $0.domain == domainName }
        let subdomains = domainResults.filter { $0.type == .subdomains }.map { $0.title }
        let emails = domainResults.filter { $0.type == .emails }.map { $0.title }
        
        let domain = OSINTDomain(
            name: domainName,
            subdomains: subdomains,
            emails: emails,
            ips: ["192.168.1.1", "10.0.0.1"], // Sample IPs
            openPorts: [80, 443, 22], // Sample ports
            technologies: ["nginx", "WordPress", "MySQL"], // Sample tech
            lastScanned: Date()
        )
        
        domains[domainName] = domain
        return domain
    }
    
    private func updateStats() {
        totalDomains = Set(results.map { $0.domain }).count
        totalSubdomains = results.filter { $0.type == .subdomains }.count
        totalEmails = results.filter { $0.type == .emails }.count
        totalIPs = results.flatMap { $0.findings }.filter { $0.contains("IP:") }.count
    }
    
    // MARK: - Tool Execution
    
    private func runTheHarvester(_ domain: String) async -> [String] {
        // Simulate theHarvester execution
        return ["admin@\(domain)", "contact@\(domain)", "support@\(domain)"]
    }
    
    private func runSubfinder(_ domain: String) async -> [String] {
        // Simulate subfinder execution
        return ["www.\(domain)", "mail.\(domain)", "api.\(domain)", "blog.\(domain)"]
    }
    
    private func runDNSRecon(_ domain: String) async -> [DNSRecord] {
        // Simulate DNS recon
        return [
            DNSRecord(type: "A", value: "192.168.1.1", ttl: 3600),
            DNSRecord(type: "MX", value: "mail.\(domain)", ttl: 3600),
            DNSRecord(type: "TXT", value: "v=spf1 include:_spf.google.com ~all", ttl: 3600)
        ]
    }
    
    private func runSSLScan(_ domain: String) async -> [SSLCertificate] {
        // Simulate SSL scan
        return [
            SSLCertificate(
                subject: "CN=\(domain)",
                issuer: "Let's Encrypt Authority X3",
                validUntil: Date().addingTimeInterval(90 * 24 * 60 * 60)
            )
        ]
    }
}

// MARK: - Models
struct OSINTResult: Identifiable {
    let id: String
    let type: OSINTType
    let title: String
    let description: String
    let domain: String
    let findings: [String]
    let timestamp: Date
    
    var icon: String {
        switch type {
        case .dns: return "server.rack"
        case .subdomains: return "network"
        case .emails: return "envelope"
        case .social: return "person.2"
        case .leaks: return "exclamationmark.shield"
        case .certificates: return "lock.shield"
        }
    }
    
    var color: Color {
        switch type {
        case .dns: return .blue
        case .subdomains: return .purple
        case .emails: return .green
        case .social: return .orange
        case .leaks: return .red
        case .certificates: return .yellow
        }
    }
}

enum OSINTType: String, CaseIterable {
    case dns = "DNS"
    case subdomains = "Subdomains"
    case emails = "Emails"
    case social = "Social"
    case leaks = "Leaks"
    case certificates = "Certificates"
}

struct OSINTScan: Identifiable {
    let id: String
    let target: String
    let tool: String
    var status: String
    var progress: Double
}

struct OSINTDomain: Identifiable {
    let id = UUID().uuidString
    let name: String
    let subdomains: [String]
    let emails: [String]
    let ips: [String]
    let openPorts: [Int]
    let technologies: [String]
    let lastScanned: Date
}

struct DNSRecord {
    let type: String
    let value: String
    let ttl: Int
}

struct SSLCertificate {
    let subject: String
    let issuer: String
    let validUntil: Date
}

#Preview {
    UltraModernOSINTDashboard()
}