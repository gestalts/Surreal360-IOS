import Foundation

/// Protocol defining operations for user data management
protocol UserRepository {
    /// Fetch all users with optional filtering
    func getUsers(query: UserQuery?) async throws -> [User]

    /// Fetch a single user by ID
    func getUser(id: UUID) async throws -> User

    /// Create a new user
    func createUser(_ user: CreateUserRequest) async throws -> User

    /// Update an existing user
    func updateUser(id: UUID, data: UpdateUserRequest) async throws -> User

    /// Delete a user
    func deleteUser(id: UUID) async throws

    /// Search users by query string
    func searchUsers(query: String) async throws -> [User]
}

// MARK: - Request/Query Models

struct UserQuery {
    var page: Int?
    var limit: Int?
    var role: UserRole?
    var status: UserStatus?
    var organizationId: UUID?
    var search: String?

    init(
        page: Int? = nil,
        limit: Int? = nil,
        role: UserRole? = nil,
        status: UserStatus? = nil,
        organizationId: UUID? = nil,
        search: String? = nil
    ) {
        self.page = page
        self.limit = limit
        self.role = role
        self.status = status
        self.organizationId = organizationId
        self.search = search
    }
}

struct CreateUserRequest: Codable {
    let email: String
    let password: String
    let firstName: String?
    let lastName: String?
    let role: UserRole
    let organizationId: UUID?
}

struct UpdateUserRequest: Codable {
    let firstName: String?
    let lastName: String?
    let role: UserRole?
    let status: UserStatus?
    let organizationId: UUID?
}
