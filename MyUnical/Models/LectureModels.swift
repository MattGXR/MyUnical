//
//  LectureModels.swift
//  MyUnical
//
//  Created by Mattia Meligeni on 01/11/24.
//

import Foundation

/// Represents a lecture with its details.
struct Lecture: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var day: Weekday
    var startTime: Date
    var endTime: Date
    var location: String?
    var isDisabled: Bool = false
    var colorName: String  // Store color as a string name
    var notes: String?
    
    init(
        id: UUID = UUID(), title: String, day: Weekday, startTime: Date,
        endTime: Date, location: String?, isDisabled: Bool = false,
        colorName: String, notes: String?
    ) {
        self.id = id
        self.title = title
        self.day = day
        self.startTime = startTime
        self.endTime = endTime
        self.location = location
        self.isDisabled = isDisabled
        self.colorName = colorName
        self.notes = notes
    }
}
