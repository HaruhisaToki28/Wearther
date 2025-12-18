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
    @State private var isShowingSignUp = false
    
    var body: some View {
        VStack {
            Text("アカウントにログイン")
                .font(.title)
                .padding(.bottom, 30)

            Group {
                TextField("メールアドレス", text: $email)
                    .textFieldStyle(.roundedBorder)
                SecureField("パスワード", text: $password)
                    .textFieldStyle(.roundedBorder)
                
                Button("ログイン") {
                    Task {
                        try? await authService.signIn(email: email, password: password)
                    }
                }
                .padding()
            }
            .padding(.horizontal)
            
            Divider()
            
            //Google SingIn
            GoogleSignInButton {
                Task {
                    try? await authService.signInWithGoogle()
                }
            }
            
            .padding(.top, 20)
        }
        .padding()
        
        //SingUp への導線
        Button("新しくアカウントを作る") {
            isShowingSignUp = true
        }
        
        .padding(.top, 10)
        .sheet(isPresented: $isShowingSignUp) {
            SignUpView()
        }
    }
}
