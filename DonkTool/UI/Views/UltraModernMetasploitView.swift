//
//  UltraModernMetasploitView.swift
//  DonkTool
//
//  Ultra-modern Metasploit Framework interface with real tool integration
//

import SwiftUI
import Combine

struct UltraModernMetasploitView: View {
    @StateObject private var metasploit = MetasploitManager.shared
    @State private var selectedCategory = "All"
    @State private var searchQuery = ""
    @State private var showingExploitDetails = false
    @State private var selectedExploit: MetasploitModule?
    @State private var showingSessionManager = false
    
    let categories = ["All", "Exploits", "Auxiliary", "Payloads", "Encoders", "Post"]
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.black, Color.black.opacity(0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Main Content
                if metasploit.isConnected {
                    contentView
                } else {
                    connectionView
                }
            }
        }
        .sheet(item: $selectedExploit) { exploit in
            ExploitDetailSheet(exploit: exploit, metasploit: metasploit)
        }
        .sheet(isPresented: $showingSessionManager) {
            SessionManagerSheet(metasploit: metasploit)
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 0) {
            // Title Bar
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: "terminal.fill")
                        .font(.title)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.red, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Metasploit Framework")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 8) {
                            MetasploitStatusIndicator(
                                isActive: metasploit.isConnected,
                                activeText: "Connected",
                                inactiveText: "Disconnected"
                            )
                            
                            if metasploit.isConnected {
                                Text("•")
                                    .foregroundColor(.gray)
                                
                                Text("\(metasploit.moduleCount) modules")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Text("•")
                                    .foregroundColor(.gray)
                                
                                Text("\(metasploit.activeSessions.count) sessions")
                                    .font(.caption)
                                    .foregroundColor(metasploit.activeSessions.isEmpty ? .gray : .green)
                            }
                        }
                    }
                }
                
                Spacer()
                
                if metasploit.isConnected {
                    HStack(spacing: 12) {
                        Button(action: { showingSessionManager = true }) {
                            Label("Sessions", systemImage: "link.badge.plus")
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    metasploit.activeSessions.isEmpty ?
                                    Color.gray.opacity(0.2) :
                                    Color.green.opacity(0.2)
                                )
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            metasploit.activeSessions.isEmpty ?
                                            Color.gray.opacity(0.3) :
                                            Color.green.opacity(0.5),
                                            lineWidth: 1
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: { metasploit.disconnect() }) {
                            Label("Disconnect", systemImage: "power")
                                .foregroundColor(.red)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
            
            // Search and Filter Bar
            if metasploit.isConnected {
                VStack(spacing: 12) {
                    // Search
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search modules...", text: $searchQuery)
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                        
                        if !searchQuery.isEmpty {
                            Button(action: { searchQuery = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
                    
                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(categories, id: \.self) { category in
                                MetasploitCategoryChip(
                                    title: category,
                                    isSelected: selectedCategory == category,
                                    action: { selectedCategory = category }
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            
            Divider()
                .background(Color.gray.opacity(0.3))
        }
        .background(Color.black.opacity(0.5))
    }
    
    private var connectionView: some View {
        VStack(spacing: 40) {
            // Metasploit Logo Animation
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.red.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 20)
                
                Image(systemName: "terminal.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .red.opacity(0.5), radius: 20)
            }
            .scaleEffect(metasploit.isConnecting ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: metasploit.isConnecting)
            
            VStack(spacing: 16) {
                Text("Metasploit Framework")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("The world's most used penetration testing framework")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                if metasploit.isConnecting {
                    HStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                            .scaleEffect(0.8)
                        
                        Text("Connecting to Metasploit...")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                    .padding(.top)
                } else {
                    Button(action: { metasploit.connect() }) {
                        HStack(spacing: 12) {
                            Image(systemName: "power")
                                .font(.title3)
                            
                            Text("Connect to Metasploit")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.red, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: .red.opacity(0.5), radius: 20)
                    }
                    .buttonStyle(.plain)
                    .padding(.top)
                }
            }
            
            // Installation Instructions
            if !metasploit.isInstalled {
                VStack(spacing: 12) {
                    Label("Metasploit not found", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text("Install with:")
                        .foregroundColor(.gray)
                    
                    Text("brew install metasploit")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.green)
                        .padding(8)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(6)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var contentView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredModules) { module in
                    ModuleCard(module: module) {
                        selectedExploit = module
                        showingExploitDetails = true
                    }
                }
            }
            .padding()
        }
    }
    
    private var filteredModules: [MetasploitModule] {
        metasploit.modules.filter { module in
            (selectedCategory == "All" || module.type.lowercased() == selectedCategory.lowercased()) &&
            (searchQuery.isEmpty || module.searchMatches(searchQuery))
        }
    }
}

// MARK: - Module Card
struct ModuleCard: View {
    let module: MetasploitModule
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Module Type Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(module.typeColor.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: module.typeIcon)
                        .font(.title2)
                        .foregroundColor(module.typeColor)
                }
                
                // Module Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(module.name)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(module.fullPath)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    
                    HStack(spacing: 12) {
                        // Rank
                        HStack(spacing: 4) {
                            Circle()
                                .fill(module.rankColor)
                                .frame(width: 6, height: 6)
                            
                            Text(module.rank)
                                .font(.caption2)
                                .foregroundColor(module.rankColor)
                        }
                        
                        // Date
                        if let date = module.disclosureDate {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.caption2)
                                
                                Text(date, style: .date)
                                    .font(.caption2)
                            }
                            .foregroundColor(.gray)
                        }
                        
                        // Platform
                        if !module.platform.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "desktopcomputer")
                                    .font(.caption2)
                                
                                Text(module.platform)
                                    .font(.caption2)
                            }
                            .foregroundColor(.gray)
                        }
                    }
                }
                
                Spacer()
                
                // Action Button
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Chip
struct MetasploitCategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ?
                    LinearGradient(
                        colors: [.red, .orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) :
                    LinearGradient(
                        colors: [Color.white.opacity(0.05), Color.white.opacity(0.05)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isSelected ? Color.clear : Color.white.opacity(0.1),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Status Indicator
struct MetasploitStatusIndicator: View {
    let isActive: Bool
    let activeText: String
    let inactiveText: String
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isActive ? Color.green : Color.red)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .fill(isActive ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                        .blur(radius: 4)
                )
            
            Text(isActive ? activeText : inactiveText)
                .font(.caption)
                .foregroundColor(isActive ? .green : .red)
        }
    }
}

