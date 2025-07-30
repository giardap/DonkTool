//
//  UltraModernPacketSniffer.swift
//  DonkTool
//
//  Ultra-modern packet sniffer interface with real-time visualization
//

import SwiftUI
import Charts

struct UltraModernPacketSniffer: View {
    @Environment(AppState.self) private var appState
    @StateObject private var packetSniffer = PacketSnifferManager()
    @State private var selectedInterface = "en0"
    @State private var filterExpression = ""
    @State private var isSniffing = false
    @State private var selectedPacket: ModernCapturedPacket?
    @State private var showingAdvancedFilters = false
    @State private var viewMode = ViewMode.list
    @State private var autoScroll = true
    @State private var searchText = ""
    
    enum ViewMode: String, CaseIterable {
        case list = "List"
        case flow = "Flow"
        case statistics = "Statistics"
        
        var icon: String {
            switch self {
            case .list: return "list.bullet"
            case .flow: return "arrow.left.arrow.right"
            case .statistics: return "chart.line.uptrend.xyaxis"
            }
        }
    }
    
    var filteredPackets: [ModernCapturedPacket] {
        if searchText.isEmpty {
            return packetSniffer.capturedPackets
        }
        return packetSniffer.capturedPackets.filter { packet in
            packet.sourceIP.contains(searchText) ||
            packet.destinationIP.contains(searchText) ||
            packet.protocolName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var protocolDistribution: [(String, Int)] {
        let grouped = Dictionary(grouping: packetSniffer.capturedPackets) { $0.protocolName }
        return grouped.map { ($0.key, $0.value.count) }.sorted { $0.1 > $1.1 }.prefix(6).map { ($0.0, $0.1) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Modern Header
            ModernPacketSnifferHeader(
                isSniffing: $isSniffing,
                packetCount: packetSniffer.capturedPackets.count,
                bytesCapture: packetSniffer.totalBytesCapture
            )
            .fadeIn(delay: 0.1)
            
            // Control Bar
            PacketSnifferControlBar(
                selectedInterface: $selectedInterface,
                filterExpression: $filterExpression,
                isSniffing: $isSniffing,
                viewMode: $viewMode,
                autoScroll: $autoScroll,
                searchText: $searchText,
                showingAdvancedFilters: $showingAdvancedFilters,
                startSniffing: startSniffing,
                stopSniffing: stopSniffing
            )
            .slideIn(from: .top, delay: 0.2)
            
            // Main Content
            switch viewMode {
            case .list:
                PacketListView(
                    packets: filteredPackets,
                    selectedPacket: $selectedPacket,
                    autoScroll: autoScroll
                )
                .transition(.slideAndFade)
            case .flow:
                PacketFlowView(
                    packets: filteredPackets,
                    selectedPacket: $selectedPacket
                )
                .transition(.slideAndFade)
            case .statistics:
                PacketStatisticsView(
                    packets: packetSniffer.capturedPackets,
                    protocolDistribution: protocolDistribution
                )
                .transition(.slideAndFade)
            }
        }
        .sheet(isPresented: $showingAdvancedFilters) {
            AdvancedFiltersSheet(
                filterExpression: $filterExpression
            )
        }
        .sheet(item: $selectedPacket) { packet in
            PacketDetailSheet(packet: packet)
        }
    }
    
    private func startSniffing() {
        withAnimation(.bounceSpring) {
            isSniffing = true
        }
        packetSniffer.startCapture(interface: selectedInterface, filter: filterExpression)
    }
    
    private func stopSniffing() {
        withAnimation(.smoothSpring) {
            isSniffing = false
        }
        packetSniffer.stopCapture()
    }
}

// MARK: - Header

struct ModernPacketSnifferHeader: View {
    @Binding var isSniffing: Bool
    let packetCount: Int
    let bytesCapture: Int64
    @State private var pulseAnimation = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 28))
                        .foregroundColor(.accentColor)
                        .symbolEffect(.variableColor.iterative, value: isSniffing)
                        .scaleEffect(isSniffing ? (pulseAnimation ? 1.1 : 1.0) : 1.0)
                        .animation(
                            isSniffing ? .easeInOut(duration: 1).repeatForever(autoreverses: true) : .default,
                            value: pulseAnimation
                        )
                    
