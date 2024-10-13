//
//  AppState.swift
//  MyUnical
//
//  Created by Mattia Meligeni on 13/10/24.

// AppState.swift

import Foundation
import Combine

class AppState: ObservableObject {
    @Published var isLoggedIn: Bool {
        didSet {
            UserDefaults.standard.set(isLoggedIn, forKey: "isLoggedIn")
        }
    }

    init() {
        // Retrieve the persisted login state
        self.isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        
        // If logged in, load cached data
        if isLoggedIn {
            NetworkManager.shared.loadCachedData()
        }
    }
    
    func logout() {
        // Clear credentials from Keychain
        let keychainService = "it.mattiameligeni.MyUnical"
        KeychainHelper.shared.delete(service: keychainService, account: "username")
        KeychainHelper.shared.delete(service: keychainService, account: "password")
        
        // Clear cached data
        NetworkManager.shared.clearData()
        
        // Update login state
        self.isLoggedIn = false
    }
}
