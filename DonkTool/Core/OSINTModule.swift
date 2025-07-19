//
//  OSINTModule.swift
//  DonkTool
//
//  Open Source Intelligence (OSINT) gathering capabilities
//

import Foundation
import SwiftUI

@MainActor
class OSINTModule: ObservableObject {
    static let shared = OSINTModule()
    
    @Published var isGathering = false
    @Published var gatheringProgress: Double = 0.0
    @Published var currentSource = ""
    @Published var statusMessage = "Ready"
    @Published var reports: [OSINTReport] = []
    @Published var findings: [OSINTFinding] = []
    
    private let session = URLSession.shared
    private var apiKeys: [String: String] = [:]
    
    private init() {
        loadAPIKeys()
    }
    
    // MARK: - Intelligence Gathering
    
    func gatherIntelligence(target: String, searchType: OSINTSearchType = .domain, sources: [OSINTSource]) async -> OSINTReport {
        isGathering = true
        gatheringProgress = 0.0
        
        let report = OSINTReport(
            target: target,
            startTime: Date(),
            sources: sources,
            findings: [],
            executionTime: 0
        )
        
        var allFindings: [OSINTFinding] = []
        let totalSources = Double(sources.count)
        
        for (index, source) in sources.enumerated() {
            currentSource = source.rawValue
            gatheringProgress = Double(index) / totalSources
            
            print("🔍 Gathering intelligence from: \(source.rawValue)")
            
            let sourceFindings = await gatherFromSource(source, target: target, searchType: searchType)
            allFindings.append(contentsOf: sourceFindings)
            
            // Small delay between sources to be respectful
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
        
        gatheringProgress = 1.0
        
        let finalReport = OSINTReport(
            target: target,
            startTime: report.startTime,
            sources: sources,
            findings: allFindings,
            executionTime: Date().timeIntervalSince(report.startTime)
        )
        
        reports.append(finalReport)
        findings.append(contentsOf: allFindings)
        
        isGathering = false
        return finalReport
    }
    
    private func gatherFromSource(_ source: OSINTSource, target: String, searchType: OSINTSearchType) async -> [OSINTFinding] {
        switch source {
        case .whois:
            return await performWhoisLookup(target)
        case .shodan:
            return await performShodanSearch(target)
        case .censys:
            return await performCensysSearch(target)
        case .theHarvester:
            return await runTheHarvester(target)
        case .socialMedia:
            return await searchSocialMedia(target, searchType: searchType)
        case .sherlock:
            return await runSherlockSearch(target)
        case .pastebin:
            return await searchPastebin(target)
        case .dnsRecon:
            return await performDNSRecon(target)
        case .subdomainEnum:
            return await enumerateSubdomains(target)
        case .googleDorking:
            return await performGoogleDorking(target, searchType: searchType)
        case .breachData:
            return await searchBreachData(target)
        case .phoneNumberLookup:
            return await performPhoneNumberLookup(target)
        case .haveibeenpwned:
            return await checkHaveIBeenPwned(target)
        case .emailVerification:
            return await verifyEmail(target)
        case .linkedinOSINT:
            return await searchLinkedIn(target, searchType: searchType)
        case .githubOSINT:
            return await searchGitHub(target, searchType: searchType)
        }
    }
    
    // MARK: - WHOIS Lookup
    
    private func performWhoisLookup(_ target: String) async -> [OSINTFinding] {
        guard ToolDetection.shared.isToolInstalled("whois") else {
            return [createErrorFinding("WHOIS tool not installed", source: .whois)]
        }
        
        let process = Process()
        let pipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: "/usr/bin/whois")
        process.arguments = [target]
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            return parseWhoisOutput(output, target: target)
            
        } catch {
            return [createErrorFinding("WHOIS lookup failed: \(error)", source: .whois)]
        }
    }
    
    private func parseWhoisOutput(_ output: String, target: String) -> [OSINTFinding] {
        var findings: [OSINTFinding] = []
        let lines = output.components(separatedBy: .newlines)
        
        var registrar = ""
        var registrationDate = ""
        var expirationDate = ""
        var nameServers: [String] = []
        var contacts: [String] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if trimmedLine.lowercased().contains("registrar:") {
                registrar = extractValue(from: trimmedLine)
            } else if trimmedLine.lowercased().contains("creation date:") || trimmedLine.lowercased().contains("registered:") {
                registrationDate = extractValue(from: trimmedLine)
            } else if trimmedLine.lowercased().contains("expiry date:") || trimmedLine.lowercased().contains("expires:") {
                expirationDate = extractValue(from: trimmedLine)
            } else if trimmedLine.lowercased().contains("name server:") {
                nameServers.append(extractValue(from: trimmedLine))
            } else if trimmedLine.lowercased().contains("admin") || trimmedLine.lowercased().contains("tech") {
                contacts.append(trimmedLine)
            }
        }
        
        // Create findings
        if !registrar.isEmpty {
            findings.append(OSINTFinding(
                source: .whois,
                type: .domainInfo,
                content: "Registrar: \(registrar)",
                confidence: .high,
                timestamp: Date(),
                metadata: ["registrar": registrar]
            ))
        }
        
        if !registrationDate.isEmpty {
            findings.append(OSINTFinding(
                source: .whois,
                type: .domainInfo,
                content: "Registration Date: \(registrationDate)",
                confidence: .high,
                timestamp: Date(),
                metadata: ["registration_date": registrationDate]
            ))
        }
        
        if !nameServers.isEmpty {
            findings.append(OSINTFinding(
                source: .whois,
                type: .infrastructure,
                content: "Name Servers: \(nameServers.joined(separator: ", "))",
                confidence: .high,
                timestamp: Date(),
                metadata: ["name_servers": nameServers.joined(separator: ", ")]
            ))
        }
        
        return findings
    }
    
    // MARK: - Shodan Integration
    
    private func performShodanSearch(_ target: String) async -> [OSINTFinding] {
        guard let apiKey = apiKeys["shodan"] else {
            return [createErrorFinding("Shodan API key not configured", source: .shodan)]
        }
        
        let urlString = "https://api.shodan.io/shodan/host/\(target)?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            return [createErrorFinding("Invalid Shodan URL", source: .shodan)]
        }
        
        do {
            let (data, _) = try await session.data(from: url)
            return parseShodanResponse(data)
        } catch {
            return [createErrorFinding("Shodan search failed: \(error)", source: .shodan)]
        }
    }
    
    private func parseShodanResponse(_ data: Data) -> [OSINTFinding] {
        // Parse Shodan API response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [createErrorFinding("Failed to parse Shodan response", source: .shodan)]
        }
        
        var findings: [OSINTFinding] = []
        
        if let ports = json["ports"] as? [Int] {
            findings.append(OSINTFinding(
                source: .shodan,
                type: .networkInfo,
                content: "Open Ports: \(ports.map(String.init).joined(separator: ", "))",
                confidence: .high,
                timestamp: Date(),
                metadata: ["ports": ports.map(String.init).joined(separator: ", ")]
            ))
        }
        
        if let org = json["org"] as? String {
            findings.append(OSINTFinding(
                source: .shodan,
                type: .organizationInfo,
                content: "Organization: \(org)",
                confidence: .high,
                timestamp: Date(),
                metadata: ["organization": org]
            ))
        }
        
        if let country = json["country_name"] as? String {
            findings.append(OSINTFinding(
                source: .shodan,
                type: .locationInfo,
                content: "Country: \(country)",
                confidence: .high,
                timestamp: Date(),
                metadata: ["country": country]
            ))
        }
        
        return findings
    }
    
    // MARK: - The Harvester Integration
    
    private func runTheHarvester(_ target: String) async -> [OSINTFinding] {
        guard ToolDetection.shared.isToolInstalled("theHarvester") else {
            return [createErrorFinding("theHarvester not installed", source: .theHarvester)]
        }
        
        let process = Process()
        let pipe = Pipe()
        
        // Find theHarvester path
        let harvesterPaths = [
            "/usr/local/bin/theHarvester",
            "/opt/homebrew/bin/theHarvester",
            "/usr/bin/theHarvester"
        ]
        
        var executablePath: String?
        for path in harvesterPaths {
            if FileManager.default.fileExists(atPath: path) {
                executablePath = path
                break
            }
        }
        
        guard let execPath = executablePath else {
            return [createErrorFinding("theHarvester executable not found", source: .theHarvester)]
        }
        
        process.executableURL = URL(fileURLWithPath: execPath)
        process.arguments = ["-d", target, "-b", "google,bing,duckduckgo", "-l", "100"]
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            return parseHarvesterOutput(output)
            
        } catch {
            return [createErrorFinding("theHarvester execution failed: \(error)", source: .theHarvester)]
        }
    }
    
    private func parseHarvesterOutput(_ output: String) -> [OSINTFinding] {
        var findings: [OSINTFinding] = []
        let lines = output.components(separatedBy: .newlines)
        
        var emails: [String] = []
        var hosts: [String] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Extract emails
            if isValidEmail(trimmedLine) {
                emails.append(trimmedLine)
            }
            
            // Extract hosts/subdomains
            if trimmedLine.contains(".") && !trimmedLine.contains("@") && !trimmedLine.contains(" ") {
                hosts.append(trimmedLine)
            }
        }
        
        if !emails.isEmpty {
            findings.append(OSINTFinding(
                source: .theHarvester,
                type: .emailAddresses,
                content: "Email Addresses: \(emails.joined(separator: ", "))",
                confidence: .medium,
                timestamp: Date(),
                metadata: ["emails": emails.joined(separator: ", ")]
            ))
        }
        
        if !hosts.isEmpty {
            findings.append(OSINTFinding(
                source: .theHarvester,
                type: .subdomains,
                content: "Discovered Hosts: \(hosts.joined(separator: ", "))",
                confidence: .medium,
                timestamp: Date(),
                metadata: ["hosts": hosts.joined(separator: ", ")]
            ))
        }
        
        return findings
    }
    
    // MARK: - DNS Reconnaissance
    
    private func performDNSRecon(_ target: String) async -> [OSINTFinding] {
        var findings: [OSINTFinding] = []
        
        // Perform different DNS record lookups
        let recordTypes = ["A", "AAAA", "MX", "NS", "TXT", "SOA"]
        
        for recordType in recordTypes {
            let records = await lookupDNSRecord(target, type: recordType)
            if !records.isEmpty {
                findings.append(OSINTFinding(
                    source: .dnsRecon,
                    type: .dnsRecords,
                    content: "\(recordType) Records: \(records.joined(separator: ", "))",
                    confidence: .high,
                    timestamp: Date(),
                    metadata: ["record_type": recordType, "records": records.joined(separator: ", ")]
                ))
            }
        }
        
        return findings
    }
    
    private func lookupDNSRecord(_ domain: String, type: String) async -> [String] {
        let process = Process()
        let pipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: "/usr/bin/dig")
        process.arguments = ["+short", domain, type]
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            return output.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            
        } catch {
            return []
        }
    }
    
    // MARK: - Subdomain Enumeration
    
    private func enumerateSubdomains(_ target: String) async -> [OSINTFinding] {
        guard ToolDetection.shared.isToolInstalled("subfinder") else {
            return [createErrorFinding("Subfinder not installed", source: .subdomainEnum)]
        }
        
        let process = Process()
        let pipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/subfinder")
        process.arguments = ["-d", target, "-silent"]
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            let subdomains = output.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            
            if !subdomains.isEmpty {
                return [OSINTFinding(
                    source: .subdomainEnum,
                    type: .subdomains,
                    content: "Subdomains (\(subdomains.count)): \(subdomains.prefix(10).joined(separator: ", "))",
                    confidence: .high,
                    timestamp: Date(),
                    metadata: ["subdomains": subdomains.joined(separator: ", "), "count": String(subdomains.count)]
                )]
            }
            
        } catch {
            return [createErrorFinding("Subfinder execution failed: \(error)", source: .subdomainEnum)]
        }
        
        return []
    }
    
    // MARK: - Google Dorking
    
    private func performGoogleDorking(_ target: String) async -> [OSINTFinding] {
        // Common Google dorks for information gathering
        let dorks = [
            "site:\(target) filetype:pdf",
            "site:\(target) inurl:admin",
            "site:\(target) inurl:login",
            "site:\(target) \"confidential\" OR \"internal\"",
            "site:\(target) filetype:doc OR filetype:docx",
            "site:\(target) inurl:backup OR inurl:old"
        ]
        
        var findings: [OSINTFinding] = []
        
        for dork in dorks {
            findings.append(OSINTFinding(
                source: .googleDorking,
                type: .searchResults,
                content: "Google Dork: \(dork)",
                confidence: .medium,
                timestamp: Date(),
                metadata: ["dork": dork, "url": "https://www.google.com/search?q=\(dork.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"]
            ))
        }
        
        return findings
    }
    
    // MARK: - Enhanced Social Media Search
    
    private func searchSocialMedia(_ target: String, searchType: OSINTSearchType) async -> [OSINTFinding] {
        var findings: [OSINTFinding] = []
        
        switch searchType {
        case .username:
            // Username-based social media search
            let platforms = ["Twitter", "Instagram", "TikTok", "Reddit", "YouTube"]
            for platform in platforms {
                let url = generateSocialMediaURL(platform: platform, username: target)
                findings.append(OSINTFinding(
                    source: .socialMedia,
                    type: .socialProfiles,
                    content: "Potential \(platform) profile: @\(target)",
                    confidence: .medium,
                    timestamp: Date(),
                    metadata: ["platform": platform, "username": target, "url": url]
                ))
            }
        case .email:
            // Email-based social media search (Gravatar, etc.)
            findings.append(OSINTFinding(
                source: .socialMedia,
                type: .socialProfiles,
                content: "Gravatar profile check for: \(target)",
                confidence: .medium,
                timestamp: Date(),
                metadata: ["email": target, "service": "Gravatar"]
            ))
        case .person:
            // Full name social media search
            findings.append(OSINTFinding(
                source: .socialMedia,
                type: .socialProfiles,
                content: "Social media profiles for: \(target)",
                confidence: .low,
                timestamp: Date(),
                metadata: ["full_name": target, "search_type": "person"]
            ))
        default:
            break
        }
        
        return findings
    }
    
    // MARK: - Sherlock Username Enumeration
    
    private func runSherlockSearch(_ username: String) async -> [OSINTFinding] {
        // Check if sherlock is installed
        let sherlockPaths = [
            "/usr/local/bin/sherlock",
            "/opt/homebrew/bin/sherlock",
            "/usr/bin/sherlock"
        ]
        
        var executablePath: String?
        for path in sherlockPaths {
            if FileManager.default.fileExists(atPath: path) {
                executablePath = path
                break
            }
        }
        
        // If sherlock isn't installed, provide manual search results
        guard let execPath = executablePath else {
            return generateManualUsernameSearch(username)
        }
        
        let process = Process()
        let pipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: execPath)
        process.arguments = ["--json", username]
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            return parseSherlockOutput(output, username: username)
            
        } catch {
            return [createErrorFinding("Sherlock execution failed: \(error)", source: .sherlock)]
        }
    }
    
    private func generateManualUsernameSearch(_ username: String) -> [OSINTFinding] {
        let platforms = [
            ("GitHub", "https://github.com/\(username)"),
            ("Twitter", "https://twitter.com/\(username)"),
            ("Instagram", "https://instagram.com/\(username)"),
            ("Reddit", "https://reddit.com/user/\(username)"),
            ("LinkedIn", "https://linkedin.com/in/\(username)"),
            ("YouTube", "https://youtube.com/@\(username)"),
            ("TikTok", "https://tiktok.com/@\(username)"),
            ("Telegram", "https://t.me/\(username)"),
            ("Discord", "Check Discord for username: \(username)"),
            ("Twitch", "https://twitch.tv/\(username)")
        ]
        
        return platforms.map { platform, url in
            OSINTFinding(
                source: .sherlock,
                type: .socialProfiles,
                content: "\(platform): \(username)",
                confidence: .medium,
                timestamp: Date(),
                metadata: ["platform": platform, "username": username, "url": url]
            )
        }
    }
    
    private func parseSherlockOutput(_ output: String, username: String) -> [OSINTFinding] {
        var findings: [OSINTFinding] = []
        
        // Parse sherlock JSON output
        if let data = output.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            
            for (platform, info) in json {
                if let platformInfo = info as? [String: Any],
                   let url = platformInfo["url_user"] as? String {
                    
                    findings.append(OSINTFinding(
                        source: .sherlock,
                        type: .socialProfiles,
                        content: "\(platform): @\(username) found",
                        confidence: .high,
                        timestamp: Date(),
                        metadata: ["platform": platform, "username": username, "url": url]
                    ))
                }
            }
        }
        
        return findings.isEmpty ? generateManualUsernameSearch(username) : findings
    }
    
    // MARK: - Pastebin Search
    
    private func searchPastebin(_ target: String) async -> [OSINTFinding] {
        // This would search pastebin and similar sites for leaked information
        // Implementation would depend on available APIs
        
        return [OSINTFinding(
            source: .pastebin,
            type: .leakedData,
            content: "Search Pastebin for: \(target)",
            confidence: .low,
            timestamp: Date(),
            metadata: ["search_term": target]
        )]
    }
    
    // MARK: - Breach Data Search
    
    private func searchBreachData(_ target: String) async -> [OSINTFinding] {
        // This would integrate with HaveIBeenPwned API or similar services
        // For demonstration purposes
        
        return [OSINTFinding(
            source: .breachData,
            type: .breaches,
            content: "Check breach databases for: \(target)",
            confidence: .medium,
            timestamp: Date(),
            metadata: ["search_term": target]
        )]
    }
    
    // MARK: - Censys Integration
    
    private func performCensysSearch(_ target: String) async -> [OSINTFinding] {
        guard let apiKey = apiKeys["censys"] else {
            return [createErrorFinding("Censys API key not configured", source: .censys)]
        }
        
        // Censys API integration would go here
        return [OSINTFinding(
            source: .censys,
            type: .networkInfo,
            content: "Censys search for: \(target)",
            confidence: .medium,
            timestamp: Date(),
            metadata: ["target": target]
        )]
    }
    
    // MARK: - Helper Methods
    
    private func createErrorFinding(_ message: String, source: OSINTSource) -> OSINTFinding {
        return OSINTFinding(
            source: source,
            type: .error,
            content: message,
            confidence: .low,
            timestamp: Date(),
            metadata: ["error": message]
        )
    }
    
    private func extractValue(from line: String) -> String {
        let components = line.components(separatedBy: ":")
        if components.count > 1 {
            return components[1].trimmingCharacters(in: .whitespaces)
        }
        return ""
    }
    
    private func isValidEmail(_ string: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: string)
    }
    
    private func loadAPIKeys() {
        // Load API keys from configuration file or environment
        // In a real implementation, these would be loaded securely
        
        if let plistPath = Bundle.main.path(forResource: "APIKeys", ofType: "plist"),
           let plistData = NSDictionary(contentsOfFile: plistPath) {
            
            apiKeys["shodan"] = plistData["SHODAN_API_KEY"] as? String
            apiKeys["censys"] = plistData["CENSYS_API_KEY"] as? String
            apiKeys["virustotal"] = plistData["VIRUSTOTAL_API_KEY"] as? String
        }
    }
    
    func setAPIKey(_ key: String, for service: String) {
        apiKeys[service] = key
    }
    
    func saveAPIKey(_ key: String, for service: String) {
        apiKeys[service] = key
        // In a real implementation, this would save to Keychain or secure storage
        UserDefaults.standard.set(key, forKey: "\(service)_api_key")
    }
    
    func clearFindings() {
        findings.removeAll()
    }
}

