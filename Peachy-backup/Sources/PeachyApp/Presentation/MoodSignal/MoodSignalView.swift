import SwiftUI
import UIKit

struct MoodSignalView: View {
    @StateObject private var viewModel = MoodSignalViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("How are you feeling?")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                MoodWheelComponent(selectedMood: $viewModel.selectedMood)
                    .frame(height: 300)
                    .padding()
                
                if let mood = viewModel.selectedMood {
                    VStack(spacing: 16) {
                        Text(mood.emoji)
                            .font(.system(size: 60))
                        
                        Text(mood.name)
                            .font(.headline)
                            .foregroundColor(mood.color)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                Spacer()
                
                if viewModel.selectedMood != nil {
                    CalmBufferControl(viewModel: viewModel)
                        .padding(.horizontal)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Mood Signal")
            .animation(.spring(), value: viewModel.selectedMood)
        }
    }
}

// MARK: - Mood Wheel View
struct MoodWheelComponent: View {
    @Binding var selectedMood: Mood?
    @State private var dragLocation: CGPoint = .zero
    
    let moods: [Mood] = Mood.defaultMoods
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Mood wheel segments
                ForEach(moods) { mood in
                    MoodSegment(
                        mood: mood,
                        totalMoods: moods.count,
                        isSelected: selectedMood?.id == mood.id,
                        center: CGPoint(
                            x: geometry.size.width / 2,
                            y: geometry.size.height / 2
                        ),
                        radius: min(geometry.size.width, geometry.size.height) / 2
                    )
                    .onTapGesture {
                        withAnimation(.spring()) {
                            selectedMood = mood
                        }
                    }
                }
                
                // Center circle
                Circle()
                    .fill(Color(uiColor: .systemBackground))
                    .frame(width: 80, height: 80)
                    .shadow(radius: 5)
                    .overlay(
                        Image(systemName: "heart.fill")
                            .font(.title)
                            .foregroundColor(selectedMood?.color ?? Color.gray)
                    )
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let center = CGPoint(
                            x: geometry.size.width / 2,
                            y: geometry.size.height / 2
                        )
                        selectMoodAtLocation(value.location, center: center)
                    }
            )
        }
    }
    
    private func selectMoodAtLocation(_ location: CGPoint, center: CGPoint) {
        let angle = atan2(location.y - center.y, location.x - center.x)
        let normalizedAngle = angle < 0 ? angle + 2 * .pi : angle
        let segmentAngle = 2 * .pi / CGFloat(moods.count)
        let index = Int(normalizedAngle / segmentAngle)
        
        if index >= 0 && index < moods.count {
            withAnimation(.spring()) {
                selectedMood = moods[index]
            }
        }
    }
}

// MARK: - Mood Segment
struct MoodSegment: View {
    let mood: Mood
    let totalMoods: Int
    let isSelected: Bool
    let center: CGPoint
    let radius: CGFloat
    
    var body: some View {
        Path { path in
            let angle = 2 * .pi / CGFloat(totalMoods)
            let startAngle = angle * CGFloat(mood.index) - .pi / 2
            let endAngle = startAngle + angle
            
            path.move(to: center)
            path.addArc(
                center: center,
                radius: radius * 0.9,
                startAngle: Angle(radians: startAngle),
                endAngle: Angle(radians: endAngle),
                clockwise: false
            )
            path.closeSubpath()
        }
        .fill(mood.color.opacity(isSelected ? 1.0 : 0.6))
        .overlay(
            Text(mood.emoji)
                .font(.system(size: 30))
                .position(
                    x: center.x + cos(segmentMidAngle) * radius * 0.6,
                    y: center.y + sin(segmentMidAngle) * radius * 0.6
                )
        )
    }
    
    private var segmentMidAngle: CGFloat {
        let angle = 2 * .pi / CGFloat(totalMoods)
        let startAngle = angle * CGFloat(mood.index) - .pi / 2
        return startAngle + angle / 2
    }
}

// MARK: - Calm Buffer Control
struct CalmBufferControl: View {
    @ObservedObject var viewModel: MoodSignalViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Calm Buffer Time")
                .font(.headline)
            
            HStack {
                Text("\(Int(viewModel.bufferMinutes)) min")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .frame(width: 80)
                
                Slider(value: $viewModel.bufferMinutes, in: 5...60, step: 5)
                    .accentColor(Color("BrandTeal"))
            }
            
            Button(action: viewModel.sendMoodSignal) {
                Text("Send Mood Signal")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("BrandTeal"))
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Mood Model
struct Mood: Identifiable, Equatable {
    let id = UUID()
    let index: Int
    let name: String
    let emoji: String
    let color: Color
    
    static let defaultMoods: [Mood] = [
        Mood(index: 0, name: "Happy", emoji: "😊", color: .yellow),
        Mood(index: 1, name: "Excited", emoji: "🤩", color: .orange),
        Mood(index: 2, name: "Calm", emoji: "😌", color: .green),
        Mood(index: 3, name: "Sad", emoji: "😢", color: .blue),
        Mood(index: 4, name: "Anxious", emoji: "😰", color: .purple),
        Mood(index: 5, name: "Angry", emoji: "😠", color: .red),
        Mood(index: 6, name: "Confused", emoji: "😕", color: Color.gray),
        Mood(index: 7, name: "Tired", emoji: "😴", color: .indigo)
    ]
}

// MARK: - View Model
class MoodSignalViewModel: ObservableObject {
    @Published var selectedMood: Mood?
    @Published var bufferMinutes: Double = 30
    
    func sendMoodSignal() {
        guard let mood = selectedMood else { return }
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        // Schedule notification
        scheduleBufferNotification()
        
        // Log mood (mock)
        print("Mood signal sent: \(mood.name) with \(Int(bufferMinutes)) minute buffer")
    }
    
    private func scheduleBufferNotification() {
        // Mock notification scheduling
        // In real app, use UNUserNotificationCenter
    }
}
