import SwiftUI

enum PestanaProfe: String, CaseIterable, Hashable {
    case inicio, cuotas, horario, alumnos

    var titulo: String {
        switch self {
        case .inicio: return "Inicio"
        case .cuotas: return "Cuotas"
        case .horario: return "Horario"
        case .alumnos: return "Alumnos"
        }
    }

    var icono: Icono {
        switch self {
        case .inicio: return .casa
        case .cuotas: return .plata
        case .horario: return .cal
        case .alumnos: return .gente
        }
    }
}

/// La barra flotante integrada del entrenador: una sola pieza con el +1 encastrado.
/// 70 de alto, a 20 de los lados y 28 de abajo, grilla 1fr 1fr 80 1fr 1fr.
struct BarraFlotante: View {
    @Binding var pestana: PestanaProfe
    @Binding var menuAbierto: Bool
    var badgeCuotas: Int
    var alTocarActual: (PestanaProfe) -> Void = { _ in }

    var body: some View {
        HStack(spacing: 0) {
            item(.inicio)
            item(.cuotas)
            Color.clear.frame(width: 80)
            item(.horario)
            item(.alumnos)
        }
        .padding(.horizontal, 6)
        .frame(height: 70)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: 0x3B2450), Color(hex: 0x22142D)], startPoint: .top, endPoint: .bottom))
                .overlay {
                    // Brillo de arriba (inset 0 1px 0 blanco .14) y sombra de abajo (inset 0 -1px 0 negro .3).
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(LinearGradient(stops: [.init(color: .white.opacity(0.14), location: 0),
                                                             .init(color: .clear, location: 0.08),
                                                             .init(color: .clear, location: 0.92),
                                                             .init(color: .black.opacity(0.3), location: 1)],
                                                     startPoint: .top, endPoint: .bottom), lineWidth: 1)
                }
                .sombraBarra()
        }
        .overlay(alignment: .top) {
            MasUno(abierto: menuAbierto) {
                Haptico.suave()
                withAnimation(.spring(duration: 0.35, bounce: 0.2)) { menuAbierto.toggle() }
            }
            .offset(y: -26)
        }
        .padding(.horizontal, 20)
    }

    private func item(_ p: PestanaProfe) -> some View {
        let on = p == pestana
        let icono: Icono = (p == .inicio && on) ? .casaOn : p.icono
        return Button {
            if menuAbierto { withAnimation(.spring(duration: 0.3)) { menuAbierto = false } }
            if pestana == p { alTocarActual(p) } else { Haptico.seleccion(); pestana = p }
        } label: {
            VStack(spacing: 4) {
                IconoVista(icono, tamano: 24)
                    .shadow(color: on ? Color.yema.opacity(0.45) : .clear, radius: 4)
                    .overlay(alignment: .topTrailing) {
                        if p == .cuotas && !on && badgeCuotas > 0 {
                            Text("\(badgeCuotas)")
                                .font(Estilo.texto(10, 700).font())
                                .foregroundStyle(.white)
                                .contentTransition(.numericText(value: Double(badgeCuotas)))
                                .padding(.horizontal, 4)
                                .frame(minWidth: 16, minHeight: 16)
                                .background(Color.badge, in: Capsule())
                                .overlay(Capsule().stroke(Color(hex: 0x31203F), lineWidth: 2))
                                .offset(x: 10, y: -5)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                Text(p.titulo)
                    .font(Estilo.texto(11, 600).font())
                    .tracking(0.11)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(on ? Color.yema : Color.hueso.opacity(0.58))
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(Apretable())
        .opacity(menuAbierto ? 0.45 : 1)
        .accessibilityLabel(p == .cuotas && badgeCuotas > 0 ? "\(p.titulo), \(badgeCuotas) para resolver" : p.titulo)
        .accessibilityAddTraits(on ? [.isSelected, .isButton] : .isButton)
    }
}

/// El +1: círculo de 66 con radial yema, aro calado de 6, resplandor y el «+1» 3D al 60 %.
/// Con el menú abierto muestra la cruz.
struct MasUno: View {
    var abierto: Bool
    var accion: () -> Void

    var body: some View {
        Button(action: accion) {
            ZStack {
                Circle()
                    .fill(RadialGradient(stops: [.init(color: Color(hex: 0xFFE7A3), location: 0),
                                                 .init(color: Color(hex: 0xFFC83D), location: 0.48),
                                                 .init(color: Color(hex: 0xE9A400), location: 1)],
                                         center: UnitPoint(x: 0.32, y: 0.26), startRadius: 0, endRadius: 58))
                    // Brillo interno arriba y sombra interna abajo.
                    .overlay(Circle().stroke(LinearGradient(colors: [.white.opacity(0.6), .clear], startPoint: .top, endPoint: .center), lineWidth: 2).blur(radius: 0.5).padding(1))
                    .overlay(Circle().stroke(LinearGradient(colors: [.clear, Color(hex: 0x965A00).opacity(0.35)], startPoint: .center, endPoint: .bottom), lineWidth: 6).blur(radius: 4).clipShape(Circle()))
                    .background(Circle().fill(Color(hex: 0x36213F)).padding(-6))
                    .shadow(color: Color(hex: 0xFFBE28).opacity(0.42), radius: 12, y: 14)
                if abierto {
                    ZStack {
                        Capsule().frame(width: 22, height: 3.5)
                        Capsule().frame(width: 3.5, height: 22)
                    }
                    .foregroundStyle(Color.berenjena800)
                    .rotationEffect(.degrees(45))
                    .transition(.scale.combined(with: .opacity))
                } else {
                    Image("mas-uno")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 66 * 0.6)
                        .shadow(color: Color(hex: 0x502800).opacity(0.25), radius: 1, y: 2)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: 66, height: 66)
            .contentShape(Circle())
        }
        .buttonStyle(Apretable())
        .accessibilityLabel(abierto ? "Cerrar acciones rápidas" : "Acción rápida")
    }
}

/// El velo hueso de 170 detrás de la barra: el contenido se desvanece antes de pasar por debajo.
struct VeloBarra: View {
    var body: some View {
        LinearGradient(stops: [.init(color: .hueso.opacity(0), location: 0),
                               .init(color: .hueso, location: 0.48),
                               .init(color: .hueso, location: 1)],
                       startPoint: .top, endPoint: .bottom)
            .frame(height: 170)
            .allowsHitTesting(false)
    }
}
