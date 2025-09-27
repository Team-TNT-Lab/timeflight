//
//  BiometricAuthManager.swift
//  sleeptrain
//
//  Created by bishoe01 on 9/27/25.
//

import LocalAuthentication

@MainActor
final class BiometricAuthManager {
    static let shared = BiometricAuthManager()
    private init() {}

    func authenticate(reason: String, onSuccess: @escaping () -> Void, onFailure: (() -> Void)? = nil) {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
                DispatchQueue.main.async {
                    success ? onSuccess() : onFailure?()
                }
            }
        } else {
            onSuccess()
        }
    }
}
