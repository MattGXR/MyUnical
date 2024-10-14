//
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
    
}
