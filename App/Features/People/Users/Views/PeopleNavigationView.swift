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
            AddUserView(
                createUserUseCase: container.makeCreateUserUseCase(),
                onUserCreated: {
                    Task {
                        await viewModel.loadUsers()
                    }
                }
            )
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

// MARK: - Add User View

struct AddUserView: View {
    @SwiftUI.Environment(\.dismiss) private var dismiss: DismissAction

    let createUserUseCase: CreateUserUseCase
    var onUserCreated: (() -> Void)?

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var role: UserRole = .member

    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("User Information") {
                    TextField("First Name", text: $firstName)
                        .textContentType(.givenName)
                        .autocorrectionDisabled()
                    TextField("Last Name", text: $lastName)
                        .textContentType(.familyName)
                        .autocorrectionDisabled()
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                }

                Section("Role") {
                    Picker("Role", selection: $role) {
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
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            Task {
                                await saveUser()
                            }
                        }
                        .disabled(email.isEmpty || password.isEmpty)
                    }
                }
            }
            .disabled(isSaving)
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func saveUser() async {
        isSaving = true
        defer { isSaving = false }

        let request = CreateUserRequest(
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password,
            firstName: firstName.isEmpty ? nil : firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: lastName.isEmpty ? nil : lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            role: role,
            organizationId: nil
        )

        do {
            _ = try await createUserUseCase.execute(request)
            onUserCreated?()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Preview

#Preview {
    UsersNavigationView()
        .environmentObject(DIContainer())
}
