import SwiftUI
import UIKit

/// Archivo (variable: wght 100–900, wdth 62–125) para títulos y números; Figtree (variable: wght 300–900,
/// por defecto Light, así que siempre se pasa wght) para el texto que se lee.
enum Tipo {
    private static let wght = NSNumber(value: 0x7767_6874) // 'wght'
    private static let wdth = NSNumber(value: 0x7764_7468) // 'wdth'
    private static var cache: [String: UIFont] = [:]
    private static let candado = NSLock()

    static func uiFont(_ familia: Familia, tamano: CGFloat, peso: CGFloat, ancho: CGFloat = 100) -> UIFont {
        let clave = "\(familia.rawValue)-\(tamano)-\(peso)-\(ancho)"
        candado.lock(); defer { candado.unlock() }
        if let f = cache[clave] { return f }
        var ejes: [NSNumber: NSNumber] = [wght: NSNumber(value: Double(peso))]
        if familia == .archivo { ejes[wdth] = NSNumber(value: Double(ancho)) }
        // CoreText reusa la instancia por nombre y tamaño si se pide con UIFontDescriptor(.name:): un título
        // (ancho 62) y un número (ancho 75) del mismo tamaño salían iguales. Se copia la base con la variación.
        let base = CTFontCreateWithName(familia.nombrePostScript as CFString, tamano, nil)
        let desc = CTFontDescriptorCreateWithAttributes([kCTFontVariationAttribute: ejes] as CFDictionary)
        let f = CTFontCreateCopyWithAttributes(base, tamano, nil, desc) as UIFont
        cache[clave] = f
        return f
    }

    enum Familia: String {
        case archivo, figtree
        var nombrePostScript: String { self == .archivo ? "Archivo-SemiBold" : "Figtree-Light" }
    }
}

/// Estilos de la escala v4 (12/14/16/20/28/40/64, +88 para la carga en foco).
enum Estilo {
    /// Archivo ancho 62, peso 900, MAYÚSCULAS (el texto lo pasa en mayúsculas quien llama).
    case titulo(CGFloat)
    /// Archivo ancho 75, peso 800, cifras tabulares.
    case numero(CGFloat)
    /// Figtree con peso explícito (400 texto, 600 secundario fuerte, 700 énfasis y botones).
    case texto(CGFloat, CGFloat)
    /// Etiqueta: 12, 700, mayúsculas, 0,07 em.
    case etiqueta

    var tamano: CGFloat {
        switch self {
        case .titulo(let t), .numero(let t), .texto(let t, _): return t
        case .etiqueta: return 12
        }
    }

    /// Cuánto crece con Dynamic Type: el texto sí, los títulos y números grandes poco (no rompen la grilla).
    func factor(_ dts: DynamicTypeSize) -> CGFloat {
        let f: CGFloat
        switch dts {
        case .xSmall: f = 0.85
        case .small: f = 0.9
        case .medium: f = 0.95
        case .large: f = 1
        case .xLarge: f = 1.1
        case .xxLarge: f = 1.2
        case .xxxLarge: f = 1.3
        default: f = 1.4
        }
        let tope: CGFloat = tamano >= 28 ? 1.1 : 1.3
        return min(f, tope)
    }

    func uiFont(_ dts: DynamicTypeSize = .large) -> UIFont {
        let t = tamano * factor(dts)
        switch self {
        case .titulo: return Tipo.uiFont(.archivo, tamano: t, peso: 900, ancho: 62)
        case .numero: return Tipo.uiFont(.archivo, tamano: t, peso: 800, ancho: 75)
        case .texto(_, let peso): return Tipo.uiFont(.figtree, tamano: t, peso: peso)
        case .etiqueta: return Tipo.uiFont(.figtree, tamano: t, peso: 700)
        }
    }

    func font(_ dts: DynamicTypeSize = .large) -> Font {
        // Como el `font-variant-numeric: tabular-nums` de .num: todas las cifras del mismo ancho.
        if case .numero = self { return Font(uiFont(dts)).monospacedDigit() }
        return Font(uiFont(dts))
    }

    var tracking: CGFloat {
        switch self {
        case .titulo(let t): return t * 0.005
        case .numero(let t): return t * -0.01
        case .etiqueta: return 12 * 0.07
        case .texto: return 0
        }
    }
}

private struct ModificadorTipo: ViewModifier {
    let estilo: Estilo
    /// Alto de línea en pt (como el line-height del CSS) para las líneas únicas de Archivo.
    let alto: CGFloat?
    @Environment(\.dynamicTypeSize) private var dts

    func body(content: Content) -> some View {
        let base = content
            .font(estilo.font(dts))
            .tracking(estilo.tracking)
        if let alto {
            // Alto natural de la línea y después el line-height: si no, minimumScaleFactor achica la letra para que entre en el alto.
            base.lineLimit(1).minimumScaleFactor(0.6).fixedSize(horizontal: false, vertical: true)
                .frame(height: alto * estilo.factor(dts))
        } else {
            base
        }
    }
}

extension View {
    /// Aplica un estilo de la escala. `alto` fija el line-height (sólo para una línea).
    func tipo(_ estilo: Estilo, alto: CGFloat? = nil) -> some View {
        modifier(ModificadorTipo(estilo: estilo, alto: alto))
    }
}

/// Texto en mayúsculas con Archivo ancho 62 / 900 (los títulos de la marca).
struct Titulo: View {
    let texto: String
    var tamano: CGFloat = 40
    var color: Color = .berenjena800
    init(_ texto: String, tamano: CGFloat = 40, color: Color = .berenjena800) {
        self.texto = texto; self.tamano = tamano; self.color = color
    }
    var body: some View {
        Text(texto.uppercased(with: Locale(identifier: "es_AR")))
            .tipo(.titulo(tamano), alto: tamano * 0.95 + 4)
            .foregroundStyle(color)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Etiqueta en mayúsculas (12, 700, 0,07 em).
struct Etiqueta: View {
    let texto: String
    var color: Color = .texto2
    init(_ texto: String, color: Color = .texto2) { self.texto = texto; self.color = color }
    var body: some View {
        Text(texto.uppercased(with: Locale(identifier: "es_AR")))
            .tipo(.etiqueta)
            .foregroundStyle(color)
            .lineLimit(1)
    }
}

/// Número de Archivo ancho 75 / 800 con unidad opcional en Figtree (el «.unid» del diseño).
struct Numero: View {
    let valor: String
    var tamano: CGFloat
    var color: Color = .berenjena800
    var unidad: String? = nil
    var chico: String? = nil
    var colorChico: Color? = nil
    var tamanoChico: CGFloat? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(valor).tipo(.numero(tamano)).monospacedDigit().foregroundStyle(color)
                if let chico {
                    Text(chico).tipo(.numero(tamanoChico ?? tamano * 0.6)).foregroundStyle(colorChico ?? color)
                }
            }
            if let unidad {
                Text(unidad).tipo(.texto(14, 600)).foregroundStyle(Color.texto2)
            }
        }
        .lineLimit(1)
    }
}
