import Foundation

// Lo que se responde en el onboarding. Se guarda en el teléfono (UserDefaults) y se manda a `Datos`.

enum Sexo: String, Codable, CaseIterable, Hashable {
    case mujer, hombre, sinDecir
    var titulo: String {
        switch self { case .mujer: return "Mujer"; case .hombre: return "Hombre"; case .sinDecir: return "Prefiero no decir" }
    }
}

enum Objetivo: String, Codable, CaseIterable, Hashable {
    case bajarPeso, ganarMusculo, fuerza, salud, rendimiento
    var titulo: String {
        switch self {
        case .bajarPeso: return "Bajar de peso"
        case .ganarMusculo: return "Ganar músculo"
        case .fuerza: return "Ganar fuerza"
        case .salud: return "Sentirme mejor"
        case .rendimiento: return "Rendir en mi deporte"
        }
    }
    var bajada: String {
        switch self {
        case .bajarPeso: return "Moverme más y cuidarme"
        case .ganarMusculo: return "Que se note el trabajo"
        case .fuerza: return "Levantar más que ayer"
        case .salud: return "Energía, postura y buen dormir"
        case .rendimiento: return "Correr, saltar, aguantar"
        }
    }
}

enum Experiencia: String, Codable, CaseIterable, Hashable {
    case empiezo, algo, mucha
    var titulo: String {
        switch self { case .empiezo: return "Recién empiezo"; case .algo: return "Algo entrené"; case .mucha: return "Entreno hace años" }
    }
    var bajada: String {
        switch self {
        case .empiezo: return "Vamos de a poco, con técnica"
        case .algo: return "Conozco lo básico"
        case .mucha: return "Quiero que me exijan"
        }
    }
}

enum LugarClase: String, Codable, CaseIterable, Hashable {
    case gimnasio, plaza, domicilio, online
    var titulo: String {
        switch self { case .gimnasio: return "Gimnasio"; case .plaza: return "Plaza o parque"; case .domicilio: return "A domicilio"; case .online: return "Online" }
    }
}

enum FranjaHoraria: String, Codable, CaseIterable, Hashable {
    case temprano, manana, mediodia, tarde, noche
    var titulo: String {
        switch self {
        case .temprano: return "Temprano"
        case .manana: return "Mañana"
        case .mediodia: return "Mediodía"
        case .tarde: return "Tarde"
        case .noche: return "Noche"
        }
    }
    var horas: String {
        switch self {
        case .temprano: return "6 a 9"
        case .manana: return "9 a 12"
        case .mediodia: return "12 a 15"
        case .tarde: return "16 a 19"
        case .noche: return "19 a 22"
        }
    }
}

struct Perfil: Codable, Hashable {
    var lado: Lado
    var nombre: String = ""

    // Alumno
    var sexo: Sexo = .sinDecir
    var edad: Int = 30
    var peso: Double = 70
    var altura: Int = 168
    var objetivo: Objetivo?
    var experiencia: Experiencia?
    var diasPorSemana: Int = 3
    var lesiones: [String] = []
    var saludConectada = false

    // Profe
    var lugares: [LugarClase] = []
    var cantidadAlumnos: Int = 20
    var cobros: [MedioPago] = []
    var dias: [String] = []
    var franjas: [FranjaHoraria] = []

    var primerNombre: String { String(nombre.split(separator: " ").first ?? "") }

    private static let clave = "perfil"

    static func guardado(_ defaults: UserDefaults = .standard) -> Perfil? {
        guard let d = defaults.data(forKey: clave) else { return nil }
        return try? JSONDecoder().decode(Perfil.self, from: d)
    }

    func guardar(_ defaults: UserDefaults = .standard) {
        if let d = try? JSONEncoder().encode(self) { defaults.set(d, forKey: Perfil.clave) }
    }

    static func borrar(_ defaults: UserDefaults = .standard) { defaults.removeObject(forKey: clave) }
}

/// Lesiones o molestias que se ofrecen como chips.
let lesionesComunes = ["Rodilla", "Espalda baja", "Hombro", "Cuello", "Tobillo", "Muñeca", "Cadera"]
