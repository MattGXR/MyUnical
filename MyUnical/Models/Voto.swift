//
//  Voto.swift
//  MyUnical
//
//  Created by Mattia Meligeni on 13/10/24.
//

import Foundation

struct Voto: Codable, Identifiable {
    var id = UUID()
    let insegnamento: String
    let voto: Int
    let cfu: Int
    let dataAppello: String
    let date: Date
}
