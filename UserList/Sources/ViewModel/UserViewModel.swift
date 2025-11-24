import Foundation
import Combine

final class UserViewModel: ObservableObject {

    // Outputs
    @Published var users: [User] = []
    @Published var isLoading: Bool = false
    @Published var isGridView: Bool = false
    @Published var lastError: Error?

    // Dependencies
    var repository: UserListRepositoryType

    // Init
    init(repository: UserListRepositoryType = UserListRepository()) {
        self.repository = repository
    }

    // Inputs
    func fetchUsers(quantity: Int = 20) async throws {
        guard !isLoading else { return }
        lastError = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let newUsers = try await repository.fetchUsers(quantity: quantity)
            self.users.append(contentsOf: newUsers)
        } catch {
            self.lastError = error
            print("Error fetching users: \(error.localizedDescription)")
            throw error
        }
    }

    func reloadUsers(quantity: Int = 20) async {
        lastError = nil
        users.removeAll()
        
        do {
            try await fetchUsers(quantity: quantity)
        } catch {
            self.lastError = error
            print("Error reloading users: \(error.localizedDescription)")
        }
    }

    // Output helper
    func shouldLoadMoreData(currentItem item: User) -> Bool {
        guard let lastItem = users.last else { return false }
        return !isLoading && item.id == lastItem.id
    }
}

