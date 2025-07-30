//
//  UnifiedSecurityScanner.swift
//  DonkTool
//
//  Ultra-Modern Unified Security Scanner with stunning animations
//  Matches UltraModernNetworkScanner quality with combined Network & Web testing
//

import SwiftUI
import MapKit

struct UnifiedSecurityScanner: View {
    @Environment(AppState.self) private var appState
    @State private var scanTarget = ""
    @State private var selectedScanType = "comprehensive"
    @State private var selectedMode: ScanMode = .combined
    @State private var selectedNetworkTools: Set<String> = Set([
        "Port Scan", "Service Detection", "OS Detection", "Vulnerability Scripts", 
        "UDP Scan", "Stealth Scan", "Version Detection", "Script Scan"
    ])
    @State private var selectedWebTools: Set<String> = Set([
        "SQL Injection", "Web Vulnerability Scan", "Nuclei Template Scan",
        "Directory Enumeration", "Advanced Directory Fuzzing", "XSS Detection",
        "OWASP ZAP Scan", "HTTP/HTTPS Analysis", "SSL/TLS Analysis",
        "HTTP Header Security", "Basic SSL Check", "Subdomain Enumeration"
    ])
    @State private var isScanning = false
    @State private var showResults = false
    @State private var selectedTarget: Target?
    @State private var showTargetDetails = false
    @State private var animateRadar = false
    @State private var pulseAnimation = false
    @State private var scanProgress: Double = 0.0
    @State private var currentScanPhase = ""
    @State private var showAdvancedOptions = false
    
    enum ScanMode: String, CaseIterable {
        case network = "Network"
        case web = "Web"
        case combined = "Combined"
        
        var icon: String {
            switch self {
            case .network: return "antenna.radiowaves.left.and.right"
            case .web: return "globe.badge.chevron.backward"
            case .combined: return "network.badge.shield.half.filled"
            }
        }
        
        var description: String {
            switch self {
            case .network: return "Advanced network reconnaissance and port scanning"
            case .web: return "Comprehensive web application security testing"
            case .combined: return "Complete infrastructure and application assessment"
            }
        }
        
