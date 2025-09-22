//
//  Stats.swift
//  sleeptrain
//
//  Created by 양시준 on 9/23/25.
//

import SwiftData

@Model
final class Stats {
    var streak: Int
    
    init(streak: Int = 0) {
        self.streak = streak
    }
}
