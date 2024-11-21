//
//  Prenotazioni.swift
//  MyUnical
//
//  Created by Mattia Meligeni on 21/11/24.
//

import Foundation

struct Prenotazioni: Identifiable {
    let id = UUID()
    let insegnamento: String
    let dataAppello: String
    
    var date: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy" // Ensure this matches your date format
        return formatter.date(from: dataAppello)
    }
}
