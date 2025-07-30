//
//  NetworkModels.swift
//  DonkTool
//
//  Network-specific data models for the modern UI
//

import Foundation

// Extended Target model for network scanning
extension Target {
    var hostname: String? {
        return domain
    }
    
    var openPorts: [Port] {
        // Convert vulnerabilities to ports for now
        let ports = vulnerabilities.compactMap { vuln -> Port? in
            guard let portNum = vuln.port else { return nil }
            return Port(number: portNum, service: vuln.service, state: .open)
        }
        return ports.isEmpty ? [Port(number: 80, service: "http", state: .open)] : ports
    }
}

struct Port: Identifiable, Hashable {
    let id = UUID()
    let number: Int
    let service: String?
    let state: PortState
    
    enum PortState: String {
        case open
        case closed
        case filtered
    }
}

// Network scan methods for AppState
// Add discoveredDate property to Vulnerability
extension Vulnerability {
    var discoveredDate: Date {
        return discoveredAt
    }
    
    var isPatched: Bool {
        // Mock implementation - in real app this would check actual patch status
        return false
    }
}

// Duplicate performNetworkScan implementation removed - using real implementation in AppState.swift