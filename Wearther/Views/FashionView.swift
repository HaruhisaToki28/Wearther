//
//  FashionView.swift
//  Wearther
//
//  Created by Wearther on 2026/01/22.
//

import SwiftUI

/// ファッションタブのメインビュー
/// 検索バー、今日のトレンド、おすすめユーザー、ランキング、人気の検索を表示
struct FashionView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = FashionViewModel()
    @EnvironmentObject private var authService: AuthService
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - 固定ヘッダー（検索バー）
                searchBar
                
                // MARK: - スクロールコンテンツ
                ScrollView {
                    VStack(spacing: 0) {
                        // 今日のトレンド
                        trendSection
                        
                        // おすすめユーザー
                        recommendedUsersSection
                        
                        // ランキング
                        rankingSection
                        
                        // 人気の検索
                        popularSearchesSection
                        
                        // 下部余白（タブバー分）
                        Spacer()
                            .frame(height: 20)
                    }
                }
                .refreshable {
                    await viewModel.loadAllData(userId: authService.currentUser?.id)
                }
            }
            .background(Color(hex: "F8F8F8"))
            .navigationBarHidden(true)
            .navigationDestination(for: Post.self) { post in
                PostDetailView(post: post)
            }
        }
        .task {
            await viewModel.loadAllData(userId: authService.currentUser?.id)
        }
    }
    
    // MARK: - 検索バー
    
    /// 検索バー
    /// タップすると検索画面に遷移
    private var searchBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // 検索入力欄（タップで検索画面に遷移）
                NavigationLink(destination: FashionSearchView()) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "68717B"))
                        
                        Text("ユーザーまたは投稿を検索")
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "68717B"))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(hex: "F5F5F5"))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 12)
            .background(Color.white)
            
            // 下部ボーダー
            Rectangle()
                .fill(Color(hex: "DDDDDD"))
                .frame(height: 0.5)
        }
    }
    
    // MARK: - 今日のトレンド
    
    /// 今日のトレンドセクション
    private var trendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // セクションヘッダー
            sectionHeader(
                icon: "bolt.fill",
                title: "今日のトレンド"
            )
            
            // トレンド投稿一覧（横スクロール）
            if viewModel.isLoading && viewModel.trendPosts.isEmpty {
                // スケルトン表示
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 11) {
                        ForEach(0..<3, id: \.self) { _ in
                            TrendPostCardSkeleton()
                        }
                    }
                    .padding(.horizontal, 16)
                }
            } else if viewModel.trendPosts.isEmpty {
                emptyStateView(message: "トレンド投稿がありません")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 11) {
                        ForEach(viewModel.trendPosts) { post in
                            // 投稿詳細画面への遷移
                            NavigationLink(destination: PostDetailView(post: post)) {
                                TrendPostCard(
                                    post: post,
                                    user: viewModel.trendPostUsers[post.userId]
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .padding(.top, 22)
    }
    
    // MARK: - おすすめユーザー
    
    /// おすすめユーザーセクション
    private var recommendedUsersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // セクションヘッダー
            sectionHeader(
                icon: "person.fill",
                title: "あなたにおすすめのユーザー"
            )
            
            // おすすめユーザー一覧（横スクロール）
            if viewModel.isLoading && viewModel.recommendedUsers.isEmpty {
                // スケルトン表示
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(0..<3, id: \.self) { _ in
                            RecommendedUserCardSkeleton()
                        }
                    }
                    .padding(.horizontal, 13)
                }
            } else if viewModel.recommendedUsers.isEmpty {
                emptyStateView(message: "おすすめユーザーがいません")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.recommendedUsers) { userData in
                            RecommendedUserCard(
                                userData: userData,
                                onFollowTapped: {
                                    Task {
                                        await viewModel.toggleFollow(for: userData)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 13)
                }
            }
        }
        .padding(.top, 32)
    }
    
    // MARK: - ランキング
    
    /// ランキングセクション
    private var rankingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // セクションヘッダー
            sectionHeader(
                icon: "trophy.fill",
                title: "ランキング"
            )
            
            // ランキング投稿一覧（横スクロール）
            if viewModel.isLoading && viewModel.rankingPosts.isEmpty {
                // スケルトン表示
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 11) {
                        ForEach(0..<4, id: \.self) { _ in
                            RankingPostCardSkeleton()
                        }
                    }
                    .padding(.horizontal, 16)
                }
            } else if viewModel.rankingPosts.isEmpty {
                emptyStateView(message: "ランキングデータがありません")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 11) {
                        ForEach(viewModel.rankingPosts) { rankedPost in
                            // 投稿詳細画面への遷移
                            NavigationLink(destination: PostDetailView(post: rankedPost.post)) {
                                RankingPostCard(
                                    rankedPost: rankedPost,
                                    onLikeTapped: {
                                        Task {
                                            await viewModel.toggleLike(for: rankedPost)
                                        }
                                    }
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 13)
                }
            }
        }
        .padding(.top, 32)
    }
    
    // MARK: - 人気の検索
    
    /// 人気の検索セクション
    private var popularSearchesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // セクションヘッダー
            sectionHeader(
                icon: "magnifyingglass",
                title: "人気の検索"
            )
            
            // 検索ワード一覧
            VStack(alignment: .leading, spacing: 0) {
                if viewModel.popularSearches.isEmpty && !viewModel.isLoading {
                    HStack {
                        Text("人気の検索ワードがありません")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 10)
                } else {
                    ForEach(viewModel.popularSearches) { searchQuery in
                        popularSearchRow(keyword: searchQuery.keyword)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 11)
            .background(Color.white)
        }
        .padding(.top, 32)
    }
    
    // MARK: - Helper Views
    
    /// セクションヘッダー
    /// - Parameters:
    ///   - icon: SF Symbolsのアイコン名
    ///   - title: セクションタイトル
    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color(hex: "2D2D2D"))
                .frame(width: 20, height: 20)
            
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color(hex: "2D2D2D"))
        }
        .padding(.horizontal, 15)
    }
    
    /// 人気の検索行
    /// - Parameter keyword: 検索キーワード
    private func popularSearchRow(keyword: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 10) {
                Text("#")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "2D2D2D"))
                
                Text(keyword)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "2D2D2D"))
                
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            
            // 区切り線
            Rectangle()
                .fill(Color(hex: "DDE2E2"))
                .frame(maxWidth: .infinity)
                .frame(height: 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    /// 空の状態を表示するビュー
    /// - Parameter message: 表示するメッセージ
    private func emptyStateView(message: String) -> some View {
        HStack {
            Spacer()
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .padding(.vertical, 40)
            Spacer()
        }
    }
}

