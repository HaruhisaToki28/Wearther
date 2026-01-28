//
//  TrendPostCard.swift
//  Wearther
//
//  Created by Wearther on 2026/01/22.
//

import SwiftUI
import Kingfisher

/// 今日のトレンド用の投稿カード
/// Figmaデザイン: 208x349px
/// 写真の下の方に白の文字でユーザー名+ユーザーIDを表示
struct TrendPostCard: View {
    
    // MARK: - Properties
    
    let post: Post
    let user: AppUser?
    
    // MARK: - Constants
    
    private let cardWidth: CGFloat = 208
    private let cardHeight: CGFloat = 349
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // 投稿画像
            CachedImage(
                url: post.imageURL,
                targetSize: CGSize(width: cardWidth * 2, height: cardHeight * 2)
            )
            .frame(width: cardWidth, height: cardHeight)
            .clipped()
            
            // グラデーションオーバーレイ（文字を読みやすくするため）
            LinearGradient(
                gradient: Gradient(colors: [.clear, .black.opacity(0.5)]),
                startPoint: .center,
                endPoint: .bottom
            )
            
            // ユーザー名 + ユーザーID
            if let user = user {
                Text("\(user.displayName) \(user.username)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.03), radius: 9.2, x: 0, y: 0)
    }
}

// MARK: - Preview

#Preview {
    TrendPostCard(
        post: Post(
            userId: "test",
            imageURL: "https://example.com/image.jpg",
            title: "テスト投稿",
            caption: "テストキャプション",
            weather: .sunny,
            temperature: 20,
            location: PostLocation(name: "東京"),
            userGender: "男性",
            userAge: 25,
            userHeight: 170,
            likesCount: 100
        ),
        user: AppUser(
            email: "test@example.com",
            username: "ranmaru_07",
            displayName: "蘭丸",
            postsCount: 10,
            followersCount: 100,
            followingCount: 50,
            createdAt: Date()
        )
    )
}
