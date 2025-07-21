import SwiftUI

struct BluetoothShellView: View {
    @StateObject private var shell = BluetoothShell()
    @State private var commandInput = ""
    @State private var isInputFocused = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Terminal header
            TerminalHeader()
            
            // Main terminal area
            VStack(spacing: 0) {
                // Output area
                TerminalOutputArea()
                
                // Input area
                TerminalInputArea()
            }
            .background(Color.black)
        }
        .navigationTitle("Bluetooth Shell")
        .onAppear {
            shell.isRunning = true
            // Auto-focus the input field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isTextFieldFocused = true
            }
        }
    }
    
    @ViewBuilder
    private func TerminalHeader() -> some View {
        HStack {
            // Terminal window controls (like macOS Terminal)
            HStack(spacing: 8) {
                Circle()
                    .fill(.red)
                    .frame(width: 12, height: 12)
                
                Circle()
                    .fill(.yellow)
                    .frame(width: 12, height: 12)
                
                Circle()
                    .fill(.green)
                    .frame(width: 12, height: 12)
            }
            
            Spacer()
            
            Text("Bluetooth Security Shell")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            // Shell controls
            HStack(spacing: 8) {
                Button(action: clearTerminal) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help("Clear terminal")
                
                Button(action: copyOutput) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help("Copy output")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.2))
    }
    
    @ViewBuilder
    private func TerminalOutputArea() -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(shell.output) { output in
                        TerminalOutputLine(output: output)
                            .id(output.id)
                    }
                    
                    // Invisible anchor for auto-scrolling
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onChange(of: shell.output.count) { _, _ in
                // Auto-scroll to bottom when new output appears
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func TerminalInputArea() -> some View {
        HStack(spacing: 0) {
            // Prompt
            Text(shell.currentPrompt)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.green)
            
            // Input field
            TextField("", text: $commandInput)
                .font(.system(.body, design: .monospaced))
                .textFieldStyle(.plain)
                .foregroundColor(.white)
                .focused($isTextFieldFocused)
                .onSubmit {
                    executeCommand()
                }
                .onKeyPress(.upArrow) {
                    navigateHistory(direction: .up)
                    return .handled
                }
                .onKeyPress(.downArrow) {
                    navigateHistory(direction: .down)
                    return .handled
                }
                .onKeyPress(.tab) {
                    autoComplete()
                    return .handled
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.gray.opacity(0.3)),
            alignment: .top
        )
    }
    
    private func executeCommand() {
        let command = commandInput.trimmingCharacters(in: .whitespacesAndNewlines)
        shell.executeCommand(command)
        commandInput = ""
        
        // Keep focus on input field
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isTextFieldFocused = true
        }
    }
    
    private func navigateHistory(direction: HistoryDirection) {
        let history = shell.commandHistory
        guard !history.isEmpty else { return }
        
        switch direction {
        case .up:
            if shell.historyIndex > 0 {
                shell.historyIndex -= 1
            } else if shell.historyIndex == -1 {
                shell.historyIndex = history.count - 1
            }
        case .down:
            if shell.historyIndex < history.count - 1 {
                shell.historyIndex += 1
            } else {
                shell.historyIndex = -1
                commandInput = ""
                return
            }
        }
        
        if shell.historyIndex >= 0 && shell.historyIndex < history.count {
            commandInput = history[shell.historyIndex]
        }
    }
    
    private func autoComplete() {
        let availableCommands = [
            "scan", "stop", "devices", "connect", "disconnect", 
            "info", "services", "vuln-scan", "exploit", "clear", 
            "status", "history", "help", "exit"
        ]
        
        let input = commandInput.lowercased()
        let matches = availableCommands.filter { $0.hasPrefix(input) }
        
        if matches.count == 1 {
            commandInput = matches[0]
        } else if matches.count > 1 {
            // Show available completions
            shell.addOutput("Available completions: \(matches.joined(separator: ", "))", type: .info)
        }
    }
    
    private func clearTerminal() {
        shell.clearOutput()
    }
    
    private func copyOutput() {
        let outputText = shell.output
            .map { output in
                let prefix = output.type.prefix.isEmpty ? "" : "\(output.type.prefix) "
                return "\(prefix)\(output.text)"
            }
            .joined(separator: "\n")
        
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(outputText, forType: .string)
        #endif
        
        shell.addOutput("📋 Output copied to clipboard", type: .info)
    }
}

