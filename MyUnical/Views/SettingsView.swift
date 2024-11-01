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
    private let keychainService = "it.mattiameligeni.MyUnical"
    @State private var showingOfflineAlert = false
    
    @Environment(\.openURL) var openURL

    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Account")) {
                        TextField("Username", text: $username)
                            .disabled(true)
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
                    Section(header: Text("Info")) {
                        Text("Matricola: \(networkManager.matricola)")
                        Text("CDS: \(networkManager.cdsDes)")
                    }
                    
                    Section(header: Text("Donazioni")){
                        Text("Se desideri aiutare il mantenimento di quest'app e apprezzi il lavoro svolto, puoi donare qualsiasi importo al seguente indirizzo:")
                        Text("https://www.paypal.me/mattiameligeni")
                    }
                    
                    
                }
                Spacer()
                Button(action: {
                    email()
                }) {
                    Label("Segnalazione", systemImage: "bubble.left.and.exclamationmark.bubble.right")
                        .foregroundColor(.blue)
                }
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
           let username = String(data: usernameData, encoding: .utf8){
            self.username = username
        }
    }
    
    private func email() {
        let emailRecipient = "myunical@mattiameligeni.it"
        let emailSubject = "Segnalazione da MyUnical App"
        let emailBody = """
        Ciao,

        Vorrei segnalare il seguente problema/bug/glitch:

        [Descrivi la segnalazione qui]

        Grazie,
        
        CF: \(username)
        Matricola: \(networkManager.matricola)
        """
        
        // URL-encode the subject and body
        guard let encodedSubject = emailSubject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedBody = emailBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print("Failed to encode email subject or body.")
            return
        }
        
        // Construct the mailto URL
        let mailtoURLString = "mailto:\(emailRecipient)?subject=\(encodedSubject)&body=\(encodedBody)"
        
        // Convert the string to a URL object
        if let mailtoURL = URL(string: mailtoURLString) {
            // Attempt to open the URL
            openURL(mailtoURL)
        } else {
            print("Invalid mailto URL.")
        }
    }
    
    private func logout() {
        // Step 1: Update app state to show the login screen
        appState.isLoggedIn = false
        
        // Step 2: Delete credentials from Keychain
        KeychainHelper.shared.delete(service: keychainService, account: "username")
        KeychainHelper.shared.delete(service: keychainService, account: "password")
        username = ""
        
        // Step 3: Clear data in NetworkManager
        networkManager.clearData() // Where all data and JSONs are emptied
        
        // Step 4: Clear cached data
        URLSession.shared.reset {
            print("URLSession cache cleared.")
        }
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

#Preview {
    SettingsView()
}
