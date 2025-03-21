import SwiftUI

enum AppTheme: String, CaseIterable {
    case light, dark, system
    
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
    
    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "gear"
        }
    }
}

class ThemeManager: ObservableObject {
    @AppStorage("appTheme") var currentTheme: AppTheme = .system
    
    var colorScheme: ColorScheme? {
        return currentTheme.colorScheme
    }
    
    func setTheme(_ theme: AppTheme) {
        self.currentTheme = theme
    }
} 