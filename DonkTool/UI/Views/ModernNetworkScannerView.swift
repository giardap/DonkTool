//
//  ModernNetworkScannerView.swift
//  DonkTool
//
//  Modern network scanner with background operations
//

import SwiftUI

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
import Combine

struct ModernNetworkScannerView: View {
    @Environment(AppState.self) private var appState
    @State private var targetIP = ""
@State private var resolvedTargetIP = ""
    @State private var portRange = "1-1000"
    @State private var selectedScanType: ScanType = .tcpConnect
    @State private var scanResults: [PortScanResult] = []
    @State private var showingAdvancedOptions = false
    @State private var currentScanTask: Task<Void, Never>? = nil
    // Removed BackgroundScanManager - using simplified approach
    
    enum ScanType: String, CaseIterable {
        case tcpConnect = "TCP Connect"
        case syn = "SYN Scan"
        case udp = "UDP Scan"
        case comprehensive = "Comprehensive"
        
        var description: String {
            switch self {
            case .tcpConnect: return "Standard TCP connection scan"
            case .syn: return "Stealth SYN scan"
            case .udp: return "UDP port scan"
            case .comprehensive: return "Complete port and service scan"
            }
        }
        
        var icon: String {
            switch self {
            case .tcpConnect: return "network"
            case .syn: return "eye.slash"
            case .udp: return "antenna.radiowaves.left.and.right"
            case .comprehensive: return "magnifyingglass.circle"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Clean header
            CleanScanHeader()
            
            // Main content with better spacing
            HSplitView {
                // Left panel - simplified
                VStack(spacing: 24) {
                    TargetInputSection()
                    ScanOptionsSection()
                    ActionButtonsSection()
                    Spacer()
                }
                .frame(minWidth: 280, maxWidth: 350)
                .padding(24)
                .background(Color(NSColor.controlBackgroundColor))
                
                // Right panel - cleaner results
                CleanResultsPanel()
                    .frame(minWidth: 450)
            }
        }
        .navigationTitle("Network Scanner")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 8) {
                    if appState.isNetworkScanning {
                        Button("Stop") {
                            stopScan()
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Button(action: { showingAdvancedOptions.toggle() }) {
                        Image(systemName: showingAdvancedOptions ? "gearshape.fill" : "gearshape")
                    }
                    .help("Advanced Options")
                }
            }
        }
        .task {
            // Initialization if needed
        }
        .onAppear {
            // Load results from AppState when view appears
            if !appState.networkScanResults.isEmpty {
                scanResults = convertFromNetworkPortScanResults(appState.networkScanResults)
            }
        }
        .onChange(of: appState.networkScanResults) { _, newResults in
            // Update local results whenever AppState results change
            scanResults = convertFromNetworkPortScanResults(newResults)
        }
    }
    
