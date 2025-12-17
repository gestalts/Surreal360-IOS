import SwiftUI

struct UserDetailView: View {
    let user: User

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                UserDetailHeader(user: user)
                    .padding()

                // Info Sections
                VStack(spacing: 16) {
                    InfoSection(title: "Contact Information") {
                        InfoRow(label: "Email", value: user.email, icon: "envelope.fill")
                    }

                    InfoSection(title: "Role & Status") {
                        InfoRow(label: "Role", value: user.role.displayName, icon: "person.fill.badge.plus")
                        InfoRow(label: "Status", value: user.status.displayName, icon: "circle.fill")
                    }

                    InfoSection(title: "Account Details") {
                        InfoRow(label: "User ID", value: user.id.uuidString, icon: "number")
                        InfoRow(label: "Created", value: user.createdAt.formatted(date: .long, time: .omitted), icon: "calendar")
                        InfoRow(label: "Updated", value: user.updatedAt.formatted(date: .long, time: .omitted), icon: "clock")
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle(user.fullName.isEmpty ? "User Details" : user.fullName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        // TODO: Edit user
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        // TODO: Delete user
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}

// MARK: - User Detail Header

struct UserDetailHeader: View {
    let user: User

    var body: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.blue.gradient)
                    .frame(width: 100, height: 100)

                if let avatar = user.avatar {
                    AsyncImage(url: avatar) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Text(user.initials)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                } else {
                    Text(user.initials)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }

            // Name and Email
            VStack(spacing: 4) {
                if !user.fullName.isEmpty {
                    Text(user.fullName)
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Status Badge
            StatusBadge(status: user.status)
        }
    }
}

struct StatusBadge: View {
    let status: UserStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(8)
    }

    private var statusColor: Color {
        switch status {
        case .active: return .green
        case .pending: return .orange
        case .banned: return .red
        case .rejected: return .gray
        case .unknown: return .gray
        }
    }
}

// MARK: - Info Section

struct InfoSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 0) {
                content
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.subheadline)
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        UserDetailView(user: User(
            id: UUID(),
            email: "john.doe@example.com",
            firstName: "John",
            lastName: "Doe",
            avatar: nil,
            role: .admin,
            status: .active,
            organizationId: nil,
            createdAt: Date(),
            updatedAt: Date()
        ))
    }
}
