import Foundation
import CallKit
import TwilioVoice
import AVFoundation

/// Manages CallKit integration for Twilio Voice calls
final class CallManager: NSObject {

    // MARK: - Properties

    private let callController = CXCallController()
    private let provider: CXProvider

    private var currentCall: Call?
    private var currentCallInvite: CallInvite?
    private var currentUUID: UUID?

    var twilioService: TwilioService?

    // Callbacks
    var onIncomingCall: ((UUID, String) -> Void)?
    var onCallConnected: ((UUID) -> Void)?
    var onCallEnded: ((UUID) -> Void)?
    var onCallFailed: ((UUID, Error) -> Void)?

    // MARK: - Initialization

    override init() {
        let configuration = CXProviderConfiguration()
        configuration.maximumCallGroups = 1
        configuration.maximumCallsPerCallGroup = 1
        configuration.supportsVideo = false
        configuration.supportedHandleTypes = [.phoneNumber]
        configuration.iconTemplateImageData = nil // Could add app icon here

        provider = CXProvider(configuration: configuration)

        super.init()

        provider.setDelegate(self, queue: .main)
    }

    // MARK: - Outgoing Calls

    func startCall(to phoneNumber: String, uuid: UUID) {
        currentUUID = uuid

        let handle = CXHandle(type: .phoneNumber, value: phoneNumber)
        let startCallAction = CXStartCallAction(call: uuid, handle: handle)

        let transaction = CXTransaction(action: startCallAction)
        callController.request(transaction) { [weak self] error in
            if let error = error {
                print("Failed to start call: \(error.localizedDescription)")
                self?.onCallFailed?(uuid, error)
            } else {
                print("Call started successfully")
            }
        }
    }

    func reportOutgoingCallConnected(uuid: UUID) {
        provider.reportOutgoingCall(with: uuid, connectedAt: Date())
    }

    // MARK: - Incoming Calls

    func reportIncomingCall(uuid: UUID, caller: String, completion: @escaping (Error?) -> Void) {
        currentUUID = uuid

        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .phoneNumber, value: caller)
        update.hasVideo = false
        update.localizedCallerName = caller

        provider.reportNewIncomingCall(with: uuid, update: update) { [weak self] error in
            if let error = error {
                print("Failed to report incoming call: \(error.localizedDescription)")
            } else {
                self?.onIncomingCall?(uuid, caller)
            }
            completion(error)
        }
    }

    func handleIncomingCallInvite(_ callInvite: CallInvite) {
        currentCallInvite = callInvite

        let uuid = UUID()
        let caller = callInvite.from ?? "Unknown"

        reportIncomingCall(uuid: uuid, caller: caller) { error in
            if error != nil {
                callInvite.reject()
            }
        }
    }

    // MARK: - Call Actions

    func endCall() {
        guard let uuid = currentUUID else { return }

        let endCallAction = CXEndCallAction(call: uuid)
        let transaction = CXTransaction(action: endCallAction)

        callController.request(transaction) { error in
            if let error = error {
                print("Failed to end call: \(error.localizedDescription)")
            }
        }
    }

    func setMuted(_ muted: Bool) {
        guard let uuid = currentUUID else { return }

        let muteAction = CXSetMutedCallAction(call: uuid, muted: muted)
        let transaction = CXTransaction(action: muteAction)

        callController.request(transaction) { error in
            if let error = error {
                print("Failed to mute call: \(error.localizedDescription)")
            }
        }
    }

    func setHeld(_ held: Bool) {
        guard let uuid = currentUUID else { return }

        let holdAction = CXSetHeldCallAction(call: uuid, onHold: held)
        let transaction = CXTransaction(action: holdAction)

        callController.request(transaction) { error in
            if let error = error {
                print("Failed to hold call: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Call State

    func reportCallEnded(uuid: UUID, reason: CXCallEndedReason) {
        provider.reportCall(with: uuid, endedAt: Date(), reason: reason)
        cleanup()
    }

    private func cleanup() {
        currentCall = nil
        currentCallInvite = nil
        currentUUID = nil
    }
}

// MARK: - CXProviderDelegate

extension CallManager: CXProviderDelegate {

    func providerDidReset(_ provider: CXProvider) {
        print("CallKit provider did reset")
        twilioService?.endCall()
        cleanup()
    }

    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        print("CallKit: Start call action")

        // Configure audio session
        configureAudioSession()

        // Make the Twilio call asynchronously
        Task {
            do {
                try await twilioService?.makeCall(to: action.handle.value)
            } catch {
                print("Failed to make call: \(error.localizedDescription)")
            }
        }

        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        print("CallKit: Answer call action")

        // Configure audio session
        configureAudioSession()

        // Accept the Twilio call invite
        if let callInvite = currentCallInvite {
            let acceptOptions = AcceptOptions(callInvite: callInvite) { builder in
                builder.uuid = action.callUUID
            }
            currentCall = callInvite.accept(options: acceptOptions, delegate: twilioService!)
        }

        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        print("CallKit: End call action")

        twilioService?.endCall()
        currentCallInvite?.reject()

        if let uuid = currentUUID {
            onCallEnded?(uuid)
        }

        cleanup()
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        print("CallKit: Set muted action - \(action.isMuted)")

        twilioService?.toggleMute()
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        print("CallKit: Set held action - \(action.isOnHold)")

        // Twilio doesn't natively support hold, but we can mute audio
        if action.isOnHold {
            twilioService?.toggleMute()
        }
        action.fulfill()
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        print("CallKit: Audio session activated")
        if let audioDevice = TwilioVoiceSDK.audioDevice as? DefaultAudioDevice {
            audioDevice.isEnabled = true
        }
    }

    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        print("CallKit: Audio session deactivated")
        if let audioDevice = TwilioVoiceSDK.audioDevice as? DefaultAudioDevice {
            audioDevice.isEnabled = false
        }
    }

    // MARK: - Audio Configuration

    private func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetoothA2DP, .defaultToSpeaker])
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error.localizedDescription)")
        }
    }
}
