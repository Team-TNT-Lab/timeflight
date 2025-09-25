//
//  NfcTagExampleView.swift
//  sleeptrain
//
//  Created by bishoe01 on 9/23/25.
//

import SwiftData
import SwiftUI

struct NfcTagExampleView: View {
    let onNext: () -> Void
    @State var noCardAlert: Bool = false
    init(_ onNext: @escaping () -> Void) {
        self.onNext = onNext
    }

    @Environment(\.modelContext) private var modelContext
    @Query private var userSettings: [UserSettings]
    @State private var isImageVisible = false
    let nfcScanManager = NFCManager()

    var body: some View {
        ZStack {
            Color.clear
                .background(.onBoardingBackground2)

            VStack {
                Spacer().frame(height: 40)
                VStack(spacing: 14) {
                    Text("이제 카드를 등록해볼까요?").font(.system(size: 26, weight: .semibold))
                    Text("아이폰의 상단 부분에 카드를 태그하면 돼요")
                        .font(.system(size: 17, weight: .thin))
                }
                Spacer()
                Image("NfcTagImage").resizable().scaledToFit().opacity(isImageVisible ? 1 : 0)
                    .onAppear {
                        withAnimation(.easeIn(duration: 1.0)) {
                            isImageVisible = true
                        }
                    }
                Spacer()
                VStack(spacing: 17) {
                    PrimaryButton(buttonText: "카드 등록하기") {
                        nfcScanManager.startNFCScan(alertMessage: "카드 태그 완료!") { _ in
                            onNext()
                        }
                    }
                    Button {
                        noCardAlert.toggle()
                    } label: {
                        Text("아직 카드가 없어요")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.white)
                            .opacity(0.5)
                    }
                }.padding(.bottom, 20)
            }.alert(isPresented: $noCardAlert) {
                Alert(
                    title: Text("드림카드 없이 진행")
                        .font(.system(size: 17, weight: .semibold)),
                    message: Text("카드가 없어도 앱 사용이 가능해요.\n나중에 설정에서 등록할 수 있어요.")
                        .font(.system(size: 17, weight: .regular)),
                    primaryButton: .default(
                        Text("진행하기"),
                        action: {
                            onNext()
                        }
                    ),
                    secondaryButton: .cancel(
                        Text("취소"),
                        action: {
                            noCardAlert.toggle()
                        }
                    )
                )
            }
        }
    }
}

#Preview {
    NfcTagExampleView { print("hi") }
}
