//
//  AppState.swift
//  MyUnical
//
//  Created by Mattia Meligeni on 13/10/24.
//

import Combine

class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
}
