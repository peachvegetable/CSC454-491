import SwiftUI

struct MyRewardsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = MyRewardsViewModel()
    @State private var selectedReward: RedeemedReward?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.validRewards.isEmpty && viewModel.usedRewards.isEmpty {
                        EmptyRewardsStateView()
                            .padding(.top, 100)
                    } else {
                        // Valid Rewards
                        if !viewModel.validRewards.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Ready to Use")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)
                                
                                ForEach(viewModel.validRewards) { redeemed in
                                    RedeemedRewardCard(
                                        redeemedReward: redeemed,
                                        onTap: { selectedReward = redeemed }
                                    )
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        // Used/Expired Rewards
                        if !viewModel.usedRewards.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Used & Expired")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)
                                
                                ForEach(viewModel.usedRewards) { redeemed in
                                    RedeemedRewardCard(
                                        redeemedReward: redeemed,
                                        isInactive: true,
                                        onTap: {}
                                    )
                                    .padding(.horizontal)
                                    .opacity(0.6)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("My Rewards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedReward) { redeemed in
                UseRewardView(redeemedReward: redeemed) {
                    viewModel.loadRewards()
                }
            }
        }
        .onAppear {
            viewModel.loadRewards()
        }
    }
}

struct RedeemedRewardCard: View {
    let redeemedReward: RedeemedReward
    var isInactive: Bool = false
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: redeemedReward.rewardCard.icon)
                    .font(.title2)
                    .foregroundColor(isInactive ? .gray : .brandPeach)
                    .frame(width: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(redeemedReward.rewardCard.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if redeemedReward.isUsed {
                        if let usedAt = redeemedReward.usedAt {
                            Text("Used \(RelativeDateTimeFormatter().localizedString(for: usedAt, relativeTo: Date()))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else if redeemedReward.isExpired {
                        Text("Expired")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else if let expiresAt = redeemedReward.expiresAt {
                        Text("Expires \(RelativeDateTimeFormatter().localizedString(for: expiresAt, relativeTo: Date()))")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else {
                        Text("Ready to use")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                if !isInactive {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(isInactive)
    }
}

struct UseRewardView: View {
    @Environment(\.dismiss) private var dismiss
    let redeemedReward: RedeemedReward
    let onUse: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                // Reward Icon
                Image(systemName: redeemedReward.rewardCard.icon)
                    .font(.system(size: 100))
                    .foregroundColor(.brandPeach)
                
                // Title
                Text(redeemedReward.rewardCard.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Description
                Text(redeemedReward.rewardCard.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                // Expiry Info
                if let expiresAt = redeemedReward.expiresAt {
                    Label("Expires \(DateFormatter.localizedString(from: expiresAt, dateStyle: .medium, timeStyle: .short))",
                          systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                // Instructions
                VStack(spacing: 16) {
                    Text("Show this screen to your parent to redeem")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        markAsUsed()
                    }) {
                        Label("Mark as Used", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("Use Reward")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func markAsUsed() {
        Task { @MainActor in
            do {
                try ServiceContainer.shared.rewardService.useRedeemedReward(redeemedReward.id)
                onUse()
                dismiss()
            } catch {
                print("Error marking reward as used: \(error)")
            }
        }
    }
}

struct EmptyRewardsStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "gift")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.3))
            
            Text("No Rewards Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text("Complete tasks to earn points\nand redeem awesome rewards!")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
    }
}

@MainActor
class MyRewardsViewModel: ObservableObject {
    @Published var validRewards: [RedeemedReward] = []
    @Published var usedRewards: [RedeemedReward] = []
    
    private let rewardService = ServiceContainer.shared.rewardService
    private let authService = ServiceContainer.shared.authService
    
    func loadRewards() {
        guard let currentUser = authService.currentUser else { return }
        
        let allRewards = rewardService.getValidRedeemedRewards(for: currentUser.id)
        validRewards = allRewards.filter { $0.isValid }
        
        rewardService.loadRedeemedRewards(for: currentUser.id)
        usedRewards = rewardService.myRedeemedRewards.filter { $0.isUsed || $0.isExpired }
    }
}

#Preview {
    MyRewardsView()
}