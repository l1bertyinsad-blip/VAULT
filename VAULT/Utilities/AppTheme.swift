import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "Системная"
        case .light: "Светлая"
        case .dark: "Тёмная"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum VaultPalette {
    static let purple = Color(red: 0.49, green: 0.19, blue: 0.96)

    static let colors: [(id: String, color: Color)] = [
        ("purple", purple),
        ("blue", Color(red: 0.08, green: 0.42, blue: 0.92)),
        ("pink", Color(red: 0.93, green: 0.10, blue: 0.47)),
        ("yellow", Color(red: 0.94, green: 0.62, blue: 0.04)),
        ("green", Color(red: 0.13, green: 0.64, blue: 0.42)),
        ("orange", Color.orange)
    ]

    static func color(for identifier: String) -> Color {
        colors.first(where: { $0.id == identifier })?.color ?? purple
    }
}
