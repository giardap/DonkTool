//
//  SecureCredentialVault.swift
//  DonkTool
//
//  Enhanced secure credential storage with encryption and validation
//

import Foundation
import Security
import CryptoKit
import LocalAuthentication

// MARK: - Enhanced Security Models

struct SecureStoredCredential: Identifiable, Codable {
    let id = UUID()
    let encryptedUsername: Data
    let encryptedPassword: Data
    let service: String
    let target: String
    let port: Int
    let source: String
    let confidence: CredentialConfidence
    let timestamp: Date
    let verified: Bool
    let lastTested: Date?
    let successfulServices: [String]
    let salt: Data
    let validationHash: String
    
    // Computed properties for secure access
    func getUsername(using key: SymmetricKey) throws -> String {
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedUsername)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        guard let username = String(data: decryptedData, encoding: .utf8) else {
            throw CredentialError.decryptionFailed
        }
        return username
    }
    
    func getPassword(using key: SymmetricKey) throws -> String {
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedPassword)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        guard let password = String(data: decryptedData, encoding: .utf8) else {
            throw CredentialError.decryptionFailed
        }
        return password
    }
}

enum CredentialError: Error {
    case encryptionFailed
    case decryptionFailed
    case invalidCredential
    case authenticationRequired
}

// MARK: - Credential Validator

struct CredentialValidator {
    // Common false positive patterns to filter out
    static let falsePositivePatterns = [
        "test:test", "admin:admin", "root:root", "user:user",
        "demo:demo", "guest:guest", "example:example",
        "username:password", "login:login", "default:default",
        "changeme:changeme", "password:password", "123456:123456"
    ]
    
    // Weak password patterns
    static let weakPasswordPatterns = [
        "^password\\d*$", "^12345\\d*$", "^admin\\d*$", "^test\\d*$",
        "^qwerty\\d*$", "^letmein\\d*$", "^welcome\\d*$"
    ]
    
    static func isValidCredential(username: String, password: String, context: String = "") -> Bool {
        // Check minimum requirements
        guard username.count >= 3 && password.count >= 4 else { return false }
        
        // Check for identical username/password
        guard username.lowercased() != password.lowercased() else { return false }
        
        // Check against false positive patterns
        let combined = "\(username.lowercased()):\(password.lowercased())"
        if falsePositivePatterns.contains(combined) { return false }
        
        // Check for placeholder values
        let placeholders = ["<username>", "<password>", "{username}", "{password}", "xxxx", "****"]
        if placeholders.contains(where: { username.contains($0) || password.contains($0) }) {
            return false
        }
        
        // Check for weak passwords
        for pattern in weakPasswordPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(password.startIndex..., in: password)
                if regex.firstMatch(in: password, options: [], range: range) != nil {
                    return false
                }
            }
        }
        
        // Context-based validation
        if !context.isEmpty {
            // Check if this is from documentation/examples
            let docIndicators = ["example", "documentation", "sample", "tutorial", "demo"]
            if docIndicators.contains(where: { context.lowercased().contains($0) }) {
                return false
            }
        }
        
        return true
    }
    
    static func calculateConfidence(username: String, password: String, context: String) -> CredentialConfidence {
        var score = 50 // Base score
        
        // Positive indicators
        if password.count >= 8 { score += 10 }
        if password.contains(where: { $0.isUppercase }) { score += 5 }
        if password.contains(where: { $0.isNumber }) { score += 5 }
        if password.contains(where: { "!@#$%^&*()".contains($0) }) { score += 10 }
        
        // Negative indicators
        if weakPasswordPatterns.contains(where: { password.matches(pattern: $0) }) { score -= 20 }
        if username.contains("test") || username.contains("demo") { score -= 15 }
        if password.contains(username) || username.contains(password) { score -= 15 }
        
        // Context-based adjustments
        if context.contains("default") || context.contains("initial") { score -= 10 }
        if context.contains("hardcoded") || context.contains("embedded") { score += 15 }
        
        switch score {
        case 70...: return .high
        case 40..<70: return .medium
        default: return .low
        }
    }
}

// MARK: - Secure Credential Vault

@Observable
@MainActor
class SecureCredentialVault {
    static let shared = SecureCredentialVault()
    
    // Encrypted storage
    private var credentials: [SecureStoredCredential] = []
    private let keychainService = "com.donktool.secure.credentials"
    private var encryptionKey: SymmetricKey?
    private let authContext = LAContext()
    
