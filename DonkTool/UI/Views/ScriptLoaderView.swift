//
//  ScriptLoaderView.swift
//  DonkTool
//
//  Custom script execution interface with auto-language detection
//

import SwiftUI
import UniformTypeIdentifiers

struct ScriptLoaderView: View {
    @State private var scriptLoader = ScriptLoader()
    @State private var selectedDirectory = ""
    @State private var scriptArguments = ""
    @State private var showingFilePicker = false
    @State private var showingDirectoryPicker = false
    @State private var showingExecutionResults = false
    @State private var isExecutingScript = false
    
    var body: some View {
        HSplitView {
            // Left side - Script management
            VStack(spacing: 20) {
                headerSection
                
                HStack(spacing: 16) {
                    directorySelectionSection
                    scriptsListSection
                }
                .frame(maxHeight: 400)
                
                if let selectedScript = scriptLoader.selectedScript {
                    scriptDetailsSection(selectedScript)
                }
                
                Spacer()
            }
            .padding()
            .frame(minWidth: 600, maxWidth: 800)
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.item],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
            
            // Right side - Real-time shell output
            RealTimeShellView(scriptLoader: scriptLoader)
                .frame(minWidth: 400)
        }
        .navigationTitle("Script Loader")
        .sheet(isPresented: $showingExecutionResults) {
            ExecutionResultsView(scriptLoader: scriptLoader)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Custom Script Executor")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Auto-detects language and executes scripts in a secure environment")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { showingFilePicker = true }) {
                    Label("Add Script", systemImage: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            
            // Security Notice
            HStack {
                Image(systemName: "exclamationmark.shield.fill")
                    .foregroundColor(.orange)
                
                Text("⚠️ Only execute scripts from trusted sources. Scripts run with your system permissions.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.horizontal, 8)
        }
    }
    
    private var directorySelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Script Directory")
                    .font(.headline)
                
                Spacer()
                
                Button("Browse") {
                    selectDirectory()
                }
                .buttonStyle(.bordered)
            }
            
            if !selectedDirectory.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.blue)
                            Text(URL(fileURLWithPath: selectedDirectory).lastPathComponent)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Text(selectedDirectory)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                        
                        Button("Refresh Scripts") {
                            scriptLoader.refreshScripts(in: selectedDirectory)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "folder.badge.plus")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("Select a directory containing scripts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var scriptsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Scripts (\(scriptLoader.scripts.count))")
                .font(.headline)
            
            if scriptLoader.scripts.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("No scripts found")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(scriptLoader.scripts) { script in
                            ScriptRowView(
                                script: script,
                                isSelected: scriptLoader.selectedScript?.id == script.id
                            ) {
                                scriptLoader.selectedScript = script
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func scriptDetailsSection(_ script: CustomScript) -> some View {
        VStack(spacing: 16) {
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(script.language.icon)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(script.name)
                                .font(.headline)
                            Text(script.language.rawValue)
                                .font(.caption)
                                .foregroundColor(script.language.color)
                        }
                        
                        Spacer()
                    }
                    
                    HStack(spacing: 16) {
                        HStack {
                            Image(systemName: "doc.fill")
                            Text(script.fileSize)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "calendar")
                            Text(script.lastModified, style: .relative)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    TextField("Arguments (optional)", text: $scriptArguments)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 200)
                    
                    HStack(spacing: 8) {
                        Button("Execute") {
                            executeSelectedScript()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(scriptLoader.isExecuting)
                        
                        if scriptLoader.isExecuting {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private func selectDirectory() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = false
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                selectedDirectory = url.path
                scriptLoader.refreshScripts(in: selectedDirectory)
            }
        }
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            if let script = scriptLoader.loadScript(from: url.path) {
                if !scriptLoader.scripts.contains(where: { $0.id == script.id }) {
                    scriptLoader.scripts.append(script)
                    scriptLoader.scripts.sort { $0.name < $1.name }
                }
                scriptLoader.selectedScript = script
            }
            
        case .failure(let error):
            print("Error selecting file: \(error)")
        }
    }
    
    private func executeSelectedScript() {
        guard let script = scriptLoader.selectedScript else { return }
        
        let arguments = scriptArguments
            .split(separator: " ")
            .map { String($0) }
            .filter { !$0.isEmpty }
        
        Task {
            await scriptLoader.executeScript(script, arguments: arguments)
            await MainActor.run {
                showingExecutionResults = true
            }
        }
    }
    
    private func getLineColor(_ line: String) -> Color {
        if line.contains("❌") || line.contains("ERROR") || line.contains("STDERR") {
            return .red
        } else if line.contains("✅") || line.contains("SUCCESS") {
            return .green
        } else if line.contains("🚀") || line.contains("⚙️") {
            return .blue
        } else if line.contains("📤") {
            return .orange
        }
        return .primary
    }
}

