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
                VStack(spacing: 20) {
                    // Current Weather Card
                    if let weather = weatherService.currentWeather,
                       let current = weather.srf.first {
                        CurrentWeatherCard(
                            location: locationName,
                            forecast: current,
                            todayMax: weather.mrf.first?.maxtemp,
                            todayMin: weather.mrf.first?.mintemp,
                            pop: weather.mrf.first?.pop
                        )
                    } else if weatherService.isLoading {
                        LoadingWeatherCard()
                    } else {
                        EmptyWeatherCard(message: weatherService.errorMessage ?? "天気データを取得できません")
                    }
                    
                    // Hourly Forecast
                    if !weatherService.getTodayForecast().isEmpty {
                        HourlyForecastCard(forecasts: weatherService.getTodayForecast())
                    }
                    
                    // Weekly Forecast
                    if !weatherService.getWeeklyForecast().isEmpty {
                        WeeklyForecastCard(forecasts: weatherService.getWeeklyForecast())
                    }
                    
                    // Weather Details
                    if let weather = weatherService.currentWeather,
                       let current = weather.srf.first {
                        WeatherDetailsCard(forecast: current)
                    }
                    
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
        // Get location name
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

// MARK: - Current Weather Card
private struct CurrentWeatherCard: View {
    let location: String
    let forecast: ShortRangeForecast
    let todayMax: Float?
    let todayMin: Float?
    let pop: Int?
    
    var body: some View {
        VStack(spacing: 16) {
            // Location
            Text(location)
                .font(.system(size: 23, weight: .bold))
                .foregroundColor(Color(hex: "2D2D2D"))
            
            HStack(alignment: .center, spacing: 20) {
                // Weather Icon
                WeatherIconView(condition: forecast.weatherCondition, size: 80)
                
                // Temperature & Info
                VStack(alignment: .leading, spacing: 8) {
                    // Condition
                    Text(WeatherCodeConverter.toDescription(forecast.wx))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(hex: "2D2D2D"))
                    
                    // Temperature
                    HStack(alignment: .bottom, spacing: 8) {
                        // High
                        HStack(alignment: .bottom, spacing: 0) {
                            Text("\(Int(todayMax ?? forecast.temp))")
                                .font(.system(size: 35, weight: .bold))
                                .foregroundColor(Color(hex: "FF2539"))
                            Text("°C")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Color(hex: "FF2539"))
                                .padding(.bottom, 4)
                        }
                        
                        Rectangle()
                            .fill(Color(hex: "E5E5E5"))
                            .frame(width: 1, height: 26)
                        
                        // Low
                        HStack(alignment: .bottom, spacing: 0) {
                            Text("\(Int(todayMin ?? forecast.temp))")
                                .font(.system(size: 35, weight: .bold))
                                .foregroundColor(Color(hex: "3582DC"))
                            Text("°C")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Color(hex: "3582DC"))
                                .padding(.bottom, 4)
                        }
                    }
                    
                    // Precipitation
                    HStack(spacing: 5) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "08C4FA"))
                        
                        Text("降水確率 \(pop ?? 0)%")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(hex: "2D2D2D"))
                    }
                }
            }
        }
        .padding(.vertical, 21)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(28)
        .shadow(color: Color.black.opacity(0.03), radius: 9.2, x: 0, y: 0)
    }
}

// MARK: - Hourly Forecast Card
private struct HourlyForecastCard: View {
    let forecasts: [ShortRangeForecast]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("時間ごとの天気")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: "2D2D2D"))
                .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(forecasts.prefix(24).enumerated()), id: \.element.id) { index, forecast in
                        HourlyForecastItem(forecast: forecast, isNow: index == 0)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.03), radius: 9.2, x: 0, y: 0)
    }
}

private struct HourlyForecastItem: View {
    let forecast: ShortRangeForecast
    let isNow: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Text(isNow ? "今" : forecast.formattedTime)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color(hex: "68717B"))
            
            WeatherIconView(condition: forecast.weatherCondition, size: 28)
            
            Text("\(Int(forecast.temp))°")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(hex: "2D2D2D"))
            
            HStack(spacing: 2) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 8))
                    .foregroundColor(Color(hex: "08C4FA"))
                Text("\(Int(forecast.prec))%")
                    .font(.system(size: 9))
                    .foregroundColor(Color(hex: "68717B"))
            }
        }
        .frame(width: 50)
    }
}

// MARK: - Weekly Forecast Card
private struct WeeklyForecastCard: View {
    let forecasts: [MediumRangeForecast]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("週間天気予報")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: "2D2D2D"))
            
            VStack(spacing: 0) {
                ForEach(Array(forecasts.enumerated()), id: \.element.id) { index, forecast in
                    WeeklyForecastRow(forecast: forecast, isToday: index == 0)
                    
                    if index < forecasts.count - 1 {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.03), radius: 9.2, x: 0, y: 0)
    }
}

