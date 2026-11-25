import SwiftUI

@main
struct OtraMasApp: App {
    @State private var estado: Estado

    init() {
        // Con `-pantalla x` (capturas y pruebas) se abre directo esa pantalla, en su lado.
        if let a = Arranque.actual {
            if a == .onboarding {
                Perfil.borrar()
                UserDefaults.standard.set("", forKey: "lado")
            } else if let l = a.lado {
                (l == .profe ? DatosDeMuestra.perfilProfe : DatosDeMuestra.perfilAlumno).guardar()
                UserDefaults.standard.set(l.rawValue, forKey: "lado")
            }
        }
        // Después de acomodar el perfil: Estado lo lee al crearse.
        _estado = State(initialValue: Estado())
    }

    var body: some Scene {
        WindowGroup {
            Raiz()
                .environment(estado)
                .preferredColorScheme(.light)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .task { await estado.cargar() }
        }
    }
}

/// Sin perfil, el onboarding. Con perfil, la app del lado elegido (con una carga breve y un tip al abrir).
struct Raiz: View {
    @AppStorage("lado") private var ladoGuardado = ""
    @Environment(Estado.self) private var estado
    @State private var cargando: Bool

    init() {
        let a = Arranque.actual
        _cargando = State(initialValue: a == nil || a == .carga)
    }

    var body: some View {
        ZStack(alignment: .top) {
            if estado.perfil == nil || Lado(rawValue: ladoGuardado) == nil {
                Onboarding(lado: Arranque.ladoOnboarding, paso: Arranque.pasoOnboarding,
                           perfil: Arranque.pasoOnboarding > 0
                               ? (Arranque.ladoOnboarding == .profe ? DatosDeMuestra.perfilProfe : DatosDeMuestra.perfilAlumno) : nil) { p in
                    estado.guardarPerfil(p)
                    withAnimation(.easeInOut(duration: 0.35)) { ladoGuardado = p.lado.rawValue }
                }
                .transition(.opacity)
            } else if Lado(rawValue: ladoGuardado) == .alumno {
                RaizAlumno(arranque: Arranque.actual).transition(.opacity)
            } else {
                RaizProfe(arranque: Arranque.actual).transition(.opacity)
            }
            if cargando && estado.perfil != nil {
                CargaInicial(tip: estado.tip(Lado(rawValue: ladoGuardado) ?? .alumno))
                    .transition(.opacity)
                    .zIndex(50)
                    .task {
                        guard Arranque.actual != .carga else { return }
                        try? await Task.sleep(for: .seconds(1.8))
                        withAnimation(.easeOut(duration: 0.35)) { cargando = false }
                    }
            }
            if let aviso = estado.aviso {
                AvisoFlotante(texto: aviso)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
                    .onTapGesture { withAnimation { estado.aviso = nil } }
            }
        }
    }
}

/// Qué pantalla abrir al arrancar (`-pantalla inicio`, `-pantalla onboarding -paso 3 -ladoOnb alumno`…).
/// Sólo para capturas y pruebas.
enum Arranque: String, CaseIterable {
    case onboarding, carga
    case inicio, menu, tumes, cuotas, horario, suspender, alumnos, ficha, rutina, cobrar, lista, nuevo, ajustes, ejercicios, ejercicio
    case rutinas, rutinaDetalle = "rutina-detalle", asignar, enviar, pdf
    case perfil, editarPerfil = "editar-perfil", asiTeVen = "asi-te-ven", qr
    case hoy, logros, miplan

    static var actual: Arranque? {
        UserDefaults.standard.string(forKey: "pantalla").flatMap(Arranque.init(rawValue:))
    }

    static var pasoOnboarding: Int { actual == .onboarding ? UserDefaults.standard.integer(forKey: "paso") : 0 }
    static var ladoOnboarding: Lado {
        UserDefaults.standard.string(forKey: "ladoOnb").flatMap(Lado.init(rawValue:)) ?? .profe
    }

    var lado: Lado? {
        switch self {
        case .onboarding: return nil
        case .hoy, .logros, .miplan: return .alumno
        case .carga: return .alumno
        default: return .profe
        }
    }
}
