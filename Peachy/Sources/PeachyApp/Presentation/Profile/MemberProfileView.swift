import SwiftUI

struct MemberProfileView: View {
    let member: FamilyMemberStatus
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = MemberProfileViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Member Header
                    VStack(spacing: 12) {
                        ZStack(alignment: .bottomTrailing) {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Text(member.initial)
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                )
                            
                            Circle()
                                .fill(member.statusColor)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 3)
                                )
                        }
                        
                        Text(member.name)
                            .font(.title2)
                            .bold()
                        
                        // Last mood update
                        HStack {
                            Circle()
                                .fill(Color(hex: member.simpleMoodColor.hex))
                                .frame(width: 16, height: 16)
                            
                            Text("Feeling \(member.simpleMoodColor.displayName)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Last update: \(member.lastUpdate.formatted(.relative(presentation: .named)))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    Divider()
                    
                    // Hobbies Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("\(member.name)'s Hobbies")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if viewModel.memberHobbies.isEmpty {
                            Text("No hobbies shared yet")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            ForEach(viewModel.memberHobbies, id: \.name) { hobby in
                                NavigationLink(destination: HobbyDetailView(hobby: hobby)) {
                                    MemberHobbyCard(hobby: hobby)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Recent Activity
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Activity")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(viewModel.recentActivities, id: \.id) { activity in
                            ActivityCard(activity: activity)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("\(member.name)'s Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                viewModel.loadMemberData(for: member)
            }
        }
    }
}

struct MemberHobbyCard: View {
    let hobby: HobbyModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(hobby.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if !hobby.fact.isEmpty {
                    Text(hobby.fact)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ActivityCard: View {
    let activity: MemberActivity
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.icon)
                .font(.title3)
                .foregroundColor(Color(hex: activity.color))
                .frame(width: 40, height: 40)
                .background(Color(hex: activity.color).opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(activity.timestamp.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct MemberActivity: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: String
    let timestamp: Date
}

@MainActor
class MemberProfileViewModel: ObservableObject {
    @Published var memberHobbies: [HobbyModel] = []
    @Published var recentActivities: [MemberActivity] = []
    
    func loadMemberData(for member: FamilyMemberStatus) {
        // In production, this would fetch real data from the database
        // For now, we'll use mock data
        
        // Mock hobbies
        memberHobbies = [
            HobbyModel(name: "Photography", ownerId: "member-id", fact: "I love taking pictures of nature, especially during golden hour"),
            HobbyModel(name: "Cooking", ownerId: "member-id", fact: "Recently started learning Italian cuisine"),
            HobbyModel(name: "Gaming", ownerId: "member-id", fact: "Playing strategy games helps me relax after school")
        ]
        
        // Mock recent activities
        recentActivities = [
            MemberActivity(
                title: "Shared a hobby fact about Photography",
                icon: "star.fill",
                color: "#FFC7B2",
                timestamp: Date().addingTimeInterval(-3600) // 1 hour ago
            ),
            MemberActivity(
                title: "Completed Flash Card Quiz",
                icon: "checkmark.circle.fill",
                color: "#2BB3B3",
                timestamp: Date().addingTimeInterval(-7200) // 2 hours ago
            ),
            MemberActivity(
                title: "Updated mood",
                icon: "heart.fill",
                color: member.simpleMoodColor.hex,
                timestamp: member.lastUpdate
            )
        ]
    }
}

#Preview {
    MemberProfileView(
        member: FamilyMemberStatus(
            name: "Sarah",
            initial: "S",
            simpleMoodColor: .green,
            lastUpdate: Date()
        )
    )
}