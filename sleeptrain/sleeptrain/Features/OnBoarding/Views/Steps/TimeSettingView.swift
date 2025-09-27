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
    @State private var showingValidationAlert: Bool = false
    @State private var validationMessage: String = ""

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
                        VStack(spacing: 4) {
                            Text("잠드는 시간")
                                .font(.subTitle)
                                .foregroundStyle(.white.opacity(0.8))
                            Text("오후 8시 ~ 새벽 2시")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                        }

                        Button {
                            isShowingBedTimePicker = true
                        } label: {
                            TimeDisplayCard(time: bedTime)
                        }
                    }

                    VStack(spacing: 15) {
                        VStack(spacing: 4) {
                            Text("일어나는 시간")
                                .font(.subTitle)
                                .foregroundStyle(.white.opacity(0.8))
                            Text("새벽 3시 ~ 오후 2시")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                        }

                        Button {
                            isShowingWakeTimePicker = true
                        } label: {
                            TimeDisplayCard(time: wakeTime)
                        }
                    }
                    Spacer()
                    VStack(spacing: 8) {
                        Text(sleepDurationText)
                            .font(.subTitle)
                            .foregroundStyle(isValidTimeSettings ? .white.opacity(0.6) : .red.opacity(0.8))

                        if !isValidTimeSettings {
                            Text("최소 4시간 이상 자야 해요")
                                .font(.caption)
                                .foregroundStyle(.red.opacity(0.7))
                        }
                    }
                }
            }
            .padding(.all, 20)
        }
        .toolbar(hideTabBar ? .hidden : .visible, for: .tabBar)
        .safeAreaInset(edge: .bottom, content: {
            VStack(spacing: 0) {
                Spacer().frame(height: 20)
                PrimaryButton(buttonText: LocalizedStringKey(buttonText)) {
                    if validateTimeSettings() {
                        saveTimeSettings()
                    }
                }
                .disabled(!isValidTimeSettings)
                .opacity(isValidTimeSettings ? 1.0 : 0.6)
            }
        })
        .onAppear {
            loadExistingSettings()
        }
        .sheet(isPresented: $isShowingBedTimePicker) {
            TimePickerSheetWrapper(
                isPresented: $isShowingBedTimePicker,
                date: bedTime,
                setDate: { bedTime = $0 },
                isForBedTime: true
            )
        }
        .sheet(isPresented: $isShowingWakeTimePicker) {
            TimePickerSheetWrapper(
                isPresented: $isShowingWakeTimePicker,
                date: wakeTime,
                setDate: { wakeTime = $0 },
                isForWakeTime: true
            )
        }
        .alert("시간 설정 오류", isPresented: $showingValidationAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(validationMessage)
        }
    }

    private var sleepDurationText: String {
        SleepTimeCalculator.calculateSleepDuration(bedTime: bedTime, wakeTime: wakeTime)
    }

    private var isValidTimeSettings: Bool {
        return SleepTimeCalculator.isValidSleepDuration(bedTime: bedTime, wakeTime: wakeTime) &&
            SleepTimeCalculator.isTimeInBedTimeRange(bedTime) &&
            SleepTimeCalculator.isTimeInWakeTimeRange(wakeTime)
    }

    private func loadExistingSettings() {
        if let settings = userSettings.first {
            // 기존 설정이 유효한지 확인하고 필요시 조정
            let existingBedTime = settings.targetDepartureTime
            let existingWakeTime = settings.targetArrivalTime

            // 자는 시간 유효성 검증 및 조정
            if SleepTimeCalculator.isTimeInBedTimeRange(existingBedTime) {
                bedTime = existingBedTime
            } else {
                // 유효하지 않으면 기본값으로 설정
                bedTime = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date()) ?? Date()
            }

            // 일어나는 시간 유효성 검증 및 조정
            if SleepTimeCalculator.isTimeInWakeTimeRange(existingWakeTime) {
                wakeTime = existingWakeTime
            } else {
                // 유효하지 않으면 기본값으로 설정
                wakeTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
            }
        } else {
            // 기본값을 제약 조건에 맞게 설정
            bedTime = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date()) ?? Date()
            wakeTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
        }
    }

    private func validateTimeSettings() -> Bool {
        // 자는 시간 범위
        if !SleepTimeCalculator.isTimeInBedTimeRange(bedTime) {
            validationMessage = "자는 시간은 오후 8시부터 새벽 2시 사이에 설정해주세요."
            showingValidationAlert = true
            return false
        }

        // 일어나는 시간 범위
        if !SleepTimeCalculator.isTimeInWakeTimeRange(wakeTime) {
            validationMessage = "일어나는 시간은 새벽 3시부터 오후 2시 사이에 설정해주세요."
            showingValidationAlert = true
            return false
        }

        // 최소 수면 시간
        if !SleepTimeCalculator.isValidSleepDuration(bedTime: bedTime, wakeTime: wakeTime) {
            validationMessage = "최소 4시간 이상의 수면 시간이 필요해요."
            showingValidationAlert = true
            return false
        }

        return true
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