// MARK: - OSINT Models

enum OSINTSearchType: String, CaseIterable, Codable {
    case domain = "Domain/IP"
    case username = "Username"
    case email = "Email Address"
    case phone = "Phone Number"
    case person = "Full Name"
    case company = "Company/Organization"
    
    var icon: String {
        switch self {
        case .domain: return "globe"
        case .username: return "person.circle"
        case .email: return "envelope"
        case .phone: return "phone"
        case .person: return "person"
        case .company: return "building.2"
        }
    }
    
    var placeholder: String {
        switch self {
        case .domain: return "example.com or 192.168.1.1"
        case .username: return "username123"
        case .email: return "user@example.com"
        case .phone: return "+1-555-123-4567"
        case .person: return "John Doe"
        case .company: return "Acme Corporation"
        }
    }
}

enum OSINTSource: String, CaseIterable, Codable {
    case whois = "WHOIS Lookup"
    case shodan = "Shodan Search"
    case censys = "Censys Search"
    case theHarvester = "Email Harvesting"
    case socialMedia = "Social Media Intel"
    case sherlock = "Username Enumeration"
    case pastebin = "Pastebin Search"
    case dnsRecon = "DNS Reconnaissance"
    case subdomainEnum = "Subdomain Enumeration"
    case googleDorking = "Google Dorking"
    case breachData = "Breach Data Search"
    case phoneNumberLookup = "Phone Number Lookup"
    case haveibeenpwned = "Have I Been Pwned"
    case emailVerification = "Email Verification"
    case linkedinOSINT = "LinkedIn Intelligence"
    case githubOSINT = "GitHub Intelligence"
    
