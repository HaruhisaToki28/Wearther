//
//  EditProfileView.swift
//  Wearther
//
//  Created by 阿久津咲千 on 2025/12/18.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    
    let currentUser: AppUser
    
    @State private var username: String = ""
    @State private var customID: String = ""
    @State private var bio: String = ""
    
    @State private var isSaving = false
    @State private var errorMessage = ""
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case displayName
        case userId
        case bio
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Custom Navigation Bar
            ZStack {
                // Back Button
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 25))
                            .foregroundColor(.black)
                    }
                    .padding(.leading, 24)
                    
                    Spacer()
                }
                
                // Title
                Text("プロフィールを編集")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
            }
            .frame(height: 50)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .fill(Color(hex: "DDDDDD"))
                    .frame(height: 0.2),
                alignment: .bottom
            )
            
            ScrollView {
                VStack(spacing: 0) {
                    // MARK: - Profile Icon
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.73))
                            .frame(width: 109, height: 109)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                        
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 17)
                    .padding(.bottom, 23)
                    
                    // MARK: - Form Fields
                    VStack(alignment: .leading, spacing: 15) {
                        // Section Label
                        Text("プロフィール")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: "2D2D2D"))
                        
                        // Display Name Field
                        FloatingLabelTextField(
                            placeholder: "表示名を入力",
                            text: $username,
                            isFocused: focusedField == .displayName
                        )
                        .focused($focusedField, equals: .displayName)
                        
                        // User ID Field
                        FloatingLabelTextField(
                            placeholder: "ユーザーIDを入力",
                            text: $customID,
                            isFocused: focusedField == .userId
                        )
                        .focused($focusedField, equals: .userId)
                        
                        // Bio Field
                        FloatingLabelTextEditor(
                            placeholder: "自己紹介を入力",
                            text: $bio,
                            isFocused: focusedField == .bio
                        )
                        .focused($focusedField, equals: .bio)
                        
                        // Error Message
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.system(size: 13))
                        }
                        
                        // Save Button
                        Button(action: {
                            saveUserData()
                        }) {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            } else {
                                Text("保存")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            }
                        }
                        .background(Color(hex: "2D2D2D"))
                        .cornerRadius(39)
                        .disabled(isSaving)
                        .padding(.top, 10)
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .background(Color(hex: "F8F8F8"))
        .navigationBarHidden(true)
        .onAppear {
            self.username = currentUser.displayName ?? ""
            self.customID = currentUser.username ?? ""
            self.bio = currentUser.bio ?? ""
        }
    }
    
    func saveUserData() {
        guard let uid = authService.user?.uid else { return }
        isSaving = true
        let db = Firestore.firestore()
        
        let updateData: [String: Any] = [
            "username": customID,
            "displayName": username,
            "bio": bio,
            "createdAt": Timestamp(),
            "postsCount": 0,
            "followersCount": 0,
            "followingCount": 0
        ]
        
        db.collection("users").document(uid).setData(updateData, merge: true) { error in
            isSaving = false
            if let error = error {
                errorMessage = "保存に失敗しました: \(error.localizedDescription)"
            } else {
                dismiss()
            }
        }
    }
}

// MARK: - Floating Label TextField
private struct FloatingLabelTextField: View {
    let placeholder: String
    @Binding var text: String
    let isFocused: Bool
    
    private var showFloatingLabel: Bool {
        isFocused || !text.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if showFloatingLabel {
                // Floating Label
                Text(placeholder)
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "AAAAAA").opacity(0.67))
            }
            
            // Text Field (always present)
            TextField(showFloatingLabel ? "" : placeholder, text: $text)
                .font(.system(size: showFloatingLabel ? 12 : 15, weight: showFloatingLabel ? .semibold : .regular))
                .foregroundColor(showFloatingLabel ? .black : Color(hex: "AAAAAA").opacity(0.67))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, showFloatingLabel ? 9 : 15)
        .frame(height: 50)
        .background(Color.white)
        .cornerRadius(15)
    }
}

// MARK: - Floating Label TextEditor
private struct FloatingLabelTextEditor: View {
    let placeholder: String
    @Binding var text: String
    let isFocused: Bool
    
    private var showFloatingLabel: Bool {
        isFocused || !text.isEmpty
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
            
            // Placeholder (shown when empty and not focused)
            if text.isEmpty && !isFocused {
                Text(placeholder)
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "AAAAAA").opacity(0.67))
                    .padding(.horizontal, 22)
                    .padding(.top, 15)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Floating Label (shown when focused or has text)
                if showFloatingLabel {
                    Text(placeholder)
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "AAAAAA").opacity(0.67))
                }
                
                // TextEditor (always present for tappability)
                TextEditor(text: $text)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.black)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 60)
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 12)
        }
        .frame(minHeight: 100)
    }
}
