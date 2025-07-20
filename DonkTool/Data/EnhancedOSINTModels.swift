//
//  EnhancedOSINTModels.swift
//  DonkTool
//
//  Comprehensive OSINT intelligence gathering models
//

import Foundation
import SwiftUI

// MARK: - Multi-Input Search Models

struct OSINTSearchRequest: Codable {
    let primaryTarget: String
    let searchType: OSINTSearchType
    let additionalInputs: [String: String] // Key-value pairs like "location": "California", "email": "test@domain.com"
    let sources: [OSINTSource]
    let crossReference: Bool
    let deepSearch: Bool
    
    init(primaryTarget: String, searchType: OSINTSearchType, sources: [OSINTSource], additionalInputs: [String: String] = [:], crossReference: Bool = true, deepSearch: Bool = false) {
        self.primaryTarget = primaryTarget
        self.searchType = searchType
        self.additionalInputs = additionalInputs
        self.sources = sources
        self.crossReference = crossReference
        self.deepSearch = deepSearch
    }
}

// MARK: - Comprehensive Profile Models

struct OSINTProfile: Identifiable, Codable {
    let id = UUID()
    let primaryIdentifier: String
    let profileType: ProfileType
    var confidence: Double // 0.0 to 1.0
    var lastUpdated: Date
    
    // Personal Information
    var personalInfo: PersonalInformation?
    var contactInfo: ContactInformation?
    var locationInfo: LocationInformation?
    var socialProfiles: [SocialMediaProfile]
    var professionalInfo: ProfessionalInformation?
    var digitalFootprint: DigitalFootprint?
    var relatives: [RelativeInformation]
    var associates: [AssociateInformation]
    
    // Data Sources and Correlation
    var dataSources: [DataSource]
    var correlatedFindings: [CorrelatedFinding]
    var riskAssessment: RiskAssessment
    
    enum ProfileType: String, CaseIterable, Codable {
        case individual = "Individual"
        case business = "Business"
        case unknown = "Unknown"
    }
}

struct PersonalInformation: Codable {
    var fullName: String?
    var firstName: String?
    var middleName: String?
    var lastName: String?
    var aliases: [String]
    var dateOfBirth: String?
    var age: Int?
    var gender: String?
    var maritalStatus: String?
    var education: [EducationRecord]
}

struct ContactInformation: Codable {
    var phoneNumbers: [PhoneRecord]
    var emailAddresses: [EmailRecord]
    var physicalAddresses: [AddressRecord]
    var onlineHandles: [String]
}

struct LocationInformation: Codable {
    var currentLocation: LocationRecord?
    var previousLocations: [LocationRecord]
    var frequentLocations: [LocationRecord]
    var geolocationData: [GeolocationPoint]
}

struct SocialMediaProfile: Identifiable, Codable {
    let id = UUID()
    let platform: String
    let username: String
    let profileURL: String
    let isVerified: Bool
    let followers: Int?
    let following: Int?
    let posts: Int?
    let bio: String?
    let profileImage: String?
    let joinDate: String?
    let lastActivity: String?
    let connections: [String]
    let interests: [String]
}

struct ProfessionalInformation: Codable {
    var currentEmployer: String?
    var jobTitle: String?
    var industry: String?
    var workLocation: String?
    var salary: String?
    var previousEmployers: [EmploymentRecord]
    var skills: [String]
    var certifications: [String]
    var linkedinProfile: String?
}

struct DigitalFootprint: Codable {
    var websites: [WebsiteRecord]
    var domainOwnership: [DomainRecord]
    var onlineAccounts: [OnlineAccount]
    var digitalAssets: [DigitalAsset]
    var breachExposures: [BreachExposure]
    var darkWebMentions: [DarkWebMention]
}

// MARK: - Supporting Data Structures

struct PhoneRecord: Identifiable, Codable {
    let id = UUID()
    let number: String
    let type: PhoneType
    let carrier: String?
    let location: String?
    let isActive: Bool
    let confidence: Double
    
    enum PhoneType: String, Codable {
        case mobile = "Mobile"
        case landline = "Landline"
        case voip = "VoIP"
        case unknown = "Unknown"
    }
}

