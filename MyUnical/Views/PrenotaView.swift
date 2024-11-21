// PrenotaView.swift
// MyUnical
//
// Created by Mattia Meligeni on 13/10/2024.
//

import SwiftUI

struct PrenotaView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var networkManager = NetworkManager.shared
    
    // Computed property to get filtered and unique insegnamenti
    var uniqueInsegnamenti: [Insegnamento] {
            // Step 1: Filter out entries containing "TIROCINIO" (case insensitive)
            let filtered = networkManager.insegnamenti
                .filter { !$0.adDes.localizedCaseInsensitiveContains("TIROCINIO") }
            
            // Step 2: Remove duplicates based on adDes and adDefAppId
            var seenKeys = Set<String>()
            let unique = filtered.filter { insegnamento in
                // Create a unique key by combining adDes (lowercased for case-insensitivity) and adDefAppId
                let key = "\(insegnamento.adDes.lowercased())_\(insegnamento.adDefAppId)"
                if seenKeys.contains(key) {
                    return false // Duplicate found, exclude from the result
                } else {
                    seenKeys.insert(key)
                    return true // Unique entry, include in the result
                }
            }
            
            // Step 3: Sort the unique entries alphabetically based on adDes
            let sorted = unique.sorted { lhs, rhs in
                lhs.adDes.localizedCaseInsensitiveCompare(rhs.adDes) == .orderedAscending
            }
            
            return sorted
        }
    
    var body: some View {
        NavigationView {
            VStack {
                List(uniqueInsegnamenti) { insegnamento in
                    NavigationLink(destination: PrenotaDetailView(insegnamento: insegnamento)) {
                        HStack {
                            Image(systemName: "book.closed")
                                .foregroundColor(.blue)
                            Text(insegnamento.adDes)
                                .font(.body)
                                .padding(.vertical, 8)
                        }
                    }
                }
                // Button at the bottom
                NavigationLink(destination: PrenotazioniView()) {
                    Text("Appelli Prenotati")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                        .padding([.horizontal, .bottom], 16)
                }
            }
            .navigationTitle("Prenota Appelli")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi") {
                        dismiss() // Dismiss the sheet
                    }
                }
            }
        }
    }
}

#Preview {
    PrenotaView()
}
