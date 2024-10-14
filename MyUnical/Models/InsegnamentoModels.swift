//
//  InsegnamentoModels.swift
//  MyUnical
//
//  Created by Mattia Meligeni on 14/10/24.
//

import Foundation

struct Insegnamento: Codable, Identifiable {
    let id = UUID()         // Using adDefAppId as a unique identifier
    let adDes: String     // Description of the insegnamento
    let adDefAppId: Int   // Unique identifier for the insegnamento
}
