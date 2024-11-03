//
//  DataPersistence.swift
//  MyUnical
//
//  Created by Mattia Meligeni on 13/10/24.

import Foundation

class DataPersistence {
    static let shared = DataPersistence()
    
    private init() {}
    
    /// Saves the given data to the specified filename.
    func save<T: Codable>(_ data: T, to filename: String) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601 // Ensure consistent date formatting
        do {
            let data = try encoder.encode(data)
            let url = getDocumentsDirectory().appendingPathComponent(filename)
            try data.write(to: url)
            print("Data saved to \(url)")
        } catch {
            print("Failed to save data: \(error)")
        }
    }
    
    /// Loads data from the specified filename.
    func load<T: Codable>(_ filename: String, as type: T.Type) -> T? {
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            let data = try Data(contentsOf: url)
            let decoded = try decoder.decode(T.self, from: data)
            print("Data loaded from \(url)")
            return decoded
        } catch {
            print("Failed to load data: \(error)")
            return nil
        }
    }
    /// Returns the URL to the app's Documents directory.
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