                    Text("Packet Sniffer")
                        .font(.system(size: 32, weight: .bold))
                }
                
                Text("Real-time network packet analysis")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Live Stats
            HStack(spacing: 24) {
                LiveStat(
                    label: "Packets",
                    value: formatNumber(packetCount),
                    icon: "doc.on.doc",
                    color: .blue,
                    isAnimating: isSniffing
                )
                
                LiveStat(
                    label: "Data",
                    value: formatBytes(bytesCapture),
                    icon: "arrow.up.arrow.down",
                    color: .green,
                    isAnimating: isSniffing
                )
                
                LiveStat(
                    label: "Status",
                    value: isSniffing ? "Capturing" : "Idle",
                    icon: isSniffing ? "dot.radiowaves.left.and.right" : "pause.circle",
                    color: isSniffing ? .green : .gray,
                    isAnimating: isSniffing
                )
            }
        }
        .padding(24)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            pulseAnimation = true
        }
    }
    
    private func formatNumber(_ num: Int) -> String {
        if num >= 1000000 {
            return String(format: "%.1fM", Double(num) / 1000000)
        } else if num >= 1000 {
            return String(format: "%.1fK", Double(num) / 1000)
        }
        return "\(num)"
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }
}

struct LiveStat: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    let isAnimating: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .symbolEffect(.pulse, value: isAnimating)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .semibold))
                    .contentTransition(.numericText())
                    .animation(.smoothSpring, value: value)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Control Bar

struct PacketSnifferControlBar: View {
    @Binding var selectedInterface: String
    @Binding var filterExpression: String
    @Binding var isSniffing: Bool
    @Binding var viewMode: UltraModernPacketSniffer.ViewMode
    @Binding var autoScroll: Bool
    @Binding var searchText: String
    @Binding var showingAdvancedFilters: Bool
    let startSniffing: () -> Void
    let stopSniffing: () -> Void
    @State private var isHoveredStart = false
    