    var icon: String {
        switch self {
        case .whois: return "doc.text.magnifyingglass"
        case .shodan: return "network"
        case .censys: return "globe"
        case .theHarvester: return "envelope"
        case .socialMedia: return "person.3"
        case .sherlock: return "person.badge.magnifyingglass"
        case .pastebin: return "doc.plaintext"
        case .dnsRecon: return "server.rack"
        case .subdomainEnum: return "point.3.connected.trianglepath.dotted"
        case .googleDorking: return "magnifyingglass"
        case .breachData: return "lock.trianglebadge.exclamationmark"
        case .phoneNumberLookup: return "phone.badge.checkmark"
        case .haveibeenpwned: return "shield.lefthalf.filled.badge.checkmark"
        case .emailVerification: return "envelope.badge.checkmark"
        case .linkedinOSINT: return "person.crop.circle.badge.checkmark"
        case .githubOSINT: return "chevron.left.forwardslash.chevron.right"
        }
    }
    
    var description: String {
        switch self {
        case .whois: return "Domain registration information"
        case .shodan: return "Internet-connected device search"
        case .censys: return "Internet-wide scanning data"
        case .theHarvester: return "Email and subdomain discovery"
        case .socialMedia: return "Social media profile discovery"
        case .sherlock: return "Username across social platforms"
        case .pastebin: return "Leaked information search"
        case .dnsRecon: return "DNS record enumeration"
        case .subdomainEnum: return "Subdomain discovery"
        case .googleDorking: return "Advanced Google searches"
        case .breachData: return "Data breach information"
        case .phoneNumberLookup: return "Phone number intelligence"
        case .haveibeenpwned: return "Email breach checking"
        case .emailVerification: return "Email address validation"
        case .linkedinOSINT: return "LinkedIn profile intelligence"
        case .githubOSINT: return "GitHub profile and code search"
        }
    }
}

