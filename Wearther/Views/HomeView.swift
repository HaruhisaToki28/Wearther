//
//  HomeView.swift
//  Wearther
//
//  Created by hato on 2025/11/07.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                let safeBottom = geometry.safeAreaInsets.bottom
                let targetWidth: CGFloat = 360
                let horizontalPadding = max((geometry.size.width - targetWidth) / 2, 16)
                
                VStack(spacing: 0) {
                    // MARK: - Custom Header
                    HStack {
                        Text("Wearther")
                            .font(.custom("Sinhala MN", size: 30))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Image(systemName: "bell")
                            .font(.system(size: 24))
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Color.white
                            .ignoresSafeArea(edges: .top)
                    )
                    
                    ZStack(alignment: .top) {
                        // 背景色（下層）: ベースはグレー
                        Color(red: 0.96, green: 0.96, blue: 0.96)
                            .ignoresSafeArea()
                        
                        // 背景色（上層）: 上部のバウンス領域用（白）
                        Color.white
                            .frame(height: 500)
                            .ignoresSafeArea()
                        
                        ScrollView {
                            VStack(spacing: 0) {
                                // 下に引っ張った時の上部背景用（白）は削除済み
                                
                                LazyVStack(alignment: .leading, spacing: 28) {
                                    if !viewModel.stories.isEmpty {
                                        StoriesSection(
                                            stories: viewModel.stories
                                        )
                                        .padding(.horizontal, -horizontalPadding)
                                    }
                                    
                                    if let weather = viewModel.weather {
                                        WeatherCard(weather: weather)
                                    }
                                    
                                    if let advice = viewModel.fashionAdvice {
                                        FashionAdviceCard(advice: advice)
                                    }
                            
                            SectionHeader(title: "あなたにおすすめ")
                            
                            OutfitGrid(
                                recommendations: viewModel.outfitRecommendations,
                                onLikeTapped: { recommendation in
                                    viewModel.toggleLike(for: recommendation)
                                },
                                onLoadMore: {
                                    // TODO: Implement pagination
                                    // viewModel.loadMoreRecommendations()
                                }
                            )
                            }
                            .padding(.horizontal, horizontalPadding)
                            .padding(.top, 0)
                            .padding(.bottom, safeBottom + 60)
                        }
                        .background(Color(red: 0.96, green: 0.96, blue: 0.96)) // コンテンツ部分に背景色を設定
                    }
                    .scrollIndicators(.hidden)
                    .refreshable {
                        await viewModel.refresh()
                    }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

private struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(Color(red: 0.176, green: 0.176, blue: 0.176))
    }
}

private struct StoriesSection: View {
    let stories: [StoryProfile]
    
    var body: some View {
        StoriesCarouselView(stories: stories)
            .padding(.vertical, 18)
            .background(Color.white)
            .overlay(
                Divider()
                    .background(Color(red: 0.87, green: 0.87, blue: 0.87))
                    .frame(height: 0.05),
                alignment: .bottom
            )
    }
}

private struct StoriesCarouselView: View {
    let stories: [StoryProfile]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 18) {
                ForEach(stories.prefix(18)) { story in
                    StoryCircleView(story: story)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

private struct StoryCircleView: View {
    let story: StoryProfile
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .strokeBorder(storyGradient, lineWidth: 4)
                    .frame(width: 88, height: 88)
                    .overlay(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 82, height: 82)
                    )
                
                AsyncImage(url: URL(string: story.imageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure(_), .empty:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
                .frame(width: 76, height: 76)
                .clipShape(Circle())
            }
            
            Text(story.username)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)
                .frame(width: 88)
        }
    }
    
    private var placeholder: some View {
        Circle()
            .fill(Color.gray.opacity(0.25))
            .overlay(
                Image(systemName: "person.fill")
                    .foregroundColor(.white)
            )
    }
    
    private var storyGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.78, green: 0.99, blue: 0.28),
                Color(red: 0.33, green: 0.99, blue: 0.58),
                Color(red: 0.12, green: 0.98, blue: 0.12)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview {
    HomeView()
}