struct ScriptRowView: View {
    let script: CustomScript
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text(script.language.icon)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(script.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(script.language.rawValue)
                        .font(.caption)
                        .foregroundColor(script.language.color)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue.opacity(0.2) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct ExecutionResultsView: View {
    var scriptLoader: ScriptLoader
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                if let script = scriptLoader.selectedScript {
                    HStack {
                        Text(script.language.icon)
                            .font(.title2)
                        
                        VStack(alignment: .leading) {
                            Text(script.name)
                                .font(.headline)
                            Text("Execution Results")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if scriptLoader.isExecuting {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(scriptLoader.output.enumerated()), id: \.offset) { index, line in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(index + 1)")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .frame(width: 40, alignment: .trailing)
                                
                                Text(line)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(getLineColor(line))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                    .padding()
                }
                .background(Color.black.opacity(0.05))
                .cornerRadius(8)
            }
            .padding()
            .navigationTitle("Script Output")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func getLineColor(_ line: String) -> Color {
        if line.contains("❌") || line.contains("ERROR") || line.contains("STDERR") {
            return .red
        } else if line.contains("✅") || line.contains("SUCCESS") {
            return .green
        } else if line.contains("🚀") || line.contains("⚙️") {
            return .blue
        } else if line.contains("📤") {
            return .orange
        }
        return .primary
    }
}

struct RealTimeShellView: View {
    var scriptLoader: ScriptLoader
    @State private var scrollToBottom = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Shell header
            HStack {
                Image(systemName: "terminal")
                    .foregroundColor(.green)
                
                Text("Script Execution Console")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if scriptLoader.isExecuting {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Executing...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if !scriptLoader.output.isEmpty {
                    Text("Ready")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                Button(action: {
                    scriptLoader.clearOutput()
                }) {
                    Image(systemName: "trash")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.secondary.opacity(0.1))
            
            Divider()
            
            // Terminal-style output
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        if scriptLoader.output.isEmpty && !scriptLoader.isExecuting {
                            VStack(spacing: 16) {
                                Image(systemName: "terminal.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary.opacity(0.5))
                                
                                VStack(spacing: 8) {
                                    Text("Script Console")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                    
                                    Text("Select and execute a script to see real-time output here")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding()
                        } else {
                            ForEach(Array(scriptLoader.output.enumerated()), id: \.offset) { index, line in
                                HStack(alignment: .top, spacing: 8) {
                                    // Line number
                                    Text("\(index + 1)")
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .frame(width: 40, alignment: .trailing)
                                    
                                    // Output line
                                    Text(line)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(getShellLineColor(line))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .textSelection(.enabled)
                                        .padding(.trailing, 8)
                                }
                                .id(index)
                                .padding(.horizontal, 8)
                            }
                            
                            // Auto-scroll anchor
                            if scriptLoader.isExecuting {
                                HStack {
                                    Text("▊")
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.green)
                                        .blinking()
                                    
                                    Text("Executing...")
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.green)
                                }
                                .padding(.horizontal, 8)
                                .id("bottom")
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                }
                .background(Color.black.opacity(0.02))
                .onChange(of: scriptLoader.output.count) { _, _ in
                    if scriptLoader.isExecuting {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
            }
        }
        .background(Color.primaryBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .padding()
    }
    
    private func getShellLineColor(_ line: String) -> Color {
        if line.contains("❌") || line.contains("ERROR") || line.contains("STDERR") {
            return .red
        } else if line.contains("✅") || line.contains("SUCCESS") {
            return .green
        } else if line.contains("🚀") || line.contains("⚙️") {
            return .blue
        } else if line.contains("📤") {
            return .orange
        } else if line.hasPrefix("🐍") || line.hasPrefix("🐚") || line.hasPrefix("🟨") {
            return .purple
        }
        return .primary
    }
}

// Blinking cursor effect
struct BlinkingModifier: ViewModifier {
    @State private var isVisible = true
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.8).repeatForever(), value: isVisible)
            .onAppear {
                isVisible = false
            }
    }
}

extension View {
    func blinking() -> some View {
        self.modifier(BlinkingModifier())
    }
}

#Preview {
    ScriptLoaderView()
}