enum OSINTFindingType: String, CaseIterable, Codable {
    case domainInfo = "Domain Information"
    case networkInfo = "Network Information"
    case emailAddresses = "Email Addresses"
    case socialProfiles = "Social Profiles"
    case leakedData = "Leaked Data"
    case subdomains = "Subdomains"
    case dnsRecords = "DNS Records"
    case infrastructure = "Infrastructure"
    case organizationInfo = "Organization Information"
    case locationInfo = "Location Information"
    case searchResults = "Search Results"
    case breaches = "Data Breaches"
    case error = "Error"
    
    var icon: String {
        switch self {
        case .domainInfo: return "globe"
        case .networkInfo: return "network"
        case .emailAddresses: return "envelope"
        case .socialProfiles: return "person.circle"
        case .leakedData: return "exclamationmark.triangle"
        case .subdomains: return "point.3.connected.trianglepath.dotted"
        case .dnsRecords: return "server.rack"
        case .infrastructure: return "building.2"
        case .organizationInfo: return "building.columns"
        case .locationInfo: return "location"
        case .searchResults: return "magnifyingglass"
        case .breaches: return "lock.trianglebadge.exclamationmark"
        case .error: return "xmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .domainInfo: return .blue
        case .networkInfo: return .green
        case .emailAddresses: return .orange
        case .socialProfiles: return .purple
        case .leakedData: return .red
        case .subdomains: return .mint
        case .dnsRecords: return .cyan
        case .infrastructure: return .brown
        case .organizationInfo: return .indigo
        case .locationInfo: return .teal
        case .searchResults: return .yellow
        case .breaches: return .red
        case .error: return .gray
        }
    }
}

