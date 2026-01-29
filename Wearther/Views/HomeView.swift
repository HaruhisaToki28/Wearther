//
//  HomeView.swift
//  Wearther
//
//  Created by hato on 2025/11/07.
//

import SwiftUI
import Kingfisher

struct HomeView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedTab: FeedTab = .following // デフォルトはフォロー中
    @State private var showNotifications = false
    @State private var showSettings = false
    @State private var initialLoadDone = false
    
    enum FeedTab {
        case recommended
        case following
    }
    
    /// おすすめタブが有効かどうか（居住地域が設定されている場合のみ）
    private var isRecommendedEnabled: Bool {
        viewModel.isLocationSet
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
                        .foregroundColor(Color.primary)
                    
                    // Right Bell Icon
                    HStack {
                        Spacer()
                        Button(action: {
                            showNotifications = true
                        }) {
                            Image(systemName: "bell")
                                .font(.system(size: 22))
                                .foregroundColor(Color.primary)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .accessibilityLabel("通知")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color(.systemBackground))
                .overlay(
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(height: 0.5),
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
                            FeedTabSelector(
                                selectedTab: $selectedTab,
                                isRecommendedEnabled: isRecommendedEnabled
                            )
                            .padding(.top, 8)
                            
                            // MARK: - Post Content
                            if selectedTab == .recommended {
                                // おすすめタブ
                                if viewModel.isRecommendedLoading {
                                    PostLoadingView()
                                } else if viewModel.recommendedPosts.isEmpty {
                                    EmptyRecommendedView()
                                } else {
                                    PostGridView(
                                        posts: viewModel.recommendedPosts,
                                        users: viewModel.recommendedPostUsers,
                                        isLiked: { viewModel.isLiked($0) },
                                        onLikeTapped: { post in
                                            if let userId = authService.currentUser?.id {
                                                Task {
                                                    await viewModel.toggleLike(for: post, userId: userId)
                                                }
                                            }
                                        }
                                    )
                                }
                            } else {
                                // フォロー中タブ
                                if viewModel.isFollowingLoading {
                                    PostLoadingView()
                                } else if !viewModel.hasFollowingUsers {
                                    // フォローしているユーザーがいない場合
                                    NoFollowingView()
                                } else if viewModel.followingPosts.isEmpty {
                                    // フォロー中だが投稿がない場合
                                    EmptyFollowingPostsView()
                                } else {
                                    PostGridView(
                                        posts: viewModel.followingPosts,
                                        users: viewModel.followingPostUsers,
                                        isLiked: { viewModel.isLiked($0) },
                                        onLikeTapped: { post in
                                            if let userId = authService.currentUser?.id {
                                                Task {
                                                    await viewModel.toggleLike(for: post, userId: userId)
                                                }
                                            }
                                        }
                                    )
                                }
                            }
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
        .task(id: authService.currentUser?.id) {
            // ユーザーが取得されたらデータをロード
            guard authService.currentUser != nil else { return }
            
            // 天気データを取得
            await viewModel.loadWeather(for: authService.currentUser)
            
            // 天気取得後におすすめ投稿をロード
            if viewModel.isLocationSet {
                await viewModel.loadRecommendedPosts(user: authService.currentUser)
            }
            
            // フォロー中の投稿をロード
            await viewModel.loadFollowingPosts(user: authService.currentUser)
            
            // 居住地域が設定されていればおすすめをデフォルトに
            if viewModel.isLocationSet && !initialLoadDone {
                selectedTab = .recommended
            }
            initialLoadDone = true
        }
        .onChange(of: selectedTab) { _, newTab in
            // タブ切り替え時にデータがなければロード
            Task {
                if newTab == .recommended && viewModel.recommendedPosts.isEmpty && viewModel.isLocationSet {
                    await viewModel.loadRecommendedPosts(user: authService.currentUser)
                } else if newTab == .following && viewModel.followingPosts.isEmpty {
                    await viewModel.loadFollowingPosts(user: authService.currentUser)
                }
            }
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

// MARK: - Weather Loading Card (Skeleton)
private struct WeatherLoadingCard: View {
    var body: some View {
        HStack(spacing: 16) {
            // 天気アイコン
            Circle()
                .fill(Color(hex: "E8EDF5"))
                .frame(width: 60, height: 60)
                .shimmer()
            
            VStack(alignment: .leading, spacing: 8) {
                // 場所
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "E8EDF5"))
                    .frame(width: 80, height: 14)
                
                // 気温
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "E8EDF5"))
                    .frame(width: 100, height: 28)
                
                // 天気
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "E8EDF5"))
                    .frame(width: 60, height: 12)
            }
            
            Spacer()
        }
        .padding(20)
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

