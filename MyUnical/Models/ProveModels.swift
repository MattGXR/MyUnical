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
    let modValCod: String?
    let tipoGiudCod: String?

    enum CodingKeys: String, CodingKey {
        case voto
        case modValCod
        case tipoGiudCod
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        voto = try? container.decode(Double.self, forKey: .voto)
        
        // Decode modValCod which can be either String or an object with "value"
        if let modValCodString = try? container.decode(String.self, forKey: .modValCod) {
            modValCod = modValCodString
        } else if let modValCodObject = try? container.nestedContainer(keyedBy: ValueCodingKey.self, forKey: .modValCod),
                  let value = try? modValCodObject.decode(String.self, forKey: .value) {
            modValCod = value
        } else {
            modValCod = nil
        }
        
        tipoGiudCod = try? container.decode(String.self, forKey: .tipoGiudCod)
    }

    struct ValueCodingKey: CodingKey {
        var stringValue: String
        var intValue: Int?

        init?(stringValue: String) {
            self.stringValue = stringValue
            self.intValue = nil
        }

        init?(intValue: Int) {
            self.stringValue = "\(intValue)"
            self.intValue = intValue
        }

        static let value = ValueCodingKey(stringValue: "value")!
    }
}
