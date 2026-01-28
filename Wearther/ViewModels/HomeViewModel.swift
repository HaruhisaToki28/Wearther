//
//  HomeViewModel.swift
//  Wearther
//
//  Created by hato on 2025/11/07.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var weather: Weather?
    @Published var fashionAdvice: FashionAdvice?
    @Published var stories: [StoryProfile] = []
    @Published var isLoading = false
    @Published var isWeatherLoading = false
    @Published var isAdviceLoading = false
    @Published var error: Error?
    @Published var weatherError: String?
    
    /// ユーザーの居住地域が設定されているかどうか
    @Published var isLocationSet: Bool = false
    
    // MARK: - Feed Posts
    
    /// おすすめ投稿
    @Published var recommendedPosts: [Post] = []
    /// フォロー中の投稿
    @Published var followingPosts: [Post] = []
    /// おすすめ投稿のユーザー情報
    @Published var recommendedPostUsers: [String: AppUser] = [:]
    /// フォロー中投稿のユーザー情報
    @Published var followingPostUsers: [String: AppUser] = [:]
    /// いいね済み投稿のIDセット
    @Published var likedPostIds: Set<String> = []
    
    /// おすすめ投稿をロード中
    @Published var isRecommendedLoading = false
    /// フォロー中投稿をロード中
    @Published var isFollowingLoading = false
    /// フォロー中のユーザーがいるかどうか
    @Published var hasFollowingUsers = false
    
    private let weatherService = WeatherService.shared
    private let aiAdviceService = AIAdviceService.shared
    private let postService = PostService.shared
    private let fashionService = FashionService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // 初期化時には何もロードしない
    }
    
    // MARK: - Weather Data Loading
    
    /// 最後にロードした場所（重複リクエスト防止用）
    private var lastLoadedLocation: String?
    
    /// ユーザーの居住地域をもとに天気データを取得
    func loadWeather(for user: AppUser?) async {
        guard let user = user else {
            isLocationSet = false
            weather = nil
            fashionAdvice = nil
            lastLoadedLocation = nil
            return
        }
        
        let location = user.location ?? "未設定"
        
        // 居住地域が未設定の場合
        if location == "未設定" || location.isEmpty {
            isLocationSet = false
            weather = nil
            fashionAdvice = nil
            lastLoadedLocation = nil
            return
        }
        
        // 既にロード中、または同じ場所のデータがある場合はスキップ
        if isWeatherLoading {
            return
        }
        
        // 同じ場所で既にデータがある場合はスキップ
        if location == lastLoadedLocation && weather != nil {
            return
        }
        
        isLocationSet = true
        isWeatherLoading = true
        weatherError = nil
        lastLoadedLocation = location
        
        // 都道府県から緯度経度を取得
        guard let coordinates = PrefectureCoordinates.getCoordinates(for: location) else {
            weatherError = "位置情報の取得に失敗しました"
            isWeatherLoading = false
            return
        }
        
        do {
            let response = try await weatherService.fetchWeather(
                latitude: coordinates.latitude,
                longitude: coordinates.longitude
            )
            
            // WeatherNewsDataをWeatherモデルに変換
            if let weatherData = response.wxdata.first,
               let current = weatherData.srf.first,
               let today = weatherData.mrf.first {
                
                let newWeather = Weather(
                    location: location,
                    condition: current.weatherCondition,
                    temperature: Double(today.maxtemp),
                    minTemperature: Double(today.mintemp),
                    feelsLike: Double(current.temp),
                    precipitationChance: today.pop,
                    humidity: Double(current.rhum),
                    windSpeed: Double(current.wndspd),
                    pressure: Double(current.arpress)
                )
                
                weather = newWeather
                isWeatherLoading = false
                
                // 天気取得成功後、AIアドバイスを取得
                await loadFashionAdvice(weather: newWeather, user: user)
            }
        } catch {
            weatherError = "天気データの取得に失敗しました"
            print("Weather fetch error: \(error)")
            isWeatherLoading = false
        }
    }
    
    // MARK: - AI Fashion Advice
    
    /// AIファッションアドバイスを取得
    private func loadFashionAdvice(weather: Weather, user: AppUser?) async {
        isAdviceLoading = true
        
        do {
            let advice = try await aiAdviceService.generateAdvice(
                weather: weather,
                user: user
            )
            fashionAdvice = advice
        } catch {
            print("AI Advice error: \(error)")
            // エラー時はフォールバックアドバイスが返されるので、
            // ここでは特に何もしない
        }
        
        isAdviceLoading = false
    }
    
    // MARK: - Refresh
    
    func refresh(user: AppUser?) async {
        isLoading = true
        lastLoadedLocation = nil // 強制リロード
        await loadWeather(for: user)
        await loadRecommendedPosts(user: user)
        await loadFollowingPosts(user: user)
        isLoading = false
    }
    
    // MARK: - Load Recommended Posts (おすすめ投稿)
    
    /// 天気に基づいたおすすめ投稿を取得
    func loadRecommendedPosts(user: AppUser?) async {
        guard let weather = weather, let userId = user?.id else { return }
        
        isRecommendedLoading = true
        
        do {
            // 天気条件からPostWeatherに変換
            let postWeather = PostWeather.from(weather.condition)
            let currentTemp = Int(weather.temperature)
            let location = user?.location ?? ""
            
            // おすすめ投稿を取得
            let posts = try await postService.fetchRecommendedPosts(
                currentTemperature: currentTemp,
                currentWeather: postWeather,
                currentLocation: location,
                limit: 30
            )
            
            recommendedPosts = posts
            
            // ユーザー情報を取得
            let users = try await fashionService.fetchUsersForPosts(posts)
            recommendedPostUsers = users
            
            // いいね状態を取得
            await loadLikedStatus(for: posts, userId: userId)
            
        } catch {
            print("Failed to load recommended posts: \(error)")
        }
        
        isRecommendedLoading = false
    }
    
    // MARK: - Load Following Posts (フォロー中投稿)
    
    /// フォロー中ユーザーの過去7日間の投稿を取得
    func loadFollowingPosts(user: AppUser?) async {
        guard let userId = user?.id else {
            hasFollowingUsers = false
            return
        }
        
        isFollowingLoading = true
        
        // まずフォロー中のユーザーがいるかチェック（別のtryブロック）
        do {
            hasFollowingUsers = try await postService.hasFollowing(userId: userId)
        } catch {
            print("Failed to check following users: \(error)")
            hasFollowingUsers = false
            isFollowingLoading = false
            return
        }
        
        // フォロー中のユーザーがいない場合は終了
        if !hasFollowingUsers {
            followingPosts = []
            followingPostUsers = [:]
            isFollowingLoading = false
            return
        }
        
        // フォロー中の投稿を取得
        do {
            let posts = try await postService.fetchFollowingPosts(userId: userId, limit: 30)
            followingPosts = posts
            
            // ユーザー情報を取得
            let users = try await fashionService.fetchUsersForPosts(posts)
            followingPostUsers = users
            
            // いいね状態を取得
            await loadLikedStatus(for: posts, userId: userId)
        } catch {
            print("Failed to load following posts: \(error)")
            // エラー時は空の配列を設定（hasFollowingUsersはtrueのまま）
            followingPosts = []
            followingPostUsers = [:]
        }
        
        isFollowingLoading = false
    }
    
    // MARK: - Toggle Like
    
    func toggleLike(for post: Post, userId: String) async {
        guard let postId = post.id else { return }
        
        // 現在のいいね状態
        let isCurrentlyLiked = likedPostIds.contains(postId)
        
        // UIを即座に更新（楽観的更新）
        if isCurrentlyLiked {
            likedPostIds.remove(postId)
        } else {
            likedPostIds.insert(postId)
        }
        
        do {
            // サーバー側のいいねをトグル
            try await postService.toggleLike(postId: postId, userId: userId, isLiked: isCurrentlyLiked)
        } catch {
            // エラー時は元に戻す
            if isCurrentlyLiked {
                likedPostIds.insert(postId)
            } else {
                likedPostIds.remove(postId)
            }
            print("Failed to toggle like: \(error)")
        }
    }
    
    /// 投稿のいいね状態を取得
    func loadLikedStatus(for posts: [Post], userId: String) async {
        for post in posts {
            guard let postId = post.id else { continue }
            do {
                let isLiked = try await postService.isPostLiked(postId: postId, userId: userId)
                if isLiked {
                    likedPostIds.insert(postId)
                }
            } catch {
                print("Failed to check like status: \(error)")
            }
        }
    }
    
    /// 投稿がいいね済みかどうか
    func isLiked(_ post: Post) -> Bool {
        guard let postId = post.id else { return false }
        return likedPostIds.contains(postId)
    }
}

