//
//  PacketRowView.swift
//  DonkTool
//
//  Packet list row component for the packet sniffer
//

import SwiftUI

struct PacketRowView: View {
    let packet: CapturedPacket
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Direction indicator
            Image(systemName: packet.direction == .outbound ? "arrow.up.right" : "arrow.down.left")
                .foregroundColor(packet.direction == .outbound ? .blue : .green)
                .frame(width: 16)
            
            // Timestamp
            Text(packet.timestamp, style: .time)
                .font(.system(.caption, design: .monospaced))
                .frame(width: 60, alignment: .leading)
            
            // Source IP:Port
            VStack(alignment: .leading, spacing: 2) {
                Text(packet.sourceIP)
                    .font(.system(.caption, design: .monospaced))
                if let port = packet.sourcePort {
                    Text(":\(port)")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 100, alignment: .leading)
            
            // Arrow
            Image(systemName: "arrow.right")
                .foregroundColor(.secondary)
                .font(.caption2)
            
            // Destination IP:Port
            VStack(alignment: .leading, spacing: 2) {
                Text(packet.destinationIP)
                    .font(.system(.caption, design: .monospaced))
                if let port = packet.destinationPort {
                    Text(":\(port)")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 100, alignment: .leading)
            
            // Protocol
            Text(packet.protocolName)
                .font(.system(.caption, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(protocolColor(packet.protocolName).opacity(0.2))
                .foregroundColor(protocolColor(packet.protocolName))
                .cornerRadius(4)
                .frame(width: 60)
            
            // Length
            Text("\(packet.length)")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .trailing)
            
            // Flags
            HStack(spacing: 2) {
                ForEach(packet.flags.prefix(3), id: \.rawValue) { flag in
                    Text(flag.rawValue)
                        .font(.system(.caption2, design: .monospaced))
                        .padding(.horizontal, 3)
                        .padding(.vertical, 1)
                        .background(flagColor(flag).opacity(0.3))
                        .foregroundColor(flagColor(flag))
                        .cornerRadius(2)
                }
                if packet.flags.count > 3 {
                    Text("+\(packet.flags.count - 3)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 80, alignment: .leading)
            
            // Encryption indicator
            if packet.isEncrypted {
                Image(systemName: "lock.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
            }
            
            Spacer()
            
            // Protocol info preview
            if let protocolInfo = packet.protocolInfo {
                Text(protocolInfo.applicationProtocol)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 60, alignment: .trailing)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(4)
    }
    
    private func protocolColor(_ protocolName: String) -> Color {
        switch protocolName.uppercased() {
        case "HTTP", "HTTPS":
            return .blue
        case "TCP":
            return .green
        case "UDP":
            return .orange
        case "DNS":
            return .purple
        case "SSH":
            return .red
        default:
            return .gray
        }
    }
    
    private func flagColor(_ flag: PacketFlag) -> Color {
        switch flag {
        case .syn:
            return .blue
        case .ack:
            return .green
        case .fin:
            return .orange
        case .rst:
            return .red
        case .psh:
            return .purple
        case .urg:
            return .pink
        case .encrypted:
            return .yellow
        case .fragmented:
            return .gray
        }
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
        rawData: Data(),
        decryptedData: nil,
        decryptionInfo: nil,
        protocolInfo: ProtocolInfo(
            applicationProtocol: "HTTPS",
            parsedHeaders: [:],
            extractedCredentials: nil as [PacketCredential]?,
            httpRequest: nil as HTTPRequest?,
            httpResponse: nil as HTTPResponse?
        ),
        flags: [.syn, .ack]
    )
    
    PacketRowView(packet: samplePacket, isSelected: false)
        .padding()
}