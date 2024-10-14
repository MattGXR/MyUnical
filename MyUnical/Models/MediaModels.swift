//
//  MediaModels.swift
//  MyUnical
//
//  Created by Mattia Meligeni on 13/10/24.
//

import Foundation

struct MediaElemento: Codable {
    let base: Int
    let definizioneBase: DefinizioneBase
    let media: Double
    let tipoMediaCod: TipoMediaCod
    let tipoOk: Int
}

struct DefinizioneBase: Codable {
    let value: String
}

struct TipoMediaCod: Codable {
    let value: String
}
