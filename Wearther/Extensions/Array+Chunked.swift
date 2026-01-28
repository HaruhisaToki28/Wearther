//
//  Array+Chunked.swift
//  Wearther
//
//  Created by Wearther on 2026/01/23.
//

import Foundation

extension Array {
    /// 配列を指定サイズのチャンクに分割
    /// - Parameter size: チャンクサイズ（1以上）
    /// - Returns: 分割された配列の配列
    ///
    /// 使用例:
    /// ```
    /// let array = [1, 2, 3, 4, 5, 6, 7]
    /// let chunks = array.chunked(into: 3)
    /// // [[1, 2, 3], [4, 5, 6], [7]]
    /// ```
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
