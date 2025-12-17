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
    @EnvironmentObject var authService: AuthService // 認証サービスを受け取る
    
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        VStack {
            Text("アカウントにサインイン")
                .font(.title)
                .padding(.bottom, 30)

            Group {
                TextField("メールアドレス", text: $email)
                    .textFieldStyle(.roundedBorder)
                SecureField("パスワード", text: $password)
                    .textFieldStyle(.roundedBorder)
                
                Button("サインイン") {
                    Task {
                        try? await authService.signIn(email: email, password: password)
                    }
                }
                .padding()
            }
            .padding(.horizontal)
            
            Divider()
            
            GoogleSignInButton {
                Task {
                    try? await authService.signInWithGoogle()
                }
            }
            
            .padding(.top, 20)
        }
        .padding()
    }
}
