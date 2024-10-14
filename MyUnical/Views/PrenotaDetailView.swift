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
    
    // Computed property to detect if in preview mode
    var isPreview: Bool {
#if DEBUG
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
#else
        return false
#endif
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Appelli disponibili per: \(insegnamento.adDes)")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            if isLoading {
                VStack {
                    Spacer()
                    ProgressView("Caricamento...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(1.2)
                    Spacer()
                }
            } else {
                if networkManager.appelli.isEmpty {
                    VStack {
                        Spacer()
                        Text("Nessun appello disponibile.")
                            .font(.body)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(networkManager.appelli) { appello in
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
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }
                }
            }
        }
        .navigationTitle("Dettagli Appello")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !isPreview {
                isLoading = true
                didStartFetch = true
                
                networkManager.fetchAppelli(adId: insegnamento.adDefAppId)
            } else {
                
            }
        }
        .onReceive(networkManager.$appelli) { newAppelli in
            if !isPreview { // Only handle real fetches
                isLoading = false
                
                
                if newAppelli.isEmpty {
                    
                    // Delay the alert presentation to ensure the view is fully loaded
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showAlert = true
                    }
                }
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
            // Preview with multiple appelli
            PrenotaDetailView(insegnamento: Insegnamento(adDes: "Matematica Avanzata", adDefAppId: 1))
                .environmentObject(NetworkManager.shared)
                .onAppear {
                    NetworkManager.shared.appelli = PreviewData.sampleAppelli
                }
                .previewDisplayName("With Appelli")
            
            // Preview with empty appelli
            PrenotaDetailView(insegnamento: Insegnamento(adDes: "Fisica Generale", adDefAppId: 2))
                .environmentObject(NetworkManager.shared)
                .onAppear {
                    NetworkManager.shared.appelli = PreviewData.emptyAppelli
                }
                .previewDisplayName("No Appelli")
        }
    }
}
