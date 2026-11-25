import Foundation

/// El perfil profesional del profe: lo que va a ver un alumno en su página pública (y, más adelante, en el
/// directorio de Otra Más). Cada dato de contacto tiene su visibilidad.
struct PerfilProfe: Codable, Hashable {
    struct Certificacion: Codable, Hashable, Identifiable {
        var id = UUID().uuidString
        var titulo: String
        var institucion: String
        var anio: Int
        var foto: Data? = nil
    }

    struct Lugar: Codable, Hashable, Identifiable {
        var id: LugarClase { tipo }
        var tipo: LugarClase
        var detalle: String
        /// Para «a domicilio»: hasta cuántos km.
        var radioKm: Int? = nil
    }

    enum Modalidad: String, Codable, CaseIterable, Hashable {
        case individual = "Individual", grupal = "Grupal", online = "Online"
        var unidad: String { self == .individual ? "la clase" : "por mes" }
    }

    struct Precio: Codable, Hashable, Identifiable {
        var id: Modalidad { modalidad }
        var modalidad: Modalidad
        var desde: Int
        var activo = true
    }

    struct Resena: Codable, Hashable, Identifiable {
        var id = UUID().uuidString
        var nombre: String
        var estrellas: Int
        var texto: String
        var fecha: String
    }

    /// Datos que se pueden mostrar u ocultar en público.
    enum Dato: String, Codable, CaseIterable, Hashable {
        case telefono, mail, instagram, otras, precios, barrios
        var titulo: String {
            switch self {
            case .telefono: return "WhatsApp"
            case .mail: return "Mail"
            case .instagram: return "Instagram"
            case .otras: return "Otras redes"
            case .precios: return "Precios"
            case .barrios: return "Barrios"
            }
        }
    }

    var foto: Data? = nil
    /// Foto del catálogo mientras no se sube una.
    var fotoAsset: String? = nil
    var portada: Data? = nil
    var portadaAsset: String? = nil
    var nombre: String
    var nombreProfesional: String
    var usuario: String
    var frase: String
    var sobreMi: String
    var especialidades: [String]
    var niveles: [String]
    var certificaciones: [Certificacion]
    var lugares: [Lugar]
    var ciudad: String
    var barrios: [String]
    var precios: [Precio]
    var claseDePrueba: Bool
    var telefono: String
    var mail: String
    var instagram: String
    var otrasRedes: String
    var visible: [Dato: Bool]
    var galeria: [String]
    var galeriaSubida: [Data] = []
    var resenas: [Resena]
    var enDirectorio: Bool
    /// Año en que empezó a entrenar gente.
    var desde: Int

    var link: URL { URL(string: "https://otramas.com.ar/\(usuario)")! }
    func muestra(_ d: Dato) -> Bool { visible[d] ?? true }
    var promedio: Double { resenas.isEmpty ? 0 : Double(resenas.reduce(0) { $0 + $1.estrellas }) / Double(resenas.count) }

    /// Qué falta para tener el perfil completo (título y sección donde se completa).
    var pendientes: [(String, SeccionPerfil)] {
        var p: [(String, SeccionPerfil)] = []
        if foto == nil && fotoAsset == nil { p.append(("Tu foto", .fotos)) }
        if portada == nil && portadaAsset == nil { p.append(("Una foto de portada", .fotos)) }
        if frase.count < 10 { p.append(("Una frase corta", .basicos)) }
        if sobreMi.count < 80 { p.append(("Contá quién sos en «Sobre mí»", .basicos)) }
        if especialidades.isEmpty { p.append(("Tus especialidades", .especialidades)) }
        if certificaciones.isEmpty { p.append(("Tu formación", .formacion)) }
        if lugares.isEmpty { p.append(("Dónde das clases", .lugares)) }
        if !precios.contains(where: \.activo) { p.append(("Tus precios", .precios)) }
        if telefono.isEmpty { p.append(("Tu WhatsApp", .contacto)) }
        if galeria.count + galeriaSubida.count < 6 { p.append(("Sumá \(6 - galeria.count - galeriaSubida.count) fotos a la galería", .galeria)) }
        if resenas.count < 3 { p.append(("Pedí reseñas a tus alumnos", .resenas)) }
        return p
    }

    static let totalPuntos = 11
    var completitud: Int { Int((Double(PerfilProfe.totalPuntos - pendientes.count) / Double(PerfilProfe.totalPuntos) * 100).rounded()) }
}

