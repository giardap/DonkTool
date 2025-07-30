//
//  UltraModernNetworkScanner.swift
//  DonkTool
//
//  Ultra-modern network scanner with stunning animations
//

import SwiftUI
import MapKit

struct UltraModernNetworkScanner: View {
    @Environment(AppState.self) private var appState
    @State private var scanTarget = ""
    @State private var selectedScanType = "comprehensive"
    @State private var isScanning = false
    @State private var showResults = false
    @State private var selectedTarget: Target?
    @State private var showTargetDetails = false
    @State private var animateRadar = false
    @State private var pulseAnimation = false
    
    let scanTypes = [
        ("quick", "Quick Scan", "bolt.fill", "Fast port scan"),
        ("comprehensive", "Full Scan", "shield.lefthalf.filled", "Complete analysis"),
        ("stealth", "Stealth Scan", "eye.slash.fill", "Undetectable scan"),
        ("aggressive", "Aggressive", "flame.fill", "Deep inspection")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xLarge) {
                // Header
                NetworkScannerHeader()
                    .fadeIn(delay: 0.1)
                
                // Scan Configuration
                ScanConfigurationSection(
                    scanTarget: $scanTarget,
                    selectedScanType: $selectedScanType,
                    scanTypes: scanTypes,
                    isScanning: isScanning,
                    startScan: startScan
                )
                .slideIn(from: .bottom, delay: 0.2)
                
                // Active Scan Visualization
                if isScanning {
                    ActiveScanVisualization()
                        .transition(.bounceIn)
                        .scaleIn(delay: 0.1)
                }
                
                // Discovered Targets
                if !appState.targets.isEmpty || showResults {
                    DiscoveredTargetsSection(
                        targets: appState.targets,
                        selectedTarget: $selectedTarget,
                        showTargetDetails: $showTargetDetails
                    )
                    .transition(.slideAndFade)
                    .fadeIn(delay: 0.3)
                }
                
                // Network Map
                if !appState.targets.isEmpty {
                    NetworkMapSection(targets: appState.targets)
                        .transition(.slideAndFade)
                        .scaleIn(delay: 0.4)
                }
            }
            .padding()
        }
        .background(Color.appPrimaryBackground)
        .sheet(isPresented: $showTargetDetails) {
            if let target = selectedTarget {
                TargetDetailsView(target: target)
            }
        }
        .attackExecutionSheet()
        .onChange(of: appState.isNetworkScanning) { _, newValue in
            if !newValue && isScanning {
                // Scan completed
                withAnimation(.smoothSpring) {
                    isScanning = false
                    showResults = true
                }
            }
        }
    }
    
    private func startScan() {
        guard !scanTarget.isEmpty else { return }
        
        withAnimation(.bounceSpring) {
            isScanning = true
            showResults = false
        }
        
        Task {
            await appState.performNetworkScan(target: scanTarget)
        }
    }
}

// MARK: - Header
struct NetworkScannerHeader: View {
    @State private var animateTitle = false
    
    var body: some View {
        VStack(spacing: Spacing.medium) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.primaryGradient)
                            .symbolEffect(.variableColor.iterative, value: animateTitle)
                        
                        Text("Network Scanner")
                            .font(Typography.largeTitle)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.primaryAccent, .secondaryAccent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    
                    Text("Discover and analyze network infrastructure")
                        .font(Typography.headline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(.horizontal)
        .onAppear {
            animateTitle = true
        }
    }
}

// MARK: - Scan Configuration
struct ScanConfigurationSection: View {
    @Binding var scanTarget: String
    @Binding var selectedScanType: String
    let scanTypes: [(String, String, String, String)]
    let isScanning: Bool
    let startScan: () -> Void
    
    @State private var isTargetValid = false
    
