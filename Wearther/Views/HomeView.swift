//
//  HomeView.swift
//  Wearther
//
//  Created by hato on 2025/11/07.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedTab: FeedTab = .recommended
    @State private var showNotifications = false
    @State private var showSettings = false
    
    enum FeedTab {
        case recommended
        case following
    }
    
    var body: some View {
        NavigationStack {
        GeometryReader { geometry in
            let safeBottom = geometry.safeAreaInsets.bottom
            let targetWidth: CGFloat = 360
            let horizontalPadding = max((geometry.size.width - targetWidth) / 2, 16)
            
            VStack(spacing: 0) {
                // MARK: - Custom Header (ロゴ中央配置)
                ZStack {
                    // Center Logo
                    Text("Wearther")
                        .font(.custom("Sinhala MN", size: 30))
                        .foregroundColor(.black)
                    
                    // Right Bell Icon
                    HStack {
                        Spacer()
                        Button(action: {
                            showNotifications = true
                        }) {
                            Image(systemName: "bell")
                                .font(.system(size: 24))
                                .foregroundColor(.black)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.white)
                .overlay(
                    Rectangle()
                        .fill(Color(hex: "DDDDDD"))
                        .frame(height: 0.2),
                    alignment: .bottom
                )
                
                ZStack(alignment: .top) {
                    // 背景色
                    Color(hex: "F8F8F8")
                        .ignoresSafeArea()
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            // MARK: - Weather Card
                            if viewModel.isWeatherLoading {
                                // ローディング状態
                                WeatherLoadingCard()
                            } else if !viewModel.isLocationSet {
                                // 居住地域未設定
                                LocationNotSetCard(onSettingsTapped: {
                                    showSettings = true
                                })
                            } else if let weather = viewModel.weather {
                                // 天気表示
                                WeatherCard(weather: weather)
                            } else if let error = viewModel.weatherError {
                                // エラー表示
                                WeatherErrorCard(message: error, onRetry: {
                                    Task {
                                        await viewModel.loadWeather(for: authService.currentUser)
                                    }
                                })
                            }
                            
                            // MARK: - Fashion Advice Card (コーデ提案カード)
                            if viewModel.isAdviceLoading {
                                // AIアドバイスローディング
                                AdviceLoadingCard()
                            } else if let advice = viewModel.fashionAdvice {
                                OutfitAdviceCard(advice: advice)
                            }
                            
                            // MARK: - Tab Selector
                            FeedTabSelector(selectedTab: $selectedTab)
                                .padding(.top, 8)
                            
                            // MARK: - Post Grid
                            OutfitGrid(
                                recommendations: viewModel.outfitRecommendations,
                                onLikeTapped: { recommendation in
                                    viewModel.toggleLike(for: recommendation)
                                },
                                onLoadMore: {
                                    // TODO: Implement pagination
                                }
                            )
                        }
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, 16)
                        .padding(.bottom, safeBottom + 60)
                    }
                    .scrollIndicators(.hidden)
                    .refreshable {
                        await viewModel.refresh(user: authService.currentUser)
                    }
                }
            }
            .background(Color.white)
        }
        .navigationDestination(isPresented: $showNotifications) {
            NotificationView()
        }
        .navigationDestination(isPresented: $showSettings) {
            SettingsView()
        }
        .navigationBarHidden(true)
        .task(id: authService.currentUser?.location) {
            // 初回ロード時、または居住地域が変更されたら天気データを取得
            await viewModel.loadWeather(for: authService.currentUser)
        }
        }
    }
}

// MARK: - Location Not Set Card (居住地域未設定カード)
private struct LocationNotSetCard: View {
    let onSettingsTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "location.slash")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "68717B"))
            
            VStack(spacing: 8) {
                Text("居住地域が設定されていません")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "2D2D2D"))
                
                Text("居住地域を設定すると、お住まいの地域の\n天気情報を表示できます")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "68717B"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            
            Button(action: onSettingsTapped) {
                HStack(spacing: 6) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14))
                    Text("設定画面へ")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color(hex: "2D2D2D"))
                .cornerRadius(24)
            }
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Weather Loading Card
private struct WeatherLoadingCard: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("天気情報を取得中...")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "68717B"))
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Weather Error Card
private struct WeatherErrorCard: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.icloud")
                .font(.system(size: 36))
                .foregroundColor(Color(hex: "68717B"))
            
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "68717B"))
                .multilineTextAlignment(.center)
            
            Button(action: onRetry) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14))
                    Text("再試行")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(Color(hex: "2D2D2D"))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color(hex: "F5F5F5"))
                .cornerRadius(20)
            }
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Advice Loading Card (AIアドバイスローディング)
private struct AdviceLoadingCard: View {
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
            
            Text("AIがコーデを考え中...")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: "68717B"))
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(28)
        .shadow(color: Color.black.opacity(0.03), radius: 9.2, x: 0, y: 0)
    }
}

// MARK: - Outfit Advice Card (コーデ提案カード)
private struct OutfitAdviceCard: View {
    let advice: FashionAdvice
    
    var body: some View {
        VStack(spacing: 11) {
            Text(advice.title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color(hex: "2D2D2D"))
                .multilineTextAlignment(.center)
            
            Text(advice.description)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color(hex: "2D2D2D"))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .padding(.vertical, 21)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(28)
        .shadow(color: Color.black.opacity(0.03), radius: 9.2, x: 0, y: 0)
    }
}

// MARK: - Feed Tab Selector
private struct FeedTabSelector: View {
    @Binding var selectedTab: HomeView.FeedTab
    
    var body: some View {
        HStack(spacing: 95) {
            // おすすめタブ
            TabButton(
                title: "おすすめ",
                isSelected: selectedTab == .recommended
            ) {
                selectedTab = .recommended
            }
            
            // フォロー中タブ
            TabButton(
                title: "フォロー中",
                isSelected: selectedTab == .following
            ) {
                selectedTab = .following
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(isSelected ? Color(hex: "000000") : Color(hex: "68717B"))
                
                // Underline
                Rectangle()
                    .fill(isSelected ? Color.black : Color.clear)
                    .frame(width: 40, height: 2)
            }
        }
    }
}

#Preview {
    HomeView()
}
