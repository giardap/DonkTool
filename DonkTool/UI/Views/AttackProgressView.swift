//
//  AttackProgressView.swift
//  DonkTool
//
//  Real-time attack progress monitoring view
//

import SwiftUI

struct AttackProgressView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    
    let attack: OffensiveAttackVector
    let target: String
    let port: Int
    
    @State private var output: [String] = []
    @State private var isRunning = true
    @State private var progress: Double = 0.0
    @State private var scrollToBottom = false
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
                            
                            Label("Port \(port)", systemImage: "number.circle")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
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
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Output Terminal
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(output.enumerated()), id: \.offset) { index, line in
                            OutputLine(text: line)
                                .id(index)
                        }
                        
                        if output.isEmpty && isRunning {
                            Text("Initializing attack...")
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
            .background(Color(NSColor.controlBackgroundColor))
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
        let filename = "\(attack.name.replacingOccurrences(of: " ", with: "_"))_\(timestamp).txt"
        
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

struct OutputLine: View {
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

struct AttackProgressView_Previews: PreviewProvider {
    static var previews: some View {
        AttackProgressView(
            attack: OffensiveAttackVector(
                id: "test",
                name: "Test Attack",
                description: "Test description",
                category: .reconnaissance,
                requiredTools: [],
                commands: ["echo 'test'"],
                severity: .medium,
                estimatedDuration: 60
            ),
            target: "192.168.1.1",
            port: 80
        )
        .environment(AppState())
    }
}