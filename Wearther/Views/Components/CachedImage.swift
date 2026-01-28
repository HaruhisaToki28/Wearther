//
//  CachedImage.swift
//  Wearther
//
//  Created by Wearther on 2026/01/23.
//

import SwiftUI
import Kingfisher

/// キャッシュ付き画像コンポーネント
/// Kingfisherを使用してメモリ/ディスクキャッシュを自動管理
struct CachedImage: View {
    let url: String?
    var targetSize: CGSize? = nil
    var contentMode: SwiftUI.ContentMode = .fill
    
    var body: some View {
        if let urlString = url, let imageURL = URL(string: urlString) {
            KFImage(imageURL)
                .placeholder {
                    Rectangle()
                        .fill(Color(hex: "E8EDF5"))
                        .overlay(
                            ProgressView()
                                .tint(Color(hex: "68717B"))
                        )
                }
                .onFailure { _ in }
                .resizable()
                .downsampling(size: targetSize)
                .cacheOriginalImage()
                .fade(duration: 0.2)
                .aspectRatio(contentMode: contentMode)
        } else {
            Rectangle()
                .fill(Color(hex: "E8EDF5"))
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "68717B").opacity(0.5))
                )
        }
    }
}

/// キャッシュ付きアバター画像コンポーネント
/// 丸型のプロフィール画像用
struct CachedAvatarImage: View {
    let url: String?
    var size: CGFloat = 40
    
    var body: some View {
        if let urlString = url, !urlString.isEmpty, let imageURL = URL(string: urlString) {
            KFImage(imageURL)
                .placeholder {
                    Circle()
                        .fill(Color(hex: "E8EDF5"))
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: size * 0.4))
                                .foregroundColor(Color(hex: "68717B"))
                        )
                }
                .onFailure { _ in }
                .resizable()
                .downsampling(size: CGSize(width: size * 2, height: size * 2))
                .cacheOriginalImage()
                .fade(duration: 0.2)
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(Color(hex: "E8EDF5"))
                .frame(width: size, height: size)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.4))
                        .foregroundColor(Color(hex: "68717B"))
                )
        }
    }
}

// MARK: - Kingfisher Configuration

/// Kingfisherのキャッシュ設定を行うユーティリティ
enum ImageCacheConfig {
    /// キャッシュを初期設定
    static func configure() {
        // メモリキャッシュの上限: 300MB
        ImageCache.default.memoryStorage.config.totalCostLimit = 300 * 1024 * 1024
        
        // ディスクキャッシュの上限: 1GB
        ImageCache.default.diskStorage.config.sizeLimit = 1024 * 1024 * 1024
        
        // ディスクキャッシュの有効期限: 7日
        ImageCache.default.diskStorage.config.expiration = .days(7)
        
        // メモリキャッシュの有効期限: 5分
        ImageCache.default.memoryStorage.config.expiration = .seconds(300)
    }
    
    /// キャッシュをクリア
    static func clearCache() {
        ImageCache.default.clearMemoryCache()
        ImageCache.default.clearDiskCache()
    }
    
    /// キャッシュサイズを取得
    static func getCacheSize(completion: @escaping (UInt) -> Void) {
        ImageCache.default.calculateDiskStorageSize { result in
            switch result {
            case .success(let size):
                completion(size)
            case .failure:
                completion(0)
            }
        }
    }
}

// MARK: - Kingfisher Extension for Downsampling

extension KFImage {
    /// 表示サイズに合わせてダウンサンプリング
    func downsampling(size: CGSize?) -> KFImage {
        if let size = size {
            return self.setProcessor(
                DownsamplingImageProcessor(size: size)
            )
        }
        return self
    }
}

#Preview {
    VStack(spacing: 20) {
        CachedImage(
            url: "https://images.unsplash.com/photo-1524504388940-b1c1722653e1",
            targetSize: CGSize(width: 300, height: 300)
        )
        .frame(width: 150, height: 150)
        .clipped()
        
        CachedAvatarImage(
            url: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e",
            size: 60
        )
    }
}
