import SwiftUI
import UIKit

public struct ColorWheelView: View {
    @Binding var selectedColor: SimpleMoodColor?
    @Binding var selectedEmoji: String?
    @State private var showEmojiPicker = false
    let onSave: () async -> Void
    @Environment(\.dismiss) private var dismiss
    
    public init(
        selectedColor: Binding<SimpleMoodColor?>,
        selectedEmoji: Binding<String?>,
        onSave: @escaping () async -> Void
    ) {
        self._selectedColor = selectedColor
        self._selectedEmoji = selectedEmoji
        self.onSave = onSave
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 8) {
                    Text("How are you feeling?")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                    
                    Text("Tap the wheel to select your mood")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Mood Wheel
                ZStack {
                    SimpleColorWheel(selectedColor: $selectedColor)
                        .frame(width: 280, height: 280)
                    
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
                        
                        Text("Feeling \(color.displayName)")
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
                    }
                    
                    Button(action: {
                        Task {
                            await onSave()
                            dismiss()
                        }
                    }) {
                        Text("Save Mood")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedColor != nil ? Color(hex: "#2BB3B3") : Color.gray.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(selectedColor == nil)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showEmojiPicker) {
            EmojiPickerSheet(selectedEmoji: $selectedEmoji)
        }
        .animation(.easeInOut(duration: 0.3), value: selectedColor)
    }
}

// Simple 3-color wheel
struct SimpleColorWheel: View {
    @Binding var selectedColor: SimpleMoodColor?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Mood segments
                ForEach([SimpleMoodColor.green, .yellow, .red], id: \.self) { mood in
                    ColorSegmentView(
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

struct ColorSegmentView: View {
    let mood: SimpleMoodColor
    let isSelected: Bool
    let geometry: GeometryProxy
    
    private var angle: Double {
        switch mood {
        case .green: return 0
        case .yellow: return 120
        case .red: return 240
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