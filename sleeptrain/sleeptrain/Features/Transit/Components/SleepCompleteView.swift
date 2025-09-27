//
//  SleepCompleteView.swift
//  sleeptrain
//
//  Created by Gojaehyun on 12/19/25.
//

import SwiftUI
import SwiftData

struct SleepCompleteView: View {
    let sleepDuration: String
    let streakCount: Int
    let isSuccessful: Bool
    let onGoHome: () -> Void
    
    @Query private var userSettings: [UserSettings]
    @StateObject private var trainTicketViewModel = TrainTicketViewModel()
    
    private var greetingText: String {
        isSuccessful ? "좋은 아침입니다" : "운행이 종료되었어요"
    }
    
    private var subText: String {
        isSuccessful ? "\(sleepDuration) 수면 운행 완료" : "내일은 꼭 성공하길 바라요"
    }
    
    var body: some View {
        ZStack {
            Image("MainBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                TrainTicketView()
                    .environmentObject(trainTicketViewModel)
                    .padding(.horizontal, 16)
                
                VStack(spacing: 8) {
                    Text(greetingText)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(subText)
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                PrimaryButton(buttonText: "홈으로", action: onGoHome)
                    .padding(.bottom, 32)
            }
        }
        .onAppear {
            if let settings = userSettings.first {
                trainTicketViewModel.configure(with: settings)
            }
        }
    }
}

#Preview {
    SleepCompleteView(
        sleepDuration: "8시간",
        streakCount: 32,
        isSuccessful: true,
        onGoHome: {}
    )
    .modelContainer(for: [UserSettings.self], inMemory: true)
}
