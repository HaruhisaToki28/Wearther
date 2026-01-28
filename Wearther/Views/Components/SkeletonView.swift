//
//  SkeletonView.swift
//  Wearther
//
//  Created by Wearther on 2026/01/23.
//

import SwiftUI

// MARK: - Skeleton Modifier

/// スケルトン表示用のViewModifier
struct SkeletonModifier: ViewModifier {
    let isLoading: Bool
    let shape: SkeletonShape
    
    func body(content: Content) -> some View {
        if isLoading {
            content
                .hidden()
                .overlay(
                    SkeletonShape.view(for: shape)
                        .shimmer()
                )
        } else {
            content
        }
    }
}

// MARK: - Skeleton Shapes

enum SkeletonShape {
    case rectangle
    case roundedRectangle(cornerRadius: CGFloat)
    case circle
    case capsule
    
    @ViewBuilder
    static func view(for shape: SkeletonShape) -> some View {
        switch shape {
        case .rectangle:
            Rectangle()
                .fill(Color(hex: "E8EDF5"))
        case .roundedRectangle(let cornerRadius):
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(hex: "E8EDF5"))
        case .circle:
            Circle()
                .fill(Color(hex: "E8EDF5"))
        case .capsule:
            Capsule()
                .fill(Color(hex: "E8EDF5"))
        }
    }
}

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            Color.white.opacity(0.4),
                            Color.clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                }
            )
            .clipped()
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.2)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

// MARK: - View Extensions

extension View {
    /// スケルトン表示を適用
    func skeleton(
        isLoading: Bool,
        shape: SkeletonShape = .roundedRectangle(cornerRadius: 8)
    ) -> some View {
        modifier(SkeletonModifier(isLoading: isLoading, shape: shape))
    }
    
    /// シマーエフェクトを適用
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Skeleton Components

/// 投稿カード用スケルトン
struct PostCardSkeleton: View {
    var body: some View {
        VStack(spacing: 0) {
            // 画像部分
            Rectangle()
                .fill(Color(hex: "E8EDF5"))
                .frame(height: 180)
                .shimmer()
            
            // Info部分
            HStack(spacing: 8) {
                // アバター
                Circle()
                    .fill(Color(hex: "E8EDF5"))
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    // ユーザー名
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "E8EDF5"))
                        .frame(width: 60, height: 12)
                    
                    // 温度
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "E8EDF5"))
                        .frame(width: 40, height: 10)
                }
                
                Spacer()
                
                // いいねボタン
                Circle()
                    .fill(Color(hex: "E8EDF5"))
                    .frame(width: 20, height: 20)
            }
            .padding(10)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

/// 小さい投稿カード用スケルトン（検索結果など）
struct SmallPostCardSkeleton: View {
    var cardWidth: CGFloat = 115
    var imageHeight: CGFloat = 154
    
    var body: some View {
        VStack(spacing: 0) {
            // 画像部分
            Rectangle()
                .fill(Color(hex: "E8EDF5"))
                .frame(width: cardWidth, height: imageHeight)
                .shimmer()
            
            // Info部分
            HStack(spacing: 5) {
                Circle()
                    .fill(Color(hex: "E8EDF5"))
                    .frame(width: 18, height: 18)
                
                VStack(alignment: .leading, spacing: 3) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: "E8EDF5"))
                        .frame(width: 40, height: 10)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: "E8EDF5"))
                        .frame(width: 30, height: 8)
                }
                
                Spacer()
            }
            .padding(9)
        }
        .frame(width: cardWidth)
        .background(Color.white)
        .cornerRadius(10)
    }
}

/// ユーザー行スケルトン（検索結果など）
struct UserRowSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            // アバター
            Circle()
                .fill(Color(hex: "E8EDF5"))
                .frame(width: 35, height: 35)
                .shimmer()
            
            // ユーザー情報
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "E8EDF5"))
                    .frame(width: 80, height: 12)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "E8EDF5"))
                    .frame(width: 60, height: 10)
            }
            
            Spacer()
            
            // フォローボタン
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "E8EDF5"))
                .frame(width: 80, height: 32)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
}

/// プロフィールヘッダースケルトン
struct ProfileHeaderSkeleton: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center, spacing: 16) {
                // アバター
                Circle()
                    .fill(Color(hex: "E8EDF5"))
                    .frame(width: 86, height: 86)
                    .shimmer()
                
                // Info
                VStack(alignment: .leading, spacing: 8) {
                    // 名前
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "E8EDF5"))
                        .frame(width: 100, height: 18)
                    
                    // Stats
                    HStack(spacing: 10) {
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: "E8EDF5"))
                                .frame(width: 50, height: 12)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            
            // Bio
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "E8EDF5"))
                    .frame(height: 11)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "E8EDF5"))
                    .frame(width: 200, height: 11)
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 15)
    }
}

/// 天気カードスケルトン
struct WeatherCardSkeleton: View {
    var body: some View {
        HStack(spacing: 16) {
            // 天気アイコン
            Circle()
                .fill(Color(hex: "E8EDF5"))
                .frame(width: 50, height: 50)
                .shimmer()
            
            VStack(alignment: .leading, spacing: 8) {
                // 日付
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "E8EDF5"))
                    .frame(width: 80, height: 14)
                
                // 温度
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "E8EDF5"))
                    .frame(width: 60, height: 24)
            }
            
            Spacer()
            
            // 服装画像
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "E8EDF5"))
                .frame(width: 60, height: 80)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
    }
}

// MARK: - Skeleton Grid

/// 投稿グリッドスケルトン
struct PostGridSkeleton: View {
    let columns: Int
    let rows: Int
    
    init(columns: Int = 2, rows: Int = 3) {
        self.columns = columns
        self.rows = rows
    }
    
    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: columns),
            spacing: 10
        ) {
            ForEach(0..<(columns * rows), id: \.self) { _ in
                PostCardSkeleton()
            }
        }
    }
}

/// 小さい投稿グリッドスケルトン
struct SmallPostGridSkeleton: View {
    let columns: Int
    let rows: Int
    
    init(columns: Int = 3, rows: Int = 2) {
        self.columns = columns
        self.rows = rows
    }
    
    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: columns),
            spacing: 5
        ) {
            ForEach(0..<(columns * rows), id: \.self) { _ in
                SmallPostCardSkeleton()
            }
        }
    }
}

// MARK: - Preview

#Preview("Post Card Skeleton") {
    VStack(spacing: 20) {
        PostCardSkeleton()
            .frame(width: 180)
        
        SmallPostCardSkeleton()
    }
    .padding()
    .background(Color(hex: "F8F8F8"))
}

#Preview("User Row Skeleton") {
    VStack(spacing: 0) {
        UserRowSkeleton()
        Divider()
        UserRowSkeleton()
        Divider()
        UserRowSkeleton()
    }
    .background(Color.white)
}

#Preview("Profile Header Skeleton") {
    ProfileHeaderSkeleton()
        .background(Color.white)
}

#Preview("Post Grid Skeleton") {
    ScrollView {
        PostGridSkeleton(columns: 2, rows: 3)
            .padding()
    }
    .background(Color(hex: "F8F8F8"))
}
