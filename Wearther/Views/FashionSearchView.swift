//
//  FashionSearchView.swift
//  Wearther
//
//  Created by Wearther on 2026/01/22.
//

import SwiftUI

/// ファッション検索画面
/// 検索履歴、投稿検索結果、ユーザー検索結果を表示
struct FashionSearchView: View {
    
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = FashionSearchViewModel()
    @EnvironmentObject private var authService: AuthService
    
    /// テキストフィールドのフォーカス状態
    @FocusState private var isSearchFieldFocused: Bool
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー（検索バー）
            headerSection
            
            // コンテンツ
            contentSection
        }
        .background(Color(hex: "F8F8F8"))
        .navigationBarHidden(true)
        .onAppear {
            viewModel.setCurrentUserId(authService.currentUser?.id)
            // 検索フィールドにフォーカス
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isSearchFieldFocused = true
            }
        }
    }
    
    // MARK: - Header Section
    
    /// ヘッダー（戻るボタン + 検索バー）
    private var headerSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // 戻るボタン
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(hex: "2D2D2D"))
                }
                
                // 検索入力欄
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "68717B"))
                    
                    TextField("ユーザーまたは投稿を検索", text: $viewModel.searchText)
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "2D2D2D"))
                        .autocorrectionDisabled()
                        .focused($isSearchFieldFocused)
                        .submitLabel(.search)
                        .onSubmit {
                            // Enterキーで検索実行
                            viewModel.executeSearch()
                        }
                    
                    // クリアボタン
                    if !viewModel.searchText.isEmpty {
                        Button(action: { viewModel.clearSearch() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "AAAAAA"))
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(hex: "F5F5F5"))
                .cornerRadius(15)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 12)
            .background(Color.white)
            
            // 検索結果がある場合はタブを表示
            if viewModel.hasSearched {
                tabBar
            }
            
            // 下部ボーダー
            Rectangle()
                .fill(Color(hex: "DDDDDD"))
                .frame(height: 0.5)
        }
    }
    
    /// タブバー（投稿 / ユーザー）
    private var tabBar: some View {
        HStack(spacing: 95) {
            // 投稿タブ
            tabButton(
                title: "投稿",
                isSelected: viewModel.selectedTab == .posts
            ) {
                viewModel.selectedTab = .posts
            }
            
            // ユーザータブ
            tabButton(
                title: "ユーザー",
                isSelected: viewModel.selectedTab == .users
            ) {
                viewModel.selectedTab = .users
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
        .background(Color.white)
    }
    
    /// タブボタン
    private func tabButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(isSelected ? Color(hex: "2D2D2D") : Color(hex: "68717B"))
                
                // アンダーライン
                Rectangle()
                    .fill(isSelected ? Color(hex: "2D2D2D") : Color.clear)
                    .frame(width: 40, height: 2)
            }
        }
    }
    
    // MARK: - Content Section
    
    /// コンテンツセクション
    private var contentSection: some View {
        ScrollView {
            VStack(spacing: 0) {
                if viewModel.isSearching {
                    // ローディング
                    loadingView
                } else if viewModel.hasSearched {
                    // 検索結果
                    searchResultsView
                } else {
                    // 検索履歴
                    searchHistorySection
                }
            }
            .padding(.top, 16)
        }
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture {
            // キーボードを閉じる
            isSearchFieldFocused = false
        }
    }
    
    /// ローディング表示
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("検索中...")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "68717B"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    /// 検索結果表示
    @ViewBuilder
    private var searchResultsView: some View {
        switch viewModel.selectedTab {
        case .posts:
            postsResultsSection
        case .users:
            usersResultsSection
        }
    }
    
    // MARK: - Posts Results
    
    /// 投稿検索結果
    private var postsResultsSection: some View {
        Group {
            if viewModel.searchedPosts.isEmpty {
                emptyResultView(message: "投稿が見つかりません")
            } else {
                // 3列グリッド
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 5),
                        GridItem(.flexible(), spacing: 5),
                        GridItem(.flexible(), spacing: 5)
                    ],
                    spacing: 5
                ) {
                    ForEach(viewModel.searchedPosts) { post in
                        NavigationLink(destination: PostDetailView(post: post)) {
                            SearchPostCard(
                                post: post,
                                user: viewModel.searchedPostUsers[post.userId]
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 6)
            }
        }
    }
    
    // MARK: - Users Results
    
    /// ユーザー検索結果
    private var usersResultsSection: some View {
        Group {
            if viewModel.searchedUsers.isEmpty {
                emptyResultView(message: "ユーザーが見つかりません")
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.searchedUsers) { user in
                        if let userId = user.id {
                            NavigationLink(destination: UserProfileView(userId: userId)) {
                                SearchUserRow(
                                    user: user,
                                    isFollowing: viewModel.followingStatus[userId] ?? false,
                                    isCurrentUser: userId == authService.currentUser?.id,
                                    onFollowTapped: {
                                        Task {
                                            await viewModel.toggleFollow(for: user)
                                        }
                                    }
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // 区切り線
                            if user.id != viewModel.searchedUsers.last?.id {
                                Divider()
                                    .padding(.leading, 63)
                            }
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(16)
                .padding(.horizontal, 16)
            }
        }
    }
    
    /// 結果が空の場合の表示
    private func emptyResultView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32))
                .foregroundColor(Color(hex: "AAAAAA"))
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "68717B"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Search History
    
    /// 検索履歴セクション
    private var searchHistorySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if viewModel.searchHistory.isEmpty {
                // 履歴なし
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 32))
                        .foregroundColor(Color(hex: "AAAAAA"))
                    Text("検索履歴がありません")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "68717B"))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // 履歴ヘッダー
                HStack {
                    Text("検索履歴")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "68717B"))
                    
                    Spacer()
                    
                    Button(action: { viewModel.clearHistory() }) {
                        Text("すべて削除")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(hex: "FF2539"))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                
                // 履歴一覧
                VStack(spacing: 0) {
                    ForEach(viewModel.searchHistory) { item in
                        historyRow(item: item)
                        
                        if item.id != viewModel.searchHistory.last?.id {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(16)
                .padding(.horizontal, 16)
            }
        }
    }
    
    /// 履歴行
    private func historyRow(item: FashionSearchHistory) -> some View {
        HStack(spacing: 12) {
            Button(action: {
                viewModel.executeSearch(with: item.keyword)
            }) {
                HStack(spacing: 12) {
                    // 時計アイコン
                    ZStack {
                        Circle()
                            .fill(Color(hex: "F5F5F5"))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "clock.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "68717B"))
                    }
                    
                    // キーワード
                    Text(item.keyword)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(hex: "2D2D2D"))
                        .lineLimit(1)
                    
                    Spacer()
                }
            }
            
            // 削除ボタン
            Button(action: {
                viewModel.removeFromHistory(item)
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "AAAAAA"))
                    .padding(8)
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FashionSearchView()
            .environmentObject(AuthService())
    }
}
