import SwiftUI

struct TaskListView: View {
    @StateObject private var viewModel = TaskListViewModel()
    @State private var showCreateTask = false
    @State private var selectedTask: FamilyTask?
    @State private var showTaskDetail = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Points Balance Card
                    PointsBalanceCard(balance: viewModel.currentBalance)
                        .padding(.horizontal)
                    
                    // My Tasks Section
                    if !viewModel.myTasks.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("My Tasks")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            ForEach(viewModel.myTasks) { task in
                                TaskCard(task: task) {
                                    selectedTask = task
                                    showTaskDetail = true
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Available Tasks Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Available Tasks")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        if viewModel.availableTasks.isEmpty {
                            EmptyTasksView()
                                .padding(.horizontal)
                        } else {
                            ForEach(viewModel.availableTasks) { task in
                                TaskCard(task: task) {
                                    selectedTask = task
                                    showTaskDetail = true
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Tasks Pending Approval (for parents)
                    if viewModel.isParent && !viewModel.pendingApprovalTasks.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Pending Approval")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            ForEach(viewModel.pendingApprovalTasks) { task in
                                TaskCard(task: task, showApprovalBadge: true) {
                                    selectedTask = task
                                    showTaskDetail = true
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isParent {
                        Button(action: { showCreateTask = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.brandPeach)
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreateTask) {
                CreateRewardTaskView(onComplete: {
                    viewModel.loadTasks()
                })
            }
            .sheet(item: $selectedTask) { task in
                RewardTaskDetailView(task: task, onComplete: {
                    viewModel.loadTasks()
                })
            }
        }
        .onAppear {
            viewModel.loadTasksWithSampleData()
        }
    }
}

struct PointsBalanceCard: View {
    let balance: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Points")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("\(balance)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.brandPeach)
            }
            
            Spacer()
            
            Image(systemName: "star.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.brandPeach.opacity(0.3))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
}

struct TaskCard: View {
    let task: FamilyTask
    var showApprovalBadge: Bool = false
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(task.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if showApprovalBadge {
                            Text("APPROVAL NEEDED")
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    }
                    
                    if let description = task.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    HStack {
                        Label(task.pointsDisplay, systemImage: "star.fill")
                            .font(.caption)
                            .foregroundColor(.brandPeach)
                        
                        Spacer()
                        
                        if let dueDate = task.dueDate {
                            Label(RelativeDateTimeFormatter().localizedString(for: dueDate, relativeTo: Date()), 
                                  systemImage: "clock")
                                .font(.caption)
                                .foregroundColor(task.isOverdue ? .red : .secondary)
                        }
                        
                        if task.frequency != .once {
                            Label(task.frequency.rawValue, systemImage: "repeat")
                                .font(.caption)
                                .foregroundColor(.teal)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

struct EmptyTasksView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.3))
            
            Text("No tasks available")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Check back later for new tasks!")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
}

#Preview {
    TaskListView()
}