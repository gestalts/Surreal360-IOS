import Foundation
import KeychainAccess

/// Manages secure storage of authentication tokens
protocol TokenManagerProtocol {
    func saveAccessToken(_ token: String) async throws
    func saveRefreshToken(_ token: String) async throws
    func getAccessToken() async throws -> String?
    func getRefreshToken() async throws -> String?
    func clearTokens() async throws
}

class TokenManager: TokenManagerProtocol {
    private let keychain: Keychain
    private let accessTokenKey = "com.surreal360.accessToken"
    private let refreshTokenKey = "com.surreal360.refreshToken"

    init(service: String = "com.surreal360.app") {
        self.keychain = Keychain(service: service)
            .accessibility(.afterFirstUnlock)
    }

    func saveAccessToken(_ token: String) async throws {
        try keychain.set(token, key: accessTokenKey)
    }

    func saveRefreshToken(_ token: String) async throws {
        try keychain.set(token, key: refreshTokenKey)
    }

    func getAccessToken() async throws -> String? {
        return try keychain.getString(accessTokenKey)
    }

    func getRefreshToken() async throws -> String? {
        return try keychain.getString(refreshTokenKey)
    }

    func clearTokens() async throws {
        try keychain.remove(accessTokenKey)
        try keychain.remove(refreshTokenKey)
    }
}
