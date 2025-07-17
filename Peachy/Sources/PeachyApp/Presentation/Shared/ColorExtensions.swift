import SwiftUI

// MARK: - Brand Colors
extension Color {
    static let brandPeach = Color(red: 255/255, green: 199/255, blue: 178/255)
    static let brandTeal = Color(red: 43/255, green: 179/255, blue: 179/255)
    
    // Legacy string-based initializer for compatibility
    init(_ name: String) {
        switch name {
        case "BrandPeach":
            self = .brandPeach
        case "BrandTeal":
            self = .brandTeal
        default:
            self = .accentColor
        }
    }
}