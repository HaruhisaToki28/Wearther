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
    
    @Published var posts: [OutfitRecommendation] = []
    @Published var likedPosts: [OutfitRecommendation] = []
    @Published var selectedTab: ProfileTab = .posts
    
    enum ProfileTab {
        case posts
        case likes
    }
    
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    

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
        

    deinit {
        listener?.remove()
    }
}
