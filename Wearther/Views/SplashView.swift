//
//  SplashView.swift
//  Wearther
//
//  Created by Wearther on 2025/12/19.
//

import SwiftUI

struct SplashView: View {
    let loadingStatus: String
    
    var body: some View {
        ZStack {
            // Background
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Logo
                HStack(alignment: .bottom, spacing: 1.5) {
                    // WEA / THE text
                    VStack(alignment: .center, spacing: -11) {
                        Text("WEA")
                            .font(.system(size: 60, weight: .bold))
                            .tracking(-3) // -5% letter spacing
                        Text("THE")
                            .font(.system(size: 60, weight: .bold))
                    }
                    .foregroundColor(.black)
                    
                    // R image
                    Image("SplashR")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 112)
                        .offset(y: -10)
                }
                
                // Loading Status
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.0)
                        .tint(Color(hex: "2D2D2D"))
                    
                    Text(loadingStatus)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "68717B"))
                        .animation(.easeInOut(duration: 0.2), value: loadingStatus)
                }
            }
        }
    }
}

#Preview {
    SplashView(loadingStatus: "認証情報を確認中...")
}

