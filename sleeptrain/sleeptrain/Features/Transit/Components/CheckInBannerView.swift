import SwiftUI

struct CheckInBannerView: View {
    let remainingTimeText: String
    let startTimeText: String
    let endTimeText: String
    let hasCheckedInToday: Bool
    let performCheckIn: () -> Void
    let performCheckOut: () -> Void
    let performEmergencyStop: (() -> Void)?
    let isGuestUser: Bool

    @StateObject private var nfcScanManager = NFCManager()
    @State private var showEmergencyStopAlert = false
    @State private var showFaceIDAlert = false
    @State private var didEmergencyStop: Bool = false
    @State private var isCheckInModeActive = false
    @State private var showAppUnlockToast = false

    private var isCheckInEnabled: Bool {
        canCheckIn(remainingTimeText: remainingTimeText, hasCheckedInToday: hasCheckedInToday)
    }

    private var timeUntilWakeUp: String {
        DateFormatting.remainingTimeToArrival(fromNow: Date(), endTimeText: endTimeText)
    }

    private var didTrainArrive: Bool {
        let comps = endTimeText.split(separator: ":")
        guard comps.count == 2,
              let h = Int(comps[0]),
              let m = Int(comps[1])
        else {
            return false
        }
        let cal = Calendar.current
        let startOfToday = cal.startOfDay(for: Date())
        var arrivalTime = cal.date(bySettingHour: h, minute: m, second: 0, of: startOfToday)!

        if arrivalTime <= Date() {
            arrivalTime = cal.date(byAdding: .day, value: 1, to: arrivalTime)!
        }

        return Date() > arrivalTime
    }

    init(
        remainingTimeText: String,
        startTimeText: String,
        endTimeText: String,
        hasCheckedInToday: Bool,
        performCheckIn: @escaping () -> Void,
        performCheckOut: @escaping () -> Void = {},
        performEmergencyStop: (() -> Void)? = nil,
        isGuestUser: Bool = true
    ) {
        self.remainingTimeText = remainingTimeText
        self.startTimeText = startTimeText
        self.endTimeText = endTimeText
        self.hasCheckedInToday = hasCheckedInToday
        self.performCheckIn = performCheckIn
        self.performCheckOut = performCheckOut
        self.performEmergencyStop = performEmergencyStop
        self.isGuestUser = isGuestUser
    }

    var body: some View {
        VStack(spacing: 4) {
            headerTextSection
            toastMessage
            checkInButton
            temporaryUnlockButton
        }
        .alert("운행을 종료하시겠어요?", isPresented: $showEmergencyStopAlert) {
            Button("운행 종료하기", role: .destructive) {
                authorize(
                    reason: "운행 종료를 위해 Face ID 인증이 필요합니다.",
                    onSuccess: {
                        performCheckOut()
                        isCheckInModeActive = true
                    }
                )
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("지금 멈추면 연속 기록이 사라져요.")
        }
        .alert("Face ID 인증", isPresented: $showFaceIDAlert) {
            Button("확인") {
                performCheckIn()
                isCheckInModeActive = true
            }
            Button("취소", role: .cancel) {}
        }
    }

    @ViewBuilder
    private var headerTextSection: some View {
        if hasCheckedInToday && !didTrainArrive {
            VStack(spacing: 8) {
                Text("열차 도착까지 \(timeUntilWakeUp) 남았어요")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(9.6)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 150)

                Text("잠이 오지 않으면 눈을 감고만 있어도 괜찮아요")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6.4)
                    .frame(maxWidth: .infinity)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } else {
            VStack(spacing: 8) {
                Text(makeInfoBannerText(
                    remainingTimeText: remainingTimeText,
                    startTimeText: startTimeText
                ))
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(9.6)
                .frame(maxWidth: .infinity)
                .padding(.top, 80)

                if let sub = makeInfoSubText(remainingTimeText: remainingTimeText, isEmergencyStop: didEmergencyStop) {
                    Text(sub)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6.4)
                        .frame(maxWidth: .infinity)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    @ViewBuilder
    private var toastMessage: some View {
        if showAppUnlockToast {
            Text("앱 잠금이 3분간 해제되었어요")
                .font(.footnote)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.black)
                .cornerRadius(12)
                .padding(.top, 8)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: showAppUnlockToast)
        }
    }

    @ViewBuilder
    private var checkInButton: some View {
        Button(action: {
            if hasCheckedInToday {
                showEmergencyStopAlert = true
            } else {
                authorize(
                    reason: "수면 체크인을 위해 Face ID 인증이 필요합니다.",
                    onSuccess: {
                        performCheckIn()
                        isCheckInModeActive = true
                    }
                )
            }
        }) {
            Text(hasCheckedInToday ? "운행 종료하기" : "지금 출발하기")
                .font(.system(size: 18, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    hasCheckedInToday
                        ? Color.white
                        : (isCheckInEnabled ? Color.white : Color.gray.opacity(0.3))
                )
                .foregroundColor(
                    hasCheckedInToday
                        ? .black
                        : (isCheckInEnabled ? .black : .secondary)
                )
                .cornerRadius(99)
        }
        .disabled(!hasCheckedInToday ? !isCheckInEnabled : false)
        .padding(.top, hasCheckedInToday ? 200 : 80)
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var temporaryUnlockButton: some View {
        if hasCheckedInToday {
            Button(action: {
                isCheckInModeActive = false
                showAppUnlockToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    showAppUnlockToast = false
                }
            }) {
                Text("앱 잠시 사용하기")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.subheadline)
                    .padding(.top, 8)
            }
        }
    }

    private func authorize(reason: String, onSuccess: @escaping () -> Void) {
        if isGuestUser {
            BiometricAuthManager.shared.authenticate(
                reason: reason,
                onSuccess: onSuccess,
                onFailure: {
                    print("인증 실패")
                }
            )
        } else {
            nfcScanManager.startNFCScan(alertMessage: "기기를 드림카드에 태그해주세요") { message in
                if message == "\u{02}enwake" {
                    onSuccess()
                }
            }
        }
    }
}
