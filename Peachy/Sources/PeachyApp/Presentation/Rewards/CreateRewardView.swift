import SwiftUI

struct CreateRewardView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var pointCost = 50
    @State private var category: RewardCategory = .privileges
    @State private var selectedIcon = "gift"
    @State private var hasValidityLimit = false
    @State private var validityDays = 7
    @State private var hasWeeklyLimit = false
    @State private var maxPerWeek = 1
    
    let onComplete: () -> Void
    
    let iconOptions = [
        "gift", "star.circle", "gamecontroller", "tv", "music.note",
        "fork.knife", "car", "airplane", "ticket", "dollarsign.circle",
        "heart.circle", "sparkles", "crown", "flag.checkered"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                detailsSection
                costSection
                iconSection
                limitsSection
            }
            .navigationTitle("Create Reward")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createReward()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty || description.isEmpty)
                }
            }
        }
    }
    
    private var detailsSection: some View {
        Section("Reward Details") {
            TextField("Reward Title", text: $title)
            
            TextField("Description", text: $description, axis: .vertical)
                .lineLimit(2...4)
        }
    }
    
    private var costSection: some View {
        Section("Cost & Category") {
            Stepper("Cost: \(pointCost) points", value: $pointCost, in: 10...1000, step: 10)
            
            Picker("Category", selection: $category) {
                ForEach(RewardCategory.allCases, id: \.self) { cat in
                    Label(cat.rawValue, systemImage: cat.icon)
                        .tag(cat)
                }
            }
        }
    }
    
    private var iconSection: some View {
        Section("Icon") {
            iconGrid
        }
    }
    
    private var iconGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
            ForEach(iconOptions, id: \.self) { icon in
                iconButton(for: icon)
            }
        }
    }
    
    private func iconButton(for icon: String) -> some View {
        Button(action: { selectedIcon = icon }) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(selectedIcon == icon ? Color.brandPeach.opacity(0.2) : Color.clear)
                .foregroundColor(selectedIcon == icon ? .brandPeach : .primary)
                .cornerRadius(8)
        }
    }
    
    private var limitsSection: some View {
        Section("Limits") {
            Toggle("Set Validity Period", isOn: $hasValidityLimit)
            
            if hasValidityLimit {
                Stepper("Valid for \(validityDays) days", value: $validityDays, in: 1...30)
            }
            
            Toggle("Limit Redemptions Per Week", isOn: $hasWeeklyLimit)
            
            if hasWeeklyLimit {
                Stepper("Max \(maxPerWeek) per week", value: $maxPerWeek, in: 1...10)
            }
        }
    }
    
    private func createReward() {
        guard let currentUser = ServiceContainer.shared.authService.currentUser else { return }
        
        let reward = RewardCard(
            title: title,
            description: description,
            pointCost: pointCost,
            category: category,
            icon: selectedIcon,
            validityDays: hasValidityLimit ? validityDays : nil,
            maxRedemptionsPerWeek: hasWeeklyLimit ? maxPerWeek : nil,
            createdBy: currentUser.id,
            createdByName: currentUser.displayName
        )
        
        Task { @MainActor in
            do {
                try ServiceContainer.shared.rewardService.createReward(reward)
                onComplete()
                dismiss()
            } catch {
                print("Error creating reward: \(error)")
            }
        }
    }
}

#Preview {
    CreateRewardView(onComplete: {})
}