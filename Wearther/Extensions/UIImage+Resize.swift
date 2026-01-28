//
//  UIImage+Resize.swift
//  Wearther
//
//  Created by Wearther on 2026/01/23.
//

import UIKit

extension UIImage {
    
    // MARK: - 投稿画像用リサイズ
    
    /// 投稿用に画像をリサイズ（長辺1200px以下）
    /// - Parameters:
    ///   - maxDimension: 長辺の最大サイズ（デフォルト: 1200px）
    ///   - compressionQuality: JPEG圧縮品質（デフォルト: 0.8）
    /// - Returns: リサイズ・圧縮された画像データ
    func resizedForPost(maxDimension: CGFloat = 1200, compressionQuality: CGFloat = 0.8) -> Data? {
        let resizedImage = resized(maxDimension: maxDimension)
        return resizedImage.jpegData(compressionQuality: compressionQuality)
    }
    
    // MARK: - アバター画像用リサイズ
    
    /// アバター用に画像をリサイズ（正方形にクロップ、指定サイズ）
    /// - Parameters:
    ///   - size: 出力サイズ（デフォルト: 400px）
    ///   - compressionQuality: JPEG圧縮品質（デフォルト: 0.8）
    /// - Returns: リサイズ・圧縮された画像データ
    func resizedForAvatar(size: CGFloat = 400, compressionQuality: CGFloat = 0.8) -> Data? {
        let croppedImage = croppedToSquare()
        let resizedImage = croppedImage.resized(maxDimension: size)
        return resizedImage.jpegData(compressionQuality: compressionQuality)
    }
    
    // MARK: - Private Helpers
    
    /// 画像を指定された最大サイズにリサイズ
    private func resized(maxDimension: CGFloat) -> UIImage {
        let originalSize = size
        
        // リサイズが不要な場合はそのまま返す
        guard originalSize.width > maxDimension || originalSize.height > maxDimension else {
            return self
        }
        
        let aspectRatio = originalSize.width / originalSize.height
        var newSize: CGSize
        
        if originalSize.width > originalSize.height {
            // 横長の画像
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            // 縦長または正方形の画像
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    /// 画像を正方形にクロップ（中央から切り出し）
    private func croppedToSquare() -> UIImage {
        let originalSize = size
        let minDimension = min(originalSize.width, originalSize.height)
        
        // 既に正方形の場合はそのまま返す
        guard originalSize.width != originalSize.height else {
            return self
        }
        
        let cropRect: CGRect
        if originalSize.width > originalSize.height {
            // 横長 → 中央から正方形を切り出し
            let x = (originalSize.width - minDimension) / 2
            cropRect = CGRect(x: x, y: 0, width: minDimension, height: minDimension)
        } else {
            // 縦長 → 中央から正方形を切り出し
            let y = (originalSize.height - minDimension) / 2
            cropRect = CGRect(x: 0, y: y, width: minDimension, height: minDimension)
        }
        
        // CGImageを使用してクロップ
        guard let cgImage = cgImage,
              let croppedCGImage = cgImage.cropping(to: cropRect) else {
            return self
        }
        
        return UIImage(cgImage: croppedCGImage, scale: scale, orientation: imageOrientation)
    }
    
    // MARK: - サイズ情報
    
    /// 画像のファイルサイズを取得（KB単位）
    var fileSizeInKB: Int {
        guard let data = jpegData(compressionQuality: 1.0) else { return 0 }
        return data.count / 1024
    }
    
    /// 画像の解像度を文字列で取得
    var resolutionString: String {
        "\(Int(size.width)) x \(Int(size.height))"
    }
}
