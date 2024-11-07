//
//  RegistrazioniView.swift
//  MyUnical
//
//  Created by Mattia Meligeni on 06/11/24.
//

import SwiftUI

// MARK: - Model

struct Recording: Identifiable {
    let id: UUID
    var title: String
    let date: Date
    // Removed duration and fileURL since we're not including actual recordings
}

// Sample Data
let sampleRecordings = [
    Recording(id: UUID(), title: "Team Meeting", date: Date()),
    Recording(id: UUID(), title: "Lecture Notes", date: Date().addingTimeInterval(-86400)),
    Recording(id: UUID(), title: "Interview", date: Date().addingTimeInterval(-172800))
]

// MARK: - ViewModel

class RecordingsViewModel: ObservableObject {
    @Published var recordings: [Recording] = sampleRecordings
    
    func deleteRecording(at offsets: IndexSet) {
        recordings.remove(atOffsets: offsets)
    }
    
    func addRecording(_ recording: Recording) {
        recordings.append(recording)
    }
}

// MARK: - Main View

struct RegistrazioniView: View {
    @ObservedObject var viewModel = RecordingsViewModel()
    @State private var selectedRecordingIndex: Int?
    @State private var isShowingRenameSheet = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Numero Registrazioni: \(viewModel.recordings.count)")) {
                    ForEach(viewModel.recordings) { recording in
                        RecordingRow(
                            recording: recording,
                            renameAction: renameRecording
                        )
                    }
                    .onDelete { indexSet in
                        withAnimation {
                            viewModel.deleteRecording(at: indexSet)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Registrazioni")
            .navigationBarItems(trailing:
                Button(action: {
                    addNewRecording()
                }) {
                    Image(systemName: "plus")
                }
            )
            .sheet(isPresented: $isShowingRenameSheet) {
                if let index = selectedRecordingIndex {
                    RenameRecordingView(recording: $viewModel.recordings[index])
                }
            }
        }
    }
    
    // MARK: - Actions
    
    func renameRecording(_ recording: Recording) {
        if let index = viewModel.recordings.firstIndex(where: { $0.id == recording.id }) {
            selectedRecordingIndex = index
            isShowingRenameSheet = true
        }
    }
    
    func addNewRecording() {
        // Placeholder for adding a new recording
        let newRecording = Recording(
            id: UUID(),
            title: "Nuova Registrazione",
            date: Date()
        )
        viewModel.addRecording(newRecording)
    }
}

// MARK: - Recording Row

struct RecordingRow: View {
    let recording: Recording
    let renameAction: (Recording) -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "waveform.circle.fill")
                .font(.largeTitle)
                .foregroundColor(.blue)
            VStack(alignment: .leading) {
                Text(recording.title)
                    .font(.headline)
                Text(formattedDate(recording.date))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(.vertical, 8)
        .contextMenu {
            Button(action: {
                renameAction(recording)
            }) {
                Label("Rinomina", systemImage: "pencil")
            }
        }
    }
    
    // MARK: - Helpers
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Rename Recording View

struct RenameRecordingView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var recording: Recording
    @State private var newName: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Inserisci nuovo nome")) {
                    TextField("Nome Registrazione", text: $newName)
                }
            }
            .navigationBarTitle("Rinomina Registrazione", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Annulla") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Salva") {
                    recording.title = newName
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(newName.isEmpty)
            )
            .onAppear {
                newName = recording.title
            }
        }
    }
}

// MARK: - Preview

struct RegistrazioniView_Previews: PreviewProvider {
    static var previews: some View {
        RegistrazioniView()
    }
}
