import Foundation

/// Domain entity representing an organization
struct Organization: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let description: String?
    let logo: URL?
    let type: OrganizationType
    let parentId: UUID?
    let settings: OrganizationSettings?
    let createdAt: Date
    let updatedAt: Date
}

enum OrganizationType: String, Codable, CaseIterable {
    case enterprise = "enterprise"
    case department = "department"
    case team = "team"
    case project = "project"

    var displayName: String {
        rawValue.capitalized
    }
}

struct OrganizationSettings: Codable, Equatable {
    let timezone: String?
    let locale: String?
    let features: [String: Bool]?
}
