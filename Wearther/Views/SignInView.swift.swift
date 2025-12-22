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
    @State private var errorMessage: String? = nil
    
    var body: some View {
        NavigationView {
            VStack {
                Text("アカウントにログイン")
                    .font(.title)
                    .padding(.bottom, 30)
                
                Group {
                    TextField("メールアドレス", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                    SecureField("パスワード", text: $password)
                        .textFieldStyle(.roundedBorder)
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.vertical, 5)
                    }

                    Button("ログイン") {
                        Task {
                            do {
                                errorMessage = nil
                                try await authService.signIn(email: email, password: password)
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                    }
                    .padding()
                    
                    NavigationLink(destination: ForgotPasswordView()) {
                        Text("パスワードを忘れた場合")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding(.bottom, 10)
                }
                .padding(.horizontal)
                
                Divider()
                
                // Google SignIn
                GoogleSignInButton {
                    Task {
                        try? await authService.signInWithGoogle()
                    }
                }
                .padding(.top, 20)
                
                NavigationLink(destination: SignUpView()) {
                    Text("新しくアカウントを作る")
                        .padding(.top, 10)
                }
                
            }
            .padding()
        }
    }
}
