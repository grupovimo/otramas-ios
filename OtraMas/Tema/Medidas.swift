import SwiftUI

/// Radios de v4: 24 tarjetas, hojas y bandas · 12 controles · círculo para íconos.
enum Radio {
    static let tarjeta: CGFloat = 24
    static let control: CGFloat = 12
}

/// Grilla de 4. Margen lateral del teléfono: 20.
enum Espacio {
    static let e1: CGFloat = 4
    static let e2: CGFloat = 8
    static let e3: CGFloat = 12
    static let e4: CGFloat = 16
    static let margen: CGFloat = 20
    static let e6: CGFloat = 24
    static let e8: CGFloat = 32
    /// Alto mínimo de lo que se toca.
    static let tactil: CGFloat = 44
    /// Lo que ocupa la barra flotante (70 + 28 de abajo + aire) para que el contenido no quede tapado.
    static let bajoBarra: CGFloat = 130
}

/// Sombras teñidas de berenjena (nunca gris puro). El blur del CSS ≈ el doble del radio de SwiftUI.
extension View {
    /// .card: 0 1px 2px rgb(43 22 56 / .05), 0 12px 30px rgb(43 22 56 / .07)
    func sombraTarjeta() -> some View {
        self.shadow(color: Color.berenjena800.opacity(0.05), radius: 1, x: 0, y: 1)
            .shadow(color: Color.berenjena800.opacity(0.07), radius: 15, x: 0, y: 12)
    }

    /// Barra flotante: 0 18px 36px rgb(28 20 36 / .38)
    func sombraBarra() -> some View {
        self.shadow(color: Color.tinta.opacity(0.38), radius: 18, x: 0, y: 18)
    }

    /// Menú del +1: 0 24px 48px rgb(20 13 26 / .35)
    func sombraMenu() -> some View {
        self.shadow(color: Color.berenjena950.opacity(0.35), radius: 24, x: 0, y: 24)
    }
}
