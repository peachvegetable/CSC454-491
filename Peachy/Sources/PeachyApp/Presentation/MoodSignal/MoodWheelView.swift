import SwiftUI

// BufferDurationView is in the same module, but let's define it here
struct BufferDurationView: View {
    @Binding var selectedMinutes: Int
    @State private var showPicker = false
    
    let bufferOptions = [5, 10, 15, 30, 45, 60]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Calm Buffer Time")
                .font(.headline)
            
            Text("Choose how long before others can see your mood")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button(action: { showPicker.toggle() }) {
                HStack {
                    Image(systemName: "clock")
                    Text("\(selectedMinutes) minutes")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
        .sheet(isPresented: $showPicker) {
            NavigationView {
                List {
                    ForEach(bufferOptions, id: \.self) { minutes in
                        HStack {
                            Text("\(minutes) minutes")
                            Spacer()
                            if selectedMinutes == minutes {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.brandPeach)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedMinutes = minutes
                            showPicker = false
                        }
                    }
                }
                .navigationTitle("Select Buffer Time")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showPicker = false
                        }
                    }
                }
            }
        }
    }
}

public struct MoodLoggerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appRouter: AppRouter
    @Environment(\.injected) private var container: ServiceContainer
    @State private var selectedColor: MoodColor?
    @State private var selectedEmoji: String?
    @State private var showEmojiPicker = false
    @State private var isSaving = false
    @State private var bufferMinutes = 15
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 8) {
                Text("How are you feeling today?")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Tap the wheel to select your mood")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            
            Spacer()
            
            // Mood Wheel
            ZStack {
                MoodWheelSelector(selectedColor: $selectedColor)
                    .frame(width: 280, height: 280)
                    .accessibilityIdentifier("moodWheel")
                
                if let emoji = selectedEmoji {
                    Text(emoji)
                        .font(.system(size: 60))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedEmoji)
            
            // Selected mood indicator
            if let color = selectedColor {
                HStack {
                    Circle()
                        .fill(Color(hex: color.hex))
                        .frame(width: 20, height: 20)
                    
                    Text("Feeling \(color.rawValue)")
                        .font(.headline)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(20)
                .transition(.scale.combined(with: .opacity))
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 16) {
                if selectedColor != nil {
                    Button(action: { showEmojiPicker = true }) {
                        HStack {
                            Image(systemName: selectedEmoji == nil ? "face.smiling" : "face.smiling.fill")
                            Text(selectedEmoji == nil ? "Add Emoji (Optional)" : "Change Emoji")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    .transition(.scale.combined(with: .opacity))
                    
                    BufferDurationView(selectedMinutes: $bufferMinutes)
                        .transition(.scale.combined(with: .opacity))
                }
                
                Button(action: saveMood) {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Save Mood")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedColor != nil ? Color.brandPeach : Color.gray.opacity(0.3))
                .foregroundColor(selectedColor != nil ? .white : .gray)
                .cornerRadius(12)
                .disabled(selectedColor == nil || isSaving)
                .accessibilityIdentifier("saveMoodButton")
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEmojiPicker) {
            EmojiPickerSheet(selectedEmoji: $selectedEmoji)
        }
        .animation(.easeInOut(duration: 0.3), value: selectedColor)
    }
    
    private func saveMood() {
        guard let color = selectedColor else { return }
        
        isSaving = true
        
        Task {
            do {
                // Save mood log with SimpleMoodColor
                let simpleMoodColor: SimpleMoodColor
                switch color {
                case .good:
                    simpleMoodColor = .green
                case .okay:
                    simpleMoodColor = .yellow
                case .tough:
                    simpleMoodColor = .red
                }
                print("Saving mood: \(simpleMoodColor.rawValue), emoji: \(selectedEmoji ?? "none"), buffer: \(bufferMinutes) minutes")
                try await container.moodService.save(
                    color: simpleMoodColor, 
                    emoji: selectedEmoji,
                    bufferMinutes: bufferMinutes
                )
                print("Mood saved successfully")
                
                // Dismiss the sheet
                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch {
                // Handle error
                print("Error saving mood: \(error)")
                await MainActor.run {
                    isSaving = false
                }
            }
        }
    }
}

// Mood Wheel Component (circular selector)
struct MoodWheelSelector: View {
    @Binding var selectedColor: MoodColor?
    @State private var dragLocation: CGPoint = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Mood segments
                ForEach(MoodColor.allCases, id: \.self) { mood in
                    MoodSegmentView(
                        mood: mood,
                        isSelected: selectedColor == mood,
                        geometry: geometry
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedColor = mood
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
                
                // Center white circle
                Circle()
                    .fill(Color.white)
                    .frame(width: geometry.size.width * 0.3, height: geometry.size.height * 0.3)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct MoodSegmentView: View {
    let mood: MoodColor
    let isSelected: Bool
    let geometry: GeometryProxy
    
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
            
            path.move(to: center)
            path.addArc(
                center: center,
                radius: radius,
                startAngle: .degrees(angle - 60),
                endAngle: .degrees(angle + 60),
                clockwise: false
            )
            path.addArc(
                center: center,
                radius: innerRadius,
                startAngle: .degrees(angle + 60),
                endAngle: .degrees(angle - 60),
                clockwise: true
            )
            path.closeSubpath()
        }
        .fill(Color(hex: mood.hex))
        .overlay(
            Path { path in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let radius = min(geometry.size.width, geometry.size.height) / 2
                let innerRadius = radius * 0.3
                
                path.move(to: center)
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .degrees(angle - 60),
                    endAngle: .degrees(angle + 60),
                    clockwise: false
                )
                path.addArc(
                    center: center,
                    radius: innerRadius,
                    startAngle: .degrees(angle + 60),
                    endAngle: .degrees(angle - 60),
                    clockwise: true
                )
                path.closeSubpath()
            }
            .stroke(Color.white, lineWidth: isSelected ? 4 : 2)
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
}

