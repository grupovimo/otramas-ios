import Foundation

// Modelos de Otra Más. Son valores simples (Codable) para que mañana los llene la API sin tocar las pantallas.

enum Lado: String, Codable, CaseIterable {
    case profe, alumno
}

struct Profe: Codable, Hashable {
    var nombre: String
    var foto: String
    var alias: String
}

enum TonoAvatar: String, Codable, Hashable { case berenjena, yema, arena, yemaFuerte }

enum EstadoCuota: Codable, Hashable {
    case alDia
    case porConfirmar(Comprobante)
    case debe(Deuda)
}

/// Comprobante de transferencia que mandó el alumno y la profe tiene que confirmar.
struct Comprobante: Codable, Hashable, Identifiable {
    var id: String
    var monto: Int
    /// «hoy 7:12», «ayer 21:40».
    var cuando: String
}

struct Deuda: Codable, Hashable {
    var monto: Int
    var dias: Int
}

/// Lo que se ve de un ejercicio en la ficha (la línea de progreso).
struct Progreso: Codable, Hashable {
    var ejercicio: String
    var actual: Double
    var valores: [Double]
    var meses: [String]
    var desde: String
}

struct Alumno: Codable, Hashable, Identifiable {
    var id: String
    var nombre: String
    var tono: TonoAvatar
    var plan: String
    var horario: String
    var cuota: EstadoCuota
    var asistencias: Int
    var clasesDelMes: Int
    var racha: Int
    var progreso: Progreso?
    /// Pasos por día de los últimos 7 días (Apple Salud), si los comparte.
    var pasos: [Double]?
    var ultimaVez: Int

    var iniciales: String {
        nombre.split(separator: " ").prefix(2).compactMap { $0.first.map(String.init) }.joined()
    }

    var primerNombre: String { String(nombre.split(separator: " ").first ?? "") }
}

enum MedioPago: String, Codable, CaseIterable, Hashable {
    case transferencia = "Transferencia"
    case efectivo = "Efectivo"
    case mercadoPago = "Mercado Pago"
}

enum EstadoClase: Codable, Hashable {
    case termino
    case falta(String)
    case suspendida(String)
}

struct Clase: Codable, Hashable, Identifiable {
    var id: String
    /// La clase fija de la que sale (nil: clase única) y la fecha «2026-11-26».
    var fijaId: String? = nil
    var fecha: String? = nil
    var recuperan: [String] = []
    var hora: String
    var nombre: String
    var lugar: String
    var estado: EstadoClase
    var cupo: Int
    /// Ids de los inscriptos y de los que vienen (o vinieron).
    var inscriptos: [String]
    var presentes: Set<String>
    /// Clase particular: el alumno.
    var particular: String?

    var vienen: Int { presentes.count }
}

struct DiaSemana: Codable, Hashable, Identifiable {
    var id: Int { numero }
    var corto: String
    var numero: Int
    var feriado = false
    var conClases = true
}

struct EjercicioDeRutina: Codable, Hashable, Identifiable {
    var id: String
    /// El ejercicio de la biblioteca (para la ilustración).
    var ejercicioId: String? = nil
    var nombre: String
    var foto: String
    /// Punto de foco de la foto (el object-position del diseño), de 0 a 1.
    var focoX: Double
    var focoY: Double
    var series: Double
    var reps: Double
    var kilos: Double
    /// Pausa entre series, en segundos.
    var pausa: Int
    /// Las «reps» son segundos (plancha, soga…).
    var porTiempo = false
    var notas: String? = nil

    var resumen: String {
        let base = "\(Int(series)) × \(Int(reps))\(porTiempo ? " s" : "")"
        return kilos > 0 ? "\(base) · \(Formato.decimal(kilos)) kg" : base
    }
}

struct DiaRutina: Codable, Hashable, Identifiable {
    var id: String
    var nombre: String
    var ejercicios: [EjercicioDeRutina]
}

