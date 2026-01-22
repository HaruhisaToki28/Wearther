//
//  View+DismissKeyboard.swift
//  Wearther
//
//  Created by Wearther on 2026/01/22.
//

import SwiftUI

// MARK: - キーボードを閉じる Extension

extension View {
    /// キーボード以外をタップした際にキーボードを閉じる
    /// - Returns: キーボード閉じ機能が追加されたView
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            dismissKeyboard()
        }
    }
    
    /// キーボードを閉じる
    func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

// MARK: - キーボード閉じ用のModifier

/// 背景タップでキーボードを閉じるModifier
struct DismissKeyboardOnTapModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil,
                    from: nil,
                    for: nil
                )
            }
    }
}

extension View {
    /// 背景タップでキーボードを閉じる（NavigationLinkなどと干渉しない版）
    func dismissKeyboardOnBackground() -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil,
                    from: nil,
                    for: nil
                )
            }
        )
    }
}
