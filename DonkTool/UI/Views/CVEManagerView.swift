//
//  CVEManagerView.swift
//  DonkTool
//
//  Ultra-modern CVE management interface with advanced search and filtering
//

import SwiftUI
import Charts

struct CVEManagerView: View {
    @Environment(AppState.self) private var appState
    @State private var searchText = ""
    @State private var selectedSeverities = Set<String>()
    @State private var selectedDateRange = DateRange.all
    @State private var isShowingDetail = false
    @State private var selectedCVE: CVEItem? = nil
    @State private var showingAdvancedFilters = false
    @State private var sortOrder = SortOrder.scoreDescending
    @State private var viewMode = ViewMode.list
    
    private let severityOptions = ["Critical", "High", "Medium", "Low"]
    
    enum DateRange: String, CaseIterable {
        case all = "All Time"
        case lastWeek = "Last Week"
        case lastMonth = "Last Month"
        case lastYear = "Last Year"
        
        var systemImage: String {
            switch self {
            case .all: return "infinity"
            case .lastWeek: return "7.circle"
            case .lastMonth: return "30.circle"
            case .lastYear: return "calendar"
            }
        }
    }
    
    enum SortOrder: String, CaseIterable {
        case scoreDescending = "Score (High to Low)"
        case scoreAscending = "Score (Low to High)"
        case dateNewest = "Date (Newest First)"
        case dateOldest = "Date (Oldest First)"
        
        var systemImage: String {
            switch self {
            case .scoreDescending: return "arrow.down.circle"
            case .scoreAscending: return "arrow.up.circle"
            case .dateNewest: return "clock.arrow.circlepath"
            case .dateOldest: return "clock.arrow.2.circlepath"
            }
        }
    }
    
    enum ViewMode: String, CaseIterable {
        case list = "List"
        case grid = "Grid"
        case chart = "Chart"
        
        var systemImage: String {
            switch self {
            case .list: return "list.bullet"
            case .grid: return "square.grid.2x2"
            case .chart: return "chart.bar.xaxis"
            }
        }
    }
    
    var filteredCVEs: [CVEItem] {
        var filtered = appState.cveDatabase.searchCVEs(query: searchText)
        
        // Severity filter
        if !selectedSeverities.isEmpty {
            filtered = filtered.filter { cve in
                if let severity = cve.baseSeverity {
                    return selectedSeverities.contains(severity.capitalized)
                }
                return false
            }
        }
        
        // Date range filter
        if selectedDateRange != .all {
            let calendar = Calendar.current
            let now = Date()
            var cutoffDate: Date?
            
            switch selectedDateRange {
            case .lastWeek:
                cutoffDate = calendar.date(byAdding: .day, value: -7, to: now)
            case .lastMonth:
                cutoffDate = calendar.date(byAdding: .month, value: -1, to: now)
            case .lastYear:
                cutoffDate = calendar.date(byAdding: .year, value: -1, to: now)
            default:
                break
            }
            
            if let cutoff = cutoffDate {
                filtered = filtered.filter { $0.publishedDate >= cutoff }
            }
        }
        
        // Sort
        switch sortOrder {
        case .scoreDescending:
            filtered.sort { ($0.baseScore ?? 0) > ($1.baseScore ?? 0) }
        case .scoreAscending:
            filtered.sort { ($0.baseScore ?? 0) < ($1.baseScore ?? 0) }
        case .dateNewest:
            filtered.sort { $0.publishedDate > $1.publishedDate }
        case .dateOldest:
            filtered.sort { $0.publishedDate < $1.publishedDate }
        }
        
        return filtered
    }
    
