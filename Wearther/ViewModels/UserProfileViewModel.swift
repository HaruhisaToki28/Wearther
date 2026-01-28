//
//  UserProfileViewModel.swift
//  Wearther
//
//  Created by Wearther on 2026/01/22.
//

import Foundation
import Combine
import FirebaseFirestore

/// 他ユーザーのプロフィール表示用ViewModel
/// ユーザー情報、投稿、フォロー状態を管理
@MainActor
class UserProfileViewModel: ObservableObject {
    
    // MARK: - Tab Enum
    
    enum ProfileTab {
        case posts
        case likes
    }
    
    // MARK: - Published Properties
    
    /// 表示するユーザー情報
    @Published var user: AppUser?
    
    /// ユーザーの投稿一覧
    @Published var userPosts: [Post] = []
    
    /// ユーザーがいいねした投稿一覧
    @Published var likedPosts: [Post] = []
    
    /// 選択中のタブ
    @Published var selectedTab: ProfileTab = .posts
    
    /// フォロー状態
    @Published var isFollowing: Bool = false
    
    /// ローディング状態
    @Published var isLoading: Bool = false
    
    /// エラーメッセージ
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let db = Firestore.firestore()
    private let fashionService = FashionService.shared
    private let postService = PostService.shared
    private let userId: String
    private var currentUserId: String?
    
    // MARK: - Initialization
    
    /// 初期化
    /// - Parameter userId: 表示するユーザーのID
    init(userId: String) {
        self.userId = userId
    }
    
    // MARK: - Public Methods
    
    /// データを読み込む
    /// - Parameter currentUserId: 現在ログイン中のユーザーID
    func loadData(currentUserId: String?) async {
        self.currentUserId = currentUserId
        isLoading = true
        
        // ユーザー情報を取得
        await fetchUser()
        
        // フォロー状態を確認
        await checkFollowStatus()
        
        // 投稿を取得
        await fetchUserPosts()
        
        isLoading = false
    }
    
    /// データを更新
    func refresh() async {
        await fetchUser()
        await checkFollowStatus()
        await fetchUserPosts()
        
        if selectedTab == .likes {
            await fetchLikedPosts()
        }
    }
    
    /// いいねした投稿を取得
    /// 注意: 他ユーザーのいいね一覧は権限エラーになる場合がある
    func fetchLikedPosts() async {
        // 自分のプロフィールでない場合は取得をスキップ（プライバシー保護）
        guard let currentId = currentUserId, currentId == userId else {
            print("他ユーザーのいいね一覧は非公開です")
            likedPosts = []
            return
        }
        
        do {
            // ユーザーがいいねした投稿IDを取得
            let likesSnapshot = try await db.collection("users")
                .document(userId)
                .collection("likedPosts")
                .limit(to: 50)
                .getDocuments()
            
            let postIds = likesSnapshot.documents.map { $0.documentID }
            guard !postIds.isEmpty else {
                likedPosts = []
                return
            }
            
            // バッチで投稿を取得（Firestoreのinクエリは最大10件なので分割）
            var posts: [Post] = []
            let chunks = postIds.chunked(into: 10)
            
            for chunk in chunks {
                let snapshot = try await db.collection("posts")
                    .whereField(FieldPath.documentID(), in: chunk)
                    .getDocuments()
                
                let chunkPosts = snapshot.documents.compactMap { doc in
                    try? doc.data(as: Post.self)
                }
                posts.append(contentsOf: chunkPosts)
            }
            
            // 日時でソート（新しい順）
            posts.sort { $0.createdAt > $1.createdAt }
            
            likedPosts = posts
        } catch {
            print("いいねした投稿の取得に失敗: \(error.localizedDescription)")
            likedPosts = []
        }
    }
    
    /// フォローをトグル
    func toggleFollow() async {
        guard let currentId = currentUserId,
              currentId != userId else {
            print("フォロー操作をスキップ: 自分自身またはログインしていない")
            return
        }
        
        // 楽観的UI更新（先にUIを更新）
        let previousFollowState = isFollowing
        isFollowing.toggle()
        
        // フォロワー数を先に更新
        if var updatedUser = user {
            if isFollowing {
                updatedUser.followersCount += 1
            } else {
                updatedUser.followersCount = max(0, updatedUser.followersCount - 1)
            }
            user = updatedUser
        }
        
        do {
            if previousFollowState {
                // フォロー解除
                try await fashionService.unfollowUser(
                    targetUserId: userId,
                    currentUserId: currentId
                )
                print("フォロー解除成功: \(userId)")
            } else {
                // フォロー
                try await fashionService.followUser(
                    targetUserId: userId,
                    currentUserId: currentId
                )
                print("フォロー成功: \(userId)")
            }
        } catch {
            // エラー時はUIを元に戻す
            print("フォロー操作に失敗: \(error.localizedDescription)")
            isFollowing = previousFollowState
            
            // フォロワー数も元に戻す
            if var updatedUser = user {
                if previousFollowState {
                    updatedUser.followersCount += 1
                } else {
                    updatedUser.followersCount = max(0, updatedUser.followersCount - 1)
                }
                user = updatedUser
            }
            errorMessage = "フォローの更新に失敗しました"
        }
    }
    
    // MARK: - Private Methods
    
    /// ユーザー情報を取得
    private func fetchUser() async {
        do {
            user = try await fashionService.fetchUser(userId: userId)
        } catch {
            print("ユーザー情報の取得に失敗: \(error.localizedDescription)")
            errorMessage = "ユーザー情報の取得に失敗しました"
        }
    }
    
    /// フォロー状態を確認
    private func checkFollowStatus() async {
        guard let currentId = currentUserId,
              currentId != userId else {
            isFollowing = false
            return
        }
        
        do {
            isFollowing = try await fashionService.isFollowing(
                targetUserId: userId,
                currentUserId: currentId
            )
        } catch {
            print("フォロー状態の確認に失敗: \(error.localizedDescription)")
            isFollowing = false
        }
    }
    
    /// ユーザーの投稿を取得
    private func fetchUserPosts() async {
        do {
            userPosts = try await postService.fetchUserPosts(userId: userId, limit: 50)
        } catch {
            print("投稿の取得に失敗: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Computed Properties
    
    /// 自分のプロフィールかどうか
    var isOwnProfile: Bool {
        return currentUserId == userId
    }
    
    /// フォーマットされた数値を返す
    func formatCount(_ count: Int) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter.string(from: NSNumber(value: count)) ?? "\(count)"
    }
}
