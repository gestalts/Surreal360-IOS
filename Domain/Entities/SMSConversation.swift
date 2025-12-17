import Foundation

/// Domain entity representing an SMS message
struct SMSMessage: Identifiable, Codable, Equatable {
    let id: String
    let sid: String
    let fromNumber: String
    let toNumber: String
    let body: String
    let direction: MessageDirection
    let status: MessageStatus
    let mediaUrls: [URL]?
    let errorCode: Int?
    let errorMessage: String?
    let createdAt: Date
    let updatedAt: Date

    // Associated entities
    let contactId: String?
    let companyId: String?

    init(
        id: String = UUID().uuidString,
        sid: String,
        fromNumber: String,
        toNumber: String,
        body: String,
        direction: MessageDirection,
        status: MessageStatus,
        mediaUrls: [URL]? = nil,
        errorCode: Int? = nil,
        errorMessage: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        contactId: String? = nil,
        companyId: String? = nil
    ) {
        self.id = id
        self.sid = sid
        self.fromNumber = fromNumber
        self.toNumber = toNumber
        self.body = body
        self.direction = direction
        self.status = status
        self.mediaUrls = mediaUrls
        self.errorCode = errorCode
        self.errorMessage = errorMessage
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.contactId = contactId
        self.companyId = companyId
    }

    // MARK: - Computed Properties

    var isOutbound: Bool {
        direction == .outbound
    }

    var hasMedia: Bool {
        !(mediaUrls?.isEmpty ?? true)
    }

    var otherPartyNumber: String {
        direction == .inbound ? fromNumber : toNumber
    }

    var isDelivered: Bool {
        status == .delivered || status == .read
    }

    var isFailed: Bool {
        status == .failed || status == .undelivered
    }
}

// MARK: - Message Direction

enum MessageDirection: String, Codable, CaseIterable {
    case inbound = "inbound"
    case outbound = "outbound"
}

// MARK: - Message Status

enum MessageStatus: String, Codable, CaseIterable {
    case queued = "queued"
    case sending = "sending"
    case sent = "sent"
    case delivered = "delivered"
    case failed = "failed"
    case undelivered = "undelivered"
    case received = "received"
    case read = "read"

    var displayName: String {
        switch self {
        case .queued: return "Queued"
        case .sending: return "Sending"
        case .sent: return "Sent"
        case .delivered: return "Delivered"
        case .failed: return "Failed"
        case .undelivered: return "Undelivered"
        case .received: return "Received"
        case .read: return "Read"
        }
    }

    var iconName: String {
        switch self {
        case .queued, .sending:
            return "clock"
        case .sent:
            return "checkmark"
        case .delivered, .read:
            return "checkmark.circle.fill"
        case .failed, .undelivered:
            return "exclamationmark.circle.fill"
        case .received:
            return "arrow.down.circle"
        }
    }
}

// MARK: - SMS Conversation

struct SMSConversation: Identifiable, Equatable {
    let id: String
    let phoneNumber: String
    var contactName: String?
    var lastMessage: String
    var lastMessageDate: Date
    var unreadCount: Int
    var messages: [SMSMessage]

    init(
        id: String,
        phoneNumber: String,
        contactName: String? = nil,
        lastMessage: String,
        lastMessageDate: Date,
        unreadCount: Int = 0,
        messages: [SMSMessage] = []
    ) {
        self.id = id
        self.phoneNumber = phoneNumber
        self.contactName = contactName
        self.lastMessage = lastMessage
        self.lastMessageDate = lastMessageDate
        self.unreadCount = unreadCount
        self.messages = messages
    }

    var displayName: String {
        contactName ?? phoneNumber
    }

    var hasUnreadMessages: Bool {
        unreadCount > 0
    }

    static func == (lhs: SMSConversation, rhs: SMSConversation) -> Bool {
        lhs.id == rhs.id &&
        lhs.phoneNumber == rhs.phoneNumber &&
        lhs.lastMessage == rhs.lastMessage &&
        lhs.lastMessageDate == rhs.lastMessageDate &&
        lhs.unreadCount == rhs.unreadCount
    }
}

// MARK: - Draft Message

struct DraftMessage {
    var to: String
    var body: String

    init(to: String = "", body: String = "") {
        self.to = to
        self.body = body
    }

    var isValid: Bool {
        !to.isEmpty && !body.isEmpty
    }
}
