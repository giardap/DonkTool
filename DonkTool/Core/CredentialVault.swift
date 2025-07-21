//
//  CredentialVault.swift
//  DonkTool
//
//  Secure credential storage and sharing across modules
//

import Foundation
import Security
import CryptoKit

// MARK: - Credential Vault Models

struct StoredCredential: Identifiable, Codable {
    let id = UUID()
    let username: String
    let password: String
    let service: String
    let target: String
    let port: Int
    let source: String
    let confidence: CredentialConfidence
    let timestamp: Date
    let verified: Bool
    let lastTested: Date?
    let successfulServices: [String]
    
    init(from discovery: CredentialDiscovery, verified: Bool = false) {
        self.username = discovery.username
        self.password = discovery.password
        self.service = discovery.service
        self.target = discovery.target
        self.port = discovery.port
        self.source = discovery.source
        self.confidence = discovery.confidence
        self.timestamp = discovery.timestamp
        self.verified = verified
        self.lastTested = nil
        self.successfulServices = []
    }
}

struct CredentialTestResult {
    let credential: StoredCredential
    let service: String
    let target: String
    let port: Int
    let success: Bool
    let responseTime: TimeInterval
    let additionalInfo: [String: String]
}

// MARK: - Credential Vault

@Observable
class CredentialVault {
    static let shared = CredentialVault()
    
    // Credential storage
    private var credentials: [StoredCredential] = []
    private let keychainService = "com.donktool.credentials"
    private let encryptionKey: SymmetricKey
    
    // Vault statistics
    var totalCredentials: Int { credentials.count }
    var verifiedCredentials: Int { credentials.filter { $0.verified }.count }
    var highConfidenceCredentials: Int { credentials.filter { $0.confidence == .high }.count }
    
    // Testing state
    var isTestingCredentials = false
    var currentTestProgress: Double = 0.0
    var lastTestTime: Date?
    
    private init() {
        // Generate or retrieve encryption key from Keychain
        self.encryptionKey = Self.getOrCreateEncryptionKey()
        loadCredentialsFromKeychain()
        setupIntegrationListeners()
    }
    
    private static func getOrCreateEncryptionKey() -> SymmetricKey {
        let keyName = "donktool_credential_encryption_key"
        
        // Try to retrieve existing key
        if let existingKey = getKeychainData(service: "com.donktool.encryption", account: keyName) {
            return SymmetricKey(data: existingKey)
        }
        
        // Generate new key
        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }
        
        // Store in Keychain
        saveToKeychain(data: keyData, service: "com.donktool.encryption", account: keyName)
        
