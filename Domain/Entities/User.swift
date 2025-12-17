import Foundation

/// Domain entity representing a user in the system
struct User: Identifiable, Codable, Equatable {
    let id: UUID
    let email: String
    let firstName: String?
    let lastName: String?
    let avatar: URL?
    let role: UserRole
    let status: UserStatus
    let organizationId: UUID?
    let createdAt: Date
    let updatedAt: Date

    var fullName: String {
        [firstName, lastName]
            .compactMap { $0 }
            .joined(separator: " ")
    }

    var initials: String {
        let first = firstName?.first.map(String.init) ?? ""
        let last = lastName?.first.map(String.init) ?? ""
        return (first + last).uppercased()
    }
}

/// Flexible user role that can represent any string with a priority
struct UserRole: Codable, Equatable, Hashable {
    let name: String
    let priority: Int
    
    init(name: String, priority: Int? = nil) {
        self.name = name
        self.priority = priority ?? Self.defaultPriority(for: name)
    }
    
    /// Display name for the role (capitalized)
    var displayName: String {
        // Handle special cases
        switch name.lowercased() {
        case "admin", "administrator":
            return "Administrator"
        case "ceo":
            return "CEO"
        case "cto":
            return "CTO"
        case "cfo":
            return "CFO"
        default:
            return name.capitalized
        }
    }
    
    /// Predefined common roles for easy access
    static let admin = UserRole(name: "admin", priority: 100)
    static let founder = UserRole(name: "founder", priority: 95)
    static let ceo = UserRole(name: "ceo", priority: 90)
    static let cto = UserRole(name: "cto", priority: 85)
    static let cfo = UserRole(name: "cfo", priority: 85)
    static let manager = UserRole(name: "manager", priority: 70)
    static let teamLead = UserRole(name: "team_lead", priority: 60)
    static let senior = UserRole(name: "senior", priority: 50)
    static let member = UserRole(name: "member", priority: 40)
    static let junior = UserRole(name: "junior", priority: 30)
    static let intern = UserRole(name: "intern", priority: 20)
    static let guest = UserRole(name: "guest", priority: 10)
    
    /// Common roles for UI purposes
    static var commonRoles: [UserRole] {
        [.admin, .founder, .manager, .teamLead, .senior, .member, .junior, .guest]
    }
    
    /// Get default priority for unknown roles
    private static func defaultPriority(for roleName: String) -> Int {
        switch roleName.lowercased() {
        case "admin", "administrator": return 100
        case "founder": return 95
        case "ceo": return 90
        case "cto", "cfo", "cmo": return 85
        case "director": return 80
        case "manager": return 70
        case "team_lead", "team lead", "lead": return 60
        case "senior": return 50
        case "member", "developer", "engineer": return 40
        case "junior": return 30
        case "intern": return 20
        case "guest": return 10
        default: return 40 // Default to member level
        }
    }
}

extension UserRole {
    /// For backward compatibility with string-based APIs
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let name = try? container.decode(String.self, forKey: .name) {
            // New format with name and priority
            let priority = (try? container.decode(Int.self, forKey: .priority)) ?? Self.defaultPriority(for: name)
            self.init(name: name, priority: priority)
        } else {
            // Fallback for old string-only format
            let singleValue = try decoder.singleValueContainer()
            let roleName = try singleValue.decode(String.self)
            self.init(name: roleName)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(priority, forKey: .priority)
    }
    
    private enum CodingKeys: String, CodingKey {
        case name
        case priority
    }
}

/// User account status matching backend values
enum UserStatus: String, Codable, CaseIterable {
    case active = "active"
    case pending = "pending"
    case banned = "banned"
    case rejected = "rejected"
    case unknown = "unknown"

    var displayName: String {
        switch self {
        case .active: return "Active"
        case .pending: return "Pending"
        case .banned: return "Banned"
        case .rejected: return "Rejected"
        case .unknown: return "Unknown"
        }
    }

    /// Whether the user can access the system
    var canAccess: Bool {
        self == .active
    }

    /// Custom decoder to handle unknown status values gracefully
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = UserStatus(rawValue: rawValue.lowercased()) ?? .unknown
    }
}

// MARK: - Extensions

extension UserRole: Comparable {
    /// Sort roles by priority (higher priority first)
    static func < (lhs: UserRole, rhs: UserRole) -> Bool {
        lhs.priority < rhs.priority
    }
}

extension Array where Element == User {
    /// Sort users by role priority (highest priority first)
    func sortedByRolePriority() -> [User] {
        return sorted { $0.role.priority > $1.role.priority }
    }
    
    /// Filter users by minimum role priority
    func withMinimumRolePriority(_ minPriority: Int) -> [User] {
        return filter { $0.role.priority >= minPriority }
    }
}
