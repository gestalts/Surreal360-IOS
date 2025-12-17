import SwiftUI
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var stats: DashboardStats?
    @Published var recentActivity: [ActivityItem] = []
    @Published var error: Error?

    private let userRepository: UserRepository

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }

    func loadDashboardData() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            // Fetch all users to get total count
            let users = try await userRepository.getUsers(query: nil)
            let userCount = users.count

            // For now, use placeholder values for stats that require current user context
            // In a full implementation, we'd fetch the current user's profile separately
            // The backend returns these in UserDTO: taskCount, projectCount, unreadMessageCount

            stats = DashboardStats(
                userCount: userCount,
                userChange: 0, // Trend data would come from a separate metrics endpoint
                projectCount: 0, // From current user profile
                projectChange: 0,
                taskCount: 0, // From current user profile
                taskChange: 0,
                messageCount: 0, // From current user profile
                messageChange: 0
            )

            // Keep mock activity for now - Phase 2 will connect to real activity feed
            recentActivity = [
                ActivityItem(
                    id: UUID(),
                    type: .userRegistered,
                    title: "Dashboard connected",
                    description: "Loaded \(userCount) users from backend",
                    timestamp: Date()
                )
            ]

            print("Dashboard loaded: \(userCount) users")
        } catch {
            self.error = error
            print("Dashboard error: \(error.localizedDescription)")

            // Set empty stats on error
            stats = DashboardStats(
                userCount: 0,
                userChange: 0,
                projectCount: 0,
                projectChange: 0,
                taskCount: 0,
                taskChange: 0,
                messageCount: 0,
                messageChange: 0
            )
        }
    }

    func refresh() async {
        await loadDashboardData()
    }
}

// MARK: - Dashboard Models

struct DashboardStats {
    let userCount: Int
    let userChange: Int
    let projectCount: Int
    let projectChange: Int
    let taskCount: Int
    let taskChange: Int
    let messageCount: Int
    let messageChange: Int
}

struct ActivityItem: Identifiable {
    let id: UUID
    let type: ActivityType
    let title: String
    let description: String
    let timestamp: Date

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

enum ActivityType {
    case userRegistered
    case projectUpdated
    case tasksCompleted
    case messageReceived
    case fileUploaded

    var icon: String {
        switch self {
        case .userRegistered: return "person.fill.checkmark"
        case .projectUpdated: return "folder.fill"
        case .tasksCompleted: return "checkmark.circle.fill"
        case .messageReceived: return "envelope.fill"
        case .fileUploaded: return "arrow.up.doc.fill"
        }
    }

    var color: Color {
        switch self {
        case .userRegistered: return .blue
        case .projectUpdated: return .purple
        case .tasksCompleted: return .green
        case .messageReceived: return .orange
        case .fileUploaded: return .indigo
        }
    }
}
