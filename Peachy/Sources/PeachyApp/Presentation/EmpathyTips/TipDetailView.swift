import SwiftUI

struct TipDetailView: View {
    let tip: EmpathyTip
    let viewModel: EmpathyTipsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isSaved = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    TipDetailHeader(tip: tip)
                    
                    // Main Content
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Guidance", systemImage: "lightbulb.fill")
                            .font(.headline)
                            .foregroundColor(.brandTeal)
                        
                        Text(tip.content)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    // Example Phrases
                    if !tip.examplePhrases.isEmpty {
                        ExamplePhrasesSection(phrases: Array(tip.examplePhrases))
                    }
                    
                    // What to Avoid
                    if !tip.whatToAvoid.isEmpty {
                        WhatToAvoidSection(phrases: Array(tip.whatToAvoid))
                    }
                    
                    // Follow-up Suggestions
                    if !tip.followUpSuggestions.isEmpty {
                        FollowUpSection(suggestions: Array(tip.followUpSuggestions))
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            Task { @MainActor in
                                saveTip()
                            }
                        }) {
                            Label(isSaved ? "Saved" : "Save for Later", 
                                  systemImage: isSaved ? "bookmark.fill" : "bookmark")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isSaved ? Color.gray : Color.brandTeal)
                                .cornerRadius(12)
                        }
                        .disabled(isSaved)
                        
                        Button(action: {
                            Task { @MainActor in
                                shareTip()
                            }
                        }) {
                            Label("Share with Partner", systemImage: "square.and.arrow.up")
                                .font(.headline)
                                .foregroundColor(.brandTeal)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.brandTeal, lineWidth: 2)
                                )
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Support Insight")
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
    
    @MainActor
    private func saveTip() {
        viewModel.saveTip(tip)
        withAnimation {
            isSaved = true
        }
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    @MainActor
    private func shareTip() {
        // Share support insight via messages or other methods
        let activityVC = UIActivityViewController(
            activityItems: [tip.title, tip.content],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

struct TipDetailHeader: View {
    let tip: EmpathyTip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: tip.category?.icon ?? "lightbulb.fill")
                    .font(.title)
                    .foregroundColor(.brandPeach)
                
                Spacer()
                
                // Metadata badges
                HStack(spacing: 8) {
                    Badge(
                        text: tip.ageRange?.rawValue ?? "All Ages",
                        icon: "person.2",
                        color: .blue
                    )
                    
                    Badge(
                        text: tip.urgency?.displayName ?? "",
                        icon: "clock.fill",
                        color: Color(hex: tip.urgency?.color ?? "#4ECDC4")
                    )
                }
            }
            
            Text(tip.title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(tip.category?.displayName ?? "")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.brandPeach.opacity(0.1), Color.brandTeal.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
    }
}

struct Badge: View {
    let text: String
    let icon: String
    let color: Color
    
    var body: some View {
        Label(text, systemImage: icon)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .cornerRadius(8)
    }
}

struct ExamplePhrasesSection: View {
    let phrases: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Try Saying", systemImage: "quote.bubble.fill")
                .font(.headline)
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(phrases, id: \.self) { phrase in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.top, 2)
                        
                        Text("\"\(phrase)\"")
                            .font(.body)
                            .italic()
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct WhatToAvoidSection: View {
    let phrases: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("What to Avoid", systemImage: "xmark.circle.fill")
                .font(.headline)
                .foregroundColor(.red)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(phrases, id: \.self) { phrase in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.top, 2)
                        
                        Text(phrase)
                            .font(.body)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct FollowUpSection: View {
    let suggestions: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Follow-Up Ideas", systemImage: "arrow.right.circle.fill")
                .font(.headline)
                .foregroundColor(.purple)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(suggestions, id: \.self) { suggestion in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.caption)
                            .foregroundColor(.purple)
                            .padding(.top, 2)
                        
                        Text(suggestion)
                            .font(.body)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(Color.purple.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

#Preview {
    TipDetailView(
        tip: EmpathyTipFactory.createDefaultInsights().first!,
        viewModel: EmpathyTipsViewModel()
    )
}