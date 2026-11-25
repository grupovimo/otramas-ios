import SwiftUI

enum DestinoProfe: Hashable {
    case tuMes
    case ficha(String)
}

enum HojaProfe: Identifiable, Hashable {
    case cobrar(String?)
    case lista(String)
    case nuevo
    case suspender(String)
    case asignar
    case ajustes
    case ejercicios
    case detalle(String)

    var id: String {
        switch self {
        case .cobrar(let a): return "cobrar-\(a ?? "")"
        case .lista(let c): return "lista-\(c)"
        case .nuevo: return "nuevo"
        case .suspender(let c): return "suspender-\(c)"
        case .asignar: return "asignar"
        case .ajustes: return "ajustes"
        case .ejercicios: return "ejercicios"
        case .detalle(let e): return "detalle-\(e)"
        }
    }
}

/// Navegación del lado del profe: pestaña, pilas de cada pestaña, hojas y el menú del +1.
@MainActor
@Observable
final class NavProfe {
    var pestana: PestanaProfe = .inicio
    var inicio: [DestinoProfe] = []
    var cuotas: [DestinoProfe] = []
    var horario: [DestinoProfe] = []
    var alumnos: [DestinoProfe] = []
    var hoja: HojaProfe?
    var rutinaAbierta = false
    var menuAbierto = false

    func ir(_ p: PestanaProfe) {
        withAnimation(.spring(duration: 0.3)) { menuAbierto = false }
        pestana = p
    }

    func abrirFicha(_ id: String) {
        pestana = .alumnos
        alumnos = [.ficha(id)]
    }

    /// Tocar la pestaña en la que ya estás vuelve a su raíz.
    func volverARaiz(_ p: PestanaProfe) {
        switch p {
        case .inicio: inicio = []
        case .cuotas: cuotas = []
        case .horario: horario = []
        case .alumnos: alumnos = []
        }
    }
}

struct RaizProfe: View {
    @Environment(Estado.self) private var estado
    @State private var nav = NavProfe()
    var arranque: Arranque?

    var body: some View {
        @Bindable var nav = nav
        ZStack(alignment: .bottom) {
            Group {
                switch nav.pestana {
                case .inicio:
                    NavigationStack(path: $nav.inicio) { Inicio().destinos() }
                case .cuotas:
                    NavigationStack(path: $nav.cuotas) { Cuotas().destinos() }
                case .horario:
                    NavigationStack(path: $nav.horario) { Horario().destinos() }
                case .alumnos:
                    NavigationStack(path: $nav.alumnos) { ListaAlumnos().destinos() }
                }
            }
            .blur(radius: nav.menuAbierto ? 3 : 0)

            VeloBarra()
                .ignoresSafeArea(edges: .bottom)
                .opacity(nav.menuAbierto ? 0 : 1)

            if nav.menuAbierto {
                Color.berenjena950.opacity(0.55)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation(.spring(duration: 0.3)) { nav.menuAbierto = false } }
                    .transition(.opacity)
                    .accessibilityHidden(true)
                MenuMasUno()
                    .padding(.horizontal, Espacio.margen)
                    .padding(.bottom, 124 - 34)
                    .transition(.scale(scale: 0.92, anchor: .bottom).combined(with: .opacity))
            }

            BarraFlotante(pestana: $nav.pestana, menuAbierto: $nav.menuAbierto,
                          badgeCuotas: estado.pendientesCuotas) { p in
                withAnimation { nav.volverARaiz(p) }
            }
            .padding(.bottom, 28 - 34)
            .animation(.spring(duration: 0.4), value: estado.pendientesCuotas)
        }
        .environment(nav)
        .sheet(item: $nav.hoja) { hoja in
            switch hoja {
            case .cobrar(let id): HojaCobrar(alumnoId: id)
            case .lista(let id): HojaPasarLista(claseId: id)
            case .nuevo: HojaAlumnoNuevo()
            case .suspender(let id): HojaSuspender(claseId: id)
            case .asignar: HojaAsignar()
            case .ajustes: Ajustes()
            case .ejercicios: NavigationStack { Biblioteca(volver: "Cerrar") }
            case .detalle(let id):
                if let e = estado.ejercicios.first(where: { $0.id == id }) {
                    DetalleEjercicio(ejercicio: e, sexo: estado.sexoIlustracion, cerrable: true)
                }
            }
        }
        .fullScreenCover(isPresented: $nav.rutinaAbierta) {
            ArmadoRutina()
                .environment(estado)
                .environment(nav)
        }
        .onAppear { aplicar(arranque) }
    }

    private func aplicar(_ a: Arranque?) {
        guard let a else { return }
        switch a {
        case .inicio: nav.pestana = .inicio
        case .menu: nav.pestana = .inicio; nav.menuAbierto = true
        case .tumes: nav.pestana = .inicio; nav.inicio = [.tuMes]
        case .cuotas: nav.pestana = .cuotas
        case .horario: nav.pestana = .horario
        case .suspender: nav.pestana = .horario; nav.hoja = .suspender("c3")
        case .alumnos: nav.pestana = .alumnos
        case .ficha: nav.abrirFicha("carla")
        case .rutina: nav.rutinaAbierta = true
        case .cobrar: nav.hoja = .cobrar(nil)
        case .lista: nav.hoja = .lista("c1")
        case .nuevo: nav.hoja = .nuevo
        case .ajustes: nav.hoja = .ajustes
        case .ejercicios: nav.hoja = .ejercicios
        case .ejercicio: nav.hoja = .detalle("sentadilla-goblet")
        default: break
        }
    }
}

private struct Destinos: ViewModifier {
    func body(content: Content) -> some View {
        content.navigationDestination(for: DestinoProfe.self) { d in
            switch d {
            case .tuMes: TuMes()
            case .ficha(let id): FichaAlumno(alumnoId: id)
            }
        }
    }
}

extension View {
    fileprivate func destinos() -> some View { modifier(Destinos()) }
}

/// Esqueleto de una pantalla del profe: banda arriba, cuerpo con margen 20, aire para la barra flotante.
struct PantallaProfe<BandaC: View, Cuerpo: View>: View {
    var abajo: CGFloat = Espacio.bajoBarra
    var arribaCuerpo: CGFloat = 24
    @ViewBuilder var banda: () -> BandaC
    @ViewBuilder var cuerpo: () -> Cuerpo

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Banda { banda() }
                VStack(alignment: .leading, spacing: 0) { cuerpo() }
                    .padding(.horizontal, Espacio.margen)
                    .padding(.top, arribaCuerpo)
                    .padding(.bottom, abajo)
            }
        }
        .scrollIndicators(.hidden)
        .background(Color.hueso.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }
}
