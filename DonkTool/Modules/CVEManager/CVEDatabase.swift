//
//  CVEDatabase.swift
//  DonkTool
//
//  CVE database management and API integration
//

import Foundation
import Network

@Observable
class CVEDatabase {
    var cves: [CVEItem] = []
    var isLoading: Bool = false
    var lastUpdateTime: Date?
    var lastError: String?
    
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
            cve.description.localizedCaseInsensitiveContains(query)
        }
    }
    
    private func fetchRecentCVEs(daysBack: Int = 30) async throws -> [CVEItem] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -daysBack, to: endDate)!
        
        let dateFormatter = ISO8601DateFormatter()
        
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

enum CVEError: Error {
    case invalidURL
    case noData
    case decodingError
    case networkError
}
