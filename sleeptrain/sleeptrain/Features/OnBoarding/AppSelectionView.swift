//
//  AppSelectionView.swift
//  sleeptrain
//
//  Created by bishoe01 on 9/23/25.
//

import FamilyControls
import SwiftUI

struct AppSelectionView: View {
    let onNext: () -> Void
    init(_ onNext: @escaping () -> Void) {
        self.onNext = onNext
    }

    @EnvironmentObject var screenTimeManager: ScreenTimeManager
    var body: some View {
        VStack {
            FamilyActivityPicker(selection: $screenTimeManager.selection)

        }.safeAreaInset(edge: .bottom) {
            PrimaryButton(buttonText: "다음") {
                onNext()
            }
        }
    }
}

#Preview {
    AppSelectionView { print("HI") }
}
