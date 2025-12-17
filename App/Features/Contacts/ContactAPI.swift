import Foundation

// MARK: - Contact DTOs

/// Data Transfer Object for Contact API responses
struct ContactDTO: Codable {
    let id: String
    let firstName: String?
    let lastName: String?
    let company: String?
    let jobTitle: String?
    let emails: [ContactEmailDTO]?
    let phones: [ContactPhoneDTO]?
    let avatar: String?
    let notes: String?
    let isFavorite: Bool?
    let tags: [String]?
    let createdAt: String
    let updatedAt: String

    func toDomain() throws -> Contact360 {
        // Create multiple date formatters to handle different Django date formats
        let formatters = [
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
            }()
        ]

        var createdDate: Date?
        var updatedDate: Date?

        // Try each formatter for createdAt
        for formatter in formatters {
            if let isoFormatter = formatter as? ISO8601DateFormatter {
                createdDate = isoFormatter.date(from: createdAt)
            } else if let dateFormatter = formatter as? DateFormatter {
                createdDate = dateFormatter.date(from: createdAt)
            }
            if createdDate != nil { break }
        }

        // Try each formatter for updatedAt
        for formatter in formatters {
            if let isoFormatter = formatter as? ISO8601DateFormatter {
                updatedDate = isoFormatter.date(from: updatedAt)
            } else if let dateFormatter = formatter as? DateFormatter {
                updatedDate = dateFormatter.date(from: updatedAt)
            }
            if updatedDate != nil { break }
        }

        guard let createdDate = createdDate, let updatedDate = updatedDate else {
            print("❌ Failed to parse contact dates - createdAt: '\(createdAt)', updatedAt: '\(updatedAt)'")
            throw DTOError.invalidDate("createdAt: '\(createdAt)', updatedAt: '\(updatedAt)'")
        }

        var avatarURL: URL?
        if let avatar = avatar, !avatar.isEmpty {
            avatarURL = URL(string: avatar)
        }

        let domainEmails = emails?.compactMap { emailDTO in
            try? emailDTO.toDomain()
        } ?? []

        let domainPhones = phones?.compactMap { phoneDTO in
            try? phoneDTO.toDomain()
        } ?? []

        return Contact360(
            id: id,
            firstName: firstName,
            lastName: lastName,
            company: company,
            jobTitle: jobTitle,
            emails: domainEmails,
            phones: domainPhones,
            avatar: avatarURL,
            notes: notes,
            isFavorite: isFavorite ?? false,
            tags: tags ?? [],
            createdAt: createdDate,
            updatedAt: updatedDate
        )
    }
}

struct ContactEmailDTO: Codable {
    let id: String?
    let email: String
    let label: String?
    let isPrimary: Bool?

    func toDomain() throws -> ContactEmail {
        let emailId = id ?? UUID().uuidString
        return ContactEmail(
            id: emailId,
            email: email,
            label: label ?? "Email",
            isPrimary: isPrimary ?? false
        )
    }
}

struct ContactPhoneDTO: Codable {
    let id: String?
    let phone: String
    let label: String?
    let isPrimary: Bool?

    func toDomain() throws -> ContactPhone {
        let phoneId = id ?? UUID().uuidString
        return ContactPhone(
            id: phoneId,
            phone: phone,
            label: label ?? "Phone",
            isPrimary: isPrimary ?? false
        )
    }
}

// MARK: - Request Models

struct CreateContactRequest: Codable {
    let firstName: String?
    let lastName: String?
    let company: String?
    let jobTitle: String?
    let emails: [CreateContactEmailRequest]?
    let phones: [CreateContactPhoneRequest]?
    let notes: String?
    let isFavorite: Bool?
    let tags: [String]?
}

struct CreateContactEmailRequest: Codable {
    let email: String
    let label: String?
    let isPrimary: Bool?
}

struct CreateContactPhoneRequest: Codable {
    let phone: String
    let label: String?
    let isPrimary: Bool?
}

struct UpdateContactRequest: Codable {
    let firstName: String?
    let lastName: String?
    let company: String?
    let jobTitle: String?
    let emails: [CreateContactEmailRequest]?
    let phones: [CreateContactPhoneRequest]?
    let notes: String?
    let isFavorite: Bool?
    let tags: [String]?
}

// MARK: - Repository Protocol

protocol ContactRepository {
    func getContacts(query: ContactQuery?) async throws -> [Contact360]
    func getContact(id: String) async throws -> Contact360
    func createContact(_ contact: CreateContactRequest) async throws -> Contact360
    func updateContact(id: String, data: UpdateContactRequest) async throws -> Contact360
    func deleteContact(id: String) async throws
    func searchContacts(query: String) async throws -> [Contact360]
}

struct ContactQuery {
    var page: Int?
    var limit: Int?
    var company: String?
    var isFavorite: Bool?
    var tags: [String]?
    var search: String?

    init(
        page: Int? = nil,
        limit: Int? = nil,
        company: String? = nil,
        isFavorite: Bool? = nil,
        tags: [String]? = nil,
        search: String? = nil
    ) {
        self.page = page
        self.limit = limit
        self.company = company
        self.isFavorite = isFavorite
        self.tags = tags
        self.search = search
    }
}

// MARK: - Repository Implementation

class ContactRepositoryImpl: ContactRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func getContacts(query: ContactQuery? = nil) async throws -> [Contact360] {
        print("📡 Fetching contacts via GraphQL...")

