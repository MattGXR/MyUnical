//
//  SimulationView.swift
//  MyUnical
//
//  Created by Mattia Meligeni on 13/10/24.
//

import SwiftUI

struct SimulationView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var networkManager = NetworkManager.shared
    @State private var newVote: Int = 18 // Default to the minimum allowed grade
    @State private var selectedCFU: Int = 9 // Default CFU value
    @State private var predictedAverage: Double?
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showCappedMessage = false
    @FocusState private var isInputActive: Bool
    
    @State private var isValutaLode: Bool = false
    @State private var selectedValutaLode: Double = 33 // Default value
    
    // Allowed CFU values
    let cfuOptions = [3, 6, 9, 12, 15]
    
    // Valuta Lode options
    let valutaLodeOptions: [Double] = [33, 32, 31]
    
    // Maximum allowed average
    let maxAverage: Double = 30.0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 15) {
                
                    HStack {
                        Text("Voto:")
                            .font(.headline)
                        /*Stepper(value: $newVote, in: 18...30) {
                            Text("")
                        }*/
                        Picker("Voto", selection: $newVote) {
                            ForEach(18...30, id: \.self) { value in
                                Text("\(value)")
                            }
                        }
                        Spacer()
                        .onChange(of: newVote) {
                            // Reset Valuta Lode when newVote changes from 30 to another value
                            if newVote != 30 && isValutaLode {
                                isValutaLode = false
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
                    .shadow(radius: 2)
                    
                    // CFU Input using Picker
                    VStack(alignment: .leading) {
                        Text("CFU")
                            .font(.headline)
                        Picker("CFU", selection: $selectedCFU) {
                            ForEach(cfuOptions, id: \.self) { cfu in
                                Text("\(cfu)").tag(cfu)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
                    .shadow(radius: 2)
                    
                    // Valuta Lode Toggle
                    Toggle(isOn: $isValutaLode) {
                        Text("Valuta Lode")
                            .font(.headline)
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
                    .shadow(radius: 2)
                    // Disable the toggle unless newVote is 30
                    .disabled(newVote != 30)
                    // Adjust the opacity to indicate disabled state
                    .opacity(newVote == 30 ? 1.0 : 0.6)
                    
                    // Conditional Dropdown Menu for Valuta Lode
                    if isValutaLode {
                        VStack(alignment: .leading) {
                            Text("Seleziona Valore Lode")
                                .font(.headline)
                            Picker("Valore Lode", selection: $selectedValutaLode) {
                                ForEach(valutaLodeOptions, id: \.self) { value in
                                    Text("\(value, specifier: "%.1f")").tag(value)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                        .shadow(radius: 2)
                    }
                    
                    // Display the estimated average if available
                    if let predictedAverage = predictedAverage {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Nuova media: \(predictedAverage, specifier: "%.2f")")
                                .font(.headline)
                                .foregroundColor(.orange)
                            
                            // Inline message if the average was capped
                            if showCappedMessage && predictedAverage == maxAverage {
                                Text("La media supererebbe \(Int(maxAverage)).")
                                    .foregroundColor(.red)
                                    .font(.subheadline)
                            }
                        }
                        .padding(.top)
                    }
                    
                    // Button to calculate the new average
                    Button(action: {
                        calculatePredictedAverage()
                        isInputActive = false // Dismiss keyboard after calculation
                    }) {
                        Text("Calcola")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(radius: 2)
                    }
                    .padding(.top)
                    .alert(isPresented: $showAlert) {
                        Alert(title: Text("Input non valido"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                    }
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("Simula nuovo voto")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Chiudi") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
        }
    }
    
    func calculatePredictedAverage() {
        let currentAvg = networkManager.media
        let currentCFU = networkManager.currentCfu
        
        let selectedCFUDouble = Double(selectedCFU)
        
        // Reset capping message
        showCappedMessage = false
        
        // Validate inputs
        guard newVote >= 18 && newVote <= 30 else {
            alertMessage = "Il voto deve essere un intero tra 18 e 30."
            showAlert = true
            return
        }
        
        guard cfuOptions.contains(selectedCFU) else {
            alertMessage = "CFU non valido. Seleziona un valore tra 3, 6, 9, 12, 15."
            showAlert = true
            return
        }
        
        // Calculate the current weighted sum of votes
        let currentWeightedSum = currentAvg * currentCFU
        
        // Determine the vote value, considering Valuta Lode if enabled
        var voteValue = Double(newVote)
        if isValutaLode {
            voteValue = selectedValutaLode
        }
        
        // Calculate the new total weighted sum
        let newWeightedSum = currentWeightedSum + (voteValue * selectedCFUDouble)
        
        // Calculate the new total CFU
        let totalCFUWithNew = currentCFU + selectedCFUDouble
        
        // Calculate the new weighted average
        var newAverage = newWeightedSum / totalCFUWithNew
        
        // Cap the new average at maxAverage
        if newAverage > maxAverage {
            newAverage = maxAverage
            showCappedMessage = true // Show inline message to inform the user
        }
        
        // Update the predictedAverage variable
        predictedAverage = newAverage
    }
}

#Preview {
    SimulationView()
}
