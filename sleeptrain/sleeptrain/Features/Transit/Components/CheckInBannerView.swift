import SwiftUI
import LocalAuthentication  // Face ID

struct CheckInBannerView: View {
    // MARK: - Properties
    
    let remainingTimeText: String
    let startTimeText: String
    let endTimeText: String
    let hasCheckedInToday: Bool
    let performCheckIn: () -> Void
    let performCheckOut: () -> Void
    let performEmergencyStop: (() -> Void)?
    let isGuestUser: Bool
    
    // MARK: - State Objects & State Variables
    
    @StateObject private var nfcScanManager = NFCManager()
    @State private var showEmergencyStopAlert = false
    @State private var showFaceIDAlert = false
    @State private var didEmergencyStop: Bool = false
    @State private var isCheckInModeActive = false
    @State private var showAppUnlockToast = false

    // MARK: - Computed Properties
    
    private var timeUntilWakeUp: String {
        remainingTimeToArrival(fromNow: Date(), endTimeText: endTimeText)
    }
    
    private var didTrainArrive: Bool {
        let comps = endTimeText.split(separator: ":")
        guard comps.count == 2,
              let h = Int(comps[0]),
              let m = Int(comps[1]) else {
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
    
    // MARK: - Initialization
    
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
    
    // MARK: - Subviews
    
    private var headerTextSection: some View {
        Group {
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
    }

    private var toastMessage: some View {
        Group {
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
    }

    private var checkInButton: some View {
        Button(action: {
            if hasCheckedInToday {
                showEmergencyStopAlert = true
            } else {
                if isGuestUser {
                    authenticateWithFaceID()
                } else {
                    nfcScanManager.startNFCScan(alertMessage: "기기를 드림카드에 태그해주세요") { message in
                        if message == "\u{02}enwake" {
                            performCheckIn()
                            isCheckInModeActive = true
                        }
                    }
                }
            }
        }) {
            Text(hasCheckedInToday ? "운행 종료하기" : "지금 출발하기")
                .font(.system(size: 18, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    hasCheckedInToday
                    ? Color.white
                    : (canCheckIn(remainingTimeText: remainingTimeText, hasCheckedInToday: hasCheckedInToday) ? Color.white : Color.gray.opacity(0.3))
                )
                .foregroundColor(
                    hasCheckedInToday
                    ? .black
                    : (canCheckIn(remainingTimeText: remainingTimeText, hasCheckedInToday: hasCheckedInToday) ? .black : .secondary)
                )
                .cornerRadius(99)
        }
        .disabled(!hasCheckedInToday ? !canCheckIn(remainingTimeText: remainingTimeText, hasCheckedInToday: hasCheckedInToday) : false)
        .padding(.top, hasCheckedInToday ? 200 : 80)
        .padding(.horizontal, 16)
    }

    private var temporaryUnlockButton: some View {
        Group {
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
    }
    
    // MARK: - View
    
    var body: some View {
        VStack(spacing: 4) {
            headerTextSection
            toastMessage
            checkInButton
            temporaryUnlockButton
        }
        .alert("운행을 종료하시겠어요?", isPresented: $showEmergencyStopAlert) {
            Button("운행 종료하기", role: .destructive) {
                if isGuestUser {
                    authenticateWithFaceIDForCheckOut()
                    isCheckInModeActive = true
                } else {
                    nfcScanManager.startNFCScan(alertMessage: "기기를 드림카드에 태그해주세요") { message in
                        if message == "\u{02}enwake" {
                            performCheckOut()
                            isCheckInModeActive = true
                        }
                    }
                }
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
            Button("취소", role: .cancel) { }
        }
    }
    
    // MARK: - Face ID Authentication Methods
    
    private func authenticateWithFaceID() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "수면 체크인을 위해 Face ID 인증이 필요합니다."
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
                DispatchQueue.main.async {
                    if success {
                        performCheckIn()
                        isCheckInModeActive = true
                    } else {
                        print("Face ID 인증 실패")
                    }
                }
            }
        } else {
            performCheckIn()
            isCheckInModeActive = true
        }
    }

    private func authenticateWithFaceIDForCheckOut() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "운행 종료를 위해 Face ID 인증이 필요합니다."
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
                DispatchQueue.main.async {
                    if success {
                        performCheckOut()
                        isCheckInModeActive = true
                    } else {
                        print("Face ID 인증 실패")
                    }
                }
            }
        } else {
            performCheckOut()
            isCheckInModeActive = true
        }
    }
}

// MARK: - 도착까지 남은 시간 계산(자정 넘김 고려)
private func remainingTimeToArrival(fromNow now: Date, endTimeText: String) -> String {
    let comps = endTimeText.split(separator: ":")
    guard comps.count == 2,
          let h = Int(comps[0]),
          let m = Int(comps[1]) else {
        return ""
    }
    let cal = Calendar.current
    let startOfToday = cal.startOfDay(for: now)
    var arrival = cal.date(bySettingHour: h, minute: m, second: 0, of: startOfToday) ?? now
    if arrival <= now {
        arrival = cal.date(byAdding: .day, value: 1, to: arrival) ?? arrival
    }
    let diff = cal.dateComponents([.hour, .minute], from: now, to: arrival)
    let hours = max(0, diff.hour ?? 0)
    let minutes = max(0, diff.minute ?? 0)
    if hours > 0 && minutes > 0 {
        return "\(hours)시간 \(minutes)분"
    } else if hours > 0 {
        return "\(hours)시간"
    } else {
        return "\(minutes)분"
    }
}
