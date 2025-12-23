//
//  SettingsView.swift
//  Wearther
//
//  Created by 阿久津咲千 on 2025/12/18.
//

import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    
    // 47 Prefectures
    let prefectures = [
        "北海道", "青森県", "岩手県", "宮城県", "秋田県", "山形県", "福島県",
        "茨城県", "栃木県", "群馬県", "埼玉県", "千葉県", "東京都", "神奈川県",
        "新潟県", "富山県", "石川県", "福井県", "山梨県", "長野県", "岐阜県",
        "静岡県", "愛知県", "三重県", "滋賀県", "京都府", "大阪府", "兵庫県",
        "奈良県", "和歌山県", "鳥取県", "島根県", "岡山県", "広島県", "山口県",
        "徳島県", "香川県", "愛媛県", "高知県", "福岡県", "佐賀県", "長崎県",
        "熊本県", "大分県", "宮崎県", "鹿児島県", "沖縄県", "その他"
    ]
    
    @State private var showingResidencePicker = false
    @State private var showingTemperatureActionSheet = false
    
    var body: some View {
        ZStack {
            Color(red: 0.97, green: 0.97, blue: 0.97) // Background Gray
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 0) {
                        HStack(alignment: .center, spacing: 16) {
                            // Avatar
                            AsyncImage(url: URL(string: authService.currentUser?.avatarURL ?? authService.user?.photoURL?.absoluteString ?? "")) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                case .failure, .empty:
                                    Circle().fill(Color.gray.opacity(0.3))
                                @unknown default:
                                    Circle().fill(Color.gray.opacity(0.3))
                                }
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            
                            // User Info
                            VStack(alignment: .leading, spacing: 4) {
                                // Display Name
                                if let displayName = authService.currentUser?.displayName {
                                    Text(displayName)
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.black)
                                } else {
                                    Text(authService.user?.displayName ?? "ゲスト")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.black)
                                }
                                
                                // Username
                                if let username = authService.currentUser?.username {
                                     Text("@\(username)")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                } else if let email = authService.user?.email {
                                     // Fallback to email username if profile not loaded
                                     let username = email.components(separatedBy: "@").first ?? ""
                                     Text("@\(username)")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(20)
                    }
                    .padding(.top, 20)
                    
                    // Account Info Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("アカウント情報")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black)
                            .padding(.leading, 4)
                        
                        VStack(spacing: 0) {
                            SettingsRow(icon: "envelope.fill", title: "メールアドレス", showDivider: true)
                            SettingsRow(icon: "key.fill", title: "パスワード", showDivider: true)
                            SettingsRow(title: "外部連携", showDivider: true)
                            SettingsRow(icon: "location.fill", title: "位置情報設定", showDivider: true)
                            SettingsRow(icon: "bell.fill", title: "通知設定", showDivider: false)
                        }
                        .background(Color.white)
                        .cornerRadius(20)
                    }
                    
                    // User Info Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ユーザー情報")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black)
                            .padding(.leading, 4)
                        
                        VStack(spacing: 0) {
                            // Residence
                            Button(action: {
                                showingResidencePicker = true
                            }) {
                                HStack {
                                    Image(systemName: "mappin.circle")
                                        .foregroundColor(.black)
                                        .font(.system(size: 20))
                                        .frame(width: 30)
                                    
                                    Text("居住地域")
                                        .foregroundColor(.black)
                                        .font(.system(size: 16))
                                    
                                    Spacer()
                                    
                                    Text(authService.currentUser?.location ?? "未設定")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 14))
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 14))
                                }
                                .padding()
                            }
                            
                            Divider().padding(.leading, 50)
                            
                            // Fashion Style
                            SettingsRow(icon: "star.fill", title: "好みのスタイル", showDivider: false) // Custom row needed for tags if strict to design, but "Button only" requested.
                            
                             // Tags preview (Visual only as per request)
                            HStack {
                                Spacer()
                                ForEach(["カジュアル", "フォーマル"], id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(size: 10))
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 8)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)
                                }
                                Spacer()
                            }
                            .padding(.bottom, 12)
                             
                            Divider().padding(.leading, 0)

                            // Temperature Tolerance
                            Button(action: {
                                showingTemperatureActionSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "thermometer")
                                        .foregroundColor(.black)
                                        .font(.system(size: 20))
                                        .frame(width: 30)
                                    
                                    Text("寒暖耐性")
                                        .foregroundColor(.black)
                                        .font(.system(size: 16))
                                    
                                    Spacer()
                                    
                                    Text(authService.currentUser?.temperatureTolerance ?? "未設定")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 14))
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 14))
                                }
                                .padding()
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(20)
                    }
                    
                    // Logout
                     Button(action: {
                        try? authService.signOut()
                    }) {
                        Text("ログアウト")
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(15)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("アカウント設定")
        .navigationBarTitleDisplayMode(.inline)
        // Residence Selection
        .sheet(isPresented: $showingResidencePicker) {
            NavigationView {
                List(prefectures, id: \.self) { prefecture in
                    Button(action: {
                        Task {
                            try? await authService.updateUserData(data: ["location": prefecture])
                        }
                        showingResidencePicker = false
                    }) {
                        Text(prefecture)
                            .foregroundColor(.black)
                    }
                }
                .navigationTitle("居住地域を選択")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("閉じる") {
                            showingResidencePicker = false
                        }
                    }
                }
            }
        }
        // Temperature Tolerance Selection
        .confirmationDialog("寒暖耐性を選択", isPresented: $showingTemperatureActionSheet, titleVisibility: .visible) {
            Button("寒がり") {
                Task {
                    try? await authService.updateUserData(data: ["temperatureTolerance": "寒がり"])
                }
            }
            Button("普通") {
                 Task {
                    try? await authService.updateUserData(data: ["temperatureTolerance": "普通"])
                }
            }
            Button("暑がり") {
                 Task {
                    try? await authService.updateUserData(data: ["temperatureTolerance": "暑がり"])
                }
            }
        }
    }
}

// Helper View for Settings Rows
struct SettingsRow: View {
    var icon: String?
    var title: String
    var showDivider: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {}) {
                HStack {
                    if let icon = icon {
                        Image(systemName: icon)
                            .foregroundColor(.black)
                            .font(.system(size: 20)) // Adjust size
                            .frame(width: 30)
                    } else {
                        Spacer().frame(width: 30)
                    }
                    
                    Text(title)
                        .foregroundColor(.black)
                        .font(.system(size: 16))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                }
                .padding()
            }
            
            if showDivider {
                Divider().padding(.leading, 50)
            }
        }
    }
}

#Preview {
    ProfileView()
}
