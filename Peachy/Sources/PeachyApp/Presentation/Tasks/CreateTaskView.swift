import SwiftUI

struct CreateRewardTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var pointValue = 10
    @State private var frequency: TaskFrequency = .once
    @State private var requiresProof = false
    @State private var hasDueDate = false
    @State private var dueDate = Date().addingTimeInterval(86400) // Tomorrow
    
    let onComplete: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Task Title", text: $title)
                    
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...5)
                }
                
                Section("Points & Frequency") {
                    Stepper("Points: \(pointValue)", value: $pointValue, in: 5...500, step: 5)
                    
                    Picker("Frequency", selection: $frequency) {
                        ForEach(TaskFrequency.allCases, id: \.self) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }
                }
                
                Section("Requirements") {
                    Toggle("Requires Photo Proof", isOn: $requiresProof)
                    
                    Toggle("Set Due Date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Create Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createTask()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func createTask() {
        guard let currentUser = ServiceContainer.shared.authService.currentUser else { return }
        
        let task = FamilyTask(
            title: title,
            description: description.isEmpty ? nil : description,
            pointValue: pointValue,
            frequency: frequency,
            dueDate: hasDueDate ? dueDate : nil,
            createdBy: currentUser.id,
            createdByName: currentUser.displayName,
            requiresProof: requiresProof
        )
        
        Task { @MainActor in
            do {
                try ServiceContainer.shared.taskService.createTask(task)
                onComplete()
                dismiss()
            } catch {
                print("Error creating task: \(error)")
            }
        }
    }
}

#Preview {
    CreateRewardTaskView(onComplete: {})
}