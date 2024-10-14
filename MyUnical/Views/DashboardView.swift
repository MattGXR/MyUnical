//
//  HomeView.swift
//  MyUnical
//
//  Created by Mattia Meligeni on 13/10/24.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var networkMonitor: NetworkMonitor // Access NetworkMonitor
    @ObservedObject private var networkManager = NetworkManager.shared
    @Binding var selectedTab: Int
    @State private var showSimulation = false
    @State private var showingOfflineAlert = false
    
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
                        DashboardCard(title: "Media", value: String(format: "%.2f", networkManager.media), color: .blue)
                        DashboardCard(title: "CFU", value: "\(Int(networkManager.currentCfu))/\(networkManager.totalCfu)", color: .green)
                    }
                    .padding(.horizontal)
                    
                    HStack(spacing: 20) {
                        DashboardCard(title: "Base Laurea", value: String(format: "%.2f", networkManager.baseL), color: .purple)
                        DashboardCard(title: "CFU Rimanenti", value: "\(Int(Double(networkManager.totalCfu)-networkManager.currentCfu))", color: .red)
                    }
                    .padding(.horizontal)
                    
                    // Recent grades
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Ultimi voti")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(sortedVoti.prefix(3)) { voto in
                            GradeRow(voto: voto)
                                .padding(.horizontal)
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
            .alert(isPresented: $showingOfflineAlert) {
                Alert(
                    title: Text("Offline"),
                    message: Text("Al momento sei offline, vengono mostrati gli ultimi dati disponibili."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onReceive(networkMonitor.$isConnected) { isConnected in
                if !isConnected {
                    showingOfflineAlert = true
                }
            }
        }
    }
    
    // Computed property for greeting
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
    
    // Computed property for sorted grades
    var sortedVoti: [Voto] {
        networkManager.voti.sorted(by: { $0.date > $1.date })
    }
}

// DashboardCard.swift

import SwiftUI

struct DashboardCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack {
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
        .cornerRadius(15)
    }
}

// GradeRow.swift

import SwiftUI

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
        .padding(.vertical, 5)
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView(selectedTab: .constant(0))
            .environmentObject(NetworkMonitor.shared)
            .environmentObject(NetworkManager.shared)
    }
}
