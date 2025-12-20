//
//  AuthService.swift
//  Wearther
//
//  Created by 阿久津咲千 on 2025/12/17.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import Combine

@MainActor
class AuthService: ObservableObject {

    @Published var user: User? = nil
    @Published var isAuthenticated: Bool = false

    private let db = Firestore.firestore()

    init() {
        Auth.auth().addStateDidChangeListener { _, user in
            self.user = user
            self.isAuthenticated = (user != nil)
        }
    }

    // MARK: - Email SignUp
    func signUp(
        email: String,
        password: String,
        username: String,
        displayName: String
    ) async throws {

        // 1. Firebase Auth
        let authResult = try await Auth.auth()
            .createUser(withEmail: email, password: password)

        let uid = authResult.user.uid
        let usernameKey = username.lowercased()

        let usernameRef = db.collection("usernames").document(usernameKey)
        let userRef = db.collection("users").document(uid)

        // 2. Firestore Transaction
        try await db.runTransaction { transaction, errorPointer in
            
            let usernameRef = self.db
                .collection("usernames")
                .document(username.lowercased())
            
            let userRef = self.db
                .collection("users")
                .document(uid)
            
            // username 重複チェック
            do {
                let snapshot = try transaction.getDocument(usernameRef)
                if snapshot.exists {
                    errorPointer?.pointee = NSError(
                        domain: "AuthError",
                        code: 0,
                        userInfo: [
                            NSLocalizedDescriptionKey: "このユーザーIDは既に使われています"
                        ]
                    )
                    return false
                }
            } catch {
                errorPointer?.pointee = error as NSError
                return false
            }
            
            // usernames
            transaction.setData([:], forDocument: usernameRef)
            
            // users
            transaction.setData(
                Self.makeUserData(
                    uid: uid,
                    email: email,
                    username: username,
                    displayName: displayName
                ),
                forDocument: userRef
            )
            
            return true
        }


    }

    // MARK: - User Data Builder
    private static func makeUserData(
        uid: String,
        email: String,
        username: String,
        displayName: String
    ) -> [String: Any] {

        [
            "uid": uid,
            "email": email,
            "username": username,
            "displayName": displayName,
            "avatarURL": "",
            "bio": "",
            "postsCount": 0,
            "followersCount": 0,
            "followingCount": 0,
            "gender": "未設定",
            "location": "未設定",
            "temperatureTolerance": "未設定",
            "createdAt": Timestamp()
        ]
    }

    // MARK: - Email Login
    func signIn(email: String, password: String) async throws {
        try await Auth.auth()
            .signIn(withEmail: email, password: password)
    }

    // MARK: - Google Login
    func signInWithGoogle() async throws {
        guard
            let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
            let rootVC = scene.windows
                .first(where: { $0.isKeyWindow })?
                .rootViewController
        else {
            throw NSError(domain: "AuthError", code: 0)
        }

        let result = try await GIDSignIn.sharedInstance
            .signIn(withPresenting: rootVC)

        guard let idToken = result.user.idToken?.tokenString else {
            throw NSError(domain: "AuthError", code: 0)
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )

        try await Auth.auth().signIn(with: credential)
    }

    // MARK: - Sign Out
    func signOut() throws {
        try Auth.auth().signOut()
    }
}
