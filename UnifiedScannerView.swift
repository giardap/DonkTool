                .frame(maxWidth: .infinity)
                .frame(height: 44)
            }
            .buttonStyle(.borderedProminent)
            .disabled(target.isEmpty || isScanning)
            
            HStack(spacing: 12) {
                Button("Quick Recon") {
                    startQuickRecon()
                }
                .buttonStyle(.bordered)
                .disabled(target.isEmpty || isScanning)
                
                Button("Deep Scan") {
                    startDeepScan()
                }
                .buttonStyle(.bordered)
                .disabled(target.isEmpty || isScanning)
            }
        }
    }
    
    @ViewBuilder
    private func AttackVectorSelectionSection(results: UnifiedScanResults) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Attack Vectors (\(results.attackVectors.count))", systemImage: "bolt.shield")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Select High Priority") {
                    selectHighPriorityVectors()
                }
                .font(.caption)
                .buttonStyle(.link)
            }
            
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(results.attackVectors) { vector in
                        AttackVectorRow(
                            vector: vector,
                            isSelected: selectedVectors.contains(vector.id)
                        ) { isSelected in
                            if isSelected {
                                selectedVectors.insert(vector.id)
                            } else {
                                selectedVectors.remove(vector.id)
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: 300)
        }
        .padding(16)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func UnifiedResultsPanel() -> some View {
        VStack(spacing: 0) {
            // Results Header
            HStack {
                Text("Scan Results")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if let results = scanResults {
                    ResultsSummaryBadges(results: results)
                }
            }
            .padding(20)
            
            Divider()
            
            // Results Content
            if let results = scanResults {
                UnifiedResultsContent(results: results)
            } else {
                UnifiedEmptyState()
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    @ViewBuilder
    private func UnifiedScanProgress() -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("Phase: \(scanEngine.currentPhase.rawValue)")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(scanEngine.overallProgress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: scanEngine.overallProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .purple))
            
            HStack {
                ForEach(ScanPhase.allCases, id: \.self) { phase in
                    PhaseIndicator(
                        phase: phase,
                        currentPhase: scanEngine.currentPhase,
                        phaseProgress: scanEngine.phaseProgress[phase] ?? 0
                    )
                }
            }
        }
        .padding(12)
        .background(Color.purple.opacity(0.05))
        .cornerRadius(8)
    }
    
    // MARK: - Actions
    
    private func startUnifiedScan() {
        guard !target.isEmpty else { return }
        
        isScanning = true
        scanResults = nil
        selectedVectors.removeAll()
        
        Task {
            let results = await scanEngine.performUnifiedScan(
                target: target,
                profile: scanProfile
            )
            
            // Get intelligent attack vectors
            let attackVectors = await attackVectorEngine.determineAttackVectors(
                for: ScanTarget(
                    address: target,
                    hostname: scanEngine.targetInfo?.hostname,
                    osFingerprint: results.osInfo,
                    tags: []
                ),
                scanResults: results.portResults,
                webResults: results.webResults
            )
            
            await MainActor.run {
                self.scanResults = UnifiedScanResults(
                    target: target,
                    portResults: results.portResults,
                    webResults: results.webResults,
                    vulnerabilities: results.vulnerabilities,
                    osInfo: results.osInfo,
                    attackVectors: attackVectors,
                    scanDuration: results.scanDuration
                )
                self.isScanning = false
                
                // Auto-select high priority vectors
                selectHighPriorityVectors()
            }
        }
    }
    
    private func stopScan() {
        scanEngine.stopScan()
        isScanning = false
    }
    
    private func validateTarget() {
        Task {
            await scanEngine.validateTarget(target)
        }
    }
    
    private func startQuickRecon() {
        scanProfile = .stealth
        startUnifiedScan()
    }
    
    private func startDeepScan() {
        scanProfile = .comprehensive
        startUnifiedScan()
    }
    
    private func selectHighPriorityVectors() {
        guard let results = scanResults else { return }
        
        let highPriorityVectors = results.attackVectors
            .filter { $0.severity == .critical || $0.severity == .high }
            .prefix(10)
            .map { $0.id }
        
        selectedVectors = Set(highPriorityVectors)
    }
    
    private func getSelectedVectors() -> [IntelligentAttackVector] {
        guard let results = scanResults else { return [] }
        return results.attackVectors.filter { selectedVectors.contains($0.id) }
    }
}

