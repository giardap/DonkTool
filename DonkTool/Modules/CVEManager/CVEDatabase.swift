//
//  CVEDatabase.swift
//  DonkTool
//
//  CVE database management and API integration
//

import Foundation
import Network

@MainActor
class CVEDatabase: ObservableObject {
    @Published var cves: [CVEItem] = []
    @Published var isLoading: Bool = false
    @Published var lastUpdateTime: Date?
    @Published var lastError: String?
    
    private let baseURL = "https://services.nvd.nist.gov/rest/json/cves/2.0"
    private let session = URLSession.shared
    
    var count: Int {
        cves.count
    }
    
    func updateDatabase() async {
        await MainActor.run {
            isLoading = true
            lastError = nil
        }
        
        do {
            let recentCVEs = try await fetchRecentCVEs()
            await MainActor.run {
                cves = recentCVEs
                lastUpdateTime = Date()
                isLoading = false
                lastError = nil
            }
        } catch {
            let errorMessage = handleNetworkError(error)
            await MainActor.run {
                isLoading = false
                lastError = errorMessage
            }
            print("Failed to update CVE database: \(error)")
        }
    }
    
    private func handleNetworkError(_ error: Error) -> String {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return "No internet connection available"
            case .timedOut:
                return "Request timed out"
            case .cannotFindHost:
                return "Cannot reach NVD servers"
            case .networkConnectionLost:
                return "Network connection lost"
            default:
                return "Network error: \(urlError.localizedDescription)"
            }
        }
        return "Error: \(error.localizedDescription)"
    }
    
    func searchCVEs(query: String) -> [CVEItem] {
        guard !query.isEmpty else { return cves }
        
        return cves.filter { cve in
            cve.id.localizedCaseInsensitiveContains(query) ||
            cve.description.localizedCaseInsensitiveContains(query) ||
            cve.vendor?.localizedCaseInsensitiveContains(query) == true
        }
    }
    
    private func fetchRecentCVEs(daysBack: Int = 30) async throws -> [CVEItem] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -daysBack, to: endDate)!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "pubStartDate", value: dateFormatter.string(from: startDate)),
            URLQueryItem(name: "pubEndDate", value: dateFormatter.string(from: endDate)),
            URLQueryItem(name: "resultsPerPage", value: "100")
        ]
        
        guard let url = components?.url else {
            throw CVEError.invalidURL
        }
        
        let (data, _) = try await session.data(from: url)
        
        let decoder = JSONDecoder()
        let cveResponse = try decoder.decode(CVEResponse.self, from: data)
        
        return cveResponse.vulnerabilities.map { vulnerability in
            CVEItem(from: vulnerability)
        }
    }
}

struct CVEItem: Identifiable, Codable {
    let id: String
    let description: String
    let publishedDate: Date
    let lastModifiedDate: Date
    let cvssScore: Double?
    let severity: String?
    let vendor: String?
    let product: String?
    let references: [String]
    
    init(from vulnerability: CVEVulnerability) {
        self.id = vulnerability.cve.id
        
        // Extract description (usually in English)
        self.description = vulnerability.cve.descriptions.first { $0.lang == "en" }?.value ?? "No description available"
        
        // Parse dates - API uses ISO 8601 format without milliseconds
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        self.publishedDate = formatter.date(from: vulnerability.cve.published) ?? {
            // Try without milliseconds if first format fails
            let altFormatter = DateFormatter()
            altFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            return altFormatter.date(from: vulnerability.cve.published) ?? Date()
        }()
        self.lastModifiedDate = formatter.date(from: vulnerability.cve.lastModified) ?? {
            let altFormatter = DateFormatter()
            altFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            return altFormatter.date(from: vulnerability.cve.lastModified) ?? Date()
        }()
        
        // Extract CVSS score if available
        if let metrics = vulnerability.cve.metrics?.cvssMetricV3?.first {
            self.cvssScore = metrics.cvssData.baseScore
            self.severity = metrics.cvssData.baseSeverity
        } else if let metricsV2 = vulnerability.cve.metrics?.cvssMetricV2?.first {
            self.cvssScore = metricsV2.cvssData.baseScore
            self.severity = metricsV2.baseSeverity
        } else {
            self.cvssScore = nil
            self.severity = nil
        }
        
        // Extract vendor/product info
        if let cpe = vulnerability.cve.configurations?.nodes.first?.cpeMatch.first {
            let parts = cpe.criteria.split(separator: ":")
            self.vendor = parts.count > 3 ? String(parts[3]) : nil
            self.product = parts.count > 4 ? String(parts[4]) : nil
        } else {
            self.vendor = nil
            self.product = nil
        }
        
        // Extract references
        self.references = vulnerability.cve.references.map { $0.url }
    }
}

enum CVEError: Error {
    case invalidURL
    case noData
    case decodingError
}

// MARK: - API Response Models
struct CVEResponse: Codable {
    let vulnerabilities: [CVEVulnerability]
}

struct CVEVulnerability: Codable {
    let cve: CVEDetail
}

struct CVEDetail: Codable {
    let id: String
    let published: String
    let lastModified: String
    let descriptions: [CVEDescription]
    let references: [CVEReference]
    let metrics: CVEMetrics?
    let configurations: CVEConfigurations?
    
    enum CodingKeys: String, CodingKey {
        case id, published, lastModified, descriptions, references, metrics, configurations
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        published = try container.decode(String.self, forKey: .published)
        lastModified = try container.decode(String.self, forKey: .lastModified)
        descriptions = try container.decode([CVEDescription].self, forKey: .descriptions)
        references = try container.decode([CVEReference].self, forKey: .references)
        metrics = try container.decodeIfPresent(CVEMetrics.self, forKey: .metrics)
        
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

struct CVEReference: Codable {
    let url: String
}

struct CVEMetrics: Codable {
    let cvssMetricV3: [CVSSMetricV3]?
    let cvssMetricV2: [CVSSMetricV2]?
}

struct CVSSMetricV3: Codable {
    let cvssData: CVSSDataV3
}

struct CVSSMetricV2: Codable {
    let cvssData: CVSSDataV2
    let baseSeverity: String
}

struct CVSSDataV3: Codable {
    let baseScore: Double
    let baseSeverity: String
}

struct CVSSDataV2: Codable {
    let baseScore: Double
}

struct CVEConfigurations: Codable {
    let nodes: [CVENode]
}

struct CVENode: Codable {
    let cpeMatch: [CPEMatch]
}

struct CPEMatch: Codable {
    let criteria: String
}
