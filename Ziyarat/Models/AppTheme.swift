import SwiftUI

/// ألوان واجهة التطبيق — يتحكم بها المستخدم.
struct AppTheme: Codable, Hashable {

    var accentHex: String = "#145A32"
    /// مظهر التطبيق: تلقائي / فاتح / داكن
    var appearance: ThemeAppearance = .system

    var accentColor: Color { Color(hex: accentHex) ?? Color(red: 0.08, green: 0.35, blue: 0.2) }

    static let `default` = AppTheme()

    /// ألوان جاهزة للاختيار السريع.
    static let presets: [(name: String, hex: String)] = [
        ("أخضر رسمي", "#145A32"),
        ("أخضر زيتوني", "#4F6F52"),
        ("أزرق", "#1B4F72"),
        ("تركوازي", "#0E6251"),
        ("بنفسجي", "#4A235A"),
        ("نبيذي", "#7B241C"),
        ("بني", "#6E4B3A"),
        ("ذهبي داكن", "#8A6D1F"),
        ("رمادي", "#424949"),
        ("أسود", "#1C1C1E")
    ]
}

enum ThemeAppearance: String, Codable, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "تلقائي"
        case .light:  return "فاتح"
        case .dark:   return "داكن"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}
