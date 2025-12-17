import Foundation
import SwiftUI
import Combine
import TwilioVoice

/// ViewModel for managing call state and UI updates
@MainActor
final class CallViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var activeCall: ActiveCallState?
    @Published var callHistory: [PhoneCall] = []
    @Published var isLoading = false
    @Published var error: String?

    // Call controls
    @Published var isMuted = false
    @Published var isSpeakerOn = false
    @Published var isOnHold = false

    // MARK: - Services

    private let twilioService: TwilioService
    private let callManager: CallManager
    private let authService: AuthenticationService

    private var durationTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(twilioService: TwilioService, callManager: CallManager, authService: AuthenticationService) {
        self.twilioService = twilioService
        self.callManager = callManager
        self.authService = authService

        setupCallbacks()
        twilioService.delegate = self
    }

    /// Convenience initializer using shared DIContainer (for standalone usage)
    /// Note: This creates a new container instance - prefer using container.makeCallViewModel() in production
    @MainActor
    convenience init() {
        let container = DIContainer()
        self.init(
            twilioService: container.twilioService,
            callManager: container.callManager,
            authService: container.authService
        )
    }

    // MARK: - Setup

    private func setupCallbacks() {
        callManager.onIncomingCall = { [weak self] uuid, caller in
            Task { @MainActor in
                self?.handleIncomingCall(uuid: uuid, caller: caller)
            }
        }

        callManager.onCallConnected = { [weak self] uuid in
            Task { @MainActor in
                self?.handleCallConnected(uuid: uuid)
            }
        }

        callManager.onCallEnded = { [weak self] uuid in
            Task { @MainActor in
                self?.handleCallEnded(uuid: uuid)
            }
        }

        callManager.onCallFailed = { [weak self] uuid, error in
            Task { @MainActor in
                self?.handleCallFailed(uuid: uuid, error: error)
            }
        }
    }

    // MARK: - Call Actions

    func makeCall(to phoneNumber: String, contactName: String? = nil) {
        let uuid = UUID()

        activeCall = ActiveCallState(
            uuid: uuid,
            phoneNumber: phoneNumber,
            contactName: contactName,
            direction: .outbound,
            status: .connecting
        )

        callManager.startCall(to: phoneNumber, uuid: uuid)
    }

    /// Alias for makeCall for convenience
    func startCall(to phoneNumber: String, contactName: String? = nil) {
        makeCall(to: phoneNumber, contactName: contactName)
    }

    func answerCall() {
        // CallKit handles this automatically via its UI
    }

    func endCall() {
        stopDurationTimer()
        callManager.endCall()
        twilioService.endCall()
        activeCall = nil
        resetCallState()
    }

    func toggleMute() {
        isMuted.toggle()
        twilioService.toggleMute()
        callManager.setMuted(isMuted)
    }

    func toggleSpeaker() {
        isSpeakerOn.toggle()
        twilioService.toggleSpeaker()
    }

    func toggleHold() {
        isOnHold.toggle()
        callManager.setHeld(isOnHold)

        if isOnHold {
            stopDurationTimer()
            activeCall?.status = .onHold
        } else {
            startDurationTimer()
            activeCall?.status = .connected
        }
    }

    func sendDTMF(_ digit: String) {
        twilioService.sendDigits(digit)
    }

    // MARK: - Call History

    func loadCallHistory() async {
        isLoading = true
        error = nil

        do {
            let calls = try await fetchCallHistory()
            callHistory = calls
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    private func fetchCallHistory() async throws -> [PhoneCall] {
        guard let token = try await authService.getAccessToken() else {
            throw TwilioError.notAuthenticated
        }

        var request = URLRequest(url: Environment.twilioCallsURL)
        request.httpMethod = "GET"
        request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw TwilioError.invalidResponse
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode([PhoneCall].self, from: data)
    }

    // MARK: - Private Helpers

    private func handleIncomingCall(uuid: UUID, caller: String) {
        activeCall = ActiveCallState(
            uuid: uuid,
            phoneNumber: caller,
            contactName: nil, // Could look up contact by phone
            direction: .inbound,
            status: .ringing
        )
    }

    private func handleCallConnected(uuid: UUID) {
        activeCall?.status = .connected
        activeCall?.startTime = Date()
        startDurationTimer()
        callManager.reportOutgoingCallConnected(uuid: uuid)
    }

    private func handleCallEnded(uuid: UUID) {
        stopDurationTimer()
        activeCall?.status = .ended

        // Brief delay to show "Call Ended" before dismissing
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            activeCall = nil
            resetCallState()
        }
    }

    private func handleCallFailed(uuid: UUID, error: Error) {
        stopDurationTimer()
        self.error = error.localizedDescription
        activeCall = nil
        resetCallState()
    }

    private func resetCallState() {
        isMuted = false
        isSpeakerOn = false
        isOnHold = false
    }

    // MARK: - Duration Timer

    private func startDurationTimer() {
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let startTime = self.activeCall?.startTime else { return }
                self.activeCall?.duration = Date().timeIntervalSince(startTime)
            }
        }
    }

    private func stopDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = nil
    }
}

// MARK: - TwilioServiceDelegate

extension CallViewModel: TwilioServiceDelegate {

    nonisolated func twilioService(_ service: TwilioService, callDidStartRinging call: Call) {
        Task { @MainActor in
            activeCall?.status = .ringing
        }
    }

    nonisolated func twilioService(_ service: TwilioService, callDidConnect call: Call) {
        Task { @MainActor in
            if let uuid = activeCall?.uuid {
                handleCallConnected(uuid: uuid)
            }
        }
    }

    nonisolated func twilioService(_ service: TwilioService, callDidDisconnect call: Call, error: Error?) {
        Task { @MainActor in
            if let uuid = activeCall?.uuid {
                handleCallEnded(uuid: uuid)
            }
        }
    }

    nonisolated func twilioService(_ service: TwilioService, callDidFailToConnect call: Call, error: Error) {
        Task { @MainActor in
            if let uuid = activeCall?.uuid {
                handleCallFailed(uuid: uuid, error: error)
            }
        }
    }

    nonisolated func twilioService(_ service: TwilioService, callDidReceiveQualityWarnings warnings: Set<NSNumber>) {
        // Handle quality warnings if needed
    }

    nonisolated func twilioService(_ service: TwilioService, didChangeMuteState isMuted: Bool) {
        Task { @MainActor in
            self.isMuted = isMuted
        }
    }

    nonisolated func twilioService(_ service: TwilioService, didChangeSpeakerState isSpeakerOn: Bool) {
        Task { @MainActor in
            self.isSpeakerOn = isSpeakerOn
        }
    }
}