    var severityDistribution: [(String, Int)] {
        let grouped = Dictionary(grouping: filteredCVEs) { cve -> String in
            cve.baseSeverity?.capitalized ?? "Unknown"
        }
        return grouped.map { ($0.key, $0.value.count) }.sorted { $0.1 > $1.1 }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Modern Header
            VStack(spacing: 20) {
                // Title and Actions
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CVE Database")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("\(filteredCVEs.count) vulnerabilities")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // View Mode Picker
                    Picker("View Mode", selection: $viewMode) {
                        ForEach(ViewMode.allCases, id: \.self) { mode in
                            Label(mode.rawValue, systemImage: mode.systemImage)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                    
                    // Update Database Button
                    Button(action: {
                        Task {
                            await appState.cveDatabase.updateDatabase()
                        }
                    }) {
                        Label("Update", systemImage: "arrow.triangle.2.circlepath")
                            .symbolEffect(.bounce, value: appState.cveDatabase.isLoading)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(appState.cveDatabase.isLoading)
                }
                
                // Search and Filters
                HStack(spacing: 16) {
                    // Enhanced Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16, weight: .medium))
                        
                        TextField("Search CVE ID, description, or keywords...", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14))
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 14))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(10)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(10)
                    
                    // Quick Filters
                    HStack(spacing: 8) {
                        // Severity Pills
                        ForEach(severityOptions, id: \.self) { severity in
                            FilterPill(
                                label: severity,
                                isSelected: selectedSeverities.contains(severity),
                                color: colorForSeverity(severity),
                                action: {
                                    if selectedSeverities.contains(severity) {
                                        selectedSeverities.remove(severity)
                                    } else {
                                        selectedSeverities.insert(severity)
                                    }
                                }
                            )
                        }
                        
                        Divider()
                            .frame(height: 20)
                        
                        // Date Range
                        Menu {
                            ForEach(DateRange.allCases, id: \.self) { range in
                                Button(action: { selectedDateRange = range }) {
                                    Label(range.rawValue, systemImage: range.systemImage)
                                }
                            }
                        } label: {
                            Label(selectedDateRange.rawValue, systemImage: "calendar")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(8)
                        }
                        
                        // Sort Order
                        Menu {
                            ForEach(SortOrder.allCases, id: \.self) { order in
                                Button(action: { sortOrder = order }) {
                                    Label(order.rawValue, systemImage: order.systemImage)
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                                .padding(8)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(8)
                        }
                        
                        // Advanced Filters
                        Button(action: { showingAdvancedFilters.toggle() }) {
                            Image(systemName: "slider.horizontal.3")
                                .padding(8)
                                .background(showingAdvancedFilters ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                                .foregroundColor(showingAdvancedFilters ? .white : .primary)
                                .cornerRadius(8)
                        }
                    }
                }
                
                // Stats Bar
                if viewMode != .chart {
                    ModernStatsBar(cves: filteredCVEs)
                }
            }
            .padding(24)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Content Area
            Group {
                switch viewMode {
                case .list:
                    CVEListView(cves: filteredCVEs, selectedCVE: $selectedCVE, showingDetail: $isShowingDetail)
                case .grid:
                    CVEGridView(cves: filteredCVEs, selectedCVE: $selectedCVE, showingDetail: $isShowingDetail)
                case .chart:
                    CVEChartView(cves: filteredCVEs, distribution: severityDistribution)
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
        }
        .sheet(isPresented: $isShowingDetail) {
            if let cve = selectedCVE {
                ModernCVEDetailView(cve: cve)
            }
        }
        .sheet(isPresented: $showingAdvancedFilters) {
            AdvancedFiltersView()
        }
        .task {
            // Add small delay to prevent publishing during view updates
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms delay
            if appState.cveDatabase.cves.isEmpty && !appState.cveDatabase.isLoading {
                await appState.cveDatabase.updateDatabase()
            }
        }
    }
    
    private func colorForSeverity(_ severity: String) -> Color {
        switch severity.lowercased() {
        case "critical": return .red
        case "high": return .orange
        case "medium": return .yellow
        case "low": return .blue
        default: return .gray
        }
    }
}

// Filter Pill Component
struct FilterPill: View {
    let label: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : Color(NSColor.controlBackgroundColor))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.clear : color.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// Modern Stats Bar
struct ModernStatsBar: View {
    let cves: [CVEItem]
    
    var stats: (critical: Int, high: Int, medium: Int, low: Int, avgScore: Double) {
        let severityCounts = Dictionary(grouping: cves) { cve in
            cve.baseSeverity?.lowercased() ?? "unknown"
        }
        
        let avgScore = cves.compactMap { $0.baseScore }.reduce(0, +) / Double(max(cves.count, 1))
        
        return (
            critical: severityCounts["critical"]?.count ?? 0,
            high: severityCounts["high"]?.count ?? 0,
            medium: severityCounts["medium"]?.count ?? 0,
            low: severityCounts["low"]?.count ?? 0,
            avgScore: avgScore
        )
    }
    
    var body: some View {
        HStack(spacing: 20) {
            CVEStatCard(title: "Critical", value: "\(stats.critical)", color: .red, icon: "exclamationmark.triangle.fill")
            CVEStatCard(title: "High", value: "\(stats.high)", color: .orange, icon: "exclamationmark.circle.fill")
            CVEStatCard(title: "Medium", value: "\(stats.medium)", color: .yellow, icon: "exclamationmark.square.fill")
            CVEStatCard(title: "Low", value: "\(stats.low)", color: .blue, icon: "info.circle.fill")
            CVEStatCard(title: "Avg Score", value: String(format: "%.1f", stats.avgScore), color: .purple, icon: "chart.line.uptrend.xyaxis")
        }
    }
}

// Stat Card Component
struct CVEStatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 18, weight: .semibold))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
}

