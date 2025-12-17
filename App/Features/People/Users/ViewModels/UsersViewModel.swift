import SwiftUI
import Combine

@MainActor
class UsersViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var searchQuery = ""

    private let getUsersUseCase: GetUsersUseCase

    init(getUsersUseCase: GetUsersUseCase) {
        self.getUsersUseCase = getUsersUseCase
    }

    var filteredUsers: [User] {
        if searchQuery.isEmpty {
            return users
        }
        return users.filter { user in
            user.fullName.localizedCaseInsensitiveContains(searchQuery) ||
            user.email.localizedCaseInsensitiveContains(searchQuery)
        }
    }

    func loadUsers() async {
        isLoading = true
        defer { isLoading = false }

        do {
            users = try await getUsersUseCase.execute()
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    func searchUsers(query: String) async {
        guard !query.isEmpty else {
            await loadUsers()
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let searchQuery = UserQuery(search: query)
            users = try await getUsersUseCase.execute(query: searchQuery)
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}
