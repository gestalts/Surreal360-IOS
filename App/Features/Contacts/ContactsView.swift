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
                AddContactView()
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

// MARK: - Add Contact View (Placeholder)

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
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveContact()
                    }
                    .disabled(firstName.isEmpty && lastName.isEmpty && company.isEmpty)
                }
            }
        }
    }

    private func saveContact() {
        // TODO: Implement save logic with CreateContactUseCase
        dismiss()
    }
}



// MARK: - Preview

#Preview {
    ContactsNavigationView()
        .environmentObject(DIContainer())
}