import Foundation
import RealmSwift
import Combine

@MainActor
public class FeatureSettingsService: ObservableObject {
    @Published public var currentSettings: FeatureSettings?
    @Published public var pendingRequests: [FeatureRequest] = []
    
    private let realmManager = RealmManager.shared
    private var notificationToken: NotificationToken?
    
    public init() {
        // Don't load settings in init as services might not be ready
        // Views should call loadSettings() when they appear
    }
    
    deinit {
        notificationToken?.invalidate()
    }
    
    // MARK: - Settings Management
    
    public func loadSettings() {
        guard let currentUser = ServiceContainer.shared.authService.currentUser else { 
            print("FeatureSettingsService: No current user, skipping load")
            return 
        }
        
        // Use pairedWithUserId to create a family identifier
        let familyId = getFamilyId(for: currentUser)
        let predicate = NSPredicate(format: "familyId == %@", familyId)
        
        if let settings = realmManager.fetch(FeatureSettings.self, predicate: predicate).first {
            currentSettings = settings
        } else {
            // Create default settings with full preset - all features enabled by default
            // Parents can restrict features later if needed
            let newSettings = FeatureSettings(familyId: familyId, preset: .full)
            newSettings.lastModifiedBy = currentUser.id
            newSettings.lastModifiedByName = currentUser.displayName
            
            do {
                try realmManager.realm.write {
                    // Apply preset within write transaction
                    newSettings.applyPreset(.full)
                    realmManager.realm.add(newSettings)
                }
                currentSettings = newSettings
            } catch {
                print("Error creating default feature settings: \(error)")
                // Don't crash, just use defaults
            }
        }
    }
    
    public func updateSettings(enable: Set<AppFeature>, disable: Set<AppFeature>) {
        guard let settings = currentSettings,
              let currentUser = ServiceContainer.shared.authService.currentUser else { return }
        
        do {
            try realmManager.realm.write {
                // Process disables first to handle dependencies
                for feature in disable {
                    if !feature.isCore {
                        settings.toggle(feature)
                    }
                }
                
                // Then process enables
                for feature in enable {
                    if !feature.isCore && !settings.isEnabled(feature) {
                        settings.toggle(feature)
                    }
                }
                
                settings.lastModifiedBy = currentUser.id
                settings.lastModifiedByName = currentUser.displayName
                settings.lastModifiedAt = Date()
                settings.presetType = "custom"
            }
            
            objectWillChange.send()
        } catch {
            print("Error updating feature settings: \(error)")
        }
    }
    
    public func applyPreset(_ preset: FeaturePreset) {
        guard let settings = currentSettings,
              let currentUser = ServiceContainer.shared.authService.currentUser else { return }
        
        do {
            try realmManager.realm.write {
                settings.applyPreset(preset)
                settings.lastModifiedBy = currentUser.id
                settings.lastModifiedByName = currentUser.displayName
                settings.lastModifiedAt = Date()
            }
            
            objectWillChange.send()
        } catch {
            print("Error applying preset: \(error)")
        }
    }
    
    public func toggleFeature(_ feature: AppFeature) {
        guard let settings = currentSettings,
              !feature.isCore,
              let currentUser = ServiceContainer.shared.authService.currentUser else { return }
        
        do {
            try realmManager.realm.write {
                settings.toggle(feature)
                settings.lastModifiedBy = currentUser.id
                settings.lastModifiedByName = currentUser.displayName
                settings.lastModifiedAt = Date()
                settings.presetType = "custom"
            }
            
            objectWillChange.send()
        } catch {
            print("Error toggling feature: \(error)")
        }
    }
    
    public func isFeatureEnabled(_ feature: AppFeature) -> Bool {
        // Default to all features enabled if settings haven't loaded yet
        // This prevents crashes during initialization
        return currentSettings?.isEnabled(feature) ?? true
    }
    
    // MARK: - Feature Requests (for teens)
    
    public func requestFeature(_ feature: AppFeature, reason: String) {
        guard let currentUser = ServiceContainer.shared.authService.currentUser,
              UserRole(rawValue: currentUser.role) == .user else { return }
        
        // Check if there's already a pending request
        let familyId = getFamilyId(for: currentUser)
        let predicate = NSPredicate(
            format: "requesterId == %@ AND featureRaw == %@ AND status == %@",
            currentUser.id, feature.rawValue, "pending"
        )
        
        if !realmManager.fetch(FeatureRequest.self, predicate: predicate).isEmpty {
            print("Request already pending for this feature")
            return
        }
        
        let request = FeatureRequest(
            requesterId: currentUser.id,
            requesterName: currentUser.displayName,
            feature: feature,
            reason: reason
        )
        
        do {
            try realmManager.save(request)
            // In a real app, this would send a notification to parents
            print("Feature request sent to parents")
        } catch {
            print("Error creating feature request: \(error)")
        }
    }
    
    public func startObservingRequests() {
        guard let currentUser = ServiceContainer.shared.authService.currentUser else { return }
        
        let familyId = getFamilyId(for: currentUser)
        let isParent = UserRole(rawValue: currentUser.role) == .admin
        
        let results: Results<FeatureRequest>
        if isParent {
            // Parents see all pending requests
            results = realmManager.realm.objects(FeatureRequest.self)
                .filter("status == 'pending'")
        } else {
            // Teens see their own requests
            results = realmManager.realm.objects(FeatureRequest.self)
                .filter("requesterId == %@", currentUser.id)
        }
        
        notificationToken = results.observe { [weak self] _ in
            self?.pendingRequests = Array(results)
        }
    }
    
    public func approveRequest(_ request: FeatureRequest) {
        guard let currentUser = ServiceContainer.shared.authService.currentUser,
              UserRole(rawValue: currentUser.role) == .admin,
              let feature = request.feature else { return }
        
        do {
            try realmManager.realm.write {
                request.status = "approved"
                request.respondedAt = Date()
                request.respondedBy = currentUser.id
                
                // Enable the feature
                if let settings = currentSettings {
                    settings.toggle(feature)
                    settings.lastModifiedBy = currentUser.id
                    settings.lastModifiedByName = currentUser.displayName
                    settings.lastModifiedAt = Date()
                }
            }
            
            objectWillChange.send()
        } catch {
            print("Error approving request: \(error)")
        }
    }
    
    public func denyRequest(_ request: FeatureRequest) {
        guard let currentUser = ServiceContainer.shared.authService.currentUser,
              UserRole(rawValue: currentUser.role) == .admin else { return }
        
        do {
            try realmManager.realm.write {
                request.status = "denied"
                request.respondedAt = Date()
                request.respondedBy = currentUser.id
            }
        } catch {
            print("Error denying request: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func getFamilyId(for user: UserProfile) -> String {
        // Create a consistent family ID based on pairing
        // If paired, use the smaller ID to ensure both family members get the same familyId
        if let pairedId = user.pairedWithUserId {
            return user.id < pairedId ? user.id : pairedId
        }
        return user.id
    }
    
    public func getEnabledFeatures() -> [AppFeature] {
        guard let settings = currentSettings else {
            return AppFeature.allCases // Default to all if no settings
        }
        
        return AppFeature.allCases.filter { settings.isEnabled($0) }
    }
    
    public func getFeaturesByCategory() -> [FeatureCategory: [AppFeature]] {
        var categorized: [FeatureCategory: [AppFeature]] = [:]
        
        for category in FeatureCategory.allCases {
            categorized[category] = AppFeature.allCases.filter { $0.category == category }
        }
        
        return categorized
    }
}