//
//  MyUnicalApp.swift
//  MyUnical
//
//  Created by Mattia Meligeni on 13/10/24.
//

// MyUnicalApp.swift

import SwiftUI

@main
struct MyUnicalApp: App {
    @StateObject var appState = AppState()
    @ObservedObject var networkMonitor = NetworkMonitor.shared
    @ObservedObject var networkManager = NetworkManager.shared
    
    var body: some Scene {
        WindowGroup {
            if appState.isLoggedIn {
                MyUnicalTabView()
                    .environmentObject(appState)
                    .environmentObject(networkMonitor)
                    .environmentObject(networkManager)
                    .onAppear {
                        if networkMonitor.isConnected {
                            silentFetch()
                        } else {
                            print("No internet connection. Displaying cached data.")
                        }
                    }
            } else {
                LoginView()
                    .environmentObject(appState)
                    .environmentObject(networkMonitor)
            }
        }
    }
    
    /// Performs a silent fetch to update data.
    private func silentFetch() {
        let keychainService = "it.mattiameligeni.MyUnical"
        if let usernameData = KeychainHelper.shared.read(service: keychainService, account: "username"),
           let passwordData = KeychainHelper.shared.read(service: keychainService, account: "password"),
           let username = String(data: usernameData, encoding: .utf8),
           let password = String(data: passwordData, encoding: .utf8) {
            NetworkManager.shared.authenticate(username: username, password: password) { success in
                if !success {
                    // Handle failure silently, perhaps notify the user
                    print("Silent fetch failed. Showing cached data.")
                }
            }
        }
    }
}
