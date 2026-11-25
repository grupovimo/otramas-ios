import SwiftUI

/// Un tip corto. Claro (tarjeta blanca) en las pantallas, oscuro sobre berenjena en la carga.
struct TipVista: View {
    let tip: Tip
    var oscuro = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            IconoVista(.rayo, tamano: 20)
                .foregroundStyle(Color.berenjena800)
                .frame(width: 40, height: 40)
                .background(Color.yema, in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Etiqueta(titulo, color: oscuro ? .berenjena300 : .yema700)
                Text(tip.texto)
                    .tipo(.texto(16, 600))
                    .foregroundStyle(oscuro ? Color.hueso : Color.tinta)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(oscuro ? Color.hueso.opacity(0.08) : Color.white, in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
        .modifier(SombraSi(activa: !oscuro))
        .accessibilityElement(children: .combine)
    }

    private var titulo: String {
        switch tip.tema {
        case .entrenamiento: return "Tip · Entrenamiento"
        case .descanso: return "Tip · Descanso"
        case .hidratacion: return "Tip · Hidratación"
        case .tecnica: return "Tip · Técnica"
        case .cobros: return "Tip · Cobros"
        case .retencion: return "Tip · Alumnos"
        case .organizacion: return "Tip · Organización"
        }
    }
}

private struct SombraSi: ViewModifier {
    let activa: Bool
    func body(content: Content) -> some View {
        if activa { content.sombraTarjeta() } else { content }
    }
}

/// Pantalla de carga breve al abrir: el +1 que late y un tip.
struct CargaInicial: View {
    let tip: Tip?
    @State private var late = false

    var body: some View {
        ZStack {
            Color.berenjena800.ignoresSafeArea()
            VStack(spacing: 40) {
                Spacer()
                Image("mas-uno")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120)
                    .scaleEffect(late ? 1.06 : 0.94)
                    .rotationEffect(.degrees(late ? -4 : 2))
                    .shadow(color: Color.yema.opacity(0.3), radius: 20, y: 8)
                    .accessibilityLabel("Otra Más")
                Spacer()
                if let tip {
                    TipVista(tip: tip, oscuro: true)
                        .padding(.horizontal, Espacio.margen)
                        .padding(.bottom, 32)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) { late = true }
        }
    }
}
