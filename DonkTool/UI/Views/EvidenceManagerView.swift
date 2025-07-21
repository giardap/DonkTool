//
//  EvidenceManagerView.swift
//  DonkTool
//
//  Evidence management and viewing interface
//

import SwiftUI

struct EvidenceManagerView: View {
    @Environment(AppState.self) private var appState
    @State private var evidenceManager = EvidenceManager.shared
    @State private var selectedPackage: EvidencePackage?
    @State private var showingPackageDetail = false
    @State private var showingDeleteConfirmation = false
    @State private var packageToDelete: EvidencePackage?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    Text("Evidence Manager")
                        .font(.headerPrimary)
                    
                    Spacer()
                    
                    // Statistics
                    HStack(spacing: 16) {
                        StatisticView(
                            title: "Packages",
                            value: "\(evidenceManager.evidencePackages.count)",
                            icon: "folder.fill",
                            color: .blue
                        )
                        
                        StatisticView(
                            title: "Total Vulnerabilities",
                            value: "\(evidenceManager.evidencePackages.reduce(0) { $0 + $1.summary.totalVulnerabilities })",
                            icon: "exclamationmark.triangle.fill",
                            color: .orange
                        )
                        
                        StatisticView(
                            title: "Credentials Found",
                            value: "\(evidenceManager.evidencePackages.reduce(0) { $0 + $1.summary.credentialsFound })",
                            icon: "key.fill",
                            color: .red
                        )
                    }
                }
                
                // Progress indicator
                if evidenceManager.isGeneratingEvidence {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "doc.badge.plus")
                                .foregroundColor(.blue)
                            
                            Text("Generating Evidence Package...")
                                .font(.captionPrimary)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(Int(evidenceManager.currentProgress * 100))%")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        
                        ProgressView(value: evidenceManager.currentProgress)
                            .progressViewStyle(.linear)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
            .standardContainer()
            
            Divider()
            
            // Evidence packages list
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Evidence Packages")
                        .font(.headerSecondary)
                    
                    Spacer()
                    
                    if !evidenceManager.evidencePackages.isEmpty {
                        Text("\(evidenceManager.evidencePackages.count) packages")
                            .font(.captionPrimary)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                if evidenceManager.evidencePackages.isEmpty {
                    ContentUnavailableView(
                        "No Evidence Packages",
                        systemImage: "folder",
                        description: Text("Evidence packages will appear here after attack executions")
                    )
                } else {
                    List(evidenceManager.evidencePackages.sorted { $0.timestamp > $1.timestamp }, id: \.id) { package in
                        EvidencePackageRowView(
                            package: package,
                            onViewTapped: {
                                selectedPackage = package
                                showingPackageDetail = true
                            },
                            onDeleteTapped: {
                                packageToDelete = package
                                showingDeleteConfirmation = true
                            },
                            onExportTapped: {
                                exportPackage(package)
                            }
                        )
                    }
                    .listStyle(.plain)
                }
            }
        }
        .sheet(isPresented: $showingPackageDetail) {
            if let package = selectedPackage {
                EvidencePackageDetailView(package: package)
            }
        }
        .alert("Delete Evidence Package", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let package = packageToDelete {
                    evidenceManager.deleteEvidencePackage(package)
                }
            }
        } message: {
            Text("Are you sure you want to delete this evidence package? This action cannot be undone.")
        }
    }
    
    private func exportPackage(_ package: EvidencePackage) {
        if let exportURL = evidenceManager.exportEvidencePackage(package) {
            // Open in Finder or share
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: exportURL.path)
        }
    }
}

struct EvidencePackageRowView: View {
    let package: EvidencePackage
    let onViewTapped: () -> Void
    let onDeleteTapped: () -> Void
    let onExportTapped: () -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Package info
                VStack(alignment: .leading, spacing: 4) {
                    Text(package.attackName)
                        .font(.headerTertiary)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 8) {
                        Text("\(package.target):\(package.port)")
                            .font(.captionPrimary)
                            .foregroundColor(.blue)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(package.timestamp, style: .relative)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Status and metrics
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 8) {
                        if package.success {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.orange)
                        }
                        
                        Text(String(format: "%.1fs", package.duration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 12) {
                        if package.summary.totalVulnerabilities > 0 {
                            Label("\(package.summary.totalVulnerabilities)", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        
                        if package.summary.credentialsFound > 0 {
                            Label("\(package.summary.credentialsFound)", systemImage: "key.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        Label("\(package.evidenceFiles.count)", systemImage: "doc.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                // Expand button
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
            
            // Expandable content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                    
                    // Evidence files
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Evidence Files (\(package.evidenceFiles.count))")
                            .font(.captionPrimary)
                            .fontWeight(.medium)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(package.evidenceFiles) { file in
                                EvidenceFileCardView(file: file)
                            }
                        }
                    }
                    
                    // Actions
                    HStack(spacing: 12) {
                        Button("View Details") {
                            onViewTapped()
                        }
                        .primaryButton()
                        
                        Button("Export") {
                            onExportTapped()
                        }
                        .secondaryButton()
                        
                        Spacer()
                        
                        Button("Delete") {
                            onDeleteTapped()
                        }
                        .destructiveButton()
                    }
                }
                .padding(.top, 8)
                .padding(.leading, 12)
                .overlay(
                    Rectangle()
                        .frame(width: 2)
                        .foregroundColor(.blue.opacity(0.3)),
                    alignment: .leading
                )
            }
        }
        .padding(.vertical, 8)
    }
}

