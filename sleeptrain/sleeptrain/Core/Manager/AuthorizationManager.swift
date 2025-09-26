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
    
    init() {
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        Task {
            let status = authorizationCenter.authorizationStatus
            self.isAuthorized = status == .approved
        }
    }
    
    func requestAuthorization() {
        Task {
            do {
                try await authorizationCenter.requestAuthorization(for: .individual)
                checkAuthorizationStatus()
            } catch {
                throw AuthError.requestFailed
            }
        }
    }
}
