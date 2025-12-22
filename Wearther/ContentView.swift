//
//  ContentView.swift
//  Wearther
//
//  Created by 阿久津咲千 on 2025/12/17.
//
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @State private var isShowingSplash = true
    
    var body: some View {
        ZStack {
            Group {
                if authService.isAuthenticated {
                    MainTabView()
                } else {
                    SignInView()
                }
            }
            
            // Splash Screen
            if isShowingSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            // Show splash for 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.5)) {
                    isShowingSplash = false
                }
            }
        }
    }
}
