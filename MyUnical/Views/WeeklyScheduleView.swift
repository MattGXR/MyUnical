import SwiftUI
import AVFoundation

// MARK: - Data Models

/// Enum for days of the week.
enum Weekday: String, CaseIterable, Identifiable, Comparable, Codable {
    var id: String { self.rawValue }
    
    case Lunedì, Martedì, Mercoledì, Giovedì, Venerdì
    
    // Conform to Comparable
    static func < (lhs: Weekday, rhs: Weekday) -> Bool {
        lhs.orderIndex < rhs.orderIndex
    }
    
    // Provide an order index for comparison
    private var orderIndex: Int {
        switch self {
        case .Lunedì: return 1
        case .Martedì: return 2
        case .Mercoledì: return 3
        case .Giovedì: return 4
        case .Venerdì: return 5
        }
    }
    
    /// Computed property to get the localized name of the weekday
    var localizedName: String {
        // Use the enum case's raw value as the localization key
        NSLocalizedString("\(self.rawValue)", comment: "Name of the weekday")
    }
}

/// Predefined color options.
struct ColorOption: Identifiable, Equatable, Hashable {
    let id = UUID()
    let colorName: String
    let color: Color
}

let predefinedColors: [ColorOption] = [
    ColorOption(colorName: "Blu", color: .blue),
    ColorOption(colorName: "Rosso", color: .red),
    ColorOption(colorName: "Verde", color: .green),
    ColorOption(colorName: "Arancione", color: .orange),
    ColorOption(colorName: "Viola", color: .purple),
    ColorOption(colorName: "Rosa", color: .pink),
    ColorOption(colorName: "Giallo", color: .yellow),
    ColorOption(colorName: "Marrone", color: .brown),
]

/// Helper function to get Color from colorName
func colorFromName(_ name: String) -> Color {
    predefinedColors.first(where: { $0.colorName == name })?.color ?? .blue
}

/// Helper function to create a Date with specific hour and minute.
func timeFor(hour: Int, minute: Int) -> Date {
    let calendar = Calendar.current
    var components = DateComponents()
    components.hour = hour
    components.minute = minute
    return calendar.date(from: components) ?? Date()
}

// MARK: - Main View

struct WeeklyScheduleView: View {
    @State private var lectures: [Lecture] = []
    @State private var searchText: String = ""
    @State private var selectedDayFilter: Weekday? = nil
    @State private var showAddLectureSheet: Bool = false
    @State private var lectureToEdit: Lecture? = nil
    @State private var showNoLecturesAlert: Bool = false
    @State private var showNoFeatureAlert: Bool = false
    @State private var showCurrentLectures: Bool = false
    @State private var isViewVisible: Bool = false
    @State private var showRecordingsView: Bool = false
    
    
    
    var body: some View {
        NavigationView {
            VStack {
                SearchAndFilterView(
                    searchText: $searchText,
                    selectedDayFilter: $selectedDayFilter,
                    showCurrentLectures: $showCurrentLectures  // Pass the binding
                )
                LectureListView(
                    lectures: $lectures,
                    searchText: $searchText,
                    selectedDayFilter: $selectedDayFilter,
                    lectureToEdit: $lectureToEdit,
                    showAddLectureSheet: $showAddLectureSheet,
                    showCurrentLectures: $showCurrentLectures  // Pass the binding
                )
            }
            .navigationBarTitle("Orario")
            .navigationBarItems(
                leading: Button(action: {
                    //showRecordingsView = true
                    showNoFeatureAlert = true
                }) {
                    Image(systemName: "waveform.circle")
                },
                trailing: Button(action: {
                    lectureToEdit = nil
                    showAddLectureSheet = true
                }) {
                    Image(systemName: "plus.circle")
                      
                }
                
            )
            .sheet(isPresented: $showAddLectureSheet) {
                AddEditLectureView(
                    lectures: $lectures, lectureToEdit: $lectureToEdit, selectedWeekDay: $selectedDayFilter)
            }
            .sheet(isPresented: $showRecordingsView) {
                RegistrazioniView()
            }
            .onAppear {
                isViewVisible = true
                loadLectures()
                setInitialDayFilter()
                showCurrentLectures = true
            }
            .onDisappear {
                isViewVisible = false
                showNoLecturesAlert = false
            }
            .alert(isPresented: $showNoLecturesAlert) {
                Alert(
                    title: Text("Nessuna lezione"),
                    message: Text("Non hai ancora aggiunto nessuna lezione."),
                    dismissButton: .default(Text("OK")))
            }
            .alert(isPresented: $showNoFeatureAlert) {
                Alert(
                    title: Text("Errore"),
                    message: Text("La funzione non è ancora disponibile"),
                    dismissButton: .default(Text("OK")))
            }
            .onChange(of: lectures) {
                saveLectures()
            }
        }
    }
    
