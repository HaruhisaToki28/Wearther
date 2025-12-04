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
            Text(advice.title)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)
            
            Text(advice.description)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .lineSpacing(4)
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



