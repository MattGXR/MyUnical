//
//  RegistrazioniView.swift
//  MyUnical
//
//  Created by Mattia Meligeni on 06/11/24.
//

import SwiftUI
import AVFoundation
import AVKit

// MARK: - Model

struct Recording: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    let date: Date
    var fileRelativePath: String

    // Equatable conformance
    static func == (lhs: Recording, rhs: Recording) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.date == rhs.date &&
               lhs.fileRelativePath == rhs.fileRelativePath
    }
}

// MARK: - ViewModel

class RecordingsViewModel: ObservableObject {
    @Published var recordings: [Recording] = []
    @Published var isRecording = false
    @Published var recordingPermissionsGranted = false
    @Published var currentlyPlayingRecording: Recording?
    @Published var isPlaying = false

    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    let recordingSession = AVAudioSession.sharedInstance()

    let dataPersistence = DataPersistence.shared
    let recordingsFilename = "recordings.json"

    init() {
        requestPermission()
        loadRecordings()
        setupAudioSession()
    }

    // MARK: - Permissions

    func requestPermission() {
        recordingSession.requestRecordPermission { [weak self] allowed in
            DispatchQueue.main.async {
                self?.recordingPermissionsGranted = allowed
                if allowed {
                    do {
                        try self?.recordingSession.setCategory(.playAndRecord, mode: .default)
                        try self?.recordingSession.setActive(true)
                    } catch {
                        print("Failed to set up recording session: \(error)")
                    }
                } else {
                    print("Recording permission not granted.")
                }
            }
        }
    }

    // MARK: - Recording Functions

    func startRecording() {
        let filename = "\(UUID().uuidString).m4a"
        let audioFilename = getDocumentsDirectory().appendingPathComponent(filename)

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100, // Standard sample rate for quality audio
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            isRecording = true
        } catch {
            print("Could not start recording: \(error)")
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false

        if let url = audioRecorder?.url {
            let relativePath = url.lastPathComponent
            let newRecording = Recording(id: UUID(), title: "Nuova Registrazione", date: Date(), fileRelativePath: relativePath)
            recordings.insert(newRecording, at: 0)
            saveRecordings()
        }

        audioRecorder = nil
    }

    func deleteRecording(at offsets: IndexSet) {
        for index in offsets {
            let recording = recordings[index]
            do {
                let fileURL = getDocumentsDirectory().appendingPathComponent(recording.fileRelativePath)
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                print("Failed to delete recording: \(error)")
            }
        }
        recordings.remove(atOffsets: offsets)
        saveRecordings()
    }

    // MARK: - Playback Functions

    func play(_ recording: Recording) {
        let fileURL = getDocumentsDirectory().appendingPathComponent(recording.fileRelativePath)
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
            audioPlayer?.play()
            currentlyPlayingRecording = recording
            isPlaying = true
        } catch {
            print("Failed to play recording: \(error)")
        }
    }

    func pause() {
        audioPlayer?.pause()
        isPlaying = false
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        currentlyPlayingRecording = nil
        isPlaying = false
    }

    // MARK: - Data Persistence

    func loadRecordings() {
        if let savedRecordings: [Recording] = dataPersistence.load(recordingsFilename, as: [Recording].self) {
            self.recordings = savedRecordings
        } else {
            self.recordings = []
        }
    }

    func saveRecordings() {
        dataPersistence.save(recordings, to: recordingsFilename)
    }

    func renameRecording(_ recording: Recording, newName: String) {
        let newFilename = "\(newName).m4a"
        let oldURL = getDocumentsDirectory().appendingPathComponent(recording.fileRelativePath)
        let newURL = getDocumentsDirectory().appendingPathComponent(newFilename)
        do {
            try FileManager.default.moveItem(at: oldURL, to: newURL)
            if let index = recordings.firstIndex(where: { $0.id == recording.id }) {
                recordings[index].title = newFilename
                recordings[index].fileRelativePath = newFilename
                saveRecordings()
            }
        } catch {
            print("Failed to rename recording: \(error)")
        }
    }

    // MARK: - Helper Functions

    /// Returns the URL to the app's Documents directory.
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    func shareRecording(_ recording: Recording) -> URL {
        getDocumentsDirectory().appendingPathComponent(recording.fileRelativePath)
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
    }
}

// MARK: - Main View

struct RegistrazioniView: View {
    @ObservedObject var viewModel = RecordingsViewModel()
    @State private var selectedRecordingIndex: Int?
    @State private var isShowingRenameSheet = false
    @State private var searchText = ""
    @State private var selectedRecording: Recording?

