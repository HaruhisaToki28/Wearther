//
//  FashionSearchViewModel.swift
//  Wearther
//
//  Created by Wearther on 2026/01/22.
//

import Foundation
import Combine

/// ファッション検索画面のViewModel
/// 検索状態、履歴、結果を管理
@MainActor
class FashionSearchViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// 検索テキスト
    @Published var searchText: String = ""
    
    /// 検索中フラグ
    @Published var isSearching: Bool = false
    
    /// 検索履歴
    @Published var searchHistory: [FashionSearchHistory] = []
    
    /// 検索結果: 投稿
    @Published var searchedPosts: [Post] = []
    
    /// 検索結果: 投稿に対応するユーザー情報
    @Published var searchedPostUsers: [String: AppUser] = [:]
    
    /// 検索結果: ユーザー
    @Published var searchedUsers: [AppUser] = []
    
    /// ユーザーのフォロー状態
    @Published var followingStatus: [String: Bool] = [:]
    
    /// 選択中のタブ
    @Published var selectedTab: SearchTab = .posts
    
    /// エラーメッセージ
    @Published var errorMessage: String?
    
    /// 検索が実行されたかどうか
    @Published var hasSearched: Bool = false
    
    // MARK: - Private Properties
    
    /// サービス
    private let fashionService = FashionService.shared
    
    /// 現在のユーザーID
    private var currentUserId: String?
    
    // MARK: - Enums
    
    /// 検索結果のタブ
    enum SearchTab: String, CaseIterable {
        case posts = "投稿"
        case users = "ユーザー"
    }
    
    // MARK: - Initialization
    
    init() {
        loadHistory()
    }
    
    // MARK: - Public Methods
    
    /// 現在のユーザーIDを設定
    /// - Parameter userId: ユーザーID
    func setCurrentUserId(_ userId: String?) {
        self.currentUserId = userId
    }
    
    /// 検索を実行（確定時に呼び出す）
    func executeSearch() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 空の場合は検索しない
        guard !query.isEmpty else { return }
        
        Task {
            await performSearch(query: query)
        }
    }
    
    /// キーワードを指定して検索を実行（履歴からの選択時など）
    /// - Parameter query: 検索クエリ
    func executeSearch(with query: String) {
        searchText = query
        
        Task {
            await performSearch(query: query)
        }
    }
    
    /// 検索をクリア
    func clearSearch() {
        searchText = ""
        hasSearched = false
        searchedPosts = []
        searchedUsers = []
        searchedPostUsers = [:]
        errorMessage = nil
    }
    
    // MARK: - 検索履歴
    
    /// 検索履歴を読み込み
    func loadHistory() {
        searchHistory = FashionSearchHistory.loadHistory()
    }
    
    /// 検索履歴に追加
    /// - Parameter keyword: キーワード
    func addToHistory(_ keyword: String) {
        searchHistory = FashionSearchHistory.addToHistory(keyword: keyword)
    }
    
    /// 検索履歴から削除
    /// - Parameter item: 削除するアイテム
    func removeFromHistory(_ item: FashionSearchHistory) {
        searchHistory = FashionSearchHistory.removeFromHistory(item)
    }
    
    /// 検索履歴をすべて削除
    func clearHistory() {
        FashionSearchHistory.clearHistory()
        searchHistory = []
    }
    
    // MARK: - フォロー機能
    
    /// ユーザーをフォロー/アンフォロー
    /// - Parameter user: 対象ユーザー
    func toggleFollow(for user: AppUser) async {
        guard let userId = user.id,
              let currentId = currentUserId,
              userId != currentId else {
            print("フォロー操作をスキップ: 自分自身またはログインしていない")
            return
        }
        
        // 楽観的UI更新
        let previousState = followingStatus[userId] ?? false
        followingStatus[userId] = !previousState
        
        do {
            if previousState {
                try await fashionService.unfollowUser(targetUserId: userId, currentUserId: currentId)
                print("フォロー解除成功: \(userId)")
            } else {
                try await fashionService.followUser(targetUserId: userId, currentUserId: currentId)
                print("フォロー成功: \(userId)")
            }
        } catch {
            // エラー時はUIを元に戻す
            print("フォロー操作に失敗: \(error.localizedDescription)")
            followingStatus[userId] = previousState
        }
    }
    
    // MARK: - Private Methods
    
    /// 検索を実行（内部処理）
    /// - Parameter query: 検索クエリ
    private func performSearch(query: String) async {
        isSearching = true
        errorMessage = nil
        
        do {
            // 投稿とユーザーを並列で検索
            async let postsResult = fashionService.searchPosts(query: query)
            async let usersResult = fashionService.searchUsers(query: query)
            
            let (posts, users) = try await (postsResult, usersResult)
            
            searchedPosts = posts
            searchedUsers = users
            
            // 投稿に対応するユーザー情報を取得
            if !posts.isEmpty {
                searchedPostUsers = try await fashionService.fetchUsersForPosts(posts)
            }
            
            // ユーザーのフォロー状態を確認
            await checkFollowingStatus(for: users)
            
            // 検索履歴に追加
            addToHistory(query)
            
            hasSearched = true
            
        } catch {
            print("検索に失敗: \(error.localizedDescription)")
            errorMessage = "検索に失敗しました"
        }
        
        isSearching = false
    }
    
    /// ユーザーのフォロー状態を確認
    /// - Parameter users: ユーザー配列
    private func checkFollowingStatus(for users: [AppUser]) async {
        guard let currentId = currentUserId else { return }
        
        for user in users {
            guard let userId = user.id, userId != currentId else { continue }
            
            do {
                let isFollowing = try await fashionService.isFollowing(
                    targetUserId: userId,
                    currentUserId: currentId
                )
                followingStatus[userId] = isFollowing
            } catch {
                // エラー時はfalseとする
                followingStatus[userId] = false
            }
        }
    }
}
