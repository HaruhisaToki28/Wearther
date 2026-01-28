//
//  WeatherView.swift
//  Wearther
//
//  Created by Wearther on 2025/12/23.
//

import SwiftUI
import CoreLocation
import Combine
import Kingfisher

struct WeatherView: View {
    @StateObject private var weatherService = WeatherService.shared
    @StateObject private var locationManager = LocationManager()
    @StateObject private var viewModel = WeatherViewModel()
    @EnvironmentObject private var authService: AuthService
    
    @State private var locationName: String = "現在地を取得中..."
    @State private var isShowingSearch: Bool = false
    @State private var isUsingCurrentLocation: Bool = true
    @State private var selectedLocation: LocationSearchResult?
    @State private var hasLoadedOutfits: Bool = false
    
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
        NavigationStack {
        VStack(spacing: 0) {
            // MARK: - Header with Search Bar
            HStack(spacing: 12) {
                // 検索入力欄（タップで検索画面を開く）
                Button(action: { isShowingSearch = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "68717B"))
                        
                        Text(locationName)
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "2D2D2D"))
                            .lineLimit(1)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(hex: "F5F5F5"))
                    .cornerRadius(12)
                }
                
                // 現在地ボタン
                Button(action: { useCurrentLocation() }) {
                    ZStack {
                        Circle()
                            .fill(isUsingCurrentLocation ? Color(hex: "08C4FA").opacity(0.15) : Color(hex: "F5F5F5"))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: isUsingCurrentLocation ? "location.fill" : "location")
                            .font(.system(size: 16))
                            .foregroundColor(isUsingCurrentLocation ? Color(hex: "08C4FA") : Color(hex: "68717B"))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .fill(Color(hex: "DDDDDD"))
                    .frame(height: 0.5),
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
                    if !viewModel.weeklyOutfits.isEmpty {
                        WeeklyWithOutfitSection(weeklyOutfits: viewModel.weeklyOutfits)
                    } else if !weatherService.getWeeklyForecast().isEmpty && viewModel.isLoading {
                        WeeklyOutfitLoadingSection()
                    }
                    
                    // Outfit Recommendations for Today's Weather
                    TodayOutfitSection(
                        outfits: viewModel.todayOutfits,
                        onLikeTapped: { outfit in
                            Task {
                                await viewModel.toggleLike(for: outfit)
                            }
                        }
                    )
                    
                    Spacer().frame(height: 30)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .refreshable {
                await refreshWeather()
                await loadOutfits()
            }
        }
        .background(Color(hex: "F8F8F8"))
        .navigationBarHidden(true)
        }
        .onAppear {
            if isUsingCurrentLocation {
                locationManager.requestLocation()
            }
        }
        .onChange(of: locationManager.location) { _, newLocation in
            if isUsingCurrentLocation, let location = newLocation {
                Task {
                    await fetchWeatherForLocation(location)
                    await loadOutfits()
                }
            }
        }
        .fullScreenCover(isPresented: $isShowingSearch) {
            LocationSearchView { result in
                selectSearchedLocation(result)
            }
        }
    }
    
    // MARK: - Load Outfits
    private func loadOutfits() async {
        guard let weatherData = weatherService.currentWeather,
              let today = weatherData.mrf.first,
              let current = weatherData.srf.first else {
            return
        }
        
        await viewModel.loadOutfits(
            forecasts: weatherData.mrf,
            currentTemperature: Int(today.maxtemp),
            currentWeather: current.weatherCondition,
            location: locationName,
            userId: authService.currentUser?.id
        )
    }
    
    // MARK: - Actions
    private func useCurrentLocation() {
        isUsingCurrentLocation = true
        selectedLocation = nil
        locationName = "現在地を取得中..."
        locationManager.requestLocation()
        
        if let location = locationManager.location {
            Task {
                await fetchWeatherForLocation(location)
            }
        }
    }
    
    private func selectSearchedLocation(_ result: LocationSearchResult) {
        isUsingCurrentLocation = false
        selectedLocation = result
        locationName = result.fullName
        
        Task {
            await weatherService.fetchAndUpdate(
                latitude: result.latitude,
                longitude: result.longitude
            )
            await loadOutfits()
        }
    }
    
    private func refreshWeather() async {
        if isUsingCurrentLocation {
            if let location = locationManager.location {
                await fetchWeatherForLocation(location)
            }
        } else if let selected = selectedLocation {
            await weatherService.fetchAndUpdate(
                latitude: selected.latitude,
                longitude: selected.longitude
            )
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
                // Weather Icon - 固定サイズ
                CompactWeatherIcon(condition: weather.condition, size: 48)
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
                            .frame(maxWidth: .infinity) // 均等配置
                    }
                }
                .padding(.horizontal, 12)
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
        VStack(spacing: 6) {
            // 時刻表示 - モデルのformattedTimeを使用
            Text(isNow ? "今" : forecast.formattedTime)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isNow ? Color(hex: "2D2D2D") : Color(hex: "68717B"))
                .frame(width: 40, height: 14) // 固定サイズ
            
            // アイコン - 固定サイズ
            CompactWeatherIcon(condition: forecast.weatherCondition, size: 20)
                .frame(width: 24, height: 24) // 固定サイズ
            
            // 温度 - 固定幅
            Text("\(Int(forecast.temp))°")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: "2D2D2D"))
                .frame(width: 30, height: 14) // 固定サイズ
        }
        .frame(width: 50) // アイテム全体の固定幅
    }
}

