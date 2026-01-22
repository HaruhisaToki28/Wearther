//
//  FashionSearchHistory.swift
//  Wearther
//
//  Created by Wearther on 2026/01/22.
//

import Foundation

/// ファッション検索の履歴アイテム
/// UserDefaultsに保存して永続化する
struct FashionSearchHistory: Codable, Identifiable, Equatable {
    
    // MARK: - Properties
    
    /// 一意のID（UUID）
    var id: String
    
    /// 検索キーワード
    var keyword: String
    
    /// 検索日時
    var searchedAt: Date
    
    // MARK: - Initialization
    
    init(keyword: String) {
        self.id = UUID().uuidString
        self.keyword = keyword
        self.searchedAt = Date()
    }
    
    // MARK: - Equatable
    
    static func == (lhs: FashionSearchHistory, rhs: FashionSearchHistory) -> Bool {
        // キーワードが同じなら同一とみなす（重複防止用）
        lhs.keyword.lowercased() == rhs.keyword.lowercased()
    }
}

// MARK: - UserDefaults Storage

extension FashionSearchHistory {
    
    /// UserDefaultsのキー
    private static let storageKey = "fashionSearchHistory"
    
    /// 保存できる最大履歴数
    private static let maxHistoryCount = 20
    
    /// 検索履歴を取得
    /// - Returns: 検索履歴の配列（新しい順）
    static func loadHistory() -> [FashionSearchHistory] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let history = try? JSONDecoder().decode([FashionSearchHistory].self, from: data) else {
            return []
        }
        return history.sorted { $0.searchedAt > $1.searchedAt }
    }
    
    /// 検索履歴を保存
    /// - Parameter history: 保存する検索履歴の配列
    static func saveHistory(_ history: [FashionSearchHistory]) {
        // 最大件数を超えないようにトリム
        let trimmedHistory = Array(history.prefix(maxHistoryCount))
        
        if let data = try? JSONEncoder().encode(trimmedHistory) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    /// 検索履歴に追加
    /// - Parameter keyword: 追加するキーワード
    /// - Returns: 更新後の検索履歴
    static func addToHistory(keyword: String) -> [FashionSearchHistory] {
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKeyword.isEmpty else { return loadHistory() }
        
        var history = loadHistory()
        let newItem = FashionSearchHistory(keyword: trimmedKeyword)
        
        // 既存の同じキーワードを削除（重複防止）
        history.removeAll { $0 == newItem }
        
        // 先頭に追加
        history.insert(newItem, at: 0)
        
        // 保存
        saveHistory(history)
        
        return history
    }
    
    /// 検索履歴から削除
    /// - Parameter item: 削除するアイテム
    /// - Returns: 更新後の検索履歴
    static func removeFromHistory(_ item: FashionSearchHistory) -> [FashionSearchHistory] {
        var history = loadHistory()
        history.removeAll { $0.id == item.id }
        saveHistory(history)
        return history
    }
    
    /// 検索履歴をすべて削除
    static func clearHistory() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}
