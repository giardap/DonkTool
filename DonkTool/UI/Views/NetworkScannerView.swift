//
//  NetworkScannerView.swift
//  DonkTool
//
//  Network scanning interface
//

import SwiftUI

struct NetworkScannerView: View {
    @Environment(AppState.self) private var appState
    @State private var targetIP = ""
    @State private var portRange = "80-85"
    @State private var isScanning = false
    @State private var scanResults: [PortScanResult] = []
    @State private var selectedScanType: ScanType = .tcpConnect
    @State private var scanProgress: Double = 0.0
    @State private var currentPort: Int = 0
    @State private var totalPorts: Int = 0
    @State private var scanStartTime: Date = Date()
    @State private var estimatedTimeRemaining: TimeInterval = 0
    
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
                        
                        TextField("80-85", text: $portRange)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 120)
                    }
                    
                    Spacer()
                    
                    // Scan button and progress
                    VStack(spacing: 8) {
                        Button(action: {
                            print("🔴 BUTTON CLICKED!")
                            print("🔍 Button state: targetIP='\(targetIP)', isScanning=\(isScanning)")
                            print("🔍 Button disabled: \(targetIP.isEmpty || isScanning)")
                            startScan()
                        }) {
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
                        
                        // Progress indicator
                        if isScanning {
                            VStack(spacing: 4) {
                                ProgressView(value: scanProgress, total: 1.0)
                                    .frame(width: 200)
                                
                                HStack {
                                    Text("Port \(currentPort)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text("\(String(format: "%.1f", scanProgress * 100))%")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(width: 200)
                                
                                if estimatedTimeRemaining > 0 {
                                    Text("~\(formatTime(estimatedTimeRemaining)) remaining")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
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
                        PortResultRowView(result: result, targetIP: targetIP)
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
        print("🔴 START SCAN CALLED")
        
        isScanning = true
        scanResults = []
        scanProgress = 0.0
        currentPort = 0
        
        let ports = parsePortRange(portRange)
        totalPorts = ports.count
        
        print("🎯 Scanning \(totalPorts) ports")
        
        Task { @MainActor in
            await performSimpleScan(ports: ports)
        }
    }
    
    @MainActor
    private func performSimpleScan(ports: [Int]) async {
        print("🚀 SIMPLE SCAN STARTED")
        
        for (index, port) in ports.enumerated() {
            guard isScanning else { break }
            
            print("📡 Scanning port \(port)")
            
            // Update UI
            currentPort = port
            scanProgress = Double(index + 1) / Double(totalPorts)
            
            print("📊 Progress: \(Int(scanProgress * 100))%")
            
            // Scan the port
            let isOpen = await quickTCPScan(host: targetIP, port: port)
            
            let result = PortScanResult(
                port: port,
                isOpen: isOpen,
                service: isOpen ? getServiceName(for: port) : nil,
                scanTime: Date(),
                banner: nil,
                version: nil,
                attackVectors: isOpen ? getAttackVectors(for: port, service: getServiceName(for: port)) : [],
                riskLevel: calculateRiskLevel(port: port, service: getServiceName(for: port), isOpen: isOpen)
            )
            
            scanResults.append(result)
            
            if isOpen {
                print("✅ Port \(port) OPEN")
            }
            
            // Small delay
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
        
        isScanning = false
        scanProgress = 1.0
        print("🏁 Scan complete")
    }
    
    private func quickTCPScan(host: String, port: Int) async -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                let sock = socket(AF_INET, SOCK_STREAM, 0)
                defer { close(sock) }
                
                // Quick timeout
                var timeout = timeval(tv_sec: 1, tv_usec: 0)
                setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
                setsockopt(sock, SOL_SOCKET, SO_SNDTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
                
                var addr = sockaddr_in()
                addr.sin_family = sa_family_t(AF_INET)
                addr.sin_port = in_port_t(port).bigEndian
                
                // Simple IP conversion
                if inet_pton(AF_INET, host, &addr.sin_addr) == 1 {
                    let connectResult = withUnsafePointer(to: &addr) {
                        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                            connect(sock, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
                        }
                    }
                    continuation.resume(returning: connectResult == 0)
                } else {
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    private func parsePortRange(_ range: String) -> [Int] {
        let components = range.split(separator: "-")
        guard components.count == 2,
              let start = Int(components[0]),
              let end = Int(components[1]),
              start <= end else {
            return Array(80...85) // Default range
        }
        return Array(start...end)
    }
    
    private func getScanDelay(for scanType: ScanType) -> Double {
        switch scanType {
        case .tcpConnect:
            return 50.0 // 50ms - fast but visible
        case .syn:
            return 100.0 // 100ms - nmap execution takes time
        case .udp:
            return 200.0 // 200ms - UDP is slower due to timeouts
        case .comprehensive:
            return 300.0 // 300ms - comprehensive scans are slower
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        if seconds < 60 {
            return String(format: "%.0fs", seconds)
        } else if seconds < 3600 {
            let minutes = Int(seconds / 60)
            let remainingSeconds = Int(seconds.truncatingRemainder(dividingBy: 60))
            return String(format: "%dm %ds", minutes, remainingSeconds)
        } else {
            let hours = Int(seconds / 3600)
            let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
            return String(format: "%dh %dm", hours, minutes)
        }
    }
    
    private func scanPortAsync(host: String, port: Int, scanType: ScanType) async -> PortScanResult {
        let isOpen = await checkPortConnection(host: host, port: port, scanType: scanType)
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
        case .info: return .low
        }
    }
    
    private func checkPortConnection(host: String, port: Int, scanType: ScanType) async -> Bool {
        print("🔍 Using scan type: \(scanType.rawValue) for port \(port)")
        switch scanType {
        case .tcpConnect:
            return await checkTCPConnection(host: host, port: port)
        case .syn:
            return await checkSYNConnection(host: host, port: port)
        case .udp:
            return await checkUDPConnection(host: host, port: port)
        case .comprehensive:
            return await checkComprehensiveConnection(host: host, port: port)
        }
    }
    
    private func checkTCPConnection(host: String, port: Int) async -> Bool {
        print("🔵 === TCP CONNECTION CHECK STARTED for \(host):\(port) ===")
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                print("🔍 TCP Testing connection to \(host):\(port) on background thread")
                
                let sock = socket(AF_INET, SOCK_STREAM, 0)
                defer { 
                    close(sock)
                    print("🔌 TCP Socket closed for \(host):\(port)")
                }
                
                // Set socket timeout
                var timeout = timeval(tv_sec: 3, tv_usec: 0)
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
                        print("❌ DNS resolution failed for \(host)")
                        continuation.resume(returning: false)
                        return
                    }
                }
                
                let connectResult = withUnsafePointer(to: &addr) {
                    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                        connect(sock, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
                    }
                }
                
                let isOpen = connectResult == 0
                print("📡 TCP \(host):\(port) = \(isOpen ? "OPEN" : "CLOSED")")
                continuation.resume(returning: isOpen)
            }
        }
    }
    
    private func checkSYNConnection(host: String, port: Int) async -> Bool {
        // SYN scan using nmap TCP SYN scan (doesn't require root with -sT)
        return await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                await withCheckedContinuation { continuation in
                    DispatchQueue.global().async {
                        let process = Process()
                        let pipe = Pipe()
                        
                        process.standardOutput = pipe
                        process.standardError = pipe
                        
                        // Try to use nmap for SYN-style scan (using -sT instead of -sS)
                        if let nmapPath = ToolDetection.shared.getToolPath("nmap") {
                            process.executableURL = URL(fileURLWithPath: nmapPath)
                            // Use -sT (TCP connect) instead of -sS (SYN scan) to avoid root requirement
                            process.arguments = ["-sT", "-p", String(port), host, "--max-retries=1", "-T4"]
                            
                            do {
                                try process.run()
                                process.waitUntilExit()
                                
                                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                                let output = String(data: data, encoding: .utf8) ?? ""
                                
                                // Check if nmap reports the port as open
                                let isOpen = output.contains("open") && !output.contains("closed") && !output.contains("filtered")
                                continuation.resume(returning: isOpen)
                            } catch {
                                // Fallback to TCP connect if nmap fails
                                Task {
                                    let result = await self.checkTCPConnection(host: host, port: port)
                                    continuation.resume(returning: result)
                                }
                            }
                        } else {
                            // Fallback to TCP connect if nmap not available
                            Task {
                                let result = await self.checkTCPConnection(host: host, port: port)
                                continuation.resume(returning: result)
                            }
                        }
                    }
                }
            }
            
            group.addTask {
                try? await Task.sleep(nanoseconds: 8_000_000_000) // 8 second timeout
                return false
            }
            
            guard let result = await group.next() else { return false }
            group.cancelAll()
            return result
        }
    }
    
    private func checkUDPConnection(host: String, port: Int) async -> Bool {
        // UDP scan using nmap with faster options
        return await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                await withCheckedContinuation { continuation in
                    DispatchQueue.global().async {
                        let process = Process()
                        let pipe = Pipe()
                        
                        process.standardOutput = pipe
                        process.standardError = pipe
                        
                        // Try to use nmap for UDP scan with faster options
                        if let nmapPath = ToolDetection.shared.getToolPath("nmap") {
                            process.executableURL = URL(fileURLWithPath: nmapPath)
                            // Use faster UDP scan options
                            process.arguments = ["-sU", "-p", String(port), host, "--max-retries=1", "-T4", "-n"]
                            
                            do {
                                try process.run()
                                process.waitUntilExit()
                                
                                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                                let output = String(data: data, encoding: .utf8) ?? ""
                                
                                // UDP scan results: open, open|filtered, or closed
                                let isOpen = output.contains("open") && !output.contains("closed")
                                continuation.resume(returning: isOpen)
                            } catch {
                                // UDP scanning is complex without nmap - assume closed
                                continuation.resume(returning: false)
                            }
                        } else {
                            // Basic UDP socket test (limited effectiveness)
                            let sock = socket(AF_INET, SOCK_DGRAM, 0)
                            defer { close(sock) }
                            
                            var timeout = timeval(tv_sec: 1, tv_usec: 0)
                            setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
                            setsockopt(sock, SOL_SOCKET, SO_SNDTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
                            
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
                                
                                // For UDP, try to receive a response
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
            }
            
            group.addTask {
                try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 second timeout for UDP
                return false
            }
            
            guard let result = await group.next() else { return false }
            group.cancelAll()
            return result
        }
    }
    
    private func checkComprehensiveConnection(host: String, port: Int) async -> Bool {
        // Comprehensive scan combines multiple techniques
        let tcpResult = await checkTCPConnection(host: host, port: port)
        
        // For comprehensive scan, if TCP fails, try SYN scan
        if !tcpResult {
            return await checkSYNConnection(host: host, port: port)
        }
        
        return tcpResult
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
                        
                        var addr = sockaddr_in()
                        addr.sin_family = sa_family_t(AF_INET)
                        addr.sin_port = in_port_t(port).bigEndian
                        
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
                            default:
                                break // Most services send banners immediately
                            }
                            
                            var buffer = [UInt8](repeating: 0, count: 4096)
                            let bytesRead = recv(sock, &buffer, buffer.count, 0)
                            
                            if bytesRead > 0 {
                                banner = String(bytes: buffer[0..<bytesRead], encoding: .utf8)
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
                name: "FTP Banner Grabbing",
                description: "Enumerate FTP service version and capabilities",
                severity: .medium,
                requirements: [
                    ToolRequirement(name: "nmap", type: .tool, description: "Network discovery and security auditing"),
                    ToolRequirement(name: "curl", type: .builtin, description: "Command line tool for transferring data")
                ],
                commands: [
                    "nmap -sV -p 21 {target}",
                    "curl ftp://{target} --list-only"
                ],
                references: ["https://nmap.org/nsedoc/scripts/ftp-anon.html"]
            ))
            
        case 22: // SSH
            vectors.append(AttackVector(
                name: "SSH Banner Grabbing",
                description: "Identify SSH version and supported authentication methods",
                severity: .low,
                requirements: [
                    ToolRequirement(name: "nmap", type: .tool, description: "Network discovery and security auditing")
                ],
                commands: [
                    "nmap -sV -p 22 {target}",
                    "ssh -o ConnectTimeout=5 {target} 2>&1 | head -1"
                ],
                references: ["https://nmap.org/nsedoc/scripts/ssh-hostkey.html"]
            ))
            
        case 80, 443: // HTTP/HTTPS
            vectors.append(AttackVector(
                name: "Web Directory Enumeration",
                description: "Discover hidden directories and files on web server",
                severity: .medium,
                requirements: [
                    ToolRequirement(name: "gobuster", type: .optional, description: "Directory/file/DNS busting tool"),
                    ToolRequirement(name: "dirb", type: .optional, description: "Web content scanner"),
                    ToolRequirement(name: "curl", type: .builtin, description: "Command line tool for transferring data")
                ],
                commands: [
                    "gobuster dir -u http://{target} -w /usr/share/wordlists/dirb/common.txt",
                    "dirb http://{target}",
                    "curl -I http://{target}"
                ],
                references: ["https://github.com/OJ/gobuster"]
            ))
            
            vectors.append(AttackVector(
                name: "Web Vulnerability Scanning",
                description: "Automated web application security testing",
                severity: .high,
                requirements: [
                    ToolRequirement(name: "burpsuite", type: .gui, description: "Web application security testing platform"),
                    ToolRequirement(name: "nikto", type: .optional, description: "Web server scanner")
                ],
                commands: [
                    "# Manual: Configure Burp Suite proxy and perform active scan",
                    "nikto -h http://{target}"
                ],
                references: ["https://portswigger.net/burp"]
            ))
            
        case 445: // SMB
            vectors.append(AttackVector(
                name: "SMB Enumeration",
                description: "Enumerate SMB shares and permissions",
                severity: .high,
                requirements: [
                    ToolRequirement(name: "nmap", type: .tool, description: "Network discovery and security auditing"),
                    ToolRequirement(name: "smbclient", type: .optional, description: "SMB client program")
                ],
                commands: [
                    "nmap --script smb-enum-shares -p 445 {target}",
                    "smbclient -L {target} -N"
                ],
                references: ["https://nmap.org/nsedoc/scripts/smb-enum-shares.html"]
            ))
            
        case 3389: // RDP
            vectors.append(AttackVector(
                name: "RDP Security Assessment",
                description: "Test RDP service for common vulnerabilities",
                severity: .critical,
                requirements: [
                    ToolRequirement(name: "nmap", type: .tool, description: "Network discovery and security auditing"),
                    ToolRequirement(name: "rdesktop", type: .optional, description: "RDP client")
                ],
                commands: [
                    "nmap --script rdp-enum-encryption -p 3389 {target}",
                    "nmap --script rdp-vuln-ms12-020 -p 3389 {target}"
                ],
                references: ["https://nmap.org/nsedoc/scripts/rdp-enum-encryption.html"]
            ))
            
        default:
            vectors.append(AttackVector(
                name: "Port Service Detection",
                description: "Identify service version and potential vulnerabilities",
                severity: .info,
                requirements: [
                    ToolRequirement(name: "nmap", type: .tool, description: "Network discovery and security auditing")
                ],
                commands: [
                    "nmap -sV -sC -p {port} {target}"
                ],
                references: ["https://nmap.org/book/man-version-detection.html"]
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
    
    private func getServiceName(for port: Int) -> String? {
        let commonPorts: [Int: String] = [
            21: "FTP", 22: "SSH", 23: "Telnet", 25: "SMTP", 53: "DNS",
            80: "HTTP", 110: "POP3", 143: "IMAP", 443: "HTTPS", 993: "IMAPS",
            995: "POP3S", 3389: "RDP", 5432: "PostgreSQL", 3306: "MySQL"
        ]
        return commonPorts[port]
    }
}

// PortScanResult struct is now defined in Models.swift - removed duplicate
// AttackVector struct is now defined in Models.swift - removed duplicate

struct PortResultRowView: View {
    let result: PortScanResult
    let targetIP: String
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
                    Text("\(result.port)")
                        .font(.headline)
                        .fontWeight(.medium)
                    
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
                    
                    Text(result.isOpen ? "Open" : "Closed")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(result.isOpen ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                        .cornerRadius(6)
                }
                
                if let version = result.version {
                    Text("Version: \(version)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if result.isOpen && !result.attackVectors.isEmpty {
                    Text("\(result.attackVectors.count) attack vector(s) available")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
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
            PortDetailView(result: result, targetIP: targetIP)
        }
    }
}

struct PortDetailView: View {
    let result: PortScanResult
    let targetIP: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Port \(result.port)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    if let service = result.service {
                        Text("Service: \(service)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let banner = result.banner {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Banner")
                                .font(.headline)
                            
                            Text(banner)
                                .font(.body)
                                .fontDesign(.monospaced)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    
                    if !result.attackVectors.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Attack Vectors (\(result.attackVectors.count))")
                                .font(.headline)
                            
                            ForEach(result.attackVectors) { vector in
                                AttackVectorRowView(vector: vector, target: targetIP, port: result.port)
                            }
                        }
                    }
                    
                    Spacer()
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
    let target: String
    let port: Int
    @State private var isExpanded = false
    @State private var showingAttackExecution = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(vector.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(vector.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tools:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(vector.requirements.map { $0.name }.joined(separator: ", "))
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Commands:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ForEach(vector.commands, id: \.self) { command in
                            Text(command)
                                .font(.body)
                                .fontDesign(.monospaced)
                                .textSelection(.enabled)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(4)
                        }
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
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
        .sheet(isPresented: $showingAttackExecution) {
            AttackExecutionView(attackVector: vector, target: target, port: port)
        }
    }
}

#Preview {
    NetworkScannerView()
        .environment(AppState())
}
