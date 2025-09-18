//
//  AuthorizationManager.swift
//  timeflight
//
//  Created by bishoe01 on 9/18/25.
//

import FamilyControls
import Foundation
import SwiftUI

@MainActor
class AuthorizationManager: ObservableObject {
    let authorizationCenter = AuthorizationCenter.shared
    
    @Published var isAuthorized = false
    @Published var isLoading = true
    
    init() {
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        Task {
            let status = authorizationCenter.authorizationStatus
            self.isAuthorized = status == .approved
            self.isLoading = false
            print("현재 권한 상태: \(status.rawValue)")
        }
    }
    
    func requestAuthorization() {
        Task {
            do {
                try await authorizationCenter.requestAuthorization(for: .individual)
                checkAuthorizationStatus()
                print("권한 요청 완료")
            } catch {
                throw AuthError.requestFailed
            }
        }
    }
}
