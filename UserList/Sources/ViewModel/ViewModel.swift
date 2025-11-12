import Foundation
import Combine

protocol ViewModelType: AnyObject {
    // Outputs
    var users: [User] { get }
    var isLoading: Bool { get }
    var isGridView: Bool { get set }

    // Inputs
    func fetchUsers(quantity: Int)
    func reloadUsers(quantity: Int)

    // Output helper
    func shouldLoadMoreData(currentItem item: User) -> Bool
}

final class ViewModel: ObservableObject, ViewModelType {

    // Outputs
    @Published var users: [User] = []
    @Published var isLoading: Bool = false
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