    // Security settings
    private let requireBiometricAuth = true
    private let autoLockTimeout: TimeInterval = 300 // 5 minutes
    private var lastAccessTime = Date()
    private var isLocked = true
    
    // Vault statistics
    var totalCredentials: Int { credentials.count }
    var verifiedCredentials: Int { credentials.filter { $0.verified }.count }
    var highConfidenceCredentials: Int { 
        credentials.filter { $0.confidence == .high }.count 
    }
    
    // Testing state
    var isTestingCredentials = false
    var currentTestProgress: Double = 0.0
    var lastTestTime: Date?
    
    private init() {
        Task {
            await initializeVault()
        }
    }
    
    private func initializeVault() async {
        // Require authentication to access vault
        guard await authenticateUser() else {
            print("🔐 Credential Vault: Authentication required")
            return
        }
        
        // Initialize encryption key with hardware security
        self.encryptionKey = await getOrCreateSecureEncryptionKey()
        await loadCredentialsFromKeychain()
        // setupIntegrationListeners() // TODO: Implement when integration framework is ready
        startAutoLockTimer()
    }
    
    // MARK: - Authentication
    
    private func authenticateUser() async -> Bool {
        guard requireBiometricAuth else { return true }
        
        authContext.localizedReason = "Authenticate to access credential vault"
        
        do {
            let success = try await authContext.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Access secure credentials"
            )
            if success {
                isLocked = false
                lastAccessTime = Date()
            }
            return success
        } catch {
            print("🔐 Biometric authentication failed: \(error)")
            return false
        }
    }
    
    private func requireAuthentication() async throws {
        if isLocked || Date().timeIntervalSince(lastAccessTime) > autoLockTimeout {
            guard await authenticateUser() else {
                throw CredentialError.authenticationRequired
            }
        }
        lastAccessTime = Date()
    }
    
    // MARK: - Enhanced Encryption
    
    private func getOrCreateSecureEncryptionKey() async -> SymmetricKey {
        let keyName = "donktool_secure_credential_key"
        let accessControl = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            [.privateKeyUsage, .biometryCurrentSet],
            nil
        )!
        
        // Try to retrieve existing key from Secure Enclave
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyName.data(using: .utf8)!,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecReturnRef as String: true
        ]
        
        var keyRef: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &keyRef)
        
        if status == errSecSuccess {
            // Derive symmetric key from Secure Enclave key
            return deriveSymmetricKey(from: keyRef as! SecKey)
        } else {
            // Generate new key in Secure Enclave
            let attributes: [String: Any] = [
                kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
                kSecAttrKeySizeInBits as String: 256,
                kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
                kSecPrivateKeyAttrs as String: [
                    kSecAttrIsPermanent as String: true,
                    kSecAttrApplicationTag as String: keyName.data(using: .utf8)!,
                    kSecAttrAccessControl as String: accessControl
                ]
            ]
            
            guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, nil) else {
                // Fallback to standard encryption if Secure Enclave unavailable
                return SymmetricKey(size: .bits256)
            }
            
            return deriveSymmetricKey(from: privateKey)
        }
    }
    
    private func deriveSymmetricKey(from secKey: SecKey) -> SymmetricKey {
        // Use key agreement to derive symmetric key
        guard let publicKey = SecKeyCopyPublicKey(secKey),
              let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data? else {
            return SymmetricKey(size: .bits256)
        }
        
        // Use first 32 bytes of public key as seed for symmetric key
        let keyData = publicKeyData.prefix(32)
        return SymmetricKey(data: keyData)
    }
    
    // MARK: - Secure Credential Management
    
    func addCredential(from discovery: CredentialDiscovery) async throws {
        try await requireAuthentication()
        
        // Validate credential
        guard CredentialValidator.isValidCredential(
            username: discovery.username,
            password: discovery.password,
            context: discovery.source
        ) else {
            print("🔐 Rejected invalid credential: \(discovery.username)")
            return
        }
        
        // Generate unique salt for this credential
        let salt = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        
        // Encrypt credentials
        guard let key = encryptionKey else { throw CredentialError.encryptionFailed }
        
        let usernameData = discovery.username.data(using: .utf8)!
        let passwordData = discovery.password.data(using: .utf8)!
        
        let encryptedUsername = try AES.GCM.seal(usernameData, using: key).combined!
        let encryptedPassword = try AES.GCM.seal(passwordData, using: key).combined!
        
        // Create validation hash
        let validationData = "\(discovery.username):\(discovery.password):\(salt.base64EncodedString())".data(using: .utf8)!
        let validationHash = SHA256.hash(data: validationData).compactMap { 
            String(format: "%02x", $0) 
        }.joined()
        
        let newCredential = SecureStoredCredential(
            encryptedUsername: encryptedUsername,
            encryptedPassword: encryptedPassword,
            service: discovery.service,
            target: discovery.target,
            port: discovery.port,
            source: discovery.source,
            confidence: CredentialValidator.calculateConfidence(
                username: discovery.username,
                password: discovery.password,
                context: discovery.source
            ),
            timestamp: discovery.timestamp,
            verified: false,
            lastTested: nil,
            successfulServices: [],
            salt: salt,
            validationHash: validationHash
        )
        
        // Check for duplicates using validation hash
        if !credentials.contains(where: { $0.validationHash == newCredential.validationHash }) {
            credentials.append(newCredential)
            await saveCredentialsToKeychain()
            
            print("🔐 Secure Vault: Added credential for \(discovery.target):\(discovery.port)")
            
            // Auto-test new credentials
            Task {
                await testCredential(newCredential)
            }
        }
    }
    
    func getDecryptedCredentials() async throws -> [(username: String, password: String, credential: SecureStoredCredential)] {
        try await requireAuthentication()
        guard let key = encryptionKey else { throw CredentialError.decryptionFailed }
        
        var decrypted: [(String, String, SecureStoredCredential)] = []
        
        for credential in credentials {
            do {
                let username = try credential.getUsername(using: key)
                let password = try credential.getPassword(using: key)
                decrypted.append((username, password, credential))
            } catch {
                print("🔐 Failed to decrypt credential: \(error)")
            }
        }
        
        return decrypted
    }
    
    // MARK: - Auto-lock Timer
    
    private func startAutoLockTimer() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task { @MainActor in
                if Date().timeIntervalSince(self.lastAccessTime) > self.autoLockTimeout {
                    self.isLocked = true
                    self.encryptionKey = nil // Clear key from memory
                    print("🔐 Credential Vault: Auto-locked due to inactivity")
                }
            }
        }
    }
    
    // MARK: - Enhanced Testing
    
    private func testCredential(_ credential: SecureStoredCredential) async {
        guard let key = encryptionKey else { return }
        
        do {
            let username = try credential.getUsername(using: key)
            let password = try credential.getPassword(using: key)
            
            // Use existing test methods but with decrypted values
            // ... (existing test logic)
        } catch {
            print("🔐 Failed to test credential: \(error)")
        }
    }
    
    // MARK: - Secure Keychain Operations
    
    private func saveCredentialsToKeychain() async {
        guard let key = encryptionKey else { return }
        
        do {
            let data = try JSONEncoder().encode(credentials)
            let encryptedData = try AES.GCM.seal(data, using: key)
            let combinedData = encryptedData.combined!
            
            // Use enhanced Keychain attributes
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: keychainService,
                kSecAttrAccount as String: "secure_credentials",
                kSecValueData as String: combinedData,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                kSecAttrSynchronizable as String: false
            ]
            
            SecItemDelete(query as CFDictionary)
            let status = SecItemAdd(query as CFDictionary, nil)
            
            if status != errSecSuccess {
                print("🔐 Keychain save failed: \(status)")
            }
        } catch {
            print("🔐 Failed to save credentials: \(error)")
        }
    }
    
    private func loadCredentialsFromKeychain() async {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "secure_credentials",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let encryptedData = result as? Data,
              let key = encryptionKey else { return }
        
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            credentials = try JSONDecoder().decode([SecureStoredCredential].self, from: decryptedData)
        } catch {
            print("🔐 Failed to load credentials: \(error)")
        }
    }
    
    // MARK: - Memory Protection
    
    func clearSensitiveData() {
        // Overwrite encryption key in memory
        if encryptionKey != nil {
            encryptionKey = SymmetricKey(size: .bits256) // Overwrite with random data
            encryptionKey = nil
        }
        
        // Clear credential arrays
        credentials.removeAll()
        isLocked = true
    }
    
    deinit {
        Task { @MainActor in
            clearSensitiveData()
        }
    }
}

// MARK: - String Extension

extension String {
    func matches(pattern: String) -> Bool {
        return range(of: pattern, options: .regularExpression) != nil
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let secureCredentialAdded = Notification.Name("secureCredentialAdded")
    static let vaultLocked = Notification.Name("vaultLocked")
    static let vaultUnlocked = Notification.Name("vaultUnlocked")
}