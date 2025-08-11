import SwiftUI

struct RewardShopView: View {
    @StateObject private var viewModel = RewardShopViewModel()
    @State private var selectedCategory: RewardCategory? = nil
    @State private var showCreateReward = false
    @State private var selectedReward: RewardCard?
    @State private var showMyRewards = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Points Balance and My Rewards
                    HStack(spacing: 12) {
                        PointsBalanceCard(balance: viewModel.currentBalance)
                        
                        Button(action: { showMyRewards = true }) {
                            VStack {
                                Image(systemName: "gift.fill")
                                    .font(.title2)
                                Text("My Rewards")
                                    .font(.caption)
                                Text("\(viewModel.myRedeemedRewards.count)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 80)
                            .background(LinearGradient(
                                colors: [.teal, .teal.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .cornerRadius(15)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Points Info Card
                    HStack(spacing: 16) {
                        Image(systemName: "info.circle.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("How to Earn & Use Points")
                                .font(.caption)
                                .fontWeight(.semibold)
                            
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("• Mood update: 5 pts")
                                        .font(.caption2)
                                    Text("• Complete tasks: varies")
                                        .font(.caption2)
                                }
                                
                                Divider()
                                    .frame(height: 20)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("• Tree water: 1 pt = 5 💧")
                                        .font(.caption2)
                                    Text("• Redeem rewards below")
                                        .font(.caption2)
                                }
                            }
                            .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            RewardCategoryChip(
                                title: "All",
                                icon: "square.grid.2x2",
                                isSelected: selectedCategory == nil,
                                action: { selectedCategory = nil }
                            )
                            
                            ForEach(RewardCategory.allCases, id: \.self) { category in
                                RewardCategoryChip(
                                    title: category.rawValue,
                                    icon: category.icon,
                                    isSelected: selectedCategory == category,
                                    action: { selectedCategory = category }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Rewards Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(viewModel.filteredRewards(for: selectedCategory)) { reward in
                            RewardCardView(
                                reward: reward,
                                currentBalance: viewModel.currentBalance,
                                onTap: { selectedReward = reward }
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    if viewModel.filteredRewards(for: selectedCategory).isEmpty {
                        EmptyRewardsView()
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Reward Shop")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isParent {
                        Button(action: { showCreateReward = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.brandPeach)
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreateReward) {
                CreateRewardView(onComplete: {
                    viewModel.loadRewards()
                })
            }
            .sheet(item: $selectedReward) { reward in
                RewardDetailView(reward: reward, onRedeem: {
                    viewModel.redeemReward(reward)
                    selectedReward = nil
                })
            }
            .sheet(isPresented: $showMyRewards) {
                MyRewardsView()
            }
        }
        .onAppear {
            viewModel.loadRewardsWithSampleData()
        }
    }
}

struct RewardCategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.brandPeach : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

struct RewardCardView: View {
    let reward: RewardCard
    let currentBalance: Int
    let onTap: () -> Void
    
    var canAfford: Bool {
        currentBalance >= reward.pointCost
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: reward.icon)
                        .font(.title2)
                        .foregroundColor(canAfford ? .brandPeach : .gray)
                    
                    Spacer()
                    
                    if let maxPerWeek = reward.maxRedemptionsPerWeek {
                        Text("\(maxPerWeek)/week")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(reward.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(reward.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Spacer()
                
                HStack {
                    Label(reward.pointsDisplay, systemImage: "star.fill")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(canAfford ? .brandPeach : .gray)
                    
                    Spacer()
                    
                    if !canAfford {
                        Text("Need \(reward.pointCost - currentBalance) more")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding()
            .frame(height: 160)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(canAfford ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct EmptyRewardsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "gift")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.3))
            
            Text("No rewards available")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Ask your parents to add some rewards!")
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
    RewardShopView()
}