import SwiftUI

struct UserDetailView: View {
    @EnvironmentObject var container: DIContainer
    @SwiftUI.Environment(\.dismiss) private var dismiss: DismissAction

    @State var user: User
    @State private var showingEditUser = false
    @State private var showingDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var showError = false
    @State private var errorMessage = ""

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
                        showingEditUser = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .confirmationDialog(
            "Delete User",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task { await deleteUser() }
            }
        } message: {
            Text("Are you sure you want to delete \(user.fullName.isEmpty ? user.email : user.fullName)? This action cannot be undone.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingEditUser) {
            EditUserView(
                user: user,
                updateUserUseCase: container.makeUpdateUserUseCase(),
                onUserUpdated: { updatedUser in
                    user = updatedUser
                }
            )
        }
        .overlay {
            if isDeleting {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                ProgressView("Deleting...")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func deleteUser() async {
        isDeleting = true
        defer { isDeleting = false }

        do {
            let deleteUseCase = container.makeDeleteUserUseCase()
            try await deleteUseCase.execute(id: user.id)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
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

// MARK: - Edit User View

struct EditUserView: View {
    @SwiftUI.Environment(\.dismiss) private var dismiss: DismissAction

    let user: User
    let updateUserUseCase: UpdateUserUseCase
    var onUserUpdated: ((User) -> Void)?

    @State private var firstName: String
    @State private var lastName: String
    @State private var role: UserRole
    @State private var status: UserStatus

    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""

    init(user: User, updateUserUseCase: UpdateUserUseCase, onUserUpdated: ((User) -> Void)? = nil) {
        self.user = user
        self.updateUserUseCase = updateUserUseCase
        self.onUserUpdated = onUserUpdated
        _firstName = State(initialValue: user.firstName ?? "")
        _lastName = State(initialValue: user.lastName ?? "")
        _role = State(initialValue: user.role)
        _status = State(initialValue: user.status)
    }

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
                }

                Section("Role") {
                    Picker("Role", selection: $role) {
                        ForEach(UserRole.commonRoles, id: \.self) { role in
                            Text(role.displayName).tag(role)
                        }
                    }
                }

                Section("Status") {
                    Picker("Status", selection: $status) {
                        Text("Active").tag(UserStatus.active)
                        Text("Pending").tag(UserStatus.pending)
                        Text("Banned").tag(UserStatus.banned)
                        Text("Rejected").tag(UserStatus.rejected)
                    }
                }
            }
            .navigationTitle("Edit User")
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
                            Task { await saveUser() }
                        }
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

        let request = UpdateUserRequest(
            firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            role: role,
            status: status,
            organizationId: user.organizationId
        )

        do {
            let updatedUser = try await updateUserUseCase.execute(id: user.id, data: request)
            onUserUpdated?(updatedUser)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
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
        .environmentObject(DIContainer())
    }
}
