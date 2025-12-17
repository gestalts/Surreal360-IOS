import SwiftUI

struct ContactDetailView: View {
    let contact: Contact360
    @State private var selectedTab = 0
    @State private var showingActiveCall = false
    @State private var showingMessageCompose = false
    @SwiftUI.Environment(\.dismiss) private var dismiss
    @EnvironmentObject var container: DIContainer

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header Section
                headerSection
                    .padding()
                    .background(Color(.systemBackground))

                Divider()

                // Tags Section
                if !contact.tags.isEmpty {
                    tagsSection
                        .padding()
                }

                // Tab Selector
                Picker("", selection: $selectedTab) {
                    Text("Overview").tag(0)
                    Text("Activity").tag(1)
                    Text("Notes").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                // Tab Content
                Group {
                    switch selectedTab {
                    case 0:
                        overviewTab
                    case 1:
                        activityTab
                    case 2:
                        notesTab
                    default:
                        EmptyView()
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { shareContact() }) {
                        Label("Share Contact", systemImage: "square.and.arrow.up")
                    }
                    Button(action: { editContact() }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: { deleteContact() }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .fullScreenCover(isPresented: $showingActiveCall) {
            ActiveCallView(viewModel: container.makeCallViewModel())
        }
        .sheet(isPresented: $showingMessageCompose) {
            NavigationStack {
                ConversationDetailView(viewModel: container.makeConversationViewModel())
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Avatar and Name
            HStack(spacing: 16) {
                // Avatar
                if let avatarUrl = contact.avatar {
                    AsyncImage(url: avatarUrl) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        avatarPlaceholder
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                } else {
                    avatarPlaceholder
                        .frame(width: 80, height: 80)
                }

                // Name and Title
                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.displayName)
                        .font(.title2)
                        .fontWeight(.semibold)

                    if let jobTitle = contact.jobTitle {
                        HStack(spacing: 4) {
                            Image(systemName: "briefcase.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(jobTitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    if let company = contact.company {
                        HStack(spacing: 4) {
                            Image(systemName: "building.2.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(company)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    if let email = contact.primaryEmail {
                        HStack(spacing: 4) {
                            Image(systemName: "envelope.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(email)
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }

                    if let phone = contact.primaryPhone {
                        HStack(spacing: 4) {
                            Image(systemName: "phone.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(phone)
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                }

                Spacer()

                // Favorite Star
                Button(action: { toggleFavorite() }) {
                    Image(systemName: contact.isFavorite ? "star.fill" : "star")
                        .font(.title3)
                        .foregroundColor(contact.isFavorite ? .yellow : .gray)
                }
            }

            // Action Buttons
            actionButtons
        }
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Circle()
                .fill(contact.avatarColor.gradient)

            Text(contact.initials)
                .font(.largeTitle)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Call button - always visible
            ActionButton(
                icon: "phone.fill",
                title: "Call",
                color: contact.primaryPhone != nil ? .green : .gray,
                action: {
                    if let phone = contact.primaryPhone {
                        callPhone(phone)
                    }
                }
            )
            .disabled(contact.primaryPhone == nil)

            // Message button - always visible
            ActionButton(
                icon: "message.fill",
                title: "Message",
                color: contact.primaryPhone != nil ? .blue : .gray,
                action: {
                    if let phone = contact.primaryPhone {
                        messagePhone(phone)
                    }
                }
            )
            .disabled(contact.primaryPhone == nil)

            // Email button - always visible
            ActionButton(
                icon: "envelope.fill",
                title: "Email",
                color: contact.primaryEmail != nil ? .orange : .gray,
                action: {
                    if let email = contact.primaryEmail {
                        openEmail(email)
                    }
                }
            )
            .disabled(contact.primaryEmail == nil)

            // Video button
            ActionButton(
                icon: "video.fill",
                title: "Video",
                color: .purple,
                action: { startVideoCall() }
            )
        }
    }

    // MARK: - Tags Section

    private var tagsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(contact.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - Overview Tab

    private var overviewTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Contact Information
            if !contact.emails.isEmpty || !contact.phones.isEmpty {
                contactInformationSection
            }

            // Dates
            datesSection
        }
    }

    private var contactInformationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Contact Information")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 12) {
                // Emails
                ForEach(contact.emails) { email in
                    ContactInfoRow(
                        icon: "envelope.fill",
                        label: email.label,
                        value: email.email,
                        isPrimary: email.isPrimary,
                        action: { openEmail(email.email) }
                    )
                }

                // Phones
                ForEach(contact.phones) { phone in
                    ContactInfoRow(
                        icon: "phone.fill",
                        label: phone.label,
                        value: phone.phone,
                        isPrimary: phone.isPrimary,
                        action: { callPhone(phone.phone) }
                    )
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }

    private var datesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Important Dates")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 12) {
                HStack {
                    Label("Created", systemImage: "calendar.badge.plus")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(contact.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                }

                Divider()

                HStack {
                    Label("Last Updated", systemImage: "calendar.badge.clock")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(contact.updatedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }

    // MARK: - Activity Tab

    private var activityTab: some View {
        TimelineView(contactId: contact.id, container: container)
            .frame(minHeight: 400)
    }

    // MARK: - Notes Tab

    private var notesTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let notes = contact.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.headline)

                    Text(notes)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "note.text")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("No Notes")
                        .font(.headline)

                    Text("Add notes to remember important details about this contact")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button(action: { addNote() }) {
                        Label("Add Note", systemImage: "plus")
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
    }

    // MARK: - Actions

    private func shareContact() {
        print("Share contact: \(contact.displayName)")
    }

    private func editContact() {
        print("Edit contact: \(contact.displayName)")
    }

    private func deleteContact() {
        print("Delete contact: \(contact.displayName)")
    }

    private func toggleFavorite() {
        print("Toggle favorite for: \(contact.displayName)")
    }

    private func openEmail(_ email: String) {
        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
        }
    }

    private func callPhone(_ phone: String) {
        // Use Twilio for calling via the app
        let callViewModel = container.makeCallViewModel()
        callViewModel.makeCall(to: phone, contactName: contact.displayName)
        showingActiveCall = true
    }

    private func messagePhone(_ phone: String) {
        // Open SMS compose view for this contact
        let conversationViewModel = container.makeConversationViewModel()
        conversationViewModel.startNewConversation(to: phone)
        showingMessageCompose = true
    }

    private func startVideoCall() {
        print("Start video call with: \(contact.displayName)")
    }

    private func addNote() {
        print("Add note for: \(contact.displayName)")
    }
}

// MARK: - Supporting Views

struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(color.gradient)
                    .clipShape(Circle())

                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct ContactInfoRow: View {
    let icon: String
    let label: String
    let value: String
    let isPrimary: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(.blue)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(label)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if isPrimary {
                            Text("PRIMARY")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .cornerRadius(4)
                        }
                    }

                    Text(value)
                        .font(.body)
                        .foregroundColor(.primary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ContactDetailView(
            contact: Contact360(
                id: "1",
                firstName: "John",
                lastName: "Doe",
                company: "Acme Inc",
                jobTitle: "Software Engineer",
                emails: [
                    ContactEmail(email: "john.doe@acme.com", label: "Work", isPrimary: true),
                    ContactEmail(email: "john@personal.com", label: "Personal", isPrimary: false)
                ],
                phones: [
                    ContactPhone(phone: "+1 (555) 123-4567", label: "Mobile", isPrimary: true),
                    ContactPhone(phone: "+1 (555) 987-6543", label: "Work", isPrimary: false)
                ],
                avatar: nil,
                notes: "Met at Tech Conference 2024. Interested in collaboration on AI projects.",
                isFavorite: true,
                tags: ["VIP", "Tech", "Partner"],
                createdAt: Date().addingTimeInterval(-86400 * 30),
                updatedAt: Date()
            )
        )
    }
}