    var body: some View {
        VStack(spacing: Spacing.large) {
            // Target Input
            ModernCard {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    Label("Target Configuration", systemImage: "target")
                        .font(Typography.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: Spacing.medium) {
                        Image(systemName: "network")
                            .font(.title3)
                            .foregroundColor(.primaryAccent)
                        
                        TextField("Enter IP address or hostname", text: $scanTarget)
                            .textFieldStyle(.plain)
                            .font(.system(size: 16))
                            .onSubmit {
                                if isTargetValid && !isScanning {
                                    startScan()
                                }
                            }
                            .onChange(of: scanTarget) { _, newValue in
                                isTargetValid = validateTarget(newValue)
                            }
                        
                        if isTargetValid {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.successGreen)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding()
                    .background(Color.appSecondaryBackground)
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            
            // Scan Type Selection
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Scan Type")
                    .font(Typography.headline)
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.medium) {
                        ForEach(scanTypes, id: \.0) { type in
                            ScanTypeCard(
                                id: type.0,
                                title: type.1,
                                icon: type.2,
                                description: type.3,
                                isSelected: selectedScanType == type.0,
                                action: {
                                    withAnimation(Animations.spring) {
                                        selectedScanType = type.0
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Scan Button
            HStack {
                Spacer()
                
                ScanButton(
                    isScanning: isScanning,
                    isEnabled: isTargetValid && !isScanning,
                    action: startScan
                )
                
                Spacer()
            }
            .padding(.horizontal)
        }
    }
    
    private func validateTarget(_ target: String) -> Bool {
        // Simple validation - can be enhanced
        let ipPattern = #"^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$"#
        let hostnamePattern = #"^[a-zA-Z0-9][a-zA-Z0-9-_]*\.?[a-zA-Z0-9][a-zA-Z0-9-_]*\.?[a-zA-Z0-9]+$"#
        
        return target.range(of: ipPattern, options: .regularExpression) != nil ||
               target.range(of: hostnamePattern, options: .regularExpression) != nil
    }
}

struct ScanTypeCard: View {
    let id: String
    let title: String
    let icon: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.small) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            isSelected ?
                            LinearGradient(
                                colors: [Color.primaryAccent, Color.secondaryAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.cardBackground],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: icon)
                        .font(.system(size: 28))
                        .foregroundColor(isSelected ? .white : .primaryAccent)
                }
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 140, height: 140)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.clear : Color.gray.opacity(0.2),
                        lineWidth: 1
                    )
            )
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(Animations.spring, value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct ScanButton: View {
    let isScanning: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    @State private var animateGradient = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: isScanning ? 
                                [Color.warningOrange, Color.dangerRed] :
                                [Color.primaryAccent, Color.secondaryAccent],
                            startPoint: animateGradient ? .topLeading : .bottomTrailing,
                            endPoint: animateGradient ? .bottomTrailing : .topLeading
                        )
                    )
                    .frame(width: 200, height: 56)
                
                HStack(spacing: 12) {
                    if isScanning {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.title3)
                    }
                    
                    Text(isScanning ? "Scanning..." : "Start Scan")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
            }
            .shadow(color: Color.primaryAccent.opacity(0.3), radius: 12, x: 0, y: 6)
            .opacity(isEnabled ? 1.0 : 0.6)
            .scaleEffect(isEnabled ? 1.0 : 0.95)
            .animation(Animations.spring, value: isEnabled)
        }
        .disabled(!isEnabled)
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(Animation.linear(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
        .pressEffect()
    }
}

// MARK: - Active Scan Visualization
struct ActiveScanVisualization: View {
    @State private var radarRotation = 0.0
    @State private var pulseScale = 1.0
    @State private var discoveredHosts = 0
    @State private var showPulse = false
    
