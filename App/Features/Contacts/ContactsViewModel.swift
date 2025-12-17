import Foundation
import Combine

@MainActor
class ContactsViewModel: ObservableObject {
    @Published var contacts: [Contact360] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var searchQuery = ""

    private let getContactsUseCase: GetContactsUseCase
    private let deleteContactUseCase: DeleteContactUseCase

    init(
        getContactsUseCase: GetContactsUseCase,
        deleteContactUseCase: DeleteContactUseCase
    ) {
        self.getContactsUseCase = getContactsUseCase
        self.deleteContactUseCase = deleteContactUseCase
    }

    var filteredContacts: [Contact360] {
        if searchQuery.isEmpty {
            return contacts.sorted { contact1, contact2 in
                // Favorites first, then alphabetical
                if contact1.isFavorite && !contact2.isFavorite {
                    return true
                } else if !contact1.isFavorite && contact2.isFavorite {
                    return false
                } else {
                    return contact1.displayName.localizedCaseInsensitiveCompare(contact2.displayName) == .orderedAscending
                }
            }
        }
        
        return contacts.filter { contact in
            contact.displayName.localizedCaseInsensitiveContains(searchQuery) ||
            contact.company?.localizedCaseInsensitiveContains(searchQuery) == true ||
            contact.jobTitle?.localizedCaseInsensitiveContains(searchQuery) == true ||
            contact.primaryEmail?.localizedCaseInsensitiveContains(searchQuery) == true ||
            contact.tags.contains { tag in
                tag.localizedCaseInsensitiveContains(searchQuery)
            }
        }.sorted { contact1, contact2 in
            // Favorites first, then alphabetical
            if contact1.isFavorite && !contact2.isFavorite {
                return true
            } else if !contact1.isFavorite && contact2.isFavorite {
                return false
            } else {
                return contact1.displayName.localizedCaseInsensitiveCompare(contact2.displayName) == .orderedAscending
            }
        }
    }

    func loadContacts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            print("🔄 Loading contacts from API...")
            contacts = try await getContactsUseCase.execute() as! [Contact360]
            print("✅ Loaded \(contacts.count) contacts")
        } catch {
            print("❌ Failed to load contacts: \(error)")
            showError(message: error.localizedDescription)
        }
    }

    func searchContacts(query: String) async {
        guard !query.isEmpty else {
            await loadContacts()
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let searchQuery = ContactQuery(search: query)
            contacts = try await getContactsUseCase.execute(query: searchQuery) as! [Contact360]
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    func deleteContact(_ contact: Contact360) {
        Task {
            do {
                try await deleteContactUseCase.execute(id: contact.id)
                // Remove from local array
                contacts.removeAll { $0.id == contact.id }
                print("✅ Contact deleted successfully")
            } catch {
                print("❌ Failed to delete contact: \(error)")
                showError(message: "Failed to delete contact: \(error.localizedDescription)")
            }
        }
    }

    func refreshContacts() async {
        await loadContacts()
    }

    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Contact Filtering Extensions

extension ContactsViewModel {
    func getFavoriteContacts() -> [Contact360] {
        return contacts.filter { $0.isFavorite }
    }
    
    func getContactsByCompany() -> [String: [Contact360]] {
        let grouped = Dictionary(grouping: contacts) { contact in
            contact.company ?? "No Company"
        }
        return grouped
    }
    
    func getContactsWithTag(_ tag: String) -> [Contact360] {
        return contacts.filter { $0.tags.contains(tag) }
    }
    
    func getAllTags() -> [String] {
        let allTags = contacts.flatMap { $0.tags }
        return Array(Set(allTags)).sorted()
    }
}
