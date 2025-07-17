import SwiftUI

struct ChatRow: View {
    let thread: ChatThread
    let unread: Int
    let latestMood: MoodLog?
    
    private var currentUserID: String {
        ServiceContainer.shared.authService.currentUser?.id ?? ""
    }
    
    private var otherUserID: String {
        thread.otherParticipant(for: currentUserID)
    }
    
    private var backgroundColor: LinearGradient {
        // Use green gradient for Mom (mock data)
        return LinearGradient(
            colors: [.green, .green.opacity(0.3)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Mood emoji or default icon
            if let emoji = latestMood?.emoji {
                Text(emoji)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color(UIColor.systemBackground)))
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.title)
                    .foregroundColor(.gray)
                    .frame(width: 44, height: 44)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(displayName(for: otherUserID))
                        .font(.headline)
                    
                    Spacer()
                    
                    if unread > 0 {
                        Text("\(unread)")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                }
                
                Text("5 new messages")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 16)
        .background(backgroundColor)
        .mask(RoundedRectangle(cornerRadius: 12))
        .frame(height: 88)
    }
    
    private func displayName(for userID: String) -> String {
        // In a real app, this would look up the user profile
        // For demo, show "Mom" for the other participant
        return "Mom 😊"
    }
}