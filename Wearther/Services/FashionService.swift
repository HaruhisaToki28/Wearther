//
//  FashionService.swift
//  Wearther
//
//  Created by Wearther on 2026/01/22.
//

import Foundation
import FirebaseFirestore
import Combine

/// ファッションタブ専用のサービスクラス
/// トレンド投稿、おすすめユーザー、ランキング、人気の検索を取得
@MainActor
class FashionService: ObservableObject {
    static let shared = FashionService()
    
    private let db = Firestore.firestore()
    
    // MARK: - User Cache
    
    /// ユーザー情報のキャッシュ（キー: userId）
    private let userCache = NSCache<NSString, CachedUser>()
    
    /// キャッシュの有効期限（秒）
    private let cacheExpirationSeconds: TimeInterval = 300 // 5分
    
    private init() {
        // キャッシュの設定
        userCache.countLimit = 100 // 最大100ユーザーまでキャッシュ
    }
    
    /// キャッシュをクリア
    func clearUserCache() {
        userCache.removeAllObjects()
        print("User cache cleared")
    }
    
    /// 特定ユーザーのキャッシュを無効化
    func invalidateUserCache(userId: String) {
        userCache.removeObject(forKey: userId as NSString)
    }
    
    // MARK: - 今日のトレンド
    
    /// 今日1日で最もいいねが増えた投稿を取得（0時更新）
    /// - Parameter limit: 取得する最大件数（デフォルト5件）
    /// - Returns: トレンド投稿の配列
    func fetchTodaysTrends(limit: Int = 5) async throws -> [Post] {
        // 今日の0時を取得
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        
        // 今日作成された投稿をいいね数順で取得
        // 注意: 実際の「今日1日でいいねが増えた数」を計測するには、
        // 別途いいね履歴を管理する必要がありますが、
        // 現時点では今日の投稿のいいね数で代用します
        let snapshot = try await db.collection("posts")
            .whereField("createdAt", isGreaterThanOrEqualTo: Timestamp(date: startOfToday))
            .order(by: "createdAt", descending: false)
            .getDocuments()
        
        // いいね数でソートして上位を取得
        var posts = snapshot.documents.compactMap { doc in
            try? doc.data(as: Post.self)
        }
        
        // 投稿が少ない場合は全投稿からいいね数順で取得
        if posts.count < limit {
            let allPostsSnapshot = try await db.collection("posts")
                .order(by: "likesCount", descending: true)
                .limit(to: limit)
                .getDocuments()
            
            posts = allPostsSnapshot.documents.compactMap { doc in
                try? doc.data(as: Post.self)
            }
        } else {
            // いいね数でソート
            posts.sort { $0.likesCount > $1.likesCount }
            posts = Array(posts.prefix(limit))
        }
        
        return posts
    }
    
    // MARK: - おすすめユーザー
    
    /// ランダムでおすすめユーザーを取得
    /// - Parameters:
    ///   - excludeUserId: 除外するユーザーID（自分自身）
    ///   - limit: 取得する最大件数
    /// - Returns: おすすめユーザーの配列
    func fetchRecommendedUsers(excludeUserId: String?, limit: Int = 10) async throws -> [AppUser] {
        // 全ユーザーを取得してランダムに選出
        // 注意: 大規模なアプリではより効率的な方法が必要
        let query = db.collection("users")
            .limit(to: 50)
        
        let snapshot = try await query.getDocuments()
        
        print("Firebaseから取得したユーザー数: \(snapshot.documents.count)")
        
        var users = snapshot.documents.compactMap { doc -> AppUser? in
            do {
                let user = try doc.data(as: AppUser.self)
                return user
            } catch {
                print("ユーザーのデコードに失敗: \(error.localizedDescription)")
                return nil
            }
        }
        
        print("デコードに成功したユーザー数: \(users.count)")
        
        // 自分自身を除外
        if let excludeId = excludeUserId {
            users = users.filter { $0.id != excludeId }
        }
        
        // postsCountでのフィルタリングは行わない
        // （実際の投稿有無はViewModelで確認する）
        
        // ランダムにシャッフルして指定件数を返す
        users.shuffle()
        return Array(users.prefix(limit))
    }
    