    var body: some View {
        ModernCard {
            VStack(spacing: Spacing.large) {
                Text("Scanning Network")
                    .font(Typography.title2)
                    .foregroundColor(.primary)
                
                // Radar Animation
                ZStack {
                    // Radar circles
                    ForEach(1...3, id: \.self) { ring in
                        Circle()
                            .stroke(Color.primaryAccent.opacity(0.2), lineWidth: 1)
                            .frame(width: CGFloat(ring * 60), height: CGFloat(ring * 60))
                            .scaleEffect(showPulse ? 1.1 : 1.0)
                            .opacity(showPulse ? 0.5 : 1.0)
                            .animation(
                                .easeInOut(duration: 2)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(ring) * 0.2),
                                value: showPulse
                            )
                    }
                    
                    // Radar sweep
                    Circle()
                        .trim(from: 0, to: 0.25)
                        .stroke(
                            LinearGradient(
                                colors: [Color.primaryAccent, Color.primaryAccent.opacity(0)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 80, lineCap: .round)
                        )
                        .frame(width: 180, height: 180)
                        .rotationEffect(.degrees(radarRotation))
                    
                    // Center dot
                    Circle()
                        .fill(Color.primaryAccent)
                        .frame(width: 12, height: 12)
                        .shadow(color: Color.primaryAccent, radius: 8)
                    
                    // Discovered hosts
                    ForEach(0..<discoveredHosts, id: \.self) { index in
                        Circle()
                            .fill(Color.successGreen)
                            .frame(width: 8, height: 8)
                            .position(randomPosition(for: index))
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: 200, height: 200)
                
                // Stats
                HStack(spacing: Spacing.xLarge) {
                    VStack {
                        Text("\(discoveredHosts)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primaryAccent)
                            .contentTransition(.numericText())
                            .animation(.smoothSpring, value: discoveredHosts)
                        Text("Hosts Found")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        Text("2,048")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primaryAccent)
                        Text("Ports Scanned")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        Text("45%")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primaryAccent)
                        Text("Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, Spacing.xLarge)
        }
        .padding(.horizontal)
        .onAppear {
            // Start radar animation
            withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
                radarRotation = 360
            }
            
            // Start pulse animation
            showPulse = true
            
            // Simulate discovering hosts
            Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { timer in
                withAnimation(.bounceSpring) {
                    if discoveredHosts < 5 {
                        discoveredHosts += 1
                    } else {
                        timer.invalidate()
                    }
                }
            }
        }
    }
    
    private func randomPosition(for index: Int) -> CGPoint {
        let angle = Double(index) * 72 * .pi / 180
        let radius = Double.random(in: 40...80)
        return CGPoint(
            x: 100 + radius * cos(angle),
            y: 100 + radius * sin(angle)
        )
    }
}

// MARK: - Discovered Targets
struct DiscoveredTargetsSection: View {
    let targets: [Target]
    @Binding var selectedTarget: Target?
    @Binding var showTargetDetails: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack {
                SectionHeader("Discovered Targets", subtitle: "\(targets.count) hosts found", icon: "server.rack")
                
                Spacer()
                
                Menu {
                    Button("Export CSV", action: {})
                    Button("Export JSON", action: {})
                    Button("Generate Report", action: {})
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                        .font(.subheadline)
                }
                .menuStyle(.borderlessButton)
            }
            .padding(.horizontal)
            
            ScrollView {
                LazyVStack(spacing: Spacing.small) {
                    ForEach(targets) { target in
                        TargetCard(target: target) {
                            selectedTarget = target
                            showTargetDetails = true
                        }
                        .transition(.asymmetric(
                            insertion: .slide.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                    }
                }
                .padding(.horizontal)
            }
            .frame(maxHeight: 400)
        }
    }
}

struct TargetCard: View {
    let target: Target
    let action: () -> Void
    
    @State private var isHovered = false
    @State private var showPorts = false
    
    var vulnerabilityColor: Color {
        let criticalCount = target.vulnerabilities.filter { $0.severity == .critical }.count
        let highCount = target.vulnerabilities.filter { $0.severity == .high }.count
        
        if criticalCount > 0 { return .dangerRed }
        if highCount > 0 { return .warningOrange }
        if !target.vulnerabilities.isEmpty { return .yellow }
        return .successGreen
    }
    
    var body: some View {
        Button(action: action) {
            ModernCard {
                VStack(spacing: Spacing.medium) {
                    // Header
                    HStack {
                        // Status indicator
                        Circle()
                            .fill(vulnerabilityColor)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(vulnerabilityColor.opacity(0.3), lineWidth: 8)
                                    .blur(radius: 4)
                            )
                        
                        // Target info
                        VStack(alignment: .leading, spacing: 4) {
                            Text(target.ipAddress)
                                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                .foregroundColor(.primary)
                            
                            if let hostname = target.hostname {
                                Text(hostname)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // Stats
                        HStack(spacing: Spacing.medium) {
                            StatChip(
                                value: "\(target.openPorts.count)",
                                label: "Ports",
                                color: .primaryAccent
                            )
                            
                            StatChip(
                                value: "\(target.vulnerabilities.count)",
                                label: "Vulns",
                                color: vulnerabilityColor
                            )
                        }
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .rotationEffect(.degrees(showPorts ? 90 : 0))
                    }
                    
                    // Expandable ports section
                    if showPorts && !target.openPorts.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.xSmall) {
                            Text("Open Ports")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(target.openPorts, id: \.self) { port in
                                    PortChip(port: port)
                                }
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .push(from: .top).combined(with: .opacity),
                            removal: .push(from: .bottom).combined(with: .opacity)
                        ))
                    }
                }
            }
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(Animations.spring, value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation {
                isHovered = hovering
                if hovering {
                    showPorts = true
                } else {
                    showPorts = false
                }
            }
        }
    }
}

struct StatChip: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct PortChip: View {
    let port: Port
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.successGreen)
                .frame(width: 6, height: 6)
            
            Text("\(port.number)")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
            
            if let service = port.service {
                Text("(\(service))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.appSecondaryBackground)
        .cornerRadius(12)
    }
}

// MARK: - Network Map
struct NetworkMapSection: View {
    let targets: [Target]
    @State private var selectedMapTarget: Target?
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            SectionHeader("Network Topology", subtitle: "Visual network representation", icon: "map")
                .padding(.horizontal)
            
            ModernCard {
                NetworkTopologyView(targets: targets, selectedTarget: $selectedMapTarget)
                    .frame(height: 300)
            }
            .padding(.horizontal)
        }
    }
}