struct EmailRecord: Identifiable, Codable {
    let id = UUID()
    let address: String
    let isValid: Bool
    let domain: String
    let breachCount: Int
    let lastSeen: Date?
    let confidence: Double
}

struct AddressRecord: Identifiable, Codable {
    let id = UUID()
    let fullAddress: String
    let street: String?
    let city: String?
    let state: String?
    let zipCode: String?
    let country: String?
    let addressType: AddressType
    let residencyPeriod: String?
    let confidence: Double
    
    enum AddressType: String, Codable {
        case current = "Current"
        case previous = "Previous"
        case business = "Business"
        case family = "Family"
        case unknown = "Unknown"
    }
}

struct LocationRecord: Identifiable, Codable {
    let id = UUID()
    let city: String
    let state: String?
    let country: String
    let coordinateEstimate: String?
    let timeframe: String?
    let confidence: Double
}

struct GeolocationPoint: Identifiable, Codable {
    let id = UUID()
    let latitude: Double?
    let longitude: Double?
    let accuracy: Double?
    let timestamp: Date
    let source: String
}

struct EducationRecord: Identifiable, Codable {
    let id = UUID()
    let institution: String
    let degree: String?
    let fieldOfStudy: String?
    let graduationYear: String?
    let location: String?
}

struct EmploymentRecord: Identifiable, Codable {
    let id = UUID()
    let company: String
    let position: String?
    let startDate: String?
    let endDate: String?
    let location: String?
    let industry: String?
}

struct RelativeInformation: Identifiable, Codable {
    let id = UUID()
    let name: String
    let relationship: String
    let age: Int?
    let location: String?
    let confidence: Double
}

struct AssociateInformation: Identifiable, Codable {
    let id = UUID()
    let name: String
    let associationType: String // "Colleague", "Friend", "Neighbor", etc.
    let context: String?
    let confidence: Double
}

struct WebsiteRecord: Identifiable, Codable {
    let id = UUID()
    let url: String
    let title: String?
    let description: String?
    let lastUpdated: Date?
    let isActive: Bool
}

struct DomainRecord: Identifiable, Codable {
    let id = UUID()
    let domain: String
    let registrationDate: Date?
    let expirationDate: Date?
    let registrar: String?
    let nameServers: [String]
}

struct OnlineAccount: Identifiable, Codable {
    let id = UUID()
    let platform: String
    let username: String
    let profileURL: String
    let isVerified: Bool
    let lastActivity: Date?
}

struct DigitalAsset: Identifiable, Codable {
    let id = UUID()
    let assetType: String
    let identifier: String
    let value: String?
    let blockchain: String?
}

struct BreachExposure: Identifiable, Codable {
    let id = UUID()
    let breachName: String
    let breachDate: Date
    let exposedData: [String]
    let severity: String
}

struct DarkWebMention: Identifiable, Codable {
    let id = UUID()
    let content: String
    let source: String
    let timestamp: Date
    let context: String
}

// MARK: - Data Correlation Models

struct CorrelatedFinding: Identifiable, Codable {
    let id = UUID()
    let primarySource: OSINTSource
    let correlatedSources: [OSINTSource]
    let correlationType: CorrelationType
    let confidence: Double
    let description: String
    let supportingData: [String: String]
    
    enum CorrelationType: String, Codable {
        case nameMatch = "Name Match"
        case locationMatch = "Location Match"
        case contactMatch = "Contact Match"
        case associateMatch = "Associate Match"
        case temporalCorrelation = "Temporal Correlation"
        case patternMatch = "Pattern Match"
    }
}

struct DataSource: Identifiable, Codable {
    let id = UUID()
    let source: OSINTSource
    let dataPoints: Int
    let reliability: Double
    let lastAccessed: Date
    let accessMethod: String
}

struct RiskAssessment: Codable {
    let overallRisk: RiskLevel
    let privacyRisk: RiskLevel
    let exposureLevel: RiskLevel
    let breachRisk: RiskLevel
    let socialEngineeringRisk: RiskLevel
    let recommendations: [String]
    
