import Foundation

/// De dónde salen los datos. Hoy, `DatosDeMuestra` (la maqueta, en memoria). Para conectar la API real se
/// escribe otra implementación (p. ej. `DatosApi`) y se la pasa a `Estado(datos:)`: las pantallas no cambian.
protocol Datos: Sendable {
    // Lectura
    func panelProfe() async throws -> PanelProfe
    func panelAlumno() async throws -> PanelAlumno
    func ejercicios() async throws -> [Ejercicio]
    func tips(para lado: Lado) async throws -> [Tip]

    // Perfil (lo del onboarding)
    func guardarPerfil(_ perfil: Perfil) async throws
    func perfilProfe() async throws -> PerfilProfe
    func guardarPerfilProfe(_ perfil: PerfilProfe) async throws

    // Profe
    func confirmarComprobante(alumnoId: String, comprobanteId: String) async throws
    func registrarCobro(alumnoId: String, monto: Int, medio: MedioPago) async throws
    func recordarDeudas(alumnoIds: [String]) async throws
    func suspenderClase(claseId: String, motivo: String, dejarRecuperar: Bool) async throws
    func guardarAsistencia(claseId: String, presentes: Set<String>) async throws
    func guardarRutina(_ rutina: Rutina) async throws
    func asignarRutina(rutinaId: String, alumnoIds: [String], desde: String, reemplaza: Bool) async throws
    func archivarRutina(id: String, archivada: Bool) async throws
    func enviarRutina(id: String, alumnoIds: [String]) async throws
    func anotarEnClase(claseId: String, alumnoId: String) async throws
    func crearClase(_ clase: ClaseFija, unica fecha: String?) async throws
    func crearAlumno(nombre: String, plan: String) async throws -> Alumno

    // Alumno
    func registrarSerie(ejercicioId: String, kilos: Double, reps: Int) async throws
    func avisarFalta() async throws
}

/// La maqueta: todo lo del diseño (app-v4.html), exacto, y las escrituras no hacen nada.
struct DatosDeMuestra: Datos {
    func panelProfe() async throws -> PanelProfe { Self.profe }
    func panelAlumno() async throws -> PanelAlumno { Self.alumno }
    func ejercicios() async throws -> [Ejercicio] { Self.ejercicios }
    func tips(para lado: Lado) async throws -> [Tip] { lado == .profe ? Self.tipsProfe : Self.tipsAlumno }
    func guardarPerfil(_ perfil: Perfil) async throws {}
    func perfilProfe() async throws -> PerfilProfe { Self.perfilLucia }
    func guardarPerfilProfe(_ perfil: PerfilProfe) async throws {}
    func confirmarComprobante(alumnoId: String, comprobanteId: String) async throws {}
    func registrarCobro(alumnoId: String, monto: Int, medio: MedioPago) async throws {}
    func recordarDeudas(alumnoIds: [String]) async throws {}
    func suspenderClase(claseId: String, motivo: String, dejarRecuperar: Bool) async throws {}
    func guardarAsistencia(claseId: String, presentes: Set<String>) async throws {}
    func guardarRutina(_ rutina: Rutina) async throws {}
    func asignarRutina(rutinaId: String, alumnoIds: [String], desde: String, reemplaza: Bool) async throws {}
    func archivarRutina(id: String, archivada: Bool) async throws {}
    func enviarRutina(id: String, alumnoIds: [String]) async throws {}
    func anotarEnClase(claseId: String, alumnoId: String) async throws {}
    func crearClase(_ clase: ClaseFija, unica fecha: String?) async throws {}
    func crearAlumno(nombre: String, plan: String) async throws -> Alumno {
        Alumno(id: UUID().uuidString, nombre: nombre, tono: .berenjena, plan: plan, horario: "a definir",
               cuota: .alDia, asistencias: 0, clasesDelMes: 0, racha: 0, progreso: nil, pasos: nil, ultimaVez: 0)
    }
    func registrarSerie(ejercicioId: String, kilos: Double, reps: Int) async throws {}
    func avisarFalta() async throws {}
}
