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
    @Published var outfitRecommendations: [OutfitRecommendation] = []
    @Published var stories: [StoryProfile] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    init() {
        loadMockData()
    }
    
    func loadMockData() {
        // モックデータの読み込み
        weather = Weather(
            location: "東京都千代田区",
            condition: .partlyCloudy,
            temperature: 19.0,
            minTemperature: 11.0,
            feelsLike: 18.0,
            precipitationChance: 60,
            humidity: 65,
            windSpeed: 3.0,
            uvIndex: "中",
            pressure: 1013.0
        )
        
        fashionAdvice = FashionAdvice(
            title: "コートやセーターを重ね着して暖かく",
            description: "風を通しにくいアウターやニットなど熱を逃さないアイテムを取り入れて暖かさをキープしましょう"
        )
        
        stories = [
            StoryProfile(
                username: "tarou_01",
                imageURL: "https://images.unsplash.com/photo-1521572163474-6864f9cf17ab"
            ),
            StoryProfile(
                username: "ranmaru",
                imageURL: "https://images.unsplash.com/photo-1544723795-3fb6469f5b39"
            ),
            StoryProfile(
                username: "aki_style",
                imageURL: "https://images.unsplash.com/photo-1524504388940-b1c1722653e1"
            ),
            StoryProfile(
                username: "sora",
                imageURL: "https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91"
            ),
            StoryProfile(
                username: "mei",
                imageURL: "https://images.unsplash.com/photo-1494790108377-be9c29b29330"
            )
        ]
        
        outfitRecommendations = [
            OutfitRecommendation(
                userId: "1",
                userName: "蘭丸",
                userAvatarSymbol: "person.crop.circle",
                userAvatarURL: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e",
                userHeight: 175,
                imageURL: "https://images.unsplash.com/photo-1524504388940-b1c1722653e1",
                weatherSnapshot: WeatherSnapshot(temperature: 19.0, condition: .partlyCloudy),
                likes: 120,
                isLiked: false
            ),
            OutfitRecommendation(
                userId: "2",
                userName: "蘭丸",
                userAvatarSymbol: "person.crop.circle.fill",
                userAvatarURL: "https://images.unsplash.com/photo-1524504388940-b1c1722653e1",
                userHeight: 175,
                imageURL: "https://images.unsplash.com/photo-1492447166138-50c3889fccb1",
                weatherSnapshot: WeatherSnapshot(temperature: 18.0, condition: .cloudy),
                likes: 98,
                isLiked: false
            ),
            OutfitRecommendation(
                userId: "3",
                userName: "蘭丸",
                userAvatarSymbol: "person.crop.circle.badge.checkmark",
                userAvatarURL: "https://images.unsplash.com/photo-1494790108377-be9c29b29330",
                userHeight: 175,
                imageURL: "https://images.unsplash.com/photo-1487412720507-e7ab37603c6f",
                weatherSnapshot: WeatherSnapshot(temperature: 16.0, condition: .rainy),
                likes: 155,
                isLiked: true
            ),
            OutfitRecommendation(
                userId: "4",
                userName: "蘭丸",
                userAvatarSymbol: "person.crop.circle.badge.questionmark",
                userAvatarURL: "https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91",
                userHeight: 175,
                imageURL: "https://images.unsplash.com/photo-1503341504253-dff4815485f1",
                weatherSnapshot: WeatherSnapshot(temperature: 14.0, condition: .cloudy),
                likes: 64,
                isLiked: false
            ),
            OutfitRecommendation(
                userId: "5",
                userName: "蘭丸",
                userAvatarSymbol: "person.crop.circle.badge.plus",
                userAvatarURL: "https://images.unsplash.com/photo-1488426862026-3ee34a7d66df",
                userHeight: 175,
                imageURL: "https://images.unsplash.com/photo-1503341455253-b2e723bb3dbb",
                weatherSnapshot: WeatherSnapshot(temperature: 20.0, condition: .sunny),
                likes: 87,
                isLiked: false
            ),
            OutfitRecommendation(
                userId: "6",
                userName: "蘭丸",
                userAvatarSymbol: "person.crop.circle.badge.minus",
                userAvatarURL: "https://images.unsplash.com/photo-1524504388940-b1c1722653e1",
                userHeight: 175,
                imageURL: "https://images.unsplash.com/photo-1521572163474-6864f9cf17ab",
                weatherSnapshot: WeatherSnapshot(temperature: 22.0, condition: .sunny),
                likes: 111,
                isLiked: false
            )
        ]
    }
    
    func refresh() async {
        isLoading = true
        // 疑似的な遅延を追加
        try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
        loadMockData()
        isLoading = false
    }
    
    func toggleLike(for recommendation: OutfitRecommendation) {
        if let index = outfitRecommendations.firstIndex(where: { $0.id == recommendation.id }) {
            let current = outfitRecommendations[index]
            let updated = OutfitRecommendation(
                id: current.id,
                userId: current.userId,
                userName: current.userName,
                userAvatarSymbol: current.userAvatarSymbol,
                userAvatarURL: current.userAvatarURL,
                userHeight: current.userHeight,
                imageURL: current.imageURL,
                weatherSnapshot: current.weatherSnapshot,
                likes: current.isLiked ? current.likes - 1 : current.likes + 1,
                isLiked: !current.isLiked
            )
            outfitRecommendations[index] = updated
        }
    }
}

struct StoryProfile: Identifiable {
    let id = UUID()
    let username: String
    let imageURL: String
}

