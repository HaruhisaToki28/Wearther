//
//  WeatherNewsResponse.swift
//  Wearther
//
//  Created by Wearther on 2025/12/23.
//

import Foundation

// MARK: - WeatherNews API Response
struct WeatherNewsResponse: Codable {
    let requestId: String
    let wxdata: [WeatherNewsData]
}

struct WeatherNewsData: Codable {
    let lat: Float
    let lon: Float
    let srf: [ShortRangeForecast]
    let mrf: [MediumRangeForecast]
}

// MARK: - Short Range Forecast (時間ごとの予報)
struct ShortRangeForecast: Codable, Identifiable {
    var id: String { date }
    let arpress: Float      // 気圧
    let date: String        // 日時
    let prec: Float         // 降水量
    let rhum: Int           // 湿度
    let temp: Float         // 気温
    let wnddir: Int         // 風向き
    let wndspd: Float       // 風速
    let wx: Int             // 天気コード
    
    var weatherCondition: WeatherCondition {
        WeatherCodeConverter.toCondition(wx)
    }
    
    var formattedTime: String {
        // "202312231200" -> "12:00"
        guard date.count >= 12 else { return "--:--" }
        let hourIndex = date.index(date.startIndex, offsetBy: 8)
        let minuteIndex = date.index(date.startIndex, offsetBy: 10)
        let hour = String(date[hourIndex..<minuteIndex])
        let minute = String(date[minuteIndex...])
        return "\(hour):\(minute)"
    }
    
    var formattedDate: String {
        // "202312231200" -> "12/23"
        guard date.count >= 8 else { return "--/--" }
        let monthIndex = date.index(date.startIndex, offsetBy: 4)
        let dayIndex = date.index(date.startIndex, offsetBy: 6)
        let month = String(date[monthIndex..<dayIndex])
        let day = String(date[dayIndex..<date.index(dayIndex, offsetBy: 2)])
        return "\(Int(month) ?? 0)/\(Int(day) ?? 0)"
    }
}

// MARK: - Medium Range Forecast (日ごとの予報)
struct MediumRangeForecast: Codable, Identifiable {
    var id: String { date }
    let date: String        // 日付
    let maxtemp: Float      // 最高気温
    let mintemp: Float      // 最低気温
    let pop: Int            // 降水確率
    let wx: Int             // 天気コード
    
    var weatherCondition: WeatherCondition {
        WeatherCodeConverter.toCondition(wx)
    }
    
    var formattedDate: String {
        // "20231223" -> "12/23"
        guard date.count >= 8 else { return "--/--" }
        let monthIndex = date.index(date.startIndex, offsetBy: 4)
        let dayIndex = date.index(date.startIndex, offsetBy: 6)
        let month = String(date[monthIndex..<dayIndex])
        let day = String(date[dayIndex...])
        return "\(Int(month) ?? 0)/\(Int(day) ?? 0)"
    }
    
    var dayOfWeek: String {
        guard date.count >= 8 else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        guard let dateObj = formatter.date(from: date) else { return "" }
        
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.locale = Locale(identifier: "ja_JP")
        weekdayFormatter.dateFormat = "E"
        return weekdayFormatter.string(from: dateObj)
    }
}

// MARK: - Weather Code Converter
enum WeatherCodeConverter {
    static func toCondition(_ code: Int) -> WeatherCondition {
        switch code {
        case 100...199:
            return .sunny
        case 200...299:
            return .partlyCloudy
        case 300...399:
            return .cloudy
        case 400...499:
            return .rainy
        case 500...599:
            return .snowy
        default:
            return .cloudy
        }
    }
    
    static func toDescription(_ code: Int) -> String {
        switch code {
        case 100:
            return "晴れ"
        case 101:
            return "晴れ時々くもり"
        case 102:
            return "晴れ一時雨"
        case 200:
            return "くもり時々晴れ"
        case 201:
            return "くもり"
        case 202:
            return "くもり時々雨"
        case 300:
            return "くもり"
        case 301:
            return "くもり時々雨"
        case 302:
            return "くもり一時雨"
        case 400:
            return "雨"
        case 401:
            return "雨時々くもり"
        case 402:
            return "大雨"
        case 500:
            return "雪"
        case 501:
            return "雪時々くもり"
        case 502:
            return "大雪"
        default:
            return "くもり"
        }
    }
}

