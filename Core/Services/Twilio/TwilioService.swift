import Foundation
import AVFoundation
import TwilioVoice

/// Protocol for Twilio voice service operations
protocol TwilioServiceProtocol {
    var isCallInProgress: Bool { get }
    var currentCall: Call? { get }

    func fetchAccessToken() async throws -> String
    func makeCall(to phoneNumber: String) async throws
    func endCall()
    func toggleMute()
    func toggleSpeaker()
    func sendDigits(_ digits: String)
}

/// Manages Twilio Voice SDK integration for making and receiving calls
final class TwilioService: NSObject, TwilioServiceProtocol {

    // MARK: - Properties

    private let authService: AuthenticationService
    private let baseURL: URL

    private(set) var currentCall: Call?
    private var accessToken: String?
    private var audioDevice: DefaultAudioDevice = DefaultAudioDevice()

    var isCallInProgress: Bool {
        currentCall != nil
    }

    var isMuted: Bool = false
    var isSpeakerOn: Bool = false

    weak var delegate: TwilioServiceDelegate?

    // MARK: - Initialization

    init(authService: AuthenticationService, baseURL: URL = Environment.backendURL) {
        self.authService = authService
        self.baseURL = baseURL
        super.init()

        configureAudioSession()
    }

    // MARK: - Audio Configuration

    private func configureAudioSession() {
        TwilioVoiceSDK.audioDevice = audioDevice
    }

    // MARK: - Token Management

    func fetchAccessToken() async throws -> String {
        guard let authToken = try await authService.getAccessToken() else {
            throw TwilioError.notAuthenticated
        }

        let tokenURL = baseURL.appendingPathComponent("api/twilio/voice/token/")
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "GET"
        request.setValue("Token \(authToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TwilioError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw TwilioError.tokenFetchFailed(statusCode: httpResponse.statusCode)
        }

        let tokenResponse = try JSONDecoder().decode(TwilioTokenResponse.self, from: data)
        self.accessToken = tokenResponse.token
        return tokenResponse.token
    }

    // MARK: - Call Management

    func makeCall(to phoneNumber: String) async throws {
        let token = try await fetchAccessToken()

        let connectOptions = ConnectOptions(accessToken: token) { builder in
            builder.params = ["To": phoneNumber]
        }

        await MainActor.run {
            currentCall = TwilioVoiceSDK.connect(options: connectOptions, delegate: self)
        }
    }

    func endCall() {
        currentCall?.disconnect()
        currentCall = nil
        isMuted = false
        isSpeakerOn = false
    }

    func toggleMute() {
        guard let call = currentCall else { return }
        isMuted.toggle()
        call.isMuted = isMuted
        delegate?.twilioService(self, didChangeMuteState: isMuted)
    }

    func toggleSpeaker() {
        isSpeakerOn.toggle()
        audioDevice.isEnabled = true

        do {
            let audioSession = AVAudioSession.sharedInstance()
            if isSpeakerOn {
                try audioSession.overrideOutputAudioPort(.speaker)
            } else {
                try audioSession.overrideOutputAudioPort(.none)
            }
            delegate?.twilioService(self, didChangeSpeakerState: isSpeakerOn)
        } catch {
            print("Failed to toggle speaker: \(error)")
        }
    }

    func sendDigits(_ digits: String) {
        currentCall?.sendDigits(digits)
    }
}

// MARK: - CallDelegate

extension TwilioService: CallDelegate {

    func callDidStartRinging(call: Call) {
        delegate?.twilioService(self, callDidStartRinging: call)
    }

    func callDidConnect(call: Call) {
        delegate?.twilioService(self, callDidConnect: call)
    }

    func callDidDisconnect(call: Call, error: Error?) {
        currentCall = nil
        isMuted = false
        isSpeakerOn = false
        delegate?.twilioService(self, callDidDisconnect: call, error: error)
    }

    func callDidFailToConnect(call: Call, error: Error) {
        currentCall = nil
        delegate?.twilioService(self, callDidFailToConnect: call, error: error)
    }

    func callDidReceiveQualityWarnings(call: Call, currentWarnings: Set<NSNumber>, previousWarnings: Set<NSNumber>) {
        delegate?.twilioService(self, callDidReceiveQualityWarnings: currentWarnings)
    }
}

// MARK: - Delegate Protocol

protocol TwilioServiceDelegate: AnyObject {
    func twilioService(_ service: TwilioService, callDidStartRinging call: Call)
    func twilioService(_ service: TwilioService, callDidConnect call: Call)
    func twilioService(_ service: TwilioService, callDidDisconnect call: Call, error: Error?)
    func twilioService(_ service: TwilioService, callDidFailToConnect call: Call, error: Error)
    func twilioService(_ service: TwilioService, callDidReceiveQualityWarnings warnings: Set<NSNumber>)
    func twilioService(_ service: TwilioService, didChangeMuteState isMuted: Bool)
    func twilioService(_ service: TwilioService, didChangeSpeakerState isSpeakerOn: Bool)
}

// MARK: - Default Delegate Implementation

extension TwilioServiceDelegate {
    func twilioService(_ service: TwilioService, callDidStartRinging call: Call) {}
    func twilioService(_ service: TwilioService, callDidConnect call: Call) {}
    func twilioService(_ service: TwilioService, callDidDisconnect call: Call, error: Error?) {}
    func twilioService(_ service: TwilioService, callDidFailToConnect call: Call, error: Error) {}
    func twilioService(_ service: TwilioService, callDidReceiveQualityWarnings warnings: Set<NSNumber>) {}
    func twilioService(_ service: TwilioService, didChangeMuteState isMuted: Bool) {}
    func twilioService(_ service: TwilioService, didChangeSpeakerState isSpeakerOn: Bool) {}
}

// MARK: - Supporting Types

struct TwilioTokenResponse: Codable {
    let token: String
    let identity: String?
}

enum TwilioError: LocalizedError {
    case notAuthenticated
    case invalidResponse
    case tokenFetchFailed(statusCode: Int)
    case callFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to make calls"
        case .invalidResponse:
            return "Invalid response from server"
        case .tokenFetchFailed(let statusCode):
            return "Failed to get access token (status: \(statusCode))"
        case .callFailed(let message):
            return "Call failed: \(message)"
        }
    }
}
