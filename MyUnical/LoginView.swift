// LoginView.swift
// MyUnical
//
// Created by Mattia Meligeni on 13/10/24.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var username = ""
    @State private var password = ""
    @State private var loginFailed = false
    @State private var isLoading = false
    @StateObject private var networkManager = NetworkManager.shared
    private let keychainService = "it.mattiameligeni.MyUnical"

    var body: some View {
        ZStack {
            // Background using system background color
            Color(UIColor.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // App logo or name
                Text("MyUnical")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(.top, 50)

                Spacer()

                // Username field
                CustomTextField(
                    placeholder: Text("Username").foregroundColor(.gray),
                    text: $username,
                    imageName: "person"
                )
                .padding(.horizontal)

                // Password field
                CustomSecureField(
                    placeholder: Text("Password").foregroundColor(.gray),
                    text: $password,
                    imageName: "lock"
                )
                .padding(.horizontal)

                if loginFailed {
                    Text("Login fallito. Perfavore controlla i dati inseriti.")
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                if isLoading {
                    ProgressView("Caricamento...")
                        .padding()
                }

                // Login button
                Button(action: {
                    login()
                }) {
                    Text("Login")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .padding(.top, 20)
                .disabled(isLoading)

                Spacer()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            checkLogin()
        }
    }

    func login() {
        guard !username.isEmpty, !password.isEmpty else {
            loginFailed = true
            return
        }

        isLoading = true
        loginFailed = false

        if let usernameData = username.data(using: .utf8),
           let passwordData = password.data(using: .utf8) {
            KeychainHelper.shared.save(usernameData, service: keychainService, account: "username")
            KeychainHelper.shared.save(passwordData, service: keychainService, account: "password")

            networkManager.authenticate(username: username, password: password) { success in
                DispatchQueue.main.async {
                    self.isLoading = false
                    if success {
                        self.appState.isLoggedIn = true
                    } else {
                        self.loginFailed = true
                    }
                }
            }
        } else {
            isLoading = false
            loginFailed = true
        }
    }

    func checkLogin() {
        if let usernameData = KeychainHelper.shared.read(service: keychainService, account: "username"),
           let passwordData = KeychainHelper.shared.read(service: keychainService, account: "password"),
           let savedUsername = String(data: usernameData, encoding: .utf8),
           let savedPassword = String(data: passwordData, encoding: .utf8),
           !savedUsername.isEmpty,
           !savedPassword.isEmpty {
            self.username = savedUsername
            self.password = savedPassword
            isLoading = true
            loginFailed = false
            networkManager.authenticate(username: savedUsername, password: savedPassword) { success in
                DispatchQueue.main.async {
                    self.isLoading = false
                    if success {
                        self.appState.isLoggedIn = true
                    } else {
                        self.loginFailed = true
                    }
                }
            }
        } else {
            // No valid credentials saved; do not attempt to login
            self.username = ""
            self.password = ""
        }
    }
}

// Custom TextField with icon
struct CustomTextField: View {
    var placeholder: Text
    @Binding var text: String
    var imageName: String

    var body: some View {
        HStack {
            Image(systemName: imageName)
                .foregroundColor(.gray)
            TextField("", text: $text)
                .foregroundColor(.primary)
                .placeholder(when: text.isEmpty) {
                    placeholder
                }
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

// Custom SecureField with icon
struct CustomSecureField: View {
    var placeholder: Text
    @Binding var text: String
    var imageName: String

    var body: some View {
        HStack {
            Image(systemName: imageName)
                .foregroundColor(.gray)
            SecureField("", text: $text)
                .foregroundColor(.primary)
                .placeholder(when: text.isEmpty) {
                    placeholder
                }
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

// Extension to add placeholder functionality to TextField and SecureField
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    LoginView()
}