/// A quién se le dio una rutina y desde cuándo.
struct Asignacion: Codable, Hashable {
    var alumnoId: String
    /// «2026-11-02».
    var desde: String
}

struct Rutina: Codable, Hashable, Identifiable {
    var id: String
    var nombre: String
    /// «Fuerza general · 3 días».
    var plan: String
    var dias: [DiaRutina]
    var objetivo: String = "Fuerza"
    var nivel: String = "Intermedio"
    var notas: String? = nil
    var plantilla = false
    var archivada = false
    var asignaciones: [Asignacion] = []

    var cantidadEjercicios: Int { dias.reduce(0) { $0 + $1.ejercicios.count } }
    var resumen: String {
        "\(dias.count) \(dias.count == 1 ? "día" : "días") · \(cantidadEjercicios) \(cantidadEjercicios == 1 ? "ejercicio" : "ejercicios")"
    }
    /// Ids del catálogo, sin repetir, para las miniaturas.
    var ejerciciosIds: [String] {
        var vistos = Set<String>(), out: [String] = []
        for d in dias { for e in d.ejercicios { if let i = e.ejercicioId, vistos.insert(i).inserted { out.append(i) } } }
        return out
    }
    var link: URL { URL(string: "https://otramas.com.ar/r/\(id)")! }
}

/// Una clase del horario semanal fijo (se repite cada semana en esos días).
struct ClaseFija: Codable, Hashable, Identifiable {
    var id: String
    var nombre: String
    /// 1 = lunes … 7 = domingo.
    var dias: [Int]
    var hora: String
    var lugar: String
    var cupo: Int
    var inscriptos: [String]
    var particular: String? = nil
    /// Quienes esperan un lugar.
    var espera: [String] = []
}

/// Lo que cambió en una fecha puntual de una clase fija.
struct AjusteClase: Codable, Hashable {
    var suspendida: String? = nil
    /// Alumnos anotados a recuperar ese día.
    var recuperan: [String] = []
    /// Alumnos que avisaron que faltan.
    var faltan: [String] = []
    /// Asistencia tomada (si se pasó lista).
    var presentes: Set<String>? = nil
}

struct MedioCobrado: Codable, Hashable {
    var medio: MedioPago
    var cuotas: Int
}

struct ResumenMes: Codable, Hashable {
    var mes: String
    var mesAnterior: String
    var cobrado: Int
    var variacion: Int
    /// En miles de pesos, de junio a noviembre (el último va por la mitad).
    var ingresos: [Double]
    var meses: [String]
    var alumnosActivos: Int
    var asistencia: Int
    var nuevos: Int
    var medios: [MedioCobrado]
    var noVienen: Int
}

struct PanelProfe: Codable, Hashable {
    var profe: Profe
    var fecha: String
    var hora: String
    var alumnos: [Alumno]
    var resumen: ResumenMes
    var semana: [DiaSemana]
    var hoy: Int
    var clases: [Clase]
    /// La próxima clase y cuánto falta («en 25 min»).
    var proxima: String
    var proximaEn: String
    var rutinas: [Rutina]
    var horario: [ClaseFija]
    /// Clases sueltas (eventos, clase única) por fecha.
    var clasesUnicas: [Clase] = []
    /// Cambios puntuales: clave «<fijaId>@<fecha>».
    var ajustes: [String: AjusteClase] = [:]
    var feriados: [String: String] = [:]
    /// La fecha de «hoy» en la maqueta (martes 24 de noviembre de 2026).
    var hoyISO: String
    var detalles: [String: DetalleAlumno] = DatosDeMuestra.detalles
    var abonos: [Abono] = DatosDeMuestra.abonos
    var avisos: [AvisoProfe] = DatosDeMuestra.avisos
    var cobros: ConfigCobros = DatosDeMuestra.configCobros
    var integraciones: [Integracion] = DatosDeMuestra.integraciones
    var notificaciones: [String: Bool] = ["Pagos": true, "Faltas": true, "Recordatorios": true, "Resumen semanal": false]
}