        var gradient: LinearGradient {
            switch self {
            case .network:
                return LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .web:
                return LinearGradient(colors: [.green, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .combined:
                return LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
    }
    
    let scanTypes = [
        ("quick", "Quick Scan", "bolt.fill", "Fast reconnaissance"),
        ("comprehensive", "Full Scan", "shield.lefthalf.filled", "Complete analysis"),
        ("stealth", "Stealth Scan", "eye.slash.fill", "Undetectable scan"),
        ("aggressive", "Aggressive", "flame.fill", "Deep inspection")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xLarge) {
                // Ultra-Modern Header with Animations
                UltraModernSecurityHeader()
                    .fadeIn(delay: 0.1)
                
                // Advanced Mode Selection with Gradients
                UltraModernModeSelector(selectedMode: $selectedMode)
                    .slideIn(from: .leading, delay: 0.2)
                
                // Premium Target Configuration
                UltraModernTargetConfiguration(
                    scanTarget: $scanTarget,
                    selectedScanType: $selectedScanType,
                    scanTypes: scanTypes,
                    isScanning: isScanning,
                    showAdvancedOptions: $showAdvancedOptions,
                    startScan: startUltraModernScan
                )
                .slideIn(from: .bottom, delay: 0.3)
                
                // Advanced Tool Arsenal
                if selectedMode == .network || selectedMode == .combined {
                    UltraModernNetworkToolsArsenal(selectedTools: $selectedNetworkTools)
                        .transition(.asymmetric(insertion: .slide.combined(with: .opacity), removal: .opacity))
                        .fadeIn(delay: 0.4)
                }
                
                if selectedMode == .web || selectedMode == .combined {
                    UltraModernWebToolsArsenal(selectedTools: $selectedWebTools)
                        .transition(.asymmetric(insertion: .slide.combined(with: .opacity), removal: .opacity))
                        .fadeIn(delay: 0.5)
                }
                
                // Stunning Active Scan Visualization
                if isScanning {
                    UnifiedScanVisualization(
                        mode: selectedMode,
                        target: scanTarget
                    )
                    .scaleIn(delay: 0.1)
                }
                
                // Premium Results Display
                if !appState.targets.isEmpty || !appState.webScanResults.isEmpty || showResults {
                    UnifiedResultsSection(
                        targets: appState.targets,
                        webResults: appState.webScanResults,
                        selectedTarget: $selectedTarget,
                        showTargetDetails: $showTargetDetails
                    )
                    .fadeIn(delay: 0.6)
                }
                
                // Network Topology Map (when available)
                if !appState.targets.isEmpty && appState.targets.count > 1 {
                    Text("Network Topology Visualization")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding()
                        .scaleIn(delay: 0.7)
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
        .sheet(isPresented: Binding(
            get: { appState.showExecutionDialog },
            set: { appState.showExecutionDialog = $0 }
        )) {
            if let attackVector = appState.currentAttackVector {
                AttackExecutionView(
                    attackVector: attackVector,
                    target: appState.currentAttackTarget,
                    port: appState.currentAttackPort
                )
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
        .onChange(of: appState.isNetworkScanning) { _, newValue in
            updateScanningState(newValue)
        }
        .onChange(of: appState.isWebScanning) { _, newValue in
            updateScanningState(newValue)
        }
        .onChange(of: appState.networkScanProgress) { _, progress in
            withAnimation(.smooth) {
                scanProgress = max(scanProgress, progress)
            }
        }
        .onChange(of: appState.webScanProgress) { _, progress in
            withAnimation(.smooth) {
                scanProgress = max(scanProgress, progress)
            }
        }
        .onChange(of: appState.toolExecutionStatus) { _, status in
            currentScanPhase = status
        }
    }
    
    private func startUltraModernScan() {
        guard !scanTarget.isEmpty else { return }
        
        withAnimation(.bounceSpring) {
            isScanning = true
            showResults = false
            scanProgress = 0.0
            animateRadar = true
        }
        
        Task {
            switch selectedMode {
            case .network:
                await appState.performNetworkScan(target: scanTarget)
            case .web:
                let webTarget = scanTarget.hasPrefix("http") ? scanTarget : "https://\(scanTarget)"
                appState.startWebScan(targetURL: webTarget, selectedTools: Array(selectedWebTools))
            case .combined:
                // Combined scan: Network first, then Web
                currentScanPhase = "Phase 1: Network Reconnaissance"
                await appState.performNetworkScan(target: scanTarget)
                
                currentScanPhase = "Phase 2: Web Application Testing"
                let webTarget = scanTarget.hasPrefix("http") ? scanTarget : "https://\(scanTarget)"
                appState.startWebScan(targetURL: webTarget, selectedTools: Array(selectedWebTools))
            }
        }
    }
    
    private func updateScanningState(_ newValue: Bool) {
        if !newValue && isScanning {
            withAnimation(.smoothSpring) {
                isScanning = false
                showResults = true
                animateRadar = false
                scanProgress = 1.0
                currentScanPhase = "Scan Complete"
            }
        }
    }
}

// MARK: - Ultra-Modern Components

struct UltraModernSecurityHeader: View {
    @State private var animateTitle = false
    @State private var shimmerPhase: CGFloat = 0
    
    var body: some View {
        VStack(spacing: Spacing.medium) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        ZStack {
                            // Animated icon with multiple effects
                            Image(systemName: "network.badge.shield.half.filled")
                                .font(.system(size: 36))
                                .foregroundStyle(
                                    AngularGradient(
                                        colors: [.primaryAccent, .secondaryAccent, .blue, .purple, .primaryAccent],
                                        center: .center,
                                        angle: .degrees(shimmerPhase)
                                    )
                                )
                                .symbolEffect(.variableColor.iterative, value: animateTitle)
                                .shadow(color: .primaryAccent.opacity(0.5), radius: 10)
                            
                            // Pulse ring effect
                            Circle()
                                .stroke(Color.primaryAccent.opacity(0.3), lineWidth: 2)
                                .frame(width: 60, height: 60)
                                .scaleEffect(animateTitle ? 1.2 : 1.0)
                                .opacity(animateTitle ? 0 : 1)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Security Scanner")
                                .font(Typography.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.primaryAccent, .secondaryAccent, .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .overlay(
                                    // Shimmer effect
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                colors: [.clear, .white.opacity(0.3), .clear],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .rotationEffect(.degrees(45))
                                        .offset(x: shimmerPhase * 200 - 100)
                                        .clipped()
                                )
                            
                            Text("Ultra-modern unified security testing platform")
                                .font(Typography.headline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Feature badges
                    HStack(spacing: 8) {
                        FeatureBadge(text: "Real Tools", color: .green)
                        FeatureBadge(text: "AI Enhanced", color: .blue)
                        FeatureBadge(text: "Enterprise", color: .purple)
                    }
                }
                
                Spacer()
                
                // Status indicators
                VStack(spacing: 8) {
                    SecurityStatusIndicator(title: "Network Tools", count: 15, color: .blue)
                    SecurityStatusIndicator(title: "Web Tools", count: 12, color: .green)
                    SecurityStatusIndicator(title: "Exploits", count: 50, color: .red)
                }
            }
        }
        .padding(.horizontal)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animateTitle = true
                shimmerPhase = 1.0
            }
        }
    }
}

struct FeatureBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color.opacity(0.4), lineWidth: 1)
            )
    }
}

struct SecurityStatusIndicator: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Mode Selector Component
struct UltraModernModeSelector: View {
    @Binding var selectedMode: UnifiedSecurityScanner.ScanMode
    @State private var hoverMode: UnifiedSecurityScanner.ScanMode?
    
