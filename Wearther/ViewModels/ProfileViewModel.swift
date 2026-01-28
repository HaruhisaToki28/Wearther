//
//  ProfileViewModel.swift
//  Wearther
//
//  Created by hato on 2025/11/07.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

@MainActor
class ProfileViewModel: ObservableObject {

    @Published var user: AppUser? = nil
    @Published var isLoading = false
    
    @Published var userPosts: [Post] = []
    @Published var likedPosts: [Post] = []
    @Published var selectedTab: ProfileTab = .posts
    
    /// リスナーがアクティブかどうか
    @Published private(set) var isListening = false
    
    enum ProfileTab {
        case posts
        case likes
    }
    
    private var db = Firestore.firestore()
    private var userListener: ListenerRegistration?
    private var postsListener: ListenerRegistration?
    

    init() {
        startListening()
    }
    
    // MARK: - Listener Management
    
    /// リスナーを開始（画面表示時に呼び出し）
    func startListening() {
        guard !isListening else { return }
        isListening = true
        
        fetchUserData()
        fetchUserPosts()
    }
    
    /// リスナーを停止（画面非表示時に呼び出し）
    func stopListening() {
        userListener?.remove()
        userListener = nil
        
        postsListener?.remove()
        postsListener = nil
        
        isListening = false
    }

    private func fetchUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // 既存のリスナーを解除してから新しいリスナーを登録
        userListener?.remove()
        
        userListener = db.collection("users").document(uid).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            guard let document = snapshot, document.exists else {
                print("ユーザーデータが見つかりません")
                return
            }
            
            do {
                self.user = try document.data(as: AppUser.self)
            } catch {
                print("デコードエラー: \(error)")
            }
        }
    }
    
    private func fetchUserPosts() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // 既存のリスナーを解除してから新しいリスナーを登録
        postsListener?.remove()
        
        postsListener = db.collection("posts")
            .whereField("userId", isEqualTo: uid)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                guard let documents = snapshot?.documents else {
                    print("投稿データが見つかりません: \(error?.localizedDescription ?? "")")
                    return
                }
                
                self.userPosts = documents.compactMap { doc in
                    try? doc.data(as: Post.self)
                }
            }
    }
    
    func fetchLikedPosts() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        do {
            // Get liked post IDs
            let likedSnapshot = try await db.collection("users")
                .document(uid)
                .collection("likedPosts")
                .order(by: "likedAt", descending: true)
                .getDocuments()
            
            let postIds = likedSnapshot.documents.map { $0.documentID }
            guard !postIds.isEmpty else {
                self.likedPosts = []
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
            
            // 元の順序（likedAtの降順）を維持するためにソート
            let orderedPosts = postIds.compactMap { id in
                posts.first { $0.id == id }
            }
            
            self.likedPosts = orderedPosts
        } catch {
            print("いいねした投稿の取得エラー: \(error)")
        }
    }
    
    /// データを更新
    func refresh() async {
        isLoading = true
        // リスナーを再起動して最新データを取得
        stopListening()
        startListening()
        await fetchLikedPosts()
        isLoading = false
    }
    
    deinit {
        // メインスレッドでリスナーを解除
        userListener?.remove()
        postsListener?.remove()
    }
}
