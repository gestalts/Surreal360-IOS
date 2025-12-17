import Foundation

/// Type-safe feature flags for the Surreal360 app
/// These flags control which features are enabled/disabled
enum FeatureFlags {
    
    // MARK: - MVP Features
    enum MVP {
        static var authentication: Bool {
            return configBool(for: "MVP_AUTHENTICATION", defaultValue: true)
        }
        
        static var dashboard: Bool {
            return configBool(for: "MVP_DASHBOARD", defaultValue: true)
        }
    }
    
    // MARK: - Phase 2 Features
    enum Phase2 {
        static var projects: Bool {
            return configBool(for: "PHASE2_PROJECTS", defaultValue: false)
        }
        
        static var communications: Bool {
            return configBool(for: "PHASE2_COMMUNICATIONS", defaultValue: false)
        }
    }
    
    // MARK: - Advanced Features
    static var enableRealtime: Bool {
        return configBool(for: "ENABLE_REALTIME", defaultValue: false)
    }
    
    static var enableMLTags: Bool {
        return configBool(for: "ENABLE_ML_TAGS", defaultValue: true)
    }
    
    static var enableDynamicTags: Bool {
        return configBool(for: "ENABLE_DYNAMIC_TAGS", defaultValue: true)
    }
    
    // MARK: - Helper Methods
    private static func configBool(for key: String, defaultValue: Bool) -> Bool {
        // Try Info.plist first (where xcconfig values end up)
        if let value = Bundle.main.infoDictionary?[key] as? String {
            return value.lowercased() == "yes" || value.lowercased() == "true"
        }
        
        // Fall back to process environment
        if let value = ProcessInfo.processInfo.environment[key] {
            return value.lowercased() == "yes" || value.lowercased() == "true"
        }
        
        return defaultValue
    }
}

// MARK: - Development Helpers
#if DEBUG
extension FeatureFlags {
    /// Print all current feature flag values (Debug builds only)
    static func printCurrentFlags() {
        print("🚩 Feature Flags Status:")
        print("  MVP Authentication: \(MVP.authentication)")
        print("  MVP Dashboard: \(MVP.dashboard)")
        print("  Phase2 Projects: \(Phase2.projects)")
        print("  Phase2 Communications: \(Phase2.communications)")
        print("  Enable Realtime: \(enableRealtime)")
        print("  Enable ML Tags: \(enableMLTags)")
        print("  Enable Dynamic Tags: \(enableDynamicTags)")
    }
}
#endif