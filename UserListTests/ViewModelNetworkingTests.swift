import Foundation
import XCTest
@testable import UserList


final class ViewModelNetworkIntegrationTests: XCTestCase {

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

    func testFetchUsers_WhenSuccess_ThenFieldsNonEmpty() async throws {
        
        // Given
        let viewModel = ViewModel(repository: UserListRepository())
        
        // When
        viewModel.fetchUsers(quantity: 5)
        try await waitUntil(timeout: 10.0) { !viewModel.isLoading }
        let user = try XCTUnwrap(viewModel.users[0])

        // Then
        XCTAssertEqual(viewModel.users.count, 5)
        XCTAssertFalse(user.name.first.isEmpty)
        XCTAssertFalse(user.name.last.isEmpty)
        XCTAssertFalse(user.picture.thumbnail.isEmpty)
        XCTAssertFalse(user.picture.large.isEmpty)
        XCTAssertFalse(user.picture.medium.isEmpty)
        XCTAssertFalse(user.dob.age.words.isEmpty)
        XCTAssertFalse(user.dob.date.isEmpty)
    }

    func testReloadUsers_WhenClearsAndReloads_ThenUsersMatchSecondFetchCount() async throws {
        
        // Given
        let viewModel = ViewModel(repository: UserListRepository())

        // When
        viewModel.fetchUsers(quantity: 3) // First fetch
        try await waitUntil(timeout: 10.0) { !viewModel.isLoading }
        viewModel.reloadUsers(quantity: 2) // Second fetch
        try await waitUntil(timeout: 10.0) { !viewModel.isLoading }

        // Then
        XCTAssertEqual(viewModel.users.count, 2, "Users must be equal to the second fetch, after the reload")
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
    
//    func testFetchUsers_whenRepositoryThrows_errorPathResetsIsLoadingAndDoesNotAppendUsers() async throws {
//        // Given: un repo qui jette une erreur
//        enum DummyError: Error { case boom }
//        let failingRepo = UserListRepository { _ in
//            throw DummyError.boom
//        }
//        let viewModel = ViewModel(repository: failingRepo)
//
//        // Sanity check initial
//        XCTAssertTrue(viewModel.users.isEmpty)
//        XCTAssertFalse(viewModel.isLoading)
//
//        // When: on lance le fetch
//        viewModel.fetchUsers(quantity: 3)
//
//        // Then: attendre la fin du Task et vérifier les effets
//        try await waitUntil(timeout: 1.0) { !viewModel.isLoading }
//        XCTAssertFalse(viewModel.isLoading, "isLoading doit repasser à false après l’erreur")
//        XCTAssertTrue(viewModel.users.isEmpty, "Aucun user ne doit être ajouté en cas d’erreur")
//    }
//
//    func testFetchUsers_whenRepositoryThrows_guardPreventsSecondFetchDuringLoading() async throws {
//        // Given: repo qui “ralentit” puis jette une erreur
//        enum DummyError: Error { case boom }
//        let slowFailingRepo = UserListRepository { _ in
//            try await Task.sleep(nanoseconds: 150_000_000) // 150 ms
//            throw DummyError.boom
//        }
//        let viewModel = ViewModel(repository: slowFailingRepo)
//        
//        // When: démarrer un fetch
//        viewModel.fetchUsers(quantity: 2)
//        // Juste après, isLoading doit être true
//        XCTAssertTrue(viewModel.isLoading)
//        
//        // Lancer immédiatement un second fetch: le guard !isLoading doit empêcher le démarrage
//        viewModel.fetchUsers(quantity: 2)
//        
//        // Then: attendre la fin et vérifier l’état
//        try await waitUntil(timeout: 2.0) { !viewModel.isLoading }
//        XCTAssertFalse(viewModel.isLoading)
//        XCTAssertTrue(viewModel.users.isEmpty, "Toujours aucun user après l’erreur")
//    }
}

