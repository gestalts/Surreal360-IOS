import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var container: DIContainer

    var body: some View {
        TabView {
            // Home Tab
            DashboardHomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            // Users Tab (renamed from People)
            UsersNavigationView()
                .tabItem {
                    Label("Users", systemImage: "person.2.fill")
                }

            // Contacts Tab (new)
            ContactsNavigationView()
                .tabItem {
                    Label("Contacts", systemImage: "person.crop.circle.fill")
                }

            // Projects Tab (Phase 2)
            if FeatureFlags.Phase2.projects {
                PlaceholderView(title: "Projects")
                    .tabItem {
                        Label("Projects", systemImage: "list.bullet.clipboard")
                    }
            }

            // Communications Tab (Phase 2)
            if FeatureFlags.Phase2.communications {
                PlaceholderView(title: "Communications")
                    .tabItem {
                        Label("Messages", systemImage: "envelope.fill")
                    }
            }

            // Settings Tab
            SettingsView(container: container)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}

// MARK: - Dashboard Home View

struct DashboardHomeView: View {
    @EnvironmentObject var container: DIContainer
    @StateObject private var viewModel: DashboardViewModel

    init() {
        // Initialize with a placeholder - will be replaced when container is available
        _viewModel = StateObject(wrappedValue: DashboardViewModel(userRepository: PlaceholderUserRepository()))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome Header
                    WelcomeHeader()
                        .padding(.horizontal)

                    // Stats Cards - now connected to real data
                    StatsCardsView(stats: viewModel.stats)
                        .padding(.horizontal)

                    // Quick Actions
                    QuickActionsView()
                        .padding(.horizontal)

                    // Recent Activity
                    RecentActivityView(activity: viewModel.recentActivity)
                        .padding(.horizontal)

                    // Error message if any
                    if let error = viewModel.error {
                        Text("Error: \(error.localizedDescription)")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
            .refreshable {
                await viewModel.refresh()
            }
            .overlay {
                if viewModel.isLoading && viewModel.stats == nil {
                    ProgressView("Loading...")
                }
            }
        }
        .task {
            await viewModel.loadDashboardData()
        }
    }
}

/// Placeholder repository for StateObject initialization
private class PlaceholderUserRepository: UserRepository {
    func getUsers(query: UserQuery?) async throws -> [User] { [] }
    func getUser(id: UUID) async throws -> User { throw NSError(domain: "", code: 0) }
    func createUser(_ user: CreateUserRequest) async throws -> User { throw NSError(domain: "", code: 0) }
    func updateUser(id: UUID, data: UpdateUserRequest) async throws -> User { throw NSError(domain: "", code: 0) }
    func deleteUser(id: UUID) async throws {}
    func searchUsers(query: String) async throws -> [User] { [] }
}

// MARK: - Welcome Header

struct WelcomeHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome back!")
                .font(.title2)
                .fontWeight(.bold)

            Text("Here's what's happening today")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Stats Cards

struct StatsCardsView: View {
    let stats: DashboardStats?

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                StatCard(
                    title: "Users",
                    value: "\(stats?.userCount ?? 0)",
                    change: formatChange(stats?.userChange ?? 0),
                    isPositive: (stats?.userChange ?? 0) >= 0,
                    icon: "person.2.fill",
                    color: .blue
                )

                StatCard(
                    title: "Projects",
                    value: "\(stats?.projectCount ?? 0)",
                    change: formatChange(stats?.projectChange ?? 0),
                    isPositive: (stats?.projectChange ?? 0) >= 0,
                    icon: "folder.fill",
                    color: .purple
                )
            }

            HStack(spacing: 16) {
                StatCard(
                    title: "Tasks",
                    value: "\(stats?.taskCount ?? 0)",
                    change: formatChange(stats?.taskChange ?? 0),
                    isPositive: (stats?.taskChange ?? 0) >= 0,
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                StatCard(
                    title: "Messages",
                    value: "\(stats?.messageCount ?? 0)",
                    change: formatChange(stats?.messageChange ?? 0),
                    isPositive: (stats?.messageChange ?? 0) >= 0,
                    icon: "envelope.fill",
                    color: .orange
                )
            }
        }
    }

    private func formatChange(_ value: Int) -> String {
        if value == 0 { return "-" }
        return value > 0 ? "+\(value)" : "\(value)"
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let change: String
    let isPositive: Bool
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
                Text(change)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isPositive ? .green : .red)
            }

            Text(value)
                .font(.title)
                .fontWeight(.bold)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Quick Actions

struct QuickActionsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                QuickActionButton(title: "Add User", icon: "person.badge.plus", color: .blue)
                QuickActionButton(title: "New Project", icon: "folder.badge.plus", color: .purple)
                QuickActionButton(title: "Send Message", icon: "paperplane.fill", color: .green)
                QuickActionButton(title: "Schedule", icon: "calendar.badge.plus", color: .orange)
                QuickActionButton(title: "Upload File", icon: "arrow.up.doc.fill", color: .indigo)
                QuickActionButton(title: "Reports", icon: "chart.bar.fill", color: .pink)
            }
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        Button {
            // TODO: Implement action
        } label: {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

// MARK: - Recent Activity

struct RecentActivityView: View {
    let activity: [ActivityItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .fontWeight(.semibold)

            if activity.isEmpty {
                Text("No recent activity")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(activity) { item in
                        ActivityRow(
                            icon: item.type.icon,
                            title: item.title,
                            subtitle: item.description,
                            time: item.timeAgo,
                            color: item.type.color
                        )
                    }
                }
            }
        }
    }
}

struct ActivityRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let time: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Placeholder View

struct PlaceholderView: View {
    let title: String

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "hammer.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(.gray.gradient)

                Text("Coming Soon")
                    .font(.title)
                    .fontWeight(.bold)

                Text("\(title) features will be available in a future update")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .navigationTitle(title)
        }
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .environmentObject(DIContainer())
}