    var body: some View {
        ModernCard {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Label("Scan Mode", systemImage: "slider.horizontal.3")
                    .font(Typography.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: Spacing.medium) {
                    ForEach(UnifiedSecurityScanner.ScanMode.allCases, id: \.self) { mode in
                        UltraModernModeCard(
                            mode: mode,
                            isSelected: selectedMode == mode,
                            isHovered: hoverMode == mode,
                            action: {
                                withAnimation(.smoothSpring) {
                                    selectedMode = mode
                                }
                            }
                        )
                        .onHover { hovering in
                            withAnimation(.quickEaseInOut) {
                                hoverMode = hovering ? mode : nil
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

struct UltraModernModeCard: View {
    let mode: UnifiedSecurityScanner.ScanMode
    let isSelected: Bool
    let isHovered: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    // Background glow effect
                    RoundedRectangle(cornerRadius: 16)
                        .fill(mode.gradient)
                        .opacity(isSelected ? 0.3 : (isHovered ? 0.2 : 0.1))
                        .blur(radius: isSelected ? 8 : 4)
                    
                    // Main card
                    VStack(spacing: 8) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 32))
                            .foregroundStyle(isSelected ? mode.gradient : LinearGradient(colors: [.secondary], startPoint: .top, endPoint: .bottom))
                            .symbolEffect(.bounce, value: isSelected)
                        
                        VStack(spacing: 4) {
                            Text(mode.rawValue)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(isSelected ? .primary : .secondary)
                            
                            Text(mode.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(isSelected ? mode.gradient : LinearGradient(colors: [.borderPrimary], startPoint: .top, endPoint: .bottom), lineWidth: isSelected ? 2 : 1)
                            )
                    )
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : (isHovered ? 1.02 : 1.0))
        .animation(.smoothSpring, value: isSelected)
        .animation(.quickEaseInOut, value: isHovered)
    }
}

// MARK: - Target Configuration Component
struct UltraModernTargetConfiguration: View {
    @Binding var scanTarget: String
    @Binding var selectedScanType: String
    let scanTypes: [(String, String, String, String)]
    let isScanning: Bool
    @Binding var showAdvancedOptions: Bool
    let startScan: () -> Void
    
    @State private var isHovered = false
    @State private var pulseAnimation = false
    
    var body: some View {
        ModernCard {
            VStack(alignment: .leading, spacing: Spacing.large) {
                Label("Target Configuration", systemImage: "target")
                    .font(Typography.headline)
                    .foregroundColor(.primary)
                
                // Ultra-modern target input with glow effects
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target")
                        .font(Typography.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        ZStack {
                            // Glow background
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.primaryAccent.opacity(0.1))
                                .blur(radius: isHovered ? 8 : 4)
                                .opacity(isHovered ? 1 : 0)
                            
                            TextField("IP address, domain, or URL (e.g., 192.168.1.1, example.com)", text: $scanTarget)
                                .textFieldStyle(.plain)
                                .font(.system(.body, design: .monospaced))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.cardBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    LinearGradient(
                                                        colors: isHovered ? [.primaryAccent.opacity(0.5), .secondaryAccent.opacity(0.3)] : [.borderPrimary],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: isHovered ? 2 : 1
                                                )
                                        )
                                )
                                .disabled(isScanning)
                        }
                        .onHover { hovering in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isHovered = hovering
                            }
                        }
                        
                        // Ultra-modern scan button
                        Button(action: startScan) {
                            HStack(spacing: 8) {
                                ZStack {
                                    if isScanning {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Image(systemName: "play.circle.fill")
                                            .font(.title2)
                                            .symbolEffect(.bounce, value: !scanTarget.isEmpty)
                                    }
                                }
                                
                                Text(isScanning ? "Scanning" : "Start Scan")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                ZStack {
                                    // Pulse background for scanning
                                    if isScanning {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.primaryAccent.opacity(0.3))
                                            .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                                            .blur(radius: 8)
                                    }
                                    
                                    // Main button background
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                colors: scanTarget.isEmpty ? [.gray.opacity(0.5)] : [.primaryAccent, .secondaryAccent],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: .primaryAccent.opacity(0.3), radius: scanTarget.isEmpty ? 0 : 8)
                                }
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(scanTarget.isEmpty)
                        .scaleEffect(scanTarget.isEmpty ? 0.95 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: scanTarget.isEmpty)
                    }
                }
                
                // Ultra-modern scan type selector with gradients
                VStack(alignment: .leading, spacing: 12) {
                    Text("Scan Intensity")
                        .font(Typography.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        ForEach(scanTypes, id: \.0) { type, name, icon, description in
                            UltraModernScanTypeCard(
                                type: type,
                                name: name,
                                icon: icon,
                                description: description,
                                isSelected: selectedScanType == type,
                                action: {
                                    withAnimation(.smoothSpring) {
                                        selectedScanType = type
                                    }
                                }
                            )
                        }
                    }
                }
                
                // Advanced options toggle
                Button(action: {
                    withAnimation(.smoothSpring) {
                        showAdvancedOptions.toggle()
                    }
                }) {
                    HStack {
                        Image(systemName: "gearshape.2.fill")
                            .foregroundColor(.primaryAccent)
                        
                        Text("Advanced Options")
                            .font(.subheadline)
                            .foregroundColor(.primaryAccent)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.primaryAccent)
                            .rotationEffect(.degrees(showAdvancedOptions ? 180 : 0))
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .onAppear {
            if isScanning {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    pulseAnimation = true
                }
            }
        }
        .onChange(of: isScanning) { _, newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    pulseAnimation = true
                }
            } else {
                pulseAnimation = false
            }
        }
    }
}

