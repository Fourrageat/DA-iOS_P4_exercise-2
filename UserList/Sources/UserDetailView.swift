import SwiftUI

struct UserDetailView: View {
    let user: User
    
    var body: some View {
        VStack {
            ImageView(
                pictureUrl: user.picture.large,
                size: 200
            )
            
            VStack(alignment: .leading) {
                Text("\(user.name.first) \(user.name.last)")
                    .font(.headline)
                Text("\(user.dob.date)")
                    .font(.subheadline)
            }
            .padding()
            
            Spacer()
        }
        .navigationTitle("\(user.name.first) \(user.name.last)")
    }
}

#Preview {
    let pictureUrl = "https://img.freepik.com/vecteurs-premium/icone-utilisateur-icone-grise-ronde_1076610-44912.jpg?semt=ais_hybrid&w=740&q=80"

    let mockUser = User(
        user: UserListResponse.User(
            name: .init(title: "Mr", first: "John", last: "Doe"),
            dob: .init(date: "1990-01-01", age: 31),
            picture: .init(
                large: pictureUrl,
                medium: pictureUrl,
                thumbnail: pictureUrl
            )
        )
    )
    
    NavigationView {
        UserDetailView(user: mockUser)
    }
}
