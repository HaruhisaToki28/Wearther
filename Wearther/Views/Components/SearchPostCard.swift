//
//  SearchPostCard.swift
//  Wearther
//
//  Created by Wearther on 2026/01/22.
//

import SwiftUI

/// 検索結果の投稿カード
/// Figmaデザイン: 115x193px（3列グリッド用）
/// 投稿画像、アバター、ユーザー名、温度、ハートアイコンを表示
struct SearchPostCard: View {
    
    // MARK: - Properties
    
    /// 投稿データ
    let post: Post
    
    /// 投稿者情報
    let user: AppUser?
    
    // MARK: - Constants
    
    private let cardWidth: CGFloat = 115
    private let imageHeight: CGFloat = 154
    private let totalHeight: CGFloat = 193
    private let avatarSize: CGFloat = 18
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // 投稿画像
            postImage
            
            // フッター（アバター、名前、温度、ハート）
            footerSection
        }
        .frame(width: cardWidth, height: totalHeight)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.03), radius: 9.2, x: 0, y: 0)
    }
    
    // MARK: - Subviews
    
    /// 投稿画像
    private var postImage: some View {
        AsyncImage(url: URL(string: post.imageURL)) { phase in
            switch phase {
            case .empty:
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay {
                        ProgressView()
                    }
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure:
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                            .font(.system(size: 24))
                    }
            @unknown default:
                EmptyView()
            }
        }
        .frame(width: cardWidth, height: imageHeight)
        .clipped()
        .clipShape(
            RoundedCorner(radius: 10, corners: [.topLeft, .topRight])
        )
    }
    
    /// フッターセクション
    private var footerSection: some View {
        HStack(alignment: .center, spacing: 5) {
            // アバター
            userAvatar
            
            // ユーザー名と温度
            VStack(alignment: .leading, spacing: 4) {
                // ユーザー名
                Text(user?.displayName ?? "---")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: "2D2D2D"))
                    .lineLimit(1)
                
                // 温度
                Text("\(post.temperature)°C")
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "AAAAAA"))
            }
            
            Spacer()
            
            // ハートアイコン
            Image(systemName: "heart.fill")
                .font(.system(size: 15))
                .foregroundColor(Color(hex: "D5D5D5"))
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 9)
        .frame(width: cardWidth, height: totalHeight - imageHeight)
    }
    
    /// ユーザーアバター
    private var userAvatar: some View {
        Group {
            if let avatarURL = user?.avatarURL, !avatarURL.isEmpty {
                AsyncImage(url: URL(string: avatarURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        defaultAvatar
                    }
                }
            } else {
                defaultAvatar
            }
        }
        .frame(width: avatarSize, height: avatarSize)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color(hex: "DDE2E2"), lineWidth: 0.1)
        )
    }
    
    /// デフォルトアバター
    private var defaultAvatar: some View {
        Circle()
            .fill(Color.gray.opacity(0.3))
            .overlay {
                Image(systemName: "person.fill")
                    .foregroundColor(.gray)
                    .font(.system(size: 8))
            }
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 5) {
        SearchPostCard(
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
        
        SearchPostCard(
            post: Post(
                userId: "test2",
                imageURL: "https://example.com/image2.jpg",
                title: "テスト投稿2",
                caption: "テストキャプション2",
                weather: .cloudy,
                temperature: 15,
                location: PostLocation(name: "大阪"),
                userGender: "女性",
                userAge: 22,
                userHeight: 160,
                likesCount: 50
            ),
            user: nil
        )
    }
    .padding()
    .background(Color(hex: "F8F8F8"))
}
