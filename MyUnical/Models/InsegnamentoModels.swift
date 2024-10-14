//
//  InsegnamentoModels.swift
//  MyUnical
//
//  Created by Mattia Meligeni on 14/10/24.
//

import Foundation

struct Insegnamento: Codable, Identifiable {
    let id = UUID()
    let adDes: String
    let adDefAppId: Int   
}
