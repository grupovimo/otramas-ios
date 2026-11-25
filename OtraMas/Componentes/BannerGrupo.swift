import SwiftUI

/// Las otras marcas de Grupo Vimo que se promocionan donde tiene sentido.
enum PromoGrupo: String, CaseIterable {
    case deAPoco, laColumna, bancamos

    var isotipo: String {
        switch self { case .deAPoco: return "promo-deapoco"; case .laColumna: return "promo-lacolumna"; case .bancamos: return "promo-bancamos" }
    }
    var titulo: String {
        switch self {
        case .deAPoco: return "¿Querés comer mejor?"
        case .laColumna: return "Contá lo que sabés en La Columna"
        case .bancamos: return "Vendé tus planes con Bancamos"
        }
    }
    var texto: String {
        switch self {
        case .deAPoco: return "Probá De a Poco con tu nutri: tu plan de comidas, de a poco."
        case .laColumna: return "Escribí sobre entrenamiento y sumá alumnos que te leen."
        case .bancamos: return "Planes y rutinas que se pagan solos. Muy pronto."
        }
    }
    var accion: String {
        switch self { case .deAPoco: return "Conocer De a Poco"; case .laColumna: return "Empezar a escribir"; case .bancamos: return "Avisame" }
    }
    var link: URL? {
        switch self {
        case .deAPoco: return URL(string: "https://deapoco.com.ar")
        case .laColumna: return URL(string: "https://lacolumna.com.ar")
        case .bancamos: return nil
        }
    }
}

/// Banner discreto de otra marca del grupo: tarjeta suave, «De Grupo Vimo», se cierra con la cruz y no vuelve
/// por 30 días. Sin popups.
struct BannerGrupo: View {
    let promo: PromoGrupo
    @AppStorage private var cerrado: Double
    @Environment(Estado.self) private var estado
    @Environment(\.openURL) private var abrir

    init(_ promo: PromoGrupo) {
        self.promo = promo
        _cerrado = AppStorage(wrappedValue: 0, "banner-\(promo.rawValue)")
    }

    static let dias: TimeInterval = 30 * 24 * 3600
    private var visible: Bool { cerrado == 0 || Date().timeIntervalSince1970 - cerrado > Self.dias }

    var body: some View {
        if visible {
            ContenidoBanner(promo: promo, accion: tocar) {
                withAnimation(.snappy) { cerrado = Date().timeIntervalSince1970 }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.97)))
            .padding(.top, 16)
        }
    }

    private func tocar() {
        Haptico.seleccion()
        if let url = promo.link { abrir(url) } else { estado.avisar("Listo, te avisamos cuando salga Bancamos.") }
    }
}

private struct ContenidoBanner: View {
    let promo: PromoGrupo
    var accion: () -> Void
    var cerrar: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(promo.isotipo).resizable().scaledToFit()
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                .accessibilityHidden(true)
            TextosBanner(promo: promo, accion: accion)
            Button(action: cerrar) {
                IconoVista(.cerrar, tamano: 14, grosor: 2.4).foregroundStyle(Color.arena500)
                    .frame(width: 44, height: 44)
            }
            .padding(.top, -12).padding(.trailing, -12)
            .accessibilityLabel("Cerrar la promo de \(promo.titulo)")
        }
        .padding(14)
        .background(Color.arena50, in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous).strokeBorder(Color.arena100, lineWidth: 1))
    }
}

private struct TextosBanner: View {
    let promo: PromoGrupo
    var accion: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text("DE GRUPO VIMO").tipo(.etiqueta).foregroundStyle(Color.arena500)
                if promo == .bancamos {
                    Text("Pronto").tipo(.texto(10, 700)).foregroundStyle(Color.yema700)
                        .padding(.horizontal, 6).frame(height: 18).background(Color.yema100, in: Capsule())
                }
            }
            Text(promo.titulo).tipo(.texto(16, 700)).foregroundStyle(Color.tinta).fixedSize(horizontal: false, vertical: true)
            Text(promo.texto).tipo(.texto(13, 400)).foregroundStyle(Color.texto2).fixedSize(horizontal: false, vertical: true)
            Button(action: accion) {
                HStack(spacing: 4) {
                    Text(promo.accion).tipo(.texto(14, 700))
                    IconoVista(.der, tamano: 12, grosor: 2.6)
                }
                .foregroundStyle(Color.berenjena800)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(Apretable())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
