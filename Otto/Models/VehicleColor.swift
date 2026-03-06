import SwiftUI

enum VehicleColor: String, CaseIterable, Identifiable {
    case white
    case silver
    case gray
    case black
    case red
    case blue
    case green
    case brown
    case gold
    case orange

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    /// Value sent to Imagin Studio `paintDescription` parameter
    var paintDescription: String {
        rawValue
    }

    var swatchColor: Color {
        switch self {
        case .white:  Color(uiColor: .systemBackground)
        case .silver: Color(red: 0.75, green: 0.75, blue: 0.77)
        case .gray:   Color(red: 0.45, green: 0.45, blue: 0.47)
        case .black:  Color(red: 0.15, green: 0.15, blue: 0.16)
        case .red:    Color(red: 0.78, green: 0.14, blue: 0.14)
        case .blue:   Color(red: 0.20, green: 0.45, blue: 0.78)
        case .green:  Color(red: 0.18, green: 0.55, blue: 0.34)
        case .brown:  Color(red: 0.45, green: 0.30, blue: 0.20)
        case .gold:   Color(red: 0.76, green: 0.65, blue: 0.35)
        case .orange: Color(red: 0.90, green: 0.45, blue: 0.10)
        }
    }

    var needsBorder: Bool {
        self == .white
    }
}
