//
//  IstruzioniView.swift
//  MyUnical
//
//  Created by Mattia Meligeni on 14/10/24.
//

import SwiftUI
import Foundation

enum PaymentMethod: String, CaseIterable, Identifiable {
    case appIO = "App IO"
    case postepay = "Postepay"
    case altreBanche = "Altre Banche"
    
    var id: String { self.rawValue }
    
    var localizedName: String {
        NSLocalizedString(self.rawValue, comment: "Payment method name")
    }
    
    var instructions: String {
        switch self {
        case .appIO:
            return NSLocalizedString("""
                Per effettuare il pagamento della tua fattura tramite App IO (Raccomandato), segui questi passaggi:
                
                1. Apri l'app IO;
                2. Seleziona la sezione "Inquadra";
                3. Inquadra il codice QR, caricane uno screenshot o inserisci manualmente i dati della fattura che puoi copiare in questa pagina nella sezione "Digita";
                4. Completa la transazione, la ricevuta ti sarà inviata via email e sarà anche disponibile in app.
                """, comment: "Instructions for paying via App IO")
                
        case .postepay:
            return NSLocalizedString("""
                Per effettuare il pagamento della tua fattura tramite Postepay, segui questi passaggi:
                
                1. Apri l'app Postepay;
                2. Vai alla sezione "Operazioni" e seleziona "Bollette e Pagamenti";
                3. Inquadra il codice QR o inserisci manualmente i dati della fattura disponibili in questa pagina selezionando "Compila manualmente" poi Avvisi pagoPA e infine "Banche e altri canali";
                4. Completa la transazione, la ricevuta sarà disponibile in app.
                """, comment: "Instructions for paying via Postepay")
                
        case .altreBanche:
            return NSLocalizedString("""
                Per effettuare il pagamento della tua fattura tramite altre banche, segui questi passaggi:
                
                1. Apri la tua app bancaria preferita;
                2. Vai alla sezione "Pagamenti" e seleziona "PagoPA" come metodo di pagamento;
                3. Inquadra il codice QR o inserisci manualmente i dati della fattura;
                4. Completa la transazione, la ricevuta sarà disponibile in app.
                """, comment: "Instructions for paying via Other Banks")
        }
    }
}

struct IstruzioniView: View {
    var codiceAvviso: String
    let codiceFiscaleEnteCreditore: String = "80003950781"
    var price: Double
    @State private var selectedMethod: PaymentMethod = .appIO
    
    // New state variable for copy confirmation
    @State private var showCopyConfirmation: Bool = false
    @State private var copyMessage: String = ""
    
    
    @Environment(\.presentationMode) var presentationMode // To dismiss the sheet
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    
                    Picker(NSLocalizedString("Metodo di Pagamento", comment: "Payment Method Picker Label"), selection: $selectedMethod) {
                        ForEach(PaymentMethod.allCases) { method in
                            Text(method.localizedName).tag(method)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    Text(selectedMethod.instructions)
                        .font(.body)
                        .padding([.leading, .trailing])
                    
                    
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
                            // Show confirmation
                            withAnimation {
                                showCopyConfirmation = true
                                copyMessage = NSLocalizedString("Codice Copiato!", comment: "Copy confirmation message")
                            }
                            // Hide confirmation after 2 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                withAnimation {
                                    showCopyConfirmation = false
                                }
                            }
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
                            withAnimation {
                                showCopyConfirmation = true
                                copyMessage = NSLocalizedString("Codice Copiato!", comment: "Copy confirmation message")
                            }
                            // Hide confirmation after 2 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                withAnimation {
                                    showCopyConfirmation = false
                                }
                            }
                        }) {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .accessibilityLabel("Copia Codice Fiscale Ente Creditore")
                    }
                    .padding(.vertical, 8)
                    VStack(alignment: .center,spacing: 12){
                        Text("Codice QR Avviso")
                        AsyncImage(url: URL(string: "https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=PAGOPA|002|\(codiceAvviso)|\(codiceFiscaleEnteCreditore)|\(Int(price))"))
                            .background(Color.black)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Istruzioni")
            .overlay(
                // Only show the confirmation when showCopyConfirmation is true
                showCopyConfirmation ? CopyConfirmationView(message: copyMessage) : nil
            )
            .navigationBarItems(
                leading: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
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

struct CopyConfirmationView: View {
    let message: String
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Text(message)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(10)
                Spacer()
            }
            Spacer()
        }
        // Ensure the confirmation covers the entire screen
        .background(Color.black.opacity(0.25))
        // Add a transition for smooth appearance/disappearance
        .transition(.opacity)
        .animation(.easeInOut, value: message)
    }
}

// Preview (optional)
struct IstruzioniView_Previews: PreviewProvider {
    static var previews: some View {
        IstruzioniView(codiceAvviso: "ABC123456789", price: 1650)
    }
}
