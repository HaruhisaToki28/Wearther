//
//  SettingsView.swift
//  Wearther
//
//  Created by 阿久津咲千 on 2025/12/18.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss // 戻るボタン用
    
    var body: some View {
        List {
            Section(header: Text("アカウント")) {
                Button(action: {
                    try? authService.signOut()
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("ログアウト")
                    }
                    .foregroundColor(.red)
                }
            }
            
            Section(header: Text("アプリについて")) {
                Text("バージョン 1.0.0")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
    }
}
