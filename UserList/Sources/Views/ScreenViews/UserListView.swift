import SwiftUI

struct UserListView: View {
    @StateObject private var viewModel = UserViewModel()

    var body: some View {
        NavigationView {
            if !viewModel.isGridView {
                List(viewModel.users) { user in
                    NavigationLink(destination: UserDetailView(user: user)) {
                        HStack {
                            ImageView(
                                pictureUrl: user.picture.thumbnail,
                                size: 50
                            )
                            TextView(
                                firstName: user.name.first,
                                lastName: user.name.last,
                                date: user.dob.date
                            )
                        }
                    }
                    .onAppear {
                        if viewModel.shouldLoadMoreData(currentItem: user) {
                            viewModel.fetchUsers()
                        }
                    }
                }
                .userListToolbar(isGridView: $viewModel.isGridView, onReload: {
                    viewModel.reloadUsers()
                })
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
                        ForEach(viewModel.users) { user in
                            NavigationLink(destination: UserDetailView(user: user)) {
                                VStack {
                                    ImageView(pictureUrl: user.picture.medium, size: 150)
                                    Text("\(user.name.first) \(user.name.last)")
                                        .font(.headline)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .onAppear {
                                if viewModel.shouldLoadMoreData(currentItem: user) {
                                    viewModel.fetchUsers()
                                }
                            }
                        }
                    }
                }
                .userListToolbar(isGridView: $viewModel.isGridView, onReload: {
                    viewModel.reloadUsers()
                })
            }
        }
        .onAppear {
            viewModel.fetchUsers()
        }
    }
}

private struct UserListToolbarModifier: ViewModifier {
    @Binding var isGridView: Bool
    let onReload: () -> Void

    func body(content: Content) -> some View {
        content
        .navigationTitle("Users")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Picker(selection: $isGridView, label: Text("Display")) {
                    Image(systemName: "rectangle.grid.1x2.fill")
                        .tag(true)
                        .accessibilityLabel(Text("Grid view"))
                    Image(systemName: "list.bullet")
                        .tag(false)
                        .accessibilityLabel(Text("List view"))
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    onReload()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .imageScale(.large)
                }
            }
        }
    }
}

private extension View {
    func userListToolbar(isGridView: Binding<Bool>, onReload: @escaping () -> Void) -> some View {
        self.modifier(UserListToolbarModifier(isGridView: isGridView, onReload: onReload))
    }
}

#Preview {
    UserListView()
}
