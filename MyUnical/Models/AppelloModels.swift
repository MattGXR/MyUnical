//
//  AppelloModels.swift
//  MyUnical
//
//  Created by Mattia Meligeni on 14/10/24.
//

import Foundation

struct Appello: Codable, Identifiable, Equatable {
    let id: Int // Use appId as the unique identifier
    let dataInizioIscr: String?
    let dataFineIscr: String?
    let dataInizioApp: String?
    let desApp: String?
    let note: String?
    let numIscritti: Int?
    let presidenteNome: String?
    let presidenteCognome: String?
    
    // Map JSON keys to struct properties if they differ
    enum CodingKeys: String, CodingKey {
        case id = "appId"
        case dataInizioIscr
        case dataFineIscr
        case dataInizioApp
        case desApp
        case note
        case numIscritti
        case presidenteNome
        case presidenteCognome
    }
}
