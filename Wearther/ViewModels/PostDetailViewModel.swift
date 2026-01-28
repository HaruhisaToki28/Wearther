//
//  PostDetailViewModel.swift
//  Wearther
//
//  Created by Wearther on 2026/01/22.
//

import Foundation
import Combine

/// 投稿詳細画面のViewModel
/// いいね状態、フォロー状態、ユーザー情報の管理を担当
@MainActor
class PostDetailViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// 投稿データ
    @Published var post: Post
    
    /// 投稿者のユーザー情報
    @Published var postUser: AppUser?
    
    /// いいね状態
    @Published var isLiked: Bool = false
    
    /// フォロー状態
    @Published var isFollowing: Bool = false
    
    /// ローディング状態
    @Published var isLoading: Bool = false
    
    /// エラーメッセージ
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let postService = PostService.shared
    private let fashionService = FashionService.shared
    private var currentUserId: String?
    
    // MARK: - Initialization
    
    /// 初期化
    /// - Parameter post: 表示する投稿データ
    init(post: Post) {
        self.post = post
    }
    
    // MARK: - Public Methods
    
    /// 詳細データを読み込む
    /// - Parameter currentUserId: 現在ログイン中のユーザーID
    func loadDetails(currentUserId: String?) async {
        self.currentUserId = currentUserId
        isLoading = true
        
        // 投稿者情報を取得
        await loadPostUser()
        
        // いいね状態を確認
        await checkLikeStatus()
        
        // フォロー状態を確認
        await checkFollowStatus()
        
        isLoading = false
    }
    
    /// いいねをトグル
    func toggleLike() async {
        guard let postId = post.id,
              let userId = currentUserId else { return }
        
        do {
            try await postService.toggleLike(
                postId: postId,
                userId: userId,
                isLiked: isLiked
            )
            
            // UI更新
            isLiked.toggle()
            
            // いいね数を更新
            if isLiked {
                post.likesCount += 1
            } else {
                post.likesCount -= 1
            }
        } catch {
            print("いいね操作に失敗: \(error.localizedDescription)")
            errorMessage = "いいねの更新に失敗しました"
        }
    }
    
    /// フォローをトグル
    func toggleFollow() async {
        guard let targetUserId = postUser?.id,
              let currentId = currentUserId,
              targetUserId != currentId else { return }
        
        // 楽観的UI更新
        let previousFollowState = isFollowing
        isFollowing.toggle()
        
        do {
            try await fashionService.toggleFollow(
                targetUserId: targetUserId,
                currentUserId: currentId,
                isCurrentlyFollowing: previousFollowState
            )
        } catch {
            // エラー時はUIを元に戻す
            isFollowing = previousFollowState
            errorMessage = "フォローの更新に失敗しました"
        }
    }
    
    // MARK: - Private Methods
    
    /// 投稿者情報を取得
    private func loadPostUser() async {
        do {
            postUser = try await fashionService.fetchUser(userId: post.userId)
        } catch {
            print("ユーザー情報の取得に失敗: \(error.localizedDescription)")
        }
    }
    
    /// いいね状態を確認
    private func checkLikeStatus() async {
        guard let postId = post.id,
              let userId = currentUserId else { return }
        
        do {
            isLiked = try await postService.isPostLiked(postId: postId, userId: userId)
        } catch {
            print("いいね状態の確認に失敗: \(error.localizedDescription)")
            isLiked = false
        }
    }
    
    /// フォロー状態を確認
    private func checkFollowStatus() async {
        guard let targetUserId = postUser?.id,
              let currentId = currentUserId,
              targetUserId != currentId else { return }
        
        do {
            isFollowing = try await fashionService.isFollowing(
                targetUserId: targetUserId,
                currentUserId: currentId
            )
        } catch {
            print("フォロー状態の確認に失敗: \(error.localizedDescription)")
            isFollowing = false
        }
    }
    
    // MARK: - Computed Properties
    
    /// 投稿日を「M月d日」形式で取得
    var formattedDate: String {
        DateFormatterCache.monthDay.string(from: post.createdAt)
    }
    
    /// 性別表示用テキスト
    var genderText: String {
        return post.userGender
    }
    
    /// 日付と性別の組み合わせテキスト
    var dateAndGenderText: String {
        return "\(formattedDate) / \(genderText)"
    }
    
    /// 自分の投稿かどうか
    var isOwnPost: Bool {
        return currentUserId == post.userId
    }
}
