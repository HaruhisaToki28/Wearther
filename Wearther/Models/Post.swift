//
//  Post.swift
//  Wearther
//
//  Created by Wearther on 2026/01/16.
//

import Foundation
import FirebaseFirestore

struct Post: Codable, Identifiable, Hashable {
    // Hashable conformance
    static func == (lhs: Post, rhs: Post) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    @DocumentID var id: String?
    
    var userId: String
    var imageURL: String
    var title: String
    var caption: String
    var weather: PostWeather
    var temperature: Int
    var location: PostLocation
    var userGender: String
    var userAge: Int
    var userHeight: Int
    var likesCount: Int
    var createdAt: Date
    
    init(
        id: String? = nil,
        userId: String,
        imageURL: String,
        title: String,
        caption: String,
        weather: PostWeather,
        temperature: Int,
        location: PostLocation,
        userGender: String,
        userAge: Int,
        userHeight: Int,
        likesCount: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.imageURL = imageURL
        self.title = title
        self.caption = caption
        self.weather = weather
        self.temperature = temperature
        self.location = location
        self.userGender = userGender
        self.userAge = userAge
        self.userHeight = userHeight
        self.likesCount = likesCount
        self.createdAt = createdAt
    }
}

// MARK: - Post Weather
enum PostWeather: String, Codable, CaseIterable {
    case sunny = "晴れ"
    case cloudy = "曇り"
    case rainy = "雨"
    case snowy = "雪"
    
    var symbolName: String {
        switch self {
        case .sunny:
            return "sun.max.fill"
        case .cloudy:
            return "cloud.fill"
        case .rainy:
            return "cloud.rain.fill"
        case .snowy:
            return "cloud.snow.fill"
        }
    }
    
    // WeatherConditionからPostWeatherに変換
    static func from(_ condition: WeatherCondition) -> PostWeather {
        switch condition {
        case .sunny:
            return .sunny
        case .cloudy, .partlyCloudy:
            return .cloudy
        case .rainy:
            return .rainy
        case .snowy:
            return .snowy
        }
    }
}

// MARK: - Post Location
struct PostLocation: Codable {
    var name: String
    var latitude: Double?
    var longitude: Double?
    
    init(name: String, latitude: Double? = nil, longitude: Double? = nil) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }
}
