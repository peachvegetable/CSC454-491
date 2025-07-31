import SwiftUI

struct FamilyCalendarView: View {
    @StateObject private var viewModel = FamilyCalendarViewModel()
    @State private var selectedDate = Date()
    @State private var showCreateEvent = false
    @State private var selectedEvent: FamilyEvent?
    @State private var calendarView: CalendarViewType = .month
    @State private var selectedMember: String? = nil
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.body)
                        }
                        .foregroundColor(Color(hex: "#2BB3B3"))
                    }
                    
                    Spacer()
                    
                    Menu {
                        Button(action: { calendarView = .month }) {
                            Label("Month", systemImage: calendarView == .month ? "checkmark" : "")
                        }
                        Button(action: { calendarView = .week }) {
                            Label("Week", systemImage: calendarView == .week ? "checkmark" : "")
                        }
                        Button(action: { calendarView = .day }) {
                            Label("Day", systemImage: calendarView == .day ? "checkmark" : "")
                        }
                    } label: {
                        Image(systemName: "calendar")
                            .font(.title2)
                    }
                    
                    Button(action: { showCreateEvent = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color(hex: "#2BB3B3"))
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("Family Calendar")
                        .font(.largeTitle)
                        .bold()
                    Text(selectedDate.formatted(.dateTime.month(.wide).year()))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Member filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterChip(
                            title: "All",
                            isSelected: selectedMember == nil,
                            color: .gray,
                            action: { selectedMember = nil }
                        )
                        
                        ForEach(viewModel.familyMembers, id: \.id) { member in
                            FilterChip(
                                title: member.name,
                                isSelected: selectedMember == member.id,
                                color: member.color,
                                action: { selectedMember = member.id }
                            )
                        }
                    }
                }
            }
            .padding()
            
            Divider()
            
            // Calendar content
            switch calendarView {
            case .month:
                monthView
            case .week:
                weekView
            case .day:
                dayView
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showCreateEvent) {
            CreateEventView(viewModel: viewModel, selectedDate: selectedDate)
        }
        .sheet(item: $selectedEvent) { event in
            EventDetailView(event: event, viewModel: viewModel)
        }
    }
    
    // MARK: - Month View
    var monthView: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Weekday headers
                HStack(spacing: 0) {
                    ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // Calendar grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
                    ForEach(viewModel.calendarDays(for: selectedDate), id: \.self) { date in
                        CalendarDayCell(
                            date: date,
                            events: viewModel.events(for: date, member: selectedMember),
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                            isCurrentMonth: Calendar.current.isDate(date, equalTo: selectedDate, toGranularity: .month),
                            onTap: {
                                selectedDate = date
                            }
                        )
                    }
                }
                .padding(.horizontal)
                
                // Events for selected date
                if !viewModel.events(for: selectedDate, member: selectedMember).isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Events on \(selectedDate.formatted(.dateTime.weekday(.wide).month().day()))")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(viewModel.events(for: selectedDate, member: selectedMember)) { event in
                            EventRow(event: event, onTap: { selectedEvent = event })
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                }
            }
        }
    }
    
    // MARK: - Week View
    var weekView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Week navigation
                HStack {
                    Button(action: { selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedDate) ?? selectedDate }) {
                        Image(systemName: "chevron.left")
                    }
                    
                    Text(weekDateRange)
                        .font(.headline)
                    
                    Button(action: { selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate }) {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding(.horizontal)
                
                // Week days
                ForEach(viewModel.weekDays(for: selectedDate), id: \.self) { date in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(date.formatted(.dateTime.weekday(.abbreviated)))
                                .fontWeight(.medium)
                            Text(date.formatted(.dateTime.day()))
                                .foregroundColor(Calendar.current.isDateInToday(date) ? Color(hex: "#2BB3B3") : .primary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        let events = viewModel.events(for: date, member: selectedMember)
                        if events.isEmpty {
                            Text("No events")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(events) { event in
                                EventRow(event: event, onTap: { selectedEvent = event })
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    if date != viewModel.weekDays(for: selectedDate).last {
                        Divider()
                            .padding(.horizontal)
                    }
                }
            }
        }
    }
    
    // MARK: - Day View
    var dayView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Day navigation
                HStack {
                    Button(action: { selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate }) {
                        Image(systemName: "chevron.left")
                    }
                    
                    Text(selectedDate.formatted(.dateTime.weekday(.wide).month().day()))
                        .font(.headline)
                    
                    Button(action: { selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate }) {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding(.horizontal)
                
                // Time slots
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(0..<24, id: \.self) { hour in
                        HStack(alignment: .top, spacing: 16) {
                            Text("\(hour):00")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 50, alignment: .trailing)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                let hourEvents = viewModel.events(for: selectedDate, member: selectedMember, hour: hour)
                                if hourEvents.isEmpty {
                                    Rectangle()
                                        .fill(Color(.systemGray6))
                                        .frame(height: 1)
                                } else {
                                    ForEach(hourEvents) { event in
                                        EventTimeSlot(event: event, onTap: { selectedEvent = event })
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    var weekDateRange: String {
        let calendar = Calendar.current
        let week = calendar.dateInterval(of: .weekOfYear, for: selectedDate)!
        return "\(week.start.formatted(.dateTime.month().day())) - \(week.end.formatted(.dateTime.month().day()))"
    }
}

// MARK: - Supporting Views

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(title)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? color.opacity(0.2) : Color(.systemGray6))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 1)
            )
        }
    }
}

