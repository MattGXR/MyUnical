//
//  TaxView.swift
//  MyUnical
//
//  Created by Mattia Meligeni on 14/10/24.
//

import SwiftUI

struct TaxView: View {
    @EnvironmentObject var networkMonitor: NetworkMonitor // Access NetworkMonitor
    @ObservedObject private var networkManager = NetworkManager.shared
    
    // State variables to handle sheet presentation
    @State private var isShowingIstruzioni = false
    @State private var selectedCodiceAvviso: String = ""
    @State private var selectedPrice: Double = 0
    @State private var selectedFattura: Fattura? = nil
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    // Situazione Pagamenti Section
                    Section(header: Text("Stato pagamenti")) {
                        HStack(spacing: 16) {
                            // Colored Circle
                            Circle()
                                .fill(circleColor())
                                .frame(width: 20, height: 20)
                            
                            // Importo Dovuto Text
                            Text("Importo dovuto: €\(networkManager.semaforo?.importoDovuto ?? 0.0, specifier: "%.2f")")
                                .foregroundColor(textColor())
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Fatture Section
                    Section(header: Text("Fatture")) {
                        if networkManager.fatture.isEmpty {
                            Text("Nessuna fattura disponibile.")
                                .foregroundColor(.gray)
                        } else {
                            List(sortedFatture) { fattura in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Numero Fattura: \(String(fattura.fattId))")
                                        .font(.headline)
                                        .foregroundColor(getNumeroFatturaColor(fattura))
                                    
                                    Text("Codice Avviso: \(fattura.codiceAvviso)")
                                    Text("Importo: €\(fattura.importoFattura,specifier: "%.2f")")
                                    Text("Emissione: \(fattura.dataEmissione)")
                                    Text("Scadenza: \(fattura.scadFattura)")
                                    Text("Data Pagamento: \(fattura.dataPagamento)")
                                    Text("Descrizione: \(fattura.desMav1)")
                                    
                                    Text("Pagato: \(fattura.pagato ? NSLocalizedString("Sì", comment: "") : NSLocalizedString("No", comment: ""))")
                                    
                                    // Add button if pagato is "Si"
                                    if !fattura.pagato {
                                        Button(action: {
                                            selectedFattura = fattura
                                            
                                        }) {
                                            Text("Come Pagare")
                                                .font(.subheadline)
                                                .foregroundColor(.blue)
                                        }
                                        .padding(.top, 4)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Tasse")
            // Present IstruzioniView as a sheet
            .sheet(item: $selectedFattura) { fattura in
                IstruzioniView(codiceAvviso: fattura.codiceAvviso, price: fattura.importoFattura * 100)
            }
        }
    }
    
    private var sortedFatture: [Fattura] {
        networkManager.fatture.sorted { (f1, f2) -> Bool in
            guard let date1 = parseDate(f1.scadFattura),
                  let date2 = parseDate(f2.scadFattura) else {
                return false
            }
            return date1 < date2
        }
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.date(from: dateString)
    }
    
    private func circleColor() -> Color {
        switch networkManager.semaforo?.semaforo.uppercased() {
        case "VERDE":
            return .green
        case "GIALLO":
            return .yellow
        case "ROSSO":
            return .red
        default:
            return .gray
        }
    }
    
    // Helper function to determine text color based on semaforo value
    private func textColor() -> Color {
        switch networkManager.semaforo?.semaforo.uppercased() {
        case "VERDE":
            return .green
        case "GIALLO":
            return .yellow
        case "ROSSO":
            return .red
        default:
            return .black
        }
    }
    
    private func getNumeroFatturaColor(_ fattura: Fattura) -> Color {
        if fattura.pagato {
            return .green
        } else if let scadDate = parseDate(fattura.scadFattura) {
            let today = Calendar.current.startOfDay(for: Date())
            let scadDay = Calendar.current.startOfDay(for: scadDate)
            if scadDay < today {
                return .red
            } else {
                return .orange
            }
        }
        return .black
    }
}

#Preview {
    TaxView()
}
