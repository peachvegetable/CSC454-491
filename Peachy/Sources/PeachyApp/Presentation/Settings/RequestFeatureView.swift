import SwiftUI

struct RequestFeatureView: View {
    let feature: AppFeature
    @State private var reason = ""
    @StateObject private var settingsService = ServiceContainer.shared.featureSettingsService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: feature.icon)
                            .font(.largeTitle)
                            .foregroundColor(.brandPeach)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(feature.displayName)
                                .font(.headline)
                            
                            Text(feature.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Why do you want this feature?")) {
                    TextEditor(text: $reason)
                        .frame(minHeight: 100)
                        .placeholder(when: reason.isEmpty) {
                            Text("Tell your parents why this feature would be helpful...")
                                .foregroundColor(.secondary)
                        }
                }
                
                Section(footer: Text("Your parent will receive a notification about this request")) {
                    Button(action: sendRequest) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Send Request")
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.brandPeach)
                        .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Request Feature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func sendRequest() {
        settingsService.requestFeature(feature, reason: reason)
        dismiss()
    }
}

// Helper extension for placeholder in TextEditor
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .topLeading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            if shouldShow {
                placeholder()
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
            }
            self
        }
    }
}

#Preview {
    RequestFeatureView(feature: .taskRewards)
}