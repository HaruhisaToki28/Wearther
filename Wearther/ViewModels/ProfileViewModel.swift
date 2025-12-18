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
    @Published var user = AppUser(
        username: "user_name",
        displayName: "読み込み中...",
        avatarURL: "",
        bio: "",
        postsCount: 0,
        followersCount: 0,
        followingCount: 0,
        gender: "未設定",
        location: "未設定",
        temperatureTolerance: "普通",
        email: "",
        createdAt: Date()
    )
    @Published var posts: [OutfitRecommendation] = []
    @Published var likedPosts: [OutfitRecommendation] = []
    @Published var selectedTab: ProfileTab = .posts
    
    @Published var isLoading = false
    private var db = Firestore.firestore()
    
    enum ProfileTab {
        case posts
        case likes
    }
    
    init() {
            fetchUserData()
        }
    
    func fetchUserData() {
            guard let uid = Auth.auth().currentUser?.uid else { return }

            db.collection("users").document(uid).addSnapshotListener { snapshot, error in
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
    
    func refresh() async {
        isLoading = true
        fetchUserData()
        try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
        isLoading = false
    }
}