struct CalendarDayCell: View {
    let date: Date
    let events: [FamilyEvent]
    let isSelected: Bool
    let isCurrentMonth: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.body)
                    .fontWeight(Calendar.current.isDateInToday(date) ? .bold : .regular)
                    .foregroundColor(isCurrentMonth ? .primary : .secondary)
                
                if !events.isEmpty {
                    HStack(spacing: 2) {
                        ForEach(events.prefix(3)) { event in
                            Circle()
                                .fill(event.memberColor)
                                .frame(width: 6, height: 6)
                        }
                        if events.count > 3 {
                            Text("+\(events.count - 3)")
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .frame(minHeight: 60)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(hex: "#2BB3B3").opacity(0.2) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Calendar.current.isDateInToday(date) ? Color(hex: "#2BB3B3") : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EventRow: View {
    let event: FamilyEvent
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(event.memberColor)
                    .frame(width: 4)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(event.timeString)
                            .font(.caption)
                        
                        if let location = event.location {
                            Text("•")
                                .font(.caption)
                            Image(systemName: "location")
                                .font(.caption2)
                            Text(location)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: -8) {
                    ForEach(event.assignedMembers.prefix(3), id: \.self) { memberId in
                        if let member = FamilyMember.mock.first(where: { $0.id == memberId }) {
                            Circle()
                                .fill(member.color)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Text(member.initial)
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                )
                                .overlay(
                                    Circle().stroke(Color.white, lineWidth: 2)
                                )
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EventTimeSlot: View {
    let event: FamilyEvent
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(event.memberColor)
                    .frame(width: 3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.caption)
                        .lineLimit(1)
                    Text(event.timeString)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(event.memberColor.opacity(0.1))
            .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Create Event View

struct CreateEventView: View {
    @ObservedObject var viewModel: FamilyCalendarViewModel
    let selectedDate: Date
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var location = ""
    @State private var assignedMembers: Set<String> = []
    @State private var eventType = EventType.family
    @State private var isRecurring = false
    @State private var recurringRule = RecurringRule.weekly
    @State private var reminder = ReminderTime.fifteenMinutes
    @State private var notes = ""
    
    init(viewModel: FamilyCalendarViewModel, selectedDate: Date) {
        self.viewModel = viewModel
        self.selectedDate = selectedDate
        self._startDate = State(initialValue: selectedDate)
        self._endDate = State(initialValue: selectedDate.addingTimeInterval(3600))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Event Details") {
                    TextField("Event title", text: $title)
                    
                    Picker("Event type", selection: $eventType) {
                        ForEach(EventType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                }
                
                Section("Date & Time") {
                    DatePicker("Starts", selection: $startDate)
                    DatePicker("Ends", selection: $endDate, in: startDate...)
                    
                    Toggle("Repeat", isOn: $isRecurring)
                    if isRecurring {
                        Picker("Repeat", selection: $recurringRule) {
                            ForEach(RecurringRule.allCases, id: \.self) { rule in
                                Text(rule.rawValue).tag(rule)
                            }
                        }
                    }
                }
                
                Section("Location") {
                    TextField("Add location", text: $location)
                }
                
                Section("Assign to") {
                    ForEach(viewModel.familyMembers, id: \.id) { member in
                        HStack {
                            Circle()
                                .fill(member.color)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Text(member.initial)
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                )
                            
                            Text(member.name)
                            
                            Spacer()
                            
                            if assignedMembers.contains(member.id) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color(hex: "#2BB3B3"))
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if assignedMembers.contains(member.id) {
                                assignedMembers.remove(member.id)
                            } else {
                                assignedMembers.insert(member.id)
                            }
                        }
                    }
                }
                
                Section("Reminder") {
                    Picker("Remind me", selection: $reminder) {
                        ForEach(ReminderTime.allCases, id: \.self) { time in
                            Text(time.rawValue).tag(time)
                        }
                    }
                }
                
                Section("Notes") {
                    TextField("Add notes", text: $notes, axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        viewModel.createEvent(
                            title: title,
                            startDate: startDate,
                            endDate: endDate,
                            location: location.isEmpty ? nil : location,
                            assignedMembers: Array(assignedMembers),
                            eventType: eventType,
                            isRecurring: isRecurring,
                            recurringRule: isRecurring ? recurringRule : nil,
                            reminder: reminder,
                            notes: notes.isEmpty ? nil : notes
                        )
                        dismiss()
                    }
                    .disabled(title.isEmpty || assignedMembers.isEmpty)
                }
            }
        }
    }
}

// MARK: - Event Detail View

struct EventDetailView: View {
    let event: FamilyEvent
    @ObservedObject var viewModel: FamilyCalendarViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title and type
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: event.eventType.icon)
                                .font(.title2)
                                .foregroundColor(event.memberColor)
                            Text(event.title)
                                .font(.title2)
                                .bold()
                        }
                        
                        Text(event.eventType.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Date and time
                    VStack(alignment: .leading, spacing: 8) {
                        Label {
                            VStack(alignment: .leading) {
                                Text(event.dateString)
                                Text(event.timeString)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: "calendar")
                                .foregroundColor(Color(hex: "#2BB3B3"))
                        }
                        
                        if event.isRecurring, let rule = event.recurringRule {
                            Label("Repeats \(rule.rawValue.lowercased())", systemImage: "repeat")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Location
                    if let location = event.location {
                        Label(location, systemImage: "location")
                            .foregroundColor(.primary)
                    }
                    
                    // Assigned members
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Assigned to", systemImage: "person.3")
                            .font(.headline)
                        
                        ForEach(event.assignedMembers, id: \.self) { memberId in
                            if let member = viewModel.familyMembers.first(where: { $0.id == memberId }) {
                                HStack {
                                    Circle()
                                        .fill(member.color)
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Text(member.initial)
                                                .font(.caption)
                                                .foregroundColor(.white)
                                        )
                                    
                                    Text(member.name)
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                    
                    // Reminder
                    if let reminder = event.reminders.first {
                        Label("Reminder \(reminder.rawValue) before", systemImage: "bell")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Notes
                    if let notes = event.notes {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Notes", systemImage: "note.text")
                                .font(.headline)
                            Text(notes)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Actions
                    VStack(spacing: 12) {
                        Button(action: {
                            // Add to device calendar
                        }) {
                            Label("Add to Calendar", systemImage: "calendar.badge.plus")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "#2BB3B3"))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        
                        if event.createdBy == "currentUser" {
                            Button(action: {
                                viewModel.deleteEvent(event)
                                dismiss()
                            }) {
                                Label("Delete Event", systemImage: "trash")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red.opacity(0.1))
                                    .foregroundColor(.red)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.top)
                }
                .padding()
            }
            .navigationTitle("Event Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - View Model

class FamilyCalendarViewModel: ObservableObject {
    @Published var events: [FamilyEvent] = []
    let familyMembers = FamilyMember.mock
    
    init() {
        loadMockEvents()
    }
    
    func loadMockEvents() {
        let today = Date()
        events = [
            FamilyEvent(
                id: "1",
                title: "Mom's Doctor Appointment",
                startDate: today.addingTimeInterval(3600),
                endDate: today.addingTimeInterval(7200),
                location: "Medical Center",
                assignedMembers: ["mom"],
                eventType: .medical,
                isRecurring: false,
                reminders: [.thirtyMinutes],
                createdBy: "mom",
                notes: nil
            ),
            FamilyEvent(
                id: "2",
                title: "Family Game Night",
                startDate: today.addingTimeInterval(172800), // 2 days
                endDate: today.addingTimeInterval(183600),
                location: nil,
                assignedMembers: ["dad", "mom", "teen", "kid"],
                eventType: .family,
                isRecurring: true,
                recurringRule: .weekly,
                reminders: [.oneHour],
                createdBy: "dad",
                notes: nil
            ),
            FamilyEvent(
                id: "3",
                title: "Soccer Practice",
                startDate: today.addingTimeInterval(86400), // tomorrow
                endDate: today.addingTimeInterval(90000),
                location: "Community Park",
                assignedMembers: ["teen"],
                eventType: .personal,
                isRecurring: true,
                recurringRule: .weekly,
                reminders: [.fifteenMinutes],
                createdBy: "teen",
                notes: nil
            ),
            FamilyEvent(
                id: "4",
                title: "Parent-Teacher Conference",
                startDate: today.addingTimeInterval(432000), // 5 days
                endDate: today.addingTimeInterval(435600),
                location: "High School",
                assignedMembers: ["dad", "mom"],
                eventType: .school,
                isRecurring: false,
                reminders: [.oneDay, .oneHour],
                createdBy: "mom",
                notes: "Discuss recent grades and college prep"
            )
        ]
    }
    
    func createEvent(title: String, startDate: Date, endDate: Date, location: String?, assignedMembers: [String], eventType: EventType, isRecurring: Bool, recurringRule: RecurringRule?, reminder: ReminderTime, notes: String?) {
        let newEvent = FamilyEvent(
            id: UUID().uuidString,
            title: title,
            startDate: startDate,
            endDate: endDate,
            location: location,
            assignedMembers: assignedMembers,
            eventType: eventType,
            isRecurring: isRecurring,
            recurringRule: recurringRule,
            reminders: [reminder],
            createdBy: "currentUser",
            notes: notes
        )
        events.append(newEvent)
    }
    
    func deleteEvent(_ event: FamilyEvent) {
        events.removeAll { $0.id == event.id }
    }
    
    func events(for date: Date, member: String? = nil, hour: Int? = nil) -> [FamilyEvent] {
        let calendar = Calendar.current
        return events.filter { event in
            let sameDay = calendar.isDate(event.startDate, inSameDayAs: date)
            let memberMatch = member == nil || event.assignedMembers.contains(member!)
            let hourMatch = hour == nil || calendar.component(.hour, from: event.startDate) == hour!
            return sameDay && memberMatch && hourMatch
        }.sorted { $0.startDate < $1.startDate }
    }
    
    func calendarDays(for date: Date) -> [Date] {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let range = calendar.range(of: .day, in: .month, for: date)!
        let numberOfDays = range.count
        
        var days: [Date] = []
        
        // Add days from previous month to fill the week
        let firstWeekday = calendar.component(.weekday, from: startOfMonth) - 1
        for i in (0..<firstWeekday).reversed() {
            if let day = calendar.date(byAdding: .day, value: -i-1, to: startOfMonth) {
                days.append(day)
            }
        }
        
        // Add days of current month
        for i in 0..<numberOfDays {
            if let day = calendar.date(byAdding: .day, value: i, to: startOfMonth) {
                days.append(day)
            }
        }
        
        // Add days from next month to complete the grid
        while days.count % 7 != 0 {
            if let day = calendar.date(byAdding: .day, value: days.count - firstWeekday - numberOfDays + 1, to: days.last!) {
                days.append(day)
            }
        }
        
        return days
    }
    
    func weekDays(for date: Date) -> [Date] {
        let calendar = Calendar.current
        let week = calendar.dateInterval(of: .weekOfYear, for: date)!
        var days: [Date] = []
        
        var currentDate = week.start
        while currentDate < week.end {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return days
    }
}

// MARK: - Models

struct FamilyEvent: Identifiable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let location: String?
    let assignedMembers: [String]
    let eventType: EventType
    let isRecurring: Bool
    var recurringRule: RecurringRule?
    let reminders: [ReminderTime]
    let createdBy: String
    let notes: String?
    
    var memberColor: Color {
        if let firstMember = assignedMembers.first,
           let member = FamilyMember.mock.first(where: { $0.id == firstMember }) {
            return member.color
        }
        return .gray
    }
    
    var dateString: String {
        startDate.formatted(.dateTime.weekday(.wide).month().day())
    }
    
    var timeString: String {
        if Calendar.current.isDate(startDate, inSameDayAs: endDate) {
            return "\(startDate.formatted(date: .omitted, time: .shortened)) - \(endDate.formatted(date: .omitted, time: .shortened))"
        } else {
            return "All day"
        }
    }
}

struct FamilyMember {
    let id: String
    let name: String
    let color: Color
    
    var initial: String {
        String(name.prefix(1))
    }
    
    static let mock = [
        FamilyMember(id: "dad", name: "Dad", color: .blue),
        FamilyMember(id: "mom", name: "Mom", color: .purple),
        FamilyMember(id: "teen", name: "Alex", color: Color(hex: "#2BB3B3")),
        FamilyMember(id: "kid", name: "Sam", color: .orange)
    ]
}

enum EventType: String, CaseIterable {
    case school = "School"
    case medical = "Medical"
    case family = "Family"
    case personal = "Personal"
    case social = "Social"
    
    var icon: String {
        switch self {
        case .school: return "backpack"
        case .medical: return "stethoscope"
        case .family: return "person.3"
        case .personal: return "person"
        case .social: return "person.2"
        }
    }
}

enum RecurringRule: String, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case biweekly = "Every 2 weeks"
    case monthly = "Monthly"
}

enum ReminderTime: String, CaseIterable {
    case none = "None"
    case atTime = "At time of event"
    case fiveMinutes = "5 minutes"
    case fifteenMinutes = "15 minutes"
    case thirtyMinutes = "30 minutes"
    case oneHour = "1 hour"
    case twoHours = "2 hours"
    case oneDay = "1 day"
}

enum CalendarViewType {
    case month, week, day
}

#Preview {
    NavigationStack {
        FamilyCalendarView()
    }
}