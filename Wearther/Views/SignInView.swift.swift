//
//  SignInView.swift.swift
//  Wearther
//
//  Created by 阿久津咲千 on 2025/12/18.
//

import Foundation
import SwiftUI
import GoogleSignInSwift 

struct SignInView: View {
    @EnvironmentObject var authService: AuthService
    
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 60)
                
                // App Title
                Text("Wearther")
                    .font(.custom("Sinhala MN", size: 40))
                    .tracking(-1.2) // -8% letter spacing
                    .foregroundColor(.black)
                    .padding(.bottom, 50)
                
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
                }
                .padding(.horizontal, 16)
                
                // Login Button
                Button(action: {
                    Task {
                        try? await authService.signIn(email: email, password: password)
                    }
                }) {
                    Text("ログイン")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(hex: "2D2D2D"))
                        .cornerRadius(39)
                }
                .padding(.horizontal, 16)
                .padding(.top, 30)
                
                // Forgot Password Link
                Button(action: {
                    // 機能未実装 - 見た目のみ
                }) {
                    Text("パスワードを忘れた場合")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(hex: "2D2D2D"))
                }
                .padding(.top, 15)
                
                Spacer()
                
                // Bottom Buttons
                VStack(spacing: 15) {
                    // Google Sign In Button
                    Button(action: {
                        Task {
                            try? await authService.signInWithGoogle()
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image("GoogleLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                            
                            Text("Googleで続ける")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Color(hex: "2D2D2D"))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 39)
                                .stroke(Color(hex: "2D2D2D"), lineWidth: 1)
                        )
                    }
                    
                    // Create New Account Button
                    NavigationLink(destination: SignUpView()) {
                        Text("新しいアカウント作成")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(hex: "2D2D2D"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 39)
                                    .stroke(Color(hex: "2D2D2D"), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 50)
            }
            .background(Color.white)
            .navigationBarHidden(true)
        }
    }
}

// Color extension for hex support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}


