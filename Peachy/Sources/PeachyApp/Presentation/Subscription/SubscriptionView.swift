import SwiftUI

public struct SubscriptionView: View {
    @StateObject private var subscriptionService = ServiceContainer.shared.subscriptionService
    @State private var showingSubscribeSheet = false
    @State private var selectedFeature: SubscriptionFeature?
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Test Mode Toggle (DEBUG only)
                    #if DEBUG
                    testModeSection
                    #endif
                    
                    // Family Group Info
                    if let group = subscriptionService.familyGroup {
                        familyGroupSection(group)
                    }
                    
                    // Current Plan
                    currentPlanSection
                    
                    // Available Subscriptions
                    availableSubscriptionsSection
                    
                    // Peachy Plus Promotion
                    peachyPlusSection
                }
                .padding()
            }
            .navigationTitle("Subscription")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedFeature) { feature in
                SubscribeSheet(feature: feature, subscriptionService: subscriptionService)
            }
        }
        .onAppear {
            subscriptionService.initialize()
        }
    }
    
    // MARK: - Test Mode Section
    #if DEBUG
    private var testModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "hammer.fill")
                    .foregroundColor(.orange)
                Text("Developer Options")
                    .font(.headline)
            }
            
            Toggle(isOn: Binding(
                get: { subscriptionService.currentSubscription?.isTestMode ?? false },
                set: { _ in 
                    subscriptionService.toggleTestMode()
                    // Force UI refresh after toggle
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        subscriptionService.objectWillChange.send()
                    }
                }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Test Mode")
                        .font(.subheadline)
                    Text("Access all features without payment")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .tint(.orange)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    #endif
    
    // MARK: - Family Group Section
    private func familyGroupSection(_ group: FamilyGroup) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundColor(.blue)
                Text("Family Group")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(group.groupName)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                HStack {
                    Text("Invite Code:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(group.inviteCode)
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.medium)
                    
                    Button(action: {
                        UIPasteboard.general.string = group.inviteCode
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                    }
                }
                
                if subscriptionService.isAdmin {
                    Label("You are an admin", systemImage: "crown.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Current Plan Section
    private var currentPlanSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .foregroundColor(.green)
                Text("Current Plan")
                    .font(.headline)
                
                Spacer()
                
                if let subscription = subscriptionService.currentSubscription {
                    if subscription.isTestMode {
                        Text("TEST MODE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
            }
            
            let activeSubscriptions = subscriptionService.getActiveSubscriptions()
            
            if activeSubscriptions.isEmpty {
                Text("Free Plan")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("Core features included:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(["Mood Tracking", "Chat", "Voting System", "Calendar", "Todo List"], id: \.self) { feature in
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text(feature)
                            .font(.caption)
                    }
                }
            } else {
                ForEach(activeSubscriptions, id: \.self) { subscription in
                    HStack {
                        Image(systemName: subscription.icon)
                            .foregroundColor(.brandPeach)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(subscription.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(subscription.price)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if subscriptionService.isAdmin {
                            Button(action: {
                                subscriptionService.cancelSubscription(for: subscription)
                            }) {
                                Text("Cancel")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                
                HStack {
                    Text("Total Monthly:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(String(format: "$%.2f/month", subscriptionService.getTotalMonthlyPrice()))
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Available Subscriptions Section
    private var availableSubscriptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Add-ons")
                .font(.headline)
            
            ForEach(SubscriptionFeature.allCases.filter { $0 != .peachyPlus }, id: \.self) { feature in
                if !subscriptionService.getActiveSubscriptions().contains(feature) &&
                   !subscriptionService.getActiveSubscriptions().contains(.peachyPlus) {
                    SubscriptionCard(
                        feature: feature,
                        isActive: false,
                        canSubscribe: subscriptionService.isAdmin,
                        onSubscribe: {
                            selectedFeature = feature
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Peachy Plus Section
    private var peachyPlusSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "star.circle.fill")
                    .font(.title)
                    .foregroundColor(.yellow)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Peachy Plus")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("All features included")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("$4.99/month")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.brandPeach)
                    
                    Text("Save $\(String(format: "%.2f", subscriptionService.getSavingsWithPeachyPlus()))/month")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                if subscriptionService.isAdmin {
                    Button(action: {
                        selectedFeature = .peachyPlus
                    }) {
                        Text("Subscribe")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(LinearGradient(
                                colors: [.brandPeach, .brandPeach.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .cornerRadius(20)
                    }
                }
            }
            
            // Features included
            VStack(alignment: .leading, spacing: 8) {
                Text("Includes:")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                ForEach(["Reward System", "Family Photo Wall", "Mini-Games", "AI Assistant", "Priority Support"], id: \.self) { feature in
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text(feature)
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.yellow.opacity(0.1), Color.orange.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 2)
        )
        .cornerRadius(12)
    }
}

// MARK: - Subscription Card
struct SubscriptionCard: View {
    let feature: SubscriptionFeature
    let isActive: Bool
    let canSubscribe: Bool
    let onSubscribe: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: feature.icon)
                .font(.title2)
                .foregroundColor(isActive ? .green : .gray)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(feature.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text(feature.price)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.brandPeach)
            }
            
            Spacer()
            
            if !isActive && canSubscribe {
                Button(action: onSubscribe) {
                    Text("Add")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Subscribe Sheet
struct SubscribeSheet: View {
    let feature: SubscriptionFeature
    let subscriptionService: SubscriptionService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: feature.icon)
                    .font(.system(size: 60))
                    .foregroundColor(.brandPeach)
                
                Text(feature.displayName)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(feature.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text(feature.price)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.brandPeach)
                
                Spacer()
                
                Button(action: {
                    subscriptionService.subscribe(to: feature)
                    dismiss()
                }) {
                    Text("Subscribe Now")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.brandPeach)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    SubscriptionView()
}