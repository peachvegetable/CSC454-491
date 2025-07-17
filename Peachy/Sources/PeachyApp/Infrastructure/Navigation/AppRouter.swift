import SwiftUI

public enum AppRoute {
    case welcome
    case hobbyPicker
    case moodWheel
    case pulse
}

public class AppRouter: ObservableObject {
    @Published public var currentRoute: AppRoute = .welcome
    
    public init() {}
    
    public func navigateTo(_ route: AppRoute) {
        currentRoute = route
    }
}