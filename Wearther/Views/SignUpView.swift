//
//  SignUpView.swift
//  Wearther
//
//  Created by 阿久津咲千 on 2025/12/18.
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("新規アカウント作成")
                .font(.largeTitle)
                .bold()
            
            VStack(spacing: 15) {
                TextField("メールアドレス", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                
                SecureField("パスワード", text: $password)
                    .textFieldStyle(.roundedBorder)
                
                SecureField("パスワード（確認用）", text: $confirmPassword)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.horizontal)
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: {
                signUp()
            }) {
                Text("登録する")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Button("キャンセル") {
                dismiss()
            }
        }
    }
    
    func signUp() {
        if password != confirmPassword {
            errorMessage = "パスワードが一致しません"
            return
        }
        
        Task {
            do {
                try await authService.singUp(email: email, password: password)
                dismiss()
            } catch {
                errorMessage = "エラー: \(error.localizedDescription)"
            }
        }
    }
}
