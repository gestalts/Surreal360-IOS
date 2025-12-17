import Foundation

/// Implementation of UserRepository using APIClient
class UserRepositoryImpl: UserRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func getUsers(query: UserQuery? = nil) async throws -> [User] {
        var parameters: [String: String] = [:]

        if let query = query {
            if let page = query.page {
                parameters["page"] = "\(page)"
            }
            if let limit = query.limit {
                parameters["limit"] = "\(limit)"
            }
            if let role = query.role {
                parameters["role"] = role.name
            }
            if let status = query.status {
                parameters["status"] = status.rawValue
            }
            if let organizationId = query.organizationId {
                parameters["organization_id"] = organizationId.uuidString
            }
            if let search = query.search {
                parameters["search"] = search
            }
        }

        // Django requires trailing slashes on all endpoints
        let dtos: [UserDTO] = try await apiClient.get("/api/user-profiles/", parameters: parameters.isEmpty ? nil : parameters)
        return try dtos.map { try $0.toDomain() }
    }

    func getUser(id: UUID) async throws -> User {
        let dto: UserDTO = try await apiClient.get("/api/user-profiles/\(id.uuidString)/", parameters: nil)
        return try dto.toDomain()
    }

    func createUser(_ user: CreateUserRequest) async throws -> User {
        let dto: UserDTO = try await apiClient.post("/api/user-profiles/", body: user)
        return try dto.toDomain()
    }

    func updateUser(id: UUID, data: UpdateUserRequest) async throws -> User {
        let dto: UserDTO = try await apiClient.put("/api/user-profiles/\(id.uuidString)/", body: data)
        return try dto.toDomain()
    }

    func deleteUser(id: UUID) async throws {
        try await apiClient.delete("/api/user-profiles/\(id.uuidString)/")
    }

    func searchUsers(query: String) async throws -> [User] {
        let parameters = ["search": query]
        let dtos: [UserDTO] = try await apiClient.get("/api/user-profiles/search/", parameters: parameters)
        return try dtos.map { try $0.toDomain() }
    }
}
