//
//  ForgotPasswordView.swift
//  Wearther
//
//  Created by Gemini on 2025/12/22.
//

import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var message: String?
    @State private var isError = false
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            Text("パスワードを再設定")
                .font(.title)
                .padding(.bottom, 30)
            
            Text("登録したメールアドレスを入力してください。パスワード再設定用のリンクをお送りします。")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)
            
            TextField("メールアドレス", text: $email)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .padding(.horizontal)
            
            if let message = message {
                Text(message)
                    .foregroundColor(isError ? .red : .green)
                    .font(.caption)
                    .padding(.top, 5)
            }
            
            Button(action: {
                Task {
                    await sendResetLink()
                }
            }) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("再設定リンクを送信")
                }
            }
            .padding()
            .disabled(email.isEmpty || isLoading)
            
            Spacer()
        }
        .padding()
    }
    
    private func sendResetLink() async {
        isLoading = true
        message = nil
        isError = false
        
        do {
            try await authService.sendPasswordReset(email: email)
            message = "パスワード再設定メールを送信しました。"
            isError = false
        } catch {
            message = error.localizedDescription
            isError = true
        }
        
        isLoading = false
    }
}
