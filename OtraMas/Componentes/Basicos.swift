import SwiftUI
import UIKit

// MARK: - Banda

/// La banda berenjena de arriba: radio 24 abajo, 24 de aire al pie, y se extiende detrás de la barra de estado
/// (también al estirar la lista hacia abajo).
struct Banda<Contenido: View>: View {
    var abajo: CGFloat = 24
    @ViewBuilder var contenido: () -> Contenido

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            contenido()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, abajo)
        .background(alignment: .bottom) {
            UnevenRoundedRectangle(bottomLeadingRadius: Radio.tarjeta, bottomTrailingRadius: Radio.tarjeta, style: .continuous)
                .fill(Color.berenjena800)
                .padding(.top, -1200)
        }
    }
}

// MARK: - Tarjeta y fila

/// Tarjeta única de v4: blanca, radio 24, sombra teñida.
struct Tarjeta<Contenido: View>: View {
    var relleno: CGFloat = 0
    @ViewBuilder var contenido: () -> Contenido

    var body: some View {
        VStack(alignment: .leading, spacing: 0) { contenido() }
            .padding(relleno)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
            .sombraTarjeta()
    }
}

/// Divisor de 1 pt arena-100 entre filas.
struct Divisor: View {
    var body: some View { Rectangle().fill(Color.arena100).frame(height: 1) }
}

/// Nombre y bajada de una fila (.nom + .sub).
struct NomSub: View {
    let nombre: String
    var sub: Text? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(nombre).tipo(.texto(16, 700)).foregroundStyle(Color.tinta).lineLimit(1)
            if let sub {
                sub.tipo(.texto(14, 400)).foregroundStyle(Color.texto2).lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Fragmento en negrita y tinta dentro de una bajada («<b>7 de 10</b> vienen»).
func negrita(_ s: String, color: Color = .tinta, dts: DynamicTypeSize = .large) -> Text {
    Text(s).font(Estilo.texto(14, 700).font(dts)).foregroundColor(color)
}

/// Título de sección (.titsec): Archivo 20 a la izquierda y un dato a la derecha.
struct TituloSeccion<Derecha: View>: View {
    let texto: String
    var arriba: CGFloat = 24
    @ViewBuilder var derecha: () -> Derecha

    var body: some View {
        HStack(alignment: .center) {
            Titulo(texto, tamano: 20)
            Spacer(minLength: 8)
            derecha()
        }
        .padding(.top, arriba)
        .padding(.bottom, 12)
    }
}

extension TituloSeccion where Derecha == EmptyView {
    init(_ texto: String, arriba: CGFloat = 24) {
        self.texto = texto; self.arriba = arriba; self.derecha = { EmptyView() }
    }
}

// MARK: - Avatares

/// Avatar de iniciales (.ini): berenjena, yema o arena.
struct Iniciales: View {
    let texto: String
    var tono: TonoAvatar = .berenjena
    var tamano: CGFloat = 40
    var letra: CGFloat? = nil

    var body: some View {
        let (fondo, frente): (Color, Color) = {
            switch tono {
            case .berenjena: return (.berenjena100, .berenjena800)
            case .yema: return (.yema100, .yema700)
            case .arena: return (Color(hex: 0xEAE3D8), .arena700)
            case .yemaFuerte: return (.yema, .berenjena800)
            }
        }()
        Text(texto)
            .font(Estilo.texto(letra ?? (tamano >= 56 ? 20 : tamano <= 36 ? 12 : 14), 700).font())
            .foregroundStyle(frente)
            .frame(width: tamano, height: tamano)
            .background(fondo, in: Circle())
            .accessibilityHidden(true)
    }
}

/// Foto redonda (avatar de la profe), encuadrada como el `object-position: 50% 18%` del diseño.
struct FotoRedonda: View {
    let nombre: String
    var tamano: CGFloat = 44

    var body: some View {
        Image(nombre)
            .resizable()
            .scaledToFill()
            .frame(width: tamano, height: tamano * 1.5, alignment: .top)
            .offset(y: tamano * 0.18)
            .frame(width: tamano, height: tamano)
            .clipShape(Circle())
            .accessibilityHidden(true)
    }
}

/// Foto recortada con un punto de foco (el object-position del CSS).
struct FotoRecortada: View {
    let nombre: String
    var foco: UnitPoint = .center

    var body: some View {
        GeometryReader { g in
            if let ui = UIImage(named: nombre) {
                let escala = max(g.size.width / ui.size.width, g.size.height / ui.size.height)
                let w = ui.size.width * escala, h = ui.size.height * escala
                Image(uiImage: ui)
                    .resizable()
                    .frame(width: w, height: h)
                    .offset(x: -(w - g.size.width) * foco.x, y: -(h - g.size.height) * foco.y)
            }
        }
        .clipped()
        .accessibilityHidden(true)
    }
}

// MARK: - Controles sobre la banda

/// Círculo de 44 sobre la banda (.redondo).
struct Redondo: View {
    let icono: Icono
    var etiqueta: String
    var accion: () -> Void

    var body: some View {
        Button(action: accion) {
            IconoVista(icono, tamano: 20)
                .foregroundStyle(Color.hueso)
                .frame(width: 44, height: 44)
                .background(Color.huesoOsc, in: Circle())
        }
        .buttonStyle(Apretable())
        .accessibilityLabel(etiqueta)
    }
}

/// Barra de navegación propia sobre la banda: «‹ Alumnos» a la izquierda y algo a la derecha.
struct NavBanda<Derecha: View>: View {
    var atras: String?
    var accionAtras: (() -> Void)?
    @ViewBuilder var derecha: () -> Derecha

    var body: some View {
        HStack {
            if let atras {
                Button { accionAtras?() } label: {
                    HStack(spacing: 0) {
                        IconoVista(.atras, tamano: 24)
                        Text(atras).tipo(.texto(16, 600))
                    }
                    .foregroundStyle(Color.hueso)
                    .frame(height: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(Apretable())
                .accessibilityLabel("Volver a \(atras)")
            }
            Spacer()
            derecha()
        }
        .padding(.leading, 12)
        .padding(.trailing, 20)
        .frame(height: 44)
    }
}

// MARK: - Aviso (toast)

/// Aviso corto arriba, como el «Listo. Les llegó el recordatorio.» de la landing.
struct AvisoFlotante: View {
    let texto: String
    var body: some View {
        HStack(spacing: 8) {
            IconoVista(.tilde, tamano: 20).foregroundStyle(Color.yema)
            Text(texto).tipo(.texto(15, 600)).foregroundStyle(Color.hueso).multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 48)
        .background(Color.berenjena900, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.berenjena950.opacity(0.3), radius: 16, y: 10)
        .padding(.horizontal, 20)
        .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - Hápticos

enum Haptico {
    static func suave() { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
    static func exito() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func seleccion() { UISelectionFeedbackGenerator().selectionChanged() }
}

// MARK: - Volver con el gesto aunque la barra de navegación esté oculta

extension UINavigationController: UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}
