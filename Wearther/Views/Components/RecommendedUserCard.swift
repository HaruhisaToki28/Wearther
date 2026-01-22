//
//  RecommendedUserCard.swift
//  Wearther
//
//  Created by Wearther on 2026/01/22.
//

import SwiftUI

/// おすすめユーザーカード
/// Figmaデザイン: 179x251px
/// 上半分: ユーザーのトップ2投稿を左右に配置
/// 中央: ユーザーアイコン（白枠で囲む）
/// 下部: ユーザー名、ユーザーID、フォローボタン
struct RecommendedUserCard: View {
    
    // MARK: - Properties
    
    let userData: RecommendedUserData
    let onFollowTapped: () -> Void
    
    // MARK: - Constants
    
    private let cardWidth: CGFloat = 179
    private let cardHeight: CGFloat = 251
    private let imageWidth: CGFloat = 89
    private let imageHeight: CGFloat = 125
    private let avatarSize: CGFloat = 70
    private let avatarBorderWidth: CGFloat = 2
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // 上半分: 投稿画像2枚
            ZStack {
                HStack(spacing: 0) {
                    // 左の投稿画像
                    if userData.topPosts.count > 0 {
                        postImage(url: userData.topPosts[0].imageURL)
                    } else {
                        placeholderImage()
                    }
                    
                    // 右の投稿画像（1件しかない場合は同じ画像を表示）
                    if userData.topPosts.count > 1 {
                        postImage(url: userData.topPosts[1].imageURL)
                    } else if userData.topPosts.count == 1 {
                        postImage(url: userData.topPosts[0].imageURL)
                    } else {
                        placeholderImage()
                    }
                }
                
                // 中央のユーザーアイコン
                userAvatar
                    .offset(y: 35) // 画像の下部に配置
            }
            .frame(height: imageHeight)
            
            Spacer()
                .frame(height: 46) // アバター分のスペース
            
            // 下部: ユーザー情報とフォローボタン
            VStack(spacing: 7) {
                // ユーザー名とID
                VStack(spacing: 2) {
                    Text(userData.user.displayName)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "2D2D2D"))
                        .lineLimit(1)
                    
                    Text("@\(userData.user.username)")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(hex: "AAAAAA"))
                        .lineLimit(1)
                }
                
                // フォローボタン
                followButton
            }
            .padding(.horizontal, 44)
            .padding(.bottom, 10)
        }
        .frame(width: cardWidth, height: cardHeight)
        .background(Color.white)
        .cornerRadius(15)
    }
    
    // MARK: - Subviews
    
    /// 投稿画像
    private func postImage(url: String) -> some View {
        AsyncImage(url: URL(string: url)) { phase in
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
                placeholderImage()
            @unknown default:
                EmptyView()
            }
        }
        .frame(width: imageWidth, height: imageHeight)
        .clipped()
    }
    
    /// プレースホルダー画像
    private func placeholderImage() -> some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: imageWidth, height: imageHeight)
            .overlay {
                Image(systemName: "photo")
                    .foregroundColor(.gray)
            }
    }
    
    /// ユーザーアバター
    private var userAvatar: some View {
        Group {
            if let avatarURL = userData.user.avatarURL, !avatarURL.isEmpty {
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
                .stroke(Color.white, lineWidth: avatarBorderWidth)
        )
        .background(
            Circle()
                .fill(Color.white)
                .frame(width: avatarSize + 4, height: avatarSize + 4)
        )
    }
    
    /// デフォルトのアバター
    private var defaultAvatar: some View {
        Circle()
            .fill(Color.gray.opacity(0.3))
            .overlay {
                Image(systemName: "person.fill")
                    .foregroundColor(.gray)
                    .font(.system(size: 24))
            }
    }
    
    /// フォローボタン
    private var followButton: some View {
        Button(action: onFollowTapped) {
            Text(userData.isFollowing ? "フォロー中" : "フォローする")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(userData.isFollowing ? Color(hex: "2D2D2D") : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(userData.isFollowing ? Color.white : Color(hex: "2D2D2D"))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(hex: "2D2D2D"), lineWidth: userData.isFollowing ? 1 : 0)
                )
        }
    }
}

// MARK: - Preview

#Preview {
    RecommendedUserCard(
        userData: RecommendedUserData(
            user: AppUser(
                email: "test@example.com",
                username: "tarou_01",
                displayName: "たろう",
                postsCount: 10,
                followersCount: 100,
                followingCount: 50,
                createdAt: Date()
            ),
            topPosts: [
                Post(
                    userId: "test",
                    imageURL: "https://example.com/1.jpg",
                    title: "テスト1",
                    caption: "",
                    weather: .sunny,
                    temperature: 20,
                    location: PostLocation(name: "東京"),
                    userGender: "男性",
                    userAge: 25,
                    userHeight: 170
                ),
                Post(
                    userId: "test",
                    imageURL: "https://example.com/2.jpg",
                    title: "テスト2",
                    caption: "",
                    weather: .cloudy,
                    temperature: 18,
                    location: PostLocation(name: "大阪"),
                    userGender: "男性",
                    userAge: 25,
                    userHeight: 170
                )
            ],
            isFollowing: false
        ),
        onFollowTapped: {}
    )
    .background(Color.gray.opacity(0.2))
}
