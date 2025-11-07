# SwiftUI アプリケーション アーキテクチャガイド

## 概要

このドキュメントでは、SwiftUIアプリケーションを開発する際に、コードの可読性と保守性を向上させるためのアーキテクチャパターンとベストプラクティスを説明します。

## 推奨アーキテクチャ: MVVM (Model-View-ViewModel)

SwiftUIアプリケーションでは、**MVVM (Model-View-ViewModel)** パターンを推奨します。このパターンは、SwiftUIの宣言的な性質と状態管理機能と非常に相性が良く、コードの分離とテスタビリティを向上させます。

## ディレクトリ構造

```
Wearther/
├── App/
│   └── WeartherApp.swift
├── Models/
│   ├── Weather.swift
│   └── Location.swift
├── Views/
│   ├── ContentView.swift
│   ├── WeatherView.swift
│   └── Components/
│       └── WeatherCard.swift
├── ViewModels/
│   ├── WeatherViewModel.swift
│   └── LocationViewModel.swift
├── Services/
│   ├── WeatherService.swift
│   ├── LocationService.swift
│   └── NetworkService.swift
├── Utilities/
│   ├── Extensions/
│   │   ├── String+Extensions.swift
│   │   └── Date+Extensions.swift
│   └── Constants.swift
└── Resources/
    └── Assets.xcassets/
```

## 各レイヤーの責務

### 1. Models（モデル）

**責務**: アプリケーションのデータ構造を定義

- データの構造と型を定義
- ビジネスロジックを含まない
- `Codable`プロトコルを実装してJSONデコードを可能にする
- 値型（`struct`）を使用することを推奨

**例**:
```swift
struct Weather: Codable, Identifiable {
    let id: UUID
    let temperature: Double
    let condition: String
    let humidity: Double
    let timestamp: Date
}
```

### 2. Views（ビュー）

**責務**: UIの表示とユーザーインタラクションの処理

- SwiftUIの`View`プロトコルを実装
- ビジネスロジックを含めない
- ViewModelから状態を取得し、表示のみを行う
- 再利用可能な小さなコンポーネントに分割

**例**:
```swift
struct WeatherView: View {
    @StateObject private var viewModel = WeatherViewModel()
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
            } else if let weather = viewModel.weather {
                WeatherCard(weather: weather)
            } else if let error = viewModel.error {
                ErrorView(error: error)
            }
        }
        .task {
            await viewModel.fetchWeather()
        }
    }
}
```

### 3. ViewModels（ビューモデル）

**責務**: ビューとモデルの間の橋渡し、ビジネスロジックの実装

- `ObservableObject`プロトコルを実装
- `@Published`プロパティで状態を管理
- ビューの状態（ローディング、エラーなど）を管理
- サービス層を呼び出してデータを取得・更新
- テスト可能な形でロジックを実装

**例**:
```swift
@MainActor
class WeatherViewModel: ObservableObject {
    @Published var weather: Weather?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let weatherService: WeatherServiceProtocol
    
    init(weatherService: WeatherServiceProtocol = WeatherService()) {
        self.weatherService = weatherService
    }
    
    func fetchWeather() async {
        isLoading = true
        error = nil
        
        do {
            weather = try await weatherService.fetchWeather()
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
}
```

### 4. Services（サービス層）

**責務**: 外部リソースとの通信（API、データベース、ファイルシステムなど）

- プロトコルを定義して依存性注入を可能にする
- ネットワークリクエスト、データベース操作などを実装
- エラーハンドリングを適切に実装
- 再利用可能な機能を提供

**例**:
```swift
protocol WeatherServiceProtocol {
    func fetchWeather() async throws -> Weather
}

class WeatherService: WeatherServiceProtocol {
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }
    
    func fetchWeather() async throws -> Weather {
        let data = try await networkService.request(
            url: APIEndpoint.weather.url,
            method: .get
        )
        return try JSONDecoder().decode(Weather.self, from: data)
    }
}
```

### 5. Utilities（ユーティリティ）

