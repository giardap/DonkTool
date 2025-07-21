//
//  PacketDetailView.swift
//  DonkTool
//
//  Detailed packet analysis view for the packet sniffer
//

import SwiftUI

struct PacketDetailView: View {
    let packet: CapturedPacket
    @State private var selectedTab = 0
    @State private var showRawData = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with packet summary
            PacketSummaryHeader()
            
            Divider()
            
            // Tab selector
            Picker("View", selection: $selectedTab) {
                Text("Overview").tag(0)
                Text("Headers").tag(1)
                Text("Data").tag(2)
                Text("Security").tag(3)
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Content based on selected tab
            ScrollView {
                switch selectedTab {
                case 0:
                    PacketOverviewTab()
                case 1:
                    PacketHeadersTab()
                case 2:
                    PacketDataTab()
                case 3:
                    PacketSecurityTab()
                default:
                    PacketOverviewTab()
                }
            }
        }
    }
    
    @ViewBuilder
    private func PacketSummaryHeader() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Packet Details")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(packet.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 16) {
                // Connection info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Connection")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("\(packet.sourceIP):\(packet.sourcePort ?? 0)")
                            .font(.system(.caption, design: .monospaced))
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                        Text("\(packet.destinationIP):\(packet.destinationPort ?? 0)")
                            .font(.system(.caption, design: .monospaced))
                    }
                }
                
                Divider()
                    .frame(height: 20)
                
                // Protocol info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Protocol")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(packet.protocolName)
                        .font(.system(.caption, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                }
                
                Divider()
                    .frame(height: 20)
                
                // Size info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Size")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(packet.length) bytes")
                        .font(.system(.caption, design: .monospaced))
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    @ViewBuilder
    private func PacketOverviewTab() -> some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            // Network layer info
            InfoSection("Network Layer") {
                InfoRow("Source IP", packet.sourceIP)
                InfoRow("Destination IP", packet.destinationIP)
                InfoRow("Protocol", packet.protocolName)
                InfoRow("Direction", packet.direction == .outbound ? "Outbound" : "Inbound")
            }
            
            // Transport layer info
            if packet.sourcePort != nil || packet.destinationPort != nil {
                InfoSection("Transport Layer") {
                    if let sourcePort = packet.sourcePort {
                        InfoRow("Source Port", String(sourcePort))
                    }
                    if let destPort = packet.destinationPort {
                        InfoRow("Destination Port", String(destPort))
                    }
                    if !packet.flags.isEmpty {
                        InfoRow("Flags", packet.flags.map(\.rawValue).joined(separator: ", "))
                    }
                }
            }
            
            // Application layer info
            if let protocolInfo = packet.protocolInfo {
                InfoSection("Application Layer") {
                    InfoRow("Protocol", protocolInfo.applicationProtocol)
                    
                    if let httpRequest = protocolInfo.httpRequest {
                        InfoRow("HTTP Method", httpRequest.method)
                        InfoRow("HTTP Path", httpRequest.path)
                    }
                    
                    if let credentials = protocolInfo.extractedCredentials, !credentials.isEmpty {
                        InfoRow("Credentials Found", "\(credentials.count) items")
                    }
                }
            }
            
            // Encryption info
            if let decryptionInfo = packet.decryptionInfo {
                InfoSection("Encryption") {
                    InfoRow("Encrypted", decryptionInfo.wasEncrypted ? "Yes" : "No")
                    if decryptionInfo.wasEncrypted {
                        InfoRow("Encryption Type", decryptionInfo.encryptionType)
                        InfoRow("Decryption Method", decryptionInfo.decryptionMethod)
                        InfoRow("Confidence", String(format: "%.1f%%", decryptionInfo.confidence * 100))
                    }
                }
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private func PacketHeadersTab() -> some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            if let protocolInfo = packet.protocolInfo, !protocolInfo.parsedHeaders.isEmpty {
                InfoSection("Parsed Headers") {
                    ForEach(protocolInfo.parsedHeaders.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        InfoRow(key, value)
                    }
                }
            } else {
                ContentUnavailableView(
                    "No Headers Available",
                    systemImage: "list.bullet",
                    description: Text("This packet does not contain parseable headers")
                )
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private func PacketDataTab() -> some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            // Data selector
            HStack {
                Text("Data View")
                    .font(.headline)
                
                Spacer()
                
                Picker("Data Type", selection: $showRawData) {
                    Text("Decrypted").tag(false)
                    Text("Raw").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }
            
            // Data content
            let dataToShow = showRawData ? packet.rawData : (packet.decryptedData ?? packet.rawData)
            
            if dataToShow.isEmpty {
                ContentUnavailableView(
                    "No Data Available",
                    systemImage: "doc",
                    description: Text("This packet contains no application data")
                )
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Data (\(dataToShow.count) bytes)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Button("Copy Hex") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(dataToShow.hexString, forType: .string)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    
                    // Hex dump
                    ScrollView(.horizontal) {
                        Text(formatHexDump(dataToShow))
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                    }
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .frame(maxHeight: 300)
                    
                    // ASCII representation if available
                    if let asciiString = String(data: dataToShow, encoding: .utf8) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ASCII Representation")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            ScrollView {
                                Text(asciiString)
                                    .font(.system(.caption, design: .monospaced))
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(8)
                            .frame(maxHeight: 200)
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private func PacketSecurityTab() -> some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            // Encryption analysis
            if let decryptionInfo = packet.decryptionInfo {
                InfoSection("Encryption Analysis") {
                    InfoRow("Encrypted", decryptionInfo.wasEncrypted ? "Yes" : "No")
                    if decryptionInfo.wasEncrypted {
                        InfoRow("Type", decryptionInfo.encryptionType)
                        InfoRow("Decryption Method", decryptionInfo.decryptionMethod)
                        InfoRow("Success Rate", String(format: "%.1f%%", decryptionInfo.confidence * 100))
                    }
                }
            }
            
            // Credential analysis
            if let protocolInfo = packet.protocolInfo,
               let credentials = protocolInfo.extractedCredentials,
               !credentials.isEmpty {
                
                InfoSection("Security Findings") {
                    ForEach(Array(credentials.enumerated()), id: \.offset) { index, credential in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Credential \(index + 1)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            InfoRow("Type", credential.type)
                            if let username = credential.username {
                                InfoRow("Username", username)
                            }
                            if let password = credential.password {
                                InfoRow("Password", String(repeating: "•", count: password.count))
                            }
                            if let token = credential.token {
                                InfoRow("Token", String(token.prefix(20)) + "...")
                            }
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            
            // Security recommendations
            InfoSection("Security Assessment") {
                if packet.destinationPort == 80 {
                    SecurityWarning("Unencrypted HTTP traffic detected", .high)
                }
                if packet.destinationPort == 23 {
                    SecurityWarning("Telnet protocol detected - highly insecure", .critical)
                }
                if packet.destinationPort == 21 {
                    SecurityWarning("FTP protocol detected - credentials sent in plaintext", .high)
                }
                if packet.isEncrypted {
                    SecurityRecommendation("Traffic is properly encrypted")
                } else if packet.destinationPort == 443 {
                    SecurityWarning("Expected encrypted traffic on port 443", .medium)
                }
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private func InfoSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 6) {
                content()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
    
    @ViewBuilder
    private func InfoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private func SecurityWarning(_ message: String, _ level: SecurityLevel) -> some View {
        HStack {
            Image(systemName: level.icon)
                .foregroundColor(level.color)
            
            Text(message)
                .font(.caption)
                .foregroundColor(level.color)
        }
        .padding(8)
        .background(level.color.opacity(0.1))
        .cornerRadius(6)
    }
    
    @ViewBuilder
    private func SecurityRecommendation(_ message: String) -> some View {
        HStack {
            Image(systemName: "checkmark.circle")
                .foregroundColor(.green)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.green)
        }
        .padding(8)
        .background(Color.green.opacity(0.1))
        .cornerRadius(6)
    }
    
    private func formatHexDump(_ data: Data) -> String {
        let bytesPerLine = 16
        var result = ""
        
        for lineIndex in stride(from: 0, to: data.count, by: bytesPerLine) {
            let endIndex = min(lineIndex + bytesPerLine, data.count)
            let lineData = data.subdata(in: lineIndex..<endIndex)
            
            // Offset
            result += String(format: "%08x  ", lineIndex)
            
            // Hex bytes
            for (index, byte) in lineData.enumerated() {
                result += String(format: "%02x ", byte)
                if index == 7 { result += " " }
            }
            
            // Pad if incomplete line
            let padding = bytesPerLine - lineData.count
            result += String(repeating: "   ", count: padding)
            if padding > 8 { result += " " }
            
            // ASCII representation
            result += " |"
            for byte in lineData {
                let char = (32...126).contains(byte) ? Character(UnicodeScalar(byte) ?? UnicodeScalar(46)!) : "."
                result += String(char)
            }
            result += "|\n"
        }
        
        return result
    }
}

enum SecurityLevel {
    case low, medium, high, critical
    
    var color: Color {
        switch self {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "info.circle"
        case .medium: return "exclamationmark.triangle"
        case .high: return "exclamationmark.octagon"
        case .critical: return "xmark.octagon"
        }
    }
}

// Extension for hex string conversion
extension Data {
    var hexString: String {
        return map { String(format: "%02x", $0) }.joined()
    }
}

#Preview {
    let samplePacket = CapturedPacket(
        timestamp: Date(),
        sourceIP: "192.168.1.100",
        destinationIP: "142.250.191.14",
        sourcePort: 54321,
        destinationPort: 443,
        protocolName: "TCP",
        length: 1420,
        rawData: "HTTP/1.1 GET /search?q=example HTTP/1.1\r\nHost: google.com\r\nUser-Agent: Safari\r\n\r\n".data(using: .utf8)!,
        decryptedData: nil,
        decryptionInfo: DecryptionInfo(wasEncrypted: true, encryptionType: "TLS 1.3", decryptionMethod: "Key Log", confidence: 0.95),
        protocolInfo: ProtocolInfo(
            applicationProtocol: "HTTPS",
            parsedHeaders: ["Host": "google.com", "User-Agent": "Safari"],
            extractedCredentials: nil as [PacketCredential]?,
            httpRequest: HTTPRequest(method: "GET", path: "/search", headers: [:], body: nil),
            httpResponse: nil as HTTPResponse?
        ),
        flags: [.syn, .ack]
    )
    
    PacketDetailView(packet: samplePacket)
}