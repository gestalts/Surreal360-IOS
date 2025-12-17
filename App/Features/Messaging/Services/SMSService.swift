import Foundation

/// Protocol for SMS service operations
protocol SMSServiceProtocol {
    func sendMessage(to phoneNumber: String, body: String) async throws -> SMSMessage
    func fetchMessages(contactId: String?) async throws -> [SMSMessage]
    func fetchConversations() async throws -> [SMSConversation]
    func fetchConversation(with phoneNumber: String) async throws -> [SMSMessage]
}

/// Service for sending and receiving SMS messages via backend API
final class SMSService: SMSServiceProtocol {

    // MARK: - Properties

    private let authService: AuthenticationService
    private let session: URLSession

    // MARK: - Initialization

    init(authService: AuthenticationService, session: URLSession = .shared) {
        self.authService = authService
        self.session = session
    }

    // MARK: - Send Message

    func sendMessage(to phoneNumber: String, body: String) async throws -> SMSMessage {
        guard let token = try await authService.getAccessToken() else {
            throw SMSError.notAuthenticated
        }

        var request = URLRequest(url: Environment.twilioSMSSendURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")

        let payload = SendSMSRequest(to: phoneNumber, body: body)
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SMSError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200, 201:
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(SMSMessage.self, from: data)
        case 401:
            throw SMSError.notAuthenticated
        case 400:
            let errorResponse = try? JSONDecoder().decode(SMSErrorResponse.self, from: data)
            throw SMSError.sendFailed(errorResponse?.error ?? "Invalid request")
        default:
            throw SMSError.sendFailed("Server error: \(httpResponse.statusCode)")
        }
    }

    // MARK: - Fetch Messages

    func fetchMessages(contactId: String? = nil) async throws -> [SMSMessage] {
        guard let token = try await authService.getAccessToken() else {
            throw SMSError.notAuthenticated
        }

        var urlComponents = URLComponents(url: Environment.twilioMessagesURL, resolvingAgainstBaseURL: false)!
        if let contactId = contactId {
            urlComponents.queryItems = [URLQueryItem(name: "contact_id", value: contactId)]
        }

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw SMSError.fetchFailed
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([SMSMessage].self, from: data)
    }

    // MARK: - Fetch Conversations

    func fetchConversations() async throws -> [SMSConversation] {
        let messages = try await fetchMessages(contactId: nil)
        return groupMessagesIntoConversations(messages)
    }

    func fetchConversation(with phoneNumber: String) async throws -> [SMSMessage] {
        let allMessages = try await fetchMessages(contactId: nil)
        return allMessages.filter { message in
            message.fromNumber == phoneNumber || message.toNumber == phoneNumber
        }.sorted { $0.createdAt < $1.createdAt }
    }

    // MARK: - Private Helpers

    private func groupMessagesIntoConversations(_ messages: [SMSMessage]) -> [SMSConversation] {
        var conversationMap: [String: [SMSMessage]] = [:]

        for message in messages {
            // Group by the "other party" phone number
            let otherParty = message.direction == .inbound ? message.fromNumber : message.toNumber
            conversationMap[otherParty, default: []].append(message)
        }

        return conversationMap.map { phoneNumber, messages in
            let sortedMessages = messages.sorted { $0.createdAt > $1.createdAt }
            let lastMessage = sortedMessages.first!
            let unreadCount = sortedMessages.filter { $0.direction == .inbound && $0.status != .read }.count

            return SMSConversation(
                id: phoneNumber,
                phoneNumber: phoneNumber,
                contactName: nil, // Would need contact lookup
                lastMessage: lastMessage.body,
                lastMessageDate: lastMessage.createdAt,
                unreadCount: unreadCount,
                messages: sortedMessages
            )
        }.sorted { $0.lastMessageDate > $1.lastMessageDate }
    }
}

// MARK: - Request/Response Types

private struct SendSMSRequest: Encodable {
    let to: String
    let body: String
}

private struct SMSErrorResponse: Decodable {
    let error: String
}

// MARK: - Errors

enum SMSError: LocalizedError {
    case notAuthenticated
    case invalidResponse
    case sendFailed(String)
    case fetchFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to send messages"
        case .invalidResponse:
            return "Invalid response from server"
        case .sendFailed(let reason):
            return "Failed to send message: \(reason)"
        case .fetchFailed:
            return "Failed to fetch messages"
        }
    }
}
