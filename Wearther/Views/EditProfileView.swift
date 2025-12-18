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
    
    @State private var username: String = ""
    @State private var customID: String = ""
    @State private var bio: String = ""
    
    @State private var isSaving = false
    @State private var errorMessage = ""
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.gray)
                        Text("アイコン編集は現在利用できません")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 10)
            }
            
            Section(header: Text("基本情報")) {
                TextField("表示名", text: $username)
                
                TextField("ユーザーID", text: $customID)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                VStack(alignment: .leading) {
                    Text("自己紹介")
                        .font(.caption)
                        .foregroundColor(.gray)
                    TextEditor(text: $bio)
                        .frame(minHeight: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color(UIColor.separator), lineWidth: 0.5)
                        )
                }
                .padding(.vertical, 5)
            }
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .navigationTitle("プロフィール編集")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isSaving {
                    ProgressView()
                } else {
                    Button("保存") {
                        saveUserData()
                    }
                    .bold()
                }
            }
        }
        .onAppear {
            username = authService.user?.displayName ?? ""
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
