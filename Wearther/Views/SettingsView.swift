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
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - User Profile Card
                HStack(spacing: 15) {
                    // Avatar
                    AsyncImage(url: URL(string: authService.currentUser?.avatarURL ?? authService.user?.photoURL?.absoluteString ?? "")) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure, .empty:
                            Circle()
                                .fill(Color.white.opacity(0.73))
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.gray)
                                )
                        @unknown default:
                            Circle().fill(Color.gray.opacity(0.3))
                        }
                    }
                    .frame(width: 68, height: 68)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color(hex: "DDE2E2"), lineWidth: 0.1)
                    )
                    
                    // User Info
                    VStack(alignment: .leading, spacing: 0) {
                        // Display Name
                        if let displayName = authService.currentUser?.displayName {
                            Text(displayName)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.black)
                                .frame(height: 37)
                        } else {
                            Text(authService.user?.displayName ?? "ゲスト")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.black)
                                .frame(height: 37)
                        }
                        
                        // Username
                        if let username = authService.currentUser?.username {
                            Text("@\(username)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(hex: "68717B"))
                        } else if let email = authService.user?.email {
                            let username = email.components(separatedBy: "@").first ?? ""
                            Text("@\(username)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(hex: "68717B"))
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 13)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(20)
                .padding(.top, 36)
                
                // MARK: - Account Info Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("アカウント情報")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "2D2D2D"))
                    
                    VStack(spacing: 0) {
                        SettingsRowNew(icon: "envelope", title: "メールアドレス")
                        SettingsDivider()
                        SettingsRowNew(icon: "key", title: "パスワード")
                        SettingsDivider()
                        SettingsRowNew(icon: "link", title: "外部連携")
                        SettingsDivider()
                        SettingsRowNew(icon: "paperplane", title: "位置情報設定")
                        SettingsDivider()
                        SettingsRowNew(icon: "bell", title: "通知設定")
                    }
                    .background(Color.white)
                    .cornerRadius(15)
                }
                
                // MARK: - User Info Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("ユーザー情報")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "2D2D2D"))
                    
                    VStack(spacing: 0) {
                        // Residence
                        Button(action: {
                            showingResidencePicker = true
                        }) {
                            SettingsRowWithValue(
                                icon: "mappin.and.ellipse",
                                title: "居住地域",
                                value: authService.currentUser?.location ?? "未設定"
                            )
                        }
                        
                        SettingsDivider()
                        
                        // Fashion Style with Tags
                        VStack(spacing: 0) {
                            // Row
                            HStack {
                                Image(systemName: "star")
                                    .font(.system(size: 24))
                                    .foregroundColor(.black)
                                    .frame(width: 35, height: 35)
                                
                                Text("好みのスタイル")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(hex: "2D2D2D"))
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.black)
                            }
                            .padding(.horizontal, 22)
                            .padding(.top, 10)
                            
                            // Tags
                            HStack(spacing: 10) {
                                StyleTag(text: "カジュアル")
                                StyleTag(text: "フォーマル")
                            }
                            .padding(.horizontal, 22)
                            .padding(.vertical, 5)
                        }
                        .background(Color.white)
                        
                        SettingsDivider()
                        
                        // Temperature Tolerance
                        Button(action: {
                            showingTemperatureActionSheet = true
                        }) {
                            SettingsRowWithValue(
                                icon: "wind.snow",
                                title: "寒暖耐性",
                                value: authService.currentUser?.temperatureTolerance ?? "未設定"
                            )
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(15)
                }
                
                // MARK: - Logout Button
                Button(action: {
                    try? authService.signOut()
                }) {
                    HStack {
                        Text("ログアウト")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 15)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(15)
                }
                
                Spacer().frame(height: 50)
            }
            .padding(.horizontal, 16)
        }
        .background(Color(hex: "F8F8F8"))
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

// MARK: - Settings Row (Figma Design)
private struct SettingsRowNew: View {
    let icon: String
    let title: String
    
    var body: some View {
        Button(action: {}) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.black)
                    .frame(width: 35, height: 35)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "2D2D2D"))
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 10)
        }
    }
}

// MARK: - Settings Row with Value
private struct SettingsRowWithValue: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.black)
                .frame(width: 35, height: 35)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: "2D2D2D"))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: "68717B"))
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.black)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 10)
    }
}

// MARK: - Settings Divider
private struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color(hex: "DDE2E2"))
            .frame(height: 1)
            .padding(.horizontal, 22)
    }
}

// MARK: - Style Tag
private struct StyleTag: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "tag.fill")
                .font(.system(size: 8))
                .foregroundColor(.white)
            
            Text(text)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(Color(hex: "2D2D2D"))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color(hex: "DDE2E2"))
        .cornerRadius(20)
    }
}

// Keep old SettingsRow for compatibility
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
                            .font(.system(size: 20))
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
    SettingsView()
}