    let interfaces = ["en0", "en1", "lo0", "awdl0"]
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Interface Selection
                HStack(spacing: 8) {
                    Image(systemName: "network.badge.shield.half.filled")
                        .foregroundColor(.secondary)
                    
                    Picker("Interface", selection: $selectedInterface) {
                        ForEach(interfaces, id: \.self) { interface in
                            Text(interface).tag(interface)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 100)
                    .disabled(isSniffing)
                }
                
                // Filter
                HStack {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(.secondary)
                    
                    TextField("Filter expression (e.g., tcp port 80)", text: $filterExpression)
                        .textFieldStyle(.plain)
                        .disabled(isSniffing)
                    
                    Button(action: { showingAdvancedFilters = true }) {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .disabled(isSniffing)
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
                // Start/Stop Button
                Button(action: isSniffing ? stopSniffing : startSniffing) {
                    Label(
                        isSniffing ? "Stop Capture" : "Start Capture",
                        systemImage: isSniffing ? "stop.circle.fill" : "play.circle.fill"
                    )
                    .foregroundColor(.white)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(isSniffing ? .red : .green)
            }
            
            HStack(spacing: 16) {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search packets...", text: $searchText)
                        .textFieldStyle(.plain)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .frame(maxWidth: 300)
                
                Spacer()
                
                // View Mode
                Picker("View", selection: $viewMode) {
                    ForEach(UltraModernPacketSniffer.ViewMode.allCases, id: \.self) { mode in
                        Label(mode.rawValue, systemImage: mode.icon)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 250)
                
                // Auto Scroll Toggle
                Toggle(isOn: $autoScroll) {
                    Label("Auto Scroll", systemImage: "arrow.down.to.line")
                }
                .toggleStyle(.button)
                
                // Clear Button
                Button(action: { /* Clear packets */ }) {
                    Label("Clear", systemImage: "trash")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color(NSColor.windowBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(NSColor.separatorColor)),
            alignment: .bottom
        )
    }
}

// MARK: - List View

struct PacketListView: View {
    let packets: [ModernCapturedPacket]
    @Binding var selectedPacket: ModernCapturedPacket?
    let autoScroll: Bool
    @State private var hoveredPacketID: UUID?
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    // Header
                    PacketListHeader()
                    
                    // Packets
                    ForEach(packets) { packet in
                        PacketRow(
                            packet: packet,
                            isSelected: selectedPacket?.id == packet.id,
                            isHovered: hoveredPacketID == packet.id,
                            action: { selectedPacket = packet }
                        )
                        .onHover { hovering in
                            hoveredPacketID = hovering ? packet.id : nil
                        }
                        .id(packet.id)
                    }
                }
                .padding(.horizontal, 16)
            }
            .onChange(of: packets.count) { _, _ in
                if autoScroll, let lastPacket = packets.last {
                    withAnimation {
                        proxy.scrollTo(lastPacket.id, anchor: .bottom)
                    }
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct PacketListHeader: View {
    var body: some View {
        HStack(spacing: 16) {
            Text("Time")
                .frame(width: 80, alignment: .leading)
            
            Text("Source")
                .frame(width: 120, alignment: .leading)
            
            Text("Destination")
                .frame(width: 120, alignment: .leading)
            
            Text("Protocol")
                .frame(width: 80, alignment: .leading)
            
            Text("Length")
                .frame(width: 80, alignment: .trailing)
            
            Text("Info")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.system(size: 12, weight: .semibold))
        .foregroundColor(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct PacketRow: View {
    let packet: ModernCapturedPacket
    let isSelected: Bool
    let isHovered: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(packet.timestamp, style: .time)
                    .font(.system(size: 11, design: .monospaced))
                    .frame(width: 80, alignment: .leading)
                
                Text(packet.sourceIP)
                    .font(.system(size: 11, design: .monospaced))
                    .frame(width: 120, alignment: .leading)
                
                Text(packet.destinationIP)
                    .font(.system(size: 11, design: .monospaced))
                    .frame(width: 120, alignment: .leading)
                
                ProtocolBadge(protocolName: packet.protocolName)
                    .frame(width: 80, alignment: .leading)
                
                Text("\(packet.length)")
                    .font(.system(size: 11, design: .monospaced))
                    .frame(width: 80, alignment: .trailing)
                
                Text(packet.info)
                    .font(.system(size: 11))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(backgroundColor)
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }
    
    var backgroundColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.2)
        } else if isHovered {
            return Color.primary.opacity(0.05)
        } else {
            return Color.clear
        }
    }
}

struct ProtocolBadge: View {
    let protocolName: String
    
    var protocolColor: Color {
        switch protocolName.uppercased() {
        case "TCP": return .blue
        case "UDP": return .green
        case "ICMP": return .orange
        case "ARP": return .purple
        case "DNS": return .pink
        case "HTTP", "HTTPS": return .red
        default: return .gray
        }
    }
    
    var body: some View {
        Text(protocolName)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(protocolColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(protocolColor.opacity(0.1))
            .cornerRadius(4)
    }
}

// MARK: - Flow View

struct PacketFlowView: View {
    let packets: [ModernCapturedPacket]
    @Binding var selectedPacket: ModernCapturedPacket?
    
    var flows: [(source: String, destination: String, count: Int)] {
        let grouped = Dictionary(grouping: packets) { packet in
            "\(packet.sourceIP)->\(packet.destinationIP)"
        }
        
        return grouped.compactMap { (key, packets) -> (String, String, Int)? in
            let components = key.split(separator: "->")
            guard components.count == 2 else { return nil }
            return (String(components[0]), String(components[1]), packets.count)
        }
        .sorted { $0.2 > $1.2 }
        .prefix(20)
        .map { ($0.0, $0.1, $0.2) }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(flows, id: \.source) { flow in
                    FlowCard(
                        source: flow.source,
                        destination: flow.destination,
                        packetCount: flow.count,
                        totalPackets: packets.count
                    )
                }
            }
            .padding(24)
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct FlowCard: View {
    let source: String
    let destination: String
    let packetCount: Int
    let totalPackets: Int
    
    var percentage: Double {
        Double(packetCount) / Double(max(totalPackets, 1))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(source)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                    Text("Source")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 16))
                    .foregroundColor(.accentColor)
                    .frame(maxWidth: .infinity)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(destination)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                    Text("Destination")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.primary.opacity(0.1))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: geometry.size.width * percentage, height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
            
            HStack {
                Text("\(packetCount) packets")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(String(format: "%.1f%%", percentage * 100))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Statistics View

struct PacketStatisticsView: View {
    let packets: [ModernCapturedPacket]
    let protocolDistribution: [(String, Int)]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Protocol Distribution Chart
                PacketStatCard(title: "Protocol Distribution", icon: "chart.pie.fill") {
                    if !protocolDistribution.isEmpty {
                        Chart(protocolDistribution, id: \.0) { item in
                            SectorMark(
                                angle: .value("Count", item.1),
                                innerRadius: .ratio(0.5),
                                outerRadius: .ratio(1.0)
                            )
                            .foregroundStyle(by: .value("Protocol", item.0))
                            .cornerRadius(4)
                        }
                        .frame(height: 300)
                    } else {
                        Text("No data to display")
                            .foregroundColor(.secondary)
                            .frame(height: 300)
                            .frame(maxWidth: .infinity)
                    }
                }
                
                // Packet Timeline
                PacketStatCard(title: "Packet Timeline", icon: "chart.line.uptrend.xyaxis") {
                    PacketTimelineChart(packets: packets)
                        .frame(height: 200)
                }
                
                // Top Talkers
                HStack(spacing: 24) {
                    PacketStatCard(title: "Top Sources", icon: "arrow.up.circle") {
                        TopTalkersList(packets: packets, isSource: true)
                    }
                    
                    PacketStatCard(title: "Top Destinations", icon: "arrow.down.circle") {
                        TopTalkersList(packets: packets, isSource: false)
                    }
                }
            }
            .padding(24)
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct PacketStatCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            
            content
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct PacketTimelineChart: View {
    let packets: [ModernCapturedPacket]
    
    var timelineData: [(Date, Int)] {
        let grouped = Dictionary(grouping: packets) { packet in
            Calendar.current.dateInterval(of: .minute, for: packet.timestamp)?.start ?? packet.timestamp
        }
        
        return grouped.map { ($0.key, $0.value.count) }
            .sorted { $0.0 < $1.0 }
    }
    
    var body: some View {
        if !timelineData.isEmpty {
            Chart(timelineData, id: \.0) { item in
                LineMark(
                    x: .value("Time", item.0),
                    y: .value("Packets", item.1)
                )
                .foregroundStyle(Color.accentColor)
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("Time", item.0),
                    y: .value("Packets", item.1)
                )
                .foregroundStyle(Color.accentColor.opacity(0.1))
                .interpolationMethod(.catmullRom)
            }
        } else {
            Text("No timeline data")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct TopTalkersList: View {
    let packets: [ModernCapturedPacket]
    let isSource: Bool
    
    var topTalkers: [(String, Int)] {
        let grouped = Dictionary(grouping: packets) { packet in
            isSource ? packet.sourceIP : packet.destinationIP
        }
        
        return grouped.map { ($0.key, $0.value.count) }
            .sorted { $0.1 > $1.1 }
            .prefix(5)
            .map { ($0.0, $0.1) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(topTalkers, id: \.0) { talker in
                HStack {
                    Text(talker.0)
                        .font(.system(size: 12, design: .monospaced))
                    
                    Spacer()
                    
                    Text("\(talker.1)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            
            if topTalkers.isEmpty {
                Text("No data")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Supporting Views

struct AdvancedFiltersSheet: View {
    @Binding var filterExpression: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var protocolFilter = "any"
    @State private var sourceIP = ""
    @State private var destIP = ""
    @State private var port = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Advanced Filters")
                .font(.system(size: 20, weight: .semibold))
            
            VStack(alignment: .leading, spacing: 16) {
                PacketFilterField(label: "Protocol", value: $protocolFilter, options: ["any", "tcp", "udp", "icmp"])
                PacketFilterField(label: "Source IP", value: $sourceIP, placeholder: "192.168.1.1")
                PacketFilterField(label: "Destination IP", value: $destIP, placeholder: "10.0.0.1")
                PacketFilterField(label: "Port", value: $port, placeholder: "80")
            }
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Apply") {
                    buildFilterExpression()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 400)
    }
    
    private func buildFilterExpression() {
        var parts: [String] = []
        
        if protocolFilter != "any" {
            parts.append(protocolFilter)
        }
        
        if !sourceIP.isEmpty {
            parts.append("src \(sourceIP)")
        }
        
        if !destIP.isEmpty {
            parts.append("dst \(destIP)")
        }
        
        if !port.isEmpty {
            parts.append("port \(port)")
        }
        
        filterExpression = parts.joined(separator: " and ")
    }
}

struct PacketFilterField: View {
    let label: String
    @Binding var value: String
    var placeholder: String = ""
    var options: [String]? = nil
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 100, alignment: .leading)
            
            if let options = options {
                Picker("", selection: $value) {
                    ForEach(options, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.menu)
            } else {
                TextField(placeholder, text: $value)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
}

struct PacketDetailSheet: View {
    let packet: ModernCapturedPacket
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Packet Details")
                        .font(.system(size: 20, weight: .semibold))
                    Text("Captured at \(packet.timestamp.formatted())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding(24)
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    DetailSection(title: "Network Layer") {
                        DetailField(label: "Source IP", value: packet.sourceIP)
                        DetailField(label: "Destination IP", value: packet.destinationIP)
                        DetailField(label: "Protocol", value: packet.protocolName)
                        DetailField(label: "Length", value: "\(packet.length) bytes")
                    }
                    
                    DetailSection(title: "Transport Layer") {
                        DetailField(label: "Source Port", value: "\(packet.sourcePort)")
                        DetailField(label: "Destination Port", value: "\(packet.destPort)")
                        DetailField(label: "Flags", value: packet.flags)
                    }
                    
                    DetailSection(title: "Payload") {
                        Text(packet.hexDump)
                            .font(.system(size: 12, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(12)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                    }
                }
                .padding(24)
            }
        }
        .frame(width: 600, height: 500)
    }
}

struct DetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
            
            VStack(alignment: .leading, spacing: 8) {
                content
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
}

struct DetailField: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .textSelection(.enabled)
        }
    }
}

// MARK: - Data Models

struct ModernCapturedPacket: Identifiable {
    let id = UUID()
    let timestamp: Date
    let sourceIP: String
    let destinationIP: String
    let sourcePort: Int
    let destPort: Int
    let protocolName: String
    let length: Int
    let info: String
    let flags: String
    let hexDump: String
    
    static var sample: ModernCapturedPacket {
        ModernCapturedPacket(
            timestamp: Date(),
            sourceIP: "192.168.1.100",
            destinationIP: "8.8.8.8",
            sourcePort: 54321,
            destPort: 443,
            protocolName: "TCP",
            length: 1500,
            info: "TLS Application Data",
            flags: "PSH, ACK",
            hexDump: "00 00 00 00 00 00 00 00  00 00 00 00 08 00 45 00\n00 28 00 00 40 00 40 06  B7 C0 C0 A8 01 64 08 08"
        )
    }
}

class PacketSnifferManager: ObservableObject {
    @Published var capturedPackets: [ModernCapturedPacket] = []
    @Published var totalBytesCapture: Int64 = 0
    @Published var isCapturing = false
    
    func startCapture(interface: String, filter: String) {
        isCapturing = true
        // Implementation would use tcpdump or similar
        simulatePacketCapture()
    }
    
    func stopCapture() {
        isCapturing = false
    }
    
    private func simulatePacketCapture() {
        // Simulate packet capture for demo
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            guard self.isCapturing else {
                timer.invalidate()
                return
            }
            
            let packet = ModernCapturedPacket(
                timestamp: Date(),
                sourceIP: "192.168.1.\(Int.random(in: 1...254))",
                destinationIP: ["8.8.8.8", "1.1.1.1", "142.250.185.46", "151.101.1.140"].randomElement()!,
                sourcePort: Int.random(in: 1024...65535),
                destPort: [80, 443, 53, 22, 21].randomElement()!,
                protocolName: ["TCP", "UDP", "ICMP", "HTTP", "DNS"].randomElement()!,
                length: Int.random(in: 64...1500),
                info: ["GET / HTTP/1.1", "TLS Application Data", "DNS Query", "SSH Encrypted"].randomElement()!,
                flags: ["SYN", "ACK", "PSH, ACK", "FIN, ACK"].randomElement()!,
                hexDump: "00 00 00 00 00 00 00 00  00 00 00 00 08 00 45 00"
            )
            
            DispatchQueue.main.async {
                self.capturedPackets.append(packet)
                self.totalBytesCapture += Int64(packet.length)
            }
        }
    }
}

#Preview {
    UltraModernPacketSniffer()
        .environment(AppState())
        .frame(width: 1200, height: 800)
}