// MARK: - Story Profile

struct StoryProfile: Identifiable {
    let id = UUID()
    let username: String
    let imageURL: String
}

// MARK: - Prefecture Coordinates (都道府県の県庁所在地座標)

enum PrefectureCoordinates {
    /// 都道府県名から緯度経度を取得
    static func getCoordinates(for prefecture: String) -> (latitude: Double, longitude: Double)? {
        return coordinates[prefecture]
    }
    
    /// 都道府県の県庁所在地の緯度経度
    private static let coordinates: [String: (latitude: Double, longitude: Double)] = [
        "北海道": (43.0646, 141.3468),
        "青森県": (40.8246, 140.7400),
        "岩手県": (39.7036, 141.1527),
        "宮城県": (38.2688, 140.8721),
        "秋田県": (39.7186, 140.1024),
        "山形県": (38.2404, 140.3634),
        "福島県": (37.7500, 140.4678),
        "茨城県": (36.3418, 140.4468),
        "栃木県": (36.5658, 139.8836),
        "群馬県": (36.3911, 139.0608),
        "埼玉県": (35.8569, 139.6489),
        "千葉県": (35.6047, 140.1233),
        "東京都": (35.6895, 139.6917),
        "神奈川県": (35.4478, 139.6425),
        "新潟県": (37.9026, 139.0236),
        "富山県": (36.6953, 137.2114),
        "石川県": (36.5947, 136.6256),
        "福井県": (36.0652, 136.2216),
        "山梨県": (35.6642, 138.5684),
        "長野県": (36.6513, 138.1810),
        "岐阜県": (35.3912, 136.7223),
        "静岡県": (34.9769, 138.3831),
        "愛知県": (35.1802, 136.9066),
        "三重県": (34.7303, 136.5086),
        "滋賀県": (35.0045, 135.8686),
        "京都府": (35.0116, 135.7681),
        "大阪府": (34.6863, 135.5200),
        "兵庫県": (34.6913, 135.1830),
        "奈良県": (34.6851, 135.8329),
        "和歌山県": (34.2260, 135.1675),
        "鳥取県": (35.5039, 134.2378),
        "島根県": (35.4723, 133.0505),
        "岡山県": (34.6618, 133.9344),
        "広島県": (34.3966, 132.4596),
        "山口県": (34.1859, 131.4714),
        "徳島県": (34.0658, 134.5593),
        "香川県": (34.3401, 134.0434),
        "愛媛県": (33.8416, 132.7657),
        "高知県": (33.5597, 133.5311),
        "福岡県": (33.6064, 130.4183),
        "佐賀県": (33.2494, 130.2988),
        "長崎県": (32.7448, 129.8737),
        "熊本県": (32.7898, 130.7417),
        "大分県": (33.2382, 131.6126),
        "宮崎県": (31.9111, 131.4239),
        "鹿児島県": (31.5602, 130.5581),
        "沖縄県": (26.2124, 127.6809),
        "その他": (35.6895, 139.6917) // デフォルトは東京
    ]
}

