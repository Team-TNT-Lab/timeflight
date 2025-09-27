//
//  CheckIn.swift
//  sleeptrain
//
//  Created by bishoe01 on 9/27/25.
//

import SwiftData
import SwiftUI

struct CheckInData {
    let startTimeText: String
    let context: ModelContext
    let updateSleepCount: (Int) -> Void

    init(startTimeText: String, context: ModelContext, updateSleepCount: @escaping (Int) -> Void) {
        self.startTimeText = startTimeText
        self.context = context
        self.updateSleepCount = updateSleepCount
    }
}
