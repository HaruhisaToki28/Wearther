//
//  AuthService.swift
//  Wearther
//
//  Created by 阿久津咲千 on 2025/12/17.
//

import Foundation
import FirebaseAuth
import Combine
import GoogleSignIn

class AuthService: ObservableObject {
    
    @Published var user: User? = nil
    @Published var isAuthenticated: Bool = false

    init() {
        Auth.auth().addStateDidChangeListener { auth, user in
            self.user = user
            self.isAuthenticated = (user != nil)
        }
    }
    
    //Email LogIn
    func signIn(email: String, password: String) async throws {
        _ = try await Auth.auth().signIn(withEmail: email, password: password)
    }
    
    //Email SignUp
    func singUp(email: String, password: String) async throws {
        _ = try await Auth.auth().createUser(withEmail: email, password: password)
    }

    //Google LogIn
    func signInWithGoogle() async throws {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            throw NSError(domain: "AuthError", code: 0)
        }

        guard let rootViewController = scene.windows
            .first(where: { $0.isKeyWindow })?
            .rootViewController else {
            throw NSError(domain: "AuthError", code: 0)
        }

        let result = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: rootViewController
        )

        guard
            let idToken = result.user.idToken?.tokenString
        else {
            throw NSError(domain: "AuthError", code: 0)
        }

        let accessToken = result.user.accessToken.tokenString

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: accessToken
        )

        _ = try await Auth.auth().signIn(with: credential)
    }

    
    func signOut() throws {
        try Auth.auth().signOut()
    }
}
