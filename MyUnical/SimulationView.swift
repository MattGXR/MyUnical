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
    @State private var selectedCFU: Int = 3 // Default CFU value
    @State private var predictedAverage: Double?
    @State private var showAlert = false
    @State private var alertMessage = ""
    @FocusState private var isInputActive: Bool

    // Allowed CFU values
    let cfuOptions = [3, 6, 9, 12, 15]

    var body: some View {
        NavigationView {
            VStack(spacing: 15) {
                Text("Simula nuovo voto")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.primary)

                // Voto Input using Stepper
                HStack {
                    Text("Voto: \(newVote)")
                        .font(.headline)
                    Spacer()
                    Stepper(value: $newVote, in: 18...30) {
                        Text("")
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

                // Display the estimated average if available
                if let predictedAverage = predictedAverage {
                    Text("Nuova media: \(predictedAverage, specifier: "%.2f")")
                        .font(.headline)
                        .foregroundColor(.orange)
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
            .navigationTitle("Simulatore")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Chiudi") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

    func calculatePredictedAverage() {
        let currentAvg = networkManager.media
        let currentCFU = networkManager.currentCfu

        let selectedCFUDouble = Double(selectedCFU)

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

        // Calculate the new total weighted sum
        let newWeightedSum = currentWeightedSum + (Double(newVote) * selectedCFUDouble)

        // Calculate the new total CFU
        let totalCFUWithNew = currentCFU + selectedCFUDouble

        // Calculate the new weighted average
        let newAverage = newWeightedSum / totalCFUWithNew

        // Update the predictedAverage variable
        predictedAverage = newAverage
    }
}
