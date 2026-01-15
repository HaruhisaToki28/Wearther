//
//  HomeView.swift
//  Wearther
//
//  Created by hato on 2025/11/07.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedTab: FeedTab = .recommended
    @State private var showNotifications = false
    
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
                            if let weather = viewModel.weather {
                                WeatherCard(weather: weather)
                            }
                            
                            // MARK: - Fashion Advice Card (コーデ提案カード)
                            if let advice = viewModel.fashionAdvice {
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
                        await viewModel.refresh()
                    }
                }
            }
            .background(Color.white)
        }
        .navigationDestination(isPresented: $showNotifications) {
            NotificationView()
        }
        .navigationBarHidden(true)
        }
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
