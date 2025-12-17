//
//  ContentView.swift
//  Wearther
//
//  Created by 阿久津咲千 on 2025/12/17.
//
import SwiftUI

struct ContentView: View {
    @StateObject var authService = AuthService()
    
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
                SignInView(authService: authService)
            }
        }
        .environmentObject(authService)
    }
}

struct SignInView: View {
    @ObservedObject var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        VStack {
            TextField("メールアドレス", text: $email)
            SecureField("パスワード", text: $password)
            
            Button("サインイン") {
                Task {
                    try? await authService.signIn(email: email, password: password)
                }
            }
            Button("Googleでサインイン") {
                Task {
                    try? await authService.signInWithGoogle()
                }
            }
        }
    }
}
