import SwiftUI

/// Chat-style view showing messages in a conversation
struct ConversationDetailView: View {
    @ObservedObject var viewModel: ConversationViewModel
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            messagesScrollView

            Divider()

            // Input area
            messageInputView
        }
        .navigationTitle(viewModel.currentConversation?.displayName ?? "Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if let phone = viewModel.currentConversation?.phoneNumber {
                    Button {
                        // Call action - would integrate with CallViewModel
                        if let url = URL(string: "tel:\(phone)") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Image(systemName: "phone.fill")
                    }
                }
            }
        }
        .task {
            if let phone = viewModel.currentConversation?.phoneNumber {
                await viewModel.loadConversation(with: phone)
            }
        }
        .onDisappear {
            viewModel.clearCurrentConversation()
        }
    }

    // MARK: - Messages List

    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                withAnimation {
                    if let lastMessage = viewModel.messages.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Message Input

    private var messageInputView: some View {
        HStack(spacing: 12) {
            TextField("Message", text: $viewModel.draftMessage.body, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...5)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .focused($isInputFocused)

            Button {
                Task {
                    await viewModel.sendMessage()
                }
            } label: {
                Image(systemName: viewModel.isSending ? "hourglass" : "arrow.up.circle.fill")
                    .font(.title)
                    .foregroundColor(sendButtonColor)
            }
            .disabled(!canSend)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    private var canSend: Bool {
        !viewModel.draftMessage.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isSending
    }

    private var sendButtonColor: Color {
        canSend ? .blue : .gray
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: SMSMessage

    private var isOutbound: Bool {
        message.direction == .outbound
    }

    var body: some View {
        HStack {
            if isOutbound { Spacer(minLength: 60) }

            VStack(alignment: isOutbound ? .trailing : .leading, spacing: 4) {
                Text(message.body)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(bubbleColor)
                    .foregroundColor(textColor)
                    .clipShape(BubbleShape(isOutbound: isOutbound))

                HStack(spacing: 4) {
                    Text(message.createdAt, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    if isOutbound {
                        statusIcon
                    }
                }
            }

            if !isOutbound { Spacer(minLength: 60) }
        }
    }

    private var bubbleColor: Color {
        isOutbound ? .blue : Color(.systemGray5)
    }

    private var textColor: Color {
        isOutbound ? .white : .primary
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch message.status {
        case .sent, .delivered, .read:
            Image(systemName: message.status == .delivered || message.status == .read ? "checkmark.circle.fill" : "checkmark")
                .font(.caption2)
                .foregroundColor(message.status == .read ? .blue : .secondary)
        case .failed, .undelivered:
            Image(systemName: "exclamationmark.circle.fill")
                .font(.caption2)
                .foregroundColor(.red)
        default:
            Image(systemName: "clock")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Bubble Shape

struct BubbleShape: Shape {
    let isOutbound: Bool

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 16
        let tailSize: CGFloat = 6

        var path = Path()

        if isOutbound {
            // Outbound bubble (right side, tail on right)
            path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + radius),
                             control: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
            path.addQuadCurve(to: CGPoint(x: rect.maxX - radius + tailSize, y: rect.maxY),
                             control: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
            path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - radius),
                             control: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            path.addQuadCurve(to: CGPoint(x: rect.minX + radius, y: rect.minY),
                             control: CGPoint(x: rect.minX, y: rect.minY))
        } else {
            // Inbound bubble (left side, tail on left)
            path.move(to: CGPoint(x: rect.minX + radius - tailSize, y: rect.maxY))
            path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - radius),
                             control: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            path.addQuadCurve(to: CGPoint(x: rect.minX + radius, y: rect.minY),
                             control: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + radius),
                             control: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
            path.addQuadCurve(to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
                             control: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + radius - tailSize, y: rect.maxY))
        }

        path.closeSubpath()
        return path
    }
}

#Preview {
    NavigationStack {
        ConversationDetailView(
            viewModel: ConversationViewModel(
                smsService: PreviewSMSService()
            )
        )
    }
}

// MARK: - Preview Helper

private class PreviewSMSService: SMSServiceProtocol {
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
