//
//  FashionAdviceCard.swift
//  Wearther
//
//  Created by hato on 2025/11/07.
//

import SwiftUI

struct FashionAdviceCard: View {
    let advice: FashionAdvice
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack{
                Spacer()
                Text(advice.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(red: 0x2D/255, green: 0x2D/255, blue: 0x2D/255))
                Spacer()
            }
            Text(advice.description)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineSpacing(1)
                .padding(.horizontal, 50)
        }
        
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    FashionAdviceCard(
        advice: FashionAdvice(
            title: "コートやセーターを重ね着して暖かく",
            description: "風を通しにくいアウターやニットなど熱を逃さないアイテムを取り入れて暖かさをキープしましょう"
        )
    )
    .padding()
}



