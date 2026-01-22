//
//  SearchQuery.swift
//  Wearther
//
//  Created by Wearther on 2026/01/22.
//

import Foundation
import FirebaseFirestore

/// 検索クエリを保存するモデル
/// 人気の検索機能で使用
struct SearchQuery: Codable, Identifiable {
    @DocumentID var id: String?
    
    /// 検索キーワード
    var keyword: String
    
    /// 今週の検索回数
    var weeklySearchCount: Int
    
    /// 累計検索回数
    var totalSearchCount: Int
    
    /// 最終更新日時
    var updatedAt: Date
    
    init(
        id: String? = nil,
        keyword: String,
        weeklySearchCount: Int = 0,
        totalSearchCount: Int = 0,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.keyword = keyword
        self.weeklySearchCount = weeklySearchCount
        self.totalSearchCount = totalSearchCount
        self.updatedAt = updatedAt
    }
}
