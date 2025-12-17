import SwiftUI

/// List view showing all SMS conversations
struct ConversationsListView: View {
    @ObservedObject var viewModel: ConversationViewModel
    @State private var showingNewMessage = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.conversations.isEmpty {
                    ProgressView("Loading conversations...")
                } else if viewModel.conversations.isEmpty {
                    emptyStateView
                } else {
                    conversationsList
                }
            }
            .navigationTitle("Messages")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewMessage = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showingNewMessage) {
                NewMessageView(viewModel: viewModel)
            }
            .task {
                await viewModel.loadConversations()
            }
            .refreshable {
                await viewModel.refreshConversations()
            }
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Messages",
            systemImage: "message.badge.filled.fill",
            description: Text("Start a conversation by tapping the compose button")
        )
    }

    private var conversationsList: some View {
        List {
            ForEach(viewModel.conversations) { conversation in
                NavigationLink {
                    ConversationDetailView(viewModel: viewModel)
                        .onAppear {
                            viewModel.selectConversation(conversation)
                        }
                } label: {
                    ConversationRow(conversation: conversation)
                }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Conversation Row

struct ConversationRow: View {
    let conversation: SMSConversation

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(initials)
                        .font(.headline)
                        .foregroundColor(.blue)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.displayName)
                        .font(.headline)
                        .lineLimit(1)

                    Spacer()

                    Text(conversation.lastMessageDate, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text(conversation.lastMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    Spacer()

                    if conversation.hasUnreadMessages {
                        Text("\(conversation.unreadCount)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var initials: String {
        if let name = conversation.contactName {
            let components = name.split(separator: " ")
            let first = components.first?.first.map(String.init) ?? ""
            let last = components.dropFirst().first?.first.map(String.init) ?? ""
            return (first + last).uppercased()
        }
        return "#"
    }
}

// MARK: - New Message View

struct NewMessageView: View {
    @ObservedObject var viewModel: ConversationViewModel
    @SwiftUI.Environment(\.dismiss) private var dismiss

    @State private var phoneNumber = ""
    @State private var messageBody = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                }

                Section {
                    TextField("Message", text: $messageBody, axis: .vertical)
                        .lineLimit(5...10)
                }
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        Task {
                            await sendMessage()
                        }
                    }
                    .disabled(!isValid || viewModel.isSending)
                }
            }
        }
    }

    private var isValid: Bool {
        !phoneNumber.isEmpty && !messageBody.isEmpty
    }

    private func sendMessage() async {
        await viewModel.sendMessage(to: phoneNumber, body: messageBody)
        if viewModel.error == nil {
            dismiss()
        }
    }
}

#Preview {
    ConversationsListView(
        viewModel: ConversationViewModel(
            smsService: PreviewSMSServiceForList()
        )
    )
}

// MARK: - Preview Helper

private class PreviewSMSServiceForList: SMSServiceProtocol {
    func sendMessage(to phoneNumber: String, body: String) async throws -> SMSMessage {
        SMSMessage(
            sid: "SM123",
            fromNumber: "+1234567890",
            toNumber: phoneNumber,
            body: body,
            direction: .outbound,
            status: .sent
        )
    }

    func fetchMessages(contactId: String?) async throws -> [SMSMessage] {
        []
    }

    func fetchConversations() async throws -> [SMSConversation] {
        []
    }

    func fetchConversation(with phoneNumber: String) async throws -> [SMSMessage] {
        []
    }
}
