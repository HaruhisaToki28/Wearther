//
//  UserProfileView.swift
//  Wearther
//
//  Created by Wearther on 2026/01/22.
//

import SwiftUI

/// 他ユーザーのプロフィール画面
/// ユーザー情報、投稿一覧、フォロー機能を提供
struct UserProfileView: View {
    
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: UserProfileViewModel
    @EnvironmentObject private var authService: AuthService
    
    // MARK: - Initialization
    
    /// 初期化
    /// - Parameter userId: 表示するユーザーのID
    init(userId: String) {
        _viewModel = StateObject(wrappedValue: UserProfileViewModel(userId: userId))
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            headerSection
            
            // コンテンツ
            ZStack(alignment: .top) {
                // 背景色: グレー
                Color(hex: "F8F8F8")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // プロフィール情報セクション
                        profileInfoSection
                        
                        // タブ
                        tabSection
                        
                        // 投稿グリッド
                        postsGridSection
                            .padding(.top, 5)
                            .padding(.bottom, 100)
                    }
                    .background(Color(hex: "F8F8F8"))
                }
                .scrollIndicators(.hidden)
                .refreshable {
                    await viewModel.refresh()
                }
            }
        }
        .navigationBarHidden(true)
        .onChange(of: viewModel.selectedTab) { oldValue, newValue in
            if newValue == .likes && viewModel.likedPosts.isEmpty {
                Task {
                    await viewModel.fetchLikedPosts()
                }
            }
        }
        .task {
            await viewModel.loadData(currentUserId: authService.currentUser?.id)
        }
    }
    
    // MARK: - ヘッダーセクション
    
    /// ヘッダー（戻るボタン、ユーザー名、ellipsisボタン）
    private var headerSection: some View {
        HStack {
            // 戻るボタン
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 25))
                    .foregroundColor(.black)
                    .frame(width: 19)
            }
            
            Spacer()
            
            // ユーザー名
            Text(viewModel.user?.username ?? "読み込み中...")
                .font(.system(size: 23, weight: .bold))
                .foregroundColor(.black)
            
            Spacer()
            
            // ellipsisボタン（後ほど機能実装）
            Button {
                // TODO: メニュー表示機能を実装
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 24))
                    .foregroundColor(.black)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white)
    }
    
    // MARK: - プロフィール情報セクション
    
    /// プロフィール情報（アバター、名前、統計、bio、フォローボタン）
    private var profileInfoSection: some View {
        VStack(spacing: 17) {
            // アバターと情報
            HStack(alignment: .center, spacing: 15) {
                // アバター
                userAvatar
                
                // 名前と統計
                VStack(alignment: .leading, spacing: 0) {
                    // 表示名
                    Text(viewModel.user?.displayName ?? "")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                        .frame(height: 37, alignment: .leading)
                    
                    // 統計情報
                    HStack(spacing: 0) {
                        UserStatItem(
                            value: viewModel.formatCount(viewModel.user?.postsCount ?? 0),
                            label: "投稿",
                            showDivider: true
                        )
                        UserStatItem(
                            value: viewModel.formatCount(viewModel.user?.followersCount ?? 0),
                            label: "フォロワー",
                            showDivider: true
                        )
                        UserStatItem(
                            value: viewModel.formatCount(viewModel.user?.followingCount ?? 0),
                            label: "フォロー中",
                            showDivider: false
                        )
                    }
                }
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Bio
            if let bio = viewModel.user?.bio, !bio.isEmpty {
                Text(bio)
                    .font(.system(size: 11))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 15)
            }
            
            // フォローボタン（自分のプロフィールでない場合のみ表示）
            if !viewModel.isOwnProfile {
                followButton
            }
        }
        .padding(.top, 15)
        .padding(.bottom, 17)
        .background(
            Color.white
                .padding(.top, -500) // 上方向に拡張（バウンス時の隙間を防止）
        )
    }
    
    /// ユーザーアバター
    private var userAvatar: some View {
        AsyncImage(url: URL(string: viewModel.user?.avatarURL ?? "")) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure, .empty:
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 30))
                    }
            @unknown default:
                Circle().fill(Color.gray.opacity(0.3))
            }
        }
        .frame(width: 86, height: 86)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color(hex: "DDE2E2"), lineWidth: 0.1)
        )
    }
    
    /// フォローボタン
    private var followButton: some View {
        Button {
            Task {
                await viewModel.toggleFollow()
            }
        } label: {
            Text(viewModel.isFollowing ? "フォロー中" : "フォローする")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(viewModel.isFollowing ? Color(hex: "2D2D2D") : .white)
                .padding(.vertical, 8)
                .padding(.horizontal, 20)
                .background(
                    Capsule()
                        .fill(viewModel.isFollowing ? Color.white : Color(hex: "2D2D2D"))
                )
                .overlay(
                    Capsule()
                        .stroke(Color(hex: "2D2D2D"), lineWidth: viewModel.isFollowing ? 1 : 0)
                )
        }
    }
    
    // MARK: - タブセクション
    
    /// タブ（投稿/いいね）
    private var tabSection: some View {
        HStack(spacing: 0) {
            UserProfileTabButton(
                icon: "camera",
                selectedIcon: "camera.fill",
                isSelected: viewModel.selectedTab == .posts
            ) {
                viewModel.selectedTab = .posts
            }
            
            UserProfileTabButton(
                icon: "heart",
                selectedIcon: "heart.fill",
                isSelected: viewModel.selectedTab == .likes
            ) {
                viewModel.selectedTab = .likes
            }
        }
        .padding(.horizontal, 0)
        .background(Color.white)
        .overlay(
            Divider()
                .background(Color(hex: "DDDDDD"))
                .frame(height: 0.05),
            alignment: .bottom
        )
    }
    
    // MARK: - 投稿グリッドセクション
    
    /// 投稿グリッド
    @ViewBuilder
    private var postsGridSection: some View {
        if viewModel.selectedTab == .likes && viewModel.isOwnProfile == false {
            // 他ユーザーのいいね一覧は非公開
            VStack(spacing: 16) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color(hex: "AAAAAA"))
                Text("いいねした投稿は非公開です")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "888888"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
        } else {
            UserProfilePostsGrid(
                posts: viewModel.selectedTab == .posts ? viewModel.userPosts : viewModel.likedPosts
            )
        }
    }
}

