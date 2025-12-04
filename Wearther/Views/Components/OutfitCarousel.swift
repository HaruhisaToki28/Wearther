//
//  OutfitCarousel.swift
//  Wearther
//
//  Created by hato on 2025/11/07.
//

import SwiftUI

struct OutfitCarousel: View {
    let recommendations: [OutfitRecommendation]
    let onLikeTapped: (OutfitRecommendation) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 18) {
                ForEach(recommendations) { recommendation in
                    OutfitCardView(
                        recommendation: recommendation,
                        onLikeTapped: { onLikeTapped(recommendation) }
                    )
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 4)
        }
    }
}

private struct OutfitCardView: View {
    let recommendation: OutfitRecommendation
    let onLikeTapped: () -> Void
    
    private let cardWidth: CGFloat = 220
    private let imageHeight: CGFloat = 250
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            RemoteOutfitImage(
                urlString: recommendation.imageURL,
                width: cardWidth - 12,
                height: imageHeight
            )
            
            HStack(alignment: .center, spacing: 10) {
                RemoteAvatarView(
                    urlString: recommendation.userAvatarURL,
                    fallbackSymbol: recommendation.userAvatarSymbol
                )
                VStack(alignment: .leading, spacing: 2) {
                    Text(recommendation.userName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("\(Int(recommendation.weatherSnapshot.temperature))°C")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                LikeButton(
                    isLiked: recommendation.isLiked,
                    action: onLikeTapped
                )
            }
        }
        .padding(20)
        .frame(width: cardWidth, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 25, x: 0, y: 15)
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
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
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
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.93, green: 0.93, blue: 0.95),
                        Color(red: 0.98, green: 0.98, blue: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.secondary)
            )
    }
}

private struct RemoteAvatarView: View {
    let urlString: String?
    let fallbackSymbol: String
    
    var body: some View {
        AsyncImage(url: imageURL, transaction: Transaction(animation: .easeInOut)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                fallback
            case .empty:
                fallback
            @unknown default:
                fallback
            }
        }
        .frame(width: 36, height: 36)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color(red: 0.48, green: 0.99, blue: 0.00), Color(red: 0.13, green: 0.99, blue: 0.00)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
        )
    }
    
    private var imageURL: URL? {
        guard let urlString, let url = URL(string: urlString) else { return nil }
        return url
    }
    
    private var fallback: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.2))
            Image(systemName: fallbackSymbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.gray)
        }
    }
}

private struct LikeButton: View {
    let isLiked: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: isLiked ? "heart.fill" : "heart")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(isLiked ? Color.red : Color.gray.opacity(0.5))
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    OutfitCarousel(
        recommendations: [
            OutfitRecommendation(
                userId: "1",
                userName: "user",
                userHeight: 175,
                weatherSnapshot: WeatherSnapshot(temperature: 19.0, condition: .partlyCloudy)
            )
        ],
        onLikeTapped: { _ in }
    )
    .padding()
    .background(Color(red: 0.96, green: 0.96, blue: 0.96))
}