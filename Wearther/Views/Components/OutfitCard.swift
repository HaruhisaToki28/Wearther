//
//  OutfitCard.swift
//  Wearther
//
//  Created by hato on 2025/11/07.
//

import SwiftUI

struct OutfitCard: View {
    let recommendation: OutfitRecommendation
    let onLikeTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // ファッションの画像
            RemoteOutfitImage(
                urlString: recommendation.imageURL,
                width: 115,
                height: 154
            )
            
            HStack(spacing: 5) {
                // ユーザーアイコン
                RemoteAvatarView(
                    urlString: recommendation.userAvatarURL,
                    fallbackSymbol: recommendation.userAvatarSymbol
                )
                
                VStack(alignment: .leading, spacing: 1) {
                    // ユーザー名
                    Text(recommendation.userName)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(red: 0.176, green: 0.176, blue: 0.176)) // #2D2D2D
                        .lineLimit(1)
                        .frame(maxWidth: 90, alignment: .leading) // 約5文字強が表示されるように幅を拡大
                    
                    // 気温
                    Text("\(Int(recommendation.weatherSnapshot.temperature))°C")
                        .font(.system(size: 10))
                        .foregroundColor(Color(red: 0.667, green: 0.667, blue: 0.667)) // #AAAAAA (Figmaに合わせて調整)
                }
                
                Spacer()
                
                // いいね用のハート
                Button(action: onLikeTapped) {
                    Image(systemName: recommendation.isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 15))
                        .foregroundColor(recommendation.isLiked ? Color.red : Color(red: 0.835, green: 0.835, blue: 0.835)) // #D5D5D5
                }
            }
            .padding(9)
        }
        .frame(width: 115)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.03), radius: 18.4, x: 0, y: 13)
    }
}

private struct RemoteOutfitImage: View {
    let urlString: String?
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        AsyncImage(url: imageURL, transaction: Transaction(animation: .spring())) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipped()
            case .failure:
                placeholder
            case .empty:
                placeholder
                    .overlay(ProgressView().tint(.secondary))
            @unknown default:
                placeholder
            }
        }
        .frame(width: width, height: height)
    }
    
    private var imageURL: URL? {
        guard let urlString, let url = URL(string: urlString) else { return nil }
        return url
    }
    
    private var placeholder: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
            )
    }
}

private struct RemoteAvatarView: View {
    let urlString: String?
    let fallbackSymbol: String
    
    var body: some View {
        AsyncImage(url: imageURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure, .empty:
                fallback
            @unknown default:
                fallback
            }
        }
        .frame(width: 18, height: 18)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color(red: 0.867, green: 0.886, blue: 0.886), lineWidth: 0.1) // #DDE2E2
        )
    }
    
    private var imageURL: URL? {
        guard let urlString, let url = URL(string: urlString) else { return nil }
        return url
    }
    
    private var fallback: some View {
        Circle()
            .fill(Color.gray.opacity(0.2))
            .overlay(
                Image(systemName: fallbackSymbol)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            )
    }
}

#Preview {
    OutfitCard(
        recommendation: OutfitRecommendation(
            userId: "1",
            userName: "user",
            userHeight: 175,
            weatherSnapshot: WeatherSnapshot(temperature: 20.0, condition: .sunny),
            likes: 10,
            isLiked: false
        ),
        onLikeTapped: {}
    )
    .padding()
    .background(Color(red: 0.96, green: 0.96, blue: 0.96))
}

