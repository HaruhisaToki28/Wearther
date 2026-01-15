//
//  WeatherView.swift
//  Wearther
//
//  Created by Wearther on 2025/12/23.
//

import SwiftUI
import CoreLocation
import Combine

struct WeatherView: View {
    @StateObject private var weatherService = WeatherService.shared
    @StateObject private var locationManager = LocationManager()
    
    @State private var locationName: String = "現在地を取得中..."
    
    // モックのOutfitデータ（実際にはViewModelから取得）
    private let mockOutfits: [OutfitRecommendation] = [
        OutfitRecommendation(
            userId: "1", userName: "蘭丸",
            userAvatarURL: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e",
            userHeight: 175,
            imageURL: "https://images.unsplash.com/photo-1524504388940-b1c1722653e1",
            weatherSnapshot: WeatherSnapshot(temperature: 19.0, condition: .partlyCloudy),
            likes: 120, isLiked: false
        ),
        OutfitRecommendation(
            userId: "2", userName: "太郎",
            userAvatarURL: "https://images.unsplash.com/photo-1524504388940-b1c1722653e1",
            userHeight: 175,
            imageURL: "https://images.unsplash.com/photo-1492447166138-50c3889fccb1",
            weatherSnapshot: WeatherSnapshot(temperature: 18.0, condition: .cloudy),
            likes: 98, isLiked: false
        ),
        OutfitRecommendation(
            userId: "3", userName: "花子",
            userAvatarURL: "https://images.unsplash.com/photo-1494790108377-be9c29b29330",
            userHeight: 165,
            imageURL: "https://images.unsplash.com/photo-1487412720507-e7ab37603c6f",
            weatherSnapshot: WeatherSnapshot(temperature: 16.0, condition: .rainy),
            likes: 155, isLiked: true
        ),
        OutfitRecommendation(
            userId: "4", userName: "次郎",
            userAvatarURL: "https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91",
            userHeight: 180,
            imageURL: "https://images.unsplash.com/photo-1503341504253-dff4815485f1",
            weatherSnapshot: WeatherSnapshot(temperature: 14.0, condition: .cloudy),
            likes: 64, isLiked: false
        )
    ]
    
    // WeatherNewsデータをWeatherモデルに変換
    private var currentWeatherModel: Weather? {
        guard let weatherData = weatherService.currentWeather,
              let current = weatherData.srf.first,
              let today = weatherData.mrf.first else {
            return nil
        }
        
        return Weather(
            location: locationName,
            condition: current.weatherCondition,
            temperature: Double(today.maxtemp),
            minTemperature: Double(today.mintemp),
            feelsLike: Double(current.temp),
            precipitationChance: today.pop,
            humidity: Double(current.rhum),
            windSpeed: Double(current.wndspd),
            pressure: Double(current.arpress)
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            ZStack {
                Text("天気")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
            }
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .fill(Color(hex: "DDDDDD"))
                    .frame(height: 0.2),
                alignment: .bottom
            )
            
            // MARK: - Content
            ScrollView {
                VStack(spacing: 16) {
                    // Compact Weather Hero Card
                    if let weather = currentWeatherModel {
                        CompactWeatherHeroCard(
                            weather: weather,
                            hourlyForecasts: Array(weatherService.getTodayForecast().prefix(6))
                        )
                    } else if weatherService.isLoading {
                        LoadingWeatherCard()
                    } else {
                        EmptyWeatherCard(message: weatherService.errorMessage ?? "天気データを取得できません")
                    }
                    
                    // Weather + Outfit Section
                    if !weatherService.getWeeklyForecast().isEmpty {
                        WeeklyWithOutfitSection(
                            forecasts: weatherService.getWeeklyForecast(),
                            outfits: mockOutfits
                        )
                    }
                    
                    // Outfit Recommendations for Today's Weather
                    TodayOutfitSection(outfits: mockOutfits)
                    
                    Spacer().frame(height: 30)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .refreshable {
                await refreshWeather()
            }
        }
        .background(Color(hex: "F8F8F8"))
        .onAppear {
            locationManager.requestLocation()
        }
        .onChange(of: locationManager.location) { _, newLocation in
            if let location = newLocation {
                Task {
                    await fetchWeatherForLocation(location)
                }
            }
        }
    }
    
    private func refreshWeather() async {
        if let location = locationManager.location {
            await fetchWeatherForLocation(location)
        }
    }
    
    private func fetchWeatherForLocation(_ location: CLLocation) async {
        let geocoder = CLGeocoder()
        if let placemark = try? await geocoder.reverseGeocodeLocation(location).first {
            let city = placemark.locality ?? placemark.administrativeArea ?? ""
            let ward = placemark.subLocality ?? ""
            locationName = "\(city)\(ward)"
        }
        
        await weatherService.fetchAndUpdate(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
    }
}

// MARK: - Compact Weather Hero Card
private struct CompactWeatherHeroCard: View {
    let weather: Weather
    let hourlyForecasts: [ShortRangeForecast]
    
    var body: some View {
        VStack(spacing: 0) {
            // Main weather info - compact
            HStack(spacing: 16) {
                // Weather Icon
                CompactWeatherIcon(condition: weather.condition)
                    .frame(width: 60, height: 60)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(weather.location)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "68717B"))
                    
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(Int(weather.temperature))°")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundColor(Color(hex: "FF2539"))
                        
                        Text("/")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "DDDDDD"))
                        
                        Text("\(Int(weather.minTemperature))°")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(hex: "3582DC"))
                    }
                }
                
                Spacer()
                
                // Precipitation & Condition
                VStack(alignment: .trailing, spacing: 6) {
                    Text(weather.condition.rawValue)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: "2D2D2D"))
                    
                    HStack(spacing: 4) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "08C4FA"))
                        Text("\(weather.precipitationChance)%")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "68717B"))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // Hourly mini forecast
            if !hourlyForecasts.isEmpty {
                Divider()
                    .padding(.horizontal, 16)
                
                HStack(spacing: 0) {
                    ForEach(Array(hourlyForecasts.enumerated()), id: \.element.id) { index, forecast in
                        MiniHourlyItem(forecast: forecast, isNow: index == 0)
                        if index < hourlyForecasts.count - 1 {
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
            }
        }
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
    }
}