private struct CompactWeatherIcon: View {
    let condition: WeatherCondition
    var size: CGFloat = 28
    
    var body: some View {
        Image(systemName: condition.symbolName)
            .symbolRenderingMode(.palette)
            .foregroundStyle(paletteColors[0], paletteColors[1], paletteColors[2])
            .font(.system(size: size, weight: .medium))
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
    let weeklyOutfits: [WeatherWeeklyOutfit]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("週間予報 & おすすめコーデ")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(hex: "2D2D2D"))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(weeklyOutfits.prefix(7).enumerated()), id: \.element.id) { index, item in
                        WeeklyOutfitCard(
                            item: item,
                            isToday: index == 0
                        )
                    }
                }
            }
        }
    }
}

private struct WeeklyOutfitLoadingSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("週間予報 & おすすめコーデ")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(hex: "2D2D2D"))
            
            HStack {
                Spacer()
                ProgressView()
                    .padding(.vertical, 40)
                Spacer()
            }
        }
    }
}

private struct WeeklyOutfitCard: View {
    let item: WeatherWeeklyOutfit
    let isToday: Bool
    
    private let cardWidth: CGFloat = 100
    private let imageHeight: CGFloat = 120
    
    var body: some View {
        VStack(spacing: 0) {
            // Outfit Image Background - 画像タップで投稿詳細へ
            if let post = item.recommendedPost {
                NavigationLink(destination: PostDetailView(post: post)) {
                    outfitImageView(post: post)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                gradientPlaceholder
                    .frame(width: cardWidth, height: imageHeight)
                    .clipped()
                    .overlay(alignment: .bottomLeading) {
                        weatherOverlay
                    }
            }
            
            // Date & Temp
            VStack(spacing: 4) {
                // 日付表示
                Text(isToday ? "今日" : item.forecast.formattedDate)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "2D2D2D"))
                    .frame(height: 14)
                
                HStack(spacing: 4) {
                    Text("\(Int(item.forecast.maxtemp))°")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "FF2539"))
                        .frame(width: 28, alignment: .trailing)
                    Text("\(Int(item.forecast.mintemp))°")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "3582DC"))
                        .frame(width: 28, alignment: .leading)
                }
                .frame(height: 14)
                
                HStack(spacing: 2) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 8))
                        .foregroundColor(Color(hex: "08C4FA"))
                    Text("\(item.forecast.pop)%")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "68717B"))
                }
                .frame(height: 12)
            }
            .padding(.vertical, 10)
            .frame(width: cardWidth)
            .background(Color.white)
        }
        .frame(width: cardWidth)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
    
    private func outfitImageView(post: Post) -> some View {
        ZStack {
            gradientPlaceholder
            
            CachedImage(
                url: post.imageURL,
                targetSize: CGSize(width: 200, height: 240)
            )
        }
        .frame(width: cardWidth, height: imageHeight)
        .clipped()
        .overlay(alignment: .bottomLeading) {
            weatherOverlay
        }
    }
    
    private var weatherOverlay: some View {
        HStack {
            CompactWeatherIcon(condition: item.forecast.weatherCondition, size: 18)
                .frame(width: 22, height: 22)
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
    let outfits: [WeatherTodayOutfit]
    let onLikeTapped: (WeatherTodayOutfit) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日の気温に合うコーデ")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(hex: "2D2D2D"))
            
            if outfits.isEmpty {
                HStack {
                    Spacer()
                    Text("おすすめコーデがありません")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .padding(.vertical, 40)
                    Spacer()
                }
            } else {
                // 2列グリッド
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(outfits.prefix(4)) { outfit in
                        CompactOutfitCard(
                            outfit: outfit,
                            onLikeTapped: { onLikeTapped(outfit) }
                        )
                    }
                }
            }
        }
    }
}

