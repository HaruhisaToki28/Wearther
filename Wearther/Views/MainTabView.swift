//
//  MainTabView.swift
//  Wearther
//
//  Created by hato on 2025/11/07.
//

import SwiftUI

enum Tab: String, CaseIterable {
    case home
    case weather
    case camera
    case clothes
    case profile
    
    var symbol: String {
        switch self {
        case .home: return "house"
        case .weather: return "cloud.sun"
        case .camera: return "camera"
        case .clothes: return "tshirt"
        case .profile: return "person"
        }
    }
    
    var filledSymbol: String {
        switch self {
        case .home: return "house.fill"
        case .weather: return "cloud.sun.fill"
        case .camera: return "camera.fill"
        case .clothes: return "tshirt.fill"
        case .profile: return "person.fill"
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    
    var body: some View {
        VStack(spacing: 0) {
            // Content View
            ZStack {
                switch selectedTab {
                case .home:
                    HomeView()
                case .weather:
                    WeatherView()
                case .camera:
                    Text("Camera View")
                case .clothes:
                    Text("Clothes View")
                case .profile:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom Tab Bar
            VStack(spacing: 0) {
                Divider()
                    .background(Color(red: 0.87, green: 0.87, blue: 0.87)) // #DEDEDE 仕切り線の色
                    .frame(height: 0.05) // 仕切り線の太さ
                
                HStack(spacing: 48) { // アイコン間の間隔
                    ForEach(Tab.allCases, id: \.self) { tab in
                        Button(action: {
                            selectedTab = tab
                        }) {
                            Image(systemName: selectedTab == tab ? tab.filledSymbol : tab.symbol)
                                .font(.system(size: 23)) // アイコンサイズ
                                .foregroundColor(.black) // アイコンの色
                                .frame(width: 30, height: 30) // タップ領域のサイズ
                        }
                    }
                }
                .padding(.top, 10) // アイコン上の余白
                .padding(.bottom, 25) // アイコン下の余白（SafeArea分も考慮）
                .frame(maxWidth: .infinity)
                .background(Color.white) // タブバーの背景色
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    MainTabView()
}

