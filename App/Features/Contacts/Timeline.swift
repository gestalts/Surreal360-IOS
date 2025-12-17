import Foundation
import SwiftUI
import Combine

// MARK: - Timeline Item Protocol

protocol TimelineItem: Identifiable {
    var id: String { get }
    var timestamp: Date { get }
    var type: TimelineItemType { get }
}

enum TimelineItemType: String {
    case email
    case message
    case call
    case note
}

// MARK: - Email Timeline Item

struct EmailTimelineItem: TimelineItem, Codable, Equatable {
    let id: String
    let messageId: String?
    let threadId: String?
    let subject: String?
    let content: String?
    let body: String?
    let fromAddress: String?
    let toAddresses: [String]
    let ccAddresses: [String]
    let bccAddresses: [String]
    let sentAt: Date
    let isRead: Bool
    let sentiment: String?
    let sentimentSummary: String?

    var timestamp: Date { sentAt }
    var type: TimelineItemType { .email }

    var displayFrom: String {
        fromAddress ?? "Unknown"
    }

    var displaySubject: String {
        subject ?? "(No Subject)"
    }

    var previewText: String {
        if let body = body, !body.isEmpty {
            return body.prefix(150).trimmingCharacters(in: .whitespacesAndNewlines)
        } else if let content = content, !content.isEmpty {
            return content.prefix(150).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return ""
    }
}

// MARK: - Message Timeline Item

struct MessageTimelineItem: TimelineItem, Codable, Equatable {
    let id: String
    let content: String?
    let direction: String?
    let status: String?
    let createdAt: Date
    let phoneNumber: String?
    let sentiment: String?
    let sentimentSummary: String?

    var timestamp: Date { createdAt }
    var type: TimelineItemType { .message }

    var isInbound: Bool {
        direction?.lowercased() == "inbound"
    }

    var displayContent: String {
        content ?? ""
    }
}

// MARK: - Call Timeline Item

struct CallTimelineItem: TimelineItem, Codable, Equatable {
    let id: String
    let direction: String?
    let duration: Int?
    let status: String?
    let createdAt: Date
    let fromNumber: String?
    let toNumber: String?
    let recordingUrl: String?
    let transcription: String?
    let sentiment: String?
    let sentimentSummary: String?
    let callerName: String?
    let recipientName: String?

    var timestamp: Date { createdAt }
    var type: TimelineItemType { .call }

    var isInbound: Bool {
        direction?.lowercased() == "inbound"
    }

    var durationFormatted: String {
        guard let duration = duration else { return "Unknown duration" }
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var displayPhone: String {
        if isInbound {
            return fromNumber ?? "Unknown"
        } else {
            return toNumber ?? "Unknown"
        }
    }
}

// MARK: - Note Timeline Item

struct NoteTimelineItem: TimelineItem, Codable, Equatable {
    let id: String
    let content: String?
    let title: String?
    let createdAt: Date
    let updatedAt: Date?
    let createdBy: String?

    var timestamp: Date { createdAt }
    var type: TimelineItemType { .note }

    var displayTitle: String {
        title ?? "Note"
    }

    var displayContent: String {
        content ?? ""
    }
}

// MARK: - Timeline Page Response

struct TimelinePage: Codable {
    let items: [AnyTimelineItem]
    let paging: PagingInfo

    struct PagingInfo: Codable {
        let nextCursor: String?
        let hasMore: Bool
        let totalCount: Int

        enum CodingKeys: String, CodingKey {
            case nextCursor = "next_cursor"
            case hasMore = "has_more"
            case totalCount = "total_count"
        }
    }
}

// MARK: - Type-Erased Timeline Item

enum AnyTimelineItem: Codable, Equatable {
    case email(EmailTimelineItem)
    case message(MessageTimelineItem)
    case call(CallTimelineItem)
    case note(NoteTimelineItem)

    var item: any TimelineItem {
        switch self {
        case .email(let item): return item
        case .message(let item): return item
        case .call(let item): return item
        case .note(let item): return item
        }
    }

    var timestamp: Date {
        item.timestamp
    }

    var type: TimelineItemType {
        item.type
    }

