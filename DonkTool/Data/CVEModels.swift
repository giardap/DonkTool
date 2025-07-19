//
//  CVEModels.swift
//  DonkTool
//
//  CVE-specific data models
//

import Foundation

// MARK: - CVE API Response Models
struct CVEResponse: Codable {
    let resultsPerPage: Int
    let startIndex: Int
    let totalResults: Int
    let format: String
    let version: String
    let timestamp: String
    let vulnerabilities: [CVEVulnerability]
}

struct CVEVulnerability: Codable {
    let cve: CVEData
}

struct CVEData: Codable {
    let id: String
    let sourceIdentifier: String?
    let published: String
    let lastModified: String
    let vulnStatus: String?
    let descriptions: [CVEDescription]
    let metrics: CVEMetrics?
    let weaknesses: [CVEWeakness]?
    let configurations: CVEConfigurations?
    let references: [CVEReference]
    
    enum CodingKeys: String, CodingKey {
        case id, sourceIdentifier, published, lastModified, vulnStatus
        case descriptions, metrics, weaknesses, configurations, references
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        sourceIdentifier = try container.decodeIfPresent(String.self, forKey: .sourceIdentifier)
        published = try container.decode(String.self, forKey: .published)
        lastModified = try container.decode(String.self, forKey: .lastModified)
        vulnStatus = try container.decodeIfPresent(String.self, forKey: .vulnStatus)
        descriptions = try container.decode([CVEDescription].self, forKey: .descriptions)
        metrics = try container.decodeIfPresent(CVEMetrics.self, forKey: .metrics)
        weaknesses = try container.decodeIfPresent([CVEWeakness].self, forKey: .weaknesses)
        references = try container.decode([CVEReference].self, forKey: .references)
        
        // Handle configurations field that can be either object or array
        do {
            configurations = try container.decodeIfPresent(CVEConfigurations.self, forKey: .configurations)
        } catch {
            // If decoding fails (e.g., because it's an array), set to nil
            configurations = nil
        }
    }
}

struct CVEDescription: Codable {
    let lang: String
    let value: String
}

struct CVEMetrics: Codable {
    let cvssMetricV31: [CVSSMetric]?
    let cvssMetricV30: [CVSSMetric]?
    let cvssMetricV2: [CVSSMetric]?
}

struct CVSSMetric: Codable {
    let source: String
    let type: String
    let cvssData: CVSSData
    let baseSeverity: String?
    let exploitabilityScore: Double?
    let impactScore: Double?
}

struct CVSSData: Codable {
    let version: String
    let vectorString: String
    let baseScore: Double
    let baseSeverity: String?
}

struct CVEWeakness: Codable {
    let source: String
    let type: String
    let description: [CVEDescription]
}

struct CVEConfigurations: Codable {
    let nodes: [CVENode]?
}

struct CVENode: Codable {
    let operatorType: String?
    let negate: Bool?
    let cpeMatch: [CPEMatch]?
    
    enum CodingKeys: String, CodingKey {
        case operatorType = "operator"
        case negate, cpeMatch
    }
}

struct CPEMatch: Codable {
    let vulnerable: Bool
    let criteria: String
    let versionStartIncluding: String?
    let versionEndExcluding: String?
    let matchCriteriaId: String
}

struct CVEReference: Codable {
    let url: String
    let source: String?
    let tags: [String]?
}

// MARK: - Internal CVE Item Model
struct CVEItem: Identifiable, Codable, Hashable {
    let id: String
    let description: String
    let publishedDate: Date
    let lastModifiedDate: Date
    let baseScore: Double?
    let baseSeverity: String?
    let vectorString: String?
    let references: [String]
    
    init(from vulnerability: CVEVulnerability) {
        let cve = vulnerability.cve
        self.id = cve.id
        
        // Get English description
        self.description = cve.descriptions.first { $0.lang == "en" }?.value ?? 
                          cve.descriptions.first?.value ?? "No description available"
        
        // Parse dates
        let dateFormatter = ISO8601DateFormatter()
        self.publishedDate = dateFormatter.date(from: cve.published) ?? Date()
        self.lastModifiedDate = dateFormatter.date(from: cve.lastModified) ?? Date()
        
        // Extract CVSS metrics (prefer v3.1, then v3.0, then v2)
        if let metrics = cve.metrics {
            if let cvssV31 = metrics.cvssMetricV31?.first {
                self.baseScore = cvssV31.cvssData.baseScore
                self.baseSeverity = cvssV31.baseSeverity ?? cvssV31.cvssData.baseSeverity
                self.vectorString = cvssV31.cvssData.vectorString
            } else if let cvssV30 = metrics.cvssMetricV30?.first {
                self.baseScore = cvssV30.cvssData.baseScore
                self.baseSeverity = cvssV30.baseSeverity ?? cvssV30.cvssData.baseSeverity
                self.vectorString = cvssV30.cvssData.vectorString
            } else if let cvssV2 = metrics.cvssMetricV2?.first {
                self.baseScore = cvssV2.cvssData.baseScore
                self.baseSeverity = cvssV2.baseSeverity ?? cvssV2.cvssData.baseSeverity
                self.vectorString = cvssV2.cvssData.vectorString
            } else {
                self.baseScore = nil
                self.baseSeverity = nil
                self.vectorString = nil
            }
        } else {
            self.baseScore = nil
            self.baseSeverity = nil
            self.vectorString = nil
        }
        
        // Extract reference URLs
        self.references = cve.references.map { $0.url }
    }
    
    var severity: Vulnerability.Severity {
        guard let baseSeverity = baseSeverity?.lowercased() else { return .low }
        
        switch baseSeverity {
        case "critical": return .critical
        case "high": return .high
        case "medium": return .medium
        case "low": return .low
        default: return .low
        }
    }
}