// MARK: - Alumno

struct EjercicioSesion: Codable, Hashable, Identifiable {
    var id: String
    /// El ejercicio de la biblioteca (para la ilustración).
    var ejercicioId: String? = nil
    var nombre: String
    var foto: String
    var series: Int
    var kilos: Double
    var reps: Int
    var anterior: Double
    /// Descanso entre series, en segundos.
    var descanso: Int
}

struct SesionHoy: Codable, Hashable {
    var ejercicios: [EjercicioSesion]
    var actual: Int
    /// Series ya hechas del ejercicio actual.
    var hechas: Int
    /// Segundos que le quedan al descanso en curso.
    var descansoRestante: Int
}

struct Medalla: Codable, Hashable, Identifiable {
    var id: String { titulo }
    var iconoNombre: String
    var titulo: String
    var ganada: Bool
    var deRacha = false
}

struct Record: Codable, Hashable {
    var kilos: Double
    var ejercicio: String
    var cuando: String
    var valores: [Double]
    var meses: [String]
}

struct Logros: Codable, Hashable {
    var rachaSemanas: Int
    var semanaHechas: Int
    var semanaMeta: Int
    var pasosHoy: Int
    var pasosMeta: Int
    var record: Record
    var medallas: [Medalla]
}

struct ProximaClase: Codable, Hashable {
    var diaCorto: String
    var dia: Int
    var hora: String
    var lugar: String
}

struct PlanAlumno: Codable, Hashable {
    var nombre: String
    var clasesTotal: Int
    var clasesUsadas: Int
    var mes: String
    var vence: String
    var proxima: ProximaClase
    var avisoFalta: Bool
    var paraRecuperar: Int
    var recuperarHasta: String
    var proximoMes: String
    var proximoMonto: Int
    var alias: String
}

/// Un entrenamiento hecho (historial del alumno).
struct Entrenamiento: Codable, Hashable, Identifiable {
    var id: String { fecha }
    var fecha: String
    var rutina: String
    var dia: String
    var minutos: Int
    var series: Int
    var volumen: Int
    var ejercicios: [String]
}

struct PanelAlumno: Codable, Hashable {
    var nombre: String
    var profe: String
    var fotoProfe: String
    var sesion: SesionHoy
    var logros: Logros
    var plan: PlanAlumno
    var historial: [Entrenamiento] = DatosDeMuestra.historial
    /// Diciembre: pagada, en revisión (subió comprobante) o pendiente.
    var cuotaPagada = false
    var comprobanteEnRevision = false
    /// Fechas en las que avisó que falta.
    var faltas: [String] = []
    /// Ids de clases donde reservó recuperación.
    var reservas: [String] = []
}

// MARK: - Formato

enum Formato {
    /// $1.215.000 (es-AR).
    static func plata(_ n: Int) -> String {
        "$" + miles(n)
    }

    static func miles(_ n: Int) -> String {
        let s = String(abs(n))
        var out = ""
        for (i, c) in s.reversed().enumerated() {
            if i > 0 && i % 3 == 0 { out.append(".") }
            out.append(c)
        }
        return (n < 0 ? "-" : "") + String(out.reversed())
    }

    /// 47,5 · 50 (coma decimal, sin ceros de más).
    static func decimal(_ v: Double) -> String {
        if v == v.rounded() { return String(Int(v)) }
        return String(format: "%.1f", v).replacingOccurrences(of: ".", with: ",")
    }

    static func reloj(_ segundos: Int) -> String {
        String(format: "%d:%02d", max(segundos, 0) / 60, max(segundos, 0) % 60)
    }

    static func pausa(_ s: Int) -> String { s < 120 ? "\(s) s" : "\(s / 60) min" }
}
