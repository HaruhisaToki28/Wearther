//
//  WeatherService.swift
//  Wearther
//
//  Created by Wearther on 2025/12/23.
//

import Foundation
import Combine
import CoreLocation

class WeatherService: ObservableObject {
    static let shared = WeatherService()
    
    private let apiKey = "kKmcTu2Rc6a16T4juPzMKa6wDx0tuJIC7RRfG8bZ"
    private let baseURL = "https://wxtech.weathernews.com/api/v1/ss1wx"
    
    @Published var currentWeather: WeatherNewsData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {}
    
    // MARK: - Fetch Weather
    func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherNewsResponse {
        let urlString = "\(baseURL)?lat=\(latitude)&lon=\(longitude)"
        
        print("🌤️ Weather API Request: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            throw WeatherServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw WeatherServiceError.invalidResponse
            }
            
            print("🌤️ Weather API Status: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                // デバッグ用：エラーレスポンスを出力
                if let errorString = String(data: data, encoding: .utf8) {
                    print("🌤️ Weather API Error Response: \(errorString)")
                }
                throw WeatherServiceError.httpError(statusCode: httpResponse.statusCode)
            }
            
            // デバッグ用：レスポンスを出力
            if let jsonString = String(data: data, encoding: .utf8) {
                print("🌤️ Weather API Response: \(jsonString.prefix(500))...")
            }
            
            let decoder = JSONDecoder()
            let weatherResponse = try decoder.decode(WeatherNewsResponse.self, from: data)
            
            return weatherResponse
        } catch let error as DecodingError {
            print("🌤️ Decoding Error: \(error)")
            throw WeatherServiceError.decodingError
        }
    }
    
    // MARK: - Fetch and Update
    @MainActor
    func fetchAndUpdate(latitude: Double, longitude: Double) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await fetchWeather(latitude: latitude, longitude: longitude)
            currentWeather = response.wxdata.first
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Get Current Temperature
    func getCurrentTemperature() -> Float? {
        guard let weather = currentWeather,
              let current = weather.srf.first else {
            return nil
        }
        return current.temp
    }
    
    // MARK: - Get Today's Forecast
    func getTodayForecast() -> [ShortRangeForecast] {
        guard let weather = currentWeather else { return [] }
        return Array(weather.srf.prefix(24))
    }
    
    // MARK: - Get Weekly Forecast
    func getWeeklyForecast() -> [MediumRangeForecast] {
        guard let weather = currentWeather else { return [] }
        return weather.mrf
    }
}

// MARK: - Errors
enum WeatherServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .invalidResponse:
            return "サーバーからの応答が無効です"
        case .httpError(let statusCode):
            return "HTTPエラー: \(statusCode)"
        case .decodingError:
            return "データの解析に失敗しました"
        }
    }
}

