//
//  mogumogu_tradeApp.swift
//  mogumogu-trade
//
//  Created by saki on 2026/05/22.
//

import FirebaseCore
import SwiftUI

@main
struct mogumogu_tradeApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
