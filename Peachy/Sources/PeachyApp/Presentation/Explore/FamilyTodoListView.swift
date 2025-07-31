import SwiftUI

struct FamilyTodoListView: View {
    @StateObject private var viewModel = FamilyTodoViewModel()
    @State private var showCreateTask = false
    @State private var selectedMember: String? = nil
    @State private var selectedCategory: TodoCategory? = nil
    @State private var showCompletedTasks = false
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
                    
                    Button(action: { showCreateTask = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color(hex: "#2BB3B3"))
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("Family Tasks")
                        .font(.largeTitle)
                        .bold()
                    Text("Share responsibilities together")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Filters
                VStack(spacing: 12) {
                    // Member filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            FilterChip(
                                title: "All Members",
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
                    
                    // Category filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            CategoryChip(
                                category: nil,
                                title: "All Categories",
                                isSelected: selectedCategory == nil,
                                action: { selectedCategory = nil }
                            )
                            
                            ForEach(TodoCategory.allCases, id: \.self) { category in
                                CategoryChip(
                                    category: category,
                                    title: category.rawValue,
                                    isSelected: selectedCategory == category,
                                    action: { selectedCategory = category }
                                )
                            }
                        }
                    }
                }
                
                // Toggle completed tasks
                HStack {
                    Text(showCompletedTasks ? "Showing completed tasks" : "Hiding completed tasks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Toggle("", isOn: $showCompletedTasks)
                        .labelsHidden()
                        .tint(Color(hex: "#2BB3B3"))
                }
            }
            .padding()
            
            Divider()
            
            // Task list
            if filteredTasks.isEmpty {
                emptyState
            } else {
                tasksList
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showCreateTask) {
            CreateTaskView(viewModel: viewModel)
        }
    }
    
    var filteredTasks: [FamilyTodo] {
        viewModel.tasks.filter { task in
            let memberMatch = selectedMember == nil || task.assignedTo.contains(selectedMember!)
            let categoryMatch = selectedCategory == nil || task.category == selectedCategory
            let completedMatch = showCompletedTasks || task.completedAt == nil
            return memberMatch && categoryMatch && completedMatch
        }
    }
    
    var tasksList: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Group by member if no specific member selected
                if selectedMember == nil {
                    ForEach(viewModel.familyMembers, id: \.id) { member in
                        let memberTasks = filteredTasks.filter { $0.assignedTo.contains(member.id) }
                        if !memberTasks.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Circle()
                                        .fill(member.color)
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            Text(member.initial)
                                                .font(.caption2)
                                                .foregroundColor(.white)
                                        )
                                    Text("\(member.name)'s Tasks")
                                        .font(.headline)
                                    Spacer()
                                    Text("\(memberTasks.filter { $0.completedAt == nil }.count) active")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                ForEach(memberTasks) { task in
                                    TaskRow(task: task, viewModel: viewModel)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                } else {
                    // Show tasks for selected member
                    ForEach(filteredTasks) { task in
                        TaskRow(task: task, viewModel: viewModel)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
    
    var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "checklist")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            Text("No tasks found")
                .font(.title3)
                .foregroundColor(.secondary)
            Text("Create a task to get started!")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button("Create First Task") {
                showCreateTask = true
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: "#2BB3B3"))
        }
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Task Row

struct TaskRow: View {
    let task: FamilyTodo
    @ObservedObject var viewModel: FamilyTodoViewModel
    @State private var showDetail = false
    
    var isCompleted: Bool {
        task.completedAt != nil
    }
    
