import SwiftUI

struct EmojiPickerSheet: View {
    @Binding var selectedEmoji: String?
    @Environment(\.dismiss) var dismiss
    
    let emojis = [
        "😊", "😄", "😁", "😆", "😃", "😀", "🙂", "😌",
        "😔", "😕", "😟", "😢", "😭", "😩", "😫", "😤",
        "😡", "😠", "😑", "😐", "😶", "🙄", "😏", "😒",
        "😴", "😪", "😵", "🤕", "🤒", "🤧", "😷", "🤢",
        "🥰", "😍", "🤩", "😘", "😗", "😚", "😙", "😋",
        "😛", "😜", "🤪", "😝", "🤗", "🤭", "🤫", "🤔",
        "🤐", "🤨", "😮", "😯", "😲", "😳", "🥺", "😦",
        "😧", "😨", "😰", "😥", "😓", "🤯", "😱", "🥵"
    ]
    
    let columns = [
        GridItem(.adaptive(minimum: 50))
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(emojis, id: \.self) { emoji in
                        Button(action: {
                            selectedEmoji = emoji
                            dismiss()
                        }) {
                            Text(emoji)
                                .font(.system(size: 40))
                                .frame(width: 50, height: 50)
                                .background(selectedEmoji == emoji ? Color(hex: "#2BB3B3").opacity(0.2) : Color.clear)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Emoji")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") {
                        selectedEmoji = nil
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    EmojiPickerSheet(selectedEmoji: .constant("😊"))
}