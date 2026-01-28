//
//  SearchUserRow.swift
//  Wearther
//
//  Created by Wearther on 2026/01/22.
//

import SwiftUI
import Kingfisher

/// 検索結果のユーザー行
/// Figmaデザイン: アバター(35px)、ユーザー名、ID、フォローボタン
struct SearchUserRow: View {
    
    // MARK: - Properties
    
    /// ユーザーデータ
    let user: AppUser
    
    /// フォロー中かどうか
    let isFollowing: Bool
    
    /// 自分自身かどうか（フォローボタンを非表示にするため）
    let isCurrentUser: Bool
    
    /// フォローボタンタップ時のアクション
    let onFollowTapped: () -> Void
    
    // MARK: - Constants
    
    private let avatarSize: CGFloat = 35
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            // アバター
            userAvatar
            
            // ユーザー情報
            userInfo
            
            Spacer()
            
            // フォローボタン（自分自身でない場合のみ表示）
            if !isCurrentUser {
                followButton
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
    
    // MARK: - Subviews
    
    /// ユーザーアバター
    private var userAvatar: some View {
        CachedAvatarImage(url: user.avatarURL, size: avatarSize)
            .overlay(
                Circle()
                    .stroke(Color(hex: "DDE2E2"), lineWidth: 0.1)
            )
    }
    
    /// ユーザー情報（名前とID）
    private var userInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            // 表示名
            Text(user.displayName)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: "2D2D2D"))
                .lineLimit(1)
            
            // ユーザーID
            Text("@\(user.username)")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "AAAAAA"))
                .lineLimit(1)
        }
    }
    
    /// フォローボタン
    private var followButton: some View {
        Button(action: onFollowTapped) {
            Text(isFollowing ? "フォロー中" : "フォローする")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(isFollowing ? Color(hex: "2D2D2D") : .white)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(isFollowing ? Color.white : Color(hex: "2D2D2D"))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(hex: "2D2D2D"), lineWidth: isFollowing ? 1 : 0)
                )
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        SearchUserRow(
            user: AppUser(
                email: "test@example.com",
                username: "raditon_001",
                displayName: "あ",
                postsCount: 10,
                followersCount: 100,
                followingCount: 50,
                createdAt: Date()
            ),
            isFollowing: false,
            isCurrentUser: false,
            onFollowTapped: {}
        )
        
        Divider()
            .padding(.leading, 63)
        
        SearchUserRow(
            user: AppUser(
                email: "test2@example.com",
                username: "user_002",
                displayName: "テストユーザー",
                postsCount: 5,
                followersCount: 50,
                followingCount: 30,
                createdAt: Date()
            ),
            isFollowing: true,
            isCurrentUser: false,
            onFollowTapped: {}
        )
        
        Divider()
            .padding(.leading, 63)
        
        SearchUserRow(
            user: AppUser(
                email: "me@example.com",
                username: "my_account",
                displayName: "自分",
                postsCount: 20,
                followersCount: 200,
                followingCount: 100,
                createdAt: Date()
            ),
            isFollowing: false,
            isCurrentUser: true,
            onFollowTapped: {}
        )
    }
    .background(Color.white)
    .padding()
}