    /// Sets the initial day filter to the current weekday.
    func setInitialDayFilter() {
        if let currentWeekday = currentWeekday() {
            selectedDayFilter = currentWeekday
        } else {
            selectedDayFilter = nil
        }
    }
    
    /// Returns the current weekday as a `Weekday` enum.
    func currentWeekday() -> Weekday? {
        let weekdayNumber = Calendar.current.component(.weekday, from: Date())
        // Sunday = 1, Monday = 2, ..., Saturday = 7
        switch weekdayNumber {
        case 2:
            return .Lunedì
        case 3:
            return .Martedì
        case 4:
            return .Mercoledì
        case 5:
            return .Giovedì
        case 6:
            return .Venerdì
        default:
            return nil
        }
    }
    
    /// Loads lectures from the "schedule.json" file.
    func loadLectures() {
        if let loadedLectures = DataPersistence.shared.load(
            "schedule.json", as: [Lecture].self)
        {
            lectures = loadedLectures
        } else {
            lectures = []
        }
        if lectures.isEmpty && isViewVisible {
            showNoLecturesAlert = true
        }
    }
    
    /// Saves lectures to the "schedule.json" file.
    func saveLectures() {
        DataPersistence.shared.save(lectures, to: "schedule.json")
    }
}

// MARK: - Search and Filter View

struct SearchAndFilterView: View {
    @Binding var searchText: String
    @Binding var selectedDayFilter: Weekday?
    @Binding var showCurrentLectures: Bool // New Binding
    