// MARK: - User Stat Item

/// 統計アイテム（投稿数、フォロワー数、フォロー中）
private struct UserStatItem: View {
    let value: String
    let label: String
    let showDivider: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            HStack(alignment: .center, spacing: 2) {
                Text(value)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.black)
                Text(label)
                    .font(.system(size: 8))
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 5)
            
            if showDivider {
                Rectangle()
                    .fill(Color(hex: "E5E5E5"))
                    .frame(width: 1, height: 12)
            }
        }
    }
}

// MARK: - Tab Button

/// タブボタン
private struct UserProfileTabButton: View {
    let icon: String
    let selectedIcon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 14) {
                Image(systemName: isSelected ? selectedIcon : icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .black : Color(hex: "68717B"))
                
                Rectangle()
                    .fill(isSelected ? Color.black : Color.clear)
                    .frame(height: 2)
                    .frame(maxWidth: 60)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
    }
}

// MARK: - Posts Grid

/// 投稿グリッド
private struct UserProfilePostsGrid: View {
    let posts: [Post]
    
    private let columns = [
        GridItem(.flexible(), spacing: 18),
        GridItem(.flexible(), spacing: 18),
        GridItem(.flexible(), spacing: 18)
    ]
    
    var body: some View {
        if posts.isEmpty {
            // 空の状態
            VStack(spacing: 16) {
                Image(systemName: "camera")
                    .font(.system(size: 40))
                    .foregroundColor(Color(hex: "AAAAAA"))
                Text("まだ投稿がありません")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "888888"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
        } else {
            LazyVGrid(columns: columns, spacing: 5) {
                ForEach(posts) { post in
                    // 投稿詳細画面への遷移
                    NavigationLink(value: post) {
                        ProfileOutfitCard(post: post)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 15)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        UserProfileView(userId: "testUserId")
            .environmentObject(AuthService())
    }
}