struct EvidenceFileCardView: View {
    let file: EvidenceFile
    
    var body: some View {
        Button(action: {
            NSWorkspace.shared.open(URL(fileURLWithPath: file.filepath))
        }) {
            HStack(spacing: 8) {
                Image(systemName: file.type.icon)
                    .font(.system(size: 14))
                    .foregroundColor(file.type.color)
                    .frame(width: 16)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(file.filename)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text(formatFileSize(file.size))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer(minLength: 0)
                
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 12))
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(file.type.color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct EvidencePackageDetailView: View {
    let package: EvidencePackage
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Package header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(package.attackName)
                            .font(.headerSecondary)
                            .fontWeight(.bold)
                        
                        HStack {
                            Label("\(package.target):\(package.port)", systemImage: "network")
                            Spacer()
                            Label(package.timestamp.formatted(), systemImage: "clock")
                        }
                        .font(.captionPrimary)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .standardContainer()
                    
                    // Summary statistics
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Risk Summary")
                            .font(.headerTertiary)
                            .fontWeight(.medium)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            RiskStatView(
                                title: "Critical",
                                count: package.summary.criticalVulnerabilities,
                                color: .red
                            )
                            
                            RiskStatView(
                                title: "High",
                                count: package.summary.highVulnerabilities,
                                color: .orange
                            )
                            
                            RiskStatView(
                                title: "Medium",
                                count: package.summary.mediumVulnerabilities,
                                color: .yellow
                            )
                            
                            RiskStatView(
                                title: "Low",
                                count: package.summary.lowVulnerabilities,
                                color: .green
                            )
                            
                            RiskStatView(
                                title: "Credentials",
                                count: package.summary.credentialsFound,
                                color: .purple
                            )
                            
                            RiskStatView(
                                title: "Files Found",
                                count: package.summary.directoriesFound,
                                color: .blue
                            )
                        }
                    }
                    .padding()
                    .standardContainer()
                    
                    // Evidence files
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Evidence Files")
                            .font(.headerTertiary)
                            .fontWeight(.medium)
                        
                        ForEach(package.evidenceFiles) { file in
                            EvidenceFileDetailView(file: file)
                        }
                    }
                    .padding()
                    .standardContainer()
                    
                    // Recommendations
                    if !package.summary.recommendedActions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recommended Actions")
                                .font(.headerTertiary)
                                .fontWeight(.medium)
                            
                            ForEach(Array(package.summary.recommendedActions.enumerated()), id: \.offset) { index, action in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("\(index + 1).")
                                        .font(.captionPrimary)
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)
                                    
                                    Text(action)
                                        .font(.bodyPrimary)
                                }
                            }
                        }
                        .padding()
                        .standardContainer()
                    }
                }
                .padding()
            }
            .navigationTitle("Evidence Package")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct EvidenceFileDetailView: View {
    let file: EvidenceFile
    
    var body: some View {
        Button(action: {
            NSWorkspace.shared.open(URL(fileURLWithPath: file.filepath))
        }) {
            HStack(spacing: 12) {
                Image(systemName: file.type.icon)
                    .font(.title2)
                    .foregroundColor(file.type.color)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(file.filename)
                        .font(.captionPrimary)
                        .fontWeight(.medium)
                    
                    Text(file.description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text(formatFileSize(file.size))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text("Checksum: \(file.checksum)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right.square")
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(file.type.color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct RiskStatView: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.headerTertiary)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Extensions

extension EvidenceFile.EvidenceType {
    var icon: String {
        switch self {
        case .console_output:
            return "terminal"
        case .vulnerability_report:
            return "exclamationmark.triangle"
        case .credential_list:
            return "key"
        case .network_scan:
            return "network"
        case .directory_listing:
            return "folder"
        case .screenshot:
            return "camera"
        case .packet_capture:
            return "waveform.path"
        case .exploit_code:
            return "code"
        case .summary_report:
            return "doc.text"
        case .raw_data:
            return "doc.plaintext"
        }
    }
    
    var color: Color {
        switch self {
        case .console_output:
            return .primary
        case .vulnerability_report:
            return .orange
        case .credential_list:
            return .red
        case .network_scan:
            return .blue
        case .directory_listing:
            return .green
        case .screenshot:
            return .purple
        case .packet_capture:
            return .cyan
        case .exploit_code:
            return .pink
        case .summary_report:
            return .indigo
        case .raw_data:
            return .gray
        }
    }
}

#Preview {
    EvidenceManagerView()
        .environment(AppState())
}