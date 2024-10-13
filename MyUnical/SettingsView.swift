//
//  SettingsView.swift
//  MyUnical
//
//  Created by Mattia Meligeni on 13/10/24.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var networkMonitor: NetworkMonitor // Ensure NetworkMonitor is available
    @ObservedObject private var networkManager = NetworkManager.shared
    @State private var username: String = ""
    @State private var password: String = ""
    private let keychainService = "it.mattiameligeni.MyUnical"
    @State private var showingOfflineAlert = false

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Account")) {
                        TextField("Username", text: $username)
                            .onChange(of: username) { oldValue, newValue in
                                if let data = newValue.data(using: .utf8) {
                                    KeychainHelper.shared.save(data, service: keychainService, account: "username")
                                }
                            }
                        SecureField("Password", text: $password)
                            .onChange(of: password) { oldValue, newValue in
                                if let data = newValue.data(using: .utf8) {
                                    KeychainHelper.shared.save(data, service: keychainService, account: "password")
                                }
                            }
                        Button(action: {
                            logout()
                        }) {
                            Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                        }
                        Button(action: {
                            refreshData()
                        }) {
                            Label("Aggiorna dati", systemImage: "arrow.clockwise")
                                .foregroundColor(.blue)
                        }
                    }
                    Section(header: Text("Corso di Studi")) {
                        Text(networkManager.cdsDes)
                    }
                }
                Spacer()
                Text("© 2024 Mattia Meligeni\nQuest'app non è stata commissionata né approvata dall'Università della Calabria.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .navigationBarTitle("Impostazioni")
            .alert(isPresented: $showingOfflineAlert) {
                Alert(
                    title: Text("Offline"),
                    message: Text("Impossibile aggiornare i dati: non sei connesso a internet."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .onAppear {
            loadCredentials()
        }
    }

    private func loadCredentials() {
        if let usernameData = KeychainHelper.shared.read(service: keychainService, account: "username"),
           let passwordData = KeychainHelper.shared.read(service: keychainService, account: "password"),
           let username = String(data: usernameData, encoding: .utf8),
           let password = String(data: passwordData, encoding: .utf8) {
            self.username = username
            self.password = password
        }
    }

    private func logout() {
        // Delete credentials from Keychain
        KeychainHelper.shared.delete(service: keychainService, account: "username")
        KeychainHelper.shared.delete(service: keychainService, account: "password")
        username = ""
        password = ""

        // Clear data in NetworkManager
        networkManager.clearData()

        // Update app state to show login screen
        appState.isLoggedIn = false
    }

    private func refreshData() {
        if networkMonitor.isConnected {
            if let usernameData = KeychainHelper.shared.read(service: keychainService, account: "username"),
               let passwordData = KeychainHelper.shared.read(service: keychainService, account: "password"),
               let username = String(data: usernameData, encoding: .utf8),
               let password = String(data: passwordData, encoding: .utf8) {
                networkManager.authenticate(username: username, password: password) { success in
                    if success {
                        print("Data refreshed successfully.")
                    } else {
                        print("Failed to refresh data.")
                    }
                }
            }
        } else {
            showingOfflineAlert = true
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AppState())
            .environmentObject(NetworkMonitor.shared)
    }
}
