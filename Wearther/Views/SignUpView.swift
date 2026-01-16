//
//  SignUpView.swift
//  Wearther
//
//  Created by 阿久津咲千 on 2025/12/18.
//

import SwiftUI

enum SignUpStep: Int, CaseIterable {
    case email = 0      // Step 1: メールアドレス入力
    case userInfo = 1   // Step 2: ユーザーID、表示名、パスワード
    case profile = 2    // Step 3: 性別、年齢、身長
    case complete = 3   // 完了画面
}

struct SignUpView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    
    @State private var currentStep: SignUpStep = .email
    
    // Step 1: Email
    @State private var email = ""
    
    // Step 2: User Info
    @State private var username = ""
    @State private var displayName = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    // Step 3: Profile
    @State private var gender = "未設定"
    @State private var age = ""
    @State private var height = ""
    
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    let genderOptions = ["未設定", "男性", "女性", "その他"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Navigation Bar
            navigationBar
            
            Spacer()
                .frame(height: 38)
            
            // Progress Indicator (完了画面では非表示)
            if currentStep != .complete {
                progressIndicator
                    .padding(.bottom, 30)
            }
            
            // Step Content
            switch currentStep {
            case .email:
                emailStepView
            case .userInfo:
                userInfoStepView
            case .profile:
                profileStepView
            case .complete:
                completeView
            }
            
            Spacer()
        }
        .background(Color.white)
        .navigationBarHidden(true)
    }
    
    // MARK: - Navigation Bar
    
    private var navigationBar: some View {
        ZStack {
            // Back Button (完了画面では非表示)
            if currentStep != .complete {
                HStack {
                    Button(action: {
                        handleBackButton()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 25))
                            .foregroundColor(.black)
                    }
                    .padding(.leading, 24)
                    
                    Spacer()
                }
            }
            
            // Title
            Text(navigationTitle)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black)
        }
        .frame(height: 50)
        .background(Color.white)
    }
    
    private var navigationTitle: String {
        switch currentStep {
        case .email:
            return "新規作成"
        case .userInfo:
            return "アカウント情報"
        case .profile:
            return "プロフィール設定"
        case .complete:
            return "登録完了"
        }
    }
    
    // MARK: - Progress Indicator
    
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(progressColor(for: index))
                    .frame(width: 10, height: 10)
            }
        }
    }
    
    private func progressColor(for index: Int) -> Color {
        return index <= currentStep.rawValue ? Color(hex: "2D2D2D") : Color(hex: "D9D9D9")
    }
    
    // MARK: - Step 1: Email Input
    
    private var emailStepView: some View {
        VStack(spacing: 15) {
            Text("メールアドレスを入力してください")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black)
                .padding(.bottom, 10)
            
            TextField("メールアドレス", text: $email)
                .font(.system(size: 15, weight: .light))
                .padding(.horizontal, 20)
                .frame(height: 50)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color(hex: "2D2D2D"), lineWidth: 1)
                )
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .padding(.horizontal, 16)
            
            errorMessageView
            
            Button(action: {
                checkEmailAndProceed()
            }) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(hex: "2D2D2D"))
                        .cornerRadius(39)
                } else {
                    Text("次へ")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(hex: "2D2D2D"))
                        .cornerRadius(39)
                }
            }
            .disabled(isLoading || email.isEmpty)
            .padding(.horizontal, 16)
            .padding(.top, 20)
            
            Button(action: {
                dismiss()
            }) {
                Text("アカウントをお持ちの場合")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "2D2D2D"))
            }
            .padding(.top, 15)
        }
    }
    
    // MARK: - Step 2: User Info
    
    private var userInfoStepView: some View {
        VStack(spacing: 15) {
            // Username Field
            VStack(alignment: .leading, spacing: 5) {
                TextField("ユーザーID（英数字のみ）", text: $username)
                    .font(.system(size: 15, weight: .light))
                    .padding(.horizontal, 20)
                    .frame(height: 50)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color(hex: "2D2D2D"), lineWidth: 1)
                    )
                    .autocapitalization(.none)
                    .onChange(of: username) { oldValue, newValue in
                        // 英数字のみに制限
                        username = newValue.filter { $0.isLetter || $0.isNumber }
                    }
            }
            
            // Display Name Field
            TextField("表示名", text: $displayName)
                .font(.system(size: 15, weight: .light))
                .padding(.horizontal, 20)
                .frame(height: 50)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color(hex: "2D2D2D"), lineWidth: 1)
                )
                .autocapitalization(.none)
            
            // Password Field
            SecureField("パスワード（6文字以上）", text: $password)
                .font(.system(size: 15, weight: .light))
                .padding(.horizontal, 20)
                .frame(height: 50)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color(hex: "2D2D2D"), lineWidth: 1)
                )
            
            // Confirm Password Field
            SecureField("パスワードを確認", text: $confirmPassword)
                .font(.system(size: 15, weight: .light))
                .padding(.horizontal, 20)
                .frame(height: 50)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color(hex: "2D2D2D"), lineWidth: 1)
                )
            
            errorMessageView
            
            Button(action: {
                validateUserInfoAndProceed()
            }) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(hex: "2D2D2D"))
                        .cornerRadius(39)
                } else {
                    Text("次へ")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(hex: "2D2D2D"))
                        .cornerRadius(39)
                }
            }
            .disabled(isLoading || !isUserInfoValid)
            .padding(.top, 20)
        }
        .padding(.horizontal, 16)
    }
    
    private var isUserInfoValid: Bool {
        !username.isEmpty && !displayName.isEmpty && !password.isEmpty && !confirmPassword.isEmpty
    }
    
    // MARK: - Step 3: Profile
    
    private var profileStepView: some View {
        VStack(spacing: 15) {
            // Gender Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("性別")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "666666"))
                
                Menu {
                    ForEach(genderOptions, id: \.self) { option in
                        Button(option) {
                            gender = option
                        }
                    }
                } label: {
                    HStack {
                        Text(gender)
                            .font(.system(size: 15, weight: .light))
                            .foregroundColor(.black)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 20)
                    .frame(height: 50)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color(hex: "2D2D2D"), lineWidth: 1)
                    )
                }
            }
            
            // Age Field
            VStack(alignment: .leading, spacing: 8) {
                Text("年齢")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "666666"))
                
                TextField("例: 25", text: $age)
                    .font(.system(size: 15, weight: .light))
                    .padding(.horizontal, 20)
                    .frame(height: 50)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color(hex: "2D2D2D"), lineWidth: 1)
                    )
                    .keyboardType(.numberPad)
                    .onChange(of: age) { oldValue, newValue in
                        age = newValue.filter { $0.isNumber }
                    }
            }
            
            // Height Field
            VStack(alignment: .leading, spacing: 8) {
                Text("身長 (cm)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "666666"))
                
                TextField("例: 170", text: $height)
                    .font(.system(size: 15, weight: .light))
                    .padding(.horizontal, 20)
                    .frame(height: 50)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color(hex: "2D2D2D"), lineWidth: 1)
                    )
                    .keyboardType(.numberPad)
                    .onChange(of: height) { oldValue, newValue in
                        height = newValue.filter { $0.isNumber }
                    }
            }
            
            errorMessageView
            
            Button(action: {
                completeSignUp()
            }) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(hex: "2D2D2D"))
                        .cornerRadius(39)
                } else {
                    Text("登録完了")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(hex: "2D2D2D"))
                        .cornerRadius(39)
                }
            }
            .disabled(isLoading)
            .padding(.top, 20)
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Complete View
    
    private var completeView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(Color(hex: "4CAF50"))
                .padding(.bottom, 10)
            
            Text("登録が完了しました！")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
            
            Text("確認メールを送信しました")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(hex: "666666"))
            
            Text(email)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "666666"))
            
            Text("メール内のリンクをタップして\nメールアドレスを確認してください")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "888888"))
                .multilineTextAlignment(.center)
                .padding(.top, 10)
            
            Button(action: {
                // ContentViewが自動的にMainTabViewに切り替わる
                dismiss()
            }) {
                Text("はじめる")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(hex: "2D2D2D"))
                    .cornerRadius(39)
            }
            .padding(.horizontal, 16)
            .padding(.top, 30)
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Error Message View
    
    private var errorMessageView: some View {
        Group {
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.system(size: 13))
                    .padding(.top, 10)
            }
        }
    }
    
    // MARK: - Actions
    
    private func handleBackButton() {
        errorMessage = ""
        
        switch currentStep {
        case .email:
            dismiss()
        case .userInfo:
            currentStep = .email
        case .profile:
            currentStep = .userInfo
        case .complete:
            break
        }
    }
    
    private func checkEmailAndProceed() {
        guard !email.isEmpty else {
            errorMessage = "メールアドレスを入力してください"
            return
        }
        
        // 簡易的なメール形式チェック
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        if !emailPredicate.evaluate(with: email) {
            errorMessage = "メールアドレスの形式が正しくありません"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let isAvailable = try await authService.isEmailAvailable(email)
                
                await MainActor.run {
                    isLoading = false
                    
                    if isAvailable {
                        currentStep = .userInfo
                    } else {
                        errorMessage = "このメールアドレスは既に使用されています"
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func validateUserInfoAndProceed() {
        errorMessage = ""
        
        // Validate username (alphanumeric only)
        if username.isEmpty {
            errorMessage = "ユーザーIDを入力してください"
            return
        }
        
        let alphanumericSet = CharacterSet.alphanumerics
        if username.unicodeScalars.contains(where: { !alphanumericSet.contains($0) }) {
            errorMessage = "ユーザーIDは英数字のみ使用できます"
            return
        }
        
        // Validate display name
        if displayName.isEmpty {
            errorMessage = "表示名を入力してください"
            return
        }
        
        // Validate password match
        if password != confirmPassword {
            errorMessage = "パスワードが一致しません"
            return
        }
        
        // Validate password length
        if password.count < 6 {
            errorMessage = "パスワードは6文字以上で入力してください"
            return
        }
        
        isLoading = true
        
        Task {
            do {
                // Check username availability
                let isAvailable = try await authService.isUsernameAvailable(username)
                
                await MainActor.run {
                    isLoading = false
                    
                    if isAvailable {
                        currentStep = .profile
                    } else {
                        errorMessage = "このユーザーIDは既に使用されています"
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func completeSignUp() {
        isLoading = true
        errorMessage = ""
        
        let ageInt = Int(age) ?? 0
        let heightInt = Int(height) ?? 0
        
        Task {
            do {
                try await authService.signUpWithProfile(
                    email: email,
                    password: password,
                    username: username,
                    displayName: displayName,
                    gender: gender,
                    age: ageInt,
                    height: heightInt
                )
                
                await MainActor.run {
                    isLoading = false
                    currentStep = .complete
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
