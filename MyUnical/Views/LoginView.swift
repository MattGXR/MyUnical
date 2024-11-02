// LoginView.swift
// MyUnical
//
// Created by Mattia Meligeni on 13/10/24.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @Environment(\.colorScheme) var colorScheme
    @State private var username = ""
    @State private var password = ""
    @State private var loginFailed = false
    @State private var isLoading = false
    @StateObject private var networkManager = NetworkManager.shared
    private let keychainService = "it.mattiameligeni.MyUnical"
    
    var placeholderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.7)
    }

    var textFieldBackgroundColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.05)
    }

    var textFieldForegroundColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
    
    var body: some View {
        ZStack {
            // Gradient Background
            (colorScheme == .dark ? Color.black : Color.white)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // App Logo or Name with Animation
                VStack {
                    Image("1-01")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 350, height: 350)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    
                    
                }
                .padding(.top, 20)
                
                // Username Field
                CustomTextField(
                    placeholder: Text("Username").foregroundColor(placeholderColor),
                    text: $username,
                    imageName: "person",
                    backgroundColor: textFieldBackgroundColor,
                    foregroundColor: textFieldForegroundColor
                )
                .padding(.horizontal, 40)
                
                // Password Field
                CustomSecureField(
                    placeholder: Text("Password").foregroundColor(placeholderColor),
                    text: $password,
                    imageName: "lock",
                    backgroundColor: textFieldBackgroundColor,
                    foregroundColor: textFieldForegroundColor
                )
                .padding(.horizontal, 40)
                
                if loginFailed {
                    Text("Login fallito. Per favore controlla i dati inseriti.")
                        .foregroundColor(.red.opacity(0.8))
                        .padding(.horizontal, 40)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                }
                
                if isLoading {
                    ProgressView("Caricamento...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .foregroundColor(.blue)
                        .padding()
                        .transition(.opacity)
                }
                
                // Login Button with Gradient
                Button(action: {
                    login()
                }) {
                    Text("Login")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.black)
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
                .disabled(isLoading)
                .opacity(isLoading ? 0.7 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isLoading)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
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
}

// Custom TextField with icon and enhanced styling
struct CustomTextField: View {
    var placeholder: Text
    @Binding var text: String
    var imageName: String
    var backgroundColor: Color = Color(UIColor.secondarySystemBackground)
    var foregroundColor: Color = .primary
    
    var body: some View {
        HStack {
            Image(systemName: imageName)
                .foregroundColor(foregroundColor.opacity(0.7))
            
            TextField("", text: $text)
                .foregroundColor(foregroundColor)
                .placeholder(when: text.isEmpty) {
                    placeholder
                }
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// Custom SecureField with icon and enhanced styling
struct CustomSecureField: View {
    var placeholder: Text
    @Binding var text: String
    var imageName: String
    var backgroundColor: Color = Color(UIColor.secondarySystemBackground)
    var foregroundColor: Color = .primary
    
    var body: some View {
        HStack {
            Image(systemName: imageName)
                .foregroundColor(foregroundColor.opacity(0.7))
            
            SecureField("", text: $text)
                .foregroundColor(foregroundColor)
                .placeholder(when: text.isEmpty) {
                    placeholder
                }
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
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

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AppState())
            .environmentObject(NetworkMonitor.shared)
            .preferredColorScheme(.dark) // Preview in dark mode
    }
}