// List View
struct CVEListView: View {
    let cves: [CVEItem]
    @Binding var selectedCVE: CVEItem?
    @Binding var showingDetail: Bool
    
    var body: some View {
        if cves.isEmpty {
            ContentUnavailableView(
                "No CVEs Found",
                systemImage: "shield.slash",
                description: Text("Try adjusting your filters or update the database")
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(cves) { cve in
                        ModernCVERow(cve: cve)
                            .onTapGesture {
                                selectedCVE = cve
                                showingDetail = true
                            }
                    }
                }
                .padding(20)
            }
        }
    }
}

// Modern CVE Row
struct ModernCVERow: View {
    let cve: CVEItem
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Severity Indicator
            RoundedRectangle(cornerRadius: 4)
                .fill(colorForSeverity(cve.baseSeverity ?? ""))
                .frame(width: 4)
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(cve.id)
                        .font(.system(size: 16, weight: .semibold))
                    
                    Spacer()
                    
                    if let score = cve.baseScore {
                        HStack(spacing: 8) {
                            Text(String(format: "%.1f", score))
                                .font(.system(size: 14, weight: .medium))
                            
                            if let severity = cve.baseSeverity {
                                Text(severity.uppercased())
                                    .font(.system(size: 11, weight: .bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(colorForSeverity(severity).opacity(0.2))
                                    .foregroundColor(colorForSeverity(severity))
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
                
                Text(cve.description)
                    .font(.system(size: 13))
                    .lineLimit(2)
                    .foregroundColor(.secondary)
                
                HStack {
                    Label(cve.publishedDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if !cve.references.isEmpty {
                        Label("\(cve.references.count) references", systemImage: "link")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Arrow
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .opacity(isHovered ? 1 : 0.5)
        }
        .padding(16)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .scaleEffect(isHovered ? 1.02 : 1)
        .animation(.easeOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private func colorForSeverity(_ severity: String) -> Color {
        switch severity.lowercased() {
        case "critical": return .red
        case "high": return .orange
        case "medium": return .yellow
        case "low": return .blue
        default: return .gray
        }
    }
}

// Grid View
struct CVEGridView: View {
    let cves: [CVEItem]
    @Binding var selectedCVE: CVEItem?
    @Binding var showingDetail: Bool
    
    let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 16)
    ]
    
    var body: some View {
        if cves.isEmpty {
            ContentUnavailableView(
                "No CVEs Found",
                systemImage: "shield.slash",
                description: Text("Try adjusting your filters or update the database")
            )
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(cves) { cve in
                        CVEGridCard(cve: cve)
                            .onTapGesture {
                                selectedCVE = cve
                                showingDetail = true
                            }
                    }
                }
                .padding(20)
            }
        }
    }
}

// CVE Grid Card
struct CVEGridCard: View {
    let cve: CVEItem
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(cve.id)
                    .font(.system(size: 14, weight: .semibold))
                
                Spacer()
                
                if let severity = cve.baseSeverity {
                    Text(severity.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(colorForSeverity(severity))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
            }
            
            // Score
            if let score = cve.baseScore {
                HStack(spacing: 4) {
                    Image(systemName: "gauge.medium")
                        .font(.system(size: 12))
                    Text(String(format: "%.1f", score))
                        .font(.system(size: 20, weight: .semibold))
                }
                .foregroundColor(colorForSeverity(cve.baseSeverity ?? ""))
            }
            
            // Description
            Text(cve.description)
                .font(.system(size: 12))
                .lineLimit(3)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Footer
            HStack {
                Label(cve.publishedDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !cve.references.isEmpty {
                    Label("\(cve.references.count)", systemImage: "link")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .frame(height: 180)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(color: .black.opacity(isHovered ? 0.1 : 0.05), radius: isHovered ? 8 : 4, x: 0, y: 2)
        .scaleEffect(isHovered ? 1.02 : 1)
        .animation(.easeOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private func colorForSeverity(_ severity: String) -> Color {
        switch severity.lowercased() {
        case "critical": return .red
        case "high": return .orange
        case "medium": return .yellow
        case "low": return .blue
        default: return .gray
        }
    }
}

// Chart View
struct CVEChartView: View {
    let cves: [CVEItem]
    let distribution: [(String, Int)]
    
    var monthlyData: [(month: String, count: Int)] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        
        let grouped = Dictionary(grouping: cves) { cve in
            formatter.string(from: cve.publishedDate)
        }
        
        return grouped.map { (month: $0.key, count: $0.value.count) }
            .sorted { $0.month < $1.month }
            .suffix(12)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Severity Distribution
                VStack(alignment: .leading, spacing: 12) {
                    Text("Severity Distribution")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Chart(distribution, id: \.0) { item in
                        BarMark(
                            x: .value("Count", item.1),
                            y: .value("Severity", item.0)
                        )
                        .foregroundStyle(colorForSeverity(item.0).gradient)
                        .cornerRadius(6)
                    }
                    .frame(height: 200)
                }
                .padding(20)
                .background(Color(NSColor.windowBackgroundColor))
                .cornerRadius(12)
                
                // Timeline
                VStack(alignment: .leading, spacing: 12) {
                    Text("CVE Timeline (Last 12 Months)")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Chart(monthlyData, id: \.month) { item in
                        BarMark(
                            x: .value("Month", item.month),
                            y: .value("Count", item.count)
                        )
                        .foregroundStyle(Color.accentColor.gradient)
                        .cornerRadius(4)
                    }
                    .frame(height: 200)
                }
                .padding(20)
                .background(Color(NSColor.windowBackgroundColor))
                .cornerRadius(12)
                
                // Score Distribution
                VStack(alignment: .leading, spacing: 12) {
                    Text("CVSS Score Distribution")
                        .font(.system(size: 18, weight: .semibold))
                    
                    let scoreRanges = [
                        (range: "0-3", count: cves.filter { ($0.baseScore ?? 0) <= 3 }.count),
                        (range: "3-6", count: cves.filter { let s = $0.baseScore ?? 0; return s > 3 && s <= 6 }.count),
                        (range: "6-9", count: cves.filter { let s = $0.baseScore ?? 0; return s > 6 && s <= 9 }.count),
                        (range: "9-10", count: cves.filter { ($0.baseScore ?? 0) > 9 }.count)
                    ]
                    
                    Chart(scoreRanges, id: \.range) { item in
                        SectorMark(
                            angle: .value("Count", item.count),
                            innerRadius: .ratio(0.5),
                            outerRadius: .ratio(1.0)
                        )
                        .foregroundStyle(by: .value("Range", item.range))
                        .cornerRadius(4)
                    }
                    .frame(height: 200)
                }
                .padding(20)
                .background(Color(NSColor.windowBackgroundColor))
                .cornerRadius(12)
            }
            .padding(20)
        }
    }
    
    private func colorForSeverity(_ severity: String) -> Color {
        switch severity.lowercased() {
        case "critical": return .red
        case "high": return .orange
        case "medium": return .yellow
        case "low": return .blue
        default: return .gray
        }
    }
}

// Modern CVE Detail View
struct ModernCVEDetailView: View {
    let cve: CVEItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(cve.id)
                        .font(.system(size: 28, weight: .bold))
                    
                    HStack(spacing: 16) {
                        if let score = cve.baseScore {
                            HStack(spacing: 8) {
                                Image(systemName: "gauge.medium")
                                    .font(.system(size: 16))
                                Text(String(format: "%.1f", score))
                                    .font(.system(size: 20, weight: .semibold))
                            }
                            .foregroundColor(colorForSeverity(cve.baseSeverity ?? ""))
                        }
                        
                        if let severity = cve.baseSeverity {
                            Text(severity.uppercased())
                                .font(.system(size: 14, weight: .bold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(colorForSeverity(severity))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                }
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding(24)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Description
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Description", systemImage: "text.alignleft")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text(cve.description)
                            .font(.system(size: 14))
                            .textSelection(.enabled)
                    }
                    
                    // Metadata
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Details", systemImage: "info.circle")
                            .font(.system(size: 16, weight: .semibold))
                        
                        VStack(spacing: 8) {
                            DetailRowModern(
                                icon: "calendar",
                                label: "Published",
                                value: cve.publishedDate.formatted(date: .long, time: .shortened)
                            )
                            
                            DetailRowModern(
                                icon: "clock",
                                label: "Last Modified",
                                value: cve.lastModifiedDate.formatted(date: .long, time: .shortened)
                            )
                            
                            if let vectorString = cve.vectorString {
                                DetailRowModern(
                                    icon: "shield.lefthalf.filled",
                                    label: "Vector",
                                    value: vectorString
                                )
                            }
                        }
                    }
                    
                    // References
                    if !cve.references.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("References", systemImage: "link")
                                .font(.system(size: 16, weight: .semibold))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(cve.references, id: \.self) { reference in
                                    Link(destination: URL(string: reference)!) {
                                        HStack {
                                            Image(systemName: "arrow.up.right.square")
                                                .font(.system(size: 12))
                                            Text(reference)
                                                .font(.system(size: 12))
                                                .lineLimit(1)
                                                .truncationMode(.middle)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
                .padding(24)
            }
        }
        .frame(width: 600, height: 500)
    }
    
    private func colorForSeverity(_ severity: String) -> Color {
        switch severity.lowercased() {
        case "critical": return .red
        case "high": return .orange
        case "medium": return .yellow
        case "low": return .blue
        default: return .gray
        }
    }
}

// Modern Detail Row
struct DetailRowModern: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.system(size: 13))
                .textSelection(.enabled)
            
            Spacer()
        }
    }
}

// Advanced Filters View
struct AdvancedFiltersView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedVendor = ""
    @State private var selectedProduct = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Advanced Filters")
                .font(.system(size: 20, weight: .semibold))
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Vendor")
                        .font(.system(size: 14, weight: .medium))
                    TextField("e.g., Microsoft, Adobe", text: $selectedVendor)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Product")
                        .font(.system(size: 14, weight: .medium))
                    TextField("e.g., Windows, Chrome", text: $selectedProduct)
                        .textFieldStyle(.roundedBorder)
                }
            }
            
            HStack {
                Button("Reset") {
                    selectedVendor = ""
                    selectedProduct = ""
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Apply") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 400)
    }
}

#Preview {
    CVEManagerView()
        .environment(AppState())
}
