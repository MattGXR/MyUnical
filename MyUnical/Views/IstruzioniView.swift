//
//  IstruzioniView.swift
//  MyUnical
//
//  Created by Mattia Meligeni on 14/10/24.
//

import SwiftUI

struct IstruzioniView: View {
    let codiceAvviso: String
    let codiceFiscaleEnteCreditore: String = "80003950781" // Static data
    
    @Environment(\.presentationMode) var presentationMode // To dismiss the sheet
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Sample payment instructions
                    Text("""
                        Per effettuare il pagamento della tua fattura, segui questi passaggi:

                        1. Apri l'app IO.
                        2. Spostati nella sezione "Inquadra".
                        3. Cambia modalità in "Digita".
                        4. Inserisci il codice avviso e codice fiscale ente creditore che trovi in questa pagina.
                        5. Completa la transazione, ti sarà inviata la ricevuta via email.

                        Assicurati di controllare attentamente i dettagli prima di finalizzare il pagamento.
                        """)
                        .font(.body)
                    
                    // Display Codice Avviso with Copy Button
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Codice Avviso:")
                                .fontWeight(.bold)
                            Text(codiceAvviso)
                                .foregroundColor(.blue)
                        }
                        Spacer()
                        Button(action: {
                            copyToClipboard(text: codiceAvviso)
                        }) {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .accessibilityLabel("Copia Codice Avviso")
                    }
                    .padding(.vertical, 8)
                    
                    // Static Data with Copy Button
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Codice Fiscale Ente Creditore:")
                                .fontWeight(.bold)
                            Text(codiceFiscaleEnteCreditore)
                                .foregroundColor(.blue)
                        }
                        Spacer()
                        Button(action: {
                            copyToClipboard(text: codiceFiscaleEnteCreditore)
                        }) {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .accessibilityLabel("Copia Codice Fiscale Ente Creditore")
                    }
                    .padding(.vertical, 8)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Istruzioni")
            .navigationBarItems(
                leading: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left") // Optional: Add a back arrow
                        Text("Chiudi")
                    }
                }
            )
        }
    }
    
    /// Copies the provided text to the clipboard.
    /// - Parameter text: The text to copy.
    private func copyToClipboard(text: String) {
        #if os(iOS)
        UIPasteboard.general.string = text
        #elseif os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        #endif
    }
}

// Preview (optional)
struct IstruzioniView_Previews: PreviewProvider {
    static var previews: some View {
        IstruzioniView(codiceAvviso: "ABC123456789")
    }
}
