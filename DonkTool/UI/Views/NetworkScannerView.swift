//
//  NetworkScannerView.swift
//  DonkTool
//
//  Network scanning interface
//

import SwiftUI

struct NetworkScannerView: View {
    @EnvironmentObject var appState: AppState
    @State private var targetIP = ""
    @State private var portRange = "1-1000"
    @State private var isScanning = false
    @State private var scanResults: [PortScanResult] = []
    @State private var selectedScanType: ScanType = .tcpConnect
    
    enum ScanType: String, CaseIterable {
        case tcpConnect = "TCP Connect"
        case syn = "SYN Scan"
        case udp = "UDP Scan"
        case comprehensive = "Comprehensive"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Scan Configuration Panel
            VStack(spacing: 16) {
                HStack {
                    Text("Network Scanner")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                }
                
                // Target input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target")
                        .font(.headline)
                    
                    HStack {
                        TextField("IP Address or Domain", text: $targetIP)
                            .textFieldStyle(.roundedBorder)
                        
                        Button("Add to Targets") {
                            addTarget()
                        }
                        .disabled(targetIP.isEmpty)
                    }
                }
                
                // Scan options
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Scan Type")
                            .font(.headline)
                        
                        Picker("Scan Type", selection: $selectedScanType) {
                            ForEach(ScanType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Port Range")
                            .font(.headline)
                        
                        TextField("1-1000", text: $portRange)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 120)
                    }
                    
                    Spacer()
                    
