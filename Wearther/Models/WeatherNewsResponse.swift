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
        // 複数の日付形式に対応
        if let parsedDate = DateParserHelper.parseDate(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            formatter.locale = Locale(identifier: "ja_JP")
            formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
            return formatter.string(from: parsedDate)
        }
        return "--:--"
    }
    
    var formattedDate: String {
        // 複数の日付形式に対応
        if let parsedDate = DateParserHelper.parseDate(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            formatter.locale = Locale(identifier: "ja_JP")
            formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
            return formatter.string(from: parsedDate)
        }
        return "--/--"
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
        // 複数の日付形式に対応
        if let parsedDate = DateParserHelper.parseDate(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            formatter.locale = Locale(identifier: "ja_JP")
            formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
            return formatter.string(from: parsedDate)
        }
        return "--/--"
    }
    
    var dayOfWeek: String {
        if let parsedDate = DateParserHelper.parseDate(date) {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ja_JP")
            formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
            formatter.dateFormat = "E"
            return formatter.string(from: parsedDate)
        }
        return ""
    }
}

// MARK: - Date Parser Helper
enum DateParserHelper {
    // 複数の日付形式に対応するパーサー
    static func parseDate(_ dateString: String) -> Date? {
        let formatters: [DateFormatter] = [
            // ISO 8601 形式 (2023-12-23T15:00:00)
            createFormatter("yyyy-MM-dd'T'HH:mm:ss"),
            // ISO 8601 形式 タイムゾーン付き
            createFormatter("yyyy-MM-dd'T'HH:mm:ssZ"),
            createFormatter("yyyy-MM-dd'T'HH:mm:ssXXXXX"),
            // コンパクト形式 (202312231500)
            createFormatter("yyyyMMddHHmm"),
            // コンパクト日付のみ (20231223)
            createFormatter("yyyyMMdd"),
            // ハイフン区切り (2023-12-23)
            createFormatter("yyyy-MM-dd"),
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        // ISO8601DateFormatterも試す
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: dateString) {
            return date
        }
        
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: dateString) {
            return date
        }
        
        return nil
    }
    
    private static func createFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return formatter
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
