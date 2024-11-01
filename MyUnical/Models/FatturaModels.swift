//  FattureModels.swift
//  MyUnical
//
//  Created by Mattia Meligeni on 14/10/24.
//

import Foundation

struct Fattura: Codable, Identifiable {
    let id = UUID()
    let codiceAvviso: String
    let importoFattura: Double
    let dataEmissione: String
    let scadFattura: String
    let dataPagamento: String
    let desMav1: String
    let fattId: Int
    let pagatoFlg: Int

    var pagato: Bool {
        return pagatoFlg == 1
    }

    // Exclude 'id' from the coding keys
    private enum CodingKeys: String, CodingKey {
        case codiceAvviso
        case importoFattura
        case dataEmissione
        case scadFattura
        case dataPagamento
        case desMav1
        case fattId
        case pagatoFlg
    }
}
