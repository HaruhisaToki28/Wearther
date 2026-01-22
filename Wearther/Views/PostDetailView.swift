//
//  PostDetailView.swift
//  Wearther
//
//  Created by Wearther on 2026/01/22.
//

import SwiftUI

/// 投稿詳細画面
/// フルスクリーンで投稿の詳細情報を表示
/// 天気/気温/場所、ユーザー情報、いいね、共有、フォロー機能を提供
struct PostDetailView: View {
    
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PostDetailViewModel
    @EnvironmentObject private var authService: AuthService
    
    /// 画像の高さ（Figmaデザイン: 526px）
    private let imageHeight: CGFloat = 526
    
    // MARK: - Initialization
    
    init(post: Post) {
        _viewModel = StateObject(wrappedValue: PostDetailViewModel(post: post))
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // 背景色
            Color(hex: "F8F8F8")
                .ignoresSafeArea()
            
            // メインコンテンツ
            ScrollView {
                VStack(spacing: 0) {
                    // 投稿画像エリア
                    imageSection
                    
                    // コンテンツエリア（ユーザー情報、タイトル、説明文）
                    contentSection
                }
            }
            .ignoresSafeArea(edges: .top)
            
            // 戻るボタン（固定位置 - SafeArea上部に配置）
            VStack {
                backButton
                Spacer()
            }
            .padding(.top, 10) // SafeArea内で上部に配置
            .padding(.leading, 20)
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadDetails(currentUserId: authService.currentUser?.id)
        }
    }
    
    // MARK: - 画像セクション
    
    /// 投稿画像と天気情報バッジを表示
    private var imageSection: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                // 投稿画像（画面幅に固定してレイアウト崩れを防止）
                AsyncImage(url: URL(string: viewModel.post.imageURL)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay {
                                ProgressView()
                            }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: imageHeight)
                            .clipped()
                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 40))
                            }
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: geometry.size.width, height: imageHeight)
                .clipped()
                
                // 天気情報バッジ
                weatherInfoBadge
                    .padding(.leading, 20)
                    .padding(.bottom, 14)
            }
        }
        .frame(height: imageHeight)
    }
    
    /// 天気/気温/場所を表示するバッジ
    private var weatherInfoBadge: some View {
        HStack(spacing: 9) {
            // 天気アイコン
            Image(systemName: viewModel.post.weather.symbolName)
                .font(.system(size: 24))
                .foregroundColor(.white)
            
            // 気温
            Text("\(viewModel.post.temperature)℃")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            // 場所
            Text(viewModel.post.location.name)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color(hex: "2D2D2D"))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: "68717B"), lineWidth: 0.5)
        )
    }
    
    // MARK: - コンテンツセクション
    
    /// ユーザー情報、タイトル、説明文を表示
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ユーザー情報行
            userInfoRow
            
            // タイトルと説明文
            VStack(alignment: .leading, spacing: 11) {
                // タイトル
                Text(viewModel.post.title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Color(hex: "2D2D2D"))
                
                // 説明文
                Text(viewModel.post.caption)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: "2D2D2D"))
                    .lineSpacing(4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 15)
        }
        .background(Color(hex: "F8F8F8"))
    }
    
    /// ユーザー情報、いいね、共有、フォローボタンを表示
    private var userInfoRow: some View {
        HStack {
            // 左側: アバターとユーザー情報（タップでユーザープロフィールへ遷移）
            NavigationLink(destination: UserProfileView(userId: viewModel.post.userId)) {
                HStack(spacing: 8) {
                    // ユーザーアバター
                    userAvatar
                    
                    // ユーザー名と日付/性別
                    VStack(alignment: .leading, spacing: 6) {
                        Text(viewModel.postUser?.displayName ?? "読み込み中...")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(hex: "2D2D2D"))
                            .lineLimit(1)
                        
                        Text(viewModel.dateAndGenderText)
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "AAAAAA"))
                            .lineLimit(1)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // 右側: アクションボタン
            HStack(spacing: 11) {
                // いいねボタン
                likeButton
                
                // 共有ボタン
                shareButton
                
                // フォローボタン（自分の投稿でない場合のみ表示）
                if !viewModel.isOwnPost {
                    followButton
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
    }
    
    /// ユーザーアバター
    private var userAvatar: some View {
        Group {
            if let avatarURL = viewModel.postUser?.avatarURL, !avatarURL.isEmpty {
                AsyncImage(url: URL(string: avatarURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        defaultAvatar
                    }
                }
            } else {
                defaultAvatar
            }
        }
        .frame(width: 36, height: 36)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color(hex: "DDE2E2"), lineWidth: 0.1)
        )
    }
    
    /// デフォルトのアバター
    private var defaultAvatar: some View {
        Circle()
            .fill(Color.gray.opacity(0.3))
            .overlay {
                Image(systemName: "person.fill")
                    .foregroundColor(.gray)
                    .font(.system(size: 16))
            }
    }
    
    /// いいねボタン
    private var likeButton: some View {
        Button {
            Task {
                await viewModel.toggleLike()
            }
        } label: {
            Image(systemName: viewModel.isLiked ? "heart.fill" : "heart")
                .font(.system(size: 20))
                .foregroundColor(viewModel.isLiked ? .red : Color(hex: "2D2D2D"))
                .frame(width: 18)
        }
    }
    
    /// 共有ボタン
    private var shareButton: some View {
        Button {
            sharePost()
        } label: {
            Image(systemName: "paperplane")
                .font(.system(size: 20))
                .foregroundColor(Color(hex: "2D2D2D"))
                .frame(width: 18)
        }
    }
    
    /// フォローボタン
    private var followButton: some View {
        Button {
            Task {
                await viewModel.toggleFollow()
            }
        } label: {
            Text(viewModel.isFollowing ? "フォロー中" : "フォローする")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(viewModel.isFollowing ? Color(hex: "2D2D2D") : .white)
                .frame(width: 96, height: 28)
                .background(viewModel.isFollowing ? Color.white : Color(hex: "2D2D2D"))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(hex: "2D2D2D"), lineWidth: viewModel.isFollowing ? 1 : 0)
                )
        }
    }
    
    // MARK: - 戻るボタン
    
    /// 左上の戻るボタン
    private var backButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 20))
                .foregroundColor(Color(hex: "2D2D2D").opacity(0.8))
                .frame(width: 40, height: 40)
                .background(Color.white.opacity(0.5))
                .clipShape(Circle())
        }
    }
    
    // MARK: - Actions
    
    /// 投稿を共有
    private func sharePost() {
        // 共有するコンテンツを準備
        let shareText = "\(viewModel.post.title)\n\n\(viewModel.post.caption)"
        var shareItems: [Any] = [shareText]
        
        // 画像URLも共有（オプション）
        if let url = URL(string: viewModel.post.imageURL) {
            shareItems.append(url)
        }
        
        // 共有シートを表示
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }
        
        let activityViewController = UIActivityViewController(
            activityItems: shareItems,
            applicationActivities: nil
        )
        
        // iPadの場合はポップオーバーで表示
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = window
            popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        rootViewController.present(activityViewController, animated: true)
    }
}

// MARK: - Preview

#Preview {
    PostDetailView(
        post: Post(
            id: "test",
            userId: "testUser",
            imageURL: "https://example.com/image.jpg",
            title: "今日のコーデ",
            caption: "説明文説明文説明文説明文説明文説明文説明文説明文説明文\n説明文説明文説明文説明文説明文説明文",
            weather: .sunny,
            temperature: 10,
            location: PostLocation(name: "東京"),
            userGender: "男性",
            userAge: 25,
            userHeight: 170,
            likesCount: 100,
            createdAt: Date()
        )
    )
    .environmentObject(AuthService())
}
