import SwiftUI

/// Design tokens from DESIGN_BRIEF.md (Dusk = dark, Dawn = light).
public struct Theme: Equatable, Sendable {
    public let base: UInt32
    public let text: UInt32
    public let textSecondary: UInt32
    public let blobs: [UInt32]
    public let glassFill: Double      // white opacity
    public let glassEdge: Double
    public let glassHighlight: Double
    public let glassSolid: UInt32     // Reduce Transparency fallback
    public let shadow: UInt32
    public let shadowOpacity: Double
    public let pillFill: UInt32
    public let pillText: UInt32
    public let deleteTint: UInt32     // ✕ icon / DELETE tag text
    public let keepTint: UInt32       // ✓ icon / KEEP tag text
    public let scrim: Double          // photo backdrop scrim opacity

    public static let dusk = Theme(
        base: 0x262E3B, text: 0xF4F6FA, textSecondary: 0xC9D2E0,
        blobs: [0x5E7AA6, 0x9A6F80, 0x3F6B66],
        glassFill: 0.12, glassEdge: 0.34, glassHighlight: 0.45, glassSolid: 0x323B4B,
        shadow: 0x000000, shadowOpacity: 0.28, pillFill: 0xE6ECF5, pillText: 0x1F2633,
        deleteTint: 0xF2B8A8, keepTint: 0xA9DCCD, scrim: 0.55)

    public static let dawn = Theme(
        base: 0xEEF1F6, text: 0x1F2633, textSecondary: 0x566072,
        blobs: [0xA9BCDA, 0xE3C3CD, 0xB7D6CF],
        glassFill: 0.55, glassEdge: 0.80, glassHighlight: 1.0, glassSolid: 0xFFFFFF,
        shadow: 0x28374F, shadowOpacity: 0.12, pillFill: 0x262E3B, pillText: 0xF4F6FA,
        deleteTint: 0xA4472F, keepTint: 0x286B59, scrim: 0.75)

    /// Button fills (same in both looks): blush with dark text, sage with dark text.
    public static let blush: UInt32 = 0xF2B8A8
    public static let sage: UInt32 = 0xA9DCCD
    public static let onFill: UInt32 = 0x2A1A16

    public static func resolve(_ scheme: ColorScheme) -> Theme { scheme == .dark ? .dusk : .dawn }
}

public extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255, opacity: opacity)
    }
}

public extension Font {
    /// Cormorant Garamond for titles, dates and big numbers only.
    static func display(_ size: CGFloat, italic: Bool = false) -> Font {
        .custom(italic ? "CormorantGaramond-MediumItalic" : "CormorantGaramond-SemiBold",
                size: size, relativeTo: .largeTitle)
    }
}