    enum RiskLevel: String, CaseIterable, Codable {
        case minimal = "Minimal"
        case low = "Low"
        case moderate = "Moderate"
        case high = "High"
        case critical = "Critical"
        
        var color: Color {
            switch self {
            case .minimal: return .green
            case .low: return .mint
            case .moderate: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }
    }
}

// MARK: - Search Configuration Models

struct OSINTSearchConfiguration: Codable {
    let enablePeopleSearch: Bool
    let enableSocialMedia: Bool
    let enablePublicRecords: Bool
    let enableBusinessRecords: Bool
    let enableDarkWebSearch: Bool
    let enableCrossReferencing: Bool
    let maxSearchDepth: Int
    let timeoutSeconds: Int
    let apiKeys: [String: String]
    
    static let `default` = OSINTSearchConfiguration(
        enablePeopleSearch: true,
        enableSocialMedia: true,
        enablePublicRecords: true,
        enableBusinessRecords: true,
        enableDarkWebSearch: false,
        enableCrossReferencing: true,
        maxSearchDepth: 3,
        timeoutSeconds: 300,
        apiKeys: [:]
    )
}

// MARK: - Enhanced Finding Types

enum EnhancedFindingType: String, CaseIterable, Codable {
    case personalIdentity = "Personal Identity"
    case contactInformation = "Contact Information"
    case locationData = "Location Data"
    case socialMediaProfile = "Social Media Profile"
    case professionalInfo = "Professional Information"
    case educationRecord = "Education Record"
    case familyConnection = "Family Connection"
    case businessAssociation = "Business Association"
    case digitalAsset = "Digital Asset"
    case securityBreach = "Security Breach"
    case publicRecord = "Public Record"
    case financialInformation = "Financial Information"
    case criminalRecord = "Criminal Record"
    case propertyRecord = "Property Record"
    case vehicleRecord = "Vehicle Record"
    case courtRecord = "Court Record"
    case bankruptcyRecord = "Bankruptcy Record"
    case licenseRecord = "License Record"
    case voterRecord = "Voter Record"
    case marketingProfile = "Marketing Profile"
    case databrokerListing = "Data Broker Listing"
    
    var icon: String {
        switch self {
        case .personalIdentity: return "person.circle"
        case .contactInformation: return "phone.circle"
        case .locationData: return "location.circle"
        case .socialMediaProfile: return "person.2.circle"
        case .professionalInfo: return "briefcase.circle"
        case .educationRecord: return "graduationcap.circle"
        case .familyConnection: return "person.3.circle"
        case .businessAssociation: return "building.2.circle"
        case .digitalAsset: return "bitcoinsign.circle"
        case .securityBreach: return "shield.circle"
        case .publicRecord: return "doc.circle"
        case .financialInformation: return "dollarsign.circle"
        case .criminalRecord: return "exclamationmark.triangle.circle"
        case .propertyRecord: return "house.circle"
        case .vehicleRecord: return "car.circle"
        case .courtRecord: return "scale.3d"
        case .bankruptcyRecord: return "creditcard.circle"
        case .licenseRecord: return "checkmark.circle"
        case .voterRecord: return "checkmark.ballot"
        case .marketingProfile: return "chart.bar.circle"
        case .databrokerListing: return "server.rack"
        }
    }
    
    var color: Color {
        switch self {
        case .personalIdentity: return .blue
        case .contactInformation: return .green
        case .locationData: return .purple
        case .socialMediaProfile: return .orange
        case .professionalInfo: return .indigo
        case .educationRecord: return .mint
        case .familyConnection: return .pink
        case .businessAssociation: return .teal
        case .digitalAsset: return .yellow
        case .securityBreach: return .red
        case .publicRecord: return .gray
        case .financialInformation: return .green
        case .criminalRecord: return .red
        case .propertyRecord: return .brown
        case .vehicleRecord: return .blue
        case .courtRecord: return .purple
        case .bankruptcyRecord: return .orange
        case .licenseRecord: return .mint
        case .voterRecord: return .indigo
        case .marketingProfile: return .pink
        case .databrokerListing: return .gray
        }
    }
}