// MARK: - Fashion Skeleton Components

/// トレンド投稿カードスケルトン
private struct TrendPostCardSkeleton: View {
    private let cardWidth: CGFloat = 208
    private let cardHeight: CGFloat = 349
    
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color(hex: "E8EDF5"))
                .frame(width: cardWidth, height: cardHeight - 40)
                .shimmer()
            
            // ユーザー情報部分
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "E8EDF5"))
                    .frame(width: 100, height: 12)
                Spacer()
            }
            .padding(12)
        }
        .frame(width: cardWidth, height: cardHeight)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.03), radius: 9.2, x: 0, y: 0)
    }
}

/// おすすめユーザーカードスケルトン
private struct RecommendedUserCardSkeleton: View {
    private let cardWidth: CGFloat = 179
    private let cardHeight: CGFloat = 251
    
    var body: some View {
        VStack(spacing: 0) {
            // 投稿画像部分
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color(hex: "E8EDF5"))
                    .frame(width: cardWidth / 2, height: 125)
                Rectangle()
                    .fill(Color(hex: "DDE2E2"))
                    .frame(width: cardWidth / 2, height: 125)
            }
            .shimmer()
            
            Spacer()
            
            // アバター
            Circle()
                .fill(Color(hex: "E8EDF5"))
                .frame(width: 70, height: 70)
                .offset(y: -35)
            
            // ユーザー名
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "E8EDF5"))
                    .frame(width: 60, height: 12)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "E8EDF5"))
                    .frame(width: 80, height: 10)
            }
            .offset(y: -25)
            
            // フォローボタン
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "E8EDF5"))
                .frame(width: 100, height: 32)
                .offset(y: -15)
            
            Spacer()
        }
        .frame(width: cardWidth, height: cardHeight)
        .background(Color.white)
        .cornerRadius(15)
    }
}

/// ランキング投稿カードスケルトン
private struct RankingPostCardSkeleton: View {
    private let cardWidth: CGFloat = 124
    private let cardHeight: CGFloat = 166
    
    var body: some View {
        Rectangle()
            .fill(Color(hex: "E8EDF5"))
            .frame(width: cardWidth, height: cardHeight)
            .cornerRadius(10)
            .shimmer()
            .shadow(color: .black.opacity(0.03), radius: 9.2, x: 0, y: 0)
    }
}

// MARK: - Preview

#Preview {
    FashionView()
        .environmentObject(AuthService())
}