// MARK: - Supporting Views

struct ScanProfileOption: View {
    let profile: UnifiedScannerView.ScanProfile
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .font(.system(size: 16))
                
                Image(systemName: profile.icon)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(profile.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
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

struct TargetInfoCard: View {
    let info: TargetInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Target Validated")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if let hostname = info.hostname {
                    HStack {
                        Text("Hostname:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(hostname)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                
                HStack {
                    Text("IP:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(info.ipAddress)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                if let asn = info.asn {
                    HStack {
                        Text("ASN:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(asn)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding(12)
        .background(Color.green.opacity(0.05))
        .cornerRadius(8)
    }
}

struct AttackVectorRow: View {
    let vector: IntelligentAttackVector
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        Button(action: { onToggle(!isSelected) }) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .font(.system(size: 16))
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(vector.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        HStack(spacing: 6) {
                            SeverityBadge(severity: vector.severity)
                            ReliabilityIndicator(reliability: vector.reliability)
                            DetectionRiskIndicator(risk: vector.detectionRisk)
                        }
                    }
                    
                    Text(vector.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    HStack {
                        Label("\(vector.estimatedDuration)s", systemImage: "clock")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(vector.tools.map { $0.name }.joined(separator: ", "))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .background(isSelected ? Color.accentColor.opacity(0.05) : Color.gray.opacity(0.05))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct SeverityBadge: View {
    let severity: AttackSeverity
    
    var body: some View {
        Text(severity.rawValue.uppercased())
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(severityColor.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(4)
    }
    
    private var severityColor: Color {
        switch severity {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        }
    }
}

struct ReliabilityIndicator: View {
    let reliability: IntelligentAttackVector.AttackReliability
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(index < reliabilityLevel ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 4, height: 4)
            }
        }
    }
    
    private var reliabilityLevel: Int {
        switch reliability {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}

struct DetectionRiskIndicator: View {
    let risk: IntelligentAttackVector.DetectionRisk
    
    var body: some View {
        Image(systemName: riskIcon)
            .font(.caption2)
            .foregroundColor(riskColor)
    }
    
    private var riskIcon: String {
        switch risk {
        case .low: return "eye.slash"
        case .medium: return "eye"
        case .high: return "eye.trianglebadge.exclamationmark"
        case .guaranteed: return "exclamationmark.triangle.fill"
        }
    }
    
    private var riskColor: Color {
        switch risk {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .guaranteed: return .red
        }
    }
}

struct PhaseIndicator: View {
    let phase: ScanPhase
    let currentPhase: ScanPhase
    let phaseProgress: Double
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: 30, height: 30)
                
                if isCompleted {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundColor(.white)
                } else if isCurrent {
                    Circle()
                        .trim(from: 0, to: phaseProgress)
                        .stroke(Color.purple, lineWidth: 2)
                        .frame(width: 30, height: 30)
                        .rotationEffect(.degrees(-90))
                }
                
                if !isCompleted && !isCurrent {
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 30, height: 30)
                }
            }
            
            Text(phase.shortName)
                .font(.caption2)
                .foregroundColor(isCompleted || isCurrent ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var isCompleted: Bool {
        phase.rawValue < currentPhase.rawValue
    }
    
    private var isCurrent: Bool {
        phase == currentPhase
    }
}

struct ResultsSummaryBadges: View {
    let results: UnifiedScanResults
    
    var body: some View {
        HStack(spacing: 12) {
            ResultBadge(
                label: "Ports",
                value: "\(results.portResults.filter { $0.isOpen }.count)",
                color: .blue
            )
            
            ResultBadge(
                label: "Vulns",
                value: "\(results.vulnerabilities.count)",
                color: .red
            )
            
            ResultBadge(
                label: "Vectors",
                value: "\(results.attackVectors.count)",
                color: .purple
            )
            
            ResultBadge(
                label: "Time",
                value: formatDuration(results.scanDuration),
                color: .green
            )
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

struct ResultBadge: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
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

struct UnifiedResultsContent: View {
    let results: UnifiedScanResults
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Bar
            HStack(spacing: 0) {
                TabButton(title: "Overview", icon: "square.grid.2x2", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                
                TabButton(title: "Services", icon: "network", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }
                
                TabButton(title: "Vulnerabilities", icon: "exclamationmark.triangle", isSelected: selectedTab == 2) {
                    selectedTab = 2
                }
                
                TabButton(title: "Attack Graph", icon: "point.3.connected.trianglepath.dotted", isSelected: selectedTab == 3) {
                    selectedTab = 3
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Tab Content
            TabView(selection: $selectedTab) {
                UnifiedOverviewTab(results: results)
                    .tag(0)
                
                ServicesTab(results: results)
                    .tag(1)
                
                VulnerabilitiesTab(results: results)
                    .tag(2)
                
                AttackGraphTab(results: results)
                    .tag(3)
            }
            .tabViewStyle(.automatic)
        }
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .accentColor : .secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

struct UnifiedEmptyState: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("Ready to Scan")
                    .font(.headline)
                
                Text("Enter a target and select a scan profile to begin")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Tab Views

struct UnifiedOverviewTab: View {
    let results: UnifiedScanResults
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Risk Assessment
                RiskAssessmentCard(results: results)
                
                // Key Findings
                KeyFindingsCard(results: results)
                
                // Attack Surface
                AttackSurfaceCard(results: results)
                
                // Recommendations
                RecommendationsCard(results: results)
            }
            .padding(20)
        }
    }
}

struct ServicesTab: View {
    let results: UnifiedScanResults
    
    var body: some View {
        List(results.portResults.filter { $0.isOpen }) { result in
            ServiceDetailRow(result: result)
        }
        .listStyle(.plain)
    }
}

struct VulnerabilitiesTab: View {
    let results: UnifiedScanResults
    
    var body: some View {
        if results.vulnerabilities.isEmpty {
            ContentUnavailableView(
                "No Vulnerabilities Found",
                systemImage: "checkmark.shield",
                description: Text("The target appears to be well-secured")
            )
        } else {
            List(results.vulnerabilities) { vulnerability in
                VulnerabilityDetailRow(vulnerability: vulnerability)
            }
            .listStyle(.plain)
        }
    }
}

struct AttackGraphTab: View {
    let results: UnifiedScanResults
    
    var body: some View {
        AttackGraphVisualization(
            vectors: results.attackVectors,
            services: results.portResults.filter { $0.isOpen }
        )
    }
}

// MARK: - Models

struct UnifiedScanResults {
    let target: String
    let portResults: [PortScanResult]
    let webResults: [WebTestResult]?
    let vulnerabilities: [Vulnerability]
    let osInfo: OSInfo?
    let attackVectors: [IntelligentAttackVector]
    let scanDuration: TimeInterval
}

struct TargetInfo {
    let ipAddress: String
    let hostname: String?
    let asn: String?
    let location: String?
}

enum ScanPhase: String, CaseIterable {
    case discovery = "Discovery"
    case enumeration = "Enumeration"
    case vulnerability = "Vulnerability"
    case analysis = "Analysis"
    
    var shortName: String {
        switch self {
        case .discovery: return "DISC"
        case .enumeration: return "ENUM"
        case .vulnerability: return "VULN"
        case .analysis: return "ANLY"
        }
    }
}

// MARK: - Scan Engine

@Observable
class UnifiedScanEngine {
    var currentPhase: ScanPhase = .discovery
    var overallProgress: Double = 0.0
    var phaseProgress: [ScanPhase: Double] = [:]
    var targetInfo: TargetInfo?
    
    private var scanTask: Task<Void, Never>?
    
    func performUnifiedScan(target: String, profile: UnifiedScannerView.ScanProfile) async -> UnifiedScanResults {
        // Implementation would integrate all scanning capabilities
        // This is a placeholder showing the structure
        
        // Phase 1: Discovery
        currentPhase = .discovery
        let portResults = await performPortScan(target: target, profile: profile)
        phaseProgress[.discovery] = 1.0
        
        // Phase 2: Enumeration
        currentPhase = .enumeration
        let serviceInfo = await enumerateServices(portResults: portResults)
        phaseProgress[.enumeration] = 1.0
        
        // Phase 3: Vulnerability Scanning
        currentPhase = .vulnerability
        let vulnerabilities = await scanForVulnerabilities(target: target, services: serviceInfo)
        phaseProgress[.vulnerability] = 1.0
        
        // Phase 4: Analysis
        currentPhase = .analysis
        let osInfo = await performOSFingerprinting(target: target)
        phaseProgress[.analysis] = 1.0
        
        overallProgress = 1.0
        
        return UnifiedScanResults(
            target: target,
            portResults: portResults,
            webResults: nil,
            vulnerabilities: vulnerabilities,
            osInfo: osInfo,
            attackVectors: [],
            scanDuration: 0
        )
    }
    
    func validateTarget(_ target: String) async {
        // Validate and gather target information
        targetInfo = TargetInfo(
            ipAddress: "192.168.1.100",
            hostname: "target.local",
            asn: "AS12345",
            location: "US"
        )
    }
    
    func stopScan() {
        scanTask?.cancel()
    }
    
    private func performPortScan(target: String, profile: UnifiedScannerView.ScanProfile) async -> [PortScanResult] {
        // Implementation
        return []
    }
    
    private func enumerateServices(portResults: [PortScanResult]) async -> [ServiceInfo] {
        // Implementation
        return []
    }
    
    private func scanForVulnerabilities(target: String, services: [ServiceInfo]) async -> [Vulnerability] {
        // Implementation
        return []
    }
    
    private func performOSFingerprinting(target: String) async -> OSInfo {
        // Implementation
        return OSInfo(name: "Unknown", version: nil, architecture: nil, kernel: nil)
    }
}

// Additional UI Components

struct RiskAssessmentCard: View {
    let results: UnifiedScanResults
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Risk Assessment")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 20) {
                RiskMeter(level: calculateRiskLevel())
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Overall Risk: \(calculateRiskLevel().rawValue)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(calculateRiskLevel().color)
                    
                    Text("Based on \(results.vulnerabilities.count) vulnerabilities and \(results.attackVectors.count) attack vectors")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private func calculateRiskLevel() -> RiskLevel {
        let criticalCount = results.vulnerabilities.filter { $0.severity == .critical }.count
        let highCount = results.vulnerabilities.filter { $0.severity == .high }.count
        
        if criticalCount > 0 {
            return .critical
        } else if highCount > 2 {
            return .high
        } else if highCount > 0 {
            return .medium
        } else {
            return .low
        }
    }
}

struct KeyFindingsCard: View {
    let results: UnifiedScanResults
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Findings")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(getKeyFindings(), id: \.self) { finding in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        
                        Text(finding)
                            .font(.body)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private func getKeyFindings() -> [String] {
        var findings: [String] = []
        
        // Open ports
        let openPorts = results.portResults.filter { $0.isOpen }.count
        findings.append("\(openPorts) open ports discovered")
        
        // Critical vulnerabilities
        let criticalVulns = results.vulnerabilities.filter { $0.severity == .critical }.count
        if criticalVulns > 0 {
            findings.append("\(criticalVulns) critical vulnerabilities require immediate attention")
        }
        
        // High reliability attack vectors
        let highReliabilityVectors = results.attackVectors.filter { $0.reliability == .high }.count
        if highReliabilityVectors > 0 {
            findings.append("\(highReliabilityVectors) highly reliable attack vectors available")
        }
        
        return findings
    }
}

struct AttackSurfaceCard: View {
    let results: UnifiedScanResults
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Attack Surface")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Visual representation of attack surface
            // This would be a custom visualization
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(height: 200)
                .overlay(
                    Text("Attack Surface Visualization")
                        .foregroundColor(.secondary)
                )
                .cornerRadius(8)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct RecommendationsCard: View {
    let results: UnifiedScanResults
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommendations")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(getRecommendations(), id: \.self) { recommendation in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.green)
                            .font(.caption)
                        
                        Text(recommendation)
                            .font(.body)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private func getRecommendations() -> [String] {
        var recommendations: [String] = []
        
        // Based on findings
        if results.vulnerabilities.contains(where: { $0.severity == .critical }) {
            recommendations.append("Immediately patch critical vulnerabilities")
        }
        
        if results.portResults.contains(where: { $0.port == 23 && $0.isOpen }) {
            recommendations.append("Disable Telnet and use SSH instead")
        }
        
        if results.portResults.contains(where: { $0.port == 445 && $0.isOpen }) {
            recommendations.append("Review SMB configuration and apply latest patches")
        }
        
        recommendations.append("Implement network segmentation")
        recommendations.append("Enable comprehensive logging and monitoring")
        
        return recommendations
    }
}

struct ServiceDetailRow: View {
    let result: PortScanResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Port \(result.port)")
                            .font(.headline)
                        
                        if let service = result.service {
                            Text(service)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    
                    if let version = result.version {
                        Text("Version: \(version)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text(result.riskLevel.rawValue)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(result.riskLevel.color.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
            
            if let banner = result.banner {
                Text(banner)
                    .font(.caption)
                    .fontDesign(.monospaced)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 8)
    }
}

struct VulnerabilityDetailRow: View {
    let vulnerability: Vulnerability
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(vulnerability.title)
                        .font(.headline)
                    
                    if let cveId = vulnerability.cveId {
                        Text(cveId)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                Text(vulnerability.severity.rawValue.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(vulnerability.severity.color.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
            
            Text(vulnerability.description)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)
        }
        .padding(.vertical, 8)
    }
}

struct AttackGraphVisualization: View {
    let vectors: [IntelligentAttackVector]
    let services: [PortScanResult]
    
    var body: some View {
        // This would be a complex visualization showing attack paths
        VStack {
            Text("Attack Graph Visualization")
                .font(.headline)
            
            Text("Shows relationships between services and attack vectors")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Placeholder for actual graph
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .overlay(
                    Text("Interactive Attack Graph")
                        .foregroundColor(.secondary)
                )
        }
        .padding()
    }
}

struct AttackPlanView: View {
    let vectors: [IntelligentAttackVector]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Attack Execution Plan")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("\(vectors.count) attack vectors selected")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.controlBackgroundColor))
                
                // Content
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(Array(vectors.enumerated()), id: \.element.id) { index, vector in
                            AttackPlanStep(
                                step: index + 1,
                                vector: vector
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Attack Plan")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Execute Plan") {
                        // Execute the attack plan
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

struct AttackPlanStep: View {
    let step: Int
    let vector: IntelligentAttackVector
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Text("Step \(step)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.2))
                        .cornerRadius(4)
                    
                    Text(vector.name)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text(vector.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    if !vector.prerequisites.isEmpty {
                        HStack {
                            Text("Prerequisites:")
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Text(vector.prerequisites.joined(separator: ", "))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Tools and commands
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Execution:")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        ForEach(vector.tools, id: \.name) { tool in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "terminal")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    
                                    Text(tool.name)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)
                                }
                                
                                Text(tool.command)
                                    .font(.caption)
                                    .fontDesign(.monospaced)
                                    .padding(8)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(4)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                    
                    HStack {
                        Label("Duration: ~\(vector.estimatedDuration)s", systemImage: "clock")
                        Spacer()
                        Label("Detection: \(vector.detectionRisk)", systemImage: "eye")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(.leading, 20)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Types

struct RiskMeter: View {
    let level: RiskLevel
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                .frame(width: 80, height: 80)
            
            Circle()
                .trim(from: 0, to: level.percentage)
                .stroke(level.color, lineWidth: 8)
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))
            
            VStack(spacing: 2) {
                Image(systemName: level.icon)
                    .font(.title2)
                    .foregroundColor(level.color)
                
                Text(level.abbreviation)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(level.color)
            }
        }
    }
}

enum RiskLevel: String {
    case critical = "Critical"
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    
    var percentage: Double {
        switch self {
        case .critical: return 1.0
        case .high: return 0.75
        case .medium: return 0.5
        case .low: return 0.25
        }
    }
    
    var color: Color {
        switch self {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        }
    }
    
    var icon: String {
        switch self {
        case .critical: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.circle.fill"
        case .medium: return "exclamationmark.circle"
        case .low: return "checkmark.circle"
        }
    }
    
    var abbreviation: String {
        switch self {
        case .critical: return "CRIT"
        case .high: return "HIGH"
        case .medium: return "MED"
        case .low: return "LOW"
        }
    }
}

#Preview {
    UnifiedScannerView()
        .environment(AppState())
        .frame(width: 1400, height: 900)
}
