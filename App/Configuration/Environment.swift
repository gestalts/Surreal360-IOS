import Foundation

enum Environment {
    /// Get configuration value from xcconfig files or Info.plist
    private static func configValue(for key: String) -> String? {
        // Try Info.plist first (this is where xcconfig values end up)
        if let value = Bundle.main.infoDictionary?[key] as? String, !value.isEmpty {
            return value
        }
        
        // Fall back to process environment
        return ProcessInfo.processInfo.environment[key]
    }
    
    static var backendURL: URL {
        guard let urlString = configValue(for: "BACKEND_URL"),
              let url = URL(string: urlString) else {
            // Fallback to production server
            let fallbackURL = "https://server.360surreal.com"
            guard let url = URL(string: fallbackURL) else {
                fatalError("BACKEND_URL not configured. Please set it in Config.xcconfig or Info.plist")
            }
            return url
        }
        return url
    }

    static var supabaseURL: URL {
        guard let urlString = configValue(for: "SUPABASE_URL"),
              let url = URL(string: urlString) else {
            // Fallback to the value from Config.xcconfig if not properly linked
            let fallbackURL = "https://hwzrzuryvvlmryuazzbl.supabase.co"
            guard let url = URL(string: fallbackURL) else {
                fatalError("SUPABASE_URL not configured. Please set it in Config.xcconfig or Info.plist")
            }
            return url
        }
        return url
    }

    static var supabaseAnonKey: String {
        guard let key = configValue(for: "SUPABASE_ANON_KEY"), !key.isEmpty else {
            // Fallback to the value from Config.xcconfig if not properly linked
            return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh3enJ6dXJ5dnZsbXJ5dWF6emJsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjgxNDE4MjQsImV4cCI6MjA0MzcxNzgyNH0.H8b4RDFkTVSWb_I6gbCjrr0v9_8Md_EjvFlR_88u_V8"
        }
        return key
    }
    
    static var mapboxAPIKey: String? {
        return configValue(for: "MAPBOX_API_KEY")
    }

    static var isProduction: Bool {
        #if DEBUG
        return false
        #else
        return true
        #endif
    }

    static var apiVersion: String {
        return "v1"
    }

    // MARK: - Twilio Configuration

    static var twilioVoiceTokenURL: URL {
        backendURL.appendingPathComponent("api/twilio/voice/token/")
    }

    static var twilioSMSSendURL: URL {
        backendURL.appendingPathComponent("api/twilio/sms/send/")
    }

    static var twilioMessagesURL: URL {
        backendURL.appendingPathComponent("api/twilio/messages/")
    }

    static var twilioCallsURL: URL {
        backendURL.appendingPathComponent("api/twilio/calls/")
    }

    static var twilioDeviceRegisterURL: URL {
        backendURL.appendingPathComponent("api/twilio/device/register/")
    }
}