                    // Scan button
                    Button(action: startScan) {
                        HStack {
                            if isScanning {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Scanning...")
                            } else {
                                Image(systemName: "play.fill")
                                Text("Start Scan")
                            }
                        }
                        .frame(minWidth: 120)
                    }
                    .disabled(targetIP.isEmpty || isScanning)
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Results section
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Scan Results")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if !scanResults.isEmpty {
                        Text("\(scanResults.count) ports scanned")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                if scanResults.isEmpty && !isScanning {
                    ContentUnavailableView(
                        "No Scan Results",
                        systemImage: "network.slash",
                        description: Text("Configure a target and start scanning")
                    )
                } else {
                    List(scanResults) { result in
                        PortResultRowView(result: result)
                    }
                    .listStyle(.plain)
                }
            }
        }
    }
    
    private func addTarget() {
        let target = Target(name: targetIP, ipAddress: targetIP)
        appState.addTarget(target)
        // Clear input after adding
        targetIP = ""
    }
    
    private func startScan() {
        guard !targetIP.isEmpty else { return }
        
        isScanning = true
        scanResults = []
        
        Task {
            await performScan()
            await MainActor.run {
                isScanning = false
            }
        }
    }
    
    private func performScan() async {
        // Parse port range
        let ports = parsePortRange(portRange)
        
        for port in ports {
            if !isScanning { break } // Allow cancellation
            
            let result = await scanPort(host: targetIP, port: port)
            await MainActor.run {
                scanResults.append(result)
            }
            
            // Small delay to prevent overwhelming the target
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
    }
    
    private func parsePortRange(_ range: String) -> [Int] {
        let components = range.split(separator: "-")
        guard components.count == 2,
              let start = Int(components[0]),
              let end = Int(components[1]),
              start <= end else {
            return Array(1...1000) // Default range
        }
        return Array(start...end)
    }
    
    private func scanPort(host: String, port: Int) async -> PortScanResult {
        let isOpen = await checkPortConnection(host: host, port: port)
        let service = getServiceName(for: port)
        let banner = isOpen ? await grabBanner(host: host, port: port) : nil
        let attackVectors = getAttackVectors(for: port, service: service)
        let riskLevel = calculateRiskLevel(port: port, service: service, isOpen: isOpen)
        
        let result = PortScanResult(
            port: port,
            isOpen: isOpen,
            service: service,
            scanTime: Date(),
            banner: banner,
            version: extractVersion(from: banner),
            attackVectors: attackVectors,
            riskLevel: riskLevel
        )
        
        // Add vulnerabilities to AppState if port is open and has attack vectors
        if isOpen && !attackVectors.isEmpty {
            await MainActor.run {
                addVulnerabilitiesToAppState(from: result)
            }
        }
        
        return result
    }
    
    private func addVulnerabilitiesToAppState(from result: PortScanResult) {
        for attackVector in result.attackVectors {
            let vulnerability = Vulnerability(
                title: "\(attackVector.name) on Port \(result.port)",
                description: attackVector.description,
                severity: convertRiskLevelToSeverity(result.riskLevel),
                port: result.port,
                service: result.service,
                discoveredAt: result.scanTime
            )
            appState.addVulnerability(vulnerability, targetIP: targetIP)
        }
    }
    
    private func convertRiskLevelToSeverity(_ riskLevel: PortScanResult.RiskLevel) -> Vulnerability.Severity {
        switch riskLevel {
        case .critical: return .critical
        case .high: return .high
        case .medium: return .medium
        case .low: return .low
        case .info: return .info
        }
    }
    
    private func grabBanner(host: String, port: Int) async -> String? {
        return await withTaskGroup(of: String?.self) { group in
            group.addTask {
                await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                let sock = socket(AF_INET, SOCK_STREAM, 0)
                defer { close(sock) }
                
                // Set socket timeout
                var timeout = timeval(tv_sec: 5, tv_usec: 0)
                setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
                setsockopt(sock, SOL_SOCKET, SO_SNDTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
                
                var addr = sockaddr_in()
                addr.sin_family = sa_family_t(AF_INET)
                addr.sin_port = in_port_t(port).bigEndian
                
                // Try to resolve hostname if not IP
                if inet_pton(AF_INET, host, &addr.sin_addr) != 1 {
                    var hints = addrinfo()
                    hints.ai_family = AF_INET
                    hints.ai_socktype = SOCK_STREAM
                    
                    var result: UnsafeMutablePointer<addrinfo>?
                    let status = getaddrinfo(host, nil, &hints, &result)
                    
                    if status == 0, let addrInfo = result {
                        let sockAddrIn = addrInfo.pointee.ai_addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
                        addr.sin_addr = sockAddrIn.sin_addr
                        freeaddrinfo(result)
                    } else {
                        continuation.resume(returning: nil)
                        return
                    }
                }
                
                let connectResult = withUnsafePointer(to: &addr) {
                    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                        connect(sock, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
                    }
                }
                
                if connectResult == 0 {
                    var banner: String?
                    
                    // Some services send banners immediately, others need a request
                    switch port {
                    case 80, 8080: // HTTP
                        let httpRequest = "GET / HTTP/1.1\r\nHost: \(host)\r\n\r\n"
                        send(sock, httpRequest, httpRequest.count, 0)
                    case 443: // HTTPS - would need SSL/TLS handling
                        break
                    case 25: // SMTP
                        break // SMTP usually sends banner immediately
                    case 110: // POP3
                        break // POP3 usually sends banner immediately
                    case 143: // IMAP
                        break // IMAP usually sends banner immediately
                    case 21: // FTP
                        break // FTP usually sends banner immediately
                    default:
                        break // Most services send banners immediately
                    }
                    
                    var buffer = [UInt8](repeating: 0, count: 4096)
                    let bytesRead = recv(sock, &buffer, buffer.count, 0)
                    
                    if bytesRead > 0 {
                        banner = String(bytes: buffer[0..<bytesRead], encoding: .utf8)
                        // Clean up the banner
                        banner = banner?.trimmingCharacters(in: .whitespacesAndNewlines)
                        if let cleanBanner = banner, cleanBanner.count > 200 {
                            banner = String(cleanBanner.prefix(200)) + "..."
                        }
                    }
                    
                    continuation.resume(returning: banner)
                } else {
                    continuation.resume(returning: nil)
                }
            }
                }
            }
            
            // Add timeout task
            group.addTask {
                try? await Task.sleep(nanoseconds: 6_000_000_000) // 6 second timeout
                return nil
            }
            
            // Return first completed result
            guard let result = await group.next() else { return nil }
            group.cancelAll()
            return result
        }
    }
    
    private func extractVersion(from banner: String?) -> String? {
        guard let banner = banner else { return nil }
        // Simple version extraction - can be enhanced with regex patterns
        let patterns = [
            "OpenSSH_([0-9.]+)",
            "Apache/([0-9.]+)",
            "nginx/([0-9.]+)",
            "Microsoft-IIS/([0-9.]+)"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: banner, range: NSRange(banner.startIndex..., in: banner)) {
                if let range = Range(match.range(at: 1), in: banner) {
                    return String(banner[range])
                }
            }
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
                tools: ["hydra", "nmap", "metasploit"],
                commands: ["hydra -l anonymous -p '' \(targetIP) ftp", "nmap --script ftp-anon \(targetIP)"],
                severity: .medium
            ))
            vectors.append(AttackVector(
                name: "FTP Brute Force",
                description: "Brute force FTP credentials",
                tools: ["hydra", "medusa", "ncrack"],
                commands: ["hydra -L users.txt -P pass.txt \(targetIP) ftp"],
                severity: .high
            ))
        case 22: // SSH
            vectors.append(AttackVector(
                name: "SSH Brute Force",
                description: "Brute force SSH credentials",
                tools: ["hydra", "medusa", "ncrack"],
                commands: ["hydra -L users.txt -P pass.txt \(targetIP) ssh"],
                severity: .high
            ))
            vectors.append(AttackVector(
                name: "SSH Key Enumeration",
                description: "Check for weak SSH keys or configurations",
                tools: ["ssh-audit", "nmap"],
                commands: ["ssh-audit \(targetIP)", "nmap --script ssh2-enum-algos \(targetIP)"],
                severity: .medium
            ))
        case 23: // Telnet
            vectors.append(AttackVector(
                name: "Telnet Brute Force",
                description: "Brute force Telnet credentials",
                tools: ["hydra", "medusa"],
                commands: ["hydra -L users.txt -P pass.txt \(targetIP) telnet"],
                severity: .critical
            ))
        case 25: // SMTP
            vectors.append(AttackVector(
                name: "SMTP User Enumeration",
                description: "Enumerate valid email addresses",
                tools: ["smtp-user-enum", "nmap"],
                commands: ["nmap --script smtp-enum-users \(targetIP)"],
                severity: .medium
            ))
        case 53: // DNS
            vectors.append(AttackVector(
                name: "DNS Zone Transfer",
                description: "Attempt DNS zone transfer",
                tools: ["dig", "nslookup", "dnsrecon"],
                commands: ["dig axfr @\(targetIP) domain.com"],
                severity: .high
            ))
        case 80, 443: // HTTP/HTTPS
            vectors.append(AttackVector(
                name: "Web Directory Enumeration",
                description: "Discover hidden directories and files",
                tools: ["dirb", "gobuster", "dirbuster"],
                commands: ["dirb http://\(targetIP)", "gobuster dir -u http://\(targetIP) -w /usr/share/wordlists/dirb/common.txt"],
                severity: .medium
            ))
            vectors.append(AttackVector(
                name: "Web Vulnerability Scan",
                description: "Scan for common web vulnerabilities",
                tools: ["nikto", "nmap", "burp"],
                commands: ["nikto -h \(targetIP)", "nmap --script http-vuln* \(targetIP)"],
                severity: .high
            ))
        case 110: // POP3
            vectors.append(AttackVector(
                name: "POP3 Brute Force",
                description: "Brute force POP3 credentials",
                tools: ["hydra", "medusa"],
                commands: ["hydra -L users.txt -P pass.txt \(targetIP) pop3"],
                severity: .high
            ))
        case 143: // IMAP
            vectors.append(AttackVector(
                name: "IMAP Brute Force",
                description: "Brute force IMAP credentials",
                tools: ["hydra", "medusa"],
                commands: ["hydra -L users.txt -P pass.txt \(targetIP) imap"],
                severity: .high
            ))
        case 3389: // RDP
            vectors.append(AttackVector(
                name: "RDP Brute Force",
                description: "Brute force RDP credentials",
                tools: ["hydra", "rdesktop", "ncrack"],
                commands: ["hydra -L users.txt -P pass.txt rdp://\(targetIP)"],
                severity: .critical
            ))
        case 445: // SMB
            vectors.append(AttackVector(
                name: "SMB Enumeration",
                description: "Enumerate SMB shares and users",
                tools: ["smbclient", "enum4linux", "nmap"],
                commands: ["smbclient -L \(targetIP)", "enum4linux \(targetIP)"],
                severity: .medium
            ))
        case 1433: // MSSQL
            vectors.append(AttackVector(
                name: "MSSQL Brute Force",
                description: "Brute force MSSQL credentials",
                tools: ["hydra", "medusa", "nmap"],
                commands: ["hydra -L users.txt -P pass.txt \(targetIP) mssql"],
                severity: .high
            ))
        case 3306: // MySQL
            vectors.append(AttackVector(
                name: "MySQL Brute Force",
                description: "Brute force MySQL credentials",
                tools: ["hydra", "medusa", "nmap"],
                commands: ["hydra -L users.txt -P pass.txt \(targetIP) mysql"],
                severity: .high
            ))
        case 5432: // PostgreSQL
            vectors.append(AttackVector(
                name: "PostgreSQL Brute Force",
                description: "Brute force PostgreSQL credentials",
                tools: ["hydra", "medusa", "nmap"],
                commands: ["hydra -L users.txt -P pass.txt \(targetIP) postgres"],
                severity: .high
            ))
        default:
            vectors.append(AttackVector(
                name: "Port Service Enumeration",
                description: "Identify service and version",
                tools: ["nmap", "netcat"],
                commands: ["nmap -sV -p \(port) \(targetIP)", "nc -nv \(targetIP) \(port)"],
                severity: .info
            ))
        }
        
        return vectors
    }
    
    private func calculateRiskLevel(port: Int, service: String?, isOpen: Bool) -> PortScanResult.RiskLevel {
        guard isOpen else { return .info }
        
        let highRiskPorts = [23, 3389, 445, 1433, 3306, 5432]
        let mediumRiskPorts = [21, 25, 53, 110, 143, 993, 995]
        let lowRiskPorts = [80, 443, 22]
        
        if highRiskPorts.contains(port) {
            return .critical
        } else if mediumRiskPorts.contains(port) {
            return .high
        } else if lowRiskPorts.contains(port) {
            return .medium
        } else {
            return .low
        }
    }
    
    private func checkPortConnection(host: String, port: Int) async -> Bool {
        return await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                await withCheckedContinuation { continuation in
                    DispatchQueue.global().async {
                        let sock = socket(AF_INET, SOCK_STREAM, 0)
                        defer { close(sock) }
                        
                        // Set socket timeout
                        var timeout = timeval(tv_sec: 2, tv_usec: 0)
                        setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
                        setsockopt(sock, SOL_SOCKET, SO_SNDTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
                        
                        var addr = sockaddr_in()
                        addr.sin_family = sa_family_t(AF_INET)
                        addr.sin_port = in_port_t(port).bigEndian
                        
                        // Try to resolve hostname if not IP
                        if inet_pton(AF_INET, host, &addr.sin_addr) != 1 {
                            // Try to resolve hostname with timeout
                            var hints = addrinfo()
                            hints.ai_family = AF_INET
                            hints.ai_socktype = SOCK_STREAM
                            
                            var result: UnsafeMutablePointer<addrinfo>?
                            let status = getaddrinfo(host, nil, &hints, &result)
                            
                            if status == 0, let addrInfo = result {
                                let sockAddrIn = addrInfo.pointee.ai_addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
                                addr.sin_addr = sockAddrIn.sin_addr
                                freeaddrinfo(result)
                            } else {
                                continuation.resume(returning: false)
                                return
                            }
                        }
                        
                        let connectResult = withUnsafePointer(to: &addr) {
                            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                                connect(sock, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
                            }
                        }
                        
                        continuation.resume(returning: connectResult == 0)
                    }
                }
            }
            
            // Add timeout task
            group.addTask {
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 second timeout
                return false
            }
            
            // Return first completed result
            guard let result = await group.next() else { return false }
            group.cancelAll()
            return result
        }
    }
    
    private func getServiceName(for port: Int) -> String? {
        let commonPorts: [Int: String] = [
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
            995: "POP3S",
            3389: "RDP",
            5432: "PostgreSQL",
            3306: "MySQL"
        ]
        return commonPorts[port]
    }
}

