//
//  DonkToolTests.swift
//  DonkToolTests
//
//  Unit tests for DonkTool
//

import XCTest
@testable import DonkTool

final class DonkToolTests: XCTestCase {
    
    func testTargetCreation() {
        let target = Target(name: "Test Target", ipAddress: "192.168.1.1")
        
        XCTAssertEqual(target.name, "Test Target")
        XCTAssertEqual(target.ipAddress, "192.168.1.1")
        XCTAssertEqual(target.status, .pending)
        XCTAssertTrue(target.vulnerabilities.isEmpty)
    }
    
    func testVulnerabilityCreation() {
        let vulnerability = Vulnerability(
            cveId: "CVE-2024-0001",
            title: "Test Vulnerability",
            description: "A test vulnerability",
            severity: .high,
            discoveredAt: Date()
        )
        
        XCTAssertEqual(vulnerability.cveId, "CVE-2024-0001")
        XCTAssertEqual(vulnerability.title, "Test Vulnerability")
        XCTAssertEqual(vulnerability.severity, .high)
    }
    
    func testAppStateInitialization() {
        let appState = AppState()
        
        XCTAssertEqual(appState.currentTab, .dashboard)
        XCTAssertFalse(appState.isScanning)
        XCTAssertTrue(appState.targets.isEmpty)
        XCTAssertTrue(appState.lastScanResults.isEmpty)
    }
    
    func testTargetManagement() {
        let appState = AppState()
        let target = Target(name: "Test Target", ipAddress: "192.168.1.1")
        
        appState.addTarget(target)
        XCTAssertEqual(appState.targets.count, 1)
        XCTAssertEqual(appState.targets.first?.name, "Test Target")
        
        appState.removeTarget(target)
        XCTAssertTrue(appState.targets.isEmpty)
    }
    
    func testScanResultCreation() {
        let targetId = UUID()
        let scanResult = ScanResult(targetId: targetId, scanType: .portScan)
        
        XCTAssertEqual(scanResult.targetId, targetId)
        XCTAssertEqual(scanResult.scanType, .portScan)
        XCTAssertEqual(scanResult.status, .running)
        XCTAssertNotNil(scanResult.startTime)
    }
    
    func testCVEItemInitialization() {
        // Test basic CVE item functionality
        // Note: This would need to be expanded with actual CVE API response data
        // For now, just test that the CVE database can be initialized
        let cveDatabase = CVEDatabase()
        XCTAssertEqual(cveDatabase.count, 0)
        XCTAssertTrue(cveDatabase.cves.isEmpty)
    }
    
    func testWebTestEnumeration() {
        let allTests = WebTest.allCases
        
        XCTAssertTrue(allTests.contains(.sqlInjection))
        XCTAssertTrue(allTests.contains(.xss))
        XCTAssertTrue(allTests.contains(.csrf))
        
        // Test that each test has required properties
        for test in allTests {
            XCTAssertFalse(test.displayName.isEmpty)
            XCTAssertFalse(test.description.isEmpty)
            XCTAssertFalse(test.recommendations.isEmpty)
        }
    }
    
    func testSeverityColors() {
        XCTAssertEqual(Vulnerability.Severity.critical.color, "red")
        XCTAssertEqual(Vulnerability.Severity.high.color, "orange")
        XCTAssertEqual(Vulnerability.Severity.medium.color, "yellow")
        XCTAssertEqual(Vulnerability.Severity.low.color, "blue")
        XCTAssertEqual(Vulnerability.Severity.info.color, "gray")
    }
    
    func testReportTypeProperties() {
        let reportTypes = ReportType.allCases
        
        for type in reportTypes {
            XCTAssertFalse(type.displayName.isEmpty)
            XCTAssertFalse(type.description.isEmpty)
        }
    }
    
    // Performance tests
    func testCVESearchPerformance() {
        let cveDatabase = CVEDatabase()
        
        // Add some test CVE items
        let testCVEs = (1...1000).map { index in
            CVEItem(
                id: "CVE-2024-\(String(format: "%04d", index))",
                description: "Test CVE description \(index)",
                publishedDate: Date(),
                lastModifiedDate: Date(),
                cvssScore: Double.random(in: 0...10),
                severity: ["Low", "Medium", "High", "Critical"].randomElement(),
                vendor: "TestVendor\(index % 10)",
                product: "TestProduct\(index % 5)",
                references: []
            )
        }
        
        // This would need to be updated when CVEItem initializer is implemented
        // For now, just test that search doesn't crash
        measure {
            let results = cveDatabase.searchCVEs(query: "test")
            _ = results.count
        }
    }
}

// Helper extension for creating test CVE items
extension CVEItem {
    init(id: String, description: String, publishedDate: Date, lastModifiedDate: Date, cvssScore: Double?, severity: String?, vendor: String?, product: String?, references: [String]) {
        self.id = id
        self.description = description
        self.publishedDate = publishedDate
        self.lastModifiedDate = lastModifiedDate
        self.cvssScore = cvssScore
        self.severity = severity
        self.vendor = vendor
        self.product = product
        self.references = references
    }
}
