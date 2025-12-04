//
//  HomeView.swift
//  Wearther
//
//  Created by hato on 2025/11/07.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var isHeaderVisible = true
    @State private var previousScrollOffset: CGFloat = 0
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                let safeBottom = geometry.safeAreaInsets.bottom
                let targetWidth: CGFloat = 360
                let horizontalPadding = max((geometry.size.width - targetWidth) / 2, 20)
                let safeTop = geometry.safeAreaInsets.top
                let headerExpandedHeight = safeTop + 52
                
                VStack(spacing: 0) {
                    HomeHeaderBar(
                        safeAreaTop: safeTop,
                        horizontalPadding: horizontalPadding
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: isHeaderVisible ? headerExpandedHeight : 0, alignment: .top)
                    .clipped()
                    .animation(.easeInOut(duration: 0.24), value: isHeaderVisible)
                    
                    ScrollView {
                        GeometryReader { proxy in
                            Color.clear
                                .preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: proxy.frame(in: .global).minY
                                )
                        }
                        .frame(height: 0)
                        
                        LazyVStack(alignment: .leading, spacing: 28) {
                            if !viewModel.stories.isEmpty {
                                StoriesSection(
                                    stories: viewModel.stories,
                                    horizontalPadding: horizontalPadding
                                )
                            }
                            
                            if let weather = viewModel.weather {
                                WeatherCard(weather: weather)
                            }
                            
                            if let advice = viewModel.fashionAdvice {
                                FashionAdviceCard(advice: advice)
                            }
                            
                            SectionHeader(title: "あなたにおすすめ")
                            
                            OutfitCarousel(
                                recommendations: viewModel.outfitRecommendations,
                                onLikeTapped: { recommendation in
                                    viewModel.toggleLike(for: recommendation)
                                }
                            )
                        }
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, 24)
                        .padding(.bottom, safeBottom + 60)
                    }
                    .coordinateSpace(name: "homeScroll")
                    .scrollIndicators(.hidden)
                }
                .background(
                    Color(red: 0.96, green: 0.96, blue: 0.96)
                        .ignoresSafeArea()
                )
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    updateHeaderVisibility(with: value)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }
}

private struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.primary)
    }
}

private struct HomeHeaderView: View {
    var body: some View {
        HStack(alignment: .center) {
            Text("Wearther")
                .font(.system(size: 30, weight: .bold))
                .kerning(-1)
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)
            
            Spacer()
            
            HeaderIconButton(systemName: "bell")
        }
    }
}

private struct HeaderIconButton: View {
    let systemName: String
    
    var body: some View {
        Button(action: {}) {
            Image(systemName: systemName)
                .font(.system(size: 22, weight: .regular))
                .foregroundColor(.primary)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
    }
}

private struct StoriesSection: View {
    let stories: [StoryProfile]
    let horizontalPadding: CGFloat
    
    var body: some View {
        StoriesCarouselView(stories: stories)
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(Color.white)
            .padding(.horizontal, -horizontalPadding)
    }
}

private struct HomeHeaderBar: View {
    let safeAreaTop: CGFloat
    let horizontalPadding: CGFloat
    
    var body: some View {
        HomeHeaderView()
            .padding(.top, safeAreaTop + 2)
            .padding(.horizontal, horizontalPadding)
            .padding(.bottom, 8)
            .background(Color.white)
    }
}

private struct StoriesCarouselView: View {
    let stories: [StoryProfile]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 18) {
                ForEach(stories.prefix(10)) { story in
                    StoryCircleView(story: story)
                }
            }
            .padding(.horizontal, 4)
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

private extension HomeView {
    func updateHeaderVisibility(with newOffset: CGFloat) {
        let threshold: CGFloat = 8
        let delta = newOffset - previousScrollOffset
        
        guard abs(delta) > threshold else { return }
        
        if delta < 0 {
            withAnimation(.easeInOut(duration: 0.24)) {
                isHeaderVisible = false
            }
        } else {
            withAnimation(.easeInOut(duration: 0.24)) {
                isHeaderVisible = true
            }
        }
        
        previousScrollOffset = newOffset
    }
}

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    HomeView()
}