struct UltraModernScanTypeCard: View {
    let type: String
    let name: String
    let icon: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var cardColor: Color {
        switch type {
        case "quick": return .green
        case "comprehensive": return .blue
        case "stealth": return .purple
        case "aggressive": return .red
        default: return .primaryAccent
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(cardColor.opacity(0.3))
                        .frame(width: 40, height: 40)
                        .blur(radius: isSelected ? 8 : 4)
                        .opacity(isSelected ? 1 : 0)
                    
                    // Icon background
                    Circle()
                        .fill(
                            isSelected ? 
                            LinearGradient(colors: [cardColor, cardColor.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                            LinearGradient(colors: [.cardBackground], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? cardColor : .borderPrimary, lineWidth: isSelected ? 2 : 1)
                        )
                    
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(isSelected ? .white : cardColor)
                        .symbolEffect(.bounce, value: isSelected)
                }
                
                VStack(spacing: 2) {
                    Text(name)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .primary : .secondary)
                    
                    Text(description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? cardColor.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? cardColor.opacity(0.3) : (isHovered ? .borderSecondary : .clear),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : (isHovered ? 1.02 : 1.0))
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Mode Selector
struct ScanModeSelector: View {
    @Binding var selectedMode: UnifiedSecurityScanner.ScanMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("Scan Mode")
                .font(Typography.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: Spacing.small) {
                ForEach(UnifiedSecurityScanner.ScanMode.allCases, id: \.self) { mode in
                    Button(action: {
                        withAnimation(.smoothSpring) {
                            selectedMode = mode
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 16))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(mode.rawValue)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                
                                Text(mode.description)
                                    .font(.caption2)
                                    .opacity(0.8)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            selectedMode == mode ? 
                            Color.primaryAccent.opacity(0.2) : 
                            Color.cardBackground
                        )
                        .foregroundColor(
                            selectedMode == mode ? 
                            .primaryAccent : 
                            .primary
                        )
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    selectedMode == mode ? 
                                    Color.primaryAccent : 
                                    Color.borderPrimary,
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .standardContainer()
    }
}

// MARK: - Target Configuration
struct TargetConfigurationSection: View {
    @Binding var scanTarget: String
    @Binding var selectedScanType: String
    let scanTypes: [(String, String, String, String)]
    let isScanning: Bool
    let startScan: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("Target Configuration")
                .font(Typography.headline)
                .foregroundColor(.primary)
            
            // Target input
            VStack(alignment: .leading, spacing: 8) {
                Text("Target")
                    .font(Typography.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    TextField("IP address, domain, or URL", text: $scanTarget)
                        .textFieldStyle(.roundedBorder)
                        .disabled(isScanning)
                    
                    Button(action: startScan) {
                        HStack {
                            Image(systemName: isScanning ? "stop.circle" : "play.circle.fill")
                            Text(isScanning ? "Stop" : "Start Scan")
                        }
                        .frame(minWidth: 120)
                    }
                    .disabled(scanTarget.isEmpty)
                    .primaryButton()
                }
            }
            
            // Scan type selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Scan Type")
                    .font(Typography.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    ForEach(scanTypes, id: \.0) { type, name, icon, description in
                        Button(action: {
                            selectedScanType = type
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: icon)
                                    .font(.caption)
                                
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(name)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    
                                    Text(description)
                                        .font(.caption2)
                                        .opacity(0.7)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(
                                selectedScanType == type ?
                                Color.primaryAccent.opacity(0.2) :
                                Color.clear
                            )
                            .foregroundColor(
                                selectedScanType == type ?
                                .primaryAccent :
                                .primary
                            )
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(
                                        selectedScanType == type ?
                                        Color.primaryAccent :
                                        Color.borderPrimary,
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .standardContainer()
    }
}

// MARK: - Network Tools Section
struct NetworkToolsSection: View {
    @Binding var selectedTools: Set<String>
    
    let networkTools = [
        ("Port Scan", "Nmap port scanning", "network"),
        ("Service Detection", "Service version detection", "magnifyingglass.circle"),
        ("OS Detection", "Operating system fingerprinting", "desktopcomputer"),
        ("Vulnerability Scan", "Nmap vulnerability scripts", "exclamationmark.shield"),
        ("UDP Scan", "UDP port scanning", "wifi.circle"),
        ("Stealth Scan", "SYN stealth scanning", "eye.slash")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack {
                Text("Network Tools")
                    .font(Typography.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button("All") {
                        selectedTools = Set(networkTools.map { $0.0 })
                    }
                    .buttonStyle(.link)
                    .font(.caption)
                    
                    Text("•")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Button("None") {
                        selectedTools.removeAll()
                    }
                    .buttonStyle(.link)
                    .font(.caption)
                    
                    Text("\(selectedTools.count) selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(networkTools, id: \.0) { tool, description, icon in
                    ToolSelectionCard(
                        name: tool,
                        description: description,
                        icon: icon,
                        isSelected: selectedTools.contains(tool)
                    ) {
                        if selectedTools.contains(tool) {
                            selectedTools.remove(tool)
                        } else {
                            selectedTools.insert(tool)
                        }
                    }
                }
            }
        }
        .standardContainer()
    }
}

// MARK: - Web Tools Section
struct WebToolsSection: View {
    @Binding var selectedTools: Set<String>
    
    let webTools = [
        ("SQL Injection", "SQLMap testing", "cylinder.split.1x2"),
        ("Web Vulnerability Scan", "Nikto scanner", "magnifyingglass.circle"),
        ("Directory Enumeration", "Gobuster/Feroxbuster", "folder.badge.questionmark"),
        ("XSS Detection", "Cross-site scripting", "exclamationmark.triangle"),
        ("Nuclei Template Scan", "9000+ templates", "bolt.circle"),
        ("SSL/TLS Analysis", "Certificate testing", "lock.circle")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack {
                Text("Web Tools")
                    .font(Typography.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button("All") {
                        selectedTools = Set(webTools.map { $0.0 })
                    }
                    .buttonStyle(.link)
                    .font(.caption)
                    
                    Text("•")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Button("None") {
                        selectedTools.removeAll()
                    }
                    .buttonStyle(.link)
                    .font(.caption)
                    
                    Text("\(selectedTools.count) selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(webTools, id: \.0) { tool, description, icon in
                    ToolSelectionCard(
                        name: tool,
                        description: description,
                        icon: icon,
                        isSelected: selectedTools.contains(tool)
                    ) {
                        if selectedTools.contains(tool) {
                            selectedTools.remove(tool)
                        } else {
                            selectedTools.insert(tool)
                        }
                    }
                }
            }
        }
        .standardContainer()
    }
}

// MARK: - Tool Selection Card
struct ToolSelectionCard: View {
    let name: String
    let description: String
    let icon: String
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .primaryAccent : .secondary)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .foregroundColor(isSelected ? .primary : .secondary)
                    
                    Text(description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer(minLength: 0)
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .primaryAccent : .secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(isSelected ? Color.primaryAccent.opacity(0.1) : Color.cardBackground)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.primaryAccent.opacity(0.3) : Color.borderPrimary, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Ultra-Modern Tools Arsenal Components
struct UltraModernNetworkToolsArsenal: View {
    @Binding var selectedTools: Set<String>
    @State private var showAllTools = false
    
    let networkTools = [
        ("Port Scan", "Comprehensive port scanning with Nmap", "network", "nmap"),
        ("Service Detection", "Service version detection and fingerprinting", "magnifyingglass.circle", "nmap"),
        ("OS Detection", "Operating system fingerprinting", "desktopcomputer", "nmap"),
        ("Vulnerability Scripts", "NSE vulnerability detection scripts", "exclamationmark.shield", "nmap"),
        ("UDP Scan", "UDP port scanning and discovery", "wifi.circle", "nmap"),
        ("Stealth Scan", "SYN stealth scanning techniques", "eye.slash", "nmap"),
        ("Version Detection", "Service version enumeration", "doc.text.magnifyingglass", "nmap"),
        ("Script Scan", "Advanced NSE script execution", "terminal", "nmap"),
        ("Ping Sweep", "Network discovery and host enumeration", "antenna.radiowaves.left.and.right", "nmap"),
        ("Traceroute", "Network path discovery", "map", "traceroute"),
        ("DNS Enumeration", "DNS server reconnaissance", "server.rack", "dig"),
        ("SNMP Scan", "SNMP service discovery", "network.badge.shield.half.filled", "snmpwalk"),
        ("SMB Enumeration", "SMB/NetBIOS service enumeration", "folder.badge.questionmark", "smbclient"),
        ("SSH Brute Force", "SSH credential brute forcing", "key.horizontal", "hydra"),
        ("FTP Analysis", "FTP service security testing", "arrow.up.arrow.down.circle", "nmap")
    ]
    
    var displayedTools: [(String, String, String, String)] {
        showAllTools ? networkTools : Array(networkTools.prefix(8))
    }
    
    var body: some View {
        ModernCard {
            VStack(alignment: .leading, spacing: Spacing.large) {
                HStack {
                    Label("Network Tools Arsenal", systemImage: "antenna.radiowaves.left.and.right")
                        .font(Typography.headline)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Button(selectedTools.count == networkTools.count ? "None" : "All") {
                            withAnimation(.smoothSpring) {
                                if selectedTools.count == networkTools.count {
                                    selectedTools.removeAll()
                                } else {
                                    selectedTools = Set(networkTools.map { $0.0 })
                                }
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.primaryAccent)
                        .buttonStyle(.plain)
                        
                        Text("\(selectedTools.count) selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.primaryAccent.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(displayedTools, id: \.0) { tool, description, icon, command in
                        UltraModernToolCard(
                            name: tool,
                            description: description,
                            icon: icon,
                            command: command,
                            isSelected: selectedTools.contains(tool),
                            color: .blue
                        ) {
                            withAnimation(.smoothSpring) {
                                if selectedTools.contains(tool) {
                                    selectedTools.remove(tool)
                                } else {
                                    selectedTools.insert(tool)
                                }
                            }
                        }
                    }
                }
                
                if networkTools.count > 8 {
                    Button(action: {
                        withAnimation(.smoothSpring) {
                            showAllTools.toggle()
                        }
                    }) {
                        HStack {
                            Text(showAllTools ? "Show Less" : "Show \(networkTools.count - 8) More Tools")
                                .font(.subheadline)
                                .foregroundColor(.primaryAccent)
                            
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.primaryAccent)
                                .rotationEffect(.degrees(showAllTools ? 180 : 0))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal)
    }
}

struct UltraModernWebToolsArsenal: View {
    @Binding var selectedTools: Set<String>
    @State private var showAllTools = false
    
    let webTools = [
        ("SQL Injection", "Advanced SQL injection testing with SQLMap", "cylinder.split.1x2", "sqlmap"),
        ("Web Vulnerability Scan", "Comprehensive web vulnerability scanning", "magnifyingglass.circle", "nikto"),
        ("Nuclei Template Scan", "9000+ vulnerability templates", "bolt.circle", "nuclei"),
        ("Directory Enumeration", "Hidden directory and file discovery", "folder.badge.questionmark", "gobuster"),
        ("Advanced Directory Fuzzing", "High-speed directory fuzzing", "square.grid.3x3.fill", "feroxbuster"),
        ("XSS Detection", "Cross-site scripting vulnerability testing", "exclamationmark.triangle", "xsser"),
        ("OWASP ZAP Scan", "OWASP ZAP automated scanning", "shield.lefthalf.filled", "zap"),
        ("HTTP/HTTPS Analysis", "HTTP service analysis and enumeration", "globe.badge.chevron.backward", "httpx"),
        ("SSL/TLS Analysis", "SSL/TLS configuration and certificate testing", "lock.circle", "sslyze"),
        ("HTTP Header Security", "Security header analysis and testing", "doc.text.below.ecg", "curl"),
        ("Basic SSL Check", "SSL certificate validation and analysis", "checkmark.shield", "openssl"),
        ("Subdomain Enumeration", "Subdomain discovery and mapping", "network", "subfinder")
    ]
    
    var displayedTools: [(String, String, String, String)] {
        showAllTools ? webTools : Array(webTools.prefix(8))
    }
    
    var body: some View {
        ModernCard {
            VStack(alignment: .leading, spacing: Spacing.large) {
                HStack {
                    Label("Web Security Arsenal", systemImage: "globe.badge.chevron.backward")
                        .font(Typography.headline)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .teal],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Button(selectedTools.count == webTools.count ? "None" : "All") {
                            withAnimation(.smoothSpring) {
                                if selectedTools.count == webTools.count {
                                    selectedTools.removeAll()
                                } else {
                                    selectedTools = Set(webTools.map { $0.0 })
                                }
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.green)
                        .buttonStyle(.plain)
                        
                        Text("\(selectedTools.count) selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(displayedTools, id: \.0) { tool, description, icon, command in
                        UltraModernToolCard(
                            name: tool,
                            description: description,
                            icon: icon,
                            command: command,
                            isSelected: selectedTools.contains(tool),
                            color: .green
                        ) {
                            withAnimation(.smoothSpring) {
                                if selectedTools.contains(tool) {
                                    selectedTools.remove(tool)
                                } else {
                                    selectedTools.insert(tool)
                                }
                            }
                        }
                    }
                }
                
                if webTools.count > 8 {
                    Button(action: {
                        withAnimation(.smoothSpring) {
                            showAllTools.toggle()
                        }
                    }) {
                        HStack {
                            Text(showAllTools ? "Show Less" : "Show \(webTools.count - 8) More Tools")
                                .font(.subheadline)
                                .foregroundColor(.green)
                            
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.green)
                                .rotationEffect(.degrees(showAllTools ? 180 : 0))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal)
    }
}

struct UltraModernToolCard: View {
    let name: String
    let description: String
    let icon: String
    let command: String
    let isSelected: Bool
    let color: Color
    let onToggle: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onToggle) {
            VStack(spacing: 8) {
                ZStack {
                    // Glow effect when selected
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(color.opacity(0.3))
                            .blur(radius: 8)
                            .scaleEffect(1.1)
                    }
                    
                    // Main card background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            isSelected ? 
                            LinearGradient(colors: [color.opacity(0.2), color.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                            LinearGradient(colors: [.cardBackground], startPoint: .top, endPoint: .bottom)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    isSelected ? color.opacity(0.5) : (isHovered ? .borderSecondary : .borderPrimary),
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )
                    
                    VStack(spacing: 6) {
                        // Tool icon
                        Image(systemName: icon)
                            .font(.system(size: 20))
                            .foregroundColor(isSelected ? color : .secondary)
                            .symbolEffect(.bounce, value: isSelected)
                        
                        // Tool name
                        Text(name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(isSelected ? .primary : .secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        
                        // Command badge
                        Text(command)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(isSelected ? color : .tertiaryText)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(isSelected ? color.opacity(0.2) : Color.gray.opacity(0.1))
                            )
                        
                        // Selection indicator
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.caption)
                            .foregroundColor(isSelected ? color : .secondary)
                            .symbolEffect(.bounce, value: isSelected)
                    }
                    .padding(8)
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : (isHovered ? 1.02 : 1.0))
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .help(description)
    }
}

// MARK: - Stunning Scan Visualization
/*
// DISABLED: Complex expression error - struct UltraModernScanVisualization: View {
    let mode: UnifiedSecurityScanner.ScanMode
    let target: String
    let progress: Double
    let currentPhase: String
    @Binding var animateRadar: Bool
    @Binding var pulseAnimation: Bool
    
    @State private var radarAngle: Double = 0
    @State private var particleAnimation = false
    @State private var glowIntensity = 0.5
    
    var body: some View {
        ModernCard {
            VStack(spacing: Spacing.large) {
                // Header with mode and target
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Active Scan")
                            .font(Typography.headline)
                            .foregroundColor(.primary)
                        
                        Text("Target: \(target)")
                            .font(Typography.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Mode indicator
                    HStack(spacing: 8) {
                        Image(systemName: mode.icon)
                            .foregroundStyle(mode.gradient)
                        
                        Text(mode.rawValue)
                            .font(.headline)
                            .foregroundStyle(mode.gradient)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.cardBackground)
                            .overlay(
                                Capsule()
                                    .stroke(mode.gradient, lineWidth: 1)
                            )
                    )
                }
                
                // Ultra-modern radar visualization
                ZStack {
                    // Background grid
                    ForEach(1..<6) { ring in
                        Circle()
                            .stroke(
                                Color.primaryAccent.opacity(0.1),
                                style: StrokeStyle(lineWidth: 1, dash: [5, 5])
                            )
                            .frame(width: CGFloat(ring * 40))
                    }
                    
                    // Radar sweep
                    if animateRadar {
                        Path { path in
                            let center = CGPoint(x: 100, y: 100)
                            path.move(to: center)
                            path.addLine(to: CGPoint(
                                x: center.x + 100 * cos(radarAngle * .pi / 180),
                                y: center.y + 100 * sin(radarAngle * .pi / 180)
                            ))
                        }
                        .stroke(
                            AngularGradient(
                                colors: [.clear, .primaryAccent.opacity(0.8), .clear],
                                center: .center,
                                angle: .degrees(radarAngle)
                            ),
                            lineWidth: 3
                        )
                        .blur(radius: 2)
                        
                        // Radar sweep area
                        Path { path in
                            let center = CGPoint(x: 100, y: 100)
                            path.move(to: center)
                            path.addArc(
                                center: center,
                                radius: 100,
                                startAngle: .degrees(radarAngle - 30),
                                endAngle: .degrees(radarAngle + 30),
                                clockwise: false
                            )
                        }
                        .fill(
                            AngularGradient(
                                colors: [.clear, .primaryAccent.opacity(0.2), .clear],
                                center: .center,
                                angle: .degrees(radarAngle)
                            )
                        )
                    }
                    
                    // Center pulse
                    Circle()
                        .fill(mode.gradient)
                        .frame(width: 12, height: 12)
                        .scaleEffect(pulseAnimation ? 1.5 : 1.0)
                        .opacity(pulseAnimation ? 0.5 : 1.0)
                    
                    // Scanning particles
                    if particleAnimation {
                        ForEach(0..<8) { i in
                            Circle()
                                .fill(.primaryAccent)
                                .frame(width: 4, height: 4)
                                .offset(
                                    x: cos(Double(i) * .pi / 4) * 80,
                                    y: sin(Double(i) * .pi / 4) * 80
                                )
                                .scaleEffect(particleAnimation ? 1.2 : 0.8)
                                .opacity(particleAnimation ? 0.3 : 1.0)
                        }
                    }
                }
                .frame(width: 200, height: 200)
                .background(
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.primaryAccent.opacity(0.1), .clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 100
                            )
                        )
                        .scaleEffect(glowIntensity)
                )
                
                // Progress and status
                VStack(spacing: 12) {
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                            
                            // Progress fill
                            RoundedRectangle(cornerRadius: 6)
                                .fill(mode.gradient)
                                .frame(width: geometry.size.width * progress, height: 8)
                                .animation(.easeInOut(duration: 0.3), value: progress)
                        }
                    }
                    .frame(height: 8)
                    
                    // Status text
                    HStack {
                        Text(currentPhase.isEmpty ? "Initializing scan..." : currentPhase)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(progress * 100))%")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .padding(.horizontal)
        .onAppear {
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                radarAngle = 360
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                particleAnimation = true
                glowIntensity = 1.2
            }
        }
    }
// }
*/

// MARK: - Unified Scan Visualization
struct UnifiedScanVisualization: View {
    let mode: UnifiedSecurityScanner.ScanMode
    let target: String
    @State private var animationPhase = 0.0
    
    var body: some View {
        VStack(spacing: Spacing.large) {
            // Radar-style visualization
            ZStack {
                // Background circles
                ForEach(0..<4) { i in
                    Circle()
                        .stroke(Color.primaryAccent.opacity(0.2), lineWidth: 1)
                        .frame(width: CGFloat(60 + i * 30))
                }
                
                // Scanning beam
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: 120 * cos(animationPhase), y: 120 * sin(animationPhase)))
                }
                .stroke(
                    LinearGradient(
                        colors: [.primaryAccent, .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 2
                )
                
                // Center target
                Circle()
                    .fill(Color.primaryAccent)
                    .frame(width: 8, height: 8)
                
                // Mode icon
                Image(systemName: mode.icon)
                    .font(.system(size: 20))
                    .foregroundColor(.primaryAccent)
                    .offset(y: -40)
            }
            .frame(width: 240, height: 240)
            .onAppear {
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    animationPhase = .pi * 2
                }
            }
            
            // Status text
            VStack(spacing: 4) {
                Text("Scanning \(target)")
                    .font(Typography.headline)
                    .foregroundColor(.primary)
                
                Text("Mode: \(mode.rawValue)")
                    .font(Typography.caption)
                    .foregroundColor(.secondary)
            }
        }
        .standardContainer()
    }
}

// MARK: - Unified Results Section
struct UnifiedResultsSection: View {
    let targets: [Target]
    let webResults: [WebScanResult]
    @Binding var selectedTarget: Target?
    @Binding var showTargetDetails: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("Scan Results")
                .font(Typography.headline)
                .foregroundColor(.primary)
            
            if targets.isEmpty && webResults.isEmpty {
                ContentUnavailableView(
                    "No Results Yet",
                    systemImage: "magnifyingglass",
                    description: Text("Start a scan to see results")
                )
            } else {
                VStack(spacing: Spacing.medium) {
                    // Network Results
                    if !targets.isEmpty {
                        Text("Network Targets (\(targets.count))")
                            .font(Typography.subheadline)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(targets) { target in
                                TargetResultCard(target: target) {
                                    selectedTarget = target
                                    showTargetDetails = true
                                }
                            }
                        }
                    }
                    
                    // Web Results
                    if !webResults.isEmpty {
                        Text("Web Vulnerabilities (\(webResults.count))")
                            .font(Typography.subheadline)
                            .foregroundColor(.secondary)
                        
                        LazyVStack(spacing: 8) {
                            ForEach(webResults) { result in
                                WebResultCard(result: result)
                            }
                        }
                    }
                }
            }
        }
        .standardContainer()
    }
}

// MARK: - Result Cards
struct TargetResultCard: View {
    let target: Target
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "desktopcomputer")
                        .foregroundColor(.primaryAccent)
                    
                    Text(target.name)
                        .font(Typography.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text("\(target.vulnerabilities.count)")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.primaryAccent.opacity(0.2))
                        .foregroundColor(.primaryAccent)
                        .cornerRadius(4)
                }
                
                Text(target.ipAddress)
                    .font(Typography.caption)
                    .foregroundColor(.secondary)
                
                if !target.vulnerabilities.isEmpty {
                    HStack {
                        ForEach(Array(target.vulnerabilities.prefix(3))) { vuln in
                            Text(vuln.severity.rawValue.capitalized)
                                .font(.caption2)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(vuln.severity.color.opacity(0.2))
                                .foregroundColor(vuln.severity.color)
                                .cornerRadius(3)
                        }
                        
                        if target.vulnerabilities.count > 3 {
                            Text("+\(target.vulnerabilities.count - 3)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.borderPrimary, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct WebResultCard: View {
    let result: WebScanResult
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "globe")
                    .foregroundColor(result.severity.color)
                
                Text(result.type)
                    .font(Typography.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(result.severity.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(result.severity.color.opacity(0.2))
                    .foregroundColor(result.severity.color)
                    .cornerRadius(4)
                
                if !result.details.isEmpty {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Text(result.description)
                .font(Typography.body)
                .foregroundColor(.primary)
            
            Text(result.url)
                .font(Typography.caption)
                .foregroundColor(.primaryAccent)
                .lineLimit(1)
            
            if isExpanded && !result.details.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(result.details.enumerated()), id: \.offset) { index, detail in
                        HStack(alignment: .top, spacing: 6) {
                            Text("•")
                                .foregroundColor(.secondary)
                            
                            Text(detail)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.top, 4)
                .padding(.leading, 8)
                .overlay(
                    Rectangle()
                        .frame(width: 2)
                        .foregroundColor(.primaryAccent.opacity(0.3)),
                    alignment: .leading
                )
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.borderPrimary, lineWidth: 1)
        )
    }
}

// Note: Animation extensions are defined in DesignSystem.swift

#Preview {
    UnifiedSecurityScanner()
        .environment(AppState())
}