        // GraphQL query for contacts
        let graphqlQuery = """
        query GetEnhancedContacts($junk: Boolean, $first: Int, $search: String, $orderBy: String) {
          enhancedContactsConnection(junk: $junk, first: $first, search: $search, orderBy: $orderBy) {
            edges {
              node {
                id
                name
                email
                company
                phone
                title
                status
                avatarUrl
                createdAt
                updatedAt
                tags
              }
            }
            totalCount
          }
        }
        """

        // Build variables
        var variables: [String: Any?] = [
            "junk": false,
            "first": query?.limit ?? 1000,  // Increased default from 50 to 1000
            "search": query?.search,
            "orderBy": "-created_at"
        ]

        // Make GraphQL request via raw HTTP POST
        let response = try await makeGraphQLRequest(
            query: graphqlQuery,
            variables: variables,
            operationName: "GetEnhancedContacts"
        )

        // Parse response
        guard let data = response["data"] as? [String: Any],
              let connection = data["enhancedContactsConnection"] as? [String: Any],
              let edges = connection["edges"] as? [[String: Any]] else {
            throw APIError.decodingFailed(NSError(domain: "GraphQL", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid GraphQL response structure"]))
        }

        // Convert nodes to DTOs
        var contacts: [Contact360] = []
        print("🔍 Processing \(edges.count) contact edges from GraphQL")

        for (index, edge) in edges.enumerated() {
            guard let node = edge["node"] as? [String: Any] else {
                print("⚠️ Edge \(index): Failed to cast node")
                continue
            }

            print("🔍 Edge \(index): Processing node with keys: \(node.keys.joined(separator: ", "))")

            // Map GraphQL node to ContactDTO format
            let dto = ContactDTO(
                id: node["id"] as? String ?? "",
                firstName: (node["name"] as? String)?.components(separatedBy: " ").first,
                lastName: (node["name"] as? String)?.components(separatedBy: " ").dropFirst().joined(separator: " "),
                company: node["company"] as? String,
                jobTitle: node["title"] as? String,
                emails: nil,  // GraphQL returns single email string
                phones: nil,  // GraphQL returns single phone string
                avatar: node["avatarUrl"] as? String,
                notes: nil,
                isFavorite: false,
                tags: node["tags"] as? [String],
                createdAt: node["createdAt"] as? String ?? "",
                updatedAt: node["updatedAt"] as? String ?? ""
            )

            do {
                let contact = try dto.toDomain()
                contacts.append(contact)
                print("✅ Edge \(index): Successfully parsed contact")
            } catch {
                print("❌ Edge \(index): Failed to convert DTO to domain - \(error.localizedDescription)")
                print("   ID: \(dto.id)")
                print("   createdAt: '\(dto.createdAt)'")
                print("   updatedAt: '\(dto.updatedAt)'")
            }
        }

        print("📥 Received \(contacts.count) contacts from GraphQL (out of \(edges.count) edges)")
        return contacts
    }

    // Helper method to make raw GraphQL requests
    private func makeGraphQLRequest(
        query: String,
        variables: [String: Any?],
        operationName: String
    ) async throws -> [String: Any] {
        let url = URL(string: "\(Environment.backendURL)/graphql/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add auth header - Get token from apiClient's auth service
        // Note: We need to access the token directly since APIClient uses it internally
        let tokenManager = TokenManager()
        if let token = try await tokenManager.getAccessToken() {
            request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")
            print("🔐 Adding auth header to GraphQL request")
        }

        // Build GraphQL request body
        let body: [String: Any] = [
            "operationName": operationName,
            "query": query,
            "variables": variables.compactMapValues { $0 }
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        print("🔐 Making GraphQL request to /graphql/")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        print("📥 GraphQL Response: \(httpResponse.statusCode)")

        guard (200...299).contains(httpResponse.statusCode) else {
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ GraphQL Error: \(responseString)")
            }
            throw APIError.httpError(httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw APIError.decodingFailed(NSError(domain: "GraphQL", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse JSON"]))
        }

        // Log response structure for debugging
        if let data = json["data"] as? [String: Any],
           let connection = data["enhancedContactsConnection"] as? [String: Any],
           let edges = connection["edges"] as? [[String: Any]] {
            print("📊 GraphQL returned \(edges.count) edges")
            if let first = edges.first, let node = first["node"] as? [String: Any] {
                print("📋 Sample node keys: \(node.keys.joined(separator: ", "))")
            }
        }

        return json
    }

    func getContact(id: String) async throws -> Contact360 {
        let dto: ContactDTO = try await apiClient.get("/api/contacts/\(id)/", parameters: nil)
        return try dto.toDomain()
    }

    func createContact(_ contact: CreateContactRequest) async throws -> Contact360 {
        let dto: ContactDTO = try await apiClient.post("/api/contacts/", body: contact)
        return try dto.toDomain()
    }

    func updateContact(id: String, data: UpdateContactRequest) async throws -> Contact360 {
        let dto: ContactDTO = try await apiClient.put("/api/contacts/\(id)/", body: data)
        return try dto.toDomain()
    }

    func deleteContact(id: String) async throws {
        try await apiClient.delete("/api/contacts/\(id)/")
    }

    func searchContacts(query: String) async throws -> [Contact360] {
        let parameters = ["search": query]
        let dtos: [ContactDTO] = try await apiClient.get("/api/contacts/", parameters: parameters)
        return try dtos.map { try $0.toDomain() }
    }
}