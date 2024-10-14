//
//  PrenotaDetailView.swift
//  MyUnical
//
//  Created by Mattia Meligeni on 14/10/24.
//

import SwiftUI

struct PrenotaDetailView: View {
    let insegnamento: Insegnamento
    @ObservedObject private var networkManager = NetworkManager.shared

    @State private var selectedAppelloId: Int? = nil
    @State private var showAlert: Bool = false
    @State private var isLoading: Bool = false
    @State private var didStartFetch: Bool = false
    @Environment(\.dismiss) private var dismiss // For navigation back

    var body: some View {
        VStack {
            Text("Appelli disponibili per: \(insegnamento.adDes)")
                .font(.title2)
                .padding()

            if isLoading {
                ProgressView("Caricamento...")
                    .padding()
            } else {
                if networkManager.appelli.isEmpty {
                    // Optional message indicating no appelli
                    Text("Nessun appello disponibile.")
                        .padding()
                } else {
                    List(networkManager.appelli) { appello in
                        AppelloRowView(
                            appello: appello,
                            isSelected: selectedAppelloId == appello.id,
                            onSelect: { id in
                                if selectedAppelloId == id {
                                    selectedAppelloId = nil
                                } else {
                                    selectedAppelloId = id
                                }
                            },
                            onIscriviti: { app in
                                iscriviti(to: app)
                            }
                        )
                        .listRowInsets(EdgeInsets())
                        .padding(.vertical, 4)
                    }
                    .listStyle(PlainListStyle())
                }
            }
        }
        .navigationTitle("Dettagli Appello")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isLoading = true
            didStartFetch = true
            print("PrenotaDetailView: onAppear called")
            networkManager.fetchAppelli(adId: insegnamento.adDefAppId)
        }
        .onChange(of: networkManager.isFetching) { newIsFetching in
            if didStartFetch && !newIsFetching {
                if networkManager.appelli.isEmpty {
                    // Delay the alert presentation to ensure the view is fully loaded
                    DispatchQueue.main.async {
                        showAlert = true
                    }
                }
                isLoading = false
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Avviso"),
                message: Text("Nessun appello disponibile"),
                dismissButton: .default(Text("OK")) {
                    dismiss()
                }
            )
        }
    }

    // Handle "Iscriviti" action
    private func iscriviti(to appello: Appello) {
        // Implement your subscription logic here
        print("PrenotaDetailView: Iscriviti to Appello ID: \(appello.id)")
        
        // Example: Show a confirmation alert or perform a network request
        // For now, we'll just deselect the appello
        selectedAppelloId = nil
    }
}

struct PrenotaDetailView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview with sample appelli
            PrenotaDetailView(insegnamento: Insegnamento(adDes: "Matematica", adDefAppId: 1))
                .environmentObject(NetworkManager.shared)
                .onAppear {
                    NetworkManager.shared.appelli = PreviewData.sampleAppelli
                }
                .previewDisplayName("With Appelli")
            
        }
    }
}
