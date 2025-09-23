//
//  NfcTagExampleView.swift
//  sleeptrain
//
//  Created by bishoe01 on 9/23/25.
//

import SwiftUI

struct NfcTagExampleView: View {
    let onNext: () -> Void

    init(_ onNext: @escaping () -> Void) {
        self.onNext = onNext
    }

    let nfcScanManager = NFCManager()
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 14) {
                Text("이제 카드를 등록해볼까요?").font(.system(size: 23, weight: .semibold))
                Text("아이폰의 상단 부분에 카드를 태그하면 돼요")
                    .font(.system(size: 13, weight: .thin))
            }
            Spacer()
            Image("NfcTagImage").resizable().scaledToFit()
            Spacer()
        }.safeAreaInset(edge: .bottom) {
            VStack(spacing: 17) {
                PrimaryButton(buttonText: "카드 등록하기") {
                    nfcScanManager.startNFCScan(alertMessage: "카드 태그 완료!") { _ in
                        onNext()
                    }
                }
                Text("아직 카드가 없어요")
                    .font(.system(size: 15, weight: .medium))
                    .opacity(0.5)
            }.padding(.bottom, 20)
        }
    }
}

#Preview {
    NfcTagExampleView { print("hi") }
}
