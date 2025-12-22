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
        VStack(spacing: 0) {
            // Custom Navigation Bar
            ZStack {
                // Back Button
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 25))
                            .foregroundColor(.black)
                    }
                    .padding(.leading, 24)
                    
                    Spacer()
                }
                
                // Title
                Text("新規作成")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
            }
            .frame(height: 50)
            .background(Color.white)
            
            Spacer()
                .frame(height: 38)
            
            // Form Fields
            VStack(spacing: 15) {
                // Username Field
                TextField("ユーザーID（英数字のみ）", text: $username)
                    .font(.system(size: 15, weight: .light))
                    .padding(.horizontal, 20)
                    .frame(height: 50)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color(hex: "2D2D2D"), lineWidth: 1)
                    )
                    .autocapitalization(.none)
                
                // Display Name Field
                TextField("表示名", text: $displayName)
                    .font(.system(size: 15, weight: .light))
                    .padding(.horizontal, 20)
                    .frame(height: 50)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color(hex: "2D2D2D"), lineWidth: 1)
                    )
                    .autocapitalization(.none)
                
                // Email Field
                TextField("メールアドレス", text: $email)
                    .font(.system(size: 15, weight: .light))
                    .padding(.horizontal, 20)
                    .frame(height: 50)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color(hex: "2D2D2D"), lineWidth: 1)
                    )
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                // Password Field
                SecureField("パスワード", text: $password)
                    .font(.system(size: 15, weight: .light))
                    .padding(.horizontal, 20)
                    .frame(height: 50)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color(hex: "2D2D2D"), lineWidth: 1)
                    )
                
                // Confirm Password Field
                SecureField("パスワードを確認", text: $confirmPassword)
                    .font(.system(size: 15, weight: .light))
                    .padding(.horizontal, 20)
                    .frame(height: 50)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color(hex: "2D2D2D"), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 16)
            
            // Error Message
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.system(size: 13))
                    .padding(.top, 10)
            }
            
            // Register Button
            Button(action: {
                signUp()
            }) {
                Text("登録")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(hex: "2D2D2D"))
                    .cornerRadius(39)
            }
            .padding(.horizontal, 16)
            .padding(.top, 30)
            
            // Already have an account link
            Button(action: {
                dismiss()
            }) {
                Text("アカウントをお持ちの場合")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "2D2D2D"))
            }
            .padding(.top, 15)
            
            Spacer()
        }
        .background(Color.white)
        .navigationBarHidden(true)
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
