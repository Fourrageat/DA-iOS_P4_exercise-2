//import XCTest
//@testable import UserList
//
//final class ViewModelUsersTests: XCTestCase {
//
//    // Helper pour fabriquer un User déterministe
//    private func makeUser(first: String, last: String, age: Int = 30) -> User {
//        let apiUser = UserListResponse.User(
//            name: .init(title: "Mr", first: first, last: last),
//            dob: .init(date: "2000-01-01", age: age),
//            picture: .init(large: "l", medium: "m", thumbnail: "t")
//        )
//        return User(user: apiUser)
//    }
//
//    // Helper: fabrique un UserListRepository qui renvoie un payload JSON correspondant à users
//    private func makeRepositoryReturning(users: [User]) -> UserListRepository {
//        let payload = UserListResponse(
//            results: users.map { user in
//                UserListResponse.User(
//                    name: .init(title: "Mr", first: user.name.first, last: user.name.last),
//                    dob: .init(date: user.dob.date, age: user.dob.age),
//                    picture: .init(large: user.picture.large, medium: user.picture.medium, thumbnail: user.picture.thumbnail)
//                )
//            }
//        )
//        return UserListRepository { _ in
//            let data = try JSONEncoder().encode(payload)
//            return (data, URLResponse())
//        }
//    }
//    
//    func testShouldLoadMoreData_whenUsersEmpty_returnsFalse() {
//        let repo = UserListRepository { _ in
//            let data = try JSONEncoder().encode(UserListResponse(results: []))
//            return (data, URLResponse())
//        }
//        let viewModel = ViewModel(repository: repo)
//
//        // Aucun user dans la liste
//        XCTAssertTrue(viewModel.users.isEmpty)
//
//        let someItem = makeUser(first: "X", last: "Y")
//        let result = viewModel.shouldLoadMoreData(currentItem: someItem)
//        XCTAssertFalse(result)
//    }
//    
//    func testShouldLoadMoreData_whenNotLoading_andItemIsLast_returnsTrue() {
//        let firstUser = makeUser(first: "A", last: "A")
//        let secondUser = makeUser(first: "B", last: "B")
//
//        // Repository inutile ici, on manipule directement users
//        let viewModel = ViewModel(repository: UserListRepository { _ in (Data(), URLResponse()) })
//
//        // On remplit la liste avec des instances concrètes
//        viewModel.users.append(contentsOf: [firstUser, secondUser])
//
//        // isLoading est false par défaut
//        XCTAssertFalse(viewModel.isLoading)
//
//        // On passe exactement la même instance que le dernier élément
//        let result = viewModel.shouldLoadMoreData(currentItem: secondUser)
//        XCTAssertTrue(result)
//    }
//
//    func testShouldLoadMoreData_whenNotLoading_andItemIsNotLast_returnsFalse() {
//        let firstUser = makeUser(first: "A", last: "A")
//        let secondUser = makeUser(first: "B", last: "B")
//
//        let viewModel = ViewModel(repository: UserListRepository { _ in (Data(), URLResponse()) })
//        viewModel.users.append(contentsOf: [firstUser, secondUser])
//
//        // On passe un item qui n'est pas le dernier
//        let result = viewModel.shouldLoadMoreData(currentItem: firstUser)
//        XCTAssertFalse(result)
//    }
//
//    func testShouldLoadMoreData_whenLoading_andItemIsLast_returnsFalse() {
//        let firstUser = makeUser(first: "A", last: "A")
//        let secondUser = makeUser(first: "B", last: "B")
//
//        let viewModel = ViewModel(repository: UserListRepository { _ in (Data(), URLResponse()) })
//        viewModel.users.append(contentsOf: [firstUser, secondUser])
//
//        // Simule un chargement en cours
//        viewModel.isLoading = true
//
//        let result = viewModel.shouldLoadMoreData(currentItem: secondUser)
//        XCTAssertFalse(result)
//    }
//
//    func testUsersInitiallyEmpty() {
//        let repo = makeRepositoryReturning(users: [])
//        let viewModel = ViewModel(repository: repo)
//        XCTAssertTrue(viewModel.users.isEmpty)
//    }
//
//    func testFetchUsersPopulatesUsers() async throws {
//        let firstUser = makeUser(first: "Alice", last: "Smith")
//        let secondUser = makeUser(first: "Bob", last: "Jones")
//        let repo = makeRepositoryReturning(users: [firstUser, secondUser])
//        let viewModel = ViewModel(repository: repo)
//
//        viewModel.fetchUsers(quantity: 2)
//
//        try await waitUntil(timeout: 1.0) { !viewModel.isLoading }
//        XCTAssertEqual(viewModel.users.count, 2)
//        XCTAssertEqual(viewModel.users[0].name.first, "Alice")
//        XCTAssertEqual(viewModel.users[1].name.first, "Bob")
//    }
//
//    func testReloadUsersClearsThenReloads() async throws {
//        let initial = [makeUser(first: "A", last: "A")]
//        let next = [makeUser(first: "C", last: "C"), makeUser(first: "D", last: "D")]
//
//        var useNext = false
//        let repo = UserListRepository { _ in
//            let results = (useNext ? next : initial).map { u in
//                UserListResponse.User(
//                    name: .init(title: "Mr", first: u.name.first, last: u.name.last),
//                    dob: .init(date: u.dob.date, age: u.dob.age),
//                    picture: .init(large: u.picture.large, medium: u.picture.medium, thumbnail: u.picture.thumbnail)
//                )
//            }
//            let data = try JSONEncoder().encode(UserListResponse(results: results))
//            return (data, URLResponse())
//        }
//
//        let viewModel = ViewModel(repository: repo)
//
//        viewModel.fetchUsers(quantity: 1)
//        try await waitUntil(timeout: 1.0) { !viewModel.isLoading }
//        XCTAssertEqual(viewModel.users.count, 1)
//
//        useNext = true
//
//        viewModel.reloadUsers(quantity: 2)
//        try await waitUntil(timeout: 1.0) { !viewModel.isLoading }
//        XCTAssertEqual(viewModel.users.count, 2)
//        XCTAssertEqual(viewModel.users.map { $0.name.first }, ["C", "D"])
//    }
//
//    // Petit helper pour attendre la fin du Task lancé dans ViewModel.fetchUsers
//    private func waitUntil(timeout: TimeInterval, condition: @escaping @Sendable () -> Bool) async throws {
//        let start = Date()
//        while !condition() {
//            try await Task.sleep(nanoseconds: 20_000_000) // 20 ms
//            if Date().timeIntervalSince(start) > timeout {
//                XCTFail("Timeout waiting for condition")
//                break
//            }
//        }
//    }
//}
//