struct PortScanResult: Identifiable {
    let id = UUID()
    let port: Int
    let isOpen: Bool
    let service: String?
    let scanTime: Date
    let banner: String?
    let version: String?
    let attackVectors: [AttackVector]
    let riskLevel: RiskLevel
    
    enum RiskLevel: String, CaseIterable {
        case critical = "Critical"
        case high = "High"
        case medium = "Medium"
        case low = "Low"
        case info = "Info"
        
        var color: Color {
            switch self {
            case .critical: return .red
            case .high: return .orange
            case .medium: return .yellow
            case .low: return .blue
            case .info: return .gray
            }
        }
    }
}

struct AttackVector: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let tools: [String]
    let commands: [String]
    let severity: PortScanResult.RiskLevel
}

struct PortResultRowView: View {
    let result: PortScanResult
    @State private var isShowingDetail = false
    @State private var isHovering = false
    
    var body: some View {
        HStack {
            // Status indicator
            Circle()
                .fill(result.isOpen ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    // Port number
                    Text("\(result.port)")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    // Service name
                    if let service = result.service {
                        Text(service)
                            .font(.body)
                            .foregroundColor(.primary)
                    } else {
                        Text("Unknown")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Risk level badge
                    if result.isOpen {
                        Text(result.riskLevel.rawValue)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(result.riskLevel.color.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    
                    // Status text
                    Text(result.isOpen ? "Open" : "Closed")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(result.isOpen ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                        .cornerRadius(6)
                }
                
                // Version info if available
                if let version = result.version {
                    Text("Version: \(version)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Attack vectors count
                if result.isOpen && !result.attackVectors.isEmpty {
                    Text("\(result.attackVectors.count) attack vector(s) available")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            // Chevron indicator for open ports
            if result.isOpen {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12, weight: .medium))
                    .opacity(isHovering ? 1.0 : 0.6)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovering ? Color.gray.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isHovering ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
        .onTapGesture {
            if result.isOpen {
                isShowingDetail = true
            }
        }
        .sheet(isPresented: $isShowingDetail) {
            PortDetailView(result: result)
        }
    }
}

struct PortDetailView: View {
    let result: PortScanResult
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Port \(result.port)")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Text(result.riskLevel.rawValue)
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(result.riskLevel.color.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        
                        if let service = result.service {
                            Text("Service: \(service)")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let version = result.version {
                            Text("Version: \(version)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // Banner information
                    if let banner = result.banner {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Banner")
                                .font(.headline)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                Text(banner)
                                    .font(.body)
                                    .fontDesign(.monospaced)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    
                    // Attack vectors
                    if !result.attackVectors.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Attack Vectors (\(result.attackVectors.count))")
                                .font(.headline)
                            
                            LazyVStack(spacing: 12) {
                                ForEach(result.attackVectors) { vector in
                                    AttackVectorRowView(vector: vector)
                                }
                            }
                        }
                    }
                    
                    // Port scan information
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Scan Information")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Scan Time:")
                                    .fontWeight(.medium)
                                Spacer()
                                Text(result.scanTime.formatted(date: .omitted, time: .shortened))
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("Status:")
                                    .fontWeight(.medium)
                                Spacer()
                                Text(result.isOpen ? "Open" : "Closed")
                                    .foregroundColor(result.isOpen ? .green : .red)
                            }
                            
                            HStack {
                                Text("Risk Level:")
                                    .fontWeight(.medium)
                                Spacer()
                                Text(result.riskLevel.rawValue)
                                    .foregroundColor(result.riskLevel.color)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("Port \(result.port) Details")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 500)
    }
}

struct AttackVectorRowView: View {
    let vector: AttackVector
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(vector.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(vector.severity.rawValue)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(vector.severity.color.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    
                    Text(vector.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.plain)
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    // Tools
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tools:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(vector.tools.joined(separator: ", "))
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Commands
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Commands:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ForEach(vector.commands, id: \.self) { command in
                            HStack {
                                Text(command)
                                    .font(.body)
                                    .fontDesign(.monospaced)
                                    .textSelection(.enabled)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(4)
                                
                                Spacer()
                                
                                Button {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(command, forType: .string)
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                                .help("Copy command")
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

#Preview {
    NetworkScannerView()
        .environmentObject(AppState())
}
