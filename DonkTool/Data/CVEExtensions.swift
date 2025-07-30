//
//  CVEExtensions.swift
//  DonkTool
//
//  Extensions for CVE models to support the modern UI
//

import Foundation
import SwiftUI

// MARK: - CVEItem Extensions
extension CVEItem {
    // Note: severity property is already defined in CVEModels.swift
    
    var cvssScore: Double? {
        return baseScore
    }
    
    var affectedProducts: [String] {
        // Extract affected products from configurations if available
        // For now, return empty array
        return []
    }
}

// MARK: - CVEDatabase Extensions
extension CVEDatabase {
    var items: [CVEItem] {
        return cves
    }
    
    // Note: count is already defined in CVEDatabase.swift
}