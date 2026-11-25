import Foundation

// Todo lo que el profe maneja de su trabajo: alumnos con su historia, abonos, cobros, avisos e integraciones.

enum EstadoAlumno: String, Codable, Hashable { case activo, pausado, baja }

enum TipoAbono: String, Codable, CaseIterable, Hashable {
    case mensual = "Mensual", pack = "Pack de clases", suelta = "Clase suelta"
}

struct Abono: Codable, Hashable, Identifiable {
    var id: String
    var nombre: String
    var tipo: TipoAbono
    /// Mensual: veces por semana (nil = libre). Pack: cantidad de clases.
    var cantidad: Int?
    var precio: Int

    var detalle: String {
        switch tipo {
        case .mensual: return cantidad.map { "\($0) veces por semana" } ?? "Pase libre"
        case .pack: return "\(cantidad ?? 8) clases · vencen a fin de mes"
        case .suelta: return "Una clase"
        }
    }
}

struct Medicion: Codable, Hashable, Identifiable {
    var id = UUID().uuidString
    var fecha: String
    var peso: Double
    var grasa: Double? = nil
    var cintura: Double? = nil
    var cadera: Double? = nil
}

struct Evaluacion: Codable, Hashable, Identifiable {
    var id = UUID().uuidString
    var nombre: String
    var valor: Double
    var unidad: String
    var fecha: String
}

struct MarcaEjercicio: Codable, Hashable, Identifiable {
    var id: String { ejercicioId }
    var ejercicioId: String
    var kilos: Double
    var fecha: String
}

struct Pago: Codable, Hashable, Identifiable {
    var id = UUID().uuidString
    var alumnoId: String
    /// «2026-11».
    var mes: String
    var monto: Int
    var medio: MedioPago
    var fecha: String
}

struct Nota: Codable, Hashable, Identifiable {
    var id = UUID().uuidString
    var fecha: String
    var texto: String
}

struct FotoProgreso: Codable, Hashable, Identifiable {
    var id = UUID().uuidString
    var fecha: String
    var asset: String? = nil
    var datos: Data? = nil
}

/// Lo que el profe sabe de cada alumno, más allá de la lista.
struct DetalleAlumno: Codable, Hashable {
    var estado: EstadoAlumno = .activo
    /// Quedó en pausa por superar el tope del plan (vuelve solo al subir de plan).
    var pausadoPorTope = false
    var telefono: String
    var objetivo: Objetivo?
    var lesiones: [String] = []
    var abonoId: String
    var claseFijaId: String?
    var inicio: String
    var mediciones: [Medicion] = []
    var evaluaciones: [Evaluacion] = []
    var marcas: [MarcaEjercicio] = []
    var pagos: [Pago] = []
    var notas: [Nota] = []
    var fotos: [FotoProgreso] = []
}

struct AvisoProfe: Codable, Hashable, Identifiable {
    var id = UUID().uuidString
    var fecha: String
    var titulo: String
    var texto: String
    /// «Todos», el nombre de una clase o «Los que deben».
    var para: String
    var cantidad: Int
}

struct ConfigCobros: Codable, Hashable {
    var alias: String
    var cbu: String
    var titular: String
    var medios: [MedioPago]
    var recordatorioActivo: Bool
    /// Día del mes en que sale el recordatorio a los que deben.
    var diaRecordatorio: Int
    var vence: Int
}

struct Integracion: Codable, Hashable, Identifiable {
    var id: String
    var nombre: String
    var para: String
    var conectada: Bool
}

/// Plantillas de aviso por WhatsApp.
let plantillasAviso: [(String, String)] = [
    ("Lluvia", "¡Hola! Por la lluvia hoy no hay clase. Te queda para recuperar: elegí el día desde tu link."),
    ("Feriado", "¡Hola! El lunes es feriado y no hay clase. Nos vemos el martes a la hora de siempre."),
    ("Cambio de horario", "¡Hola! Esta semana la clase de la tarde pasa a las 18:30. Mismo lugar."),
    ("Cuota", "¡Hola! Te recuerdo que la cuota de este mes vence el 10. Podés pagar desde tu link."),
    ("Evento", "¡Hola! El sábado hacemos clase especial en la playa, 9:30 en Playa Grande. ¡Traé agua!"),
]

