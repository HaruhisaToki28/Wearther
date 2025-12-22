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
        
    /// Firestoreにユーザーの初期ドキュメントを作成する
    private func createUserDocument(transaction: Transaction, uid: String, email: String, username: String, displayName: String) async throws {
        let db = Firestore.firestore()
        
//        let newUser: [String: Any] = [
//            "uid": uid,
//            "email": email,
//            "username": username,
//            "displayName": displayName,
//            "avatarURL": "",
//            "bio": "",
//            "postsCount": 0,
//            "followersCount": 0,
//            "followingCount": 0,
//            "gender": "未設定",
//            "location": "未設定",
//            "temperatureTolerance": "未設定",
//            "createdAt": Timestamp()
//        ] as [String : Any]
//        
//        try await db.collection("users").document(uid).setData(newUser)
        
        try await db.collection("users")
                .document(uid)
                .setData([
                    "uid": uid,
                    "email": email,
                    "username": username.lowercased(),
                    "displayName": displayName,
                    "createdAt": Timestamp()
                ])
    }
    

    //Email LogIn
    func signIn(email: String, password: String) async throws {
        do {
            _ = try await Auth.auth().signIn(withEmail: email, password: password)
        } catch let error as NSError {
            if let errorCode = AuthErrorCode(rawValue: error.code) {
                switch errorCode {
                case .invalidEmail:
                    throw AuthError.invalidEmailFormat
                case .wrongPassword, .userNotFound:
                    throw AuthError.invalidEmailOrPassword
                case .networkError:
                    throw AuthError.networkError
                default:
                    throw AuthError.unknown(error.localizedDescription)
                }
            }
            throw AuthError.unknown(error.localizedDescription)
        }
    }
    
    //Email SignUp
    func signUp(email: String, password: String, username: String, displayName: String) async throws {
        do {
            let result = try await Auth.auth()
                .createUser(withEmail: email, password: password)

            let uid = result.user.uid

            try await Firestore.firestore()
                .collection("users")
                .document(uid)
                .setData([
                    "uid": uid,
                    "email": email,
                    "username": username.lowercased(),
                    "displayName": displayName,
                    "createdAt": Timestamp(),
                    "avatarURL": "",
                    "bio": "",
                    "postsCount": 0,
                    "followersCount": 0,
                    "followingCount": 0,
                    "gender": "未設定",
                    "location": "未設定",
                    "temperatureTolerance": "未設定",
                ])
        } catch let error as NSError {
            if let errorCode = AuthErrorCode(rawValue: error.code) {
                switch errorCode {
                case .emailAlreadyInUse:
                    throw AuthError.emailAlreadyInUse
                case .invalidEmail:
                    throw AuthError.invalidEmailFormat
                case .weakPassword:
                    throw AuthError.weakPassword
                case .networkError:
                    throw AuthError.networkError
                default:
                    throw AuthError.unknown(error.localizedDescription)
                }
            }
            throw AuthError.unknown(error.localizedDescription)
        }
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

    // Password Reset
    func sendPasswordReset(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
}

enum AuthError: LocalizedError {
    case invalidEmailOrPassword
    case emailAlreadyInUse
    case invalidEmailFormat
    case weakPassword
    case networkError
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidEmailOrPassword:
            return "メールアドレスまたはパスワードが間違っています。"
        case .emailAlreadyInUse:
            return "このメールアドレスは既に使用されています。"
        case .invalidEmailFormat:
            return "メールアドレスの形式が正しくありません。"
        case .weakPassword:
            return "パスワードは6文字以上で入力してください。"
        case .networkError:
            return "ネットワークエラーが発生しました。通信環境を確認してください。"
        case .unknown(let message):
            return message
        }
    }
}