        return newKey
    }
    
    private func setupIntegrationListeners() {
        NotificationCenter.default.addObserver(
            forName: .credentialsDiscovered,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let discovery = notification.object as? CredentialDiscovery {
                self?.addCredential(from: discovery)
            }
        }
    }
    
    // MARK: - Credential Management
    
    func addCredential(from discovery: CredentialDiscovery) {
        let newCredential = StoredCredential(from: discovery)
        
        // Check for duplicates
        if !credentials.contains(where: { 
            $0.username == newCredential.username && 
            $0.password == newCredential.password && 
            $0.target == newCredential.target && 
            $0.service == newCredential.service 
        }) {
            credentials.append(newCredential)
            saveCredentialsToKeychain()
            
            print("🔐 Credential Vault: Added \(newCredential.username)@\(newCredential.target):\(newCredential.port)")
            
            // Auto-test new credentials
            Task {
                await testCredentialAcrossServices(newCredential)
            }
        }
    }
    
    func removeCredential(_ credential: StoredCredential) {
        credentials.removeAll { $0.id == credential.id }
        saveCredentialsToKeychain()
    }
    
    func updateCredential(_ credential: StoredCredential) {
        if let index = credentials.firstIndex(where: { $0.id == credential.id }) {
            credentials[index] = credential
            saveCredentialsToKeychain()
        }
    }
    
    func getCredentialsForTarget(_ target: String) -> [StoredCredential] {
        return credentials.filter { $0.target == target }
    }
    
    func getCredentialsForService(_ service: String) -> [StoredCredential] {
        return credentials.filter { $0.service.lowercased() == service.lowercased() }
    }
    
    func getVerifiedCredentials() -> [StoredCredential] {
        return credentials.filter { $0.verified }
    }
    
    func getAllCredentials() -> [StoredCredential] {
        return credentials
    }
    
    // MARK: - Credential Testing
    
    func testAllCredentials() async {
        isTestingCredentials = true
        currentTestProgress = 0.0
        lastTestTime = Date()
        
        let totalTests = credentials.count
        
        for (index, credential) in credentials.enumerated() {
            await testCredentialAcrossServices(credential)
            
            await MainActor.run {
                currentTestProgress = Double(index + 1) / Double(totalTests)
            }
        }
        
        await MainActor.run {
            isTestingCredentials = false
            currentTestProgress = 1.0
        }
    }
    
    private func testCredentialAcrossServices(_ credential: StoredCredential) async {
        let testResults = await performComprehensiveCredentialTest(credential)
        
        // Update credential with test results
        var updatedCredential = credential
        var newSuccessfulServices: [String] = []
        var isVerified = false
        
        for result in testResults {
            if result.success {
                newSuccessfulServices.append("\(result.service):\(result.port)")
                isVerified = true
            }
        }
        
        // Create updated credential
        let finalCredential = StoredCredential(
            username: updatedCredential.username,
            password: updatedCredential.password,
            service: updatedCredential.service,
            target: updatedCredential.target,
            port: updatedCredential.port,
            source: updatedCredential.source,
            confidence: updatedCredential.confidence,
            timestamp: updatedCredential.timestamp,
            verified: isVerified,
            lastTested: Date(),
            successfulServices: newSuccessfulServices
        )
        
        // Update in vault
        if let index = credentials.firstIndex(where: { $0.id == credential.id }) {
            credentials[index] = finalCredential
            saveCredentialsToKeychain()
        }
        
        // Notify about successful credential validation
        for result in testResults.filter({ $0.success }) {
            NotificationCenter.default.post(
                name: .credentialsDiscovered,
                object: CredentialDiscovery(
                    username: credential.username,
                    password: credential.password,
                    service: result.service,
                    target: result.target,
                    port: result.port,
                    source: "credential_vault_verification",
                    confidence: .high,
                    timestamp: Date()
                )
            )
        }
    }
    
    private func performComprehensiveCredentialTest(_ credential: StoredCredential) async -> [CredentialTestResult] {
        var results: [CredentialTestResult] = []
        
        // Test SSH
        if let sshResult = await testSSHCredential(credential) {
            results.append(sshResult)
        }
        
        // Test FTP
        if let ftpResult = await testFTPCredential(credential) {
            results.append(ftpResult)
        }
        
        // Test HTTP Basic Auth
        if let httpResult = await testHTTPCredential(credential) {
            results.append(httpResult)
        }
        
        // Test Telnet
        if let telnetResult = await testTelnetCredential(credential) {
            results.append(telnetResult)
        }
        
        // Test SMTP
        if let smtpResult = await testSMTPCredential(credential) {
            results.append(smtpResult)
        }
        
        // Test MySQL
        if let mysqlResult = await testMySQLCredential(credential) {
            results.append(mysqlResult)
        }
        
        // Test PostgreSQL
        if let pgResult = await testPostgreSQLCredential(credential) {
            results.append(pgResult)
        }
        
        // Test RDP
        if let rdpResult = await testRDPCredential(credential) {
            results.append(rdpResult)
        }
        
        return results
    }
    
    private func testSSHCredential(_ credential: StoredCredential) async -> CredentialTestResult? {
        let startTime = Date()
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/local/bin/sshpass")
        process.arguments = [
            "-p", credential.password,
            "ssh", "-o", "ConnectTimeout=5",
            "-o", "StrictHostKeyChecking=no",
            "-o", "UserKnownHostsFile=/dev/null",
            "\(credential.username)@\(credential.target)",
            "echo 'SSH_AUTH_SUCCESS'"
        ]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            let success = process.terminationStatus == 0 && output.contains("SSH_AUTH_SUCCESS")
            let responseTime = Date().timeIntervalSince(startTime)
            
            return CredentialTestResult(
                credential: credential,
                service: "SSH",
                target: credential.target,
                port: 22,
                success: success,
                responseTime: responseTime,
                additionalInfo: ["output": output]
            )
        } catch {
            return nil
        }
    }
    
    private func testFTPCredential(_ credential: StoredCredential) async -> CredentialTestResult? {
        let startTime = Date()
        
        let process = Process()
        let inputPipe = Pipe()
        let outputPipe = Pipe()
        
        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ftp")
        process.arguments = ["-n", credential.target]
        
        do {
            try process.run()
            
            let commands = """
            user \(credential.username) \(credential.password)
            pwd
            quit
            """
            
            inputPipe.fileHandleForWriting.write(commands.data(using: .utf8)!)
            inputPipe.fileHandleForWriting.closeFile()
            
            process.waitUntilExit()
            
            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            let success = process.terminationStatus == 0 && !output.contains("Login incorrect")
            let responseTime = Date().timeIntervalSince(startTime)
            
            return CredentialTestResult(
                credential: credential,
                service: "FTP",
                target: credential.target,
                port: 21,
                success: success,
                responseTime: responseTime,
                additionalInfo: ["output": output]
            )
        } catch {
            return nil
        }
    }
    
    private func testHTTPCredential(_ credential: StoredCredential) async -> CredentialTestResult? {
        let startTime = Date()
        
        let urls = [
            "http://\(credential.target)",
            "https://\(credential.target)",
            "http://\(credential.target):8080",
            "https://\(credential.target):8443"
        ]
        
        for urlString in urls {
            guard let url = URL(string: urlString) else { continue }
            
            var request = URLRequest(url: url)
            request.timeoutInterval = 10
            
            // Add Basic Auth header
            let loginString = "\(credential.username):\(credential.password)"
            let loginData = loginString.data(using: .utf8)!
            let base64LoginString = loginData.base64EncodedString()
            request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    let success = httpResponse.statusCode != 401 && httpResponse.statusCode != 403
                    let responseTime = Date().timeIntervalSince(startTime)
                    
                    if success {
                        return CredentialTestResult(
                            credential: credential,
                            service: "HTTP",
                            target: credential.target,
                            port: url.port ?? (url.scheme == "https" ? 443 : 80),
                            success: true,
                            responseTime: responseTime,
                            additionalInfo: [
                                "status_code": "\(httpResponse.statusCode)",
                                "url": urlString
                            ]
                        )
                    }
                }
            } catch {
                continue
            }
        }
        
        return nil
    }
    
    private func testTelnetCredential(_ credential: StoredCredential) async -> CredentialTestResult? {
        let startTime = Date()
        
        // Use expect script for Telnet authentication
        let expectScript = """
        #!/usr/bin/expect -f
        set timeout 10
        spawn telnet \(credential.target) 23
        expect "login:"
        send "\(credential.username)\\r"
        expect "Password:"
        send "\(credential.password)\\r"
        expect {
            "$" { exit 0 }
            "#" { exit 0 }
            ">" { exit 0 }
            timeout { exit 1 }
            eof { exit 1 }
        }
        """
        
        // Write expect script to temporary file
        let tempFile = "/tmp/telnet_test_\(UUID().uuidString).exp"
        
        do {
            try expectScript.write(toFile: tempFile, atomically: true, encoding: .utf8)
            
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/expect")
            process.arguments = [tempFile]
            
            try process.run()
            process.waitUntilExit()
            
            // Clean up
            try? FileManager.default.removeItem(atPath: tempFile)
            
            let success = process.terminationStatus == 0
            let responseTime = Date().timeIntervalSince(startTime)
            
            return CredentialTestResult(
                credential: credential,
                service: "Telnet",
                target: credential.target,
                port: 23,
                success: success,
                responseTime: responseTime,
                additionalInfo: [:]
            )
        } catch {
            try? FileManager.default.removeItem(atPath: tempFile)
            return nil
        }
    }
    
    private func testSMTPCredential(_ credential: StoredCredential) async -> CredentialTestResult? {
        let startTime = Date()
        
        // Test SMTP AUTH using openssl
        let process = Process()
        let inputPipe = Pipe()
        let outputPipe = Pipe()
        
        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        process.executableURL = URL(fileURLWithPath: "/usr/bin/openssl")
        process.arguments = ["s_client", "-connect", "\(credential.target):587", "-starttls", "smtp"]
        
        do {
            try process.run()
            
            let commands = """
            EHLO test.com
            AUTH LOGIN
            \(Data(credential.username.utf8).base64EncodedString())
            \(Data(credential.password.utf8).base64EncodedString())
            QUIT
            """
            
            inputPipe.fileHandleForWriting.write(commands.data(using: .utf8)!)
            inputPipe.fileHandleForWriting.closeFile()
            
            process.waitUntilExit()
            
            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            let success = output.contains("235") && output.contains("Authentication successful")
            let responseTime = Date().timeIntervalSince(startTime)
            
            return CredentialTestResult(
                credential: credential,
                service: "SMTP",
                target: credential.target,
                port: 587,
                success: success,
                responseTime: responseTime,
                additionalInfo: ["output": output]
            )
        } catch {
            return nil
        }
    }
    
    private func testMySQLCredential(_ credential: StoredCredential) async -> CredentialTestResult? {
        let startTime = Date()
        
        let process = Process()
        let outputPipe = Pipe()
        
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        process.executableURL = URL(fileURLWithPath: "/usr/local/bin/mysql")
        process.arguments = [
            "-h", credential.target,
            "-u", credential.username,
            "-p\(credential.password)",
            "-e", "SELECT 1 AS test_connection;"
        ]
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            let success = process.terminationStatus == 0 && output.contains("test_connection")
            let responseTime = Date().timeIntervalSince(startTime)
            
            return CredentialTestResult(
                credential: credential,
                service: "MySQL",
                target: credential.target,
                port: 3306,
                success: success,
                responseTime: responseTime,
                additionalInfo: ["output": output]
            )
        } catch {
            return nil
        }
    }
    
    private func testPostgreSQLCredential(_ credential: StoredCredential) async -> CredentialTestResult? {
        let startTime = Date()
        
        let process = Process()
        let outputPipe = Pipe()
        
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        process.executableURL = URL(fileURLWithPath: "/usr/local/bin/psql")
        process.arguments = [
            "-h", credential.target,
            "-U", credential.username,
            "-d", "postgres",
            "-c", "SELECT 1 AS test_connection;"
        ]
        process.environment = ["PGPASSWORD": credential.password]
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            let success = process.terminationStatus == 0 && output.contains("test_connection")
            let responseTime = Date().timeIntervalSince(startTime)
            
            return CredentialTestResult(
                credential: credential,
                service: "PostgreSQL",
                target: credential.target,
                port: 5432,
                success: success,
                responseTime: responseTime,
                additionalInfo: ["output": output]
            )
        } catch {
            return nil
        }
    }
    
    private func testRDPCredential(_ credential: StoredCredential) async -> CredentialTestResult? {
        let startTime = Date()
        
        // Use xfreerdp for RDP testing
        let process = Process()
        let outputPipe = Pipe()
        
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        process.executableURL = URL(fileURLWithPath: "/usr/local/bin/xfreerdp")
        process.arguments = [
            "/v:\(credential.target):3389",
            "/u:\(credential.username)",
            "/p:\(credential.password)",
            "/cert-ignore",
            "+auth-only"
        ]
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            let success = process.terminationStatus == 0 && !output.contains("Authentication failure")
            let responseTime = Date().timeIntervalSince(startTime)
            
            return CredentialTestResult(
                credential: credential,
                service: "RDP",
                target: credential.target,
                port: 3389,
                success: success,
                responseTime: responseTime,
                additionalInfo: ["output": output]
            )
        } catch {
            return nil
        }
    }
    
    // MARK: - Keychain Integration
    
    private func saveCredentialsToKeychain() {
        do {
            let data = try JSONEncoder().encode(credentials)
            let encryptedData = try AES.GCM.seal(data, using: encryptionKey)
            let combinedData = encryptedData.combined!
            
            Self.saveToKeychain(
                data: combinedData,
                service: keychainService,
                account: "stored_credentials"
            )
        } catch {
            print("Failed to save credentials to Keychain: \(error)")
        }
    }
    
    private func loadCredentialsFromKeychain() {
        guard let encryptedData = Self.getKeychainData(service: keychainService, account: "stored_credentials") else {
            return
        }
        
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: encryptionKey)
            credentials = try JSONDecoder().decode([StoredCredential].self, from: decryptedData)
        } catch {
            print("Failed to load credentials from Keychain: \(error)")
        }
    }
    
    private static func saveToKeychain(data: Data, service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private static func getKeychainData(service: String, account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        return status == errSecSuccess ? result as? Data : nil
    }
    
    // MARK: - Export/Import
    
    func exportCredentials() -> String {
        let exportData = credentials.map { credential in
            [
                "username": credential.username,
                "password": credential.password,
                "service": credential.service,
                "target": credential.target,
                "port": credential.port,
                "verified": credential.verified,
                "confidence": credential.confidence.rawValue
            ]
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            return String(data: jsonData, encoding: .utf8) ?? ""
        } catch {
            return "Export failed: \(error)"
        }
    }
    
    func clearAllCredentials() {
        credentials.removeAll()
        saveCredentialsToKeychain()
    }
    
    func getVaultStatistics() -> String {
        let uniqueTargets = Set(credentials.map { $0.target }).count
        let uniqueServices = Set(credentials.map { $0.service }).count
        
        return """
        Credential Vault Statistics:
        - Total Credentials: \(totalCredentials)
        - Verified Credentials: \(verifiedCredentials)
        - High Confidence: \(highConfidenceCredentials)
        - Unique Targets: \(uniqueTargets)
        - Unique Services: \(uniqueServices)
        - Last Test: \(lastTestTime?.formatted() ?? "Never")
        """
    }
}

// MARK: - StoredCredential Extension

extension StoredCredential {
    init(username: String, password: String, service: String, target: String, port: Int, source: String, confidence: CredentialConfidence, timestamp: Date, verified: Bool, lastTested: Date?, successfulServices: [String]) {
        self.username = username
        self.password = password
        self.service = service
        self.target = target
        self.port = port
        self.source = source
        self.confidence = confidence
        self.timestamp = timestamp
        self.verified = verified
        self.lastTested = lastTested
        self.successfulServices = successfulServices
    }
}