private struct MiniHourlyItem: View {
    let forecast: ShortRangeForecast
    let isNow: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text(isNow ? "今" : forecast.formattedTime)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isNow ? Color(hex: "2D2D2D") : Color(hex: "68717B"))
            
            CompactWeatherIcon(condition: forecast.weatherCondition)
                .frame(width: 22, height: 22)
            
            Text("\(Int(forecast.temp))°")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: "2D2D2D"))
        }
    }
}

private struct CompactWeatherIcon: View {
    let condition: WeatherCondition
    
    var body: some View {
        Image(systemName: condition.symbolName)
            .symbolRenderingMode(.palette)
            .foregroundStyle(paletteColors[0], paletteColors[1], paletteColors[2])
            .font(.system(size: 28, weight: .medium))
    }
    
    private var paletteColors: [Color] {
        switch condition {
        case .sunny:
            return [Color(hex: "FFB833"), Color(hex: "FF8C22"), Color(hex: "FFDE87")]
        case .partlyCloudy:
            return [Color(hex: "D1DBF0"), Color(hex: "FFB833"), Color(hex: "FF8C22")]
        case .cloudy:
            return [Color(hex: "CCD4E6"), Color(hex: "A8B3C7"), Color(hex: "EBEEF7")]
        case .rainy:
            return [Color(hex: "BFD1F2"), Color(hex: "08C4FA"), Color(hex: "5A8FF2")]
        case .snowy:
            return [Color(hex: "E0EDFC"), Color.white, Color(hex: "BCD1F7")]
        }
    }
}

// MARK: - Weekly With Outfit Section
private struct WeeklyWithOutfitSection: View {
    let forecasts: [MediumRangeForecast]
    let outfits: [OutfitRecommendation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("週間予報 & おすすめコーデ")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(hex: "2D2D2D"))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(forecasts.prefix(5).enumerated()), id: \.element.id) { index, forecast in
                        WeeklyOutfitCard(
                            forecast: forecast,
                            outfit: outfits.indices.contains(index) ? outfits[index] : nil,
                            isToday: index == 0
                        )
                    }
                }
            }
        }
    }
}

