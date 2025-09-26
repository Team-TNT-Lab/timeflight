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
    @StateObject private var userSettingsManager = UserSettingsManager()
    @State private var isImageVisible = false
    let nfcScanManager = NFCManager()

    var body: some View {
        ZStack {
            Color.clear
                .background(.onBoardingBackground2)

            VStack {
                Spacer().frame(height: 40)
                VStack(spacing: 14) {
                    Text("이제 카드를 등록해볼까요?")
                        .font(.mainTitle)
                    Text("아이폰의 상단 부분에 카드를 태그하면 돼요")
                        .font(.subTitle)
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
                            toggleGuestUSer()
                        }
                    }
                    Button {
                        noCardAlert.toggle()
                    } label: {
                        Text("아직 카드가 없어요")
                            .font(.subTitle)
                            .foregroundStyle(Color.white)
                            .opacity(0.5)
                    }
                }.padding(.bottom, 20)
            }.alert(isPresented: $noCardAlert) {
                Alert(
                    title: Text("드림카드 없이 진행")
                        .font(.subTitleEmphasized),
                    message: Text("카드가 없어도 앱 사용이 가능해요.\n나중에 설정에서 등록할 수 있어요.")
                        .font(.subTitle),
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

    private func toggleGuestUSer() {
        do {
            try userSettingsManager.ToggleGuestUser(context: modelContext, userSettings: userSettings)
            onNext()
        } catch {
            print("게스트 유저 토글 실패 \(error)")
        }
    }
}

#Preview {
    NfcTagExampleView { print("hi") }
}