struct NetworkTopologyView: View {
    let targets: [Target]
    @Binding var selectedTarget: Target?
    
    @State private var nodePositions: [UUID: CGPoint] = [:]
    @State private var animateConnections = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Grid background
                GridPattern()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                
                // Connections
                ForEach(targets, id: \.id) { target in
                    if let position = nodePositions[target.id] {
                        Path { path in
                            path.move(to: CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2))
                            path.addLine(to: position)
                        }
                        .stroke(
                            LinearGradient(
                                colors: [Color.primaryAccent.opacity(0.3), Color.primaryAccent.opacity(0.1)],
                                startPoint: .center,
                                endPoint: .trailing
                            ),
                            lineWidth: 2
                        )
                        .opacity(animateConnections ? 1 : 0)
                        .animation(
                            .easeInOut(duration: 0.5)
                            .delay(Double(targets.firstIndex(where: { $0.id == target.id }) ?? 0) * 0.1),
                            value: animateConnections
                        )
                    }
                }
                
                // Central router
                ZStack {
                    Circle()
                        .fill(Color.primaryAccent)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "wifi.router")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                .shadow(color: Color.primaryAccent.opacity(0.5), radius: 12)
                
                // Target nodes
                ForEach(targets, id: \.id) { target in
                    if let position = nodePositions[target.id] {
                        NetworkNode(target: target, isSelected: selectedTarget?.id == target.id)
                            .position(position)
                            .onTapGesture {
                                withAnimation(.spring()) {
                                    selectedTarget = target
                                }
                            }
                            .opacity(animateConnections ? 1 : 0)
                            .scaleEffect(animateConnections ? 1 : 0.5)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.7)
                                .delay(Double(targets.firstIndex(where: { $0.id == target.id }) ?? 0) * 0.1),
                                value: animateConnections
                            )
                    }
                }
            }
            .onAppear {
                calculateNodePositions(in: geometry.size)
                withAnimation {
                    animateConnections = true
                }
            }
        }
    }
    
    private func calculateNodePositions(in size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) * 0.35
        
        for (index, target) in targets.enumerated() {
            let angle = (2 * .pi / Double(targets.count)) * Double(index)
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            nodePositions[target.id] = CGPoint(x: x, y: y)
        }
    }
}

