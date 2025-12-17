import SwiftUI

struct UsersNavigationView: View {
    @EnvironmentObject var container: DIContainer

    var body: some View {
        NavigationStack {
            UsersListView(container: container)
                .environmentObject(container)
        }
    }
}

struct UsersListView: View {
    @EnvironmentObject var container: DIContainer
    @StateObject private var viewModel: UsersViewModel

    @State private var showingAddUser = false
    @State private var searchText = ""

    init(container: DIContainer) {
        _viewModel = StateObject(wrappedValue: UsersViewModel(
            getUsersUseCase: container.makeGetUsersUseCase()
        ))
    }

    var body: some View {
        List {
            ForEach(viewModel.filteredUsers) { user in
                NavigationLink(destination: UserDetailView(user: user)) {
                    UserRowView(user: user)
                }
            }
        }
        .navigationTitle("Users")
        .searchable(text: $searchText, prompt: "Search users")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddUser = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .refreshable {
            await viewModel.loadUsers()
        }
        .overlay {
            if viewModel.isLoading && viewModel.users.isEmpty {
                ProgressView()
            } else if viewModel.users.isEmpty {
                EmptyStateView(
                    icon: "person.2.fill",
                    title: "No Users",
                    message: "Get started by adding your first user"
                )
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .sheet(isPresented: $showingAddUser) {
            AddUserView()
        }
        .task {
            await viewModel.loadUsers()
        }
        .onChange(of: searchText) { _, newValue in
            viewModel.searchQuery = newValue
        }
    }
}

// MARK: - User Row View

struct UserRowView: View {
    let user: User

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.blue.gradient)
                    .frame(width: 44, height: 44)

                if let avatar = user.avatar {
                    AsyncImage(url: avatar) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Text(user.initials)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                } else {
                    Text(user.initials)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }

            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.fullName.isEmpty ? user.email : user.fullName)
                    .font(.body)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    Text(user.role.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if user.status != .active {
                        Text("•")
                            .foregroundColor(.secondary)

                        Text(user.status.displayName)
                            .font(.caption)
                            .foregroundColor(statusColor(for: user.status))
                    }
                }
            }

            Spacer()

            // Status indicator
            Circle()
                .fill(statusColor(for: user.status))
                .frame(width: 8, height: 8)
        }
        .padding(.vertical, 4)
    }

    private func statusColor(for status: UserStatus) -> Color {
        switch status {
        case .active: return .green
        case .pending: return .orange
        case .banned: return .red
        case .rejected: return .gray
        case .unknown: return .gray
        }
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundStyle(.gray.gradient)

            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Add User View (Placeholder)

struct AddUserView: View {
    @SwiftUI.Environment(\.dismiss) private var dismiss: DismissAction

    var body: some View {
        NavigationStack {
            Form {
                Section("User Information") {
                    TextField("First Name", text: .constant(""))
                    TextField("Last Name", text: .constant(""))
                    TextField("Email", text: .constant(""))
                }

                Section("Role") {
                    Picker("Role", selection: .constant(UserRole.member)) {
                        ForEach(UserRole.commonRoles, id: \.self) { role in
                            Text(role.displayName).tag(role)
                        }
                    }
                }
            }
            .navigationTitle("Add User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // TODO: Implement save
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    UsersNavigationView()
        .environmentObject(DIContainer())
}