extension DatosDeMuestra {
    static let abonos: [Abono] = [
        Abono(id: "m2", nombre: "Mensual 2 veces", tipo: .mensual, cantidad: 2, precio: 36000),
        Abono(id: "m3", nombre: "Mensual 3 veces", tipo: .mensual, cantidad: 3, precio: 45000),
        Abono(id: "libre", nombre: "Pase libre", tipo: .mensual, cantidad: nil, precio: 72000),
        Abono(id: "pack8", nombre: "Pack de 8 particulares", tipo: .pack, cantidad: 8, precio: 72000),
        Abono(id: "suelta", nombre: "Clase suelta", tipo: .suelta, cantidad: nil, precio: 12000),
    ]

    /// La historia de cada alumno, armada de forma estable a partir de sus datos.
    static func detalle(_ a: Alumno, _ i: Int) -> DetalleAlumno {
        let abono: String = a.plan.hasPrefix("Pack") ? (a.id == "nico" ? "pack8" : "pack8") : a.plan.contains("5 días") ? "libre" : (a.horario.contains("mar y jue") ? "m2" : "m3")
        let precio = abonos.first { $0.id == abono }?.precio ?? 45000
        let fija = DatosDeMuestra.horarioSemanal.first { $0.inscriptos.contains(a.id) }?.id
        let meses = ["2026-06", "2026-07", "2026-08", "2026-09", "2026-10"]
        let medios: [MedioPago] = [.transferencia, .efectivo, .mercadoPago]
        var pagos = meses.enumerated().map { k, m in
            Pago(alumnoId: a.id, mes: m, monto: precio - (k < 2 ? 4000 : 0), medio: medios[(i + k) % 3], fecha: "\(m)-0\(3 + (i + k) % 6)")
        }
        if a.cuota == .alDia { pagos.append(Pago(alumnoId: a.id, mes: "2026-11", monto: precio, medio: medios[i % 3], fecha: "2026-11-0\(2 + i % 7)")) }
        let base = 58.0 + Double((i * 7) % 30)
        var mediciones: [Medicion] = []
        for k in 0..<6 {
            let dk = Double(k)
            let fecha: String = k < meses.count ? meses[k] + "-05" : "2026-11-05"
            let grasa: Double? = i % 2 == 0 ? 28.0 - dk * 0.7 : nil
            let peso: Double = base + 3.0 - dk * 0.6
            let cintura: Double = 84.0 - dk
            let cadera: Double = 101.0 - dk * 0.5
            mediciones.append(Medicion(fecha: fecha, peso: peso, grasa: grasa, cintura: cintura, cadera: cadera))
        }
        let objetivos = Objetivo.allCases
        var d = DetalleAlumno(telefono: "+54 223 5\(String(format: "%02d", 10 + i))-\(String(format: "%04d", 1200 + i * 37))",
                              objetivo: objetivos[i % objetivos.count],
                              lesiones: i % 5 == 0 ? ["Rodilla"] : i % 7 == 0 ? ["Espalda baja"] : [],
                              abonoId: abono, claseFijaId: fija,
                              inicio: ["2024-03-04", "2025-02-10", "2025-08-01", "2026-03-02", "2026-09-07"][i % 5],
                              mediciones: mediciones,
                              evaluaciones: [
                                Evaluacion(nombre: "Sentadilla 1RM", valor: 30 + Double(i % 5) * 5, unidad: "kg", fecha: "2026-08-05"),
                                Evaluacion(nombre: "Sentadilla 1RM", valor: 38 + Double(i % 5) * 5, unidad: "kg", fecha: "2026-11-05"),
                                Evaluacion(nombre: "Plancha", valor: 45 + Double(i % 4) * 10, unidad: "s", fecha: "2026-08-05"),
                                Evaluacion(nombre: "Plancha", valor: 70 + Double(i % 4) * 10, unidad: "s", fecha: "2026-11-05"),
                                Evaluacion(nombre: "Test de Cooper", valor: 1800 + Double(i % 6) * 100, unidad: "m", fecha: "2026-10-01"),
                              ],
                              marcas: [
                                MarcaEjercicio(ejercicioId: "sentadilla-goblet", kilos: 16 + Double(i % 4) * 2, fecha: "2026-11-10"),
                                MarcaEjercicio(ejercicioId: "peso-muerto-rumano", kilos: 30 + Double(i % 5) * 5, fecha: "2026-11-03"),
                                MarcaEjercicio(ejercicioId: "hip-thrust", kilos: 40 + Double(i % 6) * 5, fecha: "2026-10-20"),
                              ],
                              pagos: pagos,
                              notas: i % 3 == 0 ? [Nota(fecha: "2026-11-10", texto: "Molestia leve en la rodilla derecha: sin saltos por dos semanas.")]
                                                : [Nota(fecha: "2026-10-15", texto: "Quiere sumar un día más en diciembre.")])
        if a.id == "carla" {
            d.fotos = [FotoProgreso(fecha: "2026-03-02", asset: "foto-domicilio"), FotoProgreso(fecha: "2026-11-05", asset: "foto-tecnica")]
            d.marcas[0].kilos = 24
        }
        if a.id == "nico" {
            d.marcas = [MarcaEjercicio(ejercicioId: "peso-muerto-rumano", kilos: 50, fecha: "2026-11-24"),
                        MarcaEjercicio(ejercicioId: "sentadilla-barra", kilos: 70, fecha: "2026-11-12"),
                        MarcaEjercicio(ejercicioId: "press-banca", kilos: 55, fecha: "2026-11-19")]
            var medNico: [Medicion] = []
            for k in 0..<6 {
                let dk = Double(k)
                let fecha: String = k < 5 ? meses[k] + "-05" : "2026-11-05"
                let peso: Double = 81.0 - dk * 0.6
                let grasa: Double = 21.0 - dk * 0.6
                let cintura: Double = 88.0 - dk
                medNico.append(Medicion(fecha: fecha, peso: peso, grasa: grasa, cintura: cintura, cadera: 99.0))
            }
            d.mediciones = medNico
        }
        if a.id == "ramiro" { d.estado = EstadoAlumno.pausado }
        return d
    }