enum OSINTConfidence: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var color: Color {
        switch self {
        case .low: return .red
        case .medium: return .orange
        case .high: return .green
        }
    }
    
    var score: Double {
        switch self {
        case .low: return 0.3
        case .medium: return 0.6
        case .high: return 0.9
        }
    }
}

struct OSINTFinding: Identifiable, Codable {
    let id: UUID
    let source: OSINTSource
    let type: OSINTFindingType
    let content: String
    let confidence: OSINTConfidence
    let timestamp: Date
    let metadata: [String: String]
    
    enum CodingKeys: String, CodingKey {
        case id, source, type, content, confidence, timestamp, metadata
    }
    
    init(source: OSINTSource, type: OSINTFindingType, content: String, confidence: OSINTConfidence, timestamp: Date, metadata: [String: String] = [:]) {
        self.id = UUID()
        self.source = source
        self.type = type
        self.content = content
        self.confidence = confidence
        self.timestamp = timestamp
        self.metadata = metadata
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        source = try container.decode(OSINTSource.self, forKey: .source)
        type = try container.decode(OSINTFindingType.self, forKey: .type)
        content = try container.decode(String.self, forKey: .content)
        confidence = try container.decode(OSINTConfidence.self, forKey: .confidence)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        metadata = try container.decodeIfPresent([String: String].self, forKey: .metadata) ?? [:]
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(source, forKey: .source)
        try container.encode(type, forKey: .type)
        try container.encode(content, forKey: .content)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(metadata, forKey: .metadata)
    }
}

