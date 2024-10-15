//
//  AppelloRowView.swift
//  MyUnical
//
//  Created by Mattia Meligeni on 14/10/24.
//

import SwiftUI

struct AppelloRowView: View {
    let appello: Appello
    let onIscriviti: (Appello) -> Void
    
    // Define a fixed width for the left column based on the longest label
    private let leftColumnWidth: CGFloat = 150 // Adjust as needed
    
    // State variables to manage selection and alert
    @State private var isSelected: Bool = false
    @State private var showIscrivitiButton: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Description
            Text(appello.desApp ?? "Descrizione non disponibile")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.bottom, 4)
            
            // First HStack: Data Appello & Ora Appello
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Data e Ora")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(formattedDate(appello.dataInizioApp).split(separator: " ").first ?? "") \(formattedTime(appello.oraEsa))")
                        .font(.body)
                        .foregroundColor(.blue)
                }
                .frame(width: leftColumnWidth, alignment: .leading) // Fixed width
                
            }
            
            // Second HStack: Presidente & Numero Iscritti
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Presidente")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(appello.presidenteNome ?? "Nome") \(appello.presidenteCognome ?? "Cognome")")
                        .font(.body)
                        .foregroundColor(.blue)
                }
                .frame(width: leftColumnWidth, alignment: .leading) // Fixed width
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Numero Iscritti")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(appello.numIscritti ?? 0)")
                        .font(.body)
                        .foregroundColor(.blue)
                }
            }
            
            // Third HStack: Inizio Iscrizione & Fine Iscrizione
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Inizio Iscrizione")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(formattedDate(appello.dataInizioIscr).split(separator: " ").first ?? "")
                        .font(.body)
                        .foregroundColor(.blue)
                }
                .frame(width: leftColumnWidth, alignment: .leading) // Fixed width
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fine Iscrizione")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(formattedDate(appello.dataFineIscr).split(separator: " ").first ?? "")
                        .font(.body)
                        .foregroundColor(.blue)
                }
            }
            
            // Notes
            if let note = appello.note, !note.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Note")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(note)
                        .font(.body)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity, alignment: .leading) // Ensures full width
                }
            }
            
            // "Iscriviti" Button
            if showIscrivitiButton {
                Button(action: {
                    // Existing action
                    onIscriviti(appello)
                    
                }) {
                    Text("Iscriviti")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.top, 8)
                .transition(.scale)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
        .onTapGesture {
            withAnimation {
                isSelected.toggle()
                
                
                if isSelected {
                    // Check if current date is within the registration period
                    if isWithinIscrizionePeriod {
                        showIscrivitiButton = true
                        
                    } else {
                        showIscrivitiButton = false
                        
                    }
                } else {
                    showIscrivitiButton = false
                    
                }
            }
        }
    }
    
    // Computed property to check if today is between dataInizioIscr and dataFineIscr
    private var isWithinIscrizionePeriod: Bool {
        guard let inizioStr = appello.dataInizioIscr,
              let fineStr = appello.dataFineIscr,
              let inizioDate = parseDate(inizioStr),
              let fineDate = parseDate(fineStr) else {
            print("Date strings are invalid or missing.")
            return false
        }
        let today = Date()
        
        return today >= inizioDate && today <= fineDate
    }
    
    // Helper function to parse date strings for comparison
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy" // Ensure this matches your data
        formatter.locale = Locale(identifier: "it_IT_POSIX")
        formatter.timeZone = TimeZone.current
        if let date = formatter.date(from: String(dateString.split(separator: " ").first ?? "")) {
            
            return date
        } else {
            
            return nil
        }
    }
    
    // Helper function to format date strings for display
    private func formattedDate(_ dateString: String?) -> String {
        guard let dateString = dateString else { return "Data non disponibile" }
        
        // Adjust the input date format according to your API's format
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "dd-MM-yyyy" // Ensure this matches your data
        inputFormatter.locale = Locale(identifier: "it_IT")
        inputFormatter.timeZone = TimeZone.current
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateStyle = .medium
        
        if let date = inputFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        } else {
            return dateString // Return original if parsing fails
        }
    }
    
    // Helper function to format time strings
    private func formattedTime(_ timeString: String?) -> String {
        guard let timeString = timeString else { return "Ora non disponibile" }
        
        // Expected format: "dd/MM/yyyy HH:mm:ss"
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        inputFormatter.locale = Locale(identifier: "it_IT_POSIX")
        inputFormatter.timeZone = TimeZone.current
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "HH:mm"
        
        if let date = inputFormatter.date(from: timeString) {
            return outputFormatter.string(from: date)
        } else {
            return timeString // Return original if parsing fails
        }
    }
}
