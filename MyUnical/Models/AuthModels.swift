//
//  AuthModels.swift
//  MyUnical
//
//  Created by Mattia Meligeni on 13/10/24.
//

import Foundation

struct AuthResponse: Codable {
    let user: User
}

struct User: Codable {
    let trattiCarriera: [TrattoCarriera]
    let firstName: String
    let sex: String
}

struct TrattoCarriera: Codable {
    let cdsDes: String
    let cdsId: Int
    let matId: Int
    let dettaglioTratto: DettaglioTratto
}

struct DettaglioTratto: Codable {
    let durataAnni: Int
}
