//
//  AIAdviceService.swift
//  Wearther
//
//  AI ファッションアドバイス生成サービス
//  Firebase Cloud Functions経由でOpenAI APIを呼び出し、
//  天気に基づいたファッションアドバイスを取得します
//

import Foundation
import Combine
import FirebaseFunctions

/// AIアドバイスサービス
/// Cloud Functions経由でAIファッションアドバイスを取得
@MainActor
class AIAdviceService: ObservableObject {
    static let shared = AIAdviceService()
    
    /// Cloud Functionsのインスタンス（東京リージョン）
    private lazy var functions = Functions.functions(region: "asia-northeast1")
    
    @Published var isLoading = false
    @Published var error: String?
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// 天気データに基づいてAIファッションアドバイスを取得
    /// - Parameters:
    ///   - weather: 天気データ
    ///   - user: ユーザー情報（オプション）
    /// - Returns: ファッションアドバイス
    func generateAdvice(
        weather: Weather,
        user: AppUser? = nil
    ) async throws -> FashionAdvice {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        // リクエストデータの構築
        var requestData: [String: Any] = [
            "weather": [
                "condition": weather.condition.rawValue,
                "temperature": weather.temperature,
                "minTemperature": weather.minTemperature,
                "precipitationChance": weather.precipitationChance,
                "location": weather.location
            ]
        ]
        
        // ユーザー設定がある場合は追加
        if let user = user {
            var preferences: [String: Any] = [:]
            
            if let gender = user.gender, gender != "未設定" {
                preferences["gender"] = gender
            }
            if let tolerance = user.temperatureTolerance, tolerance != "未設定" {
                preferences["temperatureTolerance"] = tolerance
            }
            
            if !preferences.isEmpty {
                requestData["userPreferences"] = preferences
            }
        }
        
        do {
            // Cloud Functionを呼び出し
            let callable = functions.httpsCallable("generateFashionAdvice")
            let result = try await callable.call(requestData)
            
            // レスポンスの解析
            guard let data = result.data as? [String: Any],
                  let title = data["title"] as? String,
                  let description = data["description"] as? String else {
                throw AIAdviceError.invalidResponse
            }
            
            return FashionAdvice(title: title, description: description)
            
        } catch {
            print("🤖 AI Advice Error: \(error)")
            self.error = error.localizedDescription
            
            // エラー時はフォールバックアドバイスを返す
            return generateFallbackAdvice(for: weather)
        }
    }
    
    // MARK: - Fallback Advice
    
    /// フォールバックアドバイス（API失敗時やオフライン時）
    /// 気温に基づいて適切なアドバイスを生成
    private func generateFallbackAdvice(for weather: Weather) -> FashionAdvice {
        let temp = weather.temperature
        
        if temp >= 30 {
            return FashionAdvice(
                title: "涼しげなTシャツとショートパンツを",
                description: "通気性の良い素材で暑さ対策。帽子や日傘で日差しを防ぎましょう"
            )
        } else if temp >= 25 {
            return FashionAdvice(
                title: "軽やかなシャツとボトムスで快適に",
                description: "薄手のトップスがおすすめ。室内の冷房対策に薄い羽織りもあると◎"
            )
        } else if temp >= 20 {
            return FashionAdvice(
                title: "長袖シャツや薄手のカーディガンを",
                description: "朝晩の寒暖差に対応できる重ね着スタイルがおすすめです"
            )
        } else if temp >= 15 {
            return FashionAdvice(
                title: "ライトアウターで季節の変わり目に対応",
                description: "ジャケットやパーカーを羽織って調節しやすいコーデを"
            )
        } else if temp >= 10 {
            return FashionAdvice(
                title: "コートやセーターを重ね着して暖かく",
                description: "風を通しにくいアウターやニットで暖かさをキープしましょう"
            )
        } else if temp >= 5 {
            return FashionAdvice(
                title: "厚手のコートとマフラーで防寒を",
                description: "ダウンジャケットやウールコートで本格的な防寒対策を"
            )
        } else {
            return FashionAdvice(
                title: "しっかり防寒で真冬の寒さに備えて",
                description: "ダウン・手袋・マフラー・ニット帽でしっかり暖かく"
            )
        }
    }
}

// MARK: - Errors

enum AIAdviceError: LocalizedError {
    case invalidResponse
    case networkError
    case functionNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "AIからの応答を解析できませんでした"
        case .networkError:
            return "ネットワークエラーが発生しました"
        case .functionNotFound:
            return "サーバー機能が見つかりません"
        }
    }
}
