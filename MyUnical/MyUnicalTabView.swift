// MyUnicalTabView.swift
// MyUnical
//
// Created by Mattia Meligeni on 13/10/24.
//

import SwiftUI

struct MyUnicalTabView: View {
    @ObservedObject private var networkManager = NetworkManager.shared
        @State private var selectedTab: Int = 0 // Add this line
        private let keychainService = "it.mattiameligeni.MyUnical"

        var body: some View {
            TabView(selection: $selectedTab) {
                DashboardView(selectedTab: $selectedTab)
                    .tabItem {
                        Image(systemName: "house")
                        Text("Dashboard")
                    }
                    .tag(0)
                GradesView()
                    .tabItem {
                        Image(systemName: "book")
                        Text("Libretto")
                    }
                    .tag(1)
                // Other tabs...
                SettingsView()
                    .tabItem {
                        Image(systemName: "gear")
                        Text("Impostazioni")
                    }
                    .tag(2)
            }
            .onAppear {
                refreshData()
            }
        }

    private func refreshData() {
        if let usernameData = KeychainHelper.shared.read(service: keychainService, account: "username"),
           let passwordData = KeychainHelper.shared.read(service: keychainService, account: "password"),
           let username = String(data: usernameData, encoding: .utf8),
           let password = String(data: passwordData, encoding: .utf8) {
            networkManager.authenticate(username: username, password: password) { success in
                if !success {
                    // Handle authentication failure if needed
                }
            }
        }
    }
}

#Preview {
    MyUnicalTabView()
}