    @ViewBuilder
    private func CleanScanHeader() -> some View {
        if appState.isNetworkScanning {
            VStack(spacing: 12) {
                HStack {
                    Text("Scanning \(appState.currentNetworkTarget)")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(Int(appState.networkScanProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: appState.networkScanProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            }
            .padding(16)
            .background(Color.blue.opacity(0.05))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.blue.opacity(0.2)),
                alignment: .bottom
            )
        }
    }
    
    @ViewBuilder
    private func TargetInputSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Target")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                TextField("IP Address or Hostname", text: $targetIP)
                    .textFieldStyle(.roundedBorder)
                    .disabled(appState.isNetworkScanning)
                
                HStack {
                    TextField("Port Range", text: $portRange)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 100)
                    
                    Button("Common") {
                        portRange = "21,22,23,25,53,80,110,143,443,993,995,3389"
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(appState.isNetworkScanning)
                }
            }
        }
    }
    
    @ViewBuilder
    private func ScanOptionsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Scan Type")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 6) {
                ForEach(ScanType.allCases, id: \.self) { type in
                    CleanScanTypeOption(
                        type: type,
                        isSelected: selectedScanType == type,
                        isDisabled: appState.isNetworkScanning
                    ) {
                        selectedScanType = type
                    }
                }
            }
            
            if showingAdvancedOptions {
                Divider()
                    .padding(.vertical, 8)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Advanced Options")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    VStack(spacing: 8) {
                        Toggle("Banner Grabbing", isOn: .constant(true))
                            .controlSize(.small)
                        Toggle("Service Detection", isOn: .constant(true))
                            .controlSize(.small)
                        Toggle("OS Detection", isOn: .constant(false))
                            .controlSize(.small)
                    }
                    .font(.caption)
                }
            }
        }
    }
    
    @ViewBuilder
    private func ActionButtonsSection() -> some View {
        VStack(spacing: 12) {
            Button(action: startScan) {
                HStack {
                    if appState.isNetworkScanning {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Scanning...")
                    } else {
                        Image(systemName: "play.fill")
                        Text("Start Scan")
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 40)
            }
            .buttonStyle(.borderedProminent)
            .disabled(targetIP.isEmpty || appState.isNetworkScanning)
            
            Button("Add to Targets") {
                addTarget()
            }
            .buttonStyle(.bordered)
            .disabled(targetIP.isEmpty)
            .frame(maxWidth: .infinity)
        }
    }
    
    @ViewBuilder
    private func CleanResultsPanel() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Results header
            HStack {
                Text("Results")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if !scanResults.isEmpty {
                    Text("\(scanResults.count) ports • \(openPorts) open")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Menu("Export") {
                        Button("Export CSV") { exportResults(format: .csv) }
                        Button("Export JSON") { exportResults(format: .json) }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider()
            
            // Results content
            if scanResults.isEmpty && !appState.isNetworkScanning {
                CleanEmptyState()
            } else {
                CleanResultsList()
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    @ViewBuilder
    private func CleanEmptyState() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "network")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("Ready to Scan")
                    .font(.headline)
                
                Text("Enter a target and click Start Scan")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func CleanResultsList() -> some View {
        List(scanResults) { result in
            CleanPortResultRow(result: result, targetIP: resolvedTargetIP.isEmpty ? targetIP : resolvedTargetIP)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 2, leading: 20, bottom: 2, trailing: 20))
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    private var openPorts: Int {
        scanResults.filter { $0.isOpen }.count
    }
    
    // Helper functions for scanning
    private func parsePortRangeInline(_ range: String) -> [Int] {
        var ports: [Int] = []
        
        let ranges = range.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        for range in ranges {
            if range.contains("-") {
                let parts = range.components(separatedBy: "-")
                if parts.count == 2,
                   let start = Int(parts[0].trimmingCharacters(in: .whitespaces)),
                   let end = Int(parts[1].trimmingCharacters(in: .whitespaces)),
                   start <= end {
                    ports.append(contentsOf: start...end)
                }
            } else {
                if let port = Int(range), port > 0 && port <= 65535 {
                    ports.append(port)
                }
            }
        }
        
        return Array(Set(ports)).sorted()
    }
    
    private func getServiceNameInline(port: Int) -> String? {
        let commonServices = [
            21: "FTP",
            22: "SSH", 
            23: "Telnet",
            25: "SMTP",
            53: "DNS",
            80: "HTTP",
            110: "POP3",
            143: "IMAP",
            443: "HTTPS",
            993: "IMAPS",
            995: "POP3S"
        ]
        
        return commonServices[port]
    }
    
    private func isValidIPAddress(_ string: String) -> Bool {
        // Check for IPv4 format
        let parts = string.components(separatedBy: ".")
        if parts.count == 4 {
            return parts.allSatisfy { part in
                if let num = Int(part), num >= 0 && num <= 255 {
                    return true
                }
                return false
            }
        }
        return false
    }
    
    private func resolveHostname(_ hostname: String) async -> String? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var hints = addrinfo()
                hints.ai_family = AF_INET  // Prefer IPv4 only
                hints.ai_socktype = SOCK_STREAM
                
                var result: UnsafeMutablePointer<addrinfo>?
                let status = getaddrinfo(hostname, nil, &hints, &result)
                
                defer {
                    if let result = result {
                        freeaddrinfo(result)
                    }
                }
                
                guard status == 0, let addr = result else {
                    continuation.resume(returning: nil)
                    return
                }
                
                // Convert the first address to string
                if let ipString = self.addressToString(addr.pointee.ai_addr, addr.pointee.ai_addrlen) {
                    continuation.resume(returning: ipString)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    private func addressToString(_ addr: UnsafePointer<sockaddr>, _ addrLen: socklen_t) -> String? {
        var buffer = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
        
        switch addr.pointee.sa_family {
        case sa_family_t(AF_INET):
            let addr4 = addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
            var inAddr = addr4.sin_addr
            if inet_ntop(AF_INET, &inAddr, &buffer, socklen_t(INET_ADDRSTRLEN)) != nil {
                return String(cString: buffer)
            }
        case sa_family_t(AF_INET6):
            let addr6 = addr.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) { $0.pointee }
            var inAddr6 = addr6.sin6_addr
            if inet_ntop(AF_INET6, &inAddr6, &buffer, socklen_t(INET6_ADDRSTRLEN)) != nil {
                return String(cString: buffer)
            }
        default:
            break
        }
        
        return nil
    }
    
    private func getAttackVectors(for port: Int, service: String?) -> [AttackVector] {
        var vectors: [AttackVector] = []
        
        switch port {
        case 21: // FTP
            vectors.append(AttackVector(
                name: "FTP Anonymous Login",
                description: "Check for anonymous FTP access",
                severity: .medium,
                requirements: [
                    ToolRequirement(name: "hydra", type: .tool, description: "Password cracking tool"),
                    ToolRequirement(name: "nmap", type: .tool, description: "Network scanning tool")
                ],
                commands: ["hydra -l anonymous -p '' TARGET ftp", "nmap --script ftp-anon TARGET"],
                references: ["https://nmap.org/nsedoc/scripts/ftp-anon.html"]
            ))
            vectors.append(AttackVector(
                name: "FTP Brute Force",
                description: "Brute force FTP credentials",
                severity: .high,
                requirements: [
                    ToolRequirement(name: "hydra", type: .tool, description: "Password cracking tool")
                ],
                commands: ["hydra -L users.txt -P pass.txt TARGET ftp"],
                references: ["https://github.com/vanhauser-thc/thc-hydra"]
            ))
        case 22: // SSH
            vectors.append(AttackVector(
                name: "SSH Brute Force",
                description: "Brute force SSH credentials",
                severity: .high,
                requirements: [
                    ToolRequirement(name: "hydra", type: .tool, description: "Password cracking tool")
                ],
                commands: ["hydra -L users.txt -P pass.txt TARGET ssh"],
                references: ["https://github.com/vanhauser-thc/thc-hydra"]
            ))
            vectors.append(AttackVector(
                name: "SSH Key Authentication Bypass",
                description: "Test for weak SSH key configurations",
                severity: .high,
                requirements: [
                    ToolRequirement(name: "nmap", type: .tool, description: "Network scanning tool")
                ],
                commands: ["nmap --script ssh-auth-methods TARGET"],
                references: ["https://nmap.org/nsedoc/scripts/ssh-auth-methods.html"]
            ))
        case 23: // Telnet
            vectors.append(AttackVector(
                name: "Telnet Brute Force",
                description: "Brute force Telnet credentials",
                severity: .high,
                requirements: [
                    ToolRequirement(name: "hydra", type: .tool, description: "Password cracking tool")
                ],
                commands: ["hydra -L users.txt -P pass.txt TARGET telnet"],
                references: ["https://github.com/vanhauser-thc/thc-hydra"]
            ))
        case 25: // SMTP
            vectors.append(AttackVector(
                name: "SMTP User Enumeration",
                description: "Enumerate valid SMTP users",
                severity: .medium,
                requirements: [
                    ToolRequirement(name: "nmap", type: .tool, description: "Network scanning tool")
                ],
                commands: ["nmap --script smtp-enum-users TARGET"],
                references: ["https://nmap.org/nsedoc/scripts/smtp-enum-users.html"]
            ))
        case 53: // DNS
            vectors.append(AttackVector(
                name: "DNS Zone Transfer",
                description: "Attempt DNS zone transfer",
                severity: .medium,
                requirements: [
                    ToolRequirement(name: "nmap", type: .tool, description: "Network scanning tool")
                ],
                commands: ["nmap --script dns-zone-transfer TARGET"],
                references: ["https://nmap.org/nsedoc/scripts/dns-zone-transfer.html"]
            ))
        case 80, 8080, 8000: // HTTP
            vectors.append(AttackVector(
                name: "Web Directory Enumeration",
                description: "Enumerate web directories and files",
                severity: .medium,
                requirements: [
                    ToolRequirement(name: "dirb", type: .tool, description: "Web directory scanner"),
                    ToolRequirement(name: "gobuster", type: .optional, description: "Directory enumeration tool")
                ],
                commands: ["dirb http://TARGET:PORT/", "gobuster dir -u http://TARGET:PORT/ -w wordlist.txt"],
                references: ["https://tools.kali.org/web-applications/dirb"]
            ))
            vectors.append(AttackVector(
                name: "Web Vulnerability Scan",
                description: "Scan for common web vulnerabilities",
                severity: .high,
                requirements: [
                    ToolRequirement(name: "nikto", type: .tool, description: "Web vulnerability scanner")
                ],
                commands: ["nikto -h TARGET:PORT"],
                references: ["https://tools.kali.org/information-gathering/nikto"]
            ))
            vectors.append(AttackVector(
                name: "SQL Injection Testing",
                description: "Test for SQL injection vulnerabilities",
                severity: .critical,
                requirements: [
                    ToolRequirement(name: "sqlmap", type: .tool, description: "SQL injection tool")
                ],
                commands: ["sqlmap -u http://TARGET:PORT/?id=1 --batch"],
                references: ["https://github.com/sqlmapproject/sqlmap"]
            ))
        case 110: // POP3
            vectors.append(AttackVector(
                name: "POP3 Brute Force",
                description: "Brute force POP3 credentials",
                severity: .medium,
                requirements: [
                    ToolRequirement(name: "hydra", type: .tool, description: "Password cracking tool")
                ],
                commands: ["hydra -L users.txt -P pass.txt TARGET pop3"],
                references: ["https://github.com/vanhauser-thc/thc-hydra"]
            ))
        case 143: // IMAP
            vectors.append(AttackVector(
                name: "IMAP Brute Force",
                description: "Brute force IMAP credentials",
                severity: .medium,
                requirements: [
                    ToolRequirement(name: "hydra", type: .tool, description: "Password cracking tool")
                ],
                commands: ["hydra -L users.txt -P pass.txt TARGET imap"],
                references: ["https://github.com/vanhauser-thc/thc-hydra"]
            ))
        case 443, 8443: // HTTPS
            vectors.append(AttackVector(
                name: "SSL/TLS Security Test",
                description: "Test SSL/TLS configuration",
                severity: .medium,
                requirements: [
                    ToolRequirement(name: "nmap", type: .tool, description: "Network scanning tool"),
                    ToolRequirement(name: "openssl", type: .builtin, description: "SSL toolkit")
                ],
                commands: ["nmap --script ssl-cert,ssl-enum-ciphers TARGET:PORT", "openssl s_client -connect TARGET:PORT"],
                references: ["https://nmap.org/nsedoc/scripts/ssl-cert.html"]
            ))
            vectors.append(AttackVector(
                name: "Web Directory Enumeration (HTTPS)",
                description: "Enumerate HTTPS web directories and files",
                severity: .medium,
                requirements: [
                    ToolRequirement(name: "dirb", type: .tool, description: "Web directory scanner"),
                    ToolRequirement(name: "gobuster", type: .optional, description: "Directory enumeration tool")
                ],
                commands: ["dirb https://TARGET:PORT/", "gobuster dir -u https://TARGET:PORT/ -w wordlist.txt"],
                references: ["https://tools.kali.org/web-applications/dirb"]
            ))
            vectors.append(AttackVector(
                name: "HTTPS Vulnerability Scan",
                description: "Scan for HTTPS vulnerabilities",
                severity: .high,
                requirements: [
                    ToolRequirement(name: "nikto", type: .tool, description: "Web vulnerability scanner")
                ],
                commands: ["nikto -h https://TARGET:PORT"],
                references: ["https://tools.kali.org/information-gathering/nikto"]
            ))
        case 445: // SMB
            vectors.append(AttackVector(
                name: "SMB Enumeration",
                description: "Enumerate SMB shares and users",
                severity: .high,
                requirements: [
                    ToolRequirement(name: "nmap", type: .tool, description: "Network scanning tool")
                ],
                commands: ["nmap --script smb-enum-shares,smb-enum-users TARGET"],
                references: ["https://nmap.org/nsedoc/scripts/smb-enum-shares.html"]
            ))
        case 993: // IMAPS
            vectors.append(AttackVector(
                name: "IMAPS Brute Force",
                description: "Brute force IMAPS credentials",
                severity: .medium,
                requirements: [
                    ToolRequirement(name: "hydra", type: .tool, description: "Password cracking tool")
                ],
                commands: ["hydra -L users.txt -P pass.txt TARGET imaps"],
                references: ["https://github.com/vanhauser-thc/thc-hydra"]
            ))
        case 995: // POP3S
            vectors.append(AttackVector(
                name: "POP3S Brute Force",
                description: "Brute force POP3S credentials",
                severity: .medium,
                requirements: [
                    ToolRequirement(name: "hydra", type: .tool, description: "Password cracking tool")
                ],
                commands: ["hydra -L users.txt -P pass.txt TARGET pop3s"],
                references: ["https://github.com/vanhauser-thc/thc-hydra"]
            ))
        case 1433: // MSSQL
            vectors.append(AttackVector(
                name: "MSSQL Brute Force",
                description: "Brute force Microsoft SQL Server credentials",
                severity: .high,
                requirements: [
                    ToolRequirement(name: "hydra", type: .tool, description: "Password cracking tool"),
                    ToolRequirement(name: "nmap", type: .tool, description: "Network scanning tool")
                ],
                commands: ["hydra -L users.txt -P pass.txt TARGET mssql", "nmap --script ms-sql-brute TARGET"],
                references: ["https://github.com/vanhauser-thc/thc-hydra", "https://nmap.org/nsedoc/scripts/ms-sql-brute.html"]
            ))
            vectors.append(AttackVector(
                name: "MSSQL Information Gathering",
                description: "Gather Microsoft SQL Server information",
                severity: .medium,
                requirements: [
                    ToolRequirement(name: "nmap", type: .tool, description: "Network scanning tool")
                ],
                commands: ["nmap --script ms-sql-info,ms-sql-config TARGET"],
                references: ["https://nmap.org/nsedoc/scripts/ms-sql-info.html"]
            ))
        case 3306: // MySQL
            vectors.append(AttackVector(
                name: "MySQL Brute Force",
                description: "Brute force MySQL credentials",
                severity: .high,
                requirements: [
                    ToolRequirement(name: "hydra", type: .tool, description: "Password cracking tool"),
                    ToolRequirement(name: "nmap", type: .tool, description: "Network scanning tool")
                ],
                commands: ["hydra -L users.txt -P pass.txt TARGET mysql", "nmap --script mysql-brute TARGET"],
                references: ["https://github.com/vanhauser-thc/thc-hydra", "https://nmap.org/nsedoc/scripts/mysql-brute.html"]
            ))
            vectors.append(AttackVector(
                name: "MySQL Information Gathering",
                description: "Gather MySQL server information and enumerate databases",
                severity: .medium,
                requirements: [
                    ToolRequirement(name: "nmap", type: .tool, description: "Network scanning tool")
                ],
                commands: ["nmap --script mysql-info,mysql-enum TARGET"],
                references: ["https://nmap.org/nsedoc/scripts/mysql-info.html"]
            ))
            vectors.append(AttackVector(
                name: "MySQL Empty Password Check",
                description: "Check for MySQL accounts with empty passwords",
                severity: .high,
                requirements: [
                    ToolRequirement(name: "nmap", type: .tool, description: "Network scanning tool")
                ],
                commands: ["nmap --script mysql-empty-password TARGET"],
                references: ["https://nmap.org/nsedoc/scripts/mysql-empty-password.html"]
            ))
        case 3389: // RDP
            vectors.append(AttackVector(
                name: "RDP Brute Force",
                description: "Brute force RDP credentials",
                severity: .high,
                requirements: [
                    ToolRequirement(name: "hydra", type: .tool, description: "Password cracking tool")
                ],
                commands: ["hydra -L users.txt -P pass.txt rdp://TARGET"],
                references: ["https://github.com/vanhauser-thc/thc-hydra"]
            ))
            vectors.append(AttackVector(
                name: "RDP Enumeration",
                description: "Enumerate RDP configuration and certificates",
                severity: .medium,
                requirements: [
                    ToolRequirement(name: "nmap", type: .tool, description: "Network scanning tool")
                ],
                commands: ["nmap --script rdp-enum-encryption,rdp-vuln-ms12-020 TARGET"],
                references: ["https://nmap.org/nsedoc/scripts/rdp-enum-encryption.html"]
            ))
        case 5432: // PostgreSQL
            vectors.append(AttackVector(
                name: "PostgreSQL Brute Force",
                description: "Brute force PostgreSQL credentials",
                severity: .high,
                requirements: [
                    ToolRequirement(name: "hydra", type: .tool, description: "Password cracking tool"),
                    ToolRequirement(name: "nmap", type: .tool, description: "Network scanning tool")
                ],
                commands: ["hydra -L users.txt -P pass.txt postgres://TARGET", "nmap --script pgsql-brute TARGET"],
                references: ["https://github.com/vanhauser-thc/thc-hydra", "https://nmap.org/nsedoc/scripts/pgsql-brute.html"]
            ))
            vectors.append(AttackVector(
                name: "PostgreSQL Information Gathering",
                description: "Gather PostgreSQL server information",
                severity: .medium,
                requirements: [
                    ToolRequirement(name: "nmap", type: .tool, description: "Network scanning tool")
                ],
                commands: ["nmap --script pgsql-databases TARGET"],
                references: ["https://nmap.org/nsedoc/scripts/pgsql-databases.html"]
            ))
        case 6379: // Redis
            vectors.append(AttackVector(
                name: "Redis Information Gathering",
                description: "Gather Redis server information and configuration",
                severity: .medium,
                requirements: [
                    ToolRequirement(name: "nmap", type: .tool, description: "Network scanning tool")
                ],
                commands: ["nmap --script redis-info TARGET"],
                references: ["https://nmap.org/nsedoc/scripts/redis-info.html"]
            ))
            vectors.append(AttackVector(
                name: "Redis Brute Force",
                description: "Brute force Redis authentication",
                severity: .high,
                requirements: [
                    ToolRequirement(name: "hydra", type: .tool, description: "Password cracking tool")
                ],
                commands: ["hydra -P pass.txt redis://TARGET"],
                references: ["https://github.com/vanhauser-thc/thc-hydra"]
            ))
        case 27017: // MongoDB
            vectors.append(AttackVector(
                name: "MongoDB Information Gathering",
                description: "Gather MongoDB server information and databases",
                severity: .medium,
                requirements: [
                    ToolRequirement(name: "nmap", type: .tool, description: "Network scanning tool")
                ],
                commands: ["nmap --script mongodb-info,mongodb-databases TARGET"],
                references: ["https://nmap.org/nsedoc/scripts/mongodb-info.html"]
            ))
            vectors.append(AttackVector(
                name: "MongoDB Brute Force",
                description: "Brute force MongoDB authentication",
                severity: .high,
                requirements: [
                    ToolRequirement(name: "nmap", type: .tool, description: "Network scanning tool")
                ],
                commands: ["nmap --script mongodb-brute TARGET"],
                references: ["https://nmap.org/nsedoc/scripts/mongodb-brute.html"]
            ))
        default:
            // For unknown ports, add a generic port scan vector
            if port > 1024 {
                vectors.append(AttackVector(
                    name: "Service Banner Grabbing",
                    description: "Grab service banner for identification",
                    severity: .info,
                    requirements: [
                        ToolRequirement(name: "nmap", type: .tool, description: "Network scanning tool"),
                        ToolRequirement(name: "netcat", type: .tool, description: "Network utility")
                    ],
                    commands: ["nmap -sV -p \(port) TARGET", "nc TARGET \(port)"],
                    references: ["https://nmap.org/book/man-version-detection.html"]
                ))
            }
        }
        
        return vectors
    }
    
    private func testTCPConnection(host: String, port: Int) async -> Bool {
        return await withCheckedContinuation { continuation in
            let queue = DispatchQueue.global()
            queue.async {
                // Create socket for IPv4
                let sock = socket(AF_INET, SOCK_STREAM, 0)
                guard sock >= 0 else {
                    continuation.resume(returning: false)
                    return
                }
                
                defer { close(sock) }
                
                // Set socket timeout with shorter duration
                var timeout = timeval()
                timeout.tv_sec = 0
                timeout.tv_usec = 200000  // 0.2 seconds = 200000 microseconds (reduced for speed)
                
                setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
                setsockopt(sock, SOL_SOCKET, SO_SNDTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
                
                // Set up socket address structure
                var addr = sockaddr_in()
                addr.sin_family = sa_family_t(AF_INET)
                addr.sin_port = in_port_t(port).bigEndian
                
                // Convert IP address string to binary
                if inet_pton(AF_INET, host, &addr.sin_addr) <= 0 {
                    print("❌ inet_pton failed for host: '\(host)' - not a valid IPv4 address")
                    continuation.resume(returning: false)
                    return
                }
                
                // Connect to the address with timeout
                let connectResult = withUnsafePointer(to: &addr) { addrPtr in
                    addrPtr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockAddrPtr in
                        connect(sock, sockAddrPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
                    }
                }
                
                let connected = connectResult == 0
                print("🔌 TCP connection to \(host):\(port) = \(connected ? "SUCCESS" : "FAILED")")
                continuation.resume(returning: connected)
            }
        }
    }
    
    private func startScan() {
        guard !targetIP.isEmpty else { return }
        
        // Cancel any existing scan first
        currentScanTask?.cancel()
        currentScanTask = nil
        
        // Clear existing results in both local state and AppState
        scanResults = []
        appState.networkScanResults = []
        
        print("🎯 Starting NEW scan for target: '\(targetIP)'")
        
        // Create new scan task
        currentScanTask = Task {
            appState.isNetworkScanning = true
            appState.currentNetworkTarget = targetIP
            appState.networkScanProgress = 0.0
            
            // Clear previous resolved target
            await MainActor.run {
                resolvedTargetIP = ""
            }
            
            // Resolve hostname to IP if needed
            let resolvedTarget: String
            if isValidIPAddress(targetIP) {
                resolvedTarget = targetIP
                print("🎯 Using IP address: \(targetIP)")
            } else {
                print("🌐 Resolving hostname: \(targetIP)")
                if let resolved = await resolveHostname(targetIP) {
                    resolvedTarget = resolved
                    print("🌐 Resolved \(targetIP) → \(resolved)")
                } else {
                    print("❌ Failed to resolve hostname: \(targetIP)")
                    await MainActor.run {
                        appState.isNetworkScanning = false
                        appState.networkScanProgress = 0.0
                    }
                    return
                }
            }
            
            // Update resolved target for attack execution
            await MainActor.run {
                resolvedTargetIP = resolvedTarget
                print("💾 Saved resolved target IP: \(resolvedTargetIP)")
            }
            
            // Parse port range inline
            let ports = parsePortRangeInline(portRange)
            
            // High-performance concurrent TCP scan with larger batches
            var results: [PortScanResult] = []
            let batchSize = 50  // Increased from 10 to 50 for faster scanning
            let _ = 100  // Limit concurrent tasks to prevent overwhelming the system
            
            print("🚀 Starting high-speed scan of \(ports.count) ports in batches of \(batchSize)")
            print("⚡ Optimization: 0.2s timeout, 50 ports per batch, unlimited concurrency per batch")
            
            for (index, batch) in ports.chunked(into: batchSize).enumerated() {
                // Check for cancellation between batches
                if Task.isCancelled {
                    print("🛑 Scan cancelled by user - stopping at batch \(index + 1)")
                    break
                }
                
                let batchStartTime = Date()
                
                await withTaskGroup(of: PortScanResult.self) { group in
                    // Process batch with high concurrency
                    for port in batch {
                        group.addTask {
                            let startTime = Date()
                            let isOpen = await testTCPConnection(host: resolvedTarget, port: port)
                            let scanDuration = Date().timeIntervalSince(startTime)
                            
                            // Log slow scans for debugging
                            if scanDuration > 1.0 {
                                print("⚠️ Slow scan detected: port \(port) took \(String(format: "%.2f", scanDuration))s")
                            }
                            
                            let service = await getServiceNameInline(port: port)
                            let attackVectors = isOpen ? await getAttackVectors(for: port, service: service) : []
                            
                            return PortScanResult(
                                port: port,
                                isOpen: isOpen,
                                service: service,
                                scanTime: Date(),
                                banner: nil,
                                version: nil,
                                attackVectors: attackVectors,
                                riskLevel: isOpen ? .medium : .info
                            )
                        }
                    }
                    
                    var batchResults: [PortScanResult] = []
                    for await result in group {
                        batchResults.append(result)
                    }
                    
                    // Sort batch results and add to main results
                    batchResults.sort { $0.port < $1.port }
                    results.append(contentsOf: batchResults)
                    
                    let batchDuration = Date().timeIntervalSince(batchStartTime)
                    let portsPerSecond = Double(batch.count) / batchDuration
                    print("📊 Batch \(index + 1) completed: \(batch.count) ports in \(String(format: "%.2f", batchDuration))s (\(String(format: "%.1f", portsPerSecond)) ports/sec)")
                    
                    // Update UI with batch results
                    await MainActor.run {
                        scanResults = results.sorted { $0.port < $1.port }
                        appState.networkScanResults = convertToNetworkPortScanResults(scanResults)
                        
                        // Update progress
                        let progress = Double(index + 1) / Double(ports.chunked(into: batchSize).count)
                        appState.networkScanProgress = progress
                        
                        print("🔄 UI updated: \(scanResults.count) total results, \(scanResults.filter { $0.isOpen }.count) open ports")
                    }
                }
            }
            
            // Final update to ensure everything is in sync
            await MainActor.run {
                scanResults = results.sorted { $0.port < $1.port }
                appState.networkScanResults = convertToNetworkPortScanResults(scanResults)
            }
            
            // Final cleanup - check if task was cancelled
            if Task.isCancelled {
                print("🛑 Scan was cancelled - cleaning up")
                await MainActor.run {
                    appState.isNetworkScanning = false
                    appState.networkScanProgress = 0.0
                    currentScanTask = nil
                }
            } else {
                print("✅ Scan completed successfully")
                await MainActor.run {
                    appState.isNetworkScanning = false
                    appState.networkScanProgress = 1.0
                    currentScanTask = nil
                }
            }
        }
    }
    
    private func stopScan() {
        print("🛑 STOP BUTTON PRESSED for target: '\(appState.currentNetworkTarget)'")
        
        // Cancel the current scan task
        currentScanTask?.cancel()
        currentScanTask = nil
        
        // Immediately update UI state
        appState.isNetworkScanning = false
        appState.networkScanProgress = 0.0
        appState.currentNetworkTarget = ""
        
        print("🛑 Scan stopped and task cancelled")
    }
    
    private func addTarget() {
        let target = Target(name: targetIP, ipAddress: targetIP)
        appState.addTarget(target)
        targetIP = ""
    }
    
    private func exportResults(format: ExportFormat) {
        // Implementation for exporting results
    }
    
    private func convertToNetworkPortScanResults(_ results: [PortScanResult]) -> [NetworkPortScanResult] {
        return results.map { result in
            NetworkPortScanResult(
                port: result.port,
                isOpen: result.isOpen,
                service: result.service,
                version: result.version,
                banner: result.banner,
                riskLevel: convertRiskLevel(result.riskLevel),
                attackVectors: convertAttackVectors(result.attackVectors)
            )
        }
    }
    
    private func convertRiskLevel(_ riskLevel: PortScanResult.RiskLevel) -> NetworkPortScanResult.RiskLevel {
        switch riskLevel {
        case .info, .low: return .low
        case .medium: return .medium
        case .high, .critical: return .high
        }
    }
    
    private func convertAttackVectors(_ vectors: [AttackVector]) -> [NetworkAttackVector] {
        return vectors.map { vector in
            NetworkAttackVector(
                name: vector.name,
                description: vector.description,
                severity: convertAttackVectorSeverity(vector.severity),
                tools: vector.requirements.map { $0.name },
                commands: vector.commands
            )
        }
    }
    
    private func convertAttackVectorSeverity(_ severity: Vulnerability.Severity) -> NetworkAttackVector.Severity {
        switch severity {
        case .info, .low: return .low
        case .medium: return .medium
        case .high, .critical: return .high
        }
    }
    
    private func convertFromNetworkPortScanResults(_ networkResults: [NetworkPortScanResult]) -> [PortScanResult] {
        return networkResults.map { result in
            PortScanResult(
                port: result.port,
                isOpen: result.isOpen,
                service: result.service,
                scanTime: result.scanTime,
                banner: result.banner,
                version: result.version,
                attackVectors: convertFromNetworkAttackVectors(result.attackVectors),
                riskLevel: convertFromNetworkRiskLevel(result.riskLevel)
            )
        }
    }
    
    private func convertFromNetworkRiskLevel(_ riskLevel: NetworkPortScanResult.RiskLevel) -> PortScanResult.RiskLevel {
        switch riskLevel {
        case .none: return .info
        case .low: return .low
        case .medium: return .medium
        case .high: return .high
        }
    }
    
    private func convertFromNetworkAttackVectors(_ vectors: [NetworkAttackVector]) -> [AttackVector] {
        return vectors.map { vector in
            AttackVector(
                name: vector.name,
                description: vector.description,
                severity: convertFromNetworkAttackVectorSeverity(vector.severity),
                requirements: vector.tools.map { ToolRequirement(name: $0, type: .tool, description: $0) },
                commands: vector.commands,
                references: [],
                attackType: determineAttackType(for: vector.name),
                difficulty: determineDifficulty(for: vector.name)
            )
        }
    }
    
    private func determineAttackType(for attackName: String) -> AttackVector.AttackType {
        let name = attackName.lowercased()
        
        if name.contains("brute force") || name.contains("password") || name.contains("login") {
            return .bruteForce
        } else if name.contains("directory") || name.contains("enum") || name.contains("dirb") || name.contains("gobuster") {
            return .webDirectoryEnum
        } else if name.contains("sql injection") || name.contains("exploit") || name.contains("vulnerability") {
            return .vulnerabilityExploit
        } else if name.contains("web") && (name.contains("scan") || name.contains("nikto")) {
            return .webVulnScan
        } else {
            return .networkRecon
        }
    }
    
    private func determineDifficulty(for attackName: String) -> AttackVector.AttackDifficulty {
        let name = attackName.lowercased()
        
        if name.contains("sql injection") || name.contains("exploit") {
            return .advanced
        } else if name.contains("brute force") || name.contains("directory") {
            return .intermediate
        } else {
            return .beginner
        }
    }
    
    private func convertFromNetworkAttackVectorSeverity(_ severity: NetworkAttackVector.Severity) -> Vulnerability.Severity {
        switch severity {
        case .low: return .info
        case .medium: return .medium
        case .high: return .high
        }
    }
}

struct CleanScanTypeOption: View {
    let type: ModernNetworkScannerView.ScanType
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .font(.system(size: 16))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(type.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

struct CleanPortResultRow: View {
    let result: PortScanResult
    let targetIP: String
    @State private var isShowingDetail = false
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Status and port
            HStack(spacing: 12) {
                Circle()
                    .fill(result.isOpen ? .green : .red)
                    .frame(width: 10, height: 10)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text("Port \(result.port)")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        if let service = result.service {
                            Text(service.uppercased())
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(3)
                        }
                    }
                    
                    if let version = result.version {
                        Text("Version: \(version)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Risk and status info
            VStack(alignment: .trailing, spacing: 4) {
                if result.isOpen {
                    Text(result.riskLevel.rawValue)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(result.riskLevel.color.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(3)
                    
                    if !result.attackVectors.isEmpty {
                        Text("\(result.attackVectors.count) vectors")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
                
                Text(result.isOpen ? "Open" : "Closed")
                    .font(.caption)
                    .foregroundColor(result.isOpen ? .green : .secondary)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovering ? Color.gray.opacity(0.05) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .onTapGesture {
            if result.isOpen {
                isShowingDetail = true
            }
        }
        .sheet(isPresented: $isShowingDetail) {
            CleanPortDetailView(result: result, targetIP: targetIP)
        }
    }
}

struct CleanPortDetailView: View {
    let result: PortScanResult
    let targetIP: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Port \(result.port)")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(result.riskLevel.rawValue)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(result.riskLevel.color.opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(4)
                                
                                Text(result.isOpen ? "Open" : "Closed")
                                    .font(.caption)
                                    .foregroundColor(result.isOpen ? .green : .red)
                            }
                        }
                        
                        if let service = result.service {
                            Text("Service: \(service)")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Scanned: \(result.scanTime.formatted(date: .abbreviated, time: .standard))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let banner = result.banner {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Service Banner")
                                .font(.headline)
                            
                            Text(banner)
                                .font(.body)
                                .fontDesign(.monospaced)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .textSelection(.enabled)
                        }
                    }
                    
                    if !result.attackVectors.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Attack Vectors (\(result.attackVectors.count))")
                                .font(.headline)
                            
                            ForEach(result.attackVectors) { vector in
                                CleanAttackVectorRow(vector: vector, targetIP: targetIP, port: result.port)
                            }
                        }
                    }
                }
                .padding(24)
            }
            .navigationTitle("Port Details")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

struct CleanAttackVectorRow: View {
    let vector: AttackVector
    let targetIP: String
    let port: Int
    @State private var isExpanded = false
    @State private var showingAttackExecution = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(vector.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(vector.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    if !vector.tools.isEmpty {
                        Text("Tools: \(vector.tools.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ForEach(vector.commands, id: \.self) { command in
                        Text(command)
                            .font(.caption)
                            .fontDesign(.monospaced)
                            .textSelection(.enabled)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    Button(action: { showingAttackExecution = true }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Execute Attack")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
        .sheet(isPresented: $showingAttackExecution) {
            AttackExecutionView(attackVector: vector, target: targetIP, port: port)
        }
    }
}

class BackgroundScanManager: ObservableObject, @unchecked Sendable {
    @Published var appState: AppState?
    private var scanTask: Task<Void, Never>?
    
    // Resolve hostname to IP address
    func resolveHostname(_ hostname: String) async -> String? {
        // If it's already an IP address, return it
        if isValidIPAddress(hostname) {
            return hostname
        }
        
        // Resolve hostname using getaddrinfo
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var hints = addrinfo()
                hints.ai_family = AF_INET  // Prefer IPv4 only
                hints.ai_socktype = SOCK_STREAM
                
                var result: UnsafeMutablePointer<addrinfo>?
                let status = getaddrinfo(hostname, nil, &hints, &result)
                
                defer {
                    if let result = result {
                        freeaddrinfo(result)
                    }
                }
                
                guard status == 0, let addr = result else {
                    continuation.resume(returning: nil)
                    return
                }
                
                // Convert the first address to string
                if let ipString = self.addressToString(addr.pointee.ai_addr, addr.pointee.ai_addrlen) {
                    continuation.resume(returning: ipString)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    private func isValidIPAddress(_ string: String) -> Bool {
        // Check for IPv4 format (preferred)
        let parts = string.components(separatedBy: ".")
        if parts.count == 4 {
            return parts.allSatisfy { part in
                if let num = Int(part), num >= 0 && num <= 255 {
                    return true
                }
                return false
            }
        }
        
        // Check for IPv6 format (fallback)
        if string.contains(":") {
            return string.count > 2 && string.count <= 39 // Basic IPv6 length check
        }
        
        return false
    }
    
    private func addressToString(_ addr: UnsafePointer<sockaddr>, _ addrLen: socklen_t) -> String? {
        var buffer = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
        
        switch addr.pointee.sa_family {
        case sa_family_t(AF_INET):
            let addr4 = addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
            var inAddr = addr4.sin_addr
            if inet_ntop(AF_INET, &inAddr, &buffer, socklen_t(INET_ADDRSTRLEN)) != nil {
                return String(cString: buffer)
            }
        case sa_family_t(AF_INET6):
            let addr6 = addr.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) { $0.pointee }
            var inAddr6 = addr6.sin6_addr
            if inet_ntop(AF_INET6, &inAddr6, &buffer, socklen_t(INET6_ADDRSTRLEN)) != nil {
                return String(cString: buffer)
            }
        default:
            break
        }
        
        return nil
    }
    
    func startNetworkScan(
        target: String,
        portRange: String,
        scanType: ModernNetworkScannerView.ScanType,
        completion: @escaping ([PortScanResult]) -> Void
    ) {
        Task { @MainActor in
            print("🔴 MODERN SCAN STARTING")
            appState?.isNetworkScanning = true
            appState?.currentNetworkTarget = target
            appState?.networkScanProgress = 0.0
            
            scanTask = Task {
                let ports = parsePortRange(portRange)
                print("🎯 Scanning \(ports.count) ports: \(ports.prefix(10))...")
                
                // Resolve hostname to IP address first (only once!)
                let resolvedIP = await Self.resolveHostnameStatic(target)
                guard let resolvedTargetIP = resolvedIP else {
                    print("❌ Failed to resolve hostname: \(target)")
                    await MainActor.run {
                        appState?.isNetworkScanning = false
                        appState?.networkScanProgress = 0.0
                    }
                    return
                }
                
                // Update the current network target to include resolved IP
                await MainActor.run {
                    appState?.currentNetworkTarget = "\(target) → \(resolvedTargetIP)"
                }
                
                print("🌐 Resolved \(target) → \(resolvedTargetIP)")
                print("🔍 Target IP validation: isValidIP = \(Self.isValidIPStatic(resolvedTargetIP))")
                
                // Perform concurrent TCP scans with progress updates
                var allResults: [PortScanResult] = []
                let batchSize = 10  // Smaller batch size for more frequent progress updates and faster timeouts
                let portBatches = ports.chunked(into: batchSize)
                
                for (batchIndex, batch) in portBatches.enumerated() {
                    guard !Task.isCancelled else { 
                        print("🛑 Scan cancelled at batch \(batchIndex)")
                        break 
                    }
                    
                    print("📡 Scanning batch \(batchIndex + 1)/\(portBatches.count) - ports: \(batch.first!)-\(batch.last!) (targetIP: \(resolvedTargetIP))")
                    
                    // Scan this batch concurrently
                    let batchResults = await withTaskGroup(of: PortScanResult.self) { group in
                        var results: [PortScanResult] = []
                        
                        for port in batch {
                            group.addTask {
                                let isOpen = await self.performPortScan(host: resolvedTargetIP, port: port, scanType: scanType)
                                print("✅ Port \(port) scan completed: \(isOpen ? "OPEN" : "CLOSED")")
                                return PortScanResult(
                                    port: port,
                                    isOpen: isOpen,
                                    service: isOpen ? self.getServiceName(for: port) : nil,
                                    scanTime: Date(),
                                    banner: nil,
                                    version: nil,
                                    attackVectors: isOpen ? self.getAttackVectors(for: port, service: self.getServiceName(for: port)) : [],
                                    riskLevel: self.calculateRiskLevel(port: port, service: self.getServiceName(for: port), isOpen: isOpen)
                                )
                            }
                        }
                        
                        for await result in group {
                            results.append(result)
                        }
                        
                        return results.sorted { $0.port < $1.port }
                    }
                    
                    allResults.append(contentsOf: batchResults)
                    print("🔄 Batch \(batchIndex + 1) completed with \(batchResults.count) results. Total results: \(allResults.count)")
                    
                    // Update progress on main thread
                    await MainActor.run {
                        let scannedPorts = (batchIndex + 1) * batchSize
                        let progress = Double(min(scannedPorts, ports.count)) / Double(ports.count)
                        appState?.networkScanProgress = progress
                        appState?.currentNetworkTarget = "\(target) → \(resolvedTargetIP)"
                        print("📊 Progress: \(Int(progress * 100))% - Scanned \(allResults.count) ports")
                        
                        // Update results in real-time - store in both AppState and call completion
                        let networkResults = allResults.map { result in
                            NetworkPortScanResult(
                                port: result.port,
                                isOpen: result.isOpen,
                                service: result.service,
                                version: result.version,
                                banner: result.banner,
                                riskLevel: self.convertRiskLevelToNetwork(result.riskLevel),
                                attackVectors: self.convertAttackVectorsToNetwork(result.attackVectors)
                            )
                        }
                        appState?.networkScanResults = networkResults
                        
                        // Also call completion for immediate UI update
                        completion(allResults)
                    }
                }
                
                // Final state update
                await MainActor.run {
                    appState?.isNetworkScanning = false
                    appState?.networkScanProgress = 1.0
                    print("🏁 Modern scan complete")
                }
            }
        }
    }
    
    func stopNetworkScan() {
        print("🛑 BACKGROUND SCAN MANAGER STOPPING")
        scanTask?.cancel()
        scanTask = nil
        
        Task { @MainActor in
            appState?.isNetworkScanning = false
            appState?.networkScanProgress = 0.0
            appState?.currentNetworkTarget = ""
            print("🛑 Background scan state cleared")
        }
    }
    
    private func executeNmapPortScan(target: String, ports: [Int], scanType: ModernNetworkScannerView.ScanType) async -> [PortScanResult] {
        var results: [PortScanResult] = []
        
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        
        // Set Nmap path
        if FileManager.default.fileExists(atPath: "/usr/local/bin/nmap") {
            process.launchPath = "/usr/local/bin/nmap"
        } else if FileManager.default.fileExists(atPath: "/opt/homebrew/bin/nmap") {
            process.launchPath = "/opt/homebrew/bin/nmap"
        } else {
            // Fallback to system path
            process.launchPath = "/usr/bin/nmap"
        }
        
        // Build Nmap arguments based on scan type
        var arguments = [String]()
        
        switch scanType {
        case .tcpConnect:
            arguments.append("-sT")  // TCP Connect scan
        case .syn:
            arguments.append("-sS")  // SYN scan (requires root)
        case .udp:
            arguments.append("-sU")  // UDP scan
        case .comprehensive:
            arguments.append("-sS")  // SYN scan
            arguments.append("-sV")  // Service version detection
            arguments.append("-A")   // Aggressive scan
        }
        
        // Add port range
        let portRangeString = ports.map(String.init).joined(separator: ",")
        arguments.append("-p")
        arguments.append(portRangeString)
        
        // Add target
        arguments.append(target)
        
        // Add output format
        arguments.append("-oX")  // XML output
        arguments.append("-")    // Output to stdout
        
        process.arguments = arguments
        
        do {
            try process.run()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let xmlString = String(data: data, encoding: .utf8) ?? ""
            
            process.waitUntilExit()
            
            // Parse Nmap XML output
            results = parseNmapXMLOutput(xmlString, target: target)
            
        } catch {
            print("Error executing Nmap: \(error)")
            // Fallback to basic TCP connection test
            results = await performBasicPortScan(target: target, ports: ports)
        }
        
        return results
    }
    
    private func parseNmapXMLOutput(_ xmlString: String, target: String) -> [PortScanResult] {
        var results: [PortScanResult] = []
        
        // Simple XML parsing for Nmap output
        let lines = xmlString.components(separatedBy: .newlines)
        
        for line in lines {
            if line.contains("<port ") && line.contains("portid=") {
                if let portMatch = extractPortNumber(from: line),
                   let stateMatch = extractPortState(from: line) {
                    
                    let isOpen = stateMatch == "open"
                    let service = extractServiceName(from: line)
                    let version = extractServiceVersion(from: line)
                    let attackVectors = getAttackVectors(for: portMatch, service: service)
                    let riskLevel = calculateRiskLevel(port: portMatch, service: service, isOpen: isOpen)
                    
                    let result = PortScanResult(
                        port: portMatch,
                        isOpen: isOpen,
                        service: service,
                        scanTime: Date(),
                        banner: nil,
                        version: version,
                        attackVectors: attackVectors,
                        riskLevel: riskLevel
                    )
                    
                    results.append(result)
                }
            }
        }
        
        return results
    }
    
    private func performBasicPortScan(target: String, ports: [Int]) async -> [PortScanResult] {
        // Resolve hostname to IP first (only once!)
        let resolvedIP = await resolveHostnameHelper(target)
        let targetIP = resolvedIP ?? target
        
        if resolvedIP != nil && resolvedIP != target {
            print("🌐 Resolved \(target) → \(targetIP)")
        }
        
        // Use concurrent scanning with TaskGroup for much faster performance
        return await withTaskGroup(of: PortScanResult.self) { group in
            var results: [PortScanResult] = []
            
            // Create concurrent tasks for each port (limit to 50 concurrent tasks to avoid overwhelming the system)
            let batchSize = 50
            let portBatches = ports.chunked(into: batchSize)
            
            for batch in portBatches {
                await withTaskGroup(of: PortScanResult.self) { batchGroup in
                    for port in batch {
                        batchGroup.addTask {
                            let isOpen = await self.testTCPConnection(host: targetIP, port: port)
                            let service = self.getServiceName(for: port)
                            let attackVectors = self.getAttackVectors(for: port, service: service)
                            let riskLevel = self.calculateRiskLevel(port: port, service: service, isOpen: isOpen)
                            
                            return PortScanResult(
                                port: port,
                                isOpen: isOpen,
                                service: service,
                                scanTime: Date(),
                                banner: nil,
                                version: nil,
                                attackVectors: attackVectors,
                                riskLevel: riskLevel
                            )
                        }
                    }
                    
                    for await result in batchGroup {
                        results.append(result)
                    }
                }
            }
            
            // Sort results by port number
            return results.sorted { $0.port < $1.port }
        }
    }
    
    private func performPortScan(host: String, port: Int, scanType: ModernNetworkScannerView.ScanType) async -> Bool {
        print("🔍 Performing \(scanType.rawValue) scan on \(host):\(port)")
        
        switch scanType {
        case .tcpConnect:
            return await testTCPConnection(host: host, port: port)
        case .syn:
            return await performSYNScan(host: host, port: port)
        case .udp:
            return await performUDPScan(host: host, port: port)
        case .comprehensive:
            return await performComprehensiveScan(host: host, port: port)
        }
    }
    
    private func testTCPConnection(host: String, port: Int) async -> Bool {
        return await withCheckedContinuation { continuation in
            let queue = DispatchQueue.global()
            queue.async {
                // Create socket for IPv4
                let sock = socket(AF_INET, SOCK_STREAM, 0)
                guard sock >= 0 else {
                    continuation.resume(returning: false)
                    return
                }
                
                defer { close(sock) }
                
                // Set socket timeout with shorter duration
                var timeout = timeval()
                timeout.tv_sec = 0
                timeout.tv_usec = 200000  // 0.2 seconds = 200000 microseconds (reduced for speed)
                
                setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
                setsockopt(sock, SOL_SOCKET, SO_SNDTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
                
                // Set up socket address structure
                var addr = sockaddr_in()
                addr.sin_family = sa_family_t(AF_INET)
                addr.sin_port = in_port_t(port).bigEndian
                
                // Convert IP address string to binary
                if inet_pton(AF_INET, host, &addr.sin_addr) <= 0 {
                    print("❌ inet_pton failed for host: '\(host)' - not a valid IPv4 address")
                    continuation.resume(returning: false)
                    return
                }
                
                // Connect to the address with timeout
                let connectResult = withUnsafePointer(to: &addr) { addrPtr in
                    addrPtr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockAddrPtr in
                        connect(sock, sockAddrPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
                    }
                }
                
                let connected = connectResult == 0
                print("🔌 TCP connection to \(host):\(port) = \(connected ? "SUCCESS" : "FAILED")")
                continuation.resume(returning: connected)
            }
        }
    }
    
    private func performSYNScan(host: String, port: Int) async -> Bool {
        print("🔥 SYN Scan on \(host):\(port)")
        
        // Try to use nmap for SYN scan
        if let nmapPath = ToolDetection.shared.getToolPath("nmap") {
            return await withCheckedContinuation { continuation in
                DispatchQueue.global().async {
                    let process = Process()
                    let pipe = Pipe()
                    
                    process.standardOutput = pipe
                    process.standardError = pipe
                    process.executableURL = URL(fileURLWithPath: nmapPath)
                    
                    // Use TCP connect scan instead of SYN if not root
                    process.arguments = ["-sT", "-p", String(port), host, "--max-retries=1", "-T4", "-n"]
                    
                    do {
                        try process.run()
                        process.waitUntilExit()
                        
                        let data = pipe.fileHandleForReading.readDataToEndOfFile()
                        let output = String(data: data, encoding: .utf8) ?? ""
                        
                        let isOpen = output.contains("open") && !output.contains("closed") && !output.contains("filtered")
                        print("🔥 SYN Scan result: \(isOpen ? "OPEN" : "CLOSED")")
                        continuation.resume(returning: isOpen)
                    } catch {
                        print("❌ SYN Scan failed, falling back to TCP")
                        Task {
                            let result = await self.testTCPConnection(host: host, port: port)
                            continuation.resume(returning: result)
                        }
                    }
                }
            }
        } else {
            print("⚠️ nmap not found, falling back to TCP scan")
            return await testTCPConnection(host: host, port: port)
        }
    }
    
    private func performUDPScan(host: String, port: Int) async -> Bool {
        print("📡 UDP Scan on \(host):\(port)")
        
        // Try to use nmap for UDP scan
        if let nmapPath = ToolDetection.shared.getToolPath("nmap") {
            return await withCheckedContinuation { continuation in
                DispatchQueue.global().async {
                    let process = Process()
                    let pipe = Pipe()
                    
                    process.standardOutput = pipe
                    process.standardError = pipe
                    process.executableURL = URL(fileURLWithPath: nmapPath)
                    
                    // UDP scan with faster timing
                    process.arguments = ["-sU", "-p", String(port), host, "--max-retries=1", "-T4", "-n"]
                    
                    do {
                        try process.run()
                        process.waitUntilExit()
                        
                        let data = pipe.fileHandleForReading.readDataToEndOfFile()
                        let output = String(data: data, encoding: .utf8) ?? ""
                        
                        let isOpen = output.contains("open") && !output.contains("closed")
                        print("📡 UDP Scan result: \(isOpen ? "OPEN" : "CLOSED")")
                        continuation.resume(returning: isOpen)
                    } catch {
                        print("❌ UDP Scan failed, falling back to basic UDP test")
                        Task {
                            let result = await self.performBasicUDPScan(host: host, port: port)
                            continuation.resume(returning: result)
                        }
                    }
                }
            }
        } else {
            print("⚠️ nmap not found, using basic UDP scan")
            return await performBasicUDPScan(host: host, port: port)
        }
    }
    
    private func performBasicUDPScan(host: String, port: Int) async -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                let sock = socket(AF_INET, SOCK_DGRAM, 0)
                defer { close(sock) }
                
                var timeout = timeval(tv_sec: 1, tv_usec: 0)
                setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
                
                var addr = sockaddr_in()
                addr.sin_family = sa_family_t(AF_INET)
                addr.sin_port = in_port_t(port).bigEndian
                
                if inet_pton(AF_INET, host, &addr.sin_addr) == 1 {
                    let testData = "test".data(using: .utf8)!
                    let sendResult = testData.withUnsafeBytes { bytes in
                        withUnsafePointer(to: &addr) { addrPtr in
                            addrPtr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockAddrPtr in
                                sendto(sock, bytes.bindMemory(to: UInt8.self).baseAddress, bytes.count, 0, sockAddrPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
                            }
                        }
                    }
                    
                    if sendResult >= 0 {
                        var buffer = [UInt8](repeating: 0, count: 1024)
                        let recvResult = recv(sock, &buffer, buffer.count, 0)
                        continuation.resume(returning: recvResult >= 0)
                    } else {
                        continuation.resume(returning: false)
                    }
                } else {
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    private func performComprehensiveScan(host: String, port: Int) async -> Bool {
        print("🌟 Comprehensive Scan on \(host):\(port)")
        
        // Try TCP first
        let tcpResult = await testTCPConnection(host: host, port: port)
        if tcpResult {
            print("🌟 Comprehensive: TCP OPEN")
            return true
        }
        
        // If TCP fails, try SYN scan
        let synResult = await performSYNScan(host: host, port: port)
        if synResult {
            print("🌟 Comprehensive: SYN OPEN")
            return true
        }
        
        // For certain ports, also try UDP
        let udpPorts = [53, 161, 162, 123, 69, 514]
        if udpPorts.contains(port) {
            let udpResult = await performUDPScan(host: host, port: port)
            if udpResult {
                print("🌟 Comprehensive: UDP OPEN")
                return true
            }
        }
        
        print("🌟 Comprehensive: All scans CLOSED")
        return false
    }
    
    // XML parsing helper methods
    private func extractPortNumber(from line: String) -> Int? {
        if let range = line.range(of: "portid=\"") {
            let start = range.upperBound
            if let endRange = line[start...].range(of: "\"") {
                let portString = String(line[start..<endRange.lowerBound])
                return Int(portString)
            }
        }
        return nil
    }
    
    private func extractPortState(from line: String) -> String? {
        if let range = line.range(of: "state=\"") {
            let start = range.upperBound
            if let endRange = line[start...].range(of: "\"") {
                return String(line[start..<endRange.lowerBound])
            }
        }
        return nil
    }
    
    private func extractServiceName(from line: String) -> String? {
        if let range = line.range(of: "name=\"") {
            let start = range.upperBound
            if let endRange = line[start...].range(of: "\"") {
                return String(line[start..<endRange.lowerBound])
            }
        }
        return nil
    }
    
    private func extractServiceVersion(from line: String) -> String? {
        if let range = line.range(of: "version=\"") {
            let start = range.upperBound
            if let endRange = line[start...].range(of: "\"") {
                return String(line[start..<endRange.lowerBound])
            }
        }
        return nil
    }
    
    private func parsePortRange(_ range: String) -> [Int] {
        if range.contains(",") {
            return range.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        }
        
        let components = range.split(separator: "-")
        guard components.count == 2,
              let start = Int(components[0]),
              let end = Int(components[1]),
              start <= end else {
            return Array(1...1000)
        }
        return Array(start...end)
    }
    
    static func resolveHostnameStatic(_ hostname: String) async -> String? {
        // Check if it's already an IP address
        if Self.isValidIPStatic(hostname) {
            return hostname
        }
        
        // Resolve hostname using getaddrinfo
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var hints = addrinfo()
                hints.ai_family = AF_INET  // Prefer IPv4 only
                hints.ai_socktype = SOCK_STREAM
                
                var result: UnsafeMutablePointer<addrinfo>?
                let status = getaddrinfo(hostname, nil, &hints, &result)
                
                defer {
                    if let result = result {
                        freeaddrinfo(result)
                    }
                }
                
                guard status == 0, let addr = result else {
                    continuation.resume(returning: hostname)
                    return
                }
                
                // Convert the first address to string
                if let ipString = Self.addressToStringHelper(addr.pointee.ai_addr, addr.pointee.ai_addrlen) {
                    continuation.resume(returning: ipString)
                } else {
                    continuation.resume(returning: hostname)
                }
            }
        }
    }
    
    private func isValidIPAddressHelper(_ string: String) -> Bool {
        // Simple check for IPv4 format
        let parts = string.components(separatedBy: ".")
        if parts.count == 4 {
            return parts.allSatisfy { part in
                if let num = Int(part), num >= 0 && num <= 255 {
                    return true
                }
                return false
            }
        }
        return false
    }
    
    // MARK: - Helper Functions
    
    static func isValidIPStatic(_ string: String) -> Bool {
        // Simple check for IPv4 format
        let parts = string.components(separatedBy: ".")
        if parts.count == 4 {
            return parts.allSatisfy { part in
                if let num = Int(part), num >= 0 && num <= 255 {
                    return true
                }
                return false
            }
        }
        return false
    }
    
    private func resolveHostnameHelper(_ hostname: String) async -> String? {
        // Check if it's already an IP address
        if Self.isValidIPStatic(hostname) {
            return hostname
        }
        
        // Resolve hostname using getaddrinfo
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var hints = addrinfo()
                hints.ai_family = AF_INET  // Prefer IPv4 only
                hints.ai_socktype = SOCK_STREAM
                
                var result: UnsafeMutablePointer<addrinfo>?
                let status = getaddrinfo(hostname, nil, &hints, &result)
                
                defer {
                    if let result = result {
                        freeaddrinfo(result)
                    }
                }
                
                guard status == 0, let addr = result else {
                    continuation.resume(returning: hostname) // Return original hostname if resolution fails
                    return
                }
                
                // Convert the first address to string
                if let ipString = Self.addressToStringHelper(addr.pointee.ai_addr, addr.pointee.ai_addrlen) {
                    continuation.resume(returning: ipString)
                } else {
                    continuation.resume(returning: hostname) // Return original hostname if conversion fails
                }
            }
        }
    }
    
    static private func addressToStringHelper(_ addr: UnsafePointer<sockaddr>, _ addrLen: socklen_t) -> String? {
        var buffer = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
        
        switch addr.pointee.sa_family {
        case sa_family_t(AF_INET):
            let addr4 = addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
            var inAddr = addr4.sin_addr
            if inet_ntop(AF_INET, &inAddr, &buffer, socklen_t(INET_ADDRSTRLEN)) != nil {
                return String(cString: buffer)
            }
        case sa_family_t(AF_INET6):
            let addr6 = addr.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) { $0.pointee }
            var inAddr6 = addr6.sin6_addr
            if inet_ntop(AF_INET6, &inAddr6, &buffer, socklen_t(INET6_ADDRSTRLEN)) != nil {
                return String(cString: buffer)
            }
        default:
            break
        }
        
        return nil
    }
    
    private func convertRiskLevelToNetwork(_ riskLevel: PortScanResult.RiskLevel) -> NetworkPortScanResult.RiskLevel {
        switch riskLevel {
        case .info: return .none
        case .low: return .low
        case .medium: return .medium
        case .high: return .high
        case .critical: return .high
        }
    }
    
    private func convertAttackVectorsToNetwork(_ vectors: [AttackVector]) -> [NetworkAttackVector] {
        return vectors.map { vector in
            NetworkAttackVector(
                name: vector.name,
                description: vector.description,
                severity: NetworkAttackVector.Severity(rawValue: vector.severity.rawValue) ?? .medium,
                tools: vector.tools,
                commands: vector.commands
            )
        }
    }
    
    // MARK: - Attack Vector Generation
    
    private func getAttackVectors(for port: Int, service: String?) -> [AttackVector] {
        var vectors: [AttackVector] = []
        
        // Add service-specific attack vectors
        switch port {
        case 21: // FTP
            vectors.append(AttackVector(
                name: "FTP Brute Force",
                description: "Attempt to brute force FTP credentials",
                severity: .high,
                requirements: [ToolRequirement(name: "hydra", type: .tool, description: "Network login cracker")],
                commands: ["hydra -L USER_LIST -P PASS_LIST ftp://TARGET"],
                references: ["https://tools.kali.org/password-attacks/hydra"]
            ))
            
            vectors.append(AttackVector(
                name: "FTP Anonymous Login",
                description: "Test for anonymous FTP access",
                severity: .medium,
                requirements: [ToolRequirement(name: "nmap", type: .tool, description: "Network discovery and security auditing")],
                commands: ["nmap -p 21 --script ftp-anon TARGET"],
                references: ["https://nmap.org/nsedoc/scripts/ftp-anon.html"]
            ))
            
        case 22: // SSH
            vectors.append(AttackVector(
                name: "SSH Brute Force",
                description: "Attempt to brute force SSH credentials using common usernames and passwords",
                severity: .high,
                requirements: [ToolRequirement(name: "hydra", type: .tool, description: "Network login cracker")],
                commands: ["hydra -L USER_LIST -P PASS_LIST ssh://TARGET:PORT"],
                references: ["https://tools.kali.org/password-attacks/hydra"]
            ))
            
            vectors.append(AttackVector(
                name: "SSH Enumeration",
                description: "Enumerate SSH version and supported algorithms",
                severity: .low,
                requirements: [ToolRequirement(name: "nmap", type: .tool, description: "Network discovery and security auditing")],
                commands: ["nmap -p 22 --script ssh2-enum-algos,ssh-hostkey TARGET"],
                references: ["https://nmap.org/nsedoc/scripts/ssh2-enum-algos.html"]
            ))
            
        case 23: // Telnet
            vectors.append(AttackVector(
                name: "Telnet Brute Force",
                description: "Attempt to brute force Telnet credentials",
                severity: .high,
                requirements: [ToolRequirement(name: "hydra", type: .tool, description: "Network login cracker")],
                commands: ["hydra -L USER_LIST -P PASS_LIST telnet://TARGET"],
                references: ["https://tools.kali.org/password-attacks/hydra"]
            ))
            
        case 25, 465, 587: // SMTP
            vectors.append(AttackVector(
                name: "SMTP User Enumeration",
                description: "Enumerate valid users via SMTP VRFY/EXPN",
                severity: .medium,
                requirements: [ToolRequirement(name: "nmap", type: .tool, description: "Network discovery and security auditing")],
                commands: ["nmap -p PORT --script smtp-enum-users TARGET"],
                references: ["https://nmap.org/nsedoc/scripts/smtp-enum-users.html"]
            ))
            
        case 53: // DNS
            vectors.append(AttackVector(
                name: "DNS Zone Transfer",
                description: "Attempt DNS zone transfer (AXFR)",
                severity: .high,
                requirements: [ToolRequirement(name: "nmap", type: .tool, description: "Network discovery and security auditing")],
                commands: ["nmap -p 53 --script dns-zone-transfer TARGET"],
                references: ["https://nmap.org/nsedoc/scripts/dns-zone-transfer.html"]
            ))
            
            vectors.append(AttackVector(
                name: "DNS Enumeration",
                description: "Enumerate DNS information and subdomains",
                severity: .medium,
                requirements: [ToolRequirement(name: "dig", type: .tool, description: "DNS lookup utility")],
                commands: ["dig @TARGET any", "dig @TARGET axfr"],
                references: ["https://linux.die.net/man/1/dig"]
            ))
            
        case 80, 8080, 8000, 8888: // HTTP
            vectors.append(AttackVector(
                name: "Web Directory Enumeration",
                description: "Discover hidden directories and files",
                severity: .medium,
                requirements: [ToolRequirement(name: "dirb", type: .tool, description: "Web content scanner")],
                commands: ["dirb http://TARGET:PORT/"],
                references: ["https://tools.kali.org/web-applications/dirb"]
            ))
            
            vectors.append(AttackVector(
                name: "Web Vulnerability Scan",
                description: "Scan for common web vulnerabilities",
                severity: .high,
                requirements: [ToolRequirement(name: "nikto", type: .tool, description: "Web server scanner")],
                commands: ["nikto -h TARGET -p PORT"],
                references: ["https://tools.kali.org/information-gathering/nikto"]
            ))
            
            vectors.append(AttackVector(
                name: "SQL Injection Testing",
                description: "Test for SQL injection vulnerabilities",
                severity: .critical,
                requirements: [ToolRequirement(name: "sqlmap", type: .tool, description: "Automatic SQL injection tool")],
                commands: ["sqlmap -u \"http://TARGET:PORT/?id=1\" --batch --level=1 --risk=1"],
                references: ["https://sqlmap.org/"]
            ))
            
        case 443, 8443: // HTTPS
            vectors.append(AttackVector(
                name: "SSL/TLS Security Scan",
                description: "Analyze SSL/TLS configuration for vulnerabilities",
                severity: .medium,
                requirements: [ToolRequirement(name: "nmap", type: .tool, description: "Network discovery and security auditing")],
                commands: ["nmap -p PORT --script ssl-cert,ssl-enum-ciphers TARGET"],
                references: ["https://nmap.org/nsedoc/scripts/ssl-cert.html"]
            ))
            
            vectors.append(AttackVector(
                name: "HTTPS Directory Enumeration",
                description: "Discover hidden directories and files over HTTPS",
                severity: .medium,
                requirements: [ToolRequirement(name: "dirb", type: .tool, description: "Web content scanner")],
                commands: ["dirb https://TARGET:PORT/"],
                references: ["https://tools.kali.org/web-applications/dirb"]
            ))
            
            vectors.append(AttackVector(
                name: "HTTPS Vulnerability Scan",
                description: "Scan for web vulnerabilities over HTTPS",
                severity: .high,
                requirements: [ToolRequirement(name: "nikto", type: .tool, description: "Web server scanner")],
                commands: ["nikto -h https://TARGET -p PORT -ssl"],
                references: ["https://tools.kali.org/information-gathering/nikto"]
            ))
            
        case 110, 995: // POP3
            vectors.append(AttackVector(
                name: "POP3 Brute Force",
                description: "Attempt to brute force POP3 credentials",
                severity: .high,
                requirements: [ToolRequirement(name: "hydra", type: .tool, description: "Network login cracker")],
                commands: ["hydra -L USER_LIST -P PASS_LIST pop3://TARGET"],
                references: ["https://tools.kali.org/password-attacks/hydra"]
            ))
            
        case 135, 139, 445: // SMB/NetBIOS
            vectors.append(AttackVector(
                name: "SMB Enumeration",
                description: "Enumerate SMB shares and information",
                severity: .medium,
                requirements: [ToolRequirement(name: "nmap", type: .tool, description: "Network discovery and security auditing")],
                commands: ["nmap -p PORT --script smb-enum-shares,smb-enum-users TARGET"],
                references: ["https://nmap.org/nsedoc/scripts/smb-enum-shares.html"]
            ))
            
            vectors.append(AttackVector(
                name: "SMB Vulnerability Scan",
                description: "Scan for known SMB vulnerabilities",
                severity: .high,
                requirements: [ToolRequirement(name: "nmap", type: .tool, description: "Network discovery and security auditing")],
                commands: ["nmap -p PORT --script smb-vuln-* TARGET"],
                references: ["https://nmap.org/nsedoc/scripts/smb-vuln-ms17-010.html"]
            ))
            
        case 143, 993: // IMAP
            vectors.append(AttackVector(
                name: "IMAP Brute Force",
                description: "Attempt to brute force IMAP credentials",
                severity: .high,
                requirements: [ToolRequirement(name: "hydra", type: .tool, description: "Network login cracker")],
                commands: ["hydra -L USER_LIST -P PASS_LIST imap://TARGET"],
                references: ["https://tools.kali.org/password-attacks/hydra"]
            ))
            
        case 389, 636: // LDAP
            vectors.append(AttackVector(
                name: "LDAP Enumeration",
                description: "Enumerate LDAP directory information",
                severity: .medium,
                requirements: [ToolRequirement(name: "nmap", type: .tool, description: "Network discovery and security auditing")],
                commands: ["nmap -p PORT --script ldap-search TARGET"],
                references: ["https://nmap.org/nsedoc/scripts/ldap-search.html"]
            ))
            
        case 1433: // MSSQL
            vectors.append(AttackVector(
                name: "MSSQL Brute Force",
                description: "Attempt to brute force MSSQL credentials",
                severity: .high,
                requirements: [ToolRequirement(name: "hydra", type: .tool, description: "Network login cracker")],
                commands: ["hydra -L USER_LIST -P PASS_LIST mssql://TARGET"],
                references: ["https://tools.kali.org/password-attacks/hydra"]
            ))
            
        case 3306: // MySQL
            vectors.append(AttackVector(
                name: "MySQL Brute Force",
                description: "Attempt to brute force MySQL credentials",
                severity: .high,
                requirements: [ToolRequirement(name: "hydra", type: .tool, description: "Network login cracker")],
                commands: ["hydra -L USER_LIST -P PASS_LIST mysql://TARGET"],
                references: ["https://tools.kali.org/password-attacks/hydra"]
            ))
            
        case 3389: // RDP
            vectors.append(AttackVector(
                name: "RDP Brute Force",
                description: "Attempt to brute force RDP credentials",
                severity: .high,
                requirements: [ToolRequirement(name: "hydra", type: .tool, description: "Network login cracker")],
                commands: ["hydra -L USER_LIST -P PASS_LIST rdp://TARGET"],
                references: ["https://tools.kali.org/password-attacks/hydra"]
            ))
            
        case 5432: // PostgreSQL
            vectors.append(AttackVector(
                name: "PostgreSQL Brute Force",
                description: "Attempt to brute force PostgreSQL credentials",
                severity: .high,
                requirements: [ToolRequirement(name: "hydra", type: .tool, description: "Network login cracker")],
                commands: ["hydra -L USER_LIST -P PASS_LIST postgres://TARGET"],
                references: ["https://tools.kali.org/password-attacks/hydra"]
            ))
            
        case 5900, 5901: // VNC
            vectors.append(AttackVector(
                name: "VNC Brute Force",
                description: "Attempt to brute force VNC passwords",
                severity: .high,
                requirements: [ToolRequirement(name: "hydra", type: .tool, description: "Network login cracker")],
                commands: ["hydra -P PASS_LIST vnc://TARGET"],
                references: ["https://tools.kali.org/password-attacks/hydra"]
            ))
            
        default:
            break
        }
        
        // Add generic network reconnaissance for all open ports
        vectors.append(AttackVector(
            name: "Service Enumeration",
            description: "Detailed service version detection and OS fingerprinting",
            severity: .low,
            requirements: [ToolRequirement(name: "nmap", type: .tool, description: "Network discovery and security auditing")],
            commands: ["nmap -sV -O -p PORT TARGET"],
            references: ["https://nmap.org/book/man-version-detection.html"]
        ))
        
        return vectors
    }
    
    private func getServiceName(for port: Int) -> String? {
        let commonServices: [Int: String] = [
            21: "FTP",
            22: "SSH",
            23: "Telnet",
            25: "SMTP",
            53: "DNS",
            80: "HTTP",
            110: "POP3",
            135: "RPC",
            139: "NetBIOS",
            143: "IMAP",
            389: "LDAP",
            443: "HTTPS",
            445: "SMB",
            465: "SMTPS",
            587: "SMTP",
            636: "LDAPS",
            993: "IMAPS",
            995: "POP3S",
            1433: "MSSQL",
            3306: "MySQL",
            3389: "RDP",
            5432: "PostgreSQL",
            5900: "VNC",
            5901: "VNC",
            8000: "HTTP-Alt",
            8080: "HTTP-Proxy",
            8443: "HTTPS-Alt",
            8888: "HTTP-Alt"
        ]
        
        return commonServices[port]
    }
    
    private func calculateRiskLevel(port: Int, service: String?, isOpen: Bool) -> PortScanResult.RiskLevel {
        guard isOpen else { return .info }
        
        // High-risk services
        let highRiskPorts: Set<Int> = [21, 23, 135, 139, 445, 1433, 3306, 3389, 5432, 5900, 5901]
        if highRiskPorts.contains(port) {
            return .high
        }
        
        // Critical services (if misconfigured)
        let criticalPorts: Set<Int> = [22, 80, 443, 8080, 8443]
        if criticalPorts.contains(port) {
            return .medium
        }
        
        // Medium risk for other services
        return .low
    }
    
}

enum ExportFormat {
    case csv, json, xml
}

#Preview {
    ModernNetworkScannerView()
        .environment(AppState())
        .frame(width: 1200, height: 800)
}