import Foundation

/// Protocol defining the API client interface
protocol APIClient {
    func get<T: Decodable>(_ path: String, parameters: [String: String]?) async throws -> T
    func post<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T
    func put<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T
    func delete(_ path: String) async throws
}

/// Implementation of APIClient using URLSession
class APIClientImpl: APIClient {
    private let session: URLSession
    private let baseURL: URL
    private let authService: AuthenticationService

    init(
        session: URLSession? = nil,
        baseURL: URL,
        authService: AuthenticationService
    ) {
        self.baseURL = baseURL
        self.authService = authService
        
        // Create a custom URLSession configuration
        let config = URLSessionConfiguration.default
        config.httpShouldSetCookies = true
        config.httpCookieAcceptPolicy = .always
        
        self.session = session ?? URLSession(configuration: config)
    }


    func get<T: Decodable>(_ path: String, parameters: [String: String]? = nil) async throws -> T {
        let url = buildURL(path: path, parameters: parameters)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        try await addAuthHeaders(to: &request)

        print("📡 GET \(url)")
        return try await performRequest(request)
    }

    func post<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        let url = buildURL(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try await addAuthHeaders(to: &request)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(body)

        return try await performRequest(request)
    }

    func put<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        let url = buildURL(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try await addAuthHeaders(to: &request)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(body)

        return try await performRequest(request)
    }

    func delete(_ path: String) async throws {
        let url = buildURL(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        try await addAuthHeaders(to: &request)

        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }

    // MARK: - Private Methods

    private func buildURL(path: String, parameters: [String: String]? = nil) -> URL {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: true)!

        if let parameters = parameters, !parameters.isEmpty {
            components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        return components.url!
    }

    private func addAuthHeaders(to request: inout URLRequest) async throws {
        if let token = try await authService.getAccessToken() {
            // Django backend expects "Token" prefix, not "Bearer"
            let authHeader = "Token \(token)"
            request.setValue(authHeader, forHTTPHeaderField: "Authorization")
            print("🔐 Adding auth header: Token \(token.prefix(20))...")
        } else {
            print("⚠️ No access token available for request to \(request.url?.path ?? "unknown")")
        }
    }

    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)

        let decoder = JSONDecoder()
        // Let the DTOs handle their own date parsing for more flexibility
        // decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            // Print the raw JSON for debugging date format issues
            if let jsonString = String(data: data, encoding: .utf8) {
                print("🔍 Raw JSON response: \(jsonString)")
            }
            throw APIError.decodingFailed(error)
        }
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        print("📥 Response: \(httpResponse.statusCode) from \(httpResponse.url?.path ?? "unknown")")

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            print("❌ 401 Unauthorized - Token may be invalid or missing")
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        case 500...599:
            throw APIError.serverError(httpResponse.statusCode)
        default:
            throw APIError.httpError(httpResponse.statusCode)
        }
    }
}

// MARK: - API Error

enum APIError: LocalizedError {
    case invalidResponse
    case decodingFailed(Error)
    case unauthorized
    case forbidden
    case notFound
    case serverError(Int)
    case httpError(Int)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .unauthorized:
            return "Unauthorized. Please sign in again."
        case .forbidden:
            return "Access forbidden"
        case .notFound:
            return "Resource not found"
        case .serverError(let code):
            return "Server error (\(code))"
        case .httpError(let code):
            return "HTTP error (\(code))"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
