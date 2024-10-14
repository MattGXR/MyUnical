//
//  AppelloRowView.swift
//  MyUnical
//
//  Created by Mattia Meligeni on 14/10/24.
//

// AppelloRowView.swift
import SwiftUI

struct AppelloRowView: View {
    let appello: Appello
    let isSelected: Bool
    let onSelect: (Int) -> Void
    let onIscriviti: (Appello) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Description
            Text(appello.desApp ?? "Descrizione non disponibile")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.bottom, 4)
            
            // Enrollment Period
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Inizio Iscrizione")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(formattedDate(appello.dataInizioIscr))
                        .font(.body)
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fine Iscrizione")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(formattedDate(appello.dataFineIscr))
                        .font(.body)
                        .foregroundColor(.black)
                }
            }
            
            // Appello Start Date and Enrollment Count
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Data Inizio Appello")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(formattedDate(appello.dataInizioApp))
                        .font(.body)
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Numero Iscritti")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(appello.numIscritti ?? 0)")
                        .font(.body)
                        .foregroundColor(.black)
                }
            }
            
            // President Information
            VStack(alignment: .leading, spacing: 4) {
                Text("Presidente")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("\(appello.presidenteNome ?? "Nome") \(appello.presidenteCognome ?? "Cognome")")
                    .font(.body)
                    .foregroundColor(.black)
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
                }
            }
            
            // "Iscriviti" Button
            if isSelected {
                Button(action: {
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

struct AppelloRowView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Sample Appello with all data
            AppelloRowView(
                appello: Appello(
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
                isSelected: false,
                onSelect: { _ in },
                onIscriviti: { _ in }
            )
            .previewLayout(.sizeThatFits)
            .padding()
            .previewDisplayName("With Appello")
            
            // Sample Appello with missing data
            AppelloRowView(
                appello: Appello(
                    id: 2,
                    dataInizioIscr: nil,
                    dataFineIscr: "2024-11-20",
                    dataInizioApp: "2024-12-05",
                    desApp: "Appello Fisica 2",
                    note: nil,
                    numIscritti: 30,
                    presidenteNome: "Luigi",
                    presidenteCognome: "Verdi"
                ),
                isSelected: true,
                onSelect: { _ in },
                onIscriviti: { _ in }
            )
            .previewLayout(.sizeThatFits)
            .padding()
            .previewDisplayName("With Partial Appello")
        }
    }
}
