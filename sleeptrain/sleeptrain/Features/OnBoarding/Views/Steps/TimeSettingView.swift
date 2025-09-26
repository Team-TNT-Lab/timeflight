//
//  TimeSettingView.swift
//  sleeptrain
//
//  Created by bishoe01 on 9/23/25.
//

import SwiftData
import SwiftUI

struct TimeSettingView: View {
    let onNext: () -> Void
    let buttonText: String
    let hideTabBar: Bool

    @Environment(\.modelContext) private var modelContext
    @Query private var userSettings: [UserSettings]
    @StateObject private var userSettingsManager = UserSettingsManager()

    @State private var bedTime: Date = .init()
    @State private var wakeTime: Date = .init()
    @State private var isShowingBedTimePicker: Bool = false
    @State private var isShowingWakeTimePicker: Bool = false

    init(_ onNext: @escaping () -> Void, buttonText: String = "다음", hideTabBar: Bool = false) {
        self.onNext = onNext
        self.buttonText = buttonText
        self.hideTabBar = hideTabBar
    }

    var body: some View {
        ZStack {
            Color.clear
                .background(.primaryBackground)
            VStack {
                VStack(spacing: 10) {
                    Text("수면 시간을 설정해주세요")
                        .font(.mainTitleEmphasized)
                        .foregroundStyle(.white)

                    Text("평균 7시간 이상의 수면을 추천해요")
                        .font(.subTitle)
                        .foregroundStyle(.white.opacity(0.4))
                }
                Spacer()

                VStack(spacing: 50) {
                    Spacer()
                    VStack(spacing: 15) {
                        Text("잠드는 시간")
                            .font(.subTitle)
                            .foregroundStyle(.white.opacity(0.8))

                        Button {
                            isShowingBedTimePicker = true
                        } label: {
                            TimeDisplayCard(time: bedTime)
                        }
                    }

                    VStack(spacing: 15) {
                        Text("일어나는 시간")
                            .font(.subTitle)
                            .foregroundStyle(.white.opacity(0.8))

                        Button {
                            isShowingWakeTimePicker = true
                        } label: {
                            TimeDisplayCard(time: wakeTime)
                        }
                    }
                    Spacer()
                    Text(sleepDurationText)
                        .font(.subTitle)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding(.all, 20)
        }
        .toolbar(hideTabBar ? .hidden : .visible, for: .tabBar)
        .safeAreaInset(edge: .bottom, content: {
            VStack(spacing: 0) {
                Spacer().frame(height: 20)
                PrimaryButton(buttonText: LocalizedStringKey(buttonText)) {
                    saveTimeSettings()
                }
            }
        })
        .onAppear {
            loadExistingSettings()
        }
        .sheet(isPresented: $isShowingBedTimePicker) {
            TimePickerSheetWrapper(
                isPresented: $isShowingBedTimePicker,
                date: bedTime,
                setDate: { bedTime = $0 }
            )
        }
        .sheet(isPresented: $isShowingWakeTimePicker) {
            TimePickerSheetWrapper(
                isPresented: $isShowingWakeTimePicker,
                date: wakeTime,
                setDate: { wakeTime = $0 }
            )
        }
    }

    private var sleepDurationText: String {
        SleepTimeCalculator.calculateSleepDuration(bedTime: bedTime, wakeTime: wakeTime)
    }

    private func loadExistingSettings() {
        if let settings = userSettings.first {
            bedTime = settings.targetDepartureTime
            wakeTime = settings.targetArrivalTime
        } else {
            bedTime = Calendar.current.date(bySettingHour: 23, minute: 00, second: 0, of: Date()) ?? Date()
            wakeTime = Calendar.current.date(bySettingHour: 7, minute: 00, second: 0, of: Date()) ?? Date()
        }
    }

    private func saveTimeSettings() {
        do {
            try userSettingsManager.saveSchedule(
                departureTime: bedTime,
                arrivalTime: wakeTime,
                context: modelContext,
                userSettings: userSettings
            )
            onNext()
        } catch {
            print("스케줄저장실패\(error)")
        }
    }
}

#Preview {
    TimeSettingView { print("Next") }
}
