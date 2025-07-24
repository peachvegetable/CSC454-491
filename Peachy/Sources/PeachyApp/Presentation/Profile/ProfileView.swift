import SwiftUI

public struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showPairingCode = false
    let destination: ProfileDestination?
    
    public init(destination: ProfileDestination? = nil) {
        self.destination = destination
    }
    
    public var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List {
                    userInfoSection
                    
                    hobbiesSection
                    
                    pairingSection
                        .id(ProfileDestination.pairLater)
                    
                    pointsSection
                    
                    streakSection
                        .id(ProfileDestination.history)
                    
                    signOutSection
                }
                .onAppear {
                    if let destination = destination {
                        withAnimation {
                            proxy.scrollTo(destination, anchor: .top)
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showPairingCode) {
                PairingCodeSheet(code: viewModel.pairingCode ?? "")
            }
            .sheet(isPresented: $viewModel.showAddHobby) {
                AddHobbySheet()
                    .environmentObject(viewModel)
            }
            .onAppear {
                viewModel.loadUserProfile()
                viewModel.loadStreak()
                viewModel.loadUserHobbies()
                Task {
                    await viewModel.loadPoints()
                }
            }
        }
    }
    
    private var userInfoSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.userSnapshot?.displayName ?? "User")
                        .font(.headline)
                    Text(viewModel.userSnapshot?.email ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let role = viewModel.userSnapshot?.userRole {
                        Text(role.rawValue)
                            .font(.caption)
                            .foregroundStyle(Color(hex: "#2BB3B3"))
                    }
                }
                
                Spacer()
                
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color(hex: "#FFC7B2"))
            }
            .padding(.vertical, 8)
        }
    }
    
    private var pairingSection: some View {
        Section {
            Button(action: {
                viewModel.generatePairingCode()
                showPairingCode = true
            }) {
                HStack {
                    Image(systemName: "link")
                        .foregroundColor(Color(hex: "#2BB3B3"))
                    Text("Pair with \(viewModel.userSnapshot?.userRole == UserRole.teen ? "Parent" : "Teen")")
                        .foregroundColor(.primary)
                    Spacer()
                    if viewModel.userSnapshot?.pairedWithUserId != nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
        } header: {
            Text("Family Connection")
        }
    }
    
    private var pointsSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Points")
                        .font(.headline)
                    Text("Earned from quizzes and sharing")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)
                    Text("\(viewModel.totalPoints)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("Rewards")
        }
    }
    
    private var streakSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Streak")
                        .font(.headline)
                    Text("Consecutive days with mood logs")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack {
                    Text("\(viewModel.currentStreak)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "#2BB3B3"))
                    Text("days")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("Activity")
        }
    }
    
    private var hobbiesSection: some View {
        Section {
            if viewModel.userHobbies.isEmpty {
                HStack {
                    Image(systemName: "star")
                        .foregroundColor(.gray)
                    Text("No hobbies added yet")
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            } else {
                ForEach(viewModel.userHobbies, id: \.name) { hobby in
                    NavigationLink(destination: HobbyDetailView(hobby: hobby)) {
                        HStack {
                            Text(hobby.name)
                                .font(.subheadline)
                            Spacer()
                            if hobby.fact.isEmpty {
                                Text("Add info")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            
            Button(action: { viewModel.showAddHobby = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Color(hex: "#2BB3B3"))
                    Text("Add Hobby")
                        .foregroundColor(Color(hex: "#2BB3B3"))
                }
            }
        } header: {
            Text("My Hobbies")
        }
    }
    
    private var signOutSection: some View {
        Section {
            Button(role: .destructive) {
                Task {
                    await viewModel.signOut()
                    await MainActor.run {
                        appState.isAuthenticated = false
                        appState.userRole = nil
                        appState.isPaired = false
                    }
                }
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Sign Out")
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
            }
            .disabled(viewModel.isLoading)
        }
    }
}

struct PairingCodeSheet: View {
    let code: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("Share this code with your family member")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text(code)
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(hex: "#2BB3B3"))
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                
                Text("This code will expire in 5 minutes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle("Pairing Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppState())
}