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
    
    func testFetchUsers_WhenAlreadyLoading_ThenDoesNotStartSecondFetch() async throws {
        
        // Given
        let viewModel = ViewModel(repository: UserListRepository())
        
        // When
        viewModel.fetchUsers(quantity: 3)
        viewModel.fetchUsers(quantity: 2)
        try await waitUntil(timeout: 10.0) { !viewModel.isLoading }

        // Then
        XCTAssertEqual(viewModel.users.count, 3, "Must be equal to 3, not to 5 because the second fetch must fail")
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

