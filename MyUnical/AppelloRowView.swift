//
//  AppelloRowView.swift
//  MyUnical
//
//  Created by Mattia Meligeni on 14/10/24.
//

import SwiftUI

struct AppelloRowView: View {
    let appello: Appello
    let isSelected: Bool
    let onSelect: (Int) -> Void
    let onIscriviti: (Appello) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Descrizione Appello
            Text(appello.desApp ?? "Descrizione non disponibile")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Iscrizione Periodo
            HStack {
                Text("Inizio Iscrizione: \(formattedDate(appello.dataInizioIscr))")
                Spacer()
                Text("Fine Iscrizione: \(formattedDate(appello.dataFineIscr))")
            }
            .font(.subheadline)
            .foregroundColor(.gray)
            
            // Inizio Appello
            Text("Data Inizio Appello: \(formattedDate(appello.dataInizioApp))")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            // Numero Iscritti
            Text("Numero Iscritti: \(appello.numIscritti ?? 0)")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            // Presidente
            Text("Presidente: \(appello.presidenteNome ?? "Nome") \(appello.presidenteCognome ?? "Cognome")")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            // Note
            if let note = appello.note, !note.isEmpty {
                Text("Note: \(note)")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            
            // "Iscriviti" Button
            if isSelected {
                Button(action: {
                    onIscriviti(appello)
                }) {
                    Text("Iscriviti")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .padding(.top, 8)
                .transition(.opacity)
            }
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .onTapGesture {
            withAnimation {
                onSelect(appello.id)
            }
        }
    }
    
    // Helper function to format date strings
    private func formattedDate(_ dateString: String?) -> String {
        guard let dateString = dateString else { return "Data non disponibile" }
        
        // Adjust the input date format according to your API's format
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd" // Change if your API uses a different format
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateStyle = .medium
        
        if let date = inputFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        } else {
            return dateString // Return original if parsing fails
        }
    }
}
