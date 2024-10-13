// GradesView.swift
// MyUnical
//
// Created by Mattia Meligeni on 13/10/24.
//

import SwiftUI

struct GradesView: View {
    @ObservedObject private var networkManager = NetworkManager.shared
    @State private var searchText: String = ""
    @State private var isSearching = false

    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Cerca insegnamento...", text: $searchText)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onTapGesture {
                                isSearching = true
                            }
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(7)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .animation(.default, value: isSearching)

                    if isSearching {
                        Button(action: {
                            isSearching = false
                            searchText = ""
                            hideKeyboard()
                        }) {
                            Text("Annulla")
                                .foregroundColor(.blue)
                        }
                        .padding(.trailing, 10)
                        .transition(.move(edge: .trailing))
                        .animation(.default, value: isSearching)
                    }
                }
                .padding(.top)

                // Filtered and sorted list
                List {
                    ForEach(filteredVoti.sorted(by: { $0.date > $1.date })) { voto in
                        GradeCard(voto: voto)
                            .listRowInsets(EdgeInsets())
                            .padding(.vertical, 5)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Libretto")
        }
    }

    // Filtered list based on search text
    var filteredVoti: [Voto] {
        if searchText.isEmpty {
            return networkManager.voti
        } else {
            return networkManager.voti.filter { $0.insegnamento.lowercased().contains(searchText.lowercased()) }
        }
    }
}

// Grade Card View
struct GradeCard: View {
    let voto: Voto

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                // Voto Badge
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 50, height: 50)
                    Text("\(voto.voto)")
                        .font(.headline)
                        .foregroundColor(.white)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 5) {
                    Text(voto.insegnamento)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("CFU: \(voto.cfu)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(voto.dataAppello)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)

            Divider()
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// Extension to hide keyboard
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
