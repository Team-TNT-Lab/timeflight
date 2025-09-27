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
                
                if !homeViewModel.hasCheckedInToday {
                    StreakWeekView(days: homeViewModel.weekDays)
                        .padding(.horizontal, 16)
                }
                
                CheckInBannerView(
                    remainingTimeText: trainTicketViewModel.remainingTimeText,
                    startTimeText: trainTicketViewModel.startTimeText,
                    endTimeText: trainTicketViewModel.endTimeText,
                    hasCheckedInToday: homeViewModel.hasCheckedInToday,
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
                        homeViewModel.performCheckOut()
                        isCheckInModeActive = false
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
        }
        .onChange(of: userSettings) { _, newSettings in
            if let settings = newSettings.first {
                trainTicketViewModel.configure(with: settings)
            }
        }
        .onChange(of: trainTicketViewModel.remainingTimeText) { _, _ in
            homeViewModel.updateTrainState(
                remainingTimeText: trainTicketViewModel.remainingTimeText,
                isTrainDeparted: trainTicketViewModel.isTrainDeparted
            )
        }
    }

    // MARK: - Helpers
    
    func refreshAll() {
        homeViewModel.refreshAll(context: modelContext) { currentStreak in
            trainTicketViewModel.sleepCount = currentStreak
        }
    }
}
