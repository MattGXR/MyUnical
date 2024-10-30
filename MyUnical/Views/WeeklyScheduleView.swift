import SwiftUI

// MARK: - Data Models

/// Represents a lecture with its details.
struct Lecture: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var day: Weekday
    var startTime: Date
    var endTime: Date
    var location: String?
    var isDisabled: Bool = false
    var colorName: String // Store color as a string name
    var notes: String?
    
    init(id: UUID = UUID(), title: String, day: Weekday, startTime: Date, endTime: Date, location: String?, isDisabled: Bool = false, colorName: String, notes: String?) {
        self.id = id
        self.title = title
        self.day = day
        self.startTime = startTime
        self.endTime = endTime
        self.location = location
        self.isDisabled = isDisabled
        self.colorName = colorName
        self.notes = notes
    }
}

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
}

// MARK: - Predefined Colors

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

// MARK: - Helper Functions

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
    
    var body: some View {
        NavigationView {
            VStack {
                SearchAndFilterView(
                    searchText: $searchText,
                    selectedDayFilter: $selectedDayFilter
                )
                LectureListView(lectures: $lectures, searchText: $searchText, selectedDayFilter: $selectedDayFilter, lectureToEdit: $lectureToEdit, showAddLectureSheet: $showAddLectureSheet)
            }
            .navigationBarTitle("Orario")
            .navigationBarItems(trailing: Button(action: {
                lectureToEdit = nil
                showAddLectureSheet = true
            }) {
                Image(systemName: "plus")
            })
            .sheet(isPresented: $showAddLectureSheet) {
                AddEditLectureView(lectures: $lectures, lectureToEdit: $lectureToEdit)
            }
            .onAppear {
                loadLectures()
                setInitialDayFilter()
            }
            .alert(isPresented: $showNoLecturesAlert) {
                Alert(title: Text("Nessuna lezione"), message: Text("Non hai ancora aggiunto nessuna lezione."), dismissButton: .default(Text("OK")))
            }
            .onChange(of: lectures) { _ in
                saveLectures()
            }
        }
    }
    
    /// Sets the initial day filter to the current weekday.
    func setInitialDayFilter() {
        let weekdayNumber = Calendar.current.component(.weekday, from: Date())
        // Sunday = 1, Monday = 2, ..., Saturday = 7
        switch weekdayNumber {
        case 2:
            selectedDayFilter = .Lunedì
        case 3:
            selectedDayFilter = .Martedì
        case 4:
            selectedDayFilter = .Mercoledì
        case 5:
            selectedDayFilter = .Giovedì
        case 6:
            selectedDayFilter = .Venerdì
        default:
            selectedDayFilter = nil
        }
    }
    
    /// Loads lectures from the "schedule.json" file.
    func loadLectures() {
        if let loadedLectures = DataPersistence.shared.load("schedule.json", as: [Lecture].self) {
            lectures = loadedLectures
        } else {
            lectures = []
        }
        if lectures.isEmpty {
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
    
    var body: some View {
        VStack {
            // Search Bar
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Cerca Lezioni", text: $searchText)
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
            
            // Weekday Filter Bar (Always Visible)
            Picker("Giorno", selection: $selectedDayFilter) {
                Text("Tutti").tag(Weekday?.none)
                ForEach(Weekday.allCases) { day in
                    Text(day.rawValue).tag(Optional(day))
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding([.leading, .trailing, .bottom])
        }
    }
}

// MARK: - Lecture List View

struct LectureListView: View {
    @Binding var lectures: [Lecture]
    @Binding var searchText: String
    @Binding var selectedDayFilter: Weekday?
    @Binding var lectureToEdit: Lecture?
    @Binding var showAddLectureSheet: Bool
    
    var body: some View {
        List {
            ForEach(groupedLectures.keys.sorted(), id: \.self) { day in
                Section(header: Text(day.rawValue)) {
                    ForEach(groupedLectures[day]!) { lecture in
                        LectureRow(lecture: lecture)
                            .contentShape(Rectangle())
                            .contextMenu {
                                Button(action: {
                                    lectureToEdit = lecture
                                    showAddLectureSheet = true
                                }) {
                                    Label("Modifica", systemImage: "pencil")
                                }
                            }
                            .swipeActions(edge: .trailing) {
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
                            .swipeActions(edge: .leading) {
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
                            }
                    }
                }
            }
        }
    }
    
    var filteredLectures: [Lecture] {
        lectures.filter { lecture in
            (searchText.isEmpty || lecture.title.localizedCaseInsensitiveContains(searchText)) &&
            (selectedDayFilter == nil || lecture.day == selectedDayFilter)
        }
    }
    
    var groupedLectures: [Weekday: [Lecture]] {
        Dictionary(grouping: filteredLectures) { $0.day }
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
}

// MARK: - Lecture Row

struct LectureRow: View {
    let lecture: Lecture
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
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var title: String = ""
    @State private var selectedDay: Weekday = .Lunedì
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date().addingTimeInterval(5400)
    @State private var location: String = ""
    @State private var selectedColorOption: ColorOption = predefinedColors.first!
    @State private var notes: String = ""
    @State private var noteCharacterLimit: Int = 250
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Dettagli Lezione")) {
                    TextField("Titolo", text: $title)
                    Picker("Giorno", selection: $selectedDay) {
                        ForEach(Weekday.allCases) { day in
                            Text(day.rawValue).tag(day)
                        }
                    }
                    
                    HStack {
                        Text("Ora Inizio")
                        Spacer()
                        DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(CompactDatePickerStyle())
                            .labelsHidden()
                        
                    }
                    HStack {
                        Text("Ora Fine")
                        Spacer()
                        DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
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
                Section(header: Text("Note (max \(noteCharacterLimit) caratteri)")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                        .onChange(of: notes) { newValue in
                            if notes.count > noteCharacterLimit {
                                notes = String(notes.prefix(noteCharacterLimit))
                            }
                        }
                }
            }
            .navigationBarTitle(lectureToEdit == nil ? "Aggiungi Lezione" : "Modifica Lezione")
            .navigationBarItems(leading: Button("Annulla") {
                presentationMode.wrappedValue.dismiss()
            }, trailing: Button("Salva") {
                saveLecture()
            })
            .onAppear(perform: populateFields)
        }
        .onAppear {
            UIDatePicker.appearance().minuteInterval = 15
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Errore"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    
    func populateFields() {
        if let lecture = lectureToEdit {
            title = lecture.title
            selectedDay = lecture.day
            startTime = lecture.startTime
            endTime = lecture.endTime
            location = lecture.location ?? ""
            selectedColorOption = predefinedColors.first(where: { $0.colorName == lecture.colorName }) ?? predefinedColors.first!
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
