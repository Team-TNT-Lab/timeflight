//
//  TransitView.swift
//  sleeptrain
//
//  Created by bishoe01 on 9/27/25.
//

import Foundation
import SwiftData
import SwiftUI

struct TransitView: View {
    @Query private var userSettings: [UserSettings]

    @StateObject private var trainTicketViewModel = TrainTicketViewModel()
    @StateObject private var homeViewModel = TransitViewModel()
    @Environment(\.modelContext) private var modelContext
    
    @State private var isCheckInModeActive = false
    @State private var showSleepComplete = false
    @State private var sleepCompleteData: (duration: String, streak: Int, isSuccessful: Bool)?
    @State private var wakeUpTimer: Timer?
    
    private var isCheckedInToday: Bool {
        return userSettings.first?.isSleeping ?? false
    }
    
    // 수면 시간 계산
    private var sleepDuration: String {
        guard let settings = userSettings.first else { return "0시간" }
        let minutes = SleepTimeCalculator.calculateSleepMinutes(
            bedTime: settings.targetDepartureTime,
            wakeTime: settings.targetArrivalTime
        )
        let hours = minutes / 60
        return "\(hours)시간"
    }
    
    private var todayDateString: String {
        DateFormatting.monthDayKoreanString()
    }
    
    var body: some View {
        ZStack {
            Color.clear
                .background(.mainContainerBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                HStack {
                    Text("운행 일정")
                        .font(.mainTitle)
                        .foregroundColor(.white)
                    Text(todayDateString)
                        .font(.subTitle)
                        .foregroundColor(.white.opacity(0.6))
                    Spacer(minLength: 0)
                }.padding(.all, 12)
                
                TrainTicketView()
                    .environmentObject(trainTicketViewModel)
                    .padding(.horizontal, 16)
                
                if !isCheckedInToday {
                    StreakWeekView(days: homeViewModel.weekDays)
                        .padding(.horizontal, 16)
                }
                
                CheckInBannerView(
                    remainingTimeText: trainTicketViewModel.remainingTimeText,
                    startTimeText: trainTicketViewModel.startTimeText,
                    endTimeText: trainTicketViewModel.endTimeText,
                    hasCheckedInToday: isCheckedInToday,
                    performCheckIn: {
                        let checkInData = CheckInData(
                            startTimeText: trainTicketViewModel.startTimeText,
                            context: modelContext,
                            updateSleepCount: { newSleepCount in
                                trainTicketViewModel.sleepCount = newSleepCount
                                isCheckInModeActive = true
                            }
                        )
                        homeViewModel.performCheckIn(with: checkInData)
                    },
                    performCheckOut: {
                        homeViewModel.performCheckOut(context: modelContext)
                        isCheckInModeActive = false
                        
                        // 운행 종료 시에도 완료 화면 표시(다만 실패임)
                        let currentStreak = homeViewModel.getCurrentStreak(context: modelContext)
                        sleepCompleteData = (
                            duration: sleepDuration,
                            streak: currentStreak,
                            isSuccessful: false
                        )
                        showSleepComplete = true
                    },
                    isGuestUser: userSettings.first?.isGuestUser ?? true
                )
            }
        }
        .onAppear {
            if let settings = userSettings.first {
                trainTicketViewModel.configure(with: settings)
            }
            
            homeViewModel.updateTrainState(
                remainingTimeText: trainTicketViewModel.remainingTimeText,
                isTrainDeparted: trainTicketViewModel.isTrainDeparted
            )

            homeViewModel.refreshDisplayDays(context: modelContext)
            
            startAutoWakeUpChecker()
        }
        .onChange(of: userSettings) { _, newSettings in
            if let settings = newSettings.first {
                trainTicketViewModel.configure(with: settings)
            }
        }
        .onDisappear {
            stopAutoWakeUpChecker()
        }
        .fullScreenCover(isPresented: $showSleepComplete) {
            if let data = sleepCompleteData {
                SleepCompleteView(
                    sleepDuration: data.duration,
                    streakCount: data.streak,
                    isSuccessful: data.isSuccessful,
                    onGoHome: {
                        showSleepComplete = false
                        sleepCompleteData = nil
                    }
                )
            }
        }
    }
    
    func refreshAll() {
        homeViewModel.refreshAll(context: modelContext) { currentStreak in
            trainTicketViewModel.sleepCount = currentStreak
        }
    }
    
    private func startAutoWakeUpChecker() {
        wakeUpTimer?.invalidate()
        
        wakeUpTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            checkAndAutoWakeUp()
        }
    }
    
    private func stopAutoWakeUpChecker() {
        wakeUpTimer?.invalidate()
        wakeUpTimer = nil
    }
    
    private func checkAndAutoWakeUp() {
        guard let settings = userSettings.first,
              settings.isSleeping else { return }
        
        let now = Date()
        let wakeTime = settings.targetArrivalTime
        
        if now >= wakeTime {
            let currentStreak = homeViewModel.getCurrentStreak(context: modelContext)
            
            homeViewModel.wakeUp(context: modelContext)
            
            stopAutoWakeUpChecker()
            
            sleepCompleteData = (
                duration: sleepDuration,
                streak: currentStreak,
                isSuccessful: true
            )

                        showSleepComplete = true
        }
    }
}
