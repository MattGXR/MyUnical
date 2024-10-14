//
//  ProveModels.swift
//  MyUnical
//
//  Created by Mattia Meligeni on 13/10/24.
//

import Foundation

struct Prova: Codable {
    let adsceId: Int
    let dataApp: String
    let esitoFinale: EsitoFinale?
}

struct EsitoFinale: Codable {
    let voto: Double?
}
