// MyUnicalTabView.swift
// MyUnical
//
// Created by Mattia Meligeni on 13/10/24.
//


import SwiftUI

struct MyUnicalTabView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var networkMonitor: NetworkMonitor // Ensure NetworkMonitor is available
    @ObservedObject private var networkManager = NetworkManager.shared
    @State private var selectedTab: Int = 0
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
            TaxView()
                .tabItem {
                    Image(systemName: "dollarsign.circle.fill")
                    Text("Tasse")
                }
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Impostazioni")
                }
                .tag(2)
        }
        // Removed .onAppear { refreshData() } to prevent unnecessary data fetching
    }
}

struct MyUnicalTabView_Previews: PreviewProvider {
    static var previews: some View {
        MyUnicalTabView()
            .environmentObject(AppState())
            .environmentObject(NetworkMonitor.shared)
    }
}
