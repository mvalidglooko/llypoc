//
//  ThemeManager.swift
//  llypoc
//
//  Created by Mirela Validzic on 24.07.2025..
//

import SwiftUI

// MARK: - Theme Colors
struct AppColors {
    let primary: Color
    let secondary: Color
    let accent: Color
    let background: Color
    let surface: Color
    let text: Color
    let textSecondary: Color
    let success: Color
    let warning: Color
    let error: Color
    let border: Color
    let shadow: Color
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme = .light
    @Published var colorScheme: ColorScheme = .light
    
    static let shared = ThemeManager()
    
    private init() {}
    
    var colors: AppColors {
        switch currentTheme {
        case .light:
            return AppColors(
                primary: Color(hex: "00B4D8"),
                secondary: Color(hex: "90E0EF"),
                accent: Color(hex: "0077B6"),
                background: Color(hex: "F8F9FA"),
                surface: Color.white,
                text: Color(hex: "212529"),
                textSecondary: Color(hex: "6C757D"),
                success: Color(hex: "28A745"),
                warning: Color(hex: "FFC107"),
                error: Color(hex: "DC3545"),
                border: Color(hex: "DEE2E6"),
                shadow: Color.black.opacity(0.1)
            )
        case .dark:
            return AppColors(
                primary: Color(hex: "00B4D8"),
                secondary: Color(hex: "90E0EF"),
                accent: Color(hex: "0077B6"),
                background: Color(hex: "121212"),
                surface: Color(hex: "1E1E1E"),
                text: Color.white,
                textSecondary: Color(hex: "B0B0B0"),
                success: Color(hex: "4CAF50"),
                warning: Color(hex: "FF9800"),
                error: Color(hex: "F44336"),
                border: Color(hex: "2D2D2D"),
                shadow: Color.black.opacity(0.3)
            )
        case .teal:
            return AppColors(
                primary: Color(hex: "20B2AA"),
                secondary: Color(hex: "48D1CC"),
                accent: Color(hex: "008B8B"),
                background: Color(hex: "F0F8FF"),
                surface: Color.white,
                text: Color(hex: "2F4F4F"),
                textSecondary: Color(hex: "696969"),
                success: Color(hex: "32CD32"),
                warning: Color(hex: "FFD700"),
                error: Color(hex: "FF6347"),
                border: Color(hex: "E0E0E0"),
                shadow: Color.black.opacity(0.1)
            )
        }
    }
    
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        colorScheme = theme == .dark ? .dark : .light
    }
}

// MARK: - App Theme Enum
enum AppTheme: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case teal = "Teal"
    
    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .teal: return "paintbrush.fill"
        }
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 