    /// ユーザーの最も人気のある投稿を取得
    /// - Parameters:
    ///   - userId: ユーザーID
    ///   - limit: 取得する最大件数
    /// - Returns: 投稿の配列
    func fetchUserTopPosts(userId: String, limit: Int = 2) async throws -> [Post] {
        // 複合インデックスを避けるため、フィルタのみでクエリしてメモリでソート
        let snapshot = try await db.collection("posts")
            .whereField("userId", isEqualTo: userId)
            .limit(to: 20) // 十分な件数を取得
            .getDocuments()
        
        var posts = snapshot.documents.compactMap { doc in
            try? doc.data(as: Post.self)
        }
        
        // いいね数でソートして上位を返す
        posts.sort { $0.likesCount > $1.likesCount }
        return Array(posts.prefix(limit))
    }
    
    // MARK: - ランキング
    
    /// 今週1週間で最もいいねがついた投稿を取得
    /// - Parameter limit: 取得する最大件数（デフォルト5件）
    /// - Returns: ランキング投稿の配列
    func fetchWeeklyRanking(limit: Int = 5) async throws -> [Post] {
        // 今週の開始日（月曜日）を取得
        let calendar = Calendar.current
        let now = Date()
        
        // 今週の開始日を計算
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        components.weekday = 2 // 月曜日
        let startOfWeek = calendar.date(from: components) ?? calendar.date(byAdding: .day, value: -7, to: now)!
        
        // 今週作成された投稿をいいね数順で取得
        let snapshot = try await db.collection("posts")
            .whereField("createdAt", isGreaterThanOrEqualTo: Timestamp(date: startOfWeek))
            .getDocuments()
        
        var posts = snapshot.documents.compactMap { doc in
            try? doc.data(as: Post.self)
        }
        
        // 投稿が少ない場合は全投稿からいいね数順で取得
        if posts.count < limit {
            let allPostsSnapshot = try await db.collection("posts")
                .order(by: "likesCount", descending: true)
                .limit(to: limit)
                .getDocuments()
            
            posts = allPostsSnapshot.documents.compactMap { doc in
                try? doc.data(as: Post.self)
            }
        } else {
            // いいね数でソート
            posts.sort { $0.likesCount > $1.likesCount }
            posts = Array(posts.prefix(limit))
        }
        
        return posts
    }
    
    // MARK: - 人気の検索
    
