//
//  PreviewData.swift
//  MyUnical
//
//  Created by Mattia Meligeni on 14/10/24.
//

import Foundation

struct PreviewData {
    static let sampleAppelli: [Appello] = [
        Appello(
            id: 1,
            dataInizioIscr: "2024-11-01",
            dataFineIscr: "2024-11-15",
            dataInizioApp: "2024-12-01",
            desApp: "Appello Matematica 1",
            note: "Nessuna nota",
            numIscritti: 25,
            presidenteNome: "Mario",
            presidenteCognome: "Rossi"
        ),
        Appello(
            id: 2,
            dataInizioIscr: "2024-11-05",
            dataFineIscr: "2024-11-20",
            dataInizioApp: "2024-12-05",
            desApp: "Appello Fisica 2",
            note: nil,
            numIscritti: 30,
            presidenteNome: "Luigi",
            presidenteCognome: "Verdi"
        )
    ]
    
    static let emptyAppelli: [Appello] = []
}
