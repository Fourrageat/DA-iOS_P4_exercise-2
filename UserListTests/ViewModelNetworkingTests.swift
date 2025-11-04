import Foundation
import XCTest
@testable import UserList


final class ViewModelNetworkIntegrationTests: XCTestCase {

    // Attente utilitaire pour laisser finir le Task dans ViewModel.fetchUsers
    private func waitUntil(timeout: TimeInterval, condition: @escaping @Sendable () -> Bool) async throws {
        let start = Date()
        while !condition() {
            try await Task.sleep(nanoseconds: 50_000_000) // 50 ms
            if Date().timeIntervalSince(start) > timeout {
                XCTFail("Timeout waiting for condition")
                break
            }
        }
    }

    func testFetchUsersHitsNetworkAndPopulatesUsers() async throws {
        // Repository par défaut = URLSession.shared.data(for:)
        let viewModel = ViewModel(repository: UserListRepository())

        // Lancement d’un vrai appel réseau
        viewModel.fetchUsers(quantity: 5)

        // Attendre la fin du chargement
        try await waitUntil(timeout: 10.0) { !viewModel.isLoading }

        // Vérifications minimales sur des données réelles
        XCTAssertGreaterThanOrEqual(viewModel.users.count, 1, "La liste devrait contenir des utilisateurs")
        // On vérifie que des champs essentiels ne sont pas vides
        let first = try XCTUnwrap(viewModel.users.first)
        XCTAssertFalse(first.name.first.isEmpty)
        XCTAssertFalse(first.name.last.isEmpty)
        XCTAssertFalse(first.picture.thumbnail.isEmpty)
    }

    func testReloadUsersClearsThenReloadsFromNetwork() async throws {
        let repo = UserListRepository()
        let viewModel = ViewModel(repository: repo)

        // Premier chargement
        viewModel.fetchUsers(quantity: 3)
        try await waitUntil(timeout: 10.0) { !viewModel.isLoading }
        let initialCount = viewModel.users.count
        XCTAssertGreaterThan(initialCount, 0, "Le premier chargement devrait rapporter des utilisateurs")

        // Reload: doit vider puis recharger
        viewModel.reloadUsers(quantity: 2)
        // isLoading passe à true immédiatement; on attend la fin
        try await waitUntil(timeout: 10.0) { !viewModel.isLoading }

        XCTAssertEqual(viewModel.users.count, 2, "Reload devrait recharger la quantité demandée")
    }

    func testInfiniteScrollStyle_secondPageLoadsFromNetwork() async throws {
        let repo = UserListRepository()
        let viewModel = ViewModel(repository: repo)

        // Page 1
        viewModel.fetchUsers(quantity: 5)
        try await waitUntil(timeout: 10.0) { !viewModel.isLoading }
        let countAfterFirst = viewModel.users.count
        XCTAssertEqual(countAfterFirst, 5, "La première page devrait contenir 5 utilisateurs")

        // Simuler onAppear sur le dernier élément -> déclencher page 2
        if let last = viewModel.users.last, viewModel.shouldLoadMoreData(currentItem: last) {
            viewModel.fetchUsers(quantity: 5)
        } else {
            // Si la condition n’est pas vraie, on force quand même un second fetch pour tester le réseau
            viewModel.fetchUsers(quantity: 5)
        }

        try await waitUntil(timeout: 10.0) { !viewModel.isLoading }
        let countAfterSecond = viewModel.users.count
        XCTAssertEqual(countAfterSecond, 10, "Après une seconde requête, on devrait avoir 10 utilisateurs")
    }

    func testGuardWhenAlreadyLoading_doesNotStartSecondNetworkCall() async throws {
        // Ce test vérifie le guard !isLoading avec du “vrai” repo.
        // On lance un premier fetch et, pendant qu’il est en cours, on en lance un second.
        let repo = UserListRepository()
        let viewModel = ViewModel(repository: repo)

        // Démarrer un fetch
        viewModel.fetchUsers(quantity: 3)

        // Juste après, isLoading devrait être true
        XCTAssertTrue(viewModel.isLoading)

        // Tenter un second fetch immédiatement: le guard doit court-circuiter
        viewModel.fetchUsers(quantity: 3)

        // Attendre la fin du fetch initial
        try await waitUntil(timeout: 10.0) { !viewModel.isLoading }

        // On ne peut pas compter les appels réseau réels ici, mais on peut vérifier que
        // le nombre total correspond à un seul batch (3) et pas 6.
        XCTAssertEqual(viewModel.users.count, 3, "Le second fetch lancé pendant le chargement ne doit pas s’exécuter")
    }
}
