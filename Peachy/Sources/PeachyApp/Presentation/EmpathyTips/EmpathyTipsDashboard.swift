import SwiftUI

public struct EmpathyTipsDashboard: View {
    @StateObject private var viewModel = EmpathyTipsViewModel()
    @State private var selectedTip: EmpathyTip?
    @State private var showTipDetail = false
    @State private var selectedCategory: TipCategory?
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Feature Lock Check
                    if !viewModel.isFeatureAvailable {
                        LockedFeatureCard()
                    } else {
                        // Header with current status
                        EmotionalClimateHeader(childStatuses: viewModel.childMoodStatuses)
                        
                        // Active Alerts
                        if !viewModel.pendingNotifications.isEmpty {
                            ActiveAlertsSection(
                                notifications: viewModel.pendingNotifications,
                                onTapAlert: { notification in
                                    viewModel.markNotificationAsViewed(notification)
                                    if let tip = viewModel.getTipForNotification(notification) {
                                        selectedTip = tip
                                        showTipDetail = true
                                    }
                                }
                            )
                        }
                        
                        // Category Filter
                        TipCategoryFilter(
                            selectedCategory: $selectedCategory,
                            categories: TipCategory.allCases
                        )
                        
                        // Recent Tips
                        RecentTipsSection(
                            deliveries: viewModel.recentDeliveries,
                            onTapTip: { delivery in
                                if let tip = viewModel.getTipForDelivery(delivery) {
                                    selectedTip = tip
                                    showTipDetail = true
                                }
                            },
                            onFeedback: { delivery, wasHelpful in
                                viewModel.recordFeedback(for: delivery, wasHelpful: wasHelpful)
                            }
                        )
                        
                        // Tip Library
                        TipLibrarySection(
                            tips: viewModel.filteredTips(by: selectedCategory),
                            onTapTip: { tip in
                                selectedTip = tip
                                showTipDetail = true
                            }
                        )
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Support Insights")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showTipDetail) {
                if let tip = selectedTip {
                    TipDetailView(tip: tip, viewModel: viewModel)
                }
            }
        }
        .onAppear {
            viewModel.loadData()
        }
    }
}

// MARK: - Emotional Climate Header

struct EmotionalClimateHeader: View {
    let childStatuses: [ChildMoodStatus]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Emotional Climate", systemImage: "cloud.sun.fill")
                .font(.headline)
                .foregroundColor(.brandTeal)
            
