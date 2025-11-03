//
//  CommonView.swift
//  UserList
//
//  Created by Baptiste Fourrageat on 03/11/2025.
//

import SwiftUI

struct ImageView: View {
    let pictureUrl: String
    let size: CGFloat
    
    var body: some View {
        AsyncImage(url: URL(string: pictureUrl)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size, height: size)
                .clipShape(Circle())
        } placeholder: {
            ProgressView()
                .frame(width: size, height: size)
                .clipShape(Circle())
        }
    }
}
