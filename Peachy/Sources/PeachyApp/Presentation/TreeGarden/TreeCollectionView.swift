import SwiftUI

struct TreeCollectionView: View {
    @ObservedObject var viewModel: TreeGardenViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedType: TreeType?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Statistics
                    if let collection = viewModel.treeCollection {
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Level")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(collection.currentLevel)")
                                        .font(.title)
                                        .fontWeight(.bold)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text("Trees Grown")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(collection.totalTreesGrown)")
                                        .font(.title)
                                        .fontWeight(.bold)
                                }
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    
                    // Tree Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 20) {
                        ForEach(TreeType.allCases, id: \.self) { type in
                            TreeCollectionItem(
                                type: type,
                                isUnlocked: viewModel.availableTreeTypes.contains(type),
                                isCollected: viewModel.treeCollection?.hasCollected(type: type) ?? false,
                                timesGrown: getTimesGrown(for: type),
                                isSelected: selectedType == type,
                                onTap: {
                                    if viewModel.availableTreeTypes.contains(type) {
                                        selectedType = type
                                    }
                                }
                            )
                        }
                    }
                    
                    // Plant button
                    if let selected = selectedType {
                        VStack(spacing: 12) {
                            Text(selected.displayName)
                                .font(.headline)
                            
                            Text("Requires \(selected.waterRequired) 💧 to grow")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                Task {
                                    await viewModel.plantTree(type: selected)
                                    dismiss()
                                }
                            }) {
                                Text("Plant \(selected.displayName)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.green)
                                    .cornerRadius(12)
                            }
                            .disabled(viewModel.currentTree != nil && !viewModel.currentTree!.isFullyGrown)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Tree Collection")
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
    
    private func getTimesGrown(for type: TreeType) -> Int {
        guard let collection = viewModel.treeCollection else { return 0 }
        return collection.collectedTrees.first(where: { $0.treeType == type })?.timesGrown ?? 0
    }
}

struct TreeCollectionItem: View {
    let type: TreeType
    let isUnlocked: Bool
    let isCollected: Bool
    let timesGrown: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 80, height: 80)
                
                if isUnlocked {
                    Text(type.emoji)
                        .font(.system(size: 40))
                } else {
                    Image(systemName: "lock.fill")
                        .font(.title)
                        .foregroundColor(.gray)
                }
                
                if isSelected {
                    Circle()
                        .stroke(Color.green, lineWidth: 3)
                        .frame(width: 85, height: 85)
                }
            }
            
            Text(type.displayName)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(isUnlocked ? .primary : .secondary)
            
            if isCollected && timesGrown > 0 {
                Text("×\(timesGrown)")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            } else if isUnlocked && !isCollected {
                Text("Not grown")
                    .font(.caption2)
                    .foregroundColor(.orange)
            } else if !isUnlocked {
                Text("Level \(type.unlockLevel)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .onTapGesture {
            if isUnlocked {
                onTap()
            }
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color.green.opacity(0.2)
        } else if isCollected {
            return Color.green.opacity(0.1)
        } else if isUnlocked {
            return Color(UIColor.secondarySystemBackground)
        } else {
            return Color.gray.opacity(0.2)
        }
    }
}