struct OSINTReport: Identifiable, Codable {
    let id: UUID
    let target: String
    let startTime: Date
    let sources: [OSINTSource]
    let findings: [OSINTFinding]
    let executionTime: TimeInterval
    
    init(target: String, startTime: Date, sources: [OSINTSource], findings: [OSINTFinding], executionTime: TimeInterval) {
        self.id = UUID()
        self.target = target
        self.startTime = startTime
        self.sources = sources
        self.findings = findings
        self.executionTime = executionTime
    }
    
    var endTime: Date {
        startTime.addingTimeInterval(executionTime)
    }
    
    var findingsByType: [OSINTFindingType: [OSINTFinding]] {
        Dictionary(grouping: findings) { $0.type }
    }
    
    var findingsBySource: [OSINTSource: [OSINTFinding]] {
        Dictionary(grouping: findings) { $0.source }
    }
    
    var riskScore: Double {
        let totalFindings = Double(findings.count)
        guard totalFindings > 0 else { return 0.0 }
        
        let weightedScore = findings.reduce(0.0) { total, finding in
            let typeWeight: Double
            switch finding.type {
            case .leakedData, .breaches: typeWeight = 1.0
            case .emailAddresses, .socialProfiles: typeWeight = 0.7
            case .networkInfo, .subdomains: typeWeight = 0.5
            case .domainInfo, .dnsRecords: typeWeight = 0.3
            default: typeWeight = 0.2
            }
            return total + (finding.confidence.score * typeWeight)
        }
        
        return min(weightedScore / totalFindings, 1.0)
    }
}