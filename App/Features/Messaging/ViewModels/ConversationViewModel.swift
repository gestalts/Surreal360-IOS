import Foundation
import SwiftUI
import Combine

/// ViewModel for managing SMS conversations and messages
@MainActor
final class ConversationViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var conversations: [SMSConversation] = []
    @Published var currentConversation: SMSConversation?
    @Published var messages: [SMSMessage] = []

    @Published var draftMessage = DraftMessage()
    @Published var isSending = false
    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Services

    private let smsService: SMSServiceProtocol

    // MARK: - Initialization

    init(smsService: SMSServiceProtocol) {
        self.smsService = smsService
    }

    // MARK: - Conversation List

    func loadConversations() async {
        isLoading = true
        error = nil

        do {
            conversations = try await smsService.fetchConversations()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Single Conversation

    func loadConversation(with phoneNumber: String) async {
        isLoading = true
        error = nil

        do {
            messages = try await smsService.fetchConversation(with: phoneNumber)

            // Update or create current conversation
            if let existing = conversations.first(where: { $0.phoneNumber == phoneNumber }) {
                currentConversation = existing
            } else {
                currentConversation = SMSConversation(
                    id: phoneNumber,
                    phoneNumber: phoneNumber,
                    lastMessage: messages.last?.body ?? "",
                    lastMessageDate: messages.last?.createdAt ?? Date(),
                    messages: messages
                )
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func selectConversation(_ conversation: SMSConversation) {
        currentConversation = conversation
        messages = conversation.messages
        draftMessage = DraftMessage(to: conversation.phoneNumber)
    }

    func clearCurrentConversation() {
        currentConversation = nil
        messages = []
        draftMessage = DraftMessage()
    }

    // MARK: - Send Message

    func sendMessage() async {
        guard draftMessage.isValid else { return }

        isSending = true
        error = nil

        let messageBody = draftMessage.body
        let toNumber = draftMessage.to

        // Clear draft immediately for better UX
        draftMessage.body = ""

        do {
            let sentMessage = try await smsService.sendMessage(to: toNumber, body: messageBody)

            // Add to current messages
            messages.append(sentMessage)

            // Update conversation
            if var conversation = currentConversation {
                conversation.lastMessage = sentMessage.body
                conversation.lastMessageDate = sentMessage.createdAt
                conversation.messages = messages
                currentConversation = conversation

                // Update in list
                if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
                    conversations[index] = conversation
                }
            }
        } catch {
            self.error = error.localizedDescription
            // Restore draft on failure
            draftMessage.body = messageBody
        }

        isSending = false
    }

    func sendMessage(to phoneNumber: String, body: String) async {
        draftMessage = DraftMessage(to: phoneNumber, body: body)
        await sendMessage()
    }

    // MARK: - New Conversation

    func startNewConversation(to phoneNumber: String) {
        let newConversation = SMSConversation(
            id: phoneNumber,
            phoneNumber: phoneNumber,
            lastMessage: "",
            lastMessageDate: Date(),
            messages: []
        )

        currentConversation = newConversation
        messages = []
        draftMessage = DraftMessage(to: phoneNumber)
    }

    // MARK: - Refresh

    func refreshCurrentConversation() async {
        guard let phoneNumber = currentConversation?.phoneNumber else { return }
        await loadConversation(with: phoneNumber)
    }

    func refreshConversations() async {
        await loadConversations()
    }
}
