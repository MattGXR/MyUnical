//
//  TaxView.swift
//  MyUnical
//
//  Created by Mattia Meligeni on 14/10/24.
//

import SwiftUI

struct TaxView: View {
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @ObservedObject private var networkManager = NetworkManager.shared
    
    // State variables to handle sheet presentation
    @State private var isShowingIstruzioni = false
    @State private var selectedCodiceAvviso: String = ""
    @State private var selectedPrice: Double = 0
    @State private var selectedFattura: Fattura? = nil
    
    var body: some View {
        NavigationView {
            List {
                // Situazione Pagamenti Section
                Section(header: Text("Stato pagamenti")) {
                    HStack(spacing: 16) {
                        // Importo Dovuto Text
                        Text("Importo dovuto: €\(importoDovuto, specifier: "%.2f")")
                            .font(.headline)
                            .foregroundColor(textColor)
                    }
                    .padding(.vertical, 8)
                }
                
                // Fatture Section
                Section(header: Text("Fatture")) {
                    if networkManager.fatture.isEmpty {
                        Text("Nessuna fattura disponibile.")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(sortedFatture) { fattura in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Numero Fattura: \(String(fattura.fattId))")
                                    .font(.headline)
                                    .foregroundColor(getNumeroFatturaColor(fattura))
                                
                                Text("Codice Avviso: \(fattura.codiceAvviso)")
                                Text("Importo: €\(fattura.importoFattura, specifier: "%.2f")")
                                Text("Emissione: \(fattura.dataEmissione)")
                                Text("Scadenza: \(fattura.scadFattura)")
                                Text("Data Pagamento: \(fattura.dataPagamento)")
                                Text("Descrizione: \(fattura.desMav1)")
                                
                                Text("Pagato: \(fattura.pagato ? NSLocalizedString("Sì", comment: "") : NSLocalizedString("No", comment: ""))")
                                
                                // Add button if pagato is "No"
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
            .navigationTitle("Tasse")
            // Present IstruzioniView as a sheet
            .sheet(item: $selectedFattura) { fattura in
                IstruzioniView(codiceAvviso: fattura.codiceAvviso, price: fattura.importoFattura * 100)
            }
        }
    }
    
    var importoDovuto: Double {
        return networkManager.fatture
            .filter { $0.dataPagamento == "null" }
            .reduce(0) { $0 + $1.importoFattura }
    }
    
    private var sortedFatture: [Fattura] {
        networkManager.fatture.sorted {
            // Check if dataPagamento is "null" or a valid date string
            let isNull1 = $0.dataPagamento.lowercased() == "null"
            let isNull2 = $1.dataPagamento.lowercased() == "null"
            
            // Parse dates only if dataPagamento is not "null"
            let date1Pagamento = isNull1 ? nil : parseDate($0.dataPagamento)
            let date2Pagamento = isNull2 ? nil : parseDate($1.dataPagamento)
            
            // Determine if dataPagamento is missing
            if isNull1 && !isNull2 {
                return true
            }
            if !isNull1 && isNull2 {
                return false
            }
            if isNull1 && isNull2 {
                let emissione1 = parseDate($0.dataEmissione) ?? Date.distantPast
                let emissione2 = parseDate($1.dataEmissione) ?? Date.distantPast
                return emissione1 > emissione2
            }
            
            // Both dataPagamento are non-nil
            // Ensure that parsed dates are valid
            if let date1 = date1Pagamento, let date2 = date2Pagamento {
                return date1 > date2
            }
            
            // Fallback in case parsing fails
            return false
        }
    }
    
    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.date(from: dateString)
    }
    
    // Computed property to determine text color based on importoDovuto
    private var textColor: Color {
        if importoDovuto > 0 {
            return .yellow
        } else if importoDovuto == 0 {
            return .green
        } else {
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
