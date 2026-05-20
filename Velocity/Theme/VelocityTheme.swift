import SwiftUI

// MARK: - Colors (Velocity Dark Design System)
extension Color {
    // Backgrounds & Surfaces
    static let velocityBackground = Color(hex: "#0e1417")
    static let velocitySurface = Color(hex: "#0e1417")
    static let velocitySurfaceDim = Color(hex: "#0e1417")
    static let velocitySurfaceBright = Color(hex: "#333a3d")
    static let velocitySurfaceContainer = Color(hex: "#1a2123")
    static let velocitySurfaceContainerHigh = Color(hex: "#242b2e")
    static let velocitySurfaceContainerHighest = Color(hex: "#2f3639")
    static let velocitySurfaceContainerLow = Color(hex: "#161d1f")
    static let velocitySurfaceContainerLowest = Color(hex: "#090f12")

    // Primary - Nitro Blue
    static let nitroBlue = Color(hex: "#00d1ff")
    static let nitroBlueDim = Color(hex: "#4cd6ff")
    static let nitroBlueLight = Color(hex: "#a4e6ff")
    static let onNitroBlue = Color(hex: "#003543")
    static let nitroBlueContainer = Color(hex: "#00d1ff")
    static let onNitroBlueContainer = Color(hex: "#00566a")

    // Secondary - Pulse Orange
    static let pulseOrange = Color(hex: "#ff5e07")
    static let pulseOrangeLight = Color(hex: "#ffb59a")
    static let onPulseOrange = Color(hex: "#5a1b00")
    static let pulseOrangeContainer = Color(hex: "#ff5e07")

    // Tertiary
    static let velocityTertiary = Color(hex: "#dcdcdc")
    static let velocityTertiaryContainer = Color(hex: "#c0c0c0")

    // Text
    static let onSurface = Color(hex: "#dde3e7")
    static let onSurfaceVariant = Color(hex: "#bbc9cf")
    static let velocityOutline = Color(hex: "#859399")
    static let velocityOutlineVariant = Color(hex: "#3c494e")

    // Error
    static let velocityError = Color(hex: "#ffb4ab")
    static let velocityErrorContainer = Color(hex: "#93000a")

    // Utility initializer from hex
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography
extension Font {
    // Headlines - Archivo Narrow
    static func headlineHero() -> Font { .custom("ArchivoNarrow-Bold", size: 40) }
    static func headlineLarge() -> Font { .custom("ArchivoNarrow-Bold", size: 32) }
    static func headlineMedium() -> Font { .custom("ArchivoNarrow-SemiBold", size: 24) }

    // Body - Inter
    static func bodyLarge() -> Font { .custom("Inter", size: 18) }
    static func bodyMedium() -> Font { .custom("Inter", size: 16) }
    static func bodySmall() -> Font { .custom("Inter", size: 14) }

    // Labels & Stats - Space Grotesk
    static func labelCaps() -> Font { .custom("SpaceGrotesk-Bold", size: 12) }
    static func statValue() -> Font { .custom("SpaceGrotesk-SemiBold", size: 20) }
    static func statValueLarge() -> Font { .custom("SpaceGrotesk-Bold", size: 28) }
}

// MARK: - Spacing & Radii
enum VelocitySpacing {
    static let base: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let edgeMargin: CGFloat = 20
    static let gutter: CGFloat = 12
}

enum VelocityRadius {
    static let sm: CGFloat = 4
    static let component: CGFloat = 8
    static let card: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let full: CGFloat = 9999
}

// MARK: - Nitro Blue Gradient
extension LinearGradient {
    static let nitroGradient = LinearGradient(
        colors: [Color.nitroBlue, Color(hex: "#0066cc")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let heroOverlay = LinearGradient(
        colors: [.clear, Color.velocityBackground.opacity(0.8), Color.velocityBackground],
        startPoint: .top,
        endPoint: .bottom
    )
}
