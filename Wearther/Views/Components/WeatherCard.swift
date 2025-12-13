//
//  WeatherCard.swift
//  Wearther
//
//  Created by hato on 2025/11/07.
//

import SwiftUI

struct WeatherCard: View {
    let weather: Weather
    
    var body: some View {
        VStack(spacing: 16) {
            Text(weather.location)
                .font(.system(size: 25, weight: .bold))
                .kerning(-0.5)
                .foregroundColor(WeatherCardColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .center)
            
            HStack(alignment: .center, spacing: 0) {
                // 左半分: 天気アイコン
                WeatherIllustrationView(condition: weather.condition)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
                
                // 右半分: 情報
                VStack(alignment: .leading, spacing: 4) {
                    Text(weather.condition.rawValue)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(WeatherCardColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    TemperatureSpreadView(
                        high: Int(weather.temperature.rounded()),
                        low: Int(weather.minTemperature.rounded())
                    )
                    
                    PrecipitationRow(chance: weather.precipitationChance)
                }
                .frame(maxWidth: .infinity)
                .padding(.leading, 10)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(WeatherCardColors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(WeatherCardColors.cardBorder, lineWidth: 1)
        )
        .shadow(color: WeatherCardColors.cardShadow, radius: 20, x: 0, y: 12)
        .frame(maxWidth: 360)
        .frame(maxWidth: .infinity, alignment: .center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(weather.location)、\(weather.condition.rawValue)")
        .accessibilityValue("最高気温 \(Int(weather.temperature.rounded()))度、最低気温 \(Int(weather.minTemperature.rounded()))度、降水確率 \(weather.precipitationChance) パーセント")
    }
}

private enum WeatherCardColors {
    static let textPrimary = Color(red: 0.176, green: 0.176, blue: 0.176) // #2D2D2D
    static let textSecondary = Color(red: 0.176, green: 0.176, blue: 0.176) // Changed to match primary
    static let highTemperature = Color(red: 1.0, green: 0.145, blue: 0.223) // #FF2539
    static let lowTemperature = Color(red: 0.21, green: 0.51, blue: 0.86) // #3582DC
    static let cardBackground = Color.white
    static let cardBorder = Color.black.opacity(0.05)
    static let cardShadow = Color.black.opacity(0.08)
    static let precipitationIcon = Color(red: 0.03, green: 0.77, blue: 0.98) // #08C4FA
}

private struct TemperatureSpreadView: View {
    let high: Int
    let low: Int
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            TemperatureValueView(
                value: high,
                color: WeatherCardColors.highTemperature
            )
            
            Rectangle()
                .fill(Color.black.opacity(0.08))
                .frame(width: 1, height: 24)
            
            TemperatureValueView(
                value: low,
                color: WeatherCardColors.lowTemperature
            )
        }
    }
}

private struct TemperatureValueView: View {
    let value: Int
    let color: Color
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            Text("\(value)")
                .font(.system(size: 40, weight: .bold))
                .monospacedDigit()
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .kerning(-2)
            
            Text("°C")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
                .padding(.bottom, 5)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("摂氏\(value)度")
        .fixedSize(horizontal: true, vertical: false)
    }
}

private struct PrecipitationRow: View {
    let chance: Int
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "drop.fill")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(WeatherCardColors.precipitationIcon)
            
            Text("降水確率 \(chance)%")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(WeatherCardColors.textSecondary)
        }
        .accessibilityLabel("降水確率 \(chance)パーセント")
    }
}

private struct WeatherIllustrationView: View {
    let condition: WeatherCondition
    
    var body: some View {
        ZStack {
            Image(systemName: symbolName)
                .symbolRenderingMode(.palette)
                .foregroundStyle(
                    paletteColors[0],
                    paletteColors.indices.contains(1) ? paletteColors[1] : paletteColors[0],
                    paletteColors.indices.contains(2) ? paletteColors[2] : paletteColors.last ?? paletteColors[0]
                )
                .font(.system(size: 72, weight: .semibold))
                .frame(width: 110, height: 80)
        }
    }
    
    private var symbolName: String {
        switch condition {
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
                Color(red: 0.82, green: 0.86, blue: 0.94), // cloud
                Color(red: 1.0, green: 0.74, blue: 0.20), // sun
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
                Color(red: 0.75, green: 0.82, blue: 0.95), // cloud
                WeatherCardColors.precipitationIcon,        // rain
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

#Preview {
    WeatherCard(
        weather: Weather(
            location: "東京都千代田区",
            condition: .partlyCloudy,
            temperature: 19.0,
            minTemperature: 11.0,
            feelsLike: 18.0,
            precipitationChance: 60
        )
    )
    .padding()
    .background(Color(red: 0.96, green: 0.96, blue: 0.96))
}

