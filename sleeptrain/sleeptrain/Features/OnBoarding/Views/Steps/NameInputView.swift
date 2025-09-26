//
//  NameInputView.swift
//  sleeptrain
//
//  Created by bishoe01 on 9/23/25.
//

import SwiftData
import SwiftUI

struct NameInputView: View {
    let onNext: () -> Void
    @State private var name: String = ""
    @Environment(\.modelContext) private var modelContext
    @Query private var userSettings: [UserSettings]
    @StateObject private var userSettingsManager = UserSettingsManager()

    init(_ onNext: @escaping () -> Void) {
        self.onNext = onNext
    }

    var body: some View {
        ZStack {
            Color.clear
                .background(.primaryBackground)
            VStack {
                Spacer().frame(height: 40)
                Text("기관사 이름을 등록하세요")
                    .font(.mainTitle)
                Spacer()
                TextField("굿나잇", text: $name)
                    .font(.system(size: 25, weight: .medium))
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 12)
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundStyle(.white.opacity(0.85)),
                        alignment: .bottom
                    )
                    .frame(maxWidth: 200)

                Spacer()

                PrimaryButton(buttonText: "다음", action: saveName)
                    .opacity(name.count == 0 ? 0.5 : 1)
                    .disabled(name.count == 0)
            }
        }
    }

    private func saveName() {
        do {
            try userSettingsManager.saveName(name, context: modelContext, userSettings: userSettings)
            onNext()
        } catch {
            print("이름 저장 실패: \(error)")
        }
    }
}

#Preview {
    NameInputView { print("HI") }
}
