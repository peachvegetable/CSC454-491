import SwiftUI
import PhotosUI

struct RewardTaskDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingPhotoPicker = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var proofImage: UIImage?
    @StateObject private var viewModel = TaskDetailViewModel()
    
    let task: FamilyTask
    let onComplete: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Task Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.title)
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                
                                if let description = task.description {
                                    Text(description)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            VStack {
                                Image(systemName: "star.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.brandPeach)
                                Text(task.pointsDisplay)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.brandPeach)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                    
                    // Task Info
                    VStack(alignment: .leading, spacing: 16) {
                        InfoRow(icon: "person", title: "Created by", value: task.createdByName)
                        
                        if let assignedTo = task.assignedToName {
                            InfoRow(icon: "person.fill", title: "Assigned to", value: assignedTo)
                        }
                        
                        InfoRow(icon: "repeat", title: "Frequency", value: task.frequency.rawValue)
                        
                        if let dueDate = task.dueDate {
                            InfoRow(icon: "calendar", title: "Due Date", 
                                   value: DateFormatter.localizedString(from: dueDate, dateStyle: .medium, timeStyle: .none))
                        }
                        
                        if task.requiresProof {
                            InfoRow(icon: "camera.fill", title: "Proof Required", value: "Photo needed")
                        }
                        
                        InfoRow(icon: "flag", title: "Status", value: task.status.rawValue)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(15)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    // Proof Image Upload (if required and task is claimed)
                    if task.requiresProof && task.status == .claimed && task.assignedTo == viewModel.currentUserId {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Upload Proof")
                                .font(.headline)
                            
                            if let image = proofImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 300)
                                    .cornerRadius(12)
                            }
                            
                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                Label("Select Photo", systemImage: "photo")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.teal)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .onChange(of: selectedPhoto) { newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                                       let image = UIImage(data: data) {
                                        proofImage = image
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                    }
                    
                    // Action Buttons
                    actionButtons
                        .padding(.top)
                }
                .padding()
            }
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            viewModel.setup(task: task)
        }
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Claim Task Button
            if task.status == .available && task.assignedTo == nil {
                Button(action: {
                    viewModel.claimTask()
                    onComplete()
                    dismiss()
                }) {
                    Label("Claim Task", systemImage: "hand.raised.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.brandPeach)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .fontWeight(.semibold)
                }
            }
            
            // Complete Task Button
            if task.status == .claimed && task.assignedTo == viewModel.currentUserId {
                Button(action: {
                    viewModel.completeTask(proofImagePath: nil) // In real app, upload image first
                    onComplete()
                    dismiss()
                }) {
                    Label("Mark as Complete", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(task.requiresProof && proofImage == nil ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .fontWeight(.semibold)
                }
                .disabled(task.requiresProof && proofImage == nil)
            }
            
            // Approve Task Button (for parents)
            if task.status == .pendingApproval && viewModel.isParent {
                Button(action: {
                    viewModel.approveTask()
                    onComplete()
                    dismiss()
                }) {
                    Label("Approve & Award Points", systemImage: "checkmark.seal.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

@MainActor
class TaskDetailViewModel: ObservableObject {
    private var task: FamilyTask?
    @Published var currentUserId: String = ""
    @Published var isParent: Bool = false
    
    private let taskService = ServiceContainer.shared.taskService
    private let pointsService = ServiceContainer.shared.pointsService
    private let authService = ServiceContainer.shared.authService
    
    func setup(task: FamilyTask) {
        self.task = task
        if let currentUser = authService.currentUser {
            self.currentUserId = currentUser.id
            self.isParent = UserRole(rawValue: currentUser.role) == .admin
        }
    }
    
    func claimTask() {
        guard let task = task else { return }
        do {
            try taskService.claimTask(task.id)
        } catch {
            print("Error claiming task: \(error)")
        }
    }
    
    func completeTask(proofImagePath: String?) {
        guard let task = task else { return }
        do {
            try taskService.completeTask(task.id, proofImagePath: proofImagePath)
            if !task.requiresProof {
                try pointsService.completeTaskAndEarnPoints(task.id)
            }
        } catch {
            print("Error completing task: \(error)")
        }
    }
    
    func approveTask() {
        guard let task = task else { return }
        guard isParent else { return }
        
        do {
            try taskService.approveTask(task.id)
            try pointsService.completeTaskAndEarnPoints(task.id)
        } catch {
            print("Error approving task: \(error)")
        }
    }
}

#Preview {
    RewardTaskDetailView(
        task: FamilyTask(
            title: "Clean Room",
            description: "Make bed, vacuum, and organize desk",
            pointValue: 20,
            frequency: .weekly,
            createdBy: "parent123",
            createdByName: "Mom",
            requiresProof: true
        ),
        onComplete: {}
    )
}