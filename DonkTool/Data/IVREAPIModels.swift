//
//  IVREAPIModels.swift
//  DonkTool
//
//  API Response Models for IVRE Integration
//

import Foundation

// MARK: - API Response Models

struct IVREAPISearchResponse: Codable {
    let count: Int
    let hosts: [IVREAPIHost]
}

struct IVREAPIHost: Codable {
    let id: String
    let ip: String
    let hostname: String?
    let country: String?
    let firstSeen: String
    let lastSeen: String
    let ports: [IVREAPIPort]
    let services: [IVREAPIService]?
    let os: IVREAPIOs?
}

struct IVREAPIPort: Codable {
    let number: Int
    let protocolType: String
    let state: String
    let service: String?
    let version: String?
    let banner: String?
}

struct IVREAPIService: Codable {
    let name: String
    let port: Int
    let product: String?
    let serviceProtocol: String
    let version: String?
    
    enum CodingKeys: String, CodingKey {
        case name, port, product
        case serviceProtocol = "protocol"
        case version
    }
}

struct IVREAPIOs: Codable {
    let name: String
    let family: String
    let accuracy: Int
}

// MARK: - Free Reconnaissance Response Models

struct FreeReconResponse: Codable {
    let count: Int
    let hosts: [IVREHost]
    let query: String
    let sources_used: String
}

// MARK: - Conversion Extensions

extension IVREAPIHost {
    func toDomainModel() -> IVREHost {
        // Create date formatter for IVRE format
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        // Try different date formats
        let lastSeenDate = formatter.date(from: lastSeen) ?? 
                          ISO8601DateFormatter().date(from: lastSeen) ?? 
                          Date()
        let firstSeenDate = formatter.date(from: firstSeen) ?? 
                           ISO8601DateFormatter().date(from: firstSeen) ?? 
                           Date()
        
        return IVREHost(
            id: id,
            ip: ip,
            hostname: hostname,
            ports: ports.map { $0.toDomainModel() },
            geolocation: nil, // Would need geocoding
            certificates: [],
            lastSeen: lastSeenDate,
            firstSeen: firstSeenDate,
            asNumber: nil,
            country: country
        )
    }
}

extension IVREAPIPort {
    func toDomainModel() -> IVREPort {
        return IVREPort(
            number: number,
            portProtocol: protocolType,
            state: state,
            service: service,
            product: nil,
            version: version,
            banner: banner,
            cpe: [],
            vulnerabilities: []
        )
    }
}