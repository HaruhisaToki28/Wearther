//
//  ProfileOutfitCard.swift
//  Wearther
//
//  Created by hato on 2025/11/07.
//

import SwiftUI

struct ProfileOutfitCard: View {
    let post: Post
    
    var body: some View {
        // 画像のみを表示するシンプルなカード
        RemotePostImage(
            urlString: post.imageURL,
            width: 115,
            height: 154
        )
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.03), radius: 18.4, x: 0, y: 13)
    }
}

private struct RemotePostImage: View {
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
        .cornerRadius(10)
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
        post: Post(
            userId: "1",
            imageURL: "https://example.com/image.jpg",
            title: "Test",
            caption: "Test caption",
            weather: .sunny,
            temperature: 20,
            location: PostLocation(name: "Tokyo"),
            userGender: "男性",
            userAge: 25,
            userHeight: 175
        )
    )
    .padding()
    .background(Color(red: 0.96, green: 0.96, blue: 0.96))
}