    var filteredRecordings: [Recording] {
        if searchText.isEmpty {
            return viewModel.recordings
        } else {
            return viewModel.recordings.filter { $0.title.lowercased().contains(searchText.lowercased()) }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.recordingPermissionsGranted {
                    recordingsList
                        .listStyle(InsetGroupedListStyle())
                        .navigationTitle("Registrazioni")
                        .searchable(text: $searchText, prompt: "Cerca registrazioni")
                        .toolbar {
                            ToolbarItemGroup(placement: .navigationBarTrailing) {
                                recordButton
                            }
                        }
                        .sheet(isPresented: $isShowingRenameSheet) {
                            if let index = selectedRecordingIndex {
                                RenameRecordingView(
                                    recording: $viewModel.recordings[index],
                                    onSave: { newName in
                                        viewModel.renameRecording(viewModel.recordings[index], newName: newName)
                                    }
                                )
                            }
                        }
                } else {
                    Text("Permesso di registrazione non concesso. Controlla le impostazioni.")
                        .padding()
                }
            }
        }
    }

    // MARK: - Subviews

    private var recordingsList: some View {
        List {
            Section(header: Text("Numero Registrazioni: \(filteredRecordings.count)")) {
                ForEach(filteredRecordings) { recording in
                    recordingRow(for: recording)
                }
                .onDelete(perform: viewModel.deleteRecording)
            }
        }
    }

    private func recordingRow(for recording: Recording) -> some View {
        RecordingRow(recording: recording, viewModel: viewModel)
            .contextMenu {
                Button(action: {
                    renameRecording(recording)
                }) {
                    Label("Rinomina", systemImage: "pencil")
                }
                Button(role: .destructive, action: {
                    if let index = viewModel.recordings.firstIndex(where: { $0.id == recording.id }) {
                        viewModel.deleteRecording(at: IndexSet(integer: index))
                    }
                }) {
                    Label("Elimina", systemImage: "trash")
                }
            }
            .swipeActions(edge: .trailing) {
                Button {
                    let url = viewModel.shareRecording(recording)
                    let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                    UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true, completion: nil)
                } label: {
                    Label("Condividi", systemImage: "square.and.arrow.up")
                }
                .tint(.blue)
            }
    }

    private var recordButton: some View {
        Button(action: {
            if viewModel.isRecording {
                viewModel.stopRecording()
            } else {
                viewModel.startRecording()
            }
        }) {
            Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(viewModel.isRecording ? .red : .blue)
        }
    }

    // MARK: - Actions

    func renameRecording(_ recording: Recording) {
        if let index = viewModel.recordings.firstIndex(where: { $0.id == recording.id }) {
            selectedRecordingIndex = index
            isShowingRenameSheet = true
        }
    }
}

// MARK: - Recording Row

struct RecordingRow: View {
    let recording: Recording
    @ObservedObject var viewModel: RecordingsViewModel

    var body: some View {
        HStack {
            Button(action: {
                if viewModel.currentlyPlayingRecording == recording {
                    if viewModel.isPlaying {
                        viewModel.pause()
                    } else {
                        viewModel.play(recording)
                    }
                } else {
                    viewModel.stop()
                    viewModel.play(recording)
                }
            }) {
                Image(systemName: playButtonImageName)
                    .font(.title)
                    .foregroundColor(playButtonColor)
            }
            VStack(alignment: .leading) {
                Text(recording.title)
                    .font(.headline)
                Text(formattedDate(recording.date))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
            if viewModel.currentlyPlayingRecording == recording {
                AudioPlayerControls(viewModel: viewModel)
            }
        }
        .padding(.vertical, 8)
        .swipeActions(edge: .leading) {
            Button(role: .destructive) {
                if let index = viewModel.recordings.firstIndex(where: { $0.id == recording.id }) {
                    viewModel.deleteRecording(at: IndexSet(integer: index))
                }
            } label: {
                Label("Elimina", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing) {
            Button {
                let url = viewModel.shareRecording(recording)
                let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true, completion: nil)
            } label: {
                Label("Condividi", systemImage: "square.and.arrow.up")
            }
            .tint(.blue)
        }
    }

    private var playButtonImageName: String {
        if viewModel.currentlyPlayingRecording == recording {
            return viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill"
        } else {
            return "play.circle"
        }
    }

    private var playButtonColor: Color {
        viewModel.currentlyPlayingRecording == recording ? .blue : .gray
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct AudioPlayerControls: View {
    @ObservedObject var viewModel: RecordingsViewModel

    var body: some View {
        HStack(spacing: 20) {
            Button(action: {
                viewModel.stop()
            }) {
                Image(systemName: "stop.fill")
                    .foregroundColor(.red)
            }
            
            Button(action: {
                if viewModel.isPlaying {
                    viewModel.pause()
                } else if let currentRecording = viewModel.currentlyPlayingRecording {
                    viewModel.play(currentRecording)
                }
            }) {
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .foregroundColor(.blue)
            }
        }
    }
}

// MARK: - Rename Recording View

struct RenameRecordingView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var recording: Recording
    @State private var newName: String = ""
    var onSave: (String) -> Void

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
                    onSave(newName)
                    recording.title = "\(newName).m4a"
                    recording.fileRelativePath = "\(newName).m4a"
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(newName.isEmpty)
            )
            .onAppear {
                newName = recording.title.replacingOccurrences(of: ".m4a", with: "")
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
