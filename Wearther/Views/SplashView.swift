//
//  SplashView.swift
//  Wearther
//
//  Created by Wearther on 2025/12/19.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            // Background
            Color.white
                .ignoresSafeArea()
            
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
        }
    }
}

#Preview {
    SplashView()
}

