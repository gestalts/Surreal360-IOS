import Foundation

/// Data Transfer Object for User API responses
/// Maps to Django UserProfileSerializer output
struct UserDTO: Codable {
    // Core identity fields
    let id: String
    let email: String
    let firstName: String?
    let lastName: String?
    let name: String?

    // Avatar - backend returns avatarUrl
    let avatarUrl: String?

    // Role and status
    let role: String?
    let rolePriority: Int?
    let status: String

    // Organization - backend returns as object with id and name
    let organization: OrganizationRefDTO?

    // Profile fields
    let phoneNumber: String?
    let company: String?
    let bio: String?
    let school: String?
    let quote: String?

    // Location fields
    let city: String?
    let state: String?
    let country: String?
    let address: String?
    let zipCode: String?

    // Verification and permissions
    let isVerified: Bool?
    let hasAdminAccess: Bool?
    let isSuperuser: Bool?
    let groups: [String]?

    // Social stats
    let totalFollowers: Int?
    let totalFollowing: Int?

    // Enhanced contact list computed fields
    let engagementScore: Int?
    let recentInteractions: Int?
    let tags: [String]?
    let lastActivity: String?

    // Communication stats
    let emailCount: Int?
    let meetingCount: Int?
    let callCount: Int?

    // Account stats
    let projectCount: Int?
    let taskCount: Int?
    let unreadMessageCount: Int?
    let alertCount: Int?

    // Timestamps
    let createdAt: String?
    let updatedAt: String?

    // V3 Permission system
    let roleAssignments: [RoleAssignmentDTO]?

    // Coding keys to handle both snake_case and camelCase from backend
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case firstName = "firstName"
        case lastName = "lastName"
        case name
        case avatarUrl = "avatarUrl"
        case role
        case rolePriority = "rolePriority"
        case status
        case organization
        case phoneNumber = "phoneNumber"
        case company
        case bio
        case school
        case quote
        case city
        case state
        case country
        case address
        case zipCode = "zipCode"
        case isVerified = "isVerified"
        case hasAdminAccess = "hasAdminAccess"
        case isSuperuser = "isSuperuser"
        case groups
        case totalFollowers = "total_followers"
        case totalFollowing = "total_following"
        case engagementScore = "engagement_score"
        case recentInteractions = "recent_interactions"
        case tags
        case lastActivity = "lastActivity"
        case emailCount = "email_count"
        case meetingCount = "meeting_count"
        case callCount = "call_count"
        case projectCount = "project_count"
        case taskCount = "task_count"
        case unreadMessageCount = "unread_message_count"
        case alertCount = "alert_count"
        case createdAt = "createdAt"
        case updatedAt = "updatedAt"
        case roleAssignments = "roleAssignments"
    }

    // MARK: - Mapping to Domain Entity

    func toDomain() throws -> User {
        guard let uuid = UUID(uuidString: id) else {
            throw DTOError.invalidUUID(id)
        }

        // Parse dates using flexible formatters
        let createdDate = parseDate(createdAt) ?? Date()
        let updatedDate = parseDate(updatedAt) ?? parseDate(lastActivity) ?? createdDate

        // Build role from name and priority
        let userRole: UserRole
        if let roleName = role {
            userRole = UserRole(name: roleName, priority: rolePriority)
        } else {
            userRole = UserRole(name: "member")
        }

        // Parse status with fallback to unknown
        let userStatus = UserStatus(rawValue: status.lowercased()) ?? .unknown

        // Parse organization ID
        var orgId: UUID?
        if let orgIdString = organization?.id {
            orgId = UUID(uuidString: orgIdString)
        }

        // Parse avatar URL
        var avatarURL: URL?
        if let avatar = avatarUrl {
            avatarURL = URL(string: avatar)
        }

        return User(
            id: uuid,
            email: email,
            firstName: firstName,
            lastName: lastName,
            avatar: avatarURL,
            role: userRole,
            status: userStatus,
            organizationId: orgId,
            createdAt: createdDate,
            updatedAt: updatedDate
        )
    }

    // MARK: - Date Parsing

    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }

        // Try multiple date formats that Django might return
        let formatters: [Any] = [
            ISO8601DateFormatter(),
            {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                return formatter
            }()
        ]

        for formatter in formatters {
            if let isoFormatter = formatter as? ISO8601DateFormatter {
                if let date = isoFormatter.date(from: dateString) {
                    return date
                }
            } else if let dateFormatter = formatter as? DateFormatter {
                if let date = dateFormatter.date(from: dateString) {
                    return date
                }
            }
        }

        print("⚠️ Could not parse date: '\(dateString)'")
        return nil
    }
}

// MARK: - Supporting DTOs

/// Reference to an organization (returned inline by backend)
struct OrganizationRefDTO: Codable {
    let id: String?
    let name: String?
}

/// Role assignment from V3 permission system
struct RoleAssignmentDTO: Codable {
    let id: String?
    let role: RoleRefDTO?
    let organization: OrganizationRefDTO?
    let isActive: Bool?
    let assignedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case role
        case organization
        case isActive = "is_active"
        case assignedAt = "assigned_at"
    }
}

/// Reference to a role
struct RoleRefDTO: Codable {
    let id: String?
    let name: String?
    let priority: Int?
}

// MARK: - DTO Errors

enum DTOError: LocalizedError {
    case invalidUUID(String)
    case invalidDate(String? = nil)
    case invalidRole(String)
    case invalidStatus(String)

    var errorDescription: String? {
        switch self {
        case .invalidUUID(let id):
            return "Invalid UUID: \(id)"
        case .invalidDate(let dateString):
            if let dateString = dateString {
                return "Invalid date format: \(dateString)"
            } else {
                return "Invalid date format"
            }
        case .invalidRole(let role):
            return "Invalid role: \(role)"
        case .invalidStatus(let status):
            return "Invalid status: \(status)"
        }
    }
}
