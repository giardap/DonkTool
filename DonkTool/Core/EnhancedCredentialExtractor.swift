//
//  EnhancedCredentialExtractor.swift
//  DonkTool
//
//  Secure credential extraction with validation and sanitization
//

import Foundation
import NaturalLanguage

// MARK: - Enhanced Credential Extractor

class EnhancedCredentialExtractor {
    static let shared = EnhancedCredentialExtractor()
    
    // Enhanced patterns with named capture groups
    private let credentialPatterns: [(pattern: String, name: String)] = [
        // Standard formats
        (#"(?<user>\b[a-zA-Z0-9._-]{3,20}\b)\s*[:=]\s*(?<pass>[^\s:=]{4,30})"#, "colon_format"),
        (#"(?<user>\b[a-zA-Z0-9._-]{3,20}\b)\s*/\s*(?<pass>[^\s/]{4,30})"#, "slash_format"),
        
        // Quoted formats
        (#"[\"'](?<user>[a-zA-Z0-9._-]{3,20})[\"']\s*[:=]\s*[\"'](?<pass>[^\"']{4,30})[\"']"#, "quoted_format"),
        
        // Key-value formats
        (#"user(?:name)?[=\"'\s]+(?<user>[a-zA-Z0-9._-]{3,20})[\"'\s]+.*?pass(?:word)?[=\"'\s]+(?<pass>[^\s\"']{4,30})"#, "key_value"),
        (#"login[=\"'\s]+(?<user>[a-zA-Z0-9._-]{3,20})[\"'\s]+.*?pass(?:word)?[=\"'\s]+(?<pass>[^\s\"']{4,30})"#, "login_format"),
        
        // Database connection strings
        (#"(?:mysql|postgres|mongodb)://(?<user>[^:]+):(?<pass>[^@]+)@"#, "db_connection"),
        
        // Basic auth headers
        (#"Basic\s+[A-Za-z0-9+/]+=*"#, "basic_auth"),
        
        // Environment variable patterns
        (#"(?:DB_USER|USERNAME|USER)[=\"']?\s*(?<user>[a-zA-Z0-9._-]{3,20})"#, "env_user"),
        (#"(?:DB_PASS|PASSWORD|PASS)[=\"']?\s*(?<pass>[^\s\"']{4,30})"#, "env_pass")
    ]
    
    // Context indicators for higher confidence
    private let positiveContextIndicators = [
        "hardcoded", "embedded", "stored", "database", "config",
        "production", "server", "authentication", "credential"
    ]
    
    private let negativeContextIndicators = [
        "example", "sample", "test", "demo", "documentation",
        "tutorial", "placeholder", "template", "mock", "dummy"
    ]
    
    private init() {}
    
    // MARK: - Main Extraction Method
    
    func extractCredentials(from text: String, source: String, target: String, port: Int) -> [CredentialDiscovery] {
        var discoveries: [CredentialDiscovery] = []
        var processedPairs = Set<String>()
        
        // Clean and preprocess text
        let cleanedText = preprocessText(text)
        
        // Extract using regex patterns
        discoveries.append(contentsOf: extractWithPatterns(cleanedText, source: source, target: target, port: port))
        
        // Extract from Basic Auth headers
        discoveries.append(contentsOf: extractBasicAuth(cleanedText, source: source, target: target, port: port))
        
        // Extract from structured data (JSON, XML)
        discoveries.append(contentsOf: extractFromStructuredData(cleanedText, source: source, target: target, port: port))
        
        // Apply NLP-based extraction for natural language contexts
        discoveries.append(contentsOf: extractWithNLP(cleanedText, source: source, target: target, port: port))
        
        // Deduplicate and validate
        return discoveries.compactMap { discovery in
            let pairKey = "\(discovery.username):\(discovery.password)"
            guard !processedPairs.contains(pairKey) else { return nil }
            processedPairs.insert(pairKey)
            
            // Enhanced validation
            guard validateCredential(discovery, context: cleanedText) else { return nil }
            
            return discovery
        }
    }
    
    // MARK: - Pattern-Based Extraction
    
    private func extractWithPatterns(_ text: String, source: String, target: String, port: Int) -> [CredentialDiscovery] {
        var discoveries: [CredentialDiscovery] = []
        
        for (pattern, patternName) in credentialPatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { continue }
            
            let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
            
            for match in matches {
                var username: String?
                var password: String?
                
                // Extract named groups
                if let userRange = Range(match.range(withName: "user"), in: text) {
                    username = String(text[userRange])
                }
                if let passRange = Range(match.range(withName: "pass"), in: text) {
                    password = String(text[passRange])
                }
                
                // Handle special cases
                if patternName == "basic_auth" {
                    if let decoded = decodeBasicAuth(String(text[Range(match.range, in: text)!])) {
                        username = decoded.username
                        password = decoded.password
                    }
                }
                
                if let user = username, let pass = password {
                    discoveries.append(CredentialDiscovery(
                        username: sanitizeUsername(user),
                        password: sanitizePassword(pass),
                        service: determineService(from: text, port: port),
                        target: target,
                        port: port,
                        source: "\(source)_\(patternName)",
                        confidence: calculateConfidence(user: user, pass: pass, context: text, pattern: patternName),
                        timestamp: Date()
                    ))
                }
            }
        }
        
        return discoveries
    }
    
    // MARK: - Basic Auth Extraction
    
    private func extractBasicAuth(_ text: String, source: String, target: String, port: Int) -> [CredentialDiscovery] {
        var discoveries: [CredentialDiscovery] = []
        
        let pattern = #"Basic\s+([A-Za-z0-9+/]+=*)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }
        
        let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
        
        for match in matches {
            guard match.numberOfRanges >= 2,
                  let range = Range(match.range(at: 1), in: text) else { continue }
            
            let base64String = String(text[range])
            if let decoded = decodeBasicAuth("Basic \(base64String)") {
                discoveries.append(CredentialDiscovery(
                    username: decoded.username,
                    password: decoded.password,
                    service: "HTTP",
                    target: target,
                    port: port,
                    source: "\(source)_basic_auth",
                    confidence: .high,
                    timestamp: Date()
                ))
            }
        }
        
        return discoveries
    }
    
    // MARK: - Structured Data Extraction
    
    private func extractFromStructuredData(_ text: String, source: String, target: String, port: Int) -> [CredentialDiscovery] {
        var discoveries: [CredentialDiscovery] = []
        
        // Try JSON extraction
        if let jsonData = text.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            discoveries.append(contentsOf: extractFromJSON(json, source: source, target: target, port: port))
        }
        
        // Try XML/Config file patterns
        let configPatterns = [
            (#"<username>([^<]+)</username>.*?<password>([^<]+)</password>"#, "xml"),
            (#"username\s*=\s*([^\s\n]+).*?password\s*=\s*([^\s\n]+)"#, "config")
        ]
        
        for (pattern, type) in configPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) {
                let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
                
                for match in matches where match.numberOfRanges >= 3 {
                    if let userRange = Range(match.range(at: 1), in: text),
                       let passRange = Range(match.range(at: 2), in: text) {
                        let username = String(text[userRange])
                        let password = String(text[passRange])
                        
                        discoveries.append(CredentialDiscovery(
                            username: sanitizeUsername(username),
                            password: sanitizePassword(password),
                            service: determineService(from: text, port: port),
                            target: target,
                            port: port,
                            source: "\(source)_\(type)",
                            confidence: calculateConfidence(user: username, pass: password, context: text, pattern: type),
                            timestamp: Date()
                        ))
                    }
                }
            }
        }
        
        return discoveries
    }
    
    // MARK: - NLP-Based Extraction
    
    private func extractWithNLP(_ text: String, source: String, target: String, port: Int) -> [CredentialDiscovery] {
        var discoveries: [CredentialDiscovery] = []
        
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        
        var potentialUsernames: [String] = []
        var potentialPasswords: [String] = []
        
        // Look for patterns around credential-related words
        let credentialKeywords = ["username", "user", "login", "password", "pass", "credential"]
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass) { tag, range in
            let word = String(text[range])
            
            if credentialKeywords.contains(word.lowercased()) {
                // Look for the next noun or other word that could be a credential
                var nextRange = range
                for _ in 0..<5 { // Look ahead up to 5 tokens
                    guard let next = text.range(of: #"\S+"#, options: .regularExpression, range: nextRange.upperBound..<text.endIndex) else { break }
                    let nextWord = String(text[next])
                    
                    if nextWord.count >= 3 && nextWord.count <= 30 && !credentialKeywords.contains(nextWord.lowercased()) {
                        if word.lowercased().contains("user") || word.lowercased().contains("login") {
                            potentialUsernames.append(nextWord)
                        } else if word.lowercased().contains("pass") {
                            potentialPasswords.append(nextWord)
                        }
                        break
                    }
                    nextRange = next
                }
            }
            
            return true
        }
        
        // Pair up potential credentials
        for username in potentialUsernames {
            for password in potentialPasswords {
                if CredentialValidator.isValidCredential(username: username, password: password, context: text) {
                    discoveries.append(CredentialDiscovery(
                        username: sanitizeUsername(username),
                        password: sanitizePassword(password),
                        service: determineService(from: text, port: port),
                        target: target,
                        port: port,
                        source: "\(source)_nlp",
                        confidence: .low, // NLP extraction is less certain
                        timestamp: Date()
                    ))
                }
            }
        }
        
        return discoveries
    }
    
    // MARK: - Helper Methods
    
    private func preprocessText(_ text: String) -> String {
        // Remove excessive whitespace
        let cleaned = text.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        
        // Remove common obfuscation
        return cleaned
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\t", with: "\t")
            .replacingOccurrences(of: "\\\"", with: "\"")
    }
    
    private func sanitizeUsername(_ username: String) -> String {
        // Remove quotes and trim
        return username
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"'`"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func sanitizePassword(_ password: String) -> String {
        // Remove quotes but preserve special characters
        return password
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"'`"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func decodeBasicAuth(_ authHeader: String) -> (username: String, password: String)? {
        guard authHeader.hasPrefix("Basic ") else { return nil }
        
        let base64String = String(authHeader.dropFirst(6))
        guard let data = Data(base64Encoded: base64String),
              let decoded = String(data: data, encoding: .utf8) else { return nil }
        
        let parts = decoded.split(separator: ":", maxSplits: 1)
        guard parts.count == 2 else { return nil }
        
        return (String(parts[0]), String(parts[1]))
    }
    
    private func extractFromJSON(_ json: [String: Any], source: String, target: String, port: Int) -> [CredentialDiscovery] {
        var discoveries: [CredentialDiscovery] = []
        
        // Common credential keys in JSON
        let userKeys = ["username", "user", "login", "email", "account"]
        let passKeys = ["password", "pass", "secret", "key", "token"]
        
        var username: String?
        var password: String?
        
        for (key, value) in json {
            if userKeys.contains(where: { key.lowercased().contains($0) }),
               let user = value as? String {
                username = user
            }
            if passKeys.contains(where: { key.lowercased().contains($0) }),
               let pass = value as? String {
                password = pass
            }
        }
        
        if let user = username, let pass = password,
           CredentialValidator.isValidCredential(username: user, password: pass) {
            discoveries.append(CredentialDiscovery(
                username: user,
                password: pass,
                service: determineService(from: "", port: port),
                target: target,
                port: port,
                source: "\(source)_json",
                confidence: .medium,
                timestamp: Date()
            ))
        }
        
        return discoveries
    }
    
    private func determineService(from context: String, port: Int) -> String {
        // Port-based service detection
        switch port {
        case 22: return "SSH"
        case 21: return "FTP"
        case 23: return "Telnet"
        case 80, 8080: return "HTTP"
        case 443, 8443: return "HTTPS"
        case 3306: return "MySQL"
        case 5432: return "PostgreSQL"
        case 27017: return "MongoDB"
        case 3389: return "RDP"
        case 5900: return "VNC"
        default:
            // Context-based detection
            let services = [
                "ssh": "SSH", "ftp": "FTP", "telnet": "Telnet",
                "http": "HTTP", "mysql": "MySQL", "postgres": "PostgreSQL",
                "mongodb": "MongoDB", "rdp": "RDP", "vnc": "VNC"
            ]
            
            for (keyword, service) in services {
                if context.lowercased().contains(keyword) {
                    return service
                }
            }
            
            return "Unknown"
        }
    }
    
    private func calculateConfidence(user: String, pass: String, context: String, pattern: String) -> CredentialConfidence {
        var score = 50 // Base score
        
        // Pattern-based adjustments
        switch pattern {
        case "basic_auth", "db_connection":
            score += 20
        case "quoted_format", "key_value":
            score += 15
        case "env_user", "env_pass":
            score += 10
        default:
            break
        }
        
        // Context-based adjustments
        let lowerContext = context.lowercased()
        
        for indicator in positiveContextIndicators {
            if lowerContext.contains(indicator) {
                score += 10
            }
        }
        
        for indicator in negativeContextIndicators {
            if lowerContext.contains(indicator) {
                score -= 20
            }
        }
        
        // Credential quality adjustments
        if pass.count >= 12 { score += 10 }
        if pass.contains(where: { $0.isUppercase }) && 
           pass.contains(where: { $0.isLowercase }) && 
           pass.contains(where: { $0.isNumber }) { score += 15 }
        
        // Common password penalty
        let commonPasswords = ["password", "123456", "admin", "qwerty", "letmein"]
        if commonPasswords.contains(pass.lowercased()) { score -= 30 }
        
        return score >= 70 ? .high : (score >= 40 ? .medium : .low)
    }
    
    private func validateCredential(_ discovery: CredentialDiscovery, context: String) -> Bool {
        // Use enhanced validator
        return CredentialValidator.isValidCredential(
            username: discovery.username,
            password: discovery.password,
            context: context
        )
    }
}