// MARK: - Exploit Detail Sheet
struct ExploitDetailSheet: View {
    let exploit: MetasploitModule
    @ObservedObject var metasploit: MetasploitManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTarget = 0
    @State private var rhosts = ""
    @State private var rport = ""
    @State private var lhost = ""
    @State private var lport = "4444"
    @State private var isRunning = false
    @State private var output = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(exploit.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(exploit.fullPath)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
            }
            .padding()
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Description
                    if !exploit.description.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                            
                            Text(exploit.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Options
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Options")
                            .font(.headline)
                        
                        // Target Selection
                        if !exploit.targets.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Target")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Picker("Target", selection: $selectedTarget) {
                                    ForEach(exploit.targets.indices, id: \.self) { index in
                                        Text(exploit.targets[index])
                                            .tag(index)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                        }
                        
                        // Remote Host
                        VStack(alignment: .leading, spacing: 8) {
                            Text("RHOSTS (Target IP)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("192.168.1.100", text: $rhosts)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Remote Port
                        VStack(alignment: .leading, spacing: 8) {
                            Text("RPORT (Target Port)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("445", text: $rport)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Local Host
                        VStack(alignment: .leading, spacing: 8) {
                            Text("LHOST (Your IP)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("10.0.0.1", text: $lhost)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Local Port
                        VStack(alignment: .leading, spacing: 8) {
                            Text("LPORT (Callback Port)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("4444", text: $lport)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    
                    // Console Output
                    if !output.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Output")
                                .font(.headline)
                            
                            ScrollView {
                                Text(output)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.green)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                            }
                            .frame(height: 200)
                            .background(Color.black)
                            .cornerRadius(8)
                        }
                    }
                    
                    // Run Button
                    Button(action: runExploit) {
                        HStack {
                            if isRunning {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "play.fill")
                            }
                            
                            Text(isRunning ? "Running..." : "Run Exploit")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.red, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .disabled(isRunning || rhosts.isEmpty || lhost.isEmpty)
                }
                .padding()
            }
        }
        .frame(width: 600, height: 700)
    }
    
    private func runExploit() {
        isRunning = true
        output = "Loading module...\n"
        
        metasploit.runExploit(
            exploit,
            rhosts: rhosts,
            rport: rport,
            lhost: lhost,
            lport: lport,
            target: selectedTarget
        ) { result in
            output += result + "\n"
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            isRunning = false
        }
    }
}

// MARK: - Session Manager Sheet
struct SessionManagerSheet: View {
    @ObservedObject var metasploit: MetasploitManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Active Sessions")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(metasploit.activeSessions.count) active sessions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
            }
            .padding()
            
            Divider()
            
            if metasploit.activeSessions.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "link.badge.plus")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    
                    Text("No active sessions")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Run exploits to establish sessions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(metasploit.activeSessions) { session in
                        MetasploitSessionRow(session: session, metasploit: metasploit)
                    }
                }
            }
        }
        .frame(width: 600, height: 500)
    }
}

// MARK: - Session Row
struct MetasploitSessionRow: View {
    let session: MetasploitSession
    @ObservedObject var metasploit: MetasploitManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Session \(session.id)")
                        .font(.headline)
                    
                    StatusBadge(
                        status: session.type == "meterpreter" ? .success : .active,
                        text: session.type
                    )
                }
                
                Text(session.info)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 16) {
                    Label(session.exploit, systemImage: "hammer")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Label(session.target, systemImage: "desktopcomputer")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button("Interact") {
                    metasploit.interactWithSession(session.id)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Button("Kill") {
                    metasploit.killSession(session.id)
                }
                .foregroundColor(.red)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Supporting Extensions
extension MetasploitModule {
    var typeIcon: String {
        switch type.lowercased() {
        case "exploit": return "hammer.fill"
        case "auxiliary": return "wrench.and.screwdriver.fill"
        case "payload": return "shippingbox.fill"
        case "encoder": return "lock.fill"
        case "post": return "arrow.up.doc.fill"
        default: return "cube.fill"
        }
    }
    
    var typeColor: Color {
        switch type.lowercased() {
        case "exploit": return .red
        case "auxiliary": return .orange
        case "payload": return .blue
        case "encoder": return .purple
        case "post": return .green
        default: return .gray
        }
    }
    
    var rankColor: Color {
        switch rank.lowercased() {
        case "excellent": return .green
        case "great": return .green
        case "good": return .blue
        case "normal": return .orange
        case "average": return .orange
        case "low": return .red
        case "manual": return .gray
        default: return .gray
        }
    }
    
    func searchMatches(_ query: String) -> Bool {
        let lowercaseQuery = query.lowercased()
        return name.lowercased().contains(lowercaseQuery) ||
               fullPath.lowercased().contains(lowercaseQuery) ||
               description.lowercased().contains(lowercaseQuery)
    }
}

#Preview {
    UltraModernMetasploitView()
}