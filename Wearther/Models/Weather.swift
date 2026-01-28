//
//  Weather.swift
//  Wearther
//
//  Created by hato on 2025/11/07.
//

import Foundation

struct Weather: Codable, Identifiable {
    let id: UUID
    let location: String
    let condition: WeatherCondition
    let temperature: Double
    let minTemperature: Double
    let feelsLike: Double
    let precipitationChance: Int
    let humidity: Double?
    let windSpeed: Double?
    let uvIndex: String?
    let pressure: Double?
    let timestamp: Date
    
    init(
        id: UUID = UUID(),
        location: String,
        condition: WeatherCondition,
        temperature: Double,
        minTemperature: Double,
        feelsLike: Double,
        precipitationChance: Int,
        humidity: Double? = nil,
        windSpeed: Double? = nil,
        uvIndex: String? = nil,
        pressure: Double? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.location = location
        self.condition = condition
        self.temperature = temperature
        self.minTemperature = minTemperature
        self.feelsLike = feelsLike
        self.precipitationChance = precipitationChance
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.uvIndex = uvIndex
        self.pressure = pressure
        self.timestamp = timestamp
    }
}

enum WeatherCondition: String, Codable {
    case sunny = "晴れ"
    case cloudy = "くもり"
    case partlyCloudy = "くもり時々晴れ"
    case rainy = "雨"
    case snowy = "雪"
    
    var symbolName: String {
        switch self {
        case .sunny:
            return "sun.max.fill"
        case .cloudy:
            return "cloud.fill"
        case .partlyCloudy:
            return "cloud.sun.fill"
        case .rainy:
            return "cloud.rain.fill"
        case .snowy:
            return "cloud.snow.fill"
        }
    }
    
    /// PostWeatherに変換
    func toPostWeather() -> PostWeather {
        switch self {
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



