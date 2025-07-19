//
//  CVEDetailView.swift
//  DonkTool
//
//  Detailed CVE Information View
//

import SwiftUI

struct AdvancedCVEDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let cve: CVEEntry
    @StateObject private var exploitDB = ExploitDatabase.shared
    @State private var relatedExploits: [ExploitEntry] = []
    @State private var relatedMetasploitModules: [MetasploitModule] = []
    @State private var showingCVSSCalculator = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    vulnerabilityDetailsSection
                    cvssSection
                    affectedProductsSection
                    
                    if !relatedExploits.isEmpty {
                        relatedExploitsSection
                    }
                    
                    if !relatedMetasploitModules.isEmpty {
                        relatedMetasploitSection
                    }
                    
                    referencesSection
                }
                .padding()
            }
            .navigationTitle(cve.id)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await loadRelatedData()
        }
        .sheet(isPresented: $showingCVSSCalculator) {
            CVSSCalculatorView(cve: cve)
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(cve.id)
                    .font(.largeTitle)
                    .bold()
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(String(format: "%.1f", cve.cvssScore))
                        .font(.title)
                        .bold()
                        .foregroundColor(cve.severity.color)
                    
                    Text(cve.severity.rawValue)
                        .font(.headline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(cve.severity.color.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            
            if cve.exploitAvailable {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Exploit Available")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Spacer()
                    
                    Text(cve.exploitMaturity.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.2))
                        .cornerRadius(6)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    private var vulnerabilityDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Vulnerability Details")
                .font(.headline)
            
            Text(cve.description)
                .font(.body)
                .lineSpacing(4)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Published")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(cve.publishedDate, style: .date)
                        .font(.subheadline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Last Modified")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(cve.lastModified, style: .date)
                        .font(.subheadline)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            if let cweId = cve.cweId {
                HStack {
                    Text("CWE Classification:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(cweId)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                }
            }
        }
    }
    
    private var cvssSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("CVSS Scoring")
                    .font(.headline)
                
                Spacer()
                
                Button("Calculator") {
                    showingCVSSCalculator = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Base Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f", cve.cvssScore))
                        .font(.title2)
                        .bold()
                        .foregroundColor(cve.severity.color)
                }
                
                Spacer()
                
                VStack(alignment: .center) {
                    Text("Severity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(cve.severity.rawValue)
                        .font(.subheadline)
                        .bold()
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Priority")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(cve.severity.priority)/5")
                        .font(.subheadline)
                        .bold()
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            // CVSS Vector visualization
            CVSSVectorView(score: cve.cvssScore, severity: cve.severity)
        }
    }
    
    private var affectedProductsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Affected Products")
                .font(.headline)
            
            if cve.affectedProducts.isEmpty {
                Text("No specific products listed")
                    .font(.body)
                    .foregroundColor(.secondary)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(cve.affectedProducts, id: \.self) { product in
                        Text(product)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(6)
                    }
                }
            }
        }
    }
    
    private var relatedExploitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Related Exploits (\(relatedExploits.count))")
                .font(.headline)
            
            ForEach(relatedExploits.prefix(3)) { exploit in
                ExploitRow(exploit: exploit) {
                    // Handle exploit selection
                }
            }
            
            if relatedExploits.count > 3 {
                Text("+ \(relatedExploits.count - 3) more exploits")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.leading)
            }
        }
    }
    
    private var relatedMetasploitSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Metasploit Modules (\(relatedMetasploitModules.count))")
                .font(.headline)
            
            ForEach(relatedMetasploitModules.prefix(3)) { module in
                MetasploitModuleRow(module: module)
            }
            
            if relatedMetasploitModules.count > 3 {
                Text("+ \(relatedMetasploitModules.count - 3) more modules")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.leading)
            }
        }
    }
    
    private var referencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("References")
                .font(.headline)
            
            if cve.references.isEmpty {
                Text("No references available")
                    .font(.body)
                    .foregroundColor(.secondary)
            } else {
                ForEach(cve.references, id: \.self) { reference in
                    Link(destination: URL(string: reference) ?? URL(string: "https://example.com")!) {
                        HStack {
                            Image(systemName: "link")
                                .foregroundColor(.blue)
                            Text(reference)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
    
    private func loadRelatedData() async {
        // Search for related exploits
        relatedExploits = await exploitDB.searchExploits(cve: cve.id)
        
        // Search for related Metasploit modules
        relatedMetasploitModules = exploitDB.searchMetasploitModules(query: cve.id)
    }
}

struct CVSSVectorView: View {
    let score: Double
    let severity: CVEEntry.Severity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CVSS Vector Visualization")
                .font(.subheadline)
                .bold()
            
            HStack {
                // Attack Vector
                VStack {
                    Text("AV")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Circle()
                        .fill(vectorColor)
                        .frame(width: 20, height: 20)
                }
                
                // Attack Complexity
                VStack {
                    Text("AC")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Circle()
                        .fill(complexityColor)
                        .frame(width: 20, height: 20)
                }
                
                // Privileges Required
                VStack {
                    Text("PR")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Circle()
                        .fill(privilegesColor)
                        .frame(width: 20, height: 20)
                }
                
                // User Interaction
                VStack {
                    Text("UI")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Circle()
                        .fill(interactionColor)
                        .frame(width: 20, height: 20)
                }
                
                Spacer()
                
                // Overall score bar
                VStack(alignment: .trailing) {
                    Text("Score")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: score / 10.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: severity.color))
                        .frame(width: 60)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    // Simplified color mapping based on score ranges
    private var vectorColor: Color {
        score >= 8.0 ? .red : score >= 6.0 ? .orange : .green
    }
    
    private var complexityColor: Color {
        score >= 7.0 ? .red : score >= 4.0 ? .orange : .green
    }
    
    private var privilegesColor: Color {
        score >= 8.5 ? .green : score >= 5.0 ? .orange : .red
    }
    
    private var interactionColor: Color {
        score >= 8.0 ? .green : .orange
    }
}

struct CVSSCalculatorView: View {
    @Environment(\.dismiss) private var dismiss
    let cve: CVEEntry
    @StateObject private var exploitDB = ExploitDatabase.shared
    
    // CVSS Metrics
    @State private var attackVector: CVSSMetrics.AttackVector = .network
    @State private var attackComplexity: CVSSMetrics.AttackComplexity = .low
    @State private var privilegesRequired: CVSSMetrics.PrivilegesRequired = .none
    @State private var userInteraction: CVSSMetrics.UserInteraction = .none
    @State private var scope: CVSSMetrics.Scope = .unchanged
    @State private var confidentialityImpact: CVSSMetrics.Impact = .high
    @State private var integrityImpact: CVSSMetrics.Impact = .high
    @State private var availabilityImpact: CVSSMetrics.Impact = .high
    
    @State private var calculatedScore: CVSSScore?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Base Metrics")) {
                    Picker("Attack Vector", selection: $attackVector) {
                        ForEach(CVSSMetrics.AttackVector.allCases, id: \.self) { vector in
                            Text(vector.rawValue).tag(vector)
                        }
                    }
                    
                    Picker("Attack Complexity", selection: $attackComplexity) {
                        ForEach(CVSSMetrics.AttackComplexity.allCases, id: \.self) { complexity in
                            Text(complexity.rawValue).tag(complexity)
                        }
                    }
                    
                    Picker("Privileges Required", selection: $privilegesRequired) {
                        ForEach(CVSSMetrics.PrivilegesRequired.allCases, id: \.self) { privileges in
                            Text(privileges.rawValue).tag(privileges)
                        }
                    }
                    
                    Picker("User Interaction", selection: $userInteraction) {
                        ForEach(CVSSMetrics.UserInteraction.allCases, id: \.self) { interaction in
                            Text(interaction.rawValue).tag(interaction)
                        }
                    }
                    
                    Picker("Scope", selection: $scope) {
                        ForEach(CVSSMetrics.Scope.allCases, id: \.self) { scope in
                            Text(scope.rawValue).tag(scope)
                        }
                    }
                }
                
                Section(header: Text("Impact Metrics")) {
                    Picker("Confidentiality", selection: $confidentialityImpact) {
                        ForEach(CVSSMetrics.Impact.allCases, id: \.self) { impact in
                            Text(impact.rawValue).tag(impact)
                        }
                    }
                    
                    Picker("Integrity", selection: $integrityImpact) {
                        ForEach(CVSSMetrics.Impact.allCases, id: \.self) { impact in
                            Text(impact.rawValue).tag(impact)
                        }
                    }
                    
                    Picker("Availability", selection: $availabilityImpact) {
                        ForEach(CVSSMetrics.Impact.allCases, id: \.self) { impact in
                            Text(impact.rawValue).tag(impact)
                        }
                    }
                }
                
                if let score = calculatedScore {
                    Section(header: Text("Calculated Score")) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Base Score:")
                                    .bold()
                                Spacer()
                                Text(String(format: "%.1f", score.baseScore))
                                    .bold()
                                    .foregroundColor(score.severity.color)
                            }
                            
                            HStack {
                                Text("Severity:")
                                    .bold()
                                Spacer()
                                Text(score.severity.rawValue)
                                    .bold()
                                    .foregroundColor(score.severity.color)
                            }
                            
                            Text("Vector: \(score.vector)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("CVSS Calculator")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Calculate") {
                        calculateScore()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            calculateScore()
        }
        .onChange(of: attackVector) { _, _ in calculateScore() }
        .onChange(of: attackComplexity) { _, _ in calculateScore() }
        .onChange(of: privilegesRequired) { _, _ in calculateScore() }
        .onChange(of: userInteraction) { _, _ in calculateScore() }
        .onChange(of: scope) { _, _ in calculateScore() }
        .onChange(of: confidentialityImpact) { _, _ in calculateScore() }
        .onChange(of: integrityImpact) { _, _ in calculateScore() }
        .onChange(of: availabilityImpact) { _, _ in calculateScore() }
    }
    
    private func calculateScore() {
        let metrics = CVSSMetrics(
            attackVector: attackVector,
            attackComplexity: attackComplexity,
            privilegesRequired: privilegesRequired,
            userInteraction: userInteraction,
            scope: scope,
            confidentialityImpact: confidentialityImpact,
            integrityImpact: integrityImpact,
            availabilityImpact: availabilityImpact,
            exploitCodeMaturity: nil,
            remediationLevel: nil,
            reportConfidence: nil
        )
        
        calculatedScore = exploitDB.calculateCVSSScore(metrics: metrics)
    }
}

// MARK: - Component Views

struct ExploitRow: View {
    let exploit: ExploitEntry
    let onSelect: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(exploit.title)
                    .font(.subheadline)
                    .lineLimit(2)
                
                Text("by \(exploit.author)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("View") {
                onSelect()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(6)
    }
}

struct MetasploitModuleRow: View {
    let module: MetasploitModule
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(module.name)
                    .font(.subheadline)
                
                Text(module.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Text(module.rank.rawValue)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(module.rank.color.opacity(0.2))
                .cornerRadius(4)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(6)
    }
}

#Preview {
    AdvancedCVEDetailView(cve: CVEEntry(
        id: "CVE-2024-1234",
        description: "Remote code execution vulnerability in Example Software that allows attackers to execute arbitrary code with elevated privileges.",
        cvssScore: 9.8,
        severity: .critical,
        publishedDate: Date(),
        lastModified: Date(),
        affectedProducts: ["Example Software 1.0", "Example Software 1.1"],
        exploitAvailable: true,
        exploitMaturity: .functional,
        references: ["https://example.com/advisory", "https://nvd.nist.gov/vuln/detail/CVE-2024-1234"],
        cweId: "CWE-78"
    ))
}