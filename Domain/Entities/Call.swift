import Foundation

/// Domain entity representing a phone call
struct PhoneCall: Identifiable, Codable, Equatable {
    let id: String
    let sid: String
    let fromNumber: String
    let toNumber: String
    let direction: CallDirection
    let status: CallStatus
    let duration: Int?
    let recordingUrl: URL?
    let transcription: String?
    let sentiment: String?
    let sentimentSummary: String?
    let errorCode: Int?
    let errorMessage: String?
    let createdAt: Date
    let updatedAt: Date
    let startedAt: Date?
    let endedAt: Date?

    // Associated entities
    let contactId: String?
    let companyId: String?

    init(
        id: String = UUID().uuidString,
        sid: String,
        fromNumber: String,
        toNumber: String,
        direction: CallDirection,
        status: CallStatus,
        duration: Int? = nil,
        recordingUrl: URL? = nil,
        transcription: String? = nil,
        sentiment: String? = nil,
        sentimentSummary: String? = nil,
        errorCode: Int? = nil,
        errorMessage: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        startedAt: Date? = nil,
        endedAt: Date? = nil,
        contactId: String? = nil,
        companyId: String? = nil
    ) {
        self.id = id
        self.sid = sid
        self.fromNumber = fromNumber
        self.toNumber = toNumber
        self.direction = direction
        self.status = status
        self.duration = duration
        self.recordingUrl = recordingUrl
        self.transcription = transcription
        self.sentiment = sentiment
        self.sentimentSummary = sentimentSummary
        self.errorCode = errorCode
        self.errorMessage = errorMessage
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.contactId = contactId
        self.companyId = companyId
    }

    // MARK: - Computed Properties

    var formattedDuration: String {
        guard let duration = duration, duration > 0 else { return "0:00" }

        let minutes = duration / 60
        let seconds = duration % 60

        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return String(format: "%d:%02d:%02d", hours, remainingMinutes, seconds)
        }

        return String(format: "%d:%02d", minutes, seconds)
    }

    var displayNumber: String {
        direction == .inbound ? fromNumber : toNumber
    }

    var isSuccessful: Bool {
        status == .completed && (duration ?? 0) > 0
    }

    var isMissed: Bool {
        direction == .inbound && (status == .noAnswer || status == .busy || status == .canceled)
    }
}

// MARK: - Call Direction

enum CallDirection: String, Codable, CaseIterable {
    case inbound = "inbound"
    case outbound = "outbound"

    var displayName: String {
        switch self {
        case .inbound: return "Incoming"
        case .outbound: return "Outgoing"
        }
    }

    var iconName: String {
        switch self {
        case .inbound: return "phone.arrow.down.left"
        case .outbound: return "phone.arrow.up.right"
        }
    }
}

// MARK: - Call Status

enum CallStatus: String, Codable, CaseIterable {
    case queued = "queued"
    case ringing = "ringing"
    case inProgress = "in-progress"
    case completed = "completed"
    case busy = "busy"
    case failed = "failed"
    case noAnswer = "no-answer"
    case canceled = "canceled"

    var displayName: String {
        switch self {
        case .queued: return "Queued"
        case .ringing: return "Ringing"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .busy: return "Busy"
        case .failed: return "Failed"
        case .noAnswer: return "No Answer"
        case .canceled: return "Canceled"
        }
    }

    var isActive: Bool {
        switch self {
        case .queued, .ringing, .inProgress:
            return true
        default:
            return false
        }
    }

    var isTerminal: Bool {
        switch self {
        case .completed, .busy, .failed, .noAnswer, .canceled:
            return true
        default:
            return false
        }
    }
}

// MARK: - Active Call State

/// Represents the state of an active call in progress
struct ActiveCallState: Equatable {
    let uuid: UUID
    let phoneNumber: String
    let contactName: String?
    let direction: CallDirection
    var status: ActiveCallStatus
    var isMuted: Bool
    var isSpeakerOn: Bool
    var duration: TimeInterval
    var startTime: Date?

    init(
        uuid: UUID = UUID(),
        phoneNumber: String,
        contactName: String? = nil,
        direction: CallDirection,
        status: ActiveCallStatus = .connecting,
        isMuted: Bool = false,
        isSpeakerOn: Bool = false,
        duration: TimeInterval = 0,
        startTime: Date? = nil
    ) {
        self.uuid = uuid
        self.phoneNumber = phoneNumber
        self.contactName = contactName
        self.direction = direction
        self.status = status
        self.isMuted = isMuted
        self.isSpeakerOn = isSpeakerOn
        self.duration = duration
        self.startTime = startTime
    }

    var displayName: String {
        contactName ?? phoneNumber
    }
}

enum ActiveCallStatus: Equatable {
    case connecting
    case ringing
    case connected
    case onHold
    case ended

    var displayText: String {
        switch self {
        case .connecting: return "Connecting..."
        case .ringing: return "Ringing..."
        case .connected: return "Connected"
        case .onHold: return "On Hold"
        case .ended: return "Call Ended"
        }
    }
}