    var body: some View {
        Button(action: { showDetail = true }) {
            HStack(spacing: 12) {
                // Completion button
                Button(action: { viewModel.toggleTaskCompletion(task) }) {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isCompleted ? .green : .gray.opacity(0.5))
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .strikethrough(isCompleted)
                        .foregroundColor(isCompleted ? .secondary : .primary)
                    
                    HStack(spacing: 12) {
                        // Category
                        HStack(spacing: 4) {
                            Image(systemName: task.category.icon)
                                .font(.caption2)
                            Text(task.category.rawValue)
                                .font(.caption)
                        }
                        
                        // Due date
                        if let dueDate = task.dueDate {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption2)
                                Text(dueDateString(for: dueDate))
                                    .font(.caption)
                            }
                            .foregroundColor(isOverdue(dueDate) && !isCompleted ? .red : .secondary)
                        }
                        
                        // Points
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                            Text("\(task.pointValue)")
                                .font(.caption)
                        }
                        .foregroundColor(.orange)
                        
                        // Recurring
                        if task.isRecurring {
                            Image(systemName: "repeat")
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.secondary)
                    
                    // Assigned to (if multiple)
                    if task.assignedTo.count > 1 {
                        HStack(spacing: -8) {
                            ForEach(task.assignedTo.prefix(3), id: \.self) { memberId in
                                if let member = viewModel.familyMembers.first(where: { $0.id == memberId }) {
                                    Circle()
                                        .fill(member.color)
                                        .frame(width: 20, height: 20)
                                        .overlay(
                                            Text(member.initial)
                                                .font(.system(size: 10))
                                                .foregroundColor(.white)
                                        )
                                        .overlay(
                                            Circle().stroke(Color.white, lineWidth: 1)
                                        )
                                }
                            }
                            if task.assignedTo.count > 3 {
                                Text("+\(task.assignedTo.count - 3)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 4)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Priority indicator
                if task.priority != .medium {
                    VStack {
                        Image(systemName: task.priority == .high ? "exclamationmark.circle.fill" : "arrow.down.circle")
                            .foregroundColor(task.priority == .high ? .red : .blue)
                            .font(.caption)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showDetail) {
            TaskDetailView(task: task, viewModel: viewModel)
        }
    }
    
    func dueDateString(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else if date < Date() {
            let days = calendar.dateComponents([.day], from: date, to: Date()).day ?? 0
            return "\(days)d overdue"
        } else {
            let days = calendar.dateComponents([.day], from: Date(), to: date).day ?? 0
            return "In \(days) days"
        }
    }
    
    func isOverdue(_ date: Date) -> Bool {
        date < Date() && !Calendar.current.isDateInToday(date)
    }
}

// MARK: - Create Task View

struct CreateTaskView: View {
    @ObservedObject var viewModel: FamilyTodoViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var assignedTo: Set<String> = []
    @State private var dueDate: Date? = nil
    @State private var hasDueDate = false
    @State private var priority = Priority.medium
    @State private var category = TodoCategory.chores
    @State private var pointValue = 5
    @State private var isRecurring = false
    @State private var recurringPattern = RecurringPattern.daily
    
    @State private var useTemplate = false
    @State private var selectedTemplate: TodoTemplate?
    
    var body: some View {
        NavigationStack {
            Form {
                if useTemplate {
                    Section("Choose a template") {
                        ForEach(TodoTemplate.commonTemplates, id: \.title) { template in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(template.title)
                                        .font(.subheadline)
                                    HStack {
                                        Label(template.category.rawValue, systemImage: template.category.icon)
                                            .font(.caption)
                                        Text("• \(template.defaultPoints) points")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.secondary)
                                }
                                Spacer()
                                if selectedTemplate?.title == template.title {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color(hex: "#2BB3B3"))
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedTemplate = template
                                applyTemplate(template)
                            }
                        }
                    }
                }
                
                Section("Task Details") {
                    TextField("What needs to be done?", text: $title)
                    
                    TextField("Add description (optional)", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                    
                    Picker("Category", selection: $category) {
                        ForEach(TodoCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }
                    
                    Toggle("Use template", isOn: $useTemplate)
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
                            
                            if assignedTo.contains(member.id) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color(hex: "#2BB3B3"))
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if assignedTo.contains(member.id) {
                                assignedTo.remove(member.id)
                            } else {
                                assignedTo.insert(member.id)
                            }
                        }
                    }
                }
                
                Section("Due Date") {
                    Toggle("Set due date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Due date", selection: Binding(
                            get: { dueDate ?? Date() },
                            set: { dueDate = $0 }
                        ), in: Date()...)
                    }
                }
                
                Section("Priority & Points") {
                    Picker("Priority", selection: $priority) {
                        Text("Low").tag(Priority.low)
                        Text("Medium").tag(Priority.medium)
                        Text("High").tag(Priority.high)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Stepper("Points: \(pointValue)", value: $pointValue, in: 1...20)
                }
                
                Section("Recurring") {
                    Toggle("Repeat task", isOn: $isRecurring)
                    
                    if isRecurring {
                        Picker("Repeat", selection: $recurringPattern) {
                            ForEach(RecurringPattern.allCases, id: \.self) { pattern in
                                Text(pattern.rawValue).tag(pattern)
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        viewModel.createTask(
                            title: title,
                            description: description.isEmpty ? nil : description,
                            assignedTo: Array(assignedTo),
                            dueDate: hasDueDate ? dueDate : nil,
                            priority: priority,
                            category: category,
                            pointValue: pointValue,
                            isRecurring: isRecurring,
                            recurringPattern: isRecurring ? recurringPattern : nil
                        )
                        dismiss()
                    }
                    .disabled(title.isEmpty || assignedTo.isEmpty)
                }
            }
        }
    }
    
    func applyTemplate(_ template: TodoTemplate) {
        title = template.title
        category = template.category
        pointValue = template.defaultPoints
        
        // Set typical duration as due date
        if let duration = template.typicalDuration {
            hasDueDate = true
            dueDate = Date().addingTimeInterval(duration)
        }
    }
}

// MARK: - Task Detail View

struct TaskDetailView: View {
    let task: FamilyTodo
    @ObservedObject var viewModel: FamilyTodoViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: task.category.icon)
                                .font(.title2)
                                .foregroundColor(Color(hex: "#2BB3B3"))
                            Text(task.title)
                                .font(.title2)
                                .bold()
                        }
                        
                        HStack {
                            Text(task.category.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if task.isRecurring {
                                Text("•")
                                    .foregroundColor(.secondary)
                                Label("Recurring", systemImage: "repeat")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Status
                    if let completedAt = task.completedAt, let completedBy = task.completedBy {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Completed by \(viewModel.familyMembers.first(where: { $0.id == completedBy })?.name ?? "") \(completedAt.formatted(.relative(presentation: .named)))")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // Description
                    if let description = task.description {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Description", systemImage: "text.alignleft")
                                .font(.headline)
                            Text(description)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Assigned to
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Assigned to", systemImage: "person.3")
                            .font(.headline)
                        
                        ForEach(task.assignedTo, id: \.self) { memberId in
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
                    
                    // Due date
                    if let dueDate = task.dueDate {
                        HStack {
                            Label("Due \(dueDate.formatted(.dateTime.weekday(.wide).month().day()))", systemImage: "calendar")
                            Spacer()
                            if dueDate < Date() && task.completedAt == nil {
                                Text("Overdue")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    
                    // Priority & Points
                    HStack(spacing: 20) {
                        VStack(alignment: .leading) {
                            Label("Priority", systemImage: "flag")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(task.priority.rawValue)
                                .font(.headline)
                                .foregroundColor(priorityColor(task.priority))
                        }
                        
                        VStack(alignment: .leading) {
                            Label("Points", systemImage: "star.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(task.pointValue)")
                                .font(.headline)
                                .foregroundColor(.orange)
                        }
                        
                        Spacer()
                    }
                    
                    // Created by
                    HStack {
                        Label("Created by \(viewModel.familyMembers.first(where: { $0.id == task.assignedBy })?.name ?? "")", systemImage: "person.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(task.createdAt.formatted(.relative(presentation: .named)))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Actions
                    VStack(spacing: 12) {
                        if task.completedAt == nil {
                            Button(action: {
                                viewModel.toggleTaskCompletion(task)
                                dismiss()
                            }) {
                                Label("Mark as Complete", systemImage: "checkmark.circle")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(hex: "#2BB3B3"))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                        
                        if task.assignedBy == "currentUser" {
                            Button(action: { showDeleteConfirmation = true }) {
                                Label("Delete Task", systemImage: "trash")
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
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Delete Task", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    viewModel.deleteTask(task)
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete this task?")
            }
        }
    }
    
    func priorityColor(_ priority: Priority) -> Color {
        switch priority {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        }
    }
}

// MARK: - Supporting Views

struct CategoryChip: View {
    let category: TodoCategory?
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let category = category {
                    Image(systemName: category.icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color(hex: "#2BB3B3").opacity(0.2) : Color(.systemGray6))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color(hex: "#2BB3B3") : Color.clear, lineWidth: 1)
            )
        }
    }
}

// MARK: - View Model

class FamilyTodoViewModel: ObservableObject {
    @Published var tasks: [FamilyTodo] = []
    let familyMembers = FamilyMember.mock
    
    init() {
        loadMockTasks()
    }
    
    func loadMockTasks() {
        tasks = [
            FamilyTodo(
                id: "1",
                title: "Take out the trash",
                description: "Don't forget to separate recycling",
                assignedTo: ["teen"],
                assignedBy: "mom",
                dueDate: Date(),
                priority: .medium,
                category: .chores,
                pointValue: 5,
                isRecurring: true,
                recurringPattern: .weekly,
                createdAt: Date().addingTimeInterval(-86400)
            ),
            FamilyTodo(
                id: "2",
                title: "Math homework",
                description: "Chapter 5 exercises",
                assignedTo: ["teen"],
                assignedBy: "teen",
                dueDate: Date().addingTimeInterval(86400),
                priority: .high,
                category: .homework,
                pointValue: 10,
                isRecurring: false,
                createdAt: Date().addingTimeInterval(-7200)
            ),
            FamilyTodo(
                id: "3",
                title: "Clean the living room",
                description: "Vacuum and dust all surfaces",
                assignedTo: ["dad", "kid"],
                assignedBy: "mom",
                dueDate: Date().addingTimeInterval(172800),
                priority: .low,
                category: .chores,
                pointValue: 15,
                isRecurring: false,
                createdAt: Date().addingTimeInterval(-3600)
            ),
            FamilyTodo(
                id: "4",
                title: "Buy groceries",
                description: "List in the kitchen",
                assignedTo: ["mom"],
                assignedBy: "mom",
                dueDate: Date().addingTimeInterval(7200),
                priority: .high,
                category: .shopping,
                pointValue: 10,
                isRecurring: false,
                createdAt: Date()
            ),
            FamilyTodo(
                id: "5",
                title: "Practice piano",
                description: "30 minutes minimum",
                assignedTo: ["kid"],
                assignedBy: "dad",
                dueDate: nil,
                priority: .medium,
                category: .personal,
                pointValue: 5,
                isRecurring: true,
                recurringPattern: .daily,
                createdAt: Date().addingTimeInterval(-172800),
                completedAt: Date().addingTimeInterval(-3600),
                completedBy: "kid"
            )
        ]
    }
    
    func createTask(title: String, description: String?, assignedTo: [String], dueDate: Date?, priority: Priority, category: TodoCategory, pointValue: Int, isRecurring: Bool, recurringPattern: RecurringPattern?) {
        let newTask = FamilyTodo(
            id: UUID().uuidString,
            title: title,
            description: description,
            assignedTo: assignedTo,
            assignedBy: "currentUser",
            dueDate: dueDate,
            priority: priority,
            category: category,
            pointValue: pointValue,
            isRecurring: isRecurring,
            recurringPattern: recurringPattern,
            createdAt: Date()
        )
        tasks.insert(newTask, at: 0)
    }
    
    func toggleTaskCompletion(_ task: FamilyTodo) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        
        if tasks[index].completedAt == nil {
            tasks[index].completedAt = Date()
            tasks[index].completedBy = "currentUser"
            
            // Award points
            // In real app, this would update the user's points
            
            // Handle recurring tasks
            if task.isRecurring, let pattern = task.recurringPattern {
                let nextDueDate = calculateNextDueDate(from: task.dueDate ?? Date(), pattern: pattern)
                createTask(
                    title: task.title,
                    description: task.description,
                    assignedTo: task.assignedTo,
                    dueDate: nextDueDate,
                    priority: task.priority,
                    category: task.category,
                    pointValue: task.pointValue,
                    isRecurring: true,
                    recurringPattern: pattern
                )
            }
        } else {
            tasks[index].completedAt = nil
            tasks[index].completedBy = nil
        }
    }
    
    func deleteTask(_ task: FamilyTodo) {
        tasks.removeAll { $0.id == task.id }
    }
    
    private func calculateNextDueDate(from date: Date, pattern: RecurringPattern) -> Date {
        let calendar = Calendar.current
        switch pattern {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date) ?? date
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        case .biweekly:
            return calendar.date(byAdding: .weekOfYear, value: 2, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        }
    }
}

// MARK: - Models

struct FamilyTodo: Identifiable {
    let id: String
    let title: String
    let description: String?
    let assignedTo: [String]
    let assignedBy: String
    let dueDate: Date?
    let priority: Priority
    let category: TodoCategory
    let pointValue: Int
    let isRecurring: Bool
    var recurringPattern: RecurringPattern?
    let createdAt: Date
    var completedAt: Date?
    var completedBy: String?
}

enum TodoCategory: String, CaseIterable {
    case chores = "Chores"
    case homework = "Homework"
    case personal = "Personal"
    case family = "Family"
    case shopping = "Shopping"
    
    var icon: String {
        switch self {
        case .chores: return "house"
        case .homework: return "book"
        case .personal: return "person"
        case .family: return "person.3"
        case .shopping: return "cart"
        }
    }
}

enum Priority: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

enum RecurringPattern: String, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case biweekly = "Biweekly"
    case monthly = "Monthly"
}

struct TodoTemplate {
    let title: String
    let category: TodoCategory
    let defaultPoints: Int
    let typicalDuration: TimeInterval?
    
    static let commonTemplates = [
        TodoTemplate(title: "Take out trash", category: .chores, defaultPoints: 5, typicalDuration: nil),
        TodoTemplate(title: "Clean bedroom", category: .chores, defaultPoints: 10, typicalDuration: 86400),
        TodoTemplate(title: "Do laundry", category: .chores, defaultPoints: 10, typicalDuration: 172800),
        TodoTemplate(title: "Wash dishes", category: .chores, defaultPoints: 5, typicalDuration: nil),
        TodoTemplate(title: "Vacuum living room", category: .chores, defaultPoints: 8, typicalDuration: 172800),
        TodoTemplate(title: "Homework", category: .homework, defaultPoints: 10, typicalDuration: 86400),
        TodoTemplate(title: "Study for test", category: .homework, defaultPoints: 15, typicalDuration: 172800),
        TodoTemplate(title: "Practice instrument", category: .personal, defaultPoints: 5, typicalDuration: nil),
        TodoTemplate(title: "Exercise", category: .personal, defaultPoints: 5, typicalDuration: nil),
        TodoTemplate(title: "Buy groceries", category: .shopping, defaultPoints: 10, typicalDuration: 86400)
    ]
}

#Preview {
    NavigationStack {
        FamilyTodoListView()
    }
}