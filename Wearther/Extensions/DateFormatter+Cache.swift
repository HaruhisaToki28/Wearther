//
//  DateFormatter+Cache.swift
//  Wearther
//
//  Created by Wearther on 2026/01/23.
//

import Foundation

/// DateFormatterのキャッシュ
/// DateFormatterは生成コストが高いため、再利用することでパフォーマンスを向上
enum DateFormatterCache {
    
    // MARK: - Japanese Formatters
    
    /// 「M月d日」形式（例: 1月23日）
    static let monthDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日"
        return formatter
    }()
    
    /// 「M/d」形式（例: 1/23）
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return formatter
    }()
    
    /// 「HH:mm」形式（例: 14:30）
    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return formatter
    }()
    
    /// 曜日（例: 月）
    static let dayOfWeek: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        formatter.dateFormat = "E"
        return formatter
    }()
}
