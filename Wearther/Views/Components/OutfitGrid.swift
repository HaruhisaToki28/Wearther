//
//  OutfitGrid.swift
//  Wearther
//
//  Created by hato on 2025/11/07.
//

import SwiftUI

struct OutfitGrid: View {
    let recommendations: [OutfitRecommendation]
    let onLikeTapped: (OutfitRecommendation) -> Void
    let onLoadMore: () -> Void
    
    // 3列グリッドの設定
    private let columns = [
        GridItem(.flexible(), spacing: 5),
        GridItem(.flexible(), spacing: 5),
        GridItem(.flexible(), spacing: 5)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 5) {
            ForEach(recommendations) { recommendation in
                OutfitCard(
                    recommendation: recommendation,
                    onLikeTapped: { onLikeTapped(recommendation) }
                )
                .onAppear {
                    if recommendation.id == recommendations.last?.id {
                        onLoadMore()
                    }
                }
            }
        }
    }
}

#Preview {
    OutfitGrid(
        recommendations: [
            OutfitRecommendation(
                userId: "1",
                userName: "蘭丸",
                userHeight: 175,
                weatherSnapshot: WeatherSnapshot(temperature: 20.0, condition: .sunny),
                likes: 10,
                isLiked: false
            ),
            OutfitRecommendation(
                userId: "2",
                userName: "太郎",
                userHeight: 170,
                weatherSnapshot: WeatherSnapshot(temperature: 18.0, condition: .cloudy),
                likes: 5,
                isLiked: true
            ),
            OutfitRecommendation(
                userId: "3",
                userName: "花子",
                userHeight: 160,
                weatherSnapshot: WeatherSnapshot(temperature: 22.0, condition: .sunny),
                likes: 15,
                isLiked: false
            ),
            OutfitRecommendation(
                userId: "4",
                userName: "次郎",
                userHeight: 180,
                weatherSnapshot: WeatherSnapshot(temperature: 15.0, condition: .rainy),
                likes: 2,
                isLiked: false
            )
        ],
        onLikeTapped: { _ in },
        onLoadMore: {}
    )
    .padding()
    .background(Color(red: 0.96, green: 0.96, blue: 0.96))
}

