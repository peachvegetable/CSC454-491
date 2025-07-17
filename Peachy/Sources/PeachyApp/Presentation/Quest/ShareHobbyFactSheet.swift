import SwiftUI

public struct ShareHobbyFactSheet: View {
    let hobby: HobbyPresetItem
    let onDone: (String) -> Void
    @State private var fact: String = ""
    @FocusState private var isFactFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    public init(hobby: HobbyPresetItem, onDone: @escaping (String) -> Void) {
        self.hobby = hobby
        self.onDone = onDone
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 50))
                        .foregroundColor(Color(hex: "#2BB3B3"))
                    
                    Text("Share a cool fact about")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(hobby.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                .padding(.top, 40)
                
                // Fact input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your interesting fact:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("Write a cool fact...", text: $fact, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                        .focused($isFactFocused)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Mark Done button
                Button(action: shareFact) {
                    Text("Mark Done")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(fact.isEmpty ? Color.gray : Color(hex: "#2BB3B3"))
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(fact.isEmpty)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
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
    
    private func shareFact() {
        guard !fact.isEmpty else { return }
        
        // Call onDone with the fact
        onDone(fact)
        
        // Dismiss the sheet
        dismiss()
    }
}

struct ToastView: View {
    let message: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.yellow)
            Text(message)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.8))
        .foregroundColor(.white)
        .cornerRadius(25)
        .padding(.top, 50)
    }
}

#Preview {
    ShareHobbyFactSheet(hobby: HobbyPresetItem(
        id: "1",
        name: "Basketball",
        category: .sports,
        description: "Team sport with hoops",
        emoji: "🏀"
    )) { fact in
        print("Fact shared: \(fact)")
    }
}