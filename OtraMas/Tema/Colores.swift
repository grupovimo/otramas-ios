import SwiftUI

/// Paleta de Otra Más (marca/sistema/tokens.css). La interfaz es sólo clara.
extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: alpha)
    }

    // Berenjena: la base.
    static let berenjena950 = Color(hex: 0x140D1A)
    static let berenjena900 = Color(hex: 0x1C1424)
    static let berenjena800 = Color(hex: 0x2B1638)
    static let berenjena700 = Color(hex: 0x3D2350)
    static let berenjena600 = Color(hex: 0x553A69)
    static let berenjena500 = Color(hex: 0x7A6587)
    static let berenjena300 = Color(hex: 0xB9ABC2)
    static let berenjena100 = Color(hex: 0xECE6EF)

    // Yema: el único acento (relleno, nunca texto sobre claro).
    static let yema = Color(hex: 0xFFC83D)
    static let yema100 = Color(hex: 0xFFF3D1)
    static let yema700 = Color(hex: 0x8A5A00)

    // Hueso y arena.
    static let hueso = Color(hex: 0xFAF7F2)
    static let tinta = Color(hex: 0x1C1424)
    static let arena50 = Color(hex: 0xF4EFE7)
    static let arena100 = Color(hex: 0xEAE3D8)
    static let arena200 = Color(hex: 0xDAD1C4)
    static let arena300 = Color(hex: 0xBFB4A6)
    static let arena500 = Color(hex: 0x8C8177)
    static let arena600 = Color(hex: 0x6B6159)
    static let arena700 = Color(hex: 0x4F4741)

    // Estados.
    static let ok = Color(hex: 0x1E7A4C)
    static let okFondo = Color(hex: 0xE3F2E9)
    static let okClaro = Color(hex: 0x6FD39C)
    static let error = Color(hex: 0xB4322A)
    static let errorClaro = Color(hex: 0xFF8A80)
    static let badge = Color(hex: 0xE5484D)

    // Roles.
    static let texto2 = Color.arena600
    static let racha = Color(hex: 0xFF9F6B)
    static let salud = Color(hex: 0xFF375F)
    /// Hueso translúcido de los controles sobre la banda (botón osc, «redondo», pestañas de días).
    static let huesoOsc = Color.hueso.opacity(0.12)
}
