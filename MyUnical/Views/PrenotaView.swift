// PrenotaView.swift
// MyUnical
//
// Created by Mattia Meligeni on [Date].
//

import SwiftUI

struct PrenotaView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var networkManager = NetworkManager.shared
    
    var body: some View {
        NavigationView {
            List(networkManager.insegnamenti) { insegnamento in
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
            .navigationTitle("Prenota Appelli")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct PrenotaView_Previews: PreviewProvider {
    static var previews: some View {
        PrenotaView()
    }
}
