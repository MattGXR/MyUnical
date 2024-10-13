//
//  HomeView.swift
//  MyUnical
//
//  Created by Mattia Meligeni on 13/10/24.
//

// DashboardView.swift
// MyUnical
//
// Created by Mattia Meligeni on 13/10/24.
//

import SwiftUI

struct DashboardView: View {
    @ObservedObject private var networkManager = NetworkManager.shared
    @Binding var selectedTab: Int
    @State private var showSimulation = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome message
                    Text("\(greeting), \(networkManager.userName)")
                        .font(.title)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    // Cards with key information
                    HStack(spacing: 20) {
                        DashboardCard(title: "Media Ponderata", value: String(format: "%.2f", networkManager.media), color: .blue)
                        DashboardCard(title: "CFU", value: "\(Int(networkManager.currentCfu))/\(networkManager.totalCfu)", color: .green)
                    }
                    .padding(.horizontal)

                    // Recent grades
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Ultimi voti")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(sortedVoti.prefix(3)) { voto in
                            GradeRow(voto: voto)
                        }

                        // Button to navigate to the "Libretto" tab
                        Button(action: {
                            selectedTab = 1 // Set the tab index to the "Libretto" tab
                        }) {
                            Text("Visualizza tutti i voti")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .padding(.horizontal)
                                .padding(.top, 5)
                        }
                    }

                    // Simulation Button
                    Button(action: {
                        showSimulation = true
                    }) {
                        HStack {
                            Image(systemName: "graduationcap")
                            Text("Simula nuovo voto")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    .sheet(isPresented: $showSimulation) {
                        SimulationView()
                    }

                    Spacer()
                }
            }
            .navigationTitle("Dashboard")
        }
    }
    var greeting: String {
        switch networkManager.sex {
        case "F":
            return "Benvenuta"
        case "M":
            return "Benvenuto"
        default:
            return "Benvenuto/a"
        }
    }
    var sortedVoti: [Voto] {
        networkManager.voti.sorted(by: { $0.date > $1.date })
    }
}

// Reusable information card for displaying main data
struct DashboardCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)

            Text(value)
                .font(.largeTitle)
                .bold()
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color)
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

struct GradeRow: View {
    let voto: Voto

    var body: some View {
        HStack {
            // Voto Badge
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 40, height: 40)
                Text("\(voto.voto)")
                    .font(.headline)
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading) {
                Text(voto.insegnamento)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Text(voto.dataAppello)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 5)
    }
}
