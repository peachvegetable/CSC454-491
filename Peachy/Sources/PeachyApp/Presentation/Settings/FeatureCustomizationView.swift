import SwiftUI

struct FeatureCustomizationView: View {
    @StateObject private var settingsService = ServiceContainer.shared.featureSettingsService
    @State private var selectedPreset: FeaturePreset?
    @State private var showingPresetPicker = false
    @State private var hasUnsavedChanges = false
    @State private var showingSaveConfirmation = false
    @Environment(\.dismiss) private var dismiss
    
    private var categorizedFeatures: [FeatureCategory: [AppFeature]] {
        settingsService.getFeaturesByCategory()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Preset Selector
                    presetSelectorCard
                    
                    // Feature Categories
                    ForEach(FeatureCategory.allCases, id: \.self) { category in
                        featureCategorySection(category)
                    }
                    
                    // Pending Requests (for parents)
                    if !settingsService.pendingRequests.isEmpty {
                        pendingRequestsSection
                    }
                    
                    // Last Modified Info
                    if let settings = settingsService.currentSettings {
                        lastModifiedInfo(settings)
                    }
                }
                .padding()
            }
            .navigationTitle("Customize Features")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        if hasUnsavedChanges {
                            showingSaveConfirmation = true
                        } else {
                            dismiss()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingPresetPicker) {
                presetPickerSheet
            }
            .alert("Save Changes?", isPresented: $showingSaveConfirmation) {
                Button("Save") {
                    // Changes are saved automatically
                    dismiss()
                }
                Button("Discard") {
                    settingsService.loadSettings()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        .onAppear {
            settingsService.loadSettings()
            settingsService.startObservingRequests()
        }
    }
    
    // MARK: - Preset Selector Card
    private var presetSelectorCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quick Presets")
                        .font(.headline)
                    
                    Text(currentPresetName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { showingPresetPicker = true }) {
                    Text("Change")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
            
            if let preset = selectedPreset {
                Text(preset.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var currentPresetName: String {
        if let settings = settingsService.currentSettings {
            return settings.presetType == "custom" ? "Custom Configuration" : settings.presetType
        }
        return "Balanced"
    }
    
    // MARK: - Feature Category Section
    private func featureCategorySection(_ category: FeatureCategory) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundColor(.brandPeach)
                Text(category.rawValue)
                    .font(.headline)
            }
            
            VStack(spacing: 8) {
                ForEach(categorizedFeatures[category] ?? [], id: \.self) { feature in
                    featureRow(feature)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Feature Row
    private func featureRow(_ feature: AppFeature) -> some View {
        HStack(spacing: 12) {
            Image(systemName: feature.icon)
                .font(.title3)
                .foregroundColor(isFeatureEnabled(feature) ? .brandPeach : .gray)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(feature.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if feature.isCore {
                        Text("CORE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .cornerRadius(4)
                    }
                }
                
                Text(feature.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if !feature.dependencies.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                            .font(.caption2)
                        Text("Requires: \(feature.dependencies.map { $0.displayName }.joined(separator: ", "))")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { isFeatureEnabled(feature) },
                set: { _ in toggleFeature(feature) }
            ))
            .disabled(feature.isCore || !canToggleFeature(feature))
        }
        .padding(.vertical, 4)
    }
    
    private func isFeatureEnabled(_ feature: AppFeature) -> Bool {
        settingsService.isFeatureEnabled(feature)
    }
    
    private func canToggleFeature(_ feature: AppFeature) -> Bool {
        if feature.isCore { return false }
        
        // Check if dependencies are met
        for dep in feature.dependencies {
            if !isFeatureEnabled(dep) {
                return true // Can enable if we auto-enable dependencies
            }
        }
        
        return true
    }
    
    private func toggleFeature(_ feature: AppFeature) {
        settingsService.toggleFeature(feature)
        hasUnsavedChanges = true
    }
    
    // MARK: - Pending Requests Section
    private var pendingRequestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bell.badge")
                    .foregroundColor(.orange)
                Text("Feature Requests")
                    .font(.headline)
                
                Spacer()
                
                Text("\(settingsService.pendingRequests.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(6)
                    .background(Circle().fill(Color.orange))
            }
            
            ForEach(settingsService.pendingRequests, id: \.id) { request in
                requestCard(request)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func requestCard(_ request: FeatureRequest) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let feature = request.feature {
                    Image(systemName: feature.icon)
                        .foregroundColor(.brandPeach)
                    Text(feature.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                Text(request.requesterName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !request.reason.isEmpty {
                Text(request.reason)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack(spacing: 12) {
                Button(action: { settingsService.approveRequest(request) }) {
                    Label("Approve", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                Button(action: { settingsService.denyRequest(request) }) {
                    Label("Deny", systemImage: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                Text(request.requestedAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    // MARK: - Last Modified Info
    private func lastModifiedInfo(_ settings: FeatureSettings) -> some View {
        HStack {
            Image(systemName: "clock")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Last modified by \(settings.lastModifiedByName)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(settings.lastModifiedAt, style: .relative)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Preset Picker Sheet
    private var presetPickerSheet: some View {
        NavigationView {
            List(FeaturePreset.allCases, id: \.self) { preset in
                Button(action: {
                    settingsService.applyPreset(preset)
                    selectedPreset = preset
                    hasUnsavedChanges = true
                    showingPresetPicker = false
                }) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(preset.rawValue)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(preset.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            ForEach(preset.enabledFeatures.prefix(3), id: \.self) { feature in
                                Image(systemName: feature.icon)
                                    .font(.caption)
                                    .foregroundColor(.brandPeach)
                            }
                            
                            if preset.enabledFeatures.count > 3 {
                                Text("+\(preset.enabledFeatures.count - 3)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Choose Preset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showingPresetPicker = false
                    }
                }
            }
        }
    }
}

#Preview {
    FeatureCustomizationView()
}