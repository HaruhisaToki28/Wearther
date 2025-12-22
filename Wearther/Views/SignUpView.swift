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
    @State private var username = ""
    @State private var displayName = ""
    
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("新規アカウント作成")
                .font(.largeTitle)
                .bold()
            
            VStack(spacing: 15) {
                
                TextField("ユーザーID（英数字のみ）", text: $username)
                    .autocapitalization(.none)
                    .textFieldStyle(.roundedBorder)
                
                TextField("表示名", text: $displayName)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                
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
                try await authService.signUp(email: email, password: password, username: username.lowercased(), displayName: displayName)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
