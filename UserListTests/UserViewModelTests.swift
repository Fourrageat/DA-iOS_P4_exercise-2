//
//  ViewModelTests.swift
//  UserList
//
//  Created by Baptiste Fourrageat on 15/11/2025.
//

import XCTest
@testable import UserList

final class UserViewModelTests: XCTestCase {
    /**
     Creates a domain `User` from simple values to simplify test setup.
     This helper builds a `UserListResponse.User` (as if returned by the remote API)
     and converts it into the app's `User` model.
     
     - Parameters:
       - first: The user's first name.
       - last: The user's last name.
       - age: The user's age.
     - Returns: A `User` instance matching the provided values.
     */
    private func makeUser(first: String, last: String, age: Int) -> User {
        // Create a user as returned by the API
        let apiUser = UserListResponse.User(
            name: .init(title: "Mr", first: first, last: last),
            dob: .init(date: "2000-01-01", age: age),
            picture: .init(large: "l", medium: "m", thumbnail: "t")
        )
        // Convert it into the app's `User` model (`User`)
        return User(user: apiUser)
    }

    /**
     Creates a mock `UserListRepositoryType` that always returns the provided users.
     The mock encodes the given `users` into a `UserListResponse` JSON payload and
     returns it as `(Data, URLResponse)` regardless of the requested URL.
     
     - Parameter users: The list of domain `User` values that the repository should return.
     - Returns: A repository instance suitable for tests that simulates a successful network response.
     */
    private func makeRepositoryReturning(users: [User]) -> UserListRepositoryType {
        // Prepare the response payload as if it came from the API
        let payload = UserListResponse(
            results: users.map { user in
                UserListResponse.User(
                    name: .init(title: "Mr", first: user.name.first, last: user.name.last),
                    dob: .init(date: user.dob.date, age: user.dob.age),
                    picture: .init(large: user.picture.large, medium: user.picture.medium, thumbnail: user.picture.thumbnail)
                )
            }
        )
        // The mock repository ignores the URL and always returns the same encoded payload
        return UserListRepository { _ in
            let data = try JSONEncoder().encode(payload)
            return (data, URLResponse())
        }
    }

    /// Verifies that, by default, the ViewModel's user list is empty.
    func testUsersInitiallyEmpty() {
        // Given
        // Create a mock repository configured to return an empty array
        let repository: UserListRepositoryType = makeRepositoryReturning(users: Array())
        
        // When
        // Instantiate the ViewModel
        let viewModel: UserViewModelType = UserViewModel(repository: repository)
        
        // Then
        // Assert the view is empty
        XCTAssertTrue(viewModel.users.isEmpty)
    }
    
    /**
    Vérifie que `fetchUsers(quantity:)` déclenche un chargement puis peuple `users` avec
    les résultats renvoyés par le repository simulé.
     */
    func testFetchUsersPopulatesUsers() async throws {
        // Given
        // Prepare two users that the mock repository will return
        let user1: User = makeUser(first: "Alice", last: "Smith", age: 35)
        let user2: User = makeUser(first: "Bob", last: "Jones", age: 28)
        // Create a mock repository configured to return the two predefined users (user1 and user2)
        let repository: UserListRepositoryType = makeRepositoryReturning(users: [user1, user2])
        // Instantiate the ViewModel
        let viewModel: UserViewModelType = UserViewModel(repository: repository)

        // When
        // Trigger the asynchronous fetch of 2 users
        viewModel.fetchUsers(quantity: 2)
        // Wait for the end of the loading (isLoading -> false)
        try await waitUntil(timeout: 1.0) { !viewModel.isLoading }

        // Then
        // Assert the number and order of users
        XCTAssertEqual(viewModel.users.count, 2)
        // Assert the user1 data
        XCTAssertEqual(viewModel.users[0].name.first, "Alice")
        XCTAssertEqual(viewModel.users[0].name.last, "Smith")
        XCTAssertEqual(viewModel.users[0].dob.age, 35)
        // Assert the user2 data
        XCTAssertEqual(viewModel.users[1].name.first, "Bob")
        XCTAssertEqual(viewModel.users[1].name.last, "Jones")
        XCTAssertEqual(viewModel.users[1].dob.age, 28)

    }

