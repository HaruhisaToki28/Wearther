//
//  ProfileView.swift
//  Wearther
//
//  Created by hato on 2025/11/07.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(viewModel.user.username)
                        .font(.system(size: 23, weight: .bold))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Button(action: {
                        // Settings action
                    }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 24))
                            .foregroundColor(.black)
                    }
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 10) // Adjust based on status bar if needed, similar to HomeView
                .background(
                    Color.white
                        .ignoresSafeArea(edges: .top)
                )
                
                // セパレーター（白背景の続き）
                Rectangle()
                    .fill(Color.white)
                    .frame(height: 1)
                
                ZStack(alignment: .top) {
                    // 背景色（下層）: ベースはグレー
                    Color(red: 0.97, green: 0.97, blue: 0.97)
                        .ignoresSafeArea()
                    
                    // 背景色（上層）: 上部のバウンス領域用（白）
                    Color.white
                        .frame(height: 500)
                        .ignoresSafeArea()
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            // Profile Info Section
                            VStack(spacing: 16) {
                                HStack(alignment: .center, spacing: 16) { // アイコンと情報の間のスペースを16pxに
                                    // Avatar
                                    AsyncImage(url: URL(string: viewModel.user.avatarURL)) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        case .failure, .empty:
                                            Circle().fill(Color.gray.opacity(0.3))
                                        @unknown default:
                                            Circle().fill(Color.gray.opacity(0.3))
                                        }
                                    }
                                    .frame(width: 86, height: 86)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color(red: 0.87, green: 0.89, blue: 0.89), lineWidth: 1) // #DDE2E2
                                    )
                                    
                                    // Info Right
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text(viewModel.user.displayName)
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(Color.black) // #000000
                                            .padding(.bottom, 5)
                                        
                                        HStack(spacing: 10) {
                                            StatItem(value: formatCount(viewModel.user.postsCount), label: "投稿")
                                            Divider().frame(height: 20)
                                            StatItem(value: formatCount(viewModel.user.followersCount), label: "フォロワー")
                                            Divider().frame(height: 20)
                                            StatItem(value: formatCount(viewModel.user.followingCount), label: "フォロー中")
                                        }
                                    }
                                }
                                .padding(.horizontal, 16) // 左余白16px
                                .frame(maxWidth: .infinity, alignment: .leading) // ここを追加：全体を左寄せにする
                                
                                // Bio
                                Text(viewModel.user.bio)
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.black) // #000000
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 16) // 左余白16px
                                
                                // Edit Profile Button
                                Button(action: {
                                    // Edit profile action
                                }) {
                                    Text("プロフィールを編集")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 20)
                                        .background(
                                            Capsule()
                                                .fill(Color(red: 0.18, green: 0.18, blue: 0.18)) // #2D2D2D
                                        )
                                }
                            }
                            .padding(.top, 15)
                            .padding(.bottom, 0) // タブとの間隔をなくす
                            .background(Color.white) // ここまで白背景にする
                            
                            // Tabs
                            HStack(spacing: 0) {
                                TabButton(
                                    icon: "camera",
                                    selectedIcon: "camera.fill",
                                    isSelected: viewModel.selectedTab == .posts
                                ) {
                                    viewModel.selectedTab = .posts
                                }
                                
                                TabButton(
                                    icon: "heart",
                                    selectedIcon: "heart.fill",
                                    isSelected: viewModel.selectedTab == .likes
                                ) {
                                    viewModel.selectedTab = .likes
                                }
                            }
                            .padding(.horizontal, 0)
                            .background(Color.white) // タブ部分も白背景
                            
                            // Grid Content
                            let displayPosts = viewModel.selectedTab == .posts ? viewModel.posts : viewModel.likedPosts
                            OutfitGrid(
                                recommendations: displayPosts,
                                onLikeTapped: { _ in },
                                onLoadMore: {}
                            )
                            .padding(.top, 2)
                            .padding(.bottom, 100)
                        }
                        .background(Color(red: 0.97, green: 0.97, blue: 0.97))
                    }
                    .scrollIndicators(.hidden)
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    func formatCount(_ count: Int) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter.string(from: NSNumber(value: count)) ?? "\(count)"
    }
}

private struct StatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            Text(value)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color.black) // #000000
            Text(label)
                .font(.system(size: 8))
                .foregroundColor(Color.black) // #000000
        }
    }
}

private struct TabButton: View {
    let icon: String
    let selectedIcon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 14) {
                Image(systemName: isSelected ? selectedIcon : icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .black : Color(red: 0.408, green: 0.443, blue: 0.482)) // #68717B
                
                Rectangle()
                    .fill(isSelected ? Color.black : Color.clear)
                    .frame(height: 2)
                    .frame(maxWidth: 60) // デザインに合わせて幅を60pxに制限
            }
            .frame(maxWidth: .infinity) // 均等に広げる
            .contentShape(Rectangle())
        }
    }
}

#Preview {
    ProfileView()
}
