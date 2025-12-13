//
//  ProfileViewModel.swift
//  Wearther
//
//  Created by hato on 2025/11/07.
//

import Foundation
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var user: UserProfile
    @Published var posts: [OutfitRecommendation] = []
    @Published var likedPosts: [OutfitRecommendation] = []
    @Published var selectedTab: ProfileTab = .posts
    
    @Published var isLoading = false
    
    enum ProfileTab {
        case posts
        case likes
    }
    
    init() {
        // Mock Data
        self.user = UserProfile(
            id: "current_user",
            username: "tarou_01",
            displayName: "たろう",
            avatarURL: "https://images.unsplash.com/photo-1521572163474-6864f9cf17ab",
            bio: "プロフィール自由記入欄",
            postsCount: 120,
            followersCount: 3500,
            followingCount: 180
        )
        
        loadMockPosts()
    }
    
    func refresh() async {
        isLoading = true
        // 疑似的な遅延を追加
        try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
        // データを再読み込み（モックなので同じデータをセットし直すだけですが）
        loadMockPosts()
        isLoading = false
    }
    
    func loadMockPosts() {
        // Reuse some mock data logic or create new one
        let basePost = OutfitRecommendation(
            userId: "current_user",
            userName: "たろう",
            userAvatarSymbol: "person.crop.circle",
            userAvatarURL: "https://images.unsplash.com/photo-1521572163474-6864f9cf17ab",
            userHeight: 175,
            imageURL: "https://images.unsplash.com/photo-1521572163474-6864f9cf17ab",
            weatherSnapshot: WeatherSnapshot(temperature: 20.0, condition: .sunny),
            likes: 45,
            isLiked: false
        )
        
        posts = Array(repeating: basePost, count: 12).map { post in
            var newPost = post
            // Randomize slightly
            return newPost
        }
        
        likedPosts = Array(repeating: basePost, count: 5)
    }
}

struct UserProfile {
    let id: String
    let username: String
    let displayName: String
    let avatarURL: String
    let bio: String
    let postsCount: Int
    let followersCount: Int
    let followingCount: Int
}

