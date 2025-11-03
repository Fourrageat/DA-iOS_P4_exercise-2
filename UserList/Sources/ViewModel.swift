import Foundation
import Combine

final class ViewModel: ObservableObject {

    // Outputs
    @Published private(set) var users: [User] = []
    @Published private(set) var isLoading: Bool = false
    @Published var isGridView: Bool = false

    // Dependencies
    private let repository: UserListRepository

    // Init
    init(repository: UserListRepository = UserListRepository()) {
        self.repository = repository
    }

    // Inputs
    func fetchUsers(quantity: Int = 20) {
        guard !isLoading else { return }
        isLoading = true
        Task {
            do {
                let newUsers = try await repository.fetchUsers(quantity: quantity)
                self.users.append(contentsOf: newUsers)
                self.isLoading = false
            } catch {
                // Vous pouvez exposer une erreur publiée si besoin
                self.isLoading = false
                print("Error fetching users: \(error.localizedDescription)")
            }
        }
    }

    func reloadUsers(quantity: Int = 20) {
        users.removeAll()
        fetchUsers(quantity: quantity)
    }

    // Output helper
    func shouldLoadMoreData(currentItem item: User) -> Bool {
        guard let lastItem = users.last else { return false }
        return !isLoading && item.id == lastItem.id
    }
}
