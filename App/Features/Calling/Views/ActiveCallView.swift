import SwiftUI

/// View displayed during an active phone call
struct ActiveCallView: View {
    @ObservedObject var viewModel: CallViewModel
    @SwiftUI.Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.gray.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Caller info
                callerInfoSection

                Spacer()

                // Call status
                if let call = viewModel.activeCall {
                    statusSection(for: call)
                }

                Spacer()

                // Call controls
                controlsSection

                Spacer()
                    .frame(height: 40)

                // End call button
                endCallButton

                Spacer()
                    .frame(height: 60)
            }
        }
        .onChange(of: viewModel.activeCall) { _, newValue in
            if newValue == nil {
                dismiss()
            }
        }
    }

    // MARK: - Subviews

    private var callerInfoSection: some View {
        VStack(spacing: 12) {
            // Avatar placeholder
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 120, height: 120)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white.opacity(0.7))
                )

            // Name/Number
            if let call = viewModel.activeCall {
                Text(call.displayName)
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                if call.contactName != nil {
                    Text(call.phoneNumber)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }

    private func statusSection(for call: ActiveCallState) -> some View {
        VStack(spacing: 8) {
            Text(call.status.displayText)
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))

            if call.status == .connected {
                Text(formatDuration(call.duration))
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .monospacedDigit()
            }
        }
    }

    private var controlsSection: some View {
        HStack(spacing: 40) {
            // Mute button
            CallControlButton(
                icon: viewModel.isMuted ? "mic.slash.fill" : "mic.fill",
                label: "Mute",
                isActive: viewModel.isMuted
            ) {
                viewModel.toggleMute()
            }

            // Keypad button
            CallControlButton(
                icon: "circle.grid.3x3.fill",
                label: "Keypad",
                isActive: false
            ) {
                // Show keypad
            }

            // Speaker button
            CallControlButton(
                icon: viewModel.isSpeakerOn ? "speaker.wave.3.fill" : "speaker.fill",
                label: "Speaker",
                isActive: viewModel.isSpeakerOn
            ) {
                viewModel.toggleSpeaker()
            }
        }
    }

    private var endCallButton: some View {
        Button {
            viewModel.endCall()
        } label: {
            Circle()
                .fill(Color.red)
                .frame(width: 72, height: 72)
                .overlay(
                    Image(systemName: "phone.down.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(135))
                )
        }
    }

    // MARK: - Helpers

    private func formatDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60

        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return String(format: "%d:%02d:%02d", hours, remainingMinutes, seconds)
        }

        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Call Control Button

struct CallControlButton: View {
    let icon: String
    let label: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(isActive ? Color.white : Color.white.opacity(0.2))
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundColor(isActive ? .black : .white)
                    )

                Text(label)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

// MARK: - Call History View

struct CallHistoryView: View {
    @ObservedObject var viewModel: CallViewModel

    var body: some View {
        List {
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if viewModel.callHistory.isEmpty {
                ContentUnavailableView(
                    "No Calls",
                    systemImage: "phone.badge.plus",
                    description: Text("Your call history will appear here")
                )
            } else {
                ForEach(viewModel.callHistory) { call in
                    CallHistoryRow(call: call)
                }
            }
        }
        .navigationTitle("Call History")
        .task {
            await viewModel.loadCallHistory()
        }
        .refreshable {
            await viewModel.loadCallHistory()
        }
    }
}

// MARK: - Call History Row

struct CallHistoryRow: View {
    let call: PhoneCall

    var body: some View {
        HStack(spacing: 12) {
            // Direction indicator
            Image(systemName: call.direction.iconName)
                .foregroundColor(call.isMissed ? .red : (call.direction == .inbound ? .green : .blue))
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(call.displayNumber)
                    .font(.headline)

                HStack(spacing: 4) {
                    Text(call.status.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let duration = call.duration, duration > 0 {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(call.formattedDuration)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(call.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(call.createdAt, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ActiveCallView(viewModel: CallViewModel())
}
