import Foundation
import PushKit
import TwilioVoice
import CallKit

/// Handles VoIP push notifications for incoming Twilio calls
final class VoIPPushService: NSObject {

    // MARK: - Properties

    private let pushRegistry: PKPushRegistry
    private var deviceToken: String?

    var callManager: CallManager?
    var twilioService: TwilioService?

    var onTokenRegistered: ((String) -> Void)?

    // MARK: - Initialization

    override init() {
        pushRegistry = PKPushRegistry(queue: .main)
        super.init()
    }

    // MARK: - Registration

    /// Alias for registerForVoIPPush for convenience
    func start() {
        registerForVoIPPush()
    }

    func registerForVoIPPush() {
        pushRegistry.delegate = self
        pushRegistry.desiredPushTypes = [.voIP]
    }

    func unregisterFromVoIPPush() {
        pushRegistry.desiredPushTypes = []
    }

    // MARK: - Token Management

    func sendTokenToBackend(_ token: String) async throws {
        guard let authToken = try await twilioService?.fetchAccessToken() else {
            print("Cannot register push token - not authenticated")
            return
        }

        let url = Environment.backendURL.appendingPathComponent("api/twilio/device/register/")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Token \(authToken)", forHTTPHeaderField: "Authorization")

        let body = ["device_token": token, "platform": "ios"]
        request.httpBody = try JSONEncoder().encode(body)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("Failed to register device token with backend")
            return
        }

        print("Successfully registered VoIP push token with backend")
    }
}

// MARK: - PKPushRegistryDelegate

extension VoIPPushService: PKPushRegistryDelegate {

    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        guard type == .voIP else { return }

        let token = pushCredentials.token.map { String(format: "%02x", $0) }.joined()
        deviceToken = token

        print("VoIP Push Token: \(token)")

        onTokenRegistered?(token)

        Task {
            try? await sendTokenToBackend(token)
        }
    }

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        guard type == .voIP else {
            completion()
            return
        }

        print("Received VoIP push: \(payload.dictionaryPayload)")

        // Parse the Twilio push notification
        TwilioVoiceSDK.handleNotification(payload.dictionaryPayload, delegate: self, delegateQueue: .main)

        completion()
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        guard type == .voIP else { return }

        deviceToken = nil
        print("VoIP push token invalidated")
    }
}

// MARK: - NotificationDelegate

extension VoIPPushService: NotificationDelegate {

    func callInviteReceived(callInvite: CallInvite) {
        print("Incoming call from: \(callInvite.from ?? "Unknown")")

        callManager?.handleIncomingCallInvite(callInvite)
    }

    func cancelledCallInviteReceived(cancelledCallInvite: CancelledCallInvite, error: Error) {
        print("Call invite cancelled: \(error.localizedDescription)")

        // Report call ended if it was being shown
        if let uuid = callManager?.activeCallUUID {
            callManager?.reportCallEnded(uuid: uuid, reason: .remoteEnded)
        }
    }
}

// MARK: - Extension for activeCallUUID access

extension CallManager {
    var activeCallUUID: UUID? {
        // This would need to be exposed from CallManager
        // For now, we rely on the callback system
        return nil
    }
}
