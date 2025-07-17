import SwiftUI

public struct QuestDetailView: View {
    let quest: Quest
    @Environment(\.dismiss) private var dismiss
    
    public init(quest: Quest) {
        self.quest = quest
    }
    
    public var body: some View {
        VStack(spacing: 24) {
            Text(quest.title)
                .font(.largeTitle)
                .bold()
            
            Text(quest.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Button("Mark Done") { 
                dismiss() 
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}