private struct WeeklyOutfitCard: View {
    let forecast: MediumRangeForecast
    let outfit: OutfitRecommendation?
    let isToday: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Outfit Image Background
            ZStack(alignment: .bottomLeading) {
                if let outfit = outfit, let urlString = outfit.imageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            gradientPlaceholder
                        }
                    }
                } else {
                    gradientPlaceholder
                }
            }
            .frame(width: 100, height: 120)
            .clipped()
            .overlay(
                // Weather overlay
                VStack {
                    Spacer()
                    HStack {
                        CompactWeatherIcon(condition: forecast.weatherCondition)
                            .frame(width: 20, height: 20)
                        Spacer()
                    }
                    .padding(8)
                    .background(
                        LinearGradient(
                            colors: [Color.black.opacity(0.5), Color.clear],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                }
            )
            
            // Date & Temp
            VStack(spacing: 4) {
                Text(isToday ? "今日" : forecast.formattedDate)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "2D2D2D"))
                
                HStack(spacing: 4) {
                    Text("\(Int(forecast.maxtemp))°")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "FF2539"))
                    Text("\(Int(forecast.mintemp))°")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "3582DC"))
                }
                
                HStack(spacing: 2) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 8))
                        .foregroundColor(Color(hex: "08C4FA"))
                    Text("\(forecast.pop)%")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "68717B"))
                }
            }
            .padding(.vertical, 10)
            .frame(width: 100)
            .background(Color.white)
        }
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
    
    private var gradientPlaceholder: some View {
        LinearGradient(
            colors: [Color(hex: "E8EDF5"), Color(hex: "D1DBF0")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            Image(systemName: "tshirt.fill")
                .font(.system(size: 24))
                .foregroundColor(Color(hex: "68717B").opacity(0.4))
        )
    }
}

// MARK: - Today Outfit Section
private struct TodayOutfitSection: View {
    let outfits: [OutfitRecommendation]
    @State private var likedStates: [UUID: Bool] = [:]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今日の気温に合うコーデ")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "2D2D2D"))
                
                Spacer()
                
                Button(action: {}) {
                    Text("もっと見る")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "68717B"))
                }
            }
            
            // 2列グリッド
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 10) {
                ForEach(outfits.prefix(4)) { outfit in
                    CompactOutfitCard(
                        recommendation: outfit,
                        isLiked: likedStates[outfit.id] ?? outfit.isLiked,
                        onLikeTapped: {
                            likedStates[outfit.id] = !(likedStates[outfit.id] ?? outfit.isLiked)
                        }
                    )
                }
            }
        }
    }
}

private struct CompactOutfitCard: View {
    let recommendation: OutfitRecommendation
    let isLiked: Bool
    let onLikeTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Image
            ZStack(alignment: .topTrailing) {
                if let urlString = recommendation.imageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                                .overlay(ProgressView())
                        }
                    }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                }
                
                // Like button overlay
                Button(action: onLikeTapped) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 14))
                        .foregroundColor(isLiked ? .red : .white)
                        .padding(8)
                        .background(Color.black.opacity(0.2))
                        .clipShape(Circle())
                }
                .padding(8)
            }
            .frame(height: 140)
            .clipped()
            
            // Info
            HStack(spacing: 6) {
                // Avatar
                AsyncImage(url: URL(string: recommendation.userAvatarURL ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                    }
                }
                .frame(width: 20, height: 20)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(recommendation.userName)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(hex: "2D2D2D"))
                        .lineLimit(1)
                    
                    Text("\(Int(recommendation.weatherSnapshot.temperature))°C")
                        .font(.system(size: 9))
                        .foregroundColor(Color(hex: "AAAAAA"))
                }
                
                Spacer()
                
                // Weather condition icon
                CompactWeatherIcon(condition: recommendation.weatherSnapshot.condition)
                    .frame(width: 16, height: 16)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
        }
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Loading & Empty States
private struct LoadingWeatherCard: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("天気データを取得中...")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "68717B"))
        }
        .padding(.vertical, 36)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
    }
}

private struct EmptyWeatherCard: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "icloud.slash")
                .font(.system(size: 32))
                .foregroundColor(Color(hex: "68717B"))
            
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "68717B"))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 36)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    // デフォルト座標（東京）
    private let defaultLocation = CLLocation(latitude: 35.696, longitude: 139.758)
    
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
        if location == nil {
            location = defaultLocation
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        } else if authorizationStatus == .denied || authorizationStatus == .restricted {
            location = defaultLocation
        }
    }
}

#Preview {
    WeatherView()
}
