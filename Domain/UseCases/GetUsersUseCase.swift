import Foundation

/// Use case for fetching users with optional filtering
struct GetUsersUseCase {
    private let repository: UserRepository

    init(repository: UserRepository) {
        self.repository = repository
    }

    func execute(query: UserQuery? = nil) async throws -> [User] {
        return try await repository.getUsers(query: query)
    }
}

/// Use case for fetching a single user by ID
struct GetUserByIdUseCase {
    private let repository: UserRepository

    init(repository: UserRepository) {
        self.repository = repository
    }

    func execute(id: UUID) async throws -> User {
        return try await repository.getUser(id: id)
    }
}

/// Use case for creating a new user
struct CreateUserUseCase {
    private let repository: UserRepository

    init(repository: UserRepository) {
        self.repository = repository
    }

    func execute(_ request: CreateUserRequest) async throws -> User {
        // Add validation logic here if needed
        guard !request.email.isEmpty else {
            throw ValidationError.emptyEmail
        }

        guard !request.password.isEmpty, request.password.count >= 8 else {
            throw ValidationError.weakPassword
        }

        return try await repository.createUser(request)
    }
}

/// Use case for updating a user
struct UpdateUserUseCase {
    private let repository: UserRepository

    init(repository: UserRepository) {
        self.repository = repository
    }

    func execute(id: UUID, data: UpdateUserRequest) async throws -> User {
        return try await repository.updateUser(id: id, data: data)
    }
}

/// Use case for deleting a user
struct DeleteUserUseCase {
    private let repository: UserRepository

    init(repository: UserRepository) {
        self.repository = repository
    }

    func execute(id: UUID) async throws {
        try await repository.deleteUser(id: id)
    }
}

// MARK: - Validation Errors

enum ValidationError: LocalizedError {
    case emptyEmail
    case invalidEmail
    case weakPassword
    case emptyField(String)

    var errorDescription: String? {
        switch self {
        case .emptyEmail:
            return "Email cannot be empty"
        case .invalidEmail:
            return "Invalid email format"
        case .weakPassword:
            return "Password must be at least 8 characters"
        case .emptyField(let field):
            return "\(field) cannot be empty"
        }
    }
}