struct NetworkNode: View {
    let target: Target
    let isSelected: Bool
    
    var nodeColor: Color {
        let criticalCount = target.vulnerabilities.filter { $0.severity == .critical }.count
        if criticalCount > 0 { return .dangerRed }
        if !target.vulnerabilities.isEmpty { return .warningOrange }
        return .successGreen
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(nodeColor)
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(nodeColor.opacity(0.3), lineWidth: isSelected ? 12 : 0)
                        .blur(radius: 4)
                )
            
            Image(systemName: "desktopcomputer")
                .font(.system(size: 16))
                .foregroundColor(.white)
        }
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .animation(.spring(), value: isSelected)
    }
}

struct GridPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let gridSize: CGFloat = 20
        
        // Vertical lines
        for x in stride(from: 0, through: rect.width, by: gridSize) {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
        }
        
        // Horizontal lines
        for y in stride(from: 0, through: rect.height, by: gridSize) {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
        }
        
        return path
    }
}

// MARK: - Target Details View
struct TargetDetailsView: View {
    let target: Target
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Target Details")
                        .font(Typography.title2)
                    
                    Text(target.ipAddress)
                        .font(.system(size: 16, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
            .padding()
            .background(Color.appSecondaryBackground)
            
            ScrollView {
                VStack(spacing: Spacing.large) {
                    // Target Overview
                    TargetOverviewSection(target: target)
                    
                    // Open Ports
                    OpenPortsSection(target: target)
                    
                    // Vulnerabilities
                    if !target.vulnerabilities.isEmpty {
                        VulnerabilitiesSection(vulnerabilities: target.vulnerabilities)
                    }
                    
                    // Attack Options
                    AttackOptionsSection(target: target)
                }
                .padding()
            }
        }
        .frame(width: 800, height: 600)
        .background(Color.appPrimaryBackground)
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: ProposedViewSize(frame.size))
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            var maxX: CGFloat = 0
            
            for subview in subviews {
                let viewSize = subview.sizeThatFits(.unspecified)
                
                if currentX + viewSize.width > maxWidth, currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(origin: CGPoint(x: currentX, y: currentY), size: viewSize))
                lineHeight = max(lineHeight, viewSize.height)
                currentX += viewSize.width + spacing
                maxX = max(maxX, currentX)
            }
            
            size = CGSize(width: maxX - spacing, height: currentY + lineHeight)
        }
    }
}

// MARK: - Target Details Sections

struct TargetOverviewSection: View {
    let target: Target
    
    var body: some View {
        ModernCard {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                SectionHeader("Target Overview", icon: "info.circle.fill")
                
                HStack(spacing: Spacing.xLarge) {
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        TargetInfoRow(label: "IP Address", value: target.ipAddress, isMonospaced: true)
                        TargetInfoRow(label: "Hostname", value: target.hostname ?? "Unknown")
                        TargetInfoRow(label: "Domain", value: target.domain ?? "N/A")
                    }
                    
                    Spacer()
                    
                    // Risk Assessment
                    RiskAssessmentCard(target: target)
                }
            }
        }
    }
}

struct TargetInfoRow: View {
    let label: String
    let value: String
    var isMonospaced: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(isMonospaced ? .system(size: 14, design: .monospaced) : .system(size: 14))
                .foregroundColor(.primary)
                .textSelection(.enabled)
        }
    }
}

struct RiskAssessmentCard: View {
    let target: Target
    
    var riskLevel: String {
        let criticalCount = target.vulnerabilities.filter { $0.severity == .critical }.count
        let highCount = target.vulnerabilities.filter { $0.severity == .high }.count
        
        if criticalCount > 0 { return "Critical" }
        if highCount > 0 { return "High" }
        if !target.vulnerabilities.isEmpty { return "Medium" }
        return "Low"
    }
    
    var riskColor: Color {
        switch riskLevel {
        case "Critical": return .dangerRed
        case "High": return .warningOrange
        case "Medium": return .yellow
        default: return .successGreen
        }
    }
    
