//
//  UserConfirmation.swift
//  DonkTool
//
//  User confirmation for privileged operations
//

import SwiftUI
import LocalAuthentication

/// Manages user confirmation for sensitive operations
@MainActor
class UserConfirmation: ObservableObject {
    static let shared = UserConfirmation()
    
    @Published var showingConfirmation = false
    @Published var pendingOperation: PendingOperation?
    @Published var ethicalModeEnabled = true
    
    private init() {
        // Load ethical mode preference
        ethicalModeEnabled = UserDefaults.standard.bool(forKey: "ethical_mode_enabled")
        if !UserDefaults.standard.bool(forKey: "ethical_mode_set") {
            // Default to enabled on first run
            ethicalModeEnabled = true
            UserDefaults.standard.set(true, forKey: "ethical_mode_enabled")
            UserDefaults.standard.set(true, forKey: "ethical_mode_set")
        }
    }
    
    struct PendingOperation {
        let title: String
        let message: String
        let requiresSudo: Bool
        let isDestructive: Bool
        let action: () async -> Void
    }
    
    /// Request confirmation for a privileged operation
    func requestConfirmation(
        title: String,
        message: String,
        requiresSudo: Bool = false,
        isDestructive: Bool = false,
        action: @escaping () async -> Void
    ) async -> Bool {
        // Check ethical mode
        if ethicalModeEnabled && (requiresSudo || isDestructive) {
            pendingOperation = PendingOperation(
                title: title,
                message: message,
                requiresSudo: requiresSudo,
                isDestructive: isDestructive,
                action: action
            )
            showingConfirmation = true
            
            // Wait for user response
            return await waitForUserResponse()
        } else {
            // No confirmation needed
            await action()
            return true
        }
    }
    
    /// Request biometric authentication for sensitive operations
    func requestBiometricAuth(reason: String) async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        // Check if biometric authentication is available
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            do {
                let success = try await context.evaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    localizedReason: reason
                )
                return success
            } catch {
                print("Biometric authentication failed: \(error)")
                return false
            }
        } else {
            // Fallback to device passcode
            if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                do {
                    let success = try await context.evaluatePolicy(
                        .deviceOwnerAuthentication,
                        localizedReason: reason
                    )
                    return success
                } catch {
                    print("Device authentication failed: \(error)")
                    return false
                }
            }
        }
        
        return false
    }
    
    /// Wait for user response to confirmation dialog
    private func waitForUserResponse() async -> Bool {
        await withCheckedContinuation { continuation in
            // This will be resolved by the confirmation dialog
            NotificationCenter.default.addObserver(
                forName: .userConfirmationResponse,
                object: nil,
                queue: .main
            ) { notification in
                if let confirmed = notification.userInfo?["confirmed"] as? Bool {
                    continuation.resume(returning: confirmed)
                }
            }
        }
    }
    
    /// Toggle ethical mode
    func toggleEthicalMode() {
        ethicalModeEnabled.toggle()
        UserDefaults.standard.set(ethicalModeEnabled, forKey: "ethical_mode_enabled")
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let userConfirmationResponse = Notification.Name("userConfirmationResponse")
}

// MARK: - Confirmation Dialog View

struct UserConfirmationDialog: View {
    @ObservedObject var confirmation = UserConfirmation.shared
    @State private var showingBiometricAuth = false
    
    var body: some View {
        if let operation = confirmation.pendingOperation {
            VStack(spacing: 20) {
                // Warning icon for destructive operations
                if operation.isDestructive {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                }
                
                Text(operation.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(operation.message)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                if operation.requiresSudo {
                    Label("This operation requires administrator privileges", systemImage: "lock.shield")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
                
                if operation.isDestructive {
                    Text("⚠️ This is a potentially destructive operation")
                        .foregroundColor(.red)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                
                // Legal disclaimer
                Text("By proceeding, you confirm that you have proper authorization to perform this action on the target system.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                HStack(spacing: 20) {
                    Button("Cancel") {
                        handleResponse(confirmed: false)
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Confirm") {
                        if operation.isDestructive || operation.requiresSudo {
                            requestBiometricConfirmation()
                        } else {
                            handleResponse(confirmed: true)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(operation.isDestructive ? .red : .accentColor)
                }
            }
            .padding(30)
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(15)
            .shadow(radius: 20)
            .frame(maxWidth: 400)
        }
    }
    
    private func requestBiometricConfirmation() {
        Task {
            let authenticated = await UserConfirmation.shared.requestBiometricAuth(
                reason: "Authenticate to perform privileged operation"
            )
            
            if authenticated {
                handleResponse(confirmed: true)
            } else {
                // Show error
                handleResponse(confirmed: false)
            }
        }
    }
    
    private func handleResponse(confirmed: Bool) {
        if confirmed, let operation = confirmation.pendingOperation {
            Task {
                await operation.action()
            }
        }
        
        // Notify waiting continuation
        NotificationCenter.default.post(
            name: .userConfirmationResponse,
            object: nil,
            userInfo: ["confirmed": confirmed]
        )
        
        // Clear the pending operation
        confirmation.pendingOperation = nil
        confirmation.showingConfirmation = false
    }
}

// MARK: - Sudo Helper

extension UserConfirmation {
    /// Execute a command with sudo if needed
    func executeSudoCommand(_ command: String, arguments: [String]) async throws -> (output: String, exitCode: Int32) {
        // Request confirmation for sudo operations
        let confirmed = await requestConfirmation(
            title: "Administrator Access Required",
            message: "This operation requires administrator privileges to run:\n\n\(command)",
            requiresSudo: true,
            isDestructive: false
        ) {
            // Action will be performed after confirmation
        }
        
        guard confirmed else {
            throw SudoError.userCancelled
        }
        
        // Use osascript to prompt for admin password
        let script = """
        do shell script "\(command) \(arguments.joined(separator: " "))" with administrator privileges
        """
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        return (output: output, exitCode: process.terminationStatus)
    }
    
    enum SudoError: LocalizedError {
        case userCancelled
        case authenticationFailed
        
        var errorDescription: String? {
            switch self {
            case .userCancelled:
                return "Operation cancelled by user"
            case .authenticationFailed:
                return "Authentication failed"
            }
        }
    }
}