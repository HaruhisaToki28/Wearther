//
//  ContentView.swift
//  Wearther
//
//  Created by 阿久津咲千 on 2025/12/17.
//
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                VStack {
                    Text("ログイン成功！")
                    Button("ログアウト") {
                        try? authService.signOut()
                    }
                }
            } else {
                SignInView()
            }
        }
    }
}
