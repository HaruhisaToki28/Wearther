//
//  ContentView.swift
//  Wearther
//
//  Created by 阿久津咲千 on 2025/12/17.
//
import SwiftUI
import Combine

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var splashViewModel = SplashViewModel()
    
    var body: some View {
        ZStack {
            Group {
                if authService.isAuthenticated {
                    MainTabView()
                } else {
                    SignInView()
                }
            }
            
            // Splash Screen
            if splashViewModel.isShowingSplash {
                SplashView(loadingStatus: splashViewModel.loadingStatus)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task {
            await splashViewModel.initialize(authService: authService)
        }
    }
}

// MARK: - Splash ViewModel

@MainActor
class SplashViewModel: ObservableObject {
    @Published var isShowingSplash = true
    @Published var loadingStatus = "起動中..."
    
    /// 最低表示時間（秒）- フラッシュを防ぐため
    private let minimumDisplayTime: TimeInterval = 1.5
    
    /// アプリの初期化処理を実行
    func initialize(authService: AuthService) async {
        let startTime = Date()
        
        // 1. 認証状態の確認
        loadingStatus = "認証情報を確認中..."
        await checkAuthState(authService: authService)
        
        // 2. ログイン済みの場合、ユーザーデータをプリロード
        if authService.isAuthenticated {
            loadingStatus = "ユーザー情報を読み込み中..."
            await preloadUserData(authService: authService)
            
            // 3. 初期データのプリロード
            loadingStatus = "データを準備中..."
            await preloadInitialData()
        }
        
        // 4. 最低表示時間を確保
        loadingStatus = "準備完了"
        let elapsed = Date().timeIntervalSince(startTime)
        if elapsed < minimumDisplayTime {
            try? await Task.sleep(nanoseconds: UInt64((minimumDisplayTime - elapsed) * 1_000_000_000))
        }
        
        // 5. スプラッシュを非表示
        withAnimation(.easeOut(duration: 0.4)) {
            isShowingSplash = false
        }
    }
    
    /// 認証状態を確認
    private func checkAuthState(authService: AuthService) async {
        // AuthServiceの初期化を待つ
        // isAuthenticatedが確定するまで少し待機
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3秒
    }
    
    /// ユーザーデータをプリロード
    private func preloadUserData(authService: AuthService) async {
        // ユーザー情報を事前に取得
        await authService.fetchUser()
    }
    
    /// 初期データをプリロード
    private func preloadInitialData() async {
        // 画像キャッシュの初期化は WeartherApp.swift で実行済み
        // 必要に応じて追加のプリロード処理をここに追加
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
    }
}
