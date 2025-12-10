//
//  OutfitRecommendation.swift
//  Wearther
//
//  Created by hato on 2025/11/07.
//

import Foundation

struct OutfitRecommendation: Codable, Identifiable {
    let id: UUID
    let userId: String
    let userName: String
    let userAvatarSymbol: String
    let userAvatarURL: String?
    let userHeight: Int
    let imageURL: String?
    let weatherSnapshot: WeatherSnapshot
    let likes: Int
    var isLiked: Bool
    
    init(
        id: UUID = UUID(),
        userId: String,
        userName: String,
        userAvatarSymbol: String = "person.crop.circle",
        userAvatarURL: String? = nil,
        userHeight: Int,
        imageURL: String? = nil,
        weatherSnapshot: WeatherSnapshot,
        likes: Int = 0,
        isLiked: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.userAvatarSymbol = userAvatarSymbol
        self.userAvatarURL = userAvatarURL
        self.userHeight = userHeight
        self.imageURL = imageURL
        self.weatherSnapshot = weatherSnapshot
        self.likes = likes
        self.isLiked = isLiked
    }
}

struct WeatherSnapshot: Codable {
    let temperature: Double
    let condition: WeatherCondition
}

struct FashionAdvice: Codable {
    let title: String
    let description: String
}