struct TerminalOutputLine: View {
    let output: ShellOutput
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Timestamp (optional, can be toggled)
            if showTimestamp {
                Text(formatTimestamp(output.timestamp))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.gray)
                    .frame(width: 60, alignment: .leading)
            }
            
            // Output content
            VStack(alignment: .leading, spacing: 0) {
                if output.type.prefix.isEmpty {
                    // Regular output or commands
                    Text(output.text)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(output.type.color)
                        .textSelection(.enabled)
                } else {
                    // Prefixed output (info, error, etc.)
                    HStack(spacing: 8) {
                        Text(output.type.prefix)
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(output.type.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(output.type.color.opacity(0.2))
                            .cornerRadius(4)
                        
                        Text(output.text)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.white)
                            .textSelection(.enabled)
                    }
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(.vertical, 1)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var showTimestamp: Bool {
        UserDefaults.standard.bool(forKey: "BluetoothShell_ShowTimestamp")
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

// MARK: - Shell Enhancement Features

struct BluetoothShellSettingsView: View {
    @AppStorage("BluetoothShell_ShowTimestamp") private var showTimestamp = false
    @AppStorage("BluetoothShell_FontSize") private var fontSize = 14.0
    @AppStorage("BluetoothShell_Theme") private var theme = "dark"
    
    var body: some View {
        Form {
            Section("Display Options") {
                Toggle("Show Timestamps", isOn: $showTimestamp)
                
                HStack {
                    Text("Font Size:")
                    Slider(value: $fontSize, in: 10...20, step: 1)
                    Text("\(Int(fontSize))pt")
                        .frame(width: 30)
                }
                
                Picker("Theme", selection: $theme) {
                    Text("Dark").tag("dark")
                    Text("Matrix").tag("matrix")
                    Text("Retro").tag("retro")
                }
            }
            
            Section("Shell Behavior") {
                Toggle("Auto-scroll to bottom", isOn: .constant(true))
                Toggle("Save command history", isOn: .constant(true))
                Toggle("Enable tab completion", isOn: .constant(true))
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 300)
    }
}

struct BluetoothShellWithSidebar: View {
    @StateObject private var shell = BluetoothShell()
    @State private var showingSettings = false
    @State private var selectedSidebarItem: SidebarItem = .shell
    
    enum SidebarItem: String, CaseIterable {
        case shell = "Shell"
        case devices = "Devices"
        case history = "History"
        case logs = "Logs"
        
        var icon: String {
            switch self {
            case .shell: return "terminal"
            case .devices: return "antenna.radiowaves.left.and.right"
            case .history: return "clock.arrow.circlepath"
            case .logs: return "doc.text"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(SidebarItem.allCases, id: \.self, selection: $selectedSidebarItem) { item in
                Label(item.rawValue, systemImage: item.icon)
            }
            .navigationTitle("BT Shell")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
        } detail: {
            Group {
                switch selectedSidebarItem {
                case .shell:
                    BluetoothShellView()
                        .environmentObject(shell)
                case .devices:
                    BluetoothDeviceManagerView(shell: shell)
                case .history:
                    BluetoothHistoryView(shell: shell)
                case .logs:
                    BluetoothLogsView(shell: shell)
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            BluetoothShellSettingsView()
        }
    }
}

struct BluetoothDeviceManagerView: View {
    @ObservedObject var shell: BluetoothShell
    
    var body: some View {
        VStack {
            Text("Device Manager")
                .font(.title)
            
            List {
                ForEach(Array(shell.getDevices().keys), id: \.self) { address in
                    if let device = shell.getDevices()[address] {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(device.name ?? "Unknown")
                                    .font(.headline)
                                Text(address)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if shell.getConnectedDevices().keys.contains(address) {
                                Text("Connected")
                                    .foregroundColor(.green)
                            } else {
                                Button("Connect") {
                                    shell.connectToDevice(address)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }
}

struct BluetoothHistoryView: View {
    @ObservedObject var shell: BluetoothShell
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Command History")
                .font(.title)
            
            List {
                ForEach(Array(shell.commandHistory.enumerated()), id: \.offset) { index, command in
                    HStack {
                        Text("\(index + 1)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .leading)
                        
                        Text(command)
                            .font(.system(.body, design: .monospaced))
                        
                        Spacer()
                        
                        Button("Run") {
                            shell.executeCommand(command)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
        }
        .padding()
    }
}

struct BluetoothLogsView: View {
    @ObservedObject var shell: BluetoothShell
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Shell Logs")
                .font(.title)
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(shell.output) { output in
                        HStack {
                            Text(formatTimestamp(output.timestamp))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 80, alignment: .leading)
                            
                            Text(output.type.prefix)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(output.type.color)
                                .frame(width: 80, alignment: .leading)
                            
                            Text(output.text)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                        }
                        .padding(.vertical, 1)
                    }
                }
                .padding()
            }
        }
        .padding()
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Types

enum HistoryDirection {
    case up, down
}

// MARK: - Preview

#Preview {
    BluetoothShellView()
        .frame(width: 800, height: 600)
}

#Preview("With Sidebar") {
    BluetoothShellWithSidebar()
        .frame(width: 1000, height: 700)
}