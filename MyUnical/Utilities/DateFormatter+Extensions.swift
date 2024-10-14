//
//  DateFormatter+Extensions.swift
//  MyUnical
//
//  Created by Mattia Meligeni on 13/10/24.
//

import Foundation

let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()
