//
//  EditProfileView.swift
//  Wearther
//
//  Created by 阿久津咲千 on 2025/12/18.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService

    let currentUser: AppUser

    @State private var username: String = ""
    @State private var customID: String = ""
    @State private var bio: String = ""
    
    // Avatar
    @State private var avatarImage: UIImage? = nil
    @State private var avatarURL: String? = nil
    @State private var showingAvatarOptions = false
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var isUploadingAvatar = false

    @State private var isSaving = false
    @State private var errorMessage = ""

    @FocusState private var focusedField: Field?

    enum Field {
        case displayName
        case userId
        case bio
    }

    var body: some View {
        ZStack {
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
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showingAvatarOptions = true
                            }
                        }) {
                            ZStack {
                                if let avatarImage = avatarImage {
                                    // Selected new image
                                    Image(uiImage: avatarImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 109, height: 109)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(Color(hex: "DDE2E2"), lineWidth: 1)
                                        )
                                } else if let urlString = avatarURL, !urlString.isEmpty {
                                    // Existing avatar from URL
                                    CachedAvatarImage(url: urlString, size: 109)
                                        .overlay(
                                            Circle()
                                                .stroke(Color(hex: "DDE2E2"), lineWidth: 1)
                                        )
                                } else {
                                    // Default avatar
                                    defaultAvatarView
                                }
                                
                                // Upload indicator
                                if isUploadingAvatar {
                                    Circle()
                                        .fill(Color.black.opacity(0.5))
                                        .frame(width: 109, height: 109)
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                }
                            }
                        }
                        .disabled(isUploadingAvatar)
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
                self.username = currentUser.displayName
                self.customID = currentUser.username
                self.bio = currentUser.bio ?? ""
                self.avatarURL = currentUser.avatarURL
            }
            
            // MARK: - Avatar Options Bottom Sheet
            if showingAvatarOptions {
                AvatarOptionsSheet(
                    isPresented: $showingAvatarOptions,
                    hasAvatar: avatarImage != nil || (avatarURL != nil && !avatarURL!.isEmpty),
                    onTakePhoto: {
                        showingCamera = true
                    },
                    onSelectFromLibrary: {
                        showingImagePicker = true
                    },
                    onDeletePhoto: {
                        avatarImage = nil
                        avatarURL = nil
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $showingImagePicker) {
            AvatarImagePickerView(selectedImage: $avatarImage)
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPickerView(selectedImage: $avatarImage)
        }
    }
    
    // MARK: - Default Avatar View
    private var defaultAvatarView: some View {
        Circle()
            .fill(Color(hex: "E8E8E8"))
            .frame(width: 109, height: 109)
            .overlay(
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(Color(hex: "AAAAAA"))
            )
            .overlay(
                Circle()
                    .stroke(Color(hex: "DDE2E2"), lineWidth: 1)
            )
    }

    func saveUserData() {
        guard let uid = authService.user?.uid else { return }

        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCustomID = customID.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedUsername.isEmpty || trimmedCustomID.isEmpty {
            errorMessage = "表示名とユーザーIDは必須です。"
            return
        }

        if trimmedCustomID.count < 4 {
            errorMessage = "ユーザーIDは4文字以上で入力してください。"
            return
        }

        isSaving = true
        
        Task {
            do {
                var newAvatarURL: String? = avatarURL
                
                // Upload new avatar if selected
                if let image = avatarImage {
                    newAvatarURL = try await uploadAvatarImage(image, userId: uid)
                }
                
                let db = Firestore.firestore()
                var updateData: [String: Any] = [
                    "username": trimmedCustomID.lowercased(),
                    "displayName": trimmedUsername,
                    "bio": bio,
                ]
                
                // Update avatar URL (nil means delete)
                if let url = newAvatarURL {
                    updateData["avatarURL"] = url
                } else {
                    updateData["avatarURL"] = FieldValue.delete()
                }

                try await db.collection("users").document(uid).setData(updateData, merge: true)
                
                await authService.fetchUser()
                
                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "保存に失敗しました: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func uploadAvatarImage(_ image: UIImage, userId: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "画像の変換に失敗しました"])
        }
        
        let storageRef = Storage.storage().reference()
        let avatarRef = storageRef.child("avatars/\(userId).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await avatarRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await avatarRef.downloadURL()
        
        return downloadURL.absoluteString
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
                .font(
                    .system(
                        size: showFloatingLabel ? 12 : 15,
                        weight: showFloatingLabel ? .semibold : .regular)
                )
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

// MARK: - Avatar Options Bottom Sheet
private struct AvatarOptionsSheet: View {
    @Binding var isPresented: Bool
    let hasAvatar: Bool
    let onTakePhoto: () -> Void
    let onSelectFromLibrary: () -> Void
    let onDeletePhoto: () -> Void
    
    @State private var sheetOffset: CGFloat = 300
    
    private var sheetHeight: CGFloat {
        hasAvatar ? 180 : 140
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Dimmed background
                Color.black
                    .opacity(isPresented ? 0.4 : 0)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissSheet()
                    }
                
                // Bottom sheet
                VStack(spacing: 0) {
                    // Drag indicator
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: "68717B"))
                        .frame(width: 40, height: 4)
                        .padding(.top, 12)
                        .padding(.bottom, 28)
                    
                    // Options
                    VStack(spacing: 20) {
                        // Take Photo
                        Button(action: { dismissAndExecute(onTakePhoto) }) {
                            HStack(spacing: 10) {
                                Image(systemName: "camera")
                                    .font(.system(size: 15))
                                    .frame(width: 22, height: 22)
                                Text("写真を撮る")
                                    .font(.system(size: 13))
                                Spacer()
                            }
                            .foregroundColor(Color(hex: "2D2D2D"))
                        }
                        
                        // Select from Library
                        Button(action: { dismissAndExecute(onSelectFromLibrary) }) {
                            HStack(spacing: 10) {
                                Image(systemName: "photo")
                                    .font(.system(size: 15))
                                    .frame(width: 22, height: 22)
                                Text("ライブラリから選択")
                                    .font(.system(size: 13))
                                Spacer()
                            }
                            .foregroundColor(Color(hex: "2D2D2D"))
                        }
                        
                        // Delete Photo (only show if has avatar)
                        if hasAvatar {
                            Button(action: { dismissAndExecute(onDeletePhoto) }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 15))
                                        .frame(width: 22, height: 22)
                                    Text("現在の写真を削除")
                                        .font(.system(size: 13))
                                    Spacer()
                                }
                                .foregroundColor(Color(hex: "FF000F"))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 45 + geometry.safeAreaInsets.bottom)
                }
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.white)
                )
                .offset(y: sheetOffset)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                sheetOffset = 0
            }
        }
    }
    
    private func dismissSheet() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            sheetOffset = 300
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
    
    private func dismissAndExecute(_ action: @escaping () -> Void) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            sheetOffset = 300
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
            action()
        }
    }
}

// MARK: - Avatar Image Picker View
struct AvatarImagePickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedImage: UIImage?
    
    @State private var photos: [PHAsset] = []
    @State private var previewImage: UIImage? = nil
    @State private var showingCamera = false
    
    private let imageManager = PHCachingImageManager()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 25))
                            .foregroundColor(.black)
                    }
                    .padding(.leading, 24)
                    Spacer()
                }
                
                Text("アイコン")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                
                HStack {
                    Spacer()
                    Button(action: {
                        if let image = previewImage {
                            selectedImage = image
                        }
                        dismiss()
                    }) {
                        Text("完了")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(previewImage != nil ? Color(hex: "5D8FFF") : Color.gray)
                    }
                    .disabled(previewImage == nil)
                    .padding(.trailing, 24)
                }
            }
            .frame(height: 50)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .fill(Color(hex: "DDDDDD"))
                    .frame(height: 0.2),
                alignment: .bottom
            )
            
            // Preview Area
            ZStack {
                Color(hex: "F8F8F8")
                
                if let image = previewImage {
                    GeometryReader { geometry in
                        let size = min(geometry.size.width, geometry.size.height)
                        ZStack {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: size, height: size)
                                .clipped()
                            
                            // Circle mask overlay
                            Rectangle()
                                .fill(Color.black.opacity(0.33))
                                .mask(
                                    ZStack {
                                        Rectangle()
                                        Circle()
                                            .frame(width: size * 0.8, height: size * 0.8)
                                            .blendMode(.destinationOut)
                                    }
                                    .compositingGroup()
                                )
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                } else {
                    VStack {
                        Image(systemName: "photo")
                            .font(.system(size: 50))
                            .foregroundColor(Color(hex: "AAAAAA"))
                        Text("写真を選択してください")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "888888"))
                    }
                }
            }
            .frame(height: UIScreen.main.bounds.width)
            
            // Label
            HStack {
                Text("写真を選択または撮影")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "2D2D2D"))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(hex: "F8F8F8"))
            
            // Photo Grid
            photoGrid
        }
        .background(Color(hex: "F8F8F8"))
        .onAppear {
            requestPhotoAccess()
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPickerView(selectedImage: $previewImage)
        }
    }
    
    private func requestPhotoAccess() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            if status == .authorized || status == .limited {
                loadPhotos()
            }
        }
    }
    
    private func loadPhotos() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 100
        
        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        var photoArray: [PHAsset] = []
        assets.enumerateObjects { asset, _, _ in
            photoArray.append(asset)
        }
        
        DispatchQueue.main.async {
            self.photos = photoArray
        }
    }
    
    private func loadFullImage(asset: PHAsset) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = false
        options.resizeMode = .exact
        
        let targetSize = CGSize(width: 1000, height: 1000)
        
        imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            if let image = image {
                DispatchQueue.main.async {
                    self.previewImage = image
                }
            }
        }
    }
    
    // MARK: - Photo Grid
    private var photoGrid: some View {
        let cellSize = (UIScreen.main.bounds.width - 6) / 4
        
        return ScrollView {
            LazyVGrid(columns: [
                GridItem(.fixed(cellSize), spacing: 2),
                GridItem(.fixed(cellSize), spacing: 2),
                GridItem(.fixed(cellSize), spacing: 2),
                GridItem(.fixed(cellSize), spacing: 2)
            ], spacing: 2) {
                // Camera Button
                Button(action: { showingCamera = true }) {
                    ZStack {
                        Rectangle()
                            .fill(Color(hex: "2D2D2D"))
                        
                        Image(systemName: "camera.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                        
                        // Plus icon
                        VStack {
                            HStack {
                                Spacer()
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 16, height: 16)
                                    Image(systemName: "plus")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(Color(hex: "2D2D2D"))
                                }
                                .padding(4)
                            }
                            Spacer()
                        }
                    }
                    .frame(width: cellSize, height: cellSize)
                }
                
                // Photo items
                ForEach(photos, id: \.localIdentifier) { asset in
                    PhotoGridItem(asset: asset, imageManager: imageManager) {
                        loadFullImage(asset: asset)
                    }
                }
            }
        }
    }
}

// MARK: - Photo Grid Item
private struct PhotoGridItem: View {
    let asset: PHAsset
    let imageManager: PHCachingImageManager
    let onTap: () -> Void
    
    @State private var thumbnail: UIImage? = nil
    
    private let cellSize = (UIScreen.main.bounds.width - 6) / 4
    
    var body: some View {
        Button(action: onTap) {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: cellSize, height: cellSize)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: cellSize, height: cellSize)
            }
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = false
        
        let scale = UIScreen.main.scale
        let targetSize = CGSize(width: cellSize * scale, height: cellSize * scale)
        
        imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            if let image = image {
                DispatchQueue.main.async {
                    self.thumbnail = image
                }
            }
        }
    }
}

// MARK: - Camera Picker View
struct CameraPickerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedImage: UIImage?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView
        
        init(_ parent: CameraPickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
