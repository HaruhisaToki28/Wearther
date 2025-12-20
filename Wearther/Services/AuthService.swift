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
import FirebaseFirestore

class AuthService: ObservableObject {
    
    @Published var user: User? = nil
    @Published var isAuthenticated: Bool = false

    init() {
        Auth.auth().addStateDidChangeListener { auth, user in
            self.user = user
            self.isAuthenticated = (user != nil)
        }
    }
    
    //User Data
    func createUserDocument(uid: String, email: String, username: String) async throws {
        let db = Firestore.firestore()
        
        let newUser = [
            "username": username,
            "email": email,
            "gender": "未設定",
            "location": "未設定",
            "temperatureTolerance": "普通",
            "bio": "",
            "profileImageUrl": "",
            "createdAt": Timestamp()
        ] as [String : Any]
        
        try await db.collection("users").document(uid).setData(newUser)
    }
    
    //Email LogIn
    func signIn(email: String, password: String) async throws {
        _ = try await Auth.auth().signIn(withEmail: email, password: password)
    }
    
    //Email SignUp
    func signUp(email: String, password: String, username: String, displayName: String) async throws {
        let db = Firestore.firestore()
        
        // 1. まず Auth でユーザー作成
        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        let uid = authResult.user.uid
        
        // 2. トランザクションで重複チェックと保存
        let usernameRef = db.collection("usernames").document(username.lowercased())
        let userRef = db.collection("users").document(uid)
        
        try await db.runTransaction({ (transaction, errorPointer) -> Any? in
            let usernameDoc: DocumentSnapshot
            do {
                usernameDoc = try transaction.getDocument(usernameRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            // usernameが既に存在するか確認
            if usernameDoc.exists {
                let error = NSError(domain: "AppError", code: 0, userInfo: [NSLocalizedDescriptionKey: "このユーザーIDは既に使われています"])
                errorPointer?.pointee = error
                return nil
            }
            
            // 重複がなければ、両方のコレクションに書き込み
            transaction.setData([:], forDocument: usernameRef)
            
            let newUser: [String: Any] = [
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
            transaction.setData(newUser, forDocument: userRef)
            
            return nil
        })
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
