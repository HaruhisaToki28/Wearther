//
//  AuthService.swift
//  Wearther
//
//  Created by 阿久津咲千 on 2025/12/17.
//

import Foundation
import FirebaseAuth
import Combine

class AuthService: ObservableObject {
    
    @Published var user: User? = nil
    @Published var isAuthenticated: Bool = false

    init() {
        Auth.auth().addStateDidChangeListener { auth, user in
            self.user = user
            self.isAuthenticated = (user != nil)
        }
    }
    
    func signIn(email: String, password: String) async throws {
        _ = try await Auth.auth().signIn(withEmail: email, password: password)
    }


    func signInWithGoogle() async throws {
        // 認証フローを開始 (外部ライブラリの処理が必要)
        // ...
        
        // 認証トークンを取得した後、Firebaseに連携する
        // let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        // _ = try await Auth.auth().signIn(with: credential)
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
}