    enum CodingKeys: String, CodingKey {
        case type = "__typename"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "EmailMessageType":
            self = .email(try EmailTimelineItem(from: decoder))
        case "MessageType":
            self = .message(try MessageTimelineItem(from: decoder))
        case "CallType":
            self = .call(try CallTimelineItem(from: decoder))
        case "NoteType":
            self = .note(try NoteTimelineItem(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown timeline item type: \(type)"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        switch self {
        case .email(let item):
            try item.encode(to: encoder)
        case .message(let item):
            try item.encode(to: encoder)
        case .call(let item):
            try item.encode(to: encoder)
        case .note(let item):
            try item.encode(to: encoder)
        }
    }
}

// MARK: - Timeline Query Options

struct TimelineQueryOptions {
    var cursor: String?
    var limit: Int = 20
    var sentiment: [String]?
    var startDate: String?
    var endDate: String?
    var fromFilter: String?
    var toFilter: String?
    var typeFilter: [String]?
}

// MARK: - Timeline Repository Protocol

protocol TimelineRepository {
    func getContactTimeline(contactId: String, options: TimelineQueryOptions?) async throws -> TimelinePage
}

// MARK: - Timeline Repository Implementation

class TimelineRepositoryImpl: TimelineRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func getContactTimeline(contactId: String, options: TimelineQueryOptions? = nil) async throws -> TimelinePage {
        print("📡 Fetching timeline for contact: \(contactId)")

        let graphqlQuery = """
        query GetContactTimeline(
          $id: ID!,
          $cursor: String,
          $limit: Int,
          $sentiment: [String],
          $startDate: String,
          $endDate: String,
          $fromFilter: String,
          $toFilter: String,
          $typeFilter: [String]
        ) {
          emailsTimeline(
            id: $id,
            cursor: $cursor,
            limit: $limit,
            sentiment: $sentiment,
            startDate: $startDate,
            endDate: $endDate,
            fromFilter: $fromFilter,
            toFilter: $toFilter,
            typeFilter: $typeFilter
          ) {
            items {
              __typename
              ... on EmailMessageType {
                id
                messageId
                threadId
                subject
                content
                body
                createdBy
                recipients
                cc
                bcc
                sentAt
                isRead
                sentiment {
                  sentiment
                }
                sentimentSummary
              }
              ... on MessageType {
                id
                content
                direction
                status
                createdAt
                phoneNumber
                sentiment {
                  sentiment
                }
                sentimentSummary
              }
              ... on CallType {
                id
                direction
                duration
                status
                createdAt
                fromNumber
                toNumber
                recordingUrl
                transcription
                sentiment {
                  sentiment
                }
                sentimentSummary
                callerName
                recipientName
              }
              ... on NoteType {
                id
                content
                title
                createdAt
                updatedAt
                createdBy
              }
            }
            paging
          }
        }
        """

        var variables: [String: Any?] = [
            "id": contactId,
            "cursor": options?.cursor,
            "limit": options?.limit ?? 20,
            "sentiment": options?.sentiment,
            "startDate": options?.startDate,
            "endDate": options?.endDate,
            "fromFilter": options?.fromFilter,
            "toFilter": options?.toFilter,
            "typeFilter": options?.typeFilter
        ]

        variables = variables.compactMapValues { $0 }

        let response = try await makeGraphQLRequest(
            query: graphqlQuery,
            variables: variables,
            operationName: "GetContactTimeline"
        )

        guard let data = response["data"] as? [String: Any],
              let timelineData = data["emailsTimeline"] as? [String: Any] else {
            throw APIError.decodingFailed(NSError(domain: "GraphQL", code: -1))
        }

        let itemsArray = timelineData["items"] as? [[String: Any]] ?? []
        print("📊 Received \(itemsArray.count) timeline items")

        // Debug: Print first item structure
        if let firstItem = itemsArray.first {
            print("🔍 First item keys: \(firstItem.keys.sorted())")
            print("🔍 First item sample: \(String(describing: firstItem).prefix(500))")
        }

        var timelineItems: [AnyTimelineItem] = []

