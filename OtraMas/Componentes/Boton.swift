import SwiftUI

/// Se achica un poco al apretar (todo lo tocable).
struct Apretable: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

/// Botones de v4 (.btn): prim, yema, suave y osc; chico (44), normal (48) y alto (56).
struct Boton: View {
    enum Variante { case prim, yema, suave, osc }
    enum Alto { case chico, normal, alto }

    let titulo: String
    var icono: Icono? = nil
    var iconoDerecha: Icono? = nil
    var variante: Variante = .prim
    var alto: Alto = .normal
    var ancho = false
    var colorIcono: Color? = nil
    var relleno: EdgeInsets? = nil
    var accion: () -> Void

    var body: some View {
        Button(action: accion) {
            HStack(spacing: iconoDerecha != nil ? 4 : 8) {
                if let icono {
                    IconoVista(icono, tamano: 20).foregroundStyle(colorIcono ?? colorIconoBase)
                }
                Text(titulo).tipo(.texto(16, 700)).lineLimit(1).minimumScaleFactor(0.8)
                if let iconoDerecha {
                    IconoVista(iconoDerecha, tamano: 16)
                }
            }
            .foregroundStyle(frente)
            .padding(relleno ?? EdgeInsets(top: 0, leading: alto == .chico ? 14 : 16, bottom: 0, trailing: alto == .chico ? 14 : 16))
            .frame(maxWidth: ancho ? .infinity : nil)
            .frame(height: altura)
            .background(fondo, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: Radio.control))
        }
        .buttonStyle(Apretable())
    }

    private var altura: CGFloat {
        switch alto { case .chico: return 44; case .normal: return 48; case .alto: return 56 }
    }

    private var fondo: Color {
        switch variante {
        case .prim: return .berenjena800
        case .yema: return .yema
        case .suave: return .berenjena100
        case .osc: return .huesoOsc
        }
    }

    private var frente: Color {
        switch variante {
        case .prim, .osc: return .hueso
        case .yema, .suave: return .berenjena800
        }
    }

    private var colorIconoBase: Color { variante == .prim ? .yema : frente }
}

/// Botón redondo de 44 (−/+): suave, o «mas» en berenjena con el ícono yema.
struct BotonRedondo: View {
    let icono: Icono
    var fuerte = false
    var etiqueta: String
    var habilitado = true
    var accion: () -> Void

    var body: some View {
        Button(action: accion) {
            IconoVista(icono, tamano: 20)
                .foregroundStyle(fuerte ? Color.yema : Color.berenjena800)
                .frame(width: 44, height: 44)
                .background(fuerte ? Color.berenjena800 : Color.berenjena100, in: Circle())
                .opacity(habilitado ? 1 : 0.4)
        }
        .buttonStyle(Apretable())
        .disabled(!habilitado)
        .accessibilityLabel(etiqueta)
    }
}

/// Paso de la rutina (.step): etiqueta, −, valor en Archivo 40, +.
struct Paso: View {
    let etiqueta: String
    @Binding var valor: Double
    var paso: Double = 1
    var rango: ClosedRange<Double> = 0...999
    var formato: (Double) -> String = { String(Int($0)) }

    var body: some View {
        HStack(spacing: 8) {
            Text(etiqueta).tipo(.texto(16, 600)).foregroundStyle(Color.arena700)
                .frame(maxWidth: .infinity, alignment: .leading)
            BotonRedondo(icono: .menos, etiqueta: "Menos \(etiqueta.lowercased())", habilitado: valor - paso >= rango.lowerBound) {
                cambiar(-paso)
            }
            Text(formato(valor))
                .tipo(.numero(40), alto: 44)
                .monospacedDigit()
                .foregroundStyle(Color.tinta)
                .contentTransition(.numericText(value: valor))
                .frame(width: 72)
            BotonRedondo(icono: .mas, fuerte: true, etiqueta: "Más \(etiqueta.lowercased())", habilitado: valor + paso <= rango.upperBound) {
                cambiar(paso)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(etiqueta)
        .accessibilityValue(formato(valor))
        .accessibilityAdjustableAction { d in
            switch d {
            case .increment: cambiar(paso)
            case .decrement: cambiar(-paso)
            @unknown default: break
            }
        }
    }

    private func cambiar(_ d: Double) {
        let nuevo = min(max(valor + d, rango.lowerBound), rango.upperBound)
        guard nuevo != valor else { return }
        Haptico.seleccion()
        withAnimation(.snappy(duration: 0.2)) { valor = nuevo }
    }
}

/// Chip de selección de 44 (días de la rutina, pausa, motivos, filtros).
struct Chip: View {
    let titulo: String
    var icono: Icono? = nil
    var elegido: Bool
    /// Sobre la banda (hueso .12) o sobre claro (berenjena-100).
    var sobreBanda = false
    /// Elegido en berenjena con letra yema (pausa) en vez de yema con letra berenjena.
    var elegidoOscuro = false
    var ancho = false
    var accion: () -> Void

    var body: some View {
        Button(action: accion) {
            HStack(spacing: 8) {
                if let icono { IconoVista(icono, tamano: 20).foregroundStyle(elegido && elegidoOscuro ? Color.yema : frente) }
                Text(titulo).tipo(.texto(16, 700)).lineLimit(1).minimumScaleFactor(0.8)
            }
            .foregroundStyle(frente)
            .padding(.horizontal, ancho ? 8 : 16)
            .frame(maxWidth: ancho ? .infinity : nil)
            .frame(height: ancho ? 48 : 44)
            .background(fondo, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(Apretable())
        .accessibilityAddTraits(elegido ? .isSelected : [])
    }

    private var fondo: Color {
        if elegido { return elegidoOscuro ? .berenjena800 : .yema }
        return sobreBanda ? .huesoOsc : .berenjena100
    }

    private var frente: Color {
        if elegido { return elegidoOscuro ? .yema : .berenjena800 }
        return sobreBanda ? .hueso : .berenjena800
    }
}
