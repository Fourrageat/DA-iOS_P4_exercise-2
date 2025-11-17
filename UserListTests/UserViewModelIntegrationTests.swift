//import Foundation
//import XCTest
//@testable import UserList
//
//
//final class ViewModelNetworkIntegrationTests: XCTestCase {
//
//    private func waitUntil(timeout: TimeInterval, condition: @escaping @Sendable () -> Bool) async throws {
//        let start = Date()
//        while !condition() {
//            try await Task.sleep(nanoseconds: 50_000_000) // 50 ms
//            if Date().timeIntervalSince(start) > timeout {
//                XCTFail("Timeout waiting for condition")
//                break
//            }
//        }
//    }
//
//    func testFetchUsers_WhenSuccess_ThenFieldsNonEmpty() async throws {
//        
//        // Given
//        let viewModel = ViewModel(repository: UserListRepository())
//        
//        // When
//        viewModel.fetchUsers(quantity: 5)
//        try await waitUntil(timeout: 10.0) { !viewModel.isLoading }
//        let user = try XCTUnwrap(viewModel.users[0])
//
//        // Then
//        XCTAssertEqual(viewModel.users.count, 5)
//        XCTAssertFalse(user.name.first.isEmpty)
//        XCTAssertFalse(user.name.last.isEmpty)
//        XCTAssertFalse(user.picture.thumbnail.isEmpty)
//        XCTAssertFalse(user.picture.large.isEmpty)
//        XCTAssertFalse(user.picture.medium.isEmpty)
//        XCTAssertFalse(String(user.dob.age).isEmpty)
//        XCTAssertFalse(user.dob.date.isEmpty)
//    }
//    
//    func testFetchUsers_WhenAlreadyLoading_ThenDoesNotStartSecondFetch() async throws {
//        
//        // Given
//        let viewModel = ViewModel(repository: UserListRepository())
//        
//        // When
//        viewModel.fetchUsers(quantity: 3)
//        viewModel.fetchUsers(quantity: 2)
//        try await waitUntil(timeout: 10.0) { !viewModel.isLoading }
//
//        // Then
//        XCTAssertEqual(viewModel.users.count, 3, "Must be equal to 3, not to 5 because the second fetch must fail")
//    }
//    
//    func testFetchUsers_whenRepositoryThrowsError_ThenNoUsersAdded() async throws {
//        
//        // Given
//        enum DummyError: Error { case boom }
//        let failingRepo = UserListRepository { _ in
//            throw DummyError.boom
//        }
//        let viewModel = ViewModel(repository: failingRepo)
//
//        // When
//        viewModel.fetchUsers(quantity: 3)
//        try await waitUntil(timeout: 1.0) { !viewModel.isLoading }
//        
//        // Then
//        XCTAssertFalse(viewModel.isLoading, "isLoading must be false after catch error")
//        XCTAssertTrue(viewModel.users.isEmpty, "No users added after the catch error")
//    }
//
//    func testReloadUsers_WhenClearsAndReloads_ThenUsersMatchSecondFetchCount() async throws {
//        
//        // Given
//        let viewModel = ViewModel(repository: UserListRepository())
//
//        // When
//        viewModel.fetchUsers(quantity: 3) // First fetch
//        try await waitUntil(timeout: 10.0) { !viewModel.isLoading }
//        viewModel.reloadUsers(quantity: 2) // Second fetch
//        try await waitUntil(timeout: 10.0) { !viewModel.isLoading }
//
//        // Then
//        XCTAssertEqual(viewModel.users.count, 2, "Users must be equal to the second fetch, after the reload")
//    }
//}
//
