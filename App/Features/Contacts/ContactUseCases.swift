import Foundation

import Foundation

// MARK: - Contact Use Cases

struct GetContactsUseCase {
    private let repository: ContactRepository

    init(repository: ContactRepository) {
        self.repository = repository
    }

    func execute(query: ContactQuery? = nil) async throws -> [Contact360] {
        return try await repository.getContacts(query: query)
    }
}

struct GetContactByIdUseCase {
    private let repository: ContactRepository

    init(repository: ContactRepository) {
        self.repository = repository
    }

    func execute(id: String) async throws -> Contact360 {
        return try await repository.getContact(id: id)
    }
}

struct CreateContactUseCase {
    private let repository: ContactRepository

    init(repository: ContactRepository) {
        self.repository = repository
    }

    func execute(_ request: CreateContactRequest) async throws -> Contact360 {
        // Validation: must have at least a name or company
        let hasFirstName = request.firstName?.isEmpty == false
        let hasLastName = request.lastName?.isEmpty == false  
        let hasCompany = request.company?.isEmpty == false
        
        guard hasFirstName || hasLastName || hasCompany else {
            throw ContactValidationError.missingNameOrCompany
        }

        return try await repository.createContact(request)
    }
}

struct UpdateContactUseCase {
    private let repository: ContactRepository

    init(repository: ContactRepository) {
        self.repository = repository
    }

    func execute(id: String, data: UpdateContactRequest) async throws -> Contact360 {
        return try await repository.updateContact(id: id, data: data)
    }
}

struct DeleteContactUseCase {
    private let repository: ContactRepository

    init(repository: ContactRepository) {
        self.repository = repository
    }

    func execute(id: String) async throws {
        try await repository.deleteContact(id: id)
    }
}

struct SearchContactsUseCase {
    private let repository: ContactRepository

    init(repository: ContactRepository) {
        self.repository = repository
    }

    func execute(query: String) async throws -> [Contact360] {
        guard !query.isEmpty else {
            return try await repository.getContacts(query: nil)
        }
        
        return try await repository.searchContacts(query: query)
    }
}

// MARK: - Validation Errors

enum ContactValidationError: LocalizedError {
    case missingNameOrCompany
    case invalidEmail(String)
    case invalidPhoneNumber(String)
    case emptyField(String)

    var errorDescription: String? {
        switch self {
        case .missingNameOrCompany:
            return "Contact must have a name or company"
        case .invalidEmail(let email):
            return "Invalid email format: \(email)"
        case .invalidPhoneNumber(let phone):
            return "Invalid phone number: \(phone)"
        case .emptyField(let field):
            return "\(field) cannot be empty"
        }
    }
}
