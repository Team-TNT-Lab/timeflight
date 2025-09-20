//
//  TimeSettingView.swift
//  timeflight
//
//  Created by bishoe01 on 9/20/25.
//

import SwiftUI

// 1. 평일,주말 수면 시간 설정 여부
// 2. 평일 세팅
// 3. 주말 세팅
struct TimeSettingView: View {
    var body: some View {
        VStack {
            Text("평일 수면 시간을 설정해주세요")
                .font(.system(size: 24))
            Text("평균 7시간 이상의 수면을 추천해요")
                .opacity(0.4)

            Spacer()

            Button("다음") {
                print("E")
            }
            .font(.system(size: 20))
            .foregroundColor(Color.black)
            .frame(height: 54)
            .frame(maxWidth: .infinity)
            .background(Color.gray)
            .cornerRadius(15)
        }
        .padding(.all, 20)
    }
}

#Preview {
    TimeSettingView()
}
