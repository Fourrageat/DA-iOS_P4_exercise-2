//
//  ViewModelTests.swift
//  UserList
//
//  Created by Baptiste Fourrageat on 15/11/2025.
//

import XCTest
@testable import UserList

final class ViewModelUsersTests: XCTestCase {

    private func makeUser(first: String, last: String, age: Int = 30) -> User {
        let apiUser = UserListResponse.User(
            name: .init(title: "Mr", first: first, last: last),
            dob: .init(date: "2000-01-01", age: age),
            picture: .init(large: "l", medium: "m", thumbnail: "t")
        )
        return User(user: apiUser)
    }

    private func makeRepositoryReturning(users: [User]) -> UserListRepository {
        let payload = UserListResponse(
            results: users.map { user in
                UserListResponse.User(
                    name: .init(title: "Mr", first: user.name.first, last: user.name.last),
                    dob: .init(date: user.dob.date, age: user.dob.age),
                    picture: .init(large: user.picture.large, medium: user.picture.medium, thumbnail: user.picture.thumbnail)
                )
            }
        )
        return UserListRepository { _ in
            let data = try JSONEncoder().encode(payload)
            return (data, URLResponse())
        }
    }

    func testUsersInitiallyEmpty() {
        let repo = makeRepositoryReturning(users: [])
        let vm = ViewModel(repository: repo)
        XCTAssertTrue(vm.users.isEmpty)
    }

    func testFetchUsersPopulatesUsers() async throws {
        let u1 = makeUser(first: "Alice", last: "Smith")
        let u2 = makeUser(first: "Bob", last: "Jones")
        let repo = makeRepositoryReturning(users: [u1, u2])
        let vm = ViewModel(repository: repo)

        vm.fetchUsers(quantity: 2)

        try await waitUntil(timeout: 1.0) { !vm.isLoading }
        XCTAssertEqual(vm.users.count, 2)
        XCTAssertEqual(vm.users[0].name.first, "Alice")
        XCTAssertEqual(vm.users[1].name.first, "Bob")
    }

    func testReloadUsersClearsThenReloads() async throws {
        let initial = [makeUser(first: "A", last: "A")]
        let next = [makeUser(first: "C", last: "C"), makeUser(first: "D", last: "D")]

        var useNext = false
        let repo = UserListRepository { _ in
            let results = (useNext ? next : initial).map { u in
                UserListResponse.User(
                    name: .init(title: "Mr", first: u.name.first, last: u.name.last),
                    dob: .init(date: u.dob.date, age: u.dob.age),
                    picture: .init(large: u.picture.large, medium: u.picture.medium, thumbnail: u.picture.thumbnail)
                )
            }
            let data = try JSONEncoder().encode(UserListResponse(results: results))
            return (data, URLResponse())
        }

        let vm = ViewModel(repository: repo)

        vm.fetchUsers(quantity: 1)
        try await waitUntil(timeout: 1.0) { !vm.isLoading }
        XCTAssertEqual(vm.users.count, 1)

        useNext = true

        vm.reloadUsers(quantity: 2)
        try await waitUntil(timeout: 1.0) { !vm.isLoading }
        XCTAssertEqual(vm.users.count, 2)
        XCTAssertEqual(vm.users.map { $0.name.first }, ["C", "D"])
    }

    private func waitUntil(timeout: TimeInterval, condition: @escaping @Sendable () -> Bool) async throws {
        let start = Date()
        while !condition() {
            try await Task.sleep(nanoseconds: 20_000_000) // 20 ms
            if Date().timeIntervalSince(start) > timeout {
                XCTFail("Timeout waiting for condition")
                break
            }
        }
    }
}
