//
//  ProfileOutfitCard.swift
//  Wearther
//
//  Created by hato on 2025/11/07.
//

import SwiftUI

struct ProfileOutfitCard: View {
    let recommendation: OutfitRecommendation
    
    var body: some View {
        // 画像のみを表示するシンプルなカード
        RemoteOutfitImage(
            urlString: recommendation.imageURL,
            width: 115,
            height: 193 // 元のカードの高さ(154 + padding + footer)に合わせて調整、または画像アスペクト比に応じて設定
        )
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

#Preview {
    ProfileOutfitCard(
        recommendation: OutfitRecommendation(
            userId: "1",
            userName: "user",
            userHeight: 175,
            weatherSnapshot: WeatherSnapshot(temperature: 20.0, condition: .sunny),
            likes: 10,
            isLiked: false
        )
    )
    .padding()
    .background(Color(red: 0.96, green: 0.96, blue: 0.96))
}

