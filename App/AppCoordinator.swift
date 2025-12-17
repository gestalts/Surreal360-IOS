import SwiftUI
import Combine

/// AppCoordinator manages the app's navigation state and authentication flow
@MainActor
class AppCoordinator: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = true

    let container: DIContainer

    private var cancellables = Set<AnyCancellable>()

    init() {
        self.container = DIContainer()
        setupAuthenticationObserver()
    }

    func checkAuthenticationStatus() {
        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                let isValid = try await container.authService.validateSession()
                isAuthenticated = isValid
            } catch {
                print("Authentication check failed: \\(error)")
                isAuthenticated = false
            }
        }
    }

    private func setupAuthenticationObserver() {
        container.authService.authStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthenticated in
                self?.isAuthenticated = isAuthenticated
            }
            .store(in: &cancellables)
    }
}
