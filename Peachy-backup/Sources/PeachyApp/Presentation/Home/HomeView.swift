import SwiftUI

public struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedMood: MoodColor?
    @State private var showEmojiPicker = false
    @State private var selectedEmoji: String?
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("How are you feeling?")
                    .font(.title)
                    .fontWeight(.semibold)
                    .padding(.top, 20)
                
                MoodWheel(selectedMood: $selectedMood)
                    .frame(height: 300)
                    .padding(.horizontal)
                    .accessibilityIdentifier("moodWheel")
                
                if let mood = selectedMood {
                    VStack(spacing: 20) {
                        Text("You selected: \(mood.rawValue)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        if let emoji = selectedEmoji {
                            Text(emoji)
                                .font(.system(size: 60))
                        } else {
                            Button(action: {
                                showEmojiPicker = true
                            }) {
                                Label("Add Emoji", systemImage: "face.smiling")
                                    .font(.headline)
                                    .foregroundColor(Color(hex: "#2BB3B3"))
                            }
                        }
                        
                        Button(action: saveMood) {
                            Text("Save Mood")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "#2BB3B3"))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    .transition(.opacity)
                }
                
                Spacer()
            }
            .navigationTitle("Mood Signal")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showEmojiPicker) {
                EmojiPickerSheet(selectedEmoji: $selectedEmoji)
            }
            .onChange(of: selectedMood) { _ in
                selectedEmoji = nil
            }
        }
        .accessibilityIdentifier("homeRoot")
        .onAppear {
        }
    }
    
    private func saveMood() {
        guard let mood = selectedMood else { return }
        
        Task {
            await viewModel.saveMood(mood, emoji: selectedEmoji)
            selectedMood = nil
            selectedEmoji = nil
        }
    }
}

struct MoodWheel: View {
    @Binding var selectedMood: MoodColor?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(MoodColor.allCases, id: \.self) { mood in
                    HomeMoodSegment(
                        mood: mood,
                        isSelected: selectedMood == mood,
                        geometry: geometry,
                        onTap: {
                            withAnimation(.spring()) {
                                selectedMood = mood
                            }
                        }
                    )
                }
                
                Circle()
                    .fill(Color.white)
                    .frame(width: geometry.size.width * 0.3, 
                           height: geometry.size.width * 0.3)
                    .shadow(radius: 5)
            }
        }
    }
}

struct HomeMoodSegment: View {
    let mood: MoodColor
    let isSelected: Bool
    let geometry: GeometryProxy
    let onTap: () -> Void
    
    private var angle: Double {
        switch mood {
        case .good: return 0
        case .okay: return 120
        case .tough: return 240
        }
    }
    
    var body: some View {
        Path { path in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2
            let innerRadius = radius * 0.3
            
            path.addArc(center: center,
                       radius: isSelected ? radius * 1.05 : radius,
                       startAngle: .degrees(angle - 60),
                       endAngle: .degrees(angle + 60),
                       clockwise: false)
            
            path.addArc(center: center,
                       radius: innerRadius,
                       startAngle: .degrees(angle + 60),
                       endAngle: .degrees(angle - 60),
                       clockwise: true)
            
            path.closeSubpath()
        }
        .fill(Color(hex: mood.hex))
        .shadow(radius: isSelected ? 10 : 2)
        .onTapGesture(perform: onTap)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(), value: isSelected)
    }
}

#Preview {
    HomeView()
}