        for (index, itemDict) in itemsArray.enumerated() {
            // Backend uses "Typename" instead of "__typename"
            guard let typename = (itemDict["Typename"] as? String) ?? (itemDict["__typename"] as? String) else {
                print("⚠️ Item \(index): Missing Typename/__typename, keys: \(itemDict.keys.sorted())")
                continue
            }

            print("🔍 Item \(index): Type=\(typename)")

            do {
                // Add __typename to the dictionary for the decoder
                var mutableItemDict = itemDict
                mutableItemDict["__typename"] = typename

                let itemData = try JSONSerialization.data(withJSONObject: mutableItemDict)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .custom { decoder in
                    let container = try decoder.singleValueContainer()
                    let dateString = try container.decode(String.self)

                    let formatters = [
                        ISO8601DateFormatter(),
                        {
                            let formatter = ISO8601DateFormatter()
                            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                            return formatter
                        }()
                    ]

                    for formatter in formatters {
                        if let date = formatter.date(from: dateString) {
                            return date
                        }
                    }

                    print("❌ Failed to parse date: \(dateString)")
                    throw DecodingError.dataCorruptedError(
                        in: container,
                        debugDescription: "Cannot decode date string: \(dateString)"
                    )
                }

                let item: AnyTimelineItem

                switch typename {
                case "EmailMessageType":
                    var emailDict = mutableItemDict
                    if let recipients = emailDict["recipients"] as? String {
                        emailDict["toAddresses"] = recipients.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                    } else {
                        emailDict["toAddresses"] = []
                    }
                    if let cc = emailDict["cc"] as? String {
                        emailDict["ccAddresses"] = cc.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                    } else {
                        emailDict["ccAddresses"] = []
                    }
                    if let bcc = emailDict["bcc"] as? String {
                        emailDict["bccAddresses"] = bcc.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                    } else {
                        emailDict["bccAddresses"] = []
                    }
                    if let createdBy = emailDict["createdBy"] as? String {
                        emailDict["fromAddress"] = createdBy
                    }
                    // Add isRead if missing
                    if emailDict["isRead"] == nil {
                        emailDict["isRead"] = false
                    }
                    if let sentimentObj = emailDict["sentiment"] as? [String: Any],
                       let sentimentValue = sentimentObj["sentiment"] as? String {
                        emailDict["sentiment"] = sentimentValue
                    } else {
                        emailDict["sentiment"] = nil
                    }
                    let emailData = try JSONSerialization.data(withJSONObject: emailDict)
                    let email = try decoder.decode(EmailTimelineItem.self, from: emailData)
                    item = .email(email)

                case "MessageType":
                    var messageDict = mutableItemDict
                    if let sentimentObj = messageDict["sentiment"] as? [String: Any],
                       let sentimentValue = sentimentObj["sentiment"] as? String {
                        messageDict["sentiment"] = sentimentValue
                    } else {
                        messageDict["sentiment"] = nil
                    }
                    let messageData = try JSONSerialization.data(withJSONObject: messageDict)
                    let message = try decoder.decode(MessageTimelineItem.self, from: messageData)
                    item = .message(message)

                case "CallType":
                    var callDict = mutableItemDict
                    // Convert phone numbers from integers to strings
                    if let fromNumber = callDict["fromNumber"] {
                        callDict["fromNumber"] = String(describing: fromNumber)
                    }
                    if let toNumber = callDict["toNumber"] {
                        callDict["toNumber"] = String(describing: toNumber)
                    }
                    if let sentimentObj = callDict["sentiment"] as? [String: Any],
                       let sentimentValue = sentimentObj["sentiment"] as? String {
                        callDict["sentiment"] = sentimentValue
                    } else {
                        callDict["sentiment"] = nil
                    }
                    let callData = try JSONSerialization.data(withJSONObject: callDict)
                    let call = try decoder.decode(CallTimelineItem.self, from: callData)
                    item = .call(call)

                case "NoteType":
                    let noteData = try JSONSerialization.data(withJSONObject: mutableItemDict)
                    let note = try decoder.decode(NoteTimelineItem.self, from: noteData)
                    item = .note(note)

                default:
                    continue
                }

                timelineItems.append(item)
                print("✅ Item \(index): Successfully parsed \(typename)")

            } catch {
                print("❌ Failed to parse timeline item \(index) (\(typename)): \(error)")
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("   Missing key: \(key.stringValue) - \(context.debugDescription)")
                    case .typeMismatch(let type, let context):
                        print("   Type mismatch: expected \(type) - \(context.debugDescription)")
                    case .valueNotFound(let type, let context):
                        print("   Value not found: \(type) - \(context.debugDescription)")
                    case .dataCorrupted(let context):
                        print("   Data corrupted: \(context.debugDescription)")
                    @unknown default:
                        print("   Unknown decoding error")
                    }
                }
                continue
            }
        }

        let pagingDict = timelineData["paging"] as? [String: Any] ?? [:]
        let pagingInfo = TimelinePage.PagingInfo(
            nextCursor: pagingDict["next_cursor"] as? String,
            hasMore: pagingDict["has_more"] as? Bool ?? false,
            totalCount: pagingDict["total_count"] as? Int ?? timelineItems.count
        )

        print("✅ Successfully parsed \(timelineItems.count) timeline items")

        return TimelinePage(items: timelineItems, paging: pagingInfo)
    }

    private func makeGraphQLRequest(
        query: String,
        variables: [String: Any],
        operationName: String
    ) async throws -> [String: Any] {
        let url = URL(string: "\(Environment.backendURL)/graphql/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let tokenManager = TokenManager()
        if let token = try await tokenManager.getAccessToken() {
            request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")
        }

        let body: [String: Any] = [
            "query": query,
            "variables": variables,
            "operationName": operationName
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let json = json else {
            throw APIError.decodingFailed(NSError(domain: "GraphQL", code: -1))
        }

        if let errors = json["errors"] as? [[String: Any]] {
            let errorMessages = errors.compactMap { $0["message"] as? String }
            throw APIError.decodingFailed(NSError(
                domain: "GraphQL",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: errorMessages.joined(separator: ", ")]
            ))
        }

        return json
    }
}

// MARK: - Get Timeline Use Case

struct GetTimelineUseCase {
    private let repository: TimelineRepository

    init(repository: TimelineRepository) {
        self.repository = repository
    }

    func execute(
        contactId: String,
        options: TimelineQueryOptions? = nil
    ) async throws -> TimelinePage {
        return try await repository.getContactTimeline(contactId: contactId, options: options)
    }
}

// MARK: - Timeline ViewModel

@MainActor
class TimelineViewModel: ObservableObject {
    @Published var items: [AnyTimelineItem] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var showError = false
    @Published var errorMessage = ""

    private let contactId: String
    private let getTimelineUseCase: GetTimelineUseCase
    private var nextCursor: String?
    private var hasMore = false

    init(contactId: String, getTimelineUseCase: GetTimelineUseCase) {
        self.contactId = contactId
        self.getTimelineUseCase = getTimelineUseCase
    }

    func loadTimeline() async {
        guard !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let page = try await getTimelineUseCase.execute(
                contactId: contactId,
                options: TimelineQueryOptions(limit: 20)
            )

            items = page.items
            nextCursor = page.paging.nextCursor
            hasMore = page.paging.hasMore

        } catch {
            showError(message: error.localizedDescription)
        }
    }

    func loadMore() async {
        guard !isLoadingMore, hasMore, let cursor = nextCursor else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let page = try await getTimelineUseCase.execute(
                contactId: contactId,
                options: TimelineQueryOptions(cursor: cursor, limit: 20)
            )

            items.append(contentsOf: page.items)
            nextCursor = page.paging.nextCursor
            hasMore = page.paging.hasMore

        } catch {
            showError(message: error.localizedDescription)
        }
    }

    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Timeline View

struct TimelineView: View {
    let contactId: String
    @StateObject private var viewModel: TimelineViewModel
    @EnvironmentObject var container: DIContainer

    init(contactId: String, container: DIContainer) {
        self.contactId = contactId
        _viewModel = StateObject(wrappedValue: TimelineViewModel(
            contactId: contactId,
            getTimelineUseCase: container.makeGetTimelineUseCase()
        ))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.items.isEmpty {
                loadingView
            } else if viewModel.items.isEmpty {
                emptyStateView
            } else {
                timelineList
            }
        }
        .task {
            await viewModel.loadTimeline()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    private var timelineList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(viewModel.items.enumerated()), id: \.element.item.id) { index, item in
                    TimelineItemView(item: item)
                        .onAppear {
                            if index == viewModel.items.count - 3 {
                                Task {
                                    await viewModel.loadMore()
                                }
                            }
                        }
                }

                if viewModel.isLoadingMore {
                    ProgressView()
                        .padding()
                }
            }
            .padding()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading activity...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Activity Yet")
                .font(.headline)

            Text("Emails, calls, messages, and notes will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Timeline Item View

struct TimelineItemView: View {
    let item: AnyTimelineItem

    var body: some View {
        switch item {
        case .email(let email):
            EmailTimelineItemView(email: email)
        case .message(let message):
            MessageTimelineItemView(message: message)
        case .call(let call):
            CallTimelineItemView(call: call)
        case .note(let note):
            NoteTimelineItemView(note: note)
        }
    }
}

// MARK: - Email Timeline Item View

struct EmailTimelineItemView: View {
    let email: EmailTimelineItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "envelope.fill")
                    .foregroundColor(.blue)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Email")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(email.displayFrom)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Spacer()

                Text(email.sentAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(email.displaySubject)
                    .font(.body)
                    .fontWeight(.semibold)

                if !email.previewText.isEmpty {
                    Text(email.previewText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }

                if let sentiment = email.sentiment {
                    SentimentBadge(sentiment: sentiment)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Message Timeline Item View

struct MessageTimelineItemView: View {
    let message: MessageTimelineItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: message.isInbound ? "arrow.down.message.fill" : "arrow.up.message.fill")
                    .foregroundColor(message.isInbound ? .green : .blue)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(message.isInbound ? "Received Message" : "Sent Message")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let phone = message.phoneNumber {
                        Text(phone)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }

                Spacer()

                Text(message.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if !message.displayContent.isEmpty {
                Text(message.displayContent)
                    .font(.body)
                    .foregroundColor(.primary)
            }

            if let sentiment = message.sentiment {
                SentimentBadge(sentiment: sentiment)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Call Timeline Item View

struct CallTimelineItemView: View {
    let call: CallTimelineItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: call.isInbound ? "phone.arrow.down.left.fill" : "phone.arrow.up.right.fill")
                    .foregroundColor(call.isInbound ? .green : .blue)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(call.isInbound ? "Incoming Call" : "Outgoing Call")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(call.displayPhone)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Spacer()

                Text(call.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 16) {
                Label(call.durationFormatted, systemImage: "clock.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let status = call.status {
                    Text(status.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor(for: status).opacity(0.2))
                        .foregroundColor(statusColor(for: status))
                        .cornerRadius(8)
                }

                if let sentiment = call.sentiment {
                    SentimentBadge(sentiment: sentiment)
                }
            }

            if let transcription = call.transcription, !transcription.isEmpty {
                Text(transcription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "completed": return .green
        case "missed", "failed": return .red
        case "busy", "no-answer": return .orange
        default: return .gray
        }
    }
}

// MARK: - Note Timeline Item View

struct NoteTimelineItemView: View {
    let note: NoteTimelineItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(.orange)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Note")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let createdBy = note.createdBy {
                        Text(createdBy)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }

                Spacer()

                Text(note.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(note.displayTitle)
                    .font(.body)
                    .fontWeight(.semibold)

                if !note.displayContent.isEmpty {
                    Text(note.displayContent)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(5)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Sentiment Badge

struct SentimentBadge: View {
    let sentiment: String

    var body: some View {
        Text(sentiment.capitalized)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(sentimentColor.opacity(0.2))
            .foregroundColor(sentimentColor)
            .cornerRadius(8)
    }

    private var sentimentColor: Color {
        switch sentiment.lowercased() {
        case "positive": return .green
        case "negative": return .red
        case "neutral": return .gray
        default: return .blue
        }
    }
}