    var body: some View {
        VStack {
            // Search Bar
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Cerca lezioni...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(EdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 6))
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .padding()
            
            // Weekday Picker
            Picker("Giorno", selection: $selectedDayFilter) {
                Text("Tutti").tag(Weekday?.none)
                ForEach(Weekday.allCases) { day in
                    Text(day.localizedName).tag(Optional(day))
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding([.leading, .trailing])
            .onChange(of: selectedDayFilter) {
                if selectedDayFilter != currentWeekday() {
                    showCurrentLectures = false
                }
            }
            
            // "Ora" Button Positioned Underneath the Weekday Picker
            HStack {
                Spacer()
                Button(action: {
                    if showCurrentLectures {
                        showCurrentLectures = false
                    } else {
                        if selectedDayFilter != nil && currentWeekday() != nil {
                            showCurrentLectures = true
                            if selectedDayFilter != currentWeekday() {
                                selectedDayFilter = currentWeekday()
                            }
                        }
                        
                    }
                }) {
                    Text("Ora")
                        .padding(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .background(showCurrentLectures ? Color.blue : Color.clear)
                        .foregroundColor(showCurrentLectures ? .white : .blue)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                        .cornerRadius(5)
                }
                Spacer()
                
            }
            .onAppear {
                if selectedDayFilter == nil {
                    showCurrentLectures = false
                }
            }
            .padding([.top, .bottom], 8)
        }
    }
    /// Returns the current weekday as a `Weekday` enum.
    func currentWeekday() -> Weekday? {
        let weekdayNumber = Calendar.current.component(.weekday, from: Date())
        // Sunday = 1, Monday = 2, ..., Saturday = 7
        switch weekdayNumber {
        case 2:
            return .Lunedì
        case 3:
            return .Martedì
        case 4:
            return .Mercoledì
        case 5:
            return .Giovedì
        case 6:
            return .Venerdì
        default:
            return nil
        }
    }
}


// MARK: - Lecture List View
import SwiftUI
import AVFoundation

struct LectureListView: View {
    @Binding var lectures: [Lecture]
    @Binding var searchText: String
    @Binding var selectedDayFilter: Weekday?
    @Binding var lectureToEdit: Lecture?
    @Binding var showAddLectureSheet: Bool
    @Binding var showCurrentLectures: Bool
    //@ObservedObject var recordingManager = RecordingManager() Add future recordingmanager
    
    // State to manage which lecture is selected for recording
    @State private var selectedLectureForRecording: Lecture? = nil
    @State private var showRecordingSheet: Bool = false
    
    var body: some View {
        List {
            if filteredLectures.isEmpty {
                Section {
                    VStack {
                        Spacer()
                        Image(systemName: "exclamationmark.magnifyingglass")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 70)
                            .foregroundColor(.blue)
                        Text("Non c'è nulla qui")
                            .font(.title2)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                       
                    }
                    .frame(maxWidth: .infinity)
                    
                }
            } else {
                ForEach(groupedLectures.keys.sorted(), id: \.self) { day in
                    Section(header: Text(day.localizedName)) {
                        ForEach(groupedLectures[day]!) { lecture in
                            LectureRow(
                                lecture: lecture,
                                lectures: lectures
                            )
                            .contentShape(Rectangle())
                            // Trailing Swipe Actions (Delete & Edit)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    deleteLecture(lecture)
                                } label: {
                                    Label("Elimina", systemImage: "trash")
                                }
                                
                                Button {
                                    lectureToEdit = lecture
                                    showAddLectureSheet = true
                                } label: {
                                    Label("Modifica", systemImage: "pencil")
                                }
                                .tint(.orange)
                            }
                            
                            // Leading Swipe Actions (Enable/Disable & Record)
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    toggleDisableLecture(lecture)
                                } label: {
                                    if lecture.isDisabled {
                                        Label("Abilita", systemImage: "checkmark.circle")
                                    } else {
                                        Label("Disabilita", systemImage: "slash.circle")
                                    }
                                }
                                .tint(.gray)
                                /*
                                 Button {
                                 selectedLectureForRecording = lecture
                                 showRecordingSheet = true
                                 } label: {
                                 Label("Record", systemImage: "mic.fill")
                                 }
                                 .tint(.red)
                                 */
                            }
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .sheet(isPresented: $showRecordingSheet) {
            if let lecture = selectedLectureForRecording {
                //RecordingView(lecture: lecture, recordingManager: recordingManager) Add recording view
            }
        }
    }
    
    var filteredLectures: [Lecture] {
        lectures.filter { lecture in
            let matchesSearchText = searchText.isEmpty || lecture.title.localizedCaseInsensitiveContains(searchText)
            let matchesDayFilter = selectedDayFilter == nil || lecture.day == selectedDayFilter
            let matchesCurrentLecture = !showCurrentLectures || (isLectureCurrentlyOngoing(lecture) && !lecture.isDisabled)
            return matchesSearchText && matchesDayFilter && matchesCurrentLecture
        }
    }
    
    var groupedLectures: [Weekday: [Lecture]] {
        let grouped = Dictionary(grouping: filteredLectures) { $0.day }
        let sortedGrouped = grouped.mapValues { lectures in
            lectures.sorted(by: { lecture1, lecture2 in
                lecture1.normalizedStartTime ?? Date.distantPast < lecture2.normalizedStartTime ?? Date.distantPast
            })
        }
        return sortedGrouped
    }
    
    func deleteLecture(_ lecture: Lecture) {
        if let index = lectures.firstIndex(of: lecture) {
            lectures.remove(at: index)
        }
    }
    
    func toggleDisableLecture(_ lecture: Lecture) {
        if let index = lectures.firstIndex(of: lecture) {
            lectures[index].isDisabled.toggle()
        }
    }
    
    /// Checks if the lecture is currently ongoing
    func isLectureCurrentlyOngoing(_ lecture: Lecture) -> Bool {
        guard let lectureStartTimeToday = lecture.normalizedStartTime,
              let lectureEndTimeToday = lecture.normalizedEndTime else {
            return false
        }
        let now = Date()
        return lectureStartTimeToday <= now && now <= lectureEndTimeToday
    }
}

// Extension for Lecture to get normalized times
extension Lecture {
    var normalizedStartTime: Date? {
        combineDateWithTime(date: Date(), time: startTime)
    }
    
    var normalizedEndTime: Date? {
        combineDateWithTime(date: Date(), time: endTime)
    }
}

// Helper function to combine date and time
func combineDateWithTime(date: Date, time: Date) -> Date? {
    let calendar = Calendar.current
    let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
    let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
    var combinedComponents = DateComponents()
    combinedComponents.year = dateComponents.year
    combinedComponents.month = dateComponents.month
    combinedComponents.day = dateComponents.day
    combinedComponents.hour = timeComponents.hour
    combinedComponents.minute = timeComponents.minute
    combinedComponents.second = timeComponents.second
    return calendar.date(from: combinedComponents)
}

// MARK: - Lecture Row

struct LectureRow: View {
    let lecture: Lecture
    let lectures: [Lecture]
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if lecture.isDisabled {
                    Image(systemName: "slash.circle")
                        .foregroundColor(.gray)
                        .frame(width: 10, height: 10)
                } else {
                    Circle()
                        .fill(colorFromName(lecture.colorName))
                        .frame(width: 10, height: 10)
                }
                Text(lecture.title)
                    .font(.headline)
                    .foregroundColor(lecture.isDisabled ? .gray : .primary)
                if isOverlapping() {
                    Text("Sovrapposizione")
                        .font(.caption)
                        .padding(4)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(5)
                }
                Spacer()
                if lecture.notes != nil && !lecture.notes!.isEmpty {
                    Button(action: {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            HStack {
                Text("\(formattedTime(lecture.startTime)) - \(formattedTime(lecture.endTime))")
                    .font(.subheadline)
                    .foregroundColor(lecture.isDisabled ? .gray : .secondary)
                Spacer()
                Text(lecture.location ?? "Nessun'aula")
                    .font(.subheadline)
                    .foregroundColor(lecture.location == nil || lecture.location?.isEmpty == true ? .red : (lecture.isDisabled ? .gray : .secondary))
            }
            if isExpanded, let notes = lecture.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .transition(.opacity)
            }
        }
        .padding(.vertical, 5)
        .contentShape(Rectangle())
    }
    
    /// Checks if the lecture overlaps with any other lecture on the same day.
    func isOverlapping() -> Bool {
        for otherLecture in lectures {
            if otherLecture.id != lecture.id && otherLecture.day == lecture.day && !otherLecture.isDisabled {
                if let lectureStart = lecture.normalizedStartTime,
                   let lectureEnd = lecture.normalizedEndTime,
                   let otherStart = otherLecture.normalizedStartTime,
                   let otherEnd = otherLecture.normalizedEndTime {
                    if lectureStart < otherEnd && lectureEnd > otherStart {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Add/Edit Lecture View

struct AddEditLectureView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var lectures: [Lecture]
    @Binding var lectureToEdit: Lecture?
    @Binding var selectedWeekDay: Weekday?
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var title: String = ""
    @State private var selectedDay: Weekday = .Lunedì
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date().addingTimeInterval(5400)
    @State private var location: String = ""
    @State private var selectedColorOption: ColorOption = predefinedColors
        .first!
    @State private var notes: String = ""
    @State private var noteCharacterLimit: Int = 250
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Dettagli Lezione")) {
                    TextField("Titolo", text: $title)
                    Picker("Giorno", selection: $selectedDay) {
                        ForEach(Weekday.allCases) { day in
                            Text(day.localizedName).tag(day)
                        }
                    }
                    
                    HStack {
                        Text("Ora Inizio")
                        Spacer()
                        DatePicker(
                            "", selection: $startTime,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(CompactDatePickerStyle())
                        .labelsHidden()
                        
                    }
                    HStack {
                        Text("Ora Fine")
                        Spacer()
                        DatePicker(
                            "", selection: $endTime,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(CompactDatePickerStyle())
                        .labelsHidden()
                        
                    }
                    
                    TextField("Aula (opzionale)", text: $location)
                    Picker("Colore", selection: $selectedColorOption) {
                        ForEach(predefinedColors) { option in
                            HStack {
                                Circle()
                                    .fill(option.color)
                                    .frame(width: 20, height: 20)
                                Text(option.colorName)
                            }.tag(option)
                        }
                    }
                }
                Section(
                    header: Text("Note (max \(noteCharacterLimit) caratteri)")
                ) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                        .onChange(of: notes) {
                            if notes.count > noteCharacterLimit {
                                notes = String(notes.prefix(noteCharacterLimit))
                            }
                        }
                }
            }
            .navigationBarTitle(
                lectureToEdit == nil ? "Aggiungi Lezione" : "Modifica Lezione"
            )
            .navigationBarItems(
                leading: Button("Annulla") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Salva") {
                    saveLecture()
                }
            )
            .onAppear(perform: populateFields)
        }
        .onAppear {
            UIDatePicker.appearance().minuteInterval = 15
            selectedDay = selectedWeekDay ?? .Lunedì
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Errore"), message: Text(alertMessage),
                dismissButton: .default(Text("OK")))
        }
    }
    
    func populateFields() {
        if let lecture = lectureToEdit {
            title = lecture.title
            selectedDay = lecture.day
            startTime = lecture.startTime
            endTime = lecture.endTime
            location = lecture.location ?? ""
            selectedColorOption =
            predefinedColors.first(where: {
                $0.colorName == lecture.colorName
            }) ?? predefinedColors.first!
            notes = lecture.notes ?? ""
        }
    }
    
    func saveLecture() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.isEmpty {
            alertMessage = "È necessario un titolo per aggiungere una lezione"
            showAlert = true
            return
        }
        
        let newLecture = Lecture(
            title: trimmedTitle,
            day: selectedDay,
            startTime: startTime,
            endTime: endTime,
            location: location.isEmpty ? nil : location,
            isDisabled: lectureToEdit?.isDisabled ?? false,
            colorName: selectedColorOption.colorName,
            notes: notes.isEmpty ? nil : notes
        )
        
        if let lectureToEdit = lectureToEdit {
            if let index = lectures.firstIndex(of: lectureToEdit) {
                lectures[index] = newLecture
            }
        } else {
            lectures.append(newLecture)
        }
        presentationMode.wrappedValue.dismiss()
    }
    
}

// MARK: - Preview

struct WeeklyScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        WeeklyScheduleView()
    }
}
