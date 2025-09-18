//
//  ContentView.swift
//  timeflight
//
//  Created by bishoe01 on 9/18/25.
//

import FamilyControls
import SwiftUI

struct ContentView: View {
    @State var selection = FamilyActivitySelection()

    var body: some View {
        Text("TIME FLIGHT")
        FamilyActivityPicker(selection: $selection)
        Button("HI") {
            print(selection.applicationTokens.count)
            print(selection.categories.count)
        }
    }
}

#Preview {
    ContentView()
}
