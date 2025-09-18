//
//  Coordinator.swift
//  timeflight
//
//  Created by bishoe01 on 9/18/25.
//

import Foundation

final class Coordinator: ObservableObject {
    @Published var path: [Path] = []

    func push(_ path: Path) {
        self.path.append(path)
    }

    func popLast() {
        _ = self.path.popLast()
    }

    func removeAll() {
        self.path.removeAll()
    }
}

enum Path: Hashable {
    case timerView
}
