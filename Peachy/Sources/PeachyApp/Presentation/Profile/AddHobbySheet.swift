import SwiftUI

struct AddHobbySheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @State private var searchText = ""
    @State private var selectedHobby = ""
    
    let presetHobbies = [
        "Gaming", "Reading", "Music", "Sports", "Art", "Cooking",
        "Photography", "Dancing", "Writing", "Traveling", "Hiking", "Swimming",
        "Yoga", "Meditation", "Gardening", "Movies", "Theater", "Fashion",
        "Technology", "Science", "History", "Languages", "Crafts", "DIY",
        "Fitness", "Running", "Cycling", "Basketball", "Soccer", "Tennis"
    ]
    
    var filteredHobbies: [String] {
        if searchText.isEmpty {
            return presetHobbies
        } else {
            return presetHobbies.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search hobbies", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Hobby list
                List {
                    ForEach(filteredHobbies, id: \.self) { hobby in
                        HStack {
                            Text(hobby)
                            Spacer()
                            if selectedHobby == hobby {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(hex: "#2BB3B3"))
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedHobby = hobby
                        }
                    }
                    
                    // Custom hobby option
                    if !searchText.isEmpty && !presetHobbies.contains(searchText) {
                        HStack {
                            Text("Add \"\(searchText)\"")
                                .foregroundColor(Color(hex: "#2BB3B3"))
                            Spacer()
                            if selectedHobby == searchText {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(hex: "#2BB3B3"))
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedHobby = searchText
                        }
                    }
                }
            }
            .navigationTitle("Add Hobby")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addHobby()
                    }
                    .fontWeight(.medium)
                    .disabled(selectedHobby.isEmpty)
                }
            }
        }
    }
    
    private func addHobby() {
        guard !selectedHobby.isEmpty,
              let user = ServiceContainer.shared.authService.currentUser else { return }
        
        do {
            // Add to user's hobbies
            try RealmManager.shared.realm.write {
                if !user.hobbies.contains(selectedHobby) {
                    user.hobbies.append(selectedHobby)
                }
            }
            
            // Create a new hobby model
            let newHobby = HobbyModel(name: selectedHobby, ownerId: user.id, fact: "")
            
            // Save to database
            try RealmManager.shared.save(newHobby)
            
            // Reload hobbies in profile
            profileViewModel.loadUserHobbies()
            
            dismiss()
        } catch {
            print("Error adding hobby: \(error)")
        }
    }
}

#Preview {
    AddHobbySheet()
        .environmentObject(ProfileViewModel())
}