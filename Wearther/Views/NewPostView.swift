//
//  NewPostView.swift
//  Wearther
//
//  Created by Wearther on 2026/01/16.
//

import SwiftUI
import PhotosUI

struct NewPostView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var showingPhotosPicker = false
    @State private var showingDetailView = false
    @State private var photoLibraryImages: [UIImage] = []
    @State private var isLoadingPhotos = true
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Navigation Bar
                navigationBar
                
                // Selected Image Preview
                imagePreview
                
                // Caption
                Text("写真を選択または撮影")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "2D2D2D"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                
                // Photo Grid
                photoGrid
            }
            .background(Color(hex: "F8F8F8"))
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView(image: $selectedImage)
            }
            .navigationDestination(isPresented: $showingDetailView) {
                if let image = selectedImage {
                    NewPostDetailView(selectedImage: image)
                }
            }
            .onAppear {
                loadPhotoLibraryImages()
            }
            .onChange(of: selectedPhotoItem) { oldValue, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedImage = uiImage
                    }
                }
            }
        }
    }
    
    // MARK: - Navigation Bar
    private var navigationBar: some View {
        ZStack {
            // Title
            Text("新規投稿")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black)
            
            HStack {
                // Close Button
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                }
                .padding(.leading, 16)
                
                Spacer()
                
                // Next Button
                Button(action: {
                    if selectedImage != nil {
                        showingDetailView = true
                    }
                }) {
                    Text("次へ")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(selectedImage != nil ? Color(hex: "5D8FFF") : Color(hex: "AAAAAA"))
                }
                .disabled(selectedImage == nil)
                .padding(.trailing, 16)
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
    }
    
    // MARK: - Image Preview
    private var imagePreview: some View {
        GeometryReader { geometry in
            let previewWidth = geometry.size.width * 0.75
            let previewHeight = previewWidth * 4 / 3
            
            ZStack {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: previewWidth, height: previewHeight)
                        .clipped()
                        .cornerRadius(14)
                } else {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hex: "E8EDF5"))
                        .frame(width: previewWidth, height: previewHeight)
                        .overlay(
                            VStack(spacing: 12) {
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundColor(Color(hex: "AAAAAA"))
                                Text("写真を選択してください")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "AAAAAA"))
                            }
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: UIScreen.main.bounds.width * 0.75 * 4 / 3 + 20)
    }
    
    // MARK: - Photo Grid
    private var photoGrid: some View {
        let cellSize = (UIScreen.main.bounds.width - 6) / 4  // 4列、間隔2px×3
        
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
                
                // Photo Library Picker
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    ZStack {
                        Rectangle()
                            .fill(Color(hex: "2D2D2D"))
                        
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                    .frame(width: cellSize, height: cellSize)
                }
                
                // Photo Library Images
                ForEach(Array(photoLibraryImages.enumerated()), id: \.offset) { index, image in
                    Button(action: {
                        selectedImage = image
                        // 高解像度画像を読み込む
                        loadFullResolutionImage(at: index)
                    }) {
                        ZStack {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: cellSize, height: cellSize)
                                .clipped()
                            
                            if selectedImage == image {
                                Rectangle()
                                    .fill(Color.white.opacity(0.3))
                                Rectangle()
                                    .stroke(Color(hex: "5D8FFF"), lineWidth: 3)
                            }
                        }
                        .frame(width: cellSize, height: cellSize)
                    }
                }
            }
        }
    }
    
    // 高解像度画像を読み込む
    private func loadFullResolutionImage(at index: Int) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 50
        
        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        guard index < assets.count else { return }
        
        let asset = assets.object(at: index)
        let imageManager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        
        let targetSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        
        imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            if let image = image {
                DispatchQueue.main.async {
                    self.selectedImage = image
                }
            }
        }
    }
    
    // MARK: - Load Photo Library Images
    private func loadPhotoLibraryImages() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    self.isLoadingPhotos = false
                }
                return
            }
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.fetchLimit = 50
            
            let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            
            let imageManager = PHImageManager.default()
            // サムネイルサイズを大きくして高画質に
            let scale = UIScreen.main.scale
            let cellSize = (UIScreen.main.bounds.width - 6) / 4
            let targetSize = CGSize(width: cellSize * scale, height: cellSize * scale)
            
            let options = PHImageRequestOptions()
            options.isSynchronous = true
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .exact
            
            var images: [UIImage] = []
            
            // バックグラウンドスレッドで処理
            DispatchQueue.global(qos: .userInitiated).async {
                assets.enumerateObjects { asset, index, _ in
                    imageManager.requestImage(
                        for: asset,
                        targetSize: targetSize,
                        contentMode: .aspectFill,
                        options: options
                    ) { image, _ in
                        if let image = image {
                            images.append(image)
                        }
                    }
                }
                
                // メインスレッドでUI更新
                DispatchQueue.main.async {
                    self.photoLibraryImages = images
                    self.isLoadingPhotos = false
                }
            }
        }
    }
}

// MARK: - Camera View
struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
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
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    NewPostView()
}