private struct CompactOutfitCard: View {
    let outfit: WeatherTodayOutfit
    let onLikeTapped: () -> Void
    
    // カードの固定サイズ
    private let imageHeight: CGFloat = 150
    private let infoHeight: CGFloat = 50
    
    var body: some View {
        GeometryReader { geometry in
            let cardWidth = geometry.size.width
            
            VStack(spacing: 0) {
                // Image セクション - 画像タップで投稿詳細へ
                NavigationLink(destination: PostDetailView(post: outfit.post)) {
                    CachedImage(
                        url: outfit.post.imageURL,
                        targetSize: CGSize(width: cardWidth * 2, height: imageHeight * 2)
                    )
                    .frame(width: cardWidth, height: imageHeight)
                    .clipped()
                }
                .buttonStyle(PlainButtonStyle())
                .overlay(alignment: .topTrailing) {
                    // Like button
                    Button(action: onLikeTapped) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.3))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: outfit.isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(outfit.isLiked ? Color(hex: "FF2539") : .white)
                        }
                    }
                    .padding(8)
                }
                
                // Info セクション
                HStack(spacing: 8) {
                    // Avatar & Name - タップでプロフィールへ
                    if let user = outfit.user, let userId = user.id {
                        NavigationLink(destination: UserProfileView(userId: userId)) {
                            HStack(spacing: 8) {
                                // Avatar
                                CachedAvatarImage(url: user.avatarURL, size: 22)
                                
                                // ユーザー情報
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(user.displayName)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(Color(hex: "2D2D2D"))
                                        .lineLimit(1)
                                    
                                    Text("\(outfit.post.temperature)°C")
                                        .font(.system(size: 10))
                                        .foregroundColor(Color(hex: "AAAAAA"))
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        // ユーザー情報がない場合
                        HStack(spacing: 8) {
                            CachedAvatarImage(url: nil, size: 22)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("ユーザー")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Color(hex: "2D2D2D"))
                                    .lineLimit(1)
                                
                                Text("\(outfit.post.temperature)°C")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color(hex: "AAAAAA"))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Weather icon
                    Image(systemName: outfit.post.weather.symbolName)
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "68717B"))
                        .frame(width: 20, height: 20)
                }
                .padding(.horizontal, 12)
                .frame(height: infoHeight)
                .frame(width: cardWidth)
                .background(Color.white)
            }
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
        }
        .frame(height: imageHeight + infoHeight)
        .clipped()
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
        .environmentObject(AuthService())
}
