import SwiftUI

struct RewardDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showConfirmation = false
    @StateObject private var viewModel = RewardDetailViewModel()
    
    let reward: RewardCard
    let onRedeem: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Reward Icon & Title
                    VStack(spacing: 16) {
                        Image(systemName: reward.icon)
                            .font(.system(size: 80))
                            .foregroundColor(.brandPeach)
                        
                        Text(reward.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text(reward.pointsDisplay)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.brandPeach)
                    }
                    .padding()
                    
                    // Description
                    Text(reward.description)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Reward Details
                    VStack(alignment: .leading, spacing: 16) {
                        InfoRow(icon: "tag", title: "Category", value: reward.category.rawValue)
                        
                        if let validityDays = reward.validityDays {
                            InfoRow(icon: "clock", title: "Valid for", value: "\(validityDays) days after redemption")
                        }
                        
                        if let maxPerWeek = reward.maxRedemptionsPerWeek {
                            InfoRow(icon: "calendar.badge.clock", title: "Limit", value: "\(maxPerWeek) per week")
                        }
                        
                        InfoRow(icon: "person", title: "Created by", value: reward.createdByName)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                    
                    // Balance Check
                    if viewModel.currentBalance < reward.pointCost {
                        VStack(spacing: 8) {
                            Text("Insufficient Points")
                                .font(.headline)
                                .foregroundColor(.red)
                            
                            Text("You need \(reward.pointCost - viewModel.currentBalance) more points")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("Current balance: \(viewModel.currentBalance) points")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    // Redeem Button
                    Button(action: {
                        showConfirmation = true
                    }) {
                        Label("Redeem for \(reward.pointsDisplay)", systemImage: "gift.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.currentBalance >= reward.pointCost ? Color.brandPeach : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .fontWeight(.semibold)
                    }
                    .disabled(viewModel.currentBalance < reward.pointCost)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Reward Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Confirm Redemption", isPresented: $showConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Redeem") {
                    onRedeem()
                    dismiss()
                }
            } message: {
                Text("Redeem '\(reward.title)' for \(reward.pointCost) points?\n\nYour balance will be \(viewModel.currentBalance - reward.pointCost) points.")
            }
        }
        .onAppear {
            viewModel.loadBalance()
        }
    }
}

@MainActor
class RewardDetailViewModel: ObservableObject {
    @Published var currentBalance: Int = 0
    
    private let pointsService = ServiceContainer.shared.pointsService
    private let authService = ServiceContainer.shared.authService
    
    func loadBalance() {
        guard let currentUser = authService.currentUser else { return }
        pointsService.loadBalance(for: currentUser.id)
        currentBalance = pointsService.currentBalance
    }
}

#Preview {
    RewardDetailView(
        reward: RewardCard(
            title: "1 Hour Extra Screen Time",
            description: "Get an extra hour of gaming or TV time today!",
            pointCost: 50,
            category: .screenTime,
            createdBy: "parent123",
            createdByName: "Mom"
        ),
        onRedeem: {}
    )
}