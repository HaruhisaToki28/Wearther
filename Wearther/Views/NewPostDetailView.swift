//
//  NewPostDetailView.swift
//  Wearther
//
//  Created by Wearther on 2026/01/16.
//

import SwiftUI
import CoreLocation
import FirebaseAuth

struct NewPostDetailView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    let selectedImage: UIImage
    
    // Form State
    @State private var title = ""
    @State private var caption = ""
    @State private var selectedWeather: PostWeather = .sunny
    @State private var temperature: String = ""
    @State private var useCurrentWeather = true
    @State private var locationName = ""
    @State private var selectedLocation: LocationSearchResult?
    @State private var useCurrentLocation = true
    @State private var agreedToShare = false
    
    // Location & Weather
    @StateObject private var locationManager = LocationManager()
    private let weatherService = WeatherService.shared
    
    // UI State
    @State private var showingLocationSearch = false
    @State private var showingWeatherPicker = false
    @State private var showingTemperaturePicker = false
    @State private var isPosting = false
    @State private var uploadProgress: Double = 0.0
    @State private var errorMessage = ""
    @State private var showingSuccessAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation Bar
            navigationBar
            
            ScrollView {
                VStack(spacing: 20) {
                    // Image Preview
                    imagePreview
                    
                    // Form Fields
                    formSection
                    
                    // Agreement Checkbox
                    agreementSection
                    
                    // Post Button
                    postButton
                    
                    Spacer().frame(height: 30)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
        }
        .background(Color(hex: "F8F8F8"))
        .navigationBarHidden(true)
        .onAppear {
            setupInitialData()
        }
        .onChange(of: locationManager.location) { oldValue, newValue in
            if useCurrentLocation, let location = newValue {
                Task {
                    await fetchLocationAndWeather(location)
                }
            }
        }
        .fullScreenCover(isPresented: $showingLocationSearch) {
            LocationSearchView { result in
                selectedLocation = result
                locationName = result.fullName
                useCurrentLocation = false
            }
        }
        .alert("投稿完了", isPresented: $showingSuccessAlert) {
            Button("OK") {
                // Dismiss all the way back
                dismiss()
            }
        } message: {
            Text("投稿が完了しました")
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
                // Back Button
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 25))
                        .foregroundColor(.black)
                }
                .padding(.leading, 24)
                
                Spacer()
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
        Image(uiImage: selectedImage)
            .resizable()
            .scaledToFill()
            .frame(width: 164, height: 219)
            .clipped()
            .cornerRadius(14)
    }
    
    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: 20) {
            // Title
            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("タイトル")
                
                TextField("タイトルを入力", text: $title)
                    .font(.system(size: 15))
                    .padding(.horizontal, 16)
                    .frame(height: 48)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "E5E5E5"), lineWidth: 1)
                    )
            }
            
            // Caption
            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("キャプション")
                
                TextEditor(text: $caption)
                    .font(.system(size: 15))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .frame(height: 100)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "E5E5E5"), lineWidth: 1)
                    )
                    .scrollContentBackground(.hidden)
            }
            
            // Weather
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("天気")
                
                // Current Weather Button
                selectableChip(
                    icon: "location.fill",
                    text: "現在地の天気",
                    isSelected: useCurrentWeather
                ) {
                    useCurrentWeather = true
                    if let weather = getCurrentWeatherCondition() {
                        selectedWeather = weather
                    }
                }
                
                // Weather Options
                HStack(spacing: 8) {
                    ForEach(PostWeather.allCases, id: \.self) { weather in
                        weatherOptionButton(weather: weather)
                    }
                }
            }
            
            // Temperature
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("気温")
                
                HStack(spacing: 10) {
                    // Current Temperature Button
                    selectableChip(
                        icon: "location.fill",
                        text: "現在地の気温",
                        isSelected: false
                    ) {
                        if let temp = weatherService.getCurrentTemperature() {
                            temperature = String(Int(temp))
                        }
                    }
                    
                    // Temperature Input
                    HStack(spacing: 4) {
                        TextField("20", text: $temperature)
                            .font(.system(size: 15, weight: .medium))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 45)
                        Text("°C")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "666666"))
                    }
                    .frame(height: 38)
                    .padding(.horizontal, 14)
                    .background(Color.white)
                    .cornerRadius(19)
                    .overlay(
                        RoundedRectangle(cornerRadius: 19)
                            .stroke(Color(hex: "E5E5E5"), lineWidth: 1)
                    )
                    
                    Spacer()
                }
            }
            
            // Location
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("場所")
                
                HStack(spacing: 10) {
                    // Current Location Button
                    selectableChip(
                        icon: "location.fill",
                        text: "現在地",
                        isSelected: useCurrentLocation
                    ) {
                        useCurrentLocation = true
                        locationManager.requestLocation()
                    }
                    
                    // Search Location Button
                    selectableChip(
                        icon: "magnifyingglass",
                        text: "検索",
                        isSelected: false
                    ) {
                        showingLocationSearch = true
                    }
                    
                    Spacer()
                }
                
                // Selected Location Display
                if !locationName.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color(hex: "08C4FA"))
                        Text(locationName)
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "2D2D2D"))
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "E5E5E5"), lineWidth: 1)
                    )
                }
            }
            
            // Error Message
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.system(size: 13))
                    .foregroundColor(.red)
            }
        }
    }
    
    // MARK: - UI Components
    
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(Color(hex: "666666"))
    }
    
    private func selectableChip(icon: String, text: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                Text(text)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : Color(hex: "2D2D2D"))
            .frame(height: 38)
            .padding(.horizontal, 14)
            .background(isSelected ? Color(hex: "2D2D2D") : Color.white)
            .cornerRadius(19)
            .overlay(
                RoundedRectangle(cornerRadius: 19)
                    .stroke(Color(hex: "E5E5E5"), lineWidth: isSelected ? 0 : 1)
            )
        }
    }
    
    private func weatherOptionButton(weather: PostWeather) -> some View {
        let isSelected = selectedWeather == weather && !useCurrentWeather
        
        return Button(action: {
            selectedWeather = weather
            useCurrentWeather = false
        }) {
            VStack(spacing: 6) {
                Image(systemName: weather.symbolName)
                    .font(.system(size: 22))
                Text(weather.rawValue)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : Color(hex: "2D2D2D"))
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(isSelected ? Color(hex: "2D2D2D") : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "E5E5E5"), lineWidth: isSelected ? 0 : 1)
            )
        }
    }
    
    // MARK: - Agreement Section
    private var agreementSection: some View {
        Button(action: { agreedToShare.toggle() }) {
            HStack(spacing: 10) {
                Image(systemName: agreedToShare ? "checkmark.square.fill" : "square")
                    .font(.system(size: 18))
                    .foregroundColor(agreedToShare ? Color(hex: "2D2D2D") : Color(hex: "AAAAAA"))
                
                Text("あなたの性別、年齢、身長も共有されます。")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "666666"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 16)
    }
    
    // MARK: - Post Button
    private var postButton: some View {
        Button(action: {
            createPost()
        }) {
            if isPosting {
                HStack(spacing: 10) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("投稿中...")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color(hex: "2D2D2D"))
                .cornerRadius(26)
            } else {
                Text("投稿")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(canPost ? Color(hex: "2D2D2D") : Color(hex: "CCCCCC"))
                    .cornerRadius(26)
            }
        }
        .disabled(!canPost || isPosting)
        .padding(.top, 24)
    }
    
    // MARK: - Computed Properties
    private var canPost: Bool {
        !title.isEmpty && !temperature.isEmpty && !locationName.isEmpty && agreedToShare
    }
    
    // MARK: - Methods
    private func setupInitialData() {
        locationManager.requestLocation()
    }
    
    private func fetchLocationAndWeather(_ location: CLLocation) async {
        // Get location name
        let geocoder = CLGeocoder()
        if let placemark = try? await geocoder.reverseGeocodeLocation(location).first {
            let city = placemark.locality ?? placemark.administrativeArea ?? ""
            let ward = placemark.subLocality ?? ""
            await MainActor.run {
                locationName = "\(city)\(ward)"
            }
        }
        
        // Get weather
        await weatherService.fetchAndUpdate(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        
        // Set temperature and weather
        await MainActor.run {
            if let temp = weatherService.getCurrentTemperature() {
                temperature = String(Int(temp))
            }
            if let weather = getCurrentWeatherCondition() {
                selectedWeather = weather
            }
        }
    }
    
    private func getCurrentWeatherCondition() -> PostWeather? {
        guard let weatherData = weatherService.currentWeather,
              let current = weatherData.srf.first else {
            return nil
        }
        return PostWeather.from(current.weatherCondition)
    }
    
    private func createPost() {
        guard let user = authService.currentUser,
              let userId = authService.user?.uid else {
            errorMessage = "ユーザー情報の取得に失敗しました"
            return
        }
        
        guard let temp = Int(temperature) else {
            errorMessage = "気温を入力してください"
            return
        }
        
        isPosting = true
        errorMessage = ""
        
        let postLocation = PostLocation(
            name: locationName,
            latitude: useCurrentLocation ? locationManager.location?.coordinate.latitude : selectedLocation?.latitude,
            longitude: useCurrentLocation ? locationManager.location?.coordinate.longitude : selectedLocation?.longitude
        )
        
        Task {
            do {
                _ = try await PostService.shared.createPost(
                    userId: userId,
                    image: selectedImage,
                    title: title,
                    caption: caption,
                    weather: selectedWeather,
                    temperature: temp,
                    location: postLocation,
                    userGender: user.gender ?? "未設定",
                    userAge: user.age ?? 0,
                    userHeight: user.height ?? 0
                )
                
                await MainActor.run {
                    isPosting = false
                    showingSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isPosting = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    NewPostDetailView(selectedImage: UIImage(systemName: "photo")!)
        .environmentObject(AuthService())
}