            if childStatuses.isEmpty {
                Text("No family members to monitor")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(childStatuses) { status in
                            ChildMoodCard(status: status)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct ChildMoodCard: View {
    let status: ChildMoodStatus
    
    var body: some View {
        VStack(spacing: 12) {
            // Mood indicator
            ZStack {
                Circle()
                    .fill(Color(hex: status.currentMoodColor?.hex ?? "#CCCCCC").opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Text(status.currentMoodEmoji ?? "😐")
                    .font(.system(size: 30))
            }
            
            VStack(spacing: 4) {
                Text(status.childName)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if let pattern = status.detectedPattern {
                    Text(pattern.description)
                        .font(.caption2)
                        .foregroundColor(patternColor(for: pattern))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(width: 100)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    private func patternColor(for pattern: MoodPattern) -> Color {
        switch pattern {
        case .suddenDrop, .multipleBad:
            return .red
        case .prolongedLow, .lateNight:
            return .orange
        case .firstNegative:
            return .yellow
        case .improving:
            return .green
        }
    }
}

// MARK: - Active Alerts Section

struct ActiveAlertsSection: View {
    let notifications: [EmpathyNotification]
    let onTapAlert: (EmpathyNotification) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Active Alerts", systemImage: "bell.badge.fill")
                .font(.headline)
                .foregroundColor(.orange)
            
            ForEach(notifications, id: \.id) { notification in
                AlertCard(notification: notification, onTap: {
                    onTapAlert(notification)
                })
            }
        }
    }
}

struct AlertCard: View {
    let notification: EmpathyNotification
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Urgency indicator
                Circle()
                    .fill(Color(hex: notification.urgency?.color ?? "#4ECDC4"))
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(notification.childName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("• \(notification.moodContext)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(notification.primaryTip)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    Text(notification.urgency?.displayName ?? "")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: notification.urgency?.color ?? "#4ECDC4"))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Category Filter

struct TipCategoryFilter: View {
    @Binding var selectedCategory: TipCategory?
    let categories: [TipCategory]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All categories
                TipCategoryChip(
                    title: "All",
                    icon: "square.grid.2x2",
                    isSelected: selectedCategory == nil,
                    action: { selectedCategory = nil }
                )
                
                ForEach(categories, id: \.self) { category in
                    TipCategoryChip(
                        title: category.displayName,
                        icon: category.icon,
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
            }
        }
    }
}

struct TipCategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.brandTeal : Color(.systemGray5))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Recent Tips Section

struct RecentTipsSection: View {
    let deliveries: [TipDelivery]
    let onTapTip: (TipDelivery) -> Void
    let onFeedback: (TipDelivery, Bool) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recent Tips", systemImage: "clock.arrow.circlepath")
                .font(.headline)
                .foregroundColor(.purple)
            
            if deliveries.isEmpty {
                Text("No recent tips delivered")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
            } else {
                ForEach(deliveries, id: \.id) { delivery in
                    RecentTipCard(
                        delivery: delivery,
                        onTap: { onTapTip(delivery) },
                        onFeedback: { wasHelpful in
                            onFeedback(delivery, wasHelpful)
                        }
                    )
                }
            }
        }
    }
}

struct RecentTipCard: View {
    let delivery: TipDelivery
    let onTap: () -> Void
    let onFeedback: (Bool) -> Void
    @State private var showingFeedback = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onTap) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("For \(delivery.childName)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(delivery.pattern?.description ?? "Mood support")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(delivery.deliveredAt, style: .relative)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if delivery.wasHelpful == true {
                        Image(systemName: "hand.thumbsup.fill")
                            .foregroundColor(.green)
                    } else if delivery.wasHelpful == false {
                        Image(systemName: "hand.thumbsdown.fill")
                            .foregroundColor(.red)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if delivery.wasHelpful == nil && !showingFeedback {
                Button(action: { showingFeedback = true }) {
                    Text("Was this helpful?")
                        .font(.caption)
                        .foregroundColor(.brandTeal)
                }
            }
            
            if showingFeedback {
                HStack(spacing: 12) {
                    Button(action: {
                        onFeedback(true)
                        showingFeedback = false
                    }) {
                        Label("Yes", systemImage: "hand.thumbsup")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.green)
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        onFeedback(false)
                        showingFeedback = false
                    }) {
                        Label("No", systemImage: "hand.thumbsdown")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Tip Library

struct TipLibrarySection: View {
    let tips: [EmpathyTip]
    let onTapTip: (EmpathyTip) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Tip Library", systemImage: "books.vertical.fill")
                .font(.headline)
                .foregroundColor(.brandPeach)
            
            ForEach(tips, id: \.id) { tip in
                TipLibraryCard(tip: tip, onTap: { onTapTip(tip) })
            }
        }
    }
}

struct TipLibraryCard: View {
    let tip: EmpathyTip
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: tip.category?.icon ?? "lightbulb.fill")
                    .font(.title3)
                    .foregroundColor(.brandTeal)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(tip.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(tip.content)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        Label(tip.ageRange?.rawValue ?? "All", systemImage: "person.2")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Label(tip.category?.displayName ?? "", systemImage: "tag")
                            .font(.caption2)
                            .foregroundColor(.secondary)
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
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Locked Feature Card

struct LockedFeatureCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text("Premium Feature")
                .font(.headline)
            
            Text("Support Insights is included with Peachy Plus subscription")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text("Get personalized guidance on supporting your child's emotional well-being")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.orange.opacity(0.1), Color.yellow.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
}

// MARK: - Model

struct ChildMoodStatus: Identifiable {
    let id = UUID()
    let childName: String
    let currentMoodColor: SimpleMoodColor?
    let currentMoodEmoji: String?
    let detectedPattern: MoodPattern?
    let lastUpdate: Date
}

#Preview {
    EmpathyTipsDashboard()
}