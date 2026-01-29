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
    
    /// カードサイズ
    private let cardWidth: CGFloat = 115
    private let cardHeight: CGFloat = 154
    
    var body: some View {
        // 画像のみを表示するシンプルなカード
        CachedImage(
            url: post.imageURL,
            targetSize: CGSize(width: cardWidth * 2, height: cardHeight * 2)
        )
        .frame(width: cardWidth, height: cardHeight)
        .clipped()
        .contentShape(Rectangle()) // タップ判定をフレームに限定
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

