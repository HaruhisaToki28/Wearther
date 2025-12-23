//
//  AuthViewModel.swift
//  Wearther
//
//  Created by 阿久津咲千 on 2025/12/20.
//

import Firebase
import FirebaseFirestore

import Foundation
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var username = ""
    @Published var displayName = ""
    @Published var email = ""
    @Published var password = ""
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let authService: AuthService
    
    init(authService: AuthService) {
        self.authService = authService
    }
    
    func register() async {
        guard !username.isEmpty, !displayName.isEmpty else {
            self.errorMessage = "すべての項目を入力してください"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.signUp(
                email: email,
                password: password,
                username: username,
                displayName: displayName
            )
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
