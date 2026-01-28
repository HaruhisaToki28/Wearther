//
//  ProfileOutfitCard.swift
//  Wearther
//
//  Created by hato on 2025/11/07.
//

import SwiftUI
import Kingfisher

struct ProfileOutfitCard: View {
    let post: Post
    
    var body: some View {
        // 画像のみを表示するシンプルなカード
        CachedImage(
            url: post.imageURL,
            targetSize: CGSize(width: 230, height: 308)
        )
        .frame(width: 115, height: 154)
        .clipped()
        .cornerRadius(10)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.03), radius: 18.4, x: 0, y: 13)
    }
}

#Preview {
    ProfileOutfitCard(
        post: Post(
            userId: "1",
            imageURL: "https://example.com/image.jpg",
            title: "Test",
            caption: "Test caption",
            weather: .sunny,
            temperature: 20,
            location: PostLocation(name: "Tokyo"),
            userGender: "男性",
            userAge: 25,
            userHeight: 175
        )
    )
    .padding()
    .background(Color(red: 0.96, green: 0.96, blue: 0.96))
}

