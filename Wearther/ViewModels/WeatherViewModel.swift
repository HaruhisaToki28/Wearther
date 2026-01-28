//
//  WeatherViewModel.swift
//  Wearther
//
//  Created by Wearther on 2026/01/23.
//

import Foundation
import Combine

/// 週間予報とおすすめコーデのペア
struct WeatherWeeklyOutfit: Identifiable {
    var id: String { forecast.id }
    let forecast: MediumRangeForecast
    let recommendedPost: Post?
    let postUser: AppUser?
}

/// 今日の気温に合うコーデ
struct WeatherTodayOutfit: Identifiable {
    var id: String { post.id ?? UUID().uuidString }
    let post: Post
    let user: AppUser?
    var isLiked: Bool
    let score: Double
}

/// 天気タブのViewModel
@MainActor
class WeatherViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// 週間予報とおすすめコーデ
    @Published var weeklyOutfits: [WeatherWeeklyOutfit] = []
    
    /// 今日の気温に合うコーデ
    @Published var todayOutfits: [WeatherTodayOutfit] = []
    
    /// ローディング状態
    @Published var isLoading = false
    
    /// いいね状態のキャッシュ
    @Published var likedPosts: [String: Bool] = [:]
    
    // MARK: - Private Properties
    
    private let postService = PostService.shared
    private let fashionService = FashionService.shared
    private var currentUserId: String?
    
    // MARK: - Public Methods
    
    /// おすすめコーデを取得
    /// - Parameters:
    ///   - forecasts: 週間予報
    ///   - currentTemperature: 現在の気温
    ///   - currentWeather: 現在の天気
    ///   - location: 現在地
    ///   - userId: 現在のユーザーID
    func loadOutfits(
        forecasts: [MediumRangeForecast],
        currentTemperature: Int,
        currentWeather: WeatherCondition,
        location: String,
        userId: String?
    ) async {
        currentUserId = userId
        isLoading = true
        
        // 並列でデータを取得
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.loadWeeklyOutfits(forecasts: forecasts, location: location)
            }
            group.addTask {
                await self.loadTodayOutfits(
                    currentTemperature: currentTemperature,
                    currentWeather: currentWeather,
                    location: location
                )
            }
        }
        
        isLoading = false
    }
    
    // MARK: - 週間予報&おすすめコーデ
    
    /// 週間予報とおすすめコーデを並列で取得
    private func loadWeeklyOutfits(forecasts: [MediumRangeForecast], location: String) async {
        let forecastsToProcess = Array(forecasts.prefix(7))
        
        // 並列でおすすめ投稿を取得
        let results = await withTaskGroup(of: (Int, Post?, AppUser?).self, returning: [(Int, Post?, AppUser?)].self) { group in
            for (index, forecast) in forecastsToProcess.enumerated() {
                group.addTask {
                    let postWeather = forecast.weatherCondition.toPostWeather()
                    let temperature = Int(forecast.maxtemp)
                    
                    do {
                        let recommendedPosts = try await self.postService.fetchRecommendedPosts(
                            currentTemperature: temperature,
                            currentWeather: postWeather,
                            currentLocation: location,
                            limit: 1
                        )
                        
                        let post = recommendedPosts.first
                        var postUser: AppUser? = nil
                        
                        if let post = post {
                            postUser = try? await self.fashionService.fetchUser(userId: post.userId)
                        }
                        
                        return (index, post, postUser)
                    } catch {
                        return (index, nil, nil)
                    }
                }
            }
            
            var results: [(Int, Post?, AppUser?)] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
        
        // インデックス順にソートして結果を構築
        let sortedResults = results.sorted { $0.0 < $1.0 }
        var outfits: [WeatherWeeklyOutfit] = []
        
        for (index, post, user) in sortedResults {
            outfits.append(WeatherWeeklyOutfit(
                forecast: forecastsToProcess[index],
                recommendedPost: post,
                postUser: user
            ))
        }
        
        weeklyOutfits = outfits
    }
    
    // MARK: - 今日の気温に合うコーデ
    
    /// 今日の気温に合うコーデを取得
    private func loadTodayOutfits(
        currentTemperature: Int,
        currentWeather: WeatherCondition,
        location: String
    ) async {
        do {
            let postWeather = currentWeather.toPostWeather()
            
            // おすすめ投稿を取得（スコア付き）
            let posts = try await postService.fetchRecommendedPostsWithScore(
                currentTemperature: currentTemperature,
                currentWeather: postWeather,
                currentLocation: location,
                limit: 20
            )
            
            var outfits: [WeatherTodayOutfit] = []
            
            for (post, score) in posts {
                let user = try? await fashionService.fetchUser(userId: post.userId)
                
                var isLiked = false
                if let postId = post.id, let currentId = currentUserId {
                    isLiked = (try? await postService.isPostLiked(postId: postId, userId: currentId)) ?? false
                    likedPosts[postId] = isLiked
                }
                
                outfits.append(WeatherTodayOutfit(
                    post: post,
                    user: user,
                    isLiked: isLiked,
                    score: score
                ))
            }
            
            todayOutfits = outfits
        } catch {
            print("今日のコーデの取得に失敗: \(error.localizedDescription)")
            todayOutfits = []
        }
    }
    
    // MARK: - いいね操作
    
    /// いいねをトグル
    func toggleLike(for outfit: WeatherTodayOutfit) async {
        guard let postId = outfit.post.id,
              let currentId = currentUserId else { return }
        
        let currentLiked = likedPosts[postId] ?? outfit.isLiked
        
        // 楽観的UI更新
        likedPosts[postId] = !currentLiked
        if let index = todayOutfits.firstIndex(where: { $0.id == outfit.id }) {
            todayOutfits[index].isLiked = !currentLiked
        }
        
        do {
            try await postService.toggleLike(
                postId: postId,
                userId: currentId,
                isLiked: currentLiked
            )
        } catch {
            // エラー時は元に戻す
            likedPosts[postId] = currentLiked
            if let index = todayOutfits.firstIndex(where: { $0.id == outfit.id }) {
                todayOutfits[index].isLiked = currentLiked
            }
            print("いいね操作に失敗: \(error.localizedDescription)")
        }
    }
    
    /// 投稿がいいね済みかどうか
    func isLiked(_ post: Post) -> Bool {
        guard let postId = post.id else { return false }
        return likedPosts[postId] ?? false
    }
}
