import SwiftUI
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""

    private let authService: AuthenticationService
    private var cancellables = Set<AnyCancellable>()

    init(authService: AuthenticationService) {
        self.authService = authService
    }

    var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        email.contains("@") &&
        password.count >= 8
    }

    var isSignUpFormValid: Bool {
        isFormValid &&
        !firstName.isEmpty
    }

    // MARK: - Sign In

    func signIn() async {
        guard isFormValid else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let user = try await authService.signIn(email: email, password: password)
            print("✅ Signed in: \(user.email)")
            // Navigation will be handled by AppCoordinator observing auth state
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    // MARK: - Sign Up

    func signUp() async {
        guard isSignUpFormValid else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let user = try await authService.signUp(
                email: email,
                password: password,
                firstName: firstName,
                lastName: lastName
            )
            print("✅ Signed up: \(user.email)")
            // Navigation will be handled by AppCoordinator observing auth state
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    // MARK: - Reset Password

    func resetPassword() async {
        guard !email.isEmpty && email.contains("@") else {
            showError(message: "Please enter a valid email address")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await authService.resetPassword(email: email)
            showError(message: "Password reset email sent. Please check your inbox.")
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    // MARK: - Sign Out

    func signOut() async {
        do {
            try await authService.signOut()
            print("✅ Signed out")
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    // MARK: - Private Helpers

    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}