    /// 今週最も検索されているワードを取得
    /// - Parameter limit: 取得する最大件数（デフォルト5件）
    /// - Returns: 検索クエリの配列
    func fetchPopularSearches(limit: Int = 5) async throws -> [SearchQuery] {
        let snapshot = try await db.collection("searchQueries")
            .order(by: "weeklySearchCount", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: SearchQuery.self)
        }
    }
    
    /// 検索キーワードをカウントアップ
    /// - Parameter keyword: 検索キーワード
    func incrementSearchCount(keyword: String) async throws {
        let normalizedKeyword = keyword.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedKeyword.isEmpty else { return }
        
        // 既存のキーワードを検索
        let snapshot = try await db.collection("searchQueries")
            .whereField("keyword", isEqualTo: normalizedKeyword)
            .limit(to: 1)
            .getDocuments()
        
        if let doc = snapshot.documents.first {
            // 既存のキーワードをカウントアップ
            try await db.collection("searchQueries").document(doc.documentID).updateData([
                "weeklySearchCount": FieldValue.increment(Int64(1)),
                "totalSearchCount": FieldValue.increment(Int64(1)),
                "updatedAt": Timestamp()
            ])
        } else {
            // 新しいキーワードを作成
            let searchQuery = SearchQuery(
                keyword: normalizedKeyword,
                weeklySearchCount: 1,
                totalSearchCount: 1,
                updatedAt: Date()
            )
            try db.collection("searchQueries").addDocument(from: searchQuery)
        }
    }
    
    // MARK: - ユーザー情報取得
    
    /// ユーザーIDからユーザー情報を取得（キャッシュ対応）
    /// - Parameters:
    ///   - userId: ユーザーID
    ///   - forceRefresh: キャッシュを無視して強制的に再取得するかどうか
    /// - Returns: ユーザー情報
    func fetchUser(userId: String, forceRefresh: Bool = false) async throws -> AppUser? {
        let cacheKey = userId as NSString
        
        // キャッシュをチェック（強制リフレッシュでない場合）
        if !forceRefresh, let cachedUser = userCache.object(forKey: cacheKey) {
            // 有効期限をチェック
            if Date().timeIntervalSince(cachedUser.cachedAt) < cacheExpirationSeconds {
                return cachedUser.user
            }
            // 期限切れの場合はキャッシュから削除
            userCache.removeObject(forKey: cacheKey)
        }
        
        // Firestoreから取得
        let doc = try await db.collection("users").document(userId).getDocument()
        guard let user = try? doc.data(as: AppUser.self) else {
            return nil
        }
        
        // キャッシュに保存
        let cachedUser = CachedUser(user: user, cachedAt: Date())
        userCache.setObject(cachedUser, forKey: cacheKey)
        
        return user
    }
    
    // MARK: - フォロー機能
    
    /// ユーザーをフォローする
    /// - Parameters:
    ///   - targetUserId: フォロー対象のユーザーID
    ///   - currentUserId: 現在のユーザーID
    func followUser(targetUserId: String, currentUserId: String) async throws {
        let batch = db.batch()
        
        // フォロー関係を作成
        let followRef = db.collection("users").document(currentUserId)
            .collection("following").document(targetUserId)
        batch.setData(["followedAt": Timestamp()], forDocument: followRef)
        
        // フォロワー関係を作成
        let followerRef = db.collection("users").document(targetUserId)
            .collection("followers").document(currentUserId)
        batch.setData(["followedAt": Timestamp()], forDocument: followerRef)
        
        // フォロー数を更新
        let currentUserRef = db.collection("users").document(currentUserId)
        batch.updateData(["followingCount": FieldValue.increment(Int64(1))], forDocument: currentUserRef)
        
        // フォロワー数を更新
        let targetUserRef = db.collection("users").document(targetUserId)
        batch.updateData(["followersCount": FieldValue.increment(Int64(1))], forDocument: targetUserRef)
        
        try await batch.commit()
    }
    
    /// ユーザーのフォローを解除する
    /// - Parameters:
    ///   - targetUserId: フォロー解除対象のユーザーID
    ///   - currentUserId: 現在のユーザーID
    func unfollowUser(targetUserId: String, currentUserId: String) async throws {
        let batch = db.batch()
        
        // フォロー関係を削除
        let followRef = db.collection("users").document(currentUserId)
            .collection("following").document(targetUserId)
        batch.deleteDocument(followRef)
        
        // フォロワー関係を削除
        let followerRef = db.collection("users").document(targetUserId)
            .collection("followers").document(currentUserId)
        batch.deleteDocument(followerRef)
        
        // フォロー数を更新
        let currentUserRef = db.collection("users").document(currentUserId)
        batch.updateData(["followingCount": FieldValue.increment(Int64(-1))], forDocument: currentUserRef)
        
        // フォロワー数を更新
        let targetUserRef = db.collection("users").document(targetUserId)
        batch.updateData(["followersCount": FieldValue.increment(Int64(-1))], forDocument: targetUserRef)
        
        try await batch.commit()
    }
    
    /// ユーザーをフォローしているかチェック
    /// - Parameters:
    ///   - targetUserId: チェック対象のユーザーID
    ///   - currentUserId: 現在のユーザーID
    /// - Returns: フォローしているかどうか
    func isFollowing(targetUserId: String, currentUserId: String) async throws -> Bool {
        let doc = try await db.collection("users").document(currentUserId)
            .collection("following").document(targetUserId).getDocument()
        return doc.exists
    }
    
    // MARK: - 検索機能
    
    /// 投稿を検索
    /// タイトル、キャプション、場所名で部分一致検索
    /// - Parameters:
    ///   - query: 検索クエリ
    ///   - limit: 取得する最大件数（デフォルト50件）
    /// - Returns: 検索結果の投稿配列
    /// - Note: Firestoreは部分一致検索をサポートしていないため、
    ///         全件取得してクライアント側でフィルタリングします。
    ///         大規模データの場合はAlgoliaなどの検索サービスの導入を推奨。
    func searchPosts(query: String, limit: Int = 50) async throws -> [Post] {
        let normalizedQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else { return [] }
        
        // 全投稿を取得（最新順）
        let snapshot = try await db.collection("posts")
            .order(by: "createdAt", descending: true)
            .limit(to: 200) // パフォーマンスのため上限を設定
            .getDocuments()
        
        var posts = snapshot.documents.compactMap { doc in
            try? doc.data(as: Post.self)
        }
        
        // クライアント側でフィルタリング
        posts = posts.filter { post in
            post.title.lowercased().contains(normalizedQuery) ||
            post.caption.lowercased().contains(normalizedQuery) ||
            post.location.name.lowercased().contains(normalizedQuery)
        }
        
        return Array(posts.prefix(limit))
    }
    
    /// ユーザーを検索
    /// ユーザー名（username）、表示名（displayName）で部分一致検索
    /// - Parameters:
    ///   - query: 検索クエリ
    ///   - limit: 取得する最大件数（デフォルト30件）
    /// - Returns: 検索結果のユーザー配列
    func searchUsers(query: String, limit: Int = 30) async throws -> [AppUser] {
        let normalizedQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else { return [] }
        
        // 全ユーザーを取得
        let snapshot = try await db.collection("users")
            .limit(to: 200) // パフォーマンスのため上限を設定
            .getDocuments()
        
        var users = snapshot.documents.compactMap { doc in
            try? doc.data(as: AppUser.self)
        }
        
        // クライアント側でフィルタリング
        users = users.filter { user in
            user.username.lowercased().contains(normalizedQuery) ||
            user.displayName.lowercased().contains(normalizedQuery)
        }
        
        // フォロワー数順でソート（人気順）
        users.sort { $0.followersCount > $1.followersCount }
        
        return Array(users.prefix(limit))
    }
    
    /// 検索結果の投稿に対応するユーザー情報を一括取得（キャッシュ対応）
    /// - Parameter posts: 投稿の配列
    /// - Returns: userIdをキーとするユーザー辞書
    func fetchUsersForPosts(_ posts: [Post]) async throws -> [String: AppUser] {
        // ユニークなuserIdを抽出
        let userIds = Array(Set(posts.map { $0.userId }))
        guard !userIds.isEmpty else { return [:] }
        
        var userDict: [String: AppUser] = [:]
        var uncachedUserIds: [String] = []
        
        // まずキャッシュをチェック
        for userId in userIds {
            let cacheKey = userId as NSString
            if let cachedUser = userCache.object(forKey: cacheKey),
               Date().timeIntervalSince(cachedUser.cachedAt) < cacheExpirationSeconds {
                // キャッシュヒット
                userDict[userId] = cachedUser.user
            } else {
                // キャッシュミス → Firestoreから取得が必要
                uncachedUserIds.append(userId)
            }
        }
        
        // キャッシュにないユーザーのみFirestoreから取得
        if !uncachedUserIds.isEmpty {
            let chunks = uncachedUserIds.chunked(into: 10)
            
            for chunk in chunks {
                let snapshot = try await db.collection("users")
                    .whereField(FieldPath.documentID(), in: chunk)
                    .getDocuments()
                
                for doc in snapshot.documents {
                    if let user = try? doc.data(as: AppUser.self) {
                        let userId = doc.documentID
                        userDict[userId] = user
                        
                        // キャッシュに保存
                        let cachedUser = CachedUser(user: user, cachedAt: Date())
                        userCache.setObject(cachedUser, forKey: userId as NSString)
                    }
                }
            }
        }
        
        return userDict
    }
}

// MARK: - Cache Helper

/// キャッシュ用のラッパークラス（NSCacheはclassのみ対応）
final class CachedUser: NSObject {
    let user: AppUser
    let cachedAt: Date
    
    init(user: AppUser, cachedAt: Date) {
        self.user = user
        self.cachedAt = cachedAt
    }
}

// MARK: - Array Extension

extension Array {
    /// 配列を指定サイズのチャンクに分割
    /// - Parameter size: チャンクサイズ
    /// - Returns: 分割された配列の配列
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
