# Wearther 使用技術まとめ

## クライアント (iOS)
- SwiftUI
  - 宣言的UI構築、MVVMとの親和性
  - WidgetKit / App Group / BackgroundTasks連携を予定
- Combine / Swift Concurrency (`async`/`await`)
  - 非同期データ取得と状態管理
- CoreLocation
  - 位置情報による地域別天気取得（許諾必須）
- URLSession
  - Weathernews APIとの通信
- AppStorage / Keychain
  - 軽量キャッシュ、設定値保存、認証トークン管理
- XCTest / XCUITest
  - 単体・UIテスト、Snapshotテスト導入予定

## バックエンド / サービス
- Firebase Authentication
  - メール+パスワードによるユーザー管理、将来OAuth拡張
- Firebase Firestore
  - プロフィール、投稿、フィードバック、AIメタデータのドキュメントストア
- Firebase Storage
  - コーデ投稿の画像・動画保存、Cloud Functionsによるサムネイル生成
- Firebase Cloud Functions（Node.js / TypeScript）
  - Weathernews APIポーリング、AI推論呼び出し、通知トリガー、ランキング集計
- Firebase Cloud Messaging
  - 雨・気温変化、AI提案、コミュニティ通知
- Firebase Analytics / Crashlytics
  - 行動計測と障害検知

## 外部API / AI
- Weathernews API
  - 現在/時間別/週間天気の取得
  - レスポンスキャッシュとリトライ制御をFunctionsで実装
- 大規模言語モデル (LLM) API
  - AIコーデ提案生成（Vertex AI、OpenAI等候補）
  - Cloud Functionsから安全フィルタリングとコスト監視
- 画像解析サービス（検討中）
  - Vision APIなどを活用した投稿モデレーション、将来的なAR Try-on連携

## 開発・運用
- Xcode / Swift Package Manager
  - プロジェクトビルドと依存管理
- GitHub / GitHub Projects
  - バージョン管理、チケット運用
- Fastlane（導入予定）
  - TestFlight配布、自動ビルド
- Firebase Emulator Suite
  - ローカル検証（Auth/Firestore/Functions/Storage）
- Google Cloud Logging / Error Reporting
  - Functionsの運用監視

## セキュリティ / DevOps
- Firebase Security Rules / Storage Rules
  - 認可制御、リージョン`asia-northeast1`を想定
- Secret Manager / `.xcconfig`
  - Weathernews APIキー、LLMキーの安全管理
- Remote Config / Feature Flags
  - 機能の段階的リリース