    static let detalles: [String: DetalleAlumno] = Dictionary(uniqueKeysWithValues: alumnos.enumerated().map { ($1.id, detalle($1, $0)) })

    static let avisos: [AvisoProfe] = [
        AvisoProfe(fecha: "2026-11-23", titulo: "Feriado", texto: plantillasAviso[1].1, para: "Todos", cantidad: 30),
        AvisoProfe(fecha: "2026-11-17", titulo: "Lluvia", texto: plantillasAviso[0].1, para: "Funcional tarde", cantidad: 12),
        AvisoProfe(fecha: "2026-11-05", titulo: "Cuota", texto: plantillasAviso[3].1, para: "Los que deben", cantidad: 6),
        AvisoProfe(fecha: "2026-10-30", titulo: "Evento", texto: plantillasAviso[4].1, para: "Todos", cantidad: 28),
    ]

    static let configCobros = ConfigCobros(alias: "lucia.entrena.mdp", cbu: "0140 4161 0571 6503 2187 54", titular: "Lucía Ferreyra",
                                           medios: [.transferencia, .efectivo, .mercadoPago], recordatorioActivo: true, diaRecordatorio: 5, vence: 10)

    static let integraciones: [Integracion] = [
        Integracion(id: "mp", nombre: "Mercado Pago", para: "Cobrar con link y que se acredite solo", conectada: true),
        Integracion(id: "gcal", nombre: "Google Calendar", para: "Tus clases en tu calendario", conectada: false),
        Integracion(id: "sheets", nombre: "Google Sheets", para: "Una planilla con los cobros, al día", conectada: false),
        Integracion(id: "salud", nombre: "Apple Salud", para: "Los pasos de tus alumnos, si los comparten", conectada: true),
    ]
}

extension DatosDeMuestra {
    /// Lo que entrenó Nico: martes y jueves (particular) y algún sábado, desde septiembre.
    static let historial: [Entrenamiento] = {
        var out: [Entrenamiento] = []
        var f = "2026-09-01"
        var k = 0
        while f < "2026-11-24" {
            let d = Fecha.diaSemana(f)
            if d == 2 || d == 4 || (d == 6 && k % 3 == 0) {
                let dia = ["Día A", "Día B", "Día C"][k % 3]
                let ej: [[String]] = [["Sentadilla con barra", "Press de banca", "Remo con barra"],
                                      ["Peso muerto rumano", "Press militar", "Dominadas"],
                                      ["Sentadilla búlgara", "Hip thrust con barra", "Face pull", "Rueda abdominal"]]
                if !(k % 7 == 5) {
                    out.append(Entrenamiento(fecha: f, rutina: "Nico · fuerza", dia: dia, minutos: 48 + (k * 7) % 20, series: 13 + k % 3,
                                             volumen: 3200 + (k * 137) % 1800, ejercicios: ej[k % 3]))
                }
                k += 1
            }
            f = Fecha.sumar(1, a: f)
        }
        return out
    }()
}
