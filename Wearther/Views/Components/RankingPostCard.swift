//
//  RankingPostCard.swift
//  Wearther
//
//  Created by Wearther on 2026/01/22.
//

import SwiftUI
import Kingfisher

/// ランキング投稿カード
/// Figmaデザイン: 124x166px
/// 1-3位: カラーの順位タグ（金、銀、銅）
/// いいねボタン付き
struct RankingPostCard: View {
    
    // MARK: - Properties
    
    let rankedPost: RankedPost
    let onLikeTapped: () -> Void
    
    // MARK: - Constants
    
    private let cardWidth: CGFloat = 124
    private let cardHeight: CGFloat = 166
    
    /// 順位に応じたタグの色
    private var rankColor: Color {
        switch rankedPost.rank {
        case 1:
            return Color(hex: "FFAB00") // 金
        case 2:
            return Color(hex: "848484") // 銀
        case 3:
            return Color(hex: "C06300") // 銅
        default:
            return Color.clear // 4位以降は非表示
        }
    }
    
    /// 順位タグを表示するかどうか
    private var showRankTag: Bool {
        rankedPost.rank <= 3
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // 投稿画像
            CachedImage(
                url: rankedPost.post.imageURL,
                targetSize: CGSize(width: cardWidth * 2, height: cardHeight * 2)
            )
            .frame(width: cardWidth, height: cardHeight)
            .clipped()
            .cornerRadius(10, corners: showRankTag ? [.topRight, .bottomLeft, .bottomRight] : .allCorners)
            .allowsHitTesting(false)
            
            // 順位タグ（1-3位のみ）
            if showRankTag {
                rankTag
                    .allowsHitTesting(false)
            }
            
            // いいねボタン（右下）
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    likeButton
                        .padding(8)
                }
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .contentShape(Rectangle())
        .shadow(color: .black.opacity(0.03), radius: 9.2, x: 0, y: 0)
    }
    
    // MARK: - Subviews
    
    /// 順位タグ
    private var rankTag: some View {
        ZStack {
            // タグの形状（三角形 + 長方形）
            RankTagShape()
                .fill(rankColor)
                .frame(width: 21, height: 21)
            
            // 順位の数字
            Text("\(rankedPost.rank)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .offset(x: 0, y: -2)
        }
    }
    
    /// いいねボタン
    private var likeButton: some View {
        Button(action: onLikeTapped) {
            Image(systemName: rankedPost.isLiked ? "heart.fill" : "heart.fill")
                .font(.system(size: 18))
                .foregroundColor(rankedPost.isLiked ? .red : .white)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        }
    }
}

// MARK: - Rank Tag Shape

/// 順位タグの形状（旗のような形）
struct RankTagShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // 上部の三角形
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        
        // 下部の長方形部分
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Corner Radius Extension

extension View {
    /// 特定の角だけに角丸を適用
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

/// 特定の角だけ丸める形状
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 20) {
        RankingPostCard(
            rankedPost: RankedPost(
                rank: 1,
                post: Post(
                    userId: "test",
                    imageURL: "https://example.com/image.jpg",
                    title: "テスト投稿",
                    caption: "",
                    weather: .sunny,
                    temperature: 20,
                    location: PostLocation(name: "東京"),
                    userGender: "男性",
                    userAge: 25,
                    userHeight: 170,
                    likesCount: 100
                ),
                user: nil,
                isLiked: false
            ),
            onLikeTapped: {}
        )
        
        RankingPostCard(
            rankedPost: RankedPost(
                rank: 2,
                post: Post(
                    userId: "test",
                    imageURL: "https://example.com/image.jpg",
                    title: "テスト投稿",
                    caption: "",
                    weather: .sunny,
                    temperature: 20,
                    location: PostLocation(name: "東京"),
                    userGender: "男性",
                    userAge: 25,
                    userHeight: 170,
                    likesCount: 50
                ),
                user: nil,
                isLiked: true
            ),
            onLikeTapped: {}
        )
        
        RankingPostCard(
            rankedPost: RankedPost(
                rank: 3,
                post: Post(
                    userId: "test",
                    imageURL: "https://example.com/image.jpg",
                    title: "テスト投稿",
                    caption: "",
                    weather: .sunny,
                    temperature: 20,
                    location: PostLocation(name: "東京"),
                    userGender: "男性",
                    userAge: 25,
                    userHeight: 170,
                    likesCount: 30
                ),
                user: nil,
                isLiked: false
            ),
            onLikeTapped: {}
        )
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}
