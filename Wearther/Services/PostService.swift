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
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
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
