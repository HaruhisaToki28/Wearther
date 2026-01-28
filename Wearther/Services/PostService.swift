//
//  PostService.swift
//  Wearther
//
//  Created by Wearther on 2026/01/16.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage
import UIKit
import Combine

@MainActor
class PostService: ObservableObject {
    static let shared = PostService()
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    
    private init() {}
    
    // MARK: - Upload Image to Firebase Storage
    func uploadImage(_ image: UIImage, userId: String) async throws -> String {
        // 画像をリサイズ（長辺1200px以下、JPEG品質80%）
        guard let imageData = image.resizedForPost(maxDimension: 1200, compressionQuality: 0.8) else {
            throw PostServiceError.imageConversionFailed
        }
        
        let fileName = "\(UUID().uuidString).jpg"
        let storageRef = storage.reference().child("posts/\(userId)/\(fileName)")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // Upload with progress tracking
        return try await withCheckedThrowingContinuation { continuation in
            let uploadTask = storageRef.putData(imageData, metadata: metadata)
            
            uploadTask.observe(.progress) { [weak self] snapshot in
                guard let progress = snapshot.progress else { return }
                Task { @MainActor in
                    self?.uploadProgress = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                }
            }
            
            uploadTask.observe(.success) { _ in
                storageRef.downloadURL { url, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let url = url {
                        continuation.resume(returning: url.absoluteString)
                    } else {
                        continuation.resume(throwing: PostServiceError.uploadFailed)
                    }
                }
            }
            
            uploadTask.observe(.failure) { snapshot in
                if let error = snapshot.error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: PostServiceError.uploadFailed)
                }
            }
        }
    }
    
    // MARK: - Create Post
    func createPost(
        userId: String,
        image: UIImage,
        title: String,
        caption: String,
        weather: PostWeather,
        temperature: Int,
        location: PostLocation,
        userGender: String,
        userAge: Int,
        userHeight: Int
    ) async throws -> String {
        isUploading = true
        uploadProgress = 0.0
        
        defer {
            isUploading = false
        }
        
        // 1. Upload image
        let imageURL = try await uploadImage(image, userId: userId)
        
        // 2. Create post document
        let post = Post(
            userId: userId,
            imageURL: imageURL,
            title: title,
            caption: caption,
            weather: weather,
            temperature: temperature,
            location: location,
            userGender: userGender,
            userAge: userAge,
            userHeight: userHeight,
            likesCount: 0,
            createdAt: Date()
        )
        
        // 3. Save to Firestore
        let docRef = try db.collection("posts").addDocument(from: post)
        
        // 4. Update user's posts count
        try await db.collection("users").document(userId).updateData([
            "postsCount": FieldValue.increment(Int64(1))
        ])
        
        return docRef.documentID
    }
    
    // MARK: - Fetch Posts
    func fetchPosts(limit: Int = 20) async throws -> [Post] {
        let snapshot = try await db.collection("posts")
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: Post.self)
        }
    }
    
    // MARK: - Fetch Recommended Posts (天気ベースのおすすめ)
    /// 現在の天気に基づいておすすめの投稿を取得
    /// 条件: 気温差5度以内の投稿のみ
    /// 優先順位: 気温(高) > 天気(中) > 場所(低)
    func fetchRecommendedPosts(
        currentTemperature: Int,
        currentWeather: PostWeather,
        currentLocation: String,
        limit: Int = 50
    ) async throws -> [Post] {
        // 全投稿を取得（パフォーマンスのため上限設定）
        let snapshot = try await db.collection("posts")
            .order(by: "createdAt", descending: true)
            .limit(to: 200)
            .getDocuments()
        
        let allPosts = snapshot.documents.compactMap { doc in
            try? doc.data(as: Post.self)
        }
        
        // 気温差が5度以内の投稿のみをフィルタリング
        let filteredPosts = allPosts.filter { post in
            let tempDiff = abs(post.temperature - currentTemperature)
            return tempDiff <= 5
        }
        
        // スコア計算してソート
        let scoredPosts = filteredPosts.map { post -> (post: Post, score: Double) in
            let score = calculateRecommendationScore(
                post: post,
                currentTemperature: currentTemperature,
                currentWeather: currentWeather,
                currentLocation: currentLocation
            )
            return (post, score)
        }
        
        // スコアの高い順にソート
        let sortedPosts = scoredPosts.sorted { $0.score > $1.score }
        
        return Array(sortedPosts.prefix(limit).map { $0.post })
    }
    
    /// おすすめ投稿をスコア付きで取得
    func fetchRecommendedPostsWithScore(
        currentTemperature: Int,
        currentWeather: PostWeather,
        currentLocation: String,
        limit: Int = 50
    ) async throws -> [(post: Post, score: Double)] {
        // 全投稿を取得
        let snapshot = try await db.collection("posts")
            .order(by: "createdAt", descending: true)
            .limit(to: 200)
            .getDocuments()
        
        let allPosts = snapshot.documents.compactMap { doc in
            try? doc.data(as: Post.self)
        }
        
        // 気温差が5度以内の投稿のみをフィルタリング
        let filteredPosts = allPosts.filter { post in
            let tempDiff = abs(post.temperature - currentTemperature)
            return tempDiff <= 5
        }
        
        // スコア計算してソート
        let scoredPosts = filteredPosts.map { post -> (post: Post, score: Double) in
            let score = calculateRecommendationScore(
                post: post,
                currentTemperature: currentTemperature,
                currentWeather: currentWeather,
                currentLocation: currentLocation
            )
            return (post, score)
        }
        
        // スコアの高い順にソート
        let sortedPosts = scoredPosts.sorted { $0.score > $1.score }
        
        return Array(sortedPosts.prefix(limit))
    }
    
    /// おすすめスコアを計算
    /// 気温: 重み高（0-50点）、天気: 重み中（0-30点）、場所: 重み低（0-20点）
    private func calculateRecommendationScore(
        post: Post,
        currentTemperature: Int,
        currentWeather: PostWeather,
        currentLocation: String
    ) -> Double {
        var score: Double = 0
        
        // 気温スコア（重み: 高）
        // 気温差が小さいほど高スコア（最大50点）
        let tempDiff = abs(post.temperature - currentTemperature)
        let tempScore = max(0, 50 - Double(tempDiff) * 5) // 1度差ごとに5点減点
        score += tempScore
        
        // 天気スコア（重み: 中）
        // 同じ天気なら30点、近い天気なら15点
        if post.weather == currentWeather {
            score += 30
        } else if isSimilarWeather(post.weather, currentWeather) {
            score += 15
        }
        
        // 場所スコア（重み: 低）
        // 同じ都道府県なら20点、近い地域なら10点
        if post.location.name.contains(currentLocation) || currentLocation.contains(post.location.name) {
            score += 20
        } else if isSameRegion(post.location.name, currentLocation) {
            score += 10
        }
        
        return score
    }
    
    /// 似た天気かどうか判定
    private func isSimilarWeather(_ weather1: PostWeather, _ weather2: PostWeather) -> Bool {
        let similarGroups: [[PostWeather]] = [
            [.sunny, .cloudy],  // 晴れと曇りは近い
            [.rainy, .cloudy],  // 雨と曇りは近い
        ]
        
        for group in similarGroups {
            if group.contains(weather1) && group.contains(weather2) {
                return true
            }
        }
        return false
    }
    
    /// 同じ地域かどうか判定（簡易版）
    private func isSameRegion(_ location1: String, _ location2: String) -> Bool {
        let regions: [[String]] = [
            ["北海道"],
            ["青森県", "岩手県", "宮城県", "秋田県", "山形県", "福島県"], // 東北
            ["茨城県", "栃木県", "群馬県", "埼玉県", "千葉県", "東京都", "神奈川県"], // 関東
            ["新潟県", "富山県", "石川県", "福井県", "山梨県", "長野県", "岐阜県", "静岡県", "愛知県"], // 中部
            ["三重県", "滋賀県", "京都府", "大阪府", "兵庫県", "奈良県", "和歌山県"], // 近畿
            ["鳥取県", "島根県", "岡山県", "広島県", "山口県"], // 中国
            ["徳島県", "香川県", "愛媛県", "高知県"], // 四国
            ["福岡県", "佐賀県", "長崎県", "熊本県", "大分県", "宮崎県", "鹿児島県"], // 九州
            ["沖縄県"]
        ]
        
        for region in regions {
            let contains1 = region.contains { location1.contains($0) }
            let contains2 = region.contains { location2.contains($0) }
            if contains1 && contains2 {
                return true
            }
        }
        return false
    }
    
    // MARK: - Fetch Following Posts (フォロー中ユーザーの投稿)
    /// フォロー中ユーザーの過去7日間の投稿を取得
    func fetchFollowingPosts(userId: String, limit: Int = 50) async throws -> [Post] {
        // 1. フォロー中のユーザーIDを取得
        let followingIds = try await fetchFollowingUserIds(userId: userId)
        
        if followingIds.isEmpty {
            return []
        }
        
        // 2. 過去7日間の日付を計算
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        // 3. フォロー中ユーザーの投稿を取得
        // Firestoreの「in」クエリは最大10件なので、分割して取得
        var allPosts: [Post] = []
        let chunks = followingIds.chunked(into: 10)
        
        for chunk in chunks {
            let snapshot = try await db.collection("posts")
                .whereField("userId", in: chunk)
                .whereField("createdAt", isGreaterThanOrEqualTo: Timestamp(date: sevenDaysAgo))
                .getDocuments()
            
            let posts = snapshot.documents.compactMap { doc in
                try? doc.data(as: Post.self)
            }
            allPosts.append(contentsOf: posts)
        }
        
        // 作成日時でソート（新しい順）
        allPosts.sort { $0.createdAt > $1.createdAt }
        
        return Array(allPosts.prefix(limit))
    }
    
    // MARK: - Fetch Following User IDs
    /// ユーザーがフォローしているユーザーのIDリストを取得
    func fetchFollowingUserIds(userId: String) async throws -> [String] {
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("following")
            .getDocuments()
        
        return snapshot.documents.map { $0.documentID }
    }
    
    // MARK: - Check if user has following
    /// ユーザーがフォロー中のユーザーを持っているかチェック
    func hasFollowing(userId: String) async throws -> Bool {
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("following")
            .limit(to: 1)
            .getDocuments()
        
        return !snapshot.documents.isEmpty
    }
    
    // MARK: - Fetch User's Posts
    func fetchUserPosts(userId: String, limit: Int = 20) async throws -> [Post] {
        // 複合インデックスを避けるため、フィルタのみでクエリしてメモリでソート
        let snapshot = try await db.collection("posts")
            .whereField("userId", isEqualTo: userId)
            .limit(to: 100) // 十分な件数を取得
            .getDocuments()
        
        var posts = snapshot.documents.compactMap { doc in
            try? doc.data(as: Post.self)
        }
        
        // 作成日時でソート（新しい順）
        posts.sort { $0.createdAt > $1.createdAt }
        
        return Array(posts.prefix(limit))
    }
    
    // MARK: - Delete Post
    func deletePost(postId: String, userId: String, imageURL: String) async throws {
        // 1. Delete from Firestore
        try await db.collection("posts").document(postId).delete()
        
        // 2. Delete image from Storage
        if let url = URL(string: imageURL) {
            let storageRef = storage.reference(forURL: imageURL)
            try await storageRef.delete()
        }
        
        // 3. Update user's posts count
        try await db.collection("users").document(userId).updateData([
            "postsCount": FieldValue.increment(Int64(-1))
        ])
    }
    
    // MARK: - Like/Unlike Post
    func toggleLike(postId: String, userId: String, isLiked: Bool) async throws {
        let increment: Int64 = isLiked ? -1 : 1
        
        try await db.collection("posts").document(postId).updateData([
            "likesCount": FieldValue.increment(increment)
        ])
        
        // Save like status in user's liked posts subcollection
        let likeRef = db.collection("users").document(userId).collection("likedPosts").document(postId)
        
        if isLiked {
            try await likeRef.delete()
        } else {
            try await likeRef.setData(["likedAt": Timestamp()])
        }
    }
    
    // MARK: - Check if user liked post
    func isPostLiked(postId: String, userId: String) async throws -> Bool {
        let doc = try await db.collection("users").document(userId).collection("likedPosts").document(postId).getDocument()
        return doc.exists
    }
}

// MARK: - Errors
enum PostServiceError: LocalizedError {
    case imageConversionFailed
    case uploadFailed
    case postNotFound
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "画像の変換に失敗しました"
        case .uploadFailed:
            return "画像のアップロードに失敗しました"
        case .postNotFound:
            return "投稿が見つかりません"
        }
    }
}
