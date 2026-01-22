//
//  FashionViewModel.swift
//  Wearther
//
//  Created by Wearther on 2026/01/22.
//

import Foundation
import Combine

/// おすすめユーザーの表示用データ
/// ユーザー情報と代表的な投稿をまとめて保持
struct RecommendedUserData: Identifiable {
    var id: String { user.id ?? UUID().uuidString }
    let user: AppUser
    let topPosts: [Post]
    var isFollowing: Bool
}

/// ランキング投稿の表示用データ
/// 順位とフォロー状態を含む
struct RankedPost: Identifiable {
    var id: String { post.id ?? UUID().uuidString }
    let rank: Int
    let post: Post
    let user: AppUser?
    var isLiked: Bool
}

/// ファッションタブのViewModel
/// トレンド、おすすめユーザー、ランキング、人気検索のデータを管理
@MainActor
class FashionViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// 今日のトレンド投稿（最大5件）
    @Published var trendPosts: [Post] = []
    
    /// トレンド投稿のユーザー情報キャッシュ
    @Published var trendPostUsers: [String: AppUser] = [:]
    
    /// おすすめユーザー一覧
    @Published var recommendedUsers: [RecommendedUserData] = []
    
    /// ランキング投稿（最大5件）
    @Published var rankingPosts: [RankedPost] = []
    
    /// 人気の検索ワード（最大5件）
    @Published var popularSearches: [SearchQuery] = []
    
    /// ローディング状態
    @Published var isLoading: Bool = false
    
    /// エラーメッセージ
    @Published var errorMessage: String?
    
    /// いいね状態のキャッシュ（postId: isLiked）
    @Published var likedPosts: [String: Bool] = [:]
    
    // MARK: - Private Properties
    
    private let fashionService = FashionService.shared
    private let postService = PostService.shared
    private var currentUserId: String?
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Public Methods
    
    /// 全データを読み込む
    /// - Parameter userId: 現在のユーザーID
    func loadAllData(userId: String?) async {
        currentUserId = userId
        isLoading = true
        errorMessage = nil
        
        // 並列でデータを取得
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadTrendPosts() }
            group.addTask { await self.loadRecommendedUsers() }
            group.addTask { await self.loadRankingPosts() }
            group.addTask { await self.loadPopularSearches() }
        }
        
        isLoading = false
    }
    
    /// トレンド投稿を更新
    func refreshTrendPosts() async {
        await loadTrendPosts()
    }
    
    /// おすすめユーザーを更新
    func refreshRecommendedUsers() async {
        await loadRecommendedUsers()
    }
    
    /// ランキングを更新
    func refreshRanking() async {
        await loadRankingPosts()
    }
    
    // MARK: - 今日のトレンド
    
    /// トレンド投稿を取得
    private func loadTrendPosts() async {
        do {
            let posts = try await fashionService.fetchTodaysTrends(limit: 5)
            trendPosts = posts
            
            // 各投稿のユーザー情報を取得
            for post in posts {
                if trendPostUsers[post.userId] == nil {
                    if let user = try? await fashionService.fetchUser(userId: post.userId) {
                        trendPostUsers[post.userId] = user
                    }
                }
            }
        } catch {
            print("トレンド投稿の取得に失敗: \(error.localizedDescription)")
        }
    }
    
    // MARK: - おすすめユーザー
    
    /// おすすめユーザーを取得
    private func loadRecommendedUsers() async {
        do {
            let users = try await fashionService.fetchRecommendedUsers(
                excludeUserId: currentUserId,
                limit: 20 // より多くのユーザーを取得して条件に合うものを選出
            )
            
            print("取得したユーザー数: \(users.count)")
            
            var recommendedData: [RecommendedUserData] = []
            
            for user in users {
                guard let userId = user.id else { continue }
                
                // ユーザーのトップ投稿を取得（エラーが発生しても継続）
                let topPosts: [Post]
                do {
                    topPosts = try await fashionService.fetchUserTopPosts(userId: userId, limit: 2)
                } catch {
                    print("ユーザー \(user.displayName) の投稿取得に失敗: \(error.localizedDescription)")
                    continue
                }
                
                print("ユーザー \(user.displayName) の投稿数: \(topPosts.count)")
                
                // 投稿が1件以上あるユーザーを表示（1件の場合は同じ画像を両方に表示）
                guard topPosts.count >= 1 else { continue }
                
                // フォロー状態を確認（権限エラーの場合はfalseとして継続）
                var isFollowing = false
                if let currentId = currentUserId {
                    do {
                        isFollowing = try await fashionService.isFollowing(
                            targetUserId: userId,
                            currentUserId: currentId
                        )
                    } catch {
                        // 権限エラーなどの場合はフォロー状態を未フォローとして扱う
                        print("フォロー状態の確認に失敗（権限エラーの可能性）: \(error.localizedDescription)")
                        isFollowing = false
                    }
                }
                
                recommendedData.append(RecommendedUserData(
                    user: user,
                    topPosts: topPosts,
                    isFollowing: isFollowing
                ))
                
                // 最大5件まで
                if recommendedData.count >= 5 {
                    break
                }
            }
            
            print("おすすめユーザー最終件数: \(recommendedData.count)")
            recommendedUsers = recommendedData
        } catch {
            print("おすすめユーザーの取得に失敗: \(error.localizedDescription)")
        }
    }
    
    /// ユーザーをフォロー/アンフォロー
    /// - Parameter userData: 対象のおすすめユーザーデータ
    func toggleFollow(for userData: RecommendedUserData) async {
        guard let currentId = currentUserId,
              let targetId = userData.user.id else { return }
        
        do {
            if userData.isFollowing {
                try await fashionService.unfollowUser(
                    targetUserId: targetId,
                    currentUserId: currentId
                )
            } else {
                try await fashionService.followUser(
                    targetUserId: targetId,
                    currentUserId: currentId
                )
            }
            
            // UI更新
            if let index = recommendedUsers.firstIndex(where: { $0.id == userData.id }) {
                recommendedUsers[index].isFollowing.toggle()
            }
        } catch {
            print("フォロー操作に失敗: \(error.localizedDescription)")
        }
    }
    
    // MARK: - ランキング
    
    /// ランキング投稿を取得
    private func loadRankingPosts() async {
        do {
            let posts = try await fashionService.fetchWeeklyRanking(limit: 5)
            
            var rankedData: [RankedPost] = []
            
            for (index, post) in posts.enumerated() {
                // ユーザー情報を取得
                let user = try? await fashionService.fetchUser(userId: post.userId)
                
                // いいね状態を確認
                var isLiked = false
                if let postId = post.id, let currentId = currentUserId {
                    isLiked = try await postService.isPostLiked(postId: postId, userId: currentId)
                    likedPosts[postId] = isLiked
                }
                
                rankedData.append(RankedPost(
                    rank: index + 1,
                    post: post,
                    user: user,
                    isLiked: isLiked
                ))
            }
            
            rankingPosts = rankedData
        } catch {
            print("ランキングの取得に失敗: \(error.localizedDescription)")
        }
    }
    
    /// 投稿にいいねをトグル
    /// - Parameter rankedPost: 対象のランキング投稿
    func toggleLike(for rankedPost: RankedPost) async {
        guard let postId = rankedPost.post.id,
              let currentId = currentUserId else { return }
        
        do {
            let currentLiked = likedPosts[postId] ?? rankedPost.isLiked
            try await postService.toggleLike(
                postId: postId,
                userId: currentId,
                isLiked: currentLiked
            )
            
            // UI更新
            likedPosts[postId] = !currentLiked
            
            if let index = rankingPosts.firstIndex(where: { $0.id == rankedPost.id }) {
                rankingPosts[index].isLiked = !currentLiked
            }
        } catch {
            print("いいね操作に失敗: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 人気の検索
    
    /// 人気の検索ワードを取得
    private func loadPopularSearches() async {
        do {
            popularSearches = try await fashionService.fetchPopularSearches(limit: 5)
        } catch {
            print("人気の検索の取得に失敗: \(error.localizedDescription)")
        }
    }
}
