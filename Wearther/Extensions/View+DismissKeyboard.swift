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
            hideKeyboard()
        }
    }
    
    /// キーボードを閉じる
    func dismissKeyboard() {
        hideKeyboard()
    }
    
    /// キーボードを閉じる（内部実装）
    private func hideKeyboard() {
        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return
        }
        window.endEditing(true)
    }
}

// MARK: - キーボード閉じ用のModifier

/// 背景タップでキーボードを閉じるModifier
struct DismissKeyboardOnTapModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
    }
    
    private func hideKeyboard() {
        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return
        }
        window.endEditing(true)
    }
}

extension View {
    /// 背景タップでキーボードを閉じる（NavigationLinkなどと干渉しない版）
    func dismissKeyboardOnBackground() -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded {
                guard let windowScene = UIApplication.shared.connectedScenes
                    .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
                      let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
                    return
                }
                window.endEditing(true)
            }
        )
    }
}
