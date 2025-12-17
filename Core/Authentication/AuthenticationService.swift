import Foundation
import Combine
import Supabase

/// Protocol defining authentication operations
protocol AuthenticationServiceProtocol {
    var authStatePublisher: AnyPublisher<Bool, Never> { get }

    func signIn(email: String, password: String) async throws -> User
    func signUp(email: String, password: String, firstName: String?, lastName: String?) async throws -> User
    func signOut() async throws
    func resetPassword(email: String) async throws
    func updatePassword(newPassword: String) async throws
    func validateSession() async throws -> Bool
    func getAccessToken() async throws -> String?
    func refreshToken() async throws
}

/// Implementation of authentication using Supabase
class AuthenticationService: AuthenticationServiceProtocol {
    private let supabase: SupabaseClient
    private let tokenManager: TokenManager
    private let authStateSubject = CurrentValueSubject<Bool, Never>(false)

    var authStatePublisher: AnyPublisher<Bool, Never> {
        authStateSubject.eraseToAnyPublisher()
    }

    init(supabase: SupabaseClient, tokenManager: TokenManager) {
        self.supabase = supabase
        self.tokenManager = tokenManager
    }

    func signIn(email: String, password: String) async throws -> User {
        do {
            // Step 1: Sign in with Supabase
            let session = try await supabase.auth.signIn(email: email, password: password)
            let supabaseToken = session.accessToken

            // Step 2: Exchange Supabase token for Django token
            let djangoToken = try await exchangeSupabaseTokenForDjangoToken(
                supabaseToken: supabaseToken,
                email: email
            )

            // Step 3: Save Django token (this is what the backend expects)
            try await tokenManager.saveAccessToken(djangoToken)
            try await tokenManager.saveRefreshToken(session.refreshToken)
            print("💾 Django token saved to Keychain")

            let user = try await fetchUserProfile(userId: session.user.id)

            // Send auth state change on main thread
            await MainActor.run {
                authStateSubject.send(true)
            }
            return user
        } catch {
            throw AuthenticationError.signInFailed(error)
        }
    }

    func signUp(email: String, password: String, firstName: String?, lastName: String?) async throws -> User {
        do {
            let authResponse = try await supabase.auth.signUp(email: email, password: password)
            guard let session = authResponse.session else {
                throw AuthenticationError.signUpFailed(NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No session returned from sign up"]))
            }

            let supabaseToken = session.accessToken

            // Exchange Supabase token for Django token
            let djangoToken = try await exchangeSupabaseTokenForDjangoToken(
                supabaseToken: supabaseToken,
                email: email
            )

            try await tokenManager.saveAccessToken(djangoToken)
            try await tokenManager.saveRefreshToken(session.refreshToken)

            // Create user profile
            let user = try await createUserProfile(
                userId: session.user.id,
                email: email,
                firstName: firstName,
                lastName: lastName
            )

            // Send auth state change on main thread
            await MainActor.run {
                authStateSubject.send(true)
            }
            return user
        } catch {
            throw AuthenticationError.signUpFailed(error)
        }
    }

    func signOut() async throws {
        do {
            try await supabase.auth.signOut()
            try await tokenManager.clearTokens()

            // Send auth state change on main thread
            await MainActor.run {
                authStateSubject.send(false)
            }
        } catch {
            throw AuthenticationError.signOutFailed(error)
        }
    }

    func resetPassword(email: String) async throws {
        do {
            try await supabase.auth.resetPasswordForEmail(email)
        } catch {
            throw AuthenticationError.resetPasswordFailed(error)
        }
    }

    func updatePassword(newPassword: String) async throws {
        do {
            try await supabase.auth.update(user: UserAttributes(password: newPassword))
        } catch {
            throw AuthenticationError.updatePasswordFailed(error)
        }
    }

    func validateSession() async throws -> Bool {
        guard let accessToken = try await tokenManager.getAccessToken() else {
            return false
        }

        do {
            let session = try await supabase.auth.session
            return session.accessToken == accessToken
        } catch {
            return false
        }
    }

    func getAccessToken() async throws -> String? {
        let token = try await tokenManager.getAccessToken()
        if let token = token {
            print("🔑 Retrieved token from Keychain: \(token.prefix(20))...")
        } else {
            print("⚠️ No token found in Keychain")
        }
        return token
    }

    func refreshToken() async throws {
        guard let refreshToken = try await tokenManager.getRefreshToken() else {
            throw AuthenticationError.noRefreshToken
        }

        do {
            let session = try await supabase.auth.refreshSession(refreshToken: refreshToken)
            // session is already a Session object, no need to access .session property
            
            try await tokenManager.saveAccessToken(session.accessToken)
            try await tokenManager.saveRefreshToken(session.refreshToken)
        } catch {
            throw AuthenticationError.refreshFailed(error)
        }
    }

    // MARK: - Private Methods

    private func exchangeSupabaseTokenForDjangoToken(supabaseToken: String, email: String) async throws -> String {
        let url = URL(string: "\(Environment.backendURL)/api/token/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "supabase_token": supabaseToken,
            "email": email
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        print("🔄 Exchanging Supabase token for Django token...")
        print("📍 URL: \(url)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw AuthenticationError.tokenExchangeFailed
        }

        print("📊 Token exchange response: \(httpResponse.statusCode)")

        guard (200...299).contains(httpResponse.statusCode) else {
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Token exchange failed: \(responseString)")
            }
            throw AuthenticationError.tokenExchangeFailed
        }

        struct TokenResponse: Codable {
            let token: String
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        print("✅ Django token received: \(tokenResponse.token.prefix(20))...")
        return tokenResponse.token
    }

    private func fetchUserProfile(userId: UUID) async throws -> User {
        // TODO: Implement actual API call to fetch user profile
        // For now, return a mock user
        return User(
            id: userId,
            email: "user@example.com",
            firstName: "John",
            lastName: "Doe",
            avatar: nil,
            role: .member,
            status: .active,
            organizationId: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private func createUserProfile(
        userId: UUID,
        email: String,
        firstName: String?,
        lastName: String?
    ) async throws -> User {
        // TODO: Implement actual API call to create user profile
        // For now, return a mock user
        return User(
            id: userId,
            email: email,
            firstName: firstName,
            lastName: lastName,
            avatar: nil,
            role: .member,
            status: .active,
            organizationId: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// MARK: - Authentication Errors

enum AuthenticationError: LocalizedError {
    case signInFailed(Error)
    case signUpFailed(Error)
    case signOutFailed(Error)
    case resetPasswordFailed(Error)
    case updatePasswordFailed(Error)
    case refreshFailed(Error)
    case noRefreshToken
    case invalidCredentials
    case tokenExchangeFailed

    var errorDescription: String? {
        switch self {
        case .signInFailed(let error):
            return "Sign in failed: \(error.localizedDescription)"
        case .signUpFailed(let error):
            return "Sign up failed: \(error.localizedDescription)"
        case .signOutFailed(let error):
            return "Sign out failed: \(error.localizedDescription)"
        case .resetPasswordFailed(let error):
            return "Password reset failed: \(error.localizedDescription)"
        case .updatePasswordFailed(let error):
            return "Password update failed: \(error.localizedDescription)"
        case .refreshFailed(let error):
            return "Token refresh failed: \(error.localizedDescription)"
        case .noRefreshToken:
            return "No refresh token available"
        case .invalidCredentials:
            return "Invalid email or password"
        case .tokenExchangeFailed:
            return "Failed to exchange authentication token"
        }
    }
}
