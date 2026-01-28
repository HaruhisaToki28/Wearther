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
    
    private var isButtonDisabled: Bool {
        email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading
    }
    
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
                Text("パスワード再設定")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
            }
            .frame(height: 50)
            .background(Color.white)
            
            Spacer()
                .frame(height: 40)
            
            // Description
            Text("登録したメールアドレスを入力してください。\nパスワード再設定用のリンクをお送りします。")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "666666"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 30)
            
            // Form Fields
            VStack(spacing: 15) {
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
            }
            .padding(.horizontal, 16)
            
            // Message
            if let message = message {
                Text(message)
                    .font(.system(size: 13))
                    .foregroundColor(isError ? .red : .green)
                    .padding(.top, 10)
            }
            
            // Send Button
            Button(action: {
                Task {
                    await sendResetLink()
                }
            }) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                } else {
                    Text("再設定リンクを送信")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
            }
            .background(isButtonDisabled ? Color(hex: "AAAAAA") : Color(hex: "2D2D2D"))
            .cornerRadius(39)
            .padding(.horizontal, 16)
            .padding(.top, 30)
            .disabled(isButtonDisabled)
            
            Spacer()
        }
        .background(Color.white)
        .navigationBarHidden(true)
    }
    
    private func sendResetLink() async {
        isLoading = true
        message = nil
        isError = false
        
        do {
            try await authService.sendPasswordReset(email: email)
            message = "パスワード再設定メールを送信しました。"
            isError = false
            
            // 2秒後にサインイン画面に戻る
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                dismiss()
            }
        } catch {
            message = error.localizedDescription
            isError = true
        }
        
        isLoading = false
    }
}
