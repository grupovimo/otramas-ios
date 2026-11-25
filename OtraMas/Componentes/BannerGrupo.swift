import SwiftUI

/// Las otras marcas de Grupo Vimo que se promocionan donde tiene sentido (frase, CTA y link de promos.json).
enum PromoGrupo: String, CaseIterable {
    case deAPoco, laColumna, bancamos

    var marca: String {
        switch self { case .deAPoco: return "De a Poco"; case .laColumna: return "La Columna"; case .bancamos: return "Bancamos" }
    }
    /// Foto con la app, como publicidad (2:1, ya trae el logo de la marca).
    var imagen: String {
        switch self { case .deAPoco: return "promo-img-deapoco"; case .laColumna: return "promo-img-lacolumna"; case .bancamos: return "promo-img-bancamos" }
    }
    var titulo: String {
        switch self {
        case .deAPoco: return "¿Querés comer mejor?"
        case .laColumna: return "Contá lo que sabés en La Columna"
        case .bancamos: return "Que te banquen"
        }
    }
    var texto: String {
        switch self {
        case .deAPoco: return "Probá De a Poco con tu nutri: tu plan de comidas, de a poco."
        case .laColumna: return "Escribí sobre entrenamiento y sumá alumnos que te leen."
        case .bancamos: return "Vendé tus planes y rutinas con tu propia página."
        }
    }
    var accion: String {
        switch self { case .deAPoco: return "Encontrá tu nutri"; case .laColumna: return "Leer La Columna"; case .bancamos: return "Avisame" }
    }
    var link: URL {
        switch self {
        case .deAPoco: return URL(string: "https://deapoco.app")!
        case .laColumna: return URL(string: "https://lacolumna.com.ar")!
        case .bancamos: return URL(string: "https://bancamos.com.ar")!
        }
    }
    var pronto: Bool { self == .bancamos }
    /// Si el sitio ya existe. Mientras no, el CTA muestra «Te avisamos cuando salga» en vez de abrir el navegador.
    var disponible: Bool { false }
    var lineaPronto: String {
        switch self {
        case .deAPoco: return "De a Poco, la app para comer mejor con tu nutri, está por salir."
        case .laColumna: return "La Columna, para escribir y leer a los que atienden, está por salir."
        case .bancamos: return "Bancamos, para vender tus planes con tu propia página, está por salir."
        }
    }
}

/// Banner de otra marca del grupo, como publicidad real: foto arriba recortada con el radio de la tarjeta,
/// «De Grupo Vimo», título, CTA y la cruz. Se cierra por 30 días. Sin popups.
struct BannerGrupo: View {
    let promo: PromoGrupo
    @AppStorage private var cerrado: Double
    @Environment(\.openURL) private var abrir
    @State private var pronto = false

    init(_ promo: PromoGrupo) {
        self.promo = promo
        _cerrado = AppStorage(wrappedValue: 0, "banner-\(promo.rawValue)")
    }

    static let dias: TimeInterval = 30 * 24 * 3600
    private var visible: Bool { cerrado == 0 || Date().timeIntervalSince1970 - cerrado > Self.dias }

    var body: some View {
        if visible {
            VStack(alignment: .leading, spacing: 0) {
                FotoBanner(promo: promo)
                TextosBanner(promo: promo, accion: {
                    Haptico.seleccion()
                    if promo.disponible { abrir(promo.link) } else { pronto = true }
                }, cerrar: {
                    withAnimation(.snappy) { cerrado = Date().timeIntervalSince1970 }
                })
            }
            .background(Color.white, in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
            .sombraTarjeta()
            .transition(.opacity.combined(with: .scale(scale: 0.97)))
            .padding(.top, 16)
            .accessibilityElement(children: .contain)
            .sheet(isPresented: $pronto) { HojaPronto(promo: promo) }
        }
    }
}

/// Hoja simple para una marca que todavía no salió: la imagen, una línea y «Te avisamos cuando salga».
struct HojaPronto: View {
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var dismiss
    let promo: PromoGrupo
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(promo.imagen).resizable().aspectRatio(2, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
                .padding(.top, 24)
                .accessibilityLabel(promo.marca)
            Etiqueta("De Grupo Vimo · Pronto")
            Text(promo.lineaPronto).tipo(.texto(17, 600)).foregroundStyle(Color.tinta).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Boton(titulo: "Te avisamos cuando salga", icono: .tilde, variante: .prim, alto: .alto, ancho: true) {
                Haptico.exito()
                estado.avisar("Listo: te avisamos cuando salga \(promo.marca).")
                dismiss()
            }
        }
        .padding(.horizontal, Espacio.margen)
        .padding(.bottom, 8)
        .estiloHoja([.medium])
    }
}

private struct FotoBanner: View {
    let promo: PromoGrupo
    var body: some View {
        Image(promo.imagen)
            .resizable()
            .aspectRatio(2, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Publicidad de \(promo.marca)")
    }
}

private struct TextosBanner: View {
    let promo: PromoGrupo
    var accion: () -> Void
    var cerrar: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text("DE GRUPO VIMO").tipo(.etiqueta).foregroundStyle(Color.arena500)
                if promo.pronto {
                    Text("Pronto").tipo(.texto(10, 700)).foregroundStyle(Color.yema700)
                        .padding(.horizontal, 6).frame(height: 18).background(Color.yema100, in: Capsule())
                }
                Spacer()
                Button(action: cerrar) {
                    IconoVista(.cerrar, tamano: 14, grosor: 2.4).foregroundStyle(Color.arena500).frame(width: 44, height: 44)
                }
                .padding(.vertical, -14).padding(.trailing, -12)
                .accessibilityLabel("Cerrar la publicidad de \(promo.marca)")
            }
            Text(promo.titulo).tipo(.texto(17, 700)).foregroundStyle(Color.tinta).fixedSize(horizontal: false, vertical: true)
            Text(promo.texto).tipo(.texto(13, 400)).foregroundStyle(Color.texto2).fixedSize(horizontal: false, vertical: true)
            Button(action: accion) {
                HStack(spacing: 6) {
                    Text(promo.accion).tipo(.texto(14, 700))
                    IconoVista(.der, tamano: 12, grosor: 2.6)
                }
                .foregroundStyle(Color.berenjena800)
                .padding(.horizontal, 14).frame(height: 40)
                .background(Color.berenjena100, in: Capsule())
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(Apretable())
            .padding(.top, 6)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