private struct WeeklyForecastRow: View {
    let forecast: MediumRangeForecast
    let isToday: Bool
    
    var body: some View {
        HStack {
            // Date
            HStack(spacing: 4) {
                Text(isToday ? "今日" : forecast.formattedDate)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "2D2D2D"))
                    .frame(width: 45, alignment: .leading)
                
                Text(forecast.dayOfWeek)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "68717B"))
                    .frame(width: 20)
            }
            
            Spacer()
            
            // Weather Icon
            WeatherIconView(condition: forecast.weatherCondition, size: 28)
            
            Spacer()
            
            // Precipitation
            HStack(spacing: 2) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "08C4FA"))
                Text("\(forecast.pop)%")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "68717B"))
            }
            .frame(width: 45)
            
            Spacer()
            
            // Temperature
            HStack(spacing: 8) {
                Text("\(Int(forecast.maxtemp))°")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "FF2539"))
                    .frame(width: 35, alignment: .trailing)
                
                Text("\(Int(forecast.mintemp))°")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "3582DC"))
                    .frame(width: 35, alignment: .trailing)
            }
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Weather Details Card
private struct WeatherDetailsCard: View {
    let forecast: ShortRangeForecast
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("詳細情報")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: "2D2D2D"))
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                WeatherDetailItem(icon: "thermometer", title: "体感温度", value: "\(Int(forecast.temp))°C")
                WeatherDetailItem(icon: "humidity", title: "湿度", value: "\(forecast.rhum)%")
                WeatherDetailItem(icon: "wind", title: "風速", value: String(format: "%.1fm/s", forecast.wndspd))
                WeatherDetailItem(icon: "gauge", title: "気圧", value: "\(Int(forecast.arpress))hPa")
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.03), radius: 9.2, x: 0, y: 0)
    }
}

private struct WeatherDetailItem: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color(hex: "68717B"))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "68717B"))
                
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "2D2D2D"))
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color(hex: "F8F8F8"))
        .cornerRadius(12)
    }
}

// MARK: - Weather Icon View
private struct WeatherIconView: View {
    let condition: WeatherCondition
    let size: CGFloat
    
    var body: some View {
        Image(systemName: condition.symbolName)
            .symbolRenderingMode(.palette)
            .foregroundStyle(paletteColors[0], paletteColors[1], paletteColors[2])
            .font(.system(size: size))
    }
    
    private var paletteColors: [Color] {
        switch condition {
        case .sunny:
            return [
                Color(red: 1.0, green: 0.74, blue: 0.20),
                Color(red: 1.0, green: 0.55, blue: 0.14),
                Color(red: 1.0, green: 0.87, blue: 0.53)
            ]
        case .partlyCloudy:
            return [
                Color(red: 0.82, green: 0.86, blue: 0.94),
                Color(red: 1.0, green: 0.74, blue: 0.20),
                Color(red: 1.0, green: 0.55, blue: 0.14)
            ]
        case .cloudy:
            return [
                Color(red: 0.80, green: 0.83, blue: 0.90),
                Color(red: 0.66, green: 0.70, blue: 0.78),
                Color(red: 0.92, green: 0.94, blue: 0.97)
            ]
        case .rainy:
            return [
                Color(red: 0.75, green: 0.82, blue: 0.95),
                Color(hex: "08C4FA"),
                Color(red: 0.35, green: 0.56, blue: 0.95)
            ]
        case .snowy:
            return [
                Color(red: 0.88, green: 0.93, blue: 0.99),
                Color.white,
                Color(red: 0.74, green: 0.82, blue: 0.97)
            ]
        }
    }
}

// MARK: - Loading & Empty States
private struct LoadingWeatherCard: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("天気データを取得中...")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "68717B"))
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(28)
        .shadow(color: Color.black.opacity(0.03), radius: 9.2, x: 0, y: 0)
    }
}

private struct EmptyWeatherCard: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "icloud.slash")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "68717B"))
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "68717B"))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(28)
        .shadow(color: Color.black.opacity(0.03), radius: 9.2, x: 0, y: 0)
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
        // 位置情報取得に失敗した場合、デフォルト座標を使用
        if location == nil {
            location = defaultLocation
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        } else if authorizationStatus == .denied || authorizationStatus == .restricted {
            // 権限が拒否された場合もデフォルト座標を使用
            location = defaultLocation
        }
    }
}

#Preview {
    WeatherView()
}
