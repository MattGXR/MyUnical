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
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var shouldDismiss: Bool = false
    @State private var isLoading: Bool = false
    @State private var appelli: [Appello] = []
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            headerView
            
            if isLoading {
                loadingView
            } else {
                if appelli.isEmpty {
                    // Since the alert handles the empty state, we can show a placeholder or nothing
                    Spacer()
                        .frame(maxHeight: .infinity)
                } else {
                    appelliListView
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Dettagli Appello")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true) // Hide default back button
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Text("Indietro") // Custom back button text
                }
            }
        }
        .onAppear {
            fetchAppelli()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Avviso"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    if shouldDismiss {
                        dismiss()
                    }
                }
            )
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        Text("\(insegnamento.adDes)")
            .font(.title2)
            .fontWeight(.semibold)
            .multilineTextAlignment(.center) // Center text within the Text view
            .frame(maxWidth: .infinity) // Expand to full width to center
            .padding(.horizontal)
    }
    
    @ViewBuilder
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("Caricamento...")
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(1.2)
                .padding() // Add padding to ensure it's not too close to edges
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure VStack takes full space
    }
    
    @ViewBuilder
    private var appelliListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(appelli) { appello in
                    AppelloRowView(
                        appello: appello,
                        onIscriviti: { app in
                            iscriviti(to: app)
                        }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
    }
    
    // MARK: - Helper Methods
    
    private func fetchAppelli() {
        isLoading = true
        
        networkManager.fetchAppelli(adId: insegnamento.adDefAppId) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let fetchedAppelli):
                    if fetchedAppelli.isEmpty {
                        alertMessage = NSLocalizedString("Nessun appello disponibile", comment: "")
                        shouldDismiss = true // Set to true to dismiss on alert dismissal
                        showAlert = true
                    } else {
                        appelli = fetchedAppelli
                    }
                case .failure(let error):
                    // Optionally, handle specific errors differently
                    print("PrenotaDetailView: Error fetching appelli: \(error.localizedDescription)")
                    alertMessage = "Errore nel recupero degli appelli."
                    shouldDismiss = true // Do not dismiss on error
                    showAlert = true // Or present a different alert based on the error
                }
            }
        }
    }
    
    // Handle "Iscriviti" action
    private func iscriviti(to appello: Appello) {
        guard let cdsId = appello.cdsId, let adId = appello.adId else {
            // Handle the error, maybe show an alert
            alertMessage = "Dati appello non validi."
            shouldDismiss = false // Do not dismiss on invalid data
            showAlert = true
            return
        }
        isLoading = true
        Task {
            do {
                try await networkManager.prenotaAppello(cdsId: cdsId, adId: adId, appId: appello.id)
                isLoading = false
                alertMessage = NSLocalizedString("Prenotazione effettuata con successo", comment: "")
                shouldDismiss = true // Set to true to dismiss on success
                showAlert = true
                // Optionally, refresh the appelli list
                // await fetchAppelli()
            } catch {
                isLoading = false
                print("PrenotaDetailView: Error prenotando appello: \(error.localizedDescription)")
                alertMessage = "Errore nella prenotazione: \(error.localizedDescription)"
                shouldDismiss = false // Do not dismiss on booking error
                showAlert = true
            }
        }
    }
}

#Preview {
    PrenotaDetailView(insegnamento: Insegnamento(adDes: "Prova", adDefAppId: 134))
}
