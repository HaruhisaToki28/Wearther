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
        ScrollView {
            VStack(spacing: 0) {
                // 検索バー（後で実装予定のためプレースホルダー）
                searchBar
                
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
        .background(Color(hex: "F8F8F8"))
        .task {
            await viewModel.loadAllData(userId: authService.currentUser?.id)
        }
        .refreshable {
            await viewModel.loadAllData(userId: authService.currentUser?.id)
        }
    }
    
    // MARK: - 検索バー
    
    /// 検索バー（後で実装予定）
    /// LocationSearchViewと同じデザインに統一
    private var searchBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // 検索入力欄（タップ可能なプレースホルダー）
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
            if viewModel.trendPosts.isEmpty && !viewModel.isLoading {
                emptyStateView(message: "トレンド投稿がありません")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 11) {
                        ForEach(viewModel.trendPosts) { post in
                            TrendPostCard(
                                post: post,
                                user: viewModel.trendPostUsers[post.userId]
                            )
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
            if viewModel.recommendedUsers.isEmpty && !viewModel.isLoading {
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
            if viewModel.rankingPosts.isEmpty && !viewModel.isLoading {
                emptyStateView(message: "ランキングデータがありません")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 11) {
                        ForEach(viewModel.rankingPosts) { rankedPost in
                            RankingPostCard(
                                rankedPost: rankedPost,
                                onLikeTapped: {
                                    Task {
                                        await viewModel.toggleLike(for: rankedPost)
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
            if viewModel.isLoading {
                ProgressView()
                    .padding(.vertical, 40)
            } else {
                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .padding(.vertical, 40)
            }
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    FashionView()
        .environmentObject(AuthService())
}
