import SwiftUI

struct ContactsNavigationView: View {
    @EnvironmentObject var container: DIContainer

    var body: some View {
        NavigationStack {
            ContactsListView(container: container)
                .environmentObject(container)
        }
    }
}

struct ContactsListView: View {
    @EnvironmentObject var container: DIContainer
    @StateObject private var viewModel: ContactsViewModel
    @State private var showingAddContact = false
    @State private var searchText = ""

    init(container: DIContainer) {
        _viewModel = StateObject(wrappedValue: ContactsViewModel(
            getContactsUseCase: container.makeGetContactsUseCase(),
            deleteContactUseCase: container.makeDeleteContactUseCase()
        ))
    }

    var body: some View {
        contactsList
            .navigationTitle("Contacts")
            .searchable(text: $searchText, prompt: "Search contacts")
            .toolbar { toolbarContent }
            .refreshable { await viewModel.refreshContacts() }
            .overlay { overlayContent }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .sheet(isPresented: $showingAddContact) {
                AddContactView(
                    createContactUseCase: container.makeCreateContactUseCase(),
                    onContactCreated: {
                        Task { await viewModel.loadContacts() }
                    }
                )
            }
            .task { await viewModel.loadContacts() }
            .onChange(of: searchText) { _, newValue in
                viewModel.searchQuery = newValue
            }
    }

    private var contactsList: some View {
        List {
            ForEach(viewModel.filteredContacts) { contact in
                NavigationLink(destination: ContactDetailView(contact: contact)) {
                    ContactRowView(contact: contact)
                }
            }
            .onDelete(perform: deleteContacts)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                showingAddContact = true
            } label: {
                Image(systemName: "plus")
            }
        }
    }

    @ViewBuilder
    private var overlayContent: some View {
        if viewModel.isLoading && viewModel.contacts.isEmpty {
            ProgressView()
        } else if viewModel.contacts.isEmpty {
            ContactsEmptyStateView()
        }
    }
    
    private func deleteContacts(offsets: IndexSet) {
        for index in offsets {
            let contact = viewModel.filteredContacts[index]
            viewModel.deleteContact(contact)
        }
    }
}

// MARK: - Contact Row View

struct ContactRowView: View {
    let contact: Contact360

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(contact.avatarColor.gradient)
                    .frame(width: 44, height: 44)

                if let avatar = contact.avatar {
                    AsyncImage(url: avatar) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Text(contact.initials)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                } else {
                    Text(contact.initials)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }

            // Contact Info
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.displayName)
                    .font(.body)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    if let company = contact.company, !company.isEmpty {
                        Text(company)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let company = contact.company, !company.isEmpty,
                       let jobTitle = contact.jobTitle, !jobTitle.isEmpty {
                        Text("•")
                            .foregroundColor(.secondary)
                    }
                    
                    if let jobTitle = contact.jobTitle, !jobTitle.isEmpty {
                        Text(jobTitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if let email = contact.primaryEmail {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            Spacer()

            // Favorite indicator
            if contact.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Empty State View

struct ContactsEmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.plus")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundStyle(.gray.gradient)

            VStack(spacing: 8) {
                Text("No Contacts")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Add your first contact to get started")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Add Contact View

struct AddContactView: View {
    @SwiftUI.Environment(\.dismiss) private var dismiss
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var company = ""
    @State private var jobTitle = ""
    @State private var notes = ""
    @State private var isFavorite = false
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""

    private let createContactUseCase: CreateContactUseCase
    var onContactCreated: (() -> Void)?

    init(createContactUseCase: CreateContactUseCase, onContactCreated: (() -> Void)? = nil) {
        self.createContactUseCase = createContactUseCase
        self.onContactCreated = onContactCreated
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                }

                Section("Work Information") {
                    TextField("Company", text: $company)
                    TextField("Job Title", text: $jobTitle)
                }

                Section("Additional") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                    Toggle("Favorite", isOn: $isFavorite)
                }
            }
            .navigationTitle("Add Contact")
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
                            saveContact()
                        }
                        .disabled(firstName.isEmpty && lastName.isEmpty && company.isEmpty)
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

    private func saveContact() {
        let emails: [CreateContactEmailRequest]? = email.isEmpty ? nil : [
            CreateContactEmailRequest(email: email, label: "primary", isPrimary: true)
        ]
        let phones: [CreateContactPhoneRequest]? = phone.isEmpty ? nil : [
            CreateContactPhoneRequest(phone: phone, label: "primary", isPrimary: true)
        ]
        let request = CreateContactRequest(
            firstName: firstName.isEmpty ? nil : firstName,
            lastName: lastName.isEmpty ? nil : lastName,
            company: company.isEmpty ? nil : company,
            jobTitle: jobTitle.isEmpty ? nil : jobTitle,
            emails: emails,
            phones: phones,
            notes: notes.isEmpty ? nil : notes,
            isFavorite: isFavorite,
            tags: nil
        )

        isSaving = true
        Task {
            do {
                _ = try await createContactUseCase.execute(request)
                await MainActor.run {
                    onContactCreated?()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}



// MARK: - Preview

#Preview {
    ContactsNavigationView()
        .environmentObject(DIContainer())
}