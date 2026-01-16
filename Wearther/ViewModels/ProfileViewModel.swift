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
    
    enum ProfileTab {
        case posts
        case likes
    }
    
    private var db = Firestore.firestore()
    private var userListener: ListenerRegistration?
    private var postsListener: ListenerRegistration?
    

    init() {
        fetchUserData()
        fetchUserPosts()
    }

    func fetchUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        userListener = db.collection("users").document(uid).addSnapshotListener { snapshot, error in
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
    
    func fetchUserPosts() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        postsListener = db.collection("posts")
            .whereField("userId", isEqualTo: uid)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
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
            
            // Fetch each post
            var posts: [Post] = []
            for postId in postIds {
                if let post = try? await db.collection("posts").document(postId).getDocument(as: Post.self) {
                    posts.append(post)
                }
            }
            
            self.likedPosts = posts
        } catch {
            print("いいねした投稿の取得エラー: \(error)")
        }
    }
        
    func refresh() async {
        isLoading = true
        fetchUserData()
        fetchUserPosts()
        await fetchLikedPosts()
        isLoading = false
    }
        

    deinit {
        userListener?.remove()
        postsListener?.remove()
    }
}
