//
//  PrenotazioniView.swift
//  MyUnical
//
//  Created by Mattia Meligeni on 21/11/24.
//

import SwiftUI

struct PrenotazioniView: View {
    @ObservedObject private var networkManager = NetworkManager.shared
    
    
    // Computed property to get prenotazioni sorted by date closest to today
    private var sortedPrenotazioni: [Prenotazioni] {
        networkManager.prenotazioni.sorted { (a: Prenotazioni, b: Prenotazioni) -> Bool in
            // Safely unwrap dates; place entries with valid dates first
            guard let dateA = a.date, let dateB = b.date else {
                return a.date != nil
            }
            return dateA < dateB
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // List of sorted prenotazioni
                List(sortedPrenotazioni) { prenotazione in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(prenotazione.insegnamento)
                            .font(.headline)
                        Text(prenotazione.dataAppello)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(PlainListStyle()) // Optional: Adjust list style as needed
                
                // Disclaimer Text
                Text("Per via di limitazioni dell'app di Esse3 agli accessi esterni, per il momento non si può interagire con gli appelli prenotati né vedere altri dettagli.")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding([.horizontal, .bottom], 16)
            }
        }
        .navigationTitle("Prenotazioni")
    }
}

struct PrenotazioniView_Previews: PreviewProvider {
    static var previews: some View {
        PrenotazioniView()
    }
}