    /**
     Verifies that `reloadUsers(quantity:)` first clears the current list, then fetches
     a new set of users from the repository mock.
     */
    func testReloadUsersClearsThenReloads() async throws {
        // First response used by the first fetch conteining a list of 1 user
        let initial: [User] = [makeUser(first: "A", last: "A", age: 1)]
        // Seconde response used after reload fetch conteining a list of 2 users
        let next: [User] = [makeUser(first: "C", last: "C", age: 3), makeUser(first: "D", last: "D", age: 4)]

        // Ce flag permet de basculer entre la première et la seconde réponse
        var useNext = false
        // On crée un repository simulé (mock) en fournissant une closure qui sera appelée
        // quand la ViewModel demandera des données. Le type attendu est `UserListRepositoryType`,
        // et `UserListRepository` prend en paramètre une closure `(URL) throws -> (Data, URLResponse)`.
        let repository: UserListRepositoryType = UserListRepository { _ in
            // Le paramètre `_` représente ici l'URL demandée (qu'on ignore volontairement dans ce mock).
            // Dans un vrai repository, on utiliserait cette URL pour construire une requête réseau.

            // Selon le flag `useNext`, on choisit quelle liste d'utilisateurs renvoyer :
            // - Si `useNext == true`, on prend `next` (la deuxième réponse)
            // - Sinon, on prend `initial` (la première réponse)
            //
            // Ensuite, on appelle `.map { u in ... }` sur ce tableau.
            // `.map` est une fonction d'ordre supérieur qui itère sur chaque élément du tableau (ici `u`)
            // et transforme chaque `User` métier en `UserListResponse.User` (le format attendu par l'API).
            let results = (useNext ? next : initial).map { u in
                // Pour chaque utilisateur `u`, on construit un `UserListResponse.User`.
                // Remarquez l'utilisation de `.init(...)` qui est une syntaxe Swift pour appeler l'initialiseur
                // du type lorsque le type est déduit (ici `UserListResponse.User.Name`, `Dob`, etc.)
                UserListResponse.User(
                    name: .init(title: "Mr", first: u.name.first, last: u.name.last),
                    dob: .init(date: u.dob.date, age: u.dob.age),
                    picture: .init(large: u.picture.large, medium: u.picture.medium, thumbnail: u.picture.thumbnail)
                )
            }

            // On crée l'objet de réponse attendu par l'API: `UserListResponse(results: results)`,
            // puis on l'encode en `Data` (octets) via `JSONEncoder`.
            // `JSONEncoder().encode(...)` peut lancer une erreur -> `try` est requis.
            // Si l'encodage réussit, on obtient un `Data` représentant le JSON.
            let data = try JSONEncoder().encode(UserListResponse(results: results))

            // Debug: on essaye d'afficher le JSON encodé sous forme de String UTF-8 lisible.
            // `String(data:encoding:)` renvoie un `String?` (optionnel) parce que la conversion peut échouer.
            // L’opérateur `??` (nil-coalescing) fournit une valeur par défaut si c’est `nil`.
            print("\n[Tests] Encoded payload string: \(String(data: data, encoding: .utf8) ?? "<non-utf8>")\n")
            
            // On renvoie un tuple `(Data, URLResponse)` comme si l'appel réseau venait de se terminer.
            // Ici, `URLResponse()` est une réponse factice minimale (pas d'URL, pas de status code HTTP).
            return (data, URLResponse())
        }
        
        print("\n[repository] type:", type(of: repository), "description:", String(describing: repository))

        // Instantiate the ViewModel
        let viewModel: UserViewModelType = UserViewModel(repository: repository)

        // 1) Premier fetch: on s'attend à 1 utilisateur
        viewModel.fetchUsers(quantity: 1)
        try await waitUntil(timeout: 1.0) { !viewModel.isLoading }
        XCTAssertEqual(viewModel.users.count, 1)
        XCTAssertEqual(viewModel.users[0].name.first, "A")
        XCTAssertEqual(viewModel.users[0].dob.age, 1)

        // On bascule pour que le prochain appel renvoie la seconde liste
        useNext = true

        // 2) Reload: doit vider puis recharger 2 utilisateurs
        viewModel.reloadUsers(quantity: 2)
        try await waitUntil(timeout: 1.0) { !viewModel.isLoading }
        XCTAssertEqual(viewModel.users.count, 2)
        XCTAssertEqual(viewModel.users.map { $0.name.first }, ["C", "D"])
        XCTAssertEqual(viewModel.users.map { $0.dob.age }, [3, 4])

    }
    
    func testShouldLoadMoreData() async throws {
        // Given: a view model with 3 users already loaded
        let user1: User = makeUser(first: "Alice", last: "A", age: 30)
        let user2: User = makeUser(first: "Bob", last: "B", age: 31)
        let user3: User = makeUser(first: "Carol", last: "C", age: 32)
        let repository: UserListRepositoryType = makeRepositoryReturning(users: [user1, user2, user3])
        let viewModel: UserViewModelType = UserViewModel(repository: repository)

        // When: fetch initial users
        viewModel.fetchUsers(quantity: 3)
        try await waitUntil(timeout: 1.0) { !viewModel.isLoading }
        XCTAssertEqual(viewModel.users.count, 3)

        // Then: should be false when list is empty
        let emptyVM: UserViewModelType = UserViewModel(repository: makeRepositoryReturning(users: []))
        XCTAssertFalse(emptyVM.shouldLoadMoreData(currentItem: user1), "No last item when users is empty -> false")

        // Then: false when item is not the last
        XCTAssertFalse(viewModel.shouldLoadMoreData(currentItem: viewModel.users[0]))
        XCTAssertFalse(viewModel.shouldLoadMoreData(currentItem: viewModel.users[1]))

        // Then: true when item IS the last and not loading
        XCTAssertTrue(viewModel.shouldLoadMoreData(currentItem: viewModel.users[2]))

        // Then: false when loading, even if item is the last
        // Simulate a fetch starting (isLoading = true) without awaiting completion
        viewModel.fetchUsers(quantity: 1)
        // Give a tiny moment to ensure isLoading has flipped to true
        try await waitUntil(timeout: 1.0) { viewModel.isLoading }
        XCTAssertTrue(viewModel.isLoading)
        XCTAssertFalse(viewModel.shouldLoadMoreData(currentItem: viewModel.users.last!), "Must be false while loading")

        // Cleanup wait for loading to finish to avoid leaking tasks
        try await waitUntil(timeout: 1.0) { !viewModel.isLoading }
    }

    // Petite utilitaire d'attente active: on boucle jusqu'à ce que `condition` soit vraie
    // ou jusqu'au dépassement du délai `timeout`. On insère un petit sleep pour éviter de
    // bloquer le thread inutilement.
    private func waitUntil(timeout: TimeInterval, condition: @escaping @Sendable () -> Bool) async throws {
        let start = Date()
        while !condition() {
            // On dort 20 ms entre chaque vérification
            try await Task.sleep(nanoseconds: 20_000_000) // 20 ms
            if Date().timeIntervalSince(start) > timeout {
                XCTFail("Timeout waiting for condition")
                break
            }
        }
    }
}