**責務**: 共通機能、拡張、定数の提供

- 再利用可能なヘルパー関数
- Swift標準型の拡張
- アプリケーション全体で使用する定数

**例**:
```swift
extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
}

extension Date {
    func formatted(style: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        return formatter.string(from: self)
    }
}
```

## ベストプラクティス

### 1. 状態管理

- **`@State`**: ビュー内でのみ使用されるローカル状態
- **`@StateObject`**: ビューが所有する`ObservableObject`
- **`@ObservedObject`**: 親から渡される`ObservableObject`
- **`@EnvironmentObject`**: 環境を通じて共有されるオブジェクト
- **`@Published`**: ViewModel内で状態変更を通知するプロパティ

### 2. 依存性注入（Dependency Injection）

プロトコルを使用して依存関係を抽象化し、テストを容易にします。

```swift
// プロトコルを定義
protocol WeatherServiceProtocol {
    func fetchWeather() async throws -> Weather
}

// ViewModelでプロトコルを使用
class WeatherViewModel: ObservableObject {
    private let weatherService: WeatherServiceProtocol
    
    init(weatherService: WeatherServiceProtocol) {
        self.weatherService = weatherService
    }
}
```

### 3. エラーハンドリング

- カスタムエラー型を定義
- エラーを適切にユーザーに表示
- ログ記録を実装

```swift
enum WeatherError: LocalizedError {
    case networkError
    case invalidData
    case locationNotFound
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "ネットワークエラーが発生しました"
        case .invalidData:
            return "データの形式が正しくありません"
        case .locationNotFound:
            return "位置情報が見つかりません"
        }
    }
}
```

### 4. 非同期処理

- `async/await`を使用して非同期処理を実装
- `@MainActor`を使用してUI更新をメインスレッドで実行
- `Task`を使用してビューから非同期処理を呼び出す

### 5. コンポーネント化

- 再利用可能な小さなビューコンポーネントを作成
- 単一責任の原則に従う
- プロパティを通じてデータを受け取る

```swift
struct WeatherCard: View {
    let weather: Weather
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(weather.condition)
            Text("\(weather.temperature)°C")
        }
        .padding()
    }
}
```

### 6. 命名規則

- **Views**: `[機能名]View` (例: `WeatherView`, `SettingsView`)
- **ViewModels**: `[機能名]ViewModel` (例: `WeatherViewModel`)
- **Models**: 単数形の名詞 (例: `Weather`, `User`)
- **Services**: `[機能名]Service` (例: `WeatherService`)
- **Components**: 説明的な名前 (例: `WeatherCard`, `LoadingIndicator`)

### 7. テスト

- ViewModelのロジックをテスト可能にする
- プロトコルを使用してモックを作成
- 単体テストと統合テストを書く

```swift
class MockWeatherService: WeatherServiceProtocol {
    var weather: Weather?
    var error: Error?
    
    func fetchWeather() async throws -> Weather {
        if let error = error {
            throw error
        }
        return weather!
    }
}
```

## アーキテクチャの利点

1. **可読性**: 各レイヤーの責務が明確で、コードが理解しやすい
2. **保守性**: 変更が局所化され、影響範囲が限定的
3. **テスタビリティ**: 各レイヤーを独立してテスト可能
4. **再利用性**: コンポーネントやサービスを再利用可能
5. **スケーラビリティ**: アプリケーションの成長に合わせて拡張可能

## 注意事項

- 過度な抽象化は避ける（YAGNI原則: You Aren't Gonna Need It）
- 小さなプロジェクトでは、シンプルな構造を維持
- チームのスキルレベルに合わせてアーキテクチャを調整
- 定期的にコードレビューを行い、一貫性を保つ

## 参考リソース

- [Apple's SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [SwiftUI Best Practices](https://www.swiftbysundell.com/articles/swiftui-best-practices/)
- [MVVM Pattern in SwiftUI](https://www.hackingwithswift.com/books/ios-swiftui/introducing-mvvm-into-your-swiftui-project)