// MARK: - Advice Loading Card (AIアドバイスローディング - Skeleton)
private struct AdviceLoadingCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // タイトル
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(hex: "E8EDF5"))
                    .frame(width: 24, height: 24)
                    .shimmer()
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "E8EDF5"))
                    .frame(width: 120, height: 16)
            }
            
            // テキスト行
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "E8EDF5"))
                    .frame(height: 14)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "E8EDF5"))
                    .frame(width: 200, height: 14)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
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
    let isRecommendedEnabled: Bool
    
    var body: some View {
        HStack(spacing: 95) {
            // おすすめタブ
            TabButton(
                title: "おすすめ",
                isSelected: selectedTab == .recommended,
                isEnabled: isRecommendedEnabled
            ) {
                if isRecommendedEnabled {
                    selectedTab = .recommended
                }
            }
            
            // フォロー中タブ
            TabButton(
                title: "フォロー中",
                isSelected: selectedTab == .following,
                isEnabled: true
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
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(textColor)
                
                // Underline
                Rectangle()
                    .fill(isSelected ? Color.black : Color.clear)
                    .frame(width: 40, height: 2)
            }
        }
        .disabled(!isEnabled)
    }
    
    private var textColor: Color {
        if !isEnabled {
            return Color(hex: "CCCCCC") // 非活性
        } else if isSelected {
            return Color(hex: "000000")
        } else {
            return Color(hex: "68717B")
        }
    }
}

// MARK: - Post Grid View
private struct PostGridView: View {
    let posts: [Post]
    let users: [String: AppUser]
    let isLiked: (Post) -> Bool
    let onLikeTapped: (Post) -> Void
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(posts) { post in
                HomePostCard(
                    post: post,
                    user: users[post.userId],
                    isLiked: isLiked(post),
                    onLikeTapped: { onLikeTapped(post) }
                )
            }
        }
    }
}

// MARK: - Home Post Card
private struct HomePostCard: View {
    let post: Post
    let user: AppUser?
    let isLiked: Bool
    let onLikeTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Image - タップで投稿詳細へ
            NavigationLink(destination: PostDetailView(post: post)) {
                GeometryReader { geometry in
                    CachedImage(
                        url: post.imageURL,
                        targetSize: CGSize(width: geometry.size.width * 2, height: 360)
                    )
                    .frame(width: geometry.size.width, height: 180)
                    .clipped()
                }
                .frame(height: 180)
                .clipped()
            }
            .buttonStyle(PlainButtonStyle())
            
            // Info
            HStack(spacing: 8) {
                // Avatar & Name - タップでユーザープロフィールへ
                if let userId = user?.id {
                    NavigationLink(destination: UserProfileView(userId: userId)) {
                        HStack(spacing: 8) {
                            // Avatar
                            CachedAvatarImage(url: user?.avatarURL, size: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user?.displayName ?? "ユーザー")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Color(hex: "2D2D2D"))
                                    .lineLimit(1)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: post.weather.symbolName)
                                        .font(.system(size: 9))
                                        .foregroundColor(Color(hex: "68717B"))
                                    Text("\(post.temperature)°C")
                                        .font(.system(size: 10))
                                        .foregroundColor(Color(hex: "68717B"))
                                }
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    // ユーザー情報がない場合
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(hex: "E8EDF5"))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color(hex: "68717B"))
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("ユーザー")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color(hex: "2D2D2D"))
                                .lineLimit(1)
                            
                            HStack(spacing: 4) {
                                Image(systemName: post.weather.symbolName)
                                    .font(.system(size: 9))
                                    .foregroundColor(Color(hex: "68717B"))
                                Text("\(post.temperature)°C")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color(hex: "68717B"))
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Like Button
                Button(action: onLikeTapped) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 16))
                        .foregroundColor(isLiked ? Color(hex: "FF2539") : Color(hex: "68717B"))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(Color.white)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Post Loading View (Skeleton)
private struct PostLoadingView: View {
    var body: some View {
        PostGridSkeleton(columns: 2, rows: 3)
    }
}

// MARK: - Empty Recommended View
private struct EmptyRecommendedView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "68717B"))
            
            Text("おすすめの投稿がありません")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color(hex: "2D2D2D"))
            
            Text("他のユーザーが投稿すると\nここにおすすめが表示されます")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "68717B"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - No Following View (フォロー中のユーザーがいない)
private struct NoFollowingView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "68717B"))
            
            Text("フォロー中のユーザーがいません")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color(hex: "2D2D2D"))
            
            Text("ファッションタブでユーザーを探して\nフォローしてみましょう")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "68717B"))
                .multilineTextAlignment(.center)
            
            NavigationLink(destination: FashionView()) {
                HStack(spacing: 6) {
                    Image(systemName: "tshirt.fill")
                        .font(.system(size: 14))
                    Text("ファッションタブへ")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color(hex: "2D2D2D"))
                .cornerRadius(24)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Empty Following Posts View (フォロー中だが投稿がない)
private struct EmptyFollowingPostsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.image")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "68717B"))
            
            Text("新しい投稿がありません")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color(hex: "2D2D2D"))
            
            Text("フォロー中のユーザーが投稿すると\nここに表示されます")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "68717B"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthService())
}