    var body: some View {
        VStack(spacing: Spacing.small) {
            Text("Risk Level")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(riskLevel)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(riskColor)
            
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.caption)
                Text("\(target.vulnerabilities.count) issues")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
        }
        .padding()
        .background(riskColor.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(riskColor.opacity(0.3), lineWidth: 1)
        )
    }
}

struct OpenPortsSection: View {
    let target: Target
    @State private var selectedPort: Port?
    @Environment(AppState.self) private var appState
    
    var body: some View {
        ModernCard {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                SectionHeader("Open Ports", subtitle: "\(target.openPorts.count) ports discovered", icon: "network")
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: Spacing.medium) {
                    ForEach(target.openPorts) { port in
                        PortDetailCard(port: port, isSelected: selectedPort?.id == port.id) {
                            selectedPort = port
                        }
                    }
                }
            }
        }
    }
}

struct PortDetailCard: View {
    let port: Port
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var portCategoryColor: Color {
        switch port.number {
        case 22: return .warningOrange // SSH
        case 80, 443, 8080, 8443: return .tertiaryAccent // Web
        case 21: return .dangerRed // FTP
        case 23: return .dangerRed // Telnet
        case 3306: return .yellow // MySQL
        case 5432: return .yellow // PostgreSQL
        default: return .primaryAccent
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.medium) {
                ZStack {
                    Circle()
                        .fill(portCategoryColor.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Text("\(port.number)")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(portCategoryColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(port.service ?? "Unknown Service")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("TCP • \(port.state.rawValue.capitalized)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(isSelected ? 90 : 0))
            }
            .padding()
            .background(isHovered ? portCategoryColor.opacity(0.05) : Color.clear)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? portCategoryColor : Color.gray.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(Animations.quick, value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct VulnerabilitiesSection: View {
    let vulnerabilities: [Vulnerability]
    @State private var expandedVuln: UUID?
    
    var body: some View {
        ModernCard {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                SectionHeader("Discovered Vulnerabilities", icon: "exclamationmark.triangle.fill")
                
                VStack(spacing: Spacing.small) {
                    ForEach(vulnerabilities) { vuln in
                        VulnerabilityDetailCard(
                            vulnerability: vuln,
                            isExpanded: expandedVuln == vuln.id
                        ) {
                            withAnimation(.spring()) {
                                expandedVuln = expandedVuln == vuln.id ? nil : vuln.id
                            }
                        }
                    }
                }
            }
        }
    }
}

struct VulnerabilityDetailCard: View {
    let vulnerability: Vulnerability
    let isExpanded: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                HStack {
                    Circle()
                        .fill(vulnerability.severity.color)
                        .frame(width: 8, height: 8)
                    
                    Text(vulnerability.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if let cve = vulnerability.cveId {
                        Text(cve)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.secondaryText.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                
                if isExpanded {
                    Text(vulnerability.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.asymmetric(
                            insertion: .push(from: .top).combined(with: .opacity),
                            removal: .push(from: .bottom).combined(with: .opacity)
                        ))
                }
            }
            .padding()
            .background(Color.appSecondaryBackground)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct AttackOptionsSection: View {
    let target: Target
    @Environment(AppState.self) private var appState
    @State private var showingAttackConfig = false
    @State private var selectedAttack: AttackVector?
    
    let commonAttacks = [
        ("Port Scan", "antenna.radiowaves.left.and.right", "Comprehensive port discovery"),
        ("Service Enumeration", "server.rack", "Identify running services"),
        ("Vulnerability Scan", "exclamationmark.shield", "Check for known vulnerabilities"),
        ("Brute Force", "key.fill", "Test weak credentials"),
        ("Web Application Scan", "globe", "Test web vulnerabilities"),
        ("Exploit Suggestion", "hammer.fill", "Find applicable exploits")
    ]
    
    var body: some View {
        ModernCard {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                SectionHeader("Attack Options", subtitle: "Available security tests", icon: "shield.lefthalf.filled")
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: Spacing.medium) {
                    ForEach(commonAttacks, id: \.0) { attack in
                        AttackOptionCard(
                            title: attack.0,
                            icon: attack.1,
                            description: attack.2
                        ) {
                            executeAttack(type: attack.0)
                        }
                    }
                }
                
                Divider()
                    .padding(.vertical, Spacing.small)
                
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.warningOrange)
                    
                    Text("Only perform attacks on systems you own or have permission to test")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.warningOrange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .sheet(isPresented: $showingAttackConfig) {
            if let attack = selectedAttack {
                AttackConfigSheet(attack: attack, target: target)
            }
        }
    }
    
    private func executeAttack(type: String) {
        // Create attack vector based on type
        let attack = AttackVector(
            name: type,
            description: "Execute \(type) on \(target.ipAddress)",
            severity: .medium,
            requirements: [],
            commands: generateCommands(for: type),
            references: []
        )
        
        selectedAttack = attack
        showingAttackConfig = true
    }
    
    private func generateCommands(for attackType: String) -> [String] {
        switch attackType {
        case "Port Scan":
            return ["nmap -sS -sV -O TARGET"]
        case "Service Enumeration":
            return ["nmap -sV --script=default TARGET"]
        case "Vulnerability Scan":
            return ["nmap --script vuln TARGET"]
        case "Brute Force":
            return ["hydra -L users.txt -P passwords.txt TARGET ssh"]
        case "Web Application Scan":
            return ["nikto -h http://TARGET", "dirb http://TARGET"]
        case "Exploit Suggestion":
            return ["searchsploit TARGET", "msfconsole -q -x 'search TARGET'"]
        default:
            return ["echo 'No command defined for \(attackType)'"]
        }
    }
}

struct AttackOptionCard: View {
    let title: String
    let icon: String
    let description: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.small) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.primaryAccent)
                    .frame(height: 30)
                
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isHovered ? Color.primaryAccent.opacity(0.05) : Color.appSecondaryBackground)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isHovered ? Color.primaryAccent.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(Animations.spring, value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct AttackConfigSheet: View {
    let attack: AttackVector
    let target: Target
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var showingAttackProgress = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Configure Attack")
                        .font(Typography.title2)
                    
                    Text("\(attack.name) on \(target.ipAddress)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
            .padding()
            .background(Color.appSecondaryBackground)
            
            ScrollView {
                VStack(spacing: Spacing.large) {
                    // Attack details and configuration
                    ModernCard {
                        VStack(alignment: .leading, spacing: Spacing.medium) {
                            Text("Commands to Execute")
                                .font(.headline)
                            
                            ForEach(attack.commands, id: \.self) { command in
                                Text(command.replacingOccurrences(of: "TARGET", with: target.ipAddress))
                                    .font(.system(size: 12, design: .monospaced))
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.codeSurface)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
            }
            
            // Execute button
            HStack {
                Spacer()
                
                GradientButton("Execute Attack", icon: "play.fill") {
                    showingAttackProgress = true
                }
            }
            .padding()
            .background(Color.appSecondaryBackground)
        }
        .frame(width: 600, height: 500)
        .background(Color.appPrimaryBackground)
        .sheet(isPresented: $showingAttackProgress) {
            NetworkAttackProgressView(
                attack: attack,
                target: target.ipAddress,
                port: 0
            )
        }
    }
}

// MARK: - Network Attack Progress View
struct NetworkAttackProgressView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    
    let attack: AttackVector
    let target: String
    let port: Int
    
    @State private var output: [String] = []
    @State private var isRunning = true
    @State private var progress: Double = 0.0
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(attack.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 12) {
                            Label(target, systemImage: "network")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if port > 0 {
                                Label("Port \(port)", systemImage: "number.circle")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if isRunning {
                                HStack(spacing: 4) {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                    Text("Running...")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            } else {
                                Label("Completed", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Button("Close") {
                        dismiss()
                    }
                    .keyboardShortcut(.escape)
                }
                .padding()
                
                // Progress Bar
                VStack(spacing: 4) {
                    HStack {
                        Text("Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(formatDuration(elapsedTime))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .tint(Color.primaryAccent)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .background(Color.appSecondaryBackground)
            
            Divider()
            
            // Output Terminal
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(output.enumerated()), id: \.offset) { index, line in
                            NetworkOutputLine(text: line)
                                .id(index)
                        }
                        
                        if output.isEmpty && isRunning {
                            Text("Initializing \(attack.name)...")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
                .background(Color.black.opacity(0.9))
                .onChange(of: output.count) { oldValue, newValue in
                    // Auto-scroll to bottom when new output arrives
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(output.count - 1, anchor: .bottom)
                    }
                }
            }
            
            // Action Bar
            HStack {
                if isRunning {
                    Button(action: stopAttack) {
                        Label("Stop Attack", systemImage: "stop.circle.fill")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
                Button(action: copyOutput) {
                    Label("Copy Output", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
                
                Button(action: exportOutput) {
                    Label("Export", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color.appSecondaryBackground)
        }
        .frame(width: 800, height: 600)
        .onAppear {
            startAttack()
            startTimer()
        }
        .onDisappear {
            stopTimer()
            // Clear the callback
            appState.attackFramework.setRealTimeOutputCallback { _ in }
        }
    }
    
    private func startAttack() {
        // Set up real-time output callback
        appState.attackFramework.setRealTimeOutputCallback { line in
            DispatchQueue.main.async {
                self.output.append(line)
                
                // Update progress based on output
                self.updateProgress(from: line)
            }
        }
        
        // Execute the attack
        Task {
            await appState.attackFramework.executeAttack(
                attack,
                target: target,
                port: port
            )
            
            await MainActor.run {
                self.isRunning = false
                self.progress = 1.0
                self.output.append("")
                self.output.append("═══ Attack Completed ═══")
                self.stopTimer()
            }
        }
    }
    
    private func stopAttack() {
        // TODO: Implement attack cancellation
        isRunning = false
        output.append("")
        output.append("═══ Attack Stopped by User ═══")
        stopTimer()
    }
    
    private func updateProgress(from line: String) {
        // Update progress based on certain keywords in output
        if line.contains("Phase") || line.contains("Step") {
            // Increment progress for each phase
            progress = min(progress + 0.1, 0.9)
        } else if line.contains("completed") || line.contains("finished") {
            progress = 1.0
        } else if line.contains("%") {
            // Extract percentage if present
            if let match = line.firstMatch(of: /(\d+)%/) {
                if let percent = Double(match.1) {
                    progress = percent / 100.0
                }
            }
        }
    }
    
    private func copyOutput() {
        let fullOutput = output.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(fullOutput, forType: .string)
    }
    
    private func exportOutput() {
        let fullOutput = output.joined(separator: "\n")
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let filename = "\(attack.name.replacingOccurrences(of: " ", with: "_"))_\(target)_\(timestamp).txt"
        
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = filename
        savePanel.allowedContentTypes = [.plainText]
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            do {
                try fullOutput.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                print("Failed to save output: \(error)")
            }
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedTime += 1
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: seconds) ?? "0s"
    }
}

struct NetworkOutputLine: View {
    let text: String
    
    var textColor: Color {
        if text.hasPrefix("❌") || text.contains("Error") || text.contains("Failed") {
            return .red
        } else if text.hasPrefix("✅") || text.contains("Success") || text.contains("Found") {
            return .green
        } else if text.hasPrefix("⚠️") || text.contains("Warning") {
            return .yellow
        } else if text.hasPrefix("🔍") || text.hasPrefix("===") || text.hasPrefix("Phase") {
            return .cyan
        } else if text.hasPrefix("$") {
            return .mint
        } else if text.contains("VULNERABLE") || text.contains("Critical") {
            return .orange
        } else if text.contains("open") || text.contains("Open") {
            return .tertiaryAccent
        } else {
            return .white
        }
    }
    
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .regular, design: .monospaced))
            .foregroundColor(textColor)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    UltraModernNetworkScanner()
        .environment(AppState())
        .frame(width: 1200, height: 800)
}