enum SeccionPerfil: String, CaseIterable, Hashable, Identifiable {
    case fotos, basicos, especialidades, formacion, lugares, precios, horarios, contacto, galeria, resenas
    var id: String { rawValue }
    var titulo: String {
        switch self {
        case .fotos: return "Foto y portada"
        case .basicos: return "Nombre y presentación"
        case .especialidades: return "Especialidades y niveles"
        case .formacion: return "Formación"
        case .lugares: return "Dónde das clases"
        case .precios: return "Modalidades y precios"
        case .horarios: return "Horarios"
        case .contacto: return "Contacto y privacidad"
        case .galeria: return "Galería"
        case .resenas: return "Reseñas"
        }
    }
    var icono: Icono {
        switch self {
        case .fotos: return .camara
        case .basicos: return .gente
        case .especialidades: return .estrella
        case .formacion: return .trofeo
        case .lugares: return .pin
        case .precios: return .plata
        case .horarios: return .cal
        case .contacto: return .wa
        case .galeria: return .camara
        case .resenas: return .estrella
        }
    }
}

let especialidadesPosibles = ["Funcional", "Musculación", "Pilates", "Running", "Rehabilitación", "Adultos mayores",
                              "Embarazadas", "Deportistas", "Kettlebell", "Movilidad", "Yoga", "Boxeo recreativo"]
let nivelesPosibles = ["Principiantes", "Intermedios", "Avanzados", "Adolescentes", "Adultos mayores"]

extension DatosDeMuestra {
    static let perfilLucia = PerfilProfe(
        fotoAsset: "foto-estudio-ella",
        nombre: "Lucía Ferreyra",
        nombreProfesional: "Lu Ferreyra · Entrenamiento",
        usuario: "luciaentrena",
        frase: "Funcional al aire libre en Mar del Plata. Fuerte, sin lesiones y con ganas de volver.",
        sobreMi: "Soy profe de Educación Física y entreno gente hace diez años. Doy clases en Plaza Mitre y Plaza España, y a domicilio en La Perla y Los Troncos. Me importa que aprendas a moverte bien antes de cargar peso, y que cada semana se note.",
        especialidades: ["Funcional", "Musculación", "Adultos mayores", "Kettlebell"],
        niveles: ["Principiantes", "Intermedios"],
        certificaciones: [
            .init(titulo: "Profesorado de Educación Física", institucion: "ISFD N.º 19, Mar del Plata", anio: 2015),
            .init(titulo: "Entrenadora personal", institucion: "Escuela Argentina de Personal Trainers", anio: 2017),
            .init(titulo: "Entrenamiento funcional y kettlebell", institucion: "Instituto Kinés", anio: 2021),
        ],
        lugares: [
            .init(tipo: .plaza, detalle: "Plaza Mitre y Plaza España"),
            .init(tipo: .domicilio, detalle: "La Perla, Los Troncos y Centro", radioKm: 5),
            .init(tipo: .online, detalle: "Por videollamada, con rutina en la app"),
        ],
        ciudad: "Mar del Plata",
        barrios: ["La Perla", "Centro", "Los Troncos", "Playa Grande"],
        precios: [
            .init(modalidad: .individual, desde: 14000),
            .init(modalidad: .grupal, desde: 45000),
            .init(modalidad: .online, desde: 30000),
        ],
        claseDePrueba: true,
        telefono: "+54 223 555-0142",
        mail: "lu.entrena.mdp@gmail.com",
        instagram: "@lu.entrena.mdp",
        otrasRedes: "",
        visible: [.telefono: true, .mail: false, .instagram: true, .otras: false, .precios: true, .barrios: true],
        galeria: ["foto-domicilio", "foto-tecnica", "foto-detalle", "foto-estudio-ella"],
        resenas: [
            .init(nombre: "Carla Benítez", estrellas: 5, texto: "Entreno con Lu hace dos años. Llegué con dolor de espalda y hoy hago peso muerto sin miedo.", fecha: "2026-10-28"),
            .init(nombre: "Nico Paredes", estrellas: 5, texto: "Las particulares son un antes y un después. Te corrige todo y te explica por qué.", fecha: "2026-11-12"),
            .init(nombre: "Sofía Méndez", estrellas: 5, texto: "La clase de la mañana en la plaza me cambió el día. Buen grupo y buena onda.", fecha: "2026-09-03"),
            .init(nombre: "Tomás Acosta", estrellas: 4, texto: "Muy buena profe. Ojalá hubiera más horarios a la tarde.", fecha: "2026-08-20"),
        ],
        enDirectorio: false,
        desde: 2016)
}
