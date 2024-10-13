//
//  MyUnicalApp.swift
//  MyUnical
//
//  Created by Mattia Meligeni on 13/10/24.
//

import SwiftUI

@main
struct MyUnicalApp: App {
    @StateObject private